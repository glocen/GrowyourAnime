"""A heavy hit, our four layers (AR13, cue 5): the riser before it, the sub, the micro-impacts and the tail.

HeavyRiser     0.15 to 0.2 s of noise and a tone climbing into the hit, cut off on it: start it its own length before
               the hit frame. The other way to wind up is silence, which needs no file.
HeavySub       0.36 to 0.48 s. A sine falling to about 60 Hz, driven hard and off-centre before it's shaped, so its
               second, third and fourth harmonics hold through the whole decay, then the band they sit in (115 to
               260 Hz) lifted: the weight a phone can play. `harmonics` in the numbers is the share from 120 to 250 Hz.
HeavyImpacts   Three to five short thuds within 0.25 s, the first the hardest: the hit lands as a cluster.
HeavyTail      0.7 s of dark air closing down: the room after the hit. Its volume follows the hit's strength.

    py tools/audio/heavy_hit.py
"""
import numpy as np

import audiokit as ak

CUE = "HeavyHit"


def riser(take):
    r = ak.rng("HeavyRiser", take)
    total = (0.18, 0.15, 0.2)[take]
    key = 2 ** ((0.0, 1.5, -1.5)[take] / 12)
    climb = ak.glide(320 * key, 3200 * key, total, (1.4, 1.2, 1.7)[take])
    air = ak.moving_band(ak.noise(total, r), climb, 2.5)
    whine = ak.tone(ak.glide(180 * key, 720 * key, total, 1.5)) * 0.35
    rise = 0.04 + 0.96 * np.linspace(0, 1, len(climb)) ** (2.2, 1.8, 2.6)[take]
    x = (air / np.abs(air).max() + whine) * rise
    return ak.ends(x, 0.0005, 0.008)  # it stops dead on the hit


LIFT = (3.0, 3.2, 2.8)  # how far the sub's 115 to 260 Hz band is lifted over the rest


def sub(take):
    total = (0.42, 0.36, 0.48)[take]
    start, end = (104.0, 112.0, 96.0)[take], (60.0, 64.0, 56.0)[take]
    fall = np.concatenate([ak.glide(start, end, 0.12, 0.6), np.full(round((total - 0.12) * ak.RATE), end)])
    driven = np.tanh(ak.tone(fall) * (3.2, 3.6, 2.9)[take] + 0.45)  # the lean makes the even harmonics, the drive the odd
    driven -= driven.mean()
    weight = ak.band(driven, 115, 260, 2)
    shaped = (driven + weight * LIFT[take]) * ak.decay(total, total * 0.95, 0.003)
    return ak.band(shaped, high=700, order=2)


def impacts(take):
    r = ak.rng("HeavyImpacts", take)
    when = ((0.0, 0.034, 0.081, 0.15), (0.0, 0.052, 0.128), (0.0, 0.027, 0.063, 0.118, 0.196))[take]
    pieces = []
    for i, w in enumerate(when):
        low = (310.0, 340.0, 285.0)[take] * (1 - 0.06 * i)
        knock = ak.tone(ak.glide(low, low * 0.55, 0.05, 0.6)) * ak.decay(0.05, 0.045, 0.001)
        grit = ak.band(ak.noise(0.05, r), 250, (1400, 1200, 1600)[take]) * ak.decay(0.05, 0.03, 0.0005)
        pieces.append((w, knock + 0.8 * grit / np.abs(grit).max(), (1.0, 0.62, 0.48, 0.36, 0.27)[i]))
    return ak.at(when[-1] + 0.055, pieces)


def tail(take):
    r = ak.rng("HeavyTail", take)
    total = 0.7
    close = ak.glide((1300.0, 1100.0, 1500.0)[take], (240.0, 260.0, 220.0)[take], total, (0.6, 0.7, 0.5)[take])
    air = ak.moving_band(ak.noise(total, r), close, 0.9)
    roll = 1 + 0.25 * np.sin(2 * np.pi * (7.0, 9.0, 6.0)[take] * ak.clock(total) + r.uniform(0, 6))
    return ak.band(air, 140, 1600) * roll * ak.decay(total, (0.75, 0.65, 0.85)[take], 0.012)


def make():
    made = [
        ak.layer(CUE, "HeavyRiser", [riser(i) for i in range(3)], weight=(150.0, 0.9),
                 made="noise through a band-pass climbing from 320 Hz to 3.2 kHz, and a tone climbing two octaves under it",
                 use="before the hit, ending on its frame: start it its own length early. Or leave 100 to 200 ms of "
                     "near-silence instead, for the ear to choose"),
        ak.layer(CUE, "HeavySub", [sub(i) for i in range(3)], weight=(115.0, 0.5),
                 made="a sine falling from about 104 to 60 Hz in 0.12 s, driven off-centre, its 115 to 260 Hz band lifted",
                 use="on the hit frame, under the library's heavy body"),
        ak.layer(CUE, "HeavyImpacts", [impacts(i) for i in range(3)], weight=(150.0, 0.6),
                 made="three to five 50 ms knocks (a tone falling from near 310 Hz and noise from 250 to 1,400 Hz), each softer",
                 use="on the hit frame: the cluster that makes one hit read as heavy"),
        ak.layer(CUE, "HeavyTail", [tail(i) for i in range(3)], weight=(150.0, 0.85),
                 made="noise through a wide band-pass closing from 1.3 kHz to 240 Hz, kept under 1.6 kHz, with a slow roll",
                 use="from the hit frame; its volume by the hit's strength (DESIGN: nothing at a light hit, full at the heaviest)")]
    made[1]["harmonics"] = [round(ak.share(x, 120, 250), 3) for x in made[1]["samples"]]
    return made


if __name__ == "__main__":
    make()
