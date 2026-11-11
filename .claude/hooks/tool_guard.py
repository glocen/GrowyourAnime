"""tool_guard.py - PreToolUse hook over every MCP tool (matcher "^mcp__"), and the shell if you match it too: closed by default.

A deny list names what was dangerous on the day it was written. When a server adds or renames a tool, the list lets it
through. This guard turns that round. For each server named in config/tools.json, a tool passes only when it is named:
  - "read":  passes for every session, with an unknown role and in a paused project too;
  - "roles": {tool: [roles]} passes for those roles, when the project isn't paused;
  - "never": {tool: why} is refused for everyone, with its reason;
  - any other tool of that server is refused, with the line to add once the director says yes.
Names take * and ?. A server the file doesn't name follows "unlisted_servers": "pass" or "deny".

Paused: config/hooks.json "paused": {"since": "...", "words": "..."}. While it's there, only "read" passes.

The shell (matcher "Bash|PowerShell", optional): the command's text is read against "shell", a list of {id, regex, roles,
why}. A match passes only for those roles, and never in a paused project; a command that matches several patterns must be
allowed by each. This is a tripwire for the known ways round a
guarded tool (`rojo upload`, an Open Cloud call by curl). It isn't a boundary: a command can be spelled so no pattern sees
it. The boundary is what the key itself may do, so keep each key's permissions as small as its job.

A call that passes gets no output, so the normal permission flow still decides. A refusal is one line in
.claude/state/decisions.jsonl.

Fails closed: on its own error every MCP call it was shown is refused. A shell command is refused then only when its text
holds one of the built-in markers below, so a broken guard can't stop every command. Give the hook "onFailure": "block" in
settings.json as well: without it Claude Code lets a call through when a hook can't start or times out.

`py tool_guard.py --explain <role> <tool name> [...]` prints what the policy says for each name, without a session.
"""

from __future__ import annotations

import fnmatch
import json
import os
import re
import sys

SHELL_TOOLS = {"Bash", "PowerShell"}
_FALLBACK = re.compile(r"roblox\.com|rojo\S*\s+upload|_KEY\b", re.IGNORECASE)  # the shell's markers when the guard is broken


def _hit(name: str, globs) -> str | None:
    for g in globs or []:
        if fnmatch.fnmatchcase(name, g):
            return g
    return None


def decide(policy: dict, tool: str, tool_input: dict, role: str, paused: dict | None) -> tuple:
    """("pass" or "deny", reason). The reason of a pass says which line let it through."""
    stop = ""
    if paused:
        stop = (f"this project is paused since {paused.get('since', '?')} (\"{str(paused.get('words', ''))[:80]}\"), "
                f"so only read tools pass. Only the director's word reopens it.")
    who = role if role != "unknown" else "a session with no teammate title"
    if tool in SHELL_TOOLS:
        cmd = str((tool_input or {}).get("command") or "")
        hits = [m for m in policy.get("shell", []) if re.search(m["regex"], cmd, re.IGNORECASE)]
        for m in hits:  # every pattern the command matches must allow it: one allowed match never covers another
            if paused:
                return "deny", f"the command matches [{m['id']}] ({m.get('why', 'a guarded route')}), and {stop}"
            if role not in m.get("roles", []):
                may = ", ".join(m.get("roles", [])) or "no teammate; it's the director's hand"
                return "deny", (f"the command matches [{m['id']}] ({m.get('why', 'a guarded route')}). It's for: "
                                f"{may}. This session is {who}.")
        if hits:
            return "pass", f"shell [{', '.join(m['id'] for m in hits)}] for {role}"
        return "pass", "no shell marker"
    for server in policy.get("servers", []):
        m = re.match(server["match"], tool)
        if not m:
            continue
        short, label = tool[m.end():], server.get("name", server["match"])
        g = _hit(short, server.get("never", {}))
        if g:
            return "deny", f"{label}: `{short}` is never used here ({server['never'][g]})."
        if _hit(short, server.get("read", [])):
            return "pass", f"{label}: read"
        g = _hit(short, server.get("roles", {}))
        if not g:
            return "deny", (f"{label}: `{short}` isn't named in .claude/hooks/config/tools.json, and an unnamed tool "
                            f"is refused. If the team needs it, the director says who may call it, and it gets its "
                            f"line there.")
        if paused:
            return "deny", f"{label}: `{short}` changes things, and {stop}"
        if role not in server["roles"][g]:
            return "deny", (f"{label}: `{short}` is for {', '.join(server['roles'][g]) or 'nobody'}. This session is "
                            f"{who}. Read tools still work; ask that teammate.")
        return "pass", f"{label}: {role}"
    if policy.get("unlisted_servers", "pass") == "deny" and tool.startswith("mcp__"):
        return "deny", "its server isn't named in .claude/hooks/config/tools.json, and unlisted servers are refused."
    return "pass", "unlisted server"


def role_of(lib, inp: dict) -> str:
    """The signed record the role recorder keeps, else the title in the session's own transcript."""
    role, _ = lib.role_for_session(inp.get("session_id"))
    if role != "unknown":
        return role
    return lib.role_for_title(lib.session_title(inp)[0])


def _deny(reason: str) -> None:
    sys.stdout.write(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": reason}}))
    sys.stdout.flush()


def explain(argv: list) -> int:
    import hooklib as lib
    policy, paused = lib.load_config("tools.json"), lib.load_config().get("paused")
    role, names = argv[0], argv[1:]
    for tool in names:
        verdict, why = decide(policy, tool, {"command": tool}, role, paused if isinstance(paused, dict) else None)
        print(f"{verdict:5} {tool}  ({why})")
    return 0


def main(argv: list) -> int:
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    if argv and argv[0] == "--explain":
        return explain(argv[1:])
    raw = b""
    try:
        raw = sys.stdin.buffer.read()
        import hooklib as lib
        inp = json.loads(raw.decode("utf-8", errors="replace")) if raw.strip() else {}
        if not isinstance(inp, dict):
            raise ValueError("hook input is not a JSON object")
        lib.test_crash("tool_guard")
        tool = str(inp.get("tool_name") or "")
        if not tool:
            raise ValueError("hook input names no tool")
        paused = lib.load_config().get("paused")
        ti = inp.get("tool_input") if isinstance(inp.get("tool_input"), dict) else {}
        verdict, why = decide(lib.load_config("tools.json"), tool, ti, role_of(lib, inp),
                              paused if isinstance(paused, dict) else None)
        if verdict == "deny":
            lib.audit("tool_guard", "deny", why, inp)
            _deny("Tool guard: " + why)
        elif why.startswith("shell ["):
            lib.audit("tool_guard", "allow", why, inp)
        return 0
    except Exception as e:
        text = raw.decode("utf-8", errors="replace")
        shell = re.search(r'"tool_name"\s*:\s*"(Bash|PowerShell)"', text)
        if shell and not _FALLBACK.search(text):
            sys.stdout.write(json.dumps({"systemMessage": f"tool guard error ({type(e).__name__}: {e}); shell "
                                                          f"commands pass on its built-in markers only."[:300]}))
            return 0
        _deny(f"Tool guard error ({type(e).__name__}: {e}); this call is blocked because the guard fails closed. "
              f"Tell whoever keeps the hooks.")
        return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
