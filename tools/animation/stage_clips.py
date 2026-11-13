"""Stage a character's delivered clips for Studio.

Copies build/handoff/<Character>/clips/<Character>_<Clip>.json to build/import/Anim_<Character><Clip>.txt, the form
Author.SaveBaked reads (handbook/tech/animation/Author.luau): its Name becomes <Character><Clip>. Rojo carries the
import folder into ServerStorage.NL_Import.

--r6 keeps only R6's six joints, for a stand-in on the plain R6 body (TR2's lead). Without it the character's own
joints stay, for its own rig.

Run:  py tools/animation/stage_clips.py Rook Idle Combo Haymaker Hit Down Up --r6
"""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
R6 = {"Torso", "Head", "Right Arm", "Left Arm", "Right Leg", "Left Leg"}


def stage(character: str, clip: str, r6_only: bool) -> Path:
    source = ROOT / "build" / "handoff" / character / "clips" / f"{character}_{clip}.json"
    data = json.loads(source.read_text(encoding="utf-8"))
    if data.get("Name") not in (clip, f"{character}{clip}"):  # the Reveals carry the character's name already
        raise SystemExit(f"{source.name}: its Name is {data.get('Name')!r}, not {clip!r}")
    data["Name"] = f"{character}{clip}"
    dropped = set()
    if r6_only:
        for frame in data["Frames"]:
            for part in list(frame["Poses"]):
                if part not in R6:
                    dropped.add(part)
                    del frame["Poses"][part]
    out = ROOT / "build" / "import" / f"Anim_{character}{clip}.txt"
    out.write_text(json.dumps(data, separators=(",", ":")), encoding="utf-8")
    markers = ", ".join(f"{m['Name']} {m['T']:.2f}" for m in data.get("Markers", []))
    print(f"{out.name}: {len(data['Frames'])} frames" + (f", markers {markers}" if markers else "")
          + (f", dropped {', '.join(sorted(dropped))}" if dropped else ""))
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("character")
    parser.add_argument("clips", nargs="+")
    parser.add_argument("--r6", action="store_true", help="keep only R6's six joints")
    args = parser.parse_args()
    for clip in args.clips:
        stage(args.character, clip, args.r6)


if __name__ == "__main__":
    main()
