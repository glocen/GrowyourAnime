"""AR62, the HUD overhaul: three palette directions, each painted over the same phone captures (research's brief,
2026-11-26, "The HUD overhaul"), piece by piece (the director, 2026-11-26: "we do it piece by piece if that suit you better").
Piece 1, the fight's HUD: the lead's card, the signature, Auto, the eye (spectate), the foe's card, the numbers.

The director's words on this pass (2026-11-26, before 23:38): "take your time with the UI it need to be mature and polished, look
at that auto mode way to big", then "same for the spectate mode". So every take is quiet and composed, with one accent:
    - thin strokes, modest radii, short soft shadows; words without heavy outlines;
    - the signature is the one big press; Auto and the eye are small, each on a TAP-sized tap area (style_frames.TAP);
    - a fight shows only what the fight needs: no pills and no dock;
    - the lead's damage taken reads at its own card, never over the fighters; the hits dealt keep to the target, the latest
      big and the two before it smaller and fading (drawn in the numbers strip: the fight plate still holds today's pile).
Every piece is one Roblox builds: a frame with a stroke (UICorner, UIStroke), a gradient, an image, a text, a drop shadow
image. Light stays inside its piece. Plates are bright or mid-value: never near-black, never washed in violet.

    py tools/ui/hud_palettes.py <out_dir> <fight plate> [A B C]

The plate is the 1920 x 1066 capture with today's HUD taken out (build/scratch/modulo/hud/clean_plates.py, until Faber's
clean capture). Drawn on an 852-wide page, the size every HUD number is set at, and shot at the capture's pixels.
Writes <T>_fight.png, <T>_fight_small.png (the smallest phone, 568 wide), <T>_numbers.png and <T>_close.png (the pieces
at three times) for each take.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import style_frames as sf  # noqa: E402

W, H = 852, 473                     # the page: 1920 x 1066 at 852 wide
SCALE = 1920 / W
FIGHT_SRC = sf.REPO / "build/captures/ar48_install/break_player_camera.jpg"   # the portrait: the game's own, from its card
NUMBERS = dict(dealt="#FFF6E2", element=sf.TYPES["Red"], crit="#FFC93C", heal="#5BE37D", taken="#FF5A6A",
               taken_card="#FF7A86")   # on a plate, in its dark stroke: 7.2 to 1

TAKES = {
    "A": dict(
        name="Porcelain",
        line="Bright: warm white plates in a fine ink line, ink words in a wide face, one orange accent on the signature.",
        display=("BuilderExtended-SemiBold.otf", "Builder Extended SemiBold"), body=("BuilderSans-Bold.otf", "Builder Sans"),
        num=("BuilderSans-ExtraBold.otf", "Builder Sans ExtraBold"), track=0.9,
        ink="#232832", ink2="#6A7180", shade=None,
        panel=dict(top="#FFFFFF", bottom="#F0ECE4", a=0.96, stroke="#232832", stroke_a=0.9, sw=1.2, r=8,
                   inner="#FFFFFF", inner_a=0.9, shadow=0.22),
        foe=dict(top="#FFFFFF", bottom="#F0ECE4", stroke="#232832"),
        accent=("#F58A3E", "#E2601C"), accent_ink="#FFFFFF",
        well="#232832", well_a=0.10, health=("#F0606E", "#D8404F"), poise=("#F7B23B", "#EE9612"), xp="#3A8DFF",
    ),
    "B": dict(
        name="Slate glass",
        line="Mid-value: blue-grey glass with a pale rim, white words in a technical face, one gold accent.",
        display=("TitilliumWeb-Bold.ttf", "Titillium Web"), body=("BuilderSans-Bold.otf", "Builder Sans"),
        num=("TitilliumWeb-Bold.ttf", "Titillium Web"), track=1.4,
        ink="#FFFFFF", ink2="#D4DCE8", shade="#1C2431",
        # research's pick (2026-11-26): a step darker than the first take's #71829C, so every white word on a plate
        # reaches 5.5 to 1 over the brightest sky behind it (5.66 over white); a thin rim by side, from C
        panel=dict(top="#52627A", bottom="#405066", a=0.96, stroke="#E6EDF7", stroke_a=0.8, sw=1.1, r=7,
                   inner="#FFFFFF", inner_a=0.28, shadow=0.3),
        own="#6FB2FF",
        foe=dict(top="#52627A", bottom="#405066", stroke="#FF8470"),
        accent=("#F8C552", "#E9A01E"), accent_ink="#2E2104",
        well="#1C2431", well_a=0.38, health=("#FF6878", "#E2425A"), poise=("#F8C552", "#E9A01E"), xp="#A6E6FF",
    ),
    "C": dict(
        name="Azure and coral",
        line="Mid-value colour by side: yours in azure, theirs in coral, white words in a cut face, a gold accent.",
        display=("Sarpanch-Bold.ttf", "Sarpanch"), body=("BuilderSans-Bold.otf", "Builder Sans"),
        num=("Sarpanch-Bold.ttf", "Sarpanch"), track=1.0,
        ink="#FFFFFF", ink2="#E3EEFF", shade="#0F2552",
        panel=dict(top="#5398EC", bottom="#3573CF", a=0.95, stroke="#FFFFFF", stroke_a=0.55, sw=1.0, r=7,
                   inner="#FFFFFF", inner_a=0.45, shadow=0.28),
        foe=dict(top="#F27565", bottom="#D84A44", stroke="#FFFFFF"),
        accent=("#FFD45C", "#F5A623"), accent_ink="#3A2600",
        well="#0F2552", well_a=0.38, health=("#FF6B7A", "#E5364D"), poise=("#FFD45C", "#F5A623"), xp="#FFFFFF",
    ),
}


class Page(sf.Page):
    """style_frames' page, with this HUD's own plate (an opacity, a fine stroke) and words (a soft shade, no outline)."""

    def __init__(self, T, key):
        p = T["panel"]
        T = dict(T, key=key, stage=("#ECE5D6", "#B8B0A0"), equip=("#80684A", "#38322B"), today=("#30333B", "#202227"),
                 blur=7, press=dict(fill=T["accent"][0], fill2=T["accent"][1]), text_stroke=None)   # glyphs without an outline
        super().__init__(T, key)
        f = T["foe"]
        self.grad("gFoe", f["top"], f["bottom"])
        self.grad("gPoise", *T["poise"])
        self.defs.append('<filter id="tshade" x="-10%" y="-30%" width="120%" height="160%"><feDropShadow dx="0" dy="0.8" '
                         f'stdDeviation="0.7" flood-color="{T["shade"] or "#000"}" flood-opacity="0.55"/></filter>')
        self.defs.append('<filter id="lift" x="-20%" y="-20%" width="140%" height="150%"><feDropShadow dx="0" dy="2" '
                         f'stdDeviation="2.4" flood-color="#141A24" flood-opacity="{p["shadow"]}"/></filter>')

    def plate(self, x, y, w, h, r=None, fill="url(#gPanel)", stroke=None, sw=None, inner=True, shadow=True, alpha=None):
        p = self.T["panel"]
        r = p["r"] if r is None else r
        stroke = p["stroke"] if stroke is None else stroke
        sw = p["sw"] if sw is None else sw
        a = p["a"] if alpha is None else alpha
        f = ' filter="url(#lift)"' if shadow else ""
        self.add(f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{r}" fill="{fill}" fill-opacity="{a}"{f}/>')
        if inner:
            self.add(f'<path d="M{x + r:.1f},{y + sw + 0.6:.1f} H{x + w - r:.1f}" stroke="{p["inner"]}" '
                     f'stroke-opacity="{p["inner_a"]}" stroke-width="1" stroke-linecap="round"/>')
        if sw:
            self.add(f'<rect x="{x + sw / 2:.2f}" y="{y + sw / 2:.2f}" width="{w - sw:.2f}" height="{h - sw:.2f}" '
                     f'rx="{max(0, r - sw / 2)}" fill="none" stroke="{stroke}" stroke-opacity="{p["stroke_a"]}" '
                     f'stroke-width="{sw}"/>')

    def word(self, x, y, s, size, role="body", fill=None, anchor="start", caps=False, track=None, shade=None, opacity=1):
        T = self.T
        fam = {"display": T["display"][1], "num": T["num"][1]}.get(role, T["body"][1])
        if caps:
            s = s.upper()
        fill = fill or T["ink"]
        tr = T["track"] if (caps and track is None) else (track or 0)
        ls = f' letter-spacing="{tr}"' if tr else ""
        sh = shade if shade is not None else (T["shade"] is not None and fill.upper() in ("#FFFFFF", T["ink2"].upper()))
        f = ' filter="url(#tshade)"' if sh else ""
        op = f' opacity="{opacity}"' if opacity != 1 else ""
        self.add(f'<text x="{x:.1f}" y="{y:.1f}" font-family="{fam}" font-size="{size}" fill="{fill}" '
                 f'text-anchor="{anchor}"{ls}{f}{op}>{sf.esc(s)}</text>')

    def on_bar(self, x, y, s, size):
        """A number on a bar: white in a dark stroke, so it holds on the bar's lightest red (4.5 to 1 or more)."""
        self.add(f'<text x="{x:.1f}" y="{y:.1f}" font-family="{self.T["num"][1]}" font-size="{size}" fill="#FFFFFF" '
                 f'text-anchor="middle" stroke="#1C2431" stroke-width="{size * 0.24:.2f}" stroke-linejoin="round" '
                 f'paint-order="stroke">{sf.esc(s)}</text>')

    def bar(self, x, y, w, h, share, grad, r=None, sheen=True):
        T = self.T
        r = h / 2 if r is None else r
        self.add(f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h}" rx="{r}" fill="{T["well"]}" '
                 f'fill-opacity="{T["well_a"]}"/>')
        if share > 0:
            self.add(f'<rect x="{x:.1f}" y="{y:.1f}" width="{max(w * share, 2 * r):.1f}" height="{h}" rx="{r}" fill="{grad}"/>')
            if sheen and h >= 8:
                self.add(f'<rect x="{x + 1.5:.1f}" y="{y + 1:.1f}" width="{max(0, w * share - 3):.1f}" '
                         f'height="{h * 0.32:.1f}" rx="{h * 0.16:.1f}" fill="#fff" fill-opacity="0.25"/>')

    def mark(self, kind, x, y, size, fill, stroke=None):
        """Glyphs this HUD adds, on a 24-point box: the skull, the signature's slam, Auto's turn."""
        k = size / 24
        g = f'<g transform="translate({x:.1f},{y:.1f}) scale({k:.4f})">'
        if kind == "skull":
            g += (f'<path d="M12 2.5 C6.5 2.5 3.5 6.3 3.5 10.5 C3.5 13.4 5 15.4 7 16.5 V20.5 H17 V16.5 C19 15.4 20.5 13.4 '
                  f'20.5 10.5 C20.5 6.3 17.5 2.5 12 2.5 Z" fill="{fill}"/>'
                  f'<circle cx="8.6" cy="11" r="2.3" fill="{stroke}"/><circle cx="15.4" cy="11" r="2.3" fill="{stroke}"/>'
                  f'<path d="M10 18 V20.5 M14 18 V20.5" stroke="{stroke}" stroke-width="1.3"/>')
        elif kind == "fist":   # a fist thrown at the viewer, three short strokes of its blow above it
            g += (f'<path d="M5 9.6 C5 8.1 6.1 7 7.5 7 C8.2 7 8.8 7.3 9.2 7.7 C9.6 6.9 10.4 6.4 11.4 6.4 C12.4 6.4 13.2 6.9 13.6 '
                  f'7.7 C14 7.1 14.8 6.7 15.7 6.7 C17.1 6.7 18.2 7.8 18.2 9.2 V9.6 C18.6 9.3 19.1 9.1 19.6 9.1 C20.9 9.1 '
                  f'21.6 10.1 21.6 11.4 V14.6 C21.6 18.6 18.6 21.6 14.6 21.6 H11.2 C7.7 21.6 5 18.9 5 15.4 Z" fill="{fill}"/>'
                  f'<path d="M9.2 7.9 V12 M13.6 7.9 V12 M18.2 9.6 V12.6 M6.6 15.2 H13.4 C14.6 15.2 15.5 14.3 15.5 13.1" '
                  f'fill="none" stroke="{stroke}" stroke-width="1.3" stroke-linecap="round"/>'
                  f'<path d="M7.4 3.6 L8.2 1.4 M12 3.2 V0.8 M16.6 3.6 L15.8 1.4" stroke="{fill}" stroke-width="1.5" '
                  f'stroke-linecap="round"/>')
        elif kind == "auto":   # a ring turning on itself
            g += (f'<path d="M19 12 A7 7 0 1 1 15.6 6" fill="none" stroke="{fill}" stroke-width="2.6" '
                  f'stroke-linecap="round"/><path d="M14.2 2.6 L19.6 5.6 L14.6 9.2 Z" fill="{fill}"/>')
        g += "</g>"
        self.add(g)


# ---- the pieces ------------------------------------------------------------------------------------------------------------
CARD = (12, 50, 206, 58)


def lead_card(P, health, share, taken=None):
    T = P.T
    x, y, w, h = CARD
    P.plate(x, y, w, h, stroke=T.get("own"))
    px, py, pw = x + 6, y + 6, h - 12
    P.clip_rect("portrait", px, py, pw, pw, 6)
    P.add(f'<rect x="{px}" y="{py}" width="{pw}" height="{pw}" rx="6" fill="#E9D6C8"/>')
    # the game's own portrait, from today's card in the capture: the head's square, 42 page points across
    sx, sy, ss = 14.5, 65.5, 42.0
    k = pw / ss
    P.add(f'<g clip-path="url(#portrait)"><image href="{FIGHT_SRC.as_uri()}" x="{px - sx * k:.2f}" y="{py - sy * k:.2f}" '
          f'width="{W * k:.2f}" height="{H * k:.2f}"/></g>')
    P.add(f'<rect x="{px + 0.5}" y="{py + 0.5}" width="{pw - 1}" height="{pw - 1}" rx="5.5" fill="none" '
          f'stroke="{sf.RARITY["Common"]}" stroke-width="1.2"/>')
    bw, bh = 22, 13       # the level, on a small badge at the portrait's foot
    P.plate(px - 3, py + pw - 9, bw, bh, r=4, fill="url(#gPress)", stroke=T["panel"]["stroke"], sw=0.9, inner=False,
            shadow=False, alpha=1)
    P.word(px - 3 + bw / 2, py + pw + 1.2, "26", 9.5, role="num", fill=T["accent_ink"], anchor="middle", shade=False)
    nx = px + pw + 9
    P.word(nx, y + 19, "Rook", 13, role="display", caps=True)
    gx = nx + {"Builder Extended SemiBold": 50, "Titillium Web": 44, "Sarpanch": 47}[T["display"][1]]
    P.glyph("gem", gx, y + 8, 12, sf.TYPES["Red"])
    P.glyph("sword", gx + 15, y + 8.5, 11, T["ink2"])
    hx, hy, hw, hh = nx, y + 25, x + w - nx - 8, 14
    P.bar(hx, hy, hw, hh, share, "url(#gHealth)", r=4)
    P.on_bar(hx + hw / 2, hy + 10.6, health, 10)
    P.bar(hx, hy + hh + 5, hw, 3.5, 0.38, T["xp"], sheen=False)
    # the eye (spectate): a small disc docked to the card's edge, on a TAP-sized tap area
    ex, ey, er = x + w + 20, y + 15, 13
    P.plate(ex - er, ey - er, 2 * er, 2 * er, r=er)
    P.glyph("eye", ex - 8.5, ey - 8.5, 17, T["ink"])
    if taken:   # the lead's damage taken: over the bar's draining end, inside the card, rising and fading; never by the eye
        P.add(f'<text x="{x + w - 8}" y="{y + 20}" font-family="{T["num"][1]}" font-size="12" fill="{NUMBERS["taken_card"]}" '
              f'text-anchor="end" stroke="#2A0E14" stroke-width="2.6" stroke-linejoin="round" paint-order="stroke">{taken}</text>')


def signature(P):
    """The one big press: a disc in the accent, its charge a ring round it (full and lit: ready)."""
    T = P.T
    cx, cy, r = 47, 160, 33   # 66 across: the TAP height, the one press drawn at it
    P.add(f'<circle cx="{cx}" cy="{cy}" r="{r + 5}" fill="none" stroke="{T["panel"]["stroke"] if T["key"] == "A" else "#FFFFFF"}" '
          f'stroke-opacity="0.22" stroke-width="2.4"/>')
    P.add(f'<circle cx="{cx}" cy="{cy}" r="{r + 5}" fill="none" stroke="{T["accent"][0]}" stroke-width="2.4" '
          f'stroke-linecap="round"/>')                       # the charge: full
    P.add(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="url(#gPress)" filter="url(#lift)"/>')
    P.add(f'<circle cx="{cx}" cy="{cy}" r="{r - 0.6}" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.2"/>')
    P.add(f'<path d="M{cx - r * 0.62:.1f},{cy - r * 0.55:.1f} A{r * 0.85:.1f} {r * 0.85:.1f} 0 0 1 {cx + r * 0.62:.1f},'
          f'{cy - r * 0.55:.1f}" fill="none" stroke="#FFFFFF" stroke-opacity="0.35" stroke-width="2" stroke-linecap="round"/>')
    P.mark("fist", cx - 15, cy - 16, 30, T["accent_ink"], stroke=T["accent"][1])


def auto(P, on=True):
    """Auto: a slim chip beside the signature, its word and its turn in the accent when on."""
    T = P.T
    x, y, w, h = 96, 147, 66, 26
    P.plate(x, y, w, h, r=h / 2)
    c = T["accent"][1] if on else T["ink2"]
    if T["key"] != "A" and on:
        c = T["accent"][0]
    P.mark("auto", x + 7, y + 5, 16, c)
    P.word(x + 27, y + 17.3, "Auto", 10, role="display", caps=True, fill=c if T["key"] == "A" else "#FFFFFF",
           track=T["track"] * 0.8)


def foe_card(P):
    T = P.T
    x, y, w, h = 318, 50, 216, 50
    f = T["foe"]
    P.plate(x, y, w, h, fill="url(#gFoe)", stroke=f["stroke"])
    P.mark("skull", x + 8, y + 6, 14, "#FFFFFF" if T["key"] != "A" else "#F4F1EA",
           stroke="#232832")
    if T["key"] == "A":   # the skull's white needs its edge on porcelain
        P.add(f'<g transform="translate({x + 8},{y + 6}) scale({14 / 24:.4f})"><path d="M12 2.5 C6.5 2.5 3.5 6.3 3.5 10.5 C3.5 '
              f'13.4 5 15.4 7 16.5 V20.5 H17 V16.5 C19 15.4 20.5 13.4 20.5 10.5 C20.5 6.3 17.5 2.5 12 2.5 Z" fill="none" '
              f'stroke="#232832" stroke-width="2"/></g>')
    P.word(x + 27, y + 17.5, "Lv 26", 10.5, role="num", fill=T["ink"] if T["key"] == "A" else "#FFFFFF")
    P.word(x + 63, y + 17.8, "Brawler", 12.5, role="display", caps=True, fill=T["ink"] if T["key"] == "A" else "#FFFFFF")
    P.glyph("gem", x + w - 20, y + 6, 12, sf.TYPES["Red"])
    hx, hw = x + 8, w - 16
    P.bar(hx, y + 25, hw, 13, 2964 / 4290, "url(#gHealth)", r=4)
    P.on_bar(hx + hw / 2, y + 34.8, "2,964/4,290", 9.5)
    P.bar(hx, y + 42, hw, 3, 0.64, "url(#gPoise)", sheen=False)   # poise, beneath


def fight(T, key, plate):
    P = Page(T, key)
    P.add(f'<image href="{Path(plate).resolve().as_uri()}" x="0" y="0" width="{W}" height="{H}"/>')
    lead_card(P, "3,682/3,732", 3682 / 3732, taken="-15")
    signature(P)
    auto(P)
    foe_card(P)
    return P.svg(W, H)


def numbers_strip(T, key, plate):
    """The numbers over the world, in this take's number face: outlined thin, so they read over anything."""
    P = Page(T, key)
    sh = 140
    uri = Path(plate).resolve().as_uri()
    P.add(f'<image href="{uri}" x="0" y="{-322}" width="{W}" height="{H}"/>')
    P.clip_rect("feet", 350, 0, 170, sh, 0)    # the avatar's feet, covered by the plain floor from their left
    P.add(f'<g clip-path="url(#feet)"><image href="{uri}" x="300" y="{-322}" width="{W}" height="{H}"/></g>')
    P.add(f'<rect x="0" y="0" width="{W}" height="{sh}" fill="#FFFFFF" fill-opacity="0.06"/>')
    fam = T["num"][1]

    def num(x, y, s, size, fill, edge="#1D1F26", italic=False, opacity=1.0, spacing=0.8):
        sk = ' transform="skewX(-10)"' if italic else ""
        xx = x + (y * 0.1763 if italic else 0)
        P.add(f'<text x="{xx:.1f}" y="{y:.1f}" font-family="{fam}" font-size="{size}" fill="{fill}" text-anchor="middle" '
              f'letter-spacing="{spacing}" stroke="{edge}" stroke-width="{size * 0.11:.2f}" stroke-linejoin="round" '
              f'paint-order="stroke" opacity="{opacity}"{sk}>{sf.esc(s)}</text>')

    def caption(x, s):
        P.add(f'<text x="{x}" y="{sh - 10}" font-family="Builder Sans" font-size="10.5" fill="#FFFFFF" text-anchor="middle" '
              f'stroke="#1D1F26" stroke-width="2.2" stroke-linejoin="round" paint-order="stroke">{sf.esc(s)}</text>')

    num(110, 44, "290", 12, NUMBERS["dealt"], opacity=0.4)       # the target's stack: two before it, fading up
    num(110, 64, "565", 15, NUMBERS["dealt"], opacity=0.72)
    num(110, 96, "1,717", 25, NUMBERS["dealt"])
    caption(110, "dealt: the latest big")
    num(250, 90, "98", 18, NUMBERS["element"])
    caption(250, "its element, a beat behind")
    P.add('<path d="M338,90 Q384,62 444,66" fill="none" stroke="#FFC93C" stroke-width="2.6" stroke-linecap="round" opacity="0.85"/>')
    num(392, 94, "4,120", 27, NUMBERS["crit"], edge="#4A2A00", italic=True)
    caption(392, "a crit")
    P.plate(505, 70, 66, 21, r=10.5, fill="#FFFFFF", stroke="#1D1F26", sw=1.0, inner=False, shadow=False, alpha=0.95)
    P.add('<path d="M532,90.5 L538,96 L544,90.5" fill="#FFFFFF" stroke="#1D1F26" stroke-width="1" stroke-linejoin="round"/>')
    P.add('<text x="538" y="84.5" font-family="Builder Sans" font-size="11" fill="#5B6372" text-anchor="middle">Dodge</text>')
    caption(538, "dodge, on a pointer")
    num(642, 90, "+120", 18, NUMBERS["heal"], edge="#0B3A1C")
    caption(642, "a heal")
    num(760, 90, "-15", 19, NUMBERS["taken"], edge="#3A1016")
    caption(760, "taken: over the lead's bar")
    return P.svg(W, sh), sh


def faces(keys):
    seen, css = set(), []
    for k in keys:
        for file, fam in (TAKES[k]["display"], TAKES[k]["body"], TAKES[k]["num"]):
            if (file, fam) not in seen:
                seen.add((file, fam))
                css.append(f'@font-face{{font-family:"{fam}";src:url("{(sf.FONTS / file).as_uri()}")}}')
    return "".join(css)


def main():
    out, plate = Path(sys.argv[1]).resolve(), sys.argv[2]
    keys = [k for k in sys.argv[3:] if k in TAKES] or list(TAKES)
    out.mkdir(parents=True, exist_ok=True)
    css = faces(TAKES)
    for k in keys:
        T = TAKES[k]
        svg = fight(T, k, plate)
        sf.shoot(sf.html(svg, css, W, H), out / f"{k}_fight.png", W, H, scale=SCALE)
        sf.shoot(sf.html(svg, css, W, H, zoom=568 / W), out / f"{k}_fight_small.png", 568, round(H * 568 / W), scale=1)
        # the pieces at three times: the top left and the foe's card, as a phone shows them held close
        close = svg.replace(f'viewBox="0 0 {W} {H}"', 'viewBox="0 40 560 160"').replace(f'width="{W}" height="{H}"',
                                                                                         'width="560" height="160"', 1)
        sf.shoot(sf.html(close, css, 560, 160), out / f"{k}_close.png", 560, 160, scale=3)
        svg, sh = numbers_strip(T, k, plate)
        sf.shoot(sf.html(svg, css, W, sh), out / f"{k}_numbers.png", W, sh, scale=SCALE)
        print("drew", k, T["name"])


if __name__ == "__main__":
    main()
