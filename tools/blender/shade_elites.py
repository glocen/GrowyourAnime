"""AR57, the Guard's and the Dasher's elites: their look beside their ordinary kin and the Brawler elite.

  blender -b --factory-startup --python tools/blender/shade_elites.py -- <abs out> normal|hard|look

An elite is the Shade at 1.35 with its own mask a second time on the Left Arm (shade_elite.py: the placement;
shade_elite_bare.py: the mask's mesh without its ties). This draws the baked Shade (shade_model.py's, in
shade_clips.MODEL) on its rig in the game's Idle at the game's glow, each kind in its stretch's colour
(Config.Shades.Tint: the Brawler Red, the Guard Green, the Dasher Orange), as shade_kinds.py does.

- `normal` and `hard` render each figure alone through the camera of Faber's day capture of the street
  (hard_ember.py), into <out>/layers: a row of five at the square's edge (EDGE: 32 studs from the avatar), each near
  as the player's camera meets it, and the two new elites near from the lead's other side and from behind. `hard`
  wears AR46's cut as hard_cut.py composes it (into <out>/maps, never the handoff), from the cracks hard_cut.py
  `shade` baked (build/scratch/modulo/ember/layers/bake_shade.npy).
- `look` writes <out>/shade_elites_look.png: the row at the smallest phone's pixels and four times, over the paving's
  colour (the capture's own street has the avatar where the row would stand); each figure near, laid into the
  capture; and the two new elites at 64 pixels a body from three headings, over dark and over day.

The second masks are read from <out>/../bare (shade_elite_bare.py's output) or, once delivered, from the handoff.
"""
import json
import math
import shutil
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402
import shade_elite as se  # noqa: E402

SCALE = se.SCALE
TYPES = {"Brawler": "Red", "Guard": "Green", "Dasher": "Orange"}
# the row, left to right: (kind, elite)
ROW = (("Guard", False), ("Guard", True), ("Brawler", True), ("Dasher", True), ("Dasher", False))
EDGE = -32.0                          # the square is 64 studs: its edge is 32 from an elite at its middle
EDGE_X = (-15.0, -7.5, 0.0, 7.5, 15.0)
NEAR = (-7.0, -3.0)                   # hard_ember.py's near spot: open paving in the capture
# a heading: how many degrees to the Shade's left of its front the camera stands (the player's camera sits behind the
# lead's right shoulder, so a Shade that faces the lead shows it its front and its left: shade_elite.PLAYER)
HEADINGS = {"player": 24.0, "other": -24.0, "behind": 155.0}
PHONE_H = 450                         # the smallest phone's capture, in the device's pixels (brawler_mask_look.py)
TALL = 7.2                            # studs: the Dasher's point stands at 6.7
PAVING, HAZE = "#8C7FA6", "#CFC9DC"   # the capture's paving and the street's far end, for the row's ground


def name_of(kind, elite):
    return f"{kind}{'Elite' if elite else ''}"


def toward(spot, left):
    """A point the Shade faces from `spot` so the capture's camera stands `left` degrees to the left of its front."""
    import hard_ember as he
    cx, cz = he.EYE.x - spot[0], he.EYE.z - spot[1]
    n = math.hypot(cx, cz)
    cx, cz = cx / n, cz / n
    for sign in (1.0, -1.0):
        a = math.radians(left * sign)
        fx, fz = cx * math.cos(a) - cz * math.sin(a), cx * math.sin(a) + cz * math.cos(a)
        side = cx * -fz + cz * fx       # the camera along the Shade's right (-fz, fx)
        if (side < 0) == (left > 0) or left == 0:
            return spot[0] + fx * 8.0, spot[1] + fz * 8.0
    raise SystemExit("toward: no heading")


def shots():
    """Every picture a look needs: (file's stem, kind, elite, x, z, faces toward, Idle frame)."""
    out = []
    for i, ((kind, elite), x) in enumerate(zip(ROW, EDGE_X)):
        out.append((f"edge_{name_of(kind, elite)}", kind, elite, x, EDGE, toward((x, EDGE), HEADINGS["player"]), i * 23))
        out.append((f"near_{name_of(kind, elite)}_player", kind, elite, *NEAR, toward(NEAR, HEADINGS["player"]), i * 23))
    for kind in ("Guard", "Dasher"):
        for heading in ("other", "behind"):
            out.append((f"near_{name_of(kind, True)}_{heading}", kind, True, *NEAR, toward(NEAR, HEADINGS[heading]), 11))
    return out


def second_masks(rig, material, out):
    """Each kind's second mask on the Left Arm, as the game places it; hidden until worn."""
    import shade_elite_bare as seb
    masks = {}
    for kind in TYPES:
        file = f"Shade_Mask{kind}Bare.json"
        path = next((p for p in (out.parent / "bare" / file, seb.HANDOFF / file) if p.exists()), None)
        if path is None:
            raise SystemExit(f"No {file}: run shade_elite_bare.py first")
        record = json.loads(path.read_text())
        obj = seb.mesh_object(f"Second{kind}", record, material)
        seb.wear(rig, obj, se.placement(kind, record["c"]))
        obj.hide_render = True
        masks[kind] = obj
    return masks


def shoot(he, scene, rig, last, masks, layers, look, kind, wear_mask):
    for stem, k, elite, x, z, faces, frame in shots():
        if k != kind:
            continue
        wear_mask(kind)
        for other, obj in masks.items():
            obj.hide_render = not (elite and other == kind)
        scale = SCALE if elite else 1.0
        he.stand(rig, x, z, faces, scale)
        scene.frame_set(frame % last)
        he.border(scene, x, z, scale, TALL)
        path = layers / f"{look}_{stem}.npy"
        he.render(scene, path)
        full = np.load(path)
        rows, cols = np.nonzero(full[..., 3] > 0)
        y0, y1, x0, x1 = rows.min(), rows.max() + 1, cols.min(), cols.max() + 1
        np.savez_compressed(path.with_suffix(".npz"), px=full[y0:y1, x0:x1], at=np.array([x0, y0]))
        path.unlink()


def staged(out):
    import shade_kinds as sk
    he, scene, rig, last, materials, wear, wear_mask = sk.staged()
    import bpy
    bpy.context.view_layer.update()
    return he, scene, rig, last, materials, wear, wear_mask, second_masks(rig, materials["Shade_Mask"], out)


def normal_run(out):
    import hard_cut as hc
    he, scene, rig, last, _, wear, wear_mask, masks = staged(out)
    tints = hc.type_tints()
    layers = out / "layers"
    layers.mkdir(parents=True, exist_ok=True)
    for kind, colour in TYPES.items():
        wear("Normal", dict(he.SHADE, body="#" + tints[colour]))
        shoot(he, scene, rig, last, masks, layers, "Normal", kind, wear_mask)


def hard_run(out):
    """As shade_kinds.hard_run wears AR46's cut."""
    import bpy
    import hard_cut as hc
    he, scene, rig, last, materials, wear, wear_mask, masks = staged(out)
    layers, maps = out / "layers", out / "maps"
    layers.mkdir(parents=True, exist_ok=True)
    maps.mkdir(parents=True, exist_ok=True)
    shipped = hc.FOES["shade"]
    for name in ("Shade_Color.png", "Shade_Emissive.png"):
        shutil.copyfile(shipped["folder"] / name, maps / name)
    hc.FOES["shade"] = dict(shipped, folder=maps)
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
        wear("Normal", dict(he.SHADE, body="#FFFFFF"))
        shoot(he, scene, rig, last, masks, layers, "Hard", kind, wear_mask)


# --- the sheet --------------------------------------------------------------------------------------------------------

def look_run(out):
    import brawler_mask_look as bm
    import hard_cut as hc
    import hard_ember as he
    layers = out / "layers"
    still = rs.load(he.STILL)
    street = still.copy()
    street[..., :3] = he.to_linear(still[..., :3])
    gx, gz = he.ground_points()
    horizon = int(round(he.project((0.0, he.EYE.y, -4000.0))[1]))
    ground = np.empty_like(street)
    ground[..., 3] = 1.0
    ground[:horizon, :, :3] = he.to_linear(np.array(rs.rgb(HAZE), np.float32)[:3])
    ground[horizon:, :, :3] = he.to_linear(np.array(rs.rgb(PAVING), np.float32)[:3])

    def layer(look, stem):
        got = np.load(layers / f"{look}_{stem}.npz")
        px, (x0, y0) = got["px"].astype(np.float32), got["at"]
        full = np.zeros((he.H, he.W, 4), np.float32)
        full[y0:y0 + px.shape[0], x0:x0 + px.shape[1]] = px
        return full

    def box(spots, scale, half, pad):
        x0, y0, w, h = bm.box(spots, half * scale, (TALL - 0.3) * scale, pad)
        return max(x0, 0), max(y0, 0), w, h

    def over(px, colour, tall):
        """A figure's own pixels over a flat ground, shrunk to `tall` pixels high."""
        base = he.to_linear(np.array(rs.rgb(colour), np.float32)[:3])
        comp = np.empty(px.shape[:2] + (4,), np.float32)
        comp[..., :3] = he.to_srgb(px[..., :3] + base * (1 - px[..., 3:]))
        comp[..., 3] = 1.0
        return rs.shrink(comp, tall / px.shape[0])

    looks = ("Normal", "Hard")
    s = PHONE_H / he.H
    k, gap, label = 4, 20, 28
    edge_box = box([(EDGE_X[0], EDGE), (EDGE_X[-1], EDGE)], SCALE, 2.6, 8)
    rows = {}
    for look in looks:
        got = [(he.project((x, 0, EDGE))[2], layer(look, f"edge_{name_of(kind, elite)}")) for (kind, elite), x in zip(ROW, EDGE_X)]
        places = [(x, EDGE, SCALE if elite else 1.0) for (kind, elite), x in zip(ROW, EDGE_X)]
        rows[look] = rs.shrink(he.crop(he.lay(ground, got, places, "Normal", gx, gz), *edge_box), s)
    near = {}
    boxes = {elite: box([NEAR], SCALE if elite else 1.0, 2.1, 16) for elite in (False, True)}
    for look in looks:
        for kind, elite in ROW:
            scale = SCALE if elite else 1.0
            frame = he.lay(street, [(he.project((NEAR[0], 0, NEAR[1]))[2], layer(look, f"near_{name_of(kind, elite)}_player"))],
                           [(*NEAR, scale)], "Normal", gx, gz)
            near[look, kind, elite] = he.crop(frame, *boxes[elite])
    body = 64 / 5.0 / (he.F / he.project((NEAR[0], 0, NEAR[1]))[2])     # the capture's pixels to 64 a 5-stud body
    one = box([NEAR], SCALE, 1.9, 6)
    minis = {}
    for look in looks:
        for kind in ("Guard", "Dasher"):
            for heading in HEADINGS:
                px = he.crop(layer(look, f"near_{name_of(kind, True)}_{heading}"), *one)
                for where, colour in (("dark", "#101117"), ("day", "#B9C4DE")):
                    minis[look, kind, heading, where] = over(px, colour, px.shape[0] * body)

    rw, rh = rows["Normal"].shape[1], rows["Normal"].shape[0]
    nw = sum(near["Normal", kind, elite].shape[1] for kind, elite in ROW) + gap * (len(ROW) - 1)
    nh = boxes[True][3]
    mw, mh = next(iter(minis.values())).shape[1], next(iter(minis.values())).shape[0]
    width = gap * 2 + max(rw + gap + rw * k, nw, 12 * (mw + 6) + 3 * gap)
    height = 110 + 2 * (label + rh * k + gap) + 2 * (label + nh + gap) + label + 2 * (mh + 20) + gap + 70
    page = rs.canvas(width, height, rs.rgb("#101117"))
    ink, soft, pale = "#EDE6D6", "#B4AC9C", "#8C8577"
    text = [(gap, 20, 30, "AR57: THE GUARD'S AND THE DASHER'S ELITES, BESIDE THEIR KIN AND THE BRAWLER ELITE", ink)]
    text += hc.wrapped(gap, 60, 16, f"The baked Shade at {SCALE:g} with its own mask a second time on the left arm (its mesh without ties, at "
                                   f"{se.SMALL:g}), each kind in its stretch's colour, in the game's Idle. Left to right: the Guard, the "
                                   "Guard's elite, the Brawler's elite, the Dasher's elite, the Dasher. Hard is AR46's cut.", soft,
                       width - 2 * gap)
    y = 110
    for look in looks:
        text.append((gap, y, 18, f"{look}, from the square's edge ({-EDGE:g} studs from the avatar) at the smallest phone ({PHONE_H} pixels "
                                 f"high): at its own size, then {k} times. Over the paving's colour.", ink))
        rs.paste(page, rows[look], gap, y + label)
        rs.paste(page, bm.zoomed(rows[look], k), gap + rw + gap, y + label)
        y += label + rh * k + gap
    for look in looks:
        text.append((gap, y, 18, f"{look}, near, in Faber's day capture of the street, at the capture's size", ink))
        x = gap
        for kind, elite in ROW:
            tile = near[look, kind, elite]
            rs.paste(page, tile, x, y + label + nh - tile.shape[0])
            text.append((x + 6, y + label + nh - 22, 14, f"{kind}{' elite' if elite else ''}, {TYPES[kind]}", ink))
            x += tile.shape[1] + gap
        y += label + nh + gap
    text.append((gap, y, 18, "The two new elites at 64 pixels a body, over dark then day: the player's camera, the lead's other side, "
                             "behind; Normal then Hard", ink))
    for r, where in enumerate(("dark", "day")):
        x = gap
        for kind in ("Guard", "Dasher"):
            for look in looks:
                for heading in HEADINGS:
                    rs.paste(page, minis[look, kind, heading, where], x, y + label + r * (mh + 20))
                    if r == 1:
                        text.append((x, y + label + 2 * mh + 22, 11, f"{kind[0]} {look[0]} {heading}", pale))
                    x += mw + 6
                x += gap
    px = abs(he.project((0.0, 5.8 * SCALE, EDGE))[1] - he.project((0.0, 4.0 * SCALE, EDGE))[1])
    arm = abs(he.project((0.0, 4.2 * SCALE, EDGE))[1] - he.project((0.0, 2.9 * SCALE, EDGE))[1])
    note = (f"From the square's edge at the smallest phone, an elite stands about {7.0 * SCALE * he.F / he.project((0, 0, EDGE))[2] * s:.0f} "
            f"pixels tall, its mask about {px * s:.0f} and its second mask about {arm * s:.0f}. Stand-ins for the engine: Blender's glow "
            "and bloom at the game's numbers. The row's ground is a flat colour: in the capture the avatar stands where the row would.")
    text += hc.wrapped(gap, height - 56, 15, note, pale, width - 2 * gap)
    rs.paste(page, rs.text_layer(width, height, text), 0, 0)
    rs.save(page, out / "shade_elites_look.png")
    for look in looks:
        rs.save(bm.zoomed(rows[look], k), out / f"shade_elites_row_{look}.png")
        strip = np.concatenate([np.pad(near[look, kind, elite], ((nh - near[look, kind, elite].shape[0], 0), (0, 0), (0, 0)))
                                for kind, elite in ROW], axis=1)
        strip[..., 3] = 1.0
        rs.save(strip, out / f"shade_elites_near_{look}.png")
    print(f"wrote {out / 'shade_elites_look.png'} ({width} by {height}); {note}")


def main():
    out = bl.out_dir()
    rs.OUT = out
    mode = sys.argv[sys.argv.index("--") + 2]
    runs = {"normal": normal_run, "hard": hard_run, "look": look_run}
    if mode not in runs:
        raise SystemExit(f"shade_elites.py: no mode {mode}")
    runs[mode](out)


if __name__ == "__main__":
    main()
