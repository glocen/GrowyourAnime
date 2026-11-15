"""A Shade's hurt, our layer (AR13, cue 2): the spark's tick.

ShadeHurtSpark   A bright click with a short ring of three partials from 2.4 to 5.1 kHz, 60 to 75 ms: the spark over
                 the library's paper crumple. The partials aren't a chord (their ratios are a small bell's), so it
                 reads as a spark, not a note.

    py tools/audio/shade_hurt.py
"""
import audiokit as ak

CUE = "ShadeHurt"
BASE = (2650.0, 2950.0, 2400.0)  # each take's lowest partial
RATIOS = ((1.0, 1.47, 1.83), (1.0, 1.41, 1.72), (1.0, 1.52, 1.96))
LENGTH = (0.07, 0.06, 0.075)


def tick(take):
    r = ak.rng("ShadeHurtSpark", take)
    partials = [(BASE[take] * k, g, d) for k, g, d in zip(RATIOS[take], (1.0, 0.7, 0.45), (1.0, 0.75, 0.55))]
    return ak.spark(r, partials, LENGTH[take], (0.05, 0.042, 0.055)[take], (3000.0, 10000.0), (0.8, 0.9, 0.7)[take])


def make():
    return [ak.layer(CUE, "ShadeHurtSpark", [tick(i) for i in range(3)], weight=(150.0, 0.95),
                     made="a 3 to 10 kHz click a few milliseconds long, and three ringing partials from 2.4 to 5.1 kHz",
                     use="with the library's paper crumple, on the Shade's hurt")]


if __name__ == "__main__":
    make()
