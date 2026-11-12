---
name: "ga-reference-study"
description: Study reference footage and screenshots to answer one design question, cheaply and inside the IP rules, and write the findings as an OBSERVED and DESIGN study. Use before designing a map, region, enemy, boss, screen or effect from a reference.
---

# Reference study

## Where the evidence is

- **The written study, read it first:** `docs/research/gear-icons.md` (gear icons and the forge screen, from Taichi Panda 3: Dragon Hunter screenshots in `build/reference/dragon-hunter/`). When the director names a reference, research writes its study under `docs/research/` and names it here: a survey of the footage by topic, with measured bursts, so nobody opens a video to answer a question already answered.
- **The footage and images:** `build/reference/`, gitignored, never uploaded. `inbox/` is where the director drops new ones. Whoever studies one moves it to its home and names it in the study.
- **Study evidence only:** never copy frames, crops or traced shapes into the game or the repo. Git keeps our notes and our own drawings.

## Study without wasting tokens

1. Write the question down first, for example: "how is the match map structured: how many regions, how big, how they connect, how vertical?"
2. Search the written docs for the timestamps that answer it. Open only the images the docs point to, or the ones needed for what the docs can't answer.
3. Contact sheets before single frames: one sheet shows many moments. Then open only the frames that matter, as downscaled copies in `build/scratch/<teammate>/` (about 1280 px wide is plenty), never the video itself. Extract a new frame only for a gap the sheets can't fill.
4. A ruling on a form comes from the highest resolution you have, cropped and enlarged. A low-resolution read isn't a measurement.
5. Stop when the question is answered, and list the images you looked at, so nobody repeats the work.

## What to record

- Write the study where the task says: each finding with its timestamp and a label: OBSERVED (seen in an image), MANUAL (an official guide) or DESIGN (our adaptation). Unknowns stay unknown. Never present a guess as a measurement.
- Capture structure, not appearance: scale against the player and the jump kit, the number and size of regions, how regions connect, walking layers, landmark rhythm and sightlines, route types, where fights happen, light and atmosphere per phase.

## The IP line (AGENTS.md, supreme rule 3)

- **Study, never take:**
  - **Analysis** (allowed): why a frame works, in hierarchy, timing, scale, contrast and light.
  - **Original design from those principles** (the goal): our own shapes, ornament, icons, motion, names and code.
  - **Reuse or close reproduction** (never): a crop, a trace, a recolour, an AI transformation, or a distinctive composition rebuilt.
- **Footage is a benchmark for feel and readability, never a blueprint.** Never take its layout, region shapes, landmarks, names, characters, kits, signature skills, or a specific shot. Familiar functional patterns are fine. Their art isn't.
- **Screenshots and frames stay internal.** They live in `build/reference/` or `build/scratch/<teammate>/`, both gitignored. They're never uploaded to Roblox, never published, never fed to an image tool, and never source material for anything we ship.
- **Restricted footage needs extra care.** If participants in a closed test weren't allowed to share captures, keep that footage strictly private, study it for principles only, add no verbatim transcriptions to anything public, and prefer official public material for new studies.
- **Quick checks:**
  - **Yes:** study a HUD's readability, then design ours with familiar slots and our own art. Study a game's lighting depth, then build our own space. Study a polished game's motion cadence as a quality bar, then design our own effects.
  - **No:** crop or trace an ornament, emblem or frame; recolour a UI; rebuild a character, signature weapon, skill or scene; treat a percentage of change as safety.
- **Close the images before designing.** Design from your written findings and our own world, then compare. If anything echoes theirs, change the expressive detail, not the useful function.
