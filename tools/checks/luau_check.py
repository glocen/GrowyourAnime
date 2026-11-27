#!/usr/bin/env python3
"""Luau check without Studio (tools/checks/luau_check.py): what luau-lsp finds in a Rojo project, minus what's already known.

Run it from the game's folder:
    py tools/checks/luau_check.py                 new findings only; exit code 1 when there are any
    py tools/checks/luau_check.py src/server      the same, reporting only files under these paths
    py tools/checks/luau_check.py --all           every finding, known ones too
    py tools/checks/luau_check.py --freeze        write today's findings as the known list; it only shrinks

What it does: `rojo sourcemap`, so a require through the game tree resolves; Roblox's type definitions, fetched once for
each luau-lsp version into the work folder; then `luau-lsp analyze` over the whole source folder, every time, because an
edit in one file can break its callers in another.

A finding is known when the known list holds the same file and message. Line numbers are left out of the list, so a known
finding doesn't come back as new when the code above it moves. Freeze again after fixing some, and the list only shrinks.

It runs Luau's new type solver. Under the old one, luau-lsp 1.70.1 leaves `game`, `workspace` and every service unchecked
once a sourcemap is loaded, so a misspelled `Players.PlayerRemoving` passes (tested). `--old-solver` switches back, and
the two solvers word their findings differently, so each needs its own known list.

Needs `rojo` and `luau-lsp` on PATH: pin both in rokit.toml. Free, no account, no Studio, no key.
Exit codes: 0 nothing new, 1 new findings, 2 the check couldn't run.
"""
from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
import time
import urllib.request
from collections import Counter
from pathlib import Path
from typing import NamedTuple

# file, then the game-tree path in brackets when the sourcemap knows the file, then (line,column): Kind: message
FINDING = re.compile(r"^(?P<path>.+?)(?: \[[^\]]*\])?\((?P<line>\d+),(?P<col>\d+)\): (?P<kind>\w+): (?P<msg>.*)$")
LINE_IN_MESSAGE = re.compile(r"\bline \d+")  # "shadows previous declaration at line 40" moves with the code
DEFINITIONS_URL = "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/{version}/scripts/globalTypes.d.luau"
CHATTER = ("[INFO]", "[WARN] client does not allow")  # what the tool says on every run, with nothing to act on
NEW_SOLVER = "LuauSolverV2=true"
KNOWN_HEADER = (
    "# Findings luau_check.py already knows, one per line: file, kind, message. Written by --freeze, never by hand.\n"
    "# A finding listed here isn't reported. Fix some, freeze again, and this list only shrinks.\n"
)


class Finding(NamedTuple):
    path: str
    line: int
    col: int
    kind: str
    msg: str

    def key(self) -> str:
        return f"{self.path}: {self.kind}: {LINE_IN_MESSAGE.sub('line N', self.msg)}"

    def show(self) -> str:
        return f"{self.path}({self.line},{self.col}): {self.kind}: {self.msg}"


class CheckError(Exception):
    """The check itself couldn't run: a tool is missing, or one of them failed."""


def run(cmd: list[str], cwd: Path, timeout: int = 300) -> tuple[int, str]:
    """One command, with its two outputs read as one text: luau-lsp writes its findings to the error stream."""
    try:
        done = subprocess.run(cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=timeout,
                              encoding="utf-8", errors="replace")
    except FileNotFoundError:
        raise CheckError(f"`{cmd[0]}` isn't on PATH. Pin it in rokit.toml and run `rokit install`.") from None
    except subprocess.TimeoutExpired:
        raise CheckError(f"`{cmd[0]}` didn't finish in {timeout} seconds.") from None
    return done.returncode, done.stdout or ""


def tool_version(luau_lsp: str, root: Path) -> str:
    _, text = run([luau_lsp, "--version"], root, 30)
    found = re.search(r"\d+\.\d+\.\d+", text)
    if not found:
        raise CheckError(f"`{luau_lsp} --version` gave no version: {text.strip()[:200]}")
    return found.group(0)


def definitions(work: Path, version: str) -> Path:
    """Roblox's types for this luau-lsp version: the tagged file never changes, so one fetch lasts until the pin moves."""
    path = work / f"globalTypes-{version}.d.luau"
    if path.is_file() and path.stat().st_size > 0:
        return path
    url = DEFINITIONS_URL.format(version=version)
    part = work / f"globalTypes-{version}.{os.getpid()}.part"
    try:
        with urllib.request.urlopen(url, timeout=60) as reply:
            part.write_bytes(reply.read())
        part.replace(path)
    except OSError as e:
        part.unlink(missing_ok=True)
        raise CheckError(f"Couldn't fetch Roblox's type definitions from {url} ({e}). "
                         f"Save that file by hand and pass it with --definitions.") from None
    return path


def relative(raw: str, root: Path) -> str:
    """luau-lsp prints full paths with a small drive letter: make them the project's own, with forward slashes."""
    if os.path.isabs(raw):
        try:
            raw = os.path.relpath(raw, root)
        except ValueError:  # another drive
            pass
    return raw.replace("\\", "/")


def parse(text: str, root: Path) -> tuple[list[Finding], list[str]]:
    """Findings, and the lines that were none: a message's extra lines join their finding, the rest are the tool's notes."""
    findings: list[Finding] = []
    notes: list[str] = []
    for line in text.splitlines():
        m = FINDING.match(line)
        if m:
            findings.append(Finding(relative(m["path"], root), int(m["line"]), int(m["col"]), m["kind"], m["msg"].strip()))
        elif line.strip() and findings:
            last = findings[-1]
            findings[-1] = last._replace(msg=f"{last.msg} | {line.strip()}")
        elif line.strip() and not line.startswith(CHATTER):
            notes.append(line.strip())
    return sorted(set(findings)), notes  # a module reached through two requires can report twice


def analyse(root: Path, *, project: str = "default.project.json", source: str = "src", work: Path | None = None,
            luau_lsp: str = "luau-lsp", rojo: str = "rojo", ignore: tuple[str, ...] = (),
            flags: tuple[str, ...] = (NEW_SOLVER,), definitions_file: str | None = None) -> tuple[list[Finding], list[str], float]:
    """Every finding in `source`, the tool's notes, and the seconds it took. `root` is the folder holding the project file."""
    root = root.resolve()
    work = (work or root / "build" / "scratch" / "luau-check").resolve()
    work.mkdir(parents=True, exist_ok=True)
    start = time.monotonic()
    defs = Path(definitions_file).resolve() if definitions_file else definitions(work, tool_version(luau_lsp, root))
    if not defs.is_file():
        raise CheckError(f"No definitions file at {defs}.")
    sourcemap = work / f"sourcemap-{os.getpid()}.json"  # one per run, so two sessions never share a half-written file
    try:
        code, text = run([rojo, "sourcemap", project, "-o", str(sourcemap)], root, 120)
        if code != 0 or not sourcemap.is_file():
            raise CheckError(f"`rojo sourcemap {project}` failed: {text.strip()[:400]}")
        cmd = [luau_lsp, "analyze", "--platform=roblox", f"--sourcemap={sourcemap}", f"--definitions=@roblox={defs}"]
        cmd += [f"--ignore={glob}" for glob in ignore] + [f"--flag:{flag}" for flag in flags]
        code, text = run(cmd + [source], root)
    finally:
        sourcemap.unlink(missing_ok=True)
    findings, notes = parse(text, root)
    if code not in (0, 1):  # 0 is clean and 1 is findings. Anything else is a crash, and what it printed is only a part
        raise CheckError(f"`luau-lsp analyze` stopped with code {code} after {len(findings)} findings, so the list is "
                         f"incomplete. Run it again, and if it repeats, try --old-solver. {' / '.join(notes)[:300]}")
    if code == 1 and not findings:
        raise CheckError(f"`luau-lsp analyze` failed: {' / '.join(notes)[:600]}")
    return findings, notes, time.monotonic() - start


def read_known(path: Path) -> Counter:
    if not path.is_file():
        return Counter()
    lines = path.read_text(encoding="utf-8").splitlines()
    return Counter(line for line in lines if line.strip() and not line.startswith("#"))


def write_known(path: Path, findings: list[Finding]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    body = "".join(f"{key}\n" for key in sorted(f.key() for f in findings))
    path.write_text(KNOWN_HEADER + body, encoding="utf-8", newline="\n")


def split_new(findings: list[Finding], known: Counter) -> tuple[list[str], int, int]:
    """The lines to report, how many findings they stand for, and how many known ones are gone."""
    groups: dict[str, list[Finding]] = {}
    for f in findings:
        groups.setdefault(f.key(), []).append(f)
    lines: list[str] = []
    new = 0
    for key, group in groups.items():
        extra = len(group) - known[key]
        if extra <= 0:
            continue
        new += extra
        if known[key] == 0:
            lines += [f.show() for f in group]
        else:  # the same message again in the same file: which of them is the new one can't be told
            at = ", ".join(str(f.line) for f in group[:8]) + (", ..." if len(group) > 8 else "")
            lines.append(f"{key}  [{len(group)} now, {known[key]} known, at lines {at}]")
    now = Counter(f.key() for f in findings)
    gone = sum(max(0, count - now[key]) for key, count in known.items())
    return lines, new, gone


def under(path: str, only: list[str]) -> bool:
    return not only or any(path == o or path.startswith(o + "/") for o in only)


def main() -> int:
    ap = argparse.ArgumentParser(description="Type-check a Rojo project's Luau without Studio, and report only what's new.")
    ap.add_argument("paths", nargs="*", help="report only findings in these files or folders (the whole source is still checked)")
    ap.add_argument("--all", action="store_true", help="report every finding, known ones too")
    ap.add_argument("--freeze", action="store_true", help="write today's findings as the known list; refused while one is new")
    ap.add_argument("--known", default="tools/checks/luau-known.txt", help="the known list, kept in the game's repo")
    ap.add_argument("--project", default="default.project.json")
    ap.add_argument("--source", default="src")
    ap.add_argument("--work", default="build/scratch/luau-check", help="a gitignored folder for the sourcemap and the definitions")
    ap.add_argument("--luau-lsp", default="luau-lsp")
    ap.add_argument("--rojo", default="rojo")
    ap.add_argument("--ignore", action="append", default=[], metavar="GLOB", help="files whose findings luau-lsp drops; repeatable")
    ap.add_argument("--flag", action="append", default=[], metavar="NAME=VALUE", help="one more Luau flag for the analysis; repeatable")
    ap.add_argument("--old-solver", action="store_true", help="the old type solver: services go unchecked under a sourcemap")
    ap.add_argument("--definitions", help="a globalTypes.d.luau already on disk, instead of fetching one")
    args = ap.parse_args()
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    root = Path.cwd()
    if not (root / args.project).is_file():
        print(f"luau check: no {args.project} here. Run it from the game's folder.")
        return 2
    flags = tuple(args.flag) + (() if args.old_solver else (NEW_SOLVER,))
    try:
        findings, notes, seconds = analyse(root, project=args.project, source=args.source, work=root / args.work,
                                           luau_lsp=args.luau_lsp, rojo=args.rojo, ignore=tuple(args.ignore),
                                           flags=flags, definitions_file=args.definitions)
    except CheckError as e:
        print(f"luau check: it couldn't run. {e}")
        return 2
    if args.freeze:
        # Only shrinks (Turing, docs/turing.md): a fixed finding leaves the list, a new one never enters it. A first
        # freeze, with no list yet, takes everything.
        path = root / args.known
        known = read_known(path)
        if path.is_file():
            lines, new, _ = split_new(findings, known)
            if new:
                print(f"luau check: not frozen. {new} new findings would enter {args.known}, and the list only "
                      f"shrinks: fix them first ({seconds:.1f} s)")
                print("\n".join(lines))
                return 1
        write_known(path, findings)
        print(f"luau check: {len(findings)} findings frozen into {args.known}, from {sum(known.values())} "
              f"({seconds:.1f} s)")
        return 0
    only = [p.replace("\\", "/").rstrip("/") for p in args.paths]
    seen = [f for f in findings if under(f.path, only)]
    if args.all:
        print(f"luau check: {len(seen)} findings ({seconds:.1f} s)")
        if seen:
            print("\n".join(f.show() for f in seen))
        return 1 if seen else 0
    lines, new, gone = split_new(seen, read_known(root / args.known))
    if only:  # a count of what's gone only means something over the whole source
        print(f"luau check: {new} new under {', '.join(only)} ({seconds:.1f} s)")
    else:
        print(f"luau check: {new} new, {len(findings) - new} known, {gone} gone since the freeze ({seconds:.1f} s)")
    if lines:
        print("\n".join(lines))
    for note in notes[:5]:
        print(f"note: {note}")
    return 1 if new else 0


if __name__ == "__main__":
    sys.exit(main())
