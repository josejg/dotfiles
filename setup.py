#!/usr/bin/env python3
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
import tarfile
import tempfile
import urllib.request
from dataclasses import dataclass
from pathlib import Path

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

BLUE = "\033[34m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
BOLD = "\033[1m"
RESET = "\033[0m"


def info(msg: str) -> None:
    print(f"{BLUE}::{RESET} {msg}")


def ok(msg: str) -> None:
    print(f"{GREEN}OK{RESET} {msg}")


def warn(msg: str) -> None:
    print(f"{YELLOW}WARN{RESET} {msg}")


def err(msg: str) -> None:
    print(f"{RED}ERR{RESET} {msg}", file=sys.stderr)


def verbose(msg: str) -> None:
    if ARGS.verbose:
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
    """Extract a single binary from a tar.gz archive."""
    try:
        with tarfile.open(archive) as tf:
            members = tf.getmembers()
            # Find the target binary
            for member in members:
                parts = Path(member.name).parts
                if strip_components > 0 and len(parts) > strip_components:
                    name_after_strip = str(Path(*parts[strip_components:]))
                else:
                    name_after_strip = member.name
                if name_after_strip == binary_in_archive:
                    # Extract to temp and move
                    with tempfile.TemporaryDirectory() as td:
                        tf.extract(member, td)
                        extracted = Path(td) / member.name
                        shutil.move(str(extracted), str(dest))
                        dest.chmod(0o755)
                    return True
            err(f"Binary '{binary_in_archive}' not found in archive")
            return False
    except Exception as exc:
        err(f"Extraction failed: {exc}")
        return False


def extract_dir_from_tar(archive: Path, dest: Path) -> bool:
    """Extract an entire tar.gz to dest (for nvim-style full-directory installs)."""
    try:
        with tempfile.TemporaryDirectory() as td:
            with tarfile.open(archive) as tf:
                tf.extractall(td)
            # Find the single top-level directory
            extracted = list(Path(td).iterdir())
            if len(extracted) != 1 or not extracted[0].is_dir():
                err("Expected single directory in archive")
                return False
            # Remove old dest if it exists, then move
            if dest.exists():
                shutil.rmtree(dest)
            shutil.move(str(extracted[0]), str(dest))
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
            # Already up to date
            return True
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
        binary_in_archive="./eza",
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
BOOTSTRAP_TOOLS = ["gh", "jq"]

# ---------------------------------------------------------------------------
# Core install logic
# ---------------------------------------------------------------------------


def _expand(path: str) -> Path:
    return Path(path.replace("~", str(HOME)))


def should_install(tool: BinaryTool) -> bool:
    """Determine whether a tool needs installation."""
    local_path = LOCAL_BIN / tool.binary_name
    if tool.install_dir:
        local_path = _expand(tool.install_dir) / "bin" / tool.binary_name

    if local_path.exists() and not ARGS.upgrade:
        verbose(f"{tool.binary_name}: already in {local_path}, skipping")
        return False

    if local_path.exists() and ARGS.upgrade:
        return True

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
            if not ARGS.upgrade:
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
        version = version_from_tag(tag)

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

        # Special case: nvim needs full directory extraction
        if tool.install_dir:
            install_path = _expand(tool.install_dir)
            if not extract_dir_from_tar(dl_path, install_path):
                return False
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
        if dep.shallow:
            subprocess.run(
                ["git", "-C", str(dest), "fetch", "--depth=1"],
                check=True,
                capture_output=True,
            )
            subprocess.run(
                ["git", "-C", str(dest), "reset", "--hard", "origin/HEAD"],
                check=True,
                capture_output=True,
            )
        else:
            subprocess.run(
                ["git", "-C", str(dest), "pull", "--ff-only"],
                check=True,
                capture_output=True,
            )
        ok(f"{name}: updated")
        return True

    info(f"{name}: cloning to {dest}")
    if ARGS.dry_run:
        return True
    dest.parent.mkdir(parents=True, exist_ok=True)
    cmd = ["git", "clone"]
    if dep.shallow:
        cmd += ["--depth=1"]
    cmd += [url, str(dest)]
    try:
        subprocess.run(cmd, check=True, capture_output=True)
        ok(f"{name}: cloned")
        return True
    except subprocess.CalledProcessError as exc:
        err(f"{name}: clone failed: {exc.stderr.decode()}")
        return False


# ---------------------------------------------------------------------------
# Neovim environment setup
# ---------------------------------------------------------------------------

NVIM_DIR = HOME / ".neovim"


def setup_nvim_env() -> bool:
    """Set up Python venv and Node.js for Neovim providers."""
    success = True

    # Python venv
    py3_dir = NVIM_DIR / "py3"
    if py3_dir.exists() and not ARGS.upgrade:
        # Check if venv is healthy (python binary exists and works)
        py3_bin = py3_dir / "bin" / "python3"
        try:
            subprocess.check_output(
                [str(py3_bin), "-c", "import sys; print(sys.version)"],
                timeout=5,
                stderr=subprocess.STDOUT,
            )
            ok("nvim-py3: venv healthy")
        except (subprocess.CalledProcessError, FileNotFoundError, OSError):
            warn("nvim-py3: venv broken, recreating")
            if not ARGS.dry_run:
                shutil.rmtree(py3_dir)
                # Fall through to create it
    if not py3_dir.exists() or ARGS.upgrade:
        action = "upgrading" if py3_dir.exists() else "creating"
        info(f"nvim-py3: {action} venv")
        if not ARGS.dry_run:
            try:
                if not py3_dir.exists():
                    subprocess.run(
                        [sys.executable, "-m", "venv", str(py3_dir)],
                        check=True,
                        capture_output=True,
                    )
                pip = str(py3_dir / "bin" / "pip")
                subprocess.run(
                    [pip, "install", "-q", "--upgrade", "pip", "pynvim"], check=True
                )
                ok("nvim-py3: ready")
            except subprocess.CalledProcessError:
                warn(
                    "nvim-py3: venv creation failed"
                    " (install python3-venv on Debian/Ubuntu)"
                )
                success = False

    # Node.js
    node_dir = NVIM_DIR / "node"
    node_bin = node_dir / "bin" / "node"
    if node_bin.exists() and not ARGS.upgrade:
        ok("nvim-node: installed")
    elif not node_bin.exists():
        # Check if node is available system-wide
        if shutil.which("node"):
            info("nvim-node: using system node")
            if not ARGS.dry_run:
                npm = shutil.which("npm")
                if npm:
                    subprocess.run(
                        [npm, "install", "-g", "neovim"],
                        check=True,
                        capture_output=True,
                    )
                    ok("nvim-node: neovim package installed globally")
        else:
            info("nvim-node: downloading Node.js")
            if not ARGS.dry_run:
                if not _install_node(node_dir):
                    success = False
    elif ARGS.upgrade:
        info("nvim-node: upgrading neovim package")
        if not ARGS.dry_run:
            npm = (
                str(node_dir / "bin" / "npm")
                if node_bin.exists()
                else shutil.which("npm")
            )
            if npm:
                env = _node_env(node_dir) if node_bin.exists() else None
                subprocess.run(
                    [npm, "update", "-g", "neovim"],
                    check=True,
                    capture_output=True,
                    env=env,
                )
                ok("nvim-node: updated")

    return success


def _node_env(node_dir: Path) -> dict[str, str]:
    return {**os.environ, "PATH": f"{node_dir / 'bin'}:{os.environ.get('PATH', '')}"}


def _install_node(node_dir: Path) -> bool:
    """Download and install Node.js LTS to node_dir."""
    node_arch = "arm64" if ARCH == "arm64" else "x64"
    node_os = "darwin" if SYSTEM == "darwin" else "linux"

    # Get latest LTS version from nodejs.org
    try:
        with urllib.request.urlopen(
            "https://nodejs.org/dist/index.json", timeout=10
        ) as resp:
            versions = json.loads(resp.read())
        lts_version = None
        for v in versions:
            if v.get("lts"):
                lts_version = v["version"]
                break
        if not lts_version:
            err("Could not find Node.js LTS version")
            return False
    except Exception as exc:
        err(f"Failed to fetch Node.js versions: {exc}")
        return False

    tarball = f"node-{lts_version}-{node_os}-{node_arch}.tar.gz"
    url = f"https://nodejs.org/dist/{lts_version}/{tarball}"

    with tempfile.TemporaryDirectory() as td:
        dl_path = Path(td) / tarball
        if not download_file(url, dl_path):
            return False
        if not extract_dir_from_tar(dl_path, node_dir):
            return False

    npm = str(node_dir / "bin" / "npm")
    try:
        subprocess.run(
            [npm, "install", "-g", "neovim"],
            check=True,
            capture_output=True,
            env=_node_env(node_dir),
        )
    except subprocess.CalledProcessError as exc:
        err(f"npm install neovim failed: {exc}")
        return False

    ok("nvim-node: installed")
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
    all_names = set(BINARY_TOOLS) | set(GIT_DEPS) | {"nvim-env", "claude-code"}
    if requested:
        unknown = requested - all_names
        if unknown:
            err(f"Unknown tools: {', '.join(sorted(unknown))}")
            sys.exit(1)

    info(f"Platform: {PLATFORM_KEY}")
    if ARGS.dry_run:
        info("Dry run — no changes will be made")

    failures: list[str] = []

    # Phase 1: Bootstrap tools (gh, jq)
    for name in BOOTSTRAP_TOOLS:
        if requested and name not in requested:
            continue
        if not install_binary_tool(name, BINARY_TOOLS[name]):
            failures.append(name)

    # Phase 2: All other binary tools
    for name, tool in BINARY_TOOLS.items():
        if name in BOOTSTRAP_TOOLS:
            continue
        if requested and name not in requested:
            continue
        if not install_binary_tool(name, tool):
            failures.append(name)

    # Phase 3: Git dependencies
    for name, dep in GIT_DEPS.items():
        if requested and name not in requested:
            continue
        if not install_git_dep(name, dep):
            failures.append(name)

    # Phase 4: Neovim environment
    if not requested or "nvim-env" in requested:
        if not setup_nvim_env():
            failures.append("nvim-env")

    # Phase 5: Claude Code
    if not requested or "claude-code" in requested:
        if not install_claude_code():
            failures.append("claude-code")

    if failures:
        err(f"Failed: {', '.join(failures)}")
        sys.exit(1)
    info("Done!")


if __name__ == "__main__":
    main()
