"""AR12 (docs/asset-requests.md, AR12, "The palette, recomposed"): the director, 2026-11-15, 19:09: "to much purple we
need a new palette well composed". One sheet for the pick, cheap: today's colours with the purple counted, then whole
palettes, each a row: what it's made of and in what proportion, then the same four things in it: the HUD's pieces over
the dusk street, the card after the reveal, and Power's bar in its room.

A palette here is three rooms (the field's, the machines', the void's) and the colours that mean a system. The rarities
keep theirs in every row: Epic's purple is the director's own (2026-11-12). Nothing here is an image for the game; text
is Blender's face standing in for the game's.

    blender -b --factory-startup --python tools/blender/palette_compose_sheet.py -- build/handoff/UI/hud/colour
"""
import colorsys
import sys
import textwrap
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import hud_colour_sheet as h  # noqa: E402
import power_vivid_sheet as pv  # noqa: E402
import screens_vivid_sheet as sv  # noqa: E402

kit, ui, rs, c = h.kit, h.ui, h.rs, h.c
K4 = h.K4
GRAPHITE = kit.PALETTES["Graphite Dark"]
POWER, CREDITS, MAP = h.POWER, h.CREDITS, h.MAP
TRAINING = pv.TRAINING
SWATCH, HUD, CARD, BAYS = (330.0, 194.0), (520.0, 194.0), (338.0, 194.0), (400.0, 194.0)
PURPLE = (230.0, 300.0)  # a hue between these, with some colour in it, is counted as purple: indigo to magenta


def system(colour, pale, deep, night):
    """A system's colour with its pale, its deep and its night (a Block piece's body), as hud_colour_sheet keeps them."""
    h.PALE[colour], h.DEEP[colour], h.NIGHT[colour] = pale, deep, night
    return colour


def room(base, **over):
    return dict(base, alpha=1.0, **over)


SILVER = system("#D9E1F0", "#FFFFFF", "#7C88A3", ("#2D3342", "#12151D"))
COPPER = system("#F28C5A", "#FFE1D0", "#A8481F", ("#4D2513", "#210F08"))
LANTERN = system("#FF914D", "#FFE4CC", "#B4530F", ("#4F270C", "#221005"))
STEEL = system("#B9C9E6", "#F3F7FF", "#61759C", ("#263146", "#10151F"))
BONE = system("#EDE4CC", "#FFFFFF", "#8F8468", ("#3B3628", "#191710"))

DYNAMO = room(h.ROOMS["Dynamo, vivid"])
ECLIPSE = room(GRAPHITE, panel=("#1C1F2A", "#090A10"), edge="#8F98AE", facet="#C6CCDA", glint="#FFFFFF", soft="#AEB4C2",
               faint="#787E8C", channel="#040507", well="#08090D", button=("#2E323F", "#1C1F29"),
               pressed=("#12141B", "#1C1F2A"), ground="#22242C", accent="#F4F1E8", core=0.5)
NIGHT = room(GRAPHITE, panel=("#18233F", "#0B1020"), edge="#3F5488", facet="#8AA2D6", glint="#CFE0FF", soft="#A3B1CF",
             faint="#6F7C9A", channel="#05070D", well="#090C15", button=("#27365C", "#1A2440"),
             pressed=("#111829", "#18233F"), ground="#262D40")
MIDNIGHT = room(GRAPHITE, panel=("#122A5C", "#06102B"), edge="#3F78E0", facet="#8CB6FF", glint="#DCEBFF", soft="#A9BEE6",
                faint="#7088BA", channel="#04070F", well="#070C1A", button=("#1C3A7A", "#12274F"),
                pressed=("#0B1A3D", "#122A5C"), ground="#1F2C4F", accent="#EAF3FF", core=0.5)
PATINA = room(GRAPHITE, panel=("#17292B", "#0B1517"), edge="#3B6A68", facet="#7FB5AE", glint="#C9F2EA", soft="#9DB8B4",
              faint="#6A8380", channel="#040808", well="#080E0E", button=("#223D3F", "#172B2D"),
              pressed=("#101E20", "#17292B"), ground="#263234")
COPPERWORKS = room(h.ROOMS["Dynamo, vivid"], panel=("#43220F", "#1C0E06"), edge="#B5622E", facet="#E89A66", glint="#FFD9BF",
             soft="#CFAE98", faint="#96735F", button=("#5C3118", "#38200F"), pressed=("#2A1509", "#43220F"),
             ground="#3A2A20")
ABYSS = room(GRAPHITE, panel=("#0C3A3D", "#041618"), edge="#25A69A", facet="#77E3D4", glint="#D4FFF7", soft="#9FCFC8",
             faint="#62958F", channel="#030A0A", well="#061110", button=("#125054", "#0B3336"),
             pressed=("#07262A", "#0C3A3D"), ground="#1B3336", accent="#CFFFF4", core=0.5)

# A palette: its three rooms, the colours that mean a system, and the share of a screen each is meant to take (a
# design's intent, not a measure). Power, Credits, the Map and every rarity are the same in all of them.
PALETTES = (
    dict(name="Today", logic="Four of the colours that mean a system, and the void's whole room, sit in purple, beside Epic's own.",
         main=room(GRAPHITE), machine=DYNAMO, void=room(h.ROOMS["Void Violet, vivid"]), voidkin=h.VOIDKIN, regalia=h.REGALIA,
         xp="#C9B8FF", breaker=pv.BREAKER,
         rooms=("Graphite", "Dynamo", "Void Violet")),
    dict(name="A. Eclipse", logic="Neutral holds the screen and colour is kept for meaning. The void is the dark with a "
                                  "pale corona, so on a reveal the rarity's light is the only colour there.",
         main=room(GRAPHITE), machine=DYNAMO, void=ECLIPSE, voidkin=SILVER, regalia=COPPER, xp=TRAINING, breaker="#E6ECF7",
         rooms=("Graphite", "Dynamo", "Eclipse")),
    dict(name="B. Lantern Night", logic="Opposites: the night's blue holds the screen, and the lanterns' orange is the one "
                                        "warm colour that leads the eye. The festival's own two lights.",
         main=NIGHT, machine=DYNAMO, void=MIDNIGHT, voidkin=LANTERN, regalia=STEEL, xp=TRAINING, breaker="#E6F0FF",
         rooms=("Night", "Dynamo", "Midnight")),
    dict(name="C. Copper and Patina", logic="One metal, two colours, opposite on the wheel: copper carries the current, and "
                                            "patina is what copper turns to. The plant's own matter.",
         main=PATINA, machine=COPPERWORKS, void=ABYSS, voidkin=COPPER, regalia=BONE, xp=TRAINING, breaker="#D6FFF6",
         rooms=("Patina", "Copperworks", "Abyss")),
)
SHARES = (("main", 0.5), ("machine", 0.18), ("void", 0.14), ("voidkin", 0.045), ("regalia", 0.045), ("power", 0.03),
          ("credits", 0.03), ("map", 0.03), ("xp", 0.02), ("breaker", 0.02))
ROLES = (("main", "the field"), ("machine", "machines"), ("void", "the void"), ("voidkin", "Voidkin"),
         ("regalia", "Regalia"), ("power", "Power"), ("credits", "Credits"), ("map", "the Map"), ("xp", "experience"),
         ("breaker", "the Breaker"))


def colour_of(pal, role):
    if role in ("main", "machine", "void"):
        return pal[role]["panel"][0]
    return {"power": POWER, "credits": CREDITS, "map": MAP}.get(role) or pal[role]


def is_purple(code):
    r, g, b = c(code)[:3]
    hue, _, sat = colorsys.rgb_to_hls(float(r), float(g), float(b))
    return sat > 0.2 and PURPLE[0] <= hue * 360 <= PURPLE[1]


def purples(pal):
    return [name for role, name in ROLES if is_purple(colour_of(pal, role))]


def shot(st):
    return h.bytes8(h.halve(st.px)), st.items


def stone(st, x, y, size, colour, ring=None):
    """A swatch: a cut stone of the colour, as a row's chip is."""
    pad = 4.0
    t = kit.blank(size + 2 * pad, size + 2 * pad)
    d = t.poly(ui.cut_box(pad, pad, pad + size, pad + size, 4.0, 1.0, 4.0, 1.0))
    t.paint(d - 1.4, c(ring or h.STROKE))
    t.paint(d, t.ramp(h.mix(colour, "#FFFFFF", 0.18), colour, (t.y - pad) / size))
    h.place(st, t, x - pad, y - pad)


def swatches(pal):
    """What the palette is made of: its colours in the proportion meant for them, then each by its part."""
    w, hh = SWATCH
    st = kit.Stage(w, hh, h.GROUND)
    x = 4.0
    t = kit.blank(w, 26.0)
    for role, share in SHARES:
        seg = (w - 8.0) * share
        code = colour_of(pal, role)
        t.paint(np.maximum(np.maximum(x - t.x, t.x - (x + seg - 1.0)), np.abs(t.y - 13) - 11),
                t.ramp(h.mix(code, "#FFFFFF", 0.08), code, t.y / 26.0))
        x += seg
    h.place(st, t, 0, 4)
    for i, (role, name) in enumerate(ROLES):
        col, row = i % 5, i // 5
        sx, sy = 8.0 + col * 64.0, 46.0 + row * 72.0
        code = colour_of(pal, role)
        stone(st, sx, sy, 30.0, code, ring="#FFFFFF" if is_purple(code) else None)
        label = pal["rooms"][i] if i < 3 else name
        st.text(sx - 2, sy + 37, 8, label, h.HEAD)
        st.text(sx - 2, sy + 48, 7, name if i < 3 else code, h.NOTE)
    return shot(st)


def shard(st, cx, cy, r, colour):
    t = kit.blank(4 * r, 4 * r)
    d = h.g_shard(t, 2 * r, 2 * r, r)
    t.paint(d - 1.2, c(h.STROKE))
    t.paint(d, t.ramp(h.mix(colour, "#FFFFFF", 0.5), colour, (t.y - r) / (2 * r)))
    h.place(st, t, cx - 2 * r, cy - 2 * r)


def hud(pal, street):
    """The HUD's pieces over the dusk street: the two pills, a lead's plate in the field's room, the dock's four."""
    w, hh = HUD
    st = kit.Stage(w, hh, "#000000")
    rows, cols = st.px.shape[:2]
    y0, x0 = street.shape[0] - rows - round(40 * K4), (street.shape[1] - cols) // 2
    st.px[:] = street[y0:y0 + rows, x0:x0 + cols]
    p = pal["main"]
    kit.panel(st, 8, 8, 206, 64, p)
    sv.pip(st, 24, 24, sv.WORD["Epic"])
    pv.runs(st, 33, 24, 14, (("Rook", p["text"]), ("Lv 12", p["soft"])))
    kit.bar(st, 20, 38, 182, 10.0, 0.78, p)
    kit.bar(st, 20, 55, 182, 4.0, 0.42, p, pal["xp"])
    h.pill(st, w - 8 - 120, 8, 120, CREDITS, h.BLOCK, "CoinMint", "35,170")
    h.pill(st, w - 8 - 200, 8 + 36, 200, POWER, h.BLOCK, "Bolt", "30 kW", "24 kW used", None, 24 / 30)
    x = (w - 4 * 96 - 3 * 6) / 2
    for label, icon, accent in (("Voidkin", "Shard", pal["voidkin"]), ("Regalia", "Crest", pal["regalia"]),
                                ("Base", "Plant", POWER), ("Map", "Route", MAP)):
        h.dock(st, x, hh - 8 - 52, label, icon, accent, h.BLOCK)
        x += 102
    return shot(st)


def card(pal):
    """The card after the reveal, in the void's room: an Epic, so Epic's purple is seen in it."""
    w, hh = CARD
    p = pal["void"]
    st = kit.Stage(w, hh, p["ground"])
    kit.panel(st, 8, 8, 322, 178, p)
    pv.breath(st, 104, 60, 150.0, 60.0, p["glint"], 0.16)  # the room's own pale light behind the name
    pv.word(st, 28, 35.5, sv.SMALL, "A new Voidkin", p["soft"])
    pv.word(st, 28, 67, 21, "Rook", p["text"])
    sv.pip(st, 33, 98, sv.WORD["Epic"])
    pv.runs(st, 42, 98, 13, (("Epic", sv.WORD["Epic"]), ("·", p["faint"]), ("Strength", p["soft"]), ("·", p["faint"]),
                             ("Warrior", p["soft"])))
    shard(st, 35, 125, 7.0, pal["voidkin"])
    pv.runs(st, 45.5, 125, 13, (("In your collection", pal["voidkin"]),))
    x = 28.0
    for rarity in ("Common", "Uncommon", "Rare", "Legendary", "Mythical"):  # the other five, on this room's panel
        sv.pip(st, x + 5, 154, sv.WORD[rarity])
        x = pv.runs(st, x + 13, 154, 9.5, ((rarity, sv.WORD[rarity]),)) + 3
    return shot(st)


def bays(pal):
    """Power's bar in the machines' room: the Breaker's light, the Training machine's, and Power's own."""
    w, hh = BAYS
    p = pal["machine"]
    st = kit.Stage(w, hh, p["ground"])
    kit.panel(st, 8, 8, w - 16, hh - 16, p)
    pv.word(st, 26, 32, 17, "Power", p["text"])
    pv.runs(st, 96, 33, 13, (("Generation", p["soft"]), ("30 kW", POWER)))
    pv.breath(st, w / 2, 76, 190.0, 34.0, pv.EMBER, 0.14)
    kit.button(st, 26, 60, w - 52, 34, "", p, "pressed")
    pv.bus(st, 34, 65, w - 68, 24.0, (0.4, 0.7), (pal["breaker"], TRAINING, POWER), p)
    for cut in (0.4, 0.7):
        pv.grip(st, 34 + 2 + (w - 72) * cut, 77)
    for i, (name, colour) in enumerate((("Void Breaker", pal["breaker"]), ("Training", TRAINING))):
        pv.chip(st, 28 + i * 124, 124, colour)
        pv.word(st, 46 + i * 124, 124, 13, name, p["text"])
    h.main_button(st, w - 26 - 96, 136, 96, 40, "Auto", p)
    pv.runs(st, 26, 156, 13, (("19 / 60 kWh", POWER), ("·", p["faint"]), ("holds 38 min", p["soft"])))
    return shot(st)


def measures():
    for pal in PALETTES:
        for key in ("main", "void", "machine"):
            ground = pal[key]["panel"][0]
            words = (("text", pal[key]["text"]), ("soft", pal[key]["soft"]), ("faint", pal[key]["faint"]),
                     ("Voidkin", pal["voidkin"]), ("the Breaker", pal["breaker"]), ("experience", pal["xp"]))
            words += tuple(sv.WORD.items()) if key != "machine" else ()
            said = ", ".join(f"{name} {pv.contrast(colour, ground):.1f}" for name, colour in words)
            print(f"{pal['name']}, {key} ({ground}): {said}")
        print(f"{pal['name']}: purple: {', '.join(purples(pal)) or 'none'}")


NOTES = (
    "The director, 2026-11-15: \"to much purple we need a new palette well composed\". A palette here is three rooms (the "
    "field's, the machines', the void's) and the colours that mean a system. In every row Power stays yellow, Credits "
    "teal, the Map rose, and each rarity keeps its colour: Epic's purple is the director's own, and it's the only purple "
    "left in A, B and C. A swatch ringed in white is counted as purple (a hue from indigo to magenta).",
    "Each row: the palette's colours in the proportion meant for them (a design's intent, not a measure); the HUD's pieces "
    "over the dusk street, which is itself violet; the card after the reveal in the void's room, an Epic, with the other "
    "five rarities on the same panel; Power's bar in the machines' room. In A, B and C experience takes the Training "
    "machine's cyan, since training is what gives it.",
    "Stand-ins: Blender's face for the game's text; the lead's plate is a plain panel, not the lead's card; Rook is a "
    "Common, and stands in as an Epic here only to show Epic's purple. Nothing here is an image for the game.",
)


def sheet(out, rows):
    ui.K = 2
    m, gap = 20.0, 16.0
    widths = (SWATCH[0], HUD[0], CARD[0], BAYS[0])
    width = 2 * m + sum(widths) + 3 * gap
    lines = [line for note in NOTES for line in textwrap.wrap(note, 330)]
    pitch = 50.0 + SWATCH[1] + 12.0
    sh = ui.Sheet(width, 50 + len(rows) * pitch + len(lines) * 15 + 16, h.GROUND)
    t = sh.tile(0, 0, sh.w, sh.h)
    t.text(m, 14, 17, "Grow your Anime: the palette, recomposed. Today, and three whole palettes with Epic as their only purple", h.HEAD)
    for j, (pal, shots) in enumerate(rows):
        y = 50 + j * pitch
        said = purples(pal)
        count = f"Purple: {', '.join(said)}, and Epic." if said else "Purple: Epic only."
        t.text(m, y, 14, pal["name"], h.HEAD)
        t.text(m, y + 22, 10, f"{pal['logic']} {count}", h.NOTE)
        x = m
        for (px, items), w in zip(shots, widths):
            h.add(sh, px, items, x, y + 42)
            x += w + gap
    y = 50 + len(rows) * pitch
    for i, line in enumerate(lines):
        t.text(m, y + i * 15, 10, line, h.NOTE)
    kit.finish(sh, out / "palette_compose.png")


def main():
    out = bl.out_dir()
    h.stage("started")
    sv.slices()
    h.block_images()
    measures()
    street = h.backdrop("dusk")
    rows = []
    for pal in PALETTES:
        rows.append((pal, (swatches(pal), hud(pal, street), card(pal), bays(pal))))
        h.stage(pal["name"])
    del street
    kit.IMAGES.clear()
    sheet(out, rows)
    h.stage("the sheet")


if __name__ == "__main__":
    main()
