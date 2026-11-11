"""instruction_lint.py - SessionStart hook (matcher startup|clear): stale or broken instructions, said once.

Reads the instruction files named in config/hooks.json, "instruction_lint", and reports:
  - paths they name that don't exist: `backtick` paths and markdown links whose first folder is one of the repo's own
    top-level entries, and the rules' `paths:` globs that match no file (generated places such as build/ are skipped,
    config "may_be_absent");
  - lines matching a stale-pattern list (config "stale_patterns_file": id, regex, optional except rules, why). No list
    named: that check is off. A list named but missing or unreadable is a finding itself, and the other checks still run;
  - files over their size cap.
Prints nothing when clean. Otherwise the session gets the list as context, headed by a line saying who owns the wording (so
no teammate "fixes" another's file), and the director sees a one-line count.

`py instruction_lint.py --report [--scope "<glob>" ...]` prints every finding as plain text, uncapped; --scope adds files to
the stale-pattern scan only. It exits 0 when clean, 1 with findings and 2 when the lint itself failed: a failed run is
never a clean one.
"""

from __future__ import annotations

import fnmatch
import json
import os
import re
import sys
from pathlib import Path

_TICK = re.compile(r"`([^`\n]+)`")
_LINK = re.compile(r"\]\(([^)\s]+)\)")
_SKIP = re.compile(r"[<>{}$%|]|YYYY|\.\.\.|\bNN\b|^https?:|^mailto:|^#")
_DRIVE = re.compile(r"^[A-Za-z]:[\\/]")


def expand(root: Path, globs: list) -> list:
    out, seen = [], set()
    for g in globs:
        for p in sorted(root.glob(g)):
            if p.is_file() and p not in seen:
                seen.add(p)
                out.append(p)
    return out


def rel(root: Path, p: Path) -> str:
    try:
        return str(p.relative_to(root)).replace("\\", "/")
    except ValueError:
        return str(p)


def clean(tok: str, kind: str) -> str:
    t = tok.strip().strip("\"'()[]{},;")
    if kind == "link":
        t = t.split("#", 1)[0]
    t = re.sub(r":\d+(-\d+)?$", "", t)
    return re.sub(r"[.,;:]+$", "", t)


def frontmatter_globs(lines: list) -> list:
    out, inside, in_paths = [], False, False
    for n, line in enumerate(lines, 1):
        if n == 1 and line.strip() != "---":
            return []
        if n > 1 and line.strip() == "---":
            break
        if re.match(r"^paths\s*:", line):
            in_paths = True
            continue
        m = re.match(r"^\s*-\s*[\"']?([^\"']+?)[\"']?\s*$", line)
        if in_paths and m:
            out.append((n, m.group(1)))
        elif not line.startswith((" ", "\t")):
            in_paths = False
    return out


class Lint:
    def __init__(self, lib, conf: dict):
        self.lib, self.conf = lib, conf
        self.root = lib.project_root()
        self.top = {p.name for p in self.root.iterdir() if p.name != ".git"}
        self.absent_ok = [a.replace("\\", "/") for a in conf.get("may_be_absent", [])]
        self.ignore = set(conf.get("ignore_paths", []))
        self.findings: list = []

    def repo_path(self, t: str) -> bool:
        t2 = t.replace("\\", "/")
        if re.match(r"^[A-Za-z]:/", t2) or t2.startswith(("./", "../")):
            return True
        first = t2.split("/", 1)[0]
        return first in self.top and ("/" in t2 or "." in first)

    def exists(self, t: str, here: Path) -> bool:
        t2 = t.replace("\\", "/")
        if re.match(r"^[A-Za-z]:/", t2):
            return Path(t2).exists()
        if any(ch in t2 for ch in "*?["):
            return any(self.root.glob(t2.lstrip("/"))) or any(here.parent.glob(t2))
        return (self.root / t2).exists() or (here.parent / t2).exists()

    def check_paths(self, path: Path, lines: list) -> None:
        name = rel(self.root, path)
        seen = set()
        for n, line in enumerate(lines, 1):
            cands = []
            for m in _TICK.finditer(line):
                inner = m.group(1).strip()  # a Windows path may hold spaces, so one that starts at a drive is one path
                cands += [(inner, "tick")] if _DRIVE.match(inner) else [(c, "tick") for c in inner.split()]
            cands += [(m.group(1), "link") for m in _LINK.finditer(line)]
            for raw, kind in cands:
                t = clean(raw, kind)
                if not t or _SKIP.search(t) or t in self.ignore or not self.repo_path(t):
                    continue
                if any(t.replace("\\", "/").startswith(a) for a in self.absent_ok):
                    continue
                if (t, n) in seen:
                    continue
                seen.add((t, n))
                if not self.exists(t, path):
                    self.findings.append(("path", f"{name}:{n} names `{t}`, which doesn't exist"))
        for n, g in frontmatter_globs(lines):
            if not any(self.root.glob(g)):
                self.findings.append(("path", f"{name}:{n} has the rule path `{g}`, which matches no file, so the "
                                              f"rule never loads"))

    def check_stale(self, path: Path, lines: list, patterns: list) -> None:
        name = rel(self.root, path)
        for p in patterns:
            if any(fnmatch.fnmatch(name, g) for g in p.get("except_paths", [])):
                continue
            rx = re.compile(p["regex"])
            also = re.compile(p["and"]) if p.get("and") else None
            unless = re.compile(p["except_line"]) if p.get("except_line") else None
            for n, line in enumerate(lines, 1):
                if rx.search(line) and (not also or also.search(line)) and not (unless and unless.search(line)):
                    excerpt = re.sub(r"\s+", " ", line.strip())
                    m = rx.search(excerpt)
                    start = max(0, (m.start() if m else 0) - 40)
                    self.findings.append(("stale", f"{name}:{n} [{p['id']}] \"{excerpt[start:start + 110]}\" "
                                                   f"({p.get('why', 'stale')})"))

    def check_sizes(self) -> None:
        for cap in self.conf.get("size_caps", []):
            p = self.root / cap["file"]
            if not p.is_file():
                continue
            if "max_bytes" in cap and p.stat().st_size > cap["max_bytes"]:
                self.findings.append(("size", f"{cap['file']} is {p.stat().st_size / 1024:.1f} KB, over its "
                                              f"{cap['max_bytes'] / 1024:.0f} KB cap"))
            if "max_lines" in cap:
                count = len(p.read_text(encoding="utf-8", errors="replace").splitlines())
                if count > cap["max_lines"]:
                    self.findings.append(("size", f"{cap['file']} is {count} lines, over its {cap['max_lines']}-line "
                                                  f"cap ({cap.get('fix', 'trim it')})"))

    def load_patterns(self) -> list:
        """The stale-pattern list. None named: no check. Named but missing or broken: a finding, and no patterns."""
        pfile = self.conf.get("stale_patterns_file")
        if not pfile:
            return []
        ppath = self.lib.in_root(pfile) if "/" in pfile else self.lib.config_dir() / pfile  # a path: a copy elsewhere
        off = "so the stale-phrase check didn't run"
        try:
            patterns = json.loads(ppath.read_text(encoding="utf-8")).get("patterns", [])
            for p in patterns:
                p["id"], re.compile(p["regex"])
                for key in ("and", "except_line"):
                    if p.get(key):
                        re.compile(p[key])
            return patterns
        except FileNotFoundError:
            self.findings.append(("config", f"the stale-pattern list {rel(self.root, ppath)} is missing, {off}. Make "
                                            f"it, or take \"stale_patterns_file\" out of config/hooks.json"))
        except (ValueError, KeyError, TypeError, AttributeError, re.error) as e:
            self.findings.append(("config", f"the stale-pattern list {rel(self.root, ppath)} can't be read "
                                            f"({type(e).__name__}: {e}), {off}"))
        return []

    def run(self, extra_scope: list | None = None) -> list:
        files = expand(self.root, self.conf.get("files", []))
        patterns = self.load_patterns()
        texts = {}
        for f in files:
            texts[f] = f.read_text(encoding="utf-8", errors="replace").splitlines()
            self.check_paths(f, texts[f])
        for f in expand(self.root, extra_scope or []):
            texts.setdefault(f, f.read_text(encoding="utf-8", errors="replace").splitlines())
        for f, lines in texts.items():
            self.check_stale(f, lines, patterns)
        self.check_sizes()
        return self.findings


def main(argv: list) -> int:
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    report = "--report" in argv
    try:
        import hooklib as lib
        if not report:
            lib.read_input()
        lib.test_crash("instruction_lint")
        conf = lib.cfg("instruction_lint")
        scope = [argv[k + 1] for k, a in enumerate(argv) if a == "--scope" and k + 1 < len(argv)]
        found = Lint(lib, conf).run(scope)
        if report:
            sys.stdout.reconfigure(errors="replace")  # a cp1252 console can't print every character
            for kind, text in found:
                print(f"{kind:5} {text}")
            print(f"-- {len(found)} finding(s)")
            return 1 if found else 0
        if not found:
            return 0
        cap = int(conf.get("max_findings", 25))
        lines = [f"- {text}" for _, text in found[:cap]]
        if len(found) > cap:
            lines.append(f"- (+{len(found) - cap} more: py .claude/hooks/instruction_lint.py --report)")
        head = ("Instruction lint (informational): these instruction lines name missing paths, look stale, or the "
                "lint's own list is broken. "
                "One teammate owns the wording of the rules and briefs: don't edit files outside your own "
                "area; if one affects your work, tell that teammate.")
        lib.add_context("SessionStart", head + "\n" + "\n".join(lines),
                        f"Instruction lint: {len(found)} finding(s); the session has the list.")
        return 0
    except Exception as e:
        why = f"{type(e).__name__}: {e}"[:240]
        if report:
            sys.stderr.write(f"instruction lint failed ({why}). Nothing was checked.\n")
            return 2
        # fails open, and says so to both: the session starts, and nobody reads the silence as "clean"
        sys.stdout.write(json.dumps({
            "hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext":
                                   f"Instruction lint didn't run ({why}). Nothing was checked: this isn't a clean "
                                   f"result. Tell whoever keeps the hooks."},
            "systemMessage": f"instruction lint failed ({why}); nothing was checked."[:300]}))
        return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
