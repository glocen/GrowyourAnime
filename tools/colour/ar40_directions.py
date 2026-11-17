"""AR40 (docs/asset-requests.md, AR40): three colour directions by day, as values for the block in the place.

The director, 2026-11-17, 22:15: "i think the game is way to much too purple/Black and somber". Research's class: violet
is an accent where the void acts, bodies get value range, day gets a warm second colour, a look is judged by day first.

A direction moves only what's there: the kit's swatches by name (tools/blender/base_kit.py, SWATCHES: the machines' body
is "abyss", their frame "girder", their fitting "bone"), the wall's print as a ramp, the Strip's stones as a tint, the
day's light (Config.Lighting) and two UI palettes (Config.UIKit: Graphite, the HUD's; Seam, the bag's). No model, no
texture file: the builder tries them live, and the pick is painted in afterwards.

    py tools/colour/ar40_directions.py     writes build/handoff/Colour/ar40/directions.json, directions.md, chips.png

chips.png is flat colour beside flat colour, never a render: it shows each direction's values against each other and
against today's, and nothing of the game's light.
"""
import colorsys
import json
import struct
import sys
import zlib
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "handoff" / "Colour" / "ar40"
VIOLET = (235.0, 310.0, 0.18)   # a hue between these with at least this much colour in it counts as violet
DARK = 30.0                     # a body under this L* counts as black
WORDS = 4.5                     # words on their panel: the contrast they need

# The kit's cell, for a repaint in the place: a swatch is CELL pixels, its head's colour falling to its foot's down the
# cell by (y / (h - 1)) ** 0.85, times a shade across it of 1 - 0.5 * clamp((x - 8) / 48, 0, 1), all in sRGB code values
# (base_kit.atlas). Where each sits: base_kit.SWATCH_AT, in the kit's Manifest.
CELL = (64, 128)

TODAY = {
    "Name": "Today",
    "Idea": "void stone in dark violet, navy frames, a lilac fill, black glass",
    "Swatches": {
        "abyss": ("#4B3A7E", "#171030"), "girder": ("#4C5878", "#242C42"), "bone": ("#E9E2D2", "#9C95A6"),
        "steel": ("#8290B0", "#46506E"), "dark": ("#1E1426", "#0C0A12"), "rubber": ("#1F2233", "#0E101A"),
        "far": ("#9284C8", "#5E5298"), "tower": ("#7C76AE", "#46427A"), "outcrop": ("#8474BC", "#4A3E86"),
    },
    "Panel": ("#20263E", "#93A0C8"),          # the wall's print, its darkest and its lightest
    "Stones": "#B9ACD0",                      # the Strip's stones by day, read off a capture (ar20-crossing-day)
    "Lighting": {
        "Phases.Day.Sun": "#FFE2B8", "Phases.Day.Brightness": 2.6, "Phases.Day.Ambient": "#8A8496",
        "Phases.Day.Exposure": 0.0, "Phases.Day.Atmosphere.Color": "#EFE3D6", "Phases.Day.Atmosphere.Decay": "#A9BCE4",
        "Phases.Day.Glow": 0.45, "Clear.Phases.Day.Ambient": "#A3A1B4", "Clear.Phases.Day.Brightness": 2.61,
        "Clear.Phases.Day.Exposure": 0.16,
    },
    "UI": {
        "Graphite": {"Panel": ("#20242C", "#13151A"), "Edge": "#434A57", "Facet": "#8A93A6", "Glint": "#C9D2E4",
                     "Text": "#F3EFE6", "Soft": "#A6ADBA", "Faint": "#6E7482", "Channel": "#06070A", "Well": "#0B0C10",
                     "Button": ("#323845", "#22262F"), "Pressed": ("#1A1D24", "#20242C"), "Ground": "#2B2E36",
                     "Accent": "#FFF4D6"},
        "Seam": {"Panel": ("#1A1430", "#0C0A16"), "Edge": "#3B3358", "Facet": "#8F84B8", "Glint": "#DCD3FF",
                 "Text": "#F1ECFF", "Soft": "#B9B0D6", "Faint": "#6F6790", "Channel": "#050409", "Well": "#1B1728",
                 "Button": ("#2A2244", "#1A1530"), "Pressed": ("#120E20", "#1A1430"), "Ground": "#1E1A2C",
                 "Accent": "#EDE4FF", "Backing": "#07060C", "Light": "#EDE4FF", "Ink": "#0B0913",
                 "Card": ("#221A3C", "#0E0B18")},
    },
}

DIRECTIONS = [
    {
        "Name": "A, porcelain and gold",
        "Idea": "the machines in warm white stone on slate frames with gold fittings; a warm white sun; the HUD and "
                "the bag as cream paper with slate ink. The brightest of the three, and the furthest from today.",
        "Swatches": {
            "abyss": ("#F6F1E6", "#B9B6C0"), "girder": ("#5C6C8E", "#323E5A"), "bone": ("#F2C45A", "#9A6A24"),
            "steel": ("#B6C4DE", "#6E7EA0"), "dark": ("#3A4660", "#1E2638"), "rubber": ("#2A3040", "#161A26"),
            "far": ("#C6D0EE", "#97A4D2"), "tower": ("#B4BCE0", "#8088BC"), "outcrop": ("#BBC0E6", "#868EC6"),
        },
        "Panel": ("#4E618A", "#C9D5EC"),
        "Stones": "#D2CCC2",
        "Lighting": {
            "Phases.Day.Sun": "#FFF0D2", "Phases.Day.Brightness": 2.6, "Phases.Day.Ambient": "#A9A7A0",
            "Phases.Day.Exposure": 0.0, "Phases.Day.Atmosphere.Color": "#F6EBD8", "Phases.Day.Atmosphere.Decay": "#B4CCEC",
            "Phases.Day.Glow": 0.6, "Clear.Phases.Day.Ambient": "#B6B4AC", "Clear.Phases.Day.Brightness": 2.5,
            "Clear.Phases.Day.Exposure": 0.05,
        },
        "UI": {
            # Graphite wears Pearl Light's own values (Config.UIKit, Pearl): a palette the game already draws
            "Graphite": {"Panel": ("#FAF7F0", "#E9E4D8"), "Edge": "#2A3142", "Facet": "#FFFFFF", "Glint": "#FFFFFF",
                         "Text": "#191B21", "Soft": "#535967", "Faint": "#8C909B", "Channel": "#20232B",
                         "Well": "#D8D2C4", "Button": ("#FFFFFF", "#EFEADF"), "Pressed": ("#DAD4C6", "#E6E1D5"),
                         "Ground": "#CFCBC2", "Accent": "#E0A52E"},
            "Seam": {"Panel": ("#FBF9F4", "#E9E5DC"), "Edge": "#C9C2B2", "Facet": "#FFFFFF", "Glint": "#FFFFFF",
                     "Text": "#1B1D26", "Soft": "#565B6B", "Faint": "#9296A2", "Channel": "#2A2E3A", "Well": "#DDD8CC",
                     "Button": ("#FFFFFF", "#F0ECE2"), "Pressed": ("#DCD6C8", "#E8E3D8"), "Ground": "#D4D0C6",
                     "Accent": "#E0A52E", "Backing": "#EDE8DC", "Light": "#7A4DF0", "Ink": "#FFFFFF",
                     "Card": ("#FFFFFF", "#F1EDE3")},
        },
    },
    {
        "Name": "B, sky steel",
        "Idea": "the machines in light blue steel with white frames, the void's violet only in their cores; a clear "
                "blue fill under a warm white sun; the HUD and the bag in white with sky blue, gold for what's chosen.",
        "Swatches": {
            "abyss": ("#C6D6EE", "#7E94BC"), "girder": ("#F0F3F8", "#AEB8CC"), "bone": ("#FFE9A8", "#C89A3C"),
            "steel": ("#9FB6DC", "#5C76A6"), "dark": ("#34507E", "#1C2E50"), "rubber": ("#263248", "#141C2C"),
            "far": ("#BCD0F2", "#8AA4DA"), "tower": ("#A8BCE6", "#748CC8"), "outcrop": ("#B2C0EC", "#7E90D0"),
        },
        "Panel": ("#6E86B4", "#F2F5FA"),
        "Stones": "#CBD0DA",
        "Lighting": {
            "Phases.Day.Sun": "#FFF6E0", "Phases.Day.Brightness": 2.7, "Phases.Day.Ambient": "#98A8BC",
            "Phases.Day.Exposure": 0.0, "Phases.Day.Atmosphere.Color": "#EAF2FA", "Phases.Day.Atmosphere.Decay": "#A8C8F0",
            "Phases.Day.Glow": 0.55, "Clear.Phases.Day.Ambient": "#AEBCCE", "Clear.Phases.Day.Brightness": 2.6,
            "Clear.Phases.Day.Exposure": 0.08,
        },
        "UI": {
            "Graphite": {"Panel": ("#FFFFFF", "#E8F0FA"), "Edge": "#3F7FD8", "Facet": "#FFFFFF", "Glint": "#FFFFFF",
                         "Text": "#16284A", "Soft": "#4C6088", "Faint": "#8A9AB8", "Channel": "#1C2C4C",
                         "Well": "#D2DEEE", "Button": ("#4C94EE", "#2F74D2"), "Pressed": ("#255FB0", "#2F74D2"),
                         "Ground": "#C4D2E6", "Accent": "#FFC93C"},
            "Seam": {"Panel": ("#FFFFFF", "#E6EEF9"), "Edge": "#9DBDEA", "Facet": "#FFFFFF", "Glint": "#FFFFFF",
                     "Text": "#16284A", "Soft": "#4C6088", "Faint": "#8A9AB8", "Channel": "#1C2C4C", "Well": "#D6E1F0",
                     "Button": ("#4C94EE", "#2F74D2"), "Pressed": ("#255FB0", "#2F74D2"), "Ground": "#C8D5E8",
                     "Accent": "#FFC93C", "Backing": "#DCE8F6", "Light": "#2F74D2", "Ink": "#FFFFFF",
                     "Card": ("#FFFFFF", "#EEF4FB")},
        },
    },
    {
        "Name": "C, sandstone and teal",
        "Idea": "the machines in warm pale stone on teal bronze, the violet core against the sand; a gold day; the HUD "
                "and the bag stay a glass with pale words, lifted from black to a mid slate teal with gold. The "
                "nearest to today on screen, the warmest in the world.",
        "Swatches": {
            "abyss": ("#EEDDBC", "#B2946C"), "girder": ("#46A39C", "#1F5E64"), "bone": ("#FFF4DC", "#C2AE8C"),
            "steel": ("#A9C2C8", "#62808A"), "dark": ("#2C5A60", "#163238"), "rubber": ("#2A3236", "#161C20"),
            "far": ("#DCD2D6", "#B0A2AE"), "tower": ("#CEC0C6", "#A08E9A"), "outcrop": ("#D4C4CC", "#A894A2"),
        },
        "Panel": ("#8A6E4E", "#F0E2C4"),
        "Stones": "#DCCFB8",
        "Lighting": {
            "Phases.Day.Sun": "#FFDDA6", "Phases.Day.Brightness": 2.8, "Phases.Day.Ambient": "#A89C8C",
            "Phases.Day.Exposure": 0.0, "Phases.Day.Atmosphere.Color": "#F8E4C4", "Phases.Day.Atmosphere.Decay": "#C0C8DC",
            "Phases.Day.Glow": 0.6, "Clear.Phases.Day.Ambient": "#BAAE9C", "Clear.Phases.Day.Brightness": 2.7,
            "Clear.Phases.Day.Exposure": 0.08,
        },
        "UI": {
            "Graphite": {"Panel": ("#3E6672", "#2C4C58"), "Edge": "#7CC4BC", "Facet": "#A9DCD4", "Glint": "#E6FFF8",
                         "Text": "#FFF6E2", "Soft": "#CCDCD8", "Faint": "#94ACAC", "Channel": "#182C34",
                         "Well": "#243E48", "Button": ("#56808C", "#3E6672"), "Pressed": ("#2C4C58", "#3E6672"),
                         "Ground": "#486C76", "Accent": "#FFC857"},
            "Seam": {"Panel": ("#3A626E", "#284852"), "Edge": "#6AAEA8", "Facet": "#A9DCD4", "Glint": "#E6FFF8",
                     "Text": "#FFF6E2", "Soft": "#CCDCD8", "Faint": "#94ACAC", "Channel": "#162A32", "Well": "#22404A",
                     "Button": ("#527C88", "#3A626E"), "Pressed": ("#284852", "#3A626E"), "Ground": "#44686E",
                     "Accent": "#FFC857", "Backing": "#30505A", "Light": "#FFE9B0", "Ink": "#1C2A30",
                     "Card": ("#487480", "#30545E")},
        },
    },
]


def rgb(text):
    return np.array([int(text[i:i + 2], 16) for i in (1, 3, 5)], np.float64) / 255.0


def linear(c):
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def light(text):
    """A colour's lightness, L* (0 black, 100 white)."""
    y = float(linear(rgb(text)) @ np.array([0.2126, 0.7152, 0.0722]))
    return 116 * y ** (1 / 3) - 16 if y > 0.008856 else 903.3 * y


def contrast(a, b):
    ya, yb = (float(linear(rgb(t)) @ np.array([0.2126, 0.7152, 0.0722])) for t in (a, b))
    return (max(ya, yb) + 0.05) / (min(ya, yb) + 0.05)


def violet(text):
    h, _, s = colorsys.rgb_to_hls(*rgb(text))
    return bool(VIOLET[0] <= h * 360 <= VIOLET[1] and s >= VIOLET[2] and 12 < light(text) < 92)


def tint(today, want):
    """What a surface's Color takes to move today's mean to the wanted one: a tint only darkens, so it's the ratio
    brought under 1, and how much light it costs."""
    ratio = linear(rgb(want)) / linear(rgb(today))
    top = float(ratio.max())
    code = (ratio / top) ** (1 / 2.2)
    return "#" + "".join(f"{int(round(v * 255)):02X}" for v in code), top


def measures(d):
    body = d["Swatches"]
    bodies = [body[n][i] for n in ("abyss", "girder", "bone", "steel") for i in (0, 1)]
    ui = d["UI"]
    grounds = [body["abyss"][0], body["abyss"][1], body["girder"][0], body["far"][0], body["tower"][0], d["Stones"],
               d["Lighting"]["Phases.Day.Ambient"], ui["Graphite"]["Panel"][0], ui["Seam"]["Panel"][0], ui["Seam"]["Backing"]]
    return {
        "BodyLight": [round(light(body["abyss"][0])), round(light(body["abyss"][1]))],
        "FrameLight": [round(light(body["girder"][0])), round(light(body["girder"][1]))],
        "Range": round(max(light(c) for c in bodies) - min(light(c) for c in bodies)),
        "VioletGrounds": int(sum(violet(c) for c in grounds)),
        "BlackGrounds": int(sum(light(c) < DARK for c in grounds)),
        "Grounds": len(grounds),
        "HudPanelLight": round(light(ui["Graphite"]["Panel"][0])),
        "BagPanelLight": round(light(ui["Seam"]["Panel"][0])),
        "HudWords": round(min(contrast(ui["Graphite"]["Text"], p) for p in ui["Graphite"]["Panel"]), 1),
        "BagWords": round(min(contrast(ui["Seam"]["Text"], p) for p in ui["Seam"]["Panel"]), 1),
        "BagChosen": round(contrast(ui["Seam"]["Ink"], ui["Seam"]["Light"]), 1),
    }


def png(path, page):
    raw = b"".join(b"\x00" + row.tobytes() for row in (np.clip(page, 0, 1) * 255 + 0.5).astype(np.uint8))
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))
    h, w = page.shape[:2]
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                     + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def fill(page, x, y, w, h, top, foot=None):
    t = np.linspace(0, 1, h)[:, None, None]
    page[y:y + h, x:x + w] = rgb(top) * (1 - t) + rgb(foot or top) * t


def row(d):
    """One direction as a strip, 1280 by 200: a machine on the yard under the day sky with the HUD's card over it, the
    bag's panel, then its swatches."""
    page = np.ones((200, 1280, 3))
    s, ui = d["Swatches"], d["UI"]
    # the yard: the sky, the far shards, the wall, the deck (the yard's own grey, which stays)
    fill(page, 0, 0, 520, 120, "#4FA3E0", "#C4DCF2")
    for x, tall, name in ((30, 70, "far"), (110, 96, "tower"), (430, 60, "far"), (470, 84, "outcrop")):
        fill(page, x, 120 - tall, 26, tall, *s[name])
    fill(page, 0, 104, 520, 16, d["Panel"][1], d["Panel"][0])
    fill(page, 0, 120, 520, 80, "#C9CED9", "#B4BAC8")
    fill(page, 380, 150, 140, 50, d["Stones"])
    # a machine: its body, its frame, its fitting, its core of void light, an outline of ink
    fill(page, 196, 46, 128, 124, "#0C0A16")
    fill(page, 200, 50, 120, 116, *s["abyss"])
    for x in (200, 304):
        fill(page, x, 50, 16, 116, *s["girder"])
    fill(page, 216, 50, 88, 12, *s["bone"])
    fill(page, 216, 150, 88, 16, *s["dark"])
    fill(page, 244, 80, 32, 56, "#E9DBFF", "#A97CFF")
    fill(page, 340, 90, 14, 80, *s["steel"])
    # the HUD's card and a button over the yard
    g = ui["Graphite"]
    fill(page, 14, 14, 150, 44, g["Edge"])
    fill(page, 16, 16, 146, 40, *g["Panel"])
    fill(page, 24, 24, 70, 6, g["Text"])
    fill(page, 24, 36, 46, 5, g["Soft"])
    fill(page, 110, 24, 44, 24, *g["Button"])
    fill(page, 110, 46, 44, 2, g["Accent"])
    # the bag: its cover, its panel, a card, words, a chosen plate, a button
    m = ui["Seam"]
    fill(page, 540, 0, 330, 200, m["Backing"])
    fill(page, 556, 16, 298, 168, m["Edge"])
    fill(page, 558, 18, 294, 164, *m["Panel"])
    for i in range(4):
        fill(page, 570 + i * 54, 60, 46, 60, *m["Card"])
        fill(page, 570 + i * 54, 60, 46, 2, m["Facet"])
    fill(page, 570, 60, 46, 60, m["Light"])
    fill(page, 578, 106, 30, 5, m["Ink"])
    fill(page, 570, 30, 110, 7, m["Text"])
    fill(page, 570, 44, 70, 5, m["Soft"])
    fill(page, 570, 134, 200, 36, m["Well"])
    fill(page, 790, 134, 50, 36, *m["Button"])
    fill(page, 790, 168, 50, 2, m["Accent"])
    # the swatches: body, frame, fitting, steel, trim, the wall, the stones, the sun, the fill
    chips = [s["abyss"], s["girder"], s["bone"], s["steel"], s["dark"], (d["Panel"][1], d["Panel"][0]), (d["Stones"],) * 2,
             (d["Lighting"]["Phases.Day.Sun"],) * 2, (d["Lighting"]["Phases.Day.Ambient"],) * 2]
    for i, (top, foot) in enumerate(chips):
        fill(page, 890 + i * 43, 16, 39, 168, top, foot)
    return page


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    every = [TODAY] + DIRECTIONS
    for d in every:
        d["Measures"] = measures(d)
        d["StonesTint"], d["StonesLight"] = tint(TODAY["Stones"], d["Stones"])
    (OUT / "directions.json").write_text(json.dumps({"Cell": CELL, "Today": TODAY, "Directions": DIRECTIONS}, indent=1),
                                         encoding="utf-8", newline="\n")
    gap = np.ones((8, 1280, 3)) * 0.5
    png(OUT / "chips.png", np.concatenate([part for d in every for part in (row(d), gap)][:-1]))
    lines = ["# AR40: three colour directions by day, as values", "",
             "From `tools/colour/ar40_directions.py`; the values are in `directions.json`, beside this. `chips.png` is "
             "flat colour, top to bottom Today, A, B, C: a machine on the yard with the HUD's card, the bag, then the "
             "swatches (body, frame, fitting, steel, trim, the wall, the stones, the sun, the fill). It's no render.", ""]
    for d in every:
        lines += [f"- **{d['Name']}:** {d['Idea']}"]
    lines += ["", "| | body L* | frame L* | bodies' range | violet grounds | black grounds | HUD panel L* | bag panel L* | "
              "HUD words | bag words | bag's chosen |", "|---|---|---|---|---|---|---|---|---|---|---|"]
    for d in every:
        m = d["Measures"]
        lines.append(f"| {d['Name']} | {m['BodyLight'][0]} to {m['BodyLight'][1]} | {m['FrameLight'][0]} to "
                     f"{m['FrameLight'][1]} | {m['Range']} | {m['VioletGrounds']} of {m['Grounds']} | "
                     f"{m['BlackGrounds']} of {m['Grounds']} | {m['HudPanelLight']} | {m['BagPanelLight']} | "
                     f"{m['HudWords']} | {m['BagWords']} | {m['BagChosen']} |")
    lines += ["", f"A ground is one of ten large surfaces: the body's head and foot, the frame, two far shards, the "
              f"stones, the day's fill, the HUD's panel, the bag's panel and its cover. Violet: a hue from "
              f"{VIOLET[0]:g} to {VIOLET[1]:g} degrees with colour in it. Black: under L* {DARK:g}. Words need "
              f"{WORDS:g} to 1 on their panel.", "",
              "Today's stones are read by eye off one capture, an estimate. The stones' tint (a surface's Color only "
              "darkens, so a tint alone loses the light named): "
              + "; ".join(f"{d['Name'].split(',')[0]} `{d['StonesTint']}`, which wants {d['StonesLight']:.2f} times the light"
                          for d in DIRECTIONS) + ".", ""]
    (OUT / "directions.md").write_text("\n".join(lines), encoding="utf-8", newline="\n")
    for d in every:
        print(d["Name"], d["Measures"])
        low = [k for k in ("HudWords", "BagWords", "BagChosen") if d["Measures"][k] < WORDS]
        if low:
            print("  under", WORDS, ":", low)
    print("wrote", OUT)


if __name__ == "__main__":
    sys.exit(main())
