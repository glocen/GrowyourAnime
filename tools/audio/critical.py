"""A critical, our layer (AR13, cue 6): the bright metallic shing.

CritShing   FM synthesis, 0.24 to 0.28 s: two carriers between 3.9 and 6 kHz, each bent by a modulator at a ratio
            that isn't a whole number, so the sidebands are a blade's, not a chord's. The bend is deep at the start
            and dies fast: a hard bright edge, then a thin ring. It slides up a little into its pitch. Kept between
            2.8 and 7.5 kHz, so it adds a top to the hit and no loudness under it.

    py tools/audio/critical.py
"""
import numpy as np

import audiokit as ak

CUE = "Critical"
CARRIER = (4200.0, 3900.0, 4600.0)
RATIO = ((1.414, 0.707), (1.37, 0.62), (1.46, 0.75))  # each carrier's modulator, against the carrier
LENGTH = (0.26, 0.28, 0.24)


def operator(carrier, ratio, depth, seconds, r):
    slide = np.minimum(ak.clock(seconds) / 0.025, 1.0)
    pitch = carrier * (0.94 + 0.06 * slide)  # up into its pitch over 25 ms
    bend = depth * ak.decay(seconds, 0.09, 0.0005) + 0.25
    return np.sin(2 * np.pi * np.cumsum(pitch) / ak.RATE + bend * ak.tone(pitch * ratio) + r.uniform(0, 6))


def shing(take):
    r = ak.rng("CritShing", take)
    seconds = LENGTH[take]
    first = operator(CARRIER[take], RATIO[take][0], (3.2, 2.8, 3.6)[take], seconds, r)
    second = operator(CARRIER[take] * (1.31, 1.34, 1.28)[take], RATIO[take][1], 2.0, seconds, r) * 0.6
    edge = ak.band(ak.noise(seconds, r), 4000, 9000) * ak.decay(seconds, 0.018, 0.0003) * 0.5
    x = (first + second) * ak.decay(seconds, seconds * (0.9, 1.0, 0.85)[take], 0.002) + edge
    return ak.band(x, 2800, 7500, 2)


def make():
    return [ak.layer(CUE, "CritShing", [shing(i) for i in range(3)], weight=(150.0, 0.95),
                     made="two FM carriers from 3.9 to 6 kHz with modulators at ratios near 1.41 and 0.7, the bend "
                          "dying in 90 ms, kept between 2.8 and 7.5 kHz",
                     use="over the hit's own layers on a critical: it adds the top. The cue's loudness stays the hit's")]


if __name__ == "__main__":
    make()
