# Menu layout and menu motion, at a high bar (research, cloud session, 2026-11-24)

**Why:** the director wants menus that feel premium ("premium and smooth and very appealing", 2026-11-19) and asked that Play open a panel of game modes. This turns what premium games and motion guidelines say into rules and numbers we can build on Roblox. It never takes another game's art, ornament or composition (AGENTS.md rule 3).

**Labels:** SOURCED (a page read, linked), COMMUNITY (forum or practitioner posts, informed but not measured), OPINION (research's reading, to be judged in motion).
**Gaps, said plainly:** no "GDC UI Summit" talk turned up in search, so the GDC evidence is Bungie's 2016 Destiny talk as reported. gameuidatabase.com refused the fetch (HTTP 403), so nothing here comes from it. No English interview gave numbers for ZZZ's, HSR's or Wuthering Waves' menu motion. Where those games are named, it's as COMMUNITY or OPINION, not measured. m3.material.io would not render, so the Material 3 tokens come from Google's Material Components repo. The reference video's frame study is Faber's, in `reference-menu-video.md` (same folder), and isn't repeated here.

## Layout rules

1. **Few doors at the top level, pages inside them.** A phone's bar holds about five destinations. Apple says beyond that the bar overflows into "More", and to avoid more than six tabs in a tab view. SAP's iOS guide says at most 5 compact and 6 regular. SOURCED: [Apple HIG, tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars), [tab views](https://developer.apple.com/design/human-interface-guidelines/tab-views), [SAP Fiori iOS](https://www.sap.com/design-system/fiori-design-ios/v25-4/components/navigation-and-search/tab-bar/usage).
   - For us: the dock keeps its four or five. Top tabs live only inside a screen, at most 5 on compact. Past that, use a left rail, as the Voidkin screen already does. OPINION.
2. **One primary action per screen.** Size, colour, space and nearness say what matters. Close buttons are always the same style in the same corner. SOURCED: [Roblox, UI and UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design).
   - Only one filled accent button per screen. Every other button is quiet (outline or text). The accent never decorates. OPINION, and what the reference video does (`reference-menu-video.md`, point 2).
3. **Count the taps, and keep a sense of place.**
   - **Fewer steps:** Destiny 2's Director cut travel to one step, against Destiny 1's orbit, then load, then pick. SOURCED: [Game Developer, D1 to D2 UX](https://www.gamedeveloper.com/design/ux-enhancements-from-destiny-1-to-destiny-2).
   - **Not a list:** Bungie tried and dropped a plain categorised activity menu. Jason Jones' rules for the Director were "a sense of place", "a sense of wonder", and showing the player's past, future and dependencies. The later Portal's rectangles were criticised for "pull[ing] you out of the experience". SOURCED, a report of the GDC 2016 talk: [PCGamesN](https://www.pcgamesn.com/destiny-2/portal-problems-gdc-talk-director); the talk: [GDC Vault, Tenacious Design](https://gdcvault.com/play/1023107/Tenacious-Design-and-The-Interface).
   - **For a mode panel:** art cards that show where you're going and how far you've got, never a bare list. Two taps from Play to loading.
4. **Big image cards, few per view on a phone.** Mobile needs bigger icons and text. Density should match the game: an RPG needs its information, in layers. SOURCED: [Leanne Bayley, Develop 2023, via PocketGamer.biz](https://www.pocketgamer.biz/news/81990/the-magic-that-makes-mobile-ui-look-good-and-feel-great/). Keep mobile screens minimal. SOURCED: Roblox UX page above.
   - For us: on compact, 2 to 4 cards visible. Detail goes one layer down (a tap opens it, since touch has no hover). Text on art sits on a UIGradient's dark foot, never on bare art. OPINION.
5. **Hover gives speed with a mouse, never information touch can't reach.** Destiny's hover gives "speed of information and nested interfaces", scale and colour carry the hierarchy, and you count clicks. SOURCED: [Game Developer, what to steal from Destiny's UI](https://www.gamedeveloper.com/design/what-to-steal-from-destiny-s-ui). Every hover reveal has a tap or long-press equal (ours: the dock's long press shows its word). OPINION.
6. **Currencies stay in one place and show only what the screen spends.** Destiny 2 cut its currencies and gave each token one use. SOURCED: D1 to D2 above. Our pills stay top right (`docs/ui.md`). A screen that spends something else shows that one beside them. OPINION.
7. **Safe areas and thumbs.**
   - Keep `ScreenInsets` at CoreUISafeInsets for anything pressable, and leave the bottom corners to the touch controls. SOURCED: [Roblox, on-screen containers](https://create.roblox.com/docs/ui/on-screen-containers), [cross-platform design](https://create.roblox.com/docs/ui/cross-platform-design).
   - Put the primary button at the right thumb's reach, never in a corner itself. OPINION.
8. **Back is one step, close is all the way out.**
   - Back sits top left (B, Esc) and steps one level. Close sits top right and leaves the menu. A tap on the dimmed world also leaves.
   - The input-hint footer shows only for keyboard and gamepad. On touch it's noise.
   - OPINION, consistent with the Roblox UX page's "same corner" rule.

## Motion rules, with numbers

**What the guidelines measure:**
- **Material 1:**
  - On mobile, about 225 ms in, 195 ms out, 300 ms typical and 375 ms for a full-screen change.
  - Tablet about 30% longer; desktop 150 to 200 ms.
  - "Transitions longer than 400 ms may feel too slow."
  - Exits are shorter because they need less attention.
  - SOURCED: [Material, duration and easing](https://m1.material.io/motion/duration-easing.html).
- **Material 3's tokens:**
  - Durations step 50 ms from 50 to 600 ms.
  - Emphasized decelerate is (0.05, 0.7, 0.1, 1); standard accelerate is (0.3, 0, 1, 1).
  - SOURCED: [Material Components, Motion](https://github.com/material-components/material-components-android/blob/master/docs/theming/Motion.md).
- **Emil Kowalski:**
  - Keep UI motion under 300 ms; a 180 ms select feels faster than a 400 ms one.
  - Ease-out, enter from 0.9 scale or more, never from 0.
  - Make motion origin-aware: things grow from what opened them.
  - Strip motion from things seen many times a day.
  - SOURCED: [7 practical animation tips](https://emilkowal.ski/ui/7-practical-animation-tips).
- **Nielsen:** 0.1 s feels like direct manipulation; 1 s keeps the flow of thought. SOURCED: [NN/g, response times](https://www.nngroup.com/alertbox/response-times.html).

**Our rules.** Our tokens already sit in `Config.Hud.Motion` (Screen: Enter 0.2, Exit 0.16, From 0.94). They match Material 1's 225/195 ms. The table below fills in what isn't tokenised yet. Every number is a seed, tuned live by playing.

| Moment | Duration | Easing (Roblox) | Evidence |
|---|---|---|---|
| A press answers | same frame; squeeze in 50 ms, back 140 ms | Back Out, small | SOURCED (Kowalski 0.97; vfx-reference.md, item 3) |
| Hover or focus in / out | 80 / 120 ms | Quad Out | our tokens; OPINION |
| The world dims (and blurs) behind a menu | 200 to 240 ms | Quad Out | OPINION, inside Material's range |
| A panel opens | 200 to 260 ms, from 0.96 scale and see-through | Quint Out (closest to M3 emphasized decelerate, by curve shape: OPINION) | SOURCED range |
| A panel closes | 0.8 of its open, about 160 ms, to 0.97 | Quad In | SOURCED (exits shorter) |
| Items arrive in a stagger | 40 ms apart, each 180 to 200 ms, only the first 6 to 8, the whole cascade 300 ms at most | Quart Out, rising 12 to 16 px | COMMUNITY 30 to 80 ms (vfx-reference.md, item 5); a step shorter than the item's own duration reads as a cascade ([LogRocket](https://blog.logrocket.com/css-staggered-animations/)) |
| A tab switches | old content out 100 ms; new in 160 to 200 ms, sliding 8 to 12 px from the tab's side; the underline glides 180 ms | Quart Out | OPINION, M3's short-4 to medium-1 slots |
| A card grows into its screen (shared element) | 240 to 280 ms | Quart Out | SOURCED principle (origin-aware); numbers OPINION |
| A count-up, a reward | `Config.Hud.Motion.Count`, `Fly`, `Pop` | Expo Out | already researched: vfx-reference.md; chest-opening.md |

**Budgets, the rules that keep a menu snappy:**
1. **Input is never blocked by motion.** A tap during an entrance lands. An exit can be interrupted by a re-open, which reverses from where it is. OPINION: the Nielsen 0.1 s line applies to the first answer, not the settle.
2. **From a tap:** answered by 50 ms, readable by 200 ms, settled by 300 ms, cascade done by 600 ms. Only a payoff (a reveal, a level) may run past 1 s, and only after the server's yes (`docs/ui.md`, rule 4).
3. **What's seen ten times a session gets lighter.** On a second open within a minute, the stagger is skipped and the panel only fades and scales. SOURCED principle (Kowalski; Apple HIG: no motion on the most frequent interactions). The one-minute window is OPINION.
4. **Overshoot only where a thing pops** (presses, rewards, a badge): bounce 0.15 to 0.3, never above 0.4. Panels and lists settle without overshoot. SOURCED: [WWDC23, animate with springs](https://developer.apple.com/videos/play/wwdc2023/10158/), as `vfx-reference.md` DESIGN 4 already says.
5. **Reduced Motion:** every move becomes a 150 ms fade. Already `docs/ui.md`, rule 5.

**Building it on Roblox (cost):**
- **Scale through UIScale, never Size.** UIScale scales a frame's whole contents. Size tweens distort text. A UIScale tweened inside a UIListLayout still forces relayouts, so animate a wrapper outside the layout. COMMUNITY, from DevForum search snippets (the threads wouldn't render when fetched, so no single thread is cited).
- **CanvasGroup is costly, so use it only for a moment.**
  - It draws to a texture under a memory cap that depends on quality level. Past the cap it renders blank. `Visible = false` doesn't free the memory. Tweening its size makes new textures. COMMUNITY, a staff reply as quoted in search snippets (the page wouldn't render when fetched): [CanvasGroup beta thread](https://devforum.roblox.com/t/canvasgroup-beta-group-transparency-on-ui-groups/1797885/143), [many CanvasGroups](https://devforum.roblox.com/t/using-many-canvasgroups-is-unworkable-until-proper-memory-management-methods-are-implemented/3502537).
  - So use one CanvasGroup per panel, only for the fade of its entrance and exit, then hand back to a plain Frame. Roblox's own reduced-motion fade is reported to work this way. COMMUNITY: [DevForum](https://devforum.roblox.com/t/ability-to-disable-canvasgroup/2743173).
- **Tween count matters less than what's tweened.** Lag came from thousands of instances moving, not the number of tweens. COMMUNITY: [How many tweens is too many](https://devforum.roblox.com/t/how-many-tweens-is-too-many-tweens/652213), [tycoon case](https://devforum.roblox.com/t/tycoon-dropper-effectanimation-seems-to-cause-lag-in-studio-how-to-optimize/3547407).
  - For us: a menu's open tweens fewer than about 20 objects (wrappers, not leaves). OPINION.
- **The blur is a bonus, the dim carries the read.**
  - BlurEffect blurs the whole world, can't target UI, and "may render differently on low-end devices". SOURCED: [BlurEffect](https://create.roblox.com/docs/reference/engine/classes/BlurEffect). Players report it costs GPU on phones. COMMUNITY: [DevForum, UI blur](https://devforum.roblox.com/t/blur-effects-for-ui-elements/359498).
  - So use a black dim at about 0.5 under every panel. Blur Size about 12 joins in on graphics quality 5 and up, and is off below. The world stays visible, so the menu feels part of the place. OPINION: the numbers are seeds.
- **Sheens and rarity light move by UIGradient Offset and Rotation only**, as `vfx-reference.md` DESIGN 6 already says.

## Sound on UI

- Each sound has a rank:
  - Hover is near-silent or silent.
  - A press is a short tick.
  - A commitment (Start, Confirm, Equip) is the one UI sound with presence.
  - Open and close follow the motion's direction.
  - A refusal is a soft low knock.
- COMMUNITY: [GameJuice, UI audio](https://gamejuice.pages.dev/articles/ui-audio-silent-interfaces), [Bugnet](https://bugnet.io/blog/ui-sound-design-for-indie-games). Silence is a choice, and players can turn UI sound down. SOURCED: [Material, applying sound to UI](https://m2.material.io/design/sound/applying-sound-to-ui.html).
- One family for all of them, from Roblox's library, layered at runtime and logged (AGENTS.md rule 2; `docs/research/sound.md`). A tab switch and a scroll are silent. OPINION.

## Lessons from the reference video (adds to `reference-menu-video.md`, not a repeat)

- **Good, and why:**
  - The blurred world behind the glass keeps "a sense of place" (Bungie's rule, above).
  - The single gold primary with a quiet secondary is rule 2 above, done well.
  - Reward chips on the featured card show the pull before the commitment.
  - "Next:" makes Home answer what to do now (ours: Today, with Next pinned).
  - A list on the left with a hero on the right reads fast on desktop.
- **Don't take, or take with care:**
  - Don't take its composition (navy frosted glass, serif display titles, a gold accent, the top strip of eight tabs, the greeting title's form). Together they are its expression; ours is the asset maker's kit (`docs/ui.md`, rule 3).
  - Eight top tabs don't fit a landscape phone (rule 1 above).
  - Hairlines and small grey caps will break our 14 px and contrast floor on a phone.
  - The footer hint bar is right for keyboard and gamepad only.
  - The Party lobby (READY states, a party code) isn't in our scope.
- **A disagreement with the sibling note's "locked future modes as teasers":**
  - Show a locked card only for something that exists, with its real condition (Hard until the Lamplighter falls; a future Arc once it's built). A card for an undesigned mode is a placeholder in a public build, and it promises what the interface can't keep (`docs/ui.md`, rule 4). OPINION.
  - The better alternative costs nothing: show the modes that exist, and add a card the day a mode ships.

## For our Play / mode panel

**Where it stands:** TR50 built Play to open the Arc panel straight away (`docs/team-notes.md`, the 2026-11-19 23:58 entry), per the register's 23:19 row, part 3, "while the Festival of Battles is the only mode". The director now wants the mode panel. The Tower is a second mode, so the mode layer has its reason. Whether the register row needs correcting is `play-mode-panel.md`'s business. Putting the Tower in the panel is a new way into it: today you walk to its entrance behind the base (`docs/design.md`, "The Tower"). That's **tier 2** (research, Faber, Modulo for the cards' art).

**The layout (compact, landscape), OPINION:**
- **The frame:** over the dimmed world, a back button top left (shown on the second level), close top right, the currency pills where they always are.
- **The mode cards:** one large art card per mode, side by side, 2 now.
  - **What each card holds:** its own art, its name, one line of what it is, and the player's progress (Festival: "Lantern Row, Normal, stretch 2 of 4"; Tower: "Record floor 23"). Then the recommended CR beside the player's, in green, amber or red (`docs/design.md`, "The pull"), and two or three reward chips.
  - **One primary per card,** at the right thumb's reach.
- **The two-tap path:**
  - The Festival card's primary is **Continue** with the last Arc and difficulty, so Play to loading takes 2 taps.
  - A tap elsewhere on the card opens the Arc panel: Arcs on the left, the hero art and the Normal/Hard tiles on the right, Start under them.
  - The Tower card's primary is **Climb**, straight into a run, if tier 2 agrees.
- **On desktop (wide):** the same cards, wider, with room for a third mode before anything scrolls.

**The motion, seeds for `Config.Hud.Motion`:**
- **Play pressed:** squeeze 50 ms, back 140 ms.
- **The panel opens:** the dim rises 0 to 0.5 over 220 ms (Quad Out), blur on high quality. The panel goes from 0.96 to full over 220 ms (Quint Out). The cards follow 40 ms apart, each 200 ms, rising 16 px. Settled by about 300 ms, and tappable from the first frame.
- **Card focus or hover:** rim light and lift over 80 ms. Reconcile `Hover.Card` = 1.06 against a 1.03 scale for a large card, by playing.
- **Mode to Arc:** the chosen card grows to the Arc panel's left column over 260 ms (Quart Out). Its neighbour fades in 120 ms. The Arc content slides 24 px in from the right, starting at 60 ms. Back plays the reverse in about 200 ms.
- **Start pressed:** the button charges while the server answers. On its yes, a 120 ms light sweep over the card, then the commitment sound. The panel exits in 160 ms and travel's own transition takes over. On a no, a 200 ms shake and the reason in words.
- **Close:** 160 ms, Quad In, to 0.97, with the dim falling alongside. Reduced Motion: fades of 150 ms throughout.

## Top 5 to act on

1. **One press number, one home.**
   - `Config.Hud.Motion.Press.Squeeze` is 0.92, `docs/ui.md` rule 5 says "about 0.94", and `vfx-reference.md` DESIGN 2 says 0.96. The sources say 0.95 to 0.97.
   - Pick one seed (0.95) in Config, tune it by playing, and drop the number from `docs/ui.md`: tunable numbers aren't copied into docs (AGENTS.md, "Where the truth lives").
2. **Adopt the time budget as a rule.**
   - Answered by 50 ms, settled by 300 ms, cascade done by 600 ms, input never blocked, lighter on a repeat open.
   - Add it to `Config.Hud.Motion` as tokens (Dim, Stagger, Tab, Grow) so no screen makes its own tweens.
3. **Build the mode panel as art cards with progress, CR and one primary each,** with Continue for a 2-tap return and a shared-element grow into the Arc panel. The Tower card goes to tier 2 first.
4. **The dim carries every menu; the blur only on high quality.** Use a CanvasGroup only for a panel's fade, never resized. Scale with UIScale on wrappers outside the layouts.
5. **Navigation discipline.**
   - The dock keeps five doors at most. Tabs sit inside screens, at most 5 on compact, with a rail beyond.
   - Back top left, close top right, a world tap closes.
   - Input hints only for keyboard and gamepad. One accent button per screen.
