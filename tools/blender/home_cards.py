"""AR49, Home's panel: three cards with their own art, a blockout for research's pick (Modulo, 2026-11-19).

Research's ask, on the director's word of 23:20 ("MAKE IT LOOOK GOOD"): three cards with their own art replace AR43's
eight lilac buttons. Voidkin is the largest card, with the player's lead in it on its rarity's light. Equipment is one
picture of its screen's job: a blade at +N in the Reinforce ring, a jewel set in it, an emblem in its socket, in brass
and ember. Settings is quiet steel. The panel's ground is dark glass. Each card's word is large on its foot. Room is
left for a fourth card (Quest).

The three compositions:
    A  the row        Voidkin, Equipment, then a narrow column: Settings at its foot, Quest's room above it.
    B  the stack      Voidkin tall at the left; Equipment wide on the right, Settings and Quest's room under it.
    C  the stage      Voidkin in the middle over the Home tile, its lead's head rising over the frame (the lead
                      card's own move); Equipment at its left, Settings and Quest's room at its right.

The panel sits over the dimmed world with the dock left lit (Home's tile is its root), clear of the lead's card
and above the dock, and it fits the smallest phone (568 x 320). Taps 44 points or more, words 14 or more.
The world is Faber's phone still of a fight (home_panel's FIGHT).

The lead stands in for a live view (a ViewportFrame of the lead's own model in its idle), which works for every
Voidkin with no art per Voidkin. Here it is Rook rendered waist up with his portrait's pose and light.
The gear, the ring, the jewel, the emblem and the socket are the game's own images.

    blender -b --factory-startup --python tools/blender/home_cards.py -- <abs out> lead     (Rook waist up, first)
    blender -b --factory-startup --python tools/blender/home_cards.py -- <abs out> sheet    (home_cards.png)
"""

import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import foe_cards as fc  # noqa: E402
import home_panel as hp  # noqa: E402
import lead_card_art as lca  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
import upgrade_motion as um  # noqa: E402
import upgrade_pages as up  # noqa: E402

K = hp.K                                            # 2 pixels a point
REPO = fc.REPO
UI = REPO / "build" / "handoff" / "UI"
LEAN = hp.LEAN                                      # the dock's lean, 0.2 across per down
PANEL = (371.0, 184.0)                              # the glass, outside: wide, high
PAD = 8.0
GAP = 8.0
LEAD_RIGHT = {"game": 247.0, "small": 183.0}        # the lead's card's right edge, its equipment slot under it
DOCK_GAP = 9.0
DIM = 0.6                                           # the world under Home: the HUD's corner pieces recede with it
RARITY = "Common"                                   # Rook's (Definitions.Voidkin)

# Each card: its kind, its foot from fx0 to fx1 (the lean's frame: the foot line's x), its top and foot from the
# inner glass's top (0 to 168).
H_IN = PANEL[1] - 2 * PAD
COMPOSITIONS = {
    "A": [("Voidkin", 0, 120, 0, H_IN), ("Equipment", 128, 238, 0, H_IN),
          ("Quest", 246, 321, 0, H_IN - 84), ("Settings", 246, 321, H_IN - 76, H_IN)],
    "B": [("Voidkin", 0, 150, 0, H_IN), ("Equipment", 158, 321, 0, 100),
          ("Settings", 158, 236, 108, H_IN), ("Quest", 244, 321, 108, H_IN)],
    "C": [("Equipment", 0, 96, 0, H_IN), ("Voidkin", 104, 238, 0, H_IN),
          ("Quest", 246, 321, 0, H_IN - 84), ("Settings", 246, 321, H_IN - 76, H_IN)],
}
NAMES = {"A": "the row", "B": "the stack", "C": "the stage"}
SAID = {"A": "Voidkin, Equipment, then a narrow column: Settings at its foot, Quest's room above it.",
        "B": "Voidkin tall at the left; Equipment wide on the right, Settings and Quest's room under it.",
        "C": "Voidkin in the middle over the Home tile, the lead's head rising over the frame as on the lead's card; "
             "Equipment left, Settings and Quest's room right."}

# The cards' materials: the body's top and foot, the light behind the art, the rim, the lacquer's glint.
TRIM = lca.TRIM
MAT = {
    "Voidkin": dict(body=("#2A3456", "#05070D"), glint="#CFDBFF"),
    "Equipment": dict(body=("#3A2716", "#0A0604"), light="#FF8A3D", rim="#D9A85B", glint="#FFE2B0"),
    "Settings": dict(body=("#3B424C", "#121519"), light="#AEB7C2", rim="#8F99A6", glint="#E2E8EF"),
}
IVORY = "#F5EFE2"
LEAD_PNG = "_lead_Rook.png"
LEAD_SPAN, LEAD_CENTRE_Z, LEAD_SIZE = 6.0, 3.5, (600, 700)   # the render: studs high, its middle, pixels


# --- the lead, waist up ---------------------------------------------------------------------------------------------

def lead(out):
    """Rook waist up in his portrait's pose and light (hud_art's shoot_portrait with a wider frame)."""
    import hud_art as ha
    p = ha.PORTRAITS["Rook"]
    p["centre"], p["span"] = (p["centre"][0], p["centre"][1], LEAD_CENTRE_Z), LEAD_SPAN
    shot = ha.shoot_portrait("Rook", out, size=LEAD_SIZE)
    rs.save(shot, out / LEAD_PNG)
    print(f"wrote {out / LEAD_PNG} {shot.shape[1]}x{shot.shape[0]}")


LEAD_BELT = 515                                     # the belt's row in the render (read off it)


def lead_top(px):
    """The hair's top row in the render."""
    return int(np.argmax(px[..., 3].max(axis=1) > 0.5))


# --- drawing --------------------------------------------------------------------------------------------------------

def image(path, width_pt, tint=None, alpha=1.0):
    """An image `width_pt` points wide at the sheet's 2 pixels a point, tinted (its light multiplied) and faded."""
    px = rs.load(path) if isinstance(path, Path) else path
    f = width_pt * K / px.shape[1]
    im = (rs.shrink(px, f) if f < 1 else fc.scaled(px, f)).copy()
    if tint is not None:
        im[..., :3] *= ui.c(tint)
    im[..., 3] *= alpha
    return im


def cover(d):
    return np.clip(0.5 - d * K, 0, 1)


def col(colour):
    return ui.c(colour) if isinstance(colour, str) else np.asarray(colour, dtype=np.float32)


class Frame:
    """The lean's frame: a card's sides at y stand LEAN * (foot - y) right of their foot."""

    def __init__(self, x0, foot):
        self.x0, self.foot = x0, foot

    def at(self, fx, y):
        return self.x0 + fx + LEAN * (self.foot - y)

    def card(self, fx0, fx1, y0, y1, cut=7.0):
        a = self.at
        return [(a(fx0, y0 + cut), y0 + cut), (a(fx0, y0) + cut, y0), (a(fx1, y0), y0), (a(fx1, y1 - cut), y1 - cut),
                (a(fx1, y1) - cut, y1), (a(fx0, y1), y1)]


def radial(t, d, cx, cy, rx, ry, colour, strength):
    r2 = ((t.x - cx) / rx) ** 2 + ((t.y - cy) / ry) ** 2
    ui.over(t.px, col(colour), strength * np.exp(-r2) * cover(d))


def word(t, x, y, size, text, colour=IVORY, shade=True):
    """A card's word: the game's face standing in, leaning with the cards, a soft dark under it."""
    if shade:
        t.text(x + 0.8, y + 1.2, size, text, "#000000", layer="a_shade", shear=LEAN, bold=0.3)
    t.text(x, y, size, text, colour, shear=LEAN, bold=0.3)


EM = 0.46                                           # the face's mean width a letter, in its size


def word_size(text, width, most):
    return max(14.0, min(most, (width - 22) / (EM * len(text))))


def finish(t, d, y0, y1, light, rim, glint, pressed, foot=0.34, edge=0.5):
    """What binds a card's art into its frame: a shade in from the edge, a dark rising at the foot for the word, the rim
    and the lacquer's line under the top edge. Pressed: the kit's lit press, the rim and a wash in the card's light."""
    inside = cover(d)
    ui.over(t.px, ui.BLACK, edge * np.exp(np.minimum(d, 0) / 7.0) * inside)
    h = (y1 - y0) * foot
    v = np.clip((t.y - (y1 - h)) / h, 0, 1)
    ui.over(t.px, ui.c("#05060A"), 0.82 * v * v * (3 - 2 * v) * inside)
    if pressed:
        ui.over(t.px, col(light), 0.16 * inside)
        ui.over(t.px, col(light), 0.6 * np.exp(-(np.maximum(d, 0) / 5.0) ** 1.4) * np.clip(0.5 + d * K, 0, 1))
        t.line(d, 2.0, col(rim) * 0.4 + 0.6)
    else:
        t.line(d, 1.2, col(rim), 0.95)
    ui.over(t.px, col(glint), cover(np.maximum(d, np.abs(t.y - (y0 + 2.2)) - 1.0)) * (0.5 if pressed else 0.28))


def voidkin_card(t, fr, fx0, fx1, y0, y1, pressed, lead_px, rise=False, rarity=RARITY):
    pts = fr.card(fx0, fx1, y0, y1)
    d = t.poly(pts)
    m = MAT["Voidkin"]
    light = ui.c(TRIM[rarity])
    t.glow(d, 7.0, ui.BLACK, 0.6)
    t.paint(d, t.ramp(m["body"][0], m["body"][1], (t.y - y0) / (y1 - y0)))
    mid = (y0 + y1) / 2
    cx = (fr.at(fx0, mid) + fr.at(fx1, mid)) / 2
    wide, high = fx1 - fx0, y1 - y0
    # the rarity's light: a field rising from behind the shoulders, brightest behind the head, the foot left dark
    radial(t, d, cx + wide * 0.08, y0 + high * 0.3, wide * 0.62, high * 0.5, light * 0.7 + 0.3, 0.85)
    radial(t, d, cx + wide * 0.1, y0 + high * 0.22, wide * 0.3, high * 0.22, light * 0.35 + 0.65, 0.5)
    # the figure: the hair's top 10 points under the card's top (14 over it when it rises), the belt at the foot
    head = 10.0 if not rise else -14.0
    scale = (y1 - 6 - (y0 + head)) / (LEAD_BELT - lead_top(lead_px))   # points a render pixel
    fig = image(lead_px, lead_px.shape[1] * scale)
    fy = y0 + head - lead_top(lead_px) * scale
    fx = cx - fig.shape[1] / K / 2
    halo = fc.scaled(rs.shrink(fig, 0.125), 8.0)[:fig.shape[0], :fig.shape[1]].copy()   # the figure's light behind it
    halo[..., :3] = light * 0.5 + 0.5
    halo[..., 3] = np.clip(halo[..., 3] * 1.6, 0, 1) * 0.55
    t.image(halo, fx, fy, d + 1.2)
    t.image(fig, fx, fy, d + 1.2)
    finish(t, d, y0, y1, light, light * 0.6 + 0.4, MAT["Voidkin"]["glint"], pressed, foot=0.3, edge=0.38)
    if rise:                                    # the head over the frame: the figure again, above the top edge only
        above = t.poly([(fr.at(fx0, y0) + 7, y0 - 40), (fr.at(fx1, y0), y0 - 40), (fr.at(fx1, y0), y0 + 1.4),
                        (fr.at(fx0, y0) + 7, y0 + 1.4)])
        t.image(fig, fx, fy, above)
    size = word_size("Voidkin", fx1 - fx0, 22)
    word(t, fr.at(fx0, y1 - 10) + 10, y1 - 10 - size * 0.72, size, "Voidkin")
    return d


def equipment_card(t, fr, fx0, fx1, y0, y1, pressed, art):
    pts = fr.card(fx0, fx1, y0, y1)
    d = t.poly(pts)
    m = MAT["Equipment"]
    t.glow(d, 7.0, ui.BLACK, 0.6)
    t.paint(d, t.ramp(m["body"][0], m["body"][1], (t.y - y0) / (y1 - y0)))
    wide, high = fx1 - fx0, y1 - y0
    size = word_size("Equipment", wide, 20)
    room = high - size - 14                                      # above the word
    ring = min(wide * 0.86, room * 0.9)
    ry = y0 + 4 + room * 0.5
    rx = (fr.at(fx0, ry) + fr.at(fx1, ry)) / 2
    # the forge's light: a hot core in the ring, falling off to the dark bronze, embers rising out of it
    radial(t, d, rx, ry, ring * 0.5, ring * 0.5, "#FF5E14", 0.55)
    radial(t, d, rx, ry, ring * 0.22, ring * 0.22, "#FFC27A", 0.5)
    rng = np.random.default_rng(7)
    for _ in range(18):
        a = rng.uniform(0, 2 * np.pi)
        r = ring * rng.uniform(0.3, 0.75)
        ex, ey = rx + np.cos(a) * r * 0.8, ry + np.sin(a) * r - ring * rng.uniform(0.0, 0.25)
        mote = rng.uniform(0.6, 1.5)
        dot = np.hypot(t.x - ex, (t.y - ey) * 0.7) - mote
        ui.over(t.px, ui.c("#FFC27A" if rng.random() < 0.5 else "#FF8A3D"),
                cover(np.maximum(dot, d)) * rng.uniform(0.45, 0.95))
    rim = image(art["ring"], ring, "#E9B970", 0.95)
    t.image(rim, rx - ring / 2, ry - ring / 2, d + 1.2)
    blade_w = ring * 1.24
    blade = image(art["blade"], blade_w, "#FFF0DC")
    bx, by = rx - blade_w / 2, ry - blade_w / 2
    t.image(blade, bx, by, d + 1.2)
    jw = blade_w * 0.2
    t.image(image(art["jewel"], jw), bx + 0.29 * blade_w - jw / 2, by + 0.70 * blade_w - jw / 2, d + 1.2)
    # the emblem in its socket, the card's top right
    s = min(34.0, wide * 0.28)
    sx, sy = fr.at(fx1, y0 + 6 + s / 2) - s - 7, y0 + 7
    t.image(image(art["socket"], s), sx, sy, d + 1.2)
    t.image(image(art["edge"], s, "#E9B970"), sx, sy, d + 1.2)
    t.image(image(art["emblem"], s * 0.92), sx + s * 0.04, sy + s * 0.04, d + 1.2)
    finish(t, d, y0, y1, m["light"], m["rim"], m["glint"], pressed)
    plus = max(16.0, ring * 0.2)
    nx = rx + ring * 0.12
    t.text(nx + 1.0, ry - ring * 0.5 + 1.4, plus, "+7", "#000000", layer="a_shade", shear=LEAN, bold=0.45)
    t.text(nx, ry - ring * 0.5, plus, "+7", "#FFD36B", shear=LEAN, bold=0.45)
    word(t, fr.at(fx0, y1 - 10) + 10, y1 - 10 - size * 0.72, size, "Equipment")
    return d


def settings_card(t, fr, fx0, fx1, y0, y1, pressed):
    pts = fr.card(fx0, fx1, y0, y1, cut=5.0)
    d = t.poly(pts)
    m = MAT["Settings"]
    t.glow(d, 6.0, ui.BLACK, 0.55)
    t.paint(d, t.ramp(m["body"][0], m["body"][1], (t.y - y0) / (y1 - y0)))
    high = y1 - y0
    size = 14.0
    cog = min(high - size - 22, 26.0)
    cy = y0 + 8 + cog / 2
    cx = (fr.at(fx0, cy) + fr.at(fx1, cy)) / 2
    radial(t, d, cx, cy, cog, cog, m["light"], 0.18)
    finish(t, d, y0, y1, m["light"], m["rim"], m["glint"], pressed, foot=0.3)
    up.mark(t, "Settings", cx, cy, cog, ui.c("#C9D0D9"), tab=True)
    w = EM * size * len("Settings")
    word(t, (fr.at(fx0, y1 - 9) + fr.at(fx1, y1 - 9)) / 2 - w / 2 - 2, y1 - 9 - size * 0.72, size, "Settings")
    return d


def quest_room(t, fr, fx0, fx1, y0, y1):
    """Quest's room, a guide only: a faint outline where its card will stand."""
    d = t.poly(fr.card(fx0, fx1, y0, y1, cut=5.0))
    dash = (np.floor((t.x + t.y) / 4.0) % 2) == 0
    ui.over(t.px, ui.c("#8C96A8"), cover(np.abs(d + 0.5) - 0.5) * dash * 0.35)
    t.text((fr.at(fx0, (y0 + y1) / 2) + fr.at(fx1, (y0 + y1) / 2)) / 2 - 18, (y0 + y1) / 2 - 5, 13, "Quest",
           "#4C5464", shear=LEAN, bold=0.2)


def glass(t, x0, y0, x1, y1, home_x):
    """The panel's ground: dark glass, cut corners, a lacquer line, a pointer down at Home's tile."""
    pts = ui.cut_box(x0, y0, x1, y1, 12, 0, 12, 0)
    d = t.poly(pts)
    point = t.poly([(home_x - 10, y1 - 0.5), (home_x + 10, y1 - 0.5), (home_x, y1 + 8)])
    d = np.minimum(d, point)
    t.glow(d, 10.0, ui.BLACK, 0.55)
    ui.over(t.px, t.ramp("#1A2131", "#07090E", (t.y - y0) / (y1 - y0)), cover(d) * 0.88)
    band = np.exp(-(((t.x - x0) - (t.y - y0) * 1.6 - (x1 - x0) * 0.18) / 46.0) ** 2)
    ui.over(t.px, ui.c("#A9C1E8"), 0.05 * band * cover(d))
    t.line(d, 1.0, ui.c("#2E3749"), 0.95)
    ui.over(t.px, ui.c("#CFDBFF"), cover(np.maximum(d, np.abs(t.y - (y0 + 1.6)) - 0.7)) * 0.3)


def panel_box(w, h, which):
    pw, ph = PANEL
    foot = h - hp.DOCK_UP - DOCK_GAP
    left = max(LEAD_RIGHT[which] + 8, w / 2 - pw / 2)
    left = min(left, w - 6 - pw)
    return left, foot - ph, left + pw, foot


def draw_panel(t, w, h, which, kind, pressed, art):
    x0, y0, x1, y1 = panel_box(w, h, which)
    glass(t, x0, y0, x1, y1, w / 2)
    fr = Frame(x0 + PAD, y1 - PAD)
    top = y0 + PAD
    for name, fx0, fx1, a, b in COMPOSITIONS[kind]:
        on = pressed == name
        if name == "Voidkin":
            voidkin_card(t, fr, fx0, fx1, top + a, top + b, on, art["lead"], rise=(kind == "C"))
        elif name == "Equipment":
            equipment_card(t, fr, fx0, fx1, top + a, top + b, on, art)
        elif name == "Settings":
            settings_card(t, fr, fx0, fx1, top + a, top + b, on)
        else:
            quest_room(t, fr, fx0, fx1, top + a, top + b)


def opened(world, which, kind, pressed, art):
    w, h = hp.size_of(world)
    pic = hp.layer(w, h, lambda t: draw_panel(t, w, h, which, kind, pressed, art))
    out = hp.dimmed(world, "B", DIM)
    um.put(out, pic)
    return out


# --- the sheet ------------------------------------------------------------------------------------------------------

def lettered(sheet, words, band=360):
    height, width = sheet.shape[:2]
    for top in range(0, height, band):
        items = [(x, y - top, size, text, code) for x, y, size, text, code in words if top <= y < top + band]
        if items:
            rs.paste(sheet, rs.text_layer(width, band + 40, items), 0, top)


def sheet(out):
    world = hp.worlds()
    eq = UI / "equipment" / "images"
    art = dict(lead=rs.load(out / LEAD_PNG), ring=rs.load(eq / "ReinforceRing.png"),
               blade=rs.load(UI / "gear" / "images" / "GearLanternsteelSword.png"),
               jewel=rs.load(UI / "jewels" / "images" / "JewelRed3.png"), socket=rs.load(eq / "SocketFill.png"),
               edge=rs.load(eq / "SocketEdge.png"), emblem=rs.load(UI / "emblems" / "images" / "EmblemHighcrown.png"))
    game, small = world["game"], world["small"]
    gh, gw = game.shape[:2]
    sh_, sw_ = small.shape[0] // 2, small.shape[1] // 2
    margin, gap, head = 24, 16, 64
    width = margin * 2 + 2 * gw + gap * 2 + sw_
    height = 150 + len(COMPOSITIONS) * (head + gh + 30) + head + 196 * K + 30
    page = rs.canvas(width, height, tuple(rs.rgb("#101117")))
    words = [(margin, 22, 34, "AR49, Home's panel: three cards with their own art (a blockout)", "#EDE6D6"),
             (margin, 76, 20, "Each over Faber's fight capture, dimmed, the dock left lit. Left at rest, middle with "
                              "Voidkin pressed (the kit's lit press: its rim and a wash in its light), right the "
                              "smallest phone (568 x 320) at its own size.", "#A9A398"),
             (margin, 108, 20, "Quest's room is the faint dashed outline, a guide only. The lead is Rook (Common), "
                               "rendered waist up for a live view of the lead's model.", "#A9A398")]
    y = 150
    for kind in COMPOSITIONS:
        words.append((margin, y + 14, 26, f"{kind}, {NAMES[kind]}: {SAID[kind]}", "#EDE6D6"))
        rest = opened(game, "game", kind, None, art)
        rs.paste(page, rest, margin, y + head)
        del rest
        lit = opened(game, "game", kind, "Voidkin", art)
        rs.paste(page, lit, margin + gw + gap, y + head)
        del lit
        tiny = opened(small, "small", kind, None, art)
        rs.paste(page, rs.shrink(tiny, 0.5).copy(), margin + 2 * (gw + gap), y + head)
        del tiny
        y += head + gh + 30
    words.append((margin, y + 14, 26, "The Voidkin card on each rarity's light (Config.Hud.Card.Trim), its lead "
                                      "the same: Common, Uncommon, Rare, Epic, Legendary, Mythical", "#EDE6D6"))
    cw, ch = 150.0, 196.0
    for k, rarity in enumerate(lca.RARITIES):
        def one(t, rarity=rarity):
            glass(t, 4, 4, cw - 4, ch - 4, -100)
            fr = Frame(4 + PAD, ch - 4 - PAD)
            voidkin_card(t, fr, 0, 120, 4 + PAD, 4 + PAD + H_IN, False, art["lead"], rarity=rarity)
        pic = hp.layer(cw, ch, one)
        tile = rs.canvas(round(cw * K), round(ch * K), tuple(rs.rgb("#0B0D12")))
        um.put(tile, pic)
        rs.paste(page, tile, margin + k * (round(cw * K) + gap), y + head)
    lettered(page, words)
    rs.save(page, out / "home_cards.png")
    print(f"wrote {out / 'home_cards.png'} {width}x{height}")


def main():
    out = bl.out_dir()
    rs.OUT = out                                    # rook_sheet's lettering writes its passes there
    if sys.argv[-1] == "lead":
        lead(out)
    else:
        sheet(out)


if __name__ == "__main__":
    main()
