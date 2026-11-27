"""AR68, M: the press's own art for Rook's Haymaker, three targets for research's pick (research, 2026-11-27, 13:22; its
study of 01:41, AR62: the disc filled edge to edge with a rendered picture of the move, dark, one hot accent).

    py tools/ui/hud_m_press_art.py <renders> <out>

<renders> holds tools/blender/press_art.py's <take>.png, <take>_hot.png and <take>.json. Each take's art is Rook as
made, posed in the move, under the Haymaker's own strike: the effect's square of chisel bars (cream core, ember, ink
rim; Config.Effects' Haymaker, tools/blender/rook_haymaker_art.py) breaking open round the knuckles, its white-hot
flash on them, the wraps' heat bloomed, rushing lines, on a dark ember ground. T3, the silhouette, inks the whole of
him as one shape edged in ember, against the strike's own orange-white light (the impact frame). Writes:
- <out>/<take>_art.png: the art alone in its circle, at the kit's 4 pixels a point, on alpha (for the upload);
- <out>/M_568_<take>_day.png and _dusk.png: M's whole frame with it, awake by day, filling at dusk (the art greyed);
- <out>/press_art_pair.png: the presses side by side (today's stand-in, T1, T2, T3), at 4x and at 568's own size,
  awake by day over filling at dusk (delivered as build/handoff/UI/ar68/m_dark/press_art/m_press_today_T1_T2_T3.png;
  its m_press_T3_corner.png is an ffmpeg crop, 720 by 400 from the top left, of M_568_T3_dusk beside _day).
"""
import json
import math
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import hud_compositions as hc  # noqa: E402
import hud_m_export as mx  # noqa: E402
import hud_systems as hs  # noqa: E402

CORE, EMBER, INK = "#FFF1CC", "#FFA630", "#1E1B22"    # the Haymaker's bar (rook_sheet.PALETTE, rook_haymaker_art.py)
HEAT = "#FF6A1E"
LOOK = "a"      # the plate it sits on: M's dark round, (a) slate (AR68, 13:38); the face art carries to (b)
SIZE = 768

# Each take's crop of its render (its middle, 0 to 1, and half its side) and its strike: the flash's size (of the
# art's radius), the square's size and the corner it's broken at, and the rushing lines' way (radial from the
# knuckles, or along the arm).
TAKES = {
    "T1": dict(name="the drive", centre=(0.47, 0.57), half=0.36, flash=0.5, square=0.36, open=-40, lines="along"),
    "T2": dict(name="the charge", centre=(0.58, 0.62), half=0.34, flash=0.5, square=0.34, open=-20, lines="radial"),
    # the whole of him in the punch, one dark shape against the strike's light, its edge toward the light lit ember
    "T3": dict(name="the silhouette", centre=(0.6, 0.53), half=0.45, flash=0.5, square=0.3, open=-30, lines="radial",
               silhouette=True),
}


def star(cx, cy, r, points=4, inner=0.2, turn=0.0):
    pts = []
    for i in range(points * 2):
        a = math.radians(turn) + math.pi * i / points
        rr = r if i % 2 == 0 else r * inner
        pts.append((cx + rr * math.sin(a), cy - rr * math.cos(a)))
    return hc.poly(pts)


def chisel(x0, y0, x1, y1, w):
    """One of the Haymaker's bars: a stroke struck like a chisel's, square at its start, cut at a slant at its end."""
    dx, dy = x1 - x0, y1 - y0
    n = math.hypot(dx, dy)
    ux, uy, px, py = dx / n, dy / n, -dy / n * w / 2, dx / n * w / 2
    cut = w * 0.9
    return hc.poly([(x0 + px, y0 + py), (x1 + px, y1 + py), (x1 - px - ux * cut, y1 - py - uy * cut), (x0 - px, y0 - py)])


def bars(P, kx, ky, side, open_at, w):
    """The strike's square round the knuckles, its corner at `open_at` degrees flung open: four bars in the effect's three
    tones, the ink rim under, the ember, the cream core."""
    h = side / 2
    a = math.radians(open_at)
    ca, sa = math.cos(a), math.sin(a)

    def rot(x, y):
        return kx + x * ca - y * sa, ky + x * sa + y * ca

    gap = side * 0.16
    segs = [((-h + gap, -h), (h, -h)), ((h, -h), (h, h)), ((h, h), (-h, h)), ((-h, h), (-h, -h + gap))]
    for width, colour in ((w * 1.7, INK), (w * 1.15, EMBER), (w * 0.55, CORE)):
        for (x0, y0), (x1, y1) in segs:
            (X0, Y0), (X1, Y1) = rot(x0, y0), rot(x1, y1)
            P.add(f'<path d="{chisel(X0, Y0, X1, Y1, width)}" fill="{colour}"/>')
    # the flung corner's two chips, thrown out
    for d, s in ((1.0, 0.5), (1.32, 0.34)):
        X, Y = rot(-h * d - gap * 0.3, -h * d - gap * 0.3)
        P.add(f'<path d="{star(X, Y, w * 1.6 * s * 2, 4, 0.35, 45)}" fill="{CORE}" stroke="{EMBER}" stroke-width="{w * 0.3}"/>')


def art(take, renders, cx, cy, ra, awake):
    """The draw function for hud_compositions.PRESS_ART: the take's art in a circle of `ra` round cx, cy. The strike's
    light is behind the fist, so the fist reads as its shape against it (the impact frame's read); nothing is drawn over
    the fist but its own heat."""
    t = TAKES[take]
    info = json.loads((renders / f"{take}.json").read_text(encoding="utf-8"))
    u0, v0 = t["centre"]
    W = ra / t["half"]                         # the render's side in points

    def at(uv):
        return cx + (uv[0] - u0) * W, cy + (uv[1] - v0) * W

    face = [at(c) for c in info["corners"]]
    kx, ky = sum(p[0] for p in face) / 4, sum(p[1] for p in face) / 4   # the fist's face, where the strike lands
    fx, fy = at(info["forearm"])

    def draw(P, *_):
        clip = P.clip(hc.circle(cx, cy, ra))
        cold = P.uid("cold")
        grade = "" if awake else f' filter="url(#{cold})"'
        if not awake:
            P.defs.append(f'<filter id="{cold}" color-interpolation-filters="sRGB"><feColorMatrix type="saturate" '
                          f'values="0.12"/><feComponentTransfer><feFuncR type="linear" slope="0.62"/><feFuncG type="linear" '
                          f'slope="0.62"/><feFuncB type="linear" slope="0.66"/></feComponentTransfer></filter>')
        P.add(f'<g clip-path="url(#{clip})"><g{grade}>')
        g = P.uid("ground")
        if t.get("silhouette"):   # the impact frame: the light behind the whole of him, hot at the fist
            P.defs.append(f'<radialGradient id="{g}" gradientUnits="userSpaceOnUse" cx="{kx:.2f}" cy="{ky:.2f}" '
                          f'r="{ra * 2.3:.2f}"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.16" stop-color="{CORE}"/>'
                          f'<stop offset="0.45" stop-color="{EMBER}"/><stop offset="0.8" stop-color="#D8531E"/>'
                          f'<stop offset="1" stop-color="#7A2A14"/></radialGradient>')
        else:
            P.defs.append(f'<radialGradient id="{g}" gradientUnits="userSpaceOnUse" cx="{kx:.2f}" cy="{ky:.2f}" '
                          f'r="{ra * 1.9:.2f}"><stop offset="0" stop-color="#5A2412"/><stop offset="0.3" stop-color="#2A1514"/>'
                          f'<stop offset="1" stop-color="#121014"/></radialGradient>')
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{ra}" fill="url(#{g})"/>')
        # the rushing lines: along the strike, or out from the fist
        dx, dy = kx - fx, ky - fy
        n = math.hypot(dx, dy)
        ux, uy = dx / n, dy / n
        if t["lines"] == "radial":
            for i in range(22):
                a = 2 * math.pi * i / 22 + 0.11 * (i % 3)
                r0, r1, wd = ra * 0.5, ra * 2.4, 0.035 + 0.03 * (i % 2)
                p = [(kx + r0 * math.cos(a), ky + r0 * math.sin(a)),
                     (kx + r1 * math.cos(a - wd), ky + r1 * math.sin(a - wd)),
                     (kx + r1 * math.cos(a + wd), ky + r1 * math.sin(a + wd))]
                ink = "#3A1408" if t.get("silhouette") else "#FF9A4A"
                P.add(f'<path d="{hc.poly(p)}" fill="{ink}" fill-opacity="{0.16 if i % 2 else 0.08}"/>')
        else:
            for i in range(16):
                off = (i - 7.5) * ra * 0.13
                back = ra * (0.5 + 0.45 * (i % 3))
                sx, sy = kx - uy * off - ux * back, ky + ux * off - uy * back
                ln = ra * (1.0 + 0.4 * (i % 4))
                P.add(f'<path d="M {sx:.2f},{sy:.2f} L {sx - ux * ln:.2f},{sy - uy * ln:.2f}" stroke="#FF9A4A" '
                      f'stroke-opacity="{0.22 if i % 2 else 0.1}" stroke-width="{0.5 + 0.35 * (i % 2):.2f}" '
                      f'stroke-linecap="round"/>')
        # the strike's light, behind the fist: its ember halo, the Haymaker's square broken open round it, its white core
        fr = ra * t["flash"]
        h = P.uid("halo")
        P.defs.append(f'<radialGradient id="{h}"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.22" stop-color="{CORE}"/>'
                      f'<stop offset="0.5" stop-color="{EMBER}" stop-opacity="0.8"/><stop offset="1" stop-color="{HEAT}" '
                      f'stop-opacity="0"/></radialGradient>')
        P.add(f'<circle cx="{kx:.2f}" cy="{ky:.2f}" r="{fr:.2f}" fill="url(#{h})"/>')
        bars(P, kx, ky, ra * t["square"] * 2, t["open"], ra * 0.07)
        # Rook in the move, dark against it
        x, y = cx - u0 * W, cy - v0 * W
        sil = ""
        if t.get("silhouette"):
            sil = P.uid("sil")
            gx, gy = (cx - kx), (cy - ky)
            gn = math.hypot(gx, gy) or 1.0
            ox, oy = gx / gn * ra * 0.05, gy / gn * ra * 0.05      # the edge facing the light
            P.defs.append(f'<filter id="{sil}" x="-5%" y="-5%" width="110%" height="110%" color-interpolation-filters="sRGB">'
                          f'<feFlood flood-color="#120F13"/><feComposite in2="SourceAlpha" operator="in" result="ink"/>'
                          f'<feOffset in="SourceAlpha" dx="{ox:.2f}" dy="{oy:.2f}" result="o"/><feComposite in="SourceAlpha" '
                          f'in2="o" operator="out" result="edge"/><feFlood flood-color="{EMBER}"/><feComposite in2="edge" '
                          f'operator="in" result="rim"/><feMerge><feMergeNode in="ink"/><feMergeNode in="rim"/></feMerge>'
                          f'</filter>')
            sil = f' filter="url(#{sil})"'
        P.add(f'<image href="{(renders / f"{take}.png").resolve().as_uri()}" x="{x:.2f}" y="{y:.2f}" width="{W:.2f}" '
              f'height="{W:.2f}"{sil}/>')
        # the wraps' own heat, bloomed: the one hot thing on him
        b = P.uid("bloom")
        P.defs.append(f'<filter id="{b}" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur '
                      f'stdDeviation="{ra * 0.07:.2f}"/></filter>')
        hot = (renders / f"{take}_hot.png").resolve().as_uri()
        P.add(f'<image href="{hot}" x="{x:.2f}" y="{y:.2f}" width="{W:.2f}" height="{W:.2f}" filter="url(#{b})" '
              f'style="mix-blend-mode:screen"/>')
        # the disc's own edge: an inner shade, an ink hairline
        v = P.uid("vig")
        P.defs.append(f'<radialGradient id="{v}" gradientUnits="userSpaceOnUse" cx="{cx}" cy="{cy}" r="{ra}"><stop offset="0.66" '
                      f'stop-color="#0B0A0D" stop-opacity="0"/><stop offset="1" stop-color="#0B0A0D" stop-opacity="0.6"/>'
                      f'</radialGradient>')
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{ra}" fill="url(#{v})"/></g></g>')
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{ra - 0.3}" fill="none" stroke="{INK}" stroke-width="0.6"/>')
    return draw


def frame(take, renders, size, ground, charge):
    hc.M_LOOK = hc.M_LOOKS[LOOK]
    P = hc.Page(size, ground)
    hc.PRESS_ART = (lambda P_, cx, cy, ra, awake: art(take, renders, cx, cy, ra, awake)(P_)) if take else None
    try:
        hc.m_frame(P, charge)
    finally:
        hc.PRESS_ART = None
    return P


def ff(args):
    subprocess.run(["ffmpeg", "-v", "error", "-y", *args], check=True)


def main(renders, out):
    out.mkdir(parents=True, exist_ok=True)
    work = out / "work"
    work.mkdir(exist_ok=True)
    cx, cy, r = hc.PRESS
    ra = r - 6
    tiles = []
    for take in (None, "T1", "T2", "T3"):
        tag = take or "today"
        for ground, charge in (("day", 1.0), ("dusk", 0.62)):
            P = frame(take, renders, 568, ground, charge)
            if take:
                hs.shoot(P, out / f"M_568_{take}_{ground}.png")
                src = out / f"M_568_{take}_{ground}.png"
            else:
                hs.shoot(P, work / f"today_{ground}.png")
                src = work / f"today_{ground}.png"
            # the press at its own size (its 2x shoot halved) and at 4x, nearest
            box = (2 * (cx - r - 6), 2 * (cy - r - 6), 2 * (2 * r + 12), 2 * (2 * r + 12))
            own, big = work / f"{tag}_{ground}_own.png", work / f"{tag}_{ground}_big.png"
            ff(["-i", str(src), "-vf", f"crop={box[2]}:{box[3]}:{box[0]}:{box[1]},scale=iw/2:ih/2:flags=area", str(own)])
            ff(["-i", str(own), "-vf", "scale=iw*4:ih*4:flags=neighbor", str(big)])
            tiles.append((tag, ground, own, big))
        if take:
            A = mx.bare_page(2 * ra + 2, 2 * ra + 2)
            art(take, renders, ra + 1, ra + 1, ra, True)(A)
            mx.transparent_shoot(A, out / f"{take}_art.png")
    # the sheet: rows by day and at dusk; in each, today's, T1 and T2 at 4x, with their own size under each
    cols = []
    for tag in ("today", "T1", "T2", "T3"):
        ins = [t for t in tiles if t[0] == tag]
        args = []
        for _, _, own, big in ins:
            args += ["-i", str(big), "-i", str(own)]
        f = (f"[1:v]pad=iw*4:ih:(ow-iw)/2:0:color=0x101117[a];[0:v][a]vstack[d];"
             f"[3:v]pad=iw*4:ih:(ow-iw)/2:0:color=0x101117[b];[2:v][b]vstack[k];[d][k]vstack,pad=iw+24:ih:12:0:color=0x101117")
        col = work / f"col_{tag}.png"
        ff([*args, "-filter_complex", f, str(col)])
        cols.append(col)
    ff(["-i", str(cols[0]), "-i", str(cols[1]), "-i", str(cols[2]), "-i", str(cols[3]), "-filter_complex", "hstack=4",
        str(out / "press_art_pair.png")])
    for f in work.iterdir():
        f.unlink()
    work.rmdir()


if __name__ == "__main__":
    main(Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve())
