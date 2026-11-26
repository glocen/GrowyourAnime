"""AR62's icons, the signature press's art, painted, as targets (research's ask, 2026-11-27, after 00:33: painted icons in our
style, the signature press first, two directions in pairs, beside F2's press at three times and at phone size).

Two directions over F2's press, Rook's first (Haymaker: the ram lit, one straight punch, a shockwave along the ground):
    I1, the emblem: the signature's own object, whole, painted, on the gold disc with a light behind it;
    I2, the scene: the disc filled edge to edge with the signature's moment, the object driving at you.
The object is Rook's armoured fist toward us, painted piece by piece: metal ramps lit from above with the disc's
gold bounced at the foot (cool shade, warm bounce), hard cel shades on each piece's far side and a curl's underside,
a heavy ink outline round the whole, thin ink between pieces and hatched in the shade, a specular on each knuckle, a
rivet on each plate, the orange band at the wrist. A first try as boxes modelled in three dimensions read as a screen,
not a punch, and was dropped. It is drawn as SVG, so the game takes it as one image per state.

    py tools/ui/hud_icons.py <out_dir> <fight plate>

Writes icons_press.png (today's flat mark, I1 and I2: ready, firing and cooling, at three times), I1_fight_small.png and
I2_fight_small.png (F2's frame on the smallest phone) and I1_fight.png and I2_fight.png (1920 wide).
"""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import style_frames as sf  # noqa: E402
import hud_finish as hf  # noqa: E402

INK = "#151A26"
# painted metal, lit from above: a bright top, the slate, a dark band, the disc's gold bounced back at the foot (the surface
# study's hue shift: the shade cool, the bounce warm)
METAL = ("#FFFFFF", "#C3CEDF", "#6F7E98", "#465169", "#C9AD7A")
METAL_DARK = ("#DCE3EE", "#93A1B8", "#56627A", "#3A4458", "#A68C5E")
CAP = ("#FFFFFF", "#FFF4C4", "#FFC94A")     # a knuckle's striking face, lit on the Haymaker
BAND = ("#FFE0A0", "#FFB43C", "#C55A16", "#8A3410", "#E99A4A")

# Rook's armoured fist toward us, in a 100 box: the wrist's cuff behind at the lower right with the orange band, the back of
# the hand, four finger plates with their knuckle caps, the thumb across them (AR1's gauntlet, as a fist)
CUFF = (52, 72, 40, 26, 7, -28)          # x, y, w, h, radius, turn
PALM = (13, 38, 72, 46, 15)
FINGERS = [(68, 27, 16, 31, 7.5), (52, 20, 18, 36, 8.0), (34, 16, 19, 40, 8.5), (15, 21, 19, 38, 8.5)]   # little to index
THUMB = (9, 55, 52, 19, 9.5, -6)


class Fist:
    """Paints the fist into the page at (x, y), `size` across its 100 box; `hot` lights the knuckles (the Haymaker)."""

    def __init__(self, P, x, y, size, o=1.0, hot=False):
        self.P, self.x, self.y, self.k, self.o, self.hot = P, x, y, size / 100, o, hot

    def shapes(self):
        """Each piece: (its svg element, open for its paint), its ramp, its kind."""
        cx, cy, cw, ch, cr, ct = CUFF
        px, py, pw, ph, pr = PALM
        tx, ty, tw, th, tr, tt = THUMB
        out = [(f'<rect x="{cx}" y="{cy}" width="{cw}" height="{ch}" rx="{cr}" '
                f'transform="rotate({ct} {cx + cw / 2} {cy + ch / 2})"', METAL_DARK, "cuff"),
               (f'<rect x="{px}" y="{py}" width="{pw}" height="{ph}" rx="{pr}"', METAL, "palm")]
        out += [(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}"', METAL, "finger")
                for x, y, w, h, r in FINGERS]
        out.append((f'<rect x="{tx}" y="{ty}" width="{tw}" height="{th}" rx="{tr}" '
                    f'transform="rotate({tt} {tx + tw / 2} {ty + th / 2})"', METAL, "thumb"))
        return out

    def draw(self):
        P, k, o = self.P, self.k, self.o
        u = 1 / k                                # one page point in the box's units
        P.add(f'<g transform="translate({self.x:.2f},{self.y:.2f}) scale({k:.4f})">')
        sh = self.shapes()
        P.add(f'<g fill="{INK}" stroke="{INK}" stroke-width="{3.2 * o * u:.2f}" stroke-linejoin="round">'
              + "".join(e + "/>" for e, _, _ in sh) + "</g>")
        side, foot = P.uid("s"), P.uid("s")   # hard cel shades: the far (right) side, and a curl's underside
        P.defs.append(f'<linearGradient id="{side}" x1="0" y1="0" x2="1" y2="0"><stop offset="0.6" stop-color="#0B1020" '
                      f'stop-opacity="0"/><stop offset="0.605" stop-color="#0B1020" stop-opacity="0.4"/>'
                      f'<stop offset="1" stop-color="#0B1020" stop-opacity="0.52"/></linearGradient>')
        P.defs.append(f'<linearGradient id="{foot}" x1="0" y1="0" x2="0" y2="1"><stop offset="0.74" stop-color="#0B1020" '
                      f'stop-opacity="0"/><stop offset="0.745" stop-color="#0B1020" stop-opacity="0.34"/>'
                      f'<stop offset="1" stop-color="#0B1020" stop-opacity="0.44"/></linearGradient>')
        for e, stops, kind in sh:
            P.add(f'{e} fill="{P.lin(stops)}" stroke="{INK}" stroke-width="{0.75 * o * u:.2f}"/>')
            if kind == "cuff":      # the orange band round the wrist
                cx, cy, cw, ch, cr, ct = CUFF
                P.add(f'<rect x="{cx + cw * 0.18}" y="{cy}" width="{cw * 0.2}" height="{ch}" fill="{P.lin(BAND)}" '
                      f'stroke="{INK}" stroke-width="{0.75 * o * u:.2f}" transform="rotate({ct} {cx + cw / 2} {cy + ch / 2})"/>')
            P.add(f'{e} fill="url(#{side})"/>')
            if kind in ("finger", "thumb"):
                P.add(f'{e} fill="url(#{foot})"/>')
        if self.hot:   # the knuckles' striking faces burn white-gold, the metal below them as it was
            for x, y, w, h, r in FINGERS:
                P.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h * 0.36}" rx="{r}" fill="{P.lin(CAP)}" stroke="{INK}" '
                      f'stroke-width="{0.6 * o * u:.2f}"/>')
        for x, y, w, h, r in FINGERS:   # each knuckle: its cap's line, the specular, the gold bounce on its right, a rivet
            cap = y + h * 0.34
            P.add(f'<path d="M{x + 1.5},{cap} Q{x + w / 2},{cap + 2.6} {x + w - 1.5},{cap}" fill="none" stroke="{INK}" '
                  f'stroke-opacity="0.7" stroke-width="{0.55 * o * u:.2f}" stroke-linecap="round"/>')
            P.add(f'<path d="M{x + 2},{cap + 1.4} Q{x + w / 2},{cap + 4} {x + w - 2},{cap + 1.4}" fill="none" stroke="#FFFFFF" '
                  f'stroke-opacity="0.35" stroke-width="{0.45 * o * u:.2f}" stroke-linecap="round"/>')
            P.add(f'<rect x="{x + w * 0.2}" y="{y + 3}" width="{w * 0.17}" height="{h * 0.24}" rx="{w * 0.085}" '
                  f'fill="#FFFFFF" fill-opacity="0.78"/>')
            P.add(f'<rect x="{x + w * 0.22}" y="{y + h * 0.45}" width="{w * 0.1}" height="{h * 0.22}" rx="{w * 0.05}" '
                  f'fill="#FFFFFF" fill-opacity="0.3"/>')
            P.add(f'<path d="M{x + w - 1.6},{y + r} V{y + h - r}" stroke="#FFD27A" stroke-opacity="0.85" '
                  f'stroke-width="{0.7 * o * u:.2f}" stroke-linecap="round"/>')
            for j in range(2):      # ink detail in the shade, as a hand would hatch it
                hx = x + w * (0.72 + 0.1 * j)
                P.add(f'<path d="M{hx:.2f},{y + h * 0.78:.2f} l{-w * 0.06:.2f},{h * 0.12:.2f}" stroke="{INK}" '
                      f'stroke-opacity="0.65" stroke-width="{0.5 * o * u:.2f}" stroke-linecap="round"/>')
            rx, ry = x + w * 0.62, y + h * 0.58
            P.add(f'<circle cx="{rx}" cy="{ry}" r="2.1" fill="{INK}"/><circle cx="{rx}" cy="{ry}" r="1.45" fill="#56617A"/>'
                  f'<circle cx="{rx - 0.45}" cy="{ry - 0.45}" r="0.55" fill="#F2F6FC"/>')
        tx, ty, tw, th, tr, tt = THUMB      # the thumb's nail end and its light
        P.add(f'<g transform="rotate({tt} {tx + tw / 2} {ty + th / 2})">'
              f'<path d="M{tx + tw - 13},{ty + 3} V{ty + th - 3}" stroke="{INK}" stroke-opacity="0.65" '
              f'stroke-width="{0.55 * o * u:.2f}" stroke-linecap="round"/>'
              f'<rect x="{tx + 6}" y="{ty + 2.6}" width="{tw * 0.5}" height="{th * 0.16}" rx="{th * 0.08}" fill="#FFFFFF" '
              f'fill-opacity="0.7"/></g>')
        if self.hot:   # and bloom
            P.add('<g fill="#FFF3C0" fill-opacity="0.7" filter="url(#glow)">'
                  + "".join(f'<rect x="{x}" y="{y}" width="{w}" height="{h * 0.36}" rx="{r}"/>' for x, y, w, h, r in FINGERS)
                  + "</g>")
        P.add("</g>")
        return self


def dim(P, state):
    """Cooling: the art drained and dimmed under its count (the state grammar: what can't be pressed loses its colour)."""
    if state == "cooling":
        if "drain" not in "".join(P.defs):
            P.defs.append('<filter id="drain"><feColorMatrix type="saturate" values="0.15"/></filter>')
        P.add('<g filter="url(#drain)" opacity="0.5">')
        return True
    P.add("<g>")
    return False


def emblem(P, cx, cy, ri, state):
    """I1: the fist whole on the gold with a light behind it; on the press, its knuckles lit."""
    dim(P, state)
    P.add(f'<circle cx="{cx}" cy="{cy}" r="{ri * 0.78:.2f}" fill="#FFF6D6" fill-opacity="0.75" filter="url(#glow)"/>')
    size = ri * 1.66
    Fist(P, cx - size * 0.5, cy - size * 0.52, size, o=0.95, hot=state == "firing").draw()
    P.add("</g>")


def scene(P, cx, cy, ri, state):
    """I2: the disc filled with the moment: a burst behind, lines rushing out, the ground's shockwave, the fist lit."""
    cid = P.uid("c")
    P.defs.append(f'<clipPath id="{cid}"><circle cx="{cx}" cy="{cy}" r="{ri:.2f}"/></clipPath>')
    dim(P, state)
    P.add(f'<g clip-path="url(#{cid})">')
    rg = P.uid("r")
    P.defs.append(f'<radialGradient id="{rg}" cx="0.42" cy="0.5" r="0.62"><stop offset="0" stop-color="#FFF8DC"/>'
                  f'<stop offset="0.38" stop-color="#FFC94A"/><stop offset="1" stop-color="#E26A1A"/></radialGradient>')
    P.add(f'<circle cx="{cx}" cy="{cy}" r="{ri:.2f}" fill="url(#{rg})"/>')
    fx, fy = cx - ri * 0.05, cy - ri * 0.2         # the burst's heart: the knuckles
    for i in range(22):                         # lines rushing out from it
        a = math.tau * i / 22 + 0.11
        w = 0.05 if i % 2 else 0.028
        r0, r1 = ri * (0.55 if i % 2 else 0.7), ri * 1.5
        pts = [(fx + r0 * math.cos(a), fy + r0 * math.sin(a)), (fx + r1 * math.cos(a - w), fy + r1 * math.sin(a - w)),
               (fx + r1 * math.cos(a + w), fy + r1 * math.sin(a + w))]
        P.add(f'<polygon points="{" ".join(f"{x:.2f},{y:.2f}" for x, y in pts)}" fill="#FFFFFF" '
              f'fill-opacity="{0.55 if i % 2 else 0.35}"/>')
    star = []                                   # the burst: a white star behind the fist
    for i in range(20):
        a = math.tau * i / 20 - math.pi / 2
        r = ri * (0.78 if i % 2 == 0 else 0.5) * (1.08 if i % 4 == 0 else 1.0)
        star.append((fx + r * math.cos(a), fy + r * math.sin(a)))
    pts = " ".join(f"{x:.2f},{y:.2f}" for x, y in star)
    P.add(f'<polygon points="{pts}" fill="{INK}" stroke="{INK}" stroke-width="1.8" stroke-linejoin="round"/>')
    P.add(f'<polygon points="{pts}" fill="{P.lin(("#FFFFFF", "#FFF1B8"))}"/>')
    sy = cy + ri * 0.62                         # the shockwave along the ground: two front arcs, the near one heavier
    for rx, ry, w in ((ri * 1.05, ri * 0.24, 2.6), (ri * 0.72, ri * 0.15, 1.5)):
        arc = f"M{fx - rx:.2f},{sy:.2f} A{rx:.2f} {ry:.2f} 0 0 0 {fx + rx:.2f},{sy:.2f}"
        P.add(f'<path d="{arc}" fill="none" stroke="{INK}" stroke-width="{w + 1.7:.2f}" stroke-linecap="round"/>')
        P.add(f'<path d="{arc}" fill="none" stroke="{P.lin(("#FFFFFF", "#FFE8A6"))}" stroke-width="{w:.2f}" '
              f'stroke-linecap="round"/>')
    for i, (a, d, s) in enumerate(((200, 0.82, 2.2), (235, 0.9, 1.6), (320, 0.86, 2.0), (345, 0.74, 1.4), (160, 0.7, 1.5))):
        x, y = fx + ri * d * math.cos(math.radians(a)), fy + ri * d * math.sin(math.radians(a))
        chip = [(x - s, y - s * 0.4), (x + s * 0.3, y - s), (x + s, y + s * 0.2), (x - s * 0.2, y + s * 0.9)]
        P.add(f'<polygon points="{" ".join(f"{u:.2f},{v:.2f}" for u, v in chip)}" fill="#3A4258" stroke="{INK}" '
              f'stroke-width="0.7" stroke-linejoin="round"/>')
    size = ri * 1.68
    Fist(P, cx - size * 0.5, cy - size * 0.6, size, o=1.0, hot=True).draw()
    P.add("</g></g>")
    P.add(f'<circle cx="{cx}" cy="{cy}" r="{ri - 0.3:.2f}" fill="none" stroke="{INK}" stroke-opacity="0.55" stroke-width="0.8"/>')


DIRECTIONS = {"I1": ("I1, the emblem", emblem), "I2": ("I2, the scene", scene)}


def press_sheet(T, plate):
    """Rows: today's flat mark, I1, I2; columns: ready, firing, cooling; each cell the press over the same ground."""
    cw, ch, gap, side, top = 128, 104, 6, 92, 20
    rows = [("today's flat mark", None)] + list(DIRECTIONS.values())
    cols = ["ready", "firing", "cooling"]
    P = hf.Page(T)
    uri = Path(plate).resolve().as_uri()
    sw, sh = side + len(cols) * (cw + gap) + gap, top + len(rows) * (ch + gap) + gap
    P.add(f'<rect width="{sw}" height="{sh}" fill="#15191F"/>')
    for j, col in enumerate(cols):
        P.add(f'<text x="{side + gap + j * (cw + gap) + cw / 2}" y="{top - 6}" font-family="Builder Sans" font-size="10" '
              f'fill="#E8EDF4" text-anchor="middle">{col}</text>')
    for i, (name, art) in enumerate(rows):
        y = top + gap + i * (ch + gap)
        P.add(f'<text x="{side - 4}" y="{y + ch / 2 + 3}" font-family="Builder Sans" font-size="10" fill="#E8EDF4" '
              f'text-anchor="end">{sf.esc(name)}</text>')
        for j, col in enumerate(cols):
            hf.ART = art
            keep, P.parts = P.parts, []
            P.add(f'<image href="{uri}" x="0" y="0" width="{hf.W}" height="{hf.H}"/>')
            hf.signature(P, state=col)
            inner, P.parts = "".join(P.parts), keep
            P.add(f'<svg x="{side + gap + j * (cw + gap)}" y="{y}" width="{cw}" height="{ch}" viewBox="-17 108 {cw} {ch}">'
                  f'{inner}</svg>')
    hf.ART = None
    return P.svg(sw, sh), sw, sh


def main():
    out, plate = Path(sys.argv[1]).resolve(), sys.argv[2]
    out.mkdir(parents=True, exist_ok=True)
    T = hf.TAKES["F2"]       # research's pick (d11942a3)
    css = hf.faces()
    svg, sw, sh = press_sheet(T, plate)
    sf.shoot(sf.html(svg, css, sw, sh), out / "icons_press.png", sw, sh, scale=3)
    for key, (name, art) in DIRECTIONS.items():
        hf.ART = art
        svg = hf.fight(T, plate)
        sf.shoot(sf.html(svg, css, hf.W, hf.H), out / f"{key}_fight.png", hf.W, hf.H, scale=hf.SCALE)
        sf.shoot(sf.html(svg, css, hf.W, hf.H, zoom=568 / hf.W), out / f"{key}_fight_small.png", 568,
                 round(hf.H * 568 / hf.W), scale=1)
        print("drew", name)
    hf.ART = None


if __name__ == "__main__":
    main()
