"""AR68, round 3: the four palette-and-style systems as fight specimens, on the smallest phone (568 x 315), each over
Lantern Row by day and at dusk. Gemini's cheap first step ("one fight-bar specimen per system over both bright daylight
and dusk Lantern Row captures ... before drawing full screens"; transcripts 2026-11-27_hud-palette.md and _hud-fourth.md
in build/scratch/quaestor/gemini/), drawn for research's brief on the director's word of about 03:35 ("the whole
palette of colors and style need to change make it premium and of high quality").

    py tools/ui/hud_systems.py <out> [P S M R] [--green]

The systems (Gemini's, as proposals; research's brief overrides):
- P, Porcelain Relay: precision ceramic and titanium instruments with brass, the base's grid reaching the grounds.
  Chamfered collars, never a pill (kept off hud_p1's rejected A).
- S, Smoked Prism: the fight read through a ground, anti-glare Void Shard lens. Lifted satin steel-quartz, cyan.
- M, Match-Card: the arena's fighter cards, in every ground (Festival Cut's palette, its fiction moved off the festival:
  the festival look stays in its ground). Ivory over slate, a 10-degree knife cut, persimmon.
- R, Resonance Sight (Gemini's fourth): no plates. Feathered scrims, sculpted bar troughs, an open viridian bracket.

The ally's health is red in all four (the director, 11-13, "the HP of the voidkin need to be red obviously"; 03:08 was on
C's shade); --green draws Gemini's emerald in P, S and M instead, for the A/B. Where red health would sit beside a blue
experience bar (the pair the director disagreed with at 03:08), experience takes the system's warm light.

The frame: a crop of our own Lantern Row captures (AR57, the same spot by day and at dusk, the Guards and Dashers in the
ring), standing in for Faber's clean real-fight capture at the phone box, which AR68's full frames wait for.
The data, the game's: Rook, Red, a Warrior, level 26, against an Orange Dasher, level 26 (Red beats Orange: the edge's
arrow is up). Every word 14 points or more. The press holds a labelled slot for the skill's own art.

Writes <out>/<X>_day.png, <X>_dusk.png (568 x 315 at 2x); sheet.png (today's game, then the four, day and dusk);
four_day.png and four_dusk.png (the four on one ground); corner.png (each system's lead and press at 2x, both grounds).
"""
import math
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import overhaul as ov  # noqa: E402
import style_frames as sf  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
CAPS = REPO / "build" / "captures" / "ar57"
GROUNDS = {"day": CAPS / "row_idle_player_day.jpg", "dusk": CAPS / "row_held_raise_and_tell_player_dusk.jpg"}
CROP = (1010, 560, 420, 0)          # w, h, x, y in the 1920 x 1069 captures: clear of today's HUD on every side
W, H = 568, 315
GREEN = "--green" in sys.argv

LEAD = dict(name="Rook", type="Red", level=26, hp=3682, max=3732, xp=0.38)
FOE = dict(name="Dasher", type="Orange", level=26, hp=2964, max=4290, tier=1)
SKILL = "Haymaker"
TYPES = ov.TYPES
TIERS4 = ("grey", "white", "yellow", "red")      # Config.Hud.Skulls: much weaker, even, stronger, much stronger

FACES = {"Osw": "Oswald-Regular.ttf", "OswB": "Oswald-Bold.ttf",
         "Tit": "TitilliumWeb-Regular.ttf", "TitB": "TitilliumWeb-Bold.ttf",
         "Sans": "BuilderSans-Medium.otf", "SansR": "BuilderSans-Regular.otf", "SansB": "BuilderSans-Bold.otf",
         "Ext": "BuilderExtended-SemiBold.otf", "ExtB": "BuilderExtended-Bold.otf",
         "Mono": "BuilderMono-Regular.otf", "MonoB": "BuilderMono-Bold.otf",
         "Mont": "Montserrat-Medium.ttf", "MontB": "Montserrat-Bold.ttf", "MontK": "Montserrat-Black.ttf"}

# ---- the systems' tokens (Gemini's hexes; the ally's health and, beside red, the experience are ours, above) ----------
P_ = dict(name="Porcelain Relay", plate="#F5F2EB", plate2="#EAE5DA", recess="#E4E0D6", ink="#293240", sub="#5E6978",
          hue="#C99232", hue_lit="#F2C96B", ally="#26B87A" if GREEN else "#D8394A", ally_lit="#7FE3B4" if GREEN else "#FF8A92",
          foe="#DC4452", foe2="#A8283A", xp="#4EA4DE" if GREEN else "#D9A441", taken="#E04F55",
          skulls=("#8E98A8", "#F2F4F8", "#F0C244", "#E63E4D"), cooling="#7D8898")
S_ = dict(name="Smoked Prism", glass="#38485E", glass2="#2D3B4E", recess="#222E3E", ink="#F3F7FC", sub="#A6B5C8",
          hue="#32B8EB", hue_lit="#8CE4FF", ally="#2FCC8E" if GREEN else "#EE4058", ally_lit="#9BF0C9" if GREEN else "#FF97A2",
          foe="#EC4D5C", foe2="#B8303F", xp="#E6C260", taken="#F2636B", bevel="#E8F4FC", rim="#1E2836",
          skulls=("#8A99AD", "#F3F7FC", "#F5CA4C", "#ED4252"), cooling="#5F7085")
M_ = dict(name="Match-Card", ivory="#F7F4EC", slate="#2C3340", ink="#222833", sub="#626B7A", join="#D8D2C6",
          hue="#E8622A", hue_lit="#FFA463", ally="#29C07E" if GREEN else "#E23B4E", ally_lit="#8EEBB9" if GREEN else "#FF8E98",
          foe="#CC3554", foe2="#93223A", xp="#56A8E4" if GREEN else "#F2C35A", taken="#E64E5A", shadow="#232934",
          skulls=("#8E96A4", "#F5F6F8", "#E8CE52", "#DC324D"), cooling="#707A88")
R_ = dict(name="Resonance Sight", ink="#F6F4EE", sub="#B8C3D2", trough="#263142", scrim="#1C2432", deep="#141B26",
          hue="#22CCA0", hue_lit="#8EFFDF", ally="#F04256", ally_lit="#FF8790", foe="#E3682B", foe2="#C93828",
          xp="#E8CE82", taken="#FF646E", skulls=("#8C97A8", "#F4F6FA", "#F2C94C", "#F0384C"), cooling="#5D6B7E")


# ---- the page --------------------------------------------------------------------------------------------------------
def plate(ground):
    out = REPO / "build" / "scratch" / "modulo" / "ar68r3" / "plates" / f"{ground}.png"
    if not out.exists():
        out.parent.mkdir(parents=True, exist_ok=True)
        w, h, x, y = CROP
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(GROUNDS[ground]), "-vf",
                        f"crop={w}:{h}:{x}:{y},scale={2 * W}:{2 * H}:flags=lanczos", str(out)], check=True)
    return out


class Page(ov.Page):
    def __init__(self, ground):
        super().__init__(W, H, plate(ground))
        self.ground = ground
        self.defs += [
            '<filter id="lift" x="-30%" y="-60%" width="160%" height="220%"><feDropShadow dx="0" dy="1" stdDeviation="1.2" '
            'flood-color="#0E131B" flood-opacity="0.5"/></filter>',
            '<filter id="cel" x="-10%" y="-30%" width="130%" height="170%"><feDropShadow dx="2.2" dy="2.2" stdDeviation="0" '
            f'flood-color="{M_["shadow"]}" flood-opacity="0.34"/></filter>',
            '<filter id="contact" x="-10%" y="-30%" width="130%" height="170%"><feDropShadow dx="0" dy="2.4" stdDeviation="1.6" '
            'flood-color="#1F2733" flood-opacity="0.24"/></filter>',
            '<filter id="drop" x="-20%" y="-40%" width="140%" height="190%"><feDropShadow dx="0" dy="3" stdDeviation="3" '
            'flood-color="#182230" flood-opacity="0.34"/></filter>',
            '<filter id="bloom" x="-80%" y="-80%" width="260%" height="260%"><feGaussianBlur stdDeviation="2.4"/></filter>',
            '<filter id="tooth" x="0" y="0" width="100%" height="100%" color-interpolation-filters="sRGB">'
            '<feTurbulence type="fractalNoise" baseFrequency="1.1" numOctaves="2" seed="9"/><feColorMatrix type="matrix" '
            'values="0 0 0 0 0.16  0 0 0 0 0.19  0 0 0 0 0.25  0 0 0 0.9 -0.42"/></filter>',
        ]

    def t(self, x, y, spans, anchor="start", extra=""):
        """A line of text in runs: each (text, size, face, fill[, spacing, dx]). Every size is counted for the 14 pt floor."""
        parts = []
        for s in spans:
            txt, size, face, fill = s[:4]
            sp = s[4] if len(s) > 4 else 0
            dx = s[5] if len(s) > 5 else 0
            self.sizes.append((size, txt))
            parts.append(f'<tspan font-family="{face}" font-size="{size}" fill="{fill}"'
                         + (f' letter-spacing="{sp}"' if sp else "") + (f' dx="{dx}"' if dx else "") + f'>{sf.esc(txt)}</tspan>')
        self.add(f'<text x="{x:.2f}" y="{y:.2f}" text-anchor="{anchor}"{extra}>{"".join(parts)}</text>')


poly, cut, rect, circle = ov.poly, ov.cut, ov.rect, ov.circle


def slant_rect(x, y, w, h, k=0.176):
    """A bar's fill with its right end cut at 10 degrees (k = tan 10)."""
    d = h * k
    return poly([(x, y), (x + w, y), (x + w - d, y + h), (x, y + h)])


def arc(cx, cy, r, a0, a1):
    """An arc's path, angles in degrees clockwise from the top."""
    def pt(a):
        a = math.radians(a)
        return cx + r * math.sin(a), cy - r * math.cos(a)
    (x0, y0), (x1, y1) = pt(a0), pt(a1)
    large = 1 if (a1 - a0) % 360 > 180 else 0
    return f"M {x0:.2f},{y0:.2f} A {r},{r} 0 {large} 1 {x1:.2f},{y1:.2f}"


def eye_icon(P, cx, cy, w, ink, pupil, sw=1.4):
    h = w * 0.42
    P.add(f'<path d="M {cx - w / 2:.2f},{cy:.2f} Q {cx:.2f},{cy - h:.2f} {cx + w / 2:.2f},{cy:.2f} Q {cx:.2f},{cy + h:.2f} '
          f'{cx - w / 2:.2f},{cy:.2f} Z" fill="none" stroke="{ink}" stroke-width="{sw}" stroke-linejoin="round"/>'
          f'<circle cx="{cx:.2f}" cy="{cy:.2f}" r="{w * 0.15:.2f}" fill="{pupil}"/>')


def bar(P, x, y, w, h, share, fill, lit, track, shade, catch, segments=0, seg_ink=None, tip=True):
    """A recessed trough and its fill: an inner shade at the trough's top, a catch light under its bottom, the fill topped
    by a specular filament, its end cut at 10 degrees; quarters marked on the foe's."""
    P.add(f'<rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="{h:.2f}" fill="{track}"/>'
          f'<rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="1" fill="{shade}"/>'
          f'<rect x="{x:.2f}" y="{y + h:.2f}" width="{w:.2f}" height="0.8" fill="{catch}"/>')
    fw = w * share
    if fw > 0:
        g = P.lin([lit, fill, fill], 0, 1)
        d = slant_rect(x, y, fw, h) if tip and share < 1 else rect(x, y, fw, h)
        P.add(f'<path d="{d}" fill="{g}"/><rect x="{x:.2f}" y="{y:.2f}" width="{max(fw - h * 0.18, 0):.2f}" height="1.3" '
              f'fill="#FFFFFF" fill-opacity="0.55"/>')
    for i in range(1, segments):
        sx = x + w * i / segments
        P.add(f'<rect x="{sx - 0.5:.2f}" y="{y:.2f}" width="1" height="{h:.2f}" fill="{seg_ink}" fill-opacity="0.85"/>')


def art_slot(P, cx, cy, r, ink, ground, opacity=1.0):
    """The skill's own art goes here: a labelled slot (research, 03:07)."""
    pid = P.uid("hatch")
    P.defs.append(f'<pattern id="{pid}" width="3.2" height="3.2" patternUnits="userSpaceOnUse" patternTransform="rotate(-35)">'
                  f'<rect width="0.7" height="3.2" fill="{ink}"/></pattern>')
    P.add(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{ground}"/>'
          f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="url(#{pid})" fill-opacity="{0.28 * opacity:.2f}"/>')
    P.t(cx, cy + 5, [("ART", 14, "TitB", ink, 1.2)], anchor="middle", extra=f' opacity="{0.75 * opacity:.2f}"')


def numbers(P, face, plain, ink, edge_w, crit_face, glint=None, slash=None, cel=False):
    """The damage numbers at the Dasher (docs/ui.md): the latest a critical in the director's gold (heavy, slanted,
    larger), the element's a beat behind in its colour, two plain ones before it, smaller and fading as they rise."""
    ax, ay = 372, 176                      # beside the struck Dasher's head in this crop
    shadow = ' filter="url(#cel)"' if cel else ' filter="url(#lift)"'

    def num(x, y, s, size, fill, f=face, w=edge_w, k=ink, op=1.0, sp=0.6):
        P.sizes.append((size, s))
        P.add(f'<text x="{x:.2f}" y="{y:.2f}" font-family="{f}" font-size="{size}" fill="{fill}" letter-spacing="{sp}" '
              f'stroke="{k}" stroke-width="{w}" stroke-linejoin="round" paint-order="stroke" opacity="{op}"{shadow}>{s}</text>')
    num(ax + 62, ay - 46, "565", 14, plain, op=0.5)
    num(ax + 40, ay - 26, "565", 16, plain, op=0.8)
    if slash:
        P.add(f'<path d="{poly([(ax - 8, ay - 9), (ax + 92, ay - 15), (ax + 94, ay - 11), (ax - 6, ay - 5)])}" fill="{slash}" '
              f'fill-opacity="0.85"/>')
    P.add(f'<g transform="translate({ax:.2f},{ay:.2f}) skewX(-10)">')
    num(0, 0, "1,130", 26, "url(#gold)", f=crit_face, w=edge_w + 0.4, k="#3A2000", sp=1.0)
    if glint:
        P.add(f'<path d="M 58,-21 L 63,-22.2 L 68,-21 L 63,-19.8 Z M 63,-26 L 64.2,-21 L 63,-16 L 61.8,-21 Z" fill="{glint}"/>')
    P.add("</g>")
    num(ax + 84, ay + 14, "98", 16, ov.FIRE)


# ---- P, Porcelain Relay ----------------------------------------------------------------------------------------------
def p_plate(P, d):
    """Ceramic: a 92% alabaster fill falling to its lower tone, a matte tooth, a 1 px lit top edge, the titanium collar
    with a 2 pt lower lip, a tight contact shadow; no blur."""
    T = P_
    g = P.lin([T["plate"], T["plate2"]], 0, 1)
    cid = P.clip(d)
    P.add(f'<path d="{d}" fill="{g}" fill-opacity="0.94" filter="url(#contact)"/>'
          f'<g clip-path="url(#{cid})"><rect x="0" y="0" width="{W}" height="{H}" filter="url(#tooth)" opacity="0.05"/></g>'
          f'<path d="{d}" fill="none" stroke="{T["ink"]}" stroke-width="1.5" stroke-linejoin="miter"/>')


def p_frame(P, charge):
    T = P_
    # the lead: a ceramic plate, chamfered at its lower right where the brass relay pin sits; the bust breaks its top
    x0, y0, x1, y1 = 34, 10, 200, 60
    d = cut(x0, y0, x1 - x0, y1 - y0, br=12)
    p_plate(P, d)
    P.add(f'<path d="M {x0 + 1:.2f},{y1 + 0.75:.2f} L {x1 - 12:.2f},{y1 + 0.75:.2f}" stroke="{T["ink"]}" stroke-width="2"/>'
          f'<path d="M {x0 + 1:.2f},{y0 + 1.2:.2f} L {x1 - 1:.2f},{y0 + 1.2:.2f}" stroke="#FFFFFF" stroke-width="1"/>'
          f'<path d="M {x1 - 10.5:.2f},{y1 - 1.5:.2f} L {x1 - 1.5:.2f},{y1 - 10.5:.2f}" stroke="{T["hue"]}" stroke-width="1.5"/>'
          f'<circle cx="{x1 - 6:.2f}" cy="{y1 - 6:.2f}" r="1.6" fill="{T["hue_lit"]}"/>')
    P.hud(8, 4, x1 - 4, y1 - 2)
    ov.bust(P, 6, 4, 50, fade=0.8)
    # the level: a titanium chip under the bust
    P.add(f'<path d="{cut(8, 44, 40, 17, tr=5)}" fill="{T["ink"]}"/>')
    P.t(28, 57.5, [("26", 14, "MonoB", T["hue_lit"])], anchor="middle")
    bx, bw = 62, 128
    ov.gem(P, bx + 5, 19.5, 11, TYPES[LEAD["type"]], rim=T["ink"], width=0.9)
    ov.blade(P, bx + 17, 19.5, 12, T["ink"])
    P.t(bx + 27, 24, [(LEAD["name"].upper(), 14, "SansB", T["ink"], 1.4)])
    P.t(bx + bw, 24.5, [("15", 15, "ExtB", T["taken"])], anchor="end")
    bar(P, bx, 28, bw, 7, LEAD["hp"] / LEAD["max"], T["ally"], T["ally_lit"], T["recess"], "#C9C3B6", "#FFFFFF")
    bar(P, bx, 37.5, bw, 2.2, LEAD["xp"], T["xp"], T["xp"], T["recess"], "#C9C3B6", "#FFFFFF", tip=False)
    P.t(bx, 55, [(f"{LEAD['hp']:,}", 14, "ExtB", T["ink"]), (f"/ {LEAD['max']:,}", 14, "Sans", T["sub"], 0, 4)])
    # the eye
    ex, ey = 214, 14
    d = cut(ex, ey, 30, 26, br=7)
    p_plate(P, d)
    P.hud(ex, ey, 30, 26)
    eye_icon(P, ex + 15, ey + 13, 17, T["ink"], T["hue"])
    # the foe: a slim ceramic tag at the top centre; the skull on a titanium chip
    fx, fy, fw = 258, 10, 170
    d = cut(fx, fy, fw, 34, br=9)
    p_plate(P, d)
    P.add(f'<path d="M {fx + 1},{fy + 1.2} L {fx + fw - 1},{fy + 1.2}" stroke="#FFFFFF" stroke-width="1"/>')
    P.hud(fx, fy, fw, 34)
    P.add(f'<path d="{cut(fx + 4, fy + 4, 22, 17, tr=4)}" fill="{T["ink"]}"/>')
    ov.skull(P, fx + 9, fy + 6.5, 12, T["skulls"][FOE["tier"]])
    P.t(fx + 32, fy + 18, [(str(FOE["level"]), 14, "MonoB", T["ink"]), (FOE["name"].upper(), 14, "SansB", T["ink"], 1.4, 7)])
    ov.gem(P, fx + fw - 30, fy + 12.5, 11, TYPES[FOE["type"]], rim=T["ink"], width=0.9)
    ov.arrow(P, fx + fw - 15, fy + 12.5, 10, True, T["hue"], ink=T["ink"], width=0.8)
    bar(P, fx + 4, fy + 24, fw - 16, 5, FOE["hp"] / FOE["max"], T["foe"], T["foe2"], T["recess"], "#C9C3B6", "#FFFFFF",
        segments=4, seg_ink=T["plate"])
    # the press: a ceramic disc in a titanium collar; brass fills round it; awake, the brass ring closes and glints
    cx, cy, r = 40, 136, 28
    full = charge >= 1
    p_plate(P, circle(cx, cy, r))
    P.add(f'<path d="{arc(cx, cy, r - 4.5, 0, 359.9 * charge)}" fill="none" stroke="{T["hue"]}" stroke-width="4" '
          f'stroke-linecap="butt"/>')
    if not full:
        P.add(f'<path d="{arc(cx, cy, r - 4.5, 359.9 * charge, 359.9)}" fill="none" stroke="{T["recess"]}" stroke-width="4"/>')
    else:
        P.add(f'<path d="{arc(cx, cy, r - 4.5, 300, 340)}" fill="none" stroke="#FFF4D6" stroke-width="1.4"/>')
    art_slot(P, cx, cy, r - 9, T["ink"], T["plate2"], opacity=1 if full else 0.6)
    P.add(f'<circle cx="{cx}" cy="{cy}" r="{r - 9}" fill="none" stroke="{T["ink"]}" stroke-width="1"/>')
    label = (SKILL.upper(), 14, "SansB", T["ink"], 1.2) if full else (f"{round(charge * 100)}%", 14, "MonoB", T["ink"])
    lw = 84 if full else 44
    P.add(f'<path d="{cut(78, 154, lw, 20, br=5)}" fill="{T["plate"]}" fill-opacity="0.94" '
          f'stroke="{T["ink"]}" stroke-width="1.2" filter="url(#contact)"/>')
    P.t(78 + lw / 2, 169, [label], anchor="middle")
    # Auto
    ax, ay = 78, 123
    p_plate(P, cut(ax, ay, 66, 26, br=7))
    P.hud(ax, ay, 66, 26)
    P.add(f'<rect x="{ax + 8}" y="{ay + 9}" width="8" height="8" fill="{T["hue"]}"/><rect x="{ax + 8}" y="{ay + 9}" '
          f'width="8" height="1.2" fill="{T["hue_lit"]}"/>')
    P.t(ax + 21, ay + 18, [("AUTO", 14, "SansB", T["ink"], 1)])
    numbers(P, "ExtB", T["plate"], T["ink"], 2.2, "ExtB", glint="#FFFFFF")


# ---- S, Smoked Prism -------------------------------------------------------------------------------------------------
def s_glass(P, d, x, y, w, h):
    """Smoked quartz: the world blurred behind it, an 84% satin gradient, a lit bevel top left tapering out, a dark rim
    at the bottom, a soft drop."""
    T = S_
    P.add(f'<path d="{d}" fill="#000" fill-opacity="0.001" filter="url(#drop)"/>')
    P.world(d, 5)
    g = P.lin([T["glass"], T["glass2"]], 0.3, 1)
    P.add(f'<path d="{d}" fill="{g}" fill-opacity="0.86"/>')
    gid = P.uid("g")
    P.defs.append(f'<linearGradient id="{gid}" gradientUnits="userSpaceOnUse" x1="{x}" y1="{y}" x2="{x + w}" y2="{y + h}">'
                  f'<stop offset="0" stop-color="{T["bevel"]}" stop-opacity="0.8"/><stop offset="0.45" stop-color="{T["bevel"]}" '
                  f'stop-opacity="0.18"/><stop offset="0.7" stop-color="{T["rim"]}" stop-opacity="0.4"/><stop offset="1" '
                  f'stop-color="{T["rim"]}" stop-opacity="0.7"/></linearGradient>')
    P.add(f'<path d="{d}" fill="none" stroke="url(#{gid})" stroke-width="1"/>')


def s_frame(P, charge):
    T = S_
    x0, y0, x1, y1 = 8, 8, 200, 60
    # the crease: 18 degrees, the portrait's side cut from the gauges'
    k = math.tan(math.radians(18))
    cx0 = 54
    d = poly([(x0, y0), (x1, y0), (x1, y1 - 8), (x1 - 8, y1), (x0, y1)])
    s_glass(P, d, x0, y0, x1 - x0, y1 - y0)
    P.hud(x0, y0, x1 - x0, y1 - y0)
    left = poly([(x0, y0), (cx0 + (y1 - y0) * k, y0), (cx0, y1), (x0, y1)])
    P.add(f'<path d="{left}" fill="{T["glass2"]}" fill-opacity="0.55"/>')
    ov.bust(P, 6, 6, 50, fade=0.8)
    P.add(f'<path d="M {cx0 + (y1 - y0) * k:.2f},{y0:.2f} L {cx0:.2f},{y1:.2f}" stroke="{T["bevel"]}" stroke-opacity="0.75" '
          f'stroke-width="1"/>')
    P.add(f'<path d="{poly([(x0, y1 - 15), (x0 + 36, y1 - 15), (x0 + 31, y1), (x0, y1)])}" fill="{T["recess"]}" fill-opacity="0.92"/>')
    P.t(x0 + 5, y1 - 2.5, [("LV", 14, "TitB", T["sub"]), ("26", 14, "TitB", T["ink"], 0, 2)])
    bx, bw = 70, 122
    ov.gem(P, bx + 5, 17.5, 11, TYPES[LEAD["type"]], rim=T["rim"], width=0.9)
    ov.blade(P, bx + 17, 17.5, 12, T["ink"])
    P.t(bx + 27, 22.5, [(LEAD["name"], 15, "MontB", T["ink"], 0.4)])
    P.t(bx + bw, 22.5, [("15", 15, "MontB", T["taken"])], anchor="end",
        extra=f' stroke="{T["rim"]}" stroke-width="2" paint-order="stroke"')
    bar(P, bx, 27, bw, 7, LEAD["hp"] / LEAD["max"], T["ally"], T["ally_lit"], T["recess"], "#111925", T["bevel"] + "55")
    bar(P, bx, 36.5, bw, 2.2, LEAD["xp"], T["xp"], T["xp"], T["recess"], "#111925", "#00000000", tip=False)
    P.t(bx, 54, [(f"{LEAD['hp']:,}", 14, "MontB", T["ink"]), (f"/ {LEAD['max']:,}", 14, "Mont", T["sub"], 0, 4)])
    # the eye
    ex, ey = 214, 12
    d = poly([(ex, ey), (ex + 30, ey), (ex + 30, ey + 20), (ex + 24, ey + 26), (ex, ey + 26)])
    s_glass(P, d, ex, ey, 30, 26)
    P.hud(ex, ey, 30, 26)
    eye_icon(P, ex + 15, ey + 13, 17, T["ink"], T["hue"])
    # the foe
    fx, fy, fw = 258, 8, 170
    d = poly([(fx, fy), (fx + fw, fy), (fx + fw, fy + 28), (fx + fw - 8, fy + 36), (fx, fy + 36)])
    s_glass(P, d, fx, fy, fw, 36)
    P.hud(fx, fy, fw, 36)
    ov.skull(P, fx + 7, fy + 6, 13, T["skulls"][FOE["tier"]])
    P.t(fx + 25, fy + 18, [(str(FOE["level"]), 14, "TitB", T["skulls"][FOE["tier"]]),
                           (FOE["name"], 14, "MontB", T["ink"], 0.4, 6)])
    ov.gem(P, fx + fw - 30, fy + 13, 11, TYPES[FOE["type"]], rim=T["rim"], width=0.9)
    ov.arrow(P, fx + fw - 15, fy + 13, 10, True, T["hue_lit"], ink=T["rim"], width=0.8)
    bar(P, fx + 6, fy + 25, fw - 18, 5, FOE["hp"] / FOE["max"], T["foe"], T["foe2"], T["recess"], "#111925", "#00000000",
        segments=4, seg_ink=T["glass2"])
    # the press: a smoked disc; cyan runs round its rim as it fills, the crease's glint crosses it when it wakes
    cx, cy, r = 40, 136, 28
    full = charge >= 1
    s_glass(P, circle(cx, cy, r), cx - r, cy - r, 2 * r, 2 * r)
    if full:
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{r - 3}" fill="none" stroke="{T["hue"]}" stroke-width="3.2" filter="url(#bloom)" '
              f'opacity="0.8"/>')
    P.add(f'<path d="{arc(cx, cy, r - 3.5, 0, 359.9 * charge)}" fill="none" stroke="{T["hue_lit"] if full else T["hue"]}" '
          f'stroke-width="3"/>')
    art_slot(P, cx, cy, r - 9, T["ink"], T["recess"], opacity=1 if full else 0.55)
    if full:
        P.add(f'<path d="{poly([(cx - 6, cy - r + 6), (cx + 1, cy - r + 6), (cx - 9, cy + r - 6), (cx - 16, cy + r - 6)])}" '
              f'fill="#FFFFFF" fill-opacity="0.16"/>')
    label = (SKILL, 14, "MontB", T["ink"], 0.4) if full else (f"{round(charge * 100)}%", 14, "TitB", T["ink"])
    P.t(80, 168, [label], extra=f' stroke="{T["rim"]}" stroke-width="2.4" paint-order="stroke"')
    # Auto
    ax, ay = 78, 123
    d = poly([(ax, ay), (ax + 60, ay), (ax + 60, ay + 19), (ax + 53, ay + 26), (ax, ay + 26)])
    s_glass(P, d, ax, ay, 60, 26)
    P.hud(ax, ay, 60, 26)
    P.add(f'<circle cx="{ax + 12}" cy="{ay + 13}" r="3.6" fill="{T["hue_lit"]}"/><circle cx="{ax + 12}" cy="{ay + 13}" r="6" '
          f'fill="{T["hue"]}" fill-opacity="0.35" filter="url(#bloom)"/>')
    P.t(ax + 21, ay + 18, [("AUTO", 14, "TitB", T["ink"], 1)])
    numbers(P, "MontB", T["ink"], T["rim"], 2.4, "MontK", glint="#FFFFFF")


# ---- M, Match-Card ---------------------------------------------------------------------------------------------------
def m_card(P, x, y, w, top, bottom, stripe=True):
    """An ivory face 2 pt proud over a slate plinth, both ends knife-cut at 10 degrees, a crisp offset cel shadow, a
    hairline at the join, the persimmon leading stripe."""
    T = M_
    k = math.tan(math.radians(10))
    h = top + bottom
    whole = poly([(x + h * k, y), (x + w, y), (x + w - h * k, y + h), (x, y + h)])
    face = poly([(x + h * k, y), (x + w, y), (x + w - bottom * k, y + top), (x + bottom * k, y + top)])
    P.add(f'<path d="{whole}" fill="{T["slate"]}" fill-opacity="0.95" filter="url(#cel)"/>'
          f'<path d="{face}" fill="{T["ivory"]}"/>'
          f'<path d="M {x + bottom * k:.2f},{y + top:.2f} L {x + w - bottom * k:.2f},{y + top:.2f}" stroke="{T["join"]}" '
          f'stroke-width="1"/>')
    if stripe:
        P.add(f'<path d="{poly([(x + h * k, y), (x + h * k + 3, y), (x + 3, y + h), (x, y + h)])}" fill="{T["hue"]}"/>')
    return k


def m_frame(P, charge):
    T = M_
    x0, w0 = 30, 172
    k = m_card(P, x0, 10, w0, 20, 30)
    P.hud(8, 4, x0 + w0 - 4, 56)
    ov.bust(P, 6, 4, 50, fade=0.8)
    P.add(f'<path d="{poly([(10, 46), (44, 46), (41, 62), (7, 62)])}" fill="{T["hue"]}" filter="url(#cel)"/>')
    P.t(25, 59, [("26", 14, "OswB", T["ivory"], 0.4)], anchor="middle")
    bx, bw = 62, 128
    ov.gem(P, bx + 7, 20, 11, TYPES[LEAD["type"]], rim=T["ink"], width=0.9)
    ov.blade(P, bx + 19, 20, 12, T["ink"])
    P.t(bx + 29, 26, [(LEAD["name"].upper(), 16, "OswB", T["ink"], 1.0)])
    P.t(bx + bw + 2, 26, [("15", 16, "OswB", T["taken"])], anchor="end")
    bar(P, bx - 2, 34, bw, 7, LEAD["hp"] / LEAD["max"], T["ally"], T["ally_lit"], "#1C222C", "#12161D", "#3C4554")
    bar(P, bx - 3, 43.5, bw - 2, 2.2, LEAD["xp"], T["xp"], T["xp"], "#1C222C", "#12161D", "#00000000", tip=False)
    P.t(bx - 4, 59, [(f"{LEAD['hp']:,}", 14, "OswB", T["ivory"], 0.4), (f"/ {LEAD['max']:,}", 14, "Osw", "#AEB6C3", 0.4, 4)])
    # the eye
    ex, ey = 214, 14
    m_card(P, ex, ey, 32, 26, 0, stripe=False)
    P.hud(ex, ey, 32, 26)
    eye_icon(P, ex + 16, ey + 13, 17, T["ink"], T["hue"])
    # the foe
    fx, fy, fw = 258, 8, 170
    m_card(P, fx, fy, fw, 20, 15)
    P.hud(fx, fy, fw, 35)
    P.add(f'<path d="{poly([(fx + 7, fy + 2), (fx + 27, fy + 2), (fx + 24, fy + 18), (fx + 4, fy + 18)])}" fill="{T["slate"]}"/>')
    ov.skull(P, fx + 10, fy + 4, 12, T["skulls"][FOE["tier"]])
    P.t(fx + 31, fy + 16, [(str(FOE["level"]), 14, "OswB", T["ink"], 0.4), (FOE["name"].upper(), 14, "OswB", T["ink"], 1.0, 6)])
    ov.gem(P, fx + fw - 30, fy + 10.5, 11, TYPES[FOE["type"]], rim=T["ink"], width=0.9)
    ov.arrow(P, fx + fw - 16, fy + 10.5, 10, True, T["hue"], ink=T["ink"], width=0.8)
    bar(P, fx + 6, fy + 24, fw - 16, 6, FOE["hp"] / FOE["max"], T["foe"], T["foe2"], "#1C222C", "#12161D", "#00000000",
        segments=4, seg_ink=T["slate"])
    # the press: an ivory disc in a slate ring; persimmon fills round it; awake, its stripe snaps across
    cx, cy, r = 40, 136, 28
    full = charge >= 1
    P.add(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{T["slate"]}" filter="url(#cel)"/>')
    P.add(f'<path d="{arc(cx, cy, r - 3.5, 0, 359.9 * charge)}" fill="none" stroke="{T["hue"]}" stroke-width="4"/>')
    art_slot(P, cx, cy, r - 8, T["ink"], T["ivory"], opacity=1 if full else 0.55)
    if full:
        P.add(f'<path d="{poly([(cx - r - 4, cy + 12), (cx + r + 6, cy + 3), (cx + r + 6, cy + 6), (cx - r - 4, cy + 15)])}" '
              f'fill="{T["hue"]}" filter="url(#cel)"/>')
    lw = 86 if full else 44
    lx, ly = 78, 154
    P.add(f'<path d="{poly([(lx + 3, ly), (lx + lw, ly), (lx + lw - 3, ly + 18), (lx, ly + 18)])}" fill="{T["slate"]}" '
          f'filter="url(#cel)"/>')
    label = (SKILL.upper(), 14, "OswB", T["ivory"], 1.2) if full else (f"{round(charge * 100)}%", 14, "OswB", T["ivory"], 0.4)
    P.t(lx + lw / 2, ly + 14.5, [label], anchor="middle")
    # Auto
    ax, ay = 78, 123
    m_card(P, ax, ay, 62, 26, 0, stripe=False)
    P.hud(ax, ay, 62, 26)
    P.add(f'<path d="{poly([(ax + 12, ay + 8), (ax + 20, ay + 8), (ax + 18, ay + 18), (ax + 10, ay + 18)])}" fill="{T["hue"]}"/>')
    P.t(ax + 24, ay + 18.5, [("AUTO", 14, "OswB", T["ink"], 1.2)])
    numbers(P, "OswB", T["ivory"], T["ink"], 2.6, "OswB", cel=True)


# ---- R, Resonance Sight ----------------------------------------------------------------------------------------------
def r_scrim(P, x, y, w, h, feather=18, peak=0.42):
    """No plate: a scrim at 42% that feathers to nothing over 18 pt, no border, no blur, no grain."""
    T = R_
    mid = P.uid("m")
    fid = P.uid("f")
    P.defs.append(f'<filter id="{fid}" x="-50%" y="-80%" width="200%" height="260%"><feGaussianBlur stdDeviation="{feather / 2.4:.2f}"/></filter>'
                  f'<mask id="{mid}" maskUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}">'
                  f'<rect x="{x + feather / 2:.2f}" y="{y + feather / 2:.2f}" width="{w - feather:.2f}" height="{h - feather:.2f}" '
                  f'rx="{feather / 2:.2f}" fill="#fff" filter="url(#{fid})"/></mask>')
    P.add(f'<rect x="{x - feather:.2f}" y="{y - feather:.2f}" width="{w + 2 * feather:.2f}" height="{h + 2 * feather:.2f}" '
          f'fill="{T["scrim"]}" fill-opacity="{peak}" mask="url(#{mid})"/>')


def r_chip(P, d):
    T = R_
    P.add(f'<path d="{d}" fill="{T["trough"]}" fill-opacity="0.92" filter="url(#lift)"/>')


def r_frame(P, charge):
    T = R_
    r_scrim(P, 0, 0, 262, 74)
    r_scrim(P, 248, 0, 196, 50)
    r_scrim(P, 0, 96, 154, 108, peak=0.36)
    # the lead: the bust unboxed over a base chevron; the open bracket's arms frame its base
    P.hud(8, 6, 196, 54)
    ov.bust(P, 8, 4, 50, fade=0.85)
    P.add(f'<path d="M 6,56 L 6,62 L 22,62 M 40,62 L 56,62 L 56,56" fill="none" stroke="{T["hue"]}" stroke-width="1.5"/>')
    r_chip(P, cut(12, 49, 38, 17, tl=4, br=4))
    P.add(f'<rect x="13" y="49.6" width="36" height="0.8" fill="{T["ink"]}" fill-opacity="0.35"/>')
    P.t(31, 62, [("26", 14, "TitB", T["ink"], 0.6)], anchor="middle")
    bx, bw = 62, 132
    ov.gem(P, bx + 5, 16.5, 11, TYPES[LEAD["type"]], rim=T["deep"], width=0.9)
    ov.blade(P, bx + 17, 16.5, 12, T["ink"], ink=T["deep"], width=1)
    P.t(bx + 27, 22, [(LEAD["name"].upper(), 16, "OswB", T["ink"], 1.2)], extra=' filter="url(#lift)"')
    P.t(bx + bw, 22, [("15", 16, "ExtB", T["taken"])], anchor="end",
        extra=f' stroke="{T["deep"]}" stroke-width="1.5" paint-order="stroke"')
    bar(P, bx, 28, bw, 8, LEAD["hp"] / LEAD["max"], T["ally"], T["ally_lit"], T["trough"], T["deep"], T["ink"] + "47")
    bar(P, bx, 38.5, bw, 3, LEAD["xp"], T["xp"], T["xp"], T["trough"], T["deep"], "#00000000", tip=False)
    P.t(bx, 58, [(f"{LEAD['hp']:,}", 14, "ExtB", T["ink"]), (f"/ {LEAD['max']:,}", 14, "Tit", T["sub"], 0, 4)],
        extra=' filter="url(#lift)"')
    # the eye: an icon alone, its tap the size of a thumb
    P.hud(214, 12, 30, 26)
    eye_icon(P, 229, 25, 19, T["ink"], T["hue"], sw=1.6)
    # the foe: a header line and a bar on the scrim; the skull on its chip
    fx, fy, fw = 258, 8, 172
    P.hud(fx, fy, fw, 34)
    r_chip(P, cut(fx, fy + 1, 22, 18, tl=4, br=4))
    ov.skull(P, fx + 5, fy + 4.5, 12, T["skulls"][FOE["tier"]])
    P.t(fx + 28, fy + 16, [(str(FOE["level"]), 14, "TitB", T["skulls"][FOE["tier"]], 0.6),
                           (FOE["name"].upper(), 14, "OswB", T["ink"], 1.2, 6)], extra=' filter="url(#lift)"')
    ov.gem(P, fx + fw - 26, fy + 10.5, 11, TYPES[FOE["type"]], rim=T["deep"], width=0.9)
    ov.arrow(P, fx + fw - 11, fy + 10.5, 10, True, T["hue_lit"], ink=T["deep"], width=0.8)
    bar(P, fx, fy + 24, fw, 7, FOE["hp"] / FOE["max"], T["foe2"], T["foe"], T["trough"], T["deep"], "#00000000", segments=4,
        seg_ink=T["deep"])
    # the press: an open disc, a groove, viridian bevel clamped inside the rim; the bracket's arcs left open round it
    cx, cy, r = 40, 136, 28
    full = charge >= 1
    P.add(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{T["trough"]}" fill-opacity="0.8" filter="url(#drop)"/>'
          f'<circle cx="{cx}" cy="{cy}" r="{r - 5}" fill="none" stroke="#1B2432" stroke-width="3.5"/>')
    P.add(f'<path d="{arc(cx, cy, r - 5, 0, 359.9 * charge)}" fill="none" stroke="{T["hue"]}" stroke-width="3"/>')
    if full:
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{r - 1.2}" fill="none" stroke="{T["hue_lit"]}" stroke-width="1.6" opacity="0.9"/>')
    art_slot(P, cx, cy, r - 10, T["ink"], "#1B2432", opacity=1 if full else 0.55)
    for a0, a1 in ((200, 250), (290, 340)):
        P.add(f'<path d="{arc(cx, cy, r + 5, a0, a1)}" fill="none" stroke="{T["hue"]}" stroke-width="1.5"/>')
    label = (SKILL.upper(), 14, "OswB", T["ink"], 1.2) if full else (f"{round(charge * 100)}%", 14, "TitB", T["ink"], 0.6)
    P.t(82, 168, [label], extra=' filter="url(#lift)"')
    # Auto
    ax, ay = 80, 123
    P.hud(ax, ay, 60, 26)
    r_chip(P, cut(ax, ay, 60, 26, tl=5, br=5))
    P.add(f'<rect x="{ax + 1}" y="{ay + 0.6}" width="54" height="0.8" fill="{T["ink"]}" fill-opacity="0.35"/>'
          f'<circle cx="{ax + 12}" cy="{ay + 13}" r="3.4" fill="{T["hue_lit"]}"/>')
    P.t(ax + 21, ay + 18, [("AUTO", 14, "TitB", T["ink"], 0.6)])
    numbers(P, "ExtB", T["ink"], "#18202C", 1.5, "ExtB", glint="#FFF6C8", slash=T["trough"])


DRAW = {"P": (p_frame, P_), "S": (s_frame, S_), "M": (m_frame, M_), "R": (r_frame, R_)}


def faces_css():
    return "".join(f'@font-face{{font-family:"{fam}";src:url("{(sf.FONTS / file).as_uri()}")}}' for fam, file in FACES.items())


def shoot(P, path, scale=2):
    html = (f'<!doctype html><html><head><meta charset="utf-8"><style>{faces_css()} html,body{{margin:0;background:#000}}'
            f' svg{{display:block}}</style></head><body>{P.svg()}</body></html>')
    sf.shoot(html, path, P.w, P.h, scale=scale)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dest = Path(args[0]).resolve()
    keys = [k for k in args[1:] if k in DRAW] or list(DRAW)
    dest.mkdir(parents=True, exist_ok=True)
    for k in keys:
        draw, T = DRAW[k]
        for ground, charge in (("day", 1.0), ("dusk", 0.62)):       # awake by day, filling at dusk
            P = Page(ground)
            draw(P, charge)
            shoot(P, dest / f"{k}_{ground}.png")
            area = sum(bw * bh for _, _, bw, bh in P.boxes) / (W * H)
            least = min(P.sizes)
            print(f"{k} {T['name']} {ground}: the permanent HUD {area:.1%}; the smallest word {least[0]} pt ({least[1]!r})")
    if keys == list(DRAW):
        sheets(dest)
    print("drew AR68 round 3's specimens:", ", ".join(keys))


def sheets(dest):
    """sheet.png: today's game at dusk, then the four by day and at dusk, at 1x. corner.png: each one's lead and press at
    2x, by day and at dusk. four_day.png and four_dusk.png: the four on one ground."""
    today = dest / "today_dusk.png"
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(GROUNDS["dusk"]), "-vf", f"scale={2 * W}:{2 * H}",
                    str(today)], check=True)
    ins = []
    for k in DRAW:
        ins += [dest / f"{k}_day.png", dest / f"{k}_dusk.png"]
    cmd = ["ffmpeg", "-v", "error", "-y", "-i", str(today), "-i", str(today)]
    for p in ins:
        cmd += ["-i", str(p)]
    n = len(ins) + 2
    scaled = "".join(f"[{i}:v]scale={W}:{H}[s{i}];" for i in range(n))
    layout = "|".join(f"{(i % 2) * W}_{(i // 2) * H}" for i in range(n))
    cmd += ["-filter_complex", scaled + "".join(f"[s{i}]" for i in range(n)) + f"xstack=inputs={n}:layout={layout}",
            str(dest / "sheet.png")]
    subprocess.run(cmd, check=True)
    # the corner: x 0 to 250, y 0 to 200 of each frame, at 2x (the frames' own pixels)
    cmd = ["ffmpeg", "-v", "error", "-y"]
    for p in ins:
        cmd += ["-i", str(p)]
    m = len(ins)
    crops = "".join(f"[{i}:v]crop=500:400:0:0[c{i}];" for i in range(m))
    layout = "|".join(f"{(i % 2) * 500}_{(i // 2) * 400}" for i in range(m))
    cmd += ["-filter_complex", crops + "".join(f"[c{i}]" for i in range(m)) + f"xstack=inputs={m}:layout={layout}",
            str(dest / "corner.png")]
    subprocess.run(cmd, check=True)
    # four_day.png and four_dusk.png: the four on one ground, two by two, at 1.5x (P, S over M, R)
    for ground in ("day", "dusk"):
        cmd = ["ffmpeg", "-v", "error", "-y"]
        for k in DRAW:
            cmd += ["-i", str(dest / f"{k}_{ground}.png")]
        scaled = "".join(f"[{i}:v]scale=852:473[f{i}];" for i in range(4))
        cmd += ["-filter_complex", scaled + "[f0][f1][f2][f3]xstack=inputs=4:layout=0_0|852_0|0_473|852_473",
                str(dest / f"four_{ground}.png")]
        subprocess.run(cmd, check=True)


if __name__ == "__main__":
    main()
