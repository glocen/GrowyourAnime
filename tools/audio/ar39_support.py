"""AR39's support layers, ours (docs/asset-requests.md, AR39; research's order of 2026-11-17, 22:53): what the pilots'
recorded bodies lean on, made here with numpy, scipy and pedalboard as audiokit's other sounds are. Recorded material
stays each cue's base: these are short, and each sits under its cue's body.

LightContact   4 takes, 45 ms. A knock (two partials falling a third as they ring out) and a snap of noise: the light
               hit's top, 2 ms into its file, for a body whose own top comes late.
HeavyContact   3 takes, 80 ms. A thump falling an octave, a knock over it and a crack of noise, driven: the heavy
               hit's top, for the same reason, an octave under the light one's.
HeavyLow       3 takes, 140 to 180 ms. A sine falling to about 58 Hz, driven off-centre, its harmonics' band (WEIGHT,
               a take) lifted until they carry most of its energy: the heavy hit's weight, short, where gate 5 wants
               it (at most half under 120 Hz, so a phone still plays it). A third of HeavySub's length.
ShadeAir       3 takes, 300 to 400 ms. Noise through a moving band, up in 30 to 50 ms and trailing off: one closing
               downward, one opening upward and thin, one low and wide. The air a swipe leaves, for under a recorded
               pass.

Nobody here can hear them. Every file is read back as written and measured on what the gates name: its true peak, its
top's time, the steps at its two ends, the most a band between 2 and 6 kHz stands over its neighbours, what the phone's
curve takes, its share under 120 Hz, and how alike its takes are. Nothing is uploaded.

    py tools/audio/ar39_support.py     writes build/scratch/modulo/ar39/own/<Layer>_<n>.ogg, own.json and own.md
"""
import json
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import ar39_rank as rank  # noqa: E402
import audiokit as ak  # noqa: E402

OUT = Path(__file__).resolve().parents[2] / "build" / "scratch" / "modulo" / "ar39" / "own"
TOP_MS, STEP, HARSH, ALIKE = 10.0, 0.25, 10.0, 0.97   # the gates' numbers: contact, an end's step, a peak, two takes


def light_contact(take):
    r = ak.rng("LightContact", take)
    total = 0.045
    f = (340.0, 410.0, 300.0, 470.0)[take]
    over = (1.52, 1.41, 1.63, 1.36)[take]
    fall = ak.glide(1.0, 0.8, total, 0.6)
    knock = sum(g * ak.tone(f * k * fall, phase=r.uniform(0, 0.4)) * ak.decay(total, t60, 0.0006)
                for k, g, t60 in ((1.0, 1.0, 0.03), (over, 0.6, 0.022)))
    low, high = ((700, 3200), (900, 3800), (600, 2600), (1100, 4200))[take]
    snap = ak.band(ak.noise(total, r) * ak.decay(total, (0.009, 0.008, 0.011, 0.007)[take], 0.0003), low, high)
    x = knock / np.abs(knock).max() + (0.8, 0.9, 0.7, 1.0)[take] * snap / np.abs(snap).max()
    return ak.ends(ak.band(ak.drive(x / np.abs(x).max(), 1.5), high=6000), 0.0003, 0.008)


def heavy_contact(take):
    r = ak.rng("HeavyContact", take)
    total = 0.08
    start = (240.0, 210.0, 270.0)[take]
    fall = np.concatenate([ak.glide(start, start / 2, 0.035, 0.6), np.full(round((total - 0.035) * ak.RATE), start / 2)])
    thump = ak.tone(fall) * ak.decay(total, (0.055, 0.065, 0.05)[take], 0.0008)
    knock = ak.tone((520.0, 460.0, 600.0)[take], total, r.uniform(0, 0.4)) * ak.decay(total, 0.025, 0.0006)
    crack = ak.band(ak.noise(total, r) * ak.decay(total, (0.014, 0.016, 0.012)[take], 0.0003), 500, (3800, 3200, 4400)[take])
    x = thump + 0.55 * knock + (0.7, 0.6, 0.8)[take] * crack / np.abs(crack).max()
    return ak.ends(ak.band(ak.drive(x / np.abs(x).max(), 2.2), high=5000), 0.0003, 0.012)


LIFT = (3.0, 3.4, 3.6)   # how far the low body's weight band is lifted over the rest
WEIGHT = ((115, 260), (150, 340), (115, 230))   # that band, a take: the second sits a third higher


def heavy_low(take):
    total = (0.16, 0.14, 0.18)[take]
    start, end = (98.0, 106.0, 90.0)[take], (58.0, 62.0, 54.0)[take]
    fall = np.concatenate([ak.glide(start, end, 0.06, 0.6), np.full(round((total - 0.06) * ak.RATE), end)])
    driven = np.tanh(ak.tone(fall) * (3.2, 3.6, 2.9)[take] + 0.45)   # the lean makes the even harmonics, the drive the odd
    driven -= driven.mean()
    shaped = (driven + ak.band(driven, *WEIGHT[take], 2) * LIFT[take]) * ak.decay(total, total * 0.9, 0.002)
    return ak.ends(ak.band(shaped, high=600, order=2), 0.0005, 0.02)


def shade_air(take):
    r = ak.rng("ShadeAir", take)
    total = (0.34, 0.3, 0.4)[take]
    # three airs, not one at three pitches: one closing down, one opening up thin, one low and wide
    close = ak.glide((2600.0, 1300.0, 1500.0)[take], (900.0, 4600.0, 480.0)[take], total, (0.6, 0.8, 0.75)[take])
    air = ak.moving_band(ak.noise(total, r), close, (0.9, 1.6, 0.6)[take])
    flutter = 1 + 0.2 * np.sin(2 * np.pi * (11.0, 14.0, 8.0)[take] * ak.clock(total) + r.uniform(0, 6))
    shape = ak.swell(total, (0.04, 0.03, 0.05)[take], (1.2, 1.0, 1.4)[take], 0.05)
    return ak.ends(ak.band(air, (300, 700, 220)[take], (7000, 8000, 3200)[take]) * flutter * shape, 0.003, 0.03)


LAYERS = (
    ("LightHit", "LightContact", light_contact, 4, (150.0, 0.85),
     "a knock of two partials near 300 to 470 Hz falling a third, and a snap of noise from about 700 Hz to 3.8 kHz",
     "on the hit's frame with no lead, under a recorded body: the cue's top, where the body's own comes late"),
    ("HeavyHit", "HeavyContact", heavy_contact, 3, (120.0, 0.6),
     "a thump falling an octave from near 240 Hz, a knock near 520 Hz and a crack of noise to about 3.8 kHz, driven",
     "on the hit's frame with no lead, under the recorded heavy body"),
    ("HeavyHit", "HeavyLow", heavy_low, 3, (120.0, 0.5),
     "a sine falling from about 98 to 58 Hz in 60 ms, driven off-centre, its harmonics from 115 Hz up lifted",
     "on the hit's frame, under the recorded heavy body, in HeavySub's place where a short weight is wanted"),
    ("ShadeSwipe", "ShadeAir", shade_air, 3, (150.0, 0.9),
     "noise through a moving band with a slow flutter: closing from 2.6 kHz to 900 Hz, opening from 1.3 to 4.6 kHz, or low "
     "and wide from 1.5 kHz to 480 Hz",
     "from the swipe's frame, under a recorded pass: the air it leaves"),
)


def facts(name, n, x):
    """One file's numbers on the gates' measures, from its samples as read back."""
    p = rank.pick(rank.measures(x, ak.RATE, f"{name} {n}", n))
    top = np.abs(x).max()
    lit = ak.band(ak.band(x, low=200), high=8000)   # the phone's curve: 200 Hz up, 8 kHz down
    return dict(
        file=f"{name}_{n}.ogg", seconds=round(len(x) / ak.RATE, 3), truePeak=round(ak.true_peak(x), 2),
        loudness=round(ak.loudness(x), 1), phone=round(ak.loudness(lit), 1),
        topMs=round(float(np.argmax(np.abs(x))) / ak.RATE * 1000, 1),
        stepIn=round(float(abs(x[0]) / top), 3), stepOut=round(float(abs(x[-1]) / top), 3),
        under120=round(ak.share(x, 0, 120), 3), harsh=round(float(rank.harsh(p)), 1), avg=p["avg"])


def main():
    ak.OUT = OUT
    made, lines = [], []
    for cue, name, make, count, weight, how, use in LAYERS:
        record = ak.layer(cue, name, [make(i) for i in range(count)], weight=weight, made=how, use=use)
        rows = [facts(name, i + 1, x) for i, x in enumerate(record.pop("samples"))]
        pairs = [dict(takes=[i + 1, j + 1], cosine=round(rank.alike(rows[i], rows[j]), 3))
                 for i in range(count) for j in range(i + 1, count)]
        contact = name.endswith("Contact")
        checks = dict(
            truePeak=all(r["truePeak"] <= -1.0 for r in rows),
            ends=all(r["stepIn"] <= STEP and r["stepOut"] <= STEP for r in rows),
            harsh=all(r["harsh"] < HARSH for r in rows),
            takesDiffer=all(p["cosine"] < ALIKE for p in pairs),
            **({"contact": all(r["topMs"] <= TOP_MS for r in rows)} if contact else {}),
            **({"under120": all(r["under120"] <= 0.5 for r in rows)} if name == "HeavyLow" else {}))
        for r in rows:
            r.pop("avg")
        made.append(dict(cue=cue, layer=name, made=how, use=use, takes=rows, pairs=pairs, checks=checks,
                         kitChecks=record["checks"]))
        failed = [k for k, v in {**checks, **{f"kit.{k}": v for k, v in record["checks"].items()}}.items() if not v]
        print(f"  {name}: " + ("every check passes" if not failed else "FAILS " + ", ".join(failed)))
        lines += [f"## {name} ({cue})", "", f"Made of: {how}. Use: {use}.", "",
                  "| file | s | dBTP | LUFS | LUFS, phone | top, ms | step in | step out | under 120 Hz | 2 to 6 kHz peak, dB |",
                  "|---|---|---|---|---|---|---|---|---|---|"]
        lines += [f"| {r['file']} | {r['seconds']} | {r['truePeak']} | {r['loudness']} | {r['phone']} | {r['topMs']} | "
                  f"{r['stepIn']} | {r['stepOut']} | {r['under120']:.0%} | {r['harsh']} |" for r in rows]
        lines += ["", "Takes against each other, cosine of their third octaves: "
                  + ", ".join(f"{p['takes'][0]} and {p['takes'][1]} {p['cosine']}" for p in pairs) + ".",
                  "Checks: " + ", ".join(f"{k} {'passes' if v else 'FAILS'}" for k, v in checks.items()) + ".", ""]
    head = ["# AR39: our support layers, measured", "",
            "From `tools/audio/ar39_support.py`. Each file is read back as written. LUFS is the loudest 400 ms (a short "
            "file padded with silence); the phone's is the same through a 200 Hz high-pass and an 8 kHz low-pass. A step "
            "is an end's first or last sample against the file's top. The 2 to 6 kHz peak is the most a third octave "
            f"there stands over its two neighbours' mean; the gate is under {HARSH:g} dB. Nobody has heard them.", ""]
    (OUT / "own.md").write_text("\n".join(head + lines), encoding="utf-8", newline="\n")
    (OUT / "own.json").write_text(json.dumps(made, indent=1), encoding="utf-8", newline="\n")
    print("wrote", OUT)


if __name__ == "__main__":
    main()
