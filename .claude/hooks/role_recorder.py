"""role_recorder.py - SessionStart and UserPromptSubmit hook: which teammate this session is.

Claude Code puts the session's custom title in the hook input as `session_title` (set with /rename or the desktop sidebar's
rename). This hook maps the title to a role with config/roles.json and writes .claude/state/roles/<session_id>.json, signed
with the hooks' key so a record written by hand doesn't count. No title or no match: "unknown", the least privilege. If the
input carries no session_title, it falls back to the last "custom-title" entry in the session's own transcript. If neither has
one, a signed record with a title stands: a title missing from one input isn't a rename.

Never blocks a session start or a prompt: on any error it prints one warning line and the session goes on.

Also a PreToolUse guard (same script, --title-guard, matcher on the desktop app's start_session and set_session_title tools):
a session may not give itself, or a session it starts, a teammate's title, since the title is what grants the role. Only the
director names a teammate's session. That part fails closed (onFailure "block").
"""

from __future__ import annotations

import json
import os
import sys


def title_guard(inp: dict, lib) -> int:
    ti = inp.get("tool_input") if isinstance(inp.get("tool_input"), dict) else {}
    title = ti.get("title")
    if not isinstance(title, str) or not title.strip():
        return 0
    role = lib.role_for_title(title)
    if role == "unknown":
        return 0
    reason = (f"role guard: the title '{title[:60]}' would make that session {role}, and a session's title is "
              f"what grants a teammate's rights (git push, Studio locks). Only the director names a teammate's "
              f"session; pick a title that isn't a teammate's name.")
    lib.pre_tool("deny", reason)
    lib.audit("role_recorder", "deny", reason, inp)
    return 0


def main() -> int:
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    if "--title-guard" in sys.argv:
        try:
            import hooklib as lib
            inp = lib.read_input()
            lib.test_crash("role_guard")
            return title_guard(inp, lib)
        except Exception as e:
            sys.stdout.write(json.dumps({"hookSpecificOutput": {
                "hookEventName": "PreToolUse", "permissionDecision": "deny",
                "permissionDecisionReason": f"role guard error ({type(e).__name__}: {e}); blocked because it fails "
                                            f"closed."}}))
            return 0
    try:
        import hooklib as lib
        inp = lib.read_input()
        lib.test_crash("role_recorder")
        sid = inp.get("session_id")
        if not sid:
            return 0
        title, source = lib.session_title(inp)
        event = inp.get("hook_event_name") or "?"
        path = lib.role_file(sid)
        try:
            old = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, ValueError):
            old = None
        if title is None and old and lib.verify(old) and old.get("title"):
            return 0  # a title missing from one input isn't a rename: the signed record stands
        role = lib.role_for_title(title)
        if old and lib.verify(old) and old.get("role") == role and old.get("title") == title:
            return 0  # nothing changed: no write on every prompt
        record = lib.sign({"v": 1, "session_id": sid, "title": title, "title_from": source,
                           "role": role, "recorded": lib.iso(lib.now()),
                           "event": f"{event}:{inp.get('source', '')}".rstrip(":")})
        lib.atomic_write(path, json.dumps(record, indent=1))
        if role == "unknown" and event == "SessionStart":
            lib.warn("Team hooks: this session has no teammate title, so it runs with the least privilege "
                     "(no push, pull, branch switch, stash, reset --hard or clean; no Studio lock). Rename the "
                     "session after its teammate, e.g. 'Builder'.")
        return 0
    except Exception as e:
        sys.stdout.write(json.dumps({"systemMessage": f"role recorder skipped ({type(e).__name__}: {e}); this "
                                                      f"session counts as unknown to the git guard."[:300]}))
        return 0


if __name__ == "__main__":
    sys.exit(main())
