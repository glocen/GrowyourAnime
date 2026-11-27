"""AR69's build drawn from its own rows, in the target's scene (Scintilla, 2026-11-27): a model of the engine for
research's pass before the Studio take, never in place of it.

    blender -b -P tools/blender/ar69_rows.py -- <pose.json> <out_dir> <burn_rows|fall_rows> <times> [heading]

<times> are the target's seconds (ar69_targets.py), 0 where the body goes; the fall's rows start LEAD frames before.
Reads src/shared/Config/EffectRows/StateBurn.json and ShadeFall.json, the kit's meshes (build/handoff/FxKit/meshes/)
and pictures. Writes fx_<t>.exr and light_<t>.exr as ar69_targets.py does, for tools/fx/ar69_sheets.py's compositing.

How the rows are drawn (Rows.luau's rules): a track's value by its keys and eases (Track.luau), none before its first
key; a row's frame its parent's times At, then Spin about Y, then Tilt (X, Y, Z); a Beam from Low to High, facing the
camera, as wide as Width times the scale, its picture's top row at Low; a Mesh the kit's mesh at Size times Scale, its
look's picture tinted by Color and lit by Glow; an emitter's particles from its Emit frames (Lifetime, Speed, Drag,
Size, Transparency, Acceleration; EmissionDirection Top or Front; a VelocityParallel needle as a streak along its
flight, its Squash's stretch approximate). Round 1 (2026-11-27): a beam's Taper, FootFade, Reach and Color, and its
LightEmission as a share of added light over laid-over (Roblox's own blend, approximated). A Ground row at the foot,
lifted by its At's Y, as Rows.luau does since Faber's fix (2026-11-27, 23:5x; before it, the engine dropped the lift). Not
modelled: bloom, which ar69_sheets.py approximates for every layer alike.
"""
import json
import math
import random
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import ar69_targets as T  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
ROWS = ROOT / "src" / "shared" / "Config" / "EffectRows"
KIT = ROOT / "build" / "handoff" / "FxKit"
PICTURES = {"fx_lick_Flame": ROOT / "build" / "handoff" / "ShadeFire" / "pictures" / "fx_lick_Flame.png",
            "fx_rise_Flame": KIT / "images" / "fx_rise_Flame.png", "fx_beam": KIT / "images" / "fx_beam.png"}
KIT_SIZE = {"FxShell": (2, 2, 2), "FxHoop": (2, 0.3, 2), "FxChip1": (1, 0.1424, 0.3469), "FxChip2": (1, 0.1435, 0.3142),
            "FxChip3": (1, 0.1578, 0.3694)}  # Config.FxKit.Meshes' Size
LEAD = 4
TORSO_UP = 0.16  # the Brawler's torso mesh's middle over its root, at scale 1
POWERS = {"Quad": 2, "Cubic": 3, "Quart": 4, "Quint": 5}


# --- the rows' maths (Track.luau) --------------------------------------------------------------------------------------

def eased(style, u):
    if style in POWERS:
        return u ** POWERS[style]
    if style == "Sine":
        return 1 - math.cos(u * math.pi / 2)
    raise ValueError(style)


def ease(name, u):
    x = min(max(u, 0.0), 1.0)
    if name is None or name == "Linear":
        return x
    style, way = name.split(" ")
    if way == "In":
        return eased(style, x)
    if way == "Out":
        return 1 - eased(style, 1 - x)
    return eased(style, 2 * x) / 2 if x < 0.5 else 1 - eased(style, 2 - 2 * x) / 2


def decode(v):
    if isinstance(v, dict):
        if "Vector3" in v:
            return Vector(v["Vector3"])
        if "Color3" in v:  # to linear light, as Blender's colours are
            return Vector([(c / 255) ** 2.2 for c in v["Color3"]])
    return v


def value(keys, t):
    if not keys or t < keys[0][0]:
        return None
    for a, b in zip(keys, keys[1:]):
        if t <= b[0]:
            span = b[0] - a[0]
            u = ease(a[2] if len(a) > 2 else None, (t - a[0]) / span) if span > 0 else 1
            va, vb = decode(a[1]), decode(b[1])
            return va + (vb - va) * u
    return decode(keys[-1][1])


def sequence(seq, u):
    """A NumberSequence or ColorSequence as the rows write it: [[time, value], ...], or one value."""
    if not isinstance(seq, list):
        return decode(seq)
    for a, b in zip(seq, seq[1:]):
        if u <= b[0]:
            k = (u - a[0]) / max(b[0] - a[0], 1e-6)
            va, vb = decode(a[1]), decode(b[1])
            return va + (vb - va) * k
    return decode(seq[-1][1])


def angles(rx, ry, rz):
    """CFrame.Angles: X, then Y, then Z, each about the frame's own axes."""
    return Matrix.Rotation(rx, 4, "X") @ Matrix.Rotation(ry, 4, "Y") @ Matrix.Rotation(rz, 4, "Z")


# --- drawing (Roblox's axes in, Blender's out) ------------------------------------------------------------------------

def picture_mat(name, image, tint, strength, opacity, cull=False, added=0.0, foot=0.0):
    """A picture's light: colour = picture x tint x strength, alpha = picture's x opacity; `added` of it added light
    (LightEmission), the rest laid over; `foot` the share of a beam's length (UV v from 1 at Low) it fades in over."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.surface_render_method = "BLENDED"
    m.use_backface_culling = cull
    nt = m.node_tree
    nt.nodes.clear()
    L = nt.links.new
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    tex = nt.nodes.new("ShaderNodeTexImage")
    img = bpy.data.images.load(str(PICTURES[image]), check_existing=True)
    img.alpha_mode = "STRAIGHT"
    tex.image = img
    tex.extension = "EXTEND"
    tint_node = nt.nodes.new("ShaderNodeVectorMath")
    tint_node.operation = "MULTIPLY"
    L(tex.outputs["Color"], tint_node.inputs[0])
    tint_node.inputs[1].default_value = tuple(tint)
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Strength"].default_value = strength * T.SCALE
    L(tint_node.outputs["Vector"], em.inputs["Color"])
    alpha = nt.nodes.new("ShaderNodeMath")
    alpha.operation = "MULTIPLY"
    alpha.inputs[1].default_value = opacity
    L(tex.outputs["Alpha"], alpha.inputs[0])
    if foot > 0:  # (1 - v) / foot, clamped: clear at Low, whole past the fade
        coords = nt.nodes.new("ShaderNodeTexCoord")
        sep = nt.nodes.new("ShaderNodeSeparateXYZ")
        L(coords.outputs["UV"], sep.inputs[0])
        ramp = nt.nodes.new("ShaderNodeMapRange")
        ramp.inputs["From Min"].default_value, ramp.inputs["From Max"].default_value = 1.0, 1.0 - foot
        ramp.clamp = True
        L(sep.outputs["Y"], ramp.inputs["Value"])
        faded = nt.nodes.new("ShaderNodeMath")
        faded.operation = "MULTIPLY"
        L(alpha.outputs[0], faded.inputs[0])
        L(ramp.outputs["Result"], faded.inputs[1])
        alpha = faded
    over = nt.nodes.new("ShaderNodeMath")
    over.operation = "MULTIPLY"
    over.inputs[1].default_value = 1 - added
    L(alpha.outputs[0], over.inputs[0])
    tr = nt.nodes.new("ShaderNodeBsdfTransparent")
    mix = nt.nodes.new("ShaderNodeMixShader")
    L(over.outputs[0], mix.inputs[0])
    L(tr.outputs[0], mix.inputs[1])
    L(em.outputs[0], mix.inputs[2])
    if added > 0:  # the added share: emission over the clear, by the alpha
        lit = nt.nodes.new("ShaderNodeMath")
        lit.operation = "MULTIPLY"
        lit.inputs[1].default_value = added * strength * T.SCALE
        L(alpha.outputs[0], lit.inputs[0])
        em2 = nt.nodes.new("ShaderNodeEmission")
        L(tint_node.outputs["Vector"], em2.inputs["Color"])
        L(lit.outputs[0], em2.inputs["Strength"])
        add = nt.nodes.new("ShaderNodeAddShader")
        L(mix.outputs[0], add.inputs[0])
        L(em2.outputs[0], add.inputs[1])
        L(add.outputs[0], out.inputs["Surface"])
    else:
        L(mix.outputs[0], out.inputs["Surface"])
    return m


def beam(name, low, high, width, image, tint, strength, opacity, col, taper=1.0, foot=0.0, added=0.0, n=8):
    """A camera-facing ribbon from low (its picture's top row) to high, `width` studs across at low, `width * taper` at
    high, in n pieces along (so a tapered picture isn't sheared)."""
    a, b = T.to_bl(low), T.to_bl(high)
    axis = b - a
    if axis.length < 1e-4 or width <= 0 or opacity <= 0.002:
        return
    side = axis.cross(T.EYE - (a + b) / 2)
    if side.length < 1e-6:
        return
    side = side.normalized() * (width / 2)
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    strip = []
    for i in range(n + 1):
        u = i / n
        c, w = a + axis * u, 1 + (taper - 1) * u
        strip.append((bm.verts.new(c - side * w), bm.verts.new(c + side * w), 1 - u))
    for (l0, r0, v0), (l1, r1, v1) in zip(strip, strip[1:]):
        f = bm.faces.new((l0, r0, r1, l1))
        for loop, co in zip(f.loops, ((0, v0), (1, v0), (1, v1), (0, v1))):
            loop[uv].uv = co
    T.mesh_object(name, bm, col, picture_mat(name, image, tint, strength, opacity, added=added, foot=foot))


_KIT = {}


def kit_mesh(name):
    if name not in _KIT:
        m = json.loads((KIT / "meshes" / f"{name}.json").read_text(encoding="utf-8"))
        p, t, f = m["p"], m["t"], m["f"]
        pts = [Vector(p[i:i + 3]) for i in range(0, len(p), 3)]
        uvs = [(t[i], t[i + 1]) for i in range(0, len(t), 2)]
        lo = Vector([min(q[j] for q in pts) for j in range(3)])
        hi = Vector([max(q[j] for q in pts) for j in range(3)])
        _KIT[name] = (pts, uvs, [f[i:i + 9] for i in range(0, len(f), 9)], lo, hi)
    return _KIT[name]


def kit_object(name, part, frame, size, col, mat):
    """The kit's mesh at `size` studs (its box), placed by `frame` (Roblox), into Blender."""
    pts, uvs, tris, lo, hi = kit_mesh(part)
    mid, ext = (lo + hi) / 2, hi - lo
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    verts = []
    for q in pts:
        local = Vector([(q[j] - mid[j]) / max(ext[j], 1e-6) * size[j] for j in range(3)])
        verts.append(bm.verts.new(T.to_bl(frame @ local)))
    for tri in tris:
        try:
            face = bm.faces.new([verts[tri[0]], verts[tri[1]], verts[tri[2]]])
        except ValueError:
            continue
        for loop, k in zip(face.loops, tri[6:9]):
            loop[uvl].uv = (uvs[k][0], 1 - uvs[k][1])
    # Roblox's triangles wind the other way once the axes turn: put the faces outward
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return T.mesh_object(name, bm, col, mat)


def particle(name, centre, size, colour, opacity, near, lit, col, tones=None):
    """One camera-facing particle of fx_glow (added light), or a lit puff (`tones`), `near` studs toward the camera."""
    c = T.to_bl(centre)
    c = c + (T.EYE - c).normalized() * near
    if tones is None:
        T.glow(name, c, size / 2, tuple(colour), opacity, col)  # the target's scale: strength = Brightness
    else:
        obj = T.mesh_object(name, T.lumpy_sphere(size / 2.4, hash(name) % 97, lumps=0.25, subdiv=2), col,
                            T.smoke_mat(name, tones, opacity))
        obj.location = c


# --- the effects ------------------------------------------------------------------------------------------------------

def frame_of(parent, row, t, scale):
    tr = row["Tracks"]
    at = value(tr.get("At"), t) or Vector((0, 0, 0))
    spin = value(tr.get("Spin"), t) or 0
    tilt = value(tr.get("Tilt"), t) or Vector((0, 0, 0))
    return (parent @ Matrix.Translation(at * scale) @ Matrix.Rotation(math.radians(spin), 4, "Y")
            @ angles(*(math.radians(x) for x in tilt)))


def ends(frame, row, t, scale):
    up = (frame.to_3x3() @ Vector((0, 1, 0))).normalized()
    pos = frame.translation
    low = pos + up * (value(row["Tracks"].get("Foot"), t) or 0) * scale
    high = pos + up * (value(row["Tracks"].get("Top"), t) or 0) * scale
    return low, high


def draw_rows(rows, anchor, t, scale, col, lights, light_scale=180.0, night=False):
    """Every row of one effect at frame t; guides first, so the flames find their ends."""
    points = {}
    for name, row in rows.items():
        if row["Kind"] == "Beam" and "Low" not in row:
            first = min(k[0][0] for k in row["Tracks"].values())
            if t < first:
                continue
            fr = frame_of(anchor, row, t, scale)
            points[name] = ends(fr, row, t, scale)
    for name, row in rows.items():
        tr = row["Tracks"]
        first = min(k[0][0] for k in tr.values()) if tr else 0
        kind = row["Kind"]
        if kind == "Beam" and "Low" in row:
            if t < first or row["Low"].split(".")[0] not in points:
                continue
            ref = lambda r: points[r.split(".")[0]][0 if r.endswith(".Low") else 1]  # noqa: E731
            width = (value(tr.get("Width"), t) or 0) * scale
            fade = value(tr.get("Transparency"), t) or 0
            low, high = ref(row["Low"]), ref(row["High"])
            reach = value(tr.get("Reach"), t)
            if reach is not None:
                high = low + (high - low) * reach
            length = (high - low).length
            foot = min(0.998, row.get("FootFade", 0) * scale / length) if length > 1e-3 else 0
            tint = decode(row["Color"]) if "Color" in row else Vector((1, 1, 1))
            beam(name, low, high, width, row["Image"], tuple(tint), row["Beam"].get("Brightness", 1), 1 - fade, col,
                 taper=row.get("Taper", 1), foot=foot, added=row["Beam"].get("LightEmission", 0))
        elif kind == "Mesh":
            if t < first:
                continue
            fr = frame_of(anchor, row, t, scale)
            if row.get("Ground"):
                fr = Matrix.Translation((fr.translation.x, anchor.translation.y + (value(tr["At"], t).y * scale),
                                         fr.translation.z)) @ anchor.to_3x3().to_4x4()
            own = value(tr.get("Scale"), t)
            sv = own if isinstance(own, Vector) else Vector((1, 1, 1)) * (own if own is not None else 1)
            part = row["Part"][0]
            size = [KIT_SIZE[part][j] * sv[j] * scale for j in range(3)]
            fade = value(tr.get("Transparency"), t) or 0
            colour = value(tr.get("Color"), t) or decode(row.get("Color")) or Vector((1, 1, 1))
            glow = value(tr.get("Glow"), t) or 1
            if fade >= 0.998:
                continue
            if row.get("Look"):
                mat = picture_mat(name, row["Look"], tuple(colour), glow, 1 - fade, cull=True)
            else:  # Neon in its colour
                mat = T.flame_mat(name, tuple(colour), 2.2, 1 - fade)
            kit_object(name, part, fr, size, col, mat)
        elif kind == "Emitter":
            em = row["Emitter"]
            emits = row.get("Emit") or []
            rnd = random.Random(name)
            fr0 = frame_of(anchor, row, first, scale)
            facing = {"Top": (0, 1, 0), "Front": (0, 0, -1)}[em.get("EmissionDirection", "Top")]
            up = (fr0.to_3x3() @ Vector(facing)).normalized()
            pull = decode(em["Acceleration"]) * scale if "Acceleration" in em else Vector((0, 0, 0))
            radius = (value(tr.get("Radius"), first) or 0) * scale
            for frame0, count in emits:
                for k in range(count):
                    life = rnd.uniform(*em["Lifetime"]) * 60
                    speed = rnd.uniform(*em["Speed"]) * scale
                    drag = em.get("Drag", 0)
                    spread = math.radians(rnd.uniform(-1, 1) * (em.get("SpreadAngle", [0, 0])[0]))
                    turn = rnd.uniform(0, 2 * math.pi)
                    offset = Vector((math.cos(turn), 0, math.sin(turn))) * radius * rnd.random()
                    age = t - frame0
                    if age < 0 or age > life:
                        continue
                    s = age / 60
                    dist = speed * ((1 - math.exp(-drag * s)) / drag if drag else s)
                    way = (Matrix.Rotation(spread, 3, Vector((math.cos(turn), 0, math.sin(turn))).cross(up)) @ up)
                    centre = fr0.translation + offset + way * dist + pull * (0.5 * s * s)
                    u = age / life
                    size = sequence(em["Size"], u) * scale
                    opacity = 1 - sequence(em["Transparency"], u)
                    colour = sequence(em["Color"], u)
                    if em.get("LightInfluence", 0) >= 1:
                        tones = T.SMOKE_NIGHT if night else T.SMOKE_DAY
                        shade = sum(colour) / 3 / (150 / 255)
                        tones = tuple(tuple(c * shade for c in tone) for tone in tones)
                        particle(f"{name}_{frame0}_{k}", centre, size, colour, opacity, 0, True, col, tones)
                    elif em.get("Orientation") == "VelocityParallel":  # a needle along its flight
                        flight = way * speed * math.exp(-drag * s) + pull * s
                        if flight.length > 1e-3:
                            stretch = 1 + abs(min(0, sequence(em.get("Squash", [[0, 0], [1, 0]]), u)))
                            half = flight.normalized() * size * stretch * 0.5
                            beam(f"{name}_{frame0}_{k}", centre - half, centre + half, size * 0.35, "fx_beam",
                                 tuple(colour), em.get("Brightness", 1), opacity, col, taper=0.2, added=1.0, n=1)
                    else:
                        particle(f"{name}_{frame0}_{k}", centre, size, colour,
                                 opacity * em.get("Brightness", 1), em.get("ZOffset", 0), False, col)
        elif kind == "Light":
            if t < first:
                continue
            fr = frame_of(anchor, row, t, scale)
            b = value(tr.get("Brightness"), t) or 0
            colour = decode(row["Color"])
            lights.append((T.to_bl(fr.translation), tuple(colour), light_scale * b * row.get("Range", 9) / 9))


def root_of(pose):
    """The foe's root in Roblox: the torso's frame, TORSO_UP lower, and its scale."""
    parts = {p["N"]: p for p in pose.raw["Bodies"]["brawler_75"]}
    torso = parts["Shade_Torso"]
    scale = torso["S"][1] / 2.958
    c, r = torso["C"][:3], torso["C"][3:]
    m = Matrix(((r[0], r[1], r[2], c[0]), (r[3], r[4], r[5], c[1]), (r[6], r[7], r[8], c[2]), (0, 0, 0, 1)))
    up = Vector((r[1], r[4], r[7]))
    m.translation = Vector(c) - up * TORSO_UP * scale
    return m, scale


def burn_rows(t, pose, col, night, lights):
    rows = json.loads((ROWS / "StateBurn.json").read_text(encoding="utf-8"))["Rows"]
    root, scale = root_of(pose)
    draw_rows(rows, root, t * 60, scale, col, lights, light_scale=170.0, night=night)
    T.burn_embers(t, pose, col)  # the embers as the target's (an emitter per tongue tip in the game)


def fall_rows(t, pose, col, night, lights):
    rows = json.loads((ROWS / "ShadeFall.json").read_text(encoding="utf-8"))["Rows"]
    root, scale = root_of(pose)
    foot = root.translation - Vector((0, 3 * scale, 0))
    blow = Vector((pose.blow.x, 0, pose.blow.z)).normalized()
    back = -blow  # +Z of a frame whose -Z is the blow
    right = Vector((0, 1, 0)).cross(back).normalized()
    anchor = Matrix((
        (right.x, 0, back.x, foot.x),
        (right.y, 1, back.y, foot.y),
        (right.z, 0, back.z, foot.z),
        (0, 0, 0, 1)))
    draw_rows(rows, anchor, t * 60 + LEAD, scale, col, lights, light_scale=100.0, night=night)


T.LOOKS["burn_rows"] = burn_rows
T.LOOKS["fall_rows"] = fall_rows
# The fall's frames before the body goes, with the foe held out: ar69_targets.main holds the foe out for a look whose
# name starts with "burn".
T.LOOKS["burn_fall_rows"] = fall_rows

if __name__ == "__main__":
    T.main()
