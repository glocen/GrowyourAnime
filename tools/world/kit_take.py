"""Takes a world kit's two files from the handoff into the game, as they are (TR8; src/shared/World/Kit.luau).

    py tools/world/kit_take.py LanternRow

Copies build/handoff/<Kit>/manifest.json and plan.json byte for byte to src/shared/Config/Kits/<Kit>/Manifest.json and
Plan.json (Config.Kits.<Kit>), then runs the kit's logic cases with Studio closed (Cases/Kit.luau): every placement's piece
in the manifest, every stop on the street's marker, the lights under the ceiling. A pair that fails is taken back out,
and what was there before put back, so the game never holds a kit its checks refuse. Never edit a taken file: change the
kit script that wrote it, and take it again. Needs Lune and the Bash sandbox off.
"""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FILES = {"manifest.json": "Manifest.json", "plan.json": "Plan.json"}


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    kit = sys.argv[1]
    source = ROOT / "build" / "handoff" / kit
    home = ROOT / "src" / "shared" / "Config" / "Kits" / kit
    home.mkdir(parents=True, exist_ok=True)
    before: dict[Path, bytes | None] = {}
    for name, taken in FILES.items():
        origin = source / name
        if not origin.is_file():
            print(f"{origin.relative_to(ROOT).as_posix()}: missing")
            return 1
        target = home / taken
        before[target] = target.read_bytes() if target.is_file() else None
        target.write_bytes(origin.read_bytes())
    run = subprocess.run(
        ["lune", "run", "tools/checks/logic_offline.luau", "src/server/Services/Core/LogicTestService/Cases/Kit.luau"],
        cwd=ROOT, capture_output=True, text=True,
    )
    print(run.stdout.strip().splitlines()[-1] if run.stdout.strip() else run.stderr.strip()[-400:])
    if run.returncode != 0:
        for target, old in before.items():
            if old is None:
                target.unlink()
            else:
                target.write_bytes(old)
        print(f"{kit}: refused by its checks, and taken back out")
        print(run.stdout[-2000:])
        return 1
    print(f"{kit}: taken into src/shared/Config/Kits/{kit}/")
    return 0


if __name__ == "__main__":
    sys.exit(main())
