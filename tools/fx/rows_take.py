"""Takes an effect's rows file from the handoff into the game, as it is (docs/engineering-plan.md, "The rows contract").

    py tools/fx/rows_take.py build/handoff/<Name>/fx/<effect>.rows.json [more files...]

Each file is copied byte for byte to src/shared/Config/EffectRows/<Effect>.json, its "Effect" naming it, then the game's
own decoder and the rows' logic cases check it with Studio closed (Config.EffectRows; Cases/Track.luau). A file that
fails is taken back out, and what was there before put back, so the game never holds a file its checks refuse. Never
edit a taken file: change the rows script that wrote it, and take it again. Needs Lune and the Bash sandbox off.
"""
import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HOME = ROOT / "src" / "shared" / "Config" / "EffectRows"
SCHEMA = "rows/1"


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    taken: list[tuple[Path, bytes | None]] = []
    for arg in sys.argv[1:]:
        source = Path(arg)
        raw = source.read_bytes()
        try:
            effect = json.loads(raw.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as error:
            print(f"{source}: not JSON ({error})")
            return 1
        if effect.get("Schema") != SCHEMA or not isinstance(effect.get("Effect"), str):
            print(f"{source}: not a rows file: it needs \"Schema\": \"{SCHEMA}\" and its \"Effect\"")
            return 1
        target = HOME / f"{effect['Effect']}.json"
        taken.append((target, target.read_bytes() if target.exists() else None))
        target.write_bytes(raw)
        print(f"took {source} as {target.relative_to(ROOT).as_posix()}")
    check = subprocess.run(
        ["lune", "run", "tools/checks/logic_offline.luau", "src/server/Services/Core/LogicTestService/Cases/Track.luau"],
        cwd=ROOT, capture_output=True, text=True, encoding="utf-8",
    )
    print(check.stdout.strip())
    if check.returncode != 0:
        for target, before in taken:
            if before is None:
                target.unlink()
            else:
                target.write_bytes(before)
        print("refused: the files are taken back out, and what was there put back")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
