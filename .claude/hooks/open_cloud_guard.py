#!/usr/bin/env python3
"""Open Cloud guard: PreToolUse on the Studio MCP's open_cloud_invoke.

Studio grants Open Cloud per game and per person, so every session shares any grant, and an upload makes a permanent asset on
the creator's account. This is the lock:
- reads (GET) pass for everyone;
- a write passes only from a role in UPLOADERS, only as POST /assets/v1/assets, only with files inside build/upload/, and only
  with expectedPrice 0, so a fee fails the upload instead of charging;
- the Builder may also POST or PATCH this game's own game passes and developer products, once STORE_PREFIXES names this
  game's universe. It's empty until the director creates the experience and says yes to store writes for this game.

It checks the request, not the content: a file enters build/upload/ only after its content check's PASS.
Anything else is denied with its reason, and so is any error here. A call that passes gets no output, so the normal
permission flow still decides.
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

UPLOADERS = {"Builder", "Effects", "LevelDesign"}  # role names from config/roles.json
CREATE_ENDPOINT = "/assets/v1/assets"
STORE_WRITERS = {"Builder"}
STORE_METHODS = {"POST", "PATCH"}
STORE_PREFIXES: tuple = ()  # this game's passes and products, nothing else: empty until its universe exists


def store_call(method: str, endpoint: str) -> bool:
    """A POST or PATCH on this game's own passes or products, with no way out of that path."""
    if method not in STORE_METHODS or ".." in endpoint or "%" in endpoint:
        return False
    return any(endpoint == pre or endpoint.startswith(pre + "/") for pre in STORE_PREFIXES)


def role_of(lib, inp: dict) -> str:
    """The role the drift guard keeps for this session at each prompt, else the title in its transcript."""
    state = lib.state_dir() / "drift" / f"{lib.safe_id(inp.get('session_id'))}.json"
    try:
        role = json.loads(state.read_text(encoding="utf-8")).get("role")
        if role and role != "unknown":
            return role
    except (OSError, ValueError, AttributeError):
        pass
    return lib.role_for_title(lib.session_title(inp)[0])


def refusal(lib, inp: dict) -> str | None:
    """Why this call may not run, or None when it may."""
    call = inp.get("tool_input") or {}
    method = str(call.get("method", "")).upper()
    endpoint = str(call.get("endpoint", "")).split("?")[0].rstrip("/")
    if method == "GET":
        return None
    role = role_of(lib, inp)
    if store_call(method, endpoint):
        return None if role in STORE_WRITERS else f"only {sorted(STORE_WRITERS)} make passes and products, and this session is {role}."
    if role not in UPLOADERS:
        return f"only {sorted(UPLOADERS)} write through Open Cloud, and this session is {role}."
    if method != "POST" or endpoint != CREATE_ENDPOINT:
        return f"the only write allowed is POST {CREATE_ENDPOINT}, not {method} {endpoint}. Anything else asks the director."
    files = call.get("files") or []
    if not files:
        return "an upload names its file in `files`."
    folder = lib.in_root("build/upload").resolve()
    for entry in files:
        path = Path(str((entry or {}).get("path", ""))).resolve()
        if folder not in path.parents:
            return f"upload only from build/upload/, by its absolute Windows path, after the content check's PASS: {path}"
    request = json.loads(call.get("body") or "{}").get("request")
    if isinstance(request, str):
        request = json.loads(request)
    price = ((request or {}).get("creationContext") or {}).get("expectedPrice")
    if price != 0 or isinstance(price, bool):
        return "request.creationContext.expectedPrice must be 0, so a fee fails the upload instead of charging."
    return None


def main() -> int:
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    try:
        import hooklib as lib
        inp = lib.read_input()
        reason = refusal(lib, inp)
        call = inp.get("tool_input") or {}
        if reason:
            lib.audit("open_cloud_guard", "deny", reason, inp)
            lib.pre_tool("deny", "Open Cloud guard: " + reason)
        elif str(call.get("method", "")).upper() != "GET":
            paths = [str((f or {}).get("path")) for f in call.get("files") or []]
            what = f"upload {paths}" if paths else f"{call.get('method')} {call.get('endpoint')}"
            lib.audit("open_cloud_guard", "allow", what, inp)
    except Exception as e:  # fail closed: this guard stands in front of one tool only
        sys.stdout.write(json.dumps({"hookSpecificOutput": {
            "hookEventName": "PreToolUse", "permissionDecision": "deny",
            "permissionDecisionReason": f"Open Cloud guard: it could not read this call ({type(e).__name__}), so it's denied."}}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
