"""AR72, the Guard's main mask: one more paper detail. Three targets beside today's mask, each an edit of the baked
mask's own mesh (build/scratch/modulo/shade/model, Shade_MaskGuard), rendered as shade_kinds.py renders the kinds (the
rig in the game's Idle, the game's glow, the Guard's Green) and laid into Faber's day capture through its own camera.

  blender -b --factory-startup --python tools/blender/guard_paper.py -- <abs out> [targets|write|handoff|build <targets>]

- targets (the default): <out>/guard_paper_targets.png, the record of the pick: the near Guard at twice the capture's
  size, its mask at four times, the same at the smallest phone's pixels at its own size and four times, and each over
  dark at 64 pixels high. It needs today's mask in the model: it stops once the build is written there.
- write: the build. The model's Guard mask (shade_clips.MODEL) gets its corner turned (shade_sheet.turn_corner, as
  shade_model.py now does after its bake), after proving that today's mask, exported again, is byte for byte the
  model's file. It writes the mesh's JSON, the recipe's Guard entries and the .blend in the model's folder.
- handoff: the written mask and its recipe entries copied into build/handoff/Shade/, past the content check.
- build: <out>/guard_paper_build.png, the built Guard beside target B: shade_kinds.py's normal and hard runs into
  <out> first, and <targets> is the targets' folder.

The family's rule holds (AR47, AR52, AR58): the masks are pressed or folded paper, cut through to the light, no ink.
- A, the brow fold: the band above the brow cut is creased back along one line, so it takes the sky as its own plane.
- B, the turned corner: one top corner is folded forward and down onto the face, its back to us, and the square's
  outline loses that corner.
- C, the crest: one more cut through to the light, a short upright slit above where the brows nearly meet (the
  mouth's own glowing faces, turned and moved, so it glows as the other cuts do).
"""
import math
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402
import shade_kinds as sk  # noqa: E402
import shade_sheet as ss  # noqa: E402

TITLES = {"Today": "Today", "A": "A, the brow fold", "B": "B, the turned corner", "C": "C, the crest"}


def crest(me, centre=(0.0, 5.44), tall=0.34, wide=0.09):
    """One more cut: the mouth's glowing slab (0.62 by 0.1, at z 4.33) copied, stood upright and set at `centre`."""
    bm = bmesh.new()
    bm.from_mesh(me)
    mouth = [f for f in bm.faces if (c := f.calc_center_median()).y > 0.85 and abs(c.z - 4.33) < 0.08 and abs(c.x) < 0.35]
    if len(mouth) != 6:
        raise SystemExit(f"crest: found {len(mouth)} of the mouth's 6 faces")
    new = bmesh.ops.duplicate(bm, geom=mouth)["geom"]
    verts = [g for g in new if isinstance(g, bmesh.types.BMVert)]
    m = (Matrix.Translation((centre[0], 0, centre[1])) @ Matrix.Diagonal((wide / 0.1, 1, tall / 0.62, 1))
         @ Matrix.Rotation(math.radians(90), 4, "Y") @ Matrix.Translation((0, 0, -4.33)))
    for v in verts:
        v.co = m @ v.co
    bm.normal_update()
    bm.to_mesh(me)
    bm.free()


EDITS = {
    "Today": lambda me: None,
    "A": lambda me: ss.fold(me, (-1.3, 5.28), (1.3, 5.28), -40),
    "B": lambda me: ss.fold(me, *ss.GUARD_CORNER, over=True),   # picked: ss.turn_corner, the build
    "C": lambda me: crest(me),
}


def render_run(out):
    import hard_cut as hc
    he, scene, rig, last, _, wear, wear_mask = sk.staged()
    wear("Normal", dict(he.SHADE, body="#" + hc.type_tints()["Green"]))
    wear_mask("Guard")
    obj = bpy.data.objects["Shade_MaskGuard"]
    shipped = obj.data
    if shipped.get("turned_corner"):
        raise SystemExit("targets: the model's Guard mask is the build now; the targets are the record (b00e407e)")
    layers = out / "layers"
    layers.mkdir(parents=True, exist_ok=True)
    for name, edit in EDITS.items():
        me = shipped.copy()
        edit(me)
        obj.data = me
        sk.shoot(he, scene, rig, last, layers, name, "Guard")
    obj.data = shipped


def layers_of(folder, look):
    return {s: np.load(folder / "layers" / f"kinds_{look}_Guard_{s}.npy").astype(np.float32) for s in sk.SPOTS}


def lay_sheet(out, columns, heading, blurb, name):
    """The columns, each (title, its layers by spot), laid into the capture and set out as rows: twice the capture's
    size, the mask at four times, the smallest phone at its own size and four times, 64 pixels over dark. Returns
    the crops for each column alone: the mask at four times, the phone at four times."""
    import brawler_mask_look as bm
    import hard_cut as hc
    import hard_ember as he
    still = rs.load(he.STILL)
    backdrop = still.copy()
    backdrop[..., :3] = he.to_linear(still[..., :3])
    gx, gz = he.ground_points()
    spots = {spot: (x, z) for spot, x, z, _, _ in he.PACK if spot in sk.SPOTS}
    places = [(x, z, 1.0) for x, z in spots.values()]
    titles = [title for title, _ in columns]
    frames = [he.lay(backdrop, [(he.project((x, 0, z))[2], got[s]) for s, (x, z) in spots.items()], places, "Normal", gx, gz)
              for _, got in columns]
    alone = [got["near"] for _, got in columns]

    def clamp(b):
        x0, y0, w, h = b
        return max(x0, 0), max(y0, 0), w, h

    x, z = spots["near"]
    near = clamp(bm.box([spots["near"]], 1.9, sk.TALL - 0.3, 20))
    xs, ys = zip(*(he.project((x + dx, y, z))[:2] for dx in (-1.4, 1.4) for y in (3.7, 6.1)))
    face = (int(min(xs)) - 6, int(min(ys)) - 6, int(max(xs) - min(xs)) + 12, int(max(ys) - min(ys)) + 12)
    one = clamp(bm.box([spots["near"]], 1.5, sk.TALL - 0.3, 6))
    s = sk.PHONE_H / backdrop.shape[0]
    phone = [rs.shrink(f, s) for f in frames]
    pnear = tuple(int(round(v * s)) for v in near)
    zoom, fz, k, gap, label = 2, 4, 4, 20, 54   # a row's caption, then each column's title, above its tiles
    col = max(near[2] * zoom, face[2] * fz, pnear[2] + gap + pnear[2] * k)
    width = gap + len(columns) * (col + gap)
    rows = (near[3] * zoom, face[3] * fz, pnear[3] * k)
    height = 110 + sum(label + r + gap for r in rows) + label + 64 + 40 + 60
    page = rs.canvas(width, height, rs.rgb("#101117"))
    ink, soft, pale = "#EDE6D6", "#B4AC9C", "#8C8577"
    text = [(gap, 20, 32, heading, ink)]
    text += hc.wrapped(gap, 62, 16, blurb, soft, width - 2 * gap)

    def titled(y):
        for i, title in enumerate(titles):
            text.append((gap + i * (col + gap), y + 28, 16, title, soft))

    y = 110
    for what, tall, show in (("twice the capture's size", rows[0], lambda f: bm.zoomed(he.crop(f, *near), zoom)),
                             ("its mask at four times the capture's size", rows[1], lambda f: bm.zoomed(he.crop(f, *face), fz))):
        text.append((gap, y, 18, what, ink))
        titled(y)
        for i, f in enumerate(frames):
            rs.paste(page, show(f), gap + i * (col + gap), y + label)
        y += label + tall + gap
    text.append((gap, y, 18, f"At the smallest phone ({sk.PHONE_H} pixels high): at its own size, then at {k} times", ink))
    titled(y)
    for i, f in enumerate(phone):
        x0 = gap + i * (col + gap)
        rs.paste(page, he.crop(f, *pnear), x0, y + label)
        rs.paste(page, bm.zoomed(he.crop(f, *pnear), k), x0 + pnear[2] + gap, y + label)
    y += label + rows[2] + gap
    text.append((gap, y, 18, "Over dark, 64 pixels high", ink))
    titled(y)
    for i, layer in enumerate(alone):
        rs.paste(page, hc.on_dark(layer, one, 64), gap + i * (col + gap), y + label)
    px = abs(he.project((x, 5.8, z))[1] - he.project((x, 4.0, z))[1])
    note = (f"At the smallest phone the near Guard's mask is about {px * s:.0f} pixels tall ({px:.0f} in the capture). "
            "Stand-ins for the engine: Blender's glow and bloom at the game's numbers.")
    text += hc.wrapped(gap, height - 50, 15, note, pale, width - 2 * gap)
    rs.paste(page, rs.text_layer(width, height, text), 0, 0)
    rs.save(page, out / name)
    print(f"wrote {out / name} ({width} by {height}); {note}")
    return [(bm.zoomed(he.crop(f, *face), fz), bm.zoomed(he.crop(ph, *pnear), k)) for f, ph in zip(frames, phone)]


def targets_run(out):
    render_run(out)
    crops = lay_sheet(out, [(TITLES[n], layers_of(out, n)) for n in EDITS],
                      "AR72: THE GUARD'S MASK, ONE MORE PAPER DETAIL, BESIDE TODAY'S",
                      "The baked Guard, Normal, in its Green, in Faber's day capture of the street through its own camera, "
                      "where the near Shade stands. Each target is an edit of the mask's own mesh: paper folded or cut "
                      "through to the light, no ink.", "guard_paper_targets.png")
    for n, (mask, phone) in zip(EDITS, crops):   # each alone, for the pick's pairs
        rs.save(mask, out / f"guard_paper_{n}_mask.png")
        rs.save(phone, out / f"guard_paper_{n}_phone.png")


def guard_entry(obj, folder):
    """The mask exported into `folder` as shade_model.py's export() does, and its recipe facts."""
    import json
    tris = bl.export_mesh_json(obj, folder / f"{obj.name}.json")
    box = [v.co for v in obj.data.vertices]
    size = [round(max(c[i] for c in box) - min(c[i] for c in box), 3) for i in (0, 2, 1)]
    centre = json.loads((folder / f"{obj.name}.json").read_text())["c"]
    return {"centre": centre, "size": size, "tris": tris, "top": round(max(c.z for c in box), 2)}


def recipe_guard(path, entry):
    """The recipe's Guard entries changed in place; every other byte kept (it's written as json.dumps(indent=1))."""
    import json
    was = path.read_bytes()
    recipe = json.loads(was)
    recipe["masks"]["Guard"].update(entry)
    recipe["tris"]["Guard"] = recipe["tris"]["body"] + entry["tris"]
    now = json.dumps(recipe, indent=1).encode()
    path.write_bytes(now.replace(b"\n", b"\r\n") if b"\r\n" in was else now)
    return recipe["masks"]["Guard"], recipe["tris"]["Guard"]


def write_run(out):
    import shade_clips as sc
    model = sc.MODEL
    bpy.ops.wm.open_mainfile(filepath=str(model / "shade_model.blend"))
    obj = bpy.data.objects["Shade_MaskGuard"]
    today = bl.export_mesh_json(obj, out / "Shade_MaskGuard.json")
    if (out / "Shade_MaskGuard.json").read_bytes() != (model / "Shade_MaskGuard.json").read_bytes():
        raise SystemExit("write: today's mask, exported again, isn't the model's file: stop")
    print(f"today: {today} tris, the same bytes as {model / 'Shade_MaskGuard.json'}")
    ss.turn_corner(obj.data)
    if any(p.normal.y < 0 for p in obj.data.polygons if p.center.y > 0.93):
        raise SystemExit("write: a face of the flap turns away from the front")
    entry = guard_entry(obj, model)
    print("written:", *recipe_guard(model / "Shade.recipe.json", entry))
    bl.save_blend(model / "shade_model.blend")


def handoff_run(out):
    import json
    import shutil
    import shade_clips as sc
    model, hand = sc.MODEL, Path(__file__).resolve().parents[2] / "build" / "handoff" / "Shade"
    entry = json.loads((model / "Shade.recipe.json").read_text())["masks"]["Guard"]
    shutil.copyfile(model / "Shade_MaskGuard.json", hand / "Shade_MaskGuard.json")
    print("handed off:", *recipe_guard(hand / "Shade.recipe.json", {k: entry[k] for k in ("centre", "size", "tris", "top")}))


def build_run(out, targets):
    crops = lay_sheet(out, [("B, the target", layers_of(targets, "B")), ("Built, Normal", layers_of(out, "Normal")),
                            ("Built, Hard", layers_of(out, "Hard"))],
                      "AR72: THE GUARD'S TURNED CORNER, BUILT, BESIDE ITS TARGET",
                      "Target B, then the built mask (the model's own, its corner turned, as exported for Studio) on "
                      "Normal in its Green and on Hard in the ember, in Faber's day capture through its own camera.",
                      "guard_paper_build.png")
    for n, (mask, phone) in zip(("target", "normal", "hard"), crops):
        rs.save(mask, out / f"guard_paper_build_{n}_mask.png")
        rs.save(phone, out / f"guard_paper_build_{n}_phone.png")


def main():
    out = bl.out_dir()
    rs.OUT = out
    args = sys.argv[sys.argv.index("--") + 2:]
    mode = args[0] if args else "targets"
    if mode == "targets":
        targets_run(out)
    elif mode == "write":
        write_run(out)
    elif mode == "handoff":
        handoff_run(out)
    elif mode == "build":
        build_run(out, Path(args[1]).resolve())
    else:
        raise SystemExit(f"guard_paper.py: no mode {mode}")


if __name__ == "__main__":
    main()
