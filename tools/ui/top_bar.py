"""AR62, step 4, the audit's fourth screen: the full screens' top bar (the Voidkin and Equipment screens), redone from
the picked frame (A, Graphite, with the shard cut) as targets for research's pick in pairs, painted over today's phone
captures (build/captures/ar62/before/).

The director, 2026-11-24, by 13:50: "this left ui is so ugly", then "ugly heart lock" (docs/decisions.md: the top bar
and its favourite and lock icons; not removing either function, nor the pills' content). Today: Back with no plate
over a line of light; a framed group of stock outline glyphs (a heart, an open padlock, a pencil); the page's name;
the currencies, stepped down to the battery alone when the band is narrow.

Here, on every full screen, one bar beside Roblox's buttons and level with them: Back as the Arc panel's (a raised
plate, 44 pt), the screen's name, then Credits and the battery. The marks are redrawn in the kit's make: a cut heart
(solid when on), the Arc panel's padlock (shut, or its shackle lifted), a cut pencil. Off, the
glyph in the second ink on raised; on, the glyph in ink and an ivory hairline round its cell (the dock's open state:
a full ivory fill is the press's alone). Each mark is a 66 px cell (44 pt on the small phone).

Two takes, differing only in where the Voidkin's marks live:
  A  in the bar, as today: Back, the three marks, the page's name; the battery alone at the right (today's step-down:
     the bar is too narrow for Credits beside the marks).
  B  down the stage's right edge, by the Voidkin they mark: the bar is the same on every full screen, Credits kept.
The Equipment screen's bar is the same in both (it has no marks).

    py tools/ui/top_bar.py <out_dir>

Writes A_voidkin.png, B_voidkin.png, equipment.png, {A,B}_small.png (568 x 320), {A,B}_grey.png, marks.png (each mark
in both states, at 66 and at 64 px) and bar_sheet.png (today's beside each take).
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import arc_panel as ap  # noqa: E402  (sets the frame's cut; its tokens, the back glyph and the padlock)
import style_frames as sf  # noqa: E402

REPO, T = sf.REPO, ap.T
W, H = sf.W, sf.H
S, M, L = T["sizes"]
INK, INK2, RIM, RAISED, LOW, TAP = ap.INK, ap.INK2, ap.RIM, ap.RAISED, ap.LOW, ap.TAP
DIM = T["neutrals"][0][0]                     # the dim behind a screen: the bar's ground
BEFORE = REPO / "build/captures/ar62/before"
BAR_Y, BAR_FOOT = 18, 92                      # level with Roblox's buttons; the band's foot, over today's
CELL, GAP = TAP, 8


def roblox(P):
    """Roblox's own buttons, as the frame draws them (its last layer of the world)."""
    tmp = sf.Page(T, "A")
    sf.world(tmp, False)
    P.add(tmp.parts[-1])


def mark(P, kind, x, y, size, fill, on):
    """The marks in the kit's make, on a 24 grid."""
    if kind == "lock":
        if on:
            ap.glyph(P, "lock", x, y, size, fill)
            return
        k = size / 24   # open: the Arc panel's padlock, its shackle lifted clear on the left
        P.add(f'<g transform="translate({x},{y}) scale({k:.4f})">'
              f'<path d="M7.5 7.2 V5 A4.5 4.5 0 0 1 16.5 5 V11" fill="none" stroke="{fill}" stroke-width="2.8"/>'
              f'<path d="M5 11 H19 V19.5 L16.5 22 H5 Z M12 14 A1.7 1.7 0 0 0 11 17.1 V19 H13 V17.1 A1.7 1.7 0 0 0 12 14 Z" '
              f'fill="{fill}" fill-rule="evenodd"/></g>')
        return
    k = size / 24
    g = f'<g transform="translate({x},{y}) scale({k:.4f})">'
    if kind == "heart":   # cut, not rounded: two chamfered lobes and a point; on, solid (a shaded half read as half a heart)
        heart = "M12 21.5 L2.2 11.4 V6.6 L6 2.8 H9.2 L12 5.8 L14.8 2.8 H18 L21.8 6.6 V11.4 Z"
        if on:
            g += f'<path d="{heart}" fill="{fill}"/>'
        else:
            g += f'<path d="{heart}" fill="none" stroke="{fill}" stroke-width="2.4" stroke-linejoin="miter"/>'
    elif kind == "pencil":   # a cut pencil: its butt on the shard's angle, a band, a point
        g += (f'<path d="M15.2 3.2 L20.8 8.8 L9 20.6 L3 21 L3.4 15 Z" fill="{fill}"/>'
              f'<path d="M12.6 5.8 L18.2 11.4" stroke="{LOW}" stroke-width="1.8"/>'
              f'<path d="M3.4 15 L9 20.6" stroke="{LOW}" stroke-width="1.4" stroke-opacity="0.55"/>')
    g += "</g>"
    P.add(g)


def cell(P, x, y, kind, on):
    lit = on and kind != "pencil"
    P.plate(x, y, CELL, CELL, r=12, fill=RAISED, stroke=INK if lit else RIM, sw=1.6 if lit else 1.5, shadow=False)
    size = 30
    mark(P, kind, x + (CELL - size) / 2, y + (CELL - size) / 2, size, INK if (lit or kind == "pencil") else INK2, on)


MARKS = (("heart", True), ("lock", False), ("pencil", False))   # Rook: a favourite, not locked


def marks_row(P, x, y):
    for i, (kind, on) in enumerate(MARKS):
        cell(P, x + i * (CELL + GAP), y, kind, on)
    return x + 3 * CELL + 2 * GAP


def marks_column(P, x, y):
    for i, (kind, on) in enumerate(MARKS):
        cell(P, x, y + i * (CELL + 6), kind, on)


def back(P):
    P.plate(262, BAR_Y, 104, TAP, r=12, fill=RAISED, stroke=RIM, sw=1.5, shadow=False)
    ap.glyph(P, "back", 274, BAR_Y + 21, 24, INK)
    P.text(302, BAR_Y + 39.5, "Back", S, role="display")
    return 366


def pill(P, right, kind, said, colour):
    """A currency, read only: 40 tall, round ends, level with the bar's middle; returns its left."""
    w = 44 + len(said) * 13.4 + 14
    x = right - w
    P.plate(x, BAR_Y + (TAP - 40) / 2, w, 40, r=20)
    P.glyph(kind, x + 10, BAR_Y + (TAP - 24) / 2, 24, colour)
    P.text(x + 44, BAR_Y + TAP / 2 + 9, said, M, role="body")
    return x


def ground(P, shot):
    P.add(f'<image href="{(BEFORE / shot).as_uri()}" x="0" y="0" width="{W}" height="{H}"/>')
    P.defs.append(f'<linearGradient id="gBar" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{DIM}"/>'
                  f'<stop offset="0.9" stop-color="{DIM}"/><stop offset="1" stop-color="{DIM}" stop-opacity="0"/></linearGradient>')
    P.add(f'<rect x="0" y="0" width="{W}" height="{BAR_FOOT + 6}" fill="url(#gBar)"/>')
    roblox(P)


POWER = T["hues"][0][0]


def page(take, screen, grey=False):
    P = sf.Page(dict(T), "A")
    ground(P, f"{screen}.png")
    x = back(P)
    if screen == "voidkin":
        if take == "A":
            x = marks_row(P, x + 10, BAR_Y)
            P.text(x + 14, BAR_Y + 42, "Overview", M, role="display")
            pill(P, 838, "bolt", "4.2", POWER)
        else:
            P.text(x + 18, BAR_Y + 42, "Overview", M, role="display")
            left = pill(P, 838, "bolt", "4.2 kWh", POWER)
            pill(P, left - 8, "coin", "55,239", T["credits"])
            marks_column(P, 382, 102)
    else:
        P.text(x + 18, BAR_Y + 42, "Equipment", M, role="display")
        left = pill(P, 838, "bolt", "4.2 kWh", POWER)
        pill(P, left - 8, "coin", "55,239", T["credits"])
    return P.svg(grey=grey)


def marks_page():
    """Each mark off and on, at 66 (the cell) and read at 64 px."""
    P = sf.Page(dict(T), "A")
    P.add(f'<rect width="{W}" height="{H}" fill="{DIM}"/>')
    P.text(24, 44, "The marks, off and on", L, role="display")
    for row, (kind, word) in enumerate((("heart", "Favourite"), ("lock", "Lock"), ("pencil", "Rename"))):
        y = 80 + row * 128
        P.text(24, y + 42, word, M, role="display", fill=INK2)
        for col, on in enumerate((False, True)):
            if kind == "pencil" and on:
                continue
            cell(P, 220 + col * 110, y, kind, on)
            P.text(220 + col * 110 + CELL / 2, y + CELL + 24, "on" if on else ("off" if kind != "pencil" else "press"), S,
                   fill=INK2, anchor="middle")
        for col, on in enumerate((False, True)):   # the 64 px read: the glyph alone at 64, ink on the dim
            if kind == "pencil" and on:
                continue
            mark(P, kind, 500 + col * 110, y, 64, INK if (on or kind == "pencil") else INK2, on)
    P.text(500, 70, "at 64 px", S, fill=INK2)
    return P.svg()


def main():
    out = Path(sys.argv[1]).resolve()
    out.mkdir(parents=True, exist_ok=True)
    faces = sf.font_faces(["A"])
    for take in ("A", "B"):
        sf.shoot(sf.html(page(take, "voidkin"), faces), out / f"{take}_voidkin.png", W, H)
        sf.shoot(sf.html(page(take, "voidkin", grey=True), faces), out / f"{take}_grey.png", W, H)
        sf.shoot(sf.html(page(take, "voidkin"), faces, zoom=568 / W), out / f"{take}_small.png", 568, 320, scale=1)
    sf.shoot(sf.html(page("B", "equipment"), faces), out / "equipment.png", W, H)
    sf.shoot(sf.html(marks_page(), faces), out / "marks.png", W, H)
    # the sheet: today's two, then A's and B's Voidkin and the shared Equipment, then the marks
    cells = [BEFORE / "voidkin.png", BEFORE / "equipment.png", out / "A_voidkin.png", out / "B_voidkin.png",
             out / "equipment.png", out / "marks.png"]
    names = ["Today: Voidkin", "Today: Equipment", "A: the marks in the bar", "B: the marks by the Voidkin",
             "A and B: Equipment", "The marks"]
    sw, sh = 852, 480
    body = "".join(f'<div style="position:absolute;left:{(i % 2) * (sw + 24) + 24}px;top:{(i // 2) * (sh + 52) + 52}px">'
                   f'<div style="font:600 20px \'Builder Sans\';color:#F3EEE4;margin-bottom:6px">{n}</div>'
                   f'<img src="{c.as_uri()}" width="{sw}" height="{sh}"></div>' for i, (c, n) in enumerate(zip(cells, names)))
    page_w, page_h = 2 * sw + 72, 3 * (sh + 52) + 40
    doc = (f'<!doctype html><html><head><meta charset="utf-8"><style>{faces}body{{margin:0;background:{DIM};width:{page_w}px;'
           f'height:{page_h}px;position:relative}}</style></head><body>{body}</body></html>')
    sf.shoot(doc, out / "bar_sheet.png", page_w, page_h, scale=1)
    print("drew A and B, the bar")


if __name__ == "__main__":
    main()
