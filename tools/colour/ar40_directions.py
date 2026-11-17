"""AR40 (docs/asset-requests.md, AR40): three colour directions for the world by day, as values.

The director, 2026-11-17, 22:15: "i think the game is way to much too purple/Black and somber", then: "there can be
blueish purple and dark like the inventory hud is good but the other area js make it wayy to much". So the screens stay
as they are, and the world is the piece: the plot, the machines, the Shop and the Strip. Each direction keeps a share
of blue-violet (the void's light, the trim, the far shards) beside its own stone and light.

A direction moves only what's there: the kit's swatches by name (tools/blender/base_kit.py, SWATCHES: the machines' body
is "abyss", their frame "girder", their fitting "bone", their trim "dark"), the wall's print as a ramp, the Strip's
stones as one colour, and the day's light (Config.Lighting). No model and no texture file: ar40_see.py renders them, and
the pick is painted in afterwards.

    py tools/colour/ar40_directions.py     writes build/handoff/Colour/ar40/directions.json, directions.md, chips.png

chips.png is flat colour beside flat colour, never a render.
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
VIOLET = (225.0, 310.0, 0.18)   # a hue between these with at least this much colour in it counts as blue-violet
DARK = 30.0                     # a surface under this L* counts as black
HUD = {"Panel": ("#20242C", "#13151A"), "Edge": "#434A57", "Text": "#F3EFE6", "Soft": "#A6ADBA",
       "Button": ("#323845", "#22262F"), "Accent": "#FFF4D6"}   # the HUD's glass as it is and stays (Config.UIKit, Graphite)

TODAY = {
    "Name": "Today",
    "Idea": "void stone in dark violet on navy frames, violet shards on the horizon, lilac stones, a lilac fill",
    "Swatches": {
        "abyss": ("#4B3A7E", "#171030"), "girder": ("#4C5878", "#242C42"), "bone": ("#E9E2D2", "#9C95A6"),
        "steel": ("#8290B0", "#46506E"), "dark": ("#1E1426", "#0C0A12"), "rubber": ("#1F2233", "#0E101A"),
        "far": ("#9284C8", "#5E5298"), "tower": ("#7C76AE", "#46427A"), "outcrop": ("#8474BC", "#4A3E86"),
    },
    "Panel": ("#20263E", "#93A0C8"),          # the wall's print, its darkest and its lightest
    "Stones": "#B9ACD0",                      # the Strip's stones by day, read by eye off one capture (ar20-crossing-day)
    "Lighting": {
        "Phases.Day.Sun": "#FFE2B8", "Phases.Day.Glow": 0.45, "Clear.Phases.Day.Ambient": "#A3A1B4",
        "Clear.Phases.Day.Brightness": 2.61, "Clear.Phases.Day.Exposure": 0.16,
    },
}

DIRECTIONS = [
    {
        "Key": "A", "Name": "A, porcelain and indigo",
        "Idea": "the machines in warm white stone on indigo frames with gold fittings, under a warm white sun. The "
                "most blue-violet kept: every frame is the void's colour, at a mid value, never black.",
        "Swatches": {
            "abyss": ("#F6F1E6", "#B9B6C0"), "girder": ("#6468B8", "#30306C"), "bone": ("#F2C45A", "#9A6A24"),
            "steel": ("#B6C4DE", "#6E7EA0"), "dark": ("#4A4494", "#242054"), "rubber": ("#2A2C48", "#16172A"),
            "far": ("#B6B4EC", "#8884CE"), "tower": ("#A6A4E0", "#7472BA"), "outcrop": ("#AEA8E8", "#7C74C6"),
        },
        "Panel": ("#44488A", "#CED4F0"),
        "Stones": "#D2CCC2",
        "Lighting": {
            "Phases.Day.Sun": "#FFF0D2", "Phases.Day.Glow": 0.6, "Clear.Phases.Day.Ambient": "#B6B4AC",
            "Clear.Phases.Day.Brightness": 2.5, "Clear.Phases.Day.Exposure": 0.05,
        },
    },
    {
        "Key": "B", "Name": "B, sky steel",
        "Idea": "the machines in light blue steel with white frames, blue-violet only in their trim, their cores and "
                "the far shards, under a clear blue fill and a warm white sun.",
        "Swatches": {
            "abyss": ("#C6D6EE", "#7E94BC"), "girder": ("#F0F3F8", "#AEB8CC"), "bone": ("#FFE9A8", "#C89A3C"),
            "steel": ("#9FB6DC", "#5C76A6"), "dark": ("#4E50A4", "#262860"), "rubber": ("#262C4C", "#14182E"),
            "far": ("#B0B4F0", "#8084D4"), "tower": ("#9EA2E4", "#6C70C0"), "outcrop": ("#A8A6EC", "#7874CC"),
        },
        "Panel": ("#6E86B4", "#F2F5FA"),
        "Stones": "#CBD0DA",
        "Lighting": {
            "Phases.Day.Sun": "#FFF6E0", "Phases.Day.Glow": 0.55, "Clear.Phases.Day.Ambient": "#AEBCCE",
            "Clear.Phases.Day.Brightness": 2.6, "Clear.Phases.Day.Exposure": 0.08,
        },
    },
    {
        "Key": "C", "Name": "C, sandstone and teal",
        "Idea": "the machines in warm pale stone on teal bronze, with violet trim and a violet core against the sand, "
                "under a gold day. The warmest, and the violet the most set off.",
        "Swatches": {
            "abyss": ("#EEDDBC", "#B2946C"), "girder": ("#46A39C", "#1F5E64"), "bone": ("#FFF4DC", "#C2AE8C"),
            "steel": ("#A9C2C8", "#62808A"), "dark": ("#5A4A9C", "#2A2258"), "rubber": ("#2C2A44", "#181628"),
            "far": ("#B8A8E0", "#8878BC"), "tower": ("#A898D4", "#7868AE"), "outcrop": ("#B0A0DC", "#8070B8"),
        },
        "Panel": ("#8A6E4E", "#F0E2C4"),
        "Stones": "#DCCFB8",
        "Lighting": {
            "Phases.Day.Sun": "#FFDDA6", "Phases.Day.Glow": 0.6, "Clear.Phases.Day.Ambient": "#BAAE9C",
            "Clear.Phases.Day.Brightness": 2.7, "Clear.Phases.Day.Exposure": 0.08,
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


def violet(text):
    h, _, s = colorsys.rgb_to_hls(*rgb(text))
    return bool(VIOLET[0] <= h * 360 <= VIOLET[1] and s >= VIOLET[2] and 12 < light(text) < 92)


def gain(want, today=None):
    """What the stones' light takes, channel by channel, to move today's colour to the wanted one."""
    return linear(rgb(want)) / linear(rgb(today or TODAY["Stones"]))


SURFACES = (("the body's head", lambda d: d["Swatches"]["abyss"][0]), ("the body's foot", lambda d: d["Swatches"]["abyss"][1]),
            ("the frame", lambda d: d["Swatches"]["girder"][0]), ("the trim", lambda d: d["Swatches"]["dark"][0]),
            ("the far shards", lambda d: d["Swatches"]["far"][0]), ("the Tower", lambda d: d["Swatches"]["tower"][0]),
            ("the wall", lambda d: d["Panel"][1]), ("the wall's foot", lambda d: d["Panel"][0]),
            ("the stones", lambda d: d["Stones"]), ("the day's fill", lambda d: d["Lighting"]["Clear.Phases.Day.Ambient"]))


def measures(d):
    s = d["Swatches"]
    bodies = [s[n][i] for n in ("abyss", "girder", "bone", "steel") for i in (0, 1)]
    return {
        "BodyLight": [round(light(s["abyss"][0])), round(light(s["abyss"][1]))],
        "FrameLight": [round(light(s["girder"][0])), round(light(s["girder"][1]))],
        "Range": round(max(light(c) for c in bodies) - min(light(c) for c in bodies)),
        "Violet": [name for name, pick in SURFACES if violet(pick(d))],
        "Black": [name for name, pick in SURFACES if light(pick(d)) < DARK],
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
    """One direction as a strip, 940 by 200: a machine on the yard under the day sky with the HUD's card over it as it
    is today, then its swatches."""
    page = np.ones((200, 940, 3))
    s = d["Swatches"]
    fill(page, 0, 0, 520, 120, "#4FA3E0", "#C4DCF2")
    for x, tall, name in ((30, 70, "far"), (110, 96, "tower"), (430, 60, "far"), (470, 84, "outcrop")):
        fill(page, x, 120 - tall, 26, tall, *s[name])
    fill(page, 0, 104, 520, 16, d["Panel"][1], d["Panel"][0])
    fill(page, 0, 120, 520, 80, "#C9CED9", "#B4BAC8")
    fill(page, 380, 150, 140, 50, d["Stones"])
    # a machine: its body, its frame, its fitting, its trim, its core of void light, an outline of ink
    fill(page, 196, 46, 128, 124, "#0C0A16")
    fill(page, 200, 50, 120, 116, *s["abyss"])
    for x in (200, 304):
        fill(page, x, 50, 16, 116, *s["girder"])
    fill(page, 216, 50, 88, 12, *s["bone"])
    fill(page, 216, 150, 88, 16, *s["dark"])
    fill(page, 244, 80, 32, 56, "#E9DBFF", "#A97CFF")
    fill(page, 340, 90, 14, 80, *s["steel"])
    fill(page, 14, 14, 150, 44, HUD["Edge"])
    fill(page, 16, 16, 146, 40, *HUD["Panel"])
    fill(page, 24, 24, 70, 6, HUD["Text"])
    fill(page, 24, 36, 46, 5, HUD["Soft"])
    fill(page, 110, 24, 44, 24, *HUD["Button"])
    fill(page, 110, 46, 44, 2, HUD["Accent"])
    # the swatches: body, frame, fitting, steel, trim, the wall, the stones, the sun, the fill
    chips = [s["abyss"], s["girder"], s["bone"], s["steel"], s["dark"], (d["Panel"][1], d["Panel"][0]), (d["Stones"],) * 2,
             (d["Lighting"]["Phases.Day.Sun"],) * 2, (d["Lighting"]["Clear.Phases.Day.Ambient"],) * 2]
    for i, (top, foot) in enumerate(chips):
        fill(page, 546 + i * 43, 16, 39, 168, top, foot)
    return page


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    every = [TODAY] + DIRECTIONS
    for d in every:
        d["Measures"] = measures(d)
        d["StonesGain"] = [round(float(v), 3) for v in gain(d["Stones"])]
    (OUT / "directions.json").write_text(json.dumps({"Today": TODAY, "Directions": DIRECTIONS}, indent=1),
                                         encoding="utf-8", newline="\n")
    gap = np.ones((8, 940, 3)) * 0.5
    png(OUT / "chips.png", np.concatenate([part for d in every for part in (row(d), gap)][:-1]))
    lines = ["# AR40: three colour directions for the world by day, as values", "",
             "From `tools/colour/ar40_directions.py`; the values are in `directions.json`, beside this. `chips.png` is "
             "flat colour, top to bottom Today, A, B, C: a machine on the yard with the HUD's card as it is, then the "
             "swatches (body, frame, fitting, steel, trim, the wall, the stones, the sun, the fill). It's no render. The "
             "renders are `tools/colour/ar40_see.py`'s.", ""]
    for d in every:
        lines += [f"- **{d['Name']}:** {d['Idea']}"]
    lines += ["", "| | body L* | frame L* | bodies' range | blue-violet | black |", "|---|---|---|---|---|---|"]
    for d in every:
        m = d["Measures"]
        lines.append(f"| {d['Name']} | {m['BodyLight'][0]} to {m['BodyLight'][1]} | {m['FrameLight'][0]} to "
                     f"{m['FrameLight'][1]} | {m['Range']} | {len(m['Violet'])} of {len(SURFACES)}: "
                     f"{', '.join(m['Violet']) or 'none'} | {len(m['Black'])} of {len(SURFACES)}: "
                     f"{', '.join(m['Black']) or 'none'} |")
    lines += ["", f"Counted over ten of the world's surfaces. Blue-violet: a hue from {VIOLET[0]:g} to {VIOLET[1]:g} "
              f"degrees with colour in it. Black: under L* {DARK:g}. The void's own light is violet in every row and "
              "isn't counted. Today's stones are read by eye off one capture, an estimate.", ""]
    (OUT / "directions.md").write_text("\n".join(lines), encoding="utf-8", newline="\n")
    for d in every:
        print(d["Name"], d["Measures"])
    print("wrote", OUT)


if __name__ == "__main__":
    sys.exit(main())
