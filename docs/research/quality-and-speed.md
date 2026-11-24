# Quality and speed: why we iterate and it stays ugly, and the new way

Research (Quaestor), 2026-11-24, evening, from the cloud, on the director's words: "i want you to discover shortcut, learn stuff that make us be more productive while making the quality higher cause we had to iterate on so many stuff yet it still ugly", then "not only ui everything … not waste time thinking we are doing something premium for it to turn into a big pile of shit like that 20 hours making a horrendous looking dodge on umbra vesper".

**Adopted:** the director said yes on 2026-11-24, 20:50 to changes 1 to 5, and to 6 with Edge tried before any install (`docs/decisions.md`, the top row). They're written into `AGENTS.md`, `ga-review`, `ga-action` and `ga-fresh-eyes`, into AR62 (the style frame) and TR63 (Faber's tools).

Labels: OBSERVED (in our records), SOURCED (link), OPINION (research's). A = `docs/asset-requests.md`, D = `docs/decisions.md`.

## What went wrong (OBSERVED)

1. **Research's verdicts pass what the director rejects.**
   - On four three-way look picks, the director chose differently from research every time (`docs/research/cloud-2026-11-24/directors-taste.md`, line 10).
   - "Competent" appears 271 times in A, and the pass line is set to it (`.claude/skills/ga-review/SKILL.md`). Watt was "competent, no obvious issue" just before "horrible" (A, 6348).
   - The blind reviewer is told never to compare with a reference, and its examples folder doesn't exist (`.claude/agents/ga-fresh-eyes.md`, lines 15 and 20).
   - The skills say "This game has no reference footage, so judge the feel directly". So every verdict is an AI's eye judged against nothing.
2. **No target image before the hours.**
   - No piece had a final-quality target approved before it was built.
   - References came after the rejection: Watt was set beside Anime Vanguards only when the director asked (A, 5914).
3. **Judged on the wrong medium.**
   - About 125 verdicts cite Blender sheets or renders, against 66 that cite the game.
   - Teal passed on sheets and was rejected in screens (D, 50).
   - The one look iterated live over in-game screenshots, the base, got "perfect" (D, 256 to 261).
4. **Many small pieces, never one fixed style.**
   - UI came as about 18 separate requests, with six panel grounds, six pill bodies and about nine golds (`ui-colour-review.md`, line 7).
   - Colour was faulted six times between 11-15 and 11-24 (D, 18, 50, 87, 280).
5. **Patching inside a failed technique.**
   - Our "20-hour dodge" is Pip's Lantern Burst: about 15 h and two "competent" rounds, then "i despise those 2d cartoonish fire vfx" (D, 212).
   - The record had said flat cards "failed three times" two days before (A, 4155 to 4160).
   - Hair was patched twice per character, then rejected (A, 17039, 17417).
   - Rook's Haymaker took 11 h and four "works" verdicts, each saying exceptional would come later (A, 37, 190).
6. **A slow, blind loop, and the look parked for the end.**
   - No phone play since 11-17. Effects are marked "Visually reviewed: no" (A, 15929, 17330).
   - The fixes were already written in eight of our own studies (directors-taste, character-art-pipeline, animation-craft, vfx-quality, ui-colour-review, menu-layout-and-motion, devforum-ui, orchestration). None reached a skill or a rule.

## What works elsewhere (SOURCED)

- **A fake screenshot as the ground truth.** An art director paints one final-quality "fake screenshot of a key moment", and after each milestone the team compares the build with it and lists the deviations ([Boury](https://charlesboury.fr/articles/fake-screen-it.html)). Hades' modeller sculpted with the painted portrait behind the model ([Game Developer](https://gamedeveloper.com/art/learn-how-supergiant-brought-i-hades-i-hand-painted-characters-to-life)).
- **A style that forgives a small team:**
  - TF2 was built on silhouettes and readable value ([Valve, NPAR 2007](https://cdn.fastly.steamstatic.com/apps/valve/2007/NPAR07_IllustrativeRenderingInTeamFortress2_Slides.pdf));
  - Guilty Gear Xrd on cel shading and stepped keys without interpolation ([GDC](https://gdcvault.com/play/1022031/GuiltyGearXrd-s-Art-Style-The), [Game Watch](https://game.watch.impress.co.jp/docs/news/20150307_691725.html));
  - Dead Cells' single artist used a 3D-to-toon pipeline "to make up for the lack of bandwidth" ([Game Developer](https://www.gamedeveloper.com/production/art-design-deep-dive-using-a-3d-pipeline-for-2d-animation-in-i-dead-cells-i-)).
- **AI judges are reliable at pairs, not at scores.** Vision models judge "human-like" when comparing two images, and show "significant divergence" when scoring one ([MLLM-as-a-Judge](https://arxiv.org/abs/2402.04788)). They favour whichever is shown first ([Zheng et al.](https://arxiv.org/abs/2306.05685)). Few-shot examples and marks on the image beat zero-shot critique by 55%, still under experts ([UICrit](https://arxiv.org/abs/2407.08850)). Unsteered models drift to the generic look ([Anthropic](https://claude.com/blog/improving-frontend-design-through-skills)).
- **Motion is judged poorly by models** (under 60% on fine motion, [arXiv 2501.02955](https://arxiv.org/abs/2501.02955)): judge poses on contact sheets and in play, and timing by numbers.
- **Animation: poses first, stepped, curves last.** Cooper: iterating "with a roughly key-posed animation is much easier", and long anticipation on a player's move feels unresponsive ([Game Developer](https://www.gamedeveloper.com/production/the-12-principles-of-animation-in-video-games)). Roblox plays stepped keys natively (`Enum.PoseEasingStyle.Constant`).
- **Effects: one hero shape,** peak early in its life, a short fall-off, one dominant hue ([Riot's VFX style guide](https://nexus.leagueoflegends.com/wp-content/uploads/2017/10/VFX_Styleguide_final_public_hidpjqwx7lqyx0pjj3ss.pdf)).
- **Timeboxes need checkpoints, not only caps:** "Spontaneity is more valuable than time spent trying to salvage" ([Experimental Gameplay Project](https://www.gamedeveloper.com/game-platforms/how-to-prototype-a-game-in-under-7-days)).
- **Roblox UI:** Studio's own Frame, UIStroke, UICorner and UIGradient cover flat styles; glows, ornaments and icons are drawn outside. Reusable components keep quality, text isn't baked in, and design is mobile first ([DevForum 3266163](https://devforum.roblox.com/t/3266163), [3074034](https://devforum.roblox.com/t/3074034)). Images cap at 1024 px; frames stretch by 9-slice.

## The new way (research's proposal)

Seven changes, each with what it replaces:

1. **The frame before the hours.** Every piece players see starts with one target image at final quality, in the game, made in at most 3 hours:
   - a screen: a paint-over on a real phone capture;
   - a move: its 4 to 6 key poses, stepped, from the game's camera;
   - an effect: its peak frame and a strip of its life;
   - a model: a turnaround in the game's light, beside the cast;
   - a sound: unchanged, since the director's ear already picks every cue on its frame (TR42's panel), which is this same rule.
   The maker brings two or three, **the director picks one** (about two minutes), and only then does a build hour start. Research's blockout verdict no longer opens a build. It replaces "feel line → blockout → research's verdict".
2. **Lock the look once.** Before more UI or Voidkin pieces, one Home screen and one Voidkin in the game's light become the style frame, and its tokens are fixed in one page:
   - three hues and neutrals;
   - two fonts and one type scale;
   - two or three stroke widths and corner radii;
   - one material family.
   AR62 becomes this. Every later piece derives from it. Tier 3: it's the game's identity.
3. **Verdicts in pairs, in the game, against the target.** Research's verdict becomes:
   - the gates, measured: the squint (blurred) test, greyscale, a black silhouette at 64 px, the UI lint (7);
   - then the build beside its target, at phone size, in both orders, with the gaps listed by where they sit;
   - then "closer to the director's accepted or rejected examples?", from `docs/research/examples.md`, which research keeps from the director's recorded words (the folder `ga-fresh-eyes` names, `docs/reference/examples/`, was never made).
   No look passes as "competent" on research's eye alone. It replaces `ga-review`'s Felt and Tier pass line, and `ga-fresh-eyes`' "never compare".
4. **Checkpoints with a kill point.** At a quarter and at half of a piece's cap, the build sits beside its target. A miss on the main read changes the technique or simplifies; it's never polished. Two techniques missed, and the director picks from images. This adds checkpoints to the caps (`AGENTS.md`, "Blocks first").
5. **Moves posed first, stepped.** A move's key poses are judged stepped (constant interpolation) in the game before any curve exists, and the anime look may stay stepped where it reads better. Its timing is written in frames first, from the feel line. Added to `ga-action`, step 3.
6. **UI art as drawings, not paint.** UI images are written as SVG and rendered by Inkscape at twice the display size (within 1024 px), instead of being painted with numpy in Blender. Text stays live in Studio, and frames use 9-slice. SVG is something an AI writes well. Needs Inkscape on the PC: free, official, no account, the director's OK to install.
   - **Tried in the cloud, 2026-11-24 (OBSERVED):**
     - Six pieces (a 9-slice panel, two buttons, a bar, a close mark, a gem) were written as SVG from one token set and rendered at 2× with transparency.
     - Two token sets rendered in 1.1 s, and a re-theme was a token edit only. Edges are clean, and the 9-slice held with its glow outside the box, as an ImageLabel larger than its button would hold it.
     - The renderer was a headless browser, with no install. On the PC, Edge ships with Windows and could do the same, but this is UNVERIFIED there, so Inkscape may not be needed.
     - What it didn't do (OPINION): the pieces look tidy but generic. The technique buys speed and consistency, not taste: the look still comes from 1 and 2.
     - Script and renders: `build/scratch/quaestor/svg-test/` (gitignored, throwaway).
7. **Machines check what eyes tire of.**
   - **The UI lint grows** (Faber). `SelfTestController/UiLint.luau` already checks fit, text size, touch size, safe areas and overlap. It gains text under 4.5:1 contrast ([WCAG](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)), and any colour, stroke or radius outside the style frame's tokens.
   - **The pair sheet** (Faber). The capture already exists: `tools/capture/grab.ps1` records the window, and `tools/capture/moments.py` lays a take out as a sheet. What's missing is one step after it: the build and its target at phone size in both orders, with a blurred (squint) row and a greyscale row under them, as one image. That's what makes 3 and 4 cheap.

## What it costs, and what it saves (OPINION)

- **Costs:**
  - the director's two minutes per target, about one a day;
  - a style frame of about a day, Modulo and research;
  - the lint and the pair sheet, about half a day of Faber's time;
  - Inkscape, and Krita for paint-overs, installed with the director's OK.
- **Saves:** the rounds after the build. The Voidkin look has been open since 11-12, the colour since 11-15, and the Lantern Burst took 15 h. Each of those would have stopped at its target.
- **What it doesn't fix:** taste still has to come from somewhere. The director's picks and accepted examples become the team's bar, so the bar is the director's, never research's guess.
