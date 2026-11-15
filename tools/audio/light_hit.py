"""A light hit, our layer (AR13, cue 4): the spark's tick, the hurt's family in a lower register.

LightHitSpark   A click and a ring of three partials from 1.2 to 2.7 kHz, about 100 ms, in five takes: the lead's
                basic attacks land often, so five keep them from repeating. No sub: it stays fast.

    py tools/audio/light_hit.py
"""
import audiokit as ak

CUE = "LightHit"
BASE = (1320.0, 1180.0, 1450.0, 1250.0, 1390.0)
RATIOS = ((1.0, 1.47, 1.83), (1.0, 1.41, 1.9), (1.0, 1.52, 1.76), (1.0, 1.36, 1.83), (1.0, 1.58, 1.94))
LENGTH = (0.1, 0.11, 0.095, 0.105, 0.1)
RING = (0.085, 0.095, 0.075, 0.09, 0.08)
SNAP = (0.9, 0.75, 1.0, 0.85, 0.8)


def tick(take):
    r = ak.rng("LightHitSpark", take)
    partials = [(BASE[take] * k, g, d) for k, g, d in zip(RATIOS[take], (1.0, 0.6, 0.4), (1.0, 0.7, 0.5))]
    return ak.spark(r, partials, LENGTH[take], RING[take], (1500.0, 6000.0), SNAP[take])


def make():
    return [ak.layer(CUE, "LightHitSpark", [tick(i) for i in range(5)], weight=(150.0, 0.95),
                     made="a 1.5 to 6 kHz click, and three ringing partials from 1.2 to 2.7 kHz",
                     use="with the library's snap and mid body, on the lead's basic attacks")]


if __name__ == "__main__":
    make()
