"""Stage a model's delivery for Studio: its recipe and its meshes, from the handoff to the import channel.

Copies build/handoff/<Name>/<Name>.recipe.json to build/import/<Name>.recipe.txt, which ModelAssembly.Build reads, and
each piece's mesh, build/handoff/<Name>/<Piece>.json, to build/import/<Piece>.txt, which ModelAssembly.PublishMesh
publishes. Rojo carries the import folder into ServerStorage.NL_Import. Then, in Studio's Edit mode (MCP):
    local Assembly = require(game.ServerStorage.NL_Tools.ModelAssembly:Clone())
    Assembly.PublishMesh("<Piece>", "<Piece>", "...")   -- each new piece once; its id into tools/studio/Models/<Name>.json
    local model = Assembly.Build("<Name>")
and Assembly.Serialize(model) into src/storage/<Name>.rbxm. Check the build with Studio closed first:
    lune run tools/checks/models_offline.luau --recipe <Name>   (before the install: that it builds)
    lune run tools/checks/models_offline.luau <Name>            (after: the template that ships is what it builds)

Run:  py tools/upload/stage_model.py Kirra
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    name = sys.argv[1]
    home = ROOT / "build" / "handoff" / name
    source = home / f"{name}.recipe.json"
    if not source.is_file():
        print(f"{source.relative_to(ROOT).as_posix()}: no recipe")
        return 1
    recipe = json.loads(source.read_text(encoding="utf-8"))
    out = ROOT / "build" / "import"
    (out / f"{name}.recipe.txt").write_text(json.dumps(recipe, separators=(",", ":")), encoding="utf-8")
    staged = 0
    for piece in recipe["pieces"]:
        mesh = home / piece["mesh"]
        if not mesh.is_file():
            print(f"{piece['name']}: its mesh {mesh.name} isn't in the handoff")
            return 1
        (out / f"{piece['name']}.txt").write_bytes(mesh.read_bytes())
        staged += 1
    print(f"{name}: the recipe and {staged} meshes in build/import")
    return 0


if __name__ == "__main__":
    sys.exit(main())
