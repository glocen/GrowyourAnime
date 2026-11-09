"""Shared helpers for the team's hooks.

Not a hook itself. Every hook script imports it inside a try block, so a broken library still ends in that
hook's own failure mode (the upload gate, the git guard, the path guard and the Studio lock guard block;
the lint, the drift guard and the role recorder warn and let the work go on).

What lives here: where things are (project root, config, state, key), reading the hook input and writing
decisions, the title-to-role map, signed records (HMAC-SHA256 with a key kept outside the repo), atomic and
locked writes, markdown sections for the drift guard, and an audit line for every deny or ask.

Test and install overrides, all optional: NL_HOOKS_PROJECT (project root), NL_HOOKS_CONFIG (config folder),
NL_HOOKS_STATE (state folder), NL_HOOKS_KEY (key file). In production Claude Code sets CLAUDE_PROJECT_DIR.
"""

from __future__ import annotations

import datetime as _dt
import hashlib
import hmac
import json
import os
import re
import secrets
import sys
import time
from pathlib import Path

HOOKS_DIR = Path(__file__).resolve().parent
_SID_SAFE = re.compile(r"[^A-Za-z0-9_.-]")


# ---------------------------------------------------------------- where things are

def project_root() -> Path:
    env = os.environ.get("NL_HOOKS_PROJECT") or os.environ.get("CLAUDE_PROJECT_DIR")
    if env:
        return Path(env)
    for parent in [HOOKS_DIR, *HOOKS_DIR.parents]:
        if (parent / "AGENTS.md").is_file():
            return parent
    return Path.cwd()


def config_dir() -> Path:
    env = os.environ.get("NL_HOOKS_CONFIG")
    return Path(env) if env else HOOKS_DIR / "config"


_CONFIG_CACHE: dict = {}


def load_config(name: str = "hooks.json") -> dict:
    if name not in _CONFIG_CACHE:
        with open(config_dir() / name, encoding="utf-8") as f:
            _CONFIG_CACHE[name] = json.load(f)
    return _CONFIG_CACHE[name]


def cfg(section: str) -> dict:
    return load_config().get(section, {})


def in_root(rel: str) -> Path:
    """A path from the config, relative to the project root unless it's absolute or starts with ~."""
    p = Path(os.path.expanduser(rel))
    return p if p.is_absolute() else project_root() / p


def state_dir() -> Path:
    env = os.environ.get("NL_HOOKS_STATE")
    return Path(env) if env else in_root(load_config().get("state_dir", ".claude/state"))


def key_path() -> Path:
    env = os.environ.get("NL_HOOKS_KEY")
    return Path(env) if env else in_root(load_config().get("key_file", "~/.claude/team-hooks/hmac.key"))


def safe_id(session_id: str) -> str:
    """A session id as a file name: no separators, no traversal."""
    sid = _SID_SAFE.sub("_", str(session_id or "no-session"))[:120]
    return sid.strip(".") or "no-session"


# ---------------------------------------------------------------- hook input and output

def read_input() -> dict:
    raw = sys.stdin.buffer.read()
    if not raw.strip():
        return {}
    data = json.loads(raw.decode("utf-8", errors="replace"))
    if not isinstance(data, dict):
        raise ValueError("hook input is not a JSON object")
    return data


def emit(obj: dict) -> None:
    sys.stdout.write(json.dumps(obj))  # ASCII only, so a cp1252 console never breaks it
    sys.stdout.flush()


def pre_tool(decision: str, reason: str, context: str | None = None) -> None:
    out = {"hookEventName": "PreToolUse", "permissionDecision": decision, "permissionDecisionReason": reason}
    if context:
        out["additionalContext"] = context
    emit({"hookSpecificOutput": out})


def add_context(event: str, text: str, system_message: str | None = None) -> None:
    obj: dict = {"hookSpecificOutput": {"hookEventName": event, "additionalContext": text}}
    if system_message:
        obj["systemMessage"] = system_message
    emit(obj)


def warn(text: str) -> None:
    """The fail-open path: one line for the user, nothing blocked."""
    emit({"systemMessage": text[:300]})


def test_crash(hook: str) -> None:
    """Lets the tests prove each hook's failure mode. Harmless in production: a crash only ever blocks or
    warns, as that hook's mode says."""
    if os.environ.get("NL_HOOKS_TEST_CRASH") == hook:
        raise RuntimeError(f"test crash in {hook}")


# ---------------------------------------------------------------- time

def now() -> _dt.datetime:
    fake = os.environ.get("NL_HOOKS_NOW")  # tests only: an ISO time
    if fake:
        return parse_time(fake)
    return _dt.datetime.now(_dt.timezone.utc)


def iso(t: _dt.datetime) -> str:
    return t.astimezone(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def parse_time(text: str) -> _dt.datetime:
    t = _dt.datetime.fromisoformat(str(text).replace("Z", "+00:00"))
    return t if t.tzinfo else t.replace(tzinfo=_dt.timezone.utc)


# ---------------------------------------------------------------- hashing and signing

def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def hmac_key(create: bool) -> bytes | None:
    """The signing key lives outside the repo (~/.claude/team-hooks/hmac.key by default), so a record a
    session writes by hand doesn't verify. Only the recorders create it."""
    p = key_path()
    try:
        return bytes.fromhex(p.read_text(encoding="ascii").strip())
    except FileNotFoundError:
        if not create:
            return None
    except ValueError:
        return None
    p.parent.mkdir(parents=True, exist_ok=True)
    try:
        fd = os.open(p, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(fd, "w", encoding="ascii") as f:
            f.write(secrets.token_hex(32))
    except FileExistsError:
        pass
    return bytes.fromhex(p.read_text(encoding="ascii").strip())


def _canonical(record: dict) -> bytes:
    body = {k: v for k, v in record.items() if k != "mac"}
    return json.dumps(body, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode("ascii")


def sign(record: dict) -> dict:
    key = hmac_key(create=True)
    if not key:
        raise ValueError(f"the hooks' key file {key_path()} is unreadable; delete it and the next record makes a "
                         f"new one (older records then stop counting)")
    record = dict(record)
    record["mac"] = hmac.new(key, _canonical(record), hashlib.sha256).hexdigest()
    return record


def verify(record: dict) -> bool:
    key = hmac_key(create=False)
    mac = record.get("mac")
    if not key or not isinstance(mac, str):
        return False
    return hmac.compare_digest(mac, hmac.new(key, _canonical(record), hashlib.sha256).hexdigest())


# ---------------------------------------------------------------- files

def atomic_write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(f".{path.name}.{os.getpid()}.tmp")
    tmp.write_text(text, encoding="utf-8")
    for attempt in range(20):
        try:
            os.replace(tmp, path)
            return
        except PermissionError:  # Windows: another reader holds the file for a moment
            time.sleep(0.05 * (attempt + 1))
    os.replace(tmp, path)


class FileLock:
    """A lock file made with O_EXCL; a lock older than `stale` seconds is taken over."""

    def __init__(self, path: Path, wait: float = 5.0, stale: float = 15.0):
        self.path, self.wait, self.stale = Path(str(path) + ".lock"), wait, stale

    def __enter__(self):
        self.path.parent.mkdir(parents=True, exist_ok=True)
        deadline = time.monotonic() + self.wait
        while True:
            try:
                fd = os.open(self.path, os.O_WRONLY | os.O_CREAT | os.O_EXCL)
                os.write(fd, str(os.getpid()).encode())
                os.close(fd)
                return self
            except FileExistsError:
                try:
                    if time.time() - self.path.stat().st_mtime > self.stale:
                        self.path.unlink()
                        continue
                except FileNotFoundError:
                    continue
                if time.monotonic() > deadline:
                    raise TimeoutError(f"{self.path} is held")
                time.sleep(0.05)

    def __exit__(self, *exc):
        try:
            self.path.unlink()
        except FileNotFoundError:
            pass


def locked_append(path: Path, line: str) -> None:
    with FileLock(path):
        with open(path, "a", encoding="utf-8", newline="\n") as f:
            f.write(line.rstrip("\n") + "\n")


def audit(hook: str, decision: str, reason: str, inp: dict) -> None:
    """One line per deny or ask, so a trial can count false positives. Never raises."""
    try:
        cmd = (inp.get("tool_input") or {}).get("command") or ""
        line = json.dumps({
            "ts": iso(now()), "hook": hook, "decision": decision, "reason": reason[:300],
            "session": inp.get("session_id"), "agent": inp.get("agent_type"), "tool": inp.get("tool_name"),
            "command": cmd[:300],
        })
        locked_append(state_dir() / "decisions.jsonl", line)
    except Exception:
        pass


# ---------------------------------------------------------------- roles

def session_title(inp: dict) -> tuple:
    """(title, where it came from). The hook input's session_title (SessionStart and UserPromptSubmit carry it
    when a custom title is set), else the last "custom-title" entry Claude Code wrote in the session's own
    transcript ({"type":"custom-title","customTitle":...,"sessionId":...}; the desktop app writes one on
    rename). Only that session's own file, only its tail."""
    if inp.get("session_title"):
        return inp["session_title"], "input"
    sid, tp = inp.get("session_id"), inp.get("transcript_path")
    if not sid or not tp:
        return None, None
    p = Path(os.path.expanduser(str(tp)))
    if p.name != f"{sid}.jsonl" or not p.is_file():
        return None, None
    with open(p, "rb") as f:
        f.seek(max(0, p.stat().st_size - 512 * 1024))
        tail = f.read().decode("utf-8", "replace")
    title = None
    for line in tail.splitlines():
        if '"custom-title"' not in line:
            continue
        try:
            e = json.loads(line)
        except ValueError:
            continue
        if e.get("type") == "custom-title" and e.get("sessionId") == sid and isinstance(e.get("customTitle"), str):
            title = e["customTitle"]
    return (title, "transcript") if title else (None, None)


def role_for_title(title: str | None) -> str:
    """The title-to-role map (config/roles.json). No title, no match or two matches: "unknown"."""
    if not title or not str(title).strip():
        return "unknown"
    t = str(title).strip()
    roles = load_config("roles.json").get("roles", {})
    hits = [name for name, spec in roles.items()
            if any(re.search(p, t, re.IGNORECASE) for p in spec.get("titles", []))]
    return hits[0] if len(hits) == 1 else "unknown"


def role_file(session_id: str) -> Path:
    return state_dir() / "roles" / f"{safe_id(session_id)}.json"


def role_for_session(session_id: str | None) -> tuple[str, str]:
    """(role, why). A missing, unreadable or unsigned record is the least privilege: "unknown"."""
    if not session_id:
        return "unknown", "the hook input has no session id"
    p = role_file(session_id)
    try:
        rec = json.loads(p.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return "unknown", "no role is recorded for this session yet (no teammate title seen)"
    except (OSError, ValueError):
        return "unknown", "this session's role record is unreadable"
    if not verify(rec):
        return "unknown", "this session's role record isn't signed by the hooks"
    if rec.get("session_id") != session_id:
        return "unknown", "this session's role record names another session"
    return str(rec.get("role") or "unknown"), f"title '{rec.get('title')}'"


def known_roles() -> list[str]:
    return list(load_config("roles.json").get("roles", {}).keys())


# ---------------------------------------------------------------- markdown sections

_HEADING = re.compile(r"^(#{1,6})[ \t]+(.+?)[ \t]*#*[ \t]*$")


def sections(text: str) -> dict[str, str]:
    """Heading text -> sha256 of that section's body (up to the next heading of any level). The text before
    the first heading is "(top)". Headings inside ``` fences don't count. A repeated heading gets " #2"."""
    out: dict[str, str] = {}
    title, body, fence = "(top)", [], False

    def close():
        name, n = title, 2
        while name in out:
            name = f"{title} #{n}"
            n += 1
        out[name] = sha256_text("\n".join(body))

    for line in text.splitlines():
        if line.lstrip().startswith("```"):
            fence = not fence
        m = None if fence else _HEADING.match(line)
        if m:
            close()
            title, body = m.group(2).strip(), []
        else:
            body.append(line)
    close()
    return out


def section_text(text: str, wanted: str) -> str | None:
    """The body of the first section whose heading starts with `wanted` (case-insensitive)."""
    lines, grab, fence, level = text.splitlines(), None, False, 0
    for line in lines:
        if line.lstrip().startswith("```"):
            fence = not fence
        m = None if fence else _HEADING.match(line)
        if m:
            if grab is not None and len(m.group(1)) <= level:
                break
            if grab is None and m.group(2).strip().lower().startswith(wanted.lower()):
                grab, level = [], len(m.group(1))
                continue
        if grab is not None:
            grab.append(line)
    return None if grab is None else "\n".join(grab)
