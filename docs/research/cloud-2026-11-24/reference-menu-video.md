# The reference menu video (director, 2026-11-24)

The director shared a 26-second screen capture of another Roblox game's menu: "take note on the good part cause visually it looks good, im not saying to do the same". Studied by Faber from frames sampled once per second. The video stays internal: it is not committed and nothing is traced from it. These are lessons for feel and readability, not a blueprint (AGENTS.md rule 3: function is free, expression is ours).

## What it is

A full-screen menu that replaces the HUD while it's open. The 3D world stays visible behind it, blurred and darkened. A thin tab bar runs across the top: Home, Hero, Relics, House, Party, Dungeons, Goals, Shop. Currencies and the player's name and level sit at the top right, and a footer hint bar sits at the bottom (Select, Crew, Settings, "ESC Back to the world").

## The good parts, and why they work

1. **One surface, one material.** Every screen is the same dark navy frosted glass over the blurred world. No screen has its own frame or colour, so moving between eight tabs feels like one place. OBSERVED.
2. **One accent, used only for the primary action.** Warm gold appears only on the button that does the main thing ("Set Sail", "Buy & Apply", "Guide me there") and on the small currency marks. Everything else is white, grey or navy, so the eye finds the action in under a second. OBSERVED; the reading time is OPINION.
3. **Type does the hierarchy.** Big serif display titles in near-white ("Set Sail, <name>", "The Sunken Cove"), small grey caps labels above them ("FEATURED VOYAGE", "TIER 2 · POWER 120"), and plain sans text for details. There are three sizes and no boxes inside boxes. OBSERVED.
4. **The image carries the screen.** Each destination is a large picture, with its title set on a dark gradient at the card's foot. The art sells the place, and the UI stays quiet. OBSERVED.
5. **Home answers "what do I do now".** It opens with one featured card (the next voyage, its reward chips, the gold "Set Sail" button and a quiet "Sail alone"), plus a "Next:" objective chip at the top right. Smaller cards around it lead to the other places. OBSERVED.
6. **Locked content teases instead of hiding.** The Destinations list shows "Uncharted" rows with a "?" thumbnail, so the player knows more is coming. OBSERVED.
7. **List on the left, hero on the right.** Destinations is a short list of thumbnails on the left and a large preview on the right. Pressing a row swaps the preview, and the action sits under it. It's a standard, very readable pattern. OBSERVED.
8. **Social is built into the flow.** The Party screen sits between choosing a place and leaving: crew cards with READY states, a party code, and "In Server, Friends, Recent" tabs. OBSERVED. We are solo-first, so this is a note for later, not now.
9. **Goals on one screen.** The next main objective with a "Guide me there" button, side quests, daily and weekly lists with rewards, milestones as a vertical track, and achievements. OBSERVED.
10. **A footer hint bar** shows the input for each action, which helps a gamepad and keyboard player and costs one line. OBSERVED.

## What not to take

- **Its look as a whole.** The navy-and-gold serif frosted look is that game's expression. We take the principles (one material, one accent, type hierarchy, image-led cards), not the palette, the fonts or the layout as a composition.
- **Eight top tabs on a phone.** They're dense at 480p and would be hard to tap on a phone. The video looks like a desktop capture. Our dock-first phone layout should stay. A top bar fits desktop only.
- **The full-screen takeover for everything.** It suits a menu-hub game. In ours the world, the lead and the base are the show, so quick actions should stay light panels.
- **Small grey text.** Several labels are tiny grey on navy, which will fail contrast on a phone (see `ui-colour-review.md`).

## What this means for our Play button

The video's flow is Home's featured card → Destinations (list + hero) → go. Our Play should work the same way: a **mode panel** with one large image card per mode, its title on a gradient, one line of what it is, and one primary button.
- Festival of Battles first; pressing it opens today's Arc panel.
- The Tower second, with its record.
- No teaser card for a mode that doesn't exist yet: "never a placeholder" holds. A mode that exists but is shut shows its lock and its real condition, which is the video's "Uncharted" idea applied honestly (`menu-layout-and-motion.md`).

The director asked for exactly this on 11-19 ("when we click on it it show a panels of gamemode"). The register recorded the opposite (`docs/decisions.md`, the 2026-11-19 23:19 row, part 3), and TR50 built Play straight to the Arc panel. The correction and the build-ready entry are in `play-mode-panel.md`.
