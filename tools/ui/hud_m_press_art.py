"""AR68, M: the press's own art for Rook's Haymaker: the strike painted in 2D, never the fighter (research, 2026-11-27,
13:49: R6 up close stays boxes, so no body in the press). Research picked the burst (G2) at 13:58, with its shock ring
removed (it read as an orbit; an arc open behind the core read as a drawn bow). The cone and the square, not picked,
are in e0a9449c.

    py tools/ui/hud_m_press_art.py <out>

The burst is a field of heat, painted in numpy on the disc's own dark ground and coloured by the strike's ramp (a deep
ember, the Haymaker's heat and ember, its cream core, white): a star of uneven spikes stretched along the strike, its
longest forward, a white core, the speed lines rushing into it from the lower left, an ember bloom round it and ink
cuts through it. tools/ui/hud_m_export.py lays it as the press's images (awake, and greyed while filling). Writes:
- <out>/M_568_day.png and _dusk.png: M's whole frame with it, awake by day, filling at dusk;
- <out>/press_sheet.png: today's stand-in beside the burst, at 4x and at 568's own size, awake by day over filling at
  dusk; <out>/press_64.png: the art alone at 64 px over plain dark.
"""
import math
import struct
import subprocess
import sys
import zlib
from pathlib import Path

import numpy as np
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
import hud_compositions as hc  # noqa: E402
import hud_systems as hs  # noqa: E402

LOOK = "a"      # the plate it sits on: M's dark round, (a) slate (research's pick, 13:38)
INK = "#1E1B22"
RAMP = ((0.0, "#5A1E10"), (0.22, "#B23A16"), (0.42, "#FF6A1E"), (0.62, "#FFA630"), (0.84, "#FFF1CC"), (1.0, "#FFFFFF"))
GROUND_MID, GROUND_EDGE, WARM = "#2E333C", "#14171C", "#3A2722"
PPP = 4                 # the kit's pixels a point
SS = 5                  # painted at five times that
HALF = 25 / 24          # the painting's half side, in the art's radius (the art is 24 pt, its page 50)
ANGLE = 34              # the strike's way, degrees above level: from the lower left to the upper right
D = (math.cos(math.radians(ANGLE)), -math.sin(math.radians(ANGLE)))   # y runs down
SEED = 7


def rgb(h):
    return np.array([int(h[i:i + 2], 16) / 255 for i in (1, 3, 5)])


def ramp(H):
    xs = [p for p, _ in RAMP]
    cs = np.array([rgb(c) for _, c in RAMP])
    h = np.clip(H, 0, 1)
    return np.stack([np.interp(h, xs, cs[:, k]) for k in range(3)], -1)


def frame_of(o, X, Y):
    """The strike's own axes from the point `o`: s along it, t across it (down and to the right is +t)."""
    dx, dy = X - o[0], Y - o[1]
    return dx * D[0] + dy * D[1], -dx * D[1] + dy * D[0]


def smooth(e0, e1, x):
    k = np.clip((x - e0) / (e1 - e0), 0, 1)
    return k * k * (3 - 2 * k)


def streaks(s, t, rng, n, s_range, t_range, length, width, heat, taper=1.6):
    """Speed lines along the strike: each a thin trace bright at its head, fading to its tail behind it."""
    F = np.zeros_like(s)
    for _ in range(n):
        sc, tc = rng.uniform(*s_range), rng.uniform(*t_range)
        L, w, a = rng.uniform(*length), rng.uniform(*width), rng.uniform(*heat)
        ds = s - sc
        along = np.where((ds <= 0) & (ds >= -L), np.clip(1 + ds / L, 0, 1) ** taper, 0.0)
        along = np.where(ds > 0, np.exp(-(ds / (w * 2)) ** 2), along)
        F = np.maximum(F, a * along * np.exp(-((t - tc) / w) ** 2))
    return F


def burst(X, Y, rng):
    """The impact's star stretched along the strike, its white core, the lines rushing in: its heat, its ink cuts, and
    its hottest part (for the core's own bloom)."""
    s, t = frame_of((0.16 * D[0], 0.16 * D[1]), X, Y)
    sp = s / 1.3
    r = np.hypot(sp, t)
    phi = np.arctan2(t, sp)
    spikes = [(0.0, 1.05, 0.2), (math.pi, 0.95, 0.16)]
    for i in range(10):
        a = (i + 0.5) / 10 * 2 * math.pi + rng.uniform(-0.18, 0.18)
        if min(abs(math.remainder(a, 2 * math.pi)), abs(math.remainder(a - math.pi, 2 * math.pi))) < 0.35:
            continue
        spikes.append((a, rng.uniform(0.42, 0.72), rng.uniform(0.11, 0.17)))
    star = np.zeros_like(r)
    for a, ln, hw in spikes:
        dphi = np.abs(np.angle(np.exp(1j * (phi - a))))
        lim = hw * np.clip(1 - r / ln, 0, 1)
        star = np.maximum(star, smooth(0.0, 0.025, lim - dphi) * (0.42 + 0.5 * np.clip(1 - r / ln, 0, 1) ** 0.8))
    core = np.exp(-(r / 0.2) ** 2) * 1.2
    lines = streaks(s, t, rng, 16, (-0.45, -0.12), (-0.45, 0.45), (0.5, 1.1), (0.008, 0.02), (0.35, 0.75))
    H = np.maximum.reduce([star, core, lines])
    ink = np.zeros_like(r)
    for i in range(4):
        a = (i + 0.25) / 4 * 2 * math.pi + 0.4
        dphi = np.abs(np.angle(np.exp(1j * (phi - a))))
        ink = np.maximum(ink, smooth(0.0, 0.012, 0.03 * np.clip(1 - r / 0.62, 0, 1) - dphi) * smooth(0.16, 0.24, r))
    return H, ink * 0.9, core


def paint():
    """The burst on the disc's own ground at PPP*SS pixels a point over the art's 50-point page: RGB 0 to 1, and each
    pixel's distance from the middle in the art's radius."""
    n = int(round(2 * 25 * PPP * SS))
    a = ((np.arange(n) + 0.5) / n * 2 - 1) * HALF
    X, Y = np.meshgrid(a, a)
    rng = np.random.default_rng(SEED)
    H, ink, hot = burst(X, Y, rng)
    # the dark plate: the face's slate, darker to its edge, warmed a little where the strike's light falls
    r = np.hypot(X, Y)
    g = smooth(0.15, 1.05, r)[..., None]
    plate = rgb(GROUND_MID) * (1 - g) + rgb(GROUND_EDGE) * g
    spill = ndimage.gaussian_filter(H, n * 0.08)
    spill = (spill / max(spill.max(), 1e-6))[..., None]
    plate = plate * (1 - 0.55 * spill) + rgb(WARM) * 0.55 * spill
    # the light: coloured by its heat, opaque where it's hot, and its ember bloom round it
    al = np.clip(H / 0.3, 0, 1)[..., None] ** 0.85
    img = plate * (1 - al) + ramp(H) * al
    img = (img + rgb("#FF6A1E") * 0.42 * ndimage.gaussian_filter(H, n * 0.03)[..., None]
           + rgb("#FFF1CC") * 0.25 * ndimage.gaussian_filter(hot, n * 0.012)[..., None])
    # the ink cuts through it, and a little grain
    img = img * (1 - ink[..., None]) + rgb(INK) * ink[..., None]
    img = img + rng.normal(0, 0.012, img.shape[:2])[..., None]
    return np.clip(img, 0, 1), r


def write_png(path, arr):
    a = (np.clip(arr, 0, 1) * 255 + 0.5).astype(np.uint8)
    h, w, c = a.shape
    raw = b"".join(b"\x00" + a[y].tobytes() for y in range(h))

    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
    png = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6 if c == 4 else 2, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))
    Path(path).write_bytes(png)


def face(path):
    """Paints the burst and writes it to `path` (the face that art() lays)."""
    write_png(path, paint()[0])
    return path


def art(face_png, cx, cy, ra, awake):
    """The draw function for hud_compositions.PRESS_ART: the painted face laid in its circle, its inner shade and ink
    hairline; greyed while the press fills."""
    def draw(P, *_):
        clip = P.clip(hc.circle(cx, cy, ra))
        grade = ""
        if not awake:
            cold = P.uid("cold")
            P.defs.append(f'<filter id="{cold}" color-interpolation-filters="sRGB"><feColorMatrix type="saturate" '
                          f'values="0.12"/><feComponentTransfer><feFuncR type="linear" slope="0.62"/><feFuncG type="linear" '
                          f'slope="0.62"/><feFuncB type="linear" slope="0.66"/></feComponentTransfer></filter>')
            grade = f' filter="url(#{cold})"'
        side = 2 * ra * HALF
        P.add(f'<g clip-path="url(#{clip})"><g{grade}><image href="{face_png.resolve().as_uri()}" x="{cx - side / 2:.2f}" '
              f'y="{cy - side / 2:.2f}" width="{side:.2f}" height="{side:.2f}" preserveAspectRatio="none"/>')
        v = P.uid("vig")
        P.defs.append(f'<radialGradient id="{v}" gradientUnits="userSpaceOnUse" cx="{cx}" cy="{cy}" r="{ra}"><stop offset="0.7" '
                      f'stop-color="#0B0A0D" stop-opacity="0"/><stop offset="1" stop-color="#0B0A0D" stop-opacity="0.55"/>'
                      f'</radialGradient>')
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{ra}" fill="url(#{v})"/></g></g>')
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{ra - 0.3}" fill="none" stroke="{INK}" stroke-width="0.6"/>')
    return draw


def frame(face_png, size, ground, charge):
    hc.M_LOOK = hc.M_LOOKS[LOOK]
    P = hc.Page(size, ground)
    hc.PRESS_ART = (lambda P_, cx, cy, ra, awake: art(face_png, cx, cy, ra, awake)(P_)) if face_png else None
    try:
        hc.m_frame(P, charge)
    finally:
        hc.PRESS_ART = None
    return P


def ff(args):
    subprocess.run(["ffmpeg", "-v", "error", "-y", *args], check=True)


def main(out):
    out.mkdir(parents=True, exist_ok=True)
    work = out / "work"
    work.mkdir(exist_ok=True)
    cx, cy, r = hc.PRESS
    painted = face(work / "face.png")
    tiles = []
    for tag, f in (("today", None), ("burst", painted)):
        for ground, charge in (("day", 1.0), ("dusk", 0.62)):
            src = (out / f"M_568_{ground}.png") if f else (work / f"today_{ground}.png")
            hs.shoot(frame(f, 568, ground, charge), src)
            # the press at its own size (its 2x shoot halved) and at 4x, nearest
            box = (2 * (cx - r - 6), 2 * (cy - r - 6), 2 * (2 * r + 12), 2 * (2 * r + 12))
            own, big = work / f"{tag}_{ground}_own.png", work / f"{tag}_{ground}_big.png"
            ff(["-i", str(src), "-vf", f"crop={box[2]}:{box[3]}:{box[0]}:{box[1]},scale=iw/2:ih/2:flags=area", str(own)])
            ff(["-i", str(own), "-vf", "scale=iw*4:ih*4:flags=neighbor", str(big)])
            tiles.append((tag, own, big))
    # the sheet: in each column, by day over at dusk, each at 4x with its own size under it
    cols = []
    for tag in ("today", "burst"):
        args = []
        for _, own, big in (x for x in tiles if x[0] == tag):
            args += ["-i", str(big), "-i", str(own)]
        f = (f"[1:v]pad=iw*4:ih:(ow-iw)/2:0:color=0x101117[a];[0:v][a]vstack[d];"
             f"[3:v]pad=iw*4:ih:(ow-iw)/2:0:color=0x101117[b];[2:v][b]vstack[k];[d][k]vstack,pad=iw+24:ih:12:0:color=0x101117")
        col = work / f"col_{tag}.png"
        ff([*args, "-filter_complex", f, str(col)])
        cols.append(col)
    ff(["-i", str(cols[0]), "-i", str(cols[1]), "-filter_complex", "hstack=2", str(out / "press_sheet.png")])
    ff(["-f", "lavfi", "-i", "color=c=0x101117:s=88x88", "-i", str(painted), "-filter_complex",
        "[1]scale=64:64:flags=area,format=rgba,geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':"
        "a='255*lte(hypot(X-31.5,Y-31.5),30.7)'[c];[0][c]overlay=12:12", "-frames:v", "1", str(out / "press_64.png")])
    for f in work.iterdir():
        f.unlink()
    work.rmdir()


if __name__ == "__main__":
    main(Path(sys.argv[1]).resolve())
