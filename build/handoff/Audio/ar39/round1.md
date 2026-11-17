# AR39, round1: the three pilots' arrangements

Made by `tools/audio/ar39_arrange.py` from the first batch's numbers. Nothing was heard: whether one convinces stays UNVERIFIED. Every level is a seed, and every number under 'estimated' is worked from the batch's measures of each take, never measured on a mix: the gates are Faber's mixdown's.

**The levels:** LightHit at -42.1 LUFS (the loudest 400 ms of one play at full volume), HeavyHit +4.0 LU, ShadeSwipe -4.5 LU. LightHit's is solved from gate 3's worst case: the hottest HeavyHit's top over the hottest LightHit's twice, every layer's top together, held to -2 dBFS. If the mixdown shows room, the cues' fader takes it back in one number.

## The arrangements

### LightHit_A1

One recorded contact, nothing else: a slap of skin or cloth carries the hit whole, in the band a phone keeps.

| Layer | Role | Takes | At, s | Lead | Volume | Level, LUFS |
|---|---|---|---|---|---|---|
| LibContact | body | 4 | 0 |  | 0.209 | -42.1 |

Estimated, one play at full volume, its strength layer left out: -42.1 LUFS (the loudest 400 ms); its top at most -15.2 dBFS (its layers' tops together); 2% under 120 Hz; through the phone's curve -42.3 LUFS.

### LightHit_A2

Two recordings split by their bands: a glove or cloth thud for the body, a clap's crack laid on it for the contact.

| Layer | Role | Takes | At, s | Lead | Volume | Level, LUFS |
|---|---|---|---|---|---|---|
| LibThud | body | 3 | 0 |  | 0.152 | -43.3 |
| LibSnap | attack | 3 | 0 |  | 0.09 | -48.3 |

Estimated, one play at full volume, its strength layer left out: -42.1 LUFS (the loudest 400 ms); its top at most -15.3 dBFS (its layers' tops together); 26% under 120 Hz; through the phone's curve -44.4 LUFS.

### LightHit_A3

A recorded contact with recorded weight under it, and our spark as its accent, 10 dB under.

| Layer | Role | Takes | At, s | Lead | Volume | Level, LUFS |
|---|---|---|---|---|---|---|
| LibContact | body | 4 | 0 |  | 0.176 | -43.6 |
| LibLow | weight | 2 | 0 |  | 0.071 | -48.6 |
| LightHitSpark | accent | 5 | 0 |  | 0.049 | -53.6 |

Estimated, one play at full volume, its strength layer left out: -42.1 LUFS (the loudest 400 ms); its top at most -12.5 dBFS (its layers' tops together); 18% under 120 Hz; through the phone's curve -43.1 LUFS.

### HeavyHit_B1

One recorded heavy body as the base; our sub only reinforces it, and our tail by the hit's strength. The knocks are gone.

| Layer | Role | Takes | At, s | Lead | Volume | Level, LUFS |
|---|---|---|---|---|---|---|
| LibHeavyBody | body | 3 | 0 |  | 0.361 | -38.6 |
| HeavySub | weight | 3 | 0 |  | 0.042 | -48.1 |
| HeavyTail | decay (by strength) | 3 | 0 |  | 0.035 | -50.1 |

Estimated, one play at full volume, its strength layer left out: -38.1 LUFS (the loudest 400 ms); its top at most -12.4 dBFS (its layers' tops together); 27% under 120 Hz; through the phone's curve -40.3 LUFS.

### HeavyHit_B2

Two recordings and no synthesis: a deep glove thump for the weight, and the light hit's own contact over it, so a heavy hit is a light one with a body behind it.

| Layer | Role | Takes | At, s | Lead | Volume | Level, LUFS |
|---|---|---|---|---|---|---|
| LibLowLong | weight | 2 | 0 |  | 0.167 | -41.1 |
| LibContact | attack | 4 | 0 |  | 0.234 | -41.1 |

Estimated, one play at full volume, its strength layer left out: -38.1 LUFS (the loudest 400 ms); its top at most -10.0 dBFS (its layers' tops together); 37% under 120 Hz; through the phone's curve -40.3 LUFS.

### HeavyHit_B3

A recorded heavy body with a recorded snap on its edge, and no sub: the body's own lows carry it. Our tail by the hit's strength.

| Layer | Role | Takes | At, s | Lead | Volume | Level, LUFS |
|---|---|---|---|---|---|---|
| LibHeavyBody | body | 3 | 0 |  | 0.348 | -38.9 |
| LibHeavySnap | attack | 3 | 0 |  | 0.222 | -45.9 |
| HeavyTail | decay (by strength) | 3 | 0 |  | 0.036 | -49.9 |

Estimated, one play at full volume, its strength layer left out: -38.1 LUFS (the loudest 400 ms); its top at most -10.2 dBFS (its layers' tops together); 20% under 120 Hz; through the phone's curve -39.9 LUFS.

### ShadeSwipe_C1

All recorded: paper's flick for the tell, a pass through the air for the swipe.

| Layer | Role | Takes | At, s | Lead | Volume | Level, LUFS |
|---|---|---|---|---|---|---|
| LibFlick | tell | 3 | -0.2 | Peak | 0.093 | -55.7 |
| LibAir | body | 3 | 0 | Peak | 0.117 | -47.2 |

Estimated, one play at full volume, its strength layer left out: -46.6 LUFS (the loudest 400 ms); its top at most -20.7 dBFS (its layers' tops together); 7% under 120 Hz; through the phone's curve -47.0 LUFS.

### ShadeSwipe_C2

A paper-edged pass: the air's pass with a sheet's rustle riding its top; the tell stays ours.

| Layer | Role | Takes | At, s | Lead | Volume | Level, LUFS |
|---|---|---|---|---|---|---|
| ShadeTell | tell | 3 | -0.2 |  | 0.012 | -56.4 |
| LibAir | body | 3 | 0 | Peak | 0.101 | -48.4 |
| LibRustle | character | 3 | 0 | Peak | 0.136 | -52.9 |

Estimated, one play at full volume, its strength layer left out: -46.6 LUFS (the loudest 400 ms); its top at most -19.2 dBFS (its layers' tops together); 6% under 120 Hz; through the phone's curve -47.0 LUFS.

### ShadeSwipe_C3

The paper drawn back, then the pass: a longer rustle ending in its flick for the tell, and our own swipe 10 dB under the recorded pass, for its tone.

| Layer | Role | Takes | At, s | Lead | Volume | Level, LUFS |
|---|---|---|---|---|---|---|
| LibRustle | tell | 3 | -0.2 | Peak | 0.121 | -53.9 |
| LibAir | body | 3 | 0 | Peak | 0.107 | -47.9 |
| ShadeSwipe | accent | 3 | 0 | Peak | 0.009 | -57.9 |

Estimated, one play at full volume, its strength layer left out: -46.6 LUFS (the loudest 400 ms); its top at most -19.8 dBFS (its layers' tops together); 6% under 120 Hz; through the phone's curve -47.0 LUFS.

## The takes

A library take's slice in its file, s; its time to its top; its gain inside its list; its loudness at its file's level; its top; its rise from its onset; how far under its top its slice starts.

| List | Id | Title | Creator | From | To | Peak, ms | Out, ms | Gain | LUFS | Top, dBFS | Rise, ms | Start, dB |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| LibContact | 9120003720 | Thigh Slap 2 (SFX) | ProSoundEffects | 0.004 | 0.082 | 8 | 30 | 0.473 | -22.0 | 0.0 | 6 | -31 |
| LibContact | 9114773313 | Hand Slap Single Hits 16 (SFX) | ProSoundEffects | 0.000 | 0.076 | 6 | 30 | 1.161 | -29.8 | -2.9 | 4 | -37 |
| LibContact | 9113532901 | Body Pats Cloth Hits 3 (SFX) | ProSoundEffects | 0.008 | 0.057 | 6 | 20 | 0.861 | -27.2 | -3.7 | 2 | -32 |
| LibContact | 9113316991 | Baseball Slap Ball Into Glove Singles 4 (SFX) | ProSoundEffects | 0.008 | 0.040 | 3 | 15 | 1.84 | -33.8 | -7.0 | 0 | -43 |
| LibThud | 9113574504 | Boxing Hits 22 (SFX) | ProSoundEffects | 0.010 | 0.120 | 10 | 40 | 0.616 | -22.7 | -2.9 | 8 | -43 |
| LibThud | 9113818926 | Cloth Flap 13 (SFX) | ProSoundEffects | 0.044 | 0.112 | 10 | 25 | 1.0 | -26.9 | -4.9 | 6 | -21 |
| LibThud | 9113531442 | Body Kick With Leather Boots 9 (SFX) | ProSoundEffects | 0.634 | 0.738 | 5 | 40 | 1.382 | -29.7 | -7.5 | 2 | -44 |
| LibSnap | 9114763106 | Hand Clap Single Hits 14 (SFX) | ProSoundEffects | 0.000 | 0.032 | 4 | 15 | 0.768 | -25.1 | 0.0 | 0 | -40 |
| LibSnap | 9114762131 | Hand Claps 1 (SFX) | ProSoundEffects | 0.788 | 0.810 | 3 | 10 | 1.876 | -32.8 | -6.0 | 0 | -23 |
| LibSnap | 9114771788 | Hand Slap Claps 2 (SFX) | ProSoundEffects | 0.000 | 0.054 | 5 | 25 | 1.0 | -27.3 | -3.2 | 2 | -34 |
| LibLow | 9113568059 | Boxing Hits 5 (SFX) | ProSoundEffects | 0.004 | 0.114 | 8 | 40 | 0.786 | -23.5 | -3.2 | 8 | -30 |
| LibLow | 9113514100 | Body Hits Leather Baseball Glove 13 (SFX) | ProSoundEffects | 0.024 | 0.120 | 6 | 40 | 1.273 | -27.7 | -4.9 | 4 | -31 |
| LibLowLong | 9113568059 | Boxing Hits 5 (SFX) | ProSoundEffects | 0.004 | 0.144 | 8 | 50 | 0.789 | -23.5 | -3.2 | 8 | -30 |
| LibLowLong | 9113514100 | Body Hits Leather Baseball Glove 13 (SFX) | ProSoundEffects | 0.024 | 0.210 | 6 | 60 | 1.268 | -27.6 | -4.9 | 4 | -31 |
| LibHeavyBody | 9113574140 | Boxing Hits 17 (SFX) | ProSoundEffects | 0.000 | 0.138 | 3 | 50 | 0.461 | -23.0 | -3.5 | 6 | -43 |
| LibHeavyBody | 9113531442 | Body Kick With Leather Boots 9 (SFX) | ProSoundEffects | 0.634 | 0.778 | 5 | 50 | 1.0 | -29.7 | -7.5 | 2 | -44 |
| LibHeavyBody | 9113470397 | Body Fall Heavy 5 (SFX) | ProSoundEffects | 0.030 | 0.148 | 9 | 50 | 7.27 | -47.0 | -22.2 | 6 | -22 |
| LibHeavySnap | 9113316991 | Baseball Slap Ball Into Glove Singles 4 (SFX) | ProSoundEffects | 0.008 | 0.040 | 3 | 15 | 1.121 | -33.8 | -7.0 | 0 | -43 |
| LibHeavySnap | 9114763106 | Hand Clap Single Hits 14 (SFX) | ProSoundEffects | 0.000 | 0.032 | 4 | 15 | 0.41 | -25.1 | 0.0 | 0 | -40 |
| LibHeavySnap | 9114762131 | Hand Claps 1 (SFX) | ProSoundEffects | 0.788 | 0.810 | 3 | 10 | 1.0 | -32.8 | -6.0 | 0 | -23 |
| LibAir | 9120704978 | Whooshes Fast Wipes Quick Airy Slices 3 (SFX) | ProSoundEffects | 0.036 | 0.300 | 106 | 60 | 1.0 | -28.5 | -16.0 | 102 | -20 |
| LibAir | 9120972444 | Wood Whoosh Slicing Air Quick Swings 1 (SFX) | ProSoundEffects | 0.022 | 0.184 | 34 | 60 | 2.325 | -35.8 | -17.2 | 30 | -22 |
| LibAir | 9120709477 | Whoosh Fast Short Dull Several Versions 2 (SFX) | ProSoundEffects | 0.200 | 0.336 | 47 | 40 | 0.912 | -27.7 | -10.2 | 22 | -35 |
| LibFlick | 9125654187 | Map Movement Opening Closing Rustling Paper  (SFX) | ProSoundEffects | 0.322 | 0.358 | 6 | 15 | 0.737 | -32.4 | -1.9 | 0 | -31 |
| LibFlick | 9114348719 | Envelope Slam Down 12 (SFX) | ProSoundEffects | 0.580 | 0.670 | 30 | 30 | 1.0 | -35.1 | -8.6 | 6 | -55 |
| LibFlick | 9118106802 | Record Sleeve Pulled Out Back In 9 (SFX) | ProSoundEffects | 0.138 | 0.258 | 60 | 30 | 2.568 | -43.3 | -16.6 | 4 | -37 |
| LibRustle | 9125654187 | Map Movement Opening Closing Rustling Paper  (SFX) | ProSoundEffects | 0.178 | 0.348 | 150 | 12 | 0.619 | -31.4 | -1.9 | 0 | -28 |
| LibRustle | 9126143504 | Typing Paper Flutter Single Sheet Passing By (SFX) | ProSoundEffects | 0.298 | 0.498 | 111 | 40 | 1.0 | -35.6 | -12.8 | 24 | -16 |
| LibRustle | 9118106802 | Record Sleeve Pulled Out Back In 9 (SFX) | ProSoundEffects | 0.008 | 0.258 | 190 | 30 | 2.414 | -43.2 | -16.6 | 4 | -26 |
| LightHitSpark | ours | LightHitSpark_1 | ours (AR13) | whole | | | | | -27.5 | -1.7 | | |
| LightHitSpark | ours | LightHitSpark_2 | ours (AR13) | whole | | | | | -27.4 | -3.8 | | |
| LightHitSpark | ours | LightHitSpark_3 | ours (AR13) | whole | | | | | -27.4 | -2.1 | | |
| LightHitSpark | ours | LightHitSpark_4 | ours (AR13) | whole | | | | | -27.3 | -2.6 | | |
| LightHitSpark | ours | LightHitSpark_5 | ours (AR13) | whole | | | | | -27.4 | -2.4 | | |
| HeavySub | ours | HeavySub_1 | ours (AR13) | whole | | | | | -20.5 | -1.6 | | |
| HeavySub | ours | HeavySub_2 | ours (AR13) | whole | | | | | -20.5 | -1.4 | | |
| HeavySub | ours | HeavySub_3 | ours (AR13) | whole | | | | | -20.5 | -2.1 | | |
| HeavyTail | ours | HeavyTail_1 | ours (AR13) | whole | | | | | -20.9 | -4.4 | | |
| HeavyTail | ours | HeavyTail_2 | ours (AR13) | whole | | | | | -20.9 | -1.4 | | |
| HeavyTail | ours | HeavyTail_3 | ours (AR13) | whole | | | | | -21.0 | -5.8 | | |
| ShadeTell | ours | ShadeTell_1 | ours (AR13) | whole | | | | | -18.0 | -4.0 | | |
| ShadeTell | ours | ShadeTell_2 | ours (AR13) | whole | | | | | -18.0 | -2.4 | | |
| ShadeTell | ours | ShadeTell_3 | ours (AR13) | whole | | | | | -18.0 | -2.1 | | |
| ShadeSwipe | ours | ShadeSwipe_1 | ours (AR13) | whole | | | | | -16.8 | -1.9 | | |
| ShadeSwipe | ours | ShadeSwipe_2 | ours (AR13) | whole | | | | | -16.7 | -1.6 | | |
| ShadeSwipe | ours | ShadeSwipe_3 | ours (AR13) | whole | | | | | -16.8 | -2.6 | | |
