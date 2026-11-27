"""The reference guard (Turing, docs/turing.md, "The floor, kept by tools"): a pre-commit check that keeps another
game's frames out of git.

Reference footage and shipped games' frames stay internal (AGENTS.md, rule 3): they live in build/reference/, which
git ignores. A sheet that sets our build beside one of them is written there too. This refuses a commit that stages,
anywhere else:
- a picture or a clip named `*_beside*`, unless its name says it's beside our own target (`_beside_target`);
- a folder named for a reference game, or a picture or a clip whose name holds one (the names in
  tools/checks/reference-games.txt, one a line: the folders of build/reference/ that hold a game's frames).
Docs and code may name a game (AGENTS.md: internal docs may), so only folders and media files are read.
Run by tools/git-hooks/pre-commit (git config core.hooksPath tools/git-hooks), or by hand:
    py tools/checks/reference_guard.py            the staged files
    py tools/checks/reference_guard.py PATH...    these paths
Exit 1 with each path and why; 0 when clean.
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GAMES = ROOT / "tools" / "checks" / "reference-games.txt"
MEDIA = {".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".tga", ".mp4", ".mov", ".webm", ".mkv", ".avi"}
HOME = "build/reference/"


def games() -> list[str]:
    lines = GAMES.read_text(encoding="utf-8").splitlines() if GAMES.is_file() else []
    return [line.strip().lower() for line in lines if line.strip() and not line.startswith("#")]


def why(path: str, names: list[str]) -> str | None:
    p = path.replace("\\", "/")
    if p.startswith(HOME):
        return None
    parts = p.lower().split("/")
    media = Path(p).suffix.lower() in MEDIA
    stem = Path(p).stem.lower()
    if media and "_beside" in stem and "_beside_target" not in stem:
        return f"a beside sheet belongs in {HOME}"
    for name in names:
        if name in parts[:-1]:
            return f"a folder named for the reference game '{name}' belongs in {HOME}"
        if media and (name in stem or name.replace("-", "_") in stem):
            return f"a picture named for the reference game '{name}' belongs in {HOME}"
    return None


def staged() -> list[str]:
    out = subprocess.run(["git", "diff", "--cached", "--name-only", "--diff-filter=ACMR", "-z"], cwd=ROOT,
                         capture_output=True, check=True).stdout
    return [p for p in out.decode("utf-8", "replace").split("\0") if p]


def main(argv: list[str]) -> int:
    paths = argv or staged()
    names = games()
    refused = [(p, r) for p in paths if (r := why(p, names))]
    for p, r in refused:
        print(f"reference guard: {p}: {r}")
    if refused:
        print("reference guard: commit refused. Move these into build/reference/ (git ignores it) and unstage them.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
