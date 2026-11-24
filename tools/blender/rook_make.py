"""Rook in the make (docs/asset-requests.md, AR59): the picked take, A the school tough, as the files the builder
installs. The design is rook_make_takes.py's `take_a`; the make and the handoff are the kit's (anime_make.py). Nothing
is built on his body and nothing rides a joint of its own: the piston and the tape of the first Rook are gone.

    blender.exe -b --factory-startup --python tools/blender/rook_make.py -- <out_dir> model
    blender.exe -b --factory-startup --python tools/blender/rook_make.py -- <out_dir> sheet
    blender.exe -b --factory-startup --python tools/blender/rook_make.py -- <out_dir> clips [clip ...]

`model` builds him and writes <out_dir>/handoff: Rook_Color.png, Rook_Roughness.png, Rook_Emissive.png (his right
fist's wraps, which Haymaker heats), a mesh a piece (Rook_<Piece>.json, blcommon.export_mesh_json) and
Rook.recipe.json, as tools/studio/ModelRecipe.luau reads them. It then draws him from those files, the way the takes
were drawn, into <out_dir>/shots and <out_dir>/layers. `sheet` lays rook_make_sheet.png: those pictures and the maps.
The fight's foe is rook_make_takes.py's `shade` layer, drawn into the same <out_dir>. `clips` puts him on r6anim's rig
and plays the delivered clips on him (build/handoff/Rook/clips, made for the first Rook's body): one sheet a clip into
<out_dir>/clips, its marked frames and the frames between from the player's assumed camera and from his front. A pose
for the piston or the tape finds no joint and is passed over, as the game passes it over.
"""
import json
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
import anime_make as am  # noqa: E402
import blcommon as bl  # noqa: E402
import rook_make_takes as rmt  # noqa: E402
import rook_sheet as rs  # noqa: E402

NAME, TAKE = "Rook", "A"
# the points the game may hang a thing on, in the kit's frame (studs, he faces +Y, his right is +X)
POINTS = [("Knuckles", "Right Arm", (1.5, 0.0, 2.0), "the right fist's end: Haymaker's striking face"),
          ("RamCentre", "Right Arm", (1.5, 0.0, 2.2), "the right fist's middle (the first Rook's name for it, kept)")]


def model_run(out):
    rmt.takes_run(out, [TAKE], finish=lambda key, made: am.handoff(NAME, made, out / "handoff", POINTS))


def sheet_run(out):
    rmt.proof_run(out, TAKE, title="ROOK IN THE MAKE: THE MODEL FOR THE INSTALL")
    proof = rs.load(out / "rook_pick.png")
    recipe = json.loads((out / "handoff" / f"{NAME}.recipe.json").read_text())
    gap, W, side = 24, proof.shape[1], 560
    ink, soft, paper = "#EDE6D6", "#B4AC9C", "#101117"
    low = rs.canvas(W, 60 + side + 30, rs.rgb(paper))
    text = [(gap, 14, 18, "What goes up: the one picture every piece wears, and the glow's shape (the right fist's wraps, cold until "
                          "Haymaker heats them). Each at 0.55 of its size.", ink)]
    x = gap
    for kind in ("Color", "Emissive"):
        if kind in recipe["maps"]:
            rs.paste(low, rs.shrink(rs.load(out / "handoff" / recipe["maps"][kind]), side / am.ATLAS), x, 50)
            text.append((x, 50 + side + 8, 14, recipe["maps"][kind], soft))
            x += side + gap
    facts = [f"{recipe['tris']} triangles in {len(recipe['pieces'])} pieces", f"{recipe['texels_per_stud']} texels a stud on the body",
             "pieces: " + ", ".join(f"{p['name'][len(NAME) + 1:]} {p['tris']}" for p in recipe["pieces"]),
             "points: " + ", ".join(p["name"] for p in recipe["points"]),
             "no joint of its own: the piston and the tape are gone"]
    text += [(x, 60 + i * 24, 15, line, soft) for i, line in enumerate(facts)]
    rs.paste(low, rs.text_layer(W, low.shape[0], text), 0, 0)
    whole = rs.canvas(W, proof.shape[0] + low.shape[0], rs.rgb(paper))
    whole[:proof.shape[0]], whole[proof.shape[0]:] = proof, low
    rs.save(whole, out / "rook_make_sheet.png")


def clips_run(out, names):
    import hard_ember as he
    import r6anim as r6
    import r6rig
    import watt_takes as wt
    folder = out / "clips"
    folder.mkdir(parents=True, exist_ok=True)
    scene = bl.reset_scene()
    r6.stage(scene, fps=60, size=(960, 540))
    scene.display.shading.color_type = "TEXTURE"
    grey = (0.3, 0.3, 0.3)
    rig = r6.build_rig(NAME, {part: grey for part in (*r6rig.PARTS, "Face")})
    r6.place_root(rig, 0, (0, r6rig.ROOT_HEIGHT, 0), (0, 0, -1))
    bpy.context.view_layer.update()
    am.PICTURES.clear()
    am.GLOWS.clear()
    made = rmt.take_a(wt.rig(scene), out / "tex" / "clips")
    bpy.context.view_layer.update()
    for key, obj in made.items():
        holder = rig.parts[am.PIECE[key][1]]
        obj.parent = holder
        obj.matrix_parent_inverse = holder.matrix_world.inverted()
        for slot in obj.material_slots:   # Workbench's own shine would wash a face turned to its light
            slot.material.roughness, slot.material.specular_intensity = 1.0, 0.0
    for o in [rig.parts[part] for part in r6rig.PARTS] + [bpy.data.objects[f"{NAME}.Face"]]:
        o.hide_render = o.hide_viewport = True   # his pieces are R6's own blocks: the rig's would fight them for the same faces
    cams = {view: r6.body_camera(scene, rig, 0, az, el, distance=13.0, name=view) for view, (az, el) in (("game", (152.0, 18.0)), ("front", (38.0, 8.0)))}
    start = 0
    for path in sorted((rmt.REPO / "build" / "handoff" / NAME / "clips").glob(f"{NAME}_*.json")):
        clip = path.stem[len(NAME) + 1:]
        if names and clip not in names:
            continue
        data = json.loads(path.read_text())
        last = he.key(rig, path, start)
        marks = {round(m["T"] * data["Fps"]): m["Name"] for m in data.get("Markers", [])}
        beats = {**{round(last * i / 7): "" for i in range(8)}, **marks}
        shots = [(cams[view], start + f, f"{clip} {f} {beats[f]}".strip() if view == "game" else f"{f}")
                 for view in ("game", "front") for f in sorted(beats)]
        scene.render.resolution_x, scene.render.resolution_y = 300, 340
        print(f"wrote {r6.render_shots(scene, shots, folder / f'poses_{clip}.png', columns=len(beats))}")
        start += last + 10


if __name__ == "__main__":
    OUT = rs.OUT = bl.out_dir()
    rest = sys.argv[sys.argv.index("--") + 2:]
    if rest[:1] == ["clips"]:
        clips_run(OUT, rest[1:])
    else:
        {"model": model_run, "sheet": sheet_run}[rest[0] if rest else "model"](OUT)
