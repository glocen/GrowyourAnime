"""A Shade's swipe, our two layers (AR13, cue 1): the tell's cold shimmer and the swipe's whoosh.

ShadeTell    0.25 s. Noise through a narrow band that climbs, with a thinner band a fifth over it and a fast flutter:
             a faint cold shimmer rising under the library's paper rustle. It tops just before its end, where the hit is.
ShadeSwipe   Noise through a band sweeping 600 to 2,500 Hz in 0.25 s, with a dry edge of high noise on top: the
             whoosh's body under the library's paper. Its top is the hit: `peakAtMs` in the numbers says where it is in
             the file, so the build starts it that long before the hit frame.

    py tools/audio/shade_swipe.py
"""
import numpy as np

import audiokit as ak

CUE = "ShadeSwipe"
TELL = 0.25
SWEEP, AFTER = 0.25, 0.07  # the swipe's sweep, then what's left after its top


def tell(take):
    r = ak.rng("ShadeTell", take)
    key = 2 ** ((-1.5, 0.0, 1.5)[take] / 12)  # each take a little apart in pitch
    rise = ak.glide(1900 * key, (5200, 5600, 4900)[take] * key, TELL, (1.3, 1.0, 1.6)[take])
    n = ak.noise(TELL, r)
    body = ak.moving_band(n, rise, (7.0, 9.0, 6.0)[take])
    over = ak.moving_band(n, rise * 1.5, 11.0) * 0.45
    flutter = 1 + 0.35 * np.sin(2 * np.pi * (31, 38, 27)[take] * ak.clock(TELL) + r.uniform(0, 6))
    return (body + over) * flutter * ak.swell(TELL, (0.2, 0.19, 0.21)[take], 1.4, 0.03)


def swipe(take):
    r = ak.rng("ShadeSwipe", take)
    key = 2 ** ((0.0, -1.2, 1.3)[take] / 12)
    total = SWEEP + AFTER
    sweep = np.concatenate([ak.glide(600 * key, 2500 * key, SWEEP, (0.8, 1.0, 0.7)[take]),
                            np.full(round(AFTER * ak.RATE), 2500 * key)])
    n = ak.noise(total, r)
    q = (2.2, 2.8, 1.9)[take]
    body = ak.moving_band(ak.moving_band(n, sweep, q), sweep, q)  # twice, for steeper sides
    crackle = np.abs(ak.band(ak.noise(total, r), high=(140, 190, 110)[take])) ** 2  # an uneven, papery edge
    edge = ak.band(ak.noise(total, r), low=4200) * crackle / crackle.max() * (0.22, 0.18, 0.26)[take]
    return (body / np.abs(body).max() + edge) * ak.swell(total, (0.2, 0.19, 0.21)[take], (1.6, 1.3, 1.9)[take], 0.07)


def make():
    made = [
        ak.layer(CUE, "ShadeTell", [tell(i) for i in range(3)], weight=(150.0, 0.9),
                 made="noise through a band-pass climbing from about 1.9 to 5.2 kHz, a thinner band a fifth over it, "
                      "a 27 to 38 Hz flutter",
                 use="under the library's paper rustle, from the wind-up; it ends on the hit. Faint: about 0.35 of the "
                     "swipe's volume (DESIGN, for the ear)"),
        ak.layer(CUE, "ShadeSwipe", [swipe(i) for i in range(3)], weight=(150.0, 0.9),
                 made="noise through a band-pass sweeping 600 to 2,500 Hz in 0.25 s, a dry edge of noise over 4.2 kHz",
                 use="its top on the hit frame: start it `peakAtMs` before the hit. Quieter than the lead's hits")]
    made[1]["peakAtMs"] = [t["toPeakMs"] for t in made[1]["takes"]]
    return made


if __name__ == "__main__":
    make()
