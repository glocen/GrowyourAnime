"""Stage a world kit's meshes for Studio, from the handoff to the import channel (TR8; tools/studio/KitAssembly.luau).

Copies each piece's mesh, build/handoff/<Kit>/<the manifest's mesh>, to build/import/<Kit>_<Piece>.txt, which
KitAssembly.Publish publishes as <Kit>_<Piece>. Rojo carries the import folder into ServerStorage.NL_Import. The
manifest it reads is the one the game holds (src/shared/Config/Kits/<Kit>/Manifest.json, taken by
tools/world/kit_take.py), so the meshes staged are the pieces the game lays. Then, in Studio's Edit mode (MCP):
    local Kit = require(game.ServerStorage.NL_Tools.KitAssembly:Clone())
    Assembly.Start("kit", function() return Kit.Publish("<Kit>") end)   -- the ids into tools/studio/Kits/<Kit>.json
    local template = Kit.Build("<Kit>")
and Assembly.Serialize(template) into src/storage/<Kit>Kit.rbxm.

Run:  py tools/upload/stage_kit.py LanternRow
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    kit = sys.argv[1]
    manifest_path = ROOT / "src" / "shared" / "Config" / "Kits" / kit / "Manifest.json"
    if not manifest_path.is_file():
        print(f"{manifest_path.relative_to(ROOT).as_posix()}: not taken (py tools/world/kit_take.py {kit})")
        return 1
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    home = ROOT / "build" / "handoff" / kit
    out = ROOT / "build" / "import"
    staged = 0
    for name, piece in manifest["pieces"].items():
        mesh = home / piece["mesh"]
        if not mesh.is_file():
            print(f"{name}: its mesh {piece['mesh']} isn't in the handoff")
            return 1
        (out / f"{kit}_{name}.txt").write_bytes(mesh.read_bytes())
        staged += 1
    print(f"{kit}: {staged} meshes in build/import")
    return 0


if __name__ == "__main__":
    sys.exit(main())
