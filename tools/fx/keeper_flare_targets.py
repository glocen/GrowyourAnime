"""AR7 C4's option 2, the keeper's challenge as an upright warm flare at the lantern on Stamp, beside option 3 (the ring
off, the clip and the lantern's glow alone) and today's C4 (research's ask, 2026-11-26, 18:4x). Drawn on the take of the
keeper's real entrance at the player's camera (the gate's own try, 60 fps), frame by frame from Stamp, the flare riding
the lantern where the take has it. No camera numbers were kept for this take, so sizes are in studs at the lantern's
measured scale (PX).

    py tools/fx/keeper_flare_targets.py [take.mkv]

Writes build/handoff/Lamplighter/targets/C4x_<name>_entrance_{peak,strip}.png for F1 (the drop), F2 (the upright star),
O3 (the ring off) and C4 (today's take as it is), with the phone and squint sheets of the four peaks.
"""
import math
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
from paintover import Frame, phone_sheets, strip, write_png  # noqa: E402

TAKE = ROOT / "build" / "scratch" / "scintilla" / "ward" / "takes" / "c4_entrance.mkv"
OUT = ROOT / "build" / "handoff" / "Lamplighter" / "targets"
VIEW = "2042:1134:40:218"
W, H = 2042, 1134
STAMP = 350  # the take's frame at Stamp (5.833 s): the ring's first frame
BEFORE = 347  # the last frame before the ring, for O3
PX = 66.0  # pixels a stud at the lantern: the keeper (7.5 studs at Scale 1.5) stands about 500 px tall
POLE = 4.1  # studs from the lantern down to the pole's foot, as the take has them at Stamp (272 px)
TIMES = [-2, 0, 2, 4, 7, 11, 16, 22]  # the lead's first blow lands at 30  # frames from Stamp, at 60 a second
PEAK = 3
CROP = (700, 0, 1100, 1000)  # x, y, w, h: the keeper, the lantern's reach above, the lead and the avatar below
NO_CAM = {"CFrame": [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1], "Fov": 70, "Viewport": [W, H]}

GOLD = (1.0, 0.78, 0.42)  # the hot core, warm, never white
AMBER = (1.0, 0.46, 0.09)  # C4's band #E07A16, as light
EMBER = (0.75, 0.2, 0.02)  # the halo's deep edge


def frames(path, picks):
    import subprocess
    sel = "+".join(f"eq(n\\,{k})" for k in sorted(set(picks)))
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(path), "-vf", f"crop={VIEW},select='{sel}'",
                          "-fps_mode", "passthrough", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
                         capture_output=True, check=True).stdout
    got = np.frombuffer(raw, np.uint8).reshape(-1, H, W, 3)
    return dict(zip(sorted(set(picks)), got))


def lantern_at(img):
    """The lantern's middle: the brightest spot under the boss bar round the keeper's head, blurred so the light's
    middle wins over a single hot pixel (the bar's white words sit above y 270)."""
    from paintover import blur
    box = img[270:470, 1150:1350].astype(np.float32).mean(-1)
    y, x = np.unravel_index(np.argmax(blur(box, 10)), box.shape)
    return np.array([x + 1150.0, y + 270.0])


def hud_mask(img):
    """The boss bar and its words, laid back over the light: a light in the world draws under the screen's HUD."""
    m = np.zeros(img.shape[:2], bool)
    m[218:270, 0:1490] = True
    words = img[60:218, 100:1500].astype(np.int16)
    m[60:218, 100:1500] = (words.min(-1) > 175) | ((words[..., 2] > 200) & (words[..., 1] < 140))
    from paintover import blur
    return blur(m.astype(np.float32), 1.0) > 0.2


def ease_out(x):
    x = min(max(x, 0.0), 1.0)
    return 1 - (1 - x) ** 3


def ease_in(x):
    x = min(max(x, 0.0), 1.0)
    return x * x


def glow_px(fr, c, r, colour, k, falloff=2.0):
    sl = fr.box(c, r * 3.2)
    d = np.hypot(fr.xx[sl] - c[0], fr.yy[sl] - c[1]) / max(r, 0.5)
    fr.add(sl, np.exp(-d ** falloff), colour, k)


def line(fr, a, b, wa, wb, colour, k, soft=0.6):
    fr.streak(a, b, wa, wb, colour, k, soft=soft, screen=True)


def strength(f, hold=4, fade=7.0):
    if f < 0:
        return 0.0
    if f < 2:
        return 0.35 + 0.65 * f / 2
    return 1.0 if f <= hold else math.exp(-(f - hold) / fade)


def f1_drop(fr, c, f):
    """F1, the drop: on Stamp the lantern flares and a lance of warm light drops out of it down the pole, speeding up,
    to strike the street at the pole's foot in a flat warm splash: the light and the stamp land together. It burns
    out from the lantern down."""
    if f < 0:
        return
    k = strength(f, hold=6, fade=6.0)
    foot = c + np.array([-0.1, POLE]) * PX
    reach = ease_in(f / 3) if f < 3 else 1.0
    low = c + (foot - c) * max(reach, 0.12)
    gone = ease_in((f - 6) / 14) if f > 6 else 0.0  # the top burns down after the hold
    high = c + (foot - c) * gone + np.array([0, -1.1 * PX * (1 - gone)])
    thin = 1 - 0.5 * min(max((f - 4) / 12, 0), 1)
    line(fr, high, low, 1.0 * PX * thin, 0.7 * PX * thin, EMBER, 0.3 * k, soft=1.0)  # its glow in the air
    line(fr, high, low, 0.32 * PX * thin, 0.2 * PX * thin, AMBER, 1.2 * k)
    mid = high + (low - high) * 0.45  # the core hot at the lantern, cooling toward the street
    line(fr, high, mid, 0.12 * PX * thin, 0.09 * PX * thin, GOLD, 3.0 * k)
    line(fr, mid, low, 0.09 * PX * thin, 0.05 * PX * thin, GOLD, 1.8 * k)
    glow_px(fr, c, 1.2 * PX, EMBER, 0.6 * k * (1 - gone))
    glow_px(fr, c, 0.5 * PX, AMBER, 1.4 * k * (1 - gone), falloff=2.5)
    if f >= 3:
        s = ease_out((f - 3) / 5)
        e = math.exp(-(f - 3) / 7)
        width = (0.6 + 1.2 * s) * PX
        sl = fr.box(foot, width * 1.6)
        flat = np.exp(-(((fr.xx[sl] - foot[0]) / width) ** 2 + ((fr.yy[sl] - foot[1]) / (0.22 * width)) ** 2) * 2)
        fr.add(sl, flat, AMBER, 1.3 * e)  # a pool of light on the street, flat as the street lies
        for i, (dx, up) in enumerate(((-0.55, 0.7), (-0.2, 1.0), (0.2, 0.95), (0.6, 0.65))):  # a fan of short sparks
            tip = foot + np.array([dx * (0.9 + 0.8 * s), -up * (0.5 + 0.7 * s)]) * PX
            line(fr, foot + (dx * 0.15 * PX, 0), tip, 0.08 * PX, 0.01 * PX, GOLD, 2.2 * e * (1 - s * 0.5))
        glow_px(fr, foot, 0.45 * PX, GOLD, 1.0 * e, falloff=2.5)


def f2_star(fr, c, f):
    """F2, the upright star: on Stamp the lantern throws a tall warm star, its long arms up and down and its short ones
    level, with a thin ring running out of it; the arms draw back into the lantern as it fades."""
    if f < 0:
        return
    k = strength(f, hold=3, fade=6.0)
    grow = ease_out(f / 2.5) * (1 - 0.55 * min(max((f - 4) / 14, 0), 1))
    for d, length, width in (((0, -1), 2.2, 0.24), ((0, 1), 3.0, 0.24), ((-1, 0), 1.0, 0.16), ((1, 0), 1.0, 0.16)):
        tip = c + np.array(d, float) * length * grow * PX
        line(fr, c, tip, width * PX, 0.02 * PX, AMBER, 1.4 * k)
        line(fr, c, tip, width * 0.35 * PX, 0.01 * PX, GOLD, 3.0 * k)
    r = (0.45 + 1.3 * ease_out(f / 9)) * PX
    e = math.exp(-f / 6)
    sl = fr.box(c, r + 0.3 * PX)
    ring = np.hypot(fr.xx[sl] - c[0], fr.yy[sl] - c[1])
    band = np.clip(1 - np.abs(ring - r) / (0.1 * PX), 0, 1) ** 2
    fr.add(sl, band, AMBER, 2.2 * e)
    fr.add(sl, np.clip(1 - np.abs(ring - r) / (0.035 * PX), 0, 1), GOLD, 2.0 * e)
    glow_px(fr, c, 1.2 * PX, EMBER, 0.6 * k)
    glow_px(fr, c, 0.5 * PX, GOLD, 1.5 * k, falloff=2.5)


def ring_off(now, before):
    """O3: the take with C4's ring taken back out. Where the floor only got lighter and warmer than the frame before the
    ring (the band's tint: red up, blue held), the frame before's pixel is put back; bodies moving don't match that."""
    d = now.astype(np.int16) - before.astype(np.int16)
    floorish = before[..., 2].astype(np.int16) > before[..., 0].astype(np.int16) + 8
    tint = (d[..., 0] > 2) & (d[..., 0] - d[..., 2] > 1) & (d[..., 2] > -12) & (np.abs(d).max(-1) < 70) & floorish
    out = now.copy()
    out[tint] = before[tint]
    return out


def crop(img):
    x, y, w, h = CROP
    return img[y:y + h, x:x + w]


def main(argv):
    take = Path(argv[0]) if argv else TAKE
    OUT.mkdir(parents=True, exist_ok=True)
    got = frames(take, [STAMP + f for f in TIMES + [PEAK]] + [BEFORE])
    before = got[BEFORE]
    peaks, names = [], []
    for name, draw, label in (("F1", f1_drop, "the drop"), ("F2", f2_star, "the upright star"),
                              ("O3", None, "the ring off"), ("C4", None, "today's ring")):
        tiles, peak = [], None
        for f in TIMES + [PEAK]:
            img = got[STAMP + f]
            if name == "C4":
                pic = img.astype(np.float32) / 255
            else:
                base = ring_off(img, before) if f >= 0 else img
                if draw is None:
                    pic = base.astype(np.float32) / 255
                else:
                    fr = Frame(None, NO_CAM, base=base.astype(np.float32) / 255)
                    draw(fr, lantern_at(img), f)
                    hud = hud_mask(img)
                    pic = np.where(hud[..., None], img.astype(np.float32) / 255, fr.render())
            if f == PEAK:
                peak = pic
            else:
                tiles.append(crop(pic))
        path = OUT / f"C4x_{name}_entrance_peak.png"
        write_png(peak, path)
        strip(tiles, OUT / f"C4x_{name}_entrance_strip.png", cols=len(TIMES))
        peaks.append(path)
        names.append(f"{name} ({label}, frame {PEAK} from Stamp)")
        print(name, "peak and strip")
    (OUT / "C4x_entrance_strip.txt").write_text(
        "C4x_*_entrance_strip.png: frames from Stamp, at 60 a second: " + ", ".join(map(str, TIMES)) + "\n"
        "F1 the drop, F2 the upright star (option 2's two shapes), O3 the ring off (option 3), C4 today's take as it is.\n",
        encoding="utf-8")
    sheets = OUT / "C4x_phone"
    sheets.mkdir(exist_ok=True)
    phone_sheets(peaks, sheets, names, cols=2)


if __name__ == "__main__":
    main(sys.argv[1:])
