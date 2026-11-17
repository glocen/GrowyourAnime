"""Kirra's basic attack, its look as rows (AR26, Kirra fifth; /ga-action steps 1 and 3; AR8, "The method").

py tools/blender/kirra_combo_fx.py measure
py tools/blender/kirra_combo_fx.py sweeps

Plain Python, no Blender. Its numbers come from the delivered clip (build/handoff/Kirra/clips/Kirra_Combo.json, the
Transforms the game plays) on the recipe's blade joints, and from the action's own row (read only:
src/shared/Definitions/Actions.luau, KirraCombo's Beats).
- measure: each blade's grip and point in her root's frame through the clip, with the points' speed.
- sweeps: each cut's path round its beat, where it crosses the Shade's front, and what the game's camera sees of it.
"""
import json
import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kirra_scarf_step_fx as k  # noqa: E402  (the CFrame sums, the Track reader, the rows file check)
import watt_combo_fx as w  # noqa: E402  (the game's camera, the Shade's boxes, what it covers: AR26's first attack)
import combo_targets as ct  # noqa: E402  (every target the cuts land on, and rule 4's guards against them)

ROOT = Path(__file__).resolve().parents[2]
RECIPE = ROOT / "build" / "handoff" / "Kirra" / "Kirra.recipe.json"
CLIP = ROOT / "build" / "handoff" / "Kirra" / "clips" / "Kirra_Combo.json"
ACTIONS = ROOT / "src" / "shared" / "Definitions" / "Actions.luau"  # read only
ACTION = "KirraCombo"
BEATS = {"Dash": 0, "Hit1": 12, "Hit2": 26, "Hit3": 56, "Sheathe": 64}  # the clip's markers, and the action's Beats
HITS = ("Hit1", "Hit2", "Hit3")
ROOT_HEIGHT = 3.0  # R6: the HumanoidRootPart's centre over the floor
BLADES = {"R": ("Kirra_BladeR", "TipR"), "L": ("Kirra_BladeL", "TipL")}
SPACING = 3.5  # studs, her root to the target's once the dash has brought her in (Moves.Dash.Gap, Rook's spacing)


def read_action():
    text = ACTIONS.read_text(encoding="utf-8")
    start = text.index(f'Id = "{ACTION}"')
    block = text[start:text.index("Id = ", start + 10)]
    beats = {n: round(float(v) * 60) for n, v in re.findall(r"(\w+) = ([\d.]+)", re.search(r"Beats = \{([^}]*)\}", block).group(1))}
    if beats != BEATS:
        raise SystemExit(f"the action's beats moved: {beats}")
    gap = float(re.search(r"Dash = \{[^}]*Gap = ([\d.]+)", block).group(1))
    if gap != SPACING:
        raise SystemExit(f"the dash's gap moved: {gap}")
    return {"beats": beats, "gap": gap}


def measure(frames=None):
    """Each blade in her root's frame, frame by frame (x right, y from the floor, z back): its grip's middle (the
    joint's pivot) and its point."""
    recipe = json.loads(RECIPE.read_text(encoding="utf-8"))
    clip = json.loads(CLIP.read_text(encoding="utf-8"))
    marks = {m["Name"]: round(m["T"] * clip["Fps"]) for m in clip["Markers"]}
    if marks != BEATS:
        raise SystemExit(f"the clip's markers moved: {marks}")
    points = {p["name"]: p["at"] for p in recipe["points"]}
    pieces = {p["name"]: p for p in recipe["pieces"]}
    torso_rest = [0.0, ROOT_HEIGHT, 0.0]
    out = {}
    for f in frames if frames is not None else range(len(clip["Frames"])):
        poses = clip["Frames"][f]["Poses"]
        torso = k.compose(k.compose(k.R6_ROOT, k.cframe(poses["Torso"])), k.inverse(k.R6_ROOT))
        out[f] = {}
        for side, (piece, tip) in BLADES.items():
            p = pieces[piece]
            if p["on"] != "Torso":
                raise SystemExit(f"{piece} isn't on the Torso")
            joint = k.compose(k.compose(torso, k.moved(k.sub(p["pivot"], torso_rest))), k.cframe(poses[piece]))
            grip = k.add(joint[1], [0, ROOT_HEIGHT, 0])
            point = k.add(k.compose(joint, k.moved(k.sub(points[tip], p["pivot"])))[1], [0, ROOT_HEIGHT, 0])
            out[f][side] = {"Grip": grip, "Point": point}
    return out


def main():
    if sys.argv[1:2] == ["measure"]:
        print(read_action())
        n = measure()
        last = {}
        for f, blades in n.items():
            mark = next((b for b, v in BEATS.items() if v == f), "")
            cells = []
            for side, p in blades.items():
                speed = k.length(k.sub(p["Point"], last[side])) * 60 if side in last else 0.0
                last[side] = p["Point"]
                cells.append(f"{side} grip ({p['Grip'][0]:+.2f},{p['Grip'][1]:+.2f},{p['Grip'][2]:+.2f}) "
                             f"point ({p['Point'][0]:+.2f},{p['Point'][1]:+.2f},{p['Point'][2]:+.2f}) {speed:5.1f}")
            print(f"{f:3d} {mark:7s} " + " | ".join(cells))
        print("(her root's frame, y from the floor: x right, z back; the Shade stands at -z, its chest's face "
              f"{SPACING - ct.FRONT:.2f} ahead)")
        return
    print(__doc__)


if __name__ == "__main__":
    main()
