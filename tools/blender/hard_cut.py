"""AR46's cut for Faber: Hard's maps for the Shade (the Brawler, Red) and the Lamplighter, from the stand-in B
research passed at competent (2026-11-19, 17:56): the masks' cuts in the ember with the paper's glow off (A), and the
coat's cracks lit from within (B). The burst's tint is a number, in hard.json.

Roblox draws a surface's light as the colour map x EmissiveTint x the glow map x EmissiveStrength. The body's tint is
its type's colour, so cracks drawn on the body would take that colour. On Hard the body's tint goes white, and its type's
colour moves into the colour map, under the pixels that glow (by the glow's share against the day's light, fully over
TRIM): every pixel that glows today emits what it emits on Normal, and the cracks keep their own amber. A mask keeps its
tint and strength: its cuts are painted the ember under their glow, and its paper's glow is off, as the stand-in drew it.

    blender -b --factory-startup --python tools/blender/hard_cut.py -- <abs out> shade|keeper|colours|sheet

`shade` and `keeper` each (one Blender at a time, for memory):
  1. stage the foe as hard_ember.py does, its crack layer installed by hard_ember.glows;
  2. bake, into the foe's own atlas (its UVs), the crack, its core and which islands are body and which are mask
     (Cycles, on the CPU, under build/locks/blender.lock), kept in <out>/layers/bake_<foe>.npy;
  3. write the Hard maps beside the foe's, in build/handoff/<Foe>/hard/: <Foe>_Emissive_Hard.png, the stand-in's
     type's <Foe>_Color_Hard<Type>.png, and <Foe>_Color_HardTint.png for SurfaceAppearance's TintMask (the colour map
     untinted, its alpha the type's share). The roughness, and the keeper's metalness, stay the foe's own;
  4. render the Hard maps on the foe, its body's tint white, at the stand-in's places, into <out>/layers.
`colours` writes every type's colour map for both foes from the kept bakes (the types from Config/Shades.luau).
`sheet` lays the check beside the stand-in B (hard_ember.py's layers, in the same <out>), measures the fit, and
writes hard_cut.png and each foe's hard/hard.json.
"""
import json
import re
import sys
from pathlib import Path

import bpy
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import hard_ember as he  # noqa: E402
import rook_model as rm  # noqa: E402
import rook_sheet as rs  # noqa: E402

HANDOFF = he.REPO / "build" / "handoff"
FOES = {
    "shade": dict(folder=HANDOFF / "Shade", prefix="Shade", body="Shade_Baked", mask="Shade_Mask", game=he.SHADE,
                  type="Red", said="the Shade (the Brawler, Red)"),
    "keeper": dict(folder=HANDOFF / "Lamplighter", prefix="Lamplighter", body="Lamplighter_Body",
                   mask="Lamplighter_Mask", game=he.KEEPER, type="Purple", said="the Lamplighter (Purple)"),
}
DAY = 1.2          # the day's light on the cloth, in the glow's units: the sun's 3 over pi and the fill's 0.8, as drawn
TRIM = (0.3, 0.6)  # the glow over which the type's colour is fully in the map: the coat's own ramp under 0.5, trim 0.75 up
MARGIN = rm.MARGIN + 4  # texels grown past each island: past the foes' own margin, so no texel of theirs is unclassed
SAMPLES = 16       # per texel: the cracks' edges antialiased


def linear(c):
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def coded(c):
    c = np.clip(c, 0.0, 1.0)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)


def hard_paths(kind):
    f = FOES[kind]
    hard = f["folder"] / "hard"
    return hard / f"{f['prefix']}_Color_Hard{f['type']}.png", hard / f"{f['prefix']}_Emissive_Hard.png"


# --- staging, as hard_ember.py stages the stand-in ---------------------------------------------------------------

def staged(kind, out):
    """The foe as the stand-in drew it: its rig, its clip, its glowing materials with the crack layer installed.
    Returns the scene, the rig, the clip's length, its materials by name, wear(look, game), and the masks' re-dress."""
    if kind == "shade":
        import shade_clips as sc
        scene, rig, _, wear_mask, _ = sc.build("Strength")
        wear_mask("Brawler")
        redress = lambda: wear_mask("Brawler")  # noqa: E731
        he.setup(scene)
        last = he.key(rig, he.SHADE_CLIPS / "Shade_Idle.json")
    else:
        import lamplighter_clips as lc
        scene, rig, *_ = lc.build(out)
        redress = lambda: None  # noqa: E731
        he.setup(scene)
        last = he.key(rig, he.KEEPER_CLIPS / "Lamplighter_Ready.json")
    f = FOES[kind]
    materials = {m.name: m for o in scene.objects for s in o.material_slots if (m := s.material)}
    wear = he.glows([materials[f["body"]], materials[f["mask"]]], {f["body"]})
    return scene, rig, last, materials, wear, redress


# --- the bake: the cracks, their cores, and the islands, in the atlas ----------------------------------------------

def settle(baked, steps):
    """Each island grown out by `steps` texels into the texels no island owns, never over another's. Blender pads each
    piece's margin on its own, and a wide one paints over a neighbour's island (a mask's cuts lost to a body's
    margin), so the bake keeps a margin of 1 and the islands grow here. A texel between the classes (a seam's blend)
    counts as unowned and takes its neighbour's."""
    out = baked.copy()
    cls = out[..., 2]
    owned = (cls > 0.85) | ((cls > 0.4) & (cls < 0.6))
    out[~owned] = 0.0
    for _ in range(steps):
        took = np.zeros_like(owned)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            near_owned = np.zeros_like(owned)
            near = np.zeros_like(out)
            ys = slice(max(dy, 0), owned.shape[0] + min(dy, 0))
            yd = slice(max(-dy, 0), owned.shape[0] + min(-dy, 0))
            xs = slice(max(dx, 0), owned.shape[1] + min(dx, 0))
            xd = slice(max(-dx, 0), owned.shape[1] + min(-dx, 0))
            near_owned[ys, xs] = owned[yd, xd]
            near[ys, xs] = out[yd, xd]
            take = near_owned & ~owned & ~took
            out[take] = near[take]
            took |= take
        owned |= took
    return out


def bake(scene, kind, materials, size):
    """R: the crack (0 to 1), G: its core, B: 1 on the body's islands, 0.5 on a mask's. Top row first."""
    f = FOES[kind]
    body, mask = materials[f["body"]], materials[f["mask"]]
    objs = [o for o in scene.objects if o.type == "MESH" and any(s.material in (body, mask) for s in o.material_slots)]
    hidden = {o: o.hide_render for o in objs}
    image = bpy.data.images.new("HardBake", size, size, alpha=False, float_buffer=True)
    image.colorspace_settings.name = "Non-Color"
    kept = []
    for m in {s.material for o in objs for s in o.material_slots if s.material}:
        nodes, links = m.node_tree.nodes, m.node_tree.links
        target = nodes.new("ShaderNodeTexImage")
        target.image = image
        nodes.active = target
        output = next(n for n in nodes if n.bl_idname == "ShaderNodeOutputMaterial" and n.is_active_output)
        was = output.inputs["Surface"].links[0].from_socket if output.inputs["Surface"].links else None
        kept.append((m, output, was, target))
        emit = nodes.new("ShaderNodeEmission")
        if m is body:
            channels = nodes.new("ShaderNodeCombineColor")
            links.new(nodes["Crack"].outputs[0], channels.inputs[0])
            links.new(nodes["Core"].outputs["Result"], channels.inputs[1])
            channels.inputs[2].default_value = 1.0
            links.new(channels.outputs[0], emit.inputs["Color"])
        else:
            emit.inputs["Color"].default_value = (0.0, 0.0, 0.5 if m is mask else 0.0, 1.0)
        links.new(emit.outputs[0], output.inputs["Surface"])
    engine = scene.render.engine
    scene.render.engine = "CYCLES"
    scene.cycles.device, scene.cycles.samples = "CPU", SAMPLES
    scene.render.bake.margin, scene.render.bake.margin_type = 1, "EXTEND"
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.hide_render = False
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    held = rm.lock("hard_cut.py")
    try:
        bpy.ops.object.bake(type="EMIT", use_clear=True, margin=1, margin_type="EXTEND")
    finally:
        held.unlink(missing_ok=True)
    baked = settle(rm.pixels(image)[::-1].copy(), MARGIN)
    for m, output, was, target in kept:  # the materials as they were, for the check
        if was is not None:
            m.node_tree.links.new(was, output.inputs["Surface"])
        m.node_tree.nodes.remove(target)
    for o, h in hidden.items():
        o.hide_render = h
    scene.render.engine = engine
    print(f"baked {kind}: {len(objs)} pieces, cracks on {(baked[..., 0] > 0.05).sum()} texels, body islands "
          f"{(baked[..., 2] > 0.75).sum()}, mask islands {((baked[..., 2] > 0.25) & (baked[..., 2] <= 0.75)).sum()}")
    return baked


# --- the Hard maps ----------------------------------------------------------------------------------------------

def type_tints():
    """The types' glow tints, read from their home (src/shared/Config/Shades.luau, Tint), so they are never copied."""
    text = (he.REPO / "src" / "shared" / "Config" / "Shades.luau").read_text(encoding="utf-8")
    block = re.search(r"Tint = \{(.*?)\}", text, re.S).group(1)
    return dict(re.findall(r'(\w+) = Color3\.fromHex\("#?([0-9A-Fa-f]{6})"\)', block))


def compose(kind, baked, types=None):
    """The foe's colour and glow maps with Hard's ember: the stand-in B's light, for a white body tint. One colour map
    per type named (the stand-in's by default), and one for SurfaceAppearance's TintMask, its alpha the type's share."""
    f = FOES[kind]
    tints = type_tints()
    types = types or [f["type"]]
    colour = rs.load(f["folder"] / f"{f['prefix']}_Color.png")
    glow = rs.load(f["folder"] / f"{f['prefix']}_Emissive.png")
    if colour.shape[:2] != baked.shape[:2] or glow.shape[:2] != baked.shape[:2]:
        raise SystemExit(f"{kind}: the maps and the bake differ in size")
    crack, core, island = baked[..., 0].clip(0, 1), baked[..., 1].clip(0, 1), baked[..., 2]
    body, mask = island > 0.75, (island > 0.25) & (island <= 0.75)
    unclassed = ~body & ~mask & (glow[..., 0] > 0.01)  # past the margin the foe's own maps hold their mean: no glow
    print(f"{kind}: {unclassed.sum()} glowing texels on no island")
    lin, light = linear(colour[..., :3]), glow[..., 0].copy()
    # the type's colour under the body's glow, so a white tint draws it as today. The colour map is the cloth's day
    # colour too: where the glow is faint, its grey lit by day outweighs the light, so the type's colour goes in only as
    # far as the light outweighs the day (its share of the two), and fully from TRIM up, where the trim must stay exact
    share = light * f["game"]["body_s"] / (light * f["game"]["body_s"] + DAY)
    ramp_up = np.clip((light - TRIM[0]) / (TRIM[1] - TRIM[0]), 0, 1)
    w = (np.maximum(share, ramp_up * ramp_up * (3 - 2 * ramp_up)) * body)[..., None]
    # the cracks: the ramp across each, the light at the stand-in's strength over the body's
    ramp = (np.array(rs.srgb(he.EMBER)[:3]) * (1 - core[..., None])
            + np.array(rs.srgb(he.CRACK_CORE)[:3]) * core[..., None])
    k = (crack * body)[..., None]
    lit = np.where(body, np.maximum(light, crack * he.CRACK["strength"] / f["game"]["body_s"]), light)
    # a mask: its cuts the ember, its paper dark. The swatch strip at the atlas's foot holds the paper that small faces
    # wear (a mask's stitches and rim), on no area the bake can draw; only a mask wears paper (the foes' own bakes), so
    # the strip's glow is a mask's paper
    cuts = mask & (light > he.CUTS)
    strip = np.zeros_like(body)
    strip[-int(rm.STRIP * 0.8 * strip.shape[0]):] = True
    lit = np.where((mask & ~cuts) | (strip & ~body & (light <= he.CUTS)), 0.0, lit)

    def painted(tinted):
        out = colour.copy()
        hard = tinted * (1 - k) + ramp * k
        hard[cuts] = np.array(rs.srgb(he.CUT_HARD)[:3])
        out[..., :3] = coded(hard)
        return out

    hard_dir = f["folder"] / "hard"
    hard_dir.mkdir(parents=True, exist_ok=True)
    written = {}
    for name in types:
        tint = np.array(rs.srgb("#" + tints[name])[:3], dtype=np.float32)
        written[name] = hard_dir / f"{f['prefix']}_Color_Hard{name}.png"
        rs.save(painted(lin * (1 - w + w * tint)).astype(np.float32), written[name])
    # TintMask: the colour map untinted, its alpha where SurfaceAppearance.Color (the type's) multiplies it; never under
    # a crack, which keeps its own ramp. Whether that tint reaches the glow is the engine's to show (unchecked)
    tinted = painted(lin)
    tinted[..., 3] = (w * (1 - k))[..., 0]
    written["Tint"] = hard_dir / f"{f['prefix']}_Color_HardTint.png"
    rs.save(tinted.astype(np.float32), written["Tint"])
    glow_out = np.ones_like(glow)
    glow_out[..., :3] = lit[..., None]
    written["Emissive"] = hard_paths(kind)[1]
    rs.save(glow_out.astype(np.float32), written["Emissive"])
    print(f"wrote {', '.join(p.name for p in written.values())}: {cuts.sum()} cut texels, "
          f"{(crack * body > 0.05).sum()} crack texels, the cracks' glow up to "
          f"{(crack * body).max() * he.CRACK['strength'] / f['game']['body_s']:.3f}")
    return hard_paths(kind)


# --- the check: the Hard maps on the foe, as Roblox draws them ----------------------------------------------------

def check(scene, rig, last, materials, wear, redress, kind, paths, layers):
    f = FOES[kind]
    colour = bpy.data.images.load(str(paths[0]))
    glow = bpy.data.images.load(str(paths[1]))
    glow.colorspace_settings.name = "Non-Color"
    swapped = 0
    for name in (f["body"], f["mask"]):
        for node in materials[name].node_tree.nodes:
            if node.bl_idname != "ShaderNodeTexImage" or node.image is None:
                continue
            file = Path(bpy.path.abspath(node.image.filepath)).name
            if file == f"{f['prefix']}_Color.png":
                node.image, swapped = colour, swapped + 1
            elif file == f"{f['prefix']}_Emissive.png":
                node.image, swapped = glow, swapped + 1
    if swapped < 4:
        raise SystemExit(f"{kind}: only {swapped} map nodes swapped")
    redress()
    wear("Normal", dict(f["game"], body="#FFFFFF"))  # the crack layer and the stand-in's mask switch off: the maps do it
    heat = bpy.data.objects.get("Heat")
    if heat:
        heat.data.energy = 0.0
    if kind == "shade":
        for name, x, z, toward, frame in he.PACK:
            he.stand(rig, x, z, toward, 1.0)
            scene.frame_set(frame % last)
            he.border(scene, x, z, 1.0, 5.6)
            he.render(scene, layers / f"cut_shade_{name}.npy")
    else:
        name, x, z, toward, frame = he.KEEPER_AT
        he.stand(rig, x, z, toward, he.KEEPER["scale"])
        scene.frame_set(frame % last)
        he.border(scene, x, z, he.KEEPER["scale"] * 1.3, 7.4)
        he.render(scene, layers / "cut_keeper.npy")


def foe_run(kind, out):
    layers = out / "layers"
    layers.mkdir(parents=True, exist_ok=True)
    scene, rig, last, materials, wear, redress = staged(kind, layers)
    f = FOES[kind]
    size = rs.load(f["folder"] / f"{f['prefix']}_Emissive.png").shape[0]
    baked = bake(scene, kind, materials, size)
    np.save(layers / f"bake_{kind}.npy", baked.astype(np.float16))  # the islands and cracks, for the sheet's checks
    paths = compose(kind, baked)
    check(scene, rig, last, materials, wear, redress, kind, paths, layers)


# --- the sheet --------------------------------------------------------------------------------------------------

def fit(a, b, alpha):
    """The cut's frame against the stand-in's, where either has a foe: mean and 99th centile, in 8-bit steps."""
    d = np.abs(a[..., :3] - b[..., :3]).max(axis=-1)[alpha] * 255
    return float(d.mean()), float(np.percentile(d, 99))


def wrapped(x, y, size, words, colour, room):
    """A paragraph as the sheet's text lines: about half a size per letter, a line every 1.4 sizes."""
    per, lines, line = int(room / (size * 0.52)), [], ""
    for word in words.split():
        if line and len(line) + 1 + len(word) > per:
            lines.append(line)
            line = word
        else:
            line = f"{line} {word}" if line else word
    lines.append(line)
    return [(x, y + round(i * size * 1.4), size, text, colour) for i, text in enumerate(lines)]


def on_dark(layer, box, tall):
    """A foe's layer over the sheet's dark, cropped to its box, shrunk to `tall` pixels high."""
    x, y, w, h = box
    part = he.crop(layer, x, y, w, h).copy()
    dark = rs.canvas(w, h, rs.rgb("#101117"))
    rs.paste(dark, part, 0, 0)
    return rs.shrink(dark, tall / h) if tall else dark


def sheet_run(out):
    rs.OUT = out
    layers_dir = out / "layers"
    still = rs.load(he.STILL)
    backdrop = still.copy()
    backdrop[..., :3] = he.to_linear(still[..., :3])
    gx, gz = he.ground_points()

    def layer(name):
        return np.load(layers_dir / f"{name}.npy").astype(np.float32)

    places = [(x, z, 1.0) for _, x, z, _, _ in he.PACK]
    _, kx, kz, _, _ = he.KEEPER_AT
    frames, alone = {}, {}
    for label, prefix_shade, keeper_name in (("stand-in", "shade_B_", "keeper_B"), ("cut", "cut_shade_", "cut_keeper")):
        shades = [(he.project((x, 0, z))[2], layer(f"{prefix_shade}{name}")) for name, x, z, _, _ in he.PACK]
        frames[label, "shade"] = he.lay(backdrop, shades, places, "B", gx, gz)
        frames[label, "keeper"] = he.lay(backdrop, [(1.0, layer(keeper_name))], [(kx, kz, he.KEEPER["scale"])], "B",
                                         gx, gz)
        alone[label, "shade"] = layer(f"{prefix_shade}near")
        alone[label, "keeper"] = layer(keeper_name)
    fits = {}
    for foe in ("shade", "keeper"):
        mask = (alone["stand-in", foe][..., 3] > 0.01) | (alone["cut", foe][..., 3] > 0.01)
        if foe == "shade":
            for name, *_ in he.PACK[1:]:
                mask |= (layer(f"shade_B_{name}")[..., 3] > 0.01) | (layer(f"cut_shade_{name}")[..., 3] > 0.01)
        fits[foe] = fit(frames["cut", foe], frames["stand-in", foe], mask)
        print(f"fit {foe}: mean {fits[foe][0]:.2f}, 99th {fits[foe][1]:.1f} (8-bit steps)")

    def box(spots, half_w, top, pad=26):
        xs, ys = [], []
        for x, z in spots:
            for dx in (-half_w, half_w):
                for y in (0.0, top):
                    px, py, _ = he.project((x + dx, y, z))
                    xs.append(px)
                    ys.append(py)
        x0, y0 = int(min(xs)) - pad, int(min(ys)) - pad
        return x0, y0, int(max(xs)) + pad - x0, int(max(ys)) + pad - y0

    near = box([(he.PACK[0][1], he.PACK[0][2]), (he.PACK[1][1], he.PACK[1][2])], 1.6, 5.3)
    side = box([(he.PACK[2][1], he.PACK[2][2])], 1.6, 5.3)
    kbox = box([(kx, kz)], 3.2, 10.6)
    one = box([(he.PACK[0][1], he.PACK[0][2])], 1.4, 5.3, pad=8)
    bbox = box([(he.PACK[0][1], he.PACK[0][2])], 2.2, 8.8)
    zoom, gap, head, label = 2, 24, 120, 30
    cols = [near[2] * zoom, side[2] * zoom, kbox[2]]
    row_h = max(near[3] * zoom, side[3] * zoom, kbox[3])
    small_h = max(one[3], kbox[3]) + 30
    burst_h = bbox[3]
    width = max(gap + sum(c + gap for c in cols), gap + 4 * (bbox[2] + gap) + 2 * (256 + gap))
    height = head + 2 * (label + row_h + gap) + label + small_h + gap + label + max(burst_h, 256) + 2 * gap + 90
    page = rs.canvas(width, height, rs.rgb("#101117"))
    ink, soft, pale = "#EDE6D6", "#B4AC9C", "#8C8577"
    text = [(gap, 22, 34, "AR46'S CUT: HARD'S MAPS ON THE SHADE AND THE LAMPLIGHTER", ink)]
    text += wrapped(gap, 66, 16, "The stand-in B research passed, then the cut's maps on the same foes as Roblox draws "
                                 "them (the body's tint white, the masks' as today), in Faber's day capture through its "
                                 "own camera. The near pair and the side Shade at two times, the keeper at full size.",
                    soft, width - 2 * gap)
    y = head
    for label_text, key in (("B, the stand-in (research's pass, 17:56)", "stand-in"),
                            ("The cut: the Hard maps, the body's tint white", "cut")):
        text.append((gap, y, 18, label_text, ink))
        y += label
        x = gap
        for (bx, by, bw, bh), col in ((near, cols[0]), (side, cols[1])):
            big = np.repeat(np.repeat(he.crop(frames[key, "shade"], bx, by, bw, bh), zoom, 0), zoom, 1)
            rs.paste(page, big, x, y)
            x += col + gap
        rs.paste(page, he.crop(frames[key, "keeper"], *kbox), x, y)
        y += row_h + gap
    text.append((gap, y, 18, "Over dark: the cut at full size, then at 64 pixels high; the stand-in's at 64 beside", ink))
    y += label
    x = gap
    for foe, b in (("shade", one), ("keeper", kbox)):
        full = on_dark(alone["cut", foe], b, 0)
        rs.paste(page, full, x, y)
        x += full.shape[1] + gap
        for key in ("cut", "stand-in"):
            small = on_dark(alone[key, foe], b, 64)
            rs.paste(page, small, x, y)
            text.append((x, y + 70, 12, key, pale))
            x += small.shape[1] + gap
    y += small_h + gap
    text.append((gap, y, 18, "The burst on Hard (27, 29): the flame tinted, the scraps paper. Then the Shade's Hard maps",
                 ink))
    y += label
    x = gap
    for frame in he.BURST_FRAMES:
        for lbl in ("Normal", "Hard"):
            burst = he.lay(backdrop, [(1.0, layer(f"burst_{frame}_{lbl}"))], [], "Normal", gx, gz)
            rs.paste(page, he.crop(burst, *bbox), x, y)
            text.append((x + 8, y + 8, 14, f"{frame}, {lbl}", ink))
            x += bbox[2] + gap
    for path in hard_paths("shade"):
        pic = rs.load(path)
        pic[..., 3] = 1.0
        rs.paste(page, rs.shrink(pic, 256 / pic.shape[0]), x, y)
        text.append((x, y + 262, 12, path.name, pale))
        x += 256 + gap
    notes = (f"Fit, the cut against the stand-in where a foe stands (8-bit steps): the Shade's pack mean "
             f"{fits['shade'][0]:.2f}, 99th {fits['shade'][1]:.0f}; the keeper mean {fits['keeper'][0]:.2f}, 99th "
             f"{fits['keeper'][1]:.0f}. What differs: the stand-in drew the cracks per pixel, the cut holds them in the "
             "atlas's texels (69 a stud on the Shade, 60 on the keeper), so a crack's edge is a touch softer up close; "
             "and the colour map takes the type's colour under the glow, so the trim's daylit part is a touch redder.")
    text += wrapped(gap, height - 70, 15, notes, pale, width - 2 * gap)
    rs.paste(page, rs.text_layer(width, height, text), 0, 0)
    rs.save(page, out / "hard_cut.png")
    print(f"wrote {out / 'hard_cut.png'} ({width} by {height})")
    for kind in ("shade", "keeper"):
        handoff(kind, fits[kind])


# --- the handoff --------------------------------------------------------------------------------------------------

def handoff(kind, fit_numbers):
    f = FOES[kind]
    colour, glow = hard_paths(kind)
    types = sorted(type_tints())
    n = len(types)
    pieces = ("the five body pieces, the four masks and the elite's second mask" if kind == "shade" else
              "the five body pieces and the Head (the lantern's and the pole's texels are unchanged: they may keep "
              "the Normal pair)")
    data = dict(
        what=f"AR46, Hard's ember on {f['said']}: the masks' cuts in the ember with the paper's glow off, and the "
             "coat's cracks lit from within. Research's pick B without C (2026-11-19, 17:42), the cracks' second "
             "look passed at competent (17:56). From tools/blender/hard_cut.py, baked from hard_ember.py's stand-in",
        maps=dict(Emissive=glow.name, Color=colour.name, TintMask=f"{f['prefix']}_Color_HardTint.png",
                  same=["Roughness"] + (["Metalness"] if kind == "keeper" else []),
                  note=f"All of the foe's pieces share one atlas: on Hard, {pieces} wear the Hard glow map and one "
                       f"Hard colour map; the roughness stays the foe's own. {colour.name} is the {f['type']} type's, "
                       f"checked against the stand-in; the other {n - 1} types' are one run of hard_cut.py's "
                       "`colours` mode, on the atlas route's pick. A mask's texels are the same in every type's map"),
        on_hard=dict(
            body=dict(EmissiveTint="#FFFFFF", EmissiveStrength=f["game"]["body_s"],
                      note=f"the type's colour is in the colour map under the body's glow; at Config.Shades' body "
                           f"strength ({f['game']['body_s']:g}) every lit pixel draws as on Normal and the cracks "
                           "draw their own amber"),
            masks=dict(EmissiveTint=f["game"]["mask"], EmissiveStrength=f["game"]["mask_s"],
                       note="as today: the maps carry the cuts' ember and the paper's dark"),
            burst=dict(ImageColor3=he.BURST_TINT, on="every picture whose Kind is not scrap (charge, flare, flame)",
                       scraps="ImageColor3 white, on every difficulty (the content check's condition)")),
        fit=dict(mean=round(fit_numbers[0], 3), p99=round(fit_numbers[1], 2),
                 note="the cut's frame against the stand-in B's, in 8-bit steps, where a foe stands: a crack's edge "
                      "is a touch softer in the atlas's texels, and the trim's daylit part a touch redder"),
        ways={
            "the atlas, a colour map per type": f"no new parts or meshes. Per foe, {n} Hard colour maps (one per type, "
                                                f"Config.Shades.Tint) and one Hard glow map: {2 * (n + 1)} images for "
                                                "the two foes. A Hard foe wears its type's pair: a Hard template per "
                                                "foe and type, or a Hard SurfaceAppearance per type cloned onto the "
                                                "pieces at spawn. Each new type adds a colour map per foe",
            "the atlas, with TintMask": "no new parts or meshes, and type-free: per foe, the TintMask colour map and "
                                        "the Hard glow map, 4 images for the two foes. On Hard, AlphaMode TintMask, "
                                        "SurfaceAppearance.Color the type's colour, EmissiveTint white. Unchecked: "
                                        "TintMask is still a beta (Roblox's announcement), and nothing read says "
                                        "whether its tint reaches the glow; a few minutes in Studio show it. If it "
                                        "doesn't, the trim glows white",
            "a shell": "the body's maps and tint stay as they are. Each body piece gets a second, slightly larger "
                       "MeshPart carrying only the cracks, with a transparent colour map and a glow map, type-free: "
                       "per foe 5 more meshes to upload and 2 images, and the masks still wear the Hard pair (2 "
                       "images, type-free): 10 meshes and 8 images for the two foes, then 5 more MeshParts and welds "
                       "on each Hard foe at spawn, and a transparent layer that can sort or fight with the body. Not "
                       "made: on Faber's pick"},
        conditions=["each crack keeps its ramp, amber at its core falling to coral, never flat or dark red",
                    "every crack is anchored at a hem, a cuff or a foot, or tapers at both ends; none ends in a bead",
                    "no short isolated marks; nothing on the mask, the face, the hands or the trim; gone by the chest",
                    "the burst's paper stays cream on every difficulty",
                    "the built Hard foes get their own content check before upload"])
    path = f["folder"] / "hard" / "hard.json"
    path.write_text(json.dumps(data, indent=2), encoding="utf-8", newline="\n")
    print(f"wrote {path}")


def main():
    out = bl.out_dir()
    mode = sys.argv[sys.argv.index("--") + 2]
    if mode in FOES:
        foe_run(mode, out)
    elif mode == "colours":
        for kind in FOES:
            compose(kind, np.load(out / "layers" / f"bake_{kind}.npy").astype(np.float32), sorted(type_tints()))
    else:
        sheet_run(out)


if __name__ == "__main__":
    main()
