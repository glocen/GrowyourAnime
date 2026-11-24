#!/usr/bin/env python3
"""Split a request file into one file per piece, losing nothing (tools/docs/split_requests.py).

`docs/asset-requests.md` and `docs/test-requests.md` hold every piece's whole record in one file each (17,054 and 4,931
lines on 2026-11-24). This splits one into a file per piece and leaves the old path as an index, so every reference of
the form "`docs/asset-requests.md`, AR12" still leads to the piece.

Run it from the game's folder:
    py tools/docs/split_requests.py split docs/asset-requests.md      write docs/requests/AR1.md ..., then the index
    py tools/docs/split_requests.py split docs/asset-requests.md --dry-run     say what it would write, write nothing
    py tools/docs/split_requests.py check docs/asset-requests.md      the index and its files still hold together
    py tools/docs/split_requests.py join docs/asset-requests.md       the reverse: the one file again, byte for byte
    py tools/docs/split_requests.py selftest

How nothing is lost:
- A piece is a level-2 heading whose title starts with an id (`## AR12. ...`, `## TR7. ...`) and every line up to the
  next level-2 heading. Its file holds exactly those lines, the heading raised to level 1. A code fence's lines are never
  read as headings.
- Everything else (the top of the file, a level-2 section with no id such as "Later, by ground") stays in the index, in
  its place, word for word.
- The index names each piece on one line in the old order, and holds the SHA-256 of the file as it was. `split` joins
  its own output again in memory before it writes anything and refuses to write unless the bytes match. `check` does the
  same from disk when the pieces haven't been edited since, and otherwise checks that every listed piece has its file.
- `split` refuses a file that is already an index, an id that appears twice, and a pieces folder that already holds one
  of the files it would write.

After a split, a piece's record is edited in its own file. The index's line for it carries the piece's status: the first
`**Status:**` line of the piece when it has one, cut short. Run `split ... --refresh` to rewrite those lines from the
files; it changes nothing else.

Needs only Python 3.9+. Free, no account, no network.
Exit codes: 0 fine, 1 a check failed or a split was refused, 2 wrong usage.
"""
from __future__ import annotations

import argparse
import hashlib
import re
import sys
import tempfile
from pathlib import Path

PIECE = re.compile(r"^## ((?:AR|TR)\d+)\. (.*)$")
SECTION = re.compile(r"^## ")
FENCE = re.compile(r"^\s*(```|~~~)")
ROW = re.compile(r"^- \[((?:AR|TR)\d+)\]\(([^)]+)\) · (.*)$")
MARK = "<!-- split_requests: an index. The pieces are in "
SUM = re.compile(r"^<!-- split_requests: sha256 of the one file ([0-9a-f]{64}), (\d+) pieces -->$")
STATUS_WIDTH = 160


class Refused(Exception):
    pass


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def cut(lines: list[str]) -> list[tuple[str, int, int]]:
    """The file as blocks: ("", start, end) for text that stays in the index, (id, start, end) for a piece."""
    starts: list[tuple[int, str]] = []
    fenced = False
    for i, line in enumerate(lines):
        if FENCE.match(line):
            fenced = not fenced
        elif not fenced and SECTION.match(line):
            m = PIECE.match(line.rstrip("\r\n"))
            starts.append((i, m.group(1) if m else ""))
    blocks: list[tuple[str, int, int]] = []
    if not starts or starts[0][0] > 0:
        blocks.append(("", 0, starts[0][0] if starts else len(lines)))
    for n, (i, ident) in enumerate(starts):
        end = starts[n + 1][0] if n + 1 < len(starts) else len(lines)
        blocks.append((ident, i, end))
    return blocks


def status_of(piece: list[str]) -> str:
    for line in piece:
        text = line.strip()
        if text.startswith("**Status:**") or text.startswith("- **Status:**"):
            text = text.split("**Status:**", 1)[1].strip()
            return text if len(text) <= STATUS_WIDTH else text[: STATUS_WIDTH - 1].rstrip() + "…"
    return "see the piece"


def raise_heading(line: str) -> str:
    return line[1:]  # "## AR1. x" -> "# AR1. x"


def lower_heading(line: str) -> str:
    return "#" + line


def plan(source: Path, pieces_dir: Path) -> tuple[str, dict[Path, str], bytes]:
    """The index's text and each piece's text, from the one file. Nothing is written."""
    raw = source.read_bytes()
    text = raw.decode("utf-8")
    if MARK in text:
        raise Refused(f"{source} is already an index")
    lines = text.splitlines(keepends=True)
    blocks = cut(lines)
    seen: set[str] = set()
    files: dict[Path, str] = {}
    index: list[str] = []
    rel = pieces_dir.relative_to(source.parent).as_posix() if pieces_dir.is_relative_to(source.parent) else pieces_dir.as_posix()
    count = sum(1 for ident, _, _ in blocks if ident)
    for n, (ident, start, end) in enumerate(blocks):
        body = lines[start:end]
        if not ident:
            index.extend(body)
            if n == 0:
                # The marker sits after the top text, so the file still opens on its own title.
                index.append(f"{MARK}`{rel}/`, one file each; edit a piece there. -->\n")
                index.append(f"<!-- split_requests: sha256 of the one file {sha(raw)}, {count} pieces -->\n")
            continue
        if ident in seen:
            raise Refused(f"{source}: {ident} is a heading twice")
        seen.add(ident)
        title = PIECE.match(body[0].rstrip("\r\n")).group(2)  # type: ignore[union-attr]
        files[pieces_dir / f"{ident}.md"] = raise_heading(body[0]) + "".join(body[1:])
        index.append(f"- [{ident}]({rel}/{ident}.md) · {title} · {end - start} lines · {status_of(body)}\n")
    if blocks and blocks[0][0]:
        raise Refused(f"{source} starts with a piece: it needs its title first")
    return "".join(index), files, raw


def rejoin(index_text: str, read) -> str:
    """The one file again, from an index's text and a way to read a piece's text by its link."""
    out: list[str] = []
    for line in index_text.splitlines(keepends=True):
        bare = line.rstrip("\r\n")
        if bare.startswith(MARK) or SUM.match(bare):
            continue
        m = ROW.match(bare)
        if m:
            piece = read(m.group(2))
            out.append(lower_heading(piece))
        else:
            out.append(line)
    return "".join(out)


def recorded(index_text: str) -> tuple[str, int] | None:
    for line in index_text.splitlines():
        m = SUM.match(line)
        if m:
            return m.group(1), int(m.group(2))
    return None


def do_split(source: Path, pieces_dir: Path, dry: bool) -> int:
    index_text, files, raw = plan(source, pieces_dir)
    clash = [p for p in files if p.exists()]
    if clash:
        raise Refused(f"{clash[0]} already exists: nothing written")
    by_link = {f"{pieces_dir.relative_to(source.parent).as_posix()}/{p.name}": t for p, t in files.items()}
    try:
        back = rejoin(index_text, lambda link: by_link[link]).encode("utf-8")
    except KeyError as link:
        raise Refused(f"{source}: a line outside the pieces already reads as an index line ({link}): nothing written")
    if back != raw:
        raise Refused(f"{source}: the joined pieces differ from the file (sha {sha(back)[:12]} against {sha(raw)[:12]}): nothing written")
    lines_before = raw.count(b"\n")
    print(f"{source}: {lines_before} lines -> an index of {index_text.count(chr(10))} lines and {len(files)} pieces in {pieces_dir}/")
    print(f"  joined again in memory: byte for byte the same (sha256 {sha(raw)[:16]}…)")
    if dry:
        biggest = sorted(files.items(), key=lambda kv: -kv[1].count("\n"))[:5]
        for path, text in biggest:
            print(f"  would write {path} ({text.count(chr(10))} lines)")
        print("  dry run: nothing written")
        return 0
    pieces_dir.mkdir(parents=True, exist_ok=True)
    for path, text in files.items():
        path.write_bytes(text.encode("utf-8"))
    source.write_bytes(index_text.encode("utf-8"))
    return do_check(source)


def do_check(source: Path) -> int:
    index_text = source.read_bytes().decode("utf-8")
    if MARK not in index_text:
        raise Refused(f"{source} isn't an index (not split yet)")
    was = recorded(index_text)
    rows = [ROW.match(l) for l in index_text.splitlines()]
    links = [m.group(2) for m in rows if m]
    ids = [m.group(1) for m in rows if m]
    bad = 0
    if len(set(ids)) != len(ids):
        print(f"FAIL {source}: an id is listed twice")
        bad += 1
    for ident, link in zip(ids, links):
        path = source.parent / link
        if not path.is_file():
            print(f"FAIL {source}: {ident}'s file {link} is missing")
            bad += 1
            continue
        first = path.read_text(encoding="utf-8").split("\n", 1)[0]
        if not first.startswith(f"# {ident}. "):
            print(f"FAIL {link}: its first line isn't `# {ident}. ...`")
            bad += 1
    folder = {p.name for link in links[:1] for p in (source.parent / link).parent.glob(f"{ids[0][:2]}*.md")}
    stray = sorted(folder - {Path(l).name for l in links})
    for name in stray:
        print(f"FAIL {source}: {name} is in the pieces folder and not in the index")
        bad += 1
    if bad:
        return 1
    if was and len(ids) < was[1]:
        print(f"FAIL {source}: the index lists {len(ids)} pieces, and the split made {was[1]}")
        return 1
    back = rejoin(index_text, lambda link: (source.parent / link).read_bytes().decode("utf-8")).encode("utf-8")
    same = was is not None and sha(back) == was[0]
    note = "byte for byte the file that was split" if same else "edited since the split (expected once work goes on)"
    print(f"ok {source}: {len(ids)} pieces, each with its file; joined, it is {note}")
    return 0


def do_join(source: Path, out: Path | None) -> int:
    index_text = source.read_bytes().decode("utf-8")
    if MARK not in index_text:
        raise Refused(f"{source} isn't an index")
    back = rejoin(index_text, lambda link: (source.parent / link).read_bytes().decode("utf-8")).encode("utf-8")
    target = out or source.with_suffix(".joined.md")
    target.write_bytes(back)
    was = recorded(index_text)
    same = was is not None and sha(back) == was[0]
    print(f"wrote {target}: {back.count(bytes([10]))} lines, {'byte for byte the file that was split' if same else 'with the edits made since the split'}")
    return 0


def do_refresh(source: Path) -> int:
    index_text = source.read_bytes().decode("utf-8")
    if MARK not in index_text:
        raise Refused(f"{source} isn't an index")
    out: list[str] = []
    changed = 0
    for line in index_text.splitlines(keepends=True):
        m = ROW.match(line.rstrip("\r\n"))
        if not m:
            out.append(line)
            continue
        piece = (source.parent / m.group(2)).read_text(encoding="utf-8").splitlines(keepends=True)
        title = piece[0].rstrip("\r\n").split(". ", 1)[1]
        new = f"- [{m.group(1)}]({m.group(2)}) · {title} · {len(piece)} lines · {status_of(piece)}\n"
        changed += new != line
        out.append(new)
    source.write_bytes("".join(out).encode("utf-8"))
    print(f"{source}: {changed} lines rewritten from the pieces")
    return 0


def selftest() -> int:
    sample = (
        "# Requests\n\nThe queue. `##` in a line isn't a heading.\n\n"
        "## AR1. Rook, the first\n\n**Status:** in progress (Modulo). " + "x" * 200 + "\n\n### A part\n\n```\n## AR9. not a heading, it's in a fence\n```\n\n"
        "## Later, by ground\n\nKept in the index.\n\n"
        "## AR2. The Shade · with a dot\n\nNo status line.\n"
        "## AR10. Last, no newline at the end"
    )
    fails = 0

    def check(name: str, ok: bool, more: str = "") -> None:
        nonlocal fails
        print(("ok   " if ok else "FAIL ") + name + (f": {more}" if more and not ok else ""))
        fails += not ok

    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        src = root / "docs" / "asset-requests.md"
        src.parent.mkdir()
        src.write_bytes(sample.encode("utf-8"))
        pieces = src.parent / "requests"
        check("a dry run writes nothing", do_split(src, pieces, True) == 0 and not pieces.exists() and src.read_bytes() == sample.encode())
        check("a split passes its own check", do_split(src, pieces, False) == 0)
        names = sorted(p.name for p in pieces.iterdir())
        check("one file per piece, the fenced heading not one", names == ["AR1.md", "AR10.md", "AR2.md"], str(names))
        index = src.read_text(encoding="utf-8")
        check("the section with no id stays in the index", "## Later, by ground\n\nKept in the index.\n" in index)
        check("the index opens on the file's own title", index.startswith("# Requests\n"))
        check("a long status is cut short", "…" in index and "x" * 170 not in index)
        check("a piece with no status says where to look", "· see the piece" in index)
        check("a piece opens on a level-1 heading", (pieces / "AR2.md").read_text(encoding="utf-8").startswith("# AR2. The Shade · with a dot\n"))
        joined = root / "joined.md"
        do_join(src, joined)
        check("joined, it is the file byte for byte", joined.read_bytes() == sample.encode("utf-8"))
        try:
            do_split(src, pieces, False)
            check("an index isn't split twice", False)
        except Refused:
            check("an index isn't split twice", True)
        with (pieces / "AR2.md").open("a", encoding="utf-8") as f:
            f.write("\n**Status:** done.\n")
        check("an edited piece still checks", do_check(src) == 0)
        do_refresh(src)
        check("refresh brings the new status to the index", "· done." in src.read_text(encoding="utf-8"))
        (pieces / "AR10.md").unlink()
        check("a missing piece fails the check", do_check(src) == 1)
        (pieces / "AR10.md").write_text("# AR10. Last\n", encoding="utf-8")
        (pieces / "AR77.md").write_text("# AR77. Stray\n", encoding="utf-8")
        check("a file the index doesn't list fails the check", do_check(src) == 1)

        twice = root / "docs" / "twice.md"
        twice.write_text("# T\n\n## TR1. a\n\n## TR1. b\n", encoding="utf-8")
        try:
            do_split(twice, root / "docs" / "t", False)
            check("an id that appears twice is refused", False)
        except Refused:
            check("an id that appears twice is refused, nothing written", not (root / "docs" / "t").exists())
        crlf = root / "docs" / "crlf.md"
        crlf.write_bytes(b"# T\r\n\r\n## TR3. a\r\nline\r\n## TR4. b\r\n")
        check("Windows line ends survive", do_split(crlf, root / "docs" / "c", False) == 0)
        do_join(crlf, root / "crlf.joined.md")
        check("and join back byte for byte", (root / "crlf.joined.md").read_bytes() == b"# T\r\n\r\n## TR3. a\r\nline\r\n## TR4. b\r\n")
    print(f"{'FAILED' if fails else 'passed'}: {fails} failed")
    return 1 if fails else 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Split a request file into one file per piece, losing nothing.")
    parser.add_argument("action", choices=["split", "check", "join", "selftest"])
    parser.add_argument("file", nargs="?", help="docs/asset-requests.md or docs/test-requests.md")
    parser.add_argument("--pieces", help="the pieces' folder (default: requests/ beside the file)")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--refresh", action="store_true", help="with split, on an index: rewrite each line's title, size and status")
    parser.add_argument("--out", help="with join: where to write the one file (default: <file>.joined.md)")
    args = parser.parse_args()
    if args.action == "selftest":
        return selftest()
    if not args.file:
        parser.error("name the file")
    source = Path(args.file)
    pieces = Path(args.pieces) if args.pieces else source.parent / "requests"
    try:
        if args.action == "split":
            return do_refresh(source) if args.refresh else do_split(source, pieces, args.dry_run)
        if args.action == "check":
            return do_check(source)
        return do_join(source, Path(args.out) if args.out else None)
    except Refused as why:
        print(f"refused: {why}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
