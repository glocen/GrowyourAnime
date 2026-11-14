"""An effect in Config.Effects.Rows written as its rows file (docs/engineering-plan.md, "The rows contract").

    py tools/fx/rows_export.py <Effect> <out.json>

It runs the game's own encoder with Studio closed (tools/studio/RowsExport, through tools/checks/logic_offline.luau's
--json mode), so the file holds what the game holds, tuned values and all. For moving an effect first written in Luau to a
file, or for the asset maker to take one back as the base of its rows script. Needs Lune (rokit.toml) and the Bash
sandbox off.
"""
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    name, out = sys.argv[1], Path(sys.argv[2])
    run = subprocess.run(
        ["lune", "run", "tools/checks/logic_offline.luau", "--json", "ServerStorage.NL_Tools.RowsExport", name],
        cwd=ROOT, capture_output=True, text=True, encoding="utf-8",
    )
    if run.returncode != 0:
        print(run.stdout.strip() or run.stderr.strip())
        return 1
    # A Vector3 is single precision in the engine and in Lune: six places keep every value a reader would write.
    effect = json.loads(run.stdout, parse_float=lambda text: round(float(text), 6))
    # The file's own fields first, then its rows by name, so a diff between two takes reads.
    ordered = {key: effect[key] for key in ("Schema", "Effect", "Area", "Grey", "Action", "Free") if key in effect}
    ordered["Rows"] = {row: effect["Rows"][row] for row in sorted(effect["Rows"])}
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(ordered, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"{name}: {len(ordered['Rows'])} rows to {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
