## The cloud, as research measured it tonight (2026-11-28, about 02:20 to 03:00 UTC, in a cloud container)

These are observations, not assumptions. Re-check the first three in your first five minutes.

- **You are on Linux** (Ubuntu 24.04, 4 cores, about 15 GB of memory). The repo is a fresh clone. There's no Roblox Studio, no Studio MCP, no Rojo session, no Open Cloud key, no Gemini or Codex, no `build/scratch/`, no `build/reference/` (git ignores both, so no shipped game's frames are here), no `handbook/` (it lives outside this repo), no PC memory, and no other teammate's uncommitted work.
- **The team's hooks don't run here.** Every hook in `.claude/settings.json` starts `py`, which Linux doesn't have. The effects:
  - the shell tool guard, the memory guard, the role recorder and the drift guard are silently off;
  - every `mcp__*` tool is refused, because the MCP guard fails closed. That includes GitHub's MCP tools, which you don't need: git itself pushes through the session's proxy.
  - **Don't repair or route around this.** Don't create a `py` shim, don't edit anything under `.claude/`, and don't change permissions. Research tested a shim: the guards then run, but no session here has a signed teammate title. So the role is "unknown", every `git push` is refused, and the night's work couldn't be saved. A Linux-aware hook layer is a change for the director's yes (`CLAUDE_CODE_REMOTE=true` marks a cloud session), never tonight's work.
  - **Keep the off guard's rules by hand:** never `git stash`, `git clean`, `git add -A/./-u`, `git commit -a`, or any force push. Never `git pull`, `rebase`, `merge` or `switch` onto another branch. Never `rojo upload`, never call `apis.roblox.com` or `rbxcloud`, and never handle `ROBLOSECURITY`. The deny list in `.claude/settings.json` still works, because it's Claude Code's own.
  - **The reference guard's pre-commit doesn't run here either.** Before every commit, run `python3 tools/checks/reference_guard.py`. A failure means the commit doesn't happen.
- **Tools, installed in about a minute from their official sources** (research ran each of these tonight, and they worked):

  ```bash
  B=/tmp/tools && mkdir -p $B/bin && cd $B
  curl -sL -o lune.zip https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip
  curl -sL -o rojo.zip https://github.com/rojo-rbx/rojo/releases/download/v7.7.1/rojo-7.7.1-linux-x86_64.zip
  curl -sL -o lsp.zip  https://github.com/JohnnyMorganz/luau-lsp/releases/download/1.70.1/luau-lsp-linux-x86_64.zip
  for z in lune rojo lsp; do unzip -o -q $z.zip -d bin; done; chmod +x bin/*
  export PATH=$B/bin:$PATH   # repeat this export in every new shell command, since the shell's environment doesn't persist
  cd /home/user/GrowyourAnime   # or wherever the repo is cloned
  lune run tools/checks/logic_offline.luau src/server/Services/Core/LogicTestService/Cases   # tonight: 78,495 passed, 0 failed (4 s)
  lune run tools/checks/models_offline.luau                                                 # tonight: 6 models, 0 differences
  python3 tools/checks/luau_check.py                                                        # tonight: 0 new, 11 known (7 s)
  ```

  These are the versions pinned in `rokit.toml`. Rokit itself isn't needed. Use `python3` wherever a doc says `py`.
- **Blender, when your queue needs it:**

  ```bash
  mkdir -p /tmp/bl && cd /tmp/bl
  curl -sL -o b.tar.xz https://download.blender.org/release/Blender5.3/blender-5.3.0-linux-x64.tar.xz   # 407 MB, about 16 s
  curl -s https://download.blender.org/release/Blender5.3/blender-5.3.0.sha256 | grep linux-x64   # compare with: sha256sum b.tar.xz
  tar -xf b.tar.xz && rm b.tar.xz
  apt-get install -y -q libegl1 libgl1 libxkbcommon0 libxi6 libxrender1 libsm6 libxxf86vm1 libxfixes3 libegl-mesa0
  BLENDER=/tmp/bl/blender-5.3.0-linux-x64/blender   # use "$BLENDER -b --factory-startup --python <script> -- <args>" wherever a doc says blender.exe
  ```

  Measured tonight: Cycles on the CPU and Workbench render in under a second for a small scene, and EEVEE works through software Mesa, with about 40 s for its first frame (shader compile). There's no GPU. Prefer Cycles CPU with modest samples, or Workbench for blockouts, and use EEVEE only where a look depends on it. The director's PC runs the Steam build, whose exact version isn't recorded. 5.3.0 is the latest official release, so note "rendered in Blender 5.3.0, Linux, CPU" on every cloud render, and expect small differences from the PC.
- **Other tools:** Python 3.13 with Pillow 13 and NumPy 2.5, ffmpeg, Node 22, and headless Chromium through Playwright (`require('playwright')`; never `playwright install`). Free, trustworthy packages from official registries (PyPI, apt, npm) are allowed by the director's word tonight. Install only what your queue needs, and name each in your handoff.
- **Usage is one shared budget.** Every cloud session draws on the director's one subscription, and parallel sessions spend it proportionately. If you hit a usage limit, the session stops until the window resets. Nothing documented resumes a cloud session by itself, so commit and push often, and you lose at most one piece.
- **An idle VM pauses after a few minutes and can be reclaimed.** Its files go with it, but the conversation stays. Never leave work uncommitted between pieces. Never `sleep` or loop to look busy: the director said so, and it wastes the shared budget.

## Git: your branch, your paths

- **Your branch** is the development branch your session's own system instructions assign (normally `claude/...`). Work, commit and push only there, with `git push -u origin <that branch>`. On a network error, retry up to four times, waiting 2, 4, 8 and 16 s. Never push to `main` or to any other branch, never force, never merge, never open a pull request. The director and Faber integrate in the morning.
- **Commit as the studio does,** by path, with the role prefix and the session's attribution lines:
  `git add <your new files>` then `git -c user.name=glocen -c user.email=92930182+glocen@users.noreply.github.com commit -m "<Name>: <what changed and why>" -- <paths>`
- **Commit after every finished piece** and push straight after. Push at least every 90 minutes even mid-piece, as a commit titled `<Name>: WIP <piece>`, when the piece's partial work is worth keeping.
- **Shared files nobody edits tonight,** so that five branches merge cleanly in the morning: `AGENTS.md`, `CLAUDE.md`, `.claude/**`, `docs/team-notes.md`, `docs/asset-log.md`, `docs/asset-requests.md`, `docs/test-requests.md`, `docs/production-plan.md`, `docs/polish-later.md`, `default.project.json`, `rokit.toml`. Research alone writes `docs/decisions.md`. What you'd have written in one of these goes in your handoff file, under "For integration", word for word, so the integrator can paste it.
- **Your handoff file** is `docs/overnight/2026-11-28/<Name>.md`, and only you write it. It's your memory across compaction and the morning's integration record. Keep it short: what each piece is and how far it got (implemented, offline-tested, independently reviewed, visually reviewed, Studio-verified, director-accepted, each said separately), its commits, blockers, and "For integration".
