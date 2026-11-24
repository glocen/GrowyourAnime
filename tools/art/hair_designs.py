"""AR64: hair designs drawn flat, before any modelling (the director, 2026-11-24: "Draw designs first").

Each design is a few big locks drawn over the bare head's own render (hair_ways.py's `bare` mode), face on and side on.
A lock here is the lock that will be modelled: a root, a point, a width, a bend, and the same outline the model's wedge
has (broad near its root, drawn to a point), in two flat tones with one band of light. The picked design is then built
lock for lock.

    py tools/art/hair_designs.py <who> <out.png>      (who: rook)

The sheet is drawn as SVG and shot by headless Chrome (no Inkscape needed).
"""
import math
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
LIGHT = (-0.55, -0.83)   # where the drawn light comes from: over his right shoulder


def lock(root, tip, width, bend=0.0, belly=0.3, start=0.7, sharp=1.25, n=22):
    """A lock's outline from `root` to `tip`: `width` at its widest, `belly` of the way along; `start` of that at its
    root; its middle line bowed `bend` of its length to its left. Returns its two edges and its ridge line."""
    (x0, y0), (x1, y1) = root, tip
    dx, dy = x1 - x0, y1 - y0
    cx, cy = (x0 + x1) / 2 - dy * bend, (y0 + y1) / 2 + dx * bend
    left, right, ridge = [], [], []
    side = None
    for i in range(n + 1):
        t = i / n
        px = (1 - t) ** 2 * x0 + 2 * t * (1 - t) * cx + t * t * x1
        py = (1 - t) ** 2 * y0 + 2 * t * (1 - t) * cy + t * t * y1
        tx = 2 * (1 - t) * (cx - x0) + 2 * t * (x1 - cx)
        ty = 2 * (1 - t) * (cy - y0) + 2 * t * (y1 - cy)
        m = math.hypot(tx, ty) or 1.0
        nx, ny = -ty / m, tx / m
        v = min(t / belly, 1.0)
        s = start + (1 - start) * v * v * (3 - 2 * v) if t <= belly else 1 - ((t - belly) / (1 - belly)) ** sharp
        h = width / 2 * max(s, 0.0)
        if side is None:
            side = 1.0 if nx * LIGHT[0] + ny * LIGHT[1] >= 0 else -1.0   # the edge turned to the light
        left.append((px + nx * h * side, py + ny * h * side))
        right.append((px - nx * h * side, py - ny * h * side))
        ridge.append((px - nx * h * side * 0.3, py - ny * h * side * 0.3))
    return left, right, ridge


def path(points):
    return "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in points) + "Z"


TONES = {   # a layer's light face, its shaded face
    "black": [("#1B1D27", "#0F1016"), ("#272A38", "#15171F"), ("#313547", "#1A1C26")],
    "silver": [("#B9C2DA", "#8C96B4"), ("#DCE3F2", "#A6B0CC"), ("#F6F8FD", "#B8C2DC")],
}
GLINT = {"black": "#6F7AA0", "silver": "#FFFFFF"}
INK = {"black": "#06060A", "silver": "#5C6788"}


def draw(view, colour):
    """One view as SVG: the dome, then the locks in their order."""
    out = [f'<path d="{path(view["dome"])}" fill="{TONES[colour][0][1]}" stroke="{INK[colour]}" stroke-width="3" stroke-linejoin="round"/>']
    for i, (root, tip, width, bend, layer, *more) in enumerate(view["locks"]):
        kw = more[0] if more else {}
        left, right, ridge = lock(root, tip, width, bend, **kw)
        lit, shade = TONES[colour][layer]
        out.append(f'<path d="{path(left + right[::-1])}" fill="{lit}" stroke="{INK[colour]}" stroke-width="3" stroke-linejoin="round"/>')
        out.append(f'<path d="{path(ridge + right[::-1])}" fill="{shade}"/>')
        if layer:   # the band of light: a streak on the light face, the same way along every lock
            n = len(left) - 1
            a, b = int(n * 0.28), int(n * 0.62)
            outer, inner = [], []
            for k in range(a, b + 1):
                wide = 0.2 * math.sin(math.pi * (k - a) / (b - a))
                (lx, ly), (rx, ry) = left[k], ridge[k]
                outer.append((lx + (rx - lx) * (0.42 - wide), ly + (ry - ly) * (0.42 - wide)))
                inner.append((lx + (rx - lx) * (0.42 + wide), ly + (ry - ly) * (0.42 + wide)))
            out.append(f'<path d="{path(outer + inner[::-1])}" fill="{GLINT[colour]}" opacity="0.5"/>')
    return "\n".join(out)


# --- Rook's three --------------------------------------------------------------------------------------------------------
# The head in the picture: 1000 px square, the head from x 305 to 695, its top at y 414, the brows at 600, the chin at 773.
# Side on, he faces right. A lock: (root, point, width, bend, layer[, shape]).

BROAD = dict(belly=0.22, start=0.85, sharp=1.1)
LEAF = dict(belly=0.42, start=0.25, sharp=1.2)
LOOSE = dict(belly=0.3, start=0.6, sharp=1.3)

ROOK = {
    "1  Crest": dict(
        about="swept up and back in big points, three locks loose on the forehead",
        front=dict(
            dome=[(305, 610), (316, 500), (360, 452), (430, 438), (500, 458), (570, 438), (640, 452), (684, 500), (695, 610),
                  (722, 560), (728, 430), (680, 345), (500, 315), (320, 345), (272, 430), (278, 560)],
            locks=[((470, 430), (350, 268), 150, 0.1, 0, BROAD), ((485, 430), (448, 178), 170, 0.05, 0, BROAD),
                   ((505, 430), (560, 138), 170, -0.04, 0, BROAD), ((520, 430), (662, 184), 170, -0.1, 0, BROAD),
                   ((535, 430), (726, 282), 150, -0.14, 0, BROAD),
                   ((325, 470), (280, 562), 90, -0.1, 0, BROAD), ((678, 470), (726, 558), 90, 0.1, 0, BROAD),
                   ((312, 520), (292, 632), 62, 0.05, 0, BROAD), ((690, 520), (710, 632), 62, -0.05, 0, BROAD),
                   ((360, 478), (352, 312), 126, 0.1, 1, BROAD), ((428, 462), (442, 252), 136, 0.04, 1, BROAD),
                   ((506, 462), (566, 232), 136, -0.06, 1, BROAD), ((586, 462), (672, 282), 128, -0.1, 1, BROAD),
                   ((648, 482), (712, 362), 104, -0.12, 1, BROAD),
                   ((462, 440), (430, 588), 66, 0.18, 2, LOOSE), ((516, 444), (540, 640), 72, -0.12, 2, LOOSE),
                   ((568, 440), (620, 566), 60, -0.2, 2, LOOSE)]),
        side=dict(
            dome=[(692, 478), (702, 400), (645, 335), (500, 315), (370, 335), (298, 420), (288, 560), (318, 692), (402, 640),
                  (468, 560), (540, 612), (562, 520), (640, 470)],
            locks=[((370, 660), (298, 748), 76, 0.05, 0, BROAD), ((360, 600), (250, 668), 100, 0.1, 0, BROAD),
                   ((380, 520), (218, 566), 124, 0.08, 0, BROAD), ((400, 440), (190, 452), 136, 0.1, 0, BROAD),
                   ((450, 400), (205, 338), 156, 0.12, 0, BROAD), ((520, 390), (282, 242), 166, 0.13, 1, BROAD),
                   ((590, 392), (396, 194), 166, 0.12, 1, BROAD), ((644, 402), (516, 200), 156, 0.1, 1, BROAD),
                   ((684, 446), (630, 236), 124, 0.1, 1, BROAD),
                   ((560, 520), (572, 644), 54, 0.0, 1, BROAD),
                   ((672, 440), (700, 628), 66, -0.16, 2, LOOSE), ((690, 448), (742, 580), 58, -0.2, 2, LOOSE)])),
    "2  Shag": dict(
        about="full and loose, over the forehead to the brows, its points turned out",
        front=dict(
            dome=[(326, 660), (340, 560), (400, 520), (500, 540), (600, 520), (660, 560), (674, 660), (724, 640), (764, 520),
                  (738, 388), (640, 318), (500, 298), (360, 318), (262, 388), (236, 520), (276, 640)],
            locks=[((300, 500), (196, 606), 124, -0.2, 0, BROAD), ((292, 580), (232, 702), 100, -0.14, 0, BROAD),
                   ((700, 500), (804, 606), 124, 0.2, 0, BROAD), ((708, 580), (768, 702), 100, 0.14, 0, BROAD),
                   ((476, 336), (424, 236), 84, 0.22, 0, LEAF), ((524, 334), (598, 250), 76, -0.22, 0, LEAF),
                   ((500, 345), (232, 486), 150, 0.2, 1, LEAF), ((500, 345), (768, 486), 150, -0.2, 1, LEAF),
                   ((502, 348), (300, 706), 104, 0.22, 1, LEAF), ((508, 348), (700, 706), 104, -0.22, 1, LEAF),
                   ((502, 350), (336, 614), 128, 0.2, 2, LEAF), ((503, 350), (408, 584), 116, 0.14, 2, LEAF),
                   ((504, 350), (466, 646), 106, 0.06, 2, LEAF), ((506, 350), (530, 606), 108, -0.06, 2, LEAF),
                   ((507, 350), (598, 640), 114, -0.12, 2, LEAF), ((508, 350), (664, 604), 124, -0.2, 2, LEAF)]),
        side=dict(
            dome=[(700, 640), (716, 540), (742, 430), (690, 340), (560, 300), (420, 302), (300, 360), (232, 480), (240, 640),
                  (300, 730), (420, 716), (500, 640), (560, 700), (640, 680)],
            locks=[((300, 560), (212, 668), 124, -0.18, 0, BROAD), ((320, 640), (262, 762), 104, -0.12, 0, BROAD),
                   ((400, 660), (372, 776), 110, -0.05, 0, BROAD),
                   ((470, 336), (410, 240), 80, 0.2, 0, LEAF),
                   ((460, 350), (222, 560), 150, 0.2, 1, LEAF), ((462, 350), (300, 700), 140, 0.16, 1, LEAF),
                   ((466, 350), (430, 736), 140, 0.08, 1, LEAF), ((470, 350), (544, 716), 130, -0.04, 1, LEAF),
                   ((474, 350), (628, 700), 116, -0.12, 1, LEAF),
                   ((476, 348), (704, 652), 116, -0.18, 2, LEAF), ((478, 346), (744, 606), 120, -0.24, 2, LEAF),
                   ((478, 344), (762, 520), 100, -0.3, 2, LEAF)])),
    "3  Sweep": dict(
        about="parted on one side and swept across the forehead, short and close at the back",
        front=dict(
            dome=[(308, 610), (318, 520), (372, 470), (500, 480), (628, 470), (682, 520), (692, 610), (730, 580), (752, 470),
                  (712, 372), (610, 318), (480, 304), (350, 322), (274, 392), (256, 500), (280, 590)],
            locks=[((315, 500), (236, 612), 104, -0.15, 0, BROAD), ((310, 560), (280, 664), 64, 0.05, 0, BROAD),
                   ((690, 480), (780, 600), 124, 0.2, 0, BROAD), ((700, 560), (750, 692), 92, 0.12, 0, BROAD),
                   ((392, 368), (326, 258), 84, 0.2, 0, LEAF), ((430, 350), (524, 262), 72, -0.25, 0, LEAF),
                   ((400, 372), (246, 524), 136, 0.22, 1, LEAF), ((400, 372), (768, 446), 176, -0.25, 1, LEAF),
                   ((405, 380), (378, 596), 92, 0.12, 2, LEAF), ((410, 378), (462, 620), 110, -0.15, 2, LEAF),
                   ((415, 376), (548, 668), 122, -0.22, 2, LEAF), ((420, 374), (642, 622), 126, -0.28, 2, LEAF),
                   ((425, 372), (718, 556), 122, -0.32, 2, LEAF)]),
        side=dict(
            dome=[(700, 600), (716, 520), (740, 430), (690, 345), (560, 308), (420, 308), (308, 362), (246, 470), (250, 610),
                  (300, 700), (410, 690), (500, 640), (560, 690), (640, 660)],
            locks=[((300, 520), (226, 630), 110, -0.16, 0, BROAD), ((330, 600), (262, 706), 100, -0.12, 0, BROAD),
                   ((380, 650), (350, 752), 90, -0.05, 0, BROAD), ((440, 340), (380, 250), 76, 0.2, 0, LEAF),
                   ((450, 348), (236, 520), 150, 0.2, 1, LEAF), ((452, 350), (300, 660), 140, 0.16, 1, LEAF),
                   ((456, 352), (420, 690), 130, 0.08, 1, LEAF), ((462, 352), (540, 650), 110, -0.04, 1, LEAF),
                   ((458, 348), (628, 668), 110, -0.12, 1, LEAF),
                   ((460, 346), (700, 640), 120, -0.2, 2, LEAF), ((462, 344), (752, 588), 124, -0.26, 2, LEAF),
                   ((462, 342), (770, 500), 104, -0.32, 2, LEAF)])),
}
WHO = {"rook": (ROOK, "black", "Rook")}


def sheet(who, out):
    designs, colour, name = WHO[who]
    shots = REPO / "build" / "scratch" / "modulo" / "hair" / who / "shots"
    cell, pad, top = 620, 26, 96
    wide, tall = pad + len(designs) * (cell + pad), top + 2 * (cell + pad) + 60
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{wide}" height="{tall}" viewBox="0 0 {wide} {tall}">',
             f'<rect width="{wide}" height="{tall}" fill="#12131A"/>',
             f'<text x="{pad}" y="42" fill="#F2F3F7" font-family="Segoe UI, Arial" font-size="26" font-weight="600">'
             f'AR64: {name}\'s hair, three designs drawn flat. Pick one; it is then modelled lock for lock.</text>',
             f'<text x="{pad}" y="72" fill="#A9AEC0" font-family="Segoe UI, Arial" font-size="17">'
             f'Drawn over his own head with no hair, face on and side on. Two flat tones and one band of light, as the model will have.</text>']
    for i, (title, d) in enumerate(designs.items()):
        x = pad + i * (cell + pad)
        for k, view in enumerate(("front", "side")):
            y = top + k * (cell + pad)
            href = (shots / f"Bare_{view}.png").as_uri()
            parts.append(f'<svg x="{x}" y="{y}" width="{cell}" height="{cell}" viewBox="130 110 740 740">'
                         f'<rect x="130" y="110" width="740" height="740" fill="#C9CEDB"/>'
                         f'<image href="{href}" x="0" y="0" width="1000" height="1000"/>{draw(d[view], colour)}</svg>')
        y = top + 2 * (cell + pad)
        parts.append(f'<text x="{x}" y="{y + 22}" fill="#F2F3F7" font-family="Segoe UI, Arial" font-size="24" font-weight="600">{title}</text>')
        parts.append(f'<text x="{x}" y="{y + 46}" fill="#A9AEC0" font-family="Segoe UI, Arial" font-size="15">{d["about"]}</text>')
    parts.append("</svg>")
    with tempfile.TemporaryDirectory() as tmp:
        svg = Path(tmp) / "sheet.svg"
        svg.write_text("\n".join(parts), encoding="utf-8")
        subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
                        f"--user-data-dir={Path(tmp) / 'profile'}", f"--window-size={wide},{tall}",
                        f"--screenshot={Path(out).resolve()}", svg.as_uri()], check=True, capture_output=True, timeout=120)
    print("drew", out, wide, tall)


if __name__ == "__main__":
    sheet(sys.argv[1], sys.argv[2])
