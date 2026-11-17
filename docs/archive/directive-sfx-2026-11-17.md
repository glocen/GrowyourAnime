# The director's SFX rescue directive, 2026-11-17

Received by research (Quaestor) on 2026-11-17, in the evening, word for word. The director's line before it: "make sure it all free, safe etc."

---

DIRECTIVE — AUTONOMOUS SFX RESCUE

Project: Grow Your Anime / NEXT Ludus
Priority: High — audio quality is a major weakness
Owner: Quaestor, coordinating Modulo, Faber and independent QA

1. Mission

Our current sound effects are considerably below the quality standard I expect. Some sound cheap, artificial, shallow or insufficiently impactful.

I want the team to investigate, experiment, engineer, implement and improve our entire sound-production pipeline autonomously, without requiring me to participate.

Do not simply add more SFX or make existing effects louder. Make them genuinely better.

Our intended result is a polished, mature, anime-inspired Roblox audio experience with convincing impacts, distinctive abilities, expressive sound design and satisfying feedback.

Use high-quality Roblox anime action games and professional action-game sound design as quality references, without copying protected sounds or distinctive audiovisual expression.

This is not an instruction to endlessly experiment. If we cannot make meaningful progress autonomously, determine that quickly, report the limitation and stop.

2. Read the existing implementation first

Work in glocen/GrowyourAnime and use NEXT-LUDUS as the technical handbook.

Start with:

* AGENTS.md and CLAUDE.md
* docs/research/sound.md
* docs/decisions.md
* docs/asset-log.md
* src/shared/Config/Cues.luau
* src/shared/Config/Sounds.luau
* src/shared/Rules/Sound.luau
* src/client/Controllers/Main/FighterController/Cues.luau
* src/client/Controllers/Main/FighterController/Sounds.luau
* tools/audio/
* tools/studio/Audio/
* build/handoff/Audio/test6/
* Existing sound and audio test cases

Verify the current repository and Roblox Studio state rather than assuming documentation is up to date.

Preserve existing project architecture where it works. Do not rewrite a working audio engine merely because the sound assets are poor.

3. Known problems to investigate

An external code review identified several important warning signs:

A. Missing realistic layers

Our current LightHit relies on a synthesized spark rather than a complete, convincing contact sound.

Our HeavyHit uses synthesized bass, a cluster of impacts and an airy tail, but the intended realistic library body is not necessarily present.

Other cues also reference professional-library layers that were still awaiting selection.

Verify whether this remains true.

B. Inadequate artistic evaluation

The current automated tests measure duration, loudness, true peaks, frequency distribution, timing and sample variation.

These are valuable technical measurements, but they cannot prove that a sound is convincing, pleasant, powerful or appropriate.

A numerical PASS must never be treated as proof of artistic quality.

C. Potentially unsuitable synthesis

Very short synthesized clicks, highly pitched FM sounds and excessive sub-bass can create artificial, weak or harsh results.

Examine the current generators critically. Do not defend a generated asset simply because it took work to produce.

D. Insufficient real-world variation

A technically varied sample may still sound nearly identical to a player.

A complex multi-layered sound may also be worse than a carefully chosen professional recording.

Treat complexity as a cost, not a quality metric.

4. Establish whether autonomous improvement is feasible

Before starting a large overhaul, perform a bounded feasibility investigation.

Determine:

1. Which approved audio-production and evaluation tools are already available locally.
2. Whether Studio can search, inspect and play licensed professional SFX programmatically.
3. Whether the existing audio system can correctly layer and process those assets.
4. Whether the team can capture and inspect the actual in-game audio output.
5. Whether an existing, approved audio-understanding model or other independent evaluation method is accessible.
6. What can and cannot be verified without a human listener.

Audio-language models such as CLAP may help identify whether an audio clip semantically matches its intended sound. They do not automatically prove that a sound is beautiful, professional or satisfying.

Research their limitations before relying on them.

Do not install new applications or models without required authorization, open accounts, subscribe to services, spend money or bypass our existing rules.

Use already approved local tools wherever possible.

Feasibility gate: If the tools cannot access legitimate audio material, produce usable in-game playback or validate even basic technical correctness, stop and explain why. Do not spend hours creating another untestable synthesis system.

5. Change the production strategy

The primary approach should be professional recorded material for physical realism, with synthesis as a supporting tool.

Realistic foundation

Use the Roblox Creator Store's professionally produced audio library, prioritizing trusted licensed partners such as ProSoundEffects and APMOfficial.

Search beyond these partners when appropriate and permitted.

For each sound family, search broadly enough to obtain several genuinely different candidates.

Do not select sounds merely because their filenames match a keyword or their waveforms fit the expected envelope.

Evaluate source suitability using available technical and semantic evidence.

For physical sounds such as punches, blades, footsteps, impacts and material destruction, prioritize credible recordings.

Synthesis

Keep our Python synthesis pipeline for effects it can reasonably produce well:

* Sub-bass and controlled low-end reinforcement
* Magical energy, aura and electricity
* Risers, transitions and selected whooshes
* Tonal interface feedback
* Unusual supernatural textures

Do not expect a few sine waves and noise generators to replicate a complex recorded physical impact automatically.

Layering

Build cues from complementary sonic roles:

* Preparation: movement, anticipation or charge
* Attack: crisp onset and identifiable action
* Body: convincing material, weight and contact
* Character: element, energy or distinctive texture
* Decay: appropriately controlled tail

Not every cue needs all five.

Ordinary hits should remain concise. Signature abilities may require richer arrangements.

Each layer must improve the combined effect. Remove anything redundant, excessively bright, muddy, artificial or distracting.

Particularly investigate whether our current heavy-hit micro-impacts sound like several unrelated knocks rather than one powerful contact.

6. Build three pilot effects before expanding

Do not redesign the entire game's audio immediately.

Build and integrate three representative improvements:

Pilot A — Light Hit

A convincing, responsive basic attack suitable for repeated combat.

It should have recognizable physical contact, sufficient midrange body to survive phone playback and a fast, controlled decay.

The current synthetic spark can remain as a subtle accent if useful, but not as the entire hit.

Pilot B — Heavy Hit / Rook's Haymaker

A powerful impact that feels substantially heavier than Light Hit.

Use a believable recorded attack/body as its foundation, then carefully add synthesized reinforcement.

Check that the sub-bass isn't carrying all the perceived weight, especially on mobile.

Ensure the impact coincides with the visual contact rather than arriving late.

Pilot C — Shade Swipe

A distinct enemy attack with readable anticipation and a convincing swipe.

It must remain audible during combat without overpowering the player's own actions.

Keep enough variation to avoid repetitive playback.

For each pilot, produce multiple candidate arrangements, not merely multiple pitch-shifted copies of the same arrangement.

Retain the original version for comparison.

7. Build a real quality-evaluation pipeline

Technical evaluation and artistic evaluation are separate.

Technical checks must include:

* Actual audio loading and permissions
* Start latency and synchronization with animation/contact
* True-peak and clipping inspection
* Loudness consistency
* Unwanted silences, clicks and abrupt cuts
* Frequency balance
* Excessive low-frequency dependence
* Harsh or piercing resonances where detectable
* Layer masking and phase cancellation
* Overlapping voices during rapid combat
* Variation across repeated plays
* Mobile-oriented playback simulation
* Performance and memory impact

Use appropriate test material, not arbitrary numerical targets that reward the wrong sonic characteristics.

Comparison system:

Create a repeatable A/B setup for original and replacement sounds.

Compare them at matched perceived loudness where practical, so louder does not automatically seem better.

If in-game audio capture works, use it to examine the actual delivered mix, not just isolated source files.

Where an approved audio-aware model already exists, use it as additional independent evidence, not an unquestionable judge.

If no capable evaluator is available, explicitly classify subjective quality as UNVERIFIED.

Never claim to have listened to audio when no actual listening capability was used.

8. Integrate sounds professionally

Faber must make sure the audio implementation supports the improvements rather than degrading them.

Investigate and correct, where necessary:

* Preloading and readiness before important cues
* Proper voice pooling and simultaneous playback limits
* Accurate synchronization across layers
* Correct handling of animation markers and interruptions
* 3D positional attenuation
* Sound priority and ducking
* Duplicate cue prevention
* Audio graph routing and gain staging
* Runtime changes to pitch, volume and speed
* Phone and desktop consistency
* Playback under realistic multiplayer load

Do not use a permanent loudness boost to disguise a weak sound.

A heavy attack should feel stronger through its actual sonic design and arrangement, not merely by being much louder.

Test on a real Roblox client where possible. Studio-only success is insufficient for permissions and published-asset playback.

Preserve the current working system until the replacement is verified.

9. Independent review

Modulo owns sound creation, sourcing and arrangements.

Faber owns implementation, synchronization and runtime engineering.

Quaestor owns research, coordination and comparison against the intended creative direction.

An independent reviewer or QA agent must challenge their work.

The reviewer should inspect the actual files, measurements, playback evidence and integration. It must identify weaknesses rather than merely agreeing with the creator.

The maker must not define all the tests used to approve its own work.

Do not use multiple agents' opinions about audio they cannot hear as a substitute for actual audio evidence.

10. Strict experiment limits

The initial feasibility check should be short and focused.

Then make the three pilot cues with a maximum of three meaningful design iterations per cue.

Do not spend days optimizing a synthesizer that repeatedly produces unconvincing results.

If a candidate approach fails, change the source material or sound-design method rather than repeatedly tweaking tiny parameters.

If the pilot cannot demonstrate better functional coverage, suitable recorded layers and technically sound integration, stop the overhaul.

If it demonstrates these improvements but still has no legitimate subjective evaluator, continue only with an explicitly stated unverified artistic-quality limitation.

Do not claim premium quality based on automated tests alone.

11. Expand only after the pilot succeeds

If the new production method meets its technical gates and has credible quality evidence, prioritize the remaining audio by player impact.

Recommended order:

1. Regular combat hits, enemy tells, hurt and death effects
2. Voidkin signature skills, abilities and critical attacks
3. Void Shard breaking, revealing and rarity feedback
4. Void Breakers, generators and electricity production
5. Important UI actions, rewards and progression
6. Appropriate environmental ambience, movement and remaining interactions

Create coherent sonic families so fighters and environments have recognizable identities.

For long signature abilities and ultimates, design the whole audio sequence: anticipation, release, repeated hits, climax, aftermath and cancellation.

Maintain clarity when several fighters are active.

Do not indiscriminately add sound to every interaction or fill every quiet moment with noise.

12. Safety, scope and delivery

Follow AGENTS.md, Roblox rules, audio licensing restrictions and the project's existing approval requirements.

Do not download or re-upload Roblox library sounds as our own assets. Process permitted library audio through in-experience playback and effects.

Do not copy another game's protected sounds, use questionable community uploads or install unapproved paid tools.

Do not change unrelated game systems.

Use an isolated branch or development environment, retain the previous working assets and keep a rollback.

Run relevant unit tests, Roblox Studio checks and client playback tests.

Do not publish an unverified overhaul directly to the live experience.

Keep documentation minimal and useful, with one authoritative cue registry and clear asset provenance.

13. Required final report

Return a concise report containing:

* Feasibility: what the agents can actually accomplish autonomously
* Root causes: confirmed defects versus hypotheses
* Implemented improvements: sound families, asset IDs and relevant changed files
* Evidence: before/after measurements, playback tests and independent evaluations
* Quality status: technical PASS/FAIL and subjective VERIFIED/UNVERIFIED separately
* Remaining limitations: anything that still prevents reliable quality assessment
* Decision: continue, retain partial improvements, or stop

Do not report that SFX are excellent merely because the code compiles and numerical checks pass.

Do not hide unsuccessful experiments.

Final instruction

I want real progress, not an enormous research document or another collection of scripts producing bad audio.

Use your existing capabilities intelligently. Challenge the current approach. Study how professional game audio actually works. Make the best use of permitted high-quality source material.

The entire implementation, testing, iteration and technical work should be performed by the team.

Do not involve me in choosing samples, editing files, using external software, testing Studio or comparing candidate sounds.

If my personal artistic judgment is the only thing missing at the end, state that once in the final report. Do not interrupt the process to request it.

If this autonomous approach is fundamentally incapable of producing a meaningful improvement, tell me clearly and stop. Otherwise, demonstrate the improvement through actual working assets and implementation.

The objective is not to prove that Opus 5.5 can generate sounds.

The objective is to make Grow Your Anime sound substantially better.
