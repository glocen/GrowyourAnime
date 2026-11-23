"""AR56's blockout (docs/asset-requests.md, AR56): the Tower's room, three directions in stand-in grey. One big round
room, the same for everyone, far from the map: the player steps in with their lead, a foe stands across the floor, and
at each win the next one comes in. The question: how one room that never changes says "high, and climbing" from the
player's camera. Each direction answers it with a different lever:

    A, the Crown      the tower's open top: no wall, no roof. Eight tall blades lean out of the rim, their shadows lie
                      across the floor, cloud drifts past at the floor's height and lower spires stand in the cloud sea.
                      The next foe climbs floating steps over the far rim; the number stands on a slab afloat over them.
    B, the Well       the floor is an island in a wide shaft, a gap all round, a bridge to the entrance and one to the
                      foe's doorway. The wall is ring on ring, each with a lit seam and a row of ticks, down into bright
                      mist and up out of sight. The number is a plate on the wall over the foe's doorway.
    C, the Gate hall  a closed domed hall, the sun through the round opening at its top in one pool on the floor. Tall
                      openings round the wall, and opposite the entrance one great gate standing on the sky: the foe
                      walks in through it, dark against the light. No numeral: ten marks round the pool, one lit a floor.

Every direction keeps the same fight floor, FLOOR_R in radius (the elite's 64 square fits), the entrance at -Y and the
foe's way in at +Y. The figures are grey boxes: the avatar, the lead, the foe. The light is the game's day (AR40's C),
the sun turned for each room (a client's own Lighting while it stands in the room; Faber's call).

Views, at twice the smallest phone (1136 x 640): `enter`, the player's camera (12.5 studs behind the avatar, 20 degrees
down, FOV 70) as the avatar steps in; `fight`, the same camera at a fight in the middle; `up`, that spot with the camera
tilted 8 degrees up; `whole`, from outside or above, for the room's shape. The take: the walk in from the entrance to
the stand, the foe coming in, then the fight's frame held; RATE frames a second, 852 x 480.

One direction a run, under the guard (Eevee, no lock needed):

    guard.ps1 tools/blender/tower_room_block.py <abs out> see <A|B|C> [stills] [take]
    guard.ps1 tools/blender/tower_room_block.py <abs out> movie <A|B|C>
    guard.ps1 tools/blender/tower_room_block.py <abs out> sheet

`see` writes <out>/<D>_<view>.png, <out>/take/<D>/f###.png and <out>/<D>.json (the size and the count); `movie`
writes <out>/tower_room_<D>.mp4; `sheet` writes <out>/tower_room.png. Nothing is exported, nothing goes to the game.
"""

import json
import math
import random
import sys
import textwrap
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))

import blcommon as bl  # noqa: E402
import lantern_row_look as look  # noqa: E402
import rook_sheet as rs  # noqa: E402
import tower_block as tb  # noqa: E402

FLOOR_R = 48.0                       # the fight floor: the elite's 64 square has a half diagonal of 45.3
STAND = 13.0                         # the avatar this far behind the middle, the foe as far in front (Config.Tower: 0.55 x 24)
WALK = 16.0                          # studs a second, Roblox's walk
SIZE, TAKE, RATE = (1136, 640), (852, 480), 15
HOLD = 1.5                           # the fight's frame held at the take's end, seconds
SHOWN = 17                           # the floor shown
NAMES = {"A": "the Crown", "B": "the Well", "C": "the Gate hall"}
SAID = {"A": "the tower's open top, the sky all round", "B": "an island in a shaft of rings",
        "C": "a closed hall, one gate on the sky"}
GREY = dict(stone=("#BDBFC6", "#9C9EA6"), stone2=("#AAACB4", "#8A8C94"), dark=("#8A8C94", "#6C6E76"),
            floor=("#B2B4BB", "#B2B4BB"), floor2=("#C2C4CA", "#C2C4CA"), trim=("#DADBE0", "#C6C7CC"),
            avatar=("#74767E", "#5E6068"), lead=("#E4E5E9", "#C4C5CA"), foe=("#3E4048", "#2C2E36"))
LIGHT = "#FFF4DE"
# each room's sun (degrees: from where, how high), its mist (colour, density) and where the player comes in (y, z)
ROOMS = {"A": dict(sun=(262.0, 28.0), fog=("#DCE6F6", 0.0005), enter=(-54.0, -1.5), way=(67.0, -2.0),
                   whole=((105.0, -135.0, 70.0), (0.0, 0.0, 6.0))),
         "B": dict(sun=(225.0, 60.0), fog=("#E4ECF8", 0.0016), enter=(-70.0, 0.0), way=(86.0, 0.0),
                   whole=((0.0, -70.0, 132.0), (0.0, 8.0, 0.0))),
         "C": dict(sun=(180.0, 80.0), fog=("#DCE6F6", 0.0012), enter=(-62.0, 0.0), way=(80.0, 0.0),
                   whole=((120.0, 150.0, 80.0), (0.0, 0.0, 28.0)))}


# --- geometry ----------------------------------------------------------------------------------------------------------

def prism(w0, d0, w1, d1, h, shift=(0.0, 0.0)):
    """A tapered block on its foot: w0 x d0 at z 0, w1 x d1 at z h, its head moved by `shift`."""
    sx, sy = shift
    verts = [(-w0 / 2, -d0 / 2, 0), (w0 / 2, -d0 / 2, 0), (w0 / 2, d0 / 2, 0), (-w0 / 2, d0 / 2, 0),
             (sx - w1 / 2, sy - d1 / 2, h), (sx + w1 / 2, sy - d1 / 2, h), (sx + w1 / 2, sy + d1 / 2, h), (sx - w1 / 2, sy + d1 / 2, h)]
    faces = [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    return verts, faces


def box(w, d, h):
    return prism(w, d, w, d, h)


def moved(geo, at=(0.0, 0.0, 0.0), turn=0.0):
    c, s = math.cos(turn), math.sin(turn)
    return [(x * c - y * s + at[0], x * s + y * c + at[1], z + at[2]) for x, y, z in geo[0]], geo[1]


def merged(geos):
    verts, faces = [], []
    for v, f in geos:
        n = len(verts)
        verts += v
        faces += [tuple(i + n for i in face) for face in f]
    return verts, faces


def polar(r, a, z=0.0):
    return (r * math.cos(a), r * math.sin(a), z)


def out_at(a):
    """The turn that points a block's +Y outward at angle `a`."""
    return a - math.pi / 2


def ring(r0, r1, z0, z1, gaps=()):
    """A ring, whole or broken at `gaps` (each an angle and a half width, radians, in rising order)."""
    if not gaps:
        return tb.sector(r0, r1, z0, z1)
    parts = []
    for k, (a, half) in enumerate(gaps):
        b, bhalf = gaps[(k + 1) % len(gaps)]
        if k == len(gaps) - 1:
            b += 2 * math.pi
        parts.append(tb.sector(r0, r1, z0, z1, a + half, b - bhalf))
    return merged(parts)


# --- the room's pieces ---------------------------------------------------------------------------------------------------

class Room:
    def __init__(self, scene, mats):
        self.scene, self.mats = scene, mats
        self.pieces, self.outside = [], []

    def add(self, name, geo, mat, at=(0.0, 0.0, 0.0), turn=0.0, outside=False, shadow=True):
        obj = tb.solid(self.scene, name, geo, self.mats[mat])
        obj.location, obj.rotation_euler = at, (0.0, 0.0, turn)
        obj.visible_shadow = shadow
        (self.outside if outside else self.pieces).append(obj)
        return obj

    def puff(self, at, size):
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0)
        mesh = bpy.data.meshes.new("Puff")
        bm.to_mesh(mesh)
        bm.free()
        for p in mesh.polygons:
            p.use_smooth = True
        mesh.materials.append(self.mats["cloud"])
        obj = bpy.data.objects.new("Puff", mesh)
        obj.location, obj.scale, obj.visible_shadow = at, size, False
        self.scene.collection.objects.link(obj)
        self.outside.append(obj)

    def numeral(self, words, at, tall):
        """Lit numerals standing upright, read from the entrance's side (a SurfaceGui's text in the game)."""
        curve = bpy.data.curves.new("Numeral", "FONT")
        curve.body, curve.size, curve.align_x, curve.align_y, curve.extrude = words, tall, "CENTER", "CENTER", 0.12
        curve.materials.append(self.mats["light"])
        obj = bpy.data.objects.new("Numeral", curve)
        obj.location, obj.rotation_euler = at, (math.pi / 2, 0.0, 0.0)
        self.scene.collection.objects.link(obj)

    def clouds(self, sea, near, towers, seed):
        """The cloud sea `sea` under the floor, cloud heads standing out of it, and drifts near the room."""
        rng = random.Random(seed)
        self.add("CloudSea", tb.sector(0.0, 4000.0, sea - 2.0, sea, n=48), "sea", outside=True, shadow=False)
        for _ in range(towers):
            a, r = rng.uniform(0, 2 * math.pi), rng.uniform(280.0, 1500.0)
            wide, tall = rng.uniform(70.0, 220.0), rng.uniform(26.0, 80.0)
            for k in range(3):
                dx, dy = rng.uniform(-0.6, 0.6) * wide, rng.uniform(-0.6, 0.6) * wide
                share = 1.0 if k == 0 else rng.uniform(0.45, 0.8)
                self.puff((r * math.cos(a) + dx, r * math.sin(a) + dy, sea + tall * share * 0.35),
                          (wide * share, wide * share * rng.uniform(0.7, 1.0), tall * share))
        for a, r, z in near:
            wide = rng.uniform(26.0, 44.0)
            for k in range(2):
                self.puff((r * math.cos(a) + k * wide * 0.7, r * math.sin(a) + k * 6.0, z - k * 3.0),
                          (wide * (1.0 - 0.3 * k), wide * 0.7, 5.5 - 1.5 * k))

    def floor(self, body=3.0):
        """The fight floor every direction shares: the deck, its lip, one inlaid ring, a thin lit line inside the lip."""
        self.add("Floor", tb.sector(0.0, FLOOR_R, -body, 0.0), "floor")
        self.add("FloorLip", tb.sector(FLOOR_R - 2.0, FLOOR_R, 0.0, 0.3), "stone")
        self.add("FloorInlay", tb.sector(30.0, 31.0, 0.0, 0.05), "dark", shadow=False)
        self.add("FloorLine", tb.sector(FLOOR_R - 2.6, FLOOR_R - 2.2, 0.0, 0.07), "light", shadow=False)


def crown(room):
    room.floor(4.0)
    room.add("StepRing", tb.sector(FLOOR_R, 60.0, -5.0, -1.5), "stone2")
    room.add("Neck", tb.sector(0.0, 54.0, -34.0, -5.0), "dark")
    room.add("Shaft", tb.sector(0.0, 44.0, -90.0, -34.0), "dark")
    for k, tall in enumerate((46.0, 40.0, 52.0, 44.0, 48.0, 38.0, 50.0, 42.0)):
        a = math.radians(22.5 + 45.0 * k)
        room.add(f"Blade{k}", prism(14.0, 5.0, 3.5, 2.0, tall, (0.0, 12.0)), "stone", polar(61.0, a, -1.5), out_at(a))
        room.add(f"BladeLine{k}", prism(0.5, 0.3, 0.3, 0.3, tall * 0.7, (0.0, 12.0 * 0.7)), "light",
                 polar(58.3, a, -1.3), out_at(a), shadow=False)
    for k, (y, z) in enumerate(((67.0, -4.0), (82.0, -10.0), (98.0, -18.0), (115.0, -28.0))):      # the foe's steps, afloat
        room.add(f"FoeStep{k}", box(14.0, 10.0, 2.0), "stone", (0.0, y, z))
    for k, (y, z) in enumerate(((-67.0, -3.5), (-82.0, -9.0))):                                    # the way in
        room.add(f"InStep{k}", box(12.0, 10.0, 2.0), "stone", (0.0, y, z))
    room.add("NumberSlab", prism(18.0, 1.5, 15.0, 1.5, 10.0), "dark", (0.0, 63.0, 15.0))
    room.numeral(str(SHOWN), (0.0, 62.1, 20.0), 7.0)
    for k, (x, y, top) in enumerate(((-150.0, 330.0, -26.0), (200.0, 430.0, -40.0), (430.0, 110.0, -18.0))):
        room.add(f"Spire{k}", tb.sector(0.0, 46.0, -75.0, top - 8.0, n=24), "stone2", (x, y, 0.0), outside=True)
        room.add(f"SpireTop{k}", tb.sector(0.0, 54.0, top - 8.0, top, n=24), "stone", (x, y, 0.0), outside=True)
        for j in range(8):
            a = math.radians(22.5 + 45.0 * j)
            room.add(f"SpireBlade{k}_{j}", prism(12.0, 4.0, 3.0, 2.0, 34.0, (0.0, 9.0)), "stone",
                     (x + 54.0 * math.cos(a), y + 54.0 * math.sin(a), top), out_at(a), outside=True)
    near = [(math.radians(a), r, z) for a, r, z in ((70, 150, -8), (118, 190, 4), (20, 130, -14), (160, 140, -4),
                                                    (200, 170, -12), (335, 160, 2), (255, 180, -10), (290, 140, -16))]
    room.clouds(-70.0, near, 70, 56)


def well(room):
    wall, top, deep = 84.0, 7, 9
    room.floor(3.0)
    room.add("Pillar", tb.sector(0.0, 40.0, -18.0 * deep, -3.0), "dark")
    for sign, name in ((1, "FoeBridge"), (-1, "InBridge")):
        room.add(name, box(10.0, wall - FLOOR_R + 2.0, 2.0), "stone", (0.0, sign * (wall + FLOOR_R) / 2, -2.0))
        room.add(name + "Line", box(0.4, wall - FLOOR_R, 0.06), "light", (0.0, sign * (wall + FLOOR_R) / 2, 0.0), shadow=False)
    door = [(math.pi / 2, math.asin(6.0 / wall)), (3 * math.pi / 2, math.asin(6.0 / wall))]
    for k in range(-deep, top + 1):
        z = 18.0 * k
        gaps = door if k == 0 else ()
        room.add(f"Band{k}", ring(wall, wall + 6.0, z + 1.0, z + (16.0 if k == 0 else 18.0), gaps), "stone" if k % 2 else "dark")
        if k == 0:
            room.add("BandLintel", ring(wall, wall + 6.0, 16.0, 18.0), "dark")
        room.add(f"Seam{k}", ring(wall - 0.3, wall + 6.0, z, z + 1.0, gaps), "light", shadow=False)
        room.add(f"Ledge{k}", ring(wall - 3.5, wall, z + 1.0, z + 2.4, gaps), "dark")
        ticks = []
        for j in range(48):
            a = 2 * math.pi * (j + 0.5) / 48
            ticks.append(moved(box(1.6, 1.2, 8.0 if j % 4 == 0 else 4.5), polar(wall - 0.5, a, z + 4.0), out_at(a)))
        room.add(f"Ticks{k}", merged(ticks), "trim")
    for sign, name in ((1, "FoeDoor"), (-1, "InDoor")):
        room.add(name + "Floor", box(12.0, 14.0, 1.0), "stone", (0.0, sign * (wall + 7.0), -1.0))
        room.add(name + "Light", box(12.0, 0.5, 16.0), "light", (0.0, sign * (wall + 13.0), 0.0), shadow=False)
        room.add(name + "Roof", box(14.0, 8.0, 1.0), "dark", (0.0, sign * (wall + 10.0), 16.0))
        for side in (-1, 1):
            room.add(f"{name}Side{side}", box(1.0, 8.0, 16.0), "dark", (side * 6.5, sign * (wall + 10.0), 0.0))
    room.add("NumberPlate", box(16.0, 1.0, 9.0), "dark", (0.0, wall - 0.6, 20.0))
    room.numeral(str(SHOWN), (0.0, wall - 1.3, 24.5), 6.5)
    room.add("Mist", tb.sector(0.0, wall, -18.0 * deep - 1.0, -18.0 * deep), "mist", outside=True, shadow=False)


def hall(room):
    wall, thick, high, rise = 72.0, 4.0, 46.0, 58.0
    room.add("Floor", tb.sector(0.0, wall, -2.0, 0.0), "floor")
    room.add("Dais", tb.sector(0.0, FLOOR_R, 0.0, 0.6), "floor2")
    room.add("DaisLine", tb.sector(FLOOR_R - 1.2, FLOOR_R - 0.8, 0.6, 0.67), "light", shadow=False)
    lit, turns = SHOWN % 10, SHOWN // 10
    for k in range(10):                                                         # the marks: one lit a floor, clockwise
        a = math.pi / 2 - math.radians(36.0 * k)
        room.add(f"Mark{k}", tb.sector(26.0, 29.0, 0.6, 0.68, a - math.radians(30.0), a - math.radians(6.0), n=8),
                 "inlay" if k < lit else "dark", shadow=False)
        room.add(f"Pip{k}", tb.sector(22.0, 23.4, 0.6, 0.68, a - math.radians(24.0), a - math.radians(12.0), n=4),
                 "inlay" if k < turns else "dark", shadow=False)
    gaps = []
    for k in range(24):
        if k in (1, 2, 22, 23):                                                  # the gate stands alone in its wall
            continue
        half = math.asin((22.0 if k == 0 else 5.0 if k == 12 else 2.5) / wall)
        gaps.append((math.pi / 2 + math.radians(15.0 * k), half))
    door = next(g for g in gaps if abs(g[0] - 3 * math.pi / 2) < 1e-6)
    room.add("Piers", ring(wall, wall + thick, 0.0, high, gaps), "stone")
    sills = [tb.sector(wall, wall + thick, 0.0, 3.0, a - half, a + half, n=2) for k, (a, half) in enumerate(gaps) if k and (a, half) != door]
    room.add("Sills", merged(sills), "stone2")
    a, half = door
    room.add("OverDoor", tb.sector(wall, wall + thick, 14.0, high, a - half, a + half, n=4), "stone")
    room.add("Upper", tb.sector(wall, wall + thick, high, rise), "stone2")
    room.add("UpperLine", tb.sector(wall - 0.4, wall, high, high + 1.0), "light", shadow=False)
    steps = ((76.0, 62.0, 58.0, 61.0), (64.0, 52.0, 61.0, 67.0), (54.0, 44.0, 67.0, 72.0), (46.0, 36.0, 72.0, 76.0),
             (38.0, 30.0, 76.0, 79.0), (32.0, 24.0, 79.0, 81.0))
    for k, (r1, r0, z0, z1) in enumerate(steps):                                # the dome, in steps, open at its top
        room.add(f"Dome{k}", tb.sector(r0, r1, z0, z1), "stone" if k % 2 else "stone2")
    room.add("Landing", box(48.0, 20.0, 2.0), "stone", (0.0, wall + thick + 10.0, -2.0))
    room.add("InLanding", box(14.0, 12.0, 2.0), "stone", (0.0, -(wall + thick + 6.0), -2.0))
    room.add("Foot", tb.sector(0.0, wall + thick, -60.0, -2.0), "dark")
    near = [(math.radians(a), r, z) for a, r, z in ((84, 190, 6), (100, 260, 16), (64, 240, -2), (118, 210, 10),
                                                    (20, 170, 8), (165, 180, 12), (300, 190, 4), (230, 200, 14))]
    room.clouds(-60.0, near, 70, 57)


BUILD = {"A": crown, "B": well, "C": hall}


class Figure:
    """A stand-in of grey boxes: legs, body, head."""

    def __init__(self, room, name, mat, scale=1.0):
        self.parts = []
        for part, size, z in (("Legs", (2.0, 1.0, 2.0), 0.0), ("Body", (4.0, 1.0, 2.0), 2.0), ("Head", (1.2, 1.2, 1.2), 4.0)):
            obj = tb.solid(room.scene, name + part, box(*(s * scale for s in size)), room.mats[mat])
            self.parts.append((obj, z * scale))

    def at(self, x, y, z=0.0):
        for obj, up in self.parts:
            obj.location = (x, y, z + up)


# --- the scene and the camera --------------------------------------------------------------------------------------------

def build(key):
    spec = ROOMS[key]
    tb.by_day()
    d = dict(look.DIRECTIONS["M"])
    az, el = spec["sun"]
    d["sun"] = (az, el, d["sun"][2], d["sun"][3], True)
    look.FOG.update(colour=look.srgb(spec["fog"][0]), density=spec["fog"][1], azimuth=0.0, away=None)
    scene = bl.reset_scene()
    mats = {name: look.painted("Room" + name, *pair) for name, pair in GREY.items()}
    mats["light"] = look.glowing("RoomLight", LIGHT, 2.2)
    mats["inlay"] = look.glowing("RoomInlay", LIGHT, 0.7)
    mats["mist"] = look.glowing("RoomMist", "#F2F6FF", 1.4)
    mats["cloud"] = look.painted("RoomCloud", "#FFFFFF", "#A9B8DC")
    mats["sea"] = look.painted("RoomSea", "#CDD7EE", "#CDD7EE")
    room = Room(scene, mats)
    BUILD[key](room)
    who = dict(avatar=Figure(room, "Avatar", "avatar"), lead=Figure(room, "Lead", "lead", 1.15),
               foe=Figure(room, "Foe", "foe", 1.15))
    look.sky(scene, d)
    look.sun(scene, d)
    r = scene.render
    for engine in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            r.engine = engine
            break
        except TypeError:
            continue
    r.resolution_percentage = 100
    scene.view_settings.view_transform = "Standard"
    scene.eevee.taa_render_samples = 8
    for attr, val in (("use_shadows", True), ("shadow_ray_count", 1), ("use_raytracing", False)):
        try:
            setattr(scene.eevee, attr, val)
        except AttributeError:
            pass
    data = bpy.data.cameras.new("Player")
    data.sensor_fit, data.angle_y, data.clip_end = "VERTICAL", math.radians(look.FOV), 9000
    cam = bpy.data.objects.new("Player", data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    return scene, d, room, who, cam


def behind(x, y, z, pitch):
    """The player's camera behind an avatar at x, y on a floor at z, looking toward +Y, `pitch` degrees down."""
    p = math.radians(pitch)
    focus = Vector((x, y, z + 3.0 + look.FOCUS))
    return focus + Vector((0.0, -math.cos(p), math.sin(p))) * look.ZOOM, focus


def shot(scene, d, cam, eye, target, path, size):
    cam.location = eye
    cam.rotation_euler = (Vector(target) - Vector(eye)).to_track_quat("-Z", "Y").to_euler()
    scene.render.resolution_x, scene.render.resolution_y = size
    rs.save(look.finish(look.render_linear(scene, path.with_suffix(".exr")), d), path)
    path.with_suffix(".exr").unlink(missing_ok=True)


def stage(key, who, u):
    """The figures `u` of the way through the walk in (0 at the entrance, 1 at the stand); past 1, the fight."""
    y0, z0 = ROOMS[key]["enter"]
    wy, wz = ROOMS[key]["way"]
    if u > 1.0:
        avatar = (0.0, -STAND, 0.0)
        who["lead"].at(-2.5, -1.5)
        who["foe"].at(2.5, 3.5)
    else:
        y = y0 + (-STAND - y0) * u
        z = z0 if abs(y) > FLOOR_R else 0.0
        avatar = (0.0, y, z)
        who["lead"].at(3.5, y + 2.5, z)
        fy = wy + (STAND - wy) * u
        who["foe"].at(0.0, fy, wz if abs(fy) > FLOOR_R + (12.0 if key == "A" else 0.0) else 0.0)
    who["avatar"].at(*avatar)
    return avatar


def count(objs):
    tris = 0
    for obj in objs:
        obj.data.calc_loop_triangles()
        tris += len(obj.data.loop_triangles)
    return dict(parts=len(objs), triangles=tris)


def see(out, key, what):
    scene, d, room, who, cam = build(key)
    spec = ROOMS[key]
    if "stills" in what:
        avatar = stage(key, who, 0.0)
        shot(scene, d, cam, *behind(*avatar, 20.0), out / f"{key}_enter.png", SIZE)
        avatar = stage(key, who, 2.0)
        shot(scene, d, cam, *behind(*avatar, 20.0), out / f"{key}_fight.png", SIZE)
        shot(scene, d, cam, *behind(*avatar, -8.0), out / f"{key}_up.png", SIZE)
        shot(scene, d, cam, Vector(spec["whole"][0]), Vector(spec["whole"][1]), out / f"{key}_whole.png", SIZE)
    if "take" in what:
        folder = out / "take" / key
        folder.mkdir(parents=True, exist_ok=True)
        for old in folder.glob("f*.png"):
            old.unlink()
        steps = round((abs(spec["enter"][0]) - STAND) / WALK * RATE)
        for i in range(steps + 1):
            avatar = stage(key, who, i / steps)
            shot(scene, d, cam, *behind(*avatar, 20.0), folder / f"f{i:03d}.png", TAKE)
        avatar = stage(key, who, 2.0)
        shot(scene, d, cam, *behind(*avatar, 20.0), folder / f"f{steps + 1:03d}.png", TAKE)
    wide = max(math.hypot(o.location.x, o.location.y) + max(o.dimensions.x, o.dimensions.y) / 2 for o in room.pieces)
    low = min(o.location.z + min(v[2] for v in o.bound_box) for o in room.pieces)
    high = max(o.location.z + max(v[2] for v in o.bound_box) for o in room.pieces)
    record = dict(name=NAMES[key], floor=FLOOR_R, reach=round(wide, 1), low=round(low, 1), high=round(high, 1),
                  room=count(room.pieces), outside=count(room.outside), sun=spec["sun"], fog=spec["fog"])
    (out / f"{key}.json").write_text(json.dumps(record, indent=1), encoding="utf-8", newline="\n")
    print(f"AR56: {key} done", record)


# --- the movie and the sheet ---------------------------------------------------------------------------------------------

def movie(out, key):
    """A direction's take as an MP4 at 30 a second (Blender's own encoder): each frame shown 30 / RATE times, then the
    fight's frame held."""
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = *TAKE, 100
    scene.render.fps = 30
    folder = out / "take" / key
    shots = sorted(folder.glob("f*.png"))
    files = [s.name for s in shots[:-1] for _ in range(30 // RATE)] + [shots[-1].name] * round(HOLD * 30)
    se = scene.sequence_editor_create()
    strips = se.strips if hasattr(se, "strips") else se.sequences
    first = strips.new_image("Frames", str(folder / files[0]), 1, 1)
    first.directory = str(folder) + "/"
    first.elements[0].filename = files[0]
    for name in files[1:]:
        first.elements.append(name)
    scene.frame_start, scene.frame_end = 1, len(files)
    settings = scene.render.image_settings
    if hasattr(settings, "media_type"):
        settings.media_type = "VIDEO"
    settings.file_format = "FFMPEG"
    scene.render.ffmpeg.format, scene.render.ffmpeg.codec = "MPEG4", "H264"
    scene.render.ffmpeg.constant_rate_factor = "HIGH"
    scene.render.filepath = str(out / f"tower_room_{key}.mp4")
    bpy.ops.render.render(animation=True)


VIEWS = (("enter", "as the player steps in"), ("fight", "a fight's frame"), ("up", "the camera tilted 8 degrees up"),
         ("whole", "the room whole"))
HOW = {
    "A": "High: nothing stands over you, cloud drifts past at the floor's height, lower spires stand in the cloud sea. "
         "Climbing: the foe comes up floating steps over the far rim. The number: lit numerals on a slab afloat over "
         "those steps. The blades' shadows lie across the floor, which is most of the frame.",
    "B": "High: the rings go on over you and under you, and the gap shows the depth from the bridge. Climbing: every "
         "ring is a floor, ticked like a measure. The foe walks the far bridge from a lit doorway; the number is a plate "
         "over it. From the floor's middle the gap is hidden by the floor's own edge: the depth is the entrance's.",
    "C": "High: the sun falls from one opening far overhead, and the gate stands on the sky with cloud heads at its "
         "sill. Climbing: ten marks round the pool, one lit a floor, a pip a full turn; no numeral in the room. The foe "
         "walks in through the gate, dark against the light.",
}


def sheet(out):
    import ui_sheet as ui

    gap, left = 14, 150
    tw, th = SIZE[0] // 2, SIZE[1] // 2                               # the smallest phone, 568 x 320
    keys = [k for k in NAMES if (out / f"{k}.json").exists()]
    notes = ["Each frame is the smallest phone's size, 568 x 320. The player's camera: 12.5 studs behind the avatar, 20 "
             "degrees down, FOV 70. Grey boxes: the avatar (mid), the lead (light), the foe (dark). The fight floor is "
             f"{FLOOR_R:.0f} in radius in all three (the old grey disc is 24); the floor shown is {SHOWN}. By the game's "
             "day; each room's sun is its own."]
    for k in keys:
        m = json.loads((out / f"{k}.json").read_text(encoding="utf-8"))
        notes.append(f"{k}, {m['name']}. {HOW[k]} Size: {2 * m['reach']:.0f} across, from {m['low']:.0f} to {m['high']:.0f} "
                     f"high. The block: {m['room']['parts']} parts, {m['room']['triangles']} triangles a copy; outside "
                     f"(cloud, far spires, mist) {m['outside']['parts']} parts, {m['outside']['triangles']} triangles.")
    text = [ln for n in notes for ln in textwrap.wrap(n, 250)]
    ui.K = 1
    page = ui.Sheet(left + len(VIEWS) * (tw + gap) + gap, 76 + len(keys) * (th + gap) + 20 + len(text) * 19, "#14151C")
    t = page.tile(0, 0, page.w, page.h)
    t.text(gap, 14, 20, "Grow your Anime, the Tower's room (AR56): three directions in grey, from the player's camera",
           "#EDE6D6", bold=0.2)
    for c, (view, said) in enumerate(VIEWS):
        t.text(left + gap + c * (tw + gap), 46, 13, said, "#EDE6D6")
    y = 68
    for k in keys:
        t.text(gap, y + th // 2 - 20, 16, f"{k}, {NAMES[k]}", "#EDE6D6")
        for n, ln in enumerate(textwrap.wrap(SAID[k], 20)):
            t.text(gap, y + th // 2 + 2 + n * 16, 12, ln, "#B4AC9C")
        for c, (view, said) in enumerate(VIEWS):
            x = left + gap + c * (tw + gap)
            rs.paste(page.px, rs.shrink(rs.load(out / f"{k}_{view}.png"), 0.5), x, y)
        y += th + gap
    for n, ln in enumerate(text):
        t.text(gap, y + 8 + n * 19, 14, ln, "#B4AC9C")
    for layer in ui.text_layers(page.px.shape[1], page.px.shape[0], page.items).values():
        rs.paste(page.px, layer, 0, 0)
    rs.save(page.px, out / "tower_room.png")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    if args[0] == "see":
        see(out, args[1], [a for a in args[2:] if a in ("stills", "take")] or ["stills", "take"])
    elif args[0] == "movie":
        movie(out, args[1])
    elif args[0] == "sheet":
        sheet(out)


if __name__ == "__main__":
    main()
