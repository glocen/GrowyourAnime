"""Writes src/shared/Config/RevealArt.luau: Modulo's reveal as the game reads it (AR3, section 5; TR4).

From build/handoff/Reveal/parts/reveal.json, with each image's group upload id (a JSON-lines file of
tools/upload/upload_asset.py's answers, {"name": ..., "result": {"assetId": ...}}) and each shard mesh's id (a JSON
object, piece name to id, from ModelAssembly.PublishMesh). Only the numbers are written: the rules reveal.json spells
out in words are Rules.Reveal's code, and what's tuned by playing is Config.Reveal.

    py tools/ui/reveal_config.py build/scratch/faber/reveal/ids.jsonl build/scratch/faber/reveal/mesh_ids.json
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SPEC = ROOT / "build" / "handoff" / "Reveal" / "parts" / "reveal.json"
OUT = ROOT / "src" / "shared" / "Config" / "RevealArt.luau"


def num(x) -> str:
    x = float(x)
    return str(int(x)) if x.is_integer() else f"{round(x, 5):g}"


def colour(code: str) -> str:
    return f'Color3.fromHex("{code}")'


def v2(p) -> str:
    return f"Vector2.new({num(p[0])}, {num(p[1])})"


def v3(p) -> str:
    return f"Vector3.new({num(p[0])}, {num(p[1])}, {num(p[2])})"


def nums(xs) -> str:
    return "{ " + ", ".join(num(x) for x in xs) + " }"


def image_ids(path: Path) -> dict:
    ids = {}
    for line in path.read_text(encoding="utf-8-sig").splitlines():
        if line.strip():
            row = json.loads(line)
            if row.get("result", {}).get("ok"):
                ids[row["name"]] = row["result"]["assetId"]
    return ids


def cell(c: dict) -> str:
    out = f"Rect = {nums(c['rect'])}, Points = {v2(c['points'])}, Anchor = {v2(c['anchor'])}"
    if "scale" in c:
        out += f", Scale = {num(c['scale'])}"
    if "ramp" in c:
        out += f", Ramp = {nums(c['ramp'])}"
    if "curve" in c:
        out += ", Curve = { " + ", ".join(nums(p) for p in c["curve"]) + " }"
    return "{ " + out + " }"


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit("usage: reveal_config.py <images ids.jsonl> <mesh_ids.json>")
    spec = json.loads(SPEC.read_text(encoding="utf-8"))
    ids = image_ids(Path(sys.argv[1]))
    meshes = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
    missing = [n for n in spec["images"] if n not in ids] + [n for n in spec["shard"]["meshes"] if n not in meshes]
    if missing:
        sys.exit(f"no upload id for {len(missing)}: {', '.join(missing[:8])}")

    out = [
        "--!strict",
        "-- RevealArt (shared config): Modulo's reveal as the game reads it (AR3, section 5; TR4). Written by",
        "-- tools/ui/reveal_config.py from build/handoff/Reveal/parts/reveal.json, with each image's and the shard's meshes'",
        "-- group ids: run it again after a re-cut, never edit by hand. Points are on the 844 by 390 screen, x right, y down;",
        "-- seconds are from the tap. The rules that read these are Rules.Reveal; what's tuned by playing is Config.Reveal.",
        "",
        "export type Step = { When: number, Colour: Color3, Level: number, Wide: number }",
        "export type Rarity = {",
        "\tTimes: { Split: number, Colours: number, Name: number, Card: number },",
        "\tGrade: string,",
        "\tCracks: { number },",
        "\tSteps: { Step },",
        "\tBreath: { number }?,",
        "\tOffset: number, -- where his Reveal clip is at the split",
        "\tReach: number, -- how far the pieces fly, in the shard's units",
        "\tLight: { Colour: Color3, Level: number, Rays: number, RaysColour: Color3 },",
        "\tFlash: { Radius: number?, Strength: number, Seconds: number }, -- no radius: the whole screen white",
        "\tNameScale: number,",
        "\tShake: number,",
        "\tHold: number,",
        "\tRule: Color3,",
        "}",
        "export type Cell = { Rect: { number }, Points: Vector2, Anchor: Vector2, Scale: number?, Ramp: { number }?, Curve: { { number } }? }",
        "export type Image = { Id: string, Pixels: Vector2, Points: Vector2?, Anchor: Vector2?, Slice: { number }? }",
        "export type Piece = {",
        "\tId: string,",
        "\tCentre: Vector3,",
        "\tOrder: number?, -- a piece that moves: its place in the spin",
        "\tSideA: number?, -- which side of seam A it's on",
        "\tAway: Vector3?,",
        "\tReach: number?,",
        "\tSlides: { Seam: number, Way: number, Along: Vector3 }?, -- the seam it slides along, A to D as 1 to 4",
        "\tHost: string?, -- a bud: the piece it grows on",
        "}",
        "",
        "return {",
        f"\tScreen = {v2(spec['screen']['points'])},",
        "\tImages = {",
    ]
    for name, im in spec["images"].items():
        row = f'Id = "rbxassetid://{ids[name]}", Pixels = {v2(im["pixels"])}'
        if isinstance(im.get("points"), list):
            row += f", Points = {v2(im['points'])}"
        if "anchor" in im:
            row += f", Anchor = {v2(im['anchor'])}"
        if "slice" in im:
            row += f", Slice = {nums(im['slice'])}"
        out.append(f"\t\t{name} = {{ {row} }},")
    out.append("\t} :: { [string]: Image },")

    rings = sorted(spec["images"]["reveal_rings"]["cells"].values(), key=lambda c: c["ratio"])
    out.append("\t-- reveal_rings' cells: a ring of radius R and width w takes the cell whose ratio is nearest w / R, drawn R / Radius across.")
    out.append("\tRings = {")
    for c in rings:
        out.append(f"\t\t{{ Rect = {nums(c['rect'])}, Ratio = {num(c['ratio'])}, Radius = {num(c['radius'])} }},")
    out.append("\t},")

    leak = spec["images"]["reveal_leak"]
    out.append("\t-- reveal_leak's cells, by kind and set (wide0 .. hot8, each maybe with a Boost); a missing one held nothing.")
    out.append("\tLeak = {")
    out.append("\t\tSets = {")
    for s in leak["sets"]:
        out.append(f'\t\t\t{{ Seams = "{s["seams"]}", Width = {num(s["width"])} }},')
    out.append("\t\t},")
    out.append("\t\tCells = {")
    for name, c in leak["cells"].items():
        out.append(f"\t\t\t{name} = {cell(c)},")
    out.append("\t\t} :: { [string]: Cell },")
    out.append("\t},")

    shard = spec["shard"]
    seam = {"A": 1, "B": 2, "C": 3, "D": 4}
    out.append("\tShard = {")
    out.append(f"\t\tColour = {colour(spec['light']['shard'])}, -- its own light, before the climb")
    out.append("\t\tPieces = {")
    for name, p in shard["meshes"].items():
        row = f'Id = "rbxassetid://{meshes[name]}", Centre = {v3(p["centre"])}'
        if "order" in p:
            row += f", Order = {p['order']}, SideA = {p['side_A']}, Away = {v3(p['away'])}, Reach = {num(p['reach'])}"
        if "slides" in p:
            sl = p["slides"]
            row += f", Slides = {{ Seam = {seam[sl['seam']]}, Way = {sl['way']}, Along = {v3(sl['along'])} }}"
        if "host" in p:
            row += f', Host = "{p["host"]}"'
        out.append(f"\t\t\t{name} = {{ {row} }},")
    out.append("\t\t} :: { [string]: Piece },")
    out.append("\t\tGrades = {")
    for grade, buds in shard["grades"].items():
        out.append(f"\t\t\t{grade} = {{ " + ", ".join(f'"{b}"' for b in buds) + " },")
    out.append("\t\t} :: { [string]: { string } },")
    out.append(f"\t\tANormal = {v3(shard['pose']['A_normal'])}, -- seam A's normal: the pieces part along it")
    cam = shard["camera"]
    out.append(f"\t\tCamera = {{ Target = {v3(cam['target'])}, Direction = {v3(cam['direction'])}, Fov = {num(cam['fov'])}, Distance = {num(cam['distance'])} }},")
    root = shard["root"]
    out.append(f"\t\tRoot = {{ Origin = {v2(root['origin'])}, PerX = {v2(root['per_x'])}, PerZ = {v2(root['per_z'])} }}, -- the root on the screen, and a unit of X and of Z")
    out.append("\t},")

    out.append("\tRarities = {")
    for name, r in spec["rarities"].items():
        t, li, fl = r["times"], r["light"], r["flash"]
        steps = ", ".join(
            f"{{ When = {num(s['when'])}, Colour = {colour(s['colour'])}, Level = {num(s['level'])}, Wide = {num(s['wide'])} }}"
            for s in r["steps"])
        breath = nums(r["breath"]) if r.get("breath") else "nil"
        radius = num(fl["radius"]) if fl.get("radius") is not None else "nil"
        out += [
            f"\t\t{name} = {{",
            f"\t\t\tTimes = {{ Split = {num(t['split'])}, Colours = {num(t['colours'])}, Name = {num(t['name'])}, Card = {num(t['card'])} }},",
            f'\t\t\tGrade = "{r["grade"]}",',
            f"\t\t\tCracks = {nums(r['cracks'])},",
            f"\t\t\tSteps = {{ {steps} }},",
            f"\t\t\tBreath = {breath},",
            f"\t\t\tOffset = {num(r['offset'])},",
            f"\t\t\tReach = {num(r['reach'])},",
            f"\t\t\tLight = {{ Colour = {colour(li['colour'])}, Level = {num(li['level'])}, Rays = {li['rays']}, RaysColour = {colour(li['rays_colour'])} }},",
            f"\t\t\tFlash = {{ Radius = {radius}, Strength = {num(fl['strength'])}, Seconds = {num(fl['seconds'])} }},",
            f"\t\t\tNameScale = {num(r['name_scale'])},",
            f"\t\t\tShake = {num(r['shake'])},",
            f"\t\t\tHold = {num(r['hold'])},",
            f"\t\t\tRule = {colour(r['rule'])},",
            "\t\t},",
        ]
    out.append("\t} :: { [string]: Rarity },")

    fig = spec["figure"]
    flood = fig["flood"]
    out += [
        "\tFigure = {",
        f"\t\tTile = {v2(fig['tile'])}, -- centred on (cx, 185): his soles on the sill",
        f"\t\tDirection = {v3(fig['camera']['direction_in_his_frame'])}, -- the camera's, in his own frame",
        f"\t\tFov = {num(fig['camera']['fov'])},",
        f"\t\tDistance = {num(fig['camera']['distance'])},",
        f"\t\tDark = {colour(fig['dark'])},",
        f"\t\tFlood = {{ Origin = {v2(flood['origin_in_tile'])}, Reach = {num(flood['reach'])}, Soft = {num(flood['soft'])}, Seconds = {num(flood['seconds'])} }},",
        f"\t\tKnock = {num(fig['knock'])},",
        f"\t\tNameMarker = {num(fig['name_marker'])},",
        "\t},",
    ]
    nm = spec["name"]
    out.append(f"\tName = {{ Colour = {colour(nm['colour'])}, Size = 58, Left = {num(nm['left'])}, Baseline = {num(nm['baseline'])}, Widest = {num(nm['widest'])} }},")
    pl = spec["places"]
    out.append(f"\tPlaces = {{ Cy = {num(pl['cy'])}, WindowMiddle = {num(pl['window_middle'][1])}, WindowTop = {num(pl['window_top'])}, Sill = {num(pl['sill'])}, FootBand = {num(pl['foot_band'])}, RaysPoint = {num(pl['rays_point'])} }},")
    out += ["}", ""]
    OUT.write_text("\n".join(out), encoding="utf-8", newline="\n")
    print(f"wrote {OUT.relative_to(ROOT)}: {len(spec['images'])} images, {len(leak['cells'])} leak cells, {len(shard['meshes'])} pieces, {len(spec['rarities'])} rarities")


if __name__ == "__main__":
    main()
