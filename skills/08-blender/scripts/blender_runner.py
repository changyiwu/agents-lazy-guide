#!/usr/bin/env python3
"""Find and run the installed Blender executable with machine-readable output."""

from __future__ import annotations

import argparse
import glob
import json
import locale
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from typing import Iterable


def emit(payload: dict) -> None:
    # ASCII-safe JSON avoids Windows cp950 failures; JSON parsers restore Unicode.
    print(json.dumps(payload, ensure_ascii=True, indent=2))


def decode_output(value: bytes | str | None) -> str:
    if value is None:
        return ""
    if isinstance(value, str):
        return value
    encodings = ("utf-8", locale.getpreferredencoding(False))
    for encoding in dict.fromkeys(encodings):
        try:
            return value.decode(encoding)
        except UnicodeDecodeError:
            continue
    return value.decode("utf-8", errors="replace")


def version_key(path: Path) -> tuple[int, ...]:
    matches = re.findall(r"(\d+)(?:\.(\d+))?", str(path))
    if not matches:
        return (0,)
    major, minor = matches[-1]
    return int(major), int(minor or 0)


def candidate_paths() -> Iterable[Path]:
    override = os.environ.get("BLENDER_PATH")
    if override:
        yield Path(override).expanduser()

    found = shutil.which("blender")
    if found:
        yield Path(found)

    if os.name == "nt":
        roots = {
            os.environ.get("ProgramFiles"),
            os.environ.get("ProgramW6432"),
            os.environ.get("LOCALAPPDATA"),
        }
        patterns = (
            ("Blender Foundation", "Blender *", "blender.exe"),
            ("Programs", "Blender Foundation", "Blender *", "blender.exe"),
        )
        for root in filter(None, roots):
            for parts in patterns:
                pattern = str(Path(root).joinpath(*parts))
                for match in glob.glob(pattern):
                    yield Path(match)
    elif sys.platform == "darwin":
        yield Path("/Applications/Blender.app/Contents/MacOS/Blender")
        yield Path.home() / "Applications/Blender.app/Contents/MacOS/Blender"
    else:
        yield Path("/usr/bin/blender")
        yield Path("/usr/local/bin/blender")
        for match in glob.glob("/opt/blender*/blender"):
            yield Path(match)


def find_blender(explicit: str | None = None) -> tuple[Path | None, list[str]]:
    raw = [Path(explicit).expanduser()] if explicit else list(candidate_paths())
    unique: dict[str, Path] = {}
    for path in raw:
        try:
            resolved = path.resolve()
        except OSError:
            resolved = path
        if resolved.is_file():
            unique[str(resolved).lower()] = resolved
    candidates = sorted(unique.values(), key=version_key, reverse=True)
    return (candidates[0] if candidates else None), [str(p) for p in candidates]


def creation_flags() -> int:
    return getattr(subprocess, "CREATE_NO_WINDOW", 0) if os.name == "nt" else 0


def detect(args: argparse.Namespace) -> int:
    blender, candidates = find_blender(args.blender)
    if blender is None:
        emit({
            "ok": False,
            "error": "blender_not_found",
            "hint": "Install Blender or set BLENDER_PATH to the executable.",
            "candidates": [],
        })
        return 2
    try:
        result = subprocess.run(
            [str(blender), "--version"],
            capture_output=True,
            timeout=20,
            creationflags=creation_flags(),
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        emit({"ok": False, "error": "version_check_failed", "message": str(exc), "path": str(blender)})
        return 3
    version_output = decode_output(result.stdout or result.stderr)
    first_line = version_output.splitlines()
    emit({
        "ok": result.returncode == 0,
        "path": str(blender),
        "version": first_line[0] if first_line else "unknown",
        "candidates": candidates,
    })
    return 0 if result.returncode == 0 else result.returncode


def run_blender(args: argparse.Namespace) -> int:
    blender, candidates = find_blender(args.blender)
    script = Path(args.script).expanduser().resolve()
    blend = Path(args.blend).expanduser().resolve() if args.blend else None
    if blender is None:
        emit({"ok": False, "error": "blender_not_found", "candidates": candidates})
        return 2
    if not script.is_file():
        emit({"ok": False, "error": "script_not_found", "script": str(script)})
        return 2
    if blend is not None and not blend.is_file():
        emit({"ok": False, "error": "blend_not_found", "blend": str(blend)})
        return 2

    command = [str(blender), "--background"]
    if not args.allow_autoexec:
        command.append("--disable-autoexec")
    if blend is None:
        command.append("--factory-startup")
    else:
        command.append(str(blend))
    command.extend(["--python-exit-code", "1", "--python", str(script)])
    script_args = list(args.script_args)
    if script_args and script_args[0] == "--":
        script_args = script_args[1:]
    if script_args:
        command.extend(["--", *script_args])

    try:
        result = subprocess.run(
            command,
            capture_output=True,
            timeout=args.timeout,
            creationflags=creation_flags(),
            check=False,
        )
        stdout = decode_output(result.stdout)
        stderr = decode_output(result.stderr)
        returncode = result.returncode
        timed_out = False
    except subprocess.TimeoutExpired as exc:
        stdout = decode_output(exc.stdout)
        stderr = decode_output(exc.stderr)
        returncode = 124
        timed_out = True
    except OSError as exc:
        emit({"ok": False, "error": "launch_failed", "message": str(exc), "path": str(blender)})
        return 3

    log_path = None
    if args.log:
        log = Path(args.log).expanduser().resolve()
        log.parent.mkdir(parents=True, exist_ok=True)
        log.write_text(
            "COMMAND\n" + subprocess.list2cmdline(command) + "\n\nSTDOUT\n" + stdout + "\nSTDERR\n" + stderr,
            encoding="utf-8",
        )
        log_path = str(log)

    emit({
        "ok": returncode == 0,
        "returncode": returncode,
        "timed_out": timed_out,
        "blender": str(blender),
        "script": str(script),
        "blend": str(blend) if blend else None,
        "autoexec": args.allow_autoexec,
        "log": log_path,
        "stdout_tail": stdout.splitlines()[-30:],
        "stderr_tail": stderr.splitlines()[-30:],
    })
    return 0 if returncode == 0 else returncode


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    detect_parser = subparsers.add_parser("detect", help="Find Blender and report its version.")
    detect_parser.add_argument("--blender", help="Explicit Blender executable path.")
    detect_parser.set_defaults(handler=detect)

    run_parser = subparsers.add_parser("run", help="Run a Python script in Blender background mode.")
    run_parser.add_argument("--blender", help="Explicit Blender executable path.")
    run_parser.add_argument("--script", required=True, help="Python script executed inside Blender.")
    run_parser.add_argument("--blend", help="Optional input .blend file. It is not overwritten by the runner.")
    run_parser.add_argument("--timeout", type=int, default=900, help="Timeout in seconds (default: 900).")
    run_parser.add_argument("--log", help="Write complete Blender output to this UTF-8 log file.")
    run_parser.add_argument("--allow-autoexec", action="store_true", help="Allow embedded scripts and drivers in .blend files.")
    run_parser.add_argument("script_args", nargs=argparse.REMAINDER, help="Arguments after -- are passed to the Blender script.")
    run_parser.set_defaults(handler=run_blender)
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    if getattr(args, "timeout", 1) <= 0:
        parser.error("--timeout must be greater than zero")
    return args.handler(args)


if __name__ == "__main__":
    raise SystemExit(main())
