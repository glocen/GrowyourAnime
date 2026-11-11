"""selftest.py - proves the hooks beside it on a throwaway project: `py selftest.py` (add -v to list every case).

It builds a small project in a temp folder, points the hooks at it with the NL_HOOKS_* variables, feeds each hook fake
payloads and checks what comes out. Nothing outside the temp folder is read or written, and no session is needed.
Exit code 0 when every case passes, 1 when one fails. It ends with the tool guard's cost per call on this machine.

Run it after changing a hook, and once in a game after installing them (it tests the scripts beside it, with the example
configs: a game's own config is checked with `tool_guard.py --explain` and `instruction_lint.py --report`).
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
RESULTS: list = []


class Fixture:
    def __init__(self):
        self.root = Path(tempfile.mkdtemp(prefix="nl_hooks_"))
        self.conf = self.root / ".claude" / "hooks" / "config"
        self.conf.mkdir(parents=True)
        for name in ("hooks", "roles", "tools", "stale-patterns"):
            shutil.copy(HERE / "config" / f"{name}.example.json", self.conf / f"{name}.json")
        self.write("AGENTS.md", "# Rules\n\n## Git\n\nCommit by path. Read `docs/plan.md`.\n\n## Team\n\nOne builder.\n")
        self.write("CLAUDE.md", "# Builder\n\nCode is in `src/main.luau`. See [the plan](docs/plan.md).\n")
        self.write("docs/plan.md", "plan\n")
        self.write("docs/team-notes.md", "# Team notes\n\n## Now\n\n- Builder: piece 1.\n\n## Entries\n\nold\n")
        self.write("src/main.luau", "return 1\n")
        self.env = dict(os.environ, NL_HOOKS_PROJECT=str(self.root), NL_HOOKS_CONFIG=str(self.conf),
                        NL_HOOKS_STATE=str(self.root / ".claude" / "state"), NL_HOOKS_KEY=str(self.root / "key"))
        self.env.pop("NL_HOOKS_TEST_CRASH", None)
        self.env.pop("NL_HOOKS_NOW", None)

    def write(self, rel: str, text: str) -> None:
        p = self.root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text, encoding="utf-8", newline="\n")

    def config(self, name: str, change) -> None:
        p = self.conf / f"{name}.json"
        data = json.loads(p.read_text(encoding="utf-8"))
        change(data)
        p.write_text(json.dumps(data), encoding="utf-8")

    def run(self, script: str, payload=None, args=(), raw: bytes | None = None, **env) -> tuple:
        """(exit code, parsed JSON or the text, stderr)."""
        data = raw if raw is not None else (json.dumps(payload).encode() if payload is not None else b"")
        r = subprocess.run([sys.executable, str(HERE / script), *args], input=data, capture_output=True,
                           env={**self.env, **env}, cwd=str(self.root))
        out = r.stdout.decode("utf-8", "replace")
        try:
            parsed = json.loads(out) if out.strip() else {}
        except ValueError:
            parsed = out
        return r.returncode, parsed, r.stderr.decode("utf-8", "replace")

    def session(self, sid: str, title: str | None, source: str = "startup", event: str = "SessionStart", **env):
        """A session event through the role recorder and the drift guard, as settings.json runs them."""
        inp = {"session_id": sid, "hook_event_name": event, "source": source}
        if title:
            inp["session_title"] = title
        self.run("role_recorder.py", inp, **env)
        return self.run("drift_guard.py", inp, **env)[1]

    def tool(self, sid: str, name: str, tool_input: dict | None = None, **env):
        return self.run("tool_guard.py", {"session_id": sid, "hook_event_name": "PreToolUse", "tool_name": name,
                                          "tool_input": tool_input or {}}, **env)[1]

    def shell(self, sid: str, command: str, **env):
        return self.tool(sid, "Bash", {"command": command}, **env)

    def close(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)


def ctx(out) -> str:
    return (out.get("hookSpecificOutput") or {}).get("additionalContext", "") if isinstance(out, dict) else ""


def denied(out) -> bool:
    return isinstance(out, dict) and (out.get("hookSpecificOutput") or {}).get("permissionDecision") == "deny"


def reason(out) -> str:
    return (out.get("hookSpecificOutput") or {}).get("permissionDecisionReason", "") if isinstance(out, dict) else ""


def check(group: str, name: str, ok: bool, seen="") -> None:
    RESULTS.append((group, name, bool(ok), str(seen)[:300]))


# ---------------------------------------------------------------- the instruction lint

def lint_cases() -> None:
    g, start = "lint", {"session_id": "L", "hook_event_name": "SessionStart", "source": "startup"}
    f = Fixture()
    try:
        rc, out, _ = f.run("instruction_lint.py", start)
        check(g, "a clean project prints nothing", rc == 0 and out == {}, out)
        rc, out, _ = f.run("instruction_lint.py", args=["--report"])
        check(g, "report: clean exits 0", rc == 0, (rc, out))

        f.write("AGENTS.md", "# Rules\n\nThe old board is `docs/gone.md`. Rojo serves on port 34872.\n" + "x" * 30000)
        f.write(".claude/rules/world.md", "---\npaths:\n  - \"worlds/**/*.json\"\n---\nWorld rule.\n")
        f.config("stale-patterns", lambda d: d.update(patterns=[
            {"id": "old-port", "regex": r"\b34872\b", "why": "the port moved"}]))
        text = ctx(f.run("instruction_lint.py", start)[1])
        check(g, "a dead link is named with its line", "AGENTS.md:3 names `docs/gone.md`" in text, text)
        check(g, "a rule path that matches no file is named", "worlds/**/*.json" in text, text)
        check(g, "a stale phrase is named with its id", "[old-port]" in text, text)
        check(g, "a file over its size cap is named", "over its 25 KB cap" in text, text)
        rc, out, _ = f.run("instruction_lint.py", args=["--report"])
        check(g, "report: findings exit 1", rc == 1 and "-- 4 finding(s)" in str(out), (rc, out))

        (f.root / "my dir").mkdir()
        f.write("my dir/a.txt", "a")
        gone = "C:" + chr(92) + "No Such Dir" + chr(92) + "b.exe"
        f.write("CLAUDE.md", f"# Builder\n\nA tool is at `{f.root / 'my dir' / 'a.txt'}`, not at `{gone}`.\n")
        text = ctx(f.run("instruction_lint.py", start)[1])
        check(g, "a Windows path with spaces is read whole", "a.txt" not in text and f"`{gone}`" in text, text)
        f.write("CLAUDE.md", "# Builder\n")

        f.config("hooks", lambda d: d["instruction_lint"].update(max_findings=1))
        text = ctx(f.run("instruction_lint.py", start)[1])
        check(g, "the list is capped, with the way to the rest", "(+3 more" in text, text)
        f.config("hooks", lambda d: d["instruction_lint"].update(max_findings=25))

        (f.conf / "stale-patterns.json").unlink()
        text = ctx(f.run("instruction_lint.py", start)[1])
        check(g, "a missing pattern list is a finding", "stale-patterns.json is missing" in text, text)
        check(g, "and the other checks still run", "docs/gone.md" in text and "worlds/**" in text, text)

        f.config("hooks", lambda d: d["instruction_lint"].pop("stale_patterns_file"))
        text = ctx(f.run("instruction_lint.py", start)[1])
        check(g, "no list named: that check is off, silently", "stale-pattern list" not in text and "gone.md" in text, text)

        f.config("hooks", lambda d: d["instruction_lint"].update(stale_patterns_file="stale-patterns.json"))
        (f.conf / "stale-patterns.json").write_text('{"patterns": [{"id": "bad", "regex": "(["}]}', encoding="utf-8")
        text = ctx(f.run("instruction_lint.py", start)[1])
        check(g, "a broken pattern is a finding", "can't be read" in text and "gone.md" in text, text)

        rc, out, _ = f.run("instruction_lint.py", start, NL_HOOKS_TEST_CRASH="instruction_lint")
        check(g, "a crash tells the session nothing was checked", rc == 0 and "didn't run" in ctx(out)
              and "systemMessage" in out, out)
        rc, out, err = f.run("instruction_lint.py", args=["--report"], NL_HOOKS_TEST_CRASH="instruction_lint")
        check(g, "report: a crash exits 2", rc == 2 and "Nothing was checked" in err, (rc, err))
    finally:
        f.close()


# ---------------------------------------------------------------- the tool guard

def guard_cases() -> None:
    g, mcp = "guard", "mcp__Roblox_Studio__"
    f = Fixture()
    try:
        f.session("B", "Builder main")
        f.session("R", "Research")
        f.session("Q", "QA lab")
        f.session("U", None)

        check(g, "a read tool passes with no teammate title", f.tool("U", mcp + "script_read") == {})
        check(g, "a role's tool passes for that role", f.tool("B", mcp + "start_stop_play") == {})
        out = f.tool("R", mcp + "start_stop_play")
        check(g, "and is refused for another role", denied(out) and "This session is Research" in reason(out), out)
        out = f.tool("U", mcp + "execute_luau")
        check(g, "and for a session with no title", denied(out) and "no teammate title" in reason(out), out)
        out = f.tool("B", mcp + "generate_animation")
        check(g, "a never-tool is refused for everyone, by pattern", denied(out) and "never used" in reason(out), out)
        out = f.tool("B", mcp + "brand_new_tool")
        check(g, "a tool nobody named is refused", denied(out) and "isn't named" in reason(out), out)
        check(g, "a server the file doesn't name passes", f.tool("R", "mcp__claude_ai_Docs__read") == {})
        f.config("tools", lambda d: d.update(unlisted_servers="deny"))
        check(g, "or is refused, when unlisted servers are closed", denied(f.tool("R", "mcp__claude_ai_Docs__read")))
        f.config("tools", lambda d: d.update(unlisted_servers="pass"))

        check(g, "session tools: a read passes", f.tool("Q", "mcp__ccd_session_mgmt__get_session") == {})
        check(g, "session tools: an unnamed one is refused", denied(f.tool("B", "mcp__ccd_session_mgmt__delete_session")))
        check(g, "session tools: fast mode is refused", denied(f.tool("B", "mcp__ccd_session_mgmt__set_session_fast_mode")))

        check(g, "shell: an ordinary command passes silently", f.shell("R", "git status --short") == {})
        check(g, "shell: a commit by path passes", f.shell("R", 'git commit -m "x" -- docs/a.md') == {})
        for cmd in ("git stash", "git reset --hard HEAD~1", "git clean -fd", "git checkout -- src/a.luau",
                    "git restore ."):
            check(g, f"shell: `{cmd}` is refused for the builder too", denied(f.shell("B", cmd)), cmd)
        check(g, "shell: a pull passes for the builder", f.shell("B", "git pull --rebase") == {})
        check(g, "shell: a pull is refused for research", denied(f.shell("R", "git pull --rebase")))
        check(g, "shell: a branch switch is refused for QA", denied(f.shell("Q", "git checkout main")))
        check(g, "shell: a push passes for research", f.shell("R", "git push origin main") == {})
        check(g, "shell: a push is refused for QA", denied(f.shell("Q", "git push")))
        check(g, "shell: a push is refused with no title", denied(f.shell("U", "git push")))
        check(g, "shell: rojo upload is refused for the builder", denied(f.shell("B", "rojo upload --asset_id 1 x.rbxl")))
        curl = 'curl -H "x-api-key: $K" https://apis.roblox.com/universes/v1/1/places/2/versions'
        check(g, "shell: an Open Cloud call passes for the builder", f.shell("B", curl) == {})
        check(g, "shell: and is refused for research", denied(f.shell("R", curl)))
        for cmd in ('git commit -m "clean up the board" -- docs/a.md', "git log --oneline | grep clean",
                    'git -c user.name=a -c user.email=b commit -m "pull the handbook, then merge the notes" -- docs/a.md',
                    "git log --grep=merge --oneline", "git merge-base origin/main HEAD", "git add docs/a.md .gitignore",
                    'git commit -m "add the -a flag and the push --force note" -- docs/a.md',
                    "git -C handbook push origin main"):
            check(g, f"shell: `{cmd}` passes for research", f.shell("R", cmd) == {}, cmd)
        for cmd in ("git -c user.name=a clean -n", "git add -A", "git add .", "git add -u", "git -C handbook add --all",
                    'git commit -am "x"', 'git commit -a -m "x"', "git commit --all -m x", "git push --force",
                    "git push origin main --force-with-lease", "git push -f origin main", "git push origin +main"):
            check(g, f"shell: `{cmd}` is refused for the builder too", denied(f.shell("B", cmd)), cmd)
        check(g, "shell: a pull in another folder passes for the builder", f.shell("B", "git -C handbook pull --rebase") == {})
        check(g, "shell: and that pull is refused for research", denied(f.shell("R", "git -C handbook pull --rebase")))
        check(g, "shell: a push followed by rojo upload is refused for the builder",
              denied(f.shell("B", "git push origin main; rojo upload x.rbxl")))
        check(g, "shell: a push followed by an Open Cloud call is refused for research",
              denied(f.shell("R", "git push origin main && " + curl)))
        check(g, "shell: a status followed by a stash is refused", denied(f.shell("B", "git status && git stash")))
        for cmd in ("git commit -q -F build/scratch/r/msg.txt", "git commit --amend --no-edit", "git commit --allow-empty -m x",
                    'git commit -m "say -a, then -f" -- docs/a.md', "git add -N docs/a.md", "git add -v ./docs/a.md",
                    "git restore --staged docs/a.md", "git push -u origin main", "git push origin HEAD:refs/heads/main"):
            check(g, f"shell: `{cmd}` passes for research", f.shell("R", cmd) == {}, cmd)
        for cmd in ("git.exe clean -fd", "git add -Av", "git add -vu docs", "git add *", "git add ./", 'git commit -m "x" -a',
                    'git commit -vam "x"', "git commit -m 'x' --all", "git push origin main -fu", 'git push "origin" main --force',
                    "git restore docs/a.md", "git restore --source=HEAD~1 docs/a.md", "git checkout ."):
            check(g, f"shell: `{cmd}` is refused for the builder too", denied(f.shell("B", cmd)), cmd)
        check(g, "shell: PowerShell is read the same way",
              denied(f.tool("R", "PowerShell", {"command": "git stash"})))

        f.config("hooks", lambda d: d.update(paused={"since": "2026-11-06", "words": "we pause this game"}))
        out = f.tool("B", mcp + "execute_luau")
        check(g, "paused: a write is refused for the builder", denied(out) and "paused since 2026-11-06" in reason(out), out)
        check(g, "paused: a read still passes", f.tool("B", mcp + "script_read") == {})
        check(g, "paused: a guarded shell route is refused", denied(f.shell("B", curl)))
        check(g, "paused: an ordinary command still passes", f.shell("B", "git log --oneline -3") == {})
        f.config("hooks", lambda d: d.pop("paused"))
        check(g, "the pause lifted: the write passes again", f.tool("B", mcp + "execute_luau") == {})

        out = f.tool("B", mcp + "script_read", NL_HOOKS_TEST_CRASH="tool_guard")
        check(g, "a crash refuses an MCP call, a read included", denied(out) and "fails closed" in reason(out), out)
        out = f.shell("B", "git status", NL_HOOKS_TEST_CRASH="tool_guard")
        check(g, "a crash lets an ordinary command through, and says so", not denied(out) and "systemMessage" in out, out)
        check(g, "a crash still refuses a marked command", denied(f.shell("B", "rojo upload x", NL_HOOKS_TEST_CRASH="tool_guard")))
        check(g, "input that isn't JSON is refused", denied(f.run("tool_guard.py", raw=b"not json")[1]))
        check(g, "input with no tool name is refused", denied(f.run("tool_guard.py", {"session_id": "B"})[1]))
        role_file = f.root / ".claude" / "state" / "roles" / "R.json"
        rec = json.loads(role_file.read_text(encoding="utf-8"))
        rec["role"] = "Builder"
        role_file.write_text(json.dumps(rec), encoding="utf-8")
        check(g, "a role record edited by hand doesn't count", denied(f.tool("R", mcp + "start_stop_play")))
        (f.conf / "tools.json").rename(f.conf / "tools.off")
        check(g, "a missing policy file refuses every MCP call", denied(f.tool("B", mcp + "script_read")))
        (f.conf / "tools.off").rename(f.conf / "tools.json")

        log = (f.root / ".claude" / "state" / "decisions.jsonl").read_text(encoding="utf-8").splitlines()
        rows = [json.loads(line) for line in log]
        check(g, "each refusal is one readable line in the log",
              any(r["hook"] == "tool_guard" and r["decision"] == "deny" and r["tool"] and r["reason"] for r in rows),
              len(rows))
        rc, out, _ = f.run("tool_guard.py", args=["--explain", "Research", mcp + "script_read", mcp + "upload_image"])
        check(g, "--explain prints the policy without a session",
              rc == 0 and "pass" in str(out) and "deny" in str(out), out)

        n, t0 = 10, time.perf_counter()
        for _ in range(n):
            f.shell("B", "git status")
        return (time.perf_counter() - t0) / n * 1000
    finally:
        f.close()


# ---------------------------------------------------------------- the drift guard

def drift_cases() -> None:
    g = "drift"
    f = Fixture()
    try:
        prompt = dict(source="", event="UserPromptSubmit")
        out = f.session("B", "Builder main")
        check(g, "a session is told which teammate it is", "this session is Builder" in ctx(out), out)
        check(g, "a prompt with nothing changed adds nothing", f.session("B", "Builder main", **prompt) == {})
        f.write("AGENTS.md", "# Rules\n\n## Git\n\nCommit by path, always.\n\n## Team\n\nOne builder.\n")
        text = ctx(f.session("B", "Builder main", **prompt))
        check(g, "a changed section is named once", '"Git"' in text and '"Team"' not in text, text)
        check(g, "and not again at the next prompt", f.session("B", "Builder main", **prompt) == {})

        f.write("AGENTS.md", "# Rules\n\n## Git\n\nCommit by path.\n\n## Team\n\nTwo builders.\n")
        text = ctx(f.session("B", "Builder main", source="clear"))
        check(g, "a /clear takes a new baseline without a note", "changed" not in text, text)
        check(g, "so the next prompt is quiet", f.session("B", "Builder main", **prompt) == {})
        f.write("AGENTS.md", "# Rules\n\n## Git\n\nCommit by path.\n\n## Team\n\nThree builders.\n")
        text = ctx(f.session("B", "Builder main", source="resume"))
        check(g, "a resume is told what changed while it was away", '"Team"' in text, text)

        out = f.session("N", None)
        check(g, "a session with no title is told nothing it could act on", ctx(out) == "", out)
        text = ctx(f.session("N", None, **prompt))
        check(g, "and is asked to find its title before any brief", "No session title" in text, text)
        text = ctx(f.session("X", "Some other chat", **prompt))
        check(g, "a title that names no teammate gets no role", "names no teammate" in text, text)

        t0 = "2026-11-11T08:00:00+00:00"
        f.session("A", "Assets", NL_HOOKS_NOW=t0)
        f.write("docs/team-notes.md", "# Team notes\n\n## Now\n\n- Builder: piece 2.\n\n## Entries\n\nold\n")
        out = f.session("A", "Assets", **prompt, NL_HOOKS_NOW="2026-11-11T09:00:00+00:00")
        check(g, "board: a session at work isn't told of board edits", out == {}, out)
        f.write("docs/team-notes.md", "# Team notes\n\n## Now\n\n- Builder: piece 3.\n\n## Entries\n\nold\n")
        text = ctx(f.session("A", "Assets", **prompt, NL_HOOKS_NOW="2026-11-11T17:30:00+00:00"))
        check(g, "board: back after 8 hours, it's told the board changed", "status board changed" in text, text)
        out = f.session("A", "Assets", **prompt, NL_HOOKS_NOW="2026-11-11T17:31:00+00:00")
        check(g, "board: once only", out == {}, out)
        out = f.session("A", "Assets", **prompt, NL_HOOKS_NOW="2026-11-13T17:31:00+00:00")
        check(g, "board: back after two days with the board unchanged, nothing", out == {}, out)
        f.write("docs/team-notes.md", "# Team notes\n\n## Now\n\n- Builder: piece 3.\n\n## Entries\n\nnew entry\n")
        out = f.session("A", "Assets", **prompt, NL_HOOKS_NOW="2026-11-15T17:31:00+00:00")
        check(g, "board: a change outside the watched section, nothing", out == {}, out)
        f.write("docs/team-notes.md", "# Team notes\n\n## Now\n\n- Builder: piece 4.\n\n## Entries\n\nnew entry\n")
        text = ctx(f.session("A", "Assets", source="resume", NL_HOOKS_NOW="2026-11-15T17:40:00+00:00"))
        check(g, "board: a resume is told at once", "status board changed" in text, text)

        f.config("hooks", lambda d: d.update(paused={"since": "2026-11-06", "words": "we pause this game"}))
        text = ctx(f.session("B", "Builder main", **prompt))
        check(g, "pause: a running session is told at its next prompt", "paused since 2026-11-06" in text, text)
        check(g, "pause: once", f.session("B", "Builder main", **prompt) == {})
        text = ctx(f.session("P", "QA lab"))
        check(g, "pause: a new session is told at its start", "paused since 2026-11-06" in text and "QA" in text, text)
        text = ctx(f.session("N2", None))
        check(g, "pause: a session with no title is told too", "paused since 2026-11-06" in text, text)
        f.config("hooks", lambda d: d.pop("paused"))
        text = ctx(f.session("B", "Builder main", **prompt))
        check(g, "pause: lifting it is told", "pause is lifted" in text, text)

        rc, out, _ = f.run("drift_guard.py", {"session_id": "B", "hook_event_name": "UserPromptSubmit"},
                           NL_HOOKS_TEST_CRASH="drift_guard")
        check(g, "a crash warns and lets the prompt through", rc == 0 and "systemMessage" in out and not denied(out), out)
    finally:
        f.close()


def main(argv: list) -> int:
    lint_cases()
    ms = guard_cases()
    drift_cases()
    failed = [r for r in RESULTS if not r[2]]
    for group, name, ok, seen in RESULTS:
        if "-v" in argv or not ok:
            print(f"{'pass' if ok else 'FAIL'}  {group:5} {name}" + ("" if ok else f"\n      saw: {seen}"))
    print(f"hooks selftest: {len(RESULTS) - len(failed)} passed, {len(failed)} failed")
    print(f"tool guard: about {ms:.0f} ms per call on this machine")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
