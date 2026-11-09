"""drift_guard.py - SessionStart and UserPromptSubmit hook: tells a session who it is, and when its instructions
changed.

A session reads its rule files and its brief when it starts; a teammate may change them an hour later. At SessionStart
(any source) this hook hashes those files section by section (markdown headings) into .claude/state/drift/<session_id>.json;
the brief comes from the session's role (its title, config/roles.json) and config/hooks.json "drift_guard". On each
UserPromptSubmit it hashes them again and, when a section changed, appeared or went away, adds one short note to the context
naming the file and the sections, so the session knows to re-read them. The new text then becomes the baseline, so each
change is told once.

It also says which teammate the session is, once per context: at each SessionStart (a /clear and a compaction included), or
with the first prompt when the title comes late. After a /clear a session can read itself as another role.

A title can be missing from an input. An input without a title keeps the role the session already had, and a session with no
title yet is told to read its own before it asks. The record keeps where the last eight titles came from ("title_log":
input, transcript, kept or none), so the next miss can be traced.

Fails open: on any error it prints one warning line and the prompt goes through untouched.
"""

from __future__ import annotations

import json
import os
import sys


def tracked(lib, conf: dict, role: str) -> list:
    files = list(conf.get("always", ["AGENTS.md", "CLAUDE.md"])) + list(conf.get("briefs", {}).get(role, []))
    return list(dict.fromkeys(files))


def identity(lib, conf: dict, role: str, title: str | None) -> str:
    """Which teammate the session is, by its title, and what it works from (config/hooks.json "start")."""
    spec = lib.load_config("roles.json").get("roles", {}).get(role)
    ask = "ask the director which teammate it is before following any teammate's brief."
    if not spec and title is None:
        return ("No session title reached the hooks. Read it yourself with the app's get_session tool "
                "(mcp__ccd_session_mgmt__get_session, session_id \"self\"): a title that "
                ".claude/hooks/config/roles.json maps to a teammate makes this session that teammate. If it maps "
                "to none, or you can't read it, " + ask)
    if not spec:
        return (f"This session's title, \"{str(title)[:60]}\", names no teammate "
                ": " + ask)
    note = f"By its title, this session is {role}: {spec.get('who', role)}. It works from " \
           f"{conf.get('start', {}).get(role, 'its brief')}."
    builder = lib.load_config().get("builder_role")
    if builder and role != builder:
        note += " The builder's start and finish skills aren't this session's."
    return note


def snapshot(lib, files: list) -> dict:
    out = {}
    for f in files:
        p = lib.in_root(f)
        try:
            text = p.read_text(encoding="utf-8", errors="replace")
        except OSError:
            out[f] = {"sha": None, "sections": {}}
            continue
        out[f] = {"sha": lib.sha256_text(text), "sections": lib.sections(text)}
    return out


def _names(titles: list, limit: int) -> str:
    shown = [f'"{t}"' if t != "(top)" else "the opening lines" for t in titles[:limit]]
    more = f" and {len(titles) - limit} more" if len(titles) > limit else ""
    return ", ".join(shown) + more


def diff(base: dict, cur: dict, limit: int) -> list:
    notes = []
    for f, now in cur.items():
        then = base.get(f)
        if then is None or then.get("sha") == now.get("sha"):
            continue
        if now.get("sha") is None:
            notes.append(f"{f} is gone")
            continue
        if then.get("sha") is None:
            notes.append(f"{f} appeared")
            continue
        old, new = then.get("sections", {}), now.get("sections", {})
        changed = [s for s, h in new.items() if old.get(s) != h]
        removed = [s for s in old if s not in new]
        bits = []
        if changed:
            bits.append("sections " + _names(changed, limit))
        if removed:
            bits.append("removed " + _names(removed, limit))
        if bits:  # a change that moves no section (line endings, a trailing newline) isn't worth a note
            notes.append(f"{f} ({'; '.join(bits)})")
    return notes


def main() -> int:
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    try:
        import hooklib as lib
        inp = lib.read_input()
        lib.test_crash("drift_guard")
        sid = inp.get("session_id")
        if not sid:
            return 0
        conf = lib.cfg("drift_guard")
        state = lib.state_dir() / "drift" / f"{lib.safe_id(sid)}.json"
        event = inp.get("hook_event_name")
        try:
            saved = json.loads(state.read_text(encoding="utf-8"))
        except (OSError, ValueError):
            saved = None  # a new context, or a session that started before the hooks
        title, source = lib.session_title(inp)
        role = lib.role_for_title(title)
        if title is None and saved and saved.get("role", "unknown") != "unknown":
            role, source = saved["role"], "kept"  # a title missing from one input isn't a rename
        log = (saved or {}).get("title_log", [])[-7:] + [
            {"at": lib.iso(lib.now()), "event": f"{event}:{inp.get('source', '')}".rstrip(":"), "from": source}]
        files = tracked(lib, conf, role)
        cur = snapshot(lib, files)
        if event == "SessionStart":
            told = None  # no title yet: the app may write it before the first prompt, which then tells it
            if role != "unknown":
                lib.add_context("SessionStart", identity(lib, conf, role, title))
                told = role
            lib.atomic_write(state, json.dumps({"role": role, "told": told, "files": cur, "title_log": log}))
            return 0
        base = saved.get("files", {}) if saved else cur  # a session that started before the hooks: no drift note
        told = saved.get("told") if saved else None
        texts = [identity(lib, conf, role, title)] if told != role else []
        notes = diff(base, cur, int(conf.get("max_sections_named", 6)))
        if notes:
            texts.append("Instructions changed since this session read them: " + "; ".join(notes) +
                         ". Re-read those sections before relying on them (search for the heading).")
        if texts:
            lib.add_context("UserPromptSubmit", " ".join(texts))
        lib.atomic_write(state, json.dumps({"role": role, "told": role, "files": {**base, **cur}, "title_log": log}))
        return 0
    except Exception as e:
        sys.stdout.write(json.dumps({"systemMessage": f"drift guard skipped ({type(e).__name__}: {e})."[:300]}))
        return 0


if __name__ == "__main__":
    sys.exit(main())
