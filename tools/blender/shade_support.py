"""AR58, the Support Shade: its look beside the Brawler, the Guard and the Dasher, and at the back of a pack.

  blender -b --factory-startup --python tools/blender/shade_support.py -- <abs out> normal|hard|look

The Support is the baked Shade (shade_model.py's, in shade_clips.MODEL) at SLIGHT of the ordinary size in its
half-mask and veil, in the stretch's Orange. Drawn as shade_kinds.py and shade_elites.py draw the others: on its rig
at the game's glow, through the camera of Faber's day capture of the street (hard_ember.py).

- `normal` and `hard` render each figure alone into <out>/layers: the four kinds in a row at a pack's distance
  (ROW_Z), in the game's Idle; a pack (PACK) with the Support at its back, its sleeves up at the cast's held frame;
  and the Support near, in Idle and in the cast, from three headings. `hard` wears AR46's cut as hard_cut.py composes
  it (into <out>/maps, never the handoff), from the cracks hard_cut.py `shade` baked
  (build/scratch/modulo/ember/layers/bake_shade.npy).
- `look` writes <out>/shade_support_look.png: the row and the pack at the smallest phone's pixels and four times, over
  the paving's colour (the capture's own street has the avatar and its lead where they would stand); the Support
  near, laid into the capture; and at 64 pixels a body from three headings, over dark and over day. The row, the pack,
  the near pictures and the 64 pixel tiles are also saved apart, for a close read.

The cast is read from <out>/../clip/Shade_Cast.json (shade_clips.py's export) or, once delivered, from the handoff.
"""
import shutil
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402
import shade_elites as el  # noqa: E402

KINDS = {"Brawler": "Red", "Guard": "Green", "Dasher": "Orange", "Support": "Orange"}
SLIGHT = 0.9                          # AR58's seed: 0.9 of the ordinary Shade (Definitions/Enemies.luau, Scale)
ROW_Z, ROW_X = -14.0, (-9.0, -3.0, 3.0, 9.0)    # a pack's distance: 14 studs past the avatar, 26 from the camera
# a pack round a lead that stands a few studs in front of the avatar: three in front, the Support behind them
PACK = {"Brawler": (-6.0, -9.0), "Guard": (2.5, -11.0), "Dasher": (7.0, -8.5), "Support": (-2.0, -17.0)}
NEAR = el.NEAR
HEADINGS = el.HEADINGS
PHONE_H, TALL = el.PHONE_H, el.TALL
CAST, HELD = 1000, 56                 # where the cast is keyed on the rig's timeline, and its held frame
WIDE = 1.7                            # the cast's sleeves reach past the body's own border


def scale_of(kind):
    return SLIGHT if kind == "Support" else 1.0


def shots():
    """Every picture a look needs: (file's stem, kind, x, z, faces toward, frame)."""
    out = []
    for i, (kind, x) in enumerate(zip(KINDS, ROW_X)):
        out.append((f"row_{kind}", kind, x, ROW_Z, el.toward((x, ROW_Z), HEADINGS["player"]), i * 23))
        out.append((f"pack_{kind}", kind, *PACK[kind], el.toward(PACK[kind], HEADINGS["player"]),
                    CAST + HELD if kind == "Support" else 7 + i * 31))
    for heading, left in HEADINGS.items():
        out.append((f"near_idle_{heading}", "Support", *NEAR, el.toward(NEAR, left), 11))
        out.append((f"near_cast_{heading}", "Support", *NEAR, el.toward(NEAR, left), CAST + HELD))
    return out


def staged(out):
    import shade_kinds as sk
    he, scene, rig, last, materials, wear, wear_mask = sk.staged()
    file = "Shade_Cast.json"
    path = next((p for p in (out.parent / "clip" / file, he.SHADE_CLIPS / file) if p.exists()), None)
    if path is None:
        raise SystemExit(f"No {file}: export it with shade_clips.py first")
    he.key(rig, path, CAST)
    return he, scene, rig, last, materials, wear, wear_mask


def shoot(he, scene, rig, last, layers, look, kind, wear_mask):
    for stem, k, x, z, faces, frame in shots():
        if k != kind:
            continue
        wear_mask(kind)
        scale = scale_of(kind)
        he.stand(rig, x, z, faces, scale)
        scene.frame_set(frame if frame >= CAST else frame % last)
        he.border(scene, x, z, scale * WIDE, TALL / WIDE)
        path = layers / f"{look}_{stem}.npy"
        he.render(scene, path)
        full = np.load(path)
        rows, cols = np.nonzero(full[..., 3] > 0)
        y0, y1, x0, x1 = rows.min(), rows.max() + 1, cols.min(), cols.max() + 1
        np.savez_compressed(path.with_suffix(".npz"), px=full[y0:y1, x0:x1], at=np.array([x0, y0]))
        path.unlink()


def normal_run(out):
    import hard_cut as hc
    he, scene, rig, last, _, wear, wear_mask = staged(out)
    tints = hc.type_tints()
    layers = out / "layers"
    layers.mkdir(parents=True, exist_ok=True)
    for kind, colour in KINDS.items():
        wear("Normal", dict(he.SHADE, body="#" + tints[colour]))
        shoot(he, scene, rig, last, layers, "Normal", kind, wear_mask)


def hard_run(out):
    """As shade_kinds.hard_run wears AR46's cut."""
    import bpy
    import hard_cut as hc
    he, scene, rig, last, materials, wear, wear_mask = staged(out)
    layers, maps = out / "layers", out / "maps"
    layers.mkdir(parents=True, exist_ok=True)
    maps.mkdir(parents=True, exist_ok=True)
    shipped = hc.FOES["shade"]
    for name in ("Shade_Color.png", "Shade_Emissive.png"):
        shutil.copyfile(shipped["folder"] / name, maps / name)
    hc.FOES["shade"] = dict(shipped, folder=maps)
    baked = np.load(he.REPO / "build" / "scratch" / "modulo" / "ember" / "layers" / "bake_shade.npy").astype(np.float32)
    hc.compose("shade", baked, sorted(set(KINDS.values())))
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
    for kind, colour in KINDS.items():
        painted = bpy.data.images.load(str(maps / "hard" / f"Shade_Color_Hard{colour}.png"))
        for node in nodes["colour"]:
            node.image = painted
        wear("Normal", dict(he.SHADE, body="#FFFFFF"))
        shoot(he, scene, rig, last, layers, "Hard", kind, wear_mask)


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
    ground[:horizon, :, :3] = he.to_linear(np.array(rs.rgb(el.HAZE), np.float32)[:3])
    ground[horizon:, :, :3] = he.to_linear(np.array(rs.rgb(el.PAVING), np.float32)[:3])

    def layer(look, stem):
        got = np.load(layers / f"{look}_{stem}.npz")
        px, (x0, y0) = got["px"].astype(np.float32), got["at"]
        full = np.zeros((he.H, he.W, 4), np.float32)
        full[y0:y0 + px.shape[0], x0:x0 + px.shape[1]] = px
        return full

    def box(spots, half, pad):
        x0, y0, w, h = bm.box(spots, half, TALL - 0.3, pad)
        return max(x0, 0), max(y0, 0), w, h

    def laid(backdrop, look, stems_at):
        """Figures laid on a backdrop: [(stem, kind, x, z)]."""
        got = [(he.project((x, 0, z))[2], layer(look, stem)) for stem, _, x, z in stems_at]
        return he.lay(backdrop, got, [(x, z, scale_of(kind)) for _, kind, x, z in stems_at], "Normal", gx, gz)

    def over(px, colour, tall):
        """A figure's own pixels over a flat ground, shrunk to `tall` pixels high."""
        base = he.to_linear(np.array(rs.rgb(colour), np.float32)[:3])
        comp = np.empty(px.shape[:2] + (4,), np.float32)
        comp[..., :3] = he.to_srgb(px[..., :3] + base * (1 - px[..., 3:]))
        comp[..., 3] = 1.0
        return rs.shrink(comp, tall / px.shape[0])

    looks, poses = ("Normal", "Hard"), ("idle", "cast")
    s = PHONE_H / he.H
    k, gap, label = 4, 20, 28
    row_box = box([(ROW_X[0], ROW_Z), (ROW_X[-1], ROW_Z)], 2.6, 8)
    pack_box = box(list(PACK.values()), 3.4, 8)
    near_box = box([NEAR], 3.3, 14)
    one = box([NEAR], 3.3, 6)
    rows, packs, near, minis = {}, {}, {}, {}
    body = 64 / 5.0 / (he.F / he.project((NEAR[0], 0, NEAR[1]))[2])     # the capture's pixels to 64 a 5-stud body
    for look in looks:
        rows[look] = rs.shrink(he.crop(laid(ground, look, [(f"row_{kind}", kind, x, ROW_Z) for kind, x in zip(KINDS, ROW_X)]), *row_box), s)
        packs[look] = rs.shrink(he.crop(laid(ground, look, [(f"pack_{kind}", kind, *at) for kind, at in PACK.items()]), *pack_box), s)
        for pose in poses:
            near[look, pose] = he.crop(laid(street, look, [(f"near_{pose}_player", "Support", *NEAR)]), *near_box)
            for heading in HEADINGS:
                px = he.crop(layer(look, f"near_{pose}_{heading}"), *one)
                for where, colour in (("dark", "#101117"), ("day", "#B9C4DE")):
                    minis[look, pose, heading, where] = over(px, colour, px.shape[0] * body)

    rw, rh = rows["Normal"].shape[1], rows["Normal"].shape[0]
    pw, ph = packs["Normal"].shape[1], packs["Normal"].shape[0]
    nw, nh = near_box[2], near_box[3]
    mw, mh = next(iter(minis.values())).shape[1], next(iter(minis.values())).shape[0]
    width = gap * 2 + max(rw + gap + rw * k, pw + gap + pw * k, 4 * nw + 3 * gap, 12 * (mw + 6) + 3 * gap)
    height = 116 + 2 * (label + rh * k + gap) + 2 * (label + ph * k + gap) + label + nh + gap + label + 2 * (mh + 20) + gap + 76
    page = rs.canvas(width, height, rs.rgb("#101117"))
    ink, soft, pale = "#EDE6D6", "#B4AC9C", "#8C8577"
    text = [(gap, 20, 30, "AR58: THE SUPPORT SHADE, BESIDE THE BRAWLER, THE GUARD AND THE DASHER", ink)]
    text += hc.wrapped(gap, 60, 16, f"The baked Shade at {SLIGHT:g} of the ordinary size in its half-mask and veil, in the stretch's Orange, "
                                   "beside the three in their stretches' colours. In the pack it stands at the back with its sleeves "
                                   "up, at the cast's held frame; the others are in the game's Idle. Hard is AR46's cut.", soft,
                       width - 2 * gap)
    y = 116
    for look in looks:
        text.append((gap, y, 18, f"{look}, a row at a pack's distance ({-ROW_Z:g} studs past the avatar) at the smallest phone ({PHONE_H} "
                                 f"pixels high): at its own size, then {k} times. Over the paving's colour.", ink))
        rs.paste(page, rows[look], gap, y + label)
        rs.paste(page, bm.zoomed(rows[look], k), gap + rw + gap, y + label)
        y += label + rh * k + gap
    for look in looks:
        text.append((gap, y, 18, f"{look}, a pack with the Support casting at its back, at the smallest phone: at its own size, then {k} times", ink))
        rs.paste(page, packs[look], gap, y + label)
        rs.paste(page, bm.zoomed(packs[look], k), gap + pw + gap, y + label)
        y += label + ph * k + gap
    text.append((gap, y, 18, "Near, in Faber's day capture of the street, at the capture's size: hung and casting, Normal then Hard", ink))
    x = gap
    for look in looks:
        for pose in poses:
            rs.paste(page, near[look, pose], x, y + label)
            text.append((x + 6, y + label + nh - 22, 14, f"{look}, {'the cast, held' if pose == 'cast' else 'Idle'}", ink))
            x += nw + gap
    y += label + nh + gap
    text.append((gap, y, 18, "At 64 pixels a body (an ordinary Shade's 5 studs), over dark then day: the player's camera, the lead's other "
                             "side, behind; hung then casting; Normal then Hard", ink))
    for r, where in enumerate(("dark", "day")):
        x = gap
        for look in looks:
            for pose in poses:
                for heading in HEADINGS:
                    rs.paste(page, minis[look, pose, heading, where], x, y + label + r * (mh + 20))
                    if r == 1:
                        text.append((x, y + label + 2 * mh + 22, 11, f"{look[0]} {pose} {heading}", pale))
                    x += mw + 6
                x += gap
    far = he.project((0, 0, PACK["Support"][1]))[2]
    note = (f"At the back of the pack on the smallest phone the Support stands about {5.19 * SLIGHT * he.F / far * s:.0f} pixels to its "
            f"mask's top, its mask about {2.72 * SLIGHT * he.F / far * s:.0f} wide, and its raised sleeves span about "
            f"{6.6 * SLIGHT * he.F / far * s:.0f}. Stand-ins for the engine: Blender's glow and bloom at the game's numbers. The row's "
            "and the pack's ground is a flat colour: in the capture the avatar and its lead stand there.")
    text += hc.wrapped(gap, height - 60, 15, note, pale, width - 2 * gap)
    rs.paste(page, rs.text_layer(width, height, text), 0, 0)
    rs.save(page, out / "shade_support_look.png")
    for look in looks:
        rs.save(bm.zoomed(rows[look], k), out / f"shade_support_row_{look}.png")
        rs.save(bm.zoomed(packs[look], k), out / f"shade_support_pack_{look}.png")
    strip = np.concatenate([near[look, pose] for look in looks for pose in poses], axis=1)
    strip[..., 3] = 1.0
    rs.save(strip, out / "shade_support_near.png")
    # the 64 pixel tiles at their own size, a file of their own: dark over day, in the sheet's order
    rs.save(np.concatenate([np.concatenate([minis[look, pose, heading, where] for look in looks for pose in poses for heading in HEADINGS],
                                           axis=1) for where in ("dark", "day")], axis=0), out / "shade_support_64.png")
    print(f"wrote {out / 'shade_support_look.png'} ({width} by {height}); {note}")


def main():
    out = bl.out_dir()
    rs.OUT = out
    mode = sys.argv[sys.argv.index("--") + 2]
    runs = {"normal": normal_run, "hard": hard_run, "look": look_run}
    if mode not in runs:
        raise SystemExit(f"shade_support.py: no mode {mode}")
    runs[mode](out)


if __name__ == "__main__":
    main()
