"""AR48: the element states' cues (Burn, Chill then Freeze, Shock, Sap) as a grey block-in, then in colour, in motion
beside a plain hit, on the Shade and on an open-legs Voidkin (Rook), from the player's camera on Lantern Row's paving by
day (docs/asset-requests.md, AR48; handbook/visuals/vfx.md).

blender.exe -b --factory-startup --python tools/blender/element_states_fx.py -- <out_dir> Shade
blender.exe -b --factory-startup --python tools/blender/element_states_fx.py -- <out_dir> Rook
blender.exe -b --factory-startup --python tools/blender/element_states_fx.py -- <out_dir> sheet
(one model a process, so a run stays under 1.1 GB: each body's plates are kept in <out_dir>/_<body>.npz, read by the
sheet's run and deleted after it.)

Each body is built as its clip scripts build it (shade_clips.build, rook_clips.build), stood side by side in one view
(each rendered alone with the camera moved, then laid together, Rook's shadow carried over), with a grey stand-in lead
where the player's own fighter stands. The ice (the frost's sleeve, the shell, its chips) is geometry, drawn by
Workbench with the bodies and laid over them translucent by a keyed pass. The motes, embers, arcs and the hit's sparks
are drawn over the frame from their 3D paths through the same camera, hidden behind a body or the lead where they pass
behind it. Every tile is the smallest phone's own pixels (852 by 480, 1.5 a point).

Hero shapes, one each (a status reads quieter than a hit, and never hides the silhouette):
- Burn: tapered sparks, white-hot at the head to an orange tail, stretched along their rise and flickering, born off the
  shoulders' tops and at the hit, lifted fast, then drifting and fading above the head; one in seven larger.
- Chill: a sleeve of ice round the legs, its top a crown of teeth, climbing from the feet a step a frost hit. Freeze: a faceted shell of ice snapping
  up and shut round the body (0.1 s), its edges flashing once, held clear (the body shows through), then broken into
  chips flung out and falling.
- Shock: jagged arcs leaping off the body between two of its points, three frames each, in bursts about three a
  second: one big arc a burst (1.6 to 2.6 studs) and one or two smaller, each a white core in the pink glow.
- Sap: dark motes circling in round the body and sinking slowly, easing out, each round with a thin violet rim on its
  top, shrinking to a point above the knees: dark first. Never a fall or a stretch (a dark falling drop reads as a drip).
The plain hit beside them is a stand-in for the game's flinch spark (a four-point glint, sparks along the blow, dust).
The grey rows draw each colour at its own luma, so the grey is the colour's value check.
"""
import json
import math
import random
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Quaternion, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import r6anim as r6  # noqa: E402
import rook_clips as rc  # noqa: E402
import rook_haymaker_fx as hx  # noqa: E402  (camera)
import rook_sheet as rs  # noqa: E402
import shade_clips as sc  # noqa: E402

W, H = 852, 480                      # the smallest phone's pixels
VIEW = dict(azimuth=-24.0, elevation=14.0, distance=20.0, focus=(0.0, 1.0, 3.0), fov=70.0)  # the burst block-in's angle
SPOTS = {"Shade": -1.0, "Rook": -6.2}  # studs along the street's x each body stands (+x is the screen's left)
LEAD = (0.0, 7.0)                     # the stand-in lead, the player's own fighter
PAVING = (0.56, 0.52, 0.46, 1.0)      # Lantern Row's paving by day, a stand-in (linear)
SKY = (0.62, 0.68, 0.76)

COLOURS = {  # sRGB: core, body, rim, glow
    "Hit": ("#FFFFFF", "#FFF1D6", "#6B5A44", "#FFE7B8"),
    "Fire": ("#FFE9B0", "#FF8A3D", "#7A2410", "#FF8A3D"),
    "Frost": ("#F4FDFF", "#8FE3FF", "#2C6E8F", "#8FE3FF"),
    "Storm": ("#FFF2FB", "#FF6FD8", "#6E1A5C", "#FF6FD8"),
    "Void": ("#17121F", "#17121F", "#B58CFF", "#B58CFF"),  # Sap: a dark body, its violet only the rim
}
DUST = "#B9B2A6"

# The timelines, in seconds from the hit that causes the state (DESIGN seeds; the builder's numbers rule)
BURN = 3.0
CHILL = (0.0, 0.8, 1.6)            # three frost hits, one step of frost each
LEVELS = (0.0, 0.75, 1.5, 2.25)    # studs: the frost's top after each step, feet to hips
FREEZE, SHUT, THAW, SHATTER = 2.4, 0.1, 4.4, 0.4
SHOCK = (0.0, 0.38, 0.7, 1.1, 1.45, 1.9, 2.3, 2.7)  # the arcs' bursts, each three frames
SAP = 4.0
ROWS = [
    ("Hit", "the plain hit (a stand-in for the game's flinch spark)", [f / 60 for f in (0, 1, 2, 4, 6, 9, 13, 18, 24, 30)]),
    ("Burn", "Burn (Fire): embers rising", [0.0, 0.05, 0.2, 0.5, 0.9, 1.4, 2.0, 2.6, 3.0, 3.4]),
    ("Freeze", "Chill, then Freeze (Frost)", [0.05, 0.3, 0.85, 1.7, 2.43, 2.5, 3.5, 4.47, 4.6, 4.78]),
    ("Shock", "Shock (Storm): crackling light", [0.0, 0.017, 0.033, 0.25, 0.4, 0.72, 1.12, 1.47, 1.92, 2.72]),
    ("Sap", "Sap (Void): dark motes sinking", [0.05, 0.3, 0.7, 1.2, 1.8, 2.5, 3.2, 3.8, 4.3, 4.8]),
]
ELEMENT = {"Hit": "Hit", "Burn": "Fire", "Freeze": "Frost", "Shock": "Storm", "Sap": "Void"}


def hexrgb(code):
    return np.array([int(code[i:i + 2], 16) / 255 for i in (1, 3, 5)], dtype=np.float32)


def luma(c):
    return float(0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2])


def palette(element, grey):
    cols = [hexrgb(c) for c in (*COLOURS[element], DUST)]
    if grey:
        cols = [np.full(3, luma(c), dtype=np.float32) for c in cols]
    return dict(zip(("core", "body", "rim", "glow", "dust"), cols))


def clamp(u, lo=0.0, hi=1.0):
    return min(hi, max(lo, u))


def back_out(u):
    u = clamp(u) - 1
    return 1 + 2.70158 * u ** 3 + 1.70158 * u ** 2


def quart_out(u):
    return 1 - (1 - clamp(u)) ** 4


# --- a body's phase: its scene, its plates, its ice, its surface -----------------------------------------------------

def render(scene, out, name):
    path = out / f"_{name}.png"
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    img = rs.load(path)
    path.unlink()
    return img


def surface(objects):
    """Points on the body's faces, area-weighted, with their normals (world, studs)."""
    dg = bpy.context.evaluated_depsgraph_get()
    pts, nrm, area, verts = [], [], [], []
    for obj in objects:
        eo = obj.evaluated_get(dg)
        me = eo.to_mesh()
        m = obj.matrix_world
        k = sum(abs(s) for s in m.to_scale()) / 3
        for p in me.polygons:
            pts.append(tuple(m @ p.center))
            nrm.append(tuple((m.to_3x3() @ p.normal).normalized()))
            area.append(p.area * k * k)
        verts.extend(tuple(m @ v.co) for v in me.vertices)
        eo.to_mesh_clear()
    return np.array(pts), np.array(nrm), np.array(area), np.array(verts)


class Ice:
    """The frost's sleeve, the shell and its chips, set for a time t. Chill: a sleeve of ice round the legs, its top a
    crown of teeth, climbing a step a frost hit (LEVELS). Freeze: the shell snaps up out of it and shut."""

    def __init__(self, scene, surf, bounds, rng):
        self.mats = {k: r6.flat_material(f"Ice.{k}", (0.92, 0.94, 0.96)) for k in ("fill", "edge", "shard")}
        pts, nrm, _, verts = surf
        (x0, y0, z0), (x1, y1, z1) = bounds
        self.centre = Vector(((x0 + x1) / 2, (y0 + y1) / 2, 0.0))
        low = verts[verts[:, 2] < LEVELS[3] + 0.2]
        lx0, ly0, _ = low.min(0)
        lx1, ly1, _ = low.max(0)
        self.leg_centre = Vector(((lx0 + lx1) / 2, (ly0 + ly1) / 2, 0.0))
        lrx, lry = (lx1 - lx0) / 2 + 0.22, (ly1 - ly0) / 2 + 0.22
        teeth, foot, crown = 16, [], []
        for k in range(teeth):
            a = 2 * math.pi * (k + rng.uniform(-0.2, 0.2)) / teeth
            c, sn = math.cos(a), math.sin(a)
            foot.append(Vector((c * lrx * 1.08, sn * lry * 1.08, 0.0)))
            h = rng.uniform(1.05, 1.2) if k % 2 == 0 else rng.uniform(0.72, 0.85)
            crown.append(Vector((c * lrx * rng.uniform(0.97, 1.03), sn * lry * rng.uniform(0.97, 1.03), h)))
        faces = [[foot[k], foot[(k + 1) % teeth], crown[(k + 1) % teeth], crown[k]] for k in range(teeth)]
        self.sleeve = self.mesh("Ice.Sleeve", faces, self.mats["fill"])
        self.sleeve_edges = self.mesh("Ice.SleeveEdges", faces, self.mats["edge"])
        wire = self.sleeve_edges.modifiers.new("Wire", "WIREFRAME")
        wire.thickness, wire.use_replace = 0.06, True
        for obj in (self.sleeve, self.sleeve_edges):
            obj.location = self.leg_centre
        # the shell: seven sides, four rings and a point, jittered into facets, its foot on the street
        self.rx, self.ry, self.top = (x1 - x0) / 2 + 0.35, (y1 - y0) / 2 + 0.45, z1 + 0.35
        rings = ((0.0, 0.92), (0.2, 1.0), (0.55, 1.05), (0.84, 0.88))
        seg = 7
        self.ring_pts = []
        for h, r in rings:
            row = []
            for s in range(seg):
                a = 2 * math.pi * (s + rng.uniform(-0.15, 0.15)) / seg + (0.5 if len(self.ring_pts) % 2 else 0.0)
                k = r * rng.uniform(0.92, 1.06)
                row.append(Vector((math.cos(a) * self.rx * k, math.sin(a) * self.ry * k, h * self.top * rng.uniform(0.97, 1.02) if h else 0.0)))
            self.ring_pts.append(row)
        self.apex = Vector((rng.uniform(-0.1, 0.1), rng.uniform(-0.1, 0.1), self.top))
        self.quads = []
        for r in range(len(rings) - 1):
            for s in range(seg):
                a, b = self.ring_pts[r][s], self.ring_pts[r][(s + 1) % seg]
                c, d = self.ring_pts[r + 1][(s + 1) % seg], self.ring_pts[r + 1][s]
                self.quads.append([a, b, c, d])
        for s in range(seg):
            self.quads.append([self.ring_pts[-1][s], self.ring_pts[-1][(s + 1) % seg], self.apex])
        self.shell = self.mesh("Ice.Shell", self.quads, self.mats["fill"])
        self.edges = self.mesh("Ice.Edges", self.quads, self.mats["edge"])
        wire = self.edges.modifiers.new("Wire", "WIREFRAME")
        wire.thickness, wire.use_replace = 0.07, True
        for obj in (self.shell, self.edges):
            obj.location = self.centre
        self.chips = []
        for q in self.quads:
            mid = sum(q, Vector()) / len(q)
            obj = self.mesh(f"Ice.Chip{len(self.chips)}", [[v - mid for v in q]], self.mats["shard"])
            n = (q[1] - q[0]).cross(q[-1] - q[0]).normalized()
            if n.dot(Vector((mid.x, mid.y, 0))) < 0:
                n = -n
            v = n * rng.uniform(3.0, 5.0) + Vector((0, 0, rng.uniform(1.5, 3.0)))
            axis = Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(-1, 1))).normalized()
            self.chips.append((obj, self.centre + mid, v, axis, math.radians(rng.uniform(360, 720))))
        self.flash = False

    def mesh(self, name, faces, material):
        bm = bmesh.new()
        for face in faces:
            vs = [bm.verts.new(v) for v in face]
            bm.faces.new(vs)
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        obj = bl.object_from_bmesh(name, bm, material)
        obj.rotation_mode = "QUATERNION"
        return obj

    def set(self, t):
        level = 0.0
        for k, at in enumerate(CHILL):
            if t >= at:
                level = LEVELS[k] + (LEVELS[k + 1] - LEVELS[k]) * back_out((t - at) / 0.15)
        shown = bool(level > 0.02 and t < FREEZE)
        for obj in (self.sleeve, self.sleeve_edges):
            obj.hide_render = not shown
            obj.scale = (1.0, 1.0, max(level, 0.01))
        u = (t - FREEZE) / SHUT
        on = bool(FREEZE <= t < THAW)
        g = quart_out(u)
        z = LEVELS[3] / self.top + (1 - LEVELS[3] / self.top) * g
        xy = 0.85 + 0.15 * g
        for obj in (self.shell, self.edges):
            obj.hide_render = bool(not on)
            obj.scale = (xy, xy, z)
        self.flash = bool(FREEZE + SHUT <= t < FREEZE + SHUT + 2 / 60)
        tau = t - THAW
        for obj, c0, v, axis, spin in self.chips:
            obj.hide_render = bool(not 0 <= tau < SHATTER)
            if not obj.hide_render:
                obj.location = c0 + v * tau + Vector((0, 0, -0.5 * 25.0 * tau * tau))
                obj.rotation_quaternion = Quaternion(axis, spin * tau)
                k = 0.55 * (1 - (tau / SHATTER) ** 2)          # a facet breaks to a chip about half its size
                obj.scale = (k, k, k)
        return bool(shown or on or 0 <= tau < SHATTER)

    def key(self, ids):
        for k, mat in self.mats.items():
            mat.diffuse_color = (*ids[k], 1.0) if ids else (0.92, 0.94, 0.96, 1.0)

    def keyed(self):
        """Each ice object with its key, for the ID pass by object colour."""
        out = [(self.sleeve, "fill"), (self.shell, "fill"), (self.sleeve_edges, "edge"), (self.edges, "edge")]
        return out + [(obj, "shard") for obj, *_ in self.chips]


ID = {"fill": (1.0, 0.0, 1.0), "edge": (0.0, 1.0, 0.0), "shard": (1.0, 1.0, 0.0)}


def phase(name, out, times):
    offset = SPOTS[name]
    if name == "Shade":
        scene, rig, *_ = sc.build()
    else:
        scene, rig, *_ = rc.build()
    scene.frame_set(0)
    bpy.context.view_layer.update()
    scene.render.resolution_x, scene.render.resolution_y = W, H
    scene.render.use_stamp = False
    body = [o for o in scene.objects if o.type == "MESH" and not o.hide_render and o.name != "Floor"]
    floor = bpy.data.objects["Floor"]
    floor.scale = (14, 14, 1)
    floor.data.materials[0].diffuse_color = PAVING
    shading = scene.display.shading
    shading.background_color = SKY
    scene.world.color = SKY
    grey = r6.flat_material("Fx.Lead", (0.36, 0.36, 0.38))
    lead = []
    for part, size, z in (("Legs", (1.9, 0.95, 2.0), 1.0), ("Chest", (2.0, 1.0, 2.0), 3.0), ("Head", (1.2, 1.2, 1.1), 4.6),
                          ("Arms", (4.0, 0.95, 0.9), 3.5)):
        box = bl.box(f"Fx.Lead.{part}", size, grey)
        box.location = (LEAD[0] - offset, LEAD[1], z)
        lead.append(box)
    cam = hx.camera(scene, "game", VIEW["azimuth"], VIEW["elevation"], VIEW["distance"], VIEW["focus"], VIEW["fov"])
    cam.location.x -= offset
    scene.camera = cam
    bpy.context.view_layer.update()
    surf = surface(body)
    v = surf[3]
    bounds = (tuple(v.min(0)), tuple(v.max(0)))
    rng = random.Random(48 + len(name))
    ice = Ice(scene, surf, bounds, rng)
    ice.set(-1.0)
    plates = {"plate": render(scene, out, f"{name}_plate")}
    keep = {o: o.hide_render for o in body}
    for o in body:
        o.hide_render = True
    plates["floor"] = render(scene, out, f"{name}_floor")
    for o, h in keep.items():
        o.hide_render = h
    scene.render.film_transparent = True
    floor.hide_render = True
    for b in lead:
        b.hide_render = True
    plates["mask"] = render(scene, out, f"{name}_mask")[..., 3]
    for o in body:
        o.hide_render = True
    for b in lead:
        b.hide_render = False
    plates["lead"] = render(scene, out, f"{name}_lead")[..., 3]
    for o, h in keep.items():
        o.hide_render = h
    floor.hide_render = False
    scene.render.film_transparent = False
    ices = {}
    for t in times:
        if not ice.set(t):
            continue
        ice.key(None)
        lit = render(scene, out, f"{name}_ice_lit")
        # the ID pass by object colour: every ice object in its key, everything else black, so a pixel's keys unmix
        # (an edge thinner than a pixel is a blend of its key and the fill's, which matched neither key)
        saved = (shading.light, shading.show_cavity, shading.show_shadows, shading.show_object_outline,
                 shading.show_specular_highlight, shading.color_type, tuple(scene.world.color))
        shading.light, shading.show_cavity, shading.show_shadows = "FLAT", False, False
        shading.show_object_outline, shading.show_specular_highlight = False, False
        shading.color_type, scene.world.color = "OBJECT", (0.0, 0.0, 0.0)
        colours = {o: tuple(o.color) for o in scene.objects}
        for o in scene.objects:
            o.color = (0.0, 0.0, 0.0, 1.0)
        for o, k in ice.keyed():
            o.color = (*ID[k], 1.0)
        ids = render(scene, out, f"{name}_ice_id")
        for o, c in colours.items():
            o.color = c
        (shading.light, shading.show_cavity, shading.show_shadows, shading.show_object_outline,
         shading.show_specular_highlight, shading.color_type) = saved[:6]
        scene.world.color = saved[6]
        ices[t] = (lit[..., :3], ids[..., :3], ice.flash)
    m = cam.matrix_world
    camera = dict(eye=np.array(m.translation), R=np.array(m.to_3x3()), f=(H / 2) / math.tan(cam.data.angle_y / 2))
    return dict(name=name, plates=plates, ices=ices, surf=surf, bounds=bounds, camera=camera)


# --- projection and drawing ------------------------------------------------------------------------------------------

def project(camera, p):
    c = (np.asarray(p, dtype=np.float64) - camera["eye"]) @ camera["R"]
    depth = -c[..., 2]
    return np.stack([W / 2 + camera["f"] * c[..., 0] / depth, H / 2 - camera["f"] * c[..., 1] / depth], -1), depth


def px_per_stud(camera, depth):
    return camera["f"] / depth


def seg_field(box, pts):
    """Distance from each pixel of `box` to the polyline `pts` (px)."""
    x0, y0, x1, y1 = box
    ys, xs = np.mgrid[y0:y1, x0:x1].astype(np.float32) + 0.5
    d = np.full(xs.shape, 1e9, dtype=np.float32)
    if len(pts) == 1:
        pts = [pts[0], pts[0]]
    for a, b in zip(pts[:-1], pts[1:]):
        ab = b - a
        l2 = max(float(ab @ ab), 1e-6)
        t = np.clip(((xs - a[0]) * ab[0] + (ys - a[1]) * ab[1]) / l2, 0, 1)
        d = np.minimum(d, np.hypot(xs - (a[0] + t * ab[0]), ys - (a[1] + t * ab[1])))
    return d, ys, xs


def bbox(pts, reach):
    pts = np.asarray(pts)
    x0, y0 = np.floor(pts.min(0) - reach).astype(int)
    x1, y1 = np.ceil(pts.max(0) + reach).astype(int)
    return max(x0, 0), max(y0, 0), min(x1, W), min(y1, H)


def over(img, box, alpha, colour):
    x0, y0, x1, y1 = box
    a = alpha[..., None]
    img[y0:y1, x0:x1] = img[y0:y1, x0:x1] * (1 - a) + colour * a


def add(img, box, amount, colour):
    x0, y0, x1, y1 = box
    img[y0:y1, x0:x1] = img[y0:y1, x0:x1] + colour * amount[..., None]


def bright(img, pts, r, k, pal, glow=3.0, rim=True, core=0.5):
    """A lit stroke: a dark rim (it holds on a bright floor), the glow, the body, the hot core."""
    box = bbox(pts, r + glow * 3 + 2)
    if box[2] <= box[0] or box[3] <= box[1]:
        return
    d, _, _ = seg_field(box, pts)
    if rim:
        over(img, box, np.clip(r + 1.6 - d, 0, 1) * 0.55 * min(k, 1), pal["rim"])
    add(img, box, np.exp(-(d / glow) ** 2) * 0.35 * k, pal["glow"])
    over(img, box, np.clip(r + 0.5 - d, 0, 1) * min(k, 1), pal["body"])
    over(img, box, np.clip(r * core + 0.5 - d, 0, 1) * min(k, 1), pal["core"])


WHITE_HOT = np.ones(3, dtype=np.float32)


def taper(img, head, tail, r, k, pal, glow=3.0):
    """A spark stretched along its flight: widest and white-hot at its head, thinning to an orange tail."""
    box = bbox([head, tail], r + glow * 3 + 2)
    if box[2] <= box[0] or box[3] <= box[1]:
        return
    x0, y0, x1, y1 = box
    ys, xs = np.mgrid[y0:y1, x0:x1].astype(np.float32) + 0.5
    ab = np.asarray(tail, dtype=np.float32) - np.asarray(head, dtype=np.float32)
    l2 = max(float(ab @ ab), 1e-6)
    s = np.clip(((xs - head[0]) * ab[0] + (ys - head[1]) * ab[1]) / l2, 0, 1)    # 0 at the head, 1 at the tail
    d = np.hypot(xs - (head[0] + s * ab[0]), ys - (head[1] + s * ab[1]))
    w = r * (1 - s) ** 0.8                     # a needle: no round head, thinning to nothing at the tail
    a = min(k, 1)
    over(img, box, np.clip(w + 1.0 - d, 0, 1) * 0.35 * a, pal["rim"])
    add(img, box, np.exp(-(d / glow) ** 2) * 0.3 * k * (1 - 0.6 * s), pal["glow"])
    over(img, box, np.clip(w + 0.5 - d, 0, 1) * a, pal["body"])
    over(img, box, np.clip(w * 0.6 + 0.5 - d, 0, 1) * a * (1 - s) ** 0.5, pal["core"])
    over(img, box, np.clip(w * 0.4 + 0.5 - d, 0, 1) * a * np.clip(1 - 1.6 * s, 0, 1), WHITE_HOT)


def mote(img, head, tail, r, a, pal):
    """A dark mote: its body, and a thin violet rim on its top only."""
    box = bbox([head, tail], r + 3)
    if box[2] <= box[0] or box[3] <= box[1]:
        return
    d, ys, _ = seg_field(box, [tail, head])
    over(img, box, np.clip(r + 0.5 - d, 0, 1) * a, pal["body"])
    top = np.clip((min(head[1], tail[1]) + r * 0.4 - ys) / max(r, 1.0) + 0.2, 0, 1)
    over(img, box, np.clip(1 - np.abs(d - r) / 0.9, 0, 1) * top * a * 0.9, pal["rim"])


def soft(img, centre, r, a, colour, additive=False):
    box = bbox([centre], r * 2.5)
    if box[2] <= box[0] or box[3] <= box[1]:
        return
    d, _, _ = seg_field(box, [centre])
    if additive:
        add(img, box, np.exp(-(d / r) ** 2) * a, colour)
    else:
        over(img, box, np.clip(1 - d / r, 0, 1) ** 1.5 * a, colour)


# --- the cues, as 3D primitives at a time t, for one body -----------------------------------------------------------

def area_pick(surf, rng, ok, n):
    pts, nrm, area, _ = surf
    idx = np.nonzero(ok)[0]
    w = area[idx] / area[idx].sum()
    return idx[np.asarray(rng.choice(len(idx), size=n, p=w))]


class Cues:
    def __init__(self, body):
        self.body = body
        surf = body["surf"]
        pts, nrm, area, verts = surf
        (x0, y0, z0), (x1, y1, z1) = body["bounds"]
        self.top, self.mid = z1, np.array([(x0 + x1) / 2, (y0 + y1) / 2])
        self.r = np.array([(x1 - x0) / 2, (y1 - y0) / 2])
        g = np.random.default_rng(480 + len(body["name"]))
        front = (np.abs(pts[:, 2] - 0.55 * z1) < 0.6) & (nrm[:, 1] > 0.3)
        self.hit = pts[front][np.argmax(pts[front][:, 1] - 0.3 * np.abs(pts[front][:, 0] - self.mid[0]))] + [0, 0.1, 0]
        # the plain hit's sparks, along the blow (the lead strikes from in front, +y), and its dust
        axis = np.array([0.0, -1.0, 0.2])
        self.sparks = []
        for _ in range(8):
            d = axis + g.normal(0, 0.55, 3) * [1, 0.2, 0.8]
            self.sparks.append((d / np.linalg.norm(d) * g.uniform(22, 34), g.uniform(0.22, 0.32)))
        self.dust = [(g.normal(0, 1, 3) * [1.2, 0.4, 0.6] + [0, -0.6, 0.4], g.uniform(0.3, 0.45)) for _ in range(4)]
        # Burn: tapered sparks born off the shoulders' tops and at the hit, never on a face (research, 00:13: round
        # dots over the body read as a rash), rising past the head; one in seven larger
        # The head's column (its half-width, from the points above the neck) stays clear: births outside it, and every
        # spark drifts outward, away from the face, as it climbs.
        head = pts[:, 2] > 0.84 * z1
        self.head_w = float(np.abs(pts[head, 0] - self.mid[0]).max()) if head.any() else 0.6
        lateral = pts[:, 0] - self.mid[0]
        shoulder = (nrm[:, 2] > 0.5) & (pts[:, 2] > 0.55 * z1) & (pts[:, 2] < 0.82 * z1) & \
                   (np.abs(lateral) > self.head_w + 0.1)
        if not shoulder.any():
            shoulder = (nrm[:, 2] > -0.3) & (pts[:, 2] > 0.5 * z1) & (pts[:, 2] < 0.8 * z1) & \
                       (np.abs(lateral) > self.head_w + 0.1)
        n = int(18 * BURN)
        idx = area_pick(surf, g, shoulder, n)
        self.embers = []                                     # (born, p0, v0, life, size, phase, side, lift)
        for k, i in enumerate(idx):
            at_hit = k % 5 < 2                               # two in five from the hit's own spot, peeling off sideways
            side = (1.0 if k % 2 else -1.0) if at_hit else float(np.sign(lateral[i]) or 1.0)
            if at_hit:
                p0 = self.hit + g.normal(0, 0.08, 3) + [side * 0.25, 0.1, 0]
                v0, lift = np.array([side * g.uniform(1.8, 2.6), g.uniform(0.2, 0.5), 0.0]), 0.3
            else:
                p0, v0, lift = pts[i] + nrm[i] * 0.12, nrm[i] * 0.3 + [side * 0.3, 0, 0], 1.6
            size = g.uniform(0.06, 0.08) * (1.7 if g.random() < 0.15 else 1.0)
            self.embers.append((g.uniform(0, BURN), p0, v0, g.uniform(0.8, 1.2), size, g.uniform(0, 6.28), side, lift))
        for k in range(10):                                  # the catch: a fan out to both sides, never up the face
            side = 1.0 if k % 2 else -1.0
            d = np.array([side * g.uniform(1.0, 1.8), g.uniform(0.0, 0.6), g.uniform(0.2, 0.8)])
            self.embers.append((g.uniform(0, 0.03), self.hit + [side * 0.15, 0.1, 0], d / np.linalg.norm(d) * 2.6,
                                g.uniform(0.45, 0.7), g.uniform(0.08, 0.1), g.uniform(0, 6.28), side, 0.0))
        # Sap: births in the air round the upper body, circling in and sinking slowly, never falling (the content
        # check, 2026-11-20: a dark mote that drops under gravity and stretches reads as a drip)
        self.motes = []
        for k in range(int(12 * SAP) + 6):
            born = 0.0 if k < 6 else g.uniform(0, SAP)
            a = g.uniform(0, 2 * math.pi)
            rr = self.r + g.uniform(0.15, 0.55)
            z0 = g.uniform(0.6, 0.95) * z1
            self.motes.append((born, a, rr, z0, g.uniform(1.3, 2.0), g.uniform(0.11, 0.16)))
        # Shock: arcs between nearby points on the body
        body_only = (pts[:, 2] > 0.6) & (pts[:, 2] < 0.8 * z1)       # the arcs' ends on the body, under the head
        self.arc_pts = pts[body_only]
        self.arc_nrm = nrm[body_only]

    def at(self, cue, t):
        return self.plain(t) if cue == "Hit" else getattr(self, cue.lower())(t)

    def plain(self, t):
        prims = []
        if t < 2 / 60:
            prims.append(("star", self.hit, 1.0, 1.0))
        if t < 8 / 60:
            prims.append(("glow", self.hit, 1.1, 0.7 * (1 - t / (8 / 60)) ** 2))
        for v, life in self.sparks:
            if t < life:
                k = 9.0
                p = self.hit + v * (1 - math.exp(-k * t)) / k
                vel = v * math.exp(-k * t)
                tail = p - vel * 0.035
                fade = 1 - clamp((t / life - 0.6) / 0.4) ** 2
                prims.append(("streak", p, tail, 0.06, fade))
        for v, life in self.dust:
            if 2 / 60 <= t < life + 2 / 60:
                u = (t - 2 / 60) / life
                prims.append(("puff", self.hit + v * 0.6 * (1 - (1 - u) ** 2), 0.3 + 0.5 * u, 0.35 * (1 - u)))
        return prims

    def burn(self, t):
        prims = []
        for born, p0, n0, life, r0, ph, side, lift in self.embers:
            age = t - born
            if not 0 <= age < life or born > BURN:
                continue
            p, v = np.array(p0, dtype=np.float64), np.array(n0) + [0, 0, lift]
            dt = 1 / 120
            for s in range(int(age / dt)):
                a = s * dt
                acc = np.array([0.6 * math.sin(7 * a + ph) + 0.7 * side, 0.6 * math.cos(6 * a + ph),
                                4.0 * math.exp(-a / 0.4)]) - v * 1.4
                v = v + acc * dt
                p = p + v * dt
            u = age / life
            r = r0 * (1 - u ** 1.5)
            flicker = 0.55 + 0.45 * abs(math.sin(2 * math.pi * 11 * age + ph) * math.sin(2 * math.pi * 7 * age + 2 * ph))
            k = flicker * (1 - u ** 3) * clamp(age / 0.05)
            prims.append(("taper", p, p - v * 0.16, r, k))       # stretched along its rise
        return prims

    def freeze(self, t):
        return []  # geometry: the ice pass

    def shock(self, t):
        prims = []
        for b, tb in enumerate(SHOCK):
            f = int(round((t - tb) * 60))
            if not 0 <= f < 3 or t < tb:
                continue
            g = np.random.default_rng(1000 * b + 7 + len(self.body["name"]))
            jit = np.random.default_rng(1000 * b + 31 * f + len(self.body["name"]))
            # one big arc a burst, jumping between two far points of the body, and one or two smaller (research,
            # 00:13: arcs two to three times longer, a white core in the pink glow, read at 64 pixels)
            arcs = [(1.6, 2.6, 0.085, 0.32, 11, True)]
            arcs += [(0.9, 1.6, 0.05, 0.18, 9, False)] * (2 if b == 0 else int(g.integers(1, 3)))
            for lo, hi, width, lift, steps, big in arcs:
                i = int(g.integers(len(self.arc_pts)))
                p0, n0 = self.arc_pts[i], self.arc_nrm[i]
                d = np.linalg.norm(self.arc_pts - p0, axis=1)
                near = np.nonzero((d > lo) & (d < hi))[0]
                if not len(near):
                    continue
                j = int(near[g.integers(len(near))])
                p1, n1 = self.arc_pts[j], self.arc_nrm[j]
                span = float(d[j])
                path = []
                for s in np.linspace(0, 1, steps):
                    nn = n0 * (1 - s) + n1 * s
                    off = nn * (0.08 + lift * math.sin(math.pi * s))   # leaping off the body between its two points
                    if 0 < s < 1:
                        off = off + jit.normal(0, 0.07 * span, 3)
                    path.append(p0 * (1 - s) + p1 * s + off)
                k = (1.0, 0.75, 0.45)[f]
                prims.append(("arc", path, width, k, 6.0 if big else 4.0))
                prims.append(("glow", path[0], 0.35 if big else 0.22, 0.7 * k))    # a soft contact, no cross: the
                prims.append(("glow", path[-1], 0.35 if big else 0.22, 0.7 * k))  # crosses read as stitches
        return prims

    def sap(self, t):
        prims = []
        for born, a0, rr, z0, life, r0 in self.motes:
            age = t - born
            if not 0 <= age < life or born > SAP:
                continue
            u = age / life
            g = 1 - (1 - u) ** 2                                   # easing out: the sink slows, never speeds up
            a = a0 + 1.1 * age                                     # circling the body
            k = 1 - 0.35 * g                                       # and drawn in toward it
            p = np.array([self.mid[0] + math.cos(a) * rr[0] * k, self.mid[1] + math.sin(a) * rr[1] * k,
                          z0 - 0.22 * self.top * g])               # gone above the knees
            r = r0 * clamp(age / 0.12) * (1 - clamp((u - 0.5) / 0.5)) ** 0.7   # in, held, then shrinking to a point
            if r > 0.01:
                prims.append(("mote", p, p, r, 0.92))              # a round mote, no streak
        return prims


def draw(img, body, prims, pal, masks):
    camera = body["camera"]
    for prim in prims:
        kind = prim[0]
        centre = prim[1] if kind != "arc" else prim[1][len(prim[1]) // 2]
        xy, depth = project(camera, centre)
        x, y = int(xy[0]), int(xy[1])
        if not (0 <= x < W and 0 <= y < H):
            continue
        if any(m[y, x] > 0.5 and depth > dm + margin for m, dm, margin in masks):
            continue
        s = px_per_stud(camera, depth)
        if kind == "streak":
            (a, _), (b, _) = project(camera, prim[1]), project(camera, prim[2])
            bright(img, [a, b], max(prim[3] * s, 0.6), prim[4], pal)
        elif kind == "taper":
            (a, _), (b, _) = project(camera, prim[1]), project(camera, prim[2])
            taper(img, a, b, max(prim[3] * s, 0.7), prim[4], pal)
        elif kind == "arc":
            pts = [project(camera, p)[0] for p in prim[1]]
            bright(img, pts, max(prim[2] * s, 0.6), prim[3], pal, glow=prim[4], core=0.62)
        elif kind == "star":
            arm = prim[2] * s
            for d in ((arm, 0), (0, arm)):
                bright(img, [xy - d, xy + d], max(0.05 * s, 0.7), prim[3], pal, glow=2.5, rim=False)
        elif kind == "glow":
            soft(img, xy, prim[2] * s, prim[3], pal["glow"], additive=True)
        elif kind == "puff":
            soft(img, xy, prim[2] * s, prim[3], pal["dust"])
        elif kind == "mote":
            (a, _), (b, _) = project(camera, prim[1]), project(camera, prim[2])
            mote(img, a, b, max(prim[3] * s, 0.8), prim[4], pal)


def blur(a, r):
    for axis in (0, 1):
        for _ in range(3):
            c = np.cumsum(np.pad(a, [(r + 1, r) if k == axis else (0, 0) for k in range(a.ndim)], mode="edge"), axis=axis)
            a = (np.take(c, range(2 * r + 1, c.shape[axis]), axis=axis) - np.take(c, range(0, c.shape[axis] - 2 * r - 1), axis=axis)) / (2 * r + 1)
    return a


def keys(ids):
    """The ice's three keys from the ID pass (fill magenta, edge green, shard yellow, the rest black), unmixed in
    linear light: fill is blue, shard is red less blue, edge is green less shard."""
    lin = np.where(ids <= 0.04045, ids / 12.92, ((ids + 0.055) / 1.055) ** 2.4)
    r, g, b = lin[..., 0], lin[..., 1], lin[..., 2]
    shard = np.clip(r - b, 0, 1)
    return np.clip(b, 0, 1), np.clip(g - shard, 0, 1), shard


def lay_ice(img, lit, ids, flash, pal, t):
    fill, edge, shard = keys(ids)
    lum = lit @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)
    u = np.clip((lum - 0.35) / 0.6, 0, 1)[..., None]
    ramp = np.where(u < 0.6, pal["rim"] + (pal["body"] - pal["rim"]) * (u / 0.6),
                    pal["body"] + (pal["core"] - pal["body"]) * ((u - 0.6) / 0.4))
    af = np.clip(fill * 0.42 + shard * 0.65, 0, 1)[..., None]
    out = img * (1 - af) + ramp * af
    lit_edge = pal["core"] if flash else pal["body"] * 0.35 + pal["core"] * 0.65
    ae = (edge * 0.95)[..., None]
    out = out * (1 - ae) + lit_edge * ae
    if FREEZE + SHUT <= t < THAW and fill.any():  # the hold: a glint line crossing the shell, bottom to top
        ys = np.nonzero(fill.max(1) > 0.5)[0]
        yc = ys.max() + (ys.min() - ys.max()) * clamp((t - FREEZE - SHUT) / (THAW - FREEZE - SHUT))
        band = np.exp(-((np.arange(H) - yc) / 5.0) ** 2)[:, None]
        out = out + (pal["core"] * 0.3) * (fill * band)[..., None]
    glow = blur(edge, 3)[..., None] * (0.9 if flash else 0.25)
    return out + pal["glow"] * glow


# --- the sheet -------------------------------------------------------------------------------------------------------

def keep(body, path):
    ts = sorted(body["ices"])
    np.savez(path, name=body["name"], **{f"plate_{k}": v for k, v in body["plates"].items()},
             ice_times=np.array(ts), ice_lit=np.array([body["ices"][t][0] for t in ts], np.float16),
             ice_ids=np.array([body["ices"][t][1] for t in ts], np.float16),
             ice_flash=np.array([body["ices"][t][2] for t in ts]), pts=body["surf"][0], nrm=body["surf"][1],
             area=body["surf"][2], verts=body["surf"][3], bounds=np.array(body["bounds"]),
             eye=body["camera"]["eye"], R=body["camera"]["R"], f=body["camera"]["f"])


def fetch(path):
    z = np.load(path)
    lit, ids, flash = z["ice_lit"], z["ice_ids"], z["ice_flash"]  # each read once: a key read again re-reads its file
    ices = {float(t): (lit[i], ids[i], bool(flash[i])) for i, t in enumerate(z["ice_times"])}
    return dict(name=str(z["name"]), plates={k: z[f"plate_{k}"] for k in ("plate", "floor", "mask", "lead")},
                ices=ices, surf=(z["pts"], z["nrm"], z["area"], z["verts"]),
                bounds=tuple(tuple(b) for b in z["bounds"]), camera=dict(eye=z["eye"], R=z["R"], f=float(z["f"])))


def lettered(sheet, words, band=360):
    """The sheet's words, drawn a band at a time: one text render at the sheet's whole size outgrew the PC's free
    memory beside the Studios (2026-11-19, 23:15)."""
    height, width = sheet.shape[:2]
    for top in range(0, height, band):
        items = [(x, y - top, size, text, code) for x, y, size, text, code in words if top <= y < top + band]
        if items:
            rs.paste(sheet, rs.text_layer(width, band + 40, items), 0, top)


def main():
    out = bl.out_dir()
    rs.OUT = out
    step = sys.argv[sys.argv.index("--") + 2]
    times = sorted({t for cue, _, ts in ROWS if cue == "Freeze" for t in ts})
    if step in SPOTS:
        keep(phase(step, out, times), out / f"_{step}.npz")
        print(f"kept {step}'s plates")
        return
    bodies = [fetch(out / f"_{name}.npz") for name in SPOTS]
    shade, rook = bodies
    # one view: the Shade's frame, Rook's shadow carried over by its plate against its bare floor, then Rook
    base = shade["plates"]["plate"][..., :3].copy()
    rp, rf, rm = rook["plates"]["plate"][..., :3], rook["plates"]["floor"][..., :3], rook["plates"]["mask"]
    off = (rm < 0.5) & (shade["plates"]["mask"] < 0.5)
    ratio = np.clip(rp / np.maximum(rf, 1e-3), 0, 1.2)
    base[off] = base[off] * ratio[off]
    base = base * (1 - rm[..., None]) + rp * rm[..., None]
    masks = []
    for b in bodies:
        _, d = project(b["camera"], [b["bounds"][0][0] / 2 + b["bounds"][1][0] / 2,
                                      b["bounds"][0][1] / 2 + b["bounds"][1][1] / 2, 2.5])
        masks.append((b["plates"]["mask"], d, 0.3))
    lead_xy, lead_d = project(shade["camera"], [LEAD[0] - SPOTS["Shade"], LEAD[1], 3.0])
    masks.append((shade["plates"]["lead"], lead_d, 0.0))
    # the tile: both bodies, room over their heads for the embers, a little floor
    m = (shade["plates"]["mask"] > 0.1) | (rm > 0.1)
    ys, xs = np.nonzero(m)
    s = (ys.max() - ys.min()) / max(shade["bounds"][1][2], rook["bounds"][1][2])
    tile = (int(xs.min() - 1.3 * s), int(ys.min() - 1.9 * s), int(xs.max() + 1.3 * s), int(ys.max() + 0.7 * s))
    tile = (max(tile[0], 0), max(tile[1], 0), min(tile[2], W), min(tile[3], H))
    tw, th = tile[2] - tile[0], tile[3] - tile[1]
    print(f"the tile: {tw} x {th} px of the phone's 852 x 480; {s:.1f} px a stud")
    cues = [Cues(b) for b in bodies]
    on_body = np.maximum(shade["plates"]["mask"], rm) > 0.5
    frames, counts = {}, {}
    for cue, _, ts in ROWS:
        for grey in (True, False):
            pal = palette(ELEMENT[cue], grey)
            for t in ts:
                img = base.copy()
                if cue == "Freeze":
                    for b in bodies:
                        hit = [k for k in b["ices"] if abs(k - t) < 1e-6]
                        if hit:
                            lit, ids, flash = b["ices"][hit[0]]
                            lit, ids = lit.astype(np.float32), ids.astype(np.float32)
                            ice = lay_ice(img, lit, ids, flash, pal, t)
                            fill, edge, shard = keys(ids)
                            k = np.clip(fill + edge + shard, 0, 1)
                            k = np.maximum(k, blur(edge, 3) * 3).clip(0, 1)[..., None]
                            img = img * (1 - k) + ice * k
                for b, c in zip(bodies, cues):
                    draw(img, b, c.at(cue, t), pal, masks)
                img = img.clip(0, 1)
                frames[(cue, grey, t)] = img[tile[1]:tile[3], tile[0]:tile[2]].copy()  # a copy: a view keeps the whole frame
                diff = np.abs(img - base).max(-1) >= 40 / 255
                sub = (slice(tile[1], tile[3]), slice(tile[0], tile[2]))
                counts[(cue, grey, t)] = (int((diff & ~on_body)[sub].sum()), int((diff & on_body)[sub].sum()))
    # the strip sheet: per cue a grey row, then its colour row; every tile at the phone's own pixels
    gap, head, stamp, margin = 6, 24, 18, 16
    cols = max(len(ts) for _, _, ts in ROWS)
    width = margin * 2 + cols * tw + (cols - 1) * gap
    title = 64
    row_h = head + stamp + th + 12
    height = title + row_h * len(ROWS) * 2 + 110
    sheet = rs.canvas(width, height, tuple(hexrgb("#101117")))
    words = [(margin, 14, 22, "AR48: the element states' cues, a grey block-in, then colour, on the Shade (left) and "
                              "Rook (right), the player's camera, Lantern Row's paving by day", "#EDE6D6"),
             (margin, 42, 15, "Every tile is the smallest phone's own pixels (852 x 480, 1.5 a point). Times in seconds "
                              "from the hit that causes the state; the hit's row in frames at 60.", "#A9A398")]
    y = title
    for cue, name, ts in ROWS:
        for grey in (True, False):
            words.append((margin, y + 4, 16, f"{name}, {'grey' if grey else 'colour'}", "#EDE6D6"))
            for i, t in enumerate(ts):
                x = margin + i * (tw + gap)
                stamp_t = f"{round(t * 60)} f" if cue == "Hit" else f"{t:.2f} s"
                off_n, on_n = counts[(cue, grey, t)]
                words.append((x, y + head + 1, 12, f"{stamp_t}   off {off_n} on {on_n}", "#8C877E"))
                tile_img = np.concatenate([frames[(cue, grey, t)], np.ones((th, tw, 1), np.float32)], -1)
                rs.paste(sheet, tile_img, x, y + head + stamp)
            y += row_h
    notes = [
        "off / on: pixels 40 levels or more off the plain plate, off the bodies and on them (the handbook's count).",
        "The ice is geometry (the sleeve, the shell's facets, its chips) laid at 0.42 for the fill, 0.65 a chip, 0.95 its edges; "
        "the motes, embers and arcs are drawn from their 3D paths, hidden behind a body or the lead.",
        "Seeds: Burn 3 s at 18 embers a second; Chill three steps 0.8 s apart, Freeze shut in 0.1 s, held 2 s, "
        "shattered in 0.4 s; Shock in bursts of three frames; Sap 4 s at 12 motes a second, circling in, sinking slowly, "
        "round. The builder's numbers rule.",
    ]
    for i, line in enumerate(notes):
        words.append((margin, y + 8 + i * 24, 14, line, "#A9A398"))
    lettered(sheet, words)
    rs.save(sheet, out / "element_states.png")
    # the close: three colour frames a cue at twice the phone's pixels
    picks = {"Hit": (0, 2, 6), "Burn": (2, 4, 7), "Freeze": (3, 5, 7), "Shock": (0, 4, 6), "Sap": (2, 4, 6)}
    cw, ch = tw * 2, th * 2
    close = rs.canvas(margin * 2 + 3 * cw + 2 * gap, title + len(ROWS) * (ch + head + 8), tuple(hexrgb("#101117")))
    words = [(margin, 14, 22, "AR48 up close: colour, twice the phone's pixels", "#EDE6D6")]
    for r, (cue, name, ts) in enumerate(ROWS):
        yy = title + r * (ch + head + 8)
        for c, i in enumerate(picks[cue]):
            t = ts[i]
            img = np.repeat(np.repeat(frames[(cue, False, t)], 2, 0), 2, 1)
            x = margin + c * (cw + gap)
            rs.paste(close, np.concatenate([img, np.ones((ch, cw, 1), np.float32)], -1), x, yy + head)
            words.append((x, yy + 4, 15, f"{name}: {round(t * 60)} f" if cue == "Hit" else f"{name}: {t:.2f} s", "#EDE6D6"))
    lettered(close, words)
    rs.save(close, out / "element_states_close.png")
    del close
    # the thumbnail look: every colour frame 64 pixels across, on the dark
    sw = 64
    sh = round(th * sw / tw)
    thumbs = rs.canvas(margin * 2 + 150 + cols * (sw + gap), title + len(ROWS) * (sh + gap), tuple(hexrgb("#101117")))
    words = [(margin, 14, 20, "AR48 at 64 pixels across, colour, on the dark", "#EDE6D6")]
    for r, (cue, name, ts) in enumerate(ROWS):
        yy = title + r * (sh + gap)
        words.append((margin, yy + sh // 2 - 7, 14, ELEMENT[cue] if cue != "Hit" else "the plain hit", "#A9A398"))
        for i, t in enumerate(ts):
            small = rs.shrink(np.concatenate([frames[(cue, False, t)], np.ones((th, tw, 1), np.float32)], -1), sw / tw)
            rs.paste(thumbs, small, margin + 150 + i * (sw + gap), yy)
    lettered(thumbs, words)
    rs.save(thumbs, out / "element_states_64.png")
    report = {f"{cue} {'grey' if grey else 'colour'} {t:.3f}": v for (cue, grey, t), v in counts.items()}
    (out / "element_states_counts.json").write_text(json.dumps(report, indent=1))
    print(f"wrote {out / 'element_states_counts.json'}")
    for name in SPOTS:
        (out / f"_{name}.npz").unlink()


if __name__ == "__main__":
    main()
