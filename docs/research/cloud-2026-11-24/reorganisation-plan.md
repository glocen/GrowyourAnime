# Reorganising without breaking or forgetting anything

Faber, cloud, 2026-11-24. The director: "you have fable to re organize many stuff but dont break or forget something". This page says what was reorganised here, what is ready to run on the PC, and what is proposed next. Each step is lossless, has a check that proves it, and has a way back.

**Why not just do it here.** This branch is 137 commits behind main, and the docs belong to teammates who are mid-piece on the PC. Reorganising their files on a stale branch would break the merge. So the tool and its proof are built here, and the builder runs it on main at a quiet moment.

## The problem, measured on main (2026-11-24)

| File | Lines | Words | What it is |
|---|---|---|---|
| `docs/asset-requests.md` | 17,054 | 389,823 | 60 pieces' whole records in one file; the largest piece is 1,270 lines |
| `docs/test-requests.md` | 4,931 | 110,488 | 54 pieces |
| `docs/decisions.md` | 357 | 30,364 | 253 dated rows in one table; 29 lines are over 1,000 characters |
| every other doc in `docs/*.md` | about 2,000 | about 68,000 | fine |

- 83% of the words in `docs/*.md` are in the two request files. MEASURED.
- 80 of the 114 pieces have no `**Status:**` line, so nobody can list what's open without reading. MEASURED.
- Nothing may be read whole, so every session searches a 17,000-line file to find one piece.

## Step 1, ready: one file per piece

**The tool:** `tools/docs/split_requests.py` (on this branch). It turns `docs/asset-requests.md` into a 165-line index plus `docs/requests/AR1.md` … `AR60.md`, and `docs/test-requests.md` into a 64-line index plus `TR1.md` … `TR54.md`.

**Why nothing breaks:**
- The old paths stay, as indexes. 323 places in the code and docs say "`docs/asset-requests.md`, AR12" or the like, and each still leads to the piece: the index's line links its file. No reference is rewritten.
- Text that isn't a piece ("Later, by ground", "Next, not yet written", the top of each file) stays in the index, word for word, in its place.
- No hook's config names either file (checked in `.claude/hooks/config/`).

**Why nothing is forgotten:**
- Before it writes anything, the tool joins its own output again in memory and refuses unless the bytes match the original.
- The index records the SHA-256 of the file as it was. `check` proves the pieces still join to it, or says they've been edited since.
- `join` writes the one file again, byte for byte. That's the way back, beside the git commit.
- It refuses an id that appears twice, a file that is already an index, and a folder that already holds a piece.

**Tested here:**
- its self-test: 17 checks pass (`python3 tools/docs/split_requests.py selftest`), including Windows line ends, a heading inside a code fence, a missing piece and a stray file;
- on a scratch copy of main's two real files: 60 and 54 pieces, and the joined files compare identical to the originals with `cmp`.

**To run it on the PC** (the builder, at a piece boundary, about 5 minutes):
1. Every session has committed its edits to the two files: `git status --short docs/asset-requests.md docs/test-requests.md` prints nothing.
2. `py tools/docs/split_requests.py split docs/asset-requests.md --dry-run`, then without `--dry-run`; the same for `docs/test-requests.md`.
3. `py tools/docs/split_requests.py check docs/asset-requests.md` and the same for the test file: both say "byte for byte".
4. Commit by path: the two indexes and `docs/requests/`. It's docs only, so Rojo isn't touched.
5. Tell the team in one line on the board: a piece's record is now its file in `docs/requests/`.

**What needs the director's yes** (a rule's wording, so a restatement first): in `AGENTS.md`, "Where the truth lives", the row "A piece's record | its entry in `docs/asset-requests.md` or `docs/test-requests.md`" becomes "its file in `docs/requests/`, listed in `docs/asset-requests.md` or `docs/test-requests.md`". Nothing else in the rules changes. The briefs' and skills' mentions of the two files stay true, since the indexes stay.

## Step 2, proposed: a status every piece can be listed by

After the split, each piece's file gets one `**Status:**` line under its heading, from five words: **queued**, **in progress**, **waiting on** (who), **closed** (date), **cut** (date, why). `split --refresh` then copies it to the index, so the index is the list of what's open. It's a one-time pass by research over the 80 pieces that have none (the list is the index's "see the piece" lines). About an hour, and tier 1: it writes nothing new, only a label.

## Step 3, proposed: closed pieces leave the working folder

A piece that is closed moves with `git mv` to `docs/archive/requests/`, and its index line's link follows. The working folder then holds only what's alive. History stays whole: `docs/archive/` is already "History" in the rules' table. Research decides when; it needs no new rule.

## Step 4, proposed: the decision register gets a top page

`docs/decisions.md` is a 253-row log. It answers "what did the director say on the 19th" well, and "what's the standing decision about Play" badly, which is how the Play misreading survived a week (`play-mode-panel.md`). Proposed, for research: a short "Standing decisions" section at the top with one line per topic and the date of the row that holds it, at most 40 lines. The rows below stay untouched, and the top page only points. `directors-taste.md` (in this folder, when it lands) is the raw material.

## Step 5, proposed: one list of what's next

The order of work is written in four places today: `docs/production-plan.md` ("Phases"), the Now board's order lines, "Later, by ground" in the asset requests, and "Next, not yet written" in the test requests. Proposed: one ranked list in `docs/production-plan.md` (Now, at most 3 per teammate; Next; Later), and the other three link to it. This changes how the team works, so it's the director's call (`directing-the-game.md`, item 3).

## What should not be reorganised

- **`src/`.** Its layout matches `default.project.json`, every test passes on it, and a move there risks Studio. No gain.
- **The handbook.** It's the studio's, shared across games.
- **The older studies in `docs/research/`.** They're cited by design lines. An index by subject is enough: see this folder's `README.md`.
