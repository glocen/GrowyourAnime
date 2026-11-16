"""Writes src/shared/Definitions/ItemDesigns.luau from AR6's gear_icons.json: each kind's designs at each rarity, in the
json's order, each with its name and its picture's name in UIKit.Images (docs/design.md, Regalia, "An item's design").

The json keys a weapon by its kind and every other piece by its slot; a slot of a pair ("Ring I") stands for its kind
("Ring"), as Definitions/Gear.luau's Pairs. Every kind in Definitions/Items.luau must have its designs at every rarity.

    py tools/ui/gear_designs.py
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GEAR = ROOT / "build" / "handoff" / "UI" / "gear" / "gear_icons.json"
ITEMS = ROOT / "src" / "shared" / "Definitions" / "Items.luau"
OUT = ROOT / "src" / "shared" / "Definitions" / "ItemDesigns.luau"
RARITIES = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
PAIRS = {"Ring I": "Ring", "Ring II": "Ring", "Earring I": "Earring", "Earring II": "Earring"}


def lua(text: str) -> str:
    return json.dumps(text, ensure_ascii=False)


def main() -> None:
    gear = json.loads(GEAR.read_text(encoding="utf-8"))
    kinds_needed = set(re.findall(r'Kind = "([^"]+)"', ITEMS.read_text(encoding="utf-8")))
    designs: dict[str, dict[str, list[tuple[str, str]]]] = {}
    for key, rows in gear["kinds"].items():
        kind = PAIRS.get(key, key)
        if kind in designs:
            sys.exit(f"{key}: its kind {kind} is listed twice")
        by = designs.setdefault(kind, {})
        for row in rows:
            by.setdefault(row["rarity"], []).append((row["name"], Path(row["image"]).stem))
    problems = [f"{kind}: no designs" for kind in sorted(kinds_needed - designs.keys())]
    problems += [f"{kind}: not a kind in Items.luau" for kind in sorted(designs.keys() - kinds_needed)]
    for kind, by in designs.items():
        problems += [f"{kind} {rarity}: none" for rarity in RARITIES if not by.get(rarity)]
    if problems:
        sys.exit("\n".join(problems))
    lines = [
        "--!strict",
        "-- ItemDesigns (shared, pure; written by tools/ui/gear_designs.py from AR6's gear_icons.json, never by hand): each",
        "-- kind's designs at each rarity, in order. A design is a look and a name only, never a stat (docs/design.md, Regalia,",
        "-- \"An item's design\"). An owned item keeps its design's index (Data.Profile, OwnedItem.Design), so a design added at",
        "-- the end of a list never moves one. `Image` names the picture in Config.UIKit.Images.",
        "",
        "export type Design = { Name: string, Image: string }",
        "",
        "local ByKind: { [string]: { [string]: { Design } } } = {",
    ]
    for kind in sorted(designs):
        lines.append(f"\t[{lua(kind)}] = {{")
        for rarity in RARITIES:
            row = ", ".join(f"{{ Name = {lua(name)}, Image = {lua(image)} }}" for name, image in designs[kind][rarity])
            lines.append(f"\t\t{rarity} = {{ {row} }},")
        lines.append("\t},")
    lines += ["}", "", "return { ByKind = ByKind }", ""]
    OUT.write_text("\n".join(lines), encoding="utf-8")
    count = sum(len(rows) for by in designs.values() for rows in by.values())
    print(f"{OUT.relative_to(ROOT)}: {len(designs)} kinds, {count} designs")


if __name__ == "__main__":
    main()
