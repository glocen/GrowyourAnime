#!/usr/bin/env python3
"""Memory guard (Turing, docs/turing.md, "The floor, kept by tools"): PreToolUse before a Studio playtest starts or
Blender runs.

This PC has 15.5 GB and several sessions, so a playtest or a render started short of memory pages the machine, and a
take or a timing measured then is worthless. Before start_stop_play with is_start true, and before a Bash or
PowerShell command that launches Blender, it reads:
- the memory Windows has available (GlobalMemoryStatusEx: free and standby, what a new process can take);
- build/locks/blender.lock, written by the asset maker's scripts for a Cycles render or a bake (live for 30 minutes).
Below the floor (hooks.json "memory_guard": "playtest_gb", "blender_gb"; 2 GB by Turing), or with a live render lock,
it refuses, with the reading and who holds the memory (each Studio and Blender, by size) or the lock.
A stop, a read and any other call pass untouched. Its own error only warns: a broken guard never blocks the work.
NL_HOOKS_AVAIL_GB stands in for the reading in the hooks' self-test.
"""
from __future__ import annotations

import ctypes
import csv
import io
import os
import re
import subprocess
import sys
import time

PLAY_TOOL = re.compile(r"^mcp__.*Roblox.*__start_stop_play$")
BLENDER = re.compile(r"blender(\.exe)?['\"]?(\s|$)", re.IGNORECASE)
HOLDERS = {"robloxstudiobeta.exe": "Studio", "blender.exe": "Blender"}
LOCK_LIVE_S = 1800  # as the asset maker's scripts read it


def available_gb() -> float:
    stand_in = os.environ.get("NL_HOOKS_AVAIL_GB")
    if stand_in:
        return float(stand_in)

    class Status(ctypes.Structure):
        _fields_ = [("dwLength", ctypes.c_ulong), ("dwMemoryLoad", ctypes.c_ulong)] + [
            (n, ctypes.c_ulonglong) for n in ("total", "avail", "pageTotal", "pageAvail", "virtTotal", "virtAvail",
                                              "extAvail")]

    s = Status()
    s.dwLength = ctypes.sizeof(Status)
    if not ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(s)):
        raise OSError("GlobalMemoryStatusEx failed")
    return s.avail / 2 ** 30


def holders() -> str:
    """Each Studio and Blender by its working set, largest first: who to close."""
    if os.environ.get("NL_HOOKS_AVAIL_GB"):
        return "(the self-test's stand-in)"
    try:
        out = subprocess.run(["tasklist", "/FO", "CSV", "/NH"], capture_output=True, timeout=5).stdout
        rows = []
        for row in csv.reader(io.StringIO(out.decode("utf-8", "replace"))):
            if len(row) >= 5 and row[0].lower() in HOLDERS:
                mb = int(re.sub(r"\D", "", row[4]) or 0) // 1024
                rows.append((mb, f"{HOLDERS[row[0].lower()]} (pid {row[1]}) {mb / 1024:.1f} GB"))
        return ", ".join(t for _, t in sorted(rows, reverse=True)) or "no Studio or Blender running"
    except Exception:
        return "unknown"


def render_lock(root) -> str | None:
    path = root / "build" / "locks" / "blender.lock"
    try:
        if path.exists() and time.time() - path.stat().st_mtime < LOCK_LIVE_S:
            return path.read_text(encoding="utf-8", errors="replace").strip() or "unnamed"
    except OSError:
        return None
    return None


def main() -> int:
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import hooklib as lib
    try:
        inp = lib.read_input()
        lib.test_crash("memory_guard")
        name = inp.get("tool_name") or ""
        ti = inp.get("tool_input") if isinstance(inp.get("tool_input"), dict) else {}
        conf = lib.cfg("memory_guard")
        if PLAY_TOOL.match(name):
            if ti.get("is_start") is not True:
                return 0
            what, floor = "a playtest", float(conf.get("playtest_gb", 2.0))
        elif name in ("Bash", "PowerShell"):
            if not BLENDER.search(str(ti.get("command") or "")):
                return 0
            what, floor = "Blender", float(conf.get("blender_gb", 2.0))
        else:
            return 0
        held = render_lock(lib.project_root())
        if held:
            reason = (f"Memory guard: a render holds the GPU ({held}; build/locks/blender.lock). Start {what} after "
                      f"it ends, and write the turn on the Now board.")
            lib.audit("memory_guard", "deny", reason, inp)
            lib.pre_tool("deny", reason)
            return 0
        avail = available_gb()
        if avail < floor:
            reason = (f"Memory guard: {avail:.2f} GB available, under the {floor:g} GB floor for {what} (Turing). "
                      f"Holding memory: {holders()}. Free it first: close a Studio, end a render, or wait for a "
                      f"turn on the Now board. If the floor itself is wrong, say so to research with this reading.")
            lib.audit("memory_guard", "deny", reason, inp)
            lib.pre_tool("deny", reason)
        return 0
    except Exception as e:  # fail open: one line for the user, nothing blocked
        lib.warn(f"memory_guard: {type(e).__name__}: {e} (the call goes on unchecked)")
        return 0


if __name__ == "__main__":
    sys.exit(main())
