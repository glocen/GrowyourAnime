"""AR52, the Guard and the Dasher beside the Brawler: the masks' design, then their look in the street.

  blender -b --factory-startup --python tools/blender/shade_kinds.py -- <abs out> design|support|normal|hard|look

- `design` writes <out>/shade_kinds_design.png from shade_sheet.py's blockout (Workbench, no GPU turn): each mask from
  the front and as the player's camera sees it, its outline alone, and the three at 64 pixels over dusk, day and paper.
  For the content check before the bake. `support` writes the same with AR58's Support as a fourth, into
  <out>/shade_support_design.png; its look in the street is shade_support.py's.
- `normal` and `hard` render the baked model (shade_model.py's, in shade_clips.MODEL) on its rig in the game's Idle, at
  the game's glow, each kind in its stretch's colour (Config.Shades.Tint: the Brawler Red, the Guard Green, the Dasher
  Orange), where hard_ember.py's near and side Shades stand, into <out>/layers. `hard` wears AR46's cut as
  hard_cut.py composes it for each colour (into <out>/maps, never the handoff: the game's route is the TintMask map),
  from the cracks hard_cut.py `shade` baked (build/scratch/modulo/ember/layers/bake_shade.npy: run it first).
- `look` lays them into Faber's day capture through its own camera, as brawler_mask_look.py does, and writes
  <out>/shade_kinds_look.png: each kind near, Normal over Hard, at twice the capture's size; the same at the smallest
  phone's pixels, at its own size and four times; and each over dark at full size and at 64 pixels high.
"""
import shutil
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402
import shade_sheet as ss  # noqa: E402

KINDS = (("Brawler", "Strength", "Red", "round, grinning"), ("Guard", "Technique", "Green", "square, the brow cut"),
         ("Dasher", "Endurance", "Orange", "long, pointed"))


SUPPORT = ("Support", "Endurance", "Orange", "a half-mask, a fringe")


def design(out, KINDS=KINDS, title="AR52: the Guard and the Dasher, beside the Brawler", file="shade_kinds_design.png"):
    ss.OUT = out
    shots = {kind: ss.take(kind, colour, "hung", {"front": ss.BUST, "player": ss.PLAYER}) for kind, colour, _, _ in KINDS}
    W, H = 30 + 490 * len(KINDS), 900
    page = rs.canvas(W, H, ss.PAPER)
    ink, soft = "#1E1B22", "#6A655E"
    text = [(30, 22, 30, title, ink),
            (30, 62, 17, "Paper masks, cut through to the light, no ink. The blockout's picture: the glow is drawn on, not rendered.", soft)]
    y = 100
    for i, (kind, _, name, words) in enumerate(KINDS):
        x = 30 + i * 490
        rs.fill(page, x, y, 320, 320, ss.NIGHT)
        rs.paste(page, ss.bust(shots[kind]["front"]), x, y)
        rs.paste(page, rs.shrink(ss.solid(ss.bust(shots[kind]["front"])), 0.45), x + 326, y + 170)
        text += [(x + 328, y + 6, 22, kind, ink), (x + 328, y + 36, 14, words, soft), (x + 328, y + 58, 14, f"here {name}", soft)]
    y = 450
    text.append((30, y - 24, 16, "as the player's camera sees it", soft))
    wide = (W - 60) // 2
    rs.fill(page, 30, y, 2 * wide, 300, ss.NIGHT)
    rs.fill(page, 30 + wide, y, wide, 300, ss.DAY)
    for half in range(2):
        for i, (kind, _, _, _) in enumerate(KINDS):
            rs.stand(page, rs.shrink(shots[kind]["player"], 0.36), 40 + half * wide + i * (wide - 15) // len(KINDS), y + 296, 230)
    y = 790
    text.append((30, y - 24, 16, "at 64 pixels: dusk, day, the outline", soft))
    band = 8 + 104 * len(KINDS)
    for r, (ground, dark) in enumerate(((ss.NIGHT, False), (ss.DAY, False), (ss.PAPER, True))):
        rs.fill(page, 30 + r * (band + 10), y, band, 80, ground)
        for c, (kind, _, _, _) in enumerate(KINDS):
            shot = rs.shrink(shots[kind]["player"], 64 / 500)
            rs.stand(page, ss.solid(shot) if dark else shot, 40 + r * (band + 10) + c * 104, y + 76, 100)
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out / file)
    print("; ".join(f"{kind} {shots[kind]['tris']} triangles with its body" for kind, *_ in KINDS))


TYPES = {"Brawler": "Red", "Guard": "Green", "Dasher": "Orange"}
SPOTS = ("near", "side")
PHONE_H = 450   # the smallest phone's capture, in the device's pixels (brawler_mask_look.py)
TALL = 7.2      # studs: the Dasher's point stands at 6.7


def staged():
    """The Shade as hard_ember.py stages it: its rig in the game's Idle, its glowing surfaces, its masks."""
    import hard_ember as he
    import shade_clips as sc
    scene, rig, _, wear_mask, _ = sc.build("Strength")
    he.setup(scene)
    last = he.key(rig, he.SHADE_CLIPS / "Shade_Idle.json")
    materials = {m.name: m for o in scene.objects for s in o.material_slots if (m := s.material)}
    wear = he.glows([materials["Shade_Baked"], materials["Shade_Mask"]], {"Shade_Baked"})
    return he, scene, rig, last, materials, wear, wear_mask


def shoot(he, scene, rig, last, layers, look, kind):
    for name, x, z, toward, frame in he.PACK:
        if name in SPOTS:
            he.stand(rig, x, z, toward, 1.0)
            scene.frame_set(frame % last)
            he.border(scene, x, z, 1.0, TALL)
            he.render(scene, layers / f"kinds_{look}_{kind}_{name}.npy")


def normal_run(out):
    import hard_cut as hc
    he, scene, rig, last, _, wear, wear_mask = staged()
    tints = hc.type_tints()
    layers = out / "layers"
    layers.mkdir(parents=True, exist_ok=True)
    for kind, colour in TYPES.items():
        wear("Normal", dict(he.SHADE, body="#" + tints[colour]))
        wear_mask(kind)
        shoot(he, scene, rig, last, layers, "Normal", kind)


def hard_run(out):
    import bpy
    import hard_cut as hc
    he, scene, rig, last, materials, wear, wear_mask = staged()
    layers, maps = out / "layers", out / "maps"
    layers.mkdir(parents=True, exist_ok=True)
    maps.mkdir(parents=True, exist_ok=True)
    shipped = hc.FOES["shade"]
    for name in ("Shade_Color.png", "Shade_Emissive.png"):
        shutil.copyfile(shipped["folder"] / name, maps / name)
    hc.FOES["shade"] = dict(shipped, folder=maps)  # compose() reads the delivered pair there and writes beside it
    baked = np.load(he.REPO / "build" / "scratch" / "modulo" / "ember" / "layers" / "bake_shade.npy").astype(np.float32)
    hc.compose("shade", baked, sorted(set(TYPES.values())))
    glow = bpy.data.images.load(str(maps / "hard" / "Shade_Emissive_Hard.png"))
    glow.colorspace_settings.name = "Non-Color"
    nodes = {"colour": [], "glow": []}
    for name in ("Shade_Baked", "Shade_Mask"):
        for node in materials[name].node_tree.nodes:
            if node.bl_idname == "ShaderNodeTexImage" and node.image is not None:
                file = Path(bpy.path.abspath(node.image.filepath)).name
                if file in ("Shade_Color.png", "Shade_Emissive.png"):
                    nodes["colour" if file == "Shade_Color.png" else "glow"].append(node)
    if len(nodes["colour"]) < 2 or len(nodes["glow"]) < 2:
        raise SystemExit(f"hard: {len(nodes['colour'])} colour and {len(nodes['glow'])} glow nodes found")
    for node in nodes["glow"]:
        node.image = glow
    for kind, colour in TYPES.items():
        painted = bpy.data.images.load(str(maps / "hard" / f"Shade_Color_Hard{colour}.png"))
        for node in nodes["colour"]:
            node.image = painted
        wear("Normal", dict(he.SHADE, body="#FFFFFF"))  # the maps carry the ember, as hard_cut.py's check wears them
        wear_mask(kind)
        shoot(he, scene, rig, last, layers, "Hard", kind)


def look_run(out):
    import brawler_mask_look as bm
    import hard_cut as hc
    import hard_ember as he
    layers = out / "layers"
    still = rs.load(he.STILL)
    backdrop = still.copy()
    backdrop[..., :3] = he.to_linear(still[..., :3])
    gx, gz = he.ground_points()
    spots = {name: (x, z) for name, x, z, _, _ in he.PACK if name in SPOTS}
    places = [(x, z, 1.0) for x, z in spots.values()]
    frames, alone = {}, {}
    for look in ("Normal", "Hard"):
        for kind in TYPES:
            got = {name: np.load(layers / f"kinds_{look}_{kind}_{name}.npy").astype(np.float32) for name in SPOTS}
            frames[look, kind] = he.lay(backdrop, [(he.project((x, 0, z))[2], got[name]) for name, (x, z) in spots.items()],
                                        places, "Normal", gx, gz)
            alone[look, kind] = got["near"]

    def box(name, half, pad):
        x0, y0, w, h = bm.box([spots[name]], half, TALL - 0.3, pad)
        return max(x0, 0), max(y0, 0), w, h

    near, side, one = box("near", 1.9, 20), box("side", 1.9, 20), box("near", 1.5, 6)
    s = PHONE_H / backdrop.shape[0]
    phone = {key: rs.shrink(frame, s) for key, frame in frames.items()}
    pnear, pside = (tuple(int(round(v * s)) for v in b) for b in (near, side))
    zoom, k, gap, label = 2, 4, 20, 28
    col = max(near[2] * zoom, pnear[2] + gap + pnear[2] * k + gap + pside[2] * k)
    width = gap + 3 * (col + gap)
    tall_phone = max(pnear[3], pside[3]) * k
    dark = one[3]
    height = 110 + 2 * (label + near[3] * zoom + gap) + 2 * (label + tall_phone + gap) + label + dark + 40 + 60
    page = rs.canvas(width, height, rs.rgb("#101117"))
    ink, soft, pale = "#EDE6D6", "#B4AC9C", "#8C8577"
    text = [(gap, 20, 32, "AR52: THE GUARD AND THE DASHER BESIDE THE BRAWLER, NORMAL AND HARD", ink)]
    text += hc.wrapped(gap, 62, 16, "The baked Shade in Faber's day capture of the street through its own camera, each kind in its "
                                   "stretch's colour, where the near Shade stands. Hard is AR46's cut: the cuts coral, the "
                                   "paper's glow off, the coat's cracks lit.", soft, width - 2 * gap)
    y = 110
    for look in ("Normal", "Hard"):
        text.append((gap, y, 18, f"{look}, twice the capture's size", ink))
        for i, (kind, colour) in enumerate(TYPES.items()):
            rs.paste(page, bm.zoomed(he.crop(frames[look, kind], *near), zoom), gap + i * (col + gap), y + label)
            text.append((gap + i * (col + gap) + 8, y + label + 6, 16, f"{kind}, {colour}", ink))
        y += label + near[3] * zoom + gap
    for look in ("Normal", "Hard"):
        text.append((gap, y, 18, f"{look} at the smallest phone ({PHONE_H} pixels high): at its own size, then it and the side one at {k} times", ink))
        for i, kind in enumerate(TYPES):
            x = gap + i * (col + gap)
            rs.paste(page, he.crop(phone[look, kind], *pnear), x, y + label)
            x += pnear[2] + gap
            for b in (pnear, pside):
                rs.paste(page, bm.zoomed(he.crop(phone[look, kind], *b), k), x, y + label)
                x += b[2] * k + gap
        y += label + tall_phone + gap
    text.append((gap, y, 18, "Over dark: each at full size and at 64 pixels high, Normal then Hard", ink))
    x = gap
    for kind in TYPES:
        for look in ("Normal", "Hard"):
            full = hc.on_dark(alone[look, kind], one, 0)
            rs.paste(page, full, x, y + label)
            text.append((x, y + label + full.shape[0] + 6, 12, f"{kind}, {look}", pale))
            x += full.shape[1] + 6
            mini = hc.on_dark(alone[look, kind], one, 64)
            rs.paste(page, mini, x, y + label)
            x += mini.shape[1] + gap
    x, z = spots["near"]
    px = abs(he.project((x, 5.8, z))[1] - he.project((x, 4.0, z))[1])
    note = (f"At the smallest phone the near Guard's mask is about {px * s:.0f} pixels tall ({px:.0f} in the capture). "
            "Stand-ins for the engine: Blender's glow and bloom at the game's numbers, the cracks as hard_cut.py bakes them.")
    text += hc.wrapped(gap, height - 50, 15, note, pale, width - 2 * gap)
    rs.paste(page, rs.text_layer(width, height, text), 0, 0)
    rs.save(page, out / "shade_kinds_look.png")
    print(f"wrote {out / 'shade_kinds_look.png'} ({width} by {height}); {note}")


def main():
    out = bl.out_dir()
    rs.OUT = out
    mode = sys.argv[sys.argv.index("--") + 2]
    runs = {"design": design, "normal": normal_run, "hard": hard_run, "look": look_run,
            # AR58: the Support's mask beside the three, for the content check before the bake
            "support": lambda out: design(out, (*KINDS, SUPPORT), "AR58: the Support, beside the Brawler, the Guard and the Dasher",
                                          "shade_support_design.png")}
    if mode in runs:
        runs[mode](out)
    else:
        raise SystemExit(f"shade_kinds.py: no mode {mode}")


if __name__ == "__main__":
    main()
