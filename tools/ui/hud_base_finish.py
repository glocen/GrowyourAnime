"""AR62's finish, piece 2: the base's HUD (Rail) and the return panel (Tally), as picked (research, 2026-11-27, 00:07), in
F2's construction (piece 1's finish, picked 2026-11-27, 00:36; hud_finish.py) and its painted icons (hud_icons.py).

The layout and the content are Rail's and Tally's as picked (hud_base.py), with one correction: the dock's three tiles are
icons with no word, its name shown on a long press (the director, 2026-11-15: "we could make a icon of it no need to name it
inventory ... All three icons"; Rail's take printed BASE, HOME and PLAY under them). The construction is F2's: ring stacks,
the slate fills with grain, a 3 px light under each plate's top, every display word in Fredoka One with a near-black
stroke, the meta words flat in Builder Sans, the bars lit from the top over a dark tint of their own hue.

Two takes, for research's pick in pairs, on the one question the study leaves open for the base (research's adaptation,
"Hue per system"): where the systems' colours go.
    K1, Steel: one steel family on every plate; the colour is in the icons and the live bars only; the names are white.
    K2, Hued: each system's colour on its edge, never as a fill or a glow: a band under Credits (gold) and Power (cyan),
        the return panel's Credits card gold-edged and its list azure (yours); the machines' names in their job's hue,
        pale at the top to full at the foot, in the same dark stroke.
Both: the dock is one steel rail; the one you're on is a gold-rimmed cell lit from inside. Icons painted in the set's way
(an ink outline, a cel shadow, one highlight): the coin, the bolt, the battery; the base, Home's cards, Play's flag.

    py tools/ui/hud_base_finish.py <out_dir> <base plate>

Writes, for K1 and K2: <K>_base.png (1920 wide), <K>_base_small.png (the smallest phone), <K>_base_close.png (the strip and
the names at three times), <K>_return.png and <K>_return_small.png; and dock_states.png (the dock at the base, and a long
press on Home showing its word, at three times).
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import style_frames as sf  # noqa: E402
import hud_finish as hf  # noqa: E402
import hud_icons as hi  # noqa: E402
import hud_base as hb  # noqa: E402

W, H, SCALE = hf.W, hf.H, hf.SCALE
T = hf.TAKES["F2"]
STEEL_CARD = dict(ink="#080C14", dark="#1E2839", band=("#D5DFEC", "#8FA0B8"), line="#0A0F18")
GOLD_CARD = dict(ink="#1A0E00", dark="#6A4206", band=("#FFF4C8", "#FFC84A"), line="#241400")
POWER_BAR = dict(outline="#04202A", track=("#0E4656", "#082E3A"), fill=("#E2FBFF", "#6FE3FA", "#22C3E6"), lip="#1590B0")
BANDS = {"credits": ("#FFE9A0", "#F5B52C"), "power": ("#C8F6FF", "#22C3E6")}
JOB_RAMP = {k: ("#FFFFFF", v) for k, v in hb.JOBS.items()}   # a name pale at the top to its job's hue at the foot
INK = hi.INK


# ---- painted icons, in the set's way: in a 24 box, an ink outline, a ramp, the cel shadow, one highlight ------------------
@hi.small
def coin(P, u, hue):
    """Credits: the gold hexagon with its diamond sunk in it, lit at its lower right."""
    hexa = "M12 1.6 L21.4 7 V17 L12 22.4 L2.6 17 V7 Z"
    hi.edge(P, hexa, u)
    hi.form(P, hexa, hi.GILT, (9.2, 8.4, 9.4, 9.6))
    P.add('<path d="M12 6.4 L16.8 12 L12 17.6 L7.2 12 Z" fill="#7A4304"/>'
          '<path d="M16.8 12 L12 17.6 L10.6 16 L14.6 12 Z" fill="#FFE29A"/>')
    hi.shine(P, 5.4, 5.6, 4.4, 1.6, -30)


@hi.small
def bolt(P, u, hue):
    """Power: the generator's bolt, cyan, its right side in shade."""
    d = "M14.6 1.4 L4.2 13.6 H11 L8.8 22.6 L19.8 9.6 H13 Z"
    hi.edge(P, d, u)
    hi.form(P, d, ("#ECFDFF", "#62DDF6", "#1294C2"), (9.6, 9.4, 6.4, 8.4))
    hi.shine(P, 10.6, 4.4, 1.5, 4.2, 40)


@hi.small
def battery(P, u, hue):
    """The battery, full: a steel case, three cells lit in the generator's cyan."""
    body = "M2.4 6.2 H19.2 Q20.4 6.2 20.4 7.4 V16.6 Q20.4 17.8 19.2 17.8 H2.4 Q1.2 17.8 1.2 16.6 V7.4 Q1.2 6.2 2.4 6.2 Z"
    nub = "M20.4 9.4 H22.6 V14.6 H20.4 Z"
    hi.edge(P, body, u)
    hi.edge(P, nub, u)
    hi.form(P, body, hi.STEEL, (8, 9, 12, 7))
    P.add(f'<path d="{nub}" fill="{hi.STEEL[2]}"/><rect x="3.2" y="8.2" width="15.2" height="7.6" rx="0.8" fill="#0B2A36"/>')
    for i in range(3):
        P.add(f'<rect x="{4 + i * 4.9:.2f}" y="9" width="4.1" height="6" rx="0.6" fill="{P.lin(("#D8FAFF", "#3CD2F2"))}"/>')
    hi.shine(P, 3.4, 6.9, 5.2, 0.9)


@hi.small
def base_icon(P, u, hue):
    """Base: a house with the generator's bolt on its door, its roof azure (yours)."""
    whole = "M2.2 12 L12 2.8 L21.8 12 H19.2 V21.4 H4.8 V12 Z"
    roof = "M2.2 12 L12 2.8 L21.8 12 Z"
    hi.edge(P, whole, u)
    hi.form(P, "M4.8 11 H19.2 V21.4 H4.8 Z", hi.BONE, (8.6, 12.6, 9.6, 7.2))
    hi.form(P, roof, ("#B8DDFF", "#4A8CE6", "#1E4C9C"), (8.4, 6.4, 7.4, 6.4))
    P.add(f'<path d="M2.2 12 H21.8" stroke="{INK}" stroke-width="{0.9 * u:.2f}"/>'
          f'<rect x="9.2" y="14" width="5.6" height="7.4" rx="0.8" fill="#1E2838"/>'
          '<path d="M12.6 14.9 L10.4 18.1 H12 L11.4 20.6 L13.7 17.3 H12.1 Z" fill="#5FE0FA"/>')
    hi.shine(P, 6.2, 7.6, 4.6, 1.4, -42)


@hi.small
def home_icon(P, u, hue):
    """Home: its panel of cards, three fanned, the front one gold."""
    card = "M7.2 4 H16.8 Q18.4 4 18.4 5.6 V18.4 Q18.4 20 16.8 20 H7.2 Q5.6 20 5.6 18.4 V5.6 Q5.6 4 7.2 4 Z"
    for turn, ramp, lit in ((-18, hi.DULL, False), (16, hi.STEEL, False), (0, hi.GILT, True)):
        P.add(f'<g transform="rotate({turn} 12 21)">')
        hi.edge(P, card, u)
        hi.form(P, card, ramp, (9.6, 8.6, 6.4, 8))
        if lit:   # the front card's face: an inner frame and the gem of a pick
            P.add(f'<rect x="7.6" y="6" width="8.8" height="12" rx="0.9" fill="none" stroke="#8A5206" '
                  f'stroke-width="{0.8 * u:.2f}"/><path d="M12 8.4 L14.6 12 L12 15.6 L9.4 12 Z" fill="#FFFFFF"/>'
                  '<path d="M14.6 12 L12 15.6 L12 12 Z" fill="#FFD36A"/>')
            hi.shine(P, 7.4, 5, 3.2, 1.2)
        P.add("</g>")


@hi.small
def play_icon(P, u, hue):
    """Play: a pennant on a pole, the grounds' coral, its foot in shade, a gilt finial."""
    pole = "M4.4 3.6 H6.4 V22.4 H4.4 Z"
    flag = "M6.4 4.2 Q13.6 2.4 21.6 7.8 Q13.4 9.6 6.4 14.4 Z"
    hi.edge(P, pole, u)
    hi.edge(P, flag, u)
    P.add(f'<path d="{pole}" fill="{P.lin(hi.STEEL, x2=1, y2=0)}"/>')
    hi.form(P, flag, ("#FFD2C8", "#F2604B", "#A82C1E"), (10.6, 6.2, 8.6, 3.6))
    P.add(f'<circle cx="5.4" cy="3.2" r="2.1" fill="{INK}"/><circle cx="5.4" cy="3.2" r="1.4" fill="{hi.GILT[1]}"/>')
    hi.shine(P, 8.6, 4.4, 4.4, 1.3, -10)


ICONS = {"coin": coin, "bolt": bolt, "battery": battery, "base": base_icon, "home": home_icon, "play": play_icon}


# ---- the pieces ------------------------------------------------------------------------------------------------------------
def plate(P, box, fam, r):
    """A content plate: the card's ring stack in `fam`, the slate with grain, its light under the top edge."""
    x, y, w, h = box
    a, b, c, d = hf.CARD_RINGS
    rings = [(a, fam["ink"]), (b, fam["dark"]), (c, P.lin(fam["band"], x2=1, y2=1)), (d, fam["line"])]
    return P.stack(x, y, w, h, r, rings, P.lin(T["slate"]), top_light=0.5, grain=0.14, vignette=6.5)


def rule(P, x0, x1, y, upright=False):
    """An engraved line: a dark line with a light one beside it."""
    if upright:
        P.add(f'<path d="M{x0},{y} V{x1}" stroke="#05080E" stroke-opacity="0.7" stroke-width="1"/>'
              f'<path d="M{x0 + 1},{y} V{x1}" stroke="#FFFFFF" stroke-opacity="0.12" stroke-width="1"/>')
    else:
        P.add(f'<path d="M{x0},{y} H{x1}" stroke="#05080E" stroke-opacity="0.7" stroke-width="1"/>'
              f'<path d="M{x0},{y + 1} H{x1}" stroke="#FFFFFF" stroke-opacity="0.12" stroke-width="1"/>')


def band(P, x, y, w, hue, clip_box):
    """K2's colour on the edge: a band along a section's foot, inside the plate's fill."""
    cid = P.uid("c")
    fx, fy, fw, fh, fr = clip_box
    P.defs.append(f'<clipPath id="{cid}">{P.rect(fx, fy, fw, fh, fr)}</clipPath>')
    P.add(f'<g clip-path="url(#{cid})"><rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="2.2" '
          f'fill="{P.lin(hue, x2=0, y2=1)}"/><rect x="{x:.2f}" y="{y - 0.8:.2f}" width="{w:.2f}" height="0.8" '
          f'fill="#05080E" fill-opacity="0.6"/></g>')


def strip(P, hued):
    """Rail's one strip: Credits | made and used | the battery."""
    x, y, w, h = 494, 50, 346, 46
    box = plate(P, (x, y, w, h), STEEL_CARD, 6)
    a, b = x + 102, x + w - 70
    for s in (a, b):
        rule(P, s, y + h - 9, y + 9, upright=True)
    if hued:   # along the fill's foot, each under its own section
        foot = box[1] + box[3] - 2.2
        band(P, x, foot, a - x, BANDS["credits"], box)
        band(P, a + 1, foot, b - a - 1, BANDS["power"], box)
    coin(P, x + 10, y + 12, 21)
    P.word(x + 37, y + 29, "72,546", 15.5)
    bolt(P, a + 8, y + 11, 19)
    for i, (n, s) in enumerate((("91 kW", "made"), ("10 kW", "used"))):
        cx = a + 33 + i * 56
        P.word(cx, y + 20.5, n, 13.5)
        P.word(cx + 0.5, y + 31.5, s, 10, role="meta", stroke=None)
    P.bar(a + 33, y + 34.6, b - a - 46, 3.6, 10 / 91, POWER_BAR, r=1.8, lip=0)
    battery(P, b + 8, y + 13, 20)
    P.word(b + 32, y + 28.5, "Full", 12.5)


DOCK = (("base", "BASE"), ("home", "HOME"), ("play", "PLAY"))


def dock(P, at="base", held=None):
    """The rail: one steel plate, three icon cells; the one you're on a gold-rimmed cell lit from inside; `held` shows
    that cell's word, as a long press does."""
    x, y, w = 12, 128, 58
    cell = sf.TAP
    P.press(x, y, w, 3 * cell, 7, T["steel"], P.lin(T["press"]), grain=0.12)
    for i, (kind, word) in enumerate(DOCK):
        cy = y + i * cell
        if i:
            rule(P, x + 9, x + w - 9, cy)
        if kind == at:
            fam = dict(T["steel"], rim=("#FFF1B8", "#F2B636"), dark="#5A3A06")
            P.press(x + 4.5, cy + 4.5, w - 9, cell - 9, 5, fam, P.lin(("#46536C", "#2A3445")), rings=(0.8, 0.8, 0.5, 1.2),
                    grain=0.1)
        s = 44 if kind == at else 42      # the art fills its cell, as a shipped dock's does (beside ACX's lobby)
        ICONS[kind](P, x + (w - s) / 2, cy + (cell - s) / 2, s)
        if held == kind:   # the long press's word, on a chip beside the cell, its pointer at the cell
            tx, ty, tw, th = x + w + 9, cy + cell / 2 - 13, 62, 26
            P.add(f'<path d="M{tx + 1},{ty + 8} L{tx - 6},{ty + 13} L{tx + 1},{ty + 18} Z" fill="{T["steel"]["ink"]}"/>')
            P.press(tx, ty, tw, th, 4, T["steel"], P.lin(T["press"]), rings=(0.8, 0.8, 0.5, 1.0))
            P.add(f'<path d="M{tx + 1.6},{ty + 9.2} L{tx - 3.6},{ty + 13} L{tx + 1.6},{ty + 16.8} Z" '
                  f'fill="{P.lin(T["press"])}"/>')
            P.word(tx + tw / 2, ty + 17.6, word, 12, anchor="middle", stroke=T["steel"]["ink"], spacing=0.6)


def names(P, hued):
    """Each machine's name over the world, no plate and no stem: its job's dot, the word in a heavy dark stroke."""
    for name, job, x, top, _, _ in hb.MACHINES:
        if job == "Training":
            x, top = 704, 200    # clear of Bay 1's name without a stem: over its own mat (as Rail)
        tw = hb.width(name, 12.5) * 1.06
        bx = x - tw / 2 + 6
        P.add(f'<circle cx="{bx - 9}" cy="{top - 14.4}" r="4.2" fill="{INK}"/>'
              f'<circle cx="{bx - 9}" cy="{top - 14.4}" r="3.1" fill="{P.lin(JOB_RAMP[job])}"/>'
              f'<circle cx="{bx - 10}" cy="{top - 15.5}" r="0.9" fill="#FFFFFF"/>')
        fill = P.lin(JOB_RAMP[job]) if hued else "#FFFFFF"
        P.word(bx, top - 10, name, 12.5, fill=fill, stroke="#0C1220", ratio=0.24)


def base(hued, plate_path):
    P = hf.Page(T)
    P.add(f'<image href="{Path(plate_path).resolve().as_uri()}" x="0" y="0" width="{W}" height="{H}"/>')
    names(P, hued)
    hf.lead_card(P, 3732, 3732, taken=None)
    hf.eye(P)
    strip(P, hued)
    dock(P)
    return P.svg()


# ---- the return panel ------------------------------------------------------------------------------------------------------
def image(P, path, x, y, size, crop):
    w, h = sf.png_size(path)
    cx, cy, cs = crop
    k = size / cs
    P.add(f'<image href="{path.as_uri()}" x="{x - cx * k:.2f}" y="{y - cy * k:.2f}" width="{w * k:.2f}" '
          f'height="{h * k:.2f}"/>')


def picture(P, what, x, y, size):
    kind, key = what
    if kind == "stone":
        image(P, hb.STONE[key], x, y, size, hb.STONE_CROP[key])
    elif kind == "jewel":
        image(P, hb.JEWEL, x, y, size, hb.JEWEL_CROP)
    else:   # a portrait in its rarity's frame, as the lead card's
        g = hf.GREY
        fx, fy, fw, _, _ = P.stack(x, y, size, size, 5, [(0.9, g["ink"]), (1.2, g["dark"]),
                                                         (1.3, P.lin(g["band"], x2=1, y2=1)), (0.5, g["line"])], "#E9D6C8")
        cid = P.uid("c")
        P.defs.append(f'<clipPath id="{cid}">{P.rect(fx, fy, fw, fw, 2.6)}</clipPath>')
        P.add(f'<g clip-path="url(#{cid})">')
        image(P, hb.FACE[key], fx, fy, fw, hb.FACE_CROP)
        P.add("</g>")


def ring_icon(P, x, y):
    """The close hint's mark: a ring and its dot, inked."""
    P.add(f'<circle cx="{x}" cy="{y}" r="6.4" fill="none" stroke="#0C1220" stroke-width="4.2"/>'
          f'<circle cx="{x}" cy="{y}" r="6.4" fill="none" stroke="#FFFFFF" stroke-width="1.8"/>'
          f'<circle cx="{x}" cy="{y}" r="3.2" fill="#FFFFFF" stroke="#0C1220" stroke-width="1.4" paint-order="stroke"/>')


def return_panel(hued, plate_path):
    P = hf.Page(T)
    uri = Path(plate_path).resolve().as_uri()
    P.defs.append('<filter id="veil" x="-5%" y="-5%" width="110%" height="110%"><feGaussianBlur stdDeviation="6"/></filter>')
    P.add(f'<image href="{uri}" x="-16" y="-16" width="{W + 32}" height="{H + 32}" filter="url(#veil)" '
          'preserveAspectRatio="none"/>')
    P.add(f'<rect x="0" y="0" width="{W}" height="{H}" fill="#E9EEF5" fill-opacity="0.32"/>')
    lx, ly, lw, lh = 40, 36, 300, 364
    plate(P, (lx, ly, lw, lh), GOLD_CARD if hued else STEEL_CARD, 12)
    P.word(lx + 24, ly + 46, "WELCOME BACK", 23, spacing=1.2)
    P.word(lx + 24, ly + 68, "While you were away,", 12.5, role="meta", stroke=None)
    P.word(lx + 24, ly + 85, "your base kept working.", 12.5, role="meta", stroke=None)
    rule(P, lx + 24, lx + lw - 24, ly + 104)
    g = 44
    coin(P, lx + 22, ly + 136 + g, 50)
    P.word(lx + 84, ly + 172 + g, "+1,240", 36, fill=P.lin(("#FFF6D0", "#FFD45A", "#F2A21C")), stroke="#2A1700",
           ratio=0.16)
    P.word(lx + 86, ly + 194 + g, "Credits", 14)
    battery(P, lx + 22, ly + 222 + g, 20)
    P.word(lx + 50, ly + 236 + g, "Battery full: the spare became Credits.", 11.5, role="meta", stroke=None)
    rx, rw = 356, 456
    plate(P, (rx, ly, rw, lh), hf.AZURE if hued else STEEL_CARD, 12)
    gains = hb.GAINS
    rows = [("Stones", None, [g for g in gains if g[2][0] == "stone"])] + [(g[1], g, None) for g in gains[3:]]
    rh = (lh - 24) / len(rows)
    for i, (title, gain, stones) in enumerate(rows):
        y = ly + 12 + i * rh
        if i:
            rule(P, rx + 18, rx + rw - 18, y)
        mid = y + rh / 2
        if stones:   # the three grades on one row, each its count beside its stone
            P.word(rx + 20, mid + 5, "Stones", 14.5)
            for j, (count, under, what) in enumerate(stones):
                sx = rx + 166 + j * 98
                picture(P, what, sx, mid - 21, 42)
                P.word(sx + 47, mid, count, 16.5)
                P.word(sx + 47, mid + 14, under.split()[0], 10.5, role="meta", stroke=None)
            continue
        count, under, what = gain
        picture(P, what, rx + 18, mid - 22, 44)
        P.word(rx + 74, mid + 5.5, under if what[0] == "face" else under.capitalize(), 14.5)
        P.word(rx + rw - 20, mid + 6, count, 17, anchor="end")
    ring_icon(P, W / 2 - 92, 440)
    P.word(W / 2 + 8, 445, "Tap anywhere to close", 14, anchor="middle", stroke="#0C1220", ratio=0.2)
    return P.svg()


def dock_states(plate_path):
    """The dock at the base, and a long press on Home showing its word, each over the same ground, at three times."""
    cells = [("at the base", None), ("a long press on Home", "home")]
    cw, ch, gap, cap = 150, 214, 6, 18
    P = hf.Page(T)
    uri = Path(plate_path).resolve().as_uri()
    sw = len(cells) * cw + (len(cells) + 1) * gap
    P.add(f'<rect width="{sw}" height="{ch + cap + 2 * gap}" fill="#15191F"/>')
    for i, (label, held) in enumerate(cells):
        cx = gap + i * (cw + gap)
        keep, P.parts = P.parts, []
        P.add(f'<image href="{uri}" x="0" y="0" width="{W}" height="{H}"/>')
        dock(P, held=held)
        inner, P.parts = "".join(P.parts), keep
        P.add(f'<svg x="{cx}" y="{gap}" width="{cw}" height="{ch}" viewBox="0 120 {cw} {ch}">{inner}</svg>')
        P.add(f'<text x="{cx + cw / 2}" y="{gap + ch + 13}" font-family="Builder Sans" font-size="10" fill="#E8EDF4" '
              f'text-anchor="middle">{sf.esc(label)}</text>')
    return P.svg(sw, ch + cap + 2 * gap), sw, ch + cap + 2 * gap


def main():
    out, plate_path = Path(sys.argv[1]).resolve(), sys.argv[2]
    out.mkdir(parents=True, exist_ok=True)
    hf.PAINTED = hi.PAINTED     # the lead card's gem and sword and the eye, painted (the set's pass, 639965a8)
    css = hf.faces()
    for k, hued in (("K1", False), ("K2", True)):
        svg = base(hued, plate_path)
        sf.shoot(sf.html(svg, css, W, H), out / f"{k}_base.png", W, H, scale=SCALE)
        sf.shoot(sf.html(svg, css, W, H, zoom=568 / W), out / f"{k}_base_small.png", 568, round(H * 568 / W), scale=1)
        close = svg.replace(f'viewBox="0 0 {W} {H}"', 'viewBox="380 40 472 180"').replace(
            f'width="{W}" height="{H}"', 'width="472" height="180"', 1)
        sf.shoot(sf.html(close, css, 472, 180), out / f"{k}_base_close.png", 472, 180, scale=3)
        svg = return_panel(hued, plate_path)
        sf.shoot(sf.html(svg, css, W, H), out / f"{k}_return.png", W, H, scale=SCALE)
        sf.shoot(sf.html(svg, css, W, H, zoom=568 / W), out / f"{k}_return_small.png", 568, round(H * 568 / W), scale=1)
        print("drew", k)
    svg, sw, sh = dock_states(plate_path)
    sf.shoot(sf.html(svg, css, sw, sh), out / "dock_states.png", sw, sh, scale=3)
    print("drew the dock's states")


if __name__ == "__main__":
    main()
