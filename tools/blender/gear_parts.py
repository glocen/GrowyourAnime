"""AR6, batch 2 and on: the parts every gear kind past batch 1 shares, and its renders.

Batch 1 drew each kind from the swords' parts (gear_sword_ladder.py, gear_sword_sets.py). Batch 2's eight shared kinds
(Shoulders, Chest Armor, Gloves, Bracers, Boots, Cloak, Amulet, Earring) draw from these: a lathe for anything round,
a plate for anything flat, a cut stone in its bezel, and the set's own ornaments, kept in one place so a set's word
looks the same on every kind (Stormcall curls out, Gloamforge stands in prongs, Nightloom lies in shuttles, Gales
sweeps back, Hoarfrost is cut square, Embers swells round its stone).

A kind's script gives DESIGNS, build(d) -> (scene, parts), FILL, LEAST, DROP and WORDS; renders() and the sheets do
the rest. Workbench only: no GPU turn.
"""
import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_sword_ladder as g  # noqa: E402
import gear_sword_sets as s  # noqa: E402

mat = g.material
# The new keys' greys, beside the ladder's: a dark lining (leather's value, near-black in colour), cloth, a cord.
for _key, _value in dict(liner=g.GREY["leather"], cloth=0.52, cord=0.38).items():
    g.GREY.setdefault(_key, _value)

RARITIES = s.RARITIES


def design(name, rarity, note, key, **more):
    """A design's defaults: its main material `key`, its trim, and whatever its kind reads."""
    base = dict(name=name, rarity=rarity, note=note, key=key, trim=key, stone=None, line=None, edge=False, orn=None)
    base.update(more)
    return base


# --- shapes ------------------------------------------------------------------------------------------------------------

def lathe(name, profile, key, a0=0.0, a1=360.0, thick=0.06, deep=1.0, wave=None, steps=48):
    """A profile (r, z) turned about Z from angle a0 to a1 (0 faces the camera, 90 is the picture's right), `deep`
    times as deep as it's wide, given a thickness. `wave(angle, z)` scales the radius: folds, flutes."""
    closed = a1 - a0 >= 359.9
    n = steps if closed else max(3, int(steps * (a1 - a0) / 360) + 1)
    bm, cols = bmesh.new(), []
    for i in range(n):
        ad = a0 + (a1 - a0) * i / (n if closed else n - 1)
        a = math.radians(ad)
        cols.append([bm.verts.new((r * (wave(ad, z) if wave else 1.0) * math.sin(a),
                                   -r * (wave(ad, z) if wave else 1.0) * deep * math.cos(a), z)) for r, z in profile])
    for i in range(len(cols) if closed else len(cols) - 1):
        p, q = cols[i], cols[(i + 1) % len(cols)]
        for j in range(len(profile) - 1):
            bm.faces.new((p[j], p[j + 1], q[j + 1], q[j]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj = bl.object_from_bmesh(name, bm, mat(key))
    if thick:
        mod = obj.modifiers.new("Solid", "SOLIDIFY")
        mod.thickness, mod.offset = thick, 0.0
        bl.apply_modifiers(obj)
    return bl.smooth_by_angle(obj, 40.0)


def sheet_surface(name, key, point, us, vs, thick=0.06):
    """A grid surface: point(u, v) -> (x, y, z) over the values us and vs, given a thickness."""
    bm = bmesh.new()
    grid = [[bm.verts.new(point(u, v)) for v in vs] for u in us]
    for i in range(len(us) - 1):
        for j in range(len(vs) - 1):
            bm.faces.new((grid[i][j], grid[i][j + 1], grid[i + 1][j + 1], grid[i + 1][j]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj = bl.object_from_bmesh(name, bm, mat(key))
    if thick:
        mod = obj.modifiers.new("Solid", "SOLIDIFY")
        mod.thickness, mod.offset = thick, 0.0
        bl.apply_modifiers(obj)
    return bl.smooth_by_angle(obj, 40.0)


def hoop(name, radius, minor, key, z=0.0, deep=1.0, high=1.0, segments=48):
    """A band lying round Z at height z."""
    t = bl.torus(name, radius, minor, segments, 10, mat(key))
    return bl.smooth_by_angle(bl.place(t, (0, 0, z), (0, 0, 0), (1, deep, high)), 40.0)


def facing(name, radius, minor, key, at, arc=360.0, turn=0.0):
    """A torus standing in the picture's plane, facing the camera, centred at `at`."""
    t = bl.torus(name, radius, minor, 40, 10, mat(key), arc=arc)
    bl.place(t, (0, 0, 0), (0, 0, turn))
    return bl.smooth_by_angle(bl.place(t, at, (90, 0, 0)), 40.0)


def flat(name, outline, thick, key, y=0.0, bevel=0.03):
    """A plate drawn from the front (x, z), `thick` deep, its middle at y."""
    return g.plate(name, outline, thick, key, y=y, bevel=bevel)


def tube(name, points, radii, key, sides=10):
    pts = [Vector(p) for p in points]
    rr = radii if isinstance(radii, (list, tuple)) else [radii] * len(pts)
    return bl.smooth_by_angle(bl.tube_along(name, pts, rr, sides=sides, material=mat(key)), 50.0)


def curve(points, samples=24):
    return [tuple(p) for p in bl.smooth_path(points, samples)]


def ball(name, radius, key, at, squash=(1, 1, 1), segments=12, rings=8):
    return bl.place(bl.sphere(name, radius, segments, rings, mat(key)), at, (0, 0, 0), squash)


def move(obj, matrix):
    obj.data.transform(matrix)
    obj.data.update()
    return obj


def aim(obj, at=(0, 0, 0), up=(0, 0, 1)):
    """Turns a part built along Z so Z points along `up`, then moves it to `at`."""
    q = Vector((0, 0, 1)).rotation_difference(Vector(up).normalized())
    return move(obj, Matrix.Translation(Vector(at)) @ q.to_matrix().to_4x4())


# --- outlines, drawn from the front ------------------------------------------------------------------------------------

mirrored = g.mirrored


def shifted(outline, dx=0.0, dz=0.0, sx=1.0, sz=1.0):
    return [(x * sx + dx, z * sz + dz) for x, z in outline]


def turned(outline, degrees, about=(0.0, 0.0)):
    a = math.radians(degrees)
    ca, sa = math.cos(a), math.sin(a)
    return [(about[0] + (x - about[0]) * ca - (z - about[1]) * sa, about[1] + (x - about[0]) * sa + (z - about[1]) * ca)
            for x, z in outline]


def flipped(outline):
    """The same outline on the other side, kept in order."""
    return [(-x, z) for x, z in reversed(outline)]


def leaf(length, width, tip=0.0, bend=0.0, n=9):
    """A pointed leaf or blade from its foot at the origin up its length, `bend` sweeping its point sideways."""
    left, right = [], []
    for i in range(n + 1):
        t = i / n
        w = width * math.sin(math.pi * min(t * (1.0 - tip * 0.3) + 0.0001, 1.0)) ** 0.8 * (1 - t) ** 0.25 / 2
        x0 = bend * t * t
        left.append((x0 - w, t * length))
        right.append((x0 + w, t * length))
    return right + list(reversed(left[1:-1]))


def star(points, outer, inner, turn=90.0, long=1.0):
    """A star of `points` tapering points; the upright pair `long` times the others."""
    out = []
    for i in range(points * 2):
        a = math.radians(turn + 180.0 * i / points)
        r = outer if i % 2 == 0 else inner
        if i % 2 == 0 and abs(math.sin(a)) > 0.9:
            r *= long
        out.append((r * math.cos(a), r * math.sin(a)))
    return out


def ellipse(rx, rz, n=24, dx=0.0, dz=0.0):
    return [(dx + rx * math.cos(2 * math.pi * i / n), dz + rz * math.sin(2 * math.pi * i / n)) for i in range(n)]


# The sets' ornaments, each from its right half (top middle round to foot middle), for g.mirrored, at unit size
# round a stone at the origin. Scaled by each kind to its piece.
CURL_OUT = [(0.0, 0.42), (0.3, 0.44), (0.46, 0.62), (0.56, 0.92), (0.76, 1.12), (1.0, 1.12), (1.14, 0.96), (1.1, 0.76),
            (0.96, 0.7), (0.92, 0.86), (0.82, 0.92), (0.7, 0.8), (0.66, 0.5), (0.62, 0.1), (0.44, -0.34), (0.0, -0.44)]
PRONGS = [(0.0, 0.4), (0.26, 0.4), (0.34, 0.8), (0.42, 1.36), (0.54, 0.8), (0.58, 0.3), (0.44, -0.3), (0.0, -0.42)]
SPADE = [(0.0, 0.62), (0.22, 0.5), (0.5, 0.36), (0.6, 0.0), (0.42, -0.36), (0.18, -0.52), (0.0, -0.7)]
SWELL = [(0.0, 0.46), (0.3, 0.42), (0.5, 0.2), (0.52, -0.1), (0.36, -0.38), (0.0, -0.48)]
SHUTTLE = [(-0.5, 0.0), (-0.22, 0.13), (0.22, 0.13), (0.5, 0.0), (0.22, -0.13), (-0.22, -0.13)]  # whole, lying flat
VANE = [(0.0, 0.0), (0.46, 0.3), (1.1, 0.86), (0.82, 0.38), (1.22, 0.42), (0.6, 0.06), (0.2, -0.16)]  # swept up and out


def set_ornament(word, scale=1.0, at=(0.0, 0.0)):
    """The set's ornament round its stone as one outline, scaled and moved; None for a set that has none."""
    shape = dict(Stormcall=CURL_OUT, Gloamforge=PRONGS, Hoarfrost=SPADE, Embers=SWELL).get(word)
    return shifted(mirrored(shape), at[0], at[1], scale, scale) if shape else None


# --- stones ------------------------------------------------------------------------------------------------------------

def stone(kind, radius, at, trim, square=False, bezel=True):
    """A cut stone facing the camera at `at`, in its bezel: round and upright, or square on its corner."""
    x, y, z = at
    parts = []
    if square:
        gem = bl.cylinder("Stone", radius * 1.15, radius * 0.6, segments=4, material=mat(kind), radius_top=radius * 0.55)
        parts.append(bl.place(gem, (x, y - radius * 0.25, z), (90, 0, 0)))
        if bezel:
            parts.append(bl.place(bl.cylinder("Bezel", radius * 1.5, radius * 0.3, segments=4, material=mat(trim)),
                                  (x, y + radius * 0.1, z), (90, 0, 0)))
    else:
        parts.append(bl.place(bl.sphere("Stone", radius, segments=6, rings=3, material=mat(kind)), (x, y - radius * 0.1, z),
                              (0, 0, 30), (1, 0.5, 1.15)))
        if bezel:
            parts.append(facing("Bezel", radius * 1.2, 0.045, trim, (x, y + 0.02, z)))
    return parts


def stone_of(d, size, at):
    """The design's own stone, if it has one: d["stone"] is (kind, factor), a square cut for Hoarfrost and Gloamforge."""
    if not d["stone"]:
        return []
    kind, k = d["stone"]
    return stone(kind, size * k, at, d["trim"], square=d.get("cut") == "square")


# --- renders -----------------------------------------------------------------------------------------------------------

def scene_of(parts_fn, tilt, spin):
    """A fresh scene, the parts built in it, then the whole turned to the picture's view."""
    scene = bl.reset_scene()
    scene.world = bpy.data.worlds.new("Room")
    parts = parts_fn()
    lay = Matrix.Rotation(math.radians(tilt), 4, "X") @ Matrix.Rotation(math.radians(spin), 4, "Z")
    for obj in parts:
        move(obj, lay)
    return scene, parts


def renders(kind, out, keep=None):
    """Each design centred in its square, at the kind's FILL; the largest sets the scale, and a plain one is drawn no
    smaller than LEAST of it. `keep(name, shot)`, if given, is handed each shot as it's taken."""
    sizes = []
    for d in kind.DESIGNS:
        x0, x1, z0, z1 = g.bounds(kind.build(d)[1])
        sizes.append(max(x1 - x0, z1 - z0))
    shots = {}
    for d, size in zip(kind.DESIGNS, sizes):
        scene, parts = kind.build(d)
        x0, x1, z0, z1 = g.bounds(parts)
        span = max(size, kind.LEAST * max(sizes)) / kind.FILL
        shot = g.shoot(scene, out, ((x0 + x1) / 2, (z0 + z1) / 2 + kind.DROP * span), span)
        shots[d["name"]] = keep(d["name"], shot) if keep else shot
        print(f"{d['name']}: fills {size / span:.2f} of the square")
    return shots


def check_names(designs):
    assert len(designs) == 15, "a kind has fifteen designs"
    assert all(len(d["name"]) <= 24 for d in designs), [d["name"] for d in designs if len(d["name"]) > 24]
    for r in RARITIES:
        assert sum(d["rarity"] == r for d in designs) == 3, r


def main(kind):
    out = bl.out_dir()
    check_names(kind.DESIGNS)
    s.sheet(out, renders(kind, out), kind.DESIGNS, kind.WORDS)
