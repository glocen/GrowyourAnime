"""AR62's finish, piece 1 (the fight's HUD), as targets: B's layout, exactly as picked, with the surface study's construction
(docs/research/anime-crusaders-ui-surface.md, "What our finish should do" and research's adaptation, 2026-11-27, 00:19).

Two takes over the same fight capture (research's ask, 2026-11-27, after 00:19):
    F1, B's mid slate, with the full construction;
    F2, the same construction on a deeper slate, never near-black: is the dark ground what makes it premium?

The construction, as the study's rules number it:
    1  every press is a ring stack: a near-black hairline, its hue at about 25%, a black hairline, a rim brighter than the
       fill, the fill; a card is the same stack in its side's hue (azure yours, coral theirs) with a bright band;
    2  presses lit from below, cards from the top with a 3 px highlight;
    3  colour on the edge, slate in the middle; full chroma only on the press, the bars and the live numbers;
    4  one rounded heavy face from Roblox's own (Fredoka One) for names and numbers, every display word in a hue-tinted
       near-black stroke at about 18% of its cap; the plain sans (Builder Sans) for meta, flat; coloured words pale at the
       top to saturated at the bottom;
    5  the portrait and the level cross the card's edge, the damage taken crosses its top;
    6  one glow, on the press when it's ready;
    7  our own fine grain on every fill over about 100 px, and a soft inner vignette;
    8  bars on a dark tint of their own hue inside a black line, lit from the top with a darker lip, notched every 1,000;
    9  a fixed state grammar (the strip: ready, firing, cooling; Auto on and off; the keyboard's chip);
    10 radii about 14% of the height on presses, about 10% on cards; a disc only for the signature, the one big press.
Icons in the style: cel-shaded, an ink outline, a lit facet and a specular point (the gem, the sword, the skull, the eye,
the signature's fist). Every piece is one Roblox builds: frames with UICorner and UIStroke, UIGradients, a tiled grain image,
a 9-slice vignette image, images for the icons, TextLabels with a UIStroke.

    py tools/ui/hud_finish.py <out_dir> <fight plate> [F1 F2]

Writes <T>_fight.png (1920 x 1066), <T>_fight_small.png (568 wide, the smallest phone), <T>_close.png (the lead card, the
signature, Auto, the eye and the foe card at three times), <T>_states.png (at three times) and, for the gates,
<T>_fight_bare.png (no words: the ground each word sits on).
"""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import style_frames as sf  # noqa: E402
import hud_palettes as hp  # noqa: E402

W, H, SCALE = hp.W, hp.H, hp.SCALE
FACES = {"display": ("FredokaOne-Regular.ttf", "Fredoka One"), "meta": ("BuilderSans-Bold.otf", "Builder Sans")}
CAP = 0.70          # cap height over the em, both faces (ESTIMATED from the renders)
STROKE = 0.18       # a display word's stroke over its cap height (the study: 15 to 20% under 30 px)

# each family one hue in its values: a near-black hairline, the hue at about 25%, a bright band or rim, a dark line
AZURE = dict(ink="#06142A", dark="#1A4378", band=("#A9DCFF", "#4A93F0"), line="#0A1A33")
CORAL = dict(ink="#1F0705", dark="#7C2819", band=("#FFBBAA", "#EE5A46"), line="#2B0B07")
GREY = dict(ink="#0E1015", dark="#434955", band=("#F1F4F8", "#A7AEBB"), line="#101218")   # Common, Rook's rarity
GOLD = dict(ink="#1A0E00", dark="#6A4206", rim=("#FFF4C8", "#FFD457"), fill=("#D08612", "#FFCB40"),
            word="#2A1700", glow="#FFC94A")
HEALTH = dict(outline="#16060B", track=("#5C1727", "#3C0D18"), fill=("#FFA6B0", "#FF6478", "#DE3954"), lip="#9A1C34")
XP = dict(outline="#071326", track=("#123056", "#0B1E38"), fill=("#E2F6FF", "#7CCBFF", "#4AA6F2"), lip="#2C78C4")
POISE = dict(outline="#1A0E00", track=("#4A2E05", "#2E1C02"), fill=("#FFE79A", "#FFC23C", "#E59A12"), lip="#A86A06")

TAKES = {
    "F1": dict(name="Mid slate", line="B's mid slate with the full construction",
               slate=("#52627A", "#405066"), press=("#3E4B60", "#62728C"),
               steel=dict(ink="#0A101A", dark="#26324A", rim=("#E3ECF7", "#A3B3CA"))),
    "F2": dict(name="Deep slate", line="the same construction on a deeper slate, never near-black",
               slate=("#2F3A4B", "#1F2632"), press=("#252E3D", "#434F67"),
               steel=dict(ink="#080C14", dark="#1E2839", rim=("#D5DFEC", "#8FA0B8"))),
}

CARD = (12, 50, 206, 58)
ART = None          # the signature's art: None draws the flat mark; else art(P, cx, cy, inner radius, state) (hud_icons.py)
PAINTED = None      # the painted set: None draws the flat marks; else {kind: paint(P, x, y, size, hue)} (hud_icons.py)
FOE = (318, 50, 216, 50)
SIG = (47, 160, 33)          # the signature's centre and radius: 66 across, the TAP height
AUTO = (96, 147, 66, 26)
EYE = (225, 52, 26, 26)
CARD_RINGS = (0.9, 1.3, 1.8, 0.6)   # hairline, the hue's dark, the band, the dark line: 4.6 pt, about 10 px
PRESS_RINGS = (0.9, 1.0, 0.6, 1.1)  # hairline, the hue's dark, a black hairline, the rim: about 4% of 26 pt each


class Page:
    def __init__(self, T, bare=False):
        self.T, self.bare, self.parts, self.defs, self.n = T, bare, [], [], 0
        self.defs.append(   # our own grain: fractal noise as grey, laid over a fill by overlay
            '<filter id="grain" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" '
            'baseFrequency="1.25" numOctaves="2" seed="11" stitchTiles="stitch"/><feColorMatrix type="matrix" '
            'values="1 0 0 0 0  1 0 0 0 0  1 0 0 0 0  0 0 0 0 1"/></filter>')
        self.defs.append('<filter id="lift" x="-20%" y="-20%" width="140%" height="160%"><feDropShadow dx="0" dy="1.6" '
                         'stdDeviation="1.8" flood-color="#0B1018" flood-opacity="0.42"/></filter>')
        self.defs.append('<filter id="vblur" x="-10%" y="-10%" width="120%" height="120%"><feGaussianBlur stdDeviation="2.6"/></filter>')
        self.defs.append('<filter id="glow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="5"/></filter>')

    def uid(self, p):
        self.n += 1
        return f"{p}{self.n}"

    def lin(self, stops, x2=0, y2=1):
        gid = self.uid("g")
        n = len(stops)
        s = "".join(f'<stop offset="{i / (n - 1):.3f}" stop-color="{c}"/>' for i, c in enumerate(stops))
        self.defs.append(f'<linearGradient id="{gid}" x1="0" y1="0" x2="{x2}" y2="{y2}">{s}</linearGradient>')
        return f"url(#{gid})"

    def add(self, s):
        self.parts.append(s)

    def svg(self, w=W, h=H):
        return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'
                f'<defs>{"".join(self.defs)}</defs>{"".join(self.parts)}</svg>')

    # ---- the construction --------------------------------------------------------------------------------------------
    @staticmethod
    def rect(x, y, w, h, r, extra=""):
        return f'<rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="{h:.2f}" rx="{max(r, 0):.2f}"{extra}/>'

    def stack(self, x, y, w, h, r, rings, fill, top_light=0.0, grain=0.0, vignette=0.0, shadow=True, glow=None):
        """Rings from the outside in (width, paint), then the fill; returns the fill's box."""
        if glow:
            c, spread, a = glow
            self.add(self.rect(x - spread, y - spread, w + 2 * spread, h + 2 * spread, r + spread,
                               f' fill="{c}" fill-opacity="{a}" filter="url(#glow)"'))
        if shadow:
            self.add(self.rect(x, y, w, h, r, ' fill="#0B1018" fill-opacity="0.5" filter="url(#lift)"'))
        i = 0.0
        for width, paint in rings:
            self.add(self.rect(x + i, y + i, w - 2 * i, h - 2 * i, r - i, f' fill="{paint}"'))
            i += width
        fx, fy, fw, fh, fr = x + i, y + i, w - 2 * i, h - 2 * i, max(r - i, 0)
        self.add(self.rect(fx, fy, fw, fh, fr, f' fill="{fill}"'))
        cid = self.uid("c")
        self.defs.append(f'<clipPath id="{cid}">{self.rect(fx, fy, fw, fh, fr)}</clipPath>')
        if grain:
            noise = self.rect(fx, fy, fw, fh, 0, ' filter="url(#grain)"')
            self.add(f'<g clip-path="url(#{cid})" style="mix-blend-mode:overlay" opacity="{grain}">{noise}</g>')
        if vignette:
            edge = self.rect(fx, fy, fw, fh, fr, f' fill="none" stroke="#000" stroke-opacity="0.22" '
                                                 f'stroke-width="{2 * vignette:.1f}" filter="url(#vblur)"')
            self.add(f'<g clip-path="url(#{cid})">{edge}</g>')
        if top_light:   # the content plate's 3 px highlight under its top edge, at about 50% white
            self.add(f'<g clip-path="url(#{cid})"><rect x="{fx:.2f}" y="{fy:.2f}" width="{fw:.2f}" height="{1.3:.2f}" '
                     f'fill="#FFFFFF" fill-opacity="{top_light}"/></g>')
        return fx, fy, fw, fh, fr

    def card(self, box, fam):
        x, y, w, h = box
        T = self.T
        a, b, c, d = CARD_RINGS
        rings = [(a, fam["ink"]), (b, fam["dark"]), (c, self.lin(fam["band"], x2=1, y2=1)), (d, fam["line"])]
        return self.stack(x, y, w, h, round(h * 0.1, 1), rings, self.lin(T["slate"]), top_light=0.5, grain=0.14,
                          vignette=6.5)

    def press(self, x, y, w, h, r, fam, fill, rings=PRESS_RINGS, glow=None, grain=0.0):
        a, b, c, d = rings
        rr = [(a, fam["ink"]), (b, fam["dark"]), (c, "#000000"), (d, self.lin(fam["rim"]))]
        return self.stack(x, y, w, h, r, rr, fill, grain=grain, vignette=0, glow=glow)

    def word(self, x, y, s, size, role="display", fill="#FFFFFF", stroke="#0A1528", anchor="start", spacing=0.0,
             opacity=1.0, ratio=STROKE):
        if self.bare:
            return
        fam = FACES[role][1]
        st = (f' stroke="{stroke}" stroke-width="{2 * ratio * CAP * size:.2f}" stroke-linejoin="round" paint-order="stroke"'
              if stroke else "")
        sp = f' letter-spacing="{spacing}"' if spacing else ""
        op = f' opacity="{opacity}"' if opacity != 1 else ""
        self.add(f'<text x="{x:.2f}" y="{y:.2f}" font-family="{fam}" font-size="{size}" fill="{fill}" text-anchor="{anchor}"'
                 f'{st}{sp}{op}>{sf.esc(s)}</text>')

    def bar(self, x, y, w, h, share, fam, r=2.2, notch=None, lip=0.9):
        o = 0.7
        self.add(self.rect(x - o, y - o, w + 2 * o, h + 2 * o, r + o, f' fill="{fam["outline"]}"'))
        self.add(self.rect(x, y, w, h, r, f' fill="{self.lin(fam["track"])}"'))
        fw = max(w * share, 2 * r)
        self.add(self.rect(x, y, fw, h, r, f' fill="{self.lin(fam["fill"])}"'))
        cid = self.uid("c")
        self.defs.append(f'<clipPath id="{cid}">{self.rect(x, y, fw, h, r)}</clipPath>')
        g = f'<g clip-path="url(#{cid})">'
        if lip and h >= 6:
            g += f'<rect x="{x:.2f}" y="{y + h - lip:.2f}" width="{fw:.2f}" height="{lip}" fill="{fam["lip"]}"/>'
        if h >= 6:
            g += f'<rect x="{x:.2f}" y="{y + 0.7:.2f}" width="{fw:.2f}" height="0.7" fill="#FFFFFF" fill-opacity="0.45"/>'
        g += "</g>"
        self.add(g)
        if notch:   # a chunk every `notch` of the whole, across the track too
            total, step = notch
            k = step
            while k < total:
                nx = x + w * k / total
                self.add(f'<rect x="{nx - 0.35:.2f}" y="{y + 0.6:.2f}" width="0.7" height="{h - 1.2:.2f}" '
                         f'fill="{fam["outline"]}" fill-opacity="0.55"/>')
                k += step

    def on_bar(self, x, y, s, size, edge="#16060B"):
        self.word(x, y, s, size, fill="#FFFFFF", stroke=edge, anchor="middle", ratio=0.22)

    # ---- icons in the style: an ink outline, the hue, a cel shadow, a lit facet, a specular point ---------------------
    def icon(self, kind, x, y, size, hue=None, ink="#14161C", o=0.75):
        if PAINTED and kind in PAINTED:
            PAINTED[kind](self, x, y, size, hue)
            return
        k = size / 24
        sw = 2 * o / k      # the outline's stroke, drawn under its fill: `o` points showing outside
        out = f' stroke="{ink}" stroke-width="{sw:.2f}" stroke-linejoin="round" paint-order="stroke"'
        g = f'<g transform="translate({x:.2f},{y:.2f}) scale({k:.4f})">'
        if kind == "gem":
            c, d, l = hue
            g += (f'<path d="M12 1.5 L21 8 L17.5 21 H6.5 L3 8 Z" fill="{c}"{out}/>'
                  f'<path d="M12 10.5 L21 8 L17.5 21 L12 21 Z" fill="{d}"/>'
                  f'<path d="M12 1.5 L21 8 L12 10.5 L3 8 Z" fill="{l}"/>'
                  f'<path d="M6.5 6.2 L9.2 4.4" stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round"/>')
        elif kind == "sword":
            g += (f'<path d="M17.5 2 L22 2 L22 6.5 L10.5 18 L6 13.5 Z" fill="#EEF3FA"{out}/>'
                  f'<path d="M22 2 L22 6.5 L10.5 18 L8.3 15.8 Z" fill="#9DAEC6"/>'
                  f'<path d="M4 12 L12 20 L10 22 L2 14 Z" fill="#F4BA45"{out}/>'
                  f'<path d="M8 16 L12 20 L10 22 L6 18 Z" fill="#B57A10"/>'
                  f'<path d="M5.2 18.8 L2.6 21.4" stroke="{ink}" stroke-width="{2.9 + sw:.2f}" stroke-linecap="round"/>'
                  f'<path d="M5.2 18.8 L2.6 21.4" stroke="#5A3A18" stroke-width="2.9" stroke-linecap="round"/>'
                  f'<path d="M19.6 3.2 L12.6 10.2" stroke="#FFFFFF" stroke-width="1.1" stroke-linecap="round"/>')
        elif kind == "skull":
            body = ('M12 2.5 C6.5 2.5 3.5 6.3 3.5 10.5 C3.5 13.4 5 15.4 7 16.5 V20.5 H17 V16.5 C19 15.4 20.5 13.4 20.5 10.5 '
                    'C20.5 6.3 17.5 2.5 12 2.5 Z')
            cid = self.uid("c")
            self.defs.append(f'<clipPath id="{cid}"><path d="{body}"/></clipPath>')
            g += (f'<path d="{body}" fill="#F7F3EA"{out}/>'
                  f'<g clip-path="url(#{cid})"><path d="M0 14.5 Q12 18 24 12.5 V24 H0 Z" fill="#CFC6B4"/></g>'
                  f'<ellipse cx="8.5" cy="11" rx="2.5" ry="2.7" fill="{ink}"/><ellipse cx="15.5" cy="11" rx="2.5" ry="2.7" fill="{ink}"/>'
                  f'<path d="M12 13.4 L13.1 15.4 H10.9 Z" fill="{ink}"/>'
                  f'<path d="M10 18 V20.5 M14 18 V20.5" stroke="{ink}" stroke-width="1.3"/>'
                  f'<circle cx="7.4" cy="6.3" r="1.2" fill="#FFFFFF"/>')
        elif kind == "eye":
            almond = "M1.5 12 Q12 2.5 22.5 12 Q12 21.5 1.5 12 Z"
            cid = self.uid("c")
            self.defs.append(f'<clipPath id="{cid}"><path d="{almond}"/></clipPath>')
            g += (f'<path d="{almond}" fill="#FFFFFF"{out}/>'
                  f'<g clip-path="url(#{cid})"><rect x="0" y="13.4" width="24" height="10" fill="#C7D2E2"/></g>'
                  f'<circle cx="12" cy="12" r="4.6" fill="#1D2A40" stroke="{ink}" stroke-width="0.8"/>'
                  f'<circle cx="12" cy="12" r="2.2" fill="#0A0F18"/><circle cx="13.6" cy="10.4" r="1.3" fill="#FFFFFF"/>')
        elif kind == "fist":   # Rook's slam: a fist thrown at the viewer, three short strokes of its blow over it
            fist = ('M5 9.6 C5 8.1 6.1 7 7.5 7 C8.2 7 8.8 7.3 9.2 7.7 C9.6 6.9 10.4 6.4 11.4 6.4 C12.4 6.4 13.2 6.9 13.6 7.7 '
                    'C14 7.1 14.8 6.7 15.7 6.7 C17.1 6.7 18.2 7.8 18.2 9.2 V9.6 C18.6 9.3 19.1 9.1 19.6 9.1 C20.9 9.1 21.6 '
                    '10.1 21.6 11.4 V14.6 C21.6 18.6 18.6 21.6 14.6 21.6 H11.2 C7.7 21.6 5 18.9 5 15.4 Z')
            cid = self.uid("c")
            self.defs.append(f'<clipPath id="{cid}"><path d="{fist}"/></clipPath>')
            blow = "M7.4 3.6 L8.2 1.4 M12 3.2 V0.8 M16.6 3.6 L15.8 1.4"
            g += (f'<path d="{blow}" stroke="{ink}" stroke-width="{1.7 + sw:.2f}" stroke-linecap="round"/>'
                  f'<path d="{blow}" stroke="#FFFFFF" stroke-width="1.7" stroke-linecap="round"/>'
                  f'<path d="{fist}" fill="#FFF6E2"{out}/>'
                  f'<g clip-path="url(#{cid})"><path d="M24 11 Q15 15.5 8 24 H24 Z" fill="#E7C27A"/></g>'
                  f'<path d="M9.2 7.9 V12 M13.6 7.9 V12 M18.2 9.6 V12.6 M6.6 15.2 H13.4 C14.6 15.2 15.5 14.3 15.5 13.1" '
                  f'fill="none" stroke="{ink}" stroke-width="1.2" stroke-linecap="round"/>'
                  f'<ellipse cx="11.3" cy="8.4" rx="1.3" ry="0.8" fill="#FFFFFF"/>')
        elif kind == "auto":   # a ring turning on itself
            c = hue
            arc = "M19 12 A7 7 0 1 1 15.6 6"
            head = "M14.2 2.6 L19.6 5.6 L14.6 9.2 Z"
            g += (f'<path d="{arc}" fill="none" stroke="{ink}" stroke-width="{2.8 + sw:.2f}" stroke-linecap="round"/>'
                  f'<path d="{head}" fill="{c}"{out}/>'
                  f'<path d="{arc}" fill="none" stroke="{c}" stroke-width="2.8" stroke-linecap="round"/>')
        g += "</g>"
        self.add(g)


# ---- the pieces --------------------------------------------------------------------------------------------------------
GEM_RED = (sf.TYPES["Red"], "#A82A30", "#FF9EA0")
PORTRAIT = (5, 42, 54, 54)      # crosses the card's top and left edges
LEVEL = (7, 89, 26, 15)         # astride the portrait's foot, across the card's left edge


def lead_card(P, health=3682, most=3732, taken="-15"):
    x, y, w, h = CARD
    P.card(CARD, AZURE)
    # the portrait in its rarity's frame
    px, py, pw, _ = PORTRAIT
    g = GREY
    fx, fy, fw, _, _ = P.stack(px, py, pw, pw, 5, [(0.9, g["ink"]), (1.2, g["dark"]), (1.3, P.lin(g["band"], x2=1, y2=1)),
                                                    (0.5, g["line"])], "#E9D6C8")
    cid = P.uid("c")
    P.defs.append(f'<clipPath id="{cid}">{P.rect(fx, fy, fw, fw, 2.4)}</clipPath>')
    sx, sy, ss = 14.5, 65.5, 42.0     # the game's own portrait, from today's card in the capture
    k = fw / ss
    P.add(f'<g clip-path="url(#{cid})"><image href="{hp.FIGHT_SRC.as_uri()}" x="{fx - sx * k:.2f}" y="{fy - sy * k:.2f}" '
          f'width="{W * k:.2f}" height="{H * k:.2f}"/></g>')
    # the level: a gold chip astride the portrait's foot
    lx, ly, lw, lh = LEVEL
    P.press(lx, ly, lw, lh, 2.1, GOLD, P.lin(GOLD["fill"]), rings=(0.8, 0.7, 0.4, 0.8))
    P.word(lx + lw / 2, ly + 11.4, "26", 10, fill="#FFFFFF", stroke=GOLD["word"], anchor="middle", ratio=0.2)
    nx = 73
    P.word(nx, y + 19.5, "ROOK", 13.5, stroke=AZURE["ink"], spacing=0.6)
    gx = nx + 43
    P.icon("gem", gx, y + 7.5, 12.5, GEM_RED)
    P.icon("sword", gx + 16, y + 8, 11.5)
    hx, hy, hw, hh = nx, y + 25, x + w - nx - 8, 14
    P.bar(hx, hy, hw, hh, health / most, HEALTH, notch=(most, 1000))
    P.on_bar(hx + hw / 2, hy + 10.8, f"{health:,}/{most:,}", 10.5)
    P.bar(hx, hy + hh + 5, hw, 3.5, 0.38, XP, r=1.75, lip=0)
    if taken:   # the lead's damage taken, across the card's top edge over the bar's draining end
        P.word(x + w - 9, y + 4.6, taken, 13, fill=P.lin(("#FFD6DA", "#FF8A96", "#FF3D57")), stroke="#2A0610",
               anchor="end", ratio=0.22)


def eye(P):
    x, y, w, h = EYE
    T = P.T
    P.press(x, y, w, h, 3.6, T["steel"], P.lin(T["press"]))
    P.icon("eye", x + 4.5, y + 4.5, 17)


def signature(P, state="ready", key=False):
    T = P.T
    cx, cy, r = SIG
    ready, firing, cooling = state == "ready", state == "firing", state == "cooling"
    if ready or firing:   # light only on what matters now: the press when it's ready
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{r + (11 if firing else 7)}" fill="{GOLD["glow"]}" '
              f'fill-opacity="{0.7 if firing else 0.5}" filter="url(#glow)"/>')
    rc = r + 4.2    # the charge: a dark gold track, the charge lit on it
    P.add(f'<circle cx="{cx}" cy="{cy}" r="{rc}" fill="none" stroke="{GOLD["ink"]}" stroke-opacity="0.75" stroke-width="3.8"/>')
    P.add(f'<circle cx="{cx}" cy="{cy}" r="{rc}" fill="none" stroke="#4A2E05" stroke-width="2.4"/>')
    share = 0.4 if cooling else 1.0
    if share >= 1:
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{rc}" fill="none" stroke="{P.lin(("#FFF1B8", "#FFC63C"))}" stroke-width="2.4"/>')
    else:
        a = 2 * math.pi * share
        ex, ey = cx + rc * math.sin(a), cy - rc * math.cos(a)
        P.add(f'<path d="M{cx},{cy - rc} A{rc} {rc} 0 {1 if share > 0.5 else 0} 1 {ex:.2f},{ey:.2f}" fill="none" '
              f'stroke="#FFD04F" stroke-width="2.4" stroke-linecap="round"/>')
    g = ""
    if firing:   # pressed: the disc gives a little, flashes, and throws a ring of light
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{r + 9}" fill="none" stroke="#FFFFFF" stroke-opacity="0.85" stroke-width="2.2"/>')
        g = f'<g transform="translate({cx},{cy}) scale(0.94) translate({-cx},{-cy})">'
        P.add(g)
    fill = P.lin(("#FFE48A", "#FFF6CC")) if firing else P.lin(("#7E6230", "#A88A4C")) if cooling else P.lin(GOLD["fill"])
    fam = dict(GOLD, rim=("#FFFFFF", "#FFF0B0")) if firing else dict(GOLD, rim=("#E5D3A2", "#C2A866"), dark="#4A3410") \
        if cooling else GOLD
    P.press(cx - r, cy - r, 2 * r, 2 * r, r, fam, fill, rings=(1.2, 2.0, 0.9, 2.0), grain=0.14)
    if not cooling:   # the disc's lit curve, from below
        P.add(f'<path d="M{cx - r * 0.6:.1f},{cy + r * 0.58:.1f} A{r * 0.84:.1f} {r * 0.84:.1f} 0 0 0 {cx + r * 0.6:.1f},'
              f'{cy + r * 0.58:.1f}" fill="none" stroke="#FFFFFF" stroke-opacity="0.4" stroke-width="1.6" stroke-linecap="round"/>')
    if ART:
        ART(P, cx, cy, r - 6.1, state)
    else:
        s = 38
        P.add(f'<g opacity="{0.42 if cooling else 1}">')
        P.icon("fist", cx - s / 2, cy - s / 2 + 1, s, ink="#22170A", o=0.9)
        P.add("</g>")
    if cooling:
        P.word(cx, cy + 9, "4", 26, fill="#FFFFFF", stroke=GOLD["ink"], anchor="middle", ratio=0.2)
    if g:
        P.add("</g>")
    if key:   # on a keyboard: the key on a chip at the press's top left
        kx, ky, ks = cx - r * 0.86 - 8, cy - r * 0.86 - 8, 16
        P.press(kx, ky, ks, ks, 2.3, T["steel"], P.lin(T["press"]), rings=(0.8, 0.7, 0.4, 0.8))
        P.word(kx + ks / 2, ky + 11.7, "R", 10.5, anchor="middle", stroke=T["steel"]["ink"], ratio=0.2)


def auto(P, on=True):
    T = P.T
    x, y, w, h = AUTO
    fam = dict(T["steel"], rim=("#FFF1B8", "#F2B636"), dark="#5A3A06") if on else T["steel"]
    P.press(x, y, w, h, 3.6, fam, P.lin(T["press"]), grain=0.12)
    c = "#FFCB45" if on else "#AEB9C9"
    P.icon("auto", x + 6.5, y + 4.5, 17, c, ink="#0A101A", o=0.7)
    P.word(x + 27.5, y + 17.6, "AUTO", 10.5, stroke=T["steel"]["ink"], spacing=0.5)   # off: told by the grey rim and turn


def foe_card(P, health=2964, most=4290):
    x, y, w, h = FOE
    P.card(FOE, CORAL)
    P.icon("skull", x + 8, y + 6.5, 14.5)
    P.word(x + 28, y + 17.4, "Lv 26", 10.5, role="meta", stroke=None)
    P.word(x + 62, y + 17.8, "BRAWLER", 13, stroke=CORAL["ink"], spacing=0.6)
    P.icon("gem", x + w - 21, y + 6, 12.5, GEM_RED)
    hx, hw = x + 8, w - 16
    P.bar(hx, y + 23.5, hw, 13, health / most, HEALTH, notch=(most, 1000))
    P.on_bar(hx + hw / 2, y + 33.6, f"{health:,}/{most:,}", 10)
    P.bar(hx, y + 40.5, hw, 3, 0.64, POISE, r=1.5, lip=0)


def fight(T, plate, bare=False):
    P = Page(T, bare)
    P.add(f'<image href="{Path(plate).resolve().as_uri()}" x="0" y="0" width="{W}" height="{H}"/>')
    lead_card(P)
    eye(P)
    signature(P)
    auto(P)
    foe_card(P)
    return P.svg()


def states(T, plate):
    """The state grammar, each cell over the same ground: the press ready, firing, cooling, on a keyboard; Auto on, off."""
    cw, ch, gap, cap = 128, 104, 6, 18
    cells = [("ready", (-17, 108)), ("firing", (-17, 108)), ("cooling, 4 s left", (-17, 108)),
             ("ready, on a keyboard", (-17, 108)), ("Auto on", (65, 108)), ("Auto off", (65, 108))]
    P = Page(T)
    uri = Path(plate).resolve().as_uri()
    sw = len(cells) * cw + (len(cells) + 1) * gap
    P.add(f'<rect width="{sw}" height="{ch + cap + 2 * gap}" fill="#15191F"/>')
    for i, (name, (bx, by)) in enumerate(cells):
        cx = gap + i * (cw + gap)
        keep, P.parts = P.parts, []
        P.add(f'<image href="{uri}" x="0" y="0" width="{W}" height="{H}"/>')
        if name.startswith("Auto"):
            auto(P, on=name == "Auto on")
        else:
            signature(P, state=name.split(",")[0], key="keyboard" in name)
        inner, P.parts = "".join(P.parts), keep
        P.add(f'<svg x="{cx}" y="{gap}" width="{cw}" height="{ch}" viewBox="{bx} {by} {cw} {ch}">{inner}</svg>')
        P.add(f'<text x="{cx + cw / 2}" y="{gap + ch + 13}" font-family="Builder Sans" font-size="10" fill="#E8EDF4" '
              f'text-anchor="middle">{sf.esc(name)}</text>')
    return P.svg(sw, ch + cap + 2 * gap), sw, ch + cap + 2 * gap


def faces():
    return "".join(f'@font-face{{font-family:"{fam}";src:url("{(sf.FONTS / file).as_uri()}")}}' for file, fam in FACES.values())


def main():
    out, plate = Path(sys.argv[1]).resolve(), sys.argv[2]
    keys = [k for k in sys.argv[3:] if k in TAKES] or list(TAKES)
    out.mkdir(parents=True, exist_ok=True)
    css = faces()
    for k in keys:
        T = TAKES[k]
        svg = fight(T, plate)
        sf.shoot(sf.html(svg, css, W, H), out / f"{k}_fight.png", W, H, scale=SCALE)
        sf.shoot(sf.html(fight(T, plate, bare=True), css, W, H), out / f"{k}_fight_bare.png", W, H, scale=SCALE)
        sf.shoot(sf.html(svg, css, W, H, zoom=568 / W), out / f"{k}_fight_small.png", 568, round(H * 568 / W), scale=1)
        close = svg.replace(f'viewBox="0 0 {W} {H}"', 'viewBox="0 36 560 176"').replace(f'width="{W}" height="{H}"',
                                                                                         'width="560" height="176"', 1)
        sf.shoot(sf.html(close, css, 560, 176), out / f"{k}_close.png", 560, 176, scale=3)
        svg, sw, sh = states(T, plate)
        sf.shoot(sf.html(svg, css, sw, sh), out / f"{k}_states.png", sw, sh, scale=3)
        print("drew", k, T["name"])


if __name__ == "__main__":
    main()
