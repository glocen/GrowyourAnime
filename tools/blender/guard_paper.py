"""AR72, the Guard's main mask: one more paper detail. Three targets beside today's mask, each an edit of the baked
mask's own mesh (build/scratch/modulo/shade/model, Shade_MaskGuard), rendered as shade_kinds.py renders the kinds (the
rig in the game's Idle, the game's glow, the Guard's Green) and laid into Faber's day capture through its own camera.

  blender -b --factory-startup --python tools/blender/guard_paper.py -- <abs out>

Writes <out>/guard_paper_targets.png: the near Guard at twice the capture's size, its mask at four times, the same at
the smallest phone's pixels at its own size and four times, and each over dark at 64 pixels high.

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

FRONT = 0.9      # the mask's face, in its mesh's y (its front is +y); the cuts' glowing slabs sit on it, to 0.92
BODY_Y = 0.5     # the mask's paper, rim, tabs and cuts are in front of this; its ties are behind
TITLES = {"Today": "Today", "A": "A, the brow fold", "B": "B, the turned corner", "C": "C, the crest"}


def fold(me, a, b, degrees, over=False):
    """Folds the mask's paper along the line from a to b (x, z on its face), hinged on its front face: the part on the
    side away from the mask's middle turns `degrees` about the line, toward us when positive. `over`: it's turned
    right over and lies on the face. It's pressed paper-thin first (only its faces toward us kept, flattened onto the
    face's plane), or its rim turns forward as a little pyramid and shades the face; once over, its faces are turned
    to us again (a game mesh shows one side only) and take the tabs' paper."""
    bm = bmesh.new()
    bm.from_mesh(me)
    pa, pb = Vector((a[0], FRONT, a[1])), Vector((b[0], FRONT, b[1]))
    d = (pb - pa).normalized()
    n = d.cross(Vector((0, 1, 0))).normalized()          # across the line, in the face's plane
    if (Vector((0, FRONT, 4.85)) - pa).dot(n) > 0:
        n = -n                                           # pointing away from the middle
    body = [f for f in bm.faces if f.calc_center_median().y > BODY_Y]
    geom = list({v for f in body for v in f.verts}) + list({e for f in body for e in f.edges}) + body
    cut = bmesh.ops.bisect_plane(bm, geom=geom, plane_co=pa, plane_no=n)["geom_cut"]
    bmesh.ops.split_edges(bm, edges=[e for e in cut if isinstance(e, bmesh.types.BMEdge)])
    flap = [f for f in bm.faces if f.calc_center_median().y > BODY_Y and (f.calc_center_median() - pa).dot(n) > 1e-4]
    if over:
        bmesh.ops.delete(bm, geom=[f for f in flap if f.normal.y < 0.2], context="FACES")
        flap = [f for f in flap if f.is_valid]
        for v in {v for f in flap for v in f.verts}:
            v.co.y = FRONT
    far = {v for f in flap for v in f.verts}

    def turn(deg):
        return Matrix.Translation(pa) @ Matrix.Rotation(math.radians(deg), 4, d) @ Matrix.Translation(-pa)

    sign = 1 if (turn(90) @ (pa + n)).y > FRONT else -1   # positive turns toward us (+y)
    m = turn(sign * degrees)
    for v in far:
        v.co = m @ v.co
    bm.normal_update()
    if over:
        for v in far:
            v.co.y += 0.03                               # clear of the face and the cuts' slabs (to 0.92)
        bmesh.ops.reverse_faces(bm, faces=[f for f in flap if f.normal.y < 0])
        bm.normal_update()
        uv = bm.loops.layers.uv.active
        tab = next(f for f in bm.faces if f.normal.y > 0.9 and (c := f.calc_center_median()).y > 0.8
                   and abs(abs(c.x) - 1.0) < 0.05)
        paper = sum((loop[uv].uv for loop in tab.loops), Vector((0, 0))) / len(tab.loops)
        for f in flap:
            for loop in f.loops:
                loop[uv].uv = paper
    bm.to_mesh(me)
    bm.free()


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
    "A": lambda me: fold(me, (-1.3, 5.28), (1.3, 5.28), -40),
    "B": lambda me: fold(me, (0.52, 5.75), (1.0, 5.42), 172, over=True),
    "C": lambda me: crest(me),
}


def render_run(out):
    import hard_cut as hc
    he, scene, rig, last, _, wear, wear_mask = sk.staged()
    wear("Normal", dict(he.SHADE, body="#" + hc.type_tints()["Green"]))
    wear_mask("Guard")
    obj = bpy.data.objects["Shade_MaskGuard"]
    shipped = obj.data
    layers = out / "layers"
    layers.mkdir(parents=True, exist_ok=True)
    for name, edit in EDITS.items():
        me = shipped.copy()
        edit(me)
        obj.data = me
        sk.shoot(he, scene, rig, last, layers, name, "Guard")
    obj.data = shipped


def sheet_run(out):
    import brawler_mask_look as bm
    import hard_cut as hc
    import hard_ember as he
    layers = out / "layers"
    still = rs.load(he.STILL)
    backdrop = still.copy()
    backdrop[..., :3] = he.to_linear(still[..., :3])
    gx, gz = he.ground_points()
    spots = {name: (x, z) for name, x, z, _, _ in he.PACK if name in sk.SPOTS}
    places = [(x, z, 1.0) for x, z in spots.values()]
    frames, alone = {}, {}
    for name in EDITS:
        got = {s: np.load(layers / f"kinds_{name}_Guard_{s}.npy").astype(np.float32) for s in sk.SPOTS}
        frames[name] = he.lay(backdrop, [(he.project((x, 0, z))[2], got[s]) for s, (x, z) in spots.items()],
                              places, "Normal", gx, gz)
        alone[name] = got["near"]

    def clamp(b):
        x0, y0, w, h = b
        return max(x0, 0), max(y0, 0), w, h

    x, z = spots["near"]
    near = clamp(bm.box([spots["near"]], 1.9, sk.TALL - 0.3, 20))
    xs, ys = zip(*(he.project((x + dx, y, z))[:2] for dx in (-1.4, 1.4) for y in (3.7, 6.1)))
    face = (int(min(xs)) - 6, int(min(ys)) - 6, int(max(xs) - min(xs)) + 12, int(max(ys) - min(ys)) + 12)
    one = clamp(bm.box([spots["near"]], 1.5, sk.TALL - 0.3, 6))
    s = sk.PHONE_H / backdrop.shape[0]
    phone = {k: rs.shrink(f, s) for k, f in frames.items()}
    pnear, pface = (tuple(int(round(v * s)) for v in b) for b in (near, face))
    zoom, fz, k, gap, label = 2, 4, 4, 20, 54   # a row's caption, then each column's title, above its tiles
    col = max(near[2] * zoom, face[2] * fz, pnear[2] + gap + pnear[2] * k)
    width = gap + len(EDITS) * (col + gap)
    rows = (near[3] * zoom, face[3] * fz, pnear[3] * k)
    height = 110 + sum(label + r + gap for r in rows) + label + 64 + 40 + 60
    page = rs.canvas(width, height, rs.rgb("#101117"))
    ink, soft, pale = "#EDE6D6", "#B4AC9C", "#8C8577"
    text = [(gap, 20, 32, "AR72: THE GUARD'S MASK, ONE MORE PAPER DETAIL, BESIDE TODAY'S", ink)]
    text += hc.wrapped(gap, 62, 16, "The baked Guard, Normal, in its Green, in Faber's day capture of the street through its own "
                                   "camera, where the near Shade stands. Each target is an edit of the mask's own mesh: paper "
                                   "folded or cut through to the light, no ink.", soft, width - 2 * gap)
    y = 110
    for what, tall, show in (("twice the capture's size", rows[0], lambda f: bm.zoomed(he.crop(f, *near), zoom)),
                             ("its mask at four times the capture's size", rows[1], lambda f: bm.zoomed(he.crop(f, *face), fz))):
        text.append((gap, y, 18, what, ink))
        for i, name in enumerate(EDITS):
            rs.paste(page, show(frames[name]), gap + i * (col + gap), y + label)
            text.append((gap + i * (col + gap), y + 28, 16, TITLES[name], soft))
        y += label + tall + gap
    text.append((gap, y, 18, f"At the smallest phone ({sk.PHONE_H} pixels high): at its own size, then at {k} times", ink))
    for i, name in enumerate(EDITS):
        x0 = gap + i * (col + gap)
        rs.paste(page, he.crop(phone[name], *pnear), x0, y + label)
        text.append((x0, y + 28, 16, TITLES[name], soft))
        rs.paste(page, bm.zoomed(he.crop(phone[name], *pnear), k), x0 + pnear[2] + gap, y + label)
    y += label + rows[2] + gap
    text.append((gap, y, 18, "Over dark, 64 pixels high", ink))
    for i, name in enumerate(EDITS):
        rs.paste(page, hc.on_dark(alone[name], one, 64), gap + i * (col + gap), y + label)
        text.append((gap + i * (col + gap), y + 28, 16, TITLES[name], soft))
    px = abs(he.project((x, 5.8, z))[1] - he.project((x, 4.0, z))[1])
    note = (f"At the smallest phone the near Guard's mask is about {px * s:.0f} pixels tall ({px:.0f} in the capture). "
            "Stand-ins for the engine: Blender's glow and bloom at the game's numbers.")
    text += hc.wrapped(gap, height - 50, 15, note, pale, width - 2 * gap)
    rs.paste(page, rs.text_layer(width, height, text), 0, 0)
    rs.save(page, out / "guard_paper_targets.png")
    for name in EDITS:   # each alone, for the pick's pairs: the mask at four times, and the phone at four times
        rs.save(bm.zoomed(he.crop(frames[name], *face), fz), out / f"guard_paper_{name}_mask.png")
        rs.save(bm.zoomed(he.crop(phone[name], *pnear), k), out / f"guard_paper_{name}_phone.png")
    print(f"wrote {out / 'guard_paper_targets.png'} ({width} by {height}); {note}")


def main():
    out = bl.out_dir()
    rs.OUT = out
    render_run(out)
    sheet_run(out)


if __name__ == "__main__":
    main()
