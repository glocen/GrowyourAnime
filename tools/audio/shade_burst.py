"""A Shade bursts, our two layers (AR13, cue 3): the shimmer's tail and the scattered ticks.

ShadeBurstShimmer   A tail on A, 0.6 to 0.7 s: A and E only (the open fifth, so it's neither major nor minor until
                    music sets the key), each note a pair a few cents apart so it shimmers, each entering a few
                    milliseconds after the last, the higher ones dying first, with a breath of air on top.
ShadeBurstTicks     Five or six tiny sparks scattered over 0.3 s, thinning as they go, on the same A and E.

    py tools/audio/shade_burst.py
"""
import numpy as np

import audiokit as ak

CUE = "ShadeBurst"
A = 880.0
E = A * 2 ** (7 / 12)
# (Hz, gain) for each take's notes: the second take is the same key from its fifth up
NOTES = (((A, 0.8), (A * 2, 1.0), (E * 2, 0.7), (A * 4, 0.5), (E * 4, 0.25)),
         ((E, 0.7), (A * 2, 1.0), (E * 2, 0.8), (A * 4, 0.45), (A * 8, 0.15)))
LENGTH = (0.7, 0.6)


def shimmer(take):
    r = ak.rng("ShadeBurstShimmer", take)
    total = LENGTH[take]
    pieces = []
    for i, (freq, gain) in enumerate(NOTES[take]):
        late = i * (0.012, 0.018)[take] + r.uniform(0, 0.006)
        seconds = total - late
        ring = ak.decay(seconds, total * (1.1 - 0.16 * i), 0.004)
        cents = r.uniform(4, 9)
        pair = ak.tone(freq * 2 ** (cents / 2400), seconds, r.uniform(0, 6)) + ak.tone(freq * 2 ** (-cents / 2400), seconds, r.uniform(0, 6))
        pieces.append((late, pair * ring, gain / 2))
    air = ak.band(ak.noise(total, r), 6000, 11000) * ak.decay(total, total * 0.5, 0.01)
    pieces.append((0.0, air / np.abs(air).max(), 0.12))
    return ak.at(total, pieces)


def ticks(take):
    r = ak.rng("ShadeBurstTicks", take)
    count = (5, 6)[take]
    when = ((np.arange(count) + r.uniform(0, 0.8, count)) / count) ** 1.4 * 0.28  # one in each stretch, thinning
    when[0] = 0.0
    pieces = []
    for i, w in enumerate(when):
        base = (A * 4, E * 4, A * 8, E * 2)[r.integers(0, 4)]
        x = ak.spark(r, [(base, 1.0, 1.0), (base * 1.5, 0.4, 0.6)], 0.03, 0.022, (5000.0, 12000.0), 0.6)
        pieces.append((float(w), x, 1.0 - 0.6 * i / count))
    return ak.at(0.31, pieces)


def make():
    return [
        ak.layer(CUE, "ShadeBurstShimmer", [shimmer(i) for i in range(2)], weight=(150.0, 0.95), key="A",
                 made="A and E in pairs 4 to 9 cents apart, from 880 Hz up, staggered 12 to 18 ms, with air from 6 to 11 kHz",
                 use="the burst's tail, started with the pop. The seed key for every reward sound until music sets it"),
        ak.layer(CUE, "ShadeBurstTicks", [ticks(i) for i in range(2)], weight=(150.0, 0.95), key="A",
                 made="five or six sparks of 30 ms on A and E, scattered over 0.28 s, thinning",
                 use="over the burst's first 0.3 s, with the library's flutter")]


if __name__ == "__main__":
    make()
