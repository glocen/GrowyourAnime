"""The enemies a lead's basic attack lands on, for its effect rows' rule 4 guards (AR26): every target the fight puts
before a lead, built from the delivered recipes, at its game size (Definitions/Enemies' Scale, model:ScaleTo about its
root, feet on the floor), in the lead's foot frame (the lead faces -Z, the target `ahead` studs before him facing him).

- the ordinary Shade under each of its four masks;
- the Brawler elite at 1.35, with its second mask on its Left Arm (AR2, section 5);
- the Lamplighter at 1.5 (AR7), its pole and lantern by their meshes.

Two guards: `inside` (a point within a margin of a part; a mask, the pole and the lantern as slices of BAND, each
round its mesh in that slice) and `over_face` (a point drawing over a face, a mask or the
Lamplighter's head, from a camera: the face lies behind it along the camera's ray). `over_face` tries the face's box
first, then its triangles by a bundle of five rays, so a point beside a mask's outline isn't failed for its box's
corner. The cameras orbit the target's chest at the game's distance and height (kirra_scarf_step_fx's), at the four
headings the seen tables use, or at every 5 degrees and two pitches (`SWEEP`), since the player turns the camera.

Fixed rows are tested with each target spaced by its depth (`on_face`, the tier 2 ask to Faber, AR26); `root_to_root`
reports them as the game stands today, root to root, without failing them. A crack whose lines pass before a face on
their way out is tested at its ends (`near_face`, by the face's triangles), on the content check's word of 2026-11-17.

Imported by the combo scripts; run alone, it prints each target's size and where its parts are.
"""

import functools
import itertools
import json
import math
import re
from pathlib import Path

import kirra_scarf_step_fx as k

HANDOFF = k.ROOT / "build" / "handoff"
FRONT = 0.74  # the ordinary Shade's torso face before its root, where the rows' touches are set
HEADINGS = (215, 145, 285, 28)  # watt_combo_fx's: the replay's camera, its mirror, +-70 round the fight, the review camera
SWEEP = tuple(itertools.product(range(0, 360, 5), (1.0, 0.4)))  # (heading, share of the camera's height)
BAND = 0.2  # studs: a mesh part is kept as boxes this tall


def mesh_points(path, centre=None, frame=None, size=1.0):
    """A delivered mesh's corners and triangles in its recipe's frame: at the mesh's own centre, or at `centre`
    turned by `frame` (right, up, facing: where its +X, +Y and -Z point) and grown by `size`."""
    m = json.loads(Path(path).read_text(encoding="utf-8"))
    p = m["p"]
    local = [p[i:i + 3] for i in range(0, len(p), 3)] if isinstance(p[0], (int, float)) else p
    if frame is None:
        c = centre or m["c"]
        pts = [[c[j] + q[j] * size for j in range(3)] for q in local]
    else:
        right, up, facing = frame
        pts = [[centre[j] + size * (q[0] * right[j] + q[1] * up[j] - q[2] * facing[j]) for j in range(3)] for q in local]
    f = m["f"]
    tris = [f[i:i + 3] for i in range(0, len(f), 9)]  # each triangle: its 3 corners, then its normals' and UVs'
    return pts, [[pts[a], pts[b], pts[c]] for a, b, c in tris]


def banded(tris, band=BAND):
    """A mesh as boxes (centre, half size), one per `band` of height, each round the mesh's surface in that band,
    sampled across every triangle: a pole or a lantern that its own box would overstate."""
    out = {}
    for a, b, c in tris:
        for u in range(7):
            for v in range(7 - u):
                s, t = u / 6, v / 6
                q = [a[j] + (b[j] - a[j]) * s + (c[j] - a[j]) * t for j in range(3)]
                out.setdefault(math.floor(q[1] / band), []).append(q)
    boxes = []
    for key, qs in out.items():
        lo, hi = [min(q[j] for q in qs) for j in range(3)], [max(q[j] for q in qs) for j in range(3)]
        boxes.append(([(lo[j] + hi[j]) / 2 for j in range(3)], [(hi[j] - lo[j]) / 2 for j in range(3)]))
    return boxes


def box_of(points):
    lo, hi = [min(q[j] for q in points) for j in range(3)], [max(q[j] for q in points) for j in range(3)]
    return [(lo[j] + hi[j]) / 2 for j in range(3)], [(hi[j] - lo[j]) / 2 for j in range(3)]


ENEMIES = k.ROOT / "src" / "shared" / "Definitions" / "Enemies.luau"  # read only


def game_scale(enemy):
    """An enemy's Scale in Definitions/Enemies (read, not copied)."""
    text = ENEMIES.read_text(encoding="utf-8")
    return float(re.search(r'Id = "' + enemy + r'"[^}]*?Scale = ([0-9.]+)', text).group(1))


def in_game():
    """The targets the game has today: the Shade under each mask Definitions/Enemies names, the elite, the Lamplighter."""
    text = ENEMIES.read_text(encoding="utf-8")
    masks = set(re.findall(r'Rig = "Shade"[^}]*?Mask = "([A-Za-z]+)"', text))
    ids = set(re.findall(r'Id = "([a-z_]+)"', text))
    return [name for name in targets() if (name.startswith("Shade ") and name[6:] in masks)
            or (name == "Elite" and "brawler_elite" in ids) or (name == "Lamplighter" and "lamplighter" in ids)]


@functools.lru_cache(maxsize=None)
def targets():
    """Each target in its recipe's frame, at its recipe's size: parts (boxes), faces (each a box and triangles),
    its scale in the game, and its torso face before its root."""
    shade = json.loads(k.SHADE_RECIPE.read_text(encoding="utf-8"))
    body = [(p["centre"], [s / 2 for s in p["size"]]) for p in shade["pieces"] if "centre" in p]
    out = {}
    for mask in ("Brawler", "Guard", "Dasher", "Support"):
        m = shade["masks"][mask]
        pts, tris = mesh_points(HANDOFF / "Shade" / m["mesh"])
        face = (box_of(pts), tris)
        out[f"Shade {mask}"] = {"scale": 1.0, "parts": body + banded(tris), "body": body, "faces": [face],
                                 "front": FRONT}
    scale = game_scale("brawler_elite")
    arm = shade["elite"]["masks"]["Brawler"]
    pts, tris = mesh_points(HANDOFF / "Shade" / arm["mesh"], arm["centre"], (arm["right"], arm["up"], arm["facing"]),
                            shade["elite"]["size"])
    first = out["Shade Brawler"]
    second = (box_of(pts), tris)
    out["Elite"] = {"scale": scale, "parts": first["parts"] + banded(tris), "body": body,
                    "faces": first["faces"] + [second], "front": FRONT}
    lamp = json.loads((HANDOFF / "Lamplighter" / "Lamplighter.recipe.json").read_text(encoding="utf-8"))
    parts, faces = [], []
    for p in lamp["pieces"]:
        if "centre" not in p:
            continue
        if p["name"].endswith(("Pole", "Lantern")):
            parts += banded(mesh_points(HANDOFF / "Lamplighter" / p["mesh"])[1])
        else:
            parts.append((p["centre"], [s / 2 for s in p["size"]]))
        if p["name"].endswith("Head"):
            pts, tris = mesh_points(HANDOFF / "Lamplighter" / p["mesh"])
            faces.append((box_of(pts), tris))
    torso = next(p for p in lamp["pieces"] if p["name"].endswith("Torso"))
    out["Lamplighter"] = {"scale": game_scale("lamplighter"), "parts": parts, "body": parts, "faces": faces,
                          "front": torso["centre"][2] + torso["size"][2] / 2}
    return out


def where(q, scale, ahead):
    """A point of a target's recipe (its foot's frame, facing -Z) in the lead's: grown by its scale about its foot,
    turned to face him, `ahead` studs before him."""
    return [-q[0] * scale, q[1] * scale, -q[2] * scale - ahead]  # turned half round: its -Z, its front, toward him


def placed(name, ahead, which="parts"):
    """A target's parts and faces in the lead's frame, with it `ahead` studs before him: boxes as (low, high).
    `which` "body" leaves out the masks' slices (tested by their triangles instead)."""
    t = targets()[name]
    s = t["scale"]

    def box(b):
        c, h = b
        a, z = where([c[j] - h[j] for j in range(3)], s, ahead), where([c[j] + h[j] for j in range(3)], s, ahead)
        return [min(a[j], z[j]) for j in range(3)], [max(a[j], z[j]) for j in range(3)]

    faces = [(box(b), [[where(q, s, ahead) for q in tri] for tri in tris]) for b, tris in t["faces"]]
    return [box(b) for b in t[which]], faces


def on_face(name, ahead):
    """Where the target stands so its torso face is where the ordinary Shade's is at `ahead`: a row moved onto the
    target's own face (the rows stay; the target steps back by how much nearer its face is)."""
    t = targets()[name]
    return ahead + t["front"] * t["scale"] - FRONT


def chest(name):
    return k.CHEST * targets()[name]["scale"]


def eyes(name, ahead, views=HEADINGS):
    """The game's camera round the target's chest: at each heading (0 behind the lead, 90 on his right), or each
    (heading, height share) of SWEEP."""
    out = []
    for v in views:
        h, lift = v if isinstance(v, tuple) else (v, 1.0)
        r = math.radians(h)
        out.append((v, [math.sin(r) * k.CAMERA_OUT, chest(name) + k.CAMERA_UP * lift, -ahead + math.cos(r) * k.CAMERA_OUT]))
    return out


def along(a, b, step=0.05):
    """Points every `step` studs from a to b, both ends kept: what a line's guard tests."""
    n = max(1, math.ceil(k.length(k.sub(b, a)) / step))
    return [k.add(a, k.mul(k.sub(b, a), i / n)) for i in range(n + 1)]


def inside(p, boxes, margin):
    return any(all(lo[j] - margin < p[j] < hi[j] + margin for j in range(3)) for lo, hi in boxes)


def beyond(eye, p, box, margin):
    """Whether the ray from `eye` through `p` meets `box` (grown by `margin`) at or past p."""
    lo, hi = [box[0][j] - margin for j in range(3)], [box[1][j] + margin for j in range(3)]
    d = k.sub(p, eye)
    t0, t1 = -math.inf, math.inf
    for j in range(3):
        if abs(d[j]) < 1e-12:
            if not lo[j] <= eye[j] <= hi[j]:
                return False
            continue
        a, b = (lo[j] - eye[j]) / d[j], (hi[j] - eye[j]) / d[j]
        t0, t1 = max(t0, min(a, b)), min(t1, max(a, b))
    return t0 <= t1 and t1 > 1.0


def ray_hits(eye, d, tri, past):
    """Moller-Trumbore: whether eye + t d meets the triangle at t > past."""
    a, b, c = tri
    e1, e2 = k.sub(b, a), k.sub(c, a)
    h = [d[1] * e2[2] - d[2] * e2[1], d[2] * e2[0] - d[0] * e2[2], d[0] * e2[1] - d[1] * e2[0]]
    det = k.dot(e1, h)
    if abs(det) < 1e-12:
        return False
    s = k.sub(eye, a)
    u = k.dot(s, h) / det
    if u < 0 or u > 1:
        return False
    q = [s[1] * e1[2] - s[2] * e1[1], s[2] * e1[0] - s[0] * e1[2], s[0] * e1[1] - s[1] * e1[0]]
    v = k.dot(d, q) / det
    if v < 0 or u + v > 1:
        return False
    return k.dot(e2, q) / det > past


def over_face(p, faces, eyes_, margin=0.1):
    """The view from which `p` draws over a face (within `margin` across the ray), or None: the face's box first,
    then its triangles, by the ray through p and four beside it, `margin` up, down, left and right."""
    for view, eye in eyes_:
        for box, tris in faces:
            if not beyond(eye, p, box, margin):
                continue
            d = k.unit(k.sub(p, eye))
            side = k.unit([-d[2], 0.0, d[0]])
            up = [side[1] * d[2] - side[2] * d[1], side[2] * d[0] - side[0] * d[2], side[0] * d[1] - side[1] * d[0]]
            far = k.length(k.sub(p, eye))
            for o in ([0, 0], [1, 0], [-1, 0], [0, 1], [0, -1]):
                q = k.add(p, k.add(k.mul(side, o[0] * margin), k.mul(up, o[1] * margin)))
                way = k.sub(q, eye)
                if any(ray_hits(eye, way, tri, 1.0) for tri in tris):
                    return view
    return None


def faults(points, name, ahead, margin=0.1, views=HEADINGS, faces=True):
    """Rule 4 against one target: the first point inside a part, and the first view from which a point draws over a
    face. `points` are in the lead's frame."""
    boxes, face_list = placed(name, ahead)
    out = []
    hit = next((p for p in points if inside(p, boxes, margin)), None)
    if hit:
        out.append(f"enters {name} at ({hit[0]:.2f}, {hit[1]:.2f}, {hit[2]:.2f})")
    if faces:
        e = eyes(name, ahead, views)
        over = next(((p, v) for p in points for v in [over_face(p, face_list, e, margin)] if v is not None), None)
        if over:
            p, v = over
            out.append(f"draws over {name}'s face from {v} at ({p[0]:.2f}, {p[1]:.2f}, {p[2]:.2f})")
    return out


GAME = tuple(v for v in SWEEP if v[1] == 1.0)  # every 5 degrees round, at the game's camera height
VIEWS = HEADINGS + SWEEP  # and at 0.4 of it, the camera turned low (the content check's gap d)


def to_triangle(p, tri):
    """The distance from p to a triangle (its nearest point: inside, on an edge or at a corner)."""
    a, b, c = tri
    ab, ac, ap = k.sub(b, a), k.sub(c, a), k.sub(p, a)
    d1, d2 = k.dot(ab, ap), k.dot(ac, ap)
    if d1 <= 0 and d2 <= 0:
        return k.length(ap)
    bp = k.sub(p, b)
    d3, d4 = k.dot(ab, bp), k.dot(ac, bp)
    if d3 >= 0 and d4 <= d3:
        return k.length(bp)
    cp = k.sub(p, c)
    d5, d6 = k.dot(ab, cp), k.dot(ac, cp)
    if d6 >= 0 and d5 <= d6:
        return k.length(cp)
    vc = d1 * d4 - d3 * d2
    if vc <= 0 and d1 >= 0 and d3 <= 0:
        return k.length(k.sub(p, k.add(a, k.mul(ab, d1 / (d1 - d3)))))
    vb = d5 * d2 - d1 * d6
    if vb <= 0 and d2 >= 0 and d6 <= 0:
        return k.length(k.sub(p, k.add(a, k.mul(ac, d2 / (d2 - d6)))))
    va = d3 * d6 - d5 * d4
    if va <= 0 and d4 - d3 >= 0 and d5 - d6 >= 0:
        return k.length(k.sub(p, k.add(b, k.mul(k.sub(c, b), (d4 - d3) / ((d4 - d3) + (d5 - d6))))))
    den = 1 / (va + vb + vc)
    return k.length(k.sub(p, k.add(a, k.add(k.mul(ab, vb * den), k.mul(ac, vc * den)))))


def near_face(points, name, ahead, margin):
    """The first point within `margin` of a face of target `name` (`ahead` studs before him), by its triangles."""
    _, faces = placed(name, ahead)
    for p in points:
        for (lo, hi), tris in faces:
            if all(lo[j] - margin <= p[j] <= hi[j] + margin for j in range(3)) and \
                    any(to_triangle(p, tri) < margin for tri in tris):
                return p
    return None


def root_to_root(points, ahead, margin=0.1, names=None):
    """Fixed rows as the game stands today (each target `ahead` studs before him, root to root): the targets they
    enter. Reported, never failed: the rows are guarded for the spacing ask (`rule4`)."""
    return [name for name in (names or targets()) if faults(points, name, ahead, margin, faces=False)]


def landed(points, ahead, name, land):
    """Points placed for the ordinary Shade `ahead` studs before him, moved onto target `name` as a flight lands them
    there, at their own size. `land` is the script's own landing, a function giving where the flight lands on a
    target by its name (the ask's way: aimed at its belly times its Scale, stopped before its own torso face; the
    content check's fix, 2026-11-17), or a height: `land` up on the ordinary Shade's face, then `land` times the
    target's scale, on its own face."""
    if callable(land):
        d = k.sub(land(name), land("Shade Brawler"))
        return [k.add(p, d) for p in points]
    t = targets()[name]
    s = t["scale"]
    f0, ft = -ahead + FRONT, -ahead + t["front"] * s
    return [[p[0], p[1] + land * (s - 1), p[2] + ft - f0] for p in points]


def rule4(points, ahead, what, land=None, margin=0.1, views=VIEWS, waiting=None, fit=None):
    """Every target against `points` (the lead's frame, placed for the ordinary Shade `ahead` studs before him): fixed
    rows (`land` None) with the target standing so its torso face is the ordinary Shade's (the lead spaced by its
    target's depth: Faber's, AR26), or a flight's rows landed on it (`land` up on the ordinary Shade). `fit`
    (points, name) moves fixed rows as the game would place them on that target (Kirra's cuts, lifted to its waist).
    With a `waiting` list, a target the game doesn't have yet (`in_game`) is reported there, not failed: it joins the
    game only once the rows pass it (the content check's gate, 2026-11-17)."""
    bad = []
    game = in_game()
    for name in targets():
        if land is None:
            pts, at = (fit(points, name) if fit else points), on_face(name, ahead)
        else:
            pts, at = landed(points, ahead, name, land), ahead
        got = [f"{what} {x} (the target {ahead} ahead)" for x in faults(pts, name, at, margin, views)]
        if waiting is not None and name not in game:
            waiting += got
        else:
            bad += got
    return bad


def main():
    for name, t in targets().items():
        boxes, faces = placed(name, 0.0)
        top = max(hi[1] for lo, hi in boxes)
        low_face = min(b[0][1] for b, _ in faces)
        print(f"{name}: scale {t['scale']}, torso face {t['front'] * t['scale']:.2f} before its root, top {top:.2f} up, "
              f"{len(boxes)} parts, {len(faces)} face(s), the lowest from {low_face:.2f} up")


if __name__ == "__main__":
    main()
