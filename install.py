#!/usr/bin/env python3
"""Symlink dotfiles into $HOME (replaces GNU stow).

Symlinks individual leaf files only, creating parent directories as needed.
Uses relative symlink targets for portability. No third-party dependencies.
"""

from __future__ import annotations

import argparse
import fnmatch
import os
import platform
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

DOTFILES_DIR = Path(__file__).resolve().parent

PACKAGES: dict[str, str] = {
    "bash": "all",
    "env": "all",
    "git": "all",
    "python": "all",
    "scripts": "all",
    "tmux": "all",
    "vim": "all",
    "zsh": "all",
    "mac": "darwin",
    "terminal": "all",
}

# --- Output helpers -----------------------------------------------------------

_USE_COLOR = sys.stdout.isatty()


def _color(code: str, text: str) -> str:
    if _USE_COLOR:
        return f"\033[{code}m{text}\033[0m"
    return text


def ok(msg: str) -> None:
    print(f"  {_color('32', '[ OK ]')} {msg}")


def skip(msg: str) -> None:
    print(f"  {_color('33', '[SKIP]')} {msg}")


def backup_msg(msg: str) -> None:
    print(f"  {_color('36', '[BACK]')} {msg}")


def fail(msg: str) -> None:
    print(f"  {_color('31', '[FAIL]')} {msg}")


# --- Ignore patterns ----------------------------------------------------------


def load_ignore_patterns(dotfiles_dir: Path) -> list[str]:
    ignore_file = dotfiles_dir / ".dotfilesignore"
    if not ignore_file.exists():
        return []
    patterns: list[str] = []
    for line in ignore_file.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            patterns.append(line)
    return patterns


def is_ignored(rel_path: Path, patterns: list[str]) -> bool:
    rel_str = str(rel_path)
    parts = rel_path.parts
    for pat in patterns:
        # Match against the full relative path
        if fnmatch.fnmatch(rel_str, pat):
            return True
        # Match against each individual component
        for part in parts:
            if fnmatch.fnmatch(part, pat):
                return True
        # Match against each suffix subpath (e.g. "db/dhist" within "a/b/db/dhist")
        for i in range(len(parts)):
            subpath = str(Path(*parts[i:]))
            if fnmatch.fnmatch(subpath, pat):
                return True
    return False


# --- File discovery -----------------------------------------------------------


def discover_files(pkg_dir: Path, patterns: list[str]) -> list[Path]:
    files: list[Path] = []
    for p in sorted(pkg_dir.rglob("*")):
        if not p.is_file() or p.is_symlink():
            continue
        rel = p.relative_to(pkg_dir)
        if is_ignored(rel, patterns):
            continue
        files.append(p)
    return files


# --- Conflict handling --------------------------------------------------------


def prompt_conflict(dst: Path) -> str:
    """Prompt user for conflict resolution: skip, overwrite, or backup+overwrite."""
    while True:
        answer = (
            input(f"  Conflict: {dst}\n  [s]kip, [o]verwrite, [b]ackup+overwrite? ")
            .strip()
            .lower()
        )
        if answer in ("s", "o", "b"):
            return answer
        print("  Please enter s, o, or b.")


def backup_file(dst: Path, backup_root: Path, target_dir: Path) -> None:
    rel = dst.relative_to(target_dir)
    backup_path = backup_root / rel
    backup_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(str(dst), str(backup_path))
    backup_msg(f"{dst} -> {backup_path}")


# --- Core linking -------------------------------------------------------------


def link_file(
    src: Path,
    dst: Path,
    *,
    dry_run: bool,
    force: bool,
    verbose: bool,
    backup_root: Path,
    target_dir: Path,
    errors: list[str],
) -> None:
    # Guard: src must resolve to within the dotfiles repo
    try:
        resolved = src.resolve()
        if not resolved.is_relative_to(DOTFILES_DIR):
            fail(f"{src} resolves outside repo")
            errors.append(str(src))
            return
    except OSError as exc:
        fail(f"{src}: {exc}")
        errors.append(str(src))
        return

    rel_target = os.path.relpath(src, dst.parent)
    display = f"{dst} -> {rel_target}"

    try:
        # Case 1: broken symlink
        if dst.is_symlink() and not dst.exists():
            if dry_run:
                ok(f"(would fix broken link) {display}")
                return
            dst.unlink()
            dst.symlink_to(rel_target)
            ok(display)
            return

        # Case 2: nothing exists -> create
        if not dst.exists() and not dst.is_symlink():
            if dry_run:
                ok(f"(would link) {display}")
                return
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.symlink_to(rel_target)
            ok(display)
            return

        # Case 3: already correct
        try:
            if src.samefile(dst):
                if verbose:
                    skip(f"{dst} (already linked)")
                return
        except OSError:
            pass

        # Case 4: symlink pointing elsewhere OR regular file conflict
        if dry_run:
            label = "would relink" if dst.is_symlink() else "would overwrite"
            ok(f"({label}) {display}")
            return

        if force or not sys.stdin.isatty():
            if dst.is_symlink():
                dst.unlink()
            else:
                backup_file(dst, backup_root, target_dir)
            dst.symlink_to(rel_target)
            ok(display)
        else:
            choice = prompt_conflict(dst)
            if choice == "s":
                skip(f"{dst} (user skipped)")
            elif choice == "o":
                if dst.is_dir() and not dst.is_symlink():
                    shutil.rmtree(dst)
                else:
                    dst.unlink()
                dst.symlink_to(rel_target)
                ok(display)
            elif choice == "b":
                backup_file(dst, backup_root, target_dir)
                dst.symlink_to(rel_target)
                ok(display)

    except OSError as exc:
        fail(f"{dst}: {exc}")
        errors.append(str(dst))


# --- Package installation -----------------------------------------------------


def install_package(
    name: str,
    target_dir: Path,
    patterns: list[str],
    *,
    dry_run: bool,
    force: bool,
    verbose: bool,
    backup_root: Path,
    errors: list[str],
) -> int:
    pkg_dir = DOTFILES_DIR / name
    if not pkg_dir.is_dir():
        fail(f"package directory not found: {name}")
        errors.append(name)
        return 0

    files = discover_files(pkg_dir, patterns)
    if verbose:
        print(f"\n  {name}: {len(files)} file(s)")

    for src in files:
        rel = src.relative_to(pkg_dir)
        dst = target_dir / rel
        link_file(
            src,
            dst,
            dry_run=dry_run,
            force=force,
            verbose=verbose,
            backup_root=backup_root,
            target_dir=target_dir,
            errors=errors,
        )

    return len(files)


# --- Unlink -------------------------------------------------------------------


def unlink_package(
    name: str,
    target_dir: Path,
    patterns: list[str],
    *,
    dry_run: bool,
    verbose: bool,
) -> int:
    pkg_dir = DOTFILES_DIR / name
    if not pkg_dir.is_dir():
        return 0

    files = discover_files(pkg_dir, patterns)
    removed = 0
    for src in files:
        rel = src.relative_to(pkg_dir)
        dst = target_dir / rel
        if not dst.is_symlink():
            continue
        try:
            if not src.samefile(dst):
                continue
        except OSError:
            continue
        if dry_run:
            ok(f"(would unlink) {dst}")
        else:
            dst.unlink()
            ok(f"unlinked {dst}")
        removed += 1

    return removed


# --- Main ---------------------------------------------------------------------


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Symlink dotfiles into $HOME (replaces GNU stow)",
    )
    parser.add_argument(
        "packages",
        nargs="*",
        help="Packages to install (default: all platform-appropriate)",
    )
    parser.add_argument(
        "-n",
        "--dry-run",
        action="store_true",
        help="Show what would be done without making changes",
    )
    parser.add_argument(
        "-f",
        "--force",
        action="store_true",
        help="Overwrite conflicts without prompting (backup + overwrite)",
    )
    parser.add_argument(
        "-t",
        "--target",
        type=Path,
        default=Path.home(),
        help="Target directory (default: $HOME)",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Verbose output",
    )
    parser.add_argument(
        "--unlink",
        action="store_true",
        help="Remove symlinks pointing into the dotfiles repo",
    )
    args = parser.parse_args()

    current_platform = platform.system().lower()
    patterns = load_ignore_patterns(DOTFILES_DIR)
    errors: list[str] = []
    total_files = 0

    # Determine which packages to operate on
    if args.packages:
        selected = args.packages
    else:
        selected = [
            name
            for name, plat in PACKAGES.items()
            if plat == "all" or plat == current_platform
        ]

    if args.dry_run:
        print("Dry run -- no changes will be made\n")

    # Unlink mode: remove symlinks and exit
    if args.unlink:
        removed = 0
        for name in selected:
            if name not in PACKAGES:
                fail(f"unknown package: {name}")
                continue
            removed += unlink_package(
                name,
                args.target,
                patterns,
                dry_run=args.dry_run,
                verbose=args.verbose,
            )
        print(f"\n  {removed} symlink(s) {'would be ' if args.dry_run else ''}removed")
        return

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S")
    backup_root = DOTFILES_DIR / ".backups" / timestamp

    for name in selected:
        if name not in PACKAGES:
            fail(f"unknown package: {name}")
            errors.append(name)
            continue

        required_platform = PACKAGES[name]
        if required_platform != "all" and required_platform != current_platform:
            skip(f"{name} (requires {required_platform}, current: {current_platform})")
            continue

        total_files += install_package(
            name,
            args.target,
            patterns,
            dry_run=args.dry_run,
            force=args.force,
            verbose=args.verbose,
            backup_root=backup_root,
            errors=errors,
        )

    # Summary
    print(f"\n  {total_files} file(s) processed across {len(selected)} package(s)")
    if errors:
        fail(f"{len(errors)} error(s):")
        for e in errors:
            print(f"    - {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
