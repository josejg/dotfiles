#!/usr/bin/env python3
# NOTE: This script intentionally uses only stdlib to bootstrap from a bare system.
"""Bootstrap and install development tools for macOS and Linux."""

from __future__ import annotations

import argparse
import json
import os
import platform
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

_COLOR = sys.stdout.isatty()
BLUE = "\033[34m" if _COLOR else ""
GREEN = "\033[32m" if _COLOR else ""
YELLOW = "\033[33m" if _COLOR else ""
RED = "\033[31m" if _COLOR else ""
BOLD = "\033[1m" if _COLOR else ""
RESET = "\033[0m" if _COLOR else ""

_print_lock = threading.Lock()


def info(msg: str) -> None:
    with _print_lock:
        print(f"{BLUE}::{RESET} {msg}")


def ok(msg: str) -> None:
    with _print_lock:
        print(f"{GREEN}OK{RESET} {msg}")


def warn(msg: str) -> None:
    with _print_lock:
        print(f"{YELLOW}WARN{RESET} {msg}")


def err(msg: str) -> None:
    with _print_lock:
        print(f"{RED}ERR{RESET} {msg}", file=sys.stderr)


def verbose(msg: str) -> None:
    if ARGS.verbose:
        with _print_lock:
            print(f"  {msg}")


# ---------------------------------------------------------------------------
# Platform detection
# ---------------------------------------------------------------------------

SYSTEM = platform.system().lower()  # "darwin" or "linux"
_machine = platform.machine()
ARCH = "arm64" if _machine in ("aarch64", "arm64") else "x86_64"
PLATFORM_KEY = f"{SYSTEM}_{ARCH}"

HOME = Path.home()
LOCAL_BIN = HOME / ".local" / "bin"

# ---------------------------------------------------------------------------
# Version helpers
# ---------------------------------------------------------------------------

_VERSION_RE = re.compile(r"(\d+\.\d+(?:\.\d+)?)")


def parse_version(text: str) -> tuple[int, ...] | None:
    m = _VERSION_RE.search(text)
    if not m:
        return None
    return tuple(int(x) for x in m.group(1).split("."))


def installed_version(
    binary: str, version_cmd: str = "--version"
) -> tuple[int, ...] | None:
    path = shutil.which(binary)
    if not path:
        return None
    try:
        out = subprocess.check_output(
            [path, version_cmd], stderr=subprocess.STDOUT, text=True, timeout=5
        )
    except (
        subprocess.CalledProcessError,
        FileNotFoundError,
        subprocess.TimeoutExpired,
    ):
        return None
    return parse_version(out)


# ---------------------------------------------------------------------------
# Brew detection
# ---------------------------------------------------------------------------


def has_brew() -> bool:
    return shutil.which("brew") is not None


def use_brew(tool: "BinaryTool") -> bool:
    if not tool.brew_name or not has_brew():
        return False
    if SYSTEM == "darwin":
        return True
    return ARGS.prefer_brew


# ---------------------------------------------------------------------------
# GitHub API
# ---------------------------------------------------------------------------

_gh_available: bool | None = None


def _has_gh() -> bool:
    global _gh_available
    if _gh_available is None:
        _gh_available = shutil.which("gh") is not None
        if _gh_available:
            # Check auth status
            try:
                subprocess.check_output(
                    ["gh", "auth", "status"], stderr=subprocess.STDOUT, timeout=5
                )
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
                _gh_available = False
    return _gh_available


def github_latest_tag(repo: str) -> str | None:
    """Get latest release tag from GitHub.

    Primary: follow the /releases/latest 302 redirect (no API quota).
    Fallback 1: gh CLI (authenticated, 5000 req/hr).
    Fallback 2: REST API via urllib (60 req/hr unauthenticated).
    """
    # Primary: redirect-based (no rate limit)
    try:
        req = urllib.request.Request(
            f"https://github.com/{repo}/releases/latest",
            method="HEAD",
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            # Final URL after redirect: .../releases/tag/<tag>
            tag = resp.url.rsplit("/", 1)[-1]
            if tag and tag != "latest":
                verbose(f"  {repo}: resolved tag {tag} via redirect")
                return tag
    except Exception:
        pass

    # Fallback 1: gh CLI
    if _has_gh():
        try:
            return subprocess.check_output(
                ["gh", "api", f"repos/{repo}/releases/latest", "--jq", ".tag_name"],
                text=True,
                timeout=10,
            ).strip()
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
            pass

    # Fallback 2: REST API
    url = f"https://api.github.com/repos/{repo}/releases/latest"
    try:
        req = urllib.request.Request(
            url, headers={"Accept": "application/vnd.github+json"}
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read())
        return data["tag_name"]
    except Exception as exc:
        err(f"Failed to fetch latest version for {repo}: {exc}")
        return None


def version_from_tag(tag: str) -> str:
    """Extract numeric version from a tag like 'v1.2.3', 'jq-1.7', etc."""
    m = _VERSION_RE.search(tag)
    return m.group(1) if m else tag


# ---------------------------------------------------------------------------
# Download / extract helpers
# ---------------------------------------------------------------------------


def download_file(url: str, dest: Path) -> bool:
    verbose(f"Downloading {url}")
    try:
        urllib.request.urlretrieve(url, dest)
        return True
    except Exception as exc:
        err(f"Download failed: {exc}")
        return False


def extract_binary_from_tar(
    archive: Path,
    binary_in_archive: str,
    dest: Path,
    strip_components: int = 0,
) -> bool:
    """Extract a single binary from a tar.gz archive using system tar."""
    try:
        with tempfile.TemporaryDirectory() as td:
            subprocess.run(
                ["tar", "xzf", str(archive), "-C", td],
                check=True,
                capture_output=True,
            )
            # Find the binary after extraction
            for candidate in Path(td).rglob(Path(binary_in_archive).name):
                parts = candidate.relative_to(td).parts
                if strip_components > 0 and len(parts) > strip_components:
                    name_after_strip = str(Path(*parts[strip_components:]))
                else:
                    name_after_strip = str(candidate.relative_to(td))
                if name_after_strip == binary_in_archive:
                    shutil.move(str(candidate), str(dest))
                    dest.chmod(0o755)
                    return True
            err(f"Binary '{binary_in_archive}' not found in archive")
            return False
    except Exception as exc:
        err(f"Extraction failed: {exc}")
        return False


def extract_dir_from_tar(archive: Path, dest: Path) -> bool:
    """Extract an entire tar.gz to dest.

    Handles both single-directory archives (nvim) and flat archives (zsh-bin).
    """
    try:
        with tempfile.TemporaryDirectory() as td:
            subprocess.run(
                ["tar", "xzf", str(archive), "-C", td],
                check=True,
                capture_output=True,
            )
            extracted = list(Path(td).iterdir())
            if dest.exists():
                shutil.rmtree(dest)
            if len(extracted) == 1 and extracted[0].is_dir():
                # Single wrapping directory (e.g. nvim-linux-x86_64/)
                shutil.move(str(extracted[0]), str(dest))
            else:
                # Flat archive (e.g. bin/, share/, man/)
                shutil.move(td, str(dest))
        return True
    except Exception as exc:
        err(f"Directory extraction failed: {exc}")
        return False


# ---------------------------------------------------------------------------
# Brew install helper
# ---------------------------------------------------------------------------


def brew_install(package: str, upgrade: bool = False) -> bool:
    action = "upgrade" if upgrade else "install"
    try:
        subprocess.check_call(
            ["brew", action, package],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return True
    except subprocess.CalledProcessError:
        if action == "upgrade":
            # brew upgrade exits non-zero for various reasons (not
            # directly installed, already current, etc.); verify it's present
            try:
                subprocess.check_call(
                    ["brew", "list", package],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
                warn(f"brew upgrade {package} failed but package exists, continuing")
                return True  # package exists, was just already current
            except subprocess.CalledProcessError:
                return False  # genuinely broken
        return False


# ---------------------------------------------------------------------------
# BinaryTool dataclass & catalog
# ---------------------------------------------------------------------------


@dataclass
class BinaryTool:
    repo: str
    binary_name: str
    assets: dict[str, str | None]
    version_cmd: str = "--version"
    strip_components: int = 0
    binary_in_archive: str | None = None
    version_pin: str | None = None
    min_version: str | None = None
    brew_name: str | None = None
    install_dir: str | None = None  # non-standard dir (nvim -> ~/.local/nvim)
    tag_prefix: str = "v"  # prefix before version in git tag (e.g. "v" for "v1.2.3")


BINARY_TOOLS: dict[str, BinaryTool] = {
    "zsh": BinaryTool(
        repo="romkatv/zsh-bin",
        binary_name="zsh",
        brew_name="zsh",
        # Asset names are always "zsh-5.8-*" regardless of actual version;
        # romkatv/zsh-bin uses fixed filenames across releases.
        assets={
            "linux_x86_64": "zsh-5.8-linux-x86_64.tar.gz",
            "linux_arm64": "zsh-5.8-linux-aarch64.tar.gz",
            "darwin_x86_64": "zsh-5.8-darwin-x86_64.tar.gz",
            "darwin_arm64": "zsh-5.8-darwin-arm64.tar.gz",
        },
        install_dir="~/.local/zsh-bin",
    ),
    "gh": BinaryTool(
        repo="cli/cli",
        binary_name="gh",
        brew_name="gh",
        assets={
            "linux_x86_64": "gh_{v}_linux_amd64.tar.gz",
            "linux_arm64": "gh_{v}_linux_arm64.tar.gz",
            "darwin_x86_64": None,
            "darwin_arm64": None,
        },
        strip_components=1,
        binary_in_archive="bin/gh",
    ),
    "jq": BinaryTool(
        repo="jqlang/jq",
        binary_name="jq",
        brew_name="jq",
        min_version="1.7",
        tag_prefix="jq-",
        assets={
            "linux_x86_64": "jq-linux-amd64",
            "linux_arm64": "jq-linux-arm64",
            "darwin_x86_64": "jq-macos-amd64",
            "darwin_arm64": "jq-macos-arm64",
        },
    ),
    "fzf": BinaryTool(
        repo="junegunn/fzf",
        binary_name="fzf",
        brew_name="fzf",
        assets={
            "linux_x86_64": "fzf-{v}-linux_amd64.tar.gz",
            "linux_arm64": "fzf-{v}-linux_arm64.tar.gz",
            "darwin_x86_64": "fzf-{v}-darwin_amd64.tar.gz",
            "darwin_arm64": "fzf-{v}-darwin_arm64.tar.gz",
        },
        binary_in_archive="fzf",
    ),
    "delta": BinaryTool(
        repo="dandavison/delta",
        binary_name="delta",
        brew_name="git-delta",
        tag_prefix="",
        assets={
            "linux_x86_64": "delta-{v}-x86_64-unknown-linux-gnu.tar.gz",
            "linux_arm64": "delta-{v}-aarch64-unknown-linux-gnu.tar.gz",
            "darwin_x86_64": None,
            "darwin_arm64": None,
        },
        strip_components=1,
        binary_in_archive="delta",
    ),
    "fd": BinaryTool(
        repo="sharkdp/fd",
        binary_name="fd",
        brew_name="fd",
        version_pin="10.2.0",
        assets={
            "linux_x86_64": "fd-v{v}-x86_64-unknown-linux-gnu.tar.gz",
            "linux_arm64": "fd-v{v}-aarch64-unknown-linux-gnu.tar.gz",
            "darwin_x86_64": None,
            "darwin_arm64": None,
        },
        strip_components=1,
        binary_in_archive="fd",
    ),
    "rg": BinaryTool(
        repo="BurntSushi/ripgrep",
        binary_name="rg",
        brew_name="ripgrep",
        tag_prefix="",
        assets={
            "linux_x86_64": "ripgrep-{v}-x86_64-unknown-linux-musl.tar.gz",
            "linux_arm64": "ripgrep-{v}-aarch64-unknown-linux-gnu.tar.gz",
            "darwin_x86_64": None,
            "darwin_arm64": None,
        },
        strip_components=1,
        binary_in_archive="rg",
    ),
    "difft": BinaryTool(
        repo="Wilfred/difftastic",
        binary_name="difft",
        brew_name="difftastic",
        tag_prefix="",
        assets={
            "linux_x86_64": "difft-x86_64-unknown-linux-gnu.tar.gz",
            "linux_arm64": "difft-aarch64-unknown-linux-gnu.tar.gz",
            "darwin_x86_64": None,
            "darwin_arm64": None,
        },
        binary_in_archive="difft",
    ),
    "lazygit": BinaryTool(
        repo="jesseduffield/lazygit",
        binary_name="lazygit",
        brew_name="lazygit",
        assets={
            "linux_x86_64": "lazygit_{v}_Linux_x86_64.tar.gz",
            "linux_arm64": "lazygit_{v}_Linux_arm64.tar.gz",
            "darwin_x86_64": None,
            "darwin_arm64": None,
        },
        binary_in_archive="lazygit",
    ),
    "zoxide": BinaryTool(
        repo="ajeetdsouza/zoxide",
        binary_name="zoxide",
        brew_name="zoxide",
        assets={
            "linux_x86_64": "zoxide-{v}-x86_64-unknown-linux-musl.tar.gz",
            "linux_arm64": "zoxide-{v}-aarch64-unknown-linux-musl.tar.gz",
            "darwin_x86_64": None,
            "darwin_arm64": None,
        },
        binary_in_archive="zoxide",
    ),
    "eza": BinaryTool(
        repo="eza-community/eza",
        binary_name="eza",
        brew_name="eza",
        assets={
            "linux_x86_64": "eza_x86_64-unknown-linux-gnu.tar.gz",
            "linux_arm64": "eza_aarch64-unknown-linux-gnu.tar.gz",
            "darwin_x86_64": None,
            "darwin_arm64": None,
        },
        binary_in_archive="eza",
    ),
    "bat": BinaryTool(
        repo="sharkdp/bat",
        binary_name="bat",
        brew_name="bat",
        assets={
            "linux_x86_64": "bat-v{v}-x86_64-unknown-linux-musl.tar.gz",
            "linux_arm64": "bat-v{v}-aarch64-unknown-linux-musl.tar.gz",
            "darwin_x86_64": "bat-v{v}-x86_64-apple-darwin.tar.gz",
            "darwin_arm64": "bat-v{v}-aarch64-apple-darwin.tar.gz",
        },
        strip_components=1,
        binary_in_archive="bat",
    ),
    "age": BinaryTool(
        repo="FiloSottile/age",
        binary_name="age",
        brew_name="age",
        assets={
            "linux_x86_64": "age-v{v}-linux-amd64.tar.gz",
            "linux_arm64": "age-v{v}-linux-arm64.tar.gz",
            "darwin_x86_64": "age-v{v}-darwin-amd64.tar.gz",
            "darwin_arm64": "age-v{v}-darwin-arm64.tar.gz",
        },
        strip_components=1,
        binary_in_archive="age",
    ),
    "sops": BinaryTool(
        repo="getsops/sops",
        binary_name="sops",
        brew_name="sops",
        assets={
            "linux_x86_64": "sops-v{v}.linux.amd64",
            "linux_arm64": "sops-v{v}.linux.arm64",
            "darwin_x86_64": "sops-v{v}.darwin.amd64",
            "darwin_arm64": "sops-v{v}.darwin.arm64",
        },
    ),
    "uv": BinaryTool(
        repo="astral-sh/uv",
        binary_name="uv",
        brew_name="uv",
        tag_prefix="",
        assets={
            "linux_x86_64": "uv-x86_64-unknown-linux-gnu.tar.gz",
            "linux_arm64": "uv-aarch64-unknown-linux-gnu.tar.gz",
            "darwin_x86_64": "uv-x86_64-apple-darwin.tar.gz",
            "darwin_arm64": "uv-aarch64-apple-darwin.tar.gz",
        },
        strip_components=1,
        binary_in_archive="uv",
    ),
    "shellcheck": BinaryTool(
        repo="koalaman/shellcheck",
        binary_name="shellcheck",
        brew_name="shellcheck",
        assets={
            "linux_x86_64": "shellcheck-v{v}.linux.x86_64.tar.gz",
            "linux_arm64": "shellcheck-v{v}.linux.aarch64.tar.gz",
            "darwin_x86_64": "shellcheck-v{v}.darwin.x86_64.tar.gz",
            "darwin_arm64": "shellcheck-v{v}.darwin.aarch64.tar.gz",
        },
        strip_components=1,
        binary_in_archive="shellcheck",
    ),
    "shfmt": BinaryTool(
        repo="mvdan/sh",
        binary_name="shfmt",
        brew_name="shfmt",
        assets={
            "linux_x86_64": "shfmt_v{v}_linux_amd64",
            "linux_arm64": "shfmt_v{v}_linux_arm64",
            "darwin_x86_64": "shfmt_v{v}_darwin_amd64",
            "darwin_arm64": "shfmt_v{v}_darwin_arm64",
        },
    ),
    "tmux": BinaryTool(
        repo="tmux/tmux-builds",
        binary_name="tmux",
        brew_name="tmux",
        assets={
            "linux_x86_64": "tmux-{v}-linux-x86_64.tar.gz",
            "linux_arm64": "tmux-{v}-linux-arm64.tar.gz",
            "darwin_x86_64": None,
            "darwin_arm64": None,
        },
        binary_in_archive="tmux",
    ),
    "nvim": BinaryTool(
        repo="neovim/neovim",
        binary_name="nvim",
        brew_name="neovim",
        assets={
            "linux_x86_64": "nvim-linux-x86_64.tar.gz",
            "linux_arm64": "nvim-linux-arm64.tar.gz",
            "darwin_x86_64": None,
            "darwin_arm64": None,
        },
        install_dir="~/.local/nvim",
    ),
}

# Bootstrap order: gh and jq first for authenticated API access
BOOTSTRAP_TOOLS = ["zsh", "gh", "jq"]

# ---------------------------------------------------------------------------
# Core install logic
# ---------------------------------------------------------------------------


def _expand(path: str) -> Path:
    return Path(path).expanduser()


def should_install(tool: BinaryTool) -> bool:
    """Determine whether a tool needs installation."""
    local_path = LOCAL_BIN / tool.binary_name
    if tool.install_dir:
        local_path = _expand(tool.install_dir) / "bin" / tool.binary_name

    if local_path.exists():
        if ARGS.upgrade:
            return True
        verbose(f"{tool.binary_name}: already in {local_path}, skipping")
        return False

    # Not in local bin — check system PATH
    system_path = shutil.which(tool.binary_name)
    if system_path:
        if tool.min_version:
            cur = installed_version(tool.binary_name, tool.version_cmd)
            min_v = parse_version(tool.min_version)
            if cur and min_v and cur >= min_v:
                verbose(
                    f"{tool.binary_name}: system version {cur} >= {min_v}, skipping"
                )
                return False
        else:
            verbose(f"{tool.binary_name}: found on PATH at {system_path}, skipping")
            return False
    return True


def install_binary_tool(name: str, tool: BinaryTool) -> bool:
    if not should_install(tool):
        ok(f"{name}: up to date")
        return True

    # Brew path
    if use_brew(tool):
        info(f"{name}: {'upgrading' if ARGS.upgrade else 'installing'} via brew")
        if ARGS.dry_run:
            return True
        return brew_install(tool.brew_name, upgrade=ARGS.upgrade)

    # Check asset availability
    asset_template = tool.assets.get(PLATFORM_KEY)
    if asset_template is None:
        if tool.brew_name:
            info(f"{name}: no binary for {PLATFORM_KEY}, trying brew")
            if ARGS.dry_run:
                return True
            return brew_install(tool.brew_name, upgrade=ARGS.upgrade)
        warn(f"{name}: no binary available for {PLATFORM_KEY}")
        return False

    # Resolve version and tag
    if tool.version_pin:
        version = tool.version_pin
        tag = f"{tool.tag_prefix}{version}"
    else:
        tag = github_latest_tag(tool.repo)
        if not tag:
            err(f"{name}: could not determine latest version")
            return False
        version = tag.removeprefix(tool.tag_prefix) if tool.tag_prefix else version_from_tag(tag)

    asset_name = asset_template.format(v=version)
    url = f"https://github.com/{tool.repo}/releases/download/{tag}/{asset_name}"

    info(f"{name}: installing {tag} from {asset_name}")
    if ARGS.dry_run:
        return True

    LOCAL_BIN.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory() as td:
        dl_path = Path(td) / asset_name
        if not download_file(url, dl_path):
            return False

        # Full directory extraction (nvim, zsh-bin, etc.)
        if tool.install_dir:
            install_path = _expand(tool.install_dir)
            if not extract_dir_from_tar(dl_path, install_path):
                return False
            # zsh-bin: patch hardcoded paths to match install location
            relocate = install_path / "share" / "zsh" / "5.8" / "scripts" / "relocate"
            if relocate.exists():
                subprocess.run(
                    [str(relocate), "-d", str(install_path)],
                    check=True,
                    capture_output=True,
                )
            # Create symlink
            symlink = LOCAL_BIN / tool.binary_name
            symlink.unlink(missing_ok=True)
            target = install_path / "bin" / tool.binary_name
            symlink.symlink_to(target)
            ok(f"{name}: installed to {install_path}, symlinked {symlink}")
            return True

        # Raw binary (no archive extension)
        if not asset_name.endswith((".tar.gz", ".tgz", ".zip")):
            dest = LOCAL_BIN / tool.binary_name
            shutil.move(str(dl_path), str(dest))
            dest.chmod(0o755)
            ok(f"{name}: installed to {dest}")
            return True

        # Archive with binary inside
        if tool.binary_in_archive:
            dest = LOCAL_BIN / tool.binary_name
            if not extract_binary_from_tar(
                dl_path, tool.binary_in_archive, dest, tool.strip_components
            ):
                return False
            ok(f"{name}: installed to {dest}")
            return True

        err(f"{name}: don't know how to install {asset_name}")
        return False


# ---------------------------------------------------------------------------
# Git dependencies
# ---------------------------------------------------------------------------


@dataclass
class GitDep:
    repo: str  # "owner/name" on GitHub
    dest: str  # target directory (~ expanded)
    shallow: bool = False


GIT_DEPS: dict[str, GitDep] = {
    "fast-syntax-highlighting": GitDep(
        repo="zdharma-continuum/fast-syntax-highlighting",
        dest="~/.zsh/fast-syntax-highlighting",
    ),
    "zsh-autosuggestions": GitDep(
        repo="zsh-users/zsh-autosuggestions",
        dest="~/.zsh/zsh-autosuggestions",
    ),
    "zsh-history-substring-search": GitDep(
        repo="zsh-users/zsh-history-substring-search",
        dest="~/.zsh/zsh-history-substring-search",
    ),
    "zsh-completions": GitDep(
        repo="zsh-users/zsh-completions",
        dest="~/.zsh/zsh-completions",
    ),
    "zsh-you-should-use": GitDep(
        repo="MichaelAquilina/zsh-you-should-use",
        dest="~/.zsh/zsh-you-should-use",
    ),
    "fzf-tab": GitDep(
        repo="Aloxaf/fzf-tab",
        dest="~/.zsh/fzf-tab",
    ),
    "zsh-autopair": GitDep(
        repo="hlissner/zsh-autopair",
        dest="~/.zsh/zsh-autopair",
    ),
    "zsh-defer": GitDep(
        repo="romkatv/zsh-defer",
        dest="~/.zsh/zsh-defer",
    ),
    "powerlevel10k": GitDep(
        repo="romkatv/powerlevel10k",
        dest="~/.zsh/powerlevel10k",
        shallow=True,
    ),
    "alacritty-themes": GitDep(
        repo="JJGO/alacritty-theme",
        dest="~/.config/alacritty/themes",
    ),
}


def _git(*args: str) -> None:
    """Run a git command, retrying once with HTTP/1.1 on failure."""
    cmd = ["git", *args]
    try:
        subprocess.run(cmd, check=True, capture_output=True)
    except subprocess.CalledProcessError:
        verbose("retrying with http.version=HTTP/1.1")
        subprocess.run(
            ["git", "-c", "http.version=HTTP/1.1", *args],
            check=True,
            capture_output=True,
        )


def install_git_dep(name: str, dep: GitDep) -> bool:
    dest = _expand(dep.dest)
    url = f"https://github.com/{dep.repo}.git"

    if dest.exists():
        if not ARGS.upgrade:
            ok(f"{name}: already cloned")
            return True
        info(f"{name}: updating")
        if ARGS.dry_run:
            return True
        try:
            if dep.shallow:
                _git("-C", str(dest), "fetch", "--depth=1")
                _git("-C", str(dest), "reset", "--hard", "origin/HEAD")
            else:
                _git("-C", str(dest), "pull", "--ff-only")
        except subprocess.CalledProcessError as exc:
            err(f"{name}: update failed: {exc.stderr.decode()}")
            return False
        ok(f"{name}: updated")
        return True

    info(f"{name}: cloning to {dest}")
    if ARGS.dry_run:
        return True
    dest.parent.mkdir(parents=True, exist_ok=True)
    clone_args = ["clone"]
    if dep.shallow:
        clone_args += ["--depth=1"]
    clone_args += [url, str(dest)]
    try:
        _git(*clone_args)
        ok(f"{name}: cloned")
        return True
    except subprocess.CalledProcessError as exc:
        err(f"{name}: clone failed: {exc.stderr.decode()}")
        return False


# ---------------------------------------------------------------------------
# Node.js
# ---------------------------------------------------------------------------

NODE_DIR = HOME / ".local" / "node"


def install_node() -> bool:
    """Install Node.js LTS for Mason npm tools and copilot.lua."""
    node_symlink = LOCAL_BIN / "node"
    if node_symlink.exists() or (NODE_DIR / "bin" / "node").exists():
        if not ARGS.upgrade:
            ok("node: up to date")
            return True

    if shutil.which("node") and not ARGS.upgrade:
        ok("node: found on PATH")
        return True

    if SYSTEM == "darwin" and has_brew():
        info("node: installing via brew")
        if ARGS.dry_run:
            return True
        return brew_install("node", upgrade=ARGS.upgrade)

    info("node: downloading LTS from nodejs.org")
    if ARGS.dry_run:
        return True

    node_arch = "arm64" if ARCH == "arm64" else "x64"
    node_os = "darwin" if SYSTEM == "darwin" else "linux"

    try:
        with urllib.request.urlopen(
            "https://nodejs.org/dist/index.json", timeout=10
        ) as resp:
            versions = json.loads(resp.read())
        lts_version = next((v["version"] for v in versions if v.get("lts")), None)
        if not lts_version:
            err("node: could not find LTS version")
            return False
    except Exception as exc:
        err(f"node: failed to fetch versions: {exc}")
        return False

    tarball = f"node-{lts_version}-{node_os}-{node_arch}.tar.gz"
    url = f"https://nodejs.org/dist/{lts_version}/{tarball}"

    with tempfile.TemporaryDirectory() as td:
        dl_path = Path(td) / tarball
        if not download_file(url, dl_path):
            return False
        if not extract_dir_from_tar(dl_path, NODE_DIR):
            return False

    LOCAL_BIN.mkdir(parents=True, exist_ok=True)
    for binary in ("node", "npm", "npx"):
        symlink = LOCAL_BIN / binary
        symlink.unlink(missing_ok=True)
        symlink.symlink_to(NODE_DIR / "bin" / binary)

    ok(f"node: installed {lts_version} to {NODE_DIR}")
    return True


# ---------------------------------------------------------------------------
# Claude Code
# ---------------------------------------------------------------------------


def install_claude_code() -> bool:
    if shutil.which("claude") and not ARGS.upgrade:
        ok("claude-code: installed")
        return True
    info("claude-code: installing")
    if ARGS.dry_run:
        return True
    if SYSTEM == "darwin" and has_brew():
        return brew_install("claude-code", upgrade=ARGS.upgrade)
    try:
        subprocess.run(
            ["bash", "-c", "curl -fsSL https://claude.ai/install.sh | bash"],
            check=True,
        )
        ok("claude-code: installed")
        return True
    except subprocess.CalledProcessError as exc:
        err(f"claude-code install failed: {exc}")
        return False


# ---------------------------------------------------------------------------
# uv tools (Python CLI tools installed via uv tool install)
# ---------------------------------------------------------------------------

UV_TOOLS = ["ruff", "yamllint", "magic-wormhole"]


def install_uv_tools() -> bool:
    """Install Python CLI tools via uv tool install."""
    uv = shutil.which("uv")
    if not uv:
        uv_local = LOCAL_BIN / "uv"
        if uv_local.exists():
            uv = str(uv_local)
        else:
            warn("uv-tools: uv not found, skipping")
            return False

    success = True
    for tool in UV_TOOLS:
        if not ARGS.upgrade and shutil.which(tool):
            ok(f"uv-tools: {tool} already installed")
            continue
        info(f"uv-tools: installing {tool}")
        if ARGS.dry_run:
            continue
        try:
            cmd = [uv, "tool", "install", tool]
            if ARGS.upgrade:
                cmd.append("--upgrade")
            subprocess.run(cmd, check=True, capture_output=True)
            ok(f"uv-tools: {tool} installed")
        except subprocess.CalledProcessError as exc:
            err(f"uv-tools: {tool} failed: {exc.stderr.decode()}")
            success = False
    return success


# ---------------------------------------------------------------------------
# Neovim plugins
# ---------------------------------------------------------------------------


def sync_nvim_plugins() -> bool:
    """Headless nvim setup: Lazy plugins, treesitter parsers, Mason tools."""
    nvim = shutil.which("nvim")
    if not nvim:
        nvim_local = _expand("~/.local/nvim") / "bin" / "nvim"
        if nvim_local.exists():
            nvim = str(nvim_local)
        else:
            warn("nvim-plugins: nvim not found, skipping")
            return True

    if ARGS.dry_run:
        info("nvim-plugins: would sync plugins, treesitter, mason")
        return True

    # Point nvim at the repo config directly (works before install.py symlinks)
    dotfiles_dir = Path(__file__).resolve().parent
    xdg_config = str(dotfiles_dir / "nvim" / ".config")
    # Ensure ~/.local/bin is on PATH so nvim can find node (for copilot.lua cond)
    path = os.environ.get("PATH", "")
    if str(LOCAL_BIN) not in path:
        path = f"{LOCAL_BIN}:{path}"
    env = {**os.environ, "XDG_CONFIG_HOME": xdg_config, "PATH": path}

    success = True
    # Mason: force-load the lazy plugin, then run sync install
    mason_cmd = (
        "lua require('lazy').load({plugins={'mason.nvim','mason-tool-installer.nvim'}})"
    )
    steps = [
        ("plugins", [nvim, "--headless", "+Lazy! sync", "+qa"]),
        ("treesitter", [nvim, "--headless", "+TSUpdateSync", "+qa"]),
        ("mason", [nvim, "--headless", f"+{mason_cmd}", "+MasonToolsInstallSync", "+qa"]),
    ]
    for step_name, cmd in steps:
        info(f"nvim-plugins: syncing {step_name}")
        try:
            subprocess.run(cmd, check=True, timeout=600, env=env)
            ok(f"nvim-plugins: {step_name} done")
        except subprocess.TimeoutExpired:
            err(f"nvim-plugins: {step_name} timed out")
            success = False
        except subprocess.CalledProcessError as exc:
            err(f"nvim-plugins: {step_name} failed: {exc}")
            success = False
    return success


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Bootstrap development tools")
    p.add_argument("tools", nargs="*", help="Specific tools to install (default: all)")
    p.add_argument("--upgrade", action="store_true", help="Update all to latest")
    p.add_argument(
        "-n", "--dry-run", action="store_true", help="Show what would be done"
    )
    p.add_argument("-v", "--verbose", action="store_true", help="Verbose output")
    p.add_argument(
        "--prefer-brew",
        action="store_true",
        help="On Linux, use linuxbrew instead of pre-built binaries",
    )
    return p


ARGS: argparse.Namespace  # set in main()


def main() -> None:
    global ARGS
    parser = build_parser()
    ARGS = parser.parse_args()

    requested = set(ARGS.tools) if ARGS.tools else None
    all_names = set(BINARY_TOOLS) | set(GIT_DEPS) | {"node", "uv-tools", "claude-code", "nvim-plugins"}
    if requested:
        unknown = requested - all_names
        if unknown:
            err(f"Unknown tools: {', '.join(sorted(unknown))}")
            sys.exit(1)

    info(f"Platform: {PLATFORM_KEY}")
    if ARGS.dry_run:
        info("Dry run — no changes will be made")

    failures: list[str] = []
    max_workers = 6

    # Phase 1: Bootstrap tools (zsh, gh, jq) — sequential for API auth
    for name in BOOTSTRAP_TOOLS:
        if requested and name not in requested:
            continue
        if not install_binary_tool(name, BINARY_TOOLS[name]):
            failures.append(name)

    # Phase 2: Remaining binary tools + node — parallel
    binary_tasks = {
        name: tool
        for name, tool in BINARY_TOOLS.items()
        if name not in BOOTSTRAP_TOOLS and (not requested or name in requested)
    }
    with ThreadPoolExecutor(max_workers=max_workers) as pool:
        futures = {
            pool.submit(install_binary_tool, name, tool): name
            for name, tool in binary_tasks.items()
        }
        if not requested or "node" in requested:
            futures[pool.submit(install_node)] = "node"
        for fut in as_completed(futures):
            name = futures[fut]
            if not fut.result():
                failures.append(name)

    # Phase 3: Git dependencies — parallel
    git_tasks = {
        name: dep
        for name, dep in GIT_DEPS.items()
        if not requested or name in requested
    }
    with ThreadPoolExecutor(max_workers=max_workers) as pool:
        futures = {
            pool.submit(install_git_dep, name, dep): name
            for name, dep in git_tasks.items()
        }
        for fut in as_completed(futures):
            name = futures[fut]
            if not fut.result():
                failures.append(name)

    # Phase 4: uv tools (needs uv from phase 2)
    if not requested or "uv-tools" in requested:
        if not install_uv_tools():
            failures.append("uv-tools")

    # Phase 5: Claude Code
    if not requested or "claude-code" in requested:
        if not install_claude_code():
            failures.append("claude-code")

    # Phase 5: Neovim plugins (needs nvim + node from earlier phases)
    if not requested or "nvim-plugins" in requested:
        if not sync_nvim_plugins():
            failures.append("nvim-plugins")

    if failures:
        err(f"Failed: {', '.join(failures)}")
        sys.exit(1)
    info("Done!")


if __name__ == "__main__":
    main()
