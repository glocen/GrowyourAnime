"""AR6, batch 1, first step: the rarity ladder on the Sword alone, five grey renders for research's verdict on the
steps, with the batch's twenty names proposed (docs/asset-requests.md, AR6, "Batch 1, research's spec").

One sword family, Common to Legendary, point up and to the right on the square's diagonal. A rarity adds material and
ornament, never a new kind, and each is one clear step ("dont make them to sick since it range from common to
legendary", the director, 2026-11-15). Grey only: a part's grey is its material's value, so the steps are judged on
form and value before any colour, frame or finish.

A long, mature sword (the director, 2026-11-15, on a broad icon sword tried first: "no it can be the long mature sword
you did before js smaller and better"): a long sword's own proportions, a little shorter and heavier than the first
grey try so it holds at the slot's size. From how the reference draws its gear (the director, 2026-11-15: "take
geniune inspiration from tcp 3 draw"; docs/research/gear-icons.md), principles only: values set well apart, one stone
as the accent, a clear light on the bevels. The forms are ours: a guard that turns toward the point, the stone cut
like the kit's gems.

    blender -b --factory-startup --python tools/blender/gear_sword_ladder.py -- build/handoff/Gear/sword_ladder

Writes the sheet gear_sword_ladder.png. Workbench only: no GPU turn.
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
import ui_sheet as ui  # noqa: E402
from ui_sheet import c  # noqa: E402

SIZE = 768                      # a render, in pixels
FILL = 0.85                     # how much of the square the largest sword takes
SPIN, LEAN = 22.0, 45.0         # the sword turned about its own length, then laid on the diagonal
BLADE, GRIP = 6.4, 1.5          # the family's lengths: every rarity shares them
WIDTH, THICK = 0.86, 0.12       # the blade: a long sword's, about seven and a half times as long as it's wide

# A material's grey: its value, as the eye would rank it under one light.
GREY = dict(iron=0.46, wood=0.56, leather=0.3, steel=0.76, brass=0.6, blued=0.56, stone=0.88, rich=0.43, filigree=0.8,
            glow=0.95, gilt=0.87, ivory=0.95, lit=1.0)
METAL = ("iron", "steel", "brass", "blued", "rich", "filigree", "gilt")

RARITIES = (
    dict(name="Common", blade="iron", guard="iron", grip="wood", pommel="iron", fuller=False,
         words="Dark iron and wood. A long blade with one ridge, a plain bar, a wheel pommel. No stone, no light "
               "of its own."),
    dict(name="Uncommon", blade="steel", guard="steel", grip="leather", pommel="steel", fuller=True,
         words="Bright steel with a fuller. The bar gets end blocks, the grip a wrap, and one fitting in a second "
               "metal: a brass collar."),
    dict(name="Rare", blade="blued", guard="blued", grip="leather", pommel="blued", fuller=True,
         words="Blued steel. The guard turns toward the point, with one small set stone; a line of engraving runs "
               "in the fuller, and the pommel is cut in facets."),
    dict(name="Epic", blade="rich", guard="rich", grip="leather", pommel="rich", fuller=True,
         words="A darker metal with filigree: a pale plate up the blade's foot, the guard's ends hooked. The "
               "stone larger, in a bezel, glowing softly (pale here)."),
    dict(name="Legendary", blade="gilt", guard="gilt", grip="ivory", pommel="gilt", fuller=True,
         words="Gilt and ivory. One new element of form: a small wing each side of the guard. The stone lit from "
               "within and a light on the edge (white here)."),
)

# The batch's twenty names, by research's pattern: a material and the kind; the ground's craft; the kind "of" a force;
# a coined compound; a proper name with an epithet. Each fits 24 characters. A star marks research's own example.
NAMES = (
    ("Sword", ("Iron Sword*", "Lanternsteel Sword*", "Blade of Embers*", "Stormcall Blade*", "Akari, the Last Lantern*")),
    ("Short Sword", ("Iron Short Sword", "Rowsmith Short Sword", "Brand of Sparks", "Duskwire Brand", "Hotaru, the Small Light")),
    ("Helmet", ("Iron Helmet", "Paper-Lantern Helmet", "Helm of Rime", "Nightcurrent Helm*", "Tomoshibi, the Vigil")),
    ("Ring I", ("Copper Ring*", "Lantern-Wire Ring", "Band of Static*", "Voidglint Loop", "Musubi, the Bound Cord")),
)
assert all(len(n.rstrip("*")) <= 24 for _, row in NAMES for n in row), "a name is over 24 characters"


# --- the parts ---------------------------------------------------------------------------------------------------------

PAINT = None  # the colour pass sets it (gear_icons.py): a key's colour, how metal it is, how rough


def material(key):
    name = f"Grey_{key}"
    if name not in bpy.data.materials:
        m = bpy.data.materials.new(name)
        if PAINT:
            code, m.metallic, m.roughness = PAINT(key)
            m.diffuse_color = (*(float(v) ** 2.2 for v in c(code)[:3]), 1.0)
        else:
            v = GREY[key] ** 2.2
            m.diffuse_color = (v, v, v, 1.0)
            m.metallic, m.roughness = (0.4, 0.36) if key in METAL else (0.0, 0.7)
    return bpy.data.materials[name]


def edges(u):
    """The blade's two edges at u of its length: a slow taper to four fifths, then a long point."""
    hw = WIDTH / 2 * (1 - 0.2 * min(u, 0.8) / 0.8)
    if u <= 0.8:
        return -hw, hw
    v = (u - 0.8) / 0.2
    return -hw * (1 - v ** 1.5), hw * (1 - v ** 1.5)


def blade(r):
    """Two edges with wide bevels and a flat between them; down the flat a ridge, or a fuller that runs out early."""
    bm = bmesh.new()
    rings = []
    for u in (0.0, 0.15, 0.3, 0.45, 0.55, 0.62, 0.72, 0.8, 0.86, 0.91, 0.95, 0.98):
        z, (xl, xr) = u * BLADE, edges(u)
        mid, wide = (xl + xr) / 2, xr - xl
        h = THICK * (1 - 0.35 * u)
        inset = min(0.2, wide * 0.3)
        f = min(0.11, wide * 0.14) * (1.0 if not r["fuller"] else min(1.0, max(0.02, (0.62 - u) / 0.1)))
        dip = 0.42 if r["fuller"] else 1.45
        front = [(xl, 0.0), (xl + inset, -h), (mid - f, -h), (mid - 0.6 * f, -h * dip), (mid + 0.6 * f, -h * dip),
                 (mid + f, -h), (xr - inset, -h), (xr, 0.0)]
        ring = front + [(x, -y) for x, y in front[-2:0:-1]]
        rings.append([bm.verts.new((x, y, z)) for x, y in ring])
    tip = bm.verts.new((0, 0, BLADE))
    n = len(rings[0])
    for a, b in zip(rings, rings[1:]):
        for k in range(n):
            bm.faces.new((a[k], a[(k + 1) % n], b[(k + 1) % n], b[k]))
    for k in range(n):
        bm.faces.new((rings[-1][k], rings[-1][(k + 1) % n], tip))
    bm.faces.new(list(reversed(rings[0])))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bl.smooth_by_angle(bl.object_from_bmesh("Blade", bm, material(r["blade"])), 20.0)


def plate(name, outline_xz, thick, key, y=0.0, bevel=0.0):
    """A flat shape drawn from the front, `thick` deep."""
    bm = bmesh.new()
    near = [bm.verts.new((x, y - thick / 2, z)) for x, z in outline_xz]
    far = [bm.verts.new((x, y + thick / 2, z)) for x, z in outline_xz]
    bm.faces.new(near)
    bm.faces.new(list(reversed(far)))
    for i in range(len(near)):
        j = (i + 1) % len(near)
        bm.faces.new((near[i], near[j], far[j], far[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj = bl.object_from_bmesh(name, bm, material(key))
    return bl.bevel(obj, bevel, segments=1, angle=30.0) if bevel else obj


def mirrored(half):
    """An outline from its right half, from the top's middle round to the foot's middle."""
    return half + [(-x, z) for x, z in reversed(half) if x > 1e-6]


def gem(radius, key, y):
    """A cut stone on the guard's front, and its twin on the back."""
    out = []
    for side in (-1, 1):
        g = bl.sphere("Stone", radius, segments=6, rings=3, material=material(key))
        out.append(bl.place(g, (0, side * y, 0.0), (0, 0, 30), (1, 0.55, 1.2)))
    return out


# The guards, each from its right half: Rare's, turned toward the point; Epic's with its ends hooked; Legendary's wing,
# three short feathers rising off the guard beside the blade; the pale plate up the blade's foot.
TURNED = [(0.0, 0.17), (0.36, 0.17), (0.82, 0.22), (1.14, 0.44), (1.32, 0.3), (1.02, -0.02), (0.4, -0.18), (0.0, -0.2)]
HOOKED = [(0.0, 0.18), (0.36, 0.18), (0.8, 0.24), (1.06, 0.42), (1.17, 0.8), (1.44, 0.58), (1.46, 0.26), (1.04, -0.04),
          (0.4, -0.2), (0.0, -0.22)]
WING = [(0.5, 0.2), (0.55, 0.8), (0.68, 1.18), (0.93, 1.5), (0.99, 1.08), (0.87, 0.96), (1.2, 1.08), (1.19, 0.7), (1.07, 0.62),
        (1.36, 0.62), (1.31, 0.32), (1.05, 0.2)]
FOOT = [(0.0, 1.5), (0.16, 0.92), (0.29, 0.8), (0.29, 0.2), (0.0, 0.2)]


def guard(r):
    name, key, parts = r["name"], r["guard"], []
    if name == "Common":
        parts.append(bl.bevel(bl.box("Guard", (2.3, 0.3, 0.26), material(key)), 0.045, segments=1))
    elif name == "Uncommon":
        parts.append(bl.bevel(bl.box("Guard", (2.3, 0.28, 0.24), material(key)), 0.04, segments=1))
        for side in (-1, 1):
            parts.append(bl.bevel(bl.place(bl.box("End", (0.24, 0.36, 0.38), material(key)), (side * 1.16, 0, 0)), 0.045, segments=1))
        parts.append(bl.place(bl.torus("Collar", 0.2, 0.075, 24, 8, material("brass")), (0, 0, -0.2)))
    else:
        parts.append(plate("Guard", mirrored(HOOKED if name == "Epic" else TURNED), 0.34, key, bevel=0.045))
        if name == "Rare":
            parts += gem(0.17, "stone", 0.2)
        else:
            trim = "filigree" if name == "Epic" else "ivory"
            parts += gem(0.22, "lit" if name == "Legendary" else "glow", 0.2)
            for side in (-1, 1):
                parts.append(bl.place(bl.torus("Bezel", 0.26, 0.042, 20, 8, material(trim)), (0, side * 0.18, 0.0), (90, 0, 0)))
                parts.append(plate("Foot", mirrored(FOOT), 0.04, trim, y=side * (THICK + 0.015), bevel=0.01))
        if name == "Legendary":  # the one new form: where Epic's ends hooked, a small wing rises off each side of the guard
            for side in (-1, 1):
                outline = [(side * x, z) for x, z in (WING if side > 0 else WING[::-1])]
                parts.append(plate("Wing", outline, 0.18, "gilt", bevel=0.035))
    return parts


def grip(r):
    key, parts = r["grip"], []
    top, foot = -0.14, -0.14 - GRIP
    body = bl.cylinder("Grip", 0.15, GRIP, segments=20, material=material(key), radius_top=0.175)
    parts.append(bl.smooth_by_angle(bl.place(body, (0, 0, (top + foot) / 2)), 40.0))
    wraps = dict(Common=0, Uncommon=7, Rare=7, Epic=9, Legendary=0)[r["name"]]
    for i in range(wraps):  # the wrap: turns of cord, each a little tilted
        z = top - 0.2 - (GRIP - 0.4) * i / (wraps - 1)
        parts.append(bl.place(bl.torus("Wrap", 0.17, 0.04, 18, 6, material(key)), (0, 0, z), (10, 6, 0)))
    bands = dict(Common=(0.5,), Uncommon=(), Rare=(0.05, 0.95), Epic=(0.05, 0.95), Legendary=(0.05, 0.5, 0.95))[r["name"]]
    for u in bands:
        parts.append(bl.place(bl.torus("Band", 0.175, 0.05, 20, 8, material(r["guard"])), (0, 0, top - GRIP * u)))
    return parts


def pommel(r):
    name, key, z = r["name"], r["pommel"], -0.14 - GRIP - 0.22
    if name in ("Common", "Uncommon"):  # a wheel
        parts = [bl.bevel(bl.place(bl.cylinder("Pommel", 0.3, 0.22, segments=20, material=material(key)), (0, 0, z), (90, 0, 0)),
                          0.04, segments=1)]
        if name == "Uncommon":
            parts.append(bl.place(bl.torus("Rim", 0.3, 0.045, 24, 8, material("brass")), (0, 0, z), (90, 0, 0)))
        return parts
    # Cut in facets: it widens down from the grip, then closes.
    parts = [bl.place(bl.cylinder("Pommel", 0.17, 0.36, segments=8, material=material(key), radius_top=0.3), (0, 0, z + 0.04), (180, 0, 0)),
             bl.place(bl.cylinder("Cap", 0.3, 0.16, segments=8, material=material(key), radius_top=0.09), (0, 0, z - 0.22), (180, 0, 0))]
    if name != "Rare":
        parts.append(bl.place(bl.sphere("Stud", 0.09, 10, 6, material("filigree" if name == "Epic" else "ivory")), (0, 0, z - 0.32)))
    return parts


def extras(r):
    parts = []
    if r["name"] in ("Rare", "Epic", "Legendary"):  # a line of engraving in the fuller, front and back
        for side in (-1, 1):
            parts.append(bl.place(bl.box("Line", (0.05, 0.02, BLADE * 0.34), material("filigree" if r["name"] != "Legendary" else "ivory")),
                                  (0, side * THICK * 0.42, BLADE * (0.3 if r["name"] == "Rare" else 0.42))))
    if r["name"] == "Legendary":  # a light on the edge
        for side in (0, 1):
            us = np.linspace(0.05, 0.995, 28)
            path = [Vector((edges(u)[side], 0, u * BLADE)) for u in us]
            parts.append(bl.tube_along("Edge", path, [0.03] * len(path), sides=6, material=material("lit")))
    return parts


def sword(r):
    """The sword in a scene of its own, laid on the diagonal."""
    scene = bl.reset_scene()
    scene.world = bpy.data.worlds.new("Room")
    parts = [blade(r)] + guard(r) + grip(r) + pommel(r) + extras(r)
    middle = (BLADE - GRIP - 0.7) / 2
    lay = (Matrix.Rotation(math.radians(LEAN), 4, "Y") @ Matrix.Rotation(math.radians(SPIN), 4, "Z")
           @ Matrix.Translation((0, 0, -middle)))
    for obj in parts:
        obj.data.transform(lay)
    return scene, parts


def bounds(parts):
    pts = np.array([v.co for obj in parts for v in obj.data.vertices])
    return pts[:, 0].min(), pts[:, 0].max(), pts[:, 2].min(), pts[:, 2].max()


def shoot(scene, out, centre, span):
    cam = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
    scene.collection.objects.link(cam)
    scene.camera, cam.data.type, cam.data.ortho_scale, cam.data.clip_end = cam, "ORTHO", span, 200
    cam.location = (centre[0], -40, centre[1])
    cam.rotation_euler = (math.radians(90), 0, 0)
    rs.workbench(scene, SIZE, SIZE)
    scene.display.shading.show_specular_highlight = True
    scene.render.filepath = str(out / "_sword.png")
    bpy.ops.render.render(write_still=True)
    px = rs.load(out / "_sword.png")
    (out / "_sword.png").unlink()
    return px


def renders(out):
    """All five from one camera, set by the largest so the family's sizes are true to each other."""
    _, top = sword(RARITIES[-1])
    x0, x1, z0, z1 = bounds(top)
    centre, span = ((x0 + x1) / 2, (z0 + z1) / 2), max(x1 - x0, z1 - z0) / FILL
    shots = {}
    for r in RARITIES:
        scene, parts = sword(r)
        b = bounds(parts)
        shots[r["name"]] = shoot(scene, out, centre, span)
        print(f"{r['name']}: fills {max(b[1] - b[0], b[3] - b[2]) / span:.2f} of the square")
    return shots


# --- the sheet ---------------------------------------------------------------------------------------------------------

GROUND, INK, SOFT_INK, NOTE = "#1B1D24", "#F3EFE6", "#C9CDD6", "#FFE266"
CELL, DARK = "#2A2D36", "#15161B"


def lines(text, width):
    out, line = [], ""
    for word in text.split():
        if len(line) + len(word) + 1 > width:
            out.append(line)
            line = word
        else:
            line = f"{line} {word}".strip()
    return out + [line]


def sheet(out, shots):
    ui.K = K = 2
    sh = ui.Sheet(1180, 692, GROUND)
    t = sh.tile(0, 0, sh.w, sh.h)
    t.text(20, 12, 15, "Grow your Anime: the Sword's ladder, Common to Legendary, in grey (AR6, batch 1)", INK)
    t.text(20, 36, 9.5, "One long sword on the square's diagonal, one camera and one light. A grey is its material's value. Each "
           "rarity adds one thing or two, and Legendary leaves room above. For research's verdict on the steps; the other "
           "three kinds follow it.", SOFT_INK)
    t.text(20, 50, 9.5, "The director, 2026-11-15: \"dont make them to sick since it range from common to legendary\"; \"take "
           "geniune inspiration from tcp 3 draw\"; and, on a broad icon sword tried first, \"no it can be the long mature "
           "sword you did before js smaller and better\".", SOFT_INK)
    w = 220.0
    for i, r in enumerate(RARITIES):
        x, y = 20 + i * (w + 10), 72.0
        tile = sh.tile(x, y, w, w)
        tile.paint(tile.poly(ui.cut_box(0, 0, w, w, 8, 0, 8, 0)), c(CELL))
        px = rs.shrink(shots[r["name"]], w * K / SIZE)
        rs.paste(sh.px, px, round(x * K), round(y * K))
        t.text(x + 8, y + 7, 11, r["name"], INK)
        for j, line in enumerate(lines(r["words"], 46)):
            t.text(x, y + w + 8 + j * 12, 8.5, line, SOFT_INK)

    # At the slot's size and alone as a silhouette.
    y = 372.0
    t.text(20, y, 10, "At the Voidkin screen's slot, 38 points, and each silhouette alone at 32 pixels (shown at twice its size).", SOFT_INK)
    for i, r in enumerate(RARITIES):
        x = 20 + i * 96
        tile = sh.tile(x, y + 18, 44, 44)
        tile.paint(tile.poly(ui.cut_box(0, 0, 44, 44, 4, 0, 4, 0)), c(DARK))
        small = rs.shrink(shots[r["name"]], 38 * K / SIZE)
        rs.paste(sh.px, small, round((x + 3) * K), round((y + 21) * K))
        t.text(x, y + 68, 8, r["name"], SOFT_INK)
        x2 = 540 + i * 96
        tile = sh.tile(x2, y + 18, 44, 44)
        tile.paint(tile.poly(ui.cut_box(0, 0, 44, 44, 4, 0, 4, 0)), c("#8A8F9C"))
        tiny = rs.shrink(rs.black(shots[r["name"]]), 32 / SIZE)
        tiny = np.repeat(np.repeat(tiny, 2, axis=0), 2, axis=1)  # 32 pixels, each drawn as two
        rs.paste(sh.px, tiny, round((x2 + 6) * K), round((y + 24) * K))
        t.text(x2, y + 68, 8, r["name"], SOFT_INK)

    # The names.
    y = 470.0
    t.text(20, y, 10, "The batch's twenty names, proposed. Research's pattern by rarity; each fits 24 characters; a star is "
           "research's own example, kept. Research checks each against the list and the roster.", SOFT_INK)
    t.text(20, y + 22, 9.5, "Kind", NOTE)
    for i, r in enumerate(RARITIES):
        t.text(120 + i * 208, y + 22, 9.5, r["name"], NOTE)
    for j, (kind, row) in enumerate(NAMES):
        t.text(20, y + 42 + j * 20, 10, kind, INK)
        for i, name in enumerate(row):
            t.text(120 + i * 208, y + 42 + j * 20, 10, name, INK if not name.endswith("*") else SOFT_INK)
    y = 600.0
    notes = (
        "Lantern Row's craft words (Uncommon): Lanternsteel, Rowsmith, Paper-Lantern, Lantern-Wire. Forces (Rare) are the game's "
        "elements and their kin: Embers and Sparks, Rime, Static.",
        "Legendary names are Japanese words with an epithet in plain words: akari, a light; hotaru, a firefly; tomoshibi, a lamp's "
        "flame; musubi, a tie or a knot. None is a roster name (Cinder is, so no \"Cinders\").",
        "From the reference, principles only: values set apart, one stone as the accent, a clear light on the bevels. Ours: a long "
        "sword's own proportions, a guard that turns toward the point, the stone cut like the kit's gems.",
        "For research's verdict: is each step seen at 38 points? Is Legendary's wing the right one element, with room left for "
        "Mythical and Dawn? Not here yet: colour and finish, the kit's frames, the class mark, the rendered light.",
    )
    for i, line in enumerate(notes):
        t.text(20, y + i * 15, 9, line, SOFT_INK)
    layers = ui.text_layers(sh.px.shape[1], sh.px.shape[0], sh.items)
    for layer in layers.values():
        rs.paste(sh.px, layer, 0, 0)
    rs.save(sh.px, out / "gear_sword_ladder.png")


def main():
    out = bl.out_dir()
    sheet(out, renders(out))


if __name__ == "__main__":
    main()
