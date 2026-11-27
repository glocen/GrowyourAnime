"""AR68, round 4: the four systems, each its own composition from its motif, then finished as image art, for the pick
(research's brief for round 4, 2026-11-27, 12:07).

    py tools/ui/hud_compositions.py <out> [grey] [P S M R]

- P, Porcelain Relay, the instrument: a glazed ceramic collar and dial; one brass relay pin runs down the left edge and
  links the lead's dial, the eye and the press. The foe's tag hangs from the top edge on two brass pins.
- S, Smoked Prism, facets: the lead is one shard of lifted glass broken into facets at 18 degrees, lit along one edge;
  the foe is a smaller shard leaning the other way; the press is a hexagonal prism.
- M, Match-Card, the broadcast match card: the lead and the foe are the two sides of one band across the top, mirrored,
  the edge's arrow in the persimmon cut between them.
- R, Resonance Sight, plateless: the cut-out bust in an open sight on a feathered scrim; the health is the sight's line;
  the foe is a lighter reticle.

Fixed by the brief: the lead top left, the press at the left thumb, the centre 60% free; the foe lighter than the lead
(no portrait, a smaller face, its skull coloured by its tier, the edge arrow kept); the ally's health red in each
system's own red; the press names the skill awake and shows its share filling; the damage numbers in each system's face,
no fat stroke, no ghost double, the critical in the director's gold. Every word 14 points or more at 568.

`grey`: the layouts as flat shapes, then desaturated (the composition check beside the shipped frames). Otherwise the
finish: ceramic glaze and brass, glass over the blurred world with a lit edge, printed card with its grain and hard
shadow, the scrim and the bracket's glow, all lit by SVG lighting filters (no stroke-drawn outlines).

The frame: AR57's Lantern Row crops (round 3's plates), labelled stand-ins for Faber's clean capture. The 852 frame is
the same crop; the HUD scales by 1.25 from the corners, the foe from the top centre.

The gate (AR68's common rules): the permanent fight HUD, the press aside, about 6% of the screen at most; the eye sits
with Auto beside the press, so the press's cluster is measured apart.

Writes <out>/<X>_<size>_<ground>.png (2x), <X>_wake.png (the press waking, three frames) and four_<ground>.png (the four
at 568, side by side). Anything holding a shipped game's frame goes to build/reference/ar68/round4/ only (gitignored,
internal): compose_grey.png (grey mode: the two shipped frames and the four's layouts, same size) and sheet_<ground>.png
(today's game, the shipped frame and the four). Intermediates go to build/scratch/modulo/ar68r4/work/.
"""
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import hud_systems as hs  # noqa: E402
import overhaul as ov  # noqa: E402

REPO = hs.REPO
PLATES = REPO / "build" / "scratch" / "modulo" / "ar68r4" / "plates"
REF = REPO / "build" / "reference"
SHIPPED = {"g05": REF / "anime-crusaders-x" / "g05_full.png", "dh": REF / "dragon-hunter" / "2026-11-12_arena-normal-damage.png"}
WORK = REPO / "build" / "scratch" / "modulo" / "ar68r4" / "work"
REFOUT = REF / "ar68" / "round4"
SIZES = {568: (568, 315, 1.0), 852: (852, 473, 1.25)}
LEAD, FOE, SKILL, TYPES = hs.LEAD, hs.FOE, hs.SKILL, hs.TYPES
TAKEN = "15"
poly, cut, rect, circle, arc = ov.poly, ov.cut, ov.rect, ov.circle, hs.arc
GOLD_EDGE = "#4A2A00"


# ---- the page ----------------------------------------------------------------------------------------------------------
def plate(size, ground):
    w, h, _ = SIZES[size]
    out = PLATES / f"{ground}_{size}.png"
    if not out.exists():
        out.parent.mkdir(parents=True, exist_ok=True)
        cw, ch, cx, cy = hs.CROP
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(hs.GROUNDS[ground]), "-vf",
                        f"crop={cw}:{ch}:{cx}:{cy},scale={2 * w}:{2 * h}:flags=lanczos", str(out)], check=True)
    return out


def light(fid, depth, blur, diffuse, spec, exp, el=50, only=False):
    """A lit surface from the shape's own alpha: diffuse shading (the face toward the light up, the far edge down) and a
    specular glint along the lit edge. `only`: the glint alone, to lay over something else (glass)."""
    head = (f'<filter id="{fid}" x="-8%" y="-8%" width="116%" height="120%" color-interpolation-filters="sRGB">'
            f'<feGaussianBlur in="SourceAlpha" stdDeviation="{blur}" result="b"/>'
            f'<feSpecularLighting in="b" surfaceScale="{depth}" specularConstant="{spec}" specularExponent="{exp}" '
            f'lighting-color="#FFFFFF" result="sp"><feDistantLight azimuth="225" elevation="{el}"/></feSpecularLighting>'
            f'<feComposite in="sp" in2="SourceAlpha" operator="in" result="spc"/>')
    if only:
        return head + '<feComposite in="spc" in2="spc" operator="arithmetic" k1="0" k2="1" k3="0" k4="0"/></filter>'
    return (head + f'<feDiffuseLighting in="b" surfaceScale="{depth}" diffuseConstant="1" lighting-color="#FFFFFF" '
            f'result="df"><feDistantLight azimuth="225" elevation="{el + 8}"/></feDiffuseLighting>'
            f'<feComposite in="SourceGraphic" in2="df" operator="arithmetic" k1="{diffuse}" k2="{1.02 - 0.82 * diffuse}" '
            f'k3="0" k4="0" result="lit"/>'
            f'<feComposite in="lit" in2="spc" operator="arithmetic" k1="0" k2="1" k3="1" k4="0" result="o"/>'
            f'<feComposite in="o" in2="SourceAlpha" operator="in"/></filter>')


class Page(hs.Page):
    def __init__(self, size, ground, grey=False):
        w, h, s = SIZES[size]
        ov.Page.__init__(self, w, h, plate(size, ground))
        self.size, self.ground, self.flat, self.s, self.k = size, ground, grey, s, w / 568
        self.pboxes = []
        self.tf = (0.0, 0.0, 1.0)
        self.defs += [
            '<filter id="lift" x="-30%" y="-60%" width="160%" height="220%"><feDropShadow dx="0" dy="1" stdDeviation="1.2" '
            'flood-color="#0E131B" flood-opacity="0.55"/></filter>',
            '<filter id="cel" x="-10%" y="-30%" width="130%" height="170%"><feDropShadow dx="2.2" dy="2.2" stdDeviation="0" '
            f'flood-color="{hs.M_["shadow"]}" flood-opacity="0.42"/></filter>',
            '<filter id="contact" x="-10%" y="-30%" width="130%" height="170%"><feDropShadow dx="0" dy="2.4" stdDeviation="1.8" '
            'flood-color="#1A222D" flood-opacity="0.38"/></filter>',
            '<filter id="bloom" x="-80%" y="-80%" width="260%" height="260%"><feGaussianBlur stdDeviation="2.4"/></filter>',
            '<filter id="bloomWide" x="-80%" y="-80%" width="260%" height="260%"><feGaussianBlur stdDeviation="5"/></filter>',
            '<filter id="tooth" x="0" y="0" width="100%" height="100%" color-interpolation-filters="sRGB">'
            '<feTurbulence type="fractalNoise" baseFrequency="1.1" numOctaves="2" seed="9"/><feColorMatrix type="matrix" '
            'values="0 0 0 0 0.16  0 0 0 0 0.19  0 0 0 0 0.25  0 0 0 0.9 -0.42"/></filter>',
            '<filter id="paper" x="0" y="0" width="100%" height="100%" color-interpolation-filters="sRGB">'
            '<feTurbulence type="fractalNoise" baseFrequency="0.9 0.6" numOctaves="3" seed="4"/><feColorMatrix type="matrix" '
            'values="0 0 0 0 0.35  0 0 0 0 0.3  0 0 0 0 0.24  0 0 0 1.4 -0.55"/></filter>',
            light("glaze", 2.2, 2.0, 0.5, 0.55, 16),
            light("metal", 3.0, 1.2, 0.8, 1.1, 26, el=42),
            light("printed", 1.0, 0.8, 0.25, 0.25, 30),
            light("facet", 2.0, 0.9, 0, 1.3, 34, el=38, only=True),
            '<radialGradient id="scrim"><stop offset="0" stop-color="#1C2432" stop-opacity="0.5"/>'
            '<stop offset="0.6" stop-color="#1C2432" stop-opacity="0.34"/><stop offset="1" stop-color="#1C2432" '
            'stop-opacity="0"/></radialGradient>',
            '<radialGradient id="glint" cx="0.3" cy="0.25" r="0.6"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.75"/>'
            '<stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>',
            '<linearGradient id="brass" x1="0" y1="0" x2="0.35" y2="1"><stop offset="0" stop-color="#FBE3A0"/>'
            '<stop offset="0.28" stop-color="#D9A946"/><stop offset="0.55" stop-color="#9C6E22"/><stop offset="0.72" '
            'stop-color="#E9C470"/><stop offset="1" stop-color="#7A5418"/></linearGradient>',
            '<linearGradient id="brassV" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7A5418"/>'
            '<stop offset="0.35" stop-color="#F6D98E"/><stop offset="0.6" stop-color="#C48F36"/><stop offset="1" '
            'stop-color="#6E4B14"/></linearGradient>',
            '<linearGradient id="critGold" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFF3B8"/>'
            '<stop offset="0.45" stop-color="#FFD24C"/><stop offset="1" stop-color="#F0A81E"/></linearGradient>',
        ]

    # groups: the lead's side and the press from the top left, the foe from the top centre, the numbers from the world
    def begin(self, where):
        s, k = self.s, self.k
        ox, oy = {"lead": (0.0, 0.0), "foe": (self.w / 2 - 284 * s, 0.0),
                  "world": (372 * k - 372 * s, 176 * k - 176 * s)}[where]
        self.tf = (ox, oy, s)
        self.add(f'<g transform="translate({ox:.2f},{oy:.2f}) scale({s})">')

    def end(self):
        self.add("</g>")
        self.tf = (0.0, 0.0, 1.0)

    def hud(self, x, y, w, h, press=False):
        """A piece's box toward the HUD's share: the permanent HUD, or the press's cluster (`press`)."""
        ox, oy, s = self.tf
        (self.pboxes if press else self.boxes).append((ox + x * s, oy + y * s, w * s, h * s))

    def world_in(self, d, r):
        """The world behind a shape, blurred (glass), in the group's own units."""
        ox, oy, s = self.tf
        self.add(f'<g clip-path="url(#{self.clip(d)})"><image href="{ov.blurred(self.plate, self.w, self.h, r)}" '
                 f'x="{-ox / s:.2f}" y="{-oy / s:.2f}" width="{self.w / s:.2f}" height="{self.h / s:.2f}" '
                 f'preserveAspectRatio="none"/></g>')

    def clipped(self, d):
        self.add(f'<g clip-path="url(#{self.clip(d)})">')


def shade(P, d, top, bottom, opacity=1.0, filt=None):
    f = f' filter="url(#{filt})"' if filt and not P.flat else ""
    fill = top if P.flat else P.lin([top, bottom], 0, 1)
    P.add(f'<path d="{d}" fill="{fill}" fill-opacity="{opacity}"{f}/>')


def glint(P, d, opacity=0.55):
    """A soft glaze glint toward the light, inside the shape."""
    if P.flat:
        return
    P.clipped(d)
    P.add(f'<path d="{d}" fill="url(#glint)" opacity="{opacity}"/></g>')


def grain(P, d, filt, opacity):
    if P.flat:
        return
    P.clipped(d)
    P.add(f'<rect x="-50" y="-50" width="{P.w}" height="{P.h}" filter="url(#{filt})" opacity="{opacity}"/></g>')


def trough(P, d, fill_d, track, fill, lit, shade_ink="#000000"):
    """A sculpted trough and its fill (both paths): the trough recessed, the fill lit from the top."""
    P.add(f'<path d="{d}" fill="{track}"/>')
    if not P.flat:
        P.clipped(d)
        P.add(f'<path d="{d}" fill="none" stroke="{shade_ink}" stroke-opacity="0.45" stroke-width="2.2" '
              f'transform="translate(0,0.8)"/></g>')
    if fill_d:
        g = fill if P.flat else P.lin([lit, fill, fill], 0, 1)
        P.add(f'<path d="{fill_d}" fill="{g}"/>')


def hbar(x, y, w, h, share, k=0.0):
    """A bar's trough and fill as paths; `k`: the ends' slant (dx over the height)."""
    t = [(x + k * h, y), (x + w + k * h, y), (x + w, y + h), (x, y + h)]
    fw = w * share
    f = [(x + k * h, y), (x + fw + k * h, y), (x + fw, y + h), (x, y + h)] if fw > 0 else None
    return poly(t), (poly(f) if f else None)


def hbar_right(x, y, w, h, share):
    """A bar anchored at its right end (the mirrored side)."""
    fw = w * share
    return rect(x, y, w, h), (rect(x + w - fw, y, fw, h) if fw > 0 else None)


def numbers(P, face, plain, edge, crit_face, shadow="lift", edge_w=0.8):
    """The damage numbers beside the struck Dasher: the critical heavy, slanted and larger in gold; the element's in its
    colour; one plain hit before them; a thin edge and a cast shadow, no fat stroke, no double."""
    P.begin("world")
    ax, ay = 372, 176

    def num(x, y, s, size, fill, f=face, op=1.0, sp=0.5, k=edge, w=edge_w):
        P.sizes.append((size, s))
        st = f' stroke="{k}" stroke-width="{w}" stroke-linejoin="round" paint-order="stroke"' if w else ""
        P.add(f'<text x="{x:.2f}" y="{y:.2f}" font-family="{f}" font-size="{size}" fill="{fill}" letter-spacing="{sp}"'
              f'{st} opacity="{op}" filter="url(#{shadow})">{s}</text>')
    num(ax + 52, ay - 34, "565", 16, plain, op=0.85)
    P.add(f'<g transform="translate({ax:.2f},{ay:.2f}) skewX(-10)">')
    num(0, 0, "1,130", 27, "url(#critGold)", f=crit_face, sp=0.8, k=GOLD_EDGE, w=1.0)
    P.add("</g>")
    num(ax + 88, ay + 15, "98", 16, ov.FIRE)
    P.end()


def tag_text(P, x, y, spans, anchor="start", extra=""):
    P.t(x, y, spans, anchor, extra)


# ---- P, Porcelain Relay: the instrument ---------------------------------------------------------------------------------
def ceramic(P, d, tone=None, outline=True, glazed=True):
    T = hs.P_
    top, bottom = tone or (T["plate"], T["plate2"])
    if not P.flat:
        P.add(f'<path d="{d}" fill="{top}" filter="url(#contact)"/>')
    shade(P, d, top, bottom, 0.96, "glaze")
    if glazed:
        glint(P, d, 0.5)
    grain(P, d, "tooth", 0.05)
    if P.flat or outline:
        P.add(f'<path d="{d}" fill="none" stroke="{T["ink"]}" stroke-opacity="{0.9 if P.flat else 0.28}" '
              f'stroke-width="{1.2 if P.flat else 0.8}"/>')


def brass(P, d):
    if P.flat:
        P.add(f'<path d="{d}" fill="{hs.P_["hue"]}" stroke="{hs.P_["ink"]}" stroke-width="0.8"/>')
        return
    P.add(f'<path d="{d}" fill="url(#brass)" filter="url(#metal)"/>')


def p_frame(P, charge, flash=False):
    T = hs.P_
    X = 36                                                   # the relay pin's line
    P.begin("lead")
    brass(P, rect(X - 1.7, 60, 3.4, 58))                     # the pin, from the level chip down to the press
    # the collar: a chamfered ceramic plate tucked behind the dial
    d = poly([(54, 14), (186, 14), (196, 24), (196, 40), (186, 50), (54, 50)])
    ceramic(P, d)
    P.hud(54, 14, 142, 36)
    tag_text(P, 68, 29, [(LEAD["name"].upper(), 16, "SansB", T["ink"], 1.4)])
    ov.gem(P, 133, 23.5, 11, TYPES[LEAD["type"]], rim=T["ink"], width=0.8)
    ov.blade(P, 145, 23.5, 12, T["ink"])
    tag_text(P, 190, 29, [(TAKEN, 15, "ExtB", T["taken"])], anchor="end")
    tr, fl = hbar(66, 31.5, 124, 13, LEAD["hp"] / LEAD["max"])
    trough(P, tr, fl, T["recess"], T["ally"], T["ally_lit"], "#7A6E5A")
    tag_text(P, 128, 42.4, [(f'{LEAD["hp"]:,} / {LEAD["max"]:,}', 14, "MonoB", "#FFFFFF")], anchor="middle",
             extra=' filter="url(#lift)"')
    tr, fl = hbar(66, 46, 124, 2.2, LEAD["xp"])
    trough(P, tr, fl, T["recess"], T["hue"], T["hue_lit"], "#7A6E5A")
    # the dial: the bust in a ceramic face, a brass bezel
    brass(P, circle(X, 31, 24))
    ceramic(P, circle(X, 31, 20.5), tone=(T["plate2"], T["recess"]), glazed=False)
    P.clipped(circle(X, 31, 20.5))
    ov.bust(P, X - 20, 11, 41, fade=0.92)
    P.add("</g>")
    glint(P, circle(X, 31, 20.5), 0.35)
    P.hud(X - 24, 7, 48, 48)
    # the level, a chip on the pin over the bezel's foot
    ceramic(P, cut(X - 14, 47, 28, 16, tl=4, tr=4, br=4, bl=4))
    tag_text(P, X, 59.8, [(str(LEAD["level"]), 14, "MonoB", T["ink"])], anchor="middle")
    P.hud(X - 14, 55, 28, 8)
    # the eye: a ceramic knob on the pin, above the press
    brass(P, circle(X, 98, 13))
    ceramic(P, circle(X, 98, 10.5))
    hs.eye_icon(P, X, 98, 14, T["ink"], T["taken"], sw=1.3)
    P.hud(X - 13, 85, 26, 26, press=True)
    # the press: a ceramic dial in a brass bezel; the charge is brass laid round it
    cx, cy, r = X, 146, 30
    full = charge >= 1
    if flash and not P.flat:
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{r + 5}" fill="none" stroke="#FFD98A" stroke-width="8" opacity="0.95" '
              f'filter="url(#bloomWide)"/>')
    brass(P, circle(cx, cy, r))
    ceramic(P, circle(cx, cy, r - 3.5), glazed=False)
    if full and not P.flat:
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{r - 3.5}" fill="#FFD98A" opacity="0.3"/>')
    P.add(f'<path d="{arc(cx, cy, r - 7.5, 0, 359.9)}" fill="none" stroke="{T["recess"]}" stroke-width="4"/>')
    P.add(f'<path d="{arc(cx, cy, r - 7.5, 0, 359.9 * min(charge, 1))}" fill="none" '
          f'stroke="{"url(#brassV)" if not P.flat else T["hue"]}" stroke-width="4"/>')
    hs.art_slot(P, cx, cy, r - 11, T["ink"], T["plate2"], opacity=1 if full else 0.55)
    glint(P, circle(cx, cy, r - 3.5), 0.45 if full else 0.25)
    if flash and not P.flat:
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{r - 3.5}" fill="#FFF6DC" opacity="0.45"/>')
    P.hud(cx - r, cy - r, 2 * r, 2 * r, press=True)
    brass(P, rect(cx + r - 1, cy - 9.5, 10, 3))              # the arm to the press's label
    label = (SKILL.upper(), 14, "SansB", T["ink"], 1.2) if full else (f"{round(charge * 100)}%", 14, "MonoB", T["ink"])
    lw = 88 if full else 48
    (brass if full else ceramic)(P, cut(74, cy - 19, lw, 21, tr=6, br=6))
    tag_text(P, 74 + lw / 2, cy - 3.6, [label], anchor="middle")
    # Auto: a ceramic toggle with a brass lamp
    ceramic(P, cut(74, cy + 8, 66, 22, tr=6, br=6))
    P.add(f'<rect x="82" y="{cy + 15:.1f}" width="8" height="8" fill="{T["hue"] if P.flat else "url(#brass)"}" '
          f'stroke="{T["ink"]}" stroke-width="0.6"/>')
    tag_text(P, 95, cy + 24.5, [("AUTO", 14, "SansB", T["ink"], 1)])
    P.hud(74, cy - 19, lw, 21, press=True)
    P.hud(74, cy + 8, 66, 22, press=True)
    P.end()
    # the foe: a lighter ceramic tag hanging from the top edge on two brass pins
    P.begin("foe")
    fx, fy, fw, fh = 218, 10, 132, 25
    for px in (fx + 14, fx + fw - 14):
        brass(P, rect(px - 1.2, 0, 2.4, fy + 3))
    ceramic(P, cut(fx, fy, fw, fh, bl=6, br=6), tone=(T["plate2"], T["recess"]), glazed=False)
    P.hud(fx, fy, fw, fh)
    P.add(f'<circle cx="{fx + 12}" cy="{fy + 9.5}" r="7.4" fill="{T["ink"]}"/>')
    ov.skull(P, fx + 7.4, fy + 4.6, 9.6, T["skulls"][FOE["tier"]])
    tag_text(P, fx + 23, fy + 14.5, [(str(FOE["level"]), 14, "MonoB", T["ink"]),
                                     (FOE["name"].upper(), 14, "Sans", T["ink"], 0.6, 5)])
    ov.gem(P, fx + 110, fy + 9.5, 9, TYPES[FOE["type"]], rim=T["ink"], width=0.8)
    ov.arrow(P, fx + 122, fy + 9.5, 8, True, T["hue"], ink=T["ink"], width=0.7)
    tr, fl = hbar(fx + 6, fy + 18, fw - 12, 4, FOE["hp"] / FOE["max"])
    trough(P, tr, fl, T["recess"], T["foe"], T["foe2"], "#7A6E5A")
    for i in (1, 2, 3):
        P.add(f'<rect x="{fx + 6 + (fw - 12) * i / 4 - 0.5:.2f}" y="{fy + 18}" width="1" height="4" fill="{T["plate"]}"/>')
    P.end()
    numbers(P, "ExtB", "#FBF8F1", T["ink"], "ExtB")


# ---- S, Smoked Prism: facets --------------------------------------------------------------------------------------------
INK_S = "#15202D"


def glass(P, d, tint, opacity, edge=True):
    """Lifted smoked glass: the world blurred behind, a pale veil, a sheen falling across it, and the facet's edges lit."""
    if P.flat:
        P.add(f'<path d="{d}" fill="{tint}" fill-opacity="{min(1, opacity + 0.3):.2f}" stroke="{INK_S}" stroke-width="1"/>')
        return
    P.add(f'<path d="{d}" fill="#000" filter="url(#contact)"/>')
    P.world_in(d, 7)
    P.add(f'<path d="{d}" fill="{tint}" fill-opacity="{opacity}"/>')
    P.clipped(d)
    P.add(f'<path d="{d}" fill="{P.lin(["#FFFFFF", "#FFFFFF", "#FFFFFF"], 1, 1, [0.35, 0.06, 0.16])}"/></g>')
    if edge:
        P.add(f'<path d="{d}" fill="#000" filter="url(#facet)"/>')
    P.add(f'<path d="{d}" fill="none" stroke="#0E1622" stroke-opacity="0.35" stroke-width="0.7"/>')


def lit_edge(P, x0, y0, x1, y1, hot="#E9FBFF", bloom="#32B8EB", wide=False):
    if not P.flat:
        P.add(f'<path d="M {x0},{y0} L {x1},{y1}" stroke="{bloom}" stroke-width="{5 if wide else 3.4}" opacity="0.8" '
              f'filter="url(#{"bloomWide" if wide else "bloom"})"/>')
    P.add(f'<path d="M {x0},{y0} L {x1},{y1}" stroke="{hot}" stroke-width="1.6" stroke-linecap="round"/>')


def s_frame(P, charge, flash=False):
    T = hs.S_
    P.begin("lead")
    B = [(8, 8), (56, 8), (46, 56), (8, 56)]                   # the bust's facet
    G = [(56, 8), (196, 8), (187.5, 36), (50.17, 36)]          # the gauges' facet, broken from it along one line
    D = [(50.17, 36), (158, 36), (154, 52), (46.83, 52)]       # the readout's facet under it
    glass(P, poly(B), "#AFC1D4", 0.55)
    P.clipped(poly(B))
    ov.bust(P, 4, 9, 47, fade=0.9)
    P.add("</g>")
    glass(P, poly(G), "#F1F5FA", 0.72)
    glass(P, poly(D), "#DCE5EE", 0.66)
    P.hud(8, 8, 48, 48)
    P.hud(56, 8, 140, 28)
    P.hud(47, 36, 111, 16)
    lit_edge(P, 9, 8.5, 195, 8.5)
    # the level: a dark prism chip at the bust facet's foot
    lv = [(8, 42), (32, 42), (29.5, 56), (8, 56)]
    P.add(f'<path d="{poly(lv)}" fill="{T["recess"]}" fill-opacity="0.92"/>')
    tag_text(P, 19.5, 54.3, [(str(LEAD["level"]), 14, "MontB", T["ink"])], anchor="middle")
    ov.gem(P, 66, 18.5, 10, TYPES[LEAD["type"]], rim=INK_S, width=0.8)
    ov.blade(P, 77, 18.5, 11, INK_S)
    tag_text(P, 86, 24, [(LEAD["name"], 16, "MontB", INK_S, 0.4)])
    tag_text(P, 182, 23.5, [(TAKEN, 15, "MontB", "#D92B45")], anchor="end")
    tr, fl = hbar(60, 26.5, 122, 5.5, LEAD["hp"] / LEAD["max"], k=-0.32)
    trough(P, tr, fl, "#2A3646", T["ally"], T["ally_lit"])
    tr, fl = hbar(58.6, 32.8, 122, 1.6, LEAD["xp"], k=-0.32)
    trough(P, tr, fl, "#2A3646", "#E6A83C", "#FFD98A")
    tag_text(P, 55, 48.8, [(f'{LEAD["hp"]:,}', 14, "MontB", INK_S), (f' / {LEAD["max"]:,}', 14, "Mont", "#4A5A6E")])
    # the press: a hexagonal prism; its rim lights round as it fills
    cx, cy, r = 38, 142, 31
    full = charge >= 1
    hexa = [(cx + r * c, cy + r * s) for c, s in ((0, -1), (0.866, -0.5), (0.866, 0.5), (0, 1), (-0.866, 0.5), (-0.866, -0.5))]
    tints = ("#F4F8FC", "#DFE8F1", "#BCCBDB", "#AEBFD1", "#C9D6E3", "#E8EFF6")
    for i in range(6):
        glass(P, poly([(cx, cy), hexa[i], hexa[(i + 1) % 6]]), tints[i], 0.62, edge=False)
    if not P.flat:
        P.add(f'<path d="{poly(hexa)}" fill="#000" filter="url(#facet)"/>')
    per = [hexa[i] for i in range(6)] + [hexa[0]]              # the rim, lit along its length as far as the charge
    lit = 6 * min(charge, 1)
    path, i = [per[0]], 0
    while i < 6 and lit > 0:
        a, b = per[i], per[i + 1]
        u = min(1.0, lit)
        path.append((a[0] + (b[0] - a[0]) * u, a[1] + (b[1] - a[1]) * u))
        lit -= 1
        i += 1
    P.add(f'<path d="{poly(hexa)}" fill="none" stroke="{T["recess"]}" stroke-width="2.6" stroke-opacity="0.75"/>')
    seg = "M " + " L ".join(f"{x:.2f},{y:.2f}" for x, y in path)
    if not P.flat and full:
        P.add(f'<path d="{seg}" fill="none" stroke="#32B8EB" stroke-width="{8 if flash else 4.5}" opacity="0.85" '
              f'filter="url(#{"bloomWide" if flash else "bloom"})"/>')
    P.add(f'<path d="{seg}" fill="none" stroke="#DDF7FF" stroke-width="2.2" stroke-linejoin="round"/>')
    hs.art_slot(P, cx, cy, 18, INK_S, "#D7E1EB", opacity=1 if full else 0.55)
    if flash and not P.flat:
        P.add(f'<path d="{poly(hexa)}" fill="#F2FCFF" opacity="0.35"/>')
    P.hud(cx - 27, cy - r, 54, 2 * r, press=True)
    label = (SKILL.upper(), 14, "MontB", INK_S, 0.8) if full else (f"{round(charge * 100)}%", 14, "MontB", INK_S)
    lw = 96 if full else 52
    L = [(76, cy - 17), (76 + lw, cy - 17), (70 + lw, cy + 1), (70, cy + 1)]
    glass(P, poly(L), "#F1F5FA", 0.74)
    if full:
        P.add(f'<path d="{poly(L)}" fill="#7FD8F5" fill-opacity="0.5"/>')
    tag_text(P, 73 + lw / 2, cy - 3, [label], anchor="middle")
    A = [(72, cy + 7), (136, cy + 7), (130, cy + 25), (66, cy + 25)]
    glass(P, poly(A), "#E6EDF4", 0.7)
    P.add(f'<path d="{poly([(78, cy + 12), (85, cy + 12), (83, cy + 20), (76, cy + 20)])}" fill="#32B8EB"/>')
    tag_text(P, 90, cy + 21, [("AUTO", 14, "MontB", INK_S, 0.6)])
    # the eye: a small facet beside Auto
    E = [(142, cy + 7), (172, cy + 7), (166, cy + 25), (136, cy + 25)]
    glass(P, poly(E), "#F1F5FA", 0.7)
    hs.eye_icon(P, 154, cy + 16, 15, INK_S, "#D92B45", sw=1.4)
    P.hud(70, cy - 17, lw + 6, 18, press=True)
    P.hud(66, cy + 7, 106, 18, press=True)
    P.end()
    # the foe: a smaller shard leaning the other way, no lit edge
    P.begin("foe")
    F = [(216, 8), (345, 8), (352, 30), (223, 30)]
    glass(P, poly(F), "#E3EAF2", 0.6)
    P.hud(216, 8, 136, 22)
    P.add(f'<circle cx="232" cy="17.5" r="7" fill="{T["recess"]}"/>')
    ov.skull(P, 227.5, 13, 9, T["skulls"][FOE["tier"]])
    tag_text(P, 244, 23, [(str(FOE["level"]), 14, "MontB", INK_S), (FOE["name"], 14, "Mont", INK_S, 0.3, 5)])
    ov.gem(P, 325, 17, 9, TYPES[FOE["type"]], rim=INK_S, width=0.8)
    ov.arrow(P, 336, 17, 8, True, "#1E9CD0", ink=INK_S, width=0.6)
    tr, fl = hbar(228, 25.5, 108, 3, FOE["hp"] / FOE["max"], k=0.32)
    trough(P, tr, fl, "#2A3646", T["foe"], T["foe2"])
    P.end()
    numbers(P, "MontK", "#FFFFFF", "#15202D", "MontK")


# ---- M, Match-Card: the broadcast match card ----------------------------------------------------------------------------
def card(P, d, fill, print_=True, shadow=True):
    T = hs.M_
    f = ' filter="url(#cel)"' if shadow else ""
    P.add(f'<path d="{d}" fill="{fill}"{f}/>')
    if not P.flat and print_:
        P.add(f'<path d="{d}" fill="{fill}" filter="url(#printed)"/>')
        grain(P, d, "paper", 0.07)
    if P.flat:
        P.add(f'<path d="{d}" fill="none" stroke="{T["ink"]}" stroke-width="1"/>')


def m_frame(P, charge, flash=False):
    T = hs.M_
    P.begin("lead")                       # the band is one piece: its foe side rides with the lead's from the corner
    # the lead's side: the portrait on slate, the ivory name card, the health strip under it with its digits inside
    card(P, rect(6, 6, 44, 44), T["slate"])
    P.clipped(rect(6, 6, 44, 44))
    ov.bust(P, 6, 8, 42, fade=0.95)
    P.add("</g>")
    card(P, poly([(50, 6), (196, 6), (192, 24), (50, 24)]), T["ivory"])
    tag_text(P, 58, 21, [(LEAD["name"].upper(), 16, "OswB", T["ink"], 1.0)])
    ov.gem(P, 108, 15, 10, TYPES[LEAD["type"]], rim=T["ink"], width=0.8)
    ov.blade(P, 119, 15, 11, T["ink"])
    tag_text(P, 184, 21, [(TAKEN, 15, "OswB", T["ally"])], anchor="end")
    card(P, poly([(50, 24), (192, 24), (188, 40), (50, 40)]), T["slate"], print_=False)
    tr, fl = hbar(52, 26, 133, 12, LEAD["hp"] / LEAD["max"], k=-0.25)
    trough(P, tr, fl, "#1C222C", T["ally"], T["ally_lit"])
    tag_text(P, 119, 37, [(f'{LEAD["hp"]:,}', 14, "OswB", T["ivory"]), (f'/{LEAD["max"]:,}', 14, "Osw", "#F3E6D6")],
             anchor="middle", extra=' filter="url(#lift)"')
    tr, fl = hbar(50, 41, 138, 2.2, LEAD["xp"])
    trough(P, tr, fl, "#1C222C", T["xp"], "#FFE7A6")
    # the level, a persimmon tab on the portrait's corner
    card(P, poly([(28, 38), (54, 38), (50, 52), (24, 52)]), T["hue"])
    tag_text(P, 39, 49.6, [(str(LEAD["level"]), 14, "OswB", T["ivory"])], anchor="middle")
    P.hud(6, 6, 44, 44)
    P.hud(50, 6, 146, 37.2)
    P.hud(24, 50, 30, 2)
    P.hud(50, 43.2, 4, 8.8)
    # the cut between the two sides, carrying the edge's arrow
    card(P, poly([(196, 6), (212, 6), (204, 36), (188, 36)]), T["hue"])
    ov.arrow(P, 200, 20, 11, True, T["ivory"])
    P.hud(188, 6, 24, 30)
    # the foe's side, mirrored and lighter: no portrait, a smaller face, its strip filling from its own end
    card(P, poly([(214, 6), (326, 6), (326, 24), (209.2, 24)]), T["slate"])
    ov.skull(P, 216, 9.5, 10, T["skulls"][FOE["tier"]])
    tag_text(P, 231, 20, [(str(FOE["level"]), 14, "OswB", T["ivory"]), (FOE["name"].upper(), 14, "Osw", T["ivory"], 0.8, 5)])
    ov.gem(P, 316, 15, 9, TYPES[FOE["type"]], rim=T["ivory"], width=0.7)
    tr, fl = hbar_right(209, 25, 117, 5, FOE["hp"] / FOE["max"])
    trough(P, tr, fl, "#1C222C", T["foe"], "#E86A80")
    for i in (1, 2, 3):
        P.add(f'<rect x="{209 + 117 * i / 4 - 0.5:.2f}" y="25" width="1" height="5" fill="{T["slate"]}"/>')
    P.hud(209, 6, 117, 24)
    # the press: a die-cut card disc; its ring fills in persimmon, and its label card turns persimmon when it wakes
    cx, cy, r = 38, 142, 30
    full = charge >= 1
    if flash and not P.flat:
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{r + 6}" fill="{T["hue"]}" opacity="0.6" filter="url(#bloomWide)"/>')
    card(P, circle(cx, cy, r), T["hue"] if full else T["slate"])
    if not full:
        P.add(f'<path d="{arc(cx, cy, r - 3.5, 0, 359.9 * charge)}" fill="none" stroke="{T["hue"]}" stroke-width="5"/>')
    card(P, circle(cx, cy, r - 7), T["ivory"], shadow=False)
    hs.art_slot(P, cx, cy, r - 10, T["ink"], T["ivory"], opacity=1 if full else 0.55)
    if flash and not P.flat:
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{r - 1}" fill="none" stroke="#FFFFFF" stroke-width="3" opacity="0.9"/>')
    P.hud(cx - r, cy - r, 2 * r, 2 * r, press=True)
    label = (SKILL.upper(), 15, "OswB", T["ivory"], 1.2) if full else (f"{round(charge * 100)}%", 15, "OswB", T["ivory"])
    lw = 90 if full else 50
    card(P, poly([(78, cy - 18), (78 + lw, cy - 18), (74 + lw, cy + 1), (74, cy + 1)]), T["hue"] if full else T["slate"])
    tag_text(P, 76 + lw / 2, cy - 3, [label], anchor="middle")
    card(P, poly([(74, cy + 7), (134, cy + 7), (130, cy + 26), (70, cy + 26)]), T["ivory"])
    P.add(f'<rect x="80" y="{cy + 13}" width="8" height="8" fill="{T["hue"]}"/>')
    tag_text(P, 93, cy + 22.5, [("AUTO", 14, "OswB", T["ink"], 1)])
    # the eye: a small ivory card beside Auto
    card(P, poly([(140, cy + 7), (172, cy + 7), (168, cy + 26), (136, cy + 26)]), T["ivory"])
    hs.eye_icon(P, 154, cy + 16.5, 16, T["ink"], T["hue"], sw=1.4)
    P.hud(74, cy - 18, lw + 4, 19, press=True)
    P.hud(70, cy + 7, 102, 19, press=True)
    P.end()
    numbers(P, "OswB", T["ivory"], T["slate"], "OswB", shadow="cel", edge_w=0.9)


# ---- R, Resonance Sight: plateless --------------------------------------------------------------------------------------
def scrim(P, cx, cy, rx, ry, peak=1.0):
    if P.flat:
        P.add(f'<ellipse cx="{cx}" cy="{cy}" rx="{rx * 0.8:.1f}" ry="{ry * 0.8:.1f}" fill="#1C2432" fill-opacity="0.35"/>')
        return
    P.add(f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="url(#scrim)" opacity="{peak}"/>')


def bracket(P, x0, y0, x1, y1, arm, ink, w=2.0, glow=True):
    d = (f"M {x0},{y0 + arm} L {x0},{y0} L {x0 + arm},{y0} M {x1 - arm},{y0} L {x1},{y0} L {x1},{y0 + arm} "
         f"M {x1},{y1 - arm} L {x1},{y1} L {x1 - arm},{y1} M {x0 + arm},{y1} L {x0},{y1} L {x0},{y1 - arm}")
    if glow and not P.flat:
        P.add(f'<path d="{d}" fill="none" stroke="{hs.R_["hue"]}" stroke-width="{w + 2.4}" opacity="0.7" filter="url(#bloom)"/>')
    P.add(f'<path d="{d}" fill="none" stroke="{ink}" stroke-width="{w}" stroke-linecap="square"/>')


def r_frame(P, charge, flash=False):
    T = hs.R_
    lift = ' filter="url(#lift)"'
    P.begin("lead")
    scrim(P, 100, 30, 116, 38)
    ov.bust(P, 10, 6, 44, fade=0.82)
    bracket(P, 8, 4, 56, 52, 8, T["hue_lit"])
    tag_text(P, 52, 49, [(str(LEAD["level"]), 14, "TitB", T["ink"])], anchor="end", extra=lift)
    ov.gem(P, 68, 17, 10, TYPES[LEAD["type"]], rim=T["deep"], width=0.8)
    ov.blade(P, 79, 17, 11, T["ink"], ink=T["deep"], width=0.8)
    tag_text(P, 88, 22.5, [(LEAD["name"].upper(), 16, "TitB", T["ink"], 1.4)], extra=lift)
    tag_text(P, 196, 22.5, [(TAKEN, 15, "TitB", T["taken"])], anchor="end", extra=lift)
    # the sight's line: the health, ticked at its ends
    tr, fl = hbar(66, 27, 126, 6, LEAD["hp"] / LEAD["max"])
    trough(P, tr, fl, T["trough"], T["ally"], T["ally_lit"])
    for x in (63, 195):
        P.add(f'<rect x="{x - 0.8}" y="24" width="1.6" height="12" fill="{T["hue_lit"]}"/>')
    tr, fl = hbar(66, 34.5, 126, 1.8, LEAD["xp"])
    trough(P, tr, fl, T["trough"], T["xp"], "#FFF0C4")
    tag_text(P, 66, 50.5, [(f'{LEAD["hp"]:,}', 14, "TitB", T["ink"]), (f' / {LEAD["max"]:,}', 14, "Tit", T["sub"])],
             extra=lift)
    P.hud(8, 4, 48, 48)
    P.hud(60, 10, 136, 42)
    # the press: an open ring, the charge in viridian, four gaps
    cx, cy, r = 40, 142, 27
    full = charge >= 1
    scrim(P, cx + 56, cy, 100, 44)
    P.add(f'<circle cx="{cx}" cy="{cy}" r="{r - 8}" fill="{T["trough"]}" fill-opacity="0.9"/>')
    for a0 in (5, 95, 185, 275):
        P.add(f'<path d="{arc(cx, cy, r, a0, a0 + 80)}" fill="none" stroke="{T["trough"]}" stroke-width="5"/>')
    lit_to = 360 * min(charge, 1)
    for a0 in (5, 95, 185, 275):
        a1 = min(a0 + 80, lit_to)
        if a1 > a0:
            if not P.flat and full:
                P.add(f'<path d="{arc(cx, cy, r, a0, a1)}" fill="none" stroke="{T["hue"]}" stroke-width="{9 if flash else 6}" '
                      f'opacity="0.75" filter="url(#{"bloomWide" if flash else "bloom"})"/>')
            P.add(f'<path d="{arc(cx, cy, r, a0, a1)}" fill="none" stroke="{T["hue_lit"] if full else T["hue"]}" '
                  f'stroke-width="3.6"/>')
    hs.art_slot(P, cx, cy, r - 9, T["ink"], T["trough"], opacity=1 if full else 0.5)
    P.hud(cx - r - 3, cy - r - 3, 2 * r + 6, 2 * r + 6, press=True)
    label = (SKILL.upper(), 16, "TitB", T["ink"], 1.4) if full else (f"{round(charge * 100)}%", 16, "TitB", T["ink"])
    tag_text(P, 78, cy - 4, [label], extra=lift)
    P.add(f'<path d="M 78,{cy + 2} L {78 + (84 if full else 34)},{cy + 2}" stroke="{T["hue_lit"]}" stroke-width="1.4"/>')
    P.add(f'<circle cx="84" cy="{cy + 17}" r="4.2" fill="{T["hue"]}"/>')
    tag_text(P, 94, cy + 22, [("AUTO", 14, "TitB", T["ink"], 1.2)], extra=lift)
    # the eye, in a pair of brackets beside Auto
    ex, ey = 153, cy + 17
    hs.eye_icon(P, ex, ey, 17, T["ink"], T["taken"], sw=1.5)
    P.add(f'<path d="M {ex - 8},{ey - 8} L {ex - 11},{ey - 8} L {ex - 11},{ey + 8} L {ex - 8},{ey + 8} '
          f'M {ex + 8},{ey - 8} L {ex + 11},{ey - 8} L {ex + 11},{ey + 8} L {ex + 8},{ey + 8}" fill="none" '
          f'stroke="{T["hue_lit"]}" stroke-width="1.5"/>')
    P.hud(76, cy - 18, 84 if full else 40, 22, press=True)
    P.hud(78, cy + 9, 86, 17, press=True)
    P.end()
    # the foe: a lighter reticle
    P.begin("foe")
    scrim(P, 284, 20, 78, 24, 0.85)
    bracket(P, 223, 6, 345, 32, 6, T["sub"], w=1.3, glow=False)
    ov.skull(P, 229, 10, 10, T["skulls"][FOE["tier"]], ink=T["deep"], width=1)
    tag_text(P, 244, 21, [(str(FOE["level"]), 14, "TitB", T["ink"]), (FOE["name"].upper(), 14, "Tit", T["ink"], 0.5, 5)],
             extra=lift)
    ov.gem(P, 326, 15.5, 9, TYPES[FOE["type"]], rim=T["deep"], width=0.7)
    ov.arrow(P, 337, 15.5, 8, True, T["hue"], ink=T["deep"], width=0.6)
    tr, fl = hbar(230, 25.5, 108, 3.5, FOE["hp"] / FOE["max"])
    trough(P, tr, fl, T["trough"], T["foe"], "#F59A5E")
    P.hud(223, 6, 122, 26)
    P.end()
    numbers(P, "TitB", T["ink"], T["deep"], "TitB")


DRAW = {"P": (p_frame, "Porcelain Relay"), "S": (s_frame, "Smoked Prism"), "M": (m_frame, "Match-Card"),
        "R": (r_frame, "Resonance Sight")}


# ---- sheets ---------------------------------------------------------------------------------------------------------------
def ff(args):
    subprocess.run(["ffmpeg", "-v", "error", "-y"] + [str(a) for a in args], check=True)


def fit(src, dest, w, h, grey=False):
    """A frame fitted into w x h (letterboxed on black), greyed if asked."""
    vf = f"scale={w}:{h}:force_original_aspect_ratio=decrease,pad={w}:{h}:(ow-iw)/2:(oh-ih)/2:black"
    ff(["-i", src, "-vf", vf + (",hue=s=0" if grey else ""), dest])


def grid(tiles, dest, cols, w, h):
    args = []
    for t in tiles:
        args += ["-i", t]
    n = len(tiles)
    layout = "|".join(f"{(i % cols) * w}_{(i // cols) * h}" for i in range(n))
    ff(args + ["-filter_complex", "".join(f"[{i}:v]" for i in range(n)) + f"xstack=inputs={n}:layout={layout}", dest])


def main():
    args = sys.argv[1:]
    dest = Path(args[0]).resolve()
    grey = "grey" in args
    keys = [k for k in args[1:] if k in DRAW] or list(DRAW)
    for d in (dest, WORK, REFOUT):
        d.mkdir(parents=True, exist_ok=True)
    runs = [(568, "day", 1.0)] if grey else [(568, "day", 1.0), (568, "dusk", 0.62), (852, "day", 1.0), (852, "dusk", 0.62)]
    for k in keys:
        draw, name = DRAW[k]
        for size, ground, charge in runs:
            P = Page(size, ground, grey)
            draw(P, charge)
            out = (WORK if grey else dest) / f"{k}_{size}_{ground}{'_grey' if grey else ''}.png"
            hs.shoot(P, out)
            if grey:
                ff(["-i", out, "-vf", "hue=s=0", out.with_name(out.stem + "_g.png")])
            area = sum(bw * bh for _, _, bw, bh in P.boxes) / (P.w * P.h)
            press = sum(bw * bh for _, _, bw, bh in P.pboxes) / (P.w * P.h)
            least = min(P.sizes)
            print(f"{k} {name} {size} {ground}: the permanent HUD, the press aside, {area:.1%} (the press, Auto and "
                  f"the eye {press:.1%}); the smallest word {least[0]} pt ({least[1]!r})")
        if not grey:   # the press waking, three frames: nearly full, the wake, awake
            frames = []
            for i, (charge, flash) in enumerate(((0.96, False), (1.0, True), (1.0, False))):
                P = Page(568, "day")
                draw(P, charge, flash)
                f = WORK / f"{k}_wake{i}.png"
                hs.shoot(P, f)
                ff(["-i", f, "-vf", "crop=400:200:0:186", f.with_name(f.stem + "_c.png")])
                frames.append(f.with_name(f.stem + "_c.png"))
            grid(frames, dest / f"{k}_wake.png", 3, 400, 200)
    if keys != list(DRAW):
        return
    w, h = 1136, 630
    if grey:
        tiles = []
        for ref, src in SHIPPED.items():
            t = WORK / f"ref_{ref}_grey.png"
            fit(src, t, w, h, grey=True)
            tiles.append(t)
        tiles += [WORK / f"{k}_568_day_grey_g.png" for k in DRAW]
        grid(tiles, REFOUT / "compose_grey.png", 2, w, h)
        return
    ship = WORK / "ref_g05.png"
    fit(SHIPPED["g05"], ship, w, h)
    for ground in ("day", "dusk"):
        four = [dest / f"{k}_568_{ground}.png" for k in DRAW]
        grid(four, dest / f"four_{ground}.png", 2, w, h)
        today = WORK / f"today_{ground}.png"
        fit(hs.GROUNDS[ground], today, w, h)
        grid([today, ship] + four, REFOUT / f"sheet_{ground}.png", 2, w, h)
    print("drew AR68 round 4:", ", ".join(keys))


if __name__ == "__main__":
    main()
