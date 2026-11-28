"""AR76's targets (Scintilla, 2026-11-28): Rook's Haymaker in AR69's fire, two takes, rendered at the game's own camera
for a paint-over on the game's frames, as AR69's targets (tools/blender/ar69_targets.py, whose shapes and materials
this draws with).

    blender.exe -b --factory-startup --python tools/blender/ar76_targets.py -- <pose> <out_dir> <look> <frames>

<pose> is one pose file (the game's camera and the bodies' parts, read in Studio, AR69's format) or a folder of them,
pose_<frame>.json, one for each frame; <look> is hay_a (the hung fire) or hay_b (the ram's square in fire)
(build/scratch/scintilla/ar76/directions.md); <frames> the clip's frames at 60 fps, comma separated. The clip's beats:
Charge 8, the mass formed over the foe at 36, the drop from 53, Strike 57, Shock 58, Vent 70 (Actions.RookHaymaker,
Effects.Haymaker.Stamp). Each frame writes fx_<frame>.exr (the effect alone, the bodies and floor held out) and
light_<frame>.exr (the light it throws on white bodies and floor), as AR69's.

B5's composition is the director's (2026-11-12) and stays: the mass hung over the foe through the hold, slammed down on
the blow, the foe pinned where it stands. Only the look is new: fire, not a gold square.
"""
from __future__ import annotations

import json
import math
import random
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import ar69_targets as T  # noqa: E402
from ar69_targets import CORE, GOLD, ORANGE, RIM, ease_in, ease_out, mix, span  # noqa: E402

STRIKE = 57
FORMED = 36  # Stamp.Rise: 21 frames before Strike
DROP = 53  # Stamp.Drop: 4 frames
UP = Vector((0, 0, 1))


class Scene:
    """The bodies of one frame, in Blender's space: Rook's fist and torso, the foe's torso, its top and the floor."""

    def __init__(self, raw):
        bodies = raw["Bodies"]
        lead = next(k for k in bodies if k.startswith("Lead_"))
        foe = next(k for k in bodies if k.lower().startswith(("brawler", "shade", "guard", "dasher")))
        rook = {p["N"]: p for p in bodies[lead]}
        shade = {p["N"]: p for p in bodies[foe]}
        self.held = [lead, foe] + [k for k in bodies if k == "Avatar"]
        arm = rook["Rook_RightArm"]
        c = arm["C"]
        arm_up = Vector((c[4], c[7], c[10])) if len(c) == 12 else Vector((0, 1, 0))
        # the knuckles: the arm's foot, a little in from its end (Roblox), then Blender
        self.fist = T.to_bl(Vector(c[:3]) - arm_up * (arm["S"][1] * 0.42))
        self.rook = T.to_bl(Vector(rook["Rook_Torso"]["C"][:3]))
        torso = shade["Shade_Torso"]
        self.foe = T.to_bl(Vector(torso["C"][:3]))
        self.top = max(p["C"][1] + p["S"][1] / 2 for p in bodies[foe])  # Roblox Y
        self.floor = min(p["C"][1] - p["S"][1] / 2 for p in bodies[foe])
        self.feet = Vector((self.foe.x, self.foe.y, self.floor))
        blow = self.foe - self.rook
        blow.z = 0
        self.blow = blow.normalized()
        self.side = self.blow.cross(UP).normalized()


def ember(name, at, size, colour, op, col):
    obj = T.mesh_object(name, T.speck(size), col, T.flame_mat(name, colour, 2.4, op))
    obj.location = at


def lobe_width(width, foot=0.7):
    """A flame lobe's width along it (s 0 at the foot, 1 at the tip): a round foot, a full body held most of the way up,
    rounding to a soft tip. AR69's tongue_width runs almost straight to a point, a cone, which at the Haymaker's distance
    from the camera (about 15 studs) read as a spike (the first take on the plates, 02:5x)."""
    def w(u):
        grow = foot + (1 - foot) * math.sin(min(u / 0.3, 1.0) * math.pi / 2)
        return width * grow * max(1 - u ** 2.4, 0.0) ** 0.55
    return w


def beam_strip(path, width_fn):
    """One ribbon along a path, turned at every point to face the camera: a Beam with FaceCamera in the game, its
    Width0/Width1 and curve sizes drawing the lobe. UV: U across, V along. Three crossed ribbons (AR69's tongues) read
    from the Haymaker's camera as faceted crystal spikes (the plates, 2026-11-28): one camera-facing strip is one
    filled silhouette, core down its middle, rim at its edges."""
    bm = T.bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    n = len(path)
    left, right = [], []
    for i, pt in enumerate(path):
        t = (path[min(i + 1, n - 1)] - path[max(i - 1, 0)]).normalized()
        side = t.cross((T.EYE - pt).normalized())
        if side.length < 1e-4:
            side = t.cross(Vector((0, 0, 1)))
        side.normalize()
        w = width_fn(i / (n - 1)) / 2
        left.append(bm.verts.new(pt - side * w))
        right.append(bm.verts.new(pt + side * w))
    for i in range(n - 1):
        f = bm.faces.new((left[i], right[i], right[i + 1], left[i + 1]))
        for loop, co in zip(f.loops, ((0, i / (n - 1)), (1, i / (n - 1)), (1, (i + 1) / (n - 1)), (0, (i + 1) / (n - 1)))):
            loop[uv].uv = co
    return bm


def tongue(name, foot, d, length, width, col, op=0.97, bend=None, cool=0.0, foot_shape=0.7):
    """One flame lobe from `foot` along `d`, its tip curled by `bend`: a camera-facing strip (a Beam) with the kit's
    fire across it, a full round body to a soft curled tip."""
    if length < 0.05 or op < 0.01:
        return
    bend = bend if bend is not None else Vector((0, 0, 0))
    path = T.curve(foot, d.normalized(), length, bend, n=16)
    # the curl: the last third of the lobe swings back against its bend, so the tip hooks over (an S)
    path = [pt - bend * (0.9 * max(i / 15 - 0.6, 0.0) ** 2 / 0.16) for i, pt in enumerate(path)]
    T.mesh_object(name, beam_strip(path, lobe_width(width, foot_shape)), col, T.across_mat(name, op, cool, 0.25, 0.0, 1.05))


# --- both takes: the wraps' heat and the knuckle flash -----------------------------------------------------------------

def wraps(f, s, col, lights):
    """Heat gathering in the wraps from the charge: the fist on fire, three lobes up off the knuckles (sized to read from
    the game's camera, 15 studs off), embers shed, a warm light that lights his face. Taller as the hold goes on, gone a
    few frames after the strike."""
    grow = ease_out(span(f, 14, 52), 1.6) * (1 - ease_in(span(f, STRIKE + 1, STRIKE + 8), 1.2))
    if grow < 0.02:
        return
    for n, (lean, length, width, beat) in enumerate(((-0.3, 1.7, 0.85, 9), (0.25, 1.4, 0.75, 7), (0.0, 1.2, 0.65, 11))):
        cyc = (f / beat + 0.37 * n) % 1.0
        size = 0.85 + 0.2 * math.sin(2 * math.pi * cyc)
        d = UP + s.side * lean + s.blow * -0.15
        tongue(f"wrap{n}", s.fist + s.side * (lean * 0.3), d, length * grow * size, width * (0.6 + 0.4 * grow), col,
               bend=s.side * (0.15 * math.sin(2 * math.pi * cyc + n)))
    rnd = random.Random(31)
    for n in range(7):
        life = rnd.uniform(12, 20)
        tt = (f + rnd.uniform(0, life)) % life
        u = tt / life
        at = s.fist + UP * (0.3 + 2.2 * u) + s.side * (rnd.uniform(-0.6, 0.6) * u) - s.blow * (0.4 * u)
        ember(f"wember{n}", at, rnd.uniform(0.05, 0.08), mix(CORE, ORANGE, u), grow * (1 - u), col)
    lights.append((s.fist + UP * 0.4, ORANGE, 90 * grow))


def knuckles(f, s, col, lights):
    """The strike: a white-hot flash at the knuckles for two frames, and a short cone of licks thrown from the fist along
    the punch into the foe."""
    flash = ease_out(span(f, STRIKE - 0.5, STRIKE), 1.5) * (1 - ease_in(span(f, STRIKE, STRIKE + 3), 1.2))
    if flash > 0.01:
        T.glow("knuckle", s.fist + (T.EYE - s.fist).normalized() * 0.6, 1.7, CORE, 2.6 * flash, col)
        lights.append((s.fist, CORE, 500 * flash))
    u = span(f, STRIKE, STRIKE + 2.5)
    fade = 1 - ease_in(span(f, STRIKE + 1, STRIKE + 6), 1.3)
    if u > 0 and fade > 0.01:
        aim = (s.foe - s.fist).normalized()
        for n, (spread, length, width) in enumerate(((0.0, 2.8, 1.2), (0.35, 2.2, 0.9), (-0.3, 2.0, 0.85))):
            d = (aim + s.side * spread + UP * (0.15 * n)).normalized()
            tongue(f"cone{n}", s.fist + aim * 0.3, d, length * ease_out(u, 2), width, col, 0.95 * fade, cool=0.1)


# --- take A: the hung fire ----------------------------------------------------------------------------------------------

def hung_centre(s, f):
    """The mass over the foe: its middle 2.6 over the foe's top, through the hold."""
    return Vector((s.foe.x, s.foe.y, s.top + 2.6))


def hay_a(f, s, col, night, lights):
    wraps(f, s, col, lights)
    knuckles(f, s, col, lights)
    hung = hung_centre(s, f)
    rnd = random.Random(7)
    if FORMED - 8 <= f < STRIKE:
        form = ease_out(span(f, FORMED - 8, FORMED), 2.2)
        tight = ease_in(span(f, FORMED, DROP), 1.3)
        radius = 2.2 * form - 0.4 * tight + 0.06 * math.sin(f * 0.9)
        fall = ease_in(span(f, DROP, STRIKE), 2.4)  # faster and faster
        centre = hung.lerp(Vector((s.foe.x, s.foe.y, s.foe.z + 0.3)), fall)
        tall, wide = 1 + 0.35 * fall, 1 - 0.15 * fall
        if radius > 0.05:
            obj = T.mesh_object("ball", T.flame_ball(5, 0.55, s.blow), col, T.flame_mat("ball", mix(ORANGE, GOLD, 0.25), 1.35, 0.95))
            obj.location = centre
            obj.scale = (radius * wide, radius * wide, radius * tall)
            rim = T.mesh_object("rim", T.flame_ball(9, 0.8, s.blow), col, T.flame_mat("rim", mix(ORANGE, RIM, 0.55), 1.15, 0.6))
            rim.location = centre + UP * 0.1
            rim.scale = (radius * 1.14 * wide, radius * 1.14 * wide, radius * 1.1 * tall)
            toward = (T.EYE - centre).normalized()
            T.glow("heart", centre + toward * (radius * 1.15), radius * 0.75, mix(CORE, GOLD, 0.3), 1.6 + 0.8 * fall, col)
            # licks off its top, licking; streaming up behind it as it falls
            for n in range(6):
                a = 2 * math.pi * n / 6 + 0.4
                out = Vector((math.cos(a), math.sin(a), 0))
                cyc = (f / (7 + n % 3) + 0.3 * n) % 1.0
                size = 0.85 + 0.2 * math.sin(2 * math.pi * cyc)
                foot = centre + out * (radius * 0.55 * wide) + UP * (radius * 0.6 * tall)
                d = UP + out * (0.45 * (1 - fall))
                tongue(f"lick{n}", foot, d, (1.3 + 0.25 * (n % 3)) * radius / 2.2 * size * (1 + 1.4 * fall),
                       (0.95 + 0.2 * (n % 2)) * radius / 2.2, col)
            lights.append((centre, ORANGE, 260 * form))
        # embers drawn in to it as it forms
        for n in range(12):
            a, e = rnd.uniform(0, 6.28), rnd.uniform(-0.5, 0.9)
            r0 = rnd.uniform(3.5, 5.0)
            u = span(f, FORMED - 8 + rnd.uniform(0, 4), FORMED + 2)
            if 0 < u < 1:
                d = Vector((math.cos(a) * math.cos(e), math.sin(a) * math.cos(e), math.sin(e)))
                ember(f"in{n}", hung + d * (r0 * (1 - ease_in(u, 1.6)) + 1.5), 0.08, mix(GOLD, CORE, u), 1.0, col)
    if f >= STRIKE:
        burst(f, s, col, lights, crown=True)


def burst(f, s, col, lights, crown):
    """Strike: the fire splashes flat along the floor round the foe's feet, wide and dense (B5's squash and spread, in
    fire), with fat lobes curling up off its rim at full height on the hitstop's frame (take A; take B's walls are its
    own), the far ones tallest so the foe stands dark against them; the ring runs out beyond it; low dust; a flash and
    the light. The foe stands pinned in it."""
    feet = s.feet + UP * 0.05
    toward = (T.EYE - feet).normalized()
    flat = Vector((toward.x, toward.y, 0)).normalized()
    flash = 1 - ease_in(span(f, STRIKE, STRIKE + 3), 1.2)
    if flash > 0.01 and f >= STRIKE:
        T.glow("burstflash", feet + UP * 0.5 + toward * 2.2, 2.4, CORE, 0.9 * flash, col)
    if crown:
        spread = ease_out(span(f, STRIKE - 0.5, STRIKE + 4), 2.2)
        eat = 1 - ease_in(span(f, STRIKE + 6, STRIKE + 22), 1.2)
        radius = 2.0 + 2.3 * spread
        if eat > 0.01 and f >= STRIKE:
            pool = T.mesh_object("pool", T.flame_ball(3, 0.5, s.blow), col,
                                 T.flame_mat("pool", mix(ORANGE, GOLD, 0.35), 1.35, 0.92 * eat))
            pool.location = feet + UP * 0.25
            pool.scale = (radius, radius, 0.95 - 0.4 * spread)
        rnd = random.Random(13)
        for n in range(11):
            a = 2 * math.pi * n / 11 + rnd.uniform(-0.2, 0.2)
            out = Vector((math.cos(a), math.sin(a), 0))
            rise = ease_out(span(f, STRIKE - 0.5, STRIKE + 1.5 + 0.5 * (n % 3)), 2.0)
            sink = 1 - ease_in(span(f, STRIKE + 8 + n % 4, STRIKE + 28 + n % 5), 1.3)
            if rise <= 0:
                continue
            cyc = (f / (6 + n % 4) + 0.21 * n) % 1.0
            far = -out.dot(flat)  # 1 at the far side of the foe, -1 at the near side
            over = 1 + 0.4 * (1 - ease_in(span(f, STRIKE + 1, STRIKE + 7), 1.4))
            length = rnd.uniform(2.3, 3.2) * over * (1.3 + 0.35 * far) * rise * (0.35 + 0.65 * sink) * (0.92 + 0.12 * math.sin(2 * math.pi * cyc))
            tongue(f"crown{n}", feet + out * (radius * 0.72), UP + out * (0.55 - 0.3 * max(far, 0)), length,
                   rnd.uniform(2.0, 2.6) * (0.55 + 0.45 * sink), col, 0.97 * min(1, sink * 2),
                   bend=out * 0.45 + s.side * rnd.uniform(-0.2, 0.2), cool=0.25 * (1 - sink))
    # the ring: the flipbook's gold band running out over the floor (AR69's, here a mesh band as its target drew it)
    u = span(f, STRIKE + 1, STRIKE + 1 + 21)
    if 0 < u < 1:
        r = 1.5 + 4.0 * ease_out(u, 2.6)
        band = 0.55 + 0.6 * u
        ring = T.mesh_object("ring", T.annulus(max(r - band, 0.1), r), col,
                             T.ring_mat("ring", GOLD, 1.8, 1 - ease_in(u, 1.5), 0.0, 0.75))
        ring.location = feet + UP * 0.03
    # dust: low grey lumps rolled out along the floor
    rnd = random.Random(19)
    for n in range(8):
        a = 2 * math.pi * n / 8 + rnd.uniform(-0.3, 0.3)
        out = Vector((math.cos(a), math.sin(a), 0))
        u = span(f, STRIKE + 1, STRIKE + 24)
        if 0 < u < 1:
            at = feet + out * (2.4 + 2.6 * ease_out(u, 2.2)) + UP * (0.35 + 0.5 * u)
            lump = T.mesh_object(f"dust{n}", T.lumpy_sphere(0.55 + 0.35 * u, n), col,
                                 T.smoke_mat(f"dust{n}", T.SMOKE_NIGHT if NIGHT[0] else T.SMOKE_DAY, 0.55 * (1 - ease_in(u, 1.4))))
            lump.location = at
    light = 1 - ease_in(span(f, STRIKE, STRIKE + 6), 1.2)
    if light > 0.01 and f >= STRIKE:
        lights.append((feet + UP * 1.2, mix(CORE, ORANGE, 1 - light), 900 * light))
    if f >= STRIKE + 6:
        lights.append((feet + UP * 0.8, ORANGE, 260 * (1 - ease_in(span(f, STRIKE + 6, STRIKE + 28), 1.2))))
    rnd = random.Random(23)
    for n in range(12):
        life = rnd.uniform(16, 26)
        u = span(f, STRIKE + 2 + rnd.uniform(0, 6), STRIKE + 2 + life)
        if 0 < u < 1:
            a = rnd.uniform(0, 6.28)
            at = feet + Vector((math.cos(a), math.sin(a), 0)) * rnd.uniform(0.8, 3.0) + UP * (0.6 + 4.0 * u)
            ember(f"up{n}", at, rnd.uniform(0.07, 0.11), mix(CORE, ORANGE, u), 1 - u, col)


# --- take B: the ram's square, in fire ------------------------------------------------------------------------------------

def fire_slab(seed, licks):
    """A burning slab: a rounded square block (a superellipsoid, side 2, as tall as wide before scaling) with flame licks
    pulled up out of its top, irregular in count and spacing. Filled, never an outline (research, 2026-11-28: fire shaped
    like a square, not a square outlined in fire). In the game: one mesh in the kit's rise look, as AR69's ball."""
    rnd = random.Random(seed)
    bm = T.bmesh.new()
    T.bmesh.ops.create_icosphere(bm, subdivisions=5, radius=1.0)
    tips = []
    for _ in range(rnd.randint(7, 10)):
        d = Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(0.6, 1.6))).normalized()
        tips.append((d, rnd.uniform(0.5, 1.0), math.radians(rnd.uniform(10, 18))))
    n = 5.0
    for v in bm.verts:
        d = v.co.normalized()
        k = (abs(d.x) ** n + abs(d.y) ** n + abs(d.z) ** n) ** (1 / n)
        lick = 0.0
        for c, w, width in tips:
            a = math.acos(max(-1.0, min(1.0, d.dot(c))))
            lick = max(lick, w * max(0.0, 1 - a / width) ** 1.6)
        v.co = d / k + d * (licks * lick) + Vector((0, 0, 1.6 * licks * lick * max(d.z, 0)))
    T.bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


def slab(name, centre, half, thick, tilt, heading, op, col, seed=4):
    obj = T.mesh_object(name, fire_slab(seed, 0.35), col, T.flame_mat(name, mix(ORANGE, GOLD, 0.25), 1.35, op))
    obj.location = centre
    obj.scale = (half, half, thick)
    obj.rotation_euler = (tilt, 0, heading)
    rim = T.mesh_object(name + "rim", fire_slab(seed + 5, 0.5), col, T.flame_mat(name + "rim", mix(ORANGE, RIM, 0.55), 1.15, 0.6 * op))
    rim.location = centre + UP * 0.1
    rim.scale = (half * 1.1, half * 1.1, thick * 1.15)
    rim.rotation_euler = (tilt, 0, heading)


def square_point(centre, half, tilt, heading, x, y, z=0.0):
    """A point on the square's own axes (x across, y away, z up, each -1 to 1 on its sides) laid over `centre`."""
    ct, st = math.cos(tilt), math.sin(tilt)
    yy, zz = y * half * ct - z * st, y * half * st + z * ct
    ch, sh = math.cos(heading), math.sin(heading)
    return centre + Vector((x * half * ch - yy * sh, x * half * sh + yy * ch, zz))


def hay_b(f, s, col, night, lights):
    wraps(f, s, col, lights)
    knuckles(f, s, col, lights)
    hung = hung_centre(s, f) + UP * 0.2
    heading = math.atan2(s.blow.y, s.blow.x) - math.pi / 2
    if FORMED - 8 <= f < STRIKE:
        form = ease_out(span(f, FORMED - 8, FORMED), 2.0)
        tight = ease_in(span(f, FORMED, DROP), 1.3)
        fall = ease_in(span(f, DROP, STRIKE), 2.4)
        half = (2.3 - 0.4 * tight) * (0.5 + 0.5 * form) + 0.04 * math.sin(f * 0.9)
        thick = 0.75 * (0.5 + 0.5 * form) * (1 + 0.35 * fall)
        centre = hung.lerp(s.feet + UP * 0.6, fall)
        tilt = math.radians(24) * (1 - fall)  # its far edge raised toward the camera while it hangs; flat as it lands
        slab("slab", centre, half * (1 - 0.15 * fall), thick, tilt, heading, 0.95, col)
        toward = (T.EYE - centre).normalized()
        T.glow("heart", centre + toward * (half * 0.9), half * 0.7, mix(CORE, GOLD, 0.3), 1.5 + 0.8 * fall, col)
        rnd = random.Random(53)
        for j in range(7):
            x, y = rnd.uniform(-0.8, 0.8), rnd.uniform(-0.8, 0.8)
            foot = square_point(centre, half, tilt, heading, x, y, thick * 0.7)
            cyc = (f / (6 + j % 4) + 0.29 * j) % 1.0
            size = 0.85 + 0.2 * math.sin(2 * math.pi * cyc)
            length = rnd.uniform(1.0, 2.0) * size * (1 + 1.5 * fall) * form
            tongue(f"top{j}", foot, UP + s.side * rnd.uniform(-0.2, 0.2), length, rnd.uniform(1.0, 1.5) * form, col)
        lights.append((centre, ORANGE, 260 * form))
        for n in range(12):
            a, e = rnd.uniform(0, 6.28), rnd.uniform(-0.5, 0.9)
            u = span(f, FORMED - 8 + rnd.uniform(0, 4), FORMED + 2)
            if 0 < u < 1:
                d = Vector((math.cos(a) * math.cos(e), math.sin(a) * math.cos(e), math.sin(e)))
                ember(f"in{n}", hung + d * (rnd.uniform(3.5, 5.0) * (1 - ease_in(u, 1.6)) + 1.5), 0.08, mix(GOLD, CORE, u),
                      1.0, col)
    if f >= STRIKE:
        k = f - STRIKE
        spread = 1.3 + 0.25 * ease_out(span(f, STRIKE, STRIKE + 10), 2)
        half = 2.3 * spread / 1.3
        eat = 1 - ease_in(span(f, STRIKE + 3, STRIKE + 15), 1.2)
        if eat > 0.01:
            squash = (0.55, 0.3, 0.26, 0.24)[min(int(k), 3)]
            slab("pool", s.feet + UP * (0.75 * squash * 0.5), half * 0.95, 0.75 * squash, 0.0, heading, 0.9 * eat, col)
        walls(f, s, half, heading, col)
        runs(f, s, heading, col)
        burst(f, s, col, lights, crown=False)


def walls(f, s, half, heading, col):
    """On the floor, each side erupts in a wall of fire: wide tongues closer together than their width, so they merge
    into one wall with a ragged top, tallest at the middle of a side and lower toward its corners, the far side tallest
    so the foe stands dark against it; at full height on the hitstop's frame, sinking from 8 frames on."""
    rnd = random.Random(61)
    for side_n, (x0, y0, x1, y1) in enumerate(((-1, -1, 1, -1), (1, -1, 1, 1), (1, 1, -1, 1), (-1, 1, -1, -1))):
        count = 6 + side_n % 2
        for j in range(count):
            u = (j + 0.5 + rnd.uniform(-0.25, 0.25)) / count
            x, y = x0 + (x1 - x0) * u, y0 + (y1 - y0) * u
            foot = square_point(s.feet + UP * 0.05, half, 0.0, heading, x, y)
            out = Vector((foot.x - s.feet.x, foot.y - s.feet.y, 0)).normalized()
            rise = ease_out(span(f, STRIKE - 0.5, STRIKE + 1.5 + 0.5 * ((j + side_n) % 3)), 2.0)
            toward = T.EYE - s.feet
            far = -out.dot(Vector((toward.x, toward.y, 0)).normalized())
            sink = 1 - ease_in(span(f, STRIKE + 8 + j % 4, STRIKE + 26 + side_n % 3), 1.3)
            middle = 1 - 0.45 * abs(2 * u - 1) ** 1.5
            cyc = (f / (6 + (j + side_n) % 4) + 0.23 * j) % 1.0
            over = 1 + 0.4 * (1 - ease_in(span(f, STRIKE + 1, STRIKE + 7), 1.4))
            length = rnd.uniform(2.1, 3.3) * over * (1.3 + 0.35 * far) * middle * rise * (0.35 + 0.65 * sink) * (0.9 + 0.15 * math.sin(2 * math.pi * cyc))
            tongue(f"wall{side_n}_{j}", foot, UP + out * 0.15, length, rnd.uniform(1.8, 2.4) * (0.55 + 0.45 * sink), col,
                   0.97 * min(1, sink * 2), bend=out * rnd.uniform(-0.15, 0.25), cool=0.25 * (1 - sink))


def runs(f, s, heading, col):
    """B5's two bars run out along the floor from its feet: here two runs of fire, a row of low lobes lit one after
    another as the front passes, out 4.5 studs over 8 frames, gone after 17 (Stamp.Run). A thin streak read as a
    scratch at the game's camera (2026-11-28)."""
    u = span(f, STRIKE, STRIKE + 8)
    fade = 1 - ease_in(span(f, STRIKE + 6, STRIKE + 17), 1.2)
    if u <= 0 or fade < 0.01:
        return
    rnd = random.Random(71)
    for n, way in enumerate((s.side, -s.side)):
        foot = s.feet + way * 1.9 + UP * 0.05
        front = 4.5 * ease_out(u, 2.2)
        for k in range(8):
            d = 0.3 + 0.6 * k
            if d > front:
                break
            lit = min((front - d) / 0.8, 1.0)  # grows as the front passes, then holds
            size = (1.0 - 0.07 * k) * lit * fade
            tongue(f"run{n}_{k}", foot + way * d + s.blow * rnd.uniform(-0.2, 0.2), UP + way * 0.25,
                   rnd.uniform(0.9, 1.4) * size, rnd.uniform(0.8, 1.0) * (0.6 + 0.4 * size), col, 0.97 * min(1, fade * 2),
                   bend=way * 0.3, cool=0.2 * (1 - fade))


LOOKS = {"hay_a": hay_a, "hay_b": hay_b}
NIGHT = [False]


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    root = Path(__file__).resolve().parents[2]
    pose_path, out, look = root / argv[0], root / argv[1], argv[2]
    frames = [float(x) for x in argv[3].split(",")]
    out.mkdir(parents=True, exist_ok=True)
    NIGHT[0] = "night" in out.name

    def raw_at(frame):
        if pose_path.is_dir():
            return json.loads((pose_path / f"pose_{int(frame)}.json").read_text())
        return json.loads(pose_path.read_text())

    for frame in frames:
        raw = raw_at(frame)
        s = Scene(raw)
        scene = T.reset()
        cam = T.camera_from(raw, scene, 2483, 1134)
        hold, fx, lit = T.collection("Hold"), T.collection("Fx"), T.collection("Lit")
        white = T.white_mat()
        for name in s.held:
            for p in raw["Bodies"][name]:
                T.box(f"hold_{p['N']}", p["S"], T.cframe(p["C"]), hold, white)
        T.box("floor", (400, 1.0, 400), T.C @ T.Matrix.Translation(Vector((s.foe.x, s.floor - 0.5, -s.foe.y))), hold, white)
        T.EYE = cam.matrix_world.translation.copy()
        lights = []
        LOOKS[look](frame, s, fx, NIGHT[0], lights)
        view = scene.view_layers[0]
        tag = f"{int(frame)}"
        view.layer_collection.children["Hold"].holdout = True
        view.layer_collection.children["Lit"].exclude = True
        scene.render.filepath = str(out / f"fx_{tag}.exr")
        bpy.ops.render.render(write_still=True)
        for (p, colour, power) in lights:
            if power <= 1:
                continue
            ld = bpy.data.lights.new("fire", "POINT")
            ld.color = colour
            ld.energy = power * T.SCALE
            ld.shadow_soft_size = 0.8
            ld.use_custom_distance = True
            ld.cutoff_distance = 40
            lo = bpy.data.objects.new("fire", ld)
            lit.objects.link(lo)
            lo.location = p
        view.layer_collection.children["Hold"].holdout = False
        view.layer_collection.children["Fx"].exclude = True
        view.layer_collection.children["Lit"].exclude = False
        scene.render.filepath = str(out / f"light_{tag}.exr")
        bpy.ops.render.render(write_still=True)
    print("done", look, len(frames))


if __name__ == "__main__":
    main()
