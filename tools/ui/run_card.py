"""AR62, step 4, the audit's second screen: the run's card (StageScreen.Results) redone from the picked frame (A, Graphite,
with the shard cut), as targets for research's pick in pairs, beside the Arc panel's (tools/ui/arc_panel.py, whose
pieces it shares: the road of stretches, the presses, Hard's ember, the ground's picture).

The audit's faults (AR62, research's audit, item 2): the same lavender glass and glowing badges, a gloss streak across
the Hard press, the dare chip in a third material (dark with a gold edge). Here: one material (graphite, raised or low),
no light past a piece, one ivory press lit, the dare's mark in the goals' gold (Home's Today card is gold), the reward
pictures our own (AR21's chests, AR31's stones, the HUD's coin) on raised cells, never on a glow.

Three takes, each in two states, over the street dimmed:
  A  the card, fixed: today's rows kept (the stretches, the verdict, the time and the dare, what it gave, the presses).
  B  the place and the verdict: the ground's picture on the left with the verdict over it, the rows and presses on the
     right; the lit press full width, the others under it.
  C  the stamp: no card round the verdict. The stretches, the ground's name and one large word on the dimmed street, then
     one low plate for what it gave and the presses under it. Its large word asks for a fourth size (DESIGN, XL 60).
States: "win" (the keeper beaten on Normal: Hard opens, so Hard is the lit press; the dare kept on the keeper's
stretch; a keeper's chest, a stone and Credits), "fall" (Rook fell at the third stretch: Retry lit, Send another, Home).

    py tools/ui/run_card.py <out_dir> [A B C]

Writes <take>_win.png, <take>_fall.png, <take>_grey.png, <take>_small.png (568 x 320) and run_sheet.png: today's two
cards beside each take's win.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import arc_panel as ap  # noqa: E402  (sets the frame's cut; its tokens, glyphs, presses and the ground's picture)
import style_frames as sf  # noqa: E402

REPO, T = sf.REPO, ap.T
W, H = sf.W, sf.H
S, M, L = T["sizes"]
XL = T["xl"]                                # the verdict's size, on the frame's page (research's must-fix 2)
INK, INK2, RIM, RAISED, LOW, EMBER = ap.INK, ap.INK2, ap.RIM, ap.RAISED, ap.LOW, ap.EMBER
BAND = 0.9                                  # the verdict band's graphite at its core
SOFT = 0.16                                 # its fade at each side, a share of its width and of its height
GOLD = "#FFC83D"                            # the frame's Power hue, the goals' gold (a kept dare)
HURT = T["fall"]                            # a fall's words: health lifted to 4.5:1 (research's must-fix 1, a class)
UIH = REPO / "build/handoff/UI"
ICONS = {"chest": UIH / "chests/images/ChestKeeper.png", "stone": UIH / "upgrades/images/StoneLow.png",
         "coin": UIH / "hud/colour/images/CoinMint.png"}
BEFORE = REPO / "build/captures/ar62/before"

STATES = {
    "win": dict(won=True, rows=["cleared", "cleared", "cleared", "just"], kept=[4], title="Lantern Row cleared",
                word="Cleared", said="1:12   ·   from Stretch 4", dare=True,
                gave=[("coin", "+1,240"), ("chest", "+1"), ("stone", "+1")],
                presses=[("Retry", False, False), ("Hard", True, True), ("Home", False, False)]),
    "fall": dict(won=False, rows=["cleared", "cleared", "next", "shut"], kept=[], title="Rook fell", word="Rook fell",
                 said="Next run starts at Stretch 3", dare=False, gave=[],
                 presses=[("Retry", True, False), ("Send another", False, False), ("Home", False, False)]),
}


# ---- pieces --------------------------------------------------------------------------------------------------------------
def star(P, x, y, size, fill):
    """The dare's mark, kept: a four-point star, flat, no glow (AR53's shape, redrawn on the frame)."""
    k = size / 24
    P.add(f'<g transform="translate({x - size / 2:.1f},{y - size / 2:.1f}) scale({k:.4f})"><path d="M12 1 L14.6 9.4 L23 12 '
          f'L14.6 14.6 L12 23 L9.4 14.6 L1 12 L9.4 9.4 Z" fill="{fill}" stroke="{LOW}" stroke-width="1.6" stroke-linejoin="round"/></g>')


def road(P, x0, x1, cy, rows, kept, size=28, hard=False):
    """The run's stretches, as the Arc panel draws them: done a check, the one just won ringed ivory with its check, the
    next ringed, the rest dim, the keeper's last a diamond; a kept dare a gold star on its mark's corner."""
    accent = EMBER if hard else INK
    n = len(rows)
    step = (x1 - x0 - size) / (n - 1)
    y = cy - size / 2
    for k in range(n - 1):
        a, b = x0 + k * step + size, x0 + (k + 1) * step
        lit = rows[k + 1] in ("cleared", "just")
        P.add(f'<rect x="{a + 3:.1f}" y="{cy - 1.5:.1f}" width="{b - a - 6:.1f}" height="3" rx="1.5" fill="{accent if lit else RIM}"/>')
    for k, row in enumerate(rows):
        mx = x0 + k * step
        last = k == n - 1
        if row in ("cleared", "just"):
            ring = row == "just"
            if ring:
                P.plate(mx - 3, y - 3, size + 6, size + 6, r=8, fill=RAISED, stroke=accent, sw=2.2, inner=False, shadow=False)
            else:
                P.plate(mx, y, size, size, r=7, fill=RAISED, stroke=RIM, sw=1.5, inner=False, shadow=False)
            ap.glyph(P, "check", mx + size * 0.14, y + size * 0.14, size * 0.72, accent)
        elif row == "next":
            P.plate(mx - 3, y - 3, size + 6, size + 6, r=8, fill=RAISED, stroke=accent, sw=2.2, inner=False, shadow=False)
            if last:
                ap.glyph(P, "keeper", mx + size * 0.2, y + size * 0.2, size * 0.6, accent)
            else:
                P.text(mx + size / 2, cy + 6.5, str(k + 1), S, fill=accent, anchor="middle")
        else:
            P.plate(mx, y, size, size, r=7, fill=LOW, stroke=RIM, sw=1.5, inner=False, shadow=False)
            if last:
                ap.glyph(P, "keeper", mx + size * 0.25, y + size * 0.25, size * 0.5, INK2)
            else:
                P.text(mx + size / 2, cy + 6.5, str(k + 1), S, fill=INK2, anchor="middle", opacity=0.8)
        if k + 1 in kept:
            star(P, mx + size + 2, y - 2, 20, GOLD)


def chip(P, x, cy):
    """Dare kept: a raised tag, the gold star and its words. Returns its width."""
    w = 132
    P.plate(x, cy - 16, w, 32, r=7, fill=RAISED, stroke=RIM, sw=1.5, inner=False, shadow=False)
    star(P, x + 18, cy, 18, GOLD)
    P.text(x + 34, cy + 6, "Dare kept", S, fill=INK)
    return w


def gave_row(P, cx, cy, items, h=44):
    """What the run gave: one raised cell each, our own picture and its number."""
    widths = [12 + 34 + 8 + len(words) * 13 + 14 for _, words in items]
    gap = 10
    x = cx - (sum(widths) + gap * (len(items) - 1)) / 2
    for (icon, words), w in zip(items, widths):
        P.plate(x, cy - h / 2, w, h, r=8, fill=RAISED, stroke=RIM, sw=1.5, inner=False, shadow=False)
        if icon == "stone":   # a dark rock: its own light behind it, inside its cell (AR31's must-fix 2; no light past a piece)
            if "gStoneLight" not in "".join(P.defs):
                P.defs.append('<radialGradient id="gStoneLight"><stop offset="0" stop-color="#FFB46A" stop-opacity="0.55"/>'
                              '<stop offset="1" stop-color="#FFB46A" stop-opacity="0"/></radialGradient>')
            P.add(f'<ellipse cx="{x + 27}" cy="{cy}" rx="22" ry="19" fill="url(#gStoneLight)"/>')
        P.image(ICONS[icon], x + 10, cy - 17, 34, 34)
        P.text(x + 12 + 34 + 8, cy + 9, words, M, fill=INK)
        x += w + gap


def presses_row(P, cx, y, presses, h=ap.TAP, quiet=124, one=180, gap=10):
    widths = [one if lit else (150 if len(words) > 8 else quiet) for words, lit, _ in presses]
    x = cx - (sum(widths) + gap * (len(presses) - 1)) / 2
    for (words, lit, hard), w in zip(presses, widths):
        press(P, x, y, w, h, words, lit, hard)
        x += w + gap


def press(P, x, y, w, h, words, lit, hard):
    """ap.press, and Hard's own: its ember chevron before its word, the press's one accent."""
    size = M if len(words) < 8 else S + 2
    if lit:
        P.plate(x, y, w, h, r=10, fill="url(#gPress)", stroke=T["press"]["fill2"], sw=0, shadow=True)
        ink = ap.PRESS_INK
    else:
        P.plate(x, y, w, h, r=10, fill=RAISED, stroke=RIM, sw=1.5, shadow=False)
        ink = INK
    tx = x + w / 2
    if hard:
        ap.glyph(P, "chevron", tx - 46, y + h / 2 - 12, 22, EMBER)
        tx += 12
    P.text(tx, y + h / 2 + size * 0.36, words, size, role="display", fill=ink, anchor="middle")


def back(P):
    P.plate(262, 18, 104, ap.TAP, r=12, fill=RAISED, stroke=RIM, sw=1.5, shadow=False)
    ap.glyph(P, "back", 274, 39, 24, INK)
    P.text(302, 57.5, "Back", S, role="display")


# ---- the takes -----------------------------------------------------------------------------------------------------------
def take_a(P, st):
    x, w = 176, 500
    y, h = (110, 330) if st["gave"] else (140, 262)
    cx = x + w / 2
    P.plate(x, y, w, h)
    road(P, x + 40, x + w - 40, y + 40, st["rows"], st["kept"])
    P.text(cx, y + 104, st["title"], L, role="display", fill=INK if st["won"] else HURT, anchor="middle")
    said_w = len(st["said"]) * 8.4
    if st["dare"]:
        left = cx - (said_w + 12 + 132) / 2
        P.text(left, y + 144, st["said"], S, fill=INK2)
        chip(P, left + said_w + 12, y + 138)
    else:
        P.text(cx, y + 144, st["said"], S, fill=INK2, anchor="middle")
    if st["gave"]:
        gave_row(P, cx, y + 200, st["gave"])
    presses_row(P, cx, y + h - 84, st["presses"])


def take_b(P, st):
    x0, w, y0, h = 24, 804, 98, 350
    P.plate(x0, y0, w, h)
    # the place: the ground's picture, the verdict over its foot
    px, py, pw, ph = 36, 110, 352, 326
    ap.picture(P, "runB", px, py, pw, ph, (420, 250, 1000, 926))
    P.text(px + 18, py + ph - 58, "Lantern Row", S, role="display", fill=INK2)
    P.text(px + 18, py + ph - 20, "Cleared" if st["won"] else "Rook fell", L, role="display", fill=INK if st["won"] else HURT)
    # the rows, right
    x, rw = 412, 404
    cx = x + rw / 2
    dy = 0 if st["gave"] else 40
    road(P, x + 14, x + rw - 14, 138 + dy, st["rows"], st["kept"])
    P.text(x + 4, 196 + dy, st["said"], S, fill=INK2)
    if st["dare"]:
        chip(P, x + rw - 132, 190 + dy)
    P.add(f'<rect x="{x}" y="{212 + dy}" width="{rw}" height="1.2" fill="{RIM}"/>')
    if st["gave"]:
        gave_row(P, cx, 252, st["gave"])
    lit = [p for p in st["presses"] if p[1]][0]
    rest = [p for p in st["presses"] if not p[1]]
    press(P, x, 290, rw, ap.TAP, lit[0], True, lit[2])
    half = (rw - 10) / 2
    for i, (words, _, hard) in enumerate(rest):
        press(P, x + i * (half + 10), 366, half, ap.TAP, words, False, hard)


def take_c(P, st):
    cx = W / 2
    # the verdict's band: soft graphite under every word that stands over the world, no edge and no glow, dark enough
    # that its words keep 4.5:1 over any street (research's must-fix 1). Two gradients, never a blur: a blur this large
    # draws in tiles and leaves faint rectangles, an edge by another name
    fade = lambda gid, a, b, x2, y2: (  # noqa: E731
        f'<linearGradient id="{gid}" x1="0" y1="0" x2="{x2}" y2="{y2}">'
        f'<stop offset="0" stop-color="{a}" stop-opacity="0"/><stop offset="{SOFT}" stop-color="{a}" stop-opacity="{b}"/>'
        f'<stop offset="{1 - SOFT}" stop-color="{a}" stop-opacity="{b}"/><stop offset="1" stop-color="{a}" stop-opacity="0"/>'
        '</linearGradient>')
    P.defs.append(fade("gBand", LOW, BAND, 1, 0) + fade("gBandFall", "#FFFFFF", 1, 0, 1)
                  + f'<mask id="mBand"><rect x="{cx - 330:.0f}" y="96" width="660" height="220" fill="url(#gBandFall)"/></mask>')
    P.add(f'<rect x="{cx - 330:.0f}" y="96" width="660" height="220" fill="url(#gBand)" mask="url(#mBand)"/>')
    road(P, cx - 170, cx + 170, 114, st["rows"], st["kept"], size=30)
    P.text(cx, 168, "Lantern Row", M, role="display", fill=INK2, anchor="middle")
    P.text(cx, 226, st["word"], XL, role="display", fill=INK if st["won"] else HURT, anchor="middle")
    said_w = len(st["said"]) * 8.4
    if st["dare"]:
        left = cx - (said_w + 12 + 132) / 2
        P.text(left, 262, st["said"], S, fill=INK2)
        chip(P, left + said_w + 12, 256)
    else:
        P.text(cx, 262, st["said"], S, fill=INK2, anchor="middle")
    if st["gave"]:
        P.plate(cx - 250, 280, 500, 62, r=12, fill=LOW, stroke=RIM, sw=1.5, inner=True, shadow=False)
        gave_row(P, cx, 311, st["gave"])
        presses_row(P, cx, 356, st["presses"])
    else:
        presses_row(P, cx, 292, st["presses"])


TAKES = {"A": ("the card, fixed", take_a), "B": ("the place and the verdict", take_b), "C": ("the stamp", take_c)}


def page(key, state, grey=False):
    P = sf.Page(T, "A")
    sf.world(P, True)
    back(P)
    TAKES[key][1](P, STATES[state])
    return P.svg(grey=grey)


def sheet_html(out, keys, faces):
    cells = [("Today, the win", BEFORE / "run_card_win.png"), ("Today, the fall", BEFORE / "run_card_fall.png")]
    for k in keys:
        cells += [(f"{k}: {TAKES[k][0]}, the win", out / f"{k}_win.png"), (f"{k}: the fall", out / f"{k}_fall.png")]
    imgs = "".join(f'<figure><img src="{p.as_uri()}"><figcaption>{sf.esc(n)}</figcaption></figure>' for n, p in cells)
    return (f'<!doctype html><html><head><meta charset="utf-8"><style>{faces} body{{margin:0;background:#101114;'
            f'display:grid;grid-template-columns:852px 852px;gap:12px;padding:12px;font:600 18px "Builder Sans";color:#F3EEE4}}'
            f'figure{{margin:0}} img{{width:852px;height:480px;display:block}} figcaption{{padding:6px 2px}}</style></head>'
            f'<body>{imgs}</body></html>')


def main():
    out = Path(sys.argv[1]).resolve()
    keys = [k for k in sys.argv[2:] if k in TAKES] or list(TAKES)
    out.mkdir(parents=True, exist_ok=True)
    faces = sf.font_faces(["A"])
    for k in keys:
        for state in STATES:
            sf.shoot(sf.html(page(k, state), faces), out / f"{k}_{state}.png", W, H)
        sf.shoot(sf.html(page(k, "win", grey=True), faces), out / f"{k}_grey.png", W, H)
        sf.shoot(sf.html(page(k, "win"), faces, zoom=568 / W), out / f"{k}_small.png", 568, 320, scale=1)
        print("drew", k, TAKES[k][0])
    rows = len(keys) + 1
    sf.shoot(sheet_html(out, keys, faces), out / "run_sheet.png", 12 * 3 + 852 * 2, 12 + rows * (480 + 12 + 34), scale=1)


if __name__ == "__main__":
    main()
