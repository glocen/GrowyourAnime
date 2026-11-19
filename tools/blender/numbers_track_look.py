"""AR44's polish: the plain damage digits' tracking (research, 2026-11-19, 20:39). Today's gap beside the proposed, on
the game's own pixels.

  ffmpeg -ss <t> -i build/captures/ar44/numbers-motion.mkv -frames:v 1 -vf crop=350:150:1070:740 <out>/frames/t0p30.png
      for t in 0.30 0.40 0.50 0.65 0.80 0.95 (t0p30.png, t0p40.png and so on)
  blender -b --factory-startup --python tools/blender/numbers_track_look.py -- <abs out>

Faber's clip (AR44, "Faber's must-fixes, the measured colours, and the clip") is the iPhone 16 Pro simulator, at about
1.08 capture pixels to an authored pixel. Each plain number is found by its fill's colour, and its digits by the empty
columns between them. Each gap is narrowed from its middle by what the new Gap takes off that character's pad
(UI.Kit.Digits: round(Gap x Digit x size x the narrower share), in whole authored pixels), times the capture's scale
and the number's own swell (its height over its settled height). The rest of the frame keeps its pixels, the critical
included. Writes <out>/numbers_track_look.png.
"""
import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))

DIGIT = 0.36       # Oswald's digit, in its text size (Config.Hud.Numbers.Styles: Digit)
SCALE = 1.08       # capture pixels to an authored pixel in the clip, measured on the settled 949, 57 and +86
TODAY = 0.45       # Config.Hud.Numbers.Styles' Gap for Dealt, Element, Received and Heal
GAPS = (0.45, 0.25, 0.12, 0.0)
PROPOSED = 0.12
# The plain styles in the clip: their fill (UIKit.Numbers), their size in authored pixels (Combat.Numbers.Size 24 times
# the style's Size) and their fill's height settled, in capture pixels.
STYLES = {
    "Dealt": dict(fill="#F8F1DF", size=24.0, tall=15, warm=True),
    "Received": dict(fill="#E27A6A", size=28.8, tall=17, warm=False),
    "Heal": dict(fill="#6FE695", size=28.8, tall=17, warm=False),
}
# Each moment: its frame, and each plain number on it: its style, its text and a box (x0, y0, x1, y1) it stands in.
# The count's earlier moments (0.30, 0.40) stand on Rook's cream cuff, which a re-lay would tear, so they're left out.
MOMENTS = [
    ("t0p50", [("Dealt", "691", (150, 85, 201, 108))]),
    ("t0p65", [("Dealt", "949", (150, 65, 200, 105)), ("Received", "57", (222, 95, 258, 130))]),
    ("t0p80", [("Dealt", "949", (145, 55, 194, 95)), ("Received", "57", (222, 80, 258, 110)),
               ("Heal", "+86", (260, 90, 320, 130))]),
    ("t0p95", [("Dealt", "949", (140, 45, 220, 85)), ("Received", "57", (210, 70, 260, 100)),
               ("Heal", "+86", (265, 75, 330, 115))]),
]
CLOSE = ("t0p80", (100, 40, 330, 135))   # the frame and the part shown close


def rgb(code):
    return np.array([int(code[i:i + 2], 16) / 255 for i in (1, 3, 5)], np.float32)


def share(char):
    return 0.34 if char in ",." else 0.7 if char == "1" else 0.8 if char in "+-" else 1.0


def pad(gap, size, a, b):
    """UI.Kit.Digits' spaceOf, as its offset: whole authored pixels, half away from zero (math.round)."""
    return math.floor(gap * DIGIT * size * min(share(a), share(b)) + 0.5)


def fill_mask(img, style):
    s = STYLES[style]
    rgb3 = img[..., :3]
    near = np.sqrt(((rgb3 - rgb(s["fill"])) ** 2).sum(-1)) < (0.15 if s["warm"] else 0.2)
    if s["warm"]:
        near &= rgb3[..., 0] >= rgb3[..., 2]
    return near


def glyph_runs(profile):
    """Runs of columns holding fill, a single empty column inside a glyph bridged."""
    on = profile > 0
    runs, start = [], None
    for i, v in enumerate(on):
        if v and start is None:
            start = i
        elif not v and start is not None:
            runs.append([start, i - 1])
            start = None
    if start is not None:
        runs.append([start, len(on) - 1])
    merged = []
    for r in runs:
        if merged and r[0] - merged[-1][1] <= 2:
            merged[-1][1] = r[1]
        else:
            merged.append(r)
    return merged


def find(img, style, text, box):
    """The number's fill box and its glyphs' column runs, in the frame's columns."""
    x0, y0, x1, y1 = box
    sub = fill_mask(img[y0:y1, x0:x1], style)
    # the digits' rows: the run of rows holding the most fill (a cream cuff or a lit edge in the box sits apart)
    best, rows = None, glyph_runs(sub.sum(1))
    for a, b in rows:
        if best is None or sub[a:b + 1].sum() > sub[best[0]:best[1] + 1].sum():
            best = (a, b)
    if best is None:
        raise ValueError(f"no {style} fill in {box}")
    sub[:best[0]], sub[best[1] + 1:] = False, False
    ys, xs = np.nonzero(sub)
    if not len(xs):
        raise ValueError(f"no {style} fill in {box}")
    runs = [[a + x0, b + x0] for a, b in glyph_runs(sub.sum(0))]
    if len(runs) != len(text):
        raise ValueError(f"{style} '{text}' in {box}: {len(runs)} glyphs found, {runs}")
    return (x0 + xs.min(), y0 + ys.min(), x0 + xs.max(), y0 + ys.max()), runs


def relay(img, style, text, box, gap):
    """The frame with this number's gaps narrowed from Gap TODAY to `gap`; and its gaps and width before and after."""
    (fx0, fy0, fx1, fy1), runs = find(img, style, text, box)
    s = STYLES[style]
    k = SCALE * (fy1 - fy0 + 1) / s["tall"]
    drops = []
    for i, ((_, b), (a2, _)) in enumerate(zip(runs, runs[1:])):
        cut = pad(TODAY, s["size"], text[i], text[i + 1]) - pad(gap, s["size"], text[i], text[i + 1])
        drops.append((b + 1, a2 - 1, min(max(int(round(cut * k)), 0), a2 - b - 2)))
    by0, by1 = max(fy0 - 4, 0), min(fy1 + 7, img.shape[0])
    # wide of the soft shadow's tail (Numbers.Shadow: offset 1, spread 2.5), so the columns left in place are ground
    bx0, bx1 = max(fx0 - 10, 0), min(fx1 + 12, img.shape[1])
    gone = set()
    for a, b, d in drops:
        mid = (a + b + 1) // 2 - d // 2
        gone.update(range(mid, mid + d))
    keep = [c for c in range(bx0, bx1) if c not in gone]
    total = bx1 - bx0 - len(keep)
    left = total // 2
    band = img[by0:by1]
    cols = list(range(bx0, bx0 + left)) + keep + list(range(bx1 - (total - left), bx1))
    out = img.copy()
    out[by0:by1, bx0:bx1] = band[:, cols]
    widths = [b - a + 1 for a, b in runs]
    before = [a2 - b - 1 for (_, b), (a2, _) in zip(runs, runs[1:])]
    after = [g - d for g, (_, _, d) in zip(before, drops)]
    return out, dict(glyph=float(np.mean(widths)), before=before, after=after,
                     width=(fx1 - fx0 + 1, fx1 - fx0 + 1 - total))


def relaid(img, numbers, gap):
    notes = []
    for style, text, box in numbers:
        img, note = relay(img, style, text, box, gap)
        notes.append((style, text, note))
    return img, notes


def wrapped(x, y, size, words, colour, room):
    per, lines, line = int(room / (size * 0.52)), [], ""
    for word in words.split():
        if line and len(line) + 1 + len(word) > per:
            lines.append(line)
            line = word
        else:
            line = f"{line} {word}" if line else word
    lines.append(line)
    return [(x, y + i * size * 1.4, size, ln, colour) for i, ln in enumerate(lines)]


def zoomed(img, k):
    return np.repeat(np.repeat(img, k, 0), k, 1)


def main():
    import blcommon as bl
    import rook_sheet as rs

    out = bl.out_dir()
    rs.OUT = out
    frames = {name: rs.load(out / "frames" / f"{name}.png") for name, _ in MOMENTS}
    numbers = dict(MOMENTS)
    looks = {gap: {name: relaid(frames[name], numbers[name], gap) for name in frames} for gap in GAPS}
    fw, fh = frames[MOMENTS[0][0]].shape[1], frames[MOMENTS[0][0]].shape[0]
    _, (cx0, cy0, cx1, cy1) = CLOSE
    zoom, gap_px, label = 3, 24, 30
    close_w, close_h = (cx1 - cx0) * zoom, (cy1 - cy0) * zoom
    width = gap_px + max(len(MOMENTS) * (fw + gap_px), 2 * (close_w + gap_px)) + gap_px
    height = 140 + 2 * (label + fh + gap_px) + 2 * (label + close_h + gap_px) + 120
    page = rs.canvas(width, height, rs.rgb("#101117"))
    ink, soft, pale = "#EDE6D6", "#B4AC9C", "#8C8577"
    text = [(gap_px, 22, 34, "AR44, POLISH: THE PLAIN DIGITS' TRACKING", ink)]
    text += wrapped(gap_px, 70, 16, "Faber's clip of a Tower fight, the game's own pixels. Each plain number's gaps are "
                                    "narrowed by what a smaller Gap takes off UI.Kit.Digits' pad; the critical, the word "
                                    "and the world keep their pixels. Gap is in Oswald's digit, which holds the face's "
                                    "own side room, so today's 0.45 shows a gap as wide as the digit.", soft,
                    width - 2 * gap_px)
    y = 140
    for gap, caption in ((TODAY, f"Today, Gap {TODAY}: the count at 691, then 949, the lead's 57 and the heal's +86, "
                                 "at the capture's own pixels"),
                         (PROPOSED, f"Proposed, Gap {PROPOSED}: the same moments")):
        text.append((gap_px, y, 18, caption, ink))
        y += label
        x = gap_px
        for name, _ in MOMENTS:
            rs.paste(page, looks[gap][name][0], x, y)
            x += fw + gap_px
        y += fh + gap_px
    name = CLOSE[0]
    for row in (GAPS[:2], GAPS[2:]):
        x = gap_px
        for gap in row:
            img, notes = looks[gap][name]
            dealt = next(n for st, _, n in notes if st == "Dealt")
            gaps = dealt["after"] if gap != TODAY else dealt["before"]
            text.append((x, y, 18, f"Gap {gap}{' (today)' if gap == TODAY else ' (proposed)' if gap == PROPOSED else ''}"
                                   f": 949's gaps {gaps[0]} and {gaps[1]} px between {dealt['glyph']:.0f} px digits, "
                                   f"{zoom} times", ink))
            rs.paste(page, zoomed(img[cy0:cy1, cx0:cx1], zoom), x, y + label)
            x += close_w + gap_px
        y += label + close_h + gap_px
    lines = []
    for style, txt, note in looks[PROPOSED][name][1]:
        lines.append(f"{txt} ({style}): gaps {note['before']} to {note['after']} px, {note['width'][0]} to "
                     f"{note['width'][1]} px wide")
    note = ("At Gap 0.12, in this frame: " + "; ".join(lines) + ". The capture draws 1.08 pixels to an authored "
            "pixel; the smallest phone draws 1.28 (0.85 of 1.5), so there each number is 18% larger with the same "
            "proportions.")
    text += wrapped(gap_px, y + 6, 15, note, pale, width - 2 * gap_px)
    rs.paste(page, rs.text_layer(width, height, text), 0, 0)
    rs.save(page, out / "numbers_track_look.png")
    print(f"wrote {out / 'numbers_track_look.png'} ({width} by {height}); {note}")


if __name__ == "__main__":
    main()
