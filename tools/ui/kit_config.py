"""Writes src/shared/Config/UIKit.luau: the UI kit's images and palettes as the game reads them.

From Modulo's build/handoff/UI/kit/kit.json and build/handoff/UI/hud/hud_art.json (AR3, sections 2 and 3), the lead
card's lead_card.json, TR5's boss.json (the keeper's bar and the elite's card) and AR12's hud_colour.json (the HUD's
colour: each system's row, and its images once they're uploaded), with each image's group upload id. The ids come from a JSON-lines file of tools/upload/upload_asset.py's answers
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
LEAD = ROOT / "build" / "handoff" / "UI" / "hud" / "lead_card" / "lead_card.json"  # tools/blender/lead_card_art.py
BOSS = ROOT / "build" / "handoff" / "UI" / "hud" / "boss" / "boss.json"  # tools/blender/boss_hud_art.py
COLOUR = ROOT / "build" / "handoff" / "UI" / "hud" / "colour" / "hud_colour.json"  # tools/blender/hud_colour_sheet.py
MARKS = ROOT / "build" / "handoff" / "UI" / "voidkin" / "marks" / "voidkin_marks.json"  # TR17's marks, Modulo's
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
    for line in path.read_text(encoding="utf-8-sig").splitlines():  # -sig: PowerShell's Add-Content writes a BOM
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
    lead = json.loads(LEAD.read_text(encoding="utf-8"))
    boss = json.loads(BOSS.read_text(encoding="utf-8"))
    tint = json.loads(COLOUR.read_text(encoding="utf-8"))
    marks = json.loads(MARKS.read_text(encoding="utf-8"))
    ids = old_ids() | new_ids(Path(sys.argv[1]))
    images = kit["images"] | hud["images"] | lead["images"] | boss["images"]
    # The HUD's colour images and TR17's marks join as they're uploaded: a piece not built yet (the dock) keeps its out.
    waiting = [name for name in tint["images"] | marks["images"] if name not in ids]
    images |= {name: im for name, im in (tint["images"] | marks["images"]).items() if name in ids}
    missing = [name for name in images if name not in ids]
    if missing:
        sys.exit(f"no upload id for {len(missing)}: {', '.join(missing[:8])}")

    out = [
        "--!strict",
        "-- UIKit (shared config): the UI kit's images and palettes, as the game reads them. Written by",
        "-- tools/ui/kit_config.py from Modulo's build/handoff/UI/kit/kit.json and build/handoff/UI/hud/hud_art.json (AR3,",
        "-- sections 2 and 3), the lead card's build/handoff/UI/hud/lead_card/lead_card.json (tools/blender/lead_card_art.py)",
        "-- and TR5's build/handoff/UI/hud/boss/boss.json (tools/blender/boss_hud_art.py),",
        "-- with each image's group upload id: run it again after a re-cut, never edit by hand.",
        "-- A slice is white where a palette colours it. Cut is left, top, right, bottom in points; Pad is how far an image",
        "-- reaches past its piece's box on every side; At, a lead card image's box's top left in the card's points. The kit",
        "-- draws them (src/client/UI/Kit, src/client/UI/LeadCard.luau). Systems: AR12's colour, a row a system",
        "-- (build/handoff/UI/hud/colour/hud_colour.json): a piece of the HUD wears its system's body, edge, block and mark.",
        "",
        "export type Image = { Id: string, Pixels: Vector2, Points: Vector2, Cut: { number }?, Pad: number, At: Vector2? }",
        "export type System = {",
        "\tColour: Color3,",
        "\tPale: Color3,",
        "\tDeep: Color3,",
        "\tIcon: string, -- its icon in light",
        "\tMark: string, -- its mark in ink, on its block",
        "\tBlock: { Color3 }, -- the block's colours, top to foot",
        "\tMain: { Color3 }, -- a screen's one main action, filled",
        "\tPanel: { Color3 },",
        "\tAlpha: number,",
        "\tButton: { Color3 },",
        "\tPressed: { Color3 },",
        "\tEdge: Color3,",
        "\tGlint: Color3,",
        "\tChannel: Color3,",
        "\tText: Color3,",
        "\tSoft: Color3,",
        "}",
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
    out += ["\t} :: { [string]: Palette },", "\tSystems = {"]
    for name, row in tint["systems"].items():
        p = row["palette"]
        out.append(
            f"\t\t{name} = {{ Colour = {colour(row['colour'])}, Pale = {colour(row['pale'])}, Deep = {colour(row['deep'])}, "
            f'Icon = "{row["icon"]}", Mark = "{row["mark"]}", Block = {value(row["block"])}, Main = {value(row["main"])}, '
            f"Panel = {value(p['panel'])}, Alpha = {num(p['alpha'])}, Button = {value(p['button'])}, Pressed = {value(p['pressed'])}, "
            f"Edge = {colour(p['edge'])}, Glint = {colour(p['glint'])}, Channel = {colour(p['channel'])}, "
            f"Text = {colour(p['text'])}, Soft = {colour(p['soft'])} }},"
        )
    out += ["\t} :: { [string]: System },", "\tImages = {"]
    for name, im in images.items():
        px, pt = im["pixels"], im["points"]
        cut = ", Cut = { " + ", ".join(num(float(x)) for x in im["cut"]) + " }" if im.get("cut") else ""
        at = f", At = Vector2.new({num(float(im['at'][0]))}, {num(float(im['at'][1]))})" if im.get("at") else ""
        out.append(
            f'\t\t{name} = {{ Id = "rbxassetid://{ids[name]}", Pixels = Vector2.new({px[0]}, {px[1]}), '
            f"Points = Vector2.new({num(float(pt[0]))}, {num(float(pt[1]))}){cut}, Pad = {num(float(im.get('pad', 0.0)))}{at} }},"
        )
    g = lead["geometry"]
    t, p = g["target"], g["plate"]
    rounded = lambda x: num(round(float(x), 3))  # noqa: E731
    light = lambda row: "{ " + ", ".join(rounded(x) for x in row) + " }"  # noqa: E731
    out += [
        "\t} :: { [string]: Image },",
        "\t-- The lead card's shape, in its own points: images are laid at their At (tools/blender/lead_card_art.py).",
        "\tLeadCard = {",
        f"\t\tSize = Vector2.new({rounded(g['card'][0])}, {rounded(g['card'][1])}),",
        f"\t\tFrame = {light(g['frame'])}, -- the portrait's frame: x, y, w, h",
        f"\t\tHousing = {light(g['housing'])}, -- x0, y0, x1, y1",
        f"\t\tSlant = {rounded(g['slant'])}, -- across per down, every slanted edge",
        f"\t\tMid = {rounded(g['mid'])}, -- where the two blades meet",
        f"\t\tHealth = {light(g['lights']['Health'])}, -- a light's top edge: its left end, its y, its full right end; its height",
        f"\t\tXp = {light(g['lights']['Xp'])},",
        f"\t\tFillFrom = {rounded(g['fillFrom'])}, -- a bar's empty point along its top edge: the frame's right side",
        f"\t\tGlow = {rounded(g['glow'])}, -- a light's glow ahead of its front",
        f"\t\tTab = {light(g['tab'])}, -- its top, its foot, its width as drawn, its top edge's left end",
        f"\t\tBadge = {light(g['badge'])}, -- centre and size",
        "\t},",
        "\t-- Take F's plate beside the portrait (AR12, the director's pick), in the lead card's points.",
        "\tLeadPlate = {",
        f"\t\tPlate = {light(p['plate'])}, -- its top line's left end, its top, its top line's right end, its foot",
        f"\t\tName = {rounded(p['name'])}, -- the name's row reaches down to here",
        f"\t\tHealth = {light(p['health'])}, -- a light's top edge: its root (empty), its y, its full right end; its height",
        f"\t\tXp = {light(p['xp'])},",
        f"\t\tStud = {light(p['stud'])}, -- the type's stud: its centre and radius",
        f"\t\tFrameFoot = {rounded(p['frameFoot'])}, -- the lowest point of any rarity's frame: the level's mark clears it",
        "\t},",
        "\t-- The target's card, built like the lead's, in its own points; the lead's images it shares are moved by Offset.",
        "\tTargetCard = {",
        f"\t\tSize = Vector2.new({rounded(t['size'][0])}, {rounded(t['size'][1])}),",
        f"\t\tOffset = Vector2.new({rounded(t['offset'][0])}, {rounded(t['offset'][1])}), -- the lead's points to the target's",
        f"\t\tHousing = {light(t['housing'])}, -- its foot's left, its top, its top's right end, its foot",
        f"\t\tHealth = {light(t['health'])}, -- the light's top edge: its left end, its y, its full right end; its height",
        f"\t\tFillFrom = {rounded(t['fillFrom'])}, -- the light's empty point along its top edge",
        f"\t\tStud = Vector2.new({rounded(t['stud'][0])}, {rounded(t['stud'][1])}), -- the type's stud, on the blade's left end",
        "\t},",
    ]
    b, e = boss["geometry"]["bar"], boss["geometry"]["elite"]
    pair = lambda row: f"Vector2.new({rounded(row[0])}, {rounded(row[1])})"  # noqa: E731
    out += [
        "\t-- The keeper's bar's frames as drawn (TR5): the bar's height they were drawn for, a cap's and a phase mark's box,",
        "\t-- the rim's reach past the channel, the title's rules (their line, a tip's box, the gap, the taper) and its crest.",
        "\tBossBar = {",
        f"\t\tHeight = {rounded(b['height'])},",
        f"\t\tCap = {pair(b['cap'])},",
        f"\t\tMark = {pair(b['mark'])},",
        f"\t\tRim = {rounded(b['rim'])},",
        f"\t\tRule = {{ Width = {rounded(b['rule']['width'])}, Tip = {pair(b['rule']['tip'])}, Gap = {rounded(b['rule']['gap'])}, Taper = {rounded(b['rule']['taper'])} }},",
        f"\t\tCrest = {pair(b['crest'])},",
        "\t},",
        "\t-- The elite's card, in the target card's own points (TR5): its size, its blade, its light row, the stud, the Elite",
        "\t-- tab's corners and the word's centre, where the name's tab must end, and how far its crest notch rises above its top.",
        "\tEliteCard = {",
        f"\t\tSize = {pair(e['size'])},",
        f"\t\tHousing = {light(e['housing'])},",
        f"\t\tHealth = {light(e['health'])},",
        f"\t\tFillFrom = {rounded(e['fillFrom'])},",
        f"\t\tStud = {pair(e['stud'])},",
        "\t\tTab = { " + ", ".join(pair(c) for c in e["tab"]) + " },",
        f"\t\tWord = {pair(e['word'])},",
        f"\t\tNameTabEnd = {rounded(e['nameTabEnd'])},",
        f"\t\tArtTop = {rounded(e['artTop'])},",
        "\t},",
        "}",
        "",
    ]
    OUT.write_text("\n".join(out), encoding="utf-8", newline="\n")
    print(f"wrote {OUT.relative_to(ROOT)}: {len(images)} images, {len(kit['palettes'])} palettes, {len(tint['systems'])} systems")
    if waiting:
        print(f"not uploaded yet, left out: {', '.join(waiting)}")


if __name__ == "__main__":
    main()
