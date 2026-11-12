"""Writes src/shared/Config/UIKit.luau: the UI kit's images and palettes as the game reads them.

From Modulo's build/handoff/UI/kit/kit.json and build/handoff/UI/hud/hud_art.json (AR3, sections 2 and 3), with each
image's group upload id. The ids come from a JSON-lines file of tools/upload/upload_asset.py's answers
({"name": ..., "result": {"assetId": ...}}), a name's last line winning, and an image it doesn't name keeps the id the
Config already has, so a re-cut uploads only what changed and runs this again. What research tunes live (the critical's
stroke and digits) isn't written here: it lives in src/shared/Config/Hud.luau.

    py tools/ui/kit_config.py build/scratch/faber/tr3/ids.jsonl
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
KIT = ROOT / "build" / "handoff" / "UI" / "kit" / "kit.json"
HUD = ROOT / "build" / "handoff" / "UI" / "hud" / "hud_art.json"
OUT = ROOT / "src" / "shared" / "Config" / "UIKit.luau"

PALETTE_NAMES = {"Graphite Dark": "Graphite", "Pearl Light": "Pearl", "Dynamo": "Dynamo", "Void Violet": "Void"}
PALETTE_KEYS = [
    ("panel", "Panel"), ("alpha", "Alpha"), ("edge", "Edge"), ("border", "Border"), ("facet", "Facet"),
    ("glint", "Glint"), ("text", "Text"), ("soft", "Soft"), ("faint", "Faint"), ("channel", "Channel"),
    ("well", "Well"), ("button", "Button"), ("pressed", "Pressed"), ("ground", "Ground"), ("rim", "Rim"),
    ("seat", "Seat"), ("warm", "Warm"), ("accent", "Accent"), ("core", "Core"), ("selected", "Selected"),
    ("selectedText", "SelectedText"),
]


def colour(hex_: str) -> str:
    return f'Color3.fromHex("{hex_}")'


def value(v) -> str:
    if isinstance(v, str) and v.startswith("#"):
        return colour(v)
    if isinstance(v, list) and all(isinstance(x, str) for x in v):
        return "{ " + ", ".join(colour(x) for x in v) + " }"
    if isinstance(v, list):
        return "{ " + ", ".join(num(x) for x in v) + " }"
    return num(v)


def num(x) -> str:
    return f"{x:g}" if isinstance(x, float) else str(x)


def old_ids() -> dict:
    if not OUT.exists():
        return {}
    return dict(re.findall(r'^\t\t(\w+) = \{ Id = "rbxassetid://(\d+)"', OUT.read_text(encoding="utf-8"), re.M))


def new_ids(path: Path) -> dict:
    ids = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            row = json.loads(line)
            if row.get("result", {}).get("ok"):
                ids[row["name"]] = row["result"]["assetId"]
    return ids


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit("usage: kit_config.py <ids.jsonl>")
    kit = json.loads(KIT.read_text(encoding="utf-8"))
    hud = json.loads(HUD.read_text(encoding="utf-8"))
    ids = old_ids() | new_ids(Path(sys.argv[1]))
    images = kit["images"] | hud["images"]
    missing = [name for name in images if name not in ids]
    if missing:
        sys.exit(f"no upload id for {len(missing)}: {', '.join(missing[:8])}")

    out = [
        "--!strict",
        "-- UIKit (shared config): the UI kit's images and palettes, as the game reads them. Written by",
        "-- tools/ui/kit_config.py from Modulo's build/handoff/UI/kit/kit.json and build/handoff/UI/hud/hud_art.json (AR3,",
        "-- sections 2 and 3), with each image's group upload id: run it again after a re-cut, never edit by hand.",
        "-- A slice is white where a palette colours it. Cut is left, top, right, bottom in points; Pad is how far an image",
        "-- reaches past its piece's box on every side. The kit draws them (src/client/UI/Kit).",
        "",
        "export type Image = { Id: string, Pixels: Vector2, Points: Vector2, Cut: { number }?, Pad: number }",
        "export type Palette = {",
        "\tPanel: { Color3 }, -- a panel's body, top to bottom",
        "\tAlpha: number,",
        "\tEdge: Color3,",
        "\tBorder: number?, -- a bordered palette: its panels wear the bold edge",
        "\tFacet: Color3,",
        "\tGlint: Color3,",
        "\tText: Color3,",
        "\tSoft: Color3,",
        "\tFaint: Color3,",
        "\tChannel: Color3,",
        "\tWell: Color3,",
        "\tButton: { Color3 },",
        "\tPressed: { Color3 },",
        "\tGround: Color3,",
        "\tRim: number?, -- a bar's light keeps this dark rim all round",
        "\tSeat: number?, -- a frame sits in its dark seat",
        "\tWarm: { number }?, -- a warm light's edges on a pale panel",
        "\tAccent: Color3,",
        "\tCore: number,",
        "\tSelected: { Color3 }?, -- a selected button fills with these",
        "\tSelectedText: Color3?,",
        "}",
        "",
        "return {",
        f"\tPixelsPerPoint = {kit['pixelsPerPoint']},",
        f"\tSliceScale = {num(kit['sliceScale'])},",
        f"\tLight = {colour(kit['light'])}, -- health's light, and a plain hit's number",
        f"\tCharge = {colour(kit['charge'])}, -- electricity",
        f"\tGood = {colour(kit['good'])}, -- the server said yes",
        f"\tBad = {colour(kit['bad'])}, -- the server said no",
        "\tNumbers = {",
    ]
    for name, hex_ in kit["numbers"].items():
        out.append(f"\t\t{name.capitalize()} = {colour(hex_)},")
    sweep = hud["images"]["CritSweep"]
    out += [
        "\t},",
        # The stroke's tint and opacity and the digits' look are tuned live, so they live in Config.Hud, seeded by hand.
        f"\tSweep = {{ Shear = {num(sweep['shear'])} }}, -- the critical's stroke leans with its digits (Config.Hud.Critical)",
        "\tElements = {",
    ]
    for name, hex_ in kit["elements"].items():
        out.append(f"\t\t{name} = {colour(hex_)},")
    out += ["\t} :: { [string]: Color3 },", "\tPalettes = {"]
    for name, row in kit["palettes"].items():
        out.append(f"\t\t{PALETTE_NAMES[name]} = {{ -- {name}: {kit['screens'][name]}")
        for key, luau in PALETTE_KEYS:
            if key in row:
                out.append(f"\t\t\t{luau} = {value(row[key])},")
        out.append("\t\t},")
    out += ["\t} :: { [string]: Palette },", "\tImages = {"]
    for name, im in images.items():
        px, pt = im["pixels"], im["points"]
        cut = ", Cut = { " + ", ".join(num(float(x)) for x in im["cut"]) + " }" if im.get("cut") else ""
        out.append(
            f'\t\t{name} = {{ Id = "rbxassetid://{ids[name]}", Pixels = Vector2.new({px[0]}, {px[1]}), '
            f"Points = Vector2.new({num(float(pt[0]))}, {num(float(pt[1]))}){cut}, Pad = {num(float(im.get('pad', 0.0)))} }},"
        )
    out += ["\t} :: { [string]: Image },", "}", ""]
    OUT.write_text("\n".join(out), encoding="utf-8", newline="\n")
    print(f"wrote {OUT.relative_to(ROOT)}: {len(images)} images, {len(kit['palettes'])} palettes")


if __name__ == "__main__":
    main()
