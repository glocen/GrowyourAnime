"""AR68, the UI's complete overhaul: the three directions' targets (research's brief, docs/asset-requests.md, AR68;
the study, docs/research/ui-design.md).

    py tools/ui/overhaul.py <out> [A B C]

Each direction answers "whose device or voice is this UI, in our fiction?":
- A, Console: the player's own yard system. Gauge ticks, readouts with units, one live line linking the HUD, Power's
  amber on warm translucent graphite. One working face: Builder Mono; display: Builder Extended.
- B, Shard: the UI seen in the shard glass. Pale frosted facets with one lit edge, cut at break angles, the shard's
  ice light; a Voidkin's own hue only in its portrait's facet. Working face: Montserrat; display: Michroma.
- C, Episode: the lead's own anime. Ink lines with brush ends and a fine screentone on paper and ink-grey, one hot
  hue that isn't red (cobalt), names set like credits; a title card only at the skill. Working face: Source Sans
  Pro; display: Merriweather.
Common (AR68): the centre 60% of the width is the fighters'; the permanent fight HUD, the press aside, covers about
6% of the screen; the lead compact at the top left, its portrait without a box, a thin red health bar and the charge;
the press the one big thing at the left thumb (where TR52 measured it); every word 14 points or more, the same points
on every phone (Roblox's offsets); never pure black or white; thin lines, flat or cut shapes.

Writes, per direction X: fight_X_852.png and fight_X_568.png (over the clean fight capture), home_X.png (over the
base), tokens_X.png; and skill_C.png (C's title card at the skill), sheet_fight.png (today's game and the three at
the smallest phone, 2x) and sheet_home.png. Rook's portrait render (hud_art.py) stands in for key art everywhere.
"""
import math
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import style_frames as sf  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
FIGHT = REPO / "build" / "scratch" / "modulo" / "hud" / "plates" / "fight.png"     # a real fight, no HUD (1920 x 1066)
BASE = REPO / "build" / "scratch" / "modulo" / "hud" / "plates" / "base.png"       # the base, no HUD
TODAY = REPO / "build" / "scratch" / "faber" / "f2cap" / "fight_ready.jpg"        # today's game, F2's HUD
BUST = REPO / "build" / "handoff" / "Rook" / "make" / "portraits" / "PortraitRook.png"   # stand-in key art
BUST_BOX = (0.28, 0.36, 0.71, 0.73)      # the bust's visible box in its render, as shares of 736 x 800
BUST_SIZE = (736, 800)
HEAD = (0.622, 0.352)                    # the foe's head in the fight capture, as shares of the frame
W, H = 852, 473
SW, SH = 568, 315
PRESS = (54, 176, 33)
SKILL = "Haymaker"                       # Rook's signature: the press names it when it wakes (the director, 2026-11-27, by 01:00: "a
                                         # unique cool art for skills or just the name")                    # the press's centre and radius: 66 points, where TR52 measured the thumb

FACES = {"Mono": "BuilderMono-Regular.otf", "MonoB": "BuilderMono-Bold.otf", "MonoL": "BuilderMono-Light.otf",
         "Ext": "BuilderExtended-SemiBold.otf", "ExtB": "BuilderExtended-Bold.otf",
         "Mont": "Montserrat-Medium.ttf", "MontR": "Montserrat-Regular.ttf", "MontB": "Montserrat-Bold.ttf",
         "Mich": "Michroma-Regular.ttf",
         "Src": "SourceSansPro-Regular.ttf", "SrcL": "SourceSansPro-Light.ttf", "SrcS": "SourceSansPro-Semibold.ttf",
         "SrcB": "SourceSansPro-Bold.ttf", "Serif": "Merriweather-Regular.ttf"}

# the directions' tokens
A = dict(amber="#F0A73C", amber_hi="#FFD08A", amber_lo="#9A5E16", glass="#2A2622", glass2="#3A332C",
         ivory="#EEE7DB", grey="#A89F92", dim="#5E574E", red="#E0574D", red_track="#4A2420", type_red="#D9564A")
B = dict(ice="#9FDDF5", ice_hi="#F4FCFF", ice_lo="#5BB6DC", glass="#E6F1F6", ink="#1F2B38", grey="#4F6272",
         line="#8FA9BA", red="#D94A55", red_track="#C3D1DA", rook="#C8453E")
C = dict(paper="#F1EDE4", ink="#27272B", grey="#5A5A61", tone="#27272B", cobalt="#2D58D6", cobalt_hi="#7F9DF0",
         red="#D6473F", red_track="#D9D3C7")


class Page:
    def __init__(self, w, h, plate=None):
        self.w, self.h, self.parts, self.n = w, h, [], 0
        self.plate = plate.resolve().as_uri() if plate else None
        self.defs = [
            '<filter id="glow" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="3.2"/></filter>',
            '<filter id="soft" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="1.4"/></filter>',
            '<filter id="lift" x="-20%" y="-20%" width="140%" height="160%"><feDropShadow dx="0" dy="1.2" '
            'stdDeviation="1.6" flood-color="#1A1612" flood-opacity="0.35"/></filter>',
            '<filter id="frostword" x="-20%" y="-40%" width="140%" height="180%"><feMorphology in="SourceAlpha" operator="dilate" radius="1.6" result="d"/><feGaussianBlur in="d" stdDeviation="1.6" result="b"/><feFlood flood-color="#EEF6FA" flood-opacity="0.9"/><feComposite in2="b" operator="in" result="o"/><feMerge><feMergeNode in="o"/><feMergeNode in="SourceGraphic"/></feMerge></filter>',
            f'<filter id="paperword" x="-20%" y="-40%" width="140%" height="180%"><feMorphology in="SourceAlpha" operator="dilate" radius="2" result="d"/><feGaussianBlur in="d" stdDeviation="1.2" result="b"/><feFlood flood-color="{C["paper"]}" flood-opacity="0.95"/><feComposite in2="b" operator="in" result="o"/><feMerge><feMergeNode in="o"/><feMergeNode in="SourceGraphic"/></feMerge></filter>',
            '<filter id="shade" x="-20%" y="-40%" width="140%" height="180%"><feDropShadow dx="0" dy="0.8" '
            'stdDeviation="0.7" flood-color="#17130F" flood-opacity="0.75" result="a"/><feDropShadow in="a" dx="0" '
            'dy="0" stdDeviation="3" flood-color="#17130F" flood-opacity="0.35"/></filter>',
            f'<pattern id="tone" width="2.6" height="2.6" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">'
            f'<circle cx="1.3" cy="1.3" r="0.62" fill="{C["tone"]}"/></pattern>',
            f'<pattern id="toneFine" width="1.9" height="1.9" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">'
            f'<circle cx="0.95" cy="0.95" r="0.42" fill="{C["tone"]}"/></pattern>',
            f'<filter id="inkline" x="-10%" y="-10%" width="120%" height="120%"><feMorphology in="SourceAlpha" '
            f'operator="dilate" radius="1.3" result="d"/><feFlood flood-color="{C["ink"]}"/><feComposite in2="d" '
            f'operator="in" result="o"/><feMerge><feMergeNode in="o"/><feMergeNode in="SourceGraphic"/></feMerge></filter>',
        ]
        self.sizes, self.boxes, self.blurs = [], [], set()
        if plate:
            self.add(f'<image href="{self.plate}" x="0" y="0" width="{w}" height="{h}" preserveAspectRatio="none"/>')

    def uid(self, p):
        self.n += 1
        return f"{p}{self.n}"

    def add(self, s):
        self.parts.append(s)

    def svg(self):
        return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}" height="{self.h}" '
                f'viewBox="0 0 {self.w} {self.h}"><defs>{"".join(self.defs)}</defs>{"".join(self.parts)}</svg>')

    def text(self, x, y, s, size, face, fill, anchor="start", spacing=0.0, opacity=1.0, extra=""):
        self.sizes.append((size, s))
        sp = f' letter-spacing="{spacing}"' if spacing else ""
        op = f' opacity="{opacity}"' if opacity != 1 else ""
        self.add(f'<text x="{x:.2f}" y="{y:.2f}" font-family="{face}" font-size="{size}" fill="{fill}" '
                 f'text-anchor="{anchor}"{sp}{op}{extra}>{sf.esc(s)}</text>')

    def lin(self, stops, x2=0, y2=1, opacities=None):
        gid = self.uid("g")
        n = len(stops)
        ops = opacities or [1] * n
        s = "".join(f'<stop offset="{i / (n - 1):.3f}" stop-color="{c}" stop-opacity="{o}"/>'
                    for i, (c, o) in enumerate(zip(stops, ops)))
        self.defs.append(f'<linearGradient id="{gid}" x1="0" y1="0" x2="{x2}" y2="{y2}">{s}</linearGradient>')
        return f"url(#{gid})"

    def rad(self, color, opacity, cx=0.0, cy=0.0, r=1.0):
        """A haze of one colour fading out from (cx, cy), in the shape's own box."""
        gid = self.uid("r")
        self.defs.append(f'<radialGradient id="{gid}" cx="{cx}" cy="{cy}" r="{r}"><stop offset="0" stop-color="{color}" '
                         f'stop-opacity="{opacity}"/><stop offset="0.55" stop-color="{color}" stop-opacity="{opacity * 0.55:.3f}"/>'
                         f'<stop offset="1" stop-color="{color}" stop-opacity="0"/></radialGradient>')
        return f"url(#{gid})"

    def blur(self, r):
        if r not in self.blurs:
            self.blurs.add(r)
            self.defs.append(f'<filter id="blur{r}" x="0" y="0" width="100%" height="100%"><feGaussianBlur '
                             f'stdDeviation="{r}" edgeMode="duplicate"/></filter>')
        return f"url(#blur{r})"

    def frost(self, d, r, fill, opacity, extra="", shift=(0, 0)):
        """The world seen through a pane: the capture blurred inside the shape (shifted, for a refraction), then the
        pane's tint."""
        cid = self.uid("c")
        self.defs.append(f'<clipPath id="{cid}"><path d="{d}"/></clipPath>')
        if self.plate:
            self.add(f'<g clip-path="url(#{cid})"><image href="{self.plate}" x="{shift[0]}" y="{shift[1]}" width="{self.w}" '
                     f'height="{self.h}" preserveAspectRatio="none" filter="{self.blur(r)}"/></g>')
        self.add(f'<path d="{d}" fill="{fill}" fill-opacity="{opacity}"{extra}/>')
        return cid

    def hud(self, x, y, w, h):
        """Counts a permanent piece's box toward the HUD's share of the screen."""
        self.boxes.append((x, y, w, h))


def poly(pts):
    return "M" + " L".join(f"{x:.2f},{y:.2f}" for x, y in pts) + " Z"


def cut(x, y, w, h, tl=0, tr=0, br=0, bl=0, slant=0):
    """A rectangle with cut corners; `slant` leans its right edge (a shard's break)."""
    return poly([(x + tl, y), (x + w - tr, y), (x + w, y + tr), (x + w - slant, y + h - br), (x + w - slant - br, y + h),
                 (x + bl, y + h), (x, y + h - bl), (x, y + tl)])


def rect(x, y, w, h):
    return poly([(x, y), (x + w, y), (x + w, y + h), (x, y + h)])


def bust(P, x, y, size, ink=False, fade=0.72, opacity=1.0, flip=False):
    """Rook's portrait render (stand-in key art), its visible bust `size` tall with its top left at (x, y), no box;
    its foot fades into the scene."""
    bx0, by0, bx1, by1 = BUST_BOX
    iw, ih = BUST_SIZE
    k = size / ((by1 - by0) * ih)
    dw, dh = iw * k, ih * k
    ix, iy = x - bx0 * dw, y - by0 * dh
    mid = P.uid("m")
    gid = P.uid("g")
    P.defs.append(f'<linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff"/>'
                  f'<stop offset="{fade}" stop-color="#fff"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>'
                  f'<mask id="{mid}" maskUnits="userSpaceOnUse" x="{x - size:.1f}" y="{y - size:.1f}" width="{3 * size:.1f}" '
                  f'height="{2 * size + 1:.1f}"><rect x="{x - size:.1f}" y="{y:.1f}" width="{3 * size:.1f}" height="{size:.1f}" '
                  f'fill="url(#{gid})"/><rect x="{x - size:.1f}" y="{y - size:.1f}" width="{3 * size:.1f}" height="{size:.1f}" fill="#fff"/></mask>')
    tf = f' transform="translate({2 * x + (bx1 - bx0) * dw:.2f},0) scale(-1,1)"' if flip else ""
    filt = ' filter="url(#inkline)"' if ink else ""
    P.add(f'<g mask="url(#{mid})" opacity="{opacity}"><g{tf}><image href="{BUST.as_uri()}" x="{ix:.2f}" y="{iy:.2f}" '
          f'width="{dw:.2f}" height="{dh:.2f}"{filt}/></g></g>')


def brush_path(x0, y0, x1, y1, w, taper=(0.15, 0.85), wobble=0.0, steps=24, floor=0.0):
    """A tapered band along a line, its two edges wobbling apart like a brush's."""
    dx, dy = x1 - x0, y1 - y0
    length = math.hypot(dx, dy)
    nx, ny = -dy / length, dx / length
    left, right = [], []
    for i in range(steps + 1):
        t = i / steps
        a, b = taper
        k = min(1.0, t / a if t < a else (1 - t) / (1 - b) if t > b else 1.0) ** 0.7
        if t > b:
            k = floor + (1 - floor) * k
        hw = w / 2 * k
        px, py = x0 + dx * t, y0 + dy * t
        wl = 1 + wobble * math.sin(t * 37.0 + 1.3) * math.sin(t * 11.0)
        wr = 1 + wobble * math.sin(t * 29.0 + 0.4) * math.sin(t * 13.0 + 2.0)
        left.append((px + nx * hw * wl, py + ny * hw * wl))
        right.append((px - nx * hw * wr, py - ny * hw * wr))
    return poly(left + right[::-1])


def brush_line(P, x0, y0, x1, y1, w, fill, opacity=1.0, taper=(0.15, 0.85)):
    """An ink stroke with brush ends: a tapered band along the line."""
    P.add(f'<path d="{brush_path(x0, y0, x1, y1, w, taper)}" fill="{fill}" fill-opacity="{opacity}"/>')


def brush_arc(P, cx, cy, r, a0, a1, w, fill, opacity=1.0, taper=(0.12, 0.88)):
    """A brushed arc, from angle a0 to a1 (degrees clockwise from the top), tapered at both ends."""
    outer, inner = [], []
    steps = max(8, int(abs(a1 - a0) / 4))
    for i in range(steps + 1):
        t = i / steps
        a, b = taper
        k = min(1.0, t / a if t < a else (1 - t) / (1 - b) if t > b else 1.0) ** 0.6
        ang = math.radians(a0 + (a1 - a0) * t)
        hw = w / 2 * max(k, 0.04)
        sx, sy = math.sin(ang), -math.cos(ang)
        outer.append((cx + (r + hw) * sx, cy + (r + hw) * sy))
        inner.append((cx + (r - hw) * sx, cy + (r - hw) * sy))
    P.add(f'<path d="{poly(outer + inner[::-1])}" fill="{fill}" fill-opacity="{opacity}"/>')


def head(w, h):
    return HEAD[0] * w, HEAD[1] * h


# ---- A, Console -------------------------------------------------------------------------------------------------------
SHADE = ' filter="url(#shade)"'
FOE_BOX = (0.585, 0.31, 0.672, 0.50)     # the foe's body in the fight capture, as shares of the frame


def a_ticks(P, x, y, w, n, major, color, dim, lit=1.0, h1=2.0, h2=4.0):
    for i in range(n + 1):
        tx = x + w * i / n
        big = i % major == 0
        c = color if i / n <= lit + 1e-6 else dim
        P.add(f'<rect x="{tx - 0.4:.2f}" y="{y:.2f}" width="0.8" height="{h2 if big else h1}" fill="{c}" '
              f'fill-opacity="{0.95 if big else 0.7}"{SHADE}/>')


def a_bar(P, x, y, w, h, share, fill, track):
    P.add(f'<rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="{h}" fill="{track}" fill-opacity="0.85"/>')
    P.add(f'<rect x="{x:.2f}" y="{y:.2f}" width="{w * share:.2f}" height="{h}" fill="{fill}"/>')
    P.add(f'<rect x="{x + w * share - 0.6:.2f}" y="{y - 1.5:.2f}" width="1.2" height="{h + 3}" fill="{A["ivory"]}"/>')


def a_brackets(P, x, y, w, h, arm, color, width=1.2, opacity=1.0):
    """The console's mark: what it reads, it brackets."""
    d = (f"M {x},{y + arm} L {x},{y} L {x + arm},{y} M {x + w - arm},{y} L {x + w},{y} L {x + w},{y + arm} "
         f"M {x + w},{y + h - arm} L {x + w},{y + h} L {x + w - arm},{y + h} M {x + arm},{y + h} L {x},{y + h} L {x},{y + h - arm}")
    P.add(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{width}" stroke-opacity="{opacity}"/>')


def a_haze(P, x, y, w, h, opacity, cx=0.0, cy=0.0, r=1.0):
    """The console's glass where it holds a reading: warm graphite, fading out, never a box."""
    P.add(f'<rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="{h:.2f}" fill="{P.rad(A["glass"], opacity, cx, cy, r)}"/>')


def a_pane(P, d, opacity=0.72):
    """Warm translucent graphite: the world through it, darkened and warmed, a 1-point rim."""
    P.frost(d, 5, A["glass"], opacity)
    P.add(f'<path d="{d}" fill="none" stroke="{A["ivory"]}" stroke-opacity="0.16" stroke-width="1"/>')


def a_node(P, x, y, lit=False):
    c = A["amber_hi"] if lit else A["amber"]
    P.add(f'<rect x="{x - 1.6:.2f}" y="{y - 1.6:.2f}" width="3.2" height="3.2" fill="{c}"/>')


def a_press(P, charge):
    """The press: a dial of ticks round the signature. Quiet while it fills (its share in numbers), awake when full."""
    cx, cy, r = PRESS
    full = charge >= 1
    if full:
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{r + 6}" fill="{A["amber"]}" fill-opacity="0.38" filter="url(#glow)"/>')
    a_pane(P, f"M {cx - r},{cy} a {r},{r} 0 1,0 {2 * r},0 a {r},{r} 0 1,0 {-2 * r},0 Z", opacity=0.6 if full else 0.7)
    cid = P.uid("c")
    P.defs.append(f'<clipPath id="{cid}"><circle cx="{cx}" cy="{cy}" r="{r - 7}"/></clipPath>')
    P.add(f'<g clip-path="url(#{cid})">')
    bust(P, cx - 26, cy - 22, 52, fade=0.8, opacity=1.0 if full else 0.55)
    P.add("</g>")
    for i in range(48):
        a = 2 * math.pi * i / 48
        big = i % 6 == 0
        on = i / 48 < charge
        r0, r1 = r - (5.5 if big else 3.5), r - 1
        P.add(f'<line x1="{cx + r0 * math.sin(a):.2f}" y1="{cy - r0 * math.cos(a):.2f}" x2="{cx + r1 * math.sin(a):.2f}" '
              f'y2="{cy - r1 * math.cos(a):.2f}" stroke="{A["amber"] if on else A["dim"]}" stroke-width="{1.3 if big else 0.9}"/>')
    P.add(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{A["amber_hi"] if full else A["grey"]}" '
          f'stroke-opacity="{1 if full else 0.5}" stroke-width="1.2"/>')
    if full:
        P.text(cx, cy + r + 17, SKILL.upper(), 14, "MonoB", A["amber_hi"], anchor="middle", spacing=1.2, extra=SHADE)
    else:
        P.text(cx, cy + r + 17, f"{round(charge * 100)}%", 14, "Mono", A["ivory"], anchor="middle", spacing=0.6, extra=SHADE)


def a_fight(P, charge=1.0):
    w, h = P.w, P.h
    cx, cy, r = PRESS
    a_haze(P, 0, 0, 330, 140, 0.82, cx=0.2, cy=0.3, r=0.7)
    bx, bw = 66, 150
    ex, ey = bx + bw + 14, 14
    # the live line, along the frame: from the eye along the top past the lead, down the left edge to the press
    line = f"M {ex + 13},{ey - 8} L 6,{ey - 8} L 6,{cy - r - 10} L {cx - 10},{cy - r - 10}"
    P.add(f'<path d="{line}" fill="none" stroke="{A["amber"]}" stroke-opacity="0.6" stroke-width="1"{SHADE}/>')
    for x, y in ((ex + 13, ey - 8), (bx, ey - 8), (cx - 10, cy - r - 10)):
        a_node(P, x, y)
    py = ey - 8 + 0.55 * (cy - r - 10 - ey + 8)       # a pulse on its way down to the press: it gained charge
    P.add(f'<rect x="5" y="{py - 22:.2f}" width="2" height="22" fill="{P.lin((A["amber"], A["amber_hi"]), x2=0, y2=1, opacities=(0, 1))}"/>'
          f'<circle cx="6" cy="{py:.2f}" r="4" fill="{A["amber_hi"]}" fill-opacity="0.6" filter="url(#soft)"/>'
          f'<circle cx="6" cy="{py:.2f}" r="1.6" fill="{A["amber_hi"]}"/>')
    # the lead: its bust cut out, no box; its readings on the console's glass
    bust(P, 8, 8, 56)
    P.hud(8, 8, bx + bw - 8, 58)
    P.text(bx, 26, "ROOK", 15, "MonoB", A["ivory"], spacing=1.6, extra=SHADE)
    P.add(f'<rect x="{bx + 51:.1f}" y="17.5" width="5.5" height="5.5" fill="{A["type_red"]}" '
          f'transform="rotate(45 {bx + 53.75:.2f} 20.25)"/>')
    P.text(bx + bw, 24, "LV 26", 14, "Mono", A["amber"], anchor="end", spacing=0.5, extra=SHADE)
    P.add(f'<rect x="{bx + bw - 44:.1f}" y="27" width="44" height="1.2" fill="{A["dim"]}"/>'
          f'<rect x="{bx + bw - 44:.1f}" y="27" width="{44 * 0.38:.2f}" height="1.2" fill="{A["amber"]}"/>')   # XP, under the level
    a_bar(P, bx, 32, bw, 3, 3682 / 3732, A["red"], A["red_track"])
    a_ticks(P, bx, 37, bw, 20, 5, A["grey"], A["dim"])
    P.text(bx, 60, "3,682", 18, "Mono", A["ivory"], extra=SHADE)
    P.text(bx + 58, 60, "/ 3,732", 14, "Mono", A["grey"], extra=SHADE)
    # the eye, bracketed
    a_brackets(P, ex, ey, 26, 26, 5, A["ivory"], opacity=0.8)
    P.hud(ex, ey, 26, 26)
    P.add(f'<path d="M {ex + 5},{ey + 13} Q {ex + 13},{ey + 5.5} {ex + 21},{ey + 13} Q {ex + 13},{ey + 20.5} {ex + 5},{ey + 13} Z" '
          f'fill="none" stroke="{A["ivory"]}" stroke-width="1.3"{SHADE}/><circle cx="{ex + 13}" cy="{ey + 13}" r="2.5" fill="{A["amber"]}"/>')
    # the foe, locked in the world: the console brackets what it reads and prints the reading over the lock; the level
    # in the difficulty's colour (an even fight: ivory)
    x0, y0, x1, y1 = FOE_BOX
    lx, ly, lw, lh = x0 * w, y0 * h, (x1 - x0) * w, (y1 - y0) * h
    a_brackets(P, lx, ly, lw, lh, 7, A["ivory"], width=1.2, opacity=0.75)
    fw = 150
    fx = lx + lw / 2 - fw / 2
    P.hud(fx, ly - 34, fw, 28)
    a_haze(P, fx - 50, ly - 58, fw + 100, 62, 0.5, cx=0.5, cy=0.5, r=0.5)
    P.text(fx, ly - 20, "BRAWLER", 14, "MonoB", A["ivory"], spacing=1.2, extra=SHADE)
    P.add(f'<rect x="{fx + 77:.1f}" y="{ly - 29.5:.1f}" width="5" height="5" fill="{A["type_red"]}" '
          f'transform="rotate(45 {fx + 79.5:.2f} {ly - 27:.2f})"/>')
    P.text(fx + fw, ly - 20, "LV 26", 14, "Mono", A["ivory"], anchor="end", extra=SHADE)
    a_bar(P, fx, ly - 14, fw, 3, 2964 / 4290, A["red"], A["red_track"])
    P.add(f'<rect x="{fx:.2f}" y="{ly - 8.5:.2f}" width="{fw:.2f}" height="1.2" fill="{A["dim"]}"/>'
          f'<rect x="{fx:.2f}" y="{ly - 8.5:.2f}" width="{fw * 0.64:.2f}" height="1.2" fill="{A["ivory"]}"/>')   # poise
    # the press and Auto
    a_press(P, charge)
    ax, ay = cx + r + 14, cy - 12
    a_brackets(P, ax, ay, 66, 24, 5, A["ivory"], opacity=0.8)
    P.hud(ax, ay, 66, 24)
    P.add(f'<circle cx="{ax + 12}" cy="{ay + 12}" r="5.5" fill="{A["amber"]}" fill-opacity="0.45" filter="url(#soft)"/>'
          f'<circle cx="{ax + 12}" cy="{ay + 12}" r="2.8" fill="{A["amber_hi"]}"/>')
    P.text(ax + 22, ay + 17, "AUTO", 14, "MonoB", A["ivory"], spacing=0.8, extra=SHADE)


def a_home(P):
    """The console's main page: a column of the yard's readings and its pages, the lead large beside it."""
    w, h = P.w, P.h
    cw = 330
    P.add(f'<rect x="0" y="0" width="{w}" height="{h}" fill="{P.lin((A["glass"], A["glass"]), x2=1, y2=0, opacities=(0.0, 0.45))}"/>')
    bust(P, 452, 92, 320, fade=0.88)
    P.text(w - 30, h - 50, "ROOK", 34, "ExtB", A["ivory"], anchor="end", spacing=3, extra=SHADE)
    P.text(w - 30, h - 28, "LEAD  ·  LV 26  ·  WARRIOR  ·  FIRE", 14, "Mono", A["amber"], anchor="end", spacing=0.6, extra=SHADE)
    P.text(w - 30, 30, "STAND-IN ART: ROOK'S PORTRAIT RENDER", 14, "Mono", A["ivory"], anchor="end", opacity=0.7, extra=SHADE)
    col = rect(0, 0, cw, h)
    a_pane(P, col, opacity=0.8)
    P.add(f'<rect x="{cw - 1}" y="0" width="1" height="{h}" fill="{A["amber"]}" fill-opacity="0.7"/>')
    x = 26
    P.text(x, 36, "HOME", 20, "ExtB", A["ivory"], spacing=2.5)
    P.text(cw - 22, 35, "CLOSE", 14, "Mono", A["grey"], anchor="end", spacing=1.2)
    # the yard's readings
    y = 76
    P.text(x, y, "POWER", 14, "Mono", A["grey"], spacing=1.4)
    P.text(x + 120, y, "BATTERY", 14, "Mono", A["grey"], spacing=1.4)
    P.text(x, y + 30, "10", 30, "MonoB", A["ivory"])
    P.text(x + 40, y + 30, "/ 91 kW", 14, "Mono", A["grey"])
    P.text(x + 120, y + 30, "FULL", 30, "MonoB", A["ivory"])
    a_bar(P, x, y + 40, 100, 3, 10 / 91, A["amber"], A["dim"])
    a_ticks(P, x, y + 45, 100, 10, 5, A["grey"], A["dim"])
    a_bar(P, x + 120, y + 40, 100, 3, 1.0, A["amber"], A["dim"])
    a_ticks(P, x + 120, y + 45, 100, 10, 5, A["grey"], A["dim"])
    P.text(x, y + 82, "CREDITS", 14, "Mono", A["grey"], spacing=1.4)
    P.text(x + 100, y + 82, "72,546", 18, "MonoB", A["ivory"])
    # the live line runs down the pages
    top = 196
    P.add(f'<path d="M {x - 12},{top - 10} L {x - 12},{top + 4 * 56 - 20}" stroke="{A["amber"]}" stroke-opacity="0.6" stroke-width="1"/>')
    pages = [("01", "VOIDKIN", "4 OWNED"), ("02", "EQUIPMENT", "REINFORCE · JEWELS"), ("03", "TODAY", "1 OF 3 DONE"),
             ("04", "SETTINGS", "SOUND · EFFECTS")]
    for i, (k, name, read) in enumerate(pages):
        y = top + i * 56
        on = i == 0
        if on:
            P.add(f'<rect x="{x - 6}" y="{y - 4}" width="{cw - x - 12}" height="48" fill="{A["amber"]}" fill-opacity="0.12"/>'
                  f'<rect x="{x - 6}" y="{y - 4}" width="2" height="48" fill="{A["amber"]}"/>')
            a_brackets(P, x - 6, y - 4, cw - x - 12, 48, 6, A["amber"])
        a_node(P, x - 12, y + 16, lit=on)
        P.text(x + 8, y + 21, k, 14, "Mono", A["amber"] if on else A["grey"])
        P.text(x + 38, y + 22, name, 18, "ExtB", A["ivory"], spacing=1.4)
        P.text(x + 38, y + 39, read, 14, "Mono", A["grey"], spacing=0.4)


def a_tokens(P):
    tokens(P, "A, Console: the player's own yard system", A["glass"], A["ivory"],
           [("Amber", A["amber"]), ("Amber lit", A["amber_hi"]), ("Graphite", A["glass"]), ("Graphite 2", A["glass2"]),
            ("Ivory", A["ivory"]), ("Grey", A["grey"]), ("Health", A["red"])],
           [("Builder Mono Bold 15", "MonoB", 15, "ROOK   LV 26   AUTO"), ("Builder Mono 14 and 18", "Mono", 18, "3,682 / 3,732 · 10 / 91 kW"),
            ("Builder Extended Bold 18 to 34, titles", "ExtB", 22, "VOIDKIN")],
           "Lines: brackets and the live line 1 to 1.2 pt; ticks 0.8 pt; bars 3 pt; no rims, no boxes in a fight.",
           "Motion: a pulse runs along the live line to what changed, then the reading settles; the dial's ticks fill.",
           a_motif)


def a_motif(P, x, y):
    a_brackets(P, x, y, 220, 50, 7, A["amber"])
    a_bar(P, x + 12, y + 18, 196, 3, 0.62, A["red"], A["red_track"])
    a_ticks(P, x + 12, y + 23, 196, 20, 5, A["grey"], A["dim"])
    P.add(f'<path d="M {x},{y + 66} L {x + 220},{y + 66}" stroke="{A["amber"]}" stroke-opacity="0.6"/>')
    a_node(P, x, y + 66)
    a_node(P, x + 220, y + 66)
    P.add(f'<circle cx="{x + 140}" cy="{y + 66}" r="1.6" fill="{A["amber_hi"]}"/>')


# ---- B, Shard ---------------------------------------------------------------------------------------------------------
def b_pane(P, d, edge_pts=None, opacity=0.62):
    """Pale frosted glass: the world through it, blurred and lightened, one bright edge where the light catches."""
    P.add(f'<path d="{d}" fill="#3A5568" fill-opacity="0.16" transform="translate(0,1.5)" filter="url(#soft)"/>')
    P.frost(d, 7, B["glass"], opacity, shift=(3, 2))
    P.add(f'<path d="{d}" fill="{P.lin(("#FFFFFF", "#FFFFFF"), x2=1, y2=1, opacities=(0.32, 0.0))}"/>')
    P.add(f'<path d="{d}" fill="none" stroke="{B["line"]}" stroke-opacity="0.7" stroke-width="0.8"/>')
    if edge_pts:
        P.add(f'<polyline points="{" ".join(f"{x:.2f},{y:.2f}" for x, y in edge_pts)}" fill="none" stroke="{B["ice_hi"]}" '
              f'stroke-width="1.6" stroke-linecap="round"/>')


def b_bar(P, x, y, w, h, share, fill, track):
    s = h * 0.9
    P.add(f'<path d="{poly([(x + s, y), (x + w, y), (x + w - s, y + h), (x, y + h)])}" fill="{track}"/>')
    fw = max(w * share, 2 * s)
    P.add(f'<path d="{poly([(x + s, y), (x + fw, y), (x + fw - s, y + h), (x, y + h)])}" fill="{fill}"/>')


def b_shard(cx, cy, r, turn=0.0):
    """A shard's cut: an irregular hexagon at break angles."""
    pts = []
    for i, (ang, k) in enumerate([(-8, 1.0), (52, 0.9), (118, 1.04), (172, 0.94), (238, 1.02), (300, 0.92)]):
        a = math.radians(ang + turn)
        pts.append((cx + r * k * math.sin(a), cy - r * k * math.cos(a)))
    return pts


def b_along(pts, share):
    """The first `share` of a polyline's length."""
    seg = [math.dist(a, b) for a, b in zip(pts, pts[1:])]
    left = share * sum(seg)
    out = [pts[0]]
    for (a, b), d in zip(zip(pts, pts[1:]), seg):
        if left >= d:
            out.append(b)
            left -= d
        else:
            k = left / d
            out.append((a[0] + (b[0] - a[0]) * k, a[1] + (b[1] - a[1]) * k))
            break
    return out


def b_fight(P, charge=1.0):
    w, h = P.w, P.h
    lx, ly, lw, lh = 54, 10, 184, 56
    pts = [(lx + 10, ly), (lx + lw, ly), (lx + lw - 12, ly + lh), (lx, ly + lh), (lx, ly + 10)]
    b_pane(P, poly(pts), edge_pts=[pts[4], pts[0], pts[1]])
    P.hud(8, 6, lx + lw - 8, lh + 6)
    # the portrait: Rook's own hue only in his facet, the bust over it, no box
    fct = [(14, 16), (50, 8), (60, 50), (20, 62)]
    P.add(f'<path d="{poly(fct)}" fill="{B["rook"]}" fill-opacity="0.85"/>'
          f'<polyline points="14,16 50,8" stroke="#FFD9D2" stroke-width="1.2" fill="none"/>')
    bust(P, 8, 6, 58)
    tx = 72
    P.text(tx, ly + 19, "Rook", 16, "MontB", B["ink"], spacing=0.4)
    P.text(lx + lw - 20, ly + 19, "Lv 26", 14, "Mont", B["grey"], anchor="end")
    b_bar(P, tx, ly + 26, lw - (tx - lx) - 18, 4.5, 3682 / 3732, B["red"], B["red_track"])
    b_bar(P, tx, ly + 33, lw - (tx - lx) - 21, 2, 1.0, B["ice_lo"], B["red_track"])
    P.text(tx, ly + 50, "3,682 / 3,732", 14, "Mont", B["ink"])
    # the eye
    ex, ey = lx + lw + 4, 14
    ept = [(ex + 6, ey), (ex + 28, ey), (ex + 22, ey + 26), (ex, ey + 26)]
    b_pane(P, poly(ept), edge_pts=[ept[3], ept[0], ept[1]])
    P.hud(ex, ey, 28, 26)
    P.add(f'<path d="M {ex + 6},{ey + 13} Q {ex + 14},{ey + 5} {ex + 22},{ey + 13} Q {ex + 14},{ey + 21} {ex + 6},{ey + 13} Z" '
          f'fill="none" stroke="{B["ink"]}" stroke-width="1.2"/><circle cx="{ex + 14}" cy="{ey + 13}" r="2.4" fill="{B["ink"]}"/>')
    # the foe: a small facet over its head in the world
    hx, hy = head(w, h)
    tw, th = 140, 34
    tx0, ty0 = hx - tw / 2, hy - 0.06 * h - th - 8
    tp = [(tx0 + 8, ty0), (tx0 + tw, ty0), (tx0 + tw - 8, ty0 + th), (hx + 5, ty0 + th), (hx, ty0 + th + 6),
          (hx - 5, ty0 + th), (tx0, ty0 + th)]
    b_pane(P, poly(tp), edge_pts=[tp[6], tp[0], tp[1]])
    P.hud(tx0, ty0, tw, th)
    P.text(tx0 + 12, ty0 + 17, "Brawler", 14, "MontB", B["ink"])
    P.text(tx0 + tw - 14, ty0 + 17, "Lv 26", 14, "Mont", B["grey"], anchor="end")
    b_bar(P, tx0 + 10, ty0 + 23, tw - 26, 4, 2964 / 4290, B["red"], B["red_track"])
    # the press: a shard, lit along its edges as it charges, glinting when full
    cx, cy, r = PRESS
    sp = b_shard(cx, cy, r + 2)
    full = charge >= 1
    if full:
        P.add(f'<path d="{poly(sp)}" fill="{B["ice"]}" fill-opacity="0.5" filter="url(#glow)"/>')
    b_pane(P, poly(sp), opacity=0.55)
    inner = b_shard(cx, cy, r - 7, turn=14)
    P.add(f'<path d="{poly(inner)}" fill="{B["rook"]}" fill-opacity="{0.82 if full else 0.4}"/>')
    cid = P.uid("c")
    P.defs.append(f'<clipPath id="{cid}"><path d="{poly(inner)}"/></clipPath>')
    P.add(f'<g clip-path="url(#{cid})">')
    bust(P, cx - 25, cy - 22, 50, fade=0.85, opacity=1.0 if full else 0.6)
    P.add("</g>")
    ring = sp + sp[:1]
    P.add(f'<polyline points="{" ".join(f"{x:.2f},{y:.2f}" for x, y in ring)}" fill="none" stroke="{B["line"]}" '
          f'stroke-width="1" stroke-linejoin="round"/>')
    lit = b_along(ring, charge)               # the edge lights round the shard as it fills
    P.add(f'<polyline points="{" ".join(f"{x:.2f},{y:.2f}" for x, y in lit)}" fill="none" stroke="{B["ice_hi"] if full else B["ice_lo"]}" '
          f'stroke-width="1.8" stroke-linejoin="round" stroke-linecap="round"/>')
    if full:
        gx, gy = sp[5]
        P.add(f'<path d="M {gx - 7},{gy} L {gx + 7},{gy} M {gx},{gy - 7} L {gx},{gy + 7}" stroke="#FFFFFF" stroke-width="1.2"/>'
              f'<circle cx="{gx}" cy="{gy}" r="4" fill="#FFFFFF" fill-opacity="0.8" filter="url(#soft)"/>')
    P.text(cx, cy + r + 19, SKILL if full else f"{round(charge * 100)}%", 14, "MontB", B["ink"] if full else B["grey"],
           anchor="middle", extra=' filter="url(#frostword)"')
    # Auto
    ax, ay, aw, ah = cx + r + 12, cy - 12, 64, 24
    apt = [(ax + 6, ay), (ax + aw, ay), (ax + aw - 6, ay + ah), (ax, ay + ah)]
    b_pane(P, poly(apt), edge_pts=[apt[3], apt[0], apt[1]])
    P.hud(ax, ay, aw, ah)
    P.add(f'<path d="{poly([(ax + 11, ay + 7), (ax + 16, ay + 12), (ax + 11, ay + 17), (ax + 6, ay + 12)])}" fill="{B["ice_lo"]}"/>')
    P.text(ax + 22, ay + 17, "Auto", 14, "MontB", B["ink"])


def b_home(P):
    w, h = P.w, P.h
    # the lead in a large facet window, its own hue inside, and the four pages as facets beside it
    win = [(36, 36), (304, 22), (338, 318), (294, 448), (26, 444), (22, 190)]
    b_pane(P, poly(win), edge_pts=[win[5], win[0], win[1]], opacity=0.7)
    inner = [(54, 54), (292, 42), (318, 296), (52, 344), (40, 190)]
    P.add(f'<path d="{poly(inner)}" fill="{P.lin((B["rook"], "#7A2622"), x2=0.4, y2=1)}" fill-opacity="0.9"/>')
    cid = P.uid("c")
    P.defs.append(f'<clipPath id="{cid}"><path d="{poly(inner)}"/></clipPath>')
    P.add(f'<g clip-path="url(#{cid})">')
    bust(P, 60, 92, 300, fade=0.9)
    P.add("</g>")
    P.add(f'<polyline points="40,190 54,54 292,42" fill="none" stroke="#FFD9D2" stroke-width="1.4"/>')
    P.text(50, 392, "ROOK", 28, "Mich", B["ink"], spacing=3)
    P.text(52, 416, "Lead · Lv 26 · Warrior · Fire", 14, "Mont", B["grey"])
    P.text(52, 434, "Stand-in art", 14, "Mont", B["grey"], opacity=0.8)
    pages = [("VOIDKIN", "4 owned"), ("EQUIPMENT", "Reinforce · Jewels · War Emblems"), ("TODAY", "1 of 3 done"),
             ("SETTINGS", "Sound · Effects")]
    x0 = 384
    for i, (name, sub) in enumerate(pages):
        on = i == 0
        y = 64 + i * 88
        pw = 330 - i * 10
        pts = [(x0 + 10 + i * 8, y), (x0 + pw, y + 4), (x0 + pw - 9, y + 60), (x0 + i * 8, y + 62)]
        b_pane(P, poly(pts), edge_pts=[pts[3], pts[0], pts[1]] if on else None, opacity=0.8 if on else 0.5)
        if on:
            P.add(f'<polyline points="{pts[3][0]:.1f},{pts[3][1]:.1f} {pts[0][0]:.1f},{pts[0][1]:.1f}" stroke="{B["ice_lo"]}" stroke-width="3"/>')
        P.text(x0 + 26 + i * 8, y + 30, name, 18, "Mich", B["ink"], spacing=2)
        P.text(x0 + 26 + i * 8, y + 50, sub, 14, "Mont", B["grey"] if on else B["ink"], opacity=1 if on else 0.75)
    P.text(w - 28, 34, "Close", 14, "MontB", B["ink"], anchor="end")


def b_tokens(P):
    tokens(P, "B, Shard: the UI seen in the shard glass", "#DCE9EF", B["ink"],
           [("Ice", B["ice"]), ("Ice lit", B["ice_hi"]), ("Ice deep", B["ice_lo"]), ("Glass", B["glass"]),
            ("Ink", B["ink"]), ("Grey", B["grey"]), ("Health", B["red"]), ("A Voidkin's own", B["rook"])],
           [("Montserrat Bold 16", "MontB", 16, "Rook   Lv 26"), ("Montserrat Medium 14", "Mont", 14, "3,682 / 3,732 · Auto"),
            ("Michroma 22", "Mich", 22, "VOIDKIN")],
           "Lines: the lit edge 1.6 pt ice white on two sides, the cut 0.8 pt blue-grey at 70%; no rounded corners.",
           "Motion: a glint crosses a facet once when it changes; a pane settles in with a short slide along its cut.",
           b_motif)


def b_motif(P, x, y):
    pts = [(x + 10, y), (x + 220, y + 4), (x + 206, y + 46), (x, y + 50)]
    b_pane(P, poly(pts), edge_pts=[pts[3], pts[0], pts[1]], opacity=0.8)
    b_bar(P, x + 16, y + 20, 180, 5, 0.7, B["red"], B["red_track"])


# ---- C, Episode -------------------------------------------------------------------------------------------------------
def c_slip(P, d, tone=None):
    """A paper slip over the scene, a fine screentone on one end."""
    P.add(f'<path d="{d}" fill="{C["ink"]}" fill-opacity="0.18" transform="translate(1.5,2)"/>')
    P.add(f'<path d="{d}" fill="{C["paper"]}" fill-opacity="0.95"/>')
    if tone:
        cid = P.uid("c")
        P.defs.append(f'<clipPath id="{cid}"><path d="{d}"/></clipPath>')
        x, y, w, h = tone
        mid = P.uid("m")
        gid = P.uid("g")
        P.defs.append(f'<linearGradient id="{gid}" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" '
                      f'stop-opacity="0"/><stop offset="1" stop-color="#fff" stop-opacity="0.55"/></linearGradient>'
                      f'<mask id="{mid}" maskUnits="userSpaceOnUse" x="{x}" y="{y}" width="{w}" height="{h}">'
                      f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="url(#{gid})"/></mask>')
        P.add(f'<g clip-path="url(#{cid})"><rect x="{x}" y="{y}" width="{w}" height="{h}" fill="url(#toneFine)" '
              f'mask="url(#{mid})"/></g>')


def c_band(P, x, y, w, h, tone=False):
    """A band of paper laid with one brush stroke over the scene: a dry, streaked right end; the screentone under it."""
    end = x + w + 14
    d = brush_path(x - 10, y + h / 2, end, y + h / 2 - 1, h, taper=(0.025, 0.86), wobble=0.04, steps=60, floor=0.78)
    c_slip(P, d, tone=(x + w - 70, y - 4, 110, h + 8) if tone else None)
    # the bristles run dry past the stroke's end: streaks of uneven length with gaps between
    for dy, ln, share in ((-0.33, 22, 0.13), (-0.17, 38, 0.1), (-0.02, 14, 0.12), (0.13, 30, 0.09), (0.28, 18, 0.12)):
        sw = share * h
        brush_line(P, end - 8, y + h / 2 + dy * h, end + ln, y + h / 2 + dy * h - 0.8, sw, C["paper"], opacity=0.92,
                   taper=(0.01, 0.25))
    P.hud(x - 10, y, w + 40, h)


def c_bar(P, x, y, w, h, share, fill):
    P.add(f'<rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="{h}" fill="url(#toneFine)" fill-opacity="0.35"/>')
    P.add(f'<rect x="{x:.2f}" y="{y:.2f}" width="{w * share:.2f}" height="{h}" fill="{fill}"/>')
    P.add(f'<rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="{h}" fill="none" stroke="{C["ink"]}" stroke-width="1"/>')


def c_fight(P, charge=1.0):
    w, h = P.w, P.h
    lx, ly, lw, lh = 56, 12, 170, 54
    c_band(P, lx, ly, lw, lh, tone=True)
    brush_line(P, lx - 6, ly + lh + 1, lx + lw + 20, ly + lh - 1, 2.4, C["ink"], taper=(0.04, 0.7))
    bust(P, 6, 6, 58, ink=True)
    tx = 72
    P.text(tx, ly + 18, "ROOK", 14, "SrcB", C["ink"], spacing=3.2)
    P.text(lx + lw - 6, ly + 18, "LV 26", 14, "Src", C["grey"], anchor="end", spacing=1.2)
    c_bar(P, tx, ly + 25, lw - (tx - lx) - 6, 5, 3682 / 3732, C["red"])
    brush_line(P, tx, ly + 35, tx + (lw - (tx - lx) - 6) * charge, ly + 35, 2.4, C["cobalt"])       # the charge
    P.text(tx, ly + 50, "3,682 / 3,732", 14, "SrcS", C["ink"], spacing=0.6)
    # the eye
    ex, ey = lx + lw + 56, 16
    brush_arc(P, ex + 13, ey + 13, 12, -30, 300, 2.2, C["ink"])
    P.add(f'<circle cx="{ex + 13}" cy="{ey + 13}" r="11" fill="{C["paper"]}" fill-opacity="0.92"/>'
          f'<path d="M {ex + 6},{ey + 13} Q {ex + 13},{ey + 6.5} {ex + 20},{ey + 13} Q {ex + 13},{ey + 19.5} {ex + 6},{ey + 13} Z" '
          f'fill="none" stroke="{C["ink"]}" stroke-width="1.2"/><circle cx="{ex + 13}" cy="{ey + 13}" r="2.3" fill="{C["ink"]}"/>')
    P.hud(ex, ey, 26, 26)
    # the foe: a caption at its shoulder, like a show naming who's on screen, on a brush leader
    hx, hy = head(w, h)
    cx0, cy0 = min(hx + 0.09 * w, w - 132 - 62), hy - 0.11 * h      # the caption and its dry end stay on screen
    brush_line(P, hx + 8, hy - 6, cx0 - 2, cy0 + 18, 1.8, C["ink"], taper=(0.4, 0.95))
    cw, ch = 132, 36
    c_band(P, cx0, cy0, cw, ch)
    P.text(cx0 + 8, cy0 + 16, "BRAWLER", 14, "SrcB", C["ink"], spacing=2.6)
    P.text(cx0 + cw - 8, cy0 + 16, "LV 26", 14, "Src", C["grey"], anchor="end", spacing=1)
    c_bar(P, cx0 + 8, cy0 + 23, cw - 16, 5, 2964 / 4290, C["red"])
    # the press: a brushed ring on paper, its tone, the lead inside, the charge a cobalt stroke round it
    cx, cy, r = PRESS
    P.add(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{C["paper"]}" fill-opacity="0.96"/>')
    cid = P.uid("c")
    P.defs.append(f'<clipPath id="{cid}"><circle cx="{cx}" cy="{cy}" r="{r - 3}"/></clipPath>')
    P.add(f'<g clip-path="url(#{cid})"><rect x="{cx - r}" y="{cy}" width="{2 * r}" height="{r}" fill="url(#tone)" '
          f'fill-opacity="0.5"/>')
    bust(P, cx - 25, cy - 23, 50, ink=True, fade=0.86)
    P.add("</g>")
    brush_arc(P, cx, cy, r, -20, 330, 3.4, C["ink"])
    full = charge >= 1
    brush_arc(P, cx, cy, r + 6, 0, 360 * charge, 3.0, C["cobalt"], taper=(0.04, 0.96) if full else (0.06, 0.99))
    word = SKILL.upper() if full else f"{round(charge * 100)}%"
    P.text(cx, cy + r + 21, word, 14, "SrcB", C["cobalt"] if full else C["ink"], anchor="middle", spacing=2 if full else 0.6,
           extra=' filter="url(#paperword)"')
    # Auto
    ax, ay = cx + r + 22, cy - 11
    c_band(P, ax, ay, 58, 24)
    P.add(f'<circle cx="{ax + 10}" cy="{ay + 12}" r="3.4" fill="{C["cobalt"]}"/>')
    P.text(ax + 19, ay + 17, "AUTO", 14, "SrcB", C["ink"], spacing=2)


def c_skill(P):
    """The skill's moment: a title card cuts in across the fight, then the frame is still again."""
    w, h = P.w, P.h
    band = [(0, h * 0.30), (w, h * 0.16), (w, h * 0.50), (0, h * 0.64)]
    P.add(f'<path d="{poly(band)}" fill="{C["ink"]}" fill-opacity="0.25" transform="translate(4,6)"/>')
    P.add(f'<path d="{poly(band)}" fill="{C["paper"]}"/>')
    cid = P.uid("c")
    P.defs.append(f'<clipPath id="{cid}"><path d="{poly(band)}"/></clipPath>')
    P.add(f'<g clip-path="url(#{cid})"><rect x="0" y="0" width="{w}" height="{h}" fill="url(#tone)" fill-opacity="0.22"/>')
    for i in range(16):      # speed lines toward the card's left, ink
        y = h * 0.14 + i * h * 0.035
        brush_line(P, w * 0.42 + (i % 3) * 30, y + 10, w + 20, y - 26, 1.2 + (i % 4) * 0.5, C["ink"], opacity=0.5,
                   taper=(0.5, 0.98))
    bust(P, w * 0.60, h * 0.10, h * 0.55, ink=True, fade=0.95)
    P.add("</g>")
    brush_line(P, -10, h * 0.30, w + 10, h * 0.16 - 2, 4.5, C["ink"], taper=(0.02, 0.9))
    brush_line(P, -10, h * 0.64, w + 10, h * 0.50, 4.5, C["ink"], taper=(0.1, 0.98))
    brush_line(P, w * 0.05, h * 0.565, w * 0.52, h * 0.47, 7, C["cobalt"], taper=(0.05, 0.7))
    P.text(w * 0.06, h * 0.47, "HAYMAKER", 54, "Serif", C["ink"], spacing=4,
           extra=f' stroke="{C["ink"]}" stroke-width="0.9" transform="rotate(-9.3 {w * 0.06:.1f} {h * 0.47:.1f})"')
    P.text(w * 0.07, h * 0.53, "ROOK  ·  SIGNATURE", 14, "SrcB", C["grey"], spacing=4,
           extra=f' transform="rotate(-9.3 {w * 0.07:.1f} {h * 0.53:.1f})"')


def c_home(P):
    w, h = P.w, P.h
    # an episode's title card: paper over the base, the lead's art large at the right, the pages as its chapters
    pane = rect(22, 20, w - 44, h - 40)
    c_slip(P, pane)
    cid = P.uid("c")
    P.defs.append(f'<clipPath id="{cid}"><path d="{pane}"/></clipPath>')
    P.add(f'<g clip-path="url(#{cid})"><path d="{poly([(w * 0.52, 20), (w, 20), (w, h), (w * 0.44, h)])}" fill="url(#tone)" '
          f'fill-opacity="0.4"/>')
    bust(P, w * 0.50, 70, 380, ink=True, fade=0.94)
    P.add("</g>")
    brush_line(P, 18, 24, w - 18, 20, 3.2, C["ink"], taper=(0.03, 0.9))
    brush_line(P, 20, h - 18, w - 20, h - 22, 3.2, C["ink"], taper=(0.1, 0.97))
    P.text(48, 66, "LEAD", 14, "SrcB", C["grey"], spacing=5)
    P.text(46, 118, "Rook", 52, "Serif", C["ink"], spacing=1, extra=f' stroke="{C["ink"]}" stroke-width="0.8"')
    brush_line(P, 48, 134, 300, 130, 5, C["cobalt"], taper=(0.04, 0.75))
    P.text(48, 158, "LV 26   ·   WARRIOR   ·   FIRE", 14, "SrcS", C["ink"], spacing=2.5)
    pages = [("VOIDKIN", "4 owned"), ("EQUIPMENT", "Reinforce · Jewels · War Emblems"), ("TODAY", "1 of 3 done"),
             ("SETTINGS", "Sound · Effects")]
    for i, (name, sub) in enumerate(pages):
        y = 206 + i * 56
        on = i == 0
        P.text(48, y, f"0{i + 1}", 14, "SrcB", C["cobalt"] if on else C["grey"], spacing=1)
        P.text(80, y + 1, name, 20, "SrcB", C["ink"], spacing=5)
        P.text(80, y + 22, sub, 14, "Src", C["grey"], spacing=0.6)
        if on:
            brush_line(P, 78, y + 30, 270, y + 28, 2.4, C["cobalt"], taper=(0.05, 0.8))
    P.text(48, h - 38, "Stand-in art: Rook's portrait render", 14, "Src", C["grey"])
    P.text(w - 46, 58, "CLOSE", 14, "SrcB", C["ink"], anchor="end", spacing=3)


def c_tokens(P):
    tokens(P, "C, Episode: the lead's own anime", C["paper"], C["ink"],
           [("Paper", C["paper"]), ("Ink", C["ink"]), ("Ink grey", C["grey"]), ("Cobalt", C["cobalt"]),
            ("Cobalt lit", C["cobalt_hi"]), ("Health", C["red"])],
           [("Source Sans Bold 14, tracked", "SrcB", 14, "ROOK · BRAWLER", 3.2),
            ("Source Sans Semibold 14", "SrcS", 14, "3,682 / 3,732 · LV 26"), ("Merriweather 34, the skill only", "Serif", 34, "Haymaker")],
           "Lines: ink 1 pt rules, brush strokes 2 to 5 pt with tapered ends; screentone dots 1.9 pt apart at 45 degrees.",
           "Motion: nearly silent in a fight; at the skill a title card cuts in for about a second, then the frame is still.",
           c_motif)


def c_motif(P, x, y):
    brush_line(P, x, y + 12, x + 220, y + 8, 4, C["ink"])
    brush_line(P, x, y + 24, x + 160, y + 22, 3, C["cobalt"], taper=(0.05, 0.75))
    P.add(f'<rect x="{x}" y="{y + 32}" width="220" height="16" fill="url(#toneFine)" fill-opacity="0.6"/>')


# ---- the token strip ----------------------------------------------------------------------------------------------------
def tokens(P, title, ground, ink, swatches, faces, lines, motion, motif):
    P.add(f'<rect x="0" y="0" width="{P.w}" height="{P.h}" fill="{ground}"/>')
    P.text(24, 34, title, 18, "SrcB", ink)
    for i, (name, c) in enumerate(swatches):
        x = 24 + i * 100
        P.add(f'<rect x="{x}" y="52" width="88" height="44" fill="{c}" stroke="{ink}" stroke-opacity="0.25"/>')
        P.text(x, 114, name, 14, "Src", ink)
        P.text(x, 130, c.upper(), 14, "Src", ink, opacity=0.6)
    for i, (label, face, size, sample, *spacing) in enumerate(faces):
        y = 172 + i * 40
        P.text(24, y, label, 14, "Src", ink, opacity=0.6)
        P.text(250, y + 2, sample, size, face, ink, spacing=spacing[0] if spacing else 0.0)
    P.text(24, 300, lines, 14, "Src", ink)
    P.text(24, 322, motion, 14, "Src", ink)
    motif(P, P.w - 260, 168)


# ---- the output ---------------------------------------------------------------------------------------------------------
def faces_css():
    return "".join(f'@font-face{{font-family:"{fam}";src:url("{(sf.FONTS / file).as_uri()}")}}' for fam, file in FACES.items())


def shoot(P, out, scale=2):
    html = (f'<!doctype html><html><head><meta charset="utf-8"><style>{faces_css()} html,body{{margin:0;background:#000}}'
            f' svg{{display:block}}</style></head><body>{P.svg()}</body></html>')
    sf.shoot(html, out, P.w, P.h, scale=scale)


DRAW = {"A": (a_fight, a_home, a_tokens), "B": (b_fight, b_home, b_tokens), "C": (c_fight, c_home, c_tokens)}


def main():
    out = Path(sys.argv[1]).resolve()
    keys = [k for k in sys.argv[2:] if k in DRAW] or list(DRAW)
    out.mkdir(parents=True, exist_ok=True)
    for k in keys:
        fight, home, tok = DRAW[k]
        for w, h in ((W, H), (SW, SH)):
            P = Page(w, h, FIGHT)
            fight(P, charge=1.0 if w == W else 0.62)       # ready at 852, filling at the smallest phone
            shoot(P, out / f"fight_{k}_{w}.png")
            area = sum(bw * bh for _, _, bw, bh in P.boxes) / (w * h)
            least = min(P.sizes)
            print(f"{k} at {w}: the permanent HUD {area:.1%} of the screen; the smallest word {least[0]} pt ({least[1]!r})")
        P = Page(W, H, BASE)
        home(P)
        shoot(P, out / f"home_{k}.png")
        print(f"{k} home: the smallest word {min(P.sizes)[0]} pt")
        P = Page(W, 340)
        tok(P)
        shoot(P, out / f"tokens_{k}.png")
        if k == "C":
            P = Page(W, H, FIGHT)
            c_fight(P)
            c_skill(P)
            shoot(P, out / "skill_C.png")
    if keys == list(DRAW):
        sheets(out)
    print("drew AR68's targets:", ", ".join(keys))


def sheets(out):
    """Today's game and the three at the smallest phone, 2x; the three homes."""
    with tempfile.TemporaryDirectory():
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(TODAY), "-i", str(out / "fight_A_568.png"), "-i",
                        str(out / "fight_B_568.png"), "-i", str(out / "fight_C_568.png"), "-filter_complex",
                        "[0:v]scale=1136:-1[t];[t][1:v][2:v][3:v]xstack=inputs=4:layout=0_0|w0_0|0_h0|w0_h0:fill=0x15191F",
                        str(out / "sheet_fight.png")], check=True)
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(out / "home_A.png"), "-i", str(out / "home_B.png"), "-i",
                        str(out / "home_C.png"), "-filter_complex",
                        "[0:v]scale=852:-1[a];[1:v]scale=852:-1[b];[2:v]scale=852:-1[c];[a][b][c]hstack=inputs=3",
                        str(out / "sheet_home.png")], check=True)


if __name__ == "__main__":
    main()
