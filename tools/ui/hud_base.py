"""AR62, the HUD overhaul, piece 2: the base's HUD and the return panel at load, two takes of each, in B (Slate glass,
research's pick of piece 1, 2026-11-26, 23:46). Targets only: nothing is built from them before the fight's HUD has been
judged in play (research, 2026-11-26: "one specimen first").

The work is in the layout and the content, which hold through any palette:
    - Power, made and used, each with its own word, so it never reads as an overload ("91 / 10 kW" today);
    - the dock in the left column, clear of the avatar's legs;
    - the machines' markers small: words at 12 points (8 pixels on the smallest phone), never a slab;
    - the director's return panel (2026-11-26): "it should be the whole screen and appear when a player load in the game".
The base's HUD: take 1, "Tags" (the pills stacked under each other, three dock tiles, names on short stems) and take 2,
"Rail" (one strip of pills, the dock as one rail, the names written over the world). The return panel: take 1, "Grid"
(a slate veil over the base, the gains in tiles) and take 2, "Tally" (a light veil, the largest gain beside a list).
Words are the game's own (src/client/UI/ReturnCard.luau, Dock.luau), except where a take proposes its own (marked).
Every word on a plate is white (research's gate: 5.5 to 1 or more); the quieter ones are smaller, in the body face.

    py tools/ui/hud_base.py <out_dir> <base plate>

The plate is the base capture at the gate, in its installed light, with today's HUD taken out (1920 x 1066). Writes
base_1.png, base_2.png, return_1.png, return_2.png, each with a _small twin (the smallest phone, 568 wide), and
base_1_close.png, base_2_close.png (the pills and the markers at three times).
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import hud_palettes as hp  # noqa: E402
import style_frames as sf  # noqa: E402

W, H, SCALE = hp.W, hp.H, hp.SCALE
T = hp.TAKES["B"]
UI = sf.REPO / "build/handoff/UI"
POWER = "#22C3E6"          # the generator's own hue: power on the HUD is the generator's
JOBS = dict(Generator="#22C3E6", Breaker="#F0568C", Condenser="#4F86F2", Bay="#F07A3C", Training="#3CC77E")
CREDIT = "#F8C552"

# where each machine stands on the plate, in page points: its name, its job, its top's x and y, the stem's length, and
# how far its tag sits to the right of its stem (Training's, so it clears Bay 1's)
MACHINES = [("Generator", "Generator", 426, 86, 12, 0), ("Void Breaker", "Breaker", 205, 180, 12, 0),
            ("Stone Condenser", "Condenser", 340, 194, 10, 0), ("Bay 2", "Bay", 552, 197, 10, 0),
            ("Bay 1", "Bay", 628, 200, 10, 0), ("Training", "Training", 670, 206, 10, 30)]


def width(s, size, caps=False, track=0.0):
    """A word's width in Titillium Web Bold, near enough to place a plate round it."""
    per = 0.6 if caps else 0.5
    return len(s) * (size * per + track)


class Page(hp.Page):
    def __init__(self):
        super().__init__(T, "B")
        self.grad("gPower", "#6FE3FA", POWER)
        self.defs.append('<filter id="veil" x="-5%" y="-5%" width="110%" height="110%"><feGaussianBlur stdDeviation="6"/>'
                         '</filter>')

    def ground(self, plate, blur=False):
        uri = Path(plate).resolve().as_uri()
        if blur:   # drawn a little past the frame, so the blur's edge stays outside it
            self.add(f'<image href="{uri}" x="-16" y="-16" width="{W + 32}" height="{H + 32}" filter="url(#veil)" '
                     'preserveAspectRatio="none"/>')
        else:
            self.add(f'<image href="{uri}" x="0" y="0" width="{W}" height="{H}"/>')

    def icon(self, path, x, y, size, crop=None, r=None):
        """One of our images in a square: crop is its (x, y, side) in the image's pixels."""
        w, h = sf.png_size(path)
        cx, cy, cs = crop or (0, 0, min(w, h))
        k = size / cs
        clip = ""
        if r is not None:
            cid = f"c{len(self.defs)}"
            self.clip_rect(cid, x, y, size, size, r)
            clip = f' clip-path="url(#{cid})"'
        self.add(f'<g{clip}><image href="{path.as_uri()}" x="{x - cx * k:.2f}" y="{y - cy * k:.2f}" width="{w * k:.2f}" '
                 f'height="{h * k:.2f}"/></g>')

    def press(self, x, y, w, h, s):
        self.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="12" fill="url(#gPress)" filter="url(#lift)"/>')
        self.add(f'<rect x="{x + 0.6}" y="{y + 0.6}" width="{w - 1.2}" height="{h - 1.2}" rx="11.4" fill="none" '
                 'stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.2"/>')
        self.add(f'<path d="M{x + 12},{y + 3} H{x + w - 12}" stroke="#FFFFFF" stroke-opacity="0.5" stroke-width="1.4" '
                 'stroke-linecap="round"/>')
        self.word(x + w / 2 + 1.1, y + h / 2 + 6, s, 17, role="display", caps=True, fill=T["accent_ink"], track=2.2,
                  anchor="middle", shade=False)

    def pair(self, x, y, n, size, s, small, anchor="start"):
        """A number and its word on one line: "91 kW made", the word smaller and quieter, never run into the number."""
        self.add(f'<text x="{x:.1f}" y="{y:.1f}" text-anchor="{anchor}" filter="url(#tshade)">'
                 f'<tspan font-family="{T["num"][1]}" font-size="{size}" fill="#FFFFFF">{sf.esc(n)}</tspan>'
                 f'<tspan dx="{size * 0.28:.1f}" font-family="{T["body"][1]}" font-size="{small}" fill="#FFFFFF">'
                 f'{sf.esc(s)}</tspan></text>')


# ---- the base's HUD ----------------------------------------------------------------------------------------------------------
def pills_column(P):
    """Take 1: Credits, then Power under it, at the top right, the card's mirror."""
    x, w = 646, 194
    P.plate(x, 50, w, 30, r=15)
    P.glyph("coin", x + 8, 56, 18, CREDIT)
    P.word(x + 33, 70.5, "72,546", 14, role="num")
    y, h = 86, 48
    P.plate(x, y, w, h, r=10)
    P.glyph("bolt", x + 8, y + 7, 16, POWER)
    P.pair(x + 28, y + 20.5, "91 kW", 15, "made", 11)
    P.glyph("battery", x + w - 50, y + 7, 16, T["ink2"])
    P.word(x + w - 10, y + 19.5, "Full", 11, fill="#FFFFFF", anchor="end")
    mw = w - 86
    P.bar(x + 10, y + 30, mw, 6, 10 / 91, "url(#gPower)", sheen=False)
    P.pair(x + w - 10, y + 38, "10 kW", 11.5, "used", 11, anchor="end")


def pills_strip(P):
    """Take 2: one strip, Credits | made and used | the battery, each part apart by a hairline."""
    x, y, w, h = 494, 50, 346, 46      # its left end clear of the Generator's name
    P.plate(x, y, w, h, r=10)
    a, b = x + 102, x + w - 70
    for s in (a, b):
        P.add(f'<path d="M{s},{y + 9} V{y + h - 9}" stroke="#FFFFFF" stroke-opacity="0.22" stroke-width="1"/>')
    P.glyph("coin", x + 10, y + 13, 20, CREDIT)
    P.word(x + 36, y + 28.5, "72,546", 15, role="num")
    P.glyph("bolt", a + 9, y + 12, 18, POWER)
    for i, (n, s) in enumerate((("91 kW", "made"), ("10 kW", "used"))):
        cx = a + 32 + i * 54
        P.word(cx, y + 21, n, 14, role="num")
        P.word(cx, y + 34.5, s, 11, fill="#FFFFFF")
    P.bar(a + 32, y + 38.5, b - a - 44, 3.5, 10 / 91, "url(#gPower)", sheen=False)
    P.glyph("battery", b + 9, y + 14, 18, T["ink2"])
    P.word(b + 31, y + 28, "Full", 12, fill="#FFFFFF")


DOCK = (("base", "Base"), ("home", "Home"), ("map", "Play"))


def dock_tiles(P, at="base"):
    """Take 1: three tiles in the left column, each on a TAP-high pitch; the one you're on rimmed in the accent."""
    x, w, h = 12, 56, 60
    for i, (kind, word) in enumerate(DOCK):
        y = 130 + i * sf.TAP
        on = kind == at
        P.plate(x, y, w, h, r=8, stroke=T["accent"][0] if on else None, sw=1.5 if on else None)
        if on:
            P.add(f'<rect x="{x + 3.5}" y="{y + 18}" width="2.6" height="24" rx="1.3" fill="{T["accent"][0]}"/>')
        P.glyph(kind, x + (w - 24) / 2, y + 9, 24, "#FFFFFF" if on else T["ink2"])
        P.word(x + w / 2, y + 49, word, 10.5, role="display", caps=True, anchor="middle", track=0.8)


def dock_rail(P, at="base"):
    """Take 2: one rail, three parts apart by hairlines; the one you're on lit from inside, its edge in the accent."""
    x, y, w = 12, 128, 56
    P.plate(x, y, w, 3 * sf.TAP, r=10)
    for i, (kind, word) in enumerate(DOCK):
        cy = y + i * sf.TAP
        on = kind == at
        if i:
            P.add(f'<path d="M{x + 10},{cy} H{x + w - 10}" stroke="#FFFFFF" stroke-opacity="0.2" stroke-width="1"/>')
        if on:
            P.add(f'<rect x="{x + 4}" y="{cy + 4}" width="{w - 8}" height="{sf.TAP - 8}" rx="7" fill="#FFFFFF" '
                  'fill-opacity="0.13"/>')
            P.add(f'<rect x="{x + 1.2}" y="{cy + 20}" width="2.6" height="26" rx="1.3" fill="{T["accent"][0]}"/>')
        P.glyph(kind, x + (w - 24) / 2, cy + 11, 24, "#FFFFFF" if on else T["ink2"])
        P.word(x + w / 2, cy + 52, word, 10.5, role="display", caps=True, anchor="middle", track=0.8)


def tags(P):
    """Take 1: each machine's name on a small slate tag, its job's dot, a short stem down to the machine."""
    for name, job, x, top, stem, dx in MACHINES:
        tw = width(name, 12) + 28
        y, tx = top - stem - 20, x + dx
        P.add(f'<path d="M{x},{y + 19} V{top}" stroke="#FFFFFF" stroke-opacity="0.75" stroke-width="1.2"/>')
        P.add(f'<circle cx="{x}" cy="{top}" r="1.9" fill="#FFFFFF"/>')
        P.plate(tx - tw / 2, y, tw, 20, r=10, inner=False)
        P.add(f'<circle cx="{tx - tw / 2 + 10.5}" cy="{y + 10}" r="3.6" fill="{JOBS[job]}"/>')
        P.word(tx - tw / 2 + 19, y + 14.3, name, 12, role="display")


def names(P):
    """Take 2: each name written over the world in a dark edge, its job's dot before it: no plate, no stem."""
    for name, job, x, top, stem, dx in MACHINES:
        if job == "Training":
            x, top = 704, 200    # clear of Bay 1's name without a stem: over its own mat
        tw = width(name, 12.5)
        bx = x - tw / 2 + 6
        P.add(f'<circle cx="{bx - 9}" cy="{top - 14.2}" r="3.6" fill="{JOBS[job]}" stroke="#1C2431" stroke-width="1.6"/>')
        P.add(f'<text x="{bx}" y="{top - 10}" font-family="{T["display"][1]}" font-size="12.5" fill="#FFFFFF" '
              f'stroke="#1C2431" stroke-opacity="0.9" stroke-width="2.1" stroke-linejoin="round" paint-order="stroke" '
              f'filter="url(#tshade)">{sf.esc(name)}</text>')


def base(take, plate):
    P = Page()
    P.ground(plate)
    hp.lead_card(P, "3,732/3,732", 1.0)
    if take == 1:
        tags(P)
        pills_column(P)
        dock_tiles(P)
    else:
        names(P)
        pills_strip(P)
        dock_rail(P)
    return P.svg(W, H)


# ---- the return panel, at load ---------------------------------------------------------------------------------------------
STONE = {g: UI / f"upgrades/images/Stone{g}.png" for g in ("Low", "Mid", "High")}
JEWEL = UI / "jewels/images/JewelBlue2.png"
FACE = {n: UI / f"hud/images/Portrait{n}.png" for n in ("Rook", "Watt", "Kirra")}
FACE_CROP = (222, 236, 292)      # the head's square in a 736 x 800 portrait
STONE_CROP = {"Low": (36, 36, 182), "Mid": (18, 18, 218), "High": (8, 4, 238)}   # each one's drawn bounds, squared
JEWEL_CROP = (22, 38, 188)
# the gains, as ReturnCard words them: the count, the word under it, the picture
GAINS = [("+6", "Low stones", ("stone", "Low")), ("+3", "Mid stones", ("stone", "Mid")),
         ("+1", "High stone", ("stone", "High")), ("+2", "jewels", ("jewel", None)),
         ("+3 levels", "Rook", ("face", "Rook")), ("+2 levels", "Watt", ("face", "Watt")),
         ("+4 levels", "Kirra and 2 more", ("face", "Kirra"))]


def picture(P, what, x, y, size):
    kind, key = what
    if kind == "stone":
        P.icon(STONE[key], x, y, size, crop=STONE_CROP[key])
    elif kind == "jewel":
        P.icon(JEWEL, x, y, size, crop=JEWEL_CROP)
    else:
        P.add(f'<rect x="{x}" y="{y}" width="{size}" height="{size}" rx="{size * 0.2}" fill="#E9D6C8"/>')
        P.icon(FACE[key], x, y, size, crop=FACE_CROP, r=size * 0.2)
        P.add(f'<rect x="{x + 0.5}" y="{y + 0.5}" width="{size - 1}" height="{size - 1}" rx="{size * 0.2 - 0.5}" '
              f'fill="none" stroke="{sf.RARITY["Common"]}" stroke-width="1.2"/>')


def return_grid(plate):
    """Take 1: the base behind a slate veil, the whole screen; the gains in tiles; Collect the one press."""
    P = Page()
    P.ground(plate, blur=True)
    P.add(f'<rect x="0" y="0" width="{W}" height="{H}" fill="#3B4960" fill-opacity="0.76"/>')
    P.word(W / 2, 70, "Welcome back", 26, role="display", caps=True, anchor="middle", track=3.2)
    P.word(W / 2, 94, "While you were away, your base kept working.", 13, fill="#FFFFFF", anchor="middle")
    tw, th, gap = 150, 104, 12
    x0, y0 = (W - (4 * tw + 3 * gap)) / 2, 114
    tiles = [("+1,240", "Credits, battery full", ("credits", None))] + GAINS   # proposed: the Credits first and big
    for i, (count, under, what) in enumerate(tiles):
        x, y = x0 + (i % 4) * (tw + gap), y0 + (i // 4) * (th + gap)
        P.plate(x, y, tw, th, r=9)
        if what[0] == "credits":
            P.glyph("coin", x + tw / 2 - 20, y + 12, 40, CREDIT)
        else:
            picture(P, what, x + tw / 2 - 22, y + 10, 44)
        P.word(x + tw / 2, y + 76, count, 18, role="num", anchor="middle")
        P.word(x + tw / 2, y + 94, under, 12, fill="#FFFFFF", anchor="middle")
    P.press(W / 2 - 120, 364, 240, sf.TAP, "Collect")
    return P.svg(W, H)


def return_tally(plate):
    """Take 2: the base behind a light veil, the whole screen; the largest gain on the left, the rest as a list."""
    P = Page()
    P.ground(plate, blur=True)
    P.add(f'<rect x="0" y="0" width="{W}" height="{H}" fill="#E9EEF5" fill-opacity="0.32"/>')
    lx, ly, lw, lh = 40, 40, 300, 393
    P.plate(lx, ly, lw, lh, r=12)
    P.word(lx + 24, ly + 44, "Welcome back", 22, role="display", caps=True, track=2.6)
    P.word(lx + 24, ly + 66, "While you were away,", 13, fill="#FFFFFF")
    P.word(lx + 24, ly + 84, "your base kept working.", 13, fill="#FFFFFF")
    P.add(f'<path d="M{lx + 24},{ly + 104} H{lx + lw - 24}" stroke="#FFFFFF" stroke-opacity="0.22" stroke-width="1"/>')
    P.glyph("coin", lx + 24, ly + 138, 46, CREDIT)
    P.word(lx + 82, ly + 170, "+1,240", 34, role="num")
    P.word(lx + 84, ly + 192, "Credits", 14)
    P.glyph("battery", lx + 24, ly + 222, 18, POWER)
    P.word(lx + 48, ly + 236, "Battery full: the spare became Credits.", 12, fill="#FFFFFF")   # proposed words
    P.press(lx + 24, ly + lh - 24 - sf.TAP, lw - 48, sf.TAP, "Collect")
    rx, rw = 356, 456
    P.plate(rx, ly, rw, lh, r=12)
    rows = [("Stones", None, [g for g in GAINS if g[2][0] == "stone"])] + [(g[1], g, None) for g in GAINS[3:]]
    rh = (lh - 24) / len(rows)
    for i, (title, gain, stones) in enumerate(rows):
        y = ly + 12 + i * rh
        if i:
            P.add(f'<path d="M{rx + 18},{y} H{rx + rw - 18}" stroke="#FFFFFF" stroke-opacity="0.16" stroke-width="1"/>')
        mid = y + rh / 2
        if stones:   # the three grades on one row, each its count under its stone
            P.word(rx + 20, mid + 5, "Stones", 14)
            for j, (count, under, what) in enumerate(stones):
                sx = rx + 166 + j * 98
                picture(P, what, sx, mid - 20, 40)
                P.word(sx + 46, mid - 1, count, 16, role="num")
                P.word(sx + 46, mid + 14, under.split()[0], 11.5, fill="#FFFFFF")
            continue
        count, under, what = gain
        picture(P, what, rx + 18, mid - 22, 44)
        P.word(rx + 74, mid + 5, under if what[0] == "face" else under.capitalize(), 14)
        P.word(rx + rw - 20, mid + 6, count, 17, role="num", anchor="end")
    return P.svg(W, H)


def main():
    out, plate = Path(sys.argv[1]).resolve(), sys.argv[2]
    out.mkdir(parents=True, exist_ok=True)
    css = hp.faces(["B"])
    pages = {"base_1": base(1, plate), "base_2": base(2, plate), "return_1": return_grid(plate),
             "return_2": return_tally(plate)}
    for name, svg in pages.items():
        sf.shoot(sf.html(svg, css, W, H), out / f"{name}.png", W, H, scale=SCALE)
        sf.shoot(sf.html(svg, css, W, H, zoom=568 / W), out / f"{name}_small.png", 568, round(H * 568 / W), scale=1)
        if name.startswith("base"):   # the pills and the markers held close, at three times
            close = svg.replace(f'viewBox="0 0 {W} {H}"', 'viewBox="380 40 472 180"').replace(
                f'width="{W}" height="{H}"', 'width="472" height="180"', 1)
            sf.shoot(sf.html(close, css, 472, 180), out / f"{name}_close.png", 472, 180, scale=3)
        print("drew", name)


if __name__ == "__main__":
    main()
