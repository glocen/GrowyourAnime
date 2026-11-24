# Taking the wheel back: the steering brief, 2026-11-24

Faber, from a cloud session while the director is busy. It answers the director's words of 11-24: "we are lossing control of the wheel and are heading in a piles of nonsense", and "it fine to confront my idea and choice". It is one page that ranks what to do, drawn from the studies in this folder.

**Every item is a proposal.** Anything touching the core, a confirmed decision, the economy or scope waits for the director's yes to a plain restatement (`AGENTS.md`, "Changing the core"). Research leads in the director's stead (`docs/decisions.md`, 11-24 01:58) and records what's accepted.

## The diagnosis, in five lines

1. **The engineering is solid and ahead of the game.**
   - Pure rules have tens of thousands of offline checks, and the server owns every valuable.
   - Every flow that moves a valuable now has a seeded, mutation-checked fuzz run: shards, gear, Regalia, stars, the shop, the Tower, the keeper and the Breaker.
2. **Nobody outside the team has played it.** The director's last phone run was 11-17. A private save of the build to Roblox, for the director's own phone run, has waited about 8 days.
3. **The deep game was built before the small loop was proven fun.** It has 14 gear slots, Reinforce, emblems, jewels, the Forge, the Condenser, chests, the Tower and element states. The directive, section 17, forbids exactly that order.
4. **The two things the vision is about are the weakest parts:**
   - Voidkin worth owning: five at launch, being redesigned;
   - a fight that feels good: the player has nothing to press.
5. **Paper costs as much as play.**
   - The docs hold about 645k words, and `asset-requests.md` alone is 17k lines. Of 202 commits, 98 touch only docs.
   - AI verdicts keep passing work the director then rejects.

Sources: `state-of-the-game.md` and `design-review.md` (Faber checked their key claims against main), and `directing-the-game.md`.

## Do these first (ranked)

| # | What | Who | Tier | Undo? |
|---|---|---|---|---|
| 1 | **The director plays the first ten minutes on a phone, privately.** The only output is one ranked list of what broke. **No release:** the director, 11-24: "no publishing the game isnt ready". The phone run needs only the private save the board already asks for (`docs/team-notes.md`, item 4: File → Publish to Roblox, and the experience stays private, so no player can see it). People from outside play only when the director says the game is ready. | the director (about 10 min) and the builder | 3: the director's hand | yes |
| 2 | **Freeze new scope for one week.** No new system, screen or mechanic, and no art off the first ten minutes' path. | the director | 3 | yes, it's a week |
| 3 | **Stop selling the currency that buys rolls.** Credits buy rolled shards and Reinforce rolls, so selling Credits makes both paid random items (rule 4, [Roblox's page](https://create.roblox.com/docs/production/monetization/paid-random-items)). Sell passes, cosmetics, bag space and a Founder's Mark instead. Make Reinforce deterministic, or give it a shown pity count. | the director | 3, economy and rule 4 | yes, before launch |
| 4 | **Give the player one thing to press in a fight:** the lead's signature from its own portrait, the move Taichi Panda's best review praised. It answers "the lead fights beside you" without leaving auto combat. | research designs, the builder blocks | 2 | yes |
| 5 | **Play opens a mode panel.** The director asked for it twice; the 11-19 sentence was read the other way. Build-ready: `play-mode-panel.md`. | the builder | 1, plus 2 for the Tower card | yes |
| 6 | **One ground, one gold (the UI colours).** | the director | 3, identity | yes, at the cost of a re-cut |
| 7 | **Voidkin from references, sayable names with a title** ("the archetype and a twist"), and the rarer the reveal, the louder it plays. `characters-and-worlds.md`, Part 1 and the design rules. | research and Modulo | 2 | yes |
| 8 | **Check Kirra's take A before it's built.** Silver hair, a quick bladed assassin and a name close to one famous character's sit near the "Fighters" test. Its sheet is drawn beside a reference named `kinnua`. PLAUSIBLE, not confirmed: a content check decides. | Modulo, the content check | rule 3 | — |
| 9 | **Time the first 180 seconds on a phone, the teleport included.** Since 2026-06, Home counts players who leave inside 60 s and inside 180 s against the game (`retention-and-discovery.md`). | the builder, in Studio | 1 | — |
| 10 | **Put the paper on a diet and keep one ranked list:** verdicts of at most 10 lines, requests of at most 30, at most 3 pieces in progress per teammate, each with a kill date. Closed entries go to the archive weekly. | research and the builder | 3: it changes the rules | yes |

### Why the UI colours (item 6)

The director invited the challenge, so this is said plainly: the colours chosen are not good together. No one hue is the problem; there are too many.

- There are 6 panel grounds, 6 coloured pill bodies and about 9 golds, so gold no longer means "do this". MEASURED.
- The third ink step fails 4.5:1 on every palette. On the Breaker's teal, Epic is 3.3:1, Rare 3.2:1 and Mythical 3.0:1. MEASURED.
- About 1 boy in 12 can't tell Rare from Epic. That's the rarity the Breaker's odds headline. MEASURED, using the usual prevalence.
- **The fix, "Night glass":** one navy-violet glass over a blurred world. The gold #E9B65C goes only on the primary button, Power and Credits keep their own marks, and the inks clear 6.3:1 or better. It grows from the inventory screen the director kept on 11-17. Tokens and Studio checks are in `ui-colour-review.md`.

### What not to do

- Don't add the Clash Grounds, keepers or new systems as Play cards until they exist and the small loop is proven.
- Don't put a mode the first session can't use in front of a new player. Show the Tower card after the first Lantern Row clear: it fits the north star's "Want" beat (the Tower's door) and `state-of-the-game.md`'s "hide deep systems" both. This is a one-line condition in the panel; the builder's call when built.
- Don't take "heavy inspiration from famous anime IP" past rule 3. Research held that line correctly on 11-23. The energy comes from the genre's side cast and our own references, never a recognisable lead.
- Don't carry an effect's main shape on a particle `Rate`. Phones cap an emitter at 100 a second and thin rates by quality, so main shapes go in bursts, meshes or beams; Watt's Ground Wire asks for 420 a second. In `FighterController/Rows.luau:733`, the rate is written every frame: write it only on change (`vfx-quality.md`; both checked on main by Faber). The stepped-timing trial at 12 to 15 fps is Scintilla's tier 1.
- Don't trust phone haptics. Sound and motion carry every press (`devforum-ui.md`, tip 26).

## Waiting on the director (one screen)

1. **The private save for the phone run**, about 10 minutes, whenever the director chooses. It isn't a release: the experience stays private. It unblocks items 1 and 9. The game is not released or shown to anyone until the director says it's ready (11-24).
2. **Credits unsold at launch, and a deterministic Reinforce:** yes or no.
3. **"Night glass":** yes, no, or "show me a mock first". A mock is the cheap step: one screen re-coloured in Studio.
4. **A one-week scope freeze:** yes or no.
5. **The Kids and Select gate.** Before ages 5 to 15 see the game, 100 engaged, age-checked players must play it within 60 days. The group owner also needs ID verification and 2-Step Verification, plus a refundable fee or two months of Premium. That's spending, so rule 1 applies. Not urgent, but it shapes launch (`retention-and-discovery.md`, finding 1).

## The studies in this folder

**One correction covers them all.** `state-of-the-game.md`, `design-review.md` and `directing-the-game.md` were written before the director's word of 11-24 ("no publishing the game isnt ready"). Where they say "publish" or "strangers play", read: the director's private phone run now, and outside players only at the director's go.

| File | What it answers |
|---|---|
| `state-of-the-game.md` | where we stand against the vision, and the course correction |
| `design-review.md` | ten ranked challenges to the design, and what's strong |
| `directing-the-game.md` | how good teams stay on course: pillars as filters, kill dates, one list |
| `retention-and-discovery.md` | Roblox's 2026 discovery rules: the 60 to 180 s window, the Kids gate, update cadence, co-play |
| `ui-colour-review.md` | the palette, measured, and "Night glass" |
| `reference-menu-video.md` | the director's reference video: what to take, what not to |
| `menu-layout-and-motion.md` | layout rules and motion timings with numbers |
| `play-mode-panel.md` | the Play correction and a build-ready entry |
| `devforum-ui.md` | UI craft tips: the text floor, UI Styling, safe areas |
| `devforum-engineering.md` | engineering tips: a settings checklist per place, a performance row, save hardening |
| `characters-and-worlds.md` | what makes a cast and a map memorable; three world pitches |
| `taichi-panda-study.md` | Taichi Panda 3, what to borrow as principle and what to avoid |
| `vfx-quality.md` | high-bar anime effects: stepped timing, the engine's particle caps on phones, a flash rule in numbers, a 13-item checklist |

Every finding in them is labelled SOURCED, COMMUNITY, MEASURED, OBSERVED or OPINION. Nothing players see is verified until it's seen in Studio.
