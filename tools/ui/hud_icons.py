"""AR62's icons, the signature press's art, painted (research's ask, 2026-11-27, after 00:33: painted icons in our style, the
signature press first, beside F2's press at three times and at phone size).

Research picked I1, the emblem (dd4142b7): Rook's armoured fist whole on the gold disc, a light behind it. I2, the scene,
was dropped at phone size, its burst and shockwave kept for the press's firing motion. This is I1's finish, with the
pick's two must-fixes:
    1. the fist seated in the press: its shadow cast on the gold, and the gold's warm light bounced onto its lower edges;
    2. drawn at the HUD's weight: a hard-edged cel shadow shape on each plate following its form, one highlight per plate,
       and an outline as heavy as the stroked type's (about 2.3 points outside, the cooling count's 3.6 and the names' 1.7
       either side of it).
Each plate is one piece in its own frame: a light-to-slate ramp, the shadow shape (the plate less its lit oval), the
gold's bounce as a rim along its foot, one highlight, a thin ink line. The rivets and the knuckle caps' lines are the
only small detail. A first try as boxes modelled in three dimensions read as a screen, not a punch, and was dropped. It
is drawn as SVG, so the game takes it as one image per state.

    py tools/ui/hud_icons.py <out_dir> <fight plate>

Writes icons_press.png (today's flat mark and I1: ready, firing and cooling, at three times), I1_fight.png (1920 wide)
and I1_fight_small.png (F2's frame on the smallest phone).
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import style_frames as sf  # noqa: E402
import hud_finish as hf  # noqa: E402

INK = "#151A26"
# painted metal, lit from the upper left: a bright top to the slate (the surface study's hue shift: the shade cool, the
# bounce warm)
METAL = ("#F6F9FD", "#C2CDDE", "#8796AF")
METAL_DARK = ("#D8E0EC", "#99A7BE", "#68778F")
SHADE, SHADE_OP = "#18203A", 0.5       # the cel shadow laid over the metal
BOUNCE, BOUNCE_OP = "#FFB43A", 0.85    # the disc's gold thrown back onto a plate's foot
CAST, CAST_OP = "#7A3A02", 0.42        # the fist's shadow on the gold, down and right of it
CAP = ("#FFFFFF", "#FFF4C4", "#FFC94A")     # a knuckle's striking face, lit on the Haymaker
BAND = ("#FFE0A0", "#FFB43C", "#C55A16")
OUTLINE, LINE = 2.3, 1.0               # page points: the ink outside the whole, the ink between plates

# Rook's armoured fist toward us, in a 100 box: the wrist's cuff behind at the lower right with the orange band, the back of
# the hand, four finger plates with their knuckle caps, the thumb across them (AR1's gauntlet, as a fist)
CUFF = (52, 72, 40, 26, 7, -28)          # x, y, w, h, radius, turn
PALM = (13, 38, 72, 46, 15)
FINGERS = [(68, 27, 16, 31, 7.5), (52, 20, 18, 36, 8.0), (34, 16, 19, 40, 8.5), (15, 21, 19, 38, 8.5)]   # little to index
THUMB = (9, 55, 52, 19, 9.5, -6)
# per kind, as shares of the plate: its lit oval (centre x, y, radius x, y), how deep the gold's bounce reaches at its
# foot, and its one highlight (x, y, w, h); the palm, mostly under the fingers and the thumb, keeps no highlight
FORM = {"finger": ((0.3, 0.34, 0.37, 0.52), 0.2, (0.17, 0.1, 0.17, 0.3)),
        "palm": ((0.34, 0.3, 0.44, 0.52), 0.18, None),
        "thumb": ((0.4, 0.26, 0.46, 0.4), 0.36, (0.13, 0.14, 0.44, 0.2)),
        "cuff": ((0.42, 0.34, 0.44, 0.46), 0.22, (0.46, 0.14, 0.34, 0.15))}


def rect(x, y, w, h, r, extra=""):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}"{extra}/>'


class Fist:
    """Paints the fist into the page at (x, y), `size` across its 100 box; `hot` lights the knuckles (the Haymaker)."""

    def __init__(self, P, x, y, size, o=1.0, hot=False):
        self.P, self.x, self.y, self.k, self.o, self.hot = P, x, y, size / 100, o, hot

    @staticmethod
    def plates():
        """Each plate, back to front: its kind, x, y, w, h, radius, turn and ramp."""
        out = [("cuff", *CUFF, METAL_DARK), ("palm", *PALM, 0, METAL)]
        out += [("finger", *f, 0, METAL) for f in FINGERS]
        out.append(("thumb", *THUMB, METAL))
        return out

    def plate(self, kind, x, y, w, h, r, ramp, u):
        """One plate in its own frame: the ramp, the shadow shape, the bounce at its foot, its highlight, its ink."""
        P = self.P
        (ex, ey, erx, ery), bounce, hi = FORM[kind]
        cid, fid = P.uid("c"), P.uid("c")
        P.defs.append(f'<clipPath id="{cid}">{rect(x, y, w, h, r)}</clipPath>')
        P.defs.append(f'<clipPath id="{fid}"><rect x="{x - 2}" y="{y + h * (1 - bounce)}" width="{w + 4}" '
                      f'height="{h * bounce + 2}"/></clipPath>')
        P.add(rect(x, y, w, h, r, f' fill="{P.lin(ramp)}"'))
        P.add(f'<g clip-path="url(#{cid})">')
        if kind == "cuff":      # the orange band round the wrist, under the shadow like the metal
            P.add(f'<rect x="{x + w * 0.18}" y="{y}" width="{w * 0.2}" height="{h}" fill="{P.lin(BAND)}" stroke="{INK}" '
                  f'stroke-width="{LINE * u:.2f}"/>')
        cx, cy, rx, ry = x + w * ex, y + h * ey, w * erx, h * ery
        P.add(f'<path d="M{x - 2},{y - 2} h{w + 4} v{h + 4} h{-(w + 4)} Z M{cx - rx:.2f},{cy:.2f} '
              f'a{rx:.2f},{ry:.2f} 0 1 0 {2 * rx:.2f},0 a{rx:.2f},{ry:.2f} 0 1 0 {-2 * rx:.2f},0 Z" fill="{SHADE}" '
              f'fill-opacity="{SHADE_OP}" fill-rule="evenodd"/>')
        P.add(f'<g clip-path="url(#{fid})">'
              + rect(x, y, w, h, r, f' fill="none" stroke="{BOUNCE}" stroke-opacity="{BOUNCE_OP}" '
                                    f'stroke-width="{min(w, h) * 0.2:.2f}"') + "</g>")
        if self.hot and kind == "finger":   # the knuckle's striking face burns white-gold
            P.add(rect(x, y, w, h * 0.36, r, f' fill="{P.lin(CAP)}" stroke="{INK}" stroke-width="{LINE * u:.2f}"'))
        if hi:
            hx, hy, hw, hh = hi
            P.add(rect(x + w * hx, y + h * hy, w * hw, h * hh, min(w * hw, h * hh) / 2, ' fill="#FFFFFF" fill-opacity="0.92"'))
        P.add("</g>")
        P.add(rect(x, y, w, h, r, f' fill="none" stroke="{INK}" stroke-width="{LINE * u:.2f}"'))

    def draw(self):
        P, k, o = self.P, self.k, self.o
        u = o / k                                # one page point in the box's units, at this fist's weight
        P.add(f'<g transform="translate({self.x:.2f},{self.y:.2f}) scale({k:.4f})">')
        silhouette = []
        for kind, x, y, w, h, r, t, ramp in self.plates():
            turn = f' transform="rotate({t} {x + w / 2} {y + h / 2})"' if t else ""
            silhouette.append(rect(x, y, w, h, r, turn))
        dx, dy = 2.6 * u, 3.2 * u               # the cast, down and right of the light
        P.add(f'<g transform="translate({dx:.2f},{dy:.2f})" opacity="{CAST_OP}" fill="{CAST}" stroke="{CAST}" '
              f'stroke-width="{2 * OUTLINE * u:.2f}" stroke-linejoin="round">{"".join(silhouette)}</g>')
        P.add(f'<g fill="{INK}" stroke="{INK}" stroke-width="{2 * OUTLINE * u:.2f}" stroke-linejoin="round">'
              + "".join(silhouette) + "</g>")
        for kind, x, y, w, h, r, t, ramp in self.plates():
            P.add(f'<g transform="rotate({t} {x + w / 2} {y + h / 2})">' if t else "<g>")
            self.plate(kind, x, y, w, h, r, ramp, u)
            P.add("</g>")
        for x, y, w, h, r in FINGERS:   # each knuckle: its cap's line and one rivet
            cap = y + h * 0.36
            P.add(f'<path d="M{x + 1.5},{cap:.2f} Q{x + w / 2},{cap + 2.6:.2f} {x + w - 1.5},{cap:.2f}" fill="none" '
                  f'stroke="{INK}" stroke-width="{LINE * u:.2f}" stroke-linecap="round"/>')
            rx, ry = x + w * 0.6, y + h * 0.6
            P.add(f'<circle cx="{rx}" cy="{ry}" r="2.2" fill="{INK}"/><circle cx="{rx}" cy="{ry}" r="1.4" fill="#6A7690"/>'
                  f'<circle cx="{rx - 0.45}" cy="{ry - 0.45}" r="0.55" fill="#F2F6FC"/>')
        if self.hot:   # and bloom
            P.add('<g fill="#FFF3C0" fill-opacity="0.7" filter="url(#glow)">'
                  + "".join(rect(x, y, w, h * 0.36, r) for x, y, w, h, r in FINGERS) + "</g>")
        P.add("</g>")
        return self


def emblem(P, cx, cy, ri, state):
    """I1: the fist whole on the gold, a light behind it up and left; on the press, its knuckles lit. Cooling drains it
    and dims it under its count (the state grammar: what can't be pressed loses its colour)."""
    if state == "cooling":
        if "drain" not in "".join(P.defs):
            P.defs.append('<filter id="drain"><feColorMatrix type="saturate" values="0.15"/></filter>')
        P.add('<g filter="url(#drain)" opacity="0.5">')
    else:
        P.add("<g>")
    P.add(f'<circle cx="{cx - ri * 0.08:.2f}" cy="{cy - ri * 0.1:.2f}" r="{ri * 0.7:.2f}" fill="#FFF6D6" fill-opacity="0.7" '
          f'filter="url(#glow)"/>')
    size = ri * 1.74
    Fist(P, cx - size * 0.52, cy - size * 0.54, size, o=1.0, hot=state == "firing").draw()
    P.add("</g>")


# ---- the rest of the set, the same grammar at the cards' size (research, dd4142b7: the eye, Auto, the skull, the gem and the
# sword). Each is drawn in a 24 box: its outline at the names' weight, a ramp, a hard cel shadow shape, one highlight. ------
SMALL_OUT = 1.6          # page points of ink outside each small icon: the names' stroke shows 1.7
BONE = ("#FFFDF6", "#F1EADB", "#D6C9AE")
STEEL = ("#F7FAFE", "#CBD6E5", "#9DADC5")
GILT = ("#FFF1B0", "#FFC845", "#D58A12")
DULL = ("#E6EBF2", "#B3BECD", "#8592A6")


def edge(P, d, u, w=SMALL_OUT, extra=""):
    """The ink outside a form: its path stroked under everything at `w` page points."""
    P.add(f'<path d="{d}" fill="{INK}" stroke="{INK}" stroke-width="{2 * w * u:.2f}" stroke-linejoin="round" '
          f'stroke-linecap="round"{extra}/>')


def form(P, d, ramp, lit, foot=None):
    """A form: its ramp, then the cel shadow, the form less its lit oval (cx, cy, rx, ry); `foot` is (hue, from y, width), a
    rim of the ground's light along its foot."""
    cid = P.uid("c")
    P.defs.append(f'<clipPath id="{cid}"><path d="{d}"/></clipPath>')
    P.add(f'<path d="{d}" fill="{P.lin(ramp)}"/>')
    cx, cy, rx, ry = lit
    P.add(f'<g clip-path="url(#{cid})"><path d="M-4,-4 H28 V28 H-4 Z M{cx - rx},{cy} a{rx},{ry} 0 1 0 {2 * rx},0 '
          f'a{rx},{ry} 0 1 0 {-2 * rx},0 Z" fill="{SHADE}" fill-opacity="{SHADE_OP}" fill-rule="evenodd"/>')
    if foot:
        hue, y0, w = foot
        bid = P.uid("c")
        P.defs.append(f'<clipPath id="{bid}"><rect x="-4" y="{y0}" width="32" height="{28 - y0}"/></clipPath>')
        P.add(f'<g clip-path="url(#{bid})"><path d="{d}" fill="none" stroke="{hue}" stroke-width="{w}"/></g>')
    P.add("</g>")


def shine(P, x, y, w, h, turn=0):
    """The one highlight."""
    t = f' transform="rotate({turn} {x + w / 2} {y + h / 2})"' if turn else ""
    P.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{min(w, h) / 2}" fill="#FFFFFF" fill-opacity="0.95"{t}/>')


def small(paint):
    """Places a 24-box painter at (x, y), `size` across."""
    def place(P, x, y, size, hue=None):
        k = size / 24
        P.add(f'<g transform="translate({x:.2f},{y:.2f}) scale({k:.4f})">')
        paint(P, 1 / k, hue)
        P.add("</g>")
    return place


@small
def skull(P, u, hue):
    """The foe's mark: a bone skull lit from the upper left, its sockets set a little mean."""
    body = ('M12 2.2 C6.4 2.2 3.2 6.1 3.2 10.5 C3.2 13.5 4.8 15.6 6.8 16.7 V20.8 H17.2 V16.7 C19.2 15.6 20.8 13.5 20.8 10.5 '
            'C20.8 6.1 17.6 2.2 12 2.2 Z')
    edge(P, body, u)
    form(P, body, BONE, (10.2, 8.6, 8.4, 8.2))   # no rim of the card's coral: on bone it reads as flesh
    P.add(f'<path d="M5.6 10.2 Q8.4 8.4 11 10.8 Q10.4 14 7.8 13.9 Q5.4 13.6 5.6 10.2 Z" fill="{INK}"/>'
          f'<path d="M18.4 10.2 Q15.6 8.4 13 10.8 Q13.6 14 16.2 13.9 Q18.6 13.6 18.4 10.2 Z" fill="{INK}"/>'
          f'<path d="M12 14.4 L13.2 16.5 H10.8 Z" fill="{INK}"/>'
          f'<path d="M9.8 18.2 V20.8 M14.2 18.2 V20.8" stroke="{INK}" stroke-width="{1.0 * u:.2f}"/>')
    shine(P, 6.0, 4.6, 3.6, 1.7, -32)


@small
def eye(P, u, hue):
    """Spectate: an anime eye, the upper lid inked heavy and casting its shadow on the white, the iris dark above and lit
    below."""
    almond = "M1.4 12 Q12 2.8 22.6 12 Q12 21.2 1.4 12 Z"
    edge(P, almond, u)
    cid = P.uid("c")
    P.defs.append(f'<clipPath id="{cid}"><path d="{almond}"/></clipPath>')
    P.add(f'<path d="{almond}" fill="{P.lin(("#FFFFFF", "#EEF2F8", "#C9D3E2"))}"/>')
    P.add(f'<g clip-path="url(#{cid})">'
          f'<circle cx="12" cy="12.2" r="5.2" fill="{INK}"/>'
          f'<circle cx="12" cy="12.2" r="4.5" fill="{P.lin(("#0C2348", "#1D5BA8", "#7AC8FF"))}"/>'
          f'<circle cx="12" cy="12.4" r="2.1" fill="#070C16"/>'
          f'<path d="M-2 -2 H26 V9.4 Q12 5.6 -2 11.2 Z" fill="{SHADE}" fill-opacity="{SHADE_OP}"/></g>')
    P.add(f'<path d="M1.4 12 Q12 2.8 22.6 12" fill="none" stroke="{INK}" stroke-width="{1.6 * u:.2f}" '
          f'stroke-linecap="round"/>')
    shine(P, 13.4, 8.6, 2.4, 2.4)


@small
def auto(P, u, hue):
    """Auto: a ring turning on itself, gold when on and steel grey when off; the band lit at the upper left, its lower
    right in hard shade, the head cut in two facets."""
    ramp = DULL if hue == "#AEB9C9" else GILT     # hud_finish.auto: off greys it
    arc = "M19 12 A7 7 0 1 1 15.6 6"
    head = "M14 2.4 L19.9 5.6 L14.5 9.5 Z"
    P.add(f'<path d="{arc}" fill="none" stroke="{INK}" stroke-width="{2.8 + 2 * SMALL_OUT * u:.2f}" '
          f'stroke-linecap="round"/>')
    edge(P, head, u)
    g = P.uid("g")       # the band's light: lit to the upper left, a hard step into shade to the lower right
    P.defs.append(f'<linearGradient id="{g}" gradientUnits="userSpaceOnUse" x1="5" y1="5" x2="19" y2="19">'
                  f'<stop offset="0" stop-color="{ramp[0]}"/><stop offset="0.5" stop-color="{ramp[1]}"/>'
                  f'<stop offset="0.5" stop-color="{ramp[2]}"/><stop offset="1" stop-color="{ramp[2]}"/></linearGradient>')
    P.add(f'<path d="{arc}" fill="none" stroke="url(#{g})" stroke-width="2.8" stroke-linecap="round"/>')
    P.add(f'<path d="{head}" fill="{ramp[1]}"/><path d="M14.25 5.95 L19.9 5.6 L14.5 9.5 Z" fill="{ramp[2]}"/>')
    P.add('<path d="M5.4 10.2 A7 7 0 0 1 8.6 6.1" fill="none" stroke="#FFFFFF" stroke-opacity="0.95" '
          'stroke-width="1.1" stroke-linecap="round"/>')


@small
def gem(P, u, hue):
    """The type's gem, cut: a lit table, the crown's two facets, the pavilion lit left and in shade right."""
    c, d, light = hue
    whole = "M7 3 H17 L21.5 8.6 L12 22 L2.5 8.6 Z"
    edge(P, whole, u)
    for pts, fill in (("7,3 17,3 15,8.6 9,8.6", light), ("2.5,8.6 7,3 9,8.6", light), ("17,3 21.5,8.6 15,8.6", c),
                      ("2.5,8.6 9,8.6 12,22", c), ("9,8.6 15,8.6 12,22", c), ("15,8.6 21.5,8.6 12,22", d)):
        P.add(f'<polygon points="{pts}" fill="{fill}"/>')
    P.add(f'<polygon points="9,8.6 15,8.6 12,22" fill="#FFFFFF" fill-opacity="0.16"/>'
          f'<path d="M2.5 8.6 H21.5 M9 8.6 L12 22 L15 8.6" fill="none" stroke="{d}" stroke-width="0.7"/>')
    shine(P, 8.4, 4.2, 4.6, 1.6, -8)


@small
def sword(P, u, hue):
    """The class, a Warrior's blade: its ridge parting a lit edge from a shaded one, a gilt guard cut the same way, a
    wrapped grip and a gilt pommel."""
    blade = "M17.5 2 L22 2 L22 6.5 L10.5 18 L6 13.5 Z"
    guard = "M4 12 L12 20 L10 22 L2 14 Z"
    edge(P, blade, u)
    edge(P, guard, u)
    P.add(f'<path d="M5.2 18.8 L2.6 21.4" stroke="{INK}" stroke-width="{2.9 + 2 * SMALL_OUT * u:.2f}" stroke-linecap="round"/>')
    P.add(f'<path d="{blade}" fill="{P.lin(STEEL)}"/><path d="M22 2 L22 6.5 L10.5 18 L8.25 15.75 Z" fill="#7F8FAA"/>')
    P.add(f'<path d="{guard}" fill="{GILT[1]}"/><path d="M8 16 L12 20 L10 22 L6 18 Z" fill="{GILT[2]}"/>')
    P.add('<path d="M5.2 18.8 L2.6 21.4" stroke="#6B4320" stroke-width="2.9" stroke-linecap="round"/>'
          '<path d="M4.6 19.4 L3.2 20.8" stroke="#A8743E" stroke-width="0.9" stroke-linecap="round"/>')
    P.add(f'<path d="M22 2 L8.25 15.75" stroke="{INK}" stroke-opacity="0.5" stroke-width="{0.6 * u:.2f}"/>')
    P.add('<path d="M19.4 3.1 L11.6 10.9" stroke="#FFFFFF" stroke-width="1.2" stroke-linecap="round"/>')


PAINTED = {"eye": eye, "auto": auto, "skull": skull, "gem": gem, "sword": sword}   # the kinds the press and cards draw


def press_sheet(T, plate):
    """Rows: today's flat mark, I1; columns: ready, firing, cooling; each cell the press over the same ground."""
    cw, ch, gap, side, top = 128, 104, 6, 92, 20
    rows = [("today's flat mark", None), ("I1, the emblem", emblem)]
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
    for name, art, kit in (("today", None, None), ("set", emblem, PAINTED)):
        hf.ART, hf.PAINTED = art, kit
        svg = hf.fight(T, plate)
        close = svg.replace(f'viewBox="0 0 {hf.W} {hf.H}"', 'viewBox="0 36 560 176"').replace(
            f'width="{hf.W}" height="{hf.H}"', 'width="560" height="176"', 1)
        sf.shoot(sf.html(close, css, 560, 176), out / f"{name}_close.png", 560, 176, scale=3)
        if name == "set":
            sf.shoot(sf.html(svg, css, hf.W, hf.H), out / "set_fight.png", hf.W, hf.H, scale=hf.SCALE)
            sf.shoot(sf.html(svg, css, hf.W, hf.H, zoom=568 / hf.W), out / "set_fight_small.png", 568,
                     round(hf.H * 568 / hf.W), scale=1)
            svg, sw, sh = hf.states(T, plate)
            sf.shoot(sf.html(svg, css, sw, sh), out / "set_states.png", sw, sh, scale=3)
        print("drew", name)
    hf.ART = hf.PAINTED = None


if __name__ == "__main__":
    main()
