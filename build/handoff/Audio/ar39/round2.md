# AR39, round2: the three pilots' arrangements

Made by `tools/audio/ar39_arrange.py` from the first batch's numbers. Nothing was heard: whether one convinces stays UNVERIFIED. Every level is a seed, and every number under 'estimated' is worked from the batch's measures of each take, never measured on a mix: the gates are Faber's mixdown's. **A draft:** round 2's set on the first batch's numbers, with no layer of ours in any cue. It's re-run when the second batch and Faber's measures of round 1 land.

**The levels:** LightHit at -37.4 LUFS (the loudest 400 ms of one play at full volume), HeavyHit +4.5 LU, ShadeSwipe -4.5 LU: gate 4's relation sets them. LightHit's own level is where the hottest single cue's top, its layers' tops together, stands at -4 dBFS: a decibel for the true peak, and the bus limiter's 3 for an overlap.

## The arrangements

### LightHit_A1

One recorded contact, nothing else: a slap of skin or cloth carries the hit whole, in the band a phone keeps.

| Layer | Role | Takes | At, s | Lead | Volume | Level, LUFS |
|---|---|---|---|---|---|---|
| LibContact | body | 4 | 0 |  | 0.359 | -37.4 |

Estimated, one play at full volume, its strength layer left out: -37.4 LUFS (the loudest 400 ms); its top at most -10.5 dBFS (its layers' tops together); 2% under 120 Hz; through the phone's curve -37.6 LUFS.

### LightHit_A3

A recorded contact with recorded weight under it from a second recording. Our spark is gone.

| Layer | Role | Takes | At, s | Lead | Volume | Level, LUFS |
|---|---|---|---|---|---|---|
| LibContact | body | 4 | 0 |  | 0.313 | -38.6 |
| LibLow | weight | 2 | 0 |  | 0.126 | -43.6 |

Estimated, one play at full volume, its strength layer left out: -37.4 LUFS (the loudest 400 ms); its top at most -9.1 dBFS (its layers' tops together); 19% under 120 Hz; through the phone's curve -38.5 LUFS.

### LightHit_A4

A recorded contact with a clap's crack laid on its edge: the transient from one recording, the body from another.

| Layer | Role | Takes | At, s | Lead | Volume | Level, LUFS |
|---|---|---|---|---|---|---|
| LibContact | body | 4 | 0 |  | 0.328 | -38.2 |
| LibSnap | attack | 3 | 0 |  | 0.128 | -45.2 |

Estimated, one play at full volume, its strength layer left out: -37.4 LUFS (the loudest 400 ms); its top at most -8.1 dBFS (its layers' tops together); 2% under 120 Hz; through the phone's curve -37.8 LUFS.

### HeavyHit_B1

One recorded heavy body, and a deep glove thump from a second recording under it for the weight, where our sub was.

| Layer | Role | Takes | At, s | Lead | Volume | Level, LUFS |
|---|---|---|---|---|---|---|
| LibHeavyBody | body | 3 | 0 |  | 0.639 | -33.6 |
| LibLowLong | weight | 2 | 0 |  | 0.167 | -41.1 |

Estimated, one play at full volume, its strength layer left out: -32.9 LUFS (the loudest 400 ms); its top at most -6.4 dBFS (its layers' tops together); 31% under 120 Hz; through the phone's curve -35.4 LUFS.

### HeavyHit_B2

Two recordings: a deep glove thump for the weight, and the light hit's own contact over it, so a heavy hit is a light one with a body behind it.

| Layer | Role | Takes | At, s | Lead | Volume | Level, LUFS |
|---|---|---|---|---|---|---|
| LibLowLong | weight | 2 | 0 |  | 0.304 | -35.9 |
| LibContact | attack | 4 | 0 |  | 0.426 | -35.9 |

Estimated, one play at full volume, its strength layer left out: -32.9 LUFS (the loudest 400 ms); its top at most -4.8 dBFS (its layers' tops together); 37% under 120 Hz; through the phone's curve -35.1 LUFS.

### HeavyHit_B3

Three recordings stacked: a heavy body, a leather or clap snap on its edge, and a deep thump under both.

| Layer | Role | Takes | At, s | Lead | Volume | Level, LUFS |
|---|---|---|---|---|---|---|
| LibHeavyBody | body | 3 | 0 |  | 0.595 | -34.2 |
| LibHeavySnap | attack | 3 | 0 |  | 0.379 | -41.2 |
| LibLowLong | weight | 2 | 0 |  | 0.147 | -42.2 |

Estimated, one play at full volume, its strength layer left out: -32.9 LUFS (the loudest 400 ms); its top at most -4.0 dBFS (its layers' tops together); 26% under 120 Hz; through the phone's curve -35.0 LUFS.

### ShadeSwipe_C1

Paper's flick for the tell, a pass through the air for the swipe.

| Layer | Role | Takes | At, s | Lead | Volume | Level, LUFS |
|---|---|---|---|---|---|---|
| LibFlick | tell | 3 | -0.2 | Peak | 0.16 | -51.0 |
| LibAir | body | 3 | 0 | Peak | 0.2 | -42.5 |

Estimated, one play at full volume, its strength layer left out: -41.9 LUFS (the loudest 400 ms); its top at most -16.0 dBFS (its layers' tops together); 7% under 120 Hz; through the phone's curve -42.3 LUFS.

### ShadeSwipe_C2

A paper-edged pass: paper's flick for the tell, then the air's pass with a sheet's rustle riding its top.

| Layer | Role | Takes | At, s | Lead | Volume | Level, LUFS |
|---|---|---|---|---|---|---|
| LibFlick | tell | 3 | -0.2 | Peak | 0.147 | -51.7 |
| LibAir | body | 3 | 0 | Peak | 0.174 | -43.7 |
| LibRustle | character | 3 | 0 | Peak | 0.233 | -48.2 |

Estimated, one play at full volume, its strength layer left out: -41.9 LUFS (the loudest 400 ms); its top at most -11.7 dBFS (its layers' tops together); 6% under 120 Hz; through the phone's curve -42.4 LUFS.

### ShadeSwipe_C3

The paper drawn back, then the pass: a longer rustle ending in its flick for the tell, and the recorded pass alone.

| Layer | Role | Takes | At, s | Lead | Volume | Level, LUFS |
|---|---|---|---|---|---|---|
| LibRustle | tell | 3 | -0.2 | Peak | 0.216 | -48.9 |
| LibAir | body | 3 | 0 | Peak | 0.191 | -42.9 |

Estimated, one play at full volume, its strength layer left out: -41.9 LUFS (the loudest 400 ms); its top at most -15.5 dBFS (its layers' tops together); 7% under 120 Hz; through the phone's curve -42.3 LUFS.

## The takes

A library take's slice in its file, s; its time to its top; its gain inside its list; its loudness at its file's level; its top; its rise from its onset; how far under its top its slice starts.

| List | Id | Title | Creator | From | To | Peak, ms | Out, ms | Gain | LUFS | Top, dBFS | Rise, ms | Start, dB |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| LibContact | 9120003720 | Thigh Slap 2 (SFX) | ProSoundEffects | 0.004 | 0.082 | 8 | 30 | 0.473 | -22.0 | 0.0 | 6 | -31 |
| LibContact | 9114773313 | Hand Slap Single Hits 16 (SFX) | ProSoundEffects | 0.000 | 0.076 | 6 | 30 | 1.161 | -29.8 | -2.9 | 4 | -37 |
| LibContact | 9113532901 | Body Pats Cloth Hits 3 (SFX) | ProSoundEffects | 0.008 | 0.057 | 6 | 20 | 0.861 | -27.2 | -3.7 | 2 | -32 |
| LibContact | 9113316991 | Baseball Slap Ball Into Glove Singles 4 (SFX) | ProSoundEffects | 0.008 | 0.040 | 3 | 15 | 1.84 | -33.8 | -7.0 | 0 | -43 |
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
