"""AR68, the UI's complete overhaul: the three directions' targets (research's brief, docs/asset-requests.md, AR68;
the study, docs/research/ui-design.md). Round 2 answers research's check of 03:07 and the director's word on C of
about 03:08.

    py tools/ui/overhaul.py <out> [A B C]

Each direction answers "whose device or voice is this UI, in our fiction?":
- A, Console: the player's own yard system. Smoked graphite glass, gauge ticks, readouts with units, and one live line
  along the frame linking the HUD's pieces. Power's amber. Working face: Builder Mono; display: Builder Extended.
- B, Shard: the UI seen in the shard glass. Pale facets cut at break angles, each bending the world behind it its own
  way, one lit edge where the light catches; a Voidkin's own hue only in its portrait's facet. Working face:
  Montserrat; display: Michroma.
- C, Episode: the lead's own anime. Paper laid with a brush over an ink stroke, ink lines with brush ends, a fine
  screentone, one hot hue that isn't red (cobalt), names set like credits; a title card only at the skill. Working
  face: Source Sans Pro; display: Merriweather.
Common (AR68): the centre 60% of the width is the fighters'; the permanent fight HUD, the press aside, about 6% of the
screen at 852 (14-point text sets 10 to 12% on the smallest phone, research, 03:07); every word 14 points or more, the
same points on every phone; never pure black or white. Every piece of UI in the frame is the direction's, damage
numbers too (docs/ui.md, "Damage numbers"; the critical keeps the director's gold). The lead's card carries its
portrait, type gem, class mark, health and experience; the target's its name, type gem, health, the difficulty skull
with the level in the skull's colour, and the type edge's arrow. No Rook render as hero art (the director, 2026-11-26,
20:46): Home and the title card hold a labelled art frame; the press a labelled slot for the skill's own art, its name
not the main read (the director, 2026-11-27, 01:39).

Writes, per direction X: fight_X_852.png and fight_X_568.png, home_X.png, tokens_X.png; skill_C.png; sheet_fight.png
(today's game and the three at the smallest phone, 2x) and sheet_home.png.
"""
import math
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import style_frames as sf  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
SCRATCH = REPO / "build" / "scratch"
CACHE = SCRATCH / "modulo" / "ar68" / "cache"          # each plate blurred once per size and radius
W, H = 852, 473
SW, SH = 568, 315
# The fight with all UI hidden at each size, and today's game in the same fight at the same size (Faber's capture for
# AR68). Until it lands: the baseplate fight, and today's game from a wider window.
FIGHT = {W: SCRATCH / "modulo" / "hud" / "plates" / "fight.png", SW: SCRATCH / "modulo" / "hud" / "plates" / "fight.png"}
TODAY = SCRATCH / "faber" / "f2cap" / "fight_ready.jpg"
BASE = SCRATCH / "modulo" / "hud" / "plates" / "base.png"
BUST = REPO / "build" / "handoff" / "Rook" / "make" / "portraits" / "PortraitRook.png"   # the lead's portrait, on its card only
BUST_BOX = (0.28, 0.36, 0.71, 0.73)      # the bust's visible box in its render, as shares of 736 x 800
BUST_SIZE = (736, 800)
HEAD = (0.622, 0.352)                    # the foe's head, as shares of the frame
FOE_BOX = (0.585, 0.31, 0.672, 0.50)     # the foe's body, as shares of the frame
PRESS = (54, 176, 33)                    # the press's centre and radius: 66 points, where TR52 measured the thumb

# The fight's data, as the game has it: the lead, its target and the hits on screen.
LEAD = dict(name="Rook", type="Red", cls="Warrior", level=26, hp=3682, max=3732, xp=0.38)
FOE = dict(name="Brawler", type="Red", level=26, hp=2964, max=4290, tier=1)
HITS = dict(crit="1,130", hits=("565", "565"), element="98", taken="15")
SKILL = "Haymaker"
TYPES = {"Red": "#EA4B4F", "Orange": "#F4902A", "Blue": "#3F9DF2", "Purple": "#A470F2", "Green": "#42CC7E"}   # Config.Hud
RING = ("Blue", "Red", "Orange", "Purple", "Green")      # each beats the next (docs/design.md, "Type")
TIERS = ("#D3D1DC", "#F6F2E8", "#FFC83A", "#FF4F42")     # the skull (Config.Hud.Skulls): much weaker, even, stronger, much
FIRE = "#FF8A3D"                                          # the element's number (Config.UIKit)
GOLD = ((0, "#FFFDF0"), (0.15, "#FFF2B0"), (0.35, "#FFD84A"), (0.49, "#FFB300"), (0.5, "#7A3A00"), (0.58, "#B85E00"),
        (0.75, "#FF9A1A"), (0.92, "#FFD36B"), (1, "#FFF0B8"))   # the critical's chrome (Config.Hud; AR44 C, 2026-11-19)

FACES = {"Mono": "BuilderMono-Regular.otf", "MonoB": "BuilderMono-Bold.otf", "MonoL": "BuilderMono-Light.otf",
         "Ext": "BuilderExtended-SemiBold.otf", "ExtB": "BuilderExtended-Bold.otf",
         "Mont": "Montserrat-Medium.ttf", "MontR": "Montserrat-Regular.ttf", "MontB": "Montserrat-Bold.ttf",
         "MontK": "Montserrat-Black.ttf", "Mich": "Michroma-Regular.ttf",
         "Src": "SourceSansPro-Regular.ttf", "SrcL": "SourceSansPro-Light.ttf", "SrcS": "SourceSansPro-Semibold.ttf",
         "SrcB": "SourceSansPro-Bold.ttf", "Serif": "Merriweather-Regular.ttf"}

# the directions' tokens
A = dict(amber="#F0A73C", amber_hi="#FFD08A", amber_lo="#9A5E16", glass="#2A2622", glass2="#3A332C",
         ivory="#EEE7DB", grey="#A89F92", dim="#5E574E", red="#E0574D", red_track="#4A2420", outline="#17130F")
B = dict(ice="#9FDDF5", ice_hi="#F4FCFF", ice_lo="#5BB6DC", glass="#E6F1F6", ink="#1F2B38", grey="#4F6272",
         line="#8FA9BA", red="#D94A55", red_track="#C3D1DA", rook="#C8453E", up="#2F8F66")
C = dict(paper="#F1EDE4", ink="#27272B", grey="#5A5A61", tone="#27272B", cobalt="#2D58D6", cobalt_hi="#7F9DF0",
         red="#D6473F", red_track="#D9D3C7")


def edge(lead, foe):
    """The type edge: 1 when the lead's type beats the foe's, -1 when the foe's beats the lead's."""
    i, j = RING.index(lead), RING.index(foe)
    return 1 if (i + 1) % 5 == j else -1 if (j + 1) % 5 == i else 0


def out(color, width):
    """An outline behind the glyphs."""
    return f' stroke="{color}" stroke-width="{width}" stroke-linejoin="round" paint-order="stroke"'


def blurred(plate, w, h, r):
    """The plate at a frame's size, blurred once (2x, as the frame is shot)."""
    path = CACHE / f"{plate.stem}_{w}_b{r}.png"
    if not path.exists():
        CACHE.mkdir(parents=True, exist_ok=True)
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(plate), "-vf", f"scale={2 * w}:{2 * h},gblur=sigma={2 * r}",
                        str(path)], check=True)
    return path.as_uri()


def _noise(fid, freq, octaves, seed, scale, pad="-10%", size="120%", vpad="-40%", vsize="180%"):
    return (f'<filter id="{fid}" x="{pad}" y="{vpad}" width="{size}" height="{vsize}"><feTurbulence type="fractalNoise" '
            f'baseFrequency="{freq}" numOctaves="{octaves}" seed="{seed}" result="n"/><feDisplacementMap in="SourceGraphic" '
            f'in2="n" scale="{scale}" xChannelSelector="R" yChannelSelector="G"/></filter>')


class Page:
    def __init__(self, w, h, plate=None):
        self.w, self.h, self.parts, self.n = w, h, [], 0
        self.plate = plate
        self.defs = [
            '<filter id="glow" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="3.2"/></filter>',
            '<filter id="soft" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="1.4"/></filter>',
            '<filter id="frostword" x="-20%" y="-40%" width="140%" height="180%"><feMorphology in="SourceAlpha" operator="dilate" radius="1.6" result="d"/><feGaussianBlur in="d" stdDeviation="1.6" result="b"/><feFlood flood-color="#EEF6FA" flood-opacity="0.9"/><feComposite in2="b" operator="in" result="o"/><feMerge><feMergeNode in="o"/><feMergeNode in="SourceGraphic"/></feMerge></filter>',
            f'<filter id="paperword" x="-20%" y="-40%" width="140%" height="180%"><feMorphology in="SourceAlpha" operator="dilate" radius="2" result="d"/><feGaussianBlur in="d" stdDeviation="1.2" result="b"/><feFlood flood-color="{C["paper"]}" flood-opacity="0.95"/><feComposite in2="b" operator="in" result="o"/><feMerge><feMergeNode in="o"/><feMergeNode in="SourceGraphic"/></feMerge></filter>',
            '<filter id="shade" x="-20%" y="-40%" width="140%" height="180%"><feDropShadow dx="0" dy="0.8" '
            'stdDeviation="0.7" flood-color="#17130F" flood-opacity="0.75" result="a"/><feDropShadow in="a" dx="0" '
            'dy="0" stdDeviation="3" flood-color="#17130F" flood-opacity="0.35"/></filter>',
            f'<pattern id="tone" width="2.6" height="2.6" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">'
            f'<circle cx="1.3" cy="1.3" r="0.62" fill="{C["tone"]}"/></pattern>',
            f'<pattern id="toneFine" width="1.9" height="1.9" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">'
            f'<circle cx="0.95" cy="0.95" r="0.42" fill="{C["tone"]}"/></pattern>',
            f'<pattern id="hatchA" width="4" height="4" patternUnits="userSpaceOnUse" patternTransform="rotate(-35)">'
            f'<rect x="0" y="0" width="0.7" height="4" fill="{A["amber"]}"/></pattern>',
            f'<filter id="inkline" x="-10%" y="-10%" width="120%" height="120%"><feMorphology in="SourceAlpha" '
            f'operator="dilate" radius="1.3" result="d"/><feFlood flood-color="{C["ink"]}"/><feComposite in2="d" '
            f'operator="in" result="o"/><feMerge><feMergeNode in="o"/><feMergeNode in="SourceGraphic"/></feMerge></filter>',
            '<linearGradient id="gold" x1="0" y1="0" x2="0" y2="1">'
            + "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in GOLD) + '</linearGradient>',
            # C's brush: a drawn edge (the paper's and the ink's, each its own), a finer one for lines, and the
            # bristles' streaks inside a stroke
            _noise("rough", "0.07 0.32", 3, 7, 4.6),
            _noise("roughInk", "0.06 0.28", 3, 19, 5.5),
            _noise("roughFine", "0.09 0.4", 2, 5, 2.2, pad="-20%", size="140%"),
            '<filter id="bristle" x="0" y="0" width="100%" height="100%" color-interpolation-filters="sRGB">'
            '<feTurbulence type="fractalNoise" baseFrequency="0.0035 0.45" numOctaves="2" seed="11"/><feColorMatrix '
            'type="matrix" values="0 0 0 0 0.15  0 0 0 0 0.15  0 0 0 0 0.17  6 0 0 0 -3.05"/></filter>',
            # A's glass: a fine grain in it
            '<filter id="grain" x="0" y="0" width="100%" height="100%" color-interpolation-filters="sRGB">'
            '<feTurbulence type="fractalNoise" baseFrequency="0.85" numOctaves="2" seed="3"/><feColorMatrix type="matrix" '
            'values="0 0 0 0 1  0 0 0 0 0.93  0 0 0 0 0.84  2.2 0 0 0 -1.05"/></filter>',
        ]
        self.sizes, self.boxes = [], []
        if plate:
            self.add(f'<image href="{plate.resolve().as_uri()}" x="0" y="0" width="{w}" height="{h}" preserveAspectRatio="none"/>')

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

    def clip(self, d):
        cid = self.uid("c")
        self.defs.append(f'<clipPath id="{cid}"><path d="{d}"/></clipPath>')
        return cid

    def mask(self, d, filt=None):
        """A mask in the shape of a path, drawn through a filter (a brushed edge) when given."""
        mid = self.uid("m")
        f = f' filter="url(#{filt})"' if filt else ""
        self.defs.append(f'<mask id="{mid}" maskUnits="userSpaceOnUse" x="0" y="0" width="{self.w}" height="{self.h}">'
                         f'<path d="{d}" fill="#fff"{f}/></mask>')
        return mid

    def world(self, d, r, shift=(0, 0), zoom=1.0, centre=(0, 0)):
        """The world seen through a pane: the plate blurred inside the shape, shifted and scaled (a refraction)."""
        if not self.plate:
            return
        cx, cy = centre
        tf = (f' transform="translate({cx:.2f},{cy:.2f}) scale({zoom}) translate({-cx + shift[0]:.2f},{-cy + shift[1]:.2f})"'
              if zoom != 1 or shift != (0, 0) else "")
        self.add(f'<g clip-path="url(#{self.clip(d)})"><image href="{blurred(self.plate, self.w, self.h, r)}" x="0" y="0" '
                 f'width="{self.w}" height="{self.h}" preserveAspectRatio="none"{tf}/></g>')

    def hud(self, x, y, w, h):
        """Counts a permanent piece's box toward the HUD's share of the screen."""
        self.boxes.append((x, y, w, h))


def poly(pts):
    return "M" + " L".join(f"{x:.2f},{y:.2f}" for x, y in pts) + " Z"


def cut(x, y, w, h, tl=0, tr=0, br=0, bl=0):
    """A rectangle with cut corners."""
    return poly([(x + tl, y), (x + w - tr, y), (x + w, y + tr), (x + w, y + h - br), (x + w - br, y + h),
                 (x + bl, y + h), (x, y + h - bl), (x, y + tl)])


def rect(x, y, w, h):
    return poly([(x, y), (x + w, y), (x + w, y + h), (x, y + h)])


def circle(cx, cy, r):
    return f"M {cx - r:.2f},{cy:.2f} a {r},{r} 0 1,0 {2 * r},0 a {r},{r} 0 1,0 {-2 * r},0 Z"


def centroid(pts):
    return sum(x for x, _ in pts) / len(pts), sum(y for _, y in pts) / len(pts)


def split(pts, a, b):
    """A polygon cut by the line a-b: its two sides (a shard's facets)."""
    def side(p):
        return (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0])
    halves = ([], [])
    for i, p in enumerate(pts):
        q = pts[(i + 1) % len(pts)]
        sp, sq = side(p), side(q)
        if sp >= 0:
            halves[0].append(p)
        if sp <= 0:
            halves[1].append(p)
        if sp * sq < 0:
            t = sp / (sp - sq)
            x = (p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t)
            halves[0].append(x)
            halves[1].append(x)
    return [h for h in halves if len(h) >= 3]


def bust(P, x, y, size, ink=False, fade=0.72, opacity=1.0):
    """The lead's portrait on its card (its render, no box), `size` tall with its top left at (x, y); its foot fades."""
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
    filt = ' filter="url(#inkline)"' if ink else ""
    P.add(f'<g mask="url(#{mid})" opacity="{opacity}"><image href="{BUST.as_uri()}" x="{ix:.2f}" y="{iy:.2f}" '
          f'width="{dw:.2f}" height="{dh:.2f}"{filt}/></g>')


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


def brush_line(P, x0, y0, x1, y1, w, fill, opacity=1.0, taper=(0.15, 0.85), filt="roughFine"):
    """An ink stroke with brush ends, its edge drawn."""
    f = f' filter="url(#{filt})"' if filt else ""
    P.add(f'<path d="{brush_path(x0, y0, x1, y1, w, taper, wobble=0.05, steps=40)}" fill="{fill}" fill-opacity="{opacity}"{f}/>')


def brush_arc(P, cx, cy, r, a0, a1, w, fill, opacity=1.0, taper=(0.12, 0.88), filt="roughFine"):
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
    f = f' filter="url(#{filt})"' if filt else ""
    P.add(f'<path d="{poly(outer + inner[::-1])}" fill="{fill}" fill-opacity="{opacity}"{f}/>')


def head(w, h):
    return HEAD[0] * w, HEAD[1] * h


# ---- the functions' glyphs, drawn per direction ---------------------------------------------------------------------
def skull(P, x, y, s, color, ink=None, width=0.0, extra=""):
    """The difficulty skull, `s` tall, its top left at (x, y): a cranium, a narrower jaw, two eyes and a nose cut out."""
    k = s / 10.8

    def p(u, v):
        return f"{x + u * k:.2f},{y + v * k:.2f}"
    d = (f"M{p(0, 4.8)} A{5 * k:.2f},{4.8 * k:.2f} 0 1 1 {p(10, 4.8)} L{p(10, 6.3)} Q{p(10, 7.7)} {p(8.3, 8.1)} "
         f"L{p(7.9, 10.6)} L{p(2.1, 10.6)} L{p(1.7, 8.1)} Q{p(0, 7.7)} {p(0, 6.3)} Z "
         + circle(x + 3.05 * k, y + 5.3 * k, 1.45 * k) + " " + circle(x + 6.95 * k, y + 5.3 * k, 1.45 * k)
         + f" M{p(5, 6.7)} L{p(5.75, 8.1)} L{p(4.25, 8.1)} Z M{p(3.9, 9.1)} L{p(4.4, 9.1)} L{p(4.4, 10.6)} L{p(3.9, 10.6)} Z"
         f" M{p(5.6, 9.1)} L{p(6.1, 9.1)} L{p(6.1, 10.6)} L{p(5.6, 10.6)} Z")
    st = f' stroke="{ink}" stroke-width="{width}" stroke-linejoin="round" paint-order="stroke"' if ink else ""
    P.add(f'<path d="{d}" fill="{color}" fill-rule="evenodd"{st}{extra}/>')


def gem(P, cx, cy, s, color, rim=None, width=0.8, extra=""):
    """The type gem: a cut stone in its type's colour, its upper facet lit."""
    hw, hh = s * 0.4, s / 2
    pts = [(cx, cy - hh), (cx + hw, cy), (cx, cy + hh), (cx - hw, cy)]
    st = f' stroke="{rim}" stroke-width="{width}" stroke-linejoin="round"' if rim else ""
    P.add(f'<path d="{poly(pts)}" fill="{color}"{st}{extra}/>'
          f'<path d="{poly([(cx, cy - hh), (cx + hw, cy), (cx, cy - hh * 0.1), (cx - hw, cy)])}" fill="#FFFFFF" fill-opacity="0.38"/>'
          f'<path d="{poly([(cx - hw, cy), (cx, cy + hh), (cx, cy - hh * 0.1)])}" fill="#2A1712" fill-opacity="0.18"/>')


def blade(P, cx, cy, s, color, ink=None, width=0.0, extra=""):
    """The Warrior's class mark: an upright blade, `s` tall."""
    k = s / 14
    half = [(0, -6.6), (1.5, -4.9), (1.5, 2.1), (3.8, 2.1), (3.8, 3.4), (1.0, 3.4), (1.0, 5.4), (1.7, 6.3), (0, 7.4)]
    pts = half + [(-u, v) for u, v in half[-2:0:-1]]
    st = f' stroke="{ink}" stroke-width="{width}" stroke-linejoin="round" paint-order="stroke"' if ink else ""
    P.add(f'<path d="{poly([(cx + u * k, cy + v * k) for u, v in pts])}" fill="{color}"{st}{extra}/>')


def arrow(P, cx, cy, s, up, color, ink=None, width=0.0, extra=""):
    """The type edge: a small arrow, up when the lead's type beats the target's, down when the target's beats it."""
    k = 1 if up else -1
    pts = [(0, -0.5), (0.46, 0.04), (0.17, 0.04), (0.17, 0.5), (-0.17, 0.5), (-0.17, 0.04), (-0.46, 0.04)]
    st = f' stroke="{ink}" stroke-width="{width}" stroke-linejoin="round" paint-order="stroke"' if ink else ""
    P.add(f'<path d="{poly([(cx + u * s, cy + k * v * s) for u, v in pts])}" fill="{color}"{st}{extra}/>')


def number(P, x, y, text, size, st, fill, crit=False, opacity=1.0, anchor="start"):
    """One damage number in its direction's manner. Every direction keeps the outline and the wide spacing (the director,
    11-12) and the critical's gold, slant and weight (11-19); what changes is the face and how the outline is made:
    A a hairline, mitred, with the console's shadow; B a mitred ink edge with the glass's lit edge split rose and cyan
    behind it; C an ink outline laid with the brush under a clean fill."""
    face = st["crit_face"] if crit else st["face"]
    sp = st["spacing"] + (st.get("crit_extra", 0.4) if crit else 0)
    w = st["crit_width"] if crit else st["width"]
    ink = st["crit_ink"] if crit else st["ink"]
    op = f' opacity="{opacity}"' if opacity != 1 else ""
    P.add(f"<g{op}>")
    if st["kind"] == "A":
        P.text(x, y, text, size, face, fill, anchor=anchor, spacing=sp,
               extra=f' stroke="{ink}" stroke-width="{w}" stroke-linejoin="miter" paint-order="stroke"{SHADE}')
    elif st["kind"] == "B":
        d = 1.6 if crit else 1.0
        for dx, c in ((-d, "#FF8FB4"), (d, "#7FE6FF")):
            P.text(x + dx, y - d * 0.5, text, size, face, c, anchor=anchor, spacing=sp, opacity=0.95,
                   extra=f' stroke="{c}" stroke-width="{w + 1.4}" stroke-linejoin="miter" paint-order="stroke"')
        P.text(x, y, text, size, face, fill, anchor=anchor, spacing=sp,
               extra=f' stroke="{ink}" stroke-width="{w}" stroke-linejoin="miter" paint-order="stroke"')
        if crit:      # the glass's glint, caught on the number's top edge
            gx, gy = x + size * 1.9, y - size * 0.72
            P.add(f'<path d="M {gx - 7},{gy} L {gx},{gy - 1} L {gx + 7},{gy} L {gx},{gy + 1} Z M {gx},{gy - 7} L {gx + 1},{gy} '
                  f'L {gx},{gy + 7} L {gx - 1},{gy} Z" fill="#FFFFFF"/><circle cx="{gx}" cy="{gy}" r="1.6" fill="#FFFFFF"/>')
    else:
        P.text(x + (2.2 if crit else 1.4), y + (2.2 if crit else 1.4), text, size, face, ink, anchor=anchor, spacing=sp, opacity=0.55,
               extra=f' stroke="{ink}" stroke-width="{w}" stroke-linejoin="round" filter="url(#roughInk)"')
        P.text(x, y, text, size, face, ink, anchor=anchor, spacing=sp,
               extra=f' stroke="{ink}" stroke-width="{w}" stroke-linejoin="round" filter="url(#{"roughInk" if crit else "roughFine"})"')
        P.text(x, y, text, size, face, fill, anchor=anchor, spacing=sp)
    P.add("</g>")


def numbers(P, st, sweep, anchor, taken):
    """The damage numbers (docs/ui.md, "Damage numbers"), in the direction's face. At the target, rising from the body:
    the latest big (here a critical: the director's gold, heavy, slanted, larger, on the direction's own swept stroke),
    the element's number a beat behind it in its colour, and the two before smaller and fading as they rise. At the
    lead's card, the damage it takes: a size larger, muted red, crossing the card's top over the bar's draining end."""
    ax, ay = anchor
    h1, h2 = HITS["hits"]
    number(P, ax + 82, ay - 50, h2, 14, st, st["plain"], opacity=0.45)
    number(P, ax + 46, ay - 29, h1, 17, st, st["plain"], opacity=0.75)
    sweep(P, ax - 10, ay + 4, ax + 108, ay - 24)
    P.add(f'<g transform="translate({ax:.2f},{ay:.2f}) skewX(-12)">')
    number(P, 0, 0, HITS["crit"], 30, st, "url(#gold)", crit=True)
    P.add("</g>")
    number(P, ax + 100, ay + 16, HITS["element"], 17, st, FIRE)
    tx, ty = taken
    number(P, tx, ty, HITS["taken"], 20, st, "#E27A6A", anchor="middle")


def number_anchor(w, h, left=False):
    """Where the latest number lands: at the body's side, a little under its middle."""
    x0, y0, x1, y1 = FOE_BOX
    return ((x0 * w - 150) if left else (x1 * w + 10)), (y0 + 0.62 * (y1 - y0)) * h


# ---- A, Console -------------------------------------------------------------------------------------------------------
SHADE = ' filter="url(#shade)"'


def a_ticks(P, x, y, w, n, major, color, dim, lit=1.0, h1=2.0, h2=4.0):
    for i in range(n + 1):
        tx = x + w * i / n
        big = i % major == 0
        c = color if i / n <= lit + 1e-6 else dim
        P.add(f'<rect x="{tx - 0.4:.2f}" y="{y:.2f}" width="0.8" height="{h2 if big else h1}" fill="{c}" '
              f'fill-opacity="{0.95 if big else 0.7}"/>')


def a_bar(P, x, y, w, h, share, fill, track):
    P.add(f'<rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="{h}" fill="{track}" fill-opacity="0.9"/>')
    P.add(f'<rect x="{x:.2f}" y="{y:.2f}" width="{w * share:.2f}" height="{h}" fill="{fill}"/>')
    P.add(f'<rect x="{x + w * share - 0.6:.2f}" y="{y - 1.5:.2f}" width="1.2" height="{h + 3}" fill="{A["ivory"]}"/>')


def a_brackets(P, x, y, w, h, arm, color, width=1.2, opacity=1.0):
    """The console's lock: what it reads in the world, it brackets."""
    d = (f"M {x},{y + arm} L {x},{y} L {x + arm},{y} M {x + w - arm},{y} L {x + w},{y} L {x + w},{y + arm} "
         f"M {x + w},{y + h - arm} L {x + w},{y + h} L {x + w - arm},{y + h} M {x + arm},{y + h} L {x},{y + h} L {x},{y + h - arm}")
    P.add(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{width}" stroke-opacity="{opacity}"{SHADE}/>')


def a_glass(P, d, opacity=0.7, lit_top=True):
    """The console's glass: smoked warm graphite with depth. The world through it, blurred and darkened; a grain; a
    sheen across its upper part; its lit top edge and a dark foot; a soft shadow under it."""
    P.add(f'<path d="{d}" fill="#120E0B" fill-opacity="0.4" transform="translate(0,2.5)" filter="url(#soft)"/>')
    P.world(d, 6)
    P.add(f'<path d="{d}" fill="{P.lin((A["glass2"], A["glass"], "#1E1B18"), x2=0, y2=1)}" fill-opacity="{opacity}"/>')
    cid = P.clip(d)
    P.add(f'<g clip-path="url(#{cid})"><rect x="0" y="0" width="{P.w}" height="{P.h}" filter="url(#grain)" opacity="0.09"/>'
          f'<path d="{d}" fill="{P.lin(("#FFF4E2", "#FFF4E2"), x2=0.35, y2=1, opacities=(0.13, 0.0))}"/></g>')
    P.add(f'<path d="{d}" fill="none" stroke="{A["ivory"]}" stroke-opacity="0.16" stroke-width="0.8"/>')
    if lit_top:
        P.add(f'<g clip-path="url(#{cid})"><path d="{d}" fill="none" stroke="{P.lin(("#FFF1DA", "#FFF1DA"), x2=0, y2=1, opacities=(0.55, 0.0))}" '
              f'stroke-width="1.6"/></g>')


def a_node(P, x, y, lit=False):
    c = A["amber_hi"] if lit else A["amber"]
    P.add(f'<rect x="{x - 1.6:.2f}" y="{y - 1.6:.2f}" width="3.2" height="3.2" fill="{c}"/>')


def a_rail(P, pts, pulse):
    """The live line: one amber rail along the frame linking the HUD's pieces, a fine tick scale along it, fading at
    its ends; a pulse runs along it to what changed, a comet with a tail."""
    pts = [p for i, p in enumerate(pts) if i == 0 or math.dist(p, pts[i - 1]) > 0.01]
    d = "M" + " L".join(f"{x:.2f},{y:.2f}" for x, y in pts)
    seg = [math.dist(a, b) for a, b in zip(pts, pts[1:])]
    total = sum(seg)
    P.add(f'<path d="{d}" fill="none" stroke="#17130F" stroke-opacity="0.45" stroke-width="2.6"/>')
    P.add(f'<path d="{d}" fill="none" stroke="{A["amber"]}" stroke-opacity="1" stroke-width="1.4"/>')
    # ticks every 4 points along the rail, a major every 20, on the screen's side away from the edge
    n, run = 0, 0.0
    for (a, b), L in zip(zip(pts, pts[1:]), seg):
        ux, uy = (b[0] - a[0]) / L, (b[1] - a[1]) / L
        nx, ny = -uy, ux
        if nx < 0 or (nx == 0 and ny < 0):
            nx, ny = -nx, -ny
        t = (4 - run % 4) % 4
        while t <= L:
            big = n % 5 == 0
            ln = 4 if big else 2
            px, py = a[0] + ux * t, a[1] + uy * t
            fade = min(1.0, (run + t) / 18, (total - run - t) / 18)
            P.add(f'<line x1="{px:.2f}" y1="{py:.2f}" x2="{px + nx * ln:.2f}" y2="{py + ny * ln:.2f}" stroke="{A["amber"]}" '
                  f'stroke-opacity="{0.95 * max(fade, 0):.2f}" stroke-width="1"/>')
            n += 1
            t += 4
        run += L
    # the pulse, a share along the rail
    at = pulse * total
    for (a, b), L in zip(zip(pts, pts[1:]), seg):
        if at <= L:
            ux, uy = (b[0] - a[0]) / L, (b[1] - a[1]) / L
            px, py = a[0] + ux * at, a[1] + uy * at
            tail = min(at, 26)
            gid = P.uid("g")
            P.defs.append(f'<linearGradient id="{gid}" gradientUnits="userSpaceOnUse" x1="{px - ux * tail:.2f}" '
                          f'y1="{py - uy * tail:.2f}" x2="{px:.2f}" y2="{py:.2f}"><stop offset="0" stop-color="{A["amber"]}" '
                          f'stop-opacity="0"/><stop offset="1" stop-color="{A["amber_hi"]}"/></linearGradient>')
            P.add(f'<line x1="{px - ux * tail:.2f}" y1="{py - uy * tail:.2f}" x2="{px:.2f}" y2="{py:.2f}" stroke="url(#{gid})" '
                  f'stroke-width="2.2" stroke-linecap="round"/>'
                  f'<circle cx="{px:.2f}" cy="{py:.2f}" r="5" fill="{A["amber_hi"]}" fill-opacity="0.55" filter="url(#soft)"/>'
                  f'<circle cx="{px:.2f}" cy="{py:.2f}" r="1.8" fill="#FFF3DC"/>')
            break
        at -= L


def a_sweep(P, x0, y0, x1, y1):
    """A's stroke behind a critical: a gauge needle's sweep, a thin arc of ticks brightening toward where it lands."""
    cx, cy = x0 + 6, y0 + 70
    r = math.dist((cx, cy), (x1, y1)) * 0.86
    a0, a1 = -62, 40
    for i in range(26):
        t = i / 25
        a = math.radians(a0 + (a1 - a0) * t)
        r0, r1 = r - 3 - 9 * t, r + 2
        P.add(f'<line x1="{cx + r0 * math.sin(a):.2f}" y1="{cy - r0 * math.cos(a):.2f}" x2="{cx + r1 * math.sin(a):.2f}" '
              f'y2="{cy - r1 * math.cos(a):.2f}" stroke="{A["amber_hi"]}" stroke-opacity="{0.15 + 0.75 * t:.2f}" '
              f'stroke-width="{0.8 + 1.4 * t:.2f}"/>')


def a_press(P, charge):
    """The press: a dial of ticks round the skill's art. Quiet while it fills (its share in numbers), awake when full."""
    cx, cy, r = PRESS
    full = charge >= 1
    if full:
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{r + 6}" fill="{A["amber"]}" fill-opacity="0.4" filter="url(#glow)"/>')
    a_glass(P, circle(cx, cy, r), opacity=0.62 if full else 0.74)
    # the skill's art, a labelled slot: its frame inside the dial
    ri = r - 8
    P.add(f'<circle cx="{cx}" cy="{cy}" r="{ri}" fill="url(#hatchA)" fill-opacity="{0.55 if full else 0.25}"/>'
          f'<circle cx="{cx}" cy="{cy}" r="{ri}" fill="none" stroke="{A["amber"] if full else A["dim"]}" stroke-width="0.8"/>')
    P.text(cx, cy - 2, "SKILL", 14, "MonoB", A["amber_hi"] if full else A["grey"], anchor="middle", spacing=0.6, extra=SHADE)
    P.text(cx, cy + 13, "ART", 14, "MonoB", A["amber_hi"] if full else A["grey"], anchor="middle", spacing=0.6, extra=SHADE)
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
        P.text(cx, cy + r + 17, SKILL.upper(), 14, "Mono", A["grey"], anchor="middle", spacing=1, extra=SHADE)
    else:
        P.text(cx, cy + r + 17, f"{round(charge * 100)}%", 14, "Mono", A["ivory"], anchor="middle", spacing=0.6, extra=SHADE)


def a_fight(P, charge=1.0):
    w, h = P.w, P.h
    cx, cy, r = PRESS
    # the lead's card: a pane of the console's glass, the portrait crossing its edge
    a_glass(P, cut(30, 8, 206, 60, br=10))
    P.hud(4, 4, 232, 64)
    bust(P, 4, 4, 64)
    bx, bw = 72, 156
    P.text(bx, 27, LEAD["name"].upper(), 15, "MonoB", A["ivory"], spacing=1.6)
    gem(P, bx + 52, 21.5, 11, TYPES[LEAD["type"]], rim=A["outline"])
    blade(P, bx + 66, 21.5, 12, A["ivory"])
    P.text(bx + 78, 27, f"LV {LEAD['level']}", 14, "Mono", A["amber"], spacing=0.5)
    share = LEAD["hp"] / LEAD["max"]
    a_bar(P, bx, 33, bw, 3, share, A["red"], A["red_track"])
    a_ticks(P, bx, 38, bw, 20, 5, A["grey"], A["dim"])
    P.add(f'<rect x="{bx}" y="45" width="{bw}" height="1.6" fill="{A["dim"]}"/>'
          f'<rect x="{bx}" y="45" width="{bw * LEAD["xp"]:.2f}" height="1.6" fill="{A["amber"]}"/>')      # experience
    P.text(bx, 62, f"{LEAD['hp']:,}", 18, "Mono", A["ivory"])
    P.text(bx + 58, 62, f"/ {LEAD['max']:,}", 14, "Mono", A["grey"])
    # the eye, a small pane
    ex, ey = 244, 12
    a_glass(P, cut(ex, ey, 28, 26, br=6))
    P.hud(ex, ey, 28, 26)
    P.add(f'<path d="M {ex + 6},{ey + 13} Q {ex + 14},{ey + 5.5} {ex + 22},{ey + 13} Q {ex + 14},{ey + 20.5} {ex + 6},{ey + 13} Z" '
          f'fill="none" stroke="{A["ivory"]}" stroke-width="1.3"/><circle cx="{ex + 14}" cy="{ey + 13}" r="2.5" fill="{A["amber"]}"/>')
    # the live line: from the card down the frame's edge to the press, the pulse on its way (it gained charge)
    a_rail(P, [(8, 72), (8, cy - 12), (cx - r - 2, cy)], 0.55)
    a_node(P, 8, 72)
    # the foe, locked in the world: the console brackets what it reads and prints the reading over the lock
    x0, y0, x1, y1 = FOE_BOX
    lx, ly, lw, lh = x0 * w, y0 * h, (x1 - x0) * w, (y1 - y0) * h
    a_brackets(P, lx, ly, lw, lh, 7, A["ivory"], width=1.2, opacity=0.8)
    fw, fh = (168 if edge(LEAD["type"], FOE["type"]) else 156), 38
    fx, fy = lx + lw / 2 - fw / 2, ly - fh - 8
    a_glass(P, cut(fx, fy, fw, fh, br=8))
    P.add(f'<path d="M {lx + lw / 2 - 5:.2f},{fy + fh:.2f} L {lx + lw / 2:.2f},{fy + fh + 6:.2f} L {lx + lw / 2 + 5:.2f},{fy + fh:.2f}" '
          f'fill="{A["glass"]}" fill-opacity="0.8"/>')
    P.hud(fx, fy, fw, fh)
    tier = TIERS[FOE["tier"]]
    skull(P, fx + 8, fy + 9, 13, tier)
    P.text(fx + 25, fy + 20, f"LV {FOE['level']}", 14, "Mono", tier)
    P.text(fx + 72, fy + 20, FOE["name"].upper(), 14, "MonoB", A["ivory"])
    gem(P, fx + (144 if fw == 156 else 146), fy + 15, 11, TYPES[FOE["type"]], rim=A["outline"])
    e = edge(LEAD["type"], FOE["type"])
    if e:
        arrow(P, fx + fw - 10, fy + 15, 10, e > 0, A["amber_hi"] if e > 0 else A["red"])
    a_bar(P, fx + 8, fy + 27, fw - 16, 3, FOE["hp"] / FOE["max"], A["red"], A["red_track"])
    # the press and Auto
    a_press(P, charge)
    ax, ay = cx + r + 14, cy - 13
    a_glass(P, cut(ax, ay, 68, 24, br=6))
    P.hud(ax, ay, 68, 24)
    P.add(f'<circle cx="{ax + 13}" cy="{ay + 12}" r="5.5" fill="{A["amber"]}" fill-opacity="0.5" filter="url(#soft)"/>'
          f'<circle cx="{ax + 13}" cy="{ay + 12}" r="2.8" fill="{A["amber_hi"]}"/>')
    P.text(ax + 24, ay + 17, "AUTO", 14, "MonoB", A["ivory"], spacing=0.8)
    # the numbers
    numbers(P, dict(kind="A", face="MonoB", crit_face="MonoB", plain=A["ivory"], ink=A["outline"], width=1.3,
                    crit_ink="#2E1800", crit_width=1.3, spacing=1.6, crit_extra=1.6), a_sweep, number_anchor(w, h), (bx + bw * share, 18))


def a_home(P):
    """The console's main page: a column of the yard's readings and its pages; the lead's key art large beside it,
    framed as the console's display (a labelled frame, the art to be painted)."""
    w, h = P.w, P.h
    cw = 330
    P.add(f'<rect x="0" y="0" width="{w}" height="{h}" fill="{P.lin((A["glass"], A["glass"]), x2=1, y2=0, opacities=(0.0, 0.4))}"/>')
    # the art's frame
    fx, fy, fw, fh = 360, 36, 462, 330
    a_glass(P, cut(fx, fy, fw, fh, br=16), opacity=0.62)
    P.add(f'<rect x="{fx + 10}" y="{fy + 10}" width="{fw - 20}" height="{fh - 20}" fill="url(#hatchA)" fill-opacity="0.16"/>')
    a_brackets(P, fx + 10, fy + 10, fw - 20, fh - 20, 14, A["amber"], width=1.2)
    a_ticks(P, fx + 30, fy + fh - 22, fw - 60, 40, 5, A["grey"], A["dim"])
    P.text(fx + fw / 2, fy + fh / 2 - 6, "KEY ART", 22, "ExtB", A["ivory"], anchor="middle", spacing=3)
    P.text(fx + fw / 2, fy + fh / 2 + 18, "ROOK, TO BE PAINTED", 14, "Mono", A["grey"], anchor="middle", spacing=1)
    P.text(w - 30, h - 52, "ROOK", 34, "ExtB", A["ivory"], anchor="end", spacing=3, extra=SHADE)
    P.text(w - 30, h - 28, "LEAD  ·  LV 26  ·  WARRIOR  ·  FIRE", 14, "Mono", A["amber"], anchor="end", spacing=0.6, extra=SHADE)
    # the column
    a_glass(P, rect(0, 0, cw, h), opacity=0.8, lit_top=False)
    P.add(f'<rect x="{cw - 1}" y="0" width="1" height="{h}" fill="{A["amber"]}" fill-opacity="0.7"/>')
    x = 30
    P.text(x, 38, "HOME", 20, "ExtB", A["ivory"], spacing=2.5)
    P.text(cw - 22, 37, "CLOSE", 14, "Mono", A["grey"], anchor="end", spacing=1.2)
    y = 78
    P.text(x, y, "POWER", 14, "Mono", A["grey"], spacing=1.4)
    P.text(x + 120, y, "BATTERY", 14, "Mono", A["grey"], spacing=1.4)
    P.text(x, y + 30, "10", 30, "MonoB", A["ivory"])
    P.text(x + 40, y + 30, "/ 91 kW", 14, "Mono", A["grey"])
    P.text(x + 120, y + 30, "FULL", 30, "MonoB", A["ivory"])
    a_bar(P, x, y + 40, 100, 3, 10 / 91, A["amber"], A["dim"])
    a_ticks(P, x, y + 45, 100, 10, 5, A["grey"], A["dim"])
    a_bar(P, x + 120, y + 40, 100, 3, 1.0, A["amber"], A["dim"])
    a_ticks(P, x + 120, y + 45, 100, 10, 5, A["grey"], A["dim"])
    P.text(x, y + 84, "CREDITS", 14, "Mono", A["grey"], spacing=1.4)
    P.text(x + 100, y + 84, "72,546", 18, "MonoB", A["ivory"])
    top = 200
    a_rail(P, [(x - 16, top - 12), (x - 16, top + 4 * 56 - 18)], 0.12)
    pages = [("01", "VOIDKIN", "4 OWNED"), ("02", "EQUIPMENT", "REINFORCE · JEWELS"), ("03", "TODAY", "1 OF 3 DONE"),
             ("04", "SETTINGS", "SOUND · EFFECTS")]
    for i, (k, name, read) in enumerate(pages):
        y = top + i * 56
        on = i == 0
        if on:
            P.add(f'<rect x="{x - 6}" y="{y - 4}" width="{cw - x - 14}" height="48" fill="{A["amber"]}" fill-opacity="0.12"/>'
                  f'<rect x="{x - 6}" y="{y - 4}" width="2" height="48" fill="{A["amber"]}"/>')
        a_node(P, x - 16, y + 16, lit=on)
        P.text(x + 8, y + 21, k, 14, "Mono", A["amber"] if on else A["grey"])
        P.text(x + 38, y + 22, name, 18, "ExtB", A["ivory"], spacing=1.4)
        P.text(x + 38, y + 39, read, 14, "Mono", A["grey"], spacing=0.4)


def a_states(P, x, y):
    for i, c in enumerate(TIERS):
        skull(P, x + i * 24, y, 16, c)
    for i, t in enumerate(RING):
        gem(P, x + 116 + i * 22, y + 8, 15, TYPES[t], rim=A["outline"])
    blade(P, x + 236, y + 8, 17, A["ivory"])
    arrow(P, x + 262, y + 8, 15, True, A["amber_hi"])
    arrow(P, x + 284, y + 8, 15, False, A["red"])


def a_tokens(P):
    tokens(P, "A, Console: the player's own yard system", A["glass"], A["ivory"],
           [("Amber", A["amber"]), ("Amber lit", A["amber_hi"]), ("Graphite", A["glass"]), ("Graphite 2", A["glass2"]),
            ("Ivory", A["ivory"]), ("Grey", A["grey"]), ("Health", A["red"])],
           [("Builder Mono Bold 15", "MonoB", 15, "ROOK   LV 26   AUTO"), ("Builder Mono 14 and 18", "Mono", 18, "3,682 / 3,732 · 10 / 91 kW"),
            ("Builder Extended Bold 18 to 34, titles", "ExtB", 22, "VOIDKIN")],
           "Lines: the live line 1 pt with 0.8 pt ticks every 4; the lock's brackets 1.2 pt; bars 3 pt; glass panes, one cut corner.",
           "Motion: a pulse runs along the live line to what changed, then the reading settles; the dial's ticks fill.",
           a_motif, a_states)


def a_motif(P, x, y):
    a_glass(P, cut(x, y, 220, 52, br=10))
    a_bar(P, x + 12, y + 18, 196, 3, 0.62, A["red"], A["red_track"])
    a_ticks(P, x + 12, y + 23, 196, 20, 5, A["grey"], A["dim"])
    a_rail(P, [(x, y + 70), (x + 220, y + 70)], 0.6)


# ---- B, Shard ---------------------------------------------------------------------------------------------------------
REFRACT = ((3.5, 2.5, 1.05, -0.06), (-3.0, 3.0, 0.97, 0.07), (4.0, -2.0, 1.07, -0.02), (-2.5, -3.0, 1.0, 0.11))


def b_lit(P, pts, width=1.6, glint=0.45):
    """The one lit edge where the light catches: white along the cut, a faint rose and cyan split either side of it,
    and a glint on it."""
    x0, y0 = pts[0]
    x1, y1 = pts[-1]
    gid = P.uid("g")
    P.defs.append(f'<linearGradient id="{gid}" gradientUnits="userSpaceOnUse" x1="{x0:.2f}" y1="{y0:.2f}" x2="{x1:.2f}" '
                  f'y2="{y1:.2f}"><stop offset="0" stop-color="{B["ice_hi"]}" stop-opacity="0.35"/><stop offset="{glint}" '
                  f'stop-color="#FFFFFF"/><stop offset="1" stop-color="{B["ice_hi"]}" stop-opacity="0.45"/></linearGradient>')
    pl = " ".join(f"{x:.2f},{y:.2f}" for x, y in pts)
    P.add(f'<polyline points="{pl}" fill="none" stroke="#FF9FBC" stroke-opacity="0.5" stroke-width="0.8" '
          f'transform="translate(-0.9,-0.7)" stroke-linejoin="round"/>'
          f'<polyline points="{pl}" fill="none" stroke="#7FE0FF" stroke-opacity="0.6" stroke-width="0.8" '
          f'transform="translate(0.8,0.7)" stroke-linejoin="round"/>'
          f'<polyline points="{pl}" fill="none" stroke="url(#{gid})" stroke-width="{width}" stroke-linejoin="round" stroke-linecap="round"/>')
    if glint:
        seg = [math.dist(a, b) for a, b in zip(pts, pts[1:])]
        at = glint * sum(seg)
        for (a, b), L in zip(zip(pts, pts[1:]), seg):
            if at <= L:
                gx, gy = a[0] + (b[0] - a[0]) * at / L, a[1] + (b[1] - a[1]) * at / L
                P.add(f'<circle cx="{gx:.2f}" cy="{gy:.2f}" r="4" fill="#FFFFFF" fill-opacity="0.75" filter="url(#soft)"/>'
                      f'<path d="M {gx - 6:.2f},{gy:.2f} L {gx + 6:.2f},{gy:.2f} M {gx:.2f},{gy - 4.5:.2f} L {gx:.2f},{gy + 4.5:.2f}" '
                      f'stroke="#FFFFFF" stroke-width="0.9"/>')
                break
            at -= L


def b_glass(P, pts, cuts=(), facets=None, lit=None, opacity=0.56, tint=None, seed=0, glint=0.45):
    """A shard of pale glass: cut at break angles into facets, each bending the world behind it its own way and lit
    its own amount; bright seams between the facets; the glass's thickness along its lower cut; one lit edge."""
    d = poly(pts)
    P.add(f'<path d="{d}" fill="#2B4456" fill-opacity="0.22" transform="translate(0.5,2.4)" filter="url(#soft)"/>')
    P.add(f'<path d="{d}" fill="none" stroke="#56778C" stroke-opacity="0.55" stroke-width="1.4" transform="translate(0,1.4)"/>')
    fs = facets or [pts]
    if not facets:
        for a, b in cuts:
            fs = [g for f in fs for g in split(f, a, b)]
    for i, f in enumerate(fs):
        dx, dy, z, dop = REFRACT[(i + seed) % len(REFRACT)]
        fd = poly(f)
        P.world(fd, 2.5, shift=(dx, dy), zoom=z, centre=centroid(f))
        P.add(f'<path d="{fd}" fill="{tint or B["glass"]}" fill-opacity="{opacity + dop:.2f}"/>')
    P.add(f'<path d="{poly(fs[0])}" fill="{P.lin(("#FFFFFF", "#FFFFFF"), x2=1, y2=1, opacities=(0.42, 0.0))}"/>')
    cid = P.clip(d)
    seams = "".join(f'<path d="{poly(f)}" fill="none" stroke="#FFFFFF" stroke-opacity="0.7" stroke-width="0.8"/>'
                    f'<path d="{poly(f)}" fill="none" stroke="#6F8DA1" stroke-opacity="0.35" stroke-width="0.7" '
                    f'transform="translate(0.8,0.8)"/>' for f in fs) if len(fs) > 1 else ""
    P.add(f'<g clip-path="url(#{cid})">{seams}</g>')
    P.add(f'<path d="{d}" fill="none" stroke="{B["line"]}" stroke-opacity="0.8" stroke-width="0.8" stroke-linejoin="round"/>')
    if lit:
        b_lit(P, lit, glint=glint)


def b_bar(P, x, y, w, h, share, fill, track):
    s = h * 0.9
    P.add(f'<path d="{poly([(x + s, y), (x + w, y), (x + w - s, y + h), (x, y + h)])}" fill="{track}"/>')
    fw = max(w * share, 2 * s)
    P.add(f'<path d="{poly([(x + s, y), (x + fw, y), (x + fw - s, y + h), (x, y + h)])}" fill="{fill}"/>')


def b_along(pts, share):
    """The first `share` of a polyline's length."""
    seg = [math.dist(a, b) for a, b in zip(pts, pts[1:])]
    left = share * sum(seg)
    res = [pts[0]]
    for (a, b), d in zip(zip(pts, pts[1:]), seg):
        if left >= d:
            res.append(b)
            left -= d
        else:
            k = left / d
            res.append((a[0] + (b[0] - a[0]) * k, a[1] + (b[1] - a[1]) * k))
            break
    return res


def b_sweep(P, x0, y0, x1, y1):
    """B's stroke behind a critical: a long splinter of the glass, lit along its top."""
    dx, dy = x1 - x0, y1 - y0
    L = math.hypot(dx, dy)
    nx, ny = -dy / L, dx / L
    pts = [(x0, y0), (x1, y1), (x1 - dx * 0.35 - nx * 9, y1 - dy * 0.35 - ny * 9), (x0 + dx * 0.1 - nx * 5, y0 + dy * 0.1 - ny * 5)]
    P.add(f'<path d="{poly(pts)}" fill="{B["ice"]}" fill-opacity="0.55"/>')
    b_lit(P, [pts[0], pts[1]], width=1.4, glint=0.8)


def b_fight(P, charge=1.0):
    w, h = P.w, P.h
    # the lead's card: a shard, the portrait over a facet in its own hue
    lp = [(60, 8), (232, 4), (224, 38), (240, 60), (70, 70), (54, 38)]
    b_glass(P, lp, cuts=[((170, -4), (148, 80)), ((246, 28), (194, 84))], lit=[lp[5], lp[0], lp[1]])
    P.hud(6, 4, 234, 66)
    fct = [(14, 18), (50, 6), (64, 44), (36, 68), (8, 52)]
    P.add(f'<path d="{poly(fct)}" fill="{B["rook"]}" fill-opacity="0.88"/>'
          f'<path d="{poly([(14, 18), (50, 6), (38, 36)])}" fill="#FFFFFF" fill-opacity="0.16"/>')
    b_lit(P, [fct[4], fct[0], fct[1]], width=1.2, glint=0)
    bust(P, 6, 4, 60)
    tx = 76
    P.text(tx, 25, LEAD["name"], 16, "MontB", B["ink"], spacing=0.4)
    gem(P, tx + 52, 20, 11, TYPES[LEAD["type"]], rim=B["ink"], width=0.7)
    blade(P, tx + 66, 20, 12, B["ink"])
    P.text(tx + 78, 25, f"Lv {LEAD['level']}", 14, "Mont", B["grey"])
    share = LEAD["hp"] / LEAD["max"]
    b_bar(P, tx, 31, 138, 4.5, share, B["red"], B["red_track"])
    b_bar(P, tx, 38.5, 134, 2, LEAD["xp"], B["ice_lo"], B["red_track"])        # experience
    P.text(tx, 57, f"{LEAD['hp']:,} / {LEAD['max']:,}", 14, "Mont", B["ink"])
    # the eye
    ex, ey = 252, 12
    ept = [(ex + 6, ey), (ex + 28, ey + 2), (ex + 23, ey + 26), (ex, ey + 24)]
    b_glass(P, ept, cuts=[((ex + 22, ey - 2), (ex + 8, ey + 30))], lit=[ept[3], ept[0], ept[1]], glint=0)
    P.hud(ex, ey, 28, 26)
    P.add(f'<path d="M {ex + 6},{ey + 13} Q {ex + 14},{ey + 5} {ex + 22},{ey + 13} Q {ex + 14},{ey + 21} {ex + 6},{ey + 13} Z" '
          f'fill="none" stroke="{B["ink"]}" stroke-width="1.2"/><circle cx="{ex + 14}" cy="{ey + 13}" r="2.4" fill="{B["ink"]}"/>')
    # the foe: a shard over its head in the world, pointing at it
    hx, hy = head(w, h)
    tw, th = (168 if edge(LEAD["type"], FOE["type"]) else 156), 38
    tx0, ty0 = hx - tw / 2, hy - 0.06 * h - th - 8
    tp = [(tx0 + 10, ty0), (tx0 + tw, ty0 + 3), (tx0 + tw - 9, ty0 + th), (hx + 6, ty0 + th), (hx, ty0 + th + 7),
          (hx - 6, ty0 + th), (tx0 + 3, ty0 + th - 2), (tx0 - 2, ty0 + 15)]
    b_glass(P, tp, cuts=[((tx0 + tw * 0.66, ty0 - 4), (tx0 + tw * 0.52, ty0 + th + 4))], lit=[tp[7], tp[0], tp[1]], seed=1)
    P.hud(tx0, ty0, tw, th)
    tier = TIERS[FOE["tier"]]
    chip = [(tx0 + 5, ty0 + 5), (tx0 + 64, ty0 + 3), (tx0 + 60, ty0 + 21), (tx0 + 2, ty0 + 22)]
    P.add(f'<path d="{poly(chip)}" fill="{B["ink"]}" fill-opacity="0.86"/>')
    b_lit(P, [chip[3], chip[0], chip[1]], width=1, glint=0)
    skull(P, tx0 + 9, ty0 + 6.5, 12.5, tier)
    P.text(tx0 + 25, ty0 + 18, f"Lv {FOE['level']}", 14, "MontB", tier)
    P.text(tx0 + 70, ty0 + 18, FOE["name"], 14, "MontB", B["ink"])
    gem(P, tx0 + 143, ty0 + 13, 11, TYPES[FOE["type"]], rim=B["ink"], width=0.7)
    e = edge(LEAD["type"], FOE["type"])
    if e:
        arrow(P, tx0 + 156, ty0 + 13, 10, e > 0, B["up"] if e > 0 else B["red"])
    b_bar(P, tx0 + 8, ty0 + 26, tw - 24, 4, FOE["hp"] / FOE["max"], B["red"], B["red_track"])
    # the press: a shard with a long point, facets fanning from a point off its centre; its edge lights round it as
    # it fills; the skill's art in its heart (a labelled slot)
    cx, cy, r = PRESS
    full = charge >= 1
    sp = [(cx + 4, cy - 42), (cx + 31, cy - 9), (cx + 25, cy + 27), (cx - 10, cy + 36), (cx - 33, cy + 9), (cx - 24, cy - 21)]
    o = (cx + 3, cy + 1)
    fans = [[o, sp[i], sp[(i + 1) % len(sp)]] for i in range(len(sp))]
    if full:
        P.add(f'<path d="{poly(sp)}" fill="{B["ice"]}" fill-opacity="0.55" filter="url(#glow)"/>')
    b_glass(P, sp, facets=fans, opacity=0.5 if full else 0.6)
    ring = sp + sp[:1]
    P.add(f'<polyline points="{" ".join(f"{x:.2f},{y:.2f}" for x, y in ring)}" fill="none" stroke="{B["line"]}" '
          f'stroke-width="1" stroke-linejoin="round"/>')
    b_lit(P, b_along(ring, charge), width=1.8 if full else 1.5, glint=0.3 if full else 0)
    P.text(cx + 2, cy - 1, "Skill", 14, "MontB", B["ink"], anchor="middle", opacity=0.85 if full else 0.6)
    P.text(cx + 2, cy + 14, "art", 14, "MontB", B["ink"], anchor="middle", opacity=0.85 if full else 0.6)
    P.text(cx, cy + r + 21, SKILL if full else f"{round(charge * 100)}%", 14, "Mont", B["grey"], anchor="middle",
           extra=' filter="url(#frostword)"')
    # Auto
    ax, ay, aw, ah = cx + r + 12, cy - 12, 66, 24
    apt = [(ax + 6, ay), (ax + aw, ay + 2), (ax + aw - 6, ay + ah), (ax, ay + ah - 2)]
    b_glass(P, apt, cuts=[((ax + aw * 0.7, ay - 2), (ax + aw * 0.58, ay + ah + 2))], lit=[apt[3], apt[0], apt[1]], glint=0)
    P.hud(ax, ay, aw, ah)
    P.add(f'<path d="{poly([(ax + 12, ay + 6), (ax + 17, ay + 12), (ax + 12, ay + 18), (ax + 7, ay + 12)])}" fill="{B["ice_lo"]}"/>')
    P.text(ax + 23, ay + 17, "Auto", 14, "MontB", B["ink"])
    numbers(P, dict(kind="B", face="MontK", crit_face="MontK", plain=B["ice_hi"], ink=B["ink"], width=2.2,
                    crit_ink="#2A1A08", crit_width=2.4, spacing=1.4), b_sweep, number_anchor(w, h), (tx + 138 * share, 16))


def b_home(P):
    w, h = P.w, P.h
    # the lead in a large facet window: its key art (a labelled frame, to be painted) behind a facet in its own hue
    win = [(36, 36), (304, 22), (338, 318), (294, 448), (26, 444), (22, 190)]
    b_glass(P, win, cuts=[((200, 0), (120, 470)), ((0, 300), (360, 250))], lit=[win[5], win[0], win[1]], opacity=0.62)
    inner = [(58, 58), (290, 46), (316, 290), (52, 336), (42, 190)]
    P.add(f'<path d="{poly(inner)}" fill="{P.lin((B["rook"], "#9A3530"), x2=0.4, y2=1)}" fill-opacity="0.3"/>'
          f'<path d="{poly(inner)}" fill="none" stroke="#FFFFFF" stroke-opacity="0.7" stroke-width="1" stroke-dasharray="6 5"/>')
    P.text(180, 186, "KEY ART", 22, "Mich", B["ink"], anchor="middle", spacing=3)
    P.text(180, 210, "Rook, to be painted", 14, "Mont", B["ink"], anchor="middle", opacity=0.8)
    P.text(50, 392, "ROOK", 28, "Mich", B["ink"], spacing=3)
    P.text(52, 418, "Lead · Lv 26 · Warrior · Fire", 14, "Mont", B["grey"])
    pages = [("VOIDKIN", "4 owned"), ("EQUIPMENT", "Reinforce · Jewels · War Emblems"), ("TODAY", "1 of 3 done"),
             ("SETTINGS", "Sound · Effects")]
    x0 = 384
    for i, (name, sub) in enumerate(pages):
        on = i == 0
        y = 64 + i * 88
        pw = 330 - i * 10
        pts = [(x0 + 10 + i * 8, y), (x0 + pw, y + 4), (x0 + pw - 9, y + 60), (x0 + i * 8, y + 62)]
        b_glass(P, pts, cuts=[((x0 + pw * 0.72, y - 4), (x0 + pw * 0.62, y + 70))], lit=[pts[3], pts[0], pts[1]] if on else None,
                opacity=0.72 if on else 0.5, seed=i)
        if on:
            P.add(f'<polyline points="{pts[3][0]:.1f},{pts[3][1]:.1f} {pts[0][0]:.1f},{pts[0][1]:.1f}" stroke="{B["ice_lo"]}" stroke-width="3"/>')
        P.text(x0 + 26 + i * 8, y + 30, name, 18, "Mich", B["ink"], spacing=2)
        P.text(x0 + 26 + i * 8, y + 50, sub, 14, "Mont", B["grey"] if on else B["ink"], opacity=1 if on else 0.75)
    P.text(w - 28, 34, "Close", 14, "MontB", B["ink"], anchor="end")


def b_states(P, x, y):
    for i, c in enumerate(TIERS):
        skull(P, x + i * 24, y, 16, c, ink=B["ink"], width=1.6)
    for i, t in enumerate(RING):
        gem(P, x + 116 + i * 22, y + 8, 15, TYPES[t], rim=B["ink"], width=0.7)
    blade(P, x + 236, y + 8, 17, B["ink"])
    arrow(P, x + 262, y + 8, 15, True, B["up"])
    arrow(P, x + 284, y + 8, 15, False, B["red"])


def b_tokens(P):
    tokens(P, "B, Shard: the UI seen in the shard glass", "#DCE9EF", B["ink"],
           [("Ice", B["ice"]), ("Ice lit", B["ice_hi"]), ("Ice deep", B["ice_lo"]), ("Glass", B["glass"]),
            ("Ink", B["ink"]), ("Grey", B["grey"]), ("Health", B["red"]), ("A Voidkin's own", B["rook"])],
           [("Montserrat Bold 16", "MontB", 16, "Rook   Lv 26"), ("Montserrat Medium 14", "Mont", 14, "3,682 / 3,732 · Auto"),
            ("Michroma 22", "Mich", 22, "VOIDKIN")],
           "Lines: one lit edge 1.6 pt, split rose and cyan; seams 0.8 pt white; the cut 0.8 pt; the glass's thickness under it.",
           "Motion: a glint crosses a facet once when it changes; a pane settles in with a short slide along its cut.",
           b_motif, b_states)


def b_motif(P, x, y):
    pts = [(x + 10, y), (x + 220, y + 4), (x + 206, y + 46), (x + 120, y + 52), (x, y + 44)]
    b_glass(P, pts, cuts=[((x + 150, y - 4), (x + 128, y + 60))], lit=[pts[4], pts[0], pts[1]], opacity=0.8)
    b_bar(P, x + 16, y + 20, 180, 5, 0.7, B["red"], B["red_track"])


# ---- C, Episode -------------------------------------------------------------------------------------------------------
def c_band(P, x, y, w, h, tone=False):
    """A band laid with a brush over the scene: an ink stroke first, the paper laid over it a little up and left, so
    the ink shows at its lower edge; both edges drawn; the bristles' streaks in the paper; a screentone at its end."""
    end = x + w + 12
    ink = brush_path(x - 6, y + h / 2 + 1.8, end + 3, y + h / 2 + 0.6, h + 4.6, taper=(0.06, 0.93), wobble=0.05, steps=60,
                     floor=0.75)
    d = brush_path(x - 10, y + h / 2, end, y + h / 2 - 1, h, taper=(0.03, 0.94), wobble=0.03, steps=60, floor=0.84)
    P.add(f'<path d="{ink}" fill="{C["ink"]}" fill-opacity="0.9" filter="url(#roughInk)"/>')
    P.add(f'<path d="{d}" fill="{C["paper"]}" filter="url(#rough)"/>')
    mid = P.mask(d, "rough")
    P.add(f'<g mask="url(#{mid})"><rect x="{x - 14}" y="{y - 4}" width="{w + 34}" height="{h + 8}" filter="url(#bristle)" '
          f'opacity="0.16"/>')
    if tone:
        gid = P.uid("g")
        tm = P.uid("m")
        P.defs.append(f'<linearGradient id="{gid}" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" '
                      f'stop-opacity="0"/><stop offset="1" stop-color="#fff" stop-opacity="0.55"/></linearGradient>'
                      f'<mask id="{tm}" maskUnits="userSpaceOnUse" x="{x + w - 70}" y="{y - 4}" width="90" height="{h + 8}">'
                      f'<rect x="{x + w - 70}" y="{y - 4}" width="90" height="{h + 8}" fill="url(#{gid})"/></mask>')
        P.add(f'<rect x="{x + w - 70}" y="{y - 4}" width="90" height="{h + 8}" fill="url(#toneFine)" mask="url(#{tm})"/>')
    P.add("</g>")
    P.hud(x - 10, y, w + 26, h + 3)


def c_bar(P, x, y, w, h, share, fill):
    P.add(f'<rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="{h}" fill="url(#toneFine)" fill-opacity="0.35"/>')
    P.add(f'<rect x="{x:.2f}" y="{y:.2f}" width="{w * share:.2f}" height="{h}" fill="{fill}"/>')
    P.add(f'<rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="{h}" fill="none" stroke="{C["ink"]}" stroke-width="1"/>')


def c_sweep(P, x0, y0, x1, y1):
    """C's stroke behind a critical: one dry ink swipe of the brush."""
    P.add(f'<path d="{brush_path(x0, y0 + 2, x1, y1, 15, (0.05, 0.55), wobble=0.08, steps=50, floor=0.0)}" '
          f'fill="{C["ink"]}" fill-opacity="0.92" filter="url(#roughInk)"/>')
    brush_line(P, x0 + 20, y0 + 12, x1 - 10, y1 + 10, 3, C["cobalt"], taper=(0.1, 0.6))


def c_fight(P, charge=1.0):
    w, h = P.w, P.h
    lx, ly, lw, lh = 56, 12, 176, 54
    c_band(P, lx, ly, lw, lh, tone=True)
    bust(P, 6, 6, 58, ink=True)
    tx = 72
    P.text(tx, ly + 18, LEAD["name"].upper(), 14, "SrcB", C["ink"], spacing=3.2)
    gem(P, tx + 61, ly + 13, 11, TYPES[LEAD["type"]], rim=C["ink"], width=1)
    blade(P, tx + 75, ly + 13, 12, C["ink"])
    P.text(tx + 87, ly + 18, f"LV {LEAD['level']}", 14, "Src", C["grey"], spacing=1.2)
    bw = lw - (tx - lx) - 2
    share = LEAD["hp"] / LEAD["max"]
    c_bar(P, tx, ly + 25, bw, 5, share, C["red"])
    brush_line(P, tx, ly + 35, tx + bw * LEAD["xp"], ly + 35, 2.4, C["cobalt"])       # experience
    P.text(tx, ly + 50, f"{LEAD['hp']:,} / {LEAD['max']:,}", 14, "SrcS", C["ink"], spacing=0.6)
    # the eye
    ex, ey = lx + lw + 40, 16
    brush_arc(P, ex + 13, ey + 13, 12, -30, 300, 2.2, C["ink"])
    P.add(f'<circle cx="{ex + 13}" cy="{ey + 13}" r="11" fill="{C["paper"]}" fill-opacity="0.94"/>'
          f'<path d="M {ex + 6},{ey + 13} Q {ex + 13},{ey + 6.5} {ex + 20},{ey + 13} Q {ex + 13},{ey + 19.5} {ex + 6},{ey + 13} Z" '
          f'fill="none" stroke="{C["ink"]}" stroke-width="1.2"/><circle cx="{ex + 13}" cy="{ey + 13}" r="2.3" fill="{C["ink"]}"/>')
    P.hud(ex, ey, 26, 26)
    # the foe: a caption at its shoulder, like a show naming who's on screen, on a brush leader
    hx, hy = head(w, h)
    cw, ch = 160, 38
    cx0, cy0 = min(hx + 0.09 * w, w - cw - 30), hy - 0.11 * h
    brush_line(P, hx + 8, hy - 6, cx0 - 2, cy0 + 20, 1.8, C["ink"], taper=(0.4, 0.95))
    c_band(P, cx0, cy0, cw, ch)
    tier = TIERS[FOE["tier"]]
    P.add(f'<path d="{brush_path(cx0 - 4, cy0 + 10.5, cx0 + 58, cy0 + 9.5, 17, (0.04, 0.9), wobble=0.06, steps=40, floor=0.6)}" '
          f'fill="{C["ink"]}" fill-opacity="0.94" filter="url(#roughInk)"/>')
    skull(P, cx0 + 3, cy0 + 4, 13, tier)
    P.text(cx0 + 20, cy0 + 16, f"LV {FOE['level']}", 14, "SrcB", tier, spacing=1)
    P.text(cx0 + 66, cy0 + 16, FOE["name"].upper(), 14, "SrcB", C["ink"], spacing=2.4)
    gem(P, cx0 + cw - 4, cy0 + 11, 11, TYPES[FOE["type"]], rim=C["ink"], width=1)
    e = edge(LEAD["type"], FOE["type"])
    if e:
        arrow(P, cx0 + cw + 9, cy0 + 11, 10, e > 0, C["cobalt"] if e > 0 else C["red"], ink=C["ink"], width=1)
    c_bar(P, cx0 + 4, cy0 + 24, cw - 4, 5, FOE["hp"] / FOE["max"], C["red"])
    # the press: a brushed ring on paper, its tone, the skill's art in it (a labelled slot), the charge a cobalt
    # stroke round it
    cx, cy, r = PRESS
    P.add(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{C["paper"]}" fill-opacity="0.97" filter="url(#roughFine)"/>')
    cid = P.clip(circle(cx, cy, r - 3))
    P.add(f'<g clip-path="url(#{cid})"><rect x="{cx - r}" y="{cy - r}" width="{2 * r}" height="{2 * r}" fill="url(#tone)" '
          f'fill-opacity="0.3"/></g>')
    full = charge >= 1
    P.text(cx, cy - 2, "SKILL", 14, "SrcB", C["ink"], anchor="middle", spacing=2, opacity=0.8 if full else 0.55,
           extra=' filter="url(#paperword)"')
    P.text(cx, cy + 13, "ART", 14, "SrcB", C["ink"], anchor="middle", spacing=2, opacity=0.8 if full else 0.55,
           extra=' filter="url(#paperword)"')
    brush_arc(P, cx, cy, r, -20, 330, 3.4, C["ink"])
    brush_arc(P, cx, cy, r + 6, 0, 360 * charge, 3.0, C["cobalt"], taper=(0.04, 0.96) if full else (0.06, 0.99))
    word = SKILL.upper() if full else f"{round(charge * 100)}%"
    P.text(cx, cy + r + 22, word, 14, "SrcB", C["grey"] if full else C["ink"], anchor="middle", spacing=2 if full else 0.6,
           extra=' filter="url(#paperword)"')
    # Auto
    ax, ay = cx + r + 22, cy - 12
    c_band(P, ax, ay, 58, 26)
    P.add(f'<circle cx="{ax + 10}" cy="{ay + 13}" r="3.4" fill="{C["cobalt"]}"/>')
    P.text(ax + 19, ay + 18, "AUTO", 14, "SrcB", C["ink"], spacing=2)
    numbers(P, dict(kind="C", face="SrcB", crit_face="SrcB", plain=C["paper"], ink=C["ink"], width=3.4,
                    crit_ink=C["ink"], crit_width=5.4, spacing=1.6), c_sweep, number_anchor(w, h, left=True),
            (tx + bw * share, ly + 6))


def c_frame(P, pts, label, sub):
    """A labelled art frame, the panel a show's art would fill: inked with the brush, a screentone, its label."""
    P.add(f'<path d="{poly(pts)}" fill="{C["paper"]}"/>'
          f'<path d="{poly(pts)}" fill="url(#tone)" fill-opacity="0.32"/>')
    for a, b in zip(pts, pts[1:] + pts[:1]):
        brush_line(P, a[0], a[1], b[0], b[1], 3, C["ink"], taper=(0.04, 0.96))
    cx, cy = centroid(pts)
    P.text(cx, cy - 4, label, 14, "SrcB", C["ink"], anchor="middle", spacing=4, extra=' filter="url(#paperword)"')
    P.text(cx, cy + 16, sub, 14, "Src", C["grey"], anchor="middle", spacing=0.6, extra=' filter="url(#paperword)"')


def c_skill(P):
    """The skill's moment: a title card cuts in across the fight, then the frame is still again."""
    w, h = P.w, P.h
    band = [(0, h * 0.30), (w, h * 0.16), (w, h * 0.50), (0, h * 0.64)]
    P.add(f'<path d="{poly(band)}" fill="{C["ink"]}" fill-opacity="0.9" transform="translate(4,6)" filter="url(#roughInk)"/>')
    P.add(f'<path d="{poly(band)}" fill="{C["paper"]}" filter="url(#rough)"/>')
    mid = P.mask(poly(band), "rough")
    P.add(f'<g mask="url(#{mid})"><rect x="0" y="0" width="{w}" height="{h}" fill="url(#tone)" fill-opacity="0.2"/>'
          f'<g transform="rotate(-9.3 {w / 2:.1f} {h * 0.4:.1f})"><rect x="-40" y="{h * 0.1:.1f}" width="{w + 80}" height="{h * 0.6:.1f}" '
          f'filter="url(#bristle)" opacity="0.12"/></g>')
    for i in range(16):      # speed lines toward the card's left, ink
        y = h * 0.14 + i * h * 0.035
        brush_line(P, w * 0.42 + (i % 3) * 30, y + 10, w + 20, y - 26, 1.2 + (i % 4) * 0.5, C["ink"], opacity=0.5,
                   taper=(0.5, 0.98))
    P.add("</g>")
    c_frame(P, [(w * 0.60, h * 0.235), (w * 0.95, h * 0.18), (w * 0.95, h * 0.46), (w * 0.60, h * 0.52)],
            "KEY ART", "Haymaker, to be painted")
    brush_line(P, -10, h * 0.30, w + 10, h * 0.16 - 2, 4.5, C["ink"], taper=(0.02, 0.9))
    brush_line(P, -10, h * 0.64, w + 10, h * 0.50, 4.5, C["ink"], taper=(0.1, 0.98))
    brush_line(P, w * 0.05, h * 0.565, w * 0.52, h * 0.47, 7, C["cobalt"], taper=(0.05, 0.7))
    P.text(w * 0.06, h * 0.47, SKILL.upper(), 54, "Serif", C["ink"], spacing=4,
           extra=f' stroke="{C["ink"]}" stroke-width="0.9" transform="rotate(-9.3 {w * 0.06:.1f} {h * 0.47:.1f})"')


def c_home(P):
    w, h = P.w, P.h
    # an episode's title card: paper over the base, the lead's key art large at the right (a labelled frame), the
    # pages as its chapters
    pane = rect(22, 20, w - 44, h - 40)
    P.add(f'<path d="{pane}" fill="{C["ink"]}" fill-opacity="0.85" transform="translate(3,4)" filter="url(#roughInk)"/>')
    P.add(f'<path d="{pane}" fill="{C["paper"]}" filter="url(#rough)"/>')
    mid = P.mask(pane, "rough")
    P.add(f'<g mask="url(#{mid})"><rect x="0" y="0" width="{w}" height="{h}" filter="url(#bristle)" opacity="0.07"/></g>')
    c_frame(P, [(w * 0.50, 62), (w - 56, 50), (w - 62, h - 60), (w * 0.47, h - 50)], "KEY ART", "Rook, to be painted")
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
    P.text(w * 0.47 - 20, 58, "CLOSE", 14, "SrcB", C["ink"], anchor="end", spacing=3)


def c_states(P, x, y):
    for i, c in enumerate(TIERS):
        skull(P, x + i * 24, y, 16, c, ink=C["ink"], width=1.8)
    for i, t in enumerate(RING):
        gem(P, x + 116 + i * 22, y + 8, 15, TYPES[t], rim=C["ink"], width=1)
    blade(P, x + 236, y + 8, 17, C["ink"])
    arrow(P, x + 262, y + 8, 15, True, C["cobalt"], ink=C["ink"], width=1)
    arrow(P, x + 284, y + 8, 15, False, C["red"], ink=C["ink"], width=1)


def c_tokens(P):
    tokens(P, "C, Episode: the lead's own anime", C["paper"], C["ink"],
           [("Paper", C["paper"]), ("Ink", C["ink"]), ("Ink grey", C["grey"]), ("Cobalt", C["cobalt"]),
            ("Cobalt lit", C["cobalt_hi"]), ("Health", C["red"])],
           [("Source Sans Bold 14, tracked", "SrcB", 14, "ROOK · BRAWLER", 3.2),
            ("Source Sans Semibold 14", "SrcS", 14, "3,682 / 3,732 · LV 26"), ("Merriweather 34, the skill only", "Serif", 34, "Haymaker")],
           "Lines: brush strokes 2 to 5 pt with drawn edges; paper laid over ink; screentone dots 1.9 pt apart at 45 degrees.",
           "Motion: nearly silent in a fight; at the skill a title card cuts in for about a second, then the frame is still.",
           c_motif, c_states)


def c_motif(P, x, y):
    c_band(P, x + 10, y, 196, 40, tone=True)
    brush_line(P, x, y + 62, x + 160, y + 60, 3, C["cobalt"], taper=(0.05, 0.75))


# ---- the token strip ----------------------------------------------------------------------------------------------------
def tokens(P, title, ground, ink, swatches, faces, lines, motion, motif, states):
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
    P.text(24, 368, "States: the skull by tier, the type gems, the class mark, the type edge", 14,
           "Src", ink, opacity=0.6)
    states(P, 540, 354)
    motif(P, P.w - 260, 168)


# ---- the output ---------------------------------------------------------------------------------------------------------
def faces_css():
    return "".join(f'@font-face{{font-family:"{fam}";src:url("{(sf.FONTS / file).as_uri()}")}}' for fam, file in FACES.items())


def shoot(P, path, scale=2):
    html = (f'<!doctype html><html><head><meta charset="utf-8"><style>{faces_css()} html,body{{margin:0;background:#000}}'
            f' svg{{display:block}}</style></head><body>{P.svg()}</body></html>')
    sf.shoot(html, path, P.w, P.h, scale=scale)


DRAW = {"A": (a_fight, a_home, a_tokens), "B": (b_fight, b_home, b_tokens), "C": (c_fight, c_home, c_tokens)}


def main():
    dest = Path(sys.argv[1]).resolve()
    keys = [k for k in sys.argv[2:] if k in DRAW] or list(DRAW)
    dest.mkdir(parents=True, exist_ok=True)
    for k in keys:
        fight, home, tok = DRAW[k]
        for w, h in ((W, H), (SW, SH)):
            P = Page(w, h, FIGHT[w])
            fight(P, charge=1.0 if w == W else 0.62)       # ready at 852, filling at the smallest phone
            shoot(P, dest / f"fight_{k}_{w}.png")
            area = sum(bw * bh for _, _, bw, bh in P.boxes) / (w * h)
            least = min(P.sizes)
            print(f"{k} at {w}: the permanent HUD {area:.1%} of the screen; the smallest word {least[0]} pt ({least[1]!r})")
        P = Page(W, H, BASE)
        home(P)
        shoot(P, dest / f"home_{k}.png")
        print(f"{k} home: the smallest word {min(P.sizes)[0]} pt")
        P = Page(W, 400)
        tok(P)
        shoot(P, dest / f"tokens_{k}.png")
        if k == "C":
            P = Page(W, H, FIGHT[W])
            c_fight(P)
            c_skill(P)
            shoot(P, dest / "skill_C.png")
    if keys == list(DRAW):
        sheets(dest)
    print("drew AR68's targets:", ", ".join(keys))


def sheets(dest):
    """Today's game and the three at the smallest phone, 2x; the three homes."""
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(TODAY), "-i", str(dest / "fight_A_568.png"), "-i",
                    str(dest / "fight_B_568.png"), "-i", str(dest / "fight_C_568.png"), "-filter_complex",
                    "[0:v]scale=1136:630:force_original_aspect_ratio=decrease,pad=1136:630:(ow-iw)/2:(oh-ih)/2:color=0x15191F[t];"
                    "[t][1:v][2:v][3:v]xstack=inputs=4:layout=0_0|w0_0|0_h0|w0_h0:fill=0x15191F",
                    str(dest / "sheet_fight.png")], check=True)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(dest / "home_A.png"), "-i", str(dest / "home_B.png"), "-i",
                    str(dest / "home_C.png"), "-filter_complex",
                    "[0:v]scale=852:-1[a];[1:v]scale=852:-1[b];[2:v]scale=852:-1[c];[a][b][c]hstack=inputs=3",
                    str(dest / "sheet_home.png")], check=True)


if __name__ == "__main__":
    main()
