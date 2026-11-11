"""R6 parity: what Roblox's Animator should show for a baked clip, and how far two samplings of it differ.

The R6 parity check. Pure Python, no Blender, nothing to install. The rig's numbers come from r6rig.py, as r6anim.py's do.

- fk: a clip baked by r6anim.export -> each part's CFrame relative to the HumanoidRootPart, the way the Animator poses
  a standard R6 rig: Part1 = Part0 * C0 * Transform * C1:Inverse(), with Linear easing between keyframes
  (Author.SaveBaked sets every Pose to Linear), so positions lerp and rotations slerp.
- compare: two samplings in the parity JSON (below): the largest position and angle gaps, then PASS or FAIL.
- feet: whether a gait's planted feet slide on the floor.
- curves: the velocity curves of a clip or a dump, frame by frame (the clip review judges by them): the torso's lean,
  the hips' height and how fast the head, each fist, the blade's tip and the muzzle go, relative to the root.
- wrists: an export baked before the weapon wrist given its wrists at rest, rewritten in place: each arm it keys also
  keys its wrist (r6rig.WRISTS) at the weld's own pose, so its weapons sit exactly as they did, and a loop's grip key
  under it no longer shows through (a lower clip's grip key shows under a clip without one).

Parity JSON, the same from every side (Blender's scene: r6anim.parity_dump; the export: fk; Studio's Animator):
    {"Clip": "GunReload", "Side": "studio" | "blender" | "blender-blend" | "export", "Fps": 60,
     "Legs": 0.0, "Weights": {"Torso": 0.0, ...},
     "Samples": [{"T": 0.378, "Parts": {"Torso": [x, y, z, R00, ..., R22], ...},
                  "Transforms": {"Torso": [...], ...}, "Weapons": {"HeldLeft": [...], "HeldRight": [...]}}]}
"Parts" and "Weapons" are relative to the HumanoidRootPart (Luau: root.CFrame:ToObjectSpace(part.CFrame):GetComponents());
"Transforms" are each Motor6D's Transform, keyed by its Part1. Every list is the 12 CFrame components. "Legs" and
"Weights" are the clip's export fields; a Studio dump may leave them out.

What compare checks, at every sample time both files have (each paired with the nearest within 0.00005 s):
- the Transform of every joint both sides say the clip drives (its weight above 0; a leg also needs "Legs" above 0);
- Parts and Weapons only where the part and every joint above it are driven. A joint the clip leaves alone is posed
  by whatever else plays (on a clean rig in Studio, nothing: its rest), so a partial clip's arm is judged by its own
  Transform, not by where an undriven torso carries it.
--all checks every joint, driven or not (Blender against the export, where both hold the whole body).
It passes within 0.005 stud and 0.1 degree (--tol STUDS DEGREES). It fails on any gap over that, on a checked name
one side lacks, or when no sample times match. Blender against the export points to the asset maker; the export
against Studio to the builder. In-betweens are judged against the export's FK (fk at any time), never Blender's curves.

    py tools/blender/r6parity.py fk build/handoff/GunReload/Anim_GunReload.txt [times...] [--out export.json]
    py tools/blender/r6parity.py compare blender.json export.json [--tol 0.005 0.1] [--all]
    py tools/blender/r6parity.py feet build/handoff/LockedGait/Anim_HeroWalkBack.txt
    py tools/blender/r6parity.py wrists build/handoff/GunBurstHold/Anim_GunBurstHold.txt

Tested: a self-compare reads 0; a planted 0.02-stud, 1-degree error reads exactly that;
every handoff loop closes within 0.001 degrees. Angles use atan2, not acos: the export's 5-decimal rounding makes acos
read up to 0.34 degrees on identical poses. A file PowerShell's `>` wrote (UTF-16) loads too.
"""

import bisect
import json
import math
import sys

from r6rig import (CLAW_WRISTS, GRIPS, HEAD_DRAWN, JOINTS, KNEE_C0, KNEE_C1, KNEES, LOADOUTS, PARTS, SIZES, STOWED, WEAPONS, WELDED,
                   WRISTS)

CLAWS = tuple(part1 for _, part1, _ in CLAW_WRISTS.values())  # the Creature's claws' joints, keyed by their MeshParts

LEGS = ("Right Leg", "Left Leg")
SHINS = tuple(KNEES.values())
TOLERANCE = (0.005, 0.1)  # studs, degrees


# --- CFrames: (rotation rows, position) -------------------------------------------------------------------------------

def cframe(c):
    return ((tuple(c[3:6]), tuple(c[6:9]), tuple(c[9:12])), tuple(c[0:3]))


def components(cf):
    r, p = cf
    return [p[0], p[1], p[2], *r[0], *r[1], *r[2]]


IDENTITY = cframe((0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1))


def mul(a, b):
    ra, pa = a
    rb, pb = b
    r = tuple(tuple(sum(ra[i][k] * rb[k][j] for k in range(3)) for j in range(3)) for i in range(3))
    p = tuple(sum(ra[i][k] * pb[k] for k in range(3)) + pa[i] for i in range(3))
    return (r, p)


def inverse(a):
    r, p = a
    rt = tuple(tuple(r[j][i] for j in range(3)) for i in range(3))
    return (rt, tuple(-sum(rt[i][k] * p[k] for k in range(3)) for i in range(3)))


def point(a, v):
    r, p = a
    return tuple(sum(r[i][k] * v[k] for k in range(3)) + p[i] for i in range(3))


def angle_between(a, b):
    """Degrees of rotation between two CFrames' orientations. atan2 of the relative rotation's skew and trace parts:
    acos of the trace alone turns the export's 5-decimal rounding (1e-5) into tenths of a degree near zero."""
    ra, rb = a[0], b[0]
    m = [[sum(ra[k][i] * rb[k][j] for k in range(3)) for j in range(3)] for i in range(3)]  # Ra^T Rb
    sin = math.sqrt((m[2][1] - m[1][2]) ** 2 + (m[0][2] - m[2][0]) ** 2 + (m[1][0] - m[0][1]) ** 2) / 2
    cos = (m[0][0] + m[1][1] + m[2][2] - 1) / 2
    return math.degrees(math.atan2(sin, cos))


def distance(a, b):
    return math.dist(a[1], b[1])


# --- quaternions, for Linear easing between keyframes ----------------------------------------------------------------

def to_quat(r):
    t = r[0][0] + r[1][1] + r[2][2]
    if t > 0:
        s = math.sqrt(t + 1) * 2
        return ((r[2][1] - r[1][2]) / s, (r[0][2] - r[2][0]) / s, (r[1][0] - r[0][1]) / s, s / 4)
    if r[0][0] > r[1][1] and r[0][0] > r[2][2]:
        s = math.sqrt(1 + r[0][0] - r[1][1] - r[2][2]) * 2
        return (s / 4, (r[0][1] + r[1][0]) / s, (r[0][2] + r[2][0]) / s, (r[2][1] - r[1][2]) / s)
    if r[1][1] > r[2][2]:
        s = math.sqrt(1 + r[1][1] - r[0][0] - r[2][2]) * 2
        return ((r[0][1] + r[1][0]) / s, s / 4, (r[1][2] + r[2][1]) / s, (r[0][2] - r[2][0]) / s)
    s = math.sqrt(1 + r[2][2] - r[0][0] - r[1][1]) * 2
    return ((r[0][2] + r[2][0]) / s, (r[1][2] + r[2][1]) / s, s / 4, (r[1][0] - r[0][1]) / s)


def from_quat(q):
    x, y, z, w = q
    return ((1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)),
            (2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)),
            (2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)))


def slerp(qa, qb, a):
    dot = sum(i * j for i, j in zip(qa, qb))
    if dot < 0:
        qb, dot = tuple(-i for i in qb), -dot
    if dot > 0.9995:
        q = tuple(i + (j - i) * a for i, j in zip(qa, qb))
    else:
        theta = math.acos(dot)
        sa, sb = math.sin((1 - a) * theta) / math.sin(theta), math.sin(a * theta) / math.sin(theta)
        q = tuple(i * sa + j * sb for i, j in zip(qa, qb))
    n = math.sqrt(sum(i * i for i in q))
    return tuple(i / n for i in q)


def lerp_cframe(a, b, alpha):
    p = tuple(i + (j - i) * alpha for i, j in zip(a[1], b[1]))
    return (from_quat(slerp(to_quat(a[0]), to_quat(b[0]), alpha)), p)


# --- the clip ----------------------------------------------------------------------------------------------------------

def load(path):
    """A JSON file, whether written as UTF-8 or (by PowerShell's `>`) as UTF-16."""
    with open(path, "rb") as f:
        raw = f.read()
    return json.loads(raw.decode("utf-16") if raw[:2] in (b"\xff\xfe", b"\xfe\xff") else raw.decode("utf-8-sig"))


def pose(frame, part):
    """A keyframe's Transform for `part`; a part the export leaves out stays at rest."""
    c = frame["Poses"].get(part)
    return IDENTITY if c is None else cframe(c)


def joints_of(clip):
    """The joints a clip poses: the body's, and the weapon wrists', the claws' or the knees' if it keys them (r6rig.WRISTS,
    r6rig.CLAW_WRISTS, r6rig.KNEES)."""
    return PARTS + tuple(g for g in GRIPS + CLAWS + SHINS if g in clip["Frames"][0]["Poses"])


def transforms_at(clip, t):
    """Each joint's Transform at `t` seconds, Linear between keyframes (clamped to the clip)."""
    frames, joints = clip["Frames"], joints_of(clip)
    if t <= frames[0]["T"]:
        return {part: pose(frames[0], part) for part in joints}
    for a, b in zip(frames, frames[1:]):
        if t <= b["T"]:
            alpha = (t - a["T"]) / (b["T"] - a["T"])
            return {part: lerp_cframe(pose(a, part), pose(b, part), alpha) for part in joints}
    return {part: pose(frames[-1], part) for part in joints}


def fk(transforms):
    """Part and weapon CFrames relative to the HumanoidRootPart for one set of joint Transforms. A weapon is turned by
    its hand's wrist when the Transforms hold one; otherwise it sits as welded."""
    placed = {"HumanoidRootPart": IDENTITY}
    for part in PARTS:  # parents come first in PARTS
        parent, c0, c1 = JOINTS[part]
        placed[part] = mul(mul(mul(placed[parent], cframe(c0)), transforms[part]), inverse(cframe(c1)))
    for leg, shin in KNEES.items():
        if shin in transforms:  # a knee the clip keys; with none the shin is only the leg's bottom half
            placed[shin] = mul(mul(mul(placed[leg], cframe(KNEE_C0)), transforms[shin]), inverse(cframe(KNEE_C1)))
    weapons = {}
    for name in WELDED:
        arm, c0, c1, _ = WEAPONS[name]
        wrist = transforms.get(WRISTS[arm][0], IDENTITY)
        weapons[name] = mul(mul(mul(placed[arm], cframe(c0)), wrist), inverse(cframe(c1)))
    del placed["HumanoidRootPart"]
    return placed, weapons


def sample(clip, times):
    samples = []
    for t in times:
        transforms = transforms_at(clip, t)
        parts, weapons = fk(transforms)
        samples.append({"T": round(t, 6),
                        "Parts": {k: components(v) for k, v in parts.items()},
                        "Transforms": {k: components(v) for k, v in transforms.items()},
                        "Weapons": {k: components(v) for k, v in weapons.items()}})
    return {"Clip": clip["Name"], "Side": "export", "Fps": clip.get("Fps"), "Legs": clip.get("Legs", 1.0),
            "Weights": clip.get("Weights") or {part: 1.0 for part in PARTS}, "Samples": samples}


def default_times(clip):
    """Every keyframe time, the markers, and the midpoint of the first two intervals (the Linear in-betweens)."""
    frames = clip["Frames"]
    times = {f["T"] for f in frames} | {m["T"] for m in clip.get("Markers", [])}
    times |= {(frames[i]["T"] + frames[i + 1]["T"]) / 2 for i in range(min(2, len(frames) - 1))}
    return sorted(times)


# --- comparing two samplings -------------------------------------------------------------------------------------------

def driven(data):
    """The joints a sampling's clip drives: weight above 0 ("Weights"; a leg also needs "Legs"). Without them, all."""
    weights, legs = data.get("Weights") or {}, data.get("Legs", 1.0)
    return {part for part in PARTS if weights.get(part, 1.0) > 0 and (part not in LEGS or legs > 0)}


def chain(part):
    """The part and every part above it, up to the HumanoidRootPart."""
    out = set()
    while part in JOINTS:
        out.add(part)
        part = JOINTS[part][0]
    return out


SAME_TIME = 0.00005  # seconds: sample times this close are the same moment (exports round T to 4 decimals)


def nearest(samples, times, t):
    """The sample whose time is closest to `t`, if within SAME_TIME (`times`: sorted (T, index) pairs). Nearest, not
    rounded: a marker 0.00003 s from a keyframe is its own moment."""
    i = bisect.bisect_left(times, (t, -1))
    best = min((times[j] for j in (i - 1, i) if 0 <= j < len(times)), key=lambda x: abs(x[0] - t), default=None)
    return samples[best[1]] if best is not None and abs(best[0] - t) <= SAME_TIME else None


def compare(a, b, every=False):
    """The gaps between two samplings over the sample times both have. Returns the number of matched times; per
    checked (group, name), [studs, at t, degrees, at t] for its largest gaps; the checked names a side lacks; and the
    joints left unchecked because a side doesn't drive them. `every` checks all joints, driven or not (Blender
    against the export, where both hold the whole body)."""
    on = set(PARTS) if every else driven(a) & driven(b)
    whole = {part for part in on if chain(part) <= on}
    keyed = set(a["Samples"][0].get("Transforms", {})) if a["Samples"] else set()  # a wrist counts once a clip keys it
    wrists = [joint for arm, (joint, _) in WRISTS.items() if arm in on and joint in keyed]
    wrists += [part1 for arm, (_, part1, _) in CLAW_WRISTS.items() if arm in on and part1 in keyed]
    knees = [shin for leg, shin in KNEES.items() if leg in whole and shin in keyed]
    groups = (("Transforms", [p for p in PARTS if p in on] + wrists + knees), ("Parts", [p for p in PARTS if p in whole] + knees),
              ("Weapons", [w for w in WELDED if WEAPONS[w][0] in whole]))
    times = sorted((s["T"], i) for i, s in enumerate(b["Samples"]))
    matched, worst, missing = 0, {}, set()
    for sa in a["Samples"]:
        sb = nearest(b["Samples"], times, sa["T"])
        if sb is None:
            continue
        matched += 1
        for group, names in groups:
            for name in names:
                ca, cb = sa.get(group, {}).get(name), sb.get(group, {}).get(name)
                if ca is None or cb is None:
                    missing.add(f"{group} {name}")
                    continue
                fa, fb = cframe(ca), cframe(cb)
                d, g = distance(fa, fb), angle_between(fa, fb)
                w = worst.setdefault((group, name), [0.0, sa["T"], 0.0, sa["T"]])
                if d > w[0]:
                    w[0], w[1] = d, sa["T"]
                if g > w[2]:
                    w[2], w[3] = g, sa["T"]
    return matched, worst, sorted(missing), [p for p in PARTS if p not in on]


# --- feet: does a gait slide? ------------------------------------------------------------------------------------------

FLOOR = -3.0  # the floor relative to the HumanoidRootPart's centre (R6 stands with it 3 studs up)
DOWN = 0.01  # a foot is down while its lowest corner is within this of the floor
_LEG = [s / 2 for s in SIZES["Right Leg"]]
CORNERS = [(x, y, z) for x in (-_LEG[0], _LEG[0]) for y in (-_LEG[1], _LEG[1]) for z in (-_LEG[2], _LEG[2])]


def root_at(clip, t):
    """The root's world CFrame at t, the clip playing at speed 1 on the motion its feet are planted for: `Speed` studs
    a second along `Heading` (0 forward, 90 left), or `TurnRate` degrees a second (positive turns left)."""
    if "TurnRate" in clip:
        a = math.radians(clip["TurnRate"]) * t
        c, s = math.cos(a), math.sin(a)
        return (((c, 0, s), (0, 1, 0), (-s, 0, c)), (0, 0, 0))
    h = math.radians(clip.get("Heading", 0.0))
    v = clip.get("Speed", 0.0) * t
    return (IDENTITY[0], (-math.sin(h) * v, 0.0, -math.cos(h) * v))


def feet(clip):
    """Per leg, over whole stances: the plant's drift per step (studs the planted corner slides on the floor), how far
    the sole's centre slides per step, and the landing speed (studs a second the landing corner still moves on the
    frame it touches down). R6 legs are rigid blocks, so the contact rocks from corner to corner (and a turning foot
    pivots about its centre); each corner is tracked on its own."""
    fps, frames = clip["Fps"], clip["Frames"]
    n = len(frames) - 1
    out = {}
    for leg in LEGS:
        rows, soles = [], []
        for i in range(3 * n + 1):  # three cycles; only stances that start in the middle one count
            parts, _ = fk({p: pose(frames[i % n], p) for p in joints_of(clip)})
            foot = KNEES[leg] if KNEES[leg] in parts else leg  # past a keyed knee the sole is the shin's
            placed = mul(root_at(clip, i / fps), parts[foot])
            rows.append([point(placed, (x, y * SIZES[foot][1] / SIZES[leg][1], z)) for x, y, z in CORNERS])
            soles.append(point(placed, (0, -SIZES[foot][1] / 2, 0)))
        low = [min(range(8), key=lambda j: pts[j][1]) for pts in rows]
        height = [rows[i][low[i]][1] - FLOOR for i in range(len(rows))]
        stances, cur, graze = [], None, 0
        for i in range(1, len(rows)):
            k = low[i]
            speed = math.hypot(rows[i][k][0] - rows[i - 1][k][0], rows[i][k][2] - rows[i - 1][k][2]) * fps
            if height[i] <= DOWN:
                if cur is None:
                    cur = {"start": i, "land": speed if height[i - 1] > DOWN else None, "drift": 0.0, "from": soles[i],
                           "centre": 0.0}
                else:
                    if low[i - 1] == k:
                        cur["drift"] += speed / fps
                    cur["centre"] = max(cur["centre"], math.hypot(soles[i][0] - cur["from"][0], soles[i][2] - cur["from"][2]))
            else:
                if cur is not None:
                    stances.append(cur)
                    cur = None
                if height[i] <= 0.05 and n <= i < 2 * n:
                    graze += 1
        whole = [s for s in stances if s["land"] is not None and n <= s["start"] < 2 * n]
        out[leg] = {"drift": max((s["drift"] for s in whole), default=0.0),
                    "centre": max((s["centre"] for s in whole), default=0.0),
                    "land": max((s["land"] for s in whole), default=0.0),
                    "graze": graze, "lowest": min(height)}
    return out


# --- audit: what reads as broken on screen -----------------------------------------------------------------------------

# What fails a check: studs, except "Pop" (a joint's turn in one frame over the larger of its neighbours', counted only
# above POP_FLOOR degrees a second), "Seam" (degrees between a loop's last pose and its first), "Limb flip" (degrees a
# limb turns about its own length in one frame), "Wrist flip" (degrees a wrist turns in one frame: a hold solved through
# the forearm's line rolls its weapon 180 degrees in a frame, which no body part's turn shows) and "Salute held" (seconds an
# arm stays in the salute zone, SALUTE, the body upright within SALUTE_UPRIGHT).
AUDIT = {"Legs cross": 0.10, "Arm through body": 0.05, "Leg out of hip": 0.10, "Weapon through body": 0.05,
         "Under the floor": 0.02, "Pop": 3.0, "Seam": 0.5, "Limb flip": 45.0, "Wrist flip": 60.0, "Salute held": 0.1,
         "Knee the wrong way": 5.0, "Neck offset": 0.15, "Nod": 30.0}
UNITS = {"Pop": "x", "Seam": " deg", "Limb flip": " deg", "Wrist flip": " deg", "Salute held": " s", "Knee the wrong way": " deg", "Nod": " deg"}  # the rest are studs
POP_FLOOR = 120.0
SALUTE = (20.0, 70.0, 30.0)  # an arm's degrees up, low and high, and off the body's own facing (the salute zone)
SALUTE_UPRIGHT = 30.0  # degrees the torso may tilt from upright and still count: a salute needs the body upright, and
# a body thrown level or lying on its back makes none
SHOULDER = 0.5  # an arm's shoulder pivot, studs above its middle (C1): the cap above it tips into the chest on any
# R6 rig when the arm swings out, so it's reported apart ("Shoulder cap") and never fails
FIST = 0.5  # studs at the end of an arm that are its fist: a weapon leaving the fist sits in it


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def obb(cf, size, y0=None, y1=None):
    """An oriented box (centre, unit axes, half sizes) from a part's CFrame and size, optionally only the slice of its
    length from y0 to y1 (part-local studs)."""
    r, p = cf
    lo, hi = (-size[1] / 2 if y0 is None else y0), (size[1] / 2 if y1 is None else y1)
    axes = [tuple(r[i][j] for i in range(3)) for j in range(3)]  # the box's own X, Y, Z: the rotation's columns
    centre = point(cf, (0, (lo + hi) / 2, 0))
    return centre, axes, (size[0] / 2, (hi - lo) / 2, size[2] / 2)


def overlap(a, b):
    """How deep two oriented boxes sink into each other: the shortest push that parts them (studs, 0 if apart)."""
    (pa, xa, ha), (pb, xb, hb) = a, b
    d = [j - i for i, j in zip(pa, pb)]
    axes = list(xa) + list(xb)
    for u in xa:
        for v in xb:
            c = cross(u, v)
            n = math.sqrt(dot(c, c))
            if n > 1e-6:
                axes.append(tuple(x / n for x in c))
    depth = math.inf
    for axis in axes:
        reach = sum(h * abs(dot(u, axis)) for u, h in zip(xa, ha)) + sum(h * abs(dot(v, axis)) for v, h in zip(xb, hb))
        gap = abs(dot(d, axis)) - reach
        if gap >= 0:
            return 0.0
        depth = min(depth, -gap)
    return depth


def corners(box):
    centre, axes, half = box
    return [tuple(centre[i] + sum(s * h * axes[k][i] for k, (s, h) in enumerate(zip(signs, half))) for i in range(3))
            for signs in [(x, y, z) for x in (-1, 1) for y in (-1, 1) for z in (-1, 1)]]


def drawn_size(part):
    return HEAD_DRAWN if part == "Head" else SIZES[part]


def poses(data):
    """(t, parts, weapons, transforms) per sample, from an export (posed by fk) or from a parity JSON."""
    if "Frames" in data:
        for frame in data["Frames"]:
            transforms = {part: pose(frame, part) for part in joints_of(data)}
            parts, weapons = fk(transforms)
            yield frame["T"], parts, weapons, transforms
    else:
        for s in data["Samples"]:
            yield (s["T"], {k: cframe(v) for k, v in s["Parts"].items()}, {k: cframe(v) for k, v in s["Weapons"].items()},
                   {k: cframe(v) for k, v in s.get("Transforms", {}).items()})


def knee_backward(leg, shin):
    """How far a knee bends behind the body, in degrees: its bend, by how much of its push out of the hip-to-sole line goes against
    the root's facing. The thigh's own frame can't say: an R6 leg swung out at the side has no front of its own."""
    top, knee, sole = point(leg, (0, 1, 0)), point(leg, (0, 0, 0)), point(shin, (0, -SIZES["Right Shin"][1] / 2, 0))
    thigh, lower = [b - a for a, b in zip(top, knee)], [b - a for a, b in zip(knee, sole)]
    line = [b - a for a, b in zip(top, sole)]
    push = [k - (a + b) / 2 for k, a, b in zip(knee, top, sole)]
    size = math.sqrt(dot(push, push))
    length = dot(line, line)
    facing = [v * line[2] / length for v in line]  # -Z, square to the line
    facing[2] -= 1.0
    across = math.sqrt(dot(facing, facing))
    if size < 1e-6 or across < 1e-6:
        return 0.0
    bend = math.degrees(math.acos(max(-1.0, min(1.0, dot(thigh, lower) / math.sqrt(dot(thigh, thigh) * dot(lower, lower))))))
    return bend * max(-dot(push, facing) / (size * across), 0.0)


def neck(parts):
    """(studs the head has left its neck, degrees it nods forward against the torso), from the placed parts: the fold hides the
    head, never the neck."""
    (tr, tp), (hr, hp) = parts["Torso"], parts["Head"]
    gap = [tp[i] + tr[i][1] - (hp[i] - 0.5 * hr[i][1]) for i in range(3)]
    up = [sum(tr[k][i] * hr[k][1] for k in range(3)) for i in range(3)]  # the head's up in the torso's frame
    return math.sqrt(sum(g * g for g in gap)), math.degrees(math.atan2(-up[2], up[1]))


def audit(data, frames=None, lift=None):
    """Each check's worst value over the clip: {check: (value, at t, what)}; plus the shoulder caps for information.
    `frames`, a dict, gathers every check that fails by the sample time it fails at (t -> {check}), for the fast preview
    to mark its frames (preview.py). `lift` (t -> studs) is how far the game carries the body over its standing height,
    for a clip played on a launch (the knockdown's fall rides the knock's arc): the floor drops by it."""
    worst = {}

    def note(check, value, t, what):
        if value > worst.get(check, (-math.inf,))[0]:
            worst[check] = (value, t, what)
        if frames is not None and value > AUDIT.get(check, math.inf):
            frames.setdefault(t, set()).add(check)

    rows = list(poses(data))
    # weapons only for a character that carries them (r6rig.LOADOUTS); a file without a character is an older
    # Hero dump
    armed = data.get("Character", "Hero") in LOADOUTS
    for t, parts, weapons, transforms in rows:
        floor = FLOOR - (lift(t) if lift else 0.0)
        if "Head" in parts and "Torso" in parts:
            offset, nod = neck(parts)
            note("Neck offset", offset, t, "the head off its neck")
            note("Nod", nod, t, "the head against the torso")
        body = {part: obb(parts[part], drawn_size(part)) for part in PARTS}
        shins = tuple(shin for shin in SHINS if shin in parts)  # a keyed knee cuts its leg's box in two; with none, the leg's one box
        for leg, shin in KNEES.items():
            if shin in shins:
                body[leg], body[shin] = obb(parts[leg], SIZES[leg], y0=0.0), obb(parts[shin], SIZES[shin])
                note("Knee the wrong way", knee_backward(parts[leg], parts[shin]), t, shin)
        lower = {arm: obb(parts[arm], SIZES[arm], y1=SHOULDER) for arm in ("Right Arm", "Left Arm")}
        cap = {arm: obb(parts[arm], SIZES[arm], y0=SHOULDER) for arm in ("Right Arm", "Left Arm")}
        for right in ("Right Leg", "Right Shin"):
            for left in ("Left Leg", "Left Shin"):
                if right in body and left in body:
                    note("Legs cross", overlap(body[right], body[left]), t, "the legs")
        for arm, other in (("Right Arm", "Left Arm"), ("Left Arm", "Right Arm")):
            for part in ("Torso", "Head", "Right Leg", "Left Leg") + shins:
                note("Arm through body", overlap(lower[arm], body[part]), t, f"{arm} into {part}")
            note("Arm through body", overlap(lower[arm], body[other]), t, f"{arm} into {other}")
            note("Shoulder cap", overlap(cap[arm], body["Torso"]), t, f"{arm}")
        torso_inv = inverse(parts["Torso"])
        for leg in LEGS:  # the leg's top face against the torso's base, across
            top = [point(torso_inv, c) for c in corners(obb(parts[leg], SIZES[leg], y0=SIZES[leg][1] / 2 - 1e-3))]
            out = max(max(abs(c[0]) - SIZES["Torso"][0] / 2, abs(c[2]) - SIZES["Torso"][2] / 2) for c in top)
            note("Leg out of hip", max(out, 0.0), t, leg)
        if weapons and armed:
            blade = mul(mul(weapons["HeldRight"], cframe(WEAPONS["HeldRightBlade"][1])), inverse(cframe(WEAPONS["HeldRightBlade"][2])))
            held = {"HeldRightBlade": (blade, None), "HeldRight": (weapons["HeldRight"], "Right Arm"),
                    "HeldLeft": (weapons["HeldLeft"], "Left Arm")}
            # a weapon its wrist carries off the hand (stowed, r6rig.STOWS) meets its own arm like any other part
            away = {arm for arm, (joint, _) in WRISTS.items()
                    if joint in transforms and math.sqrt(dot(transforms[joint][1], transforms[joint][1])) > STOWED}
            for name, (cf, hand) in held.items():
                box = obb(cf, WEAPONS[name][3])
                own = hand or "Right Arm"  # the arm that holds it (the blade's, through the hilt)
                for part in PARTS + shins:
                    if part != own or own in away:
                        target = body[part]
                    elif name == "HeldRight":
                        continue  # the hilt sits in the fist
                    else:  # held: the fist (the arm's last 0.5 stud, where it's held) left out
                        target = obb(parts[part], SIZES[part], y0=-SIZES[part][1] / 2 + FIST)
                    note("Weapon through body", overlap(box, target), t, f"{name} into {part}")
                for c in corners(box):
                    note("Under the floor", floor - c[1], t, name)
        for part in PARTS + shins:
            for c in corners(body[part]):
                note("Under the floor", floor - c[1], t, part)
    # pops: a joint's turn in one frame against its neighbours'. One within a frame of a marker is the clip's own beat
    # (a recoil kick, a chamber snap): reported, but it doesn't fail.
    fps = data.get("Fps") or 60
    markers = [(m["T"], m["Name"]) for m in data.get("Markers", [])]
    for part in PARTS + SHINS:
        steps = [angle_between(a[3][part], b[3][part]) for a, b in zip(rows, rows[1:]) if part in a[3] and part in b[3]]
        for i in range(1, len(steps) - 1):
            around = max(steps[i - 1], steps[i + 1], 1e-9)
            if steps[i] * fps > POP_FLOOR:
                t = rows[i + 1][0]
                beat = next((n for mt, n in markers if abs(mt - t) <= 1.5 / fps), None)
                what = f"{part} turns {steps[i]:.1f} deg in one frame"
                note("Beat" if beat else "Pop", steps[i] / around, t, f"{what}, on the marker {beat}" if beat else what)
    if data.get("Loop") and "Frames" in data:
        first, last = rows[0][3], rows[-1][3]
        for part in PARTS + tuple(shin for shin in SHINS if shin in first):
            note("Seam", angle_between(first[part], last[part]), rows[-1][0], part)
    # a limb flipping about its own length: an R6 limb has no square front straight out at its side, so a solve
    # through there spins it in one frame (a cast: 113-133 degrees); its twist about its own Y
    for limb in ("Right Arm", "Left Arm") + LEGS:
        for a, b in zip(rows, rows[1:]):
            ra, rb = a[1][limb][0], b[1][limb][0]
            relative = [[sum(ra[k][i] * rb[k][j] for k in range(3)) for j in range(3)] for i in range(3)]  # Ra^T Rb
            x, y, z, w = to_quat(relative)
            twist = abs(math.degrees(2 * math.atan2(y, w)))
            note("Limb flip", min(twist, 360.0 - twist), b[0], f"{limb} turns about its own length in one frame")
    for wrist in ("GripR", "GripL"):
        for a, b in zip(rows, rows[1:]):
            if wrist in a[3] and wrist in b[3]:
                note("Wrist flip", angle_between(a[3][wrist], b[3][wrist]), b[0], f"{wrist} in one frame")
    # the salute zone: a straight arm 20-70 degrees up within 30 of the
    # body's own facing, the body upright (within SALUTE_UPRIGHT), reads as a salute in a still frame. An arm passing
    # through the zone is moving; one that stays in it, wobble or not, is held: the longest an arm stays in the zone, however far it moves there, since a cone fixed in the world undercounts a
    # chest turning with the arm (the chest is the facing). The same hold by a body tilted past
    # SALUTE_UPRIGHT is printed for information ("Salute tilted")
    low, high, wide = SALUTE
    upright = math.cos(math.radians(SALUTE_UPRIGHT))
    for arm in ("Right Arm", "Left Arm"):
        lines = []
        for t, parts, _, _ in rows:
            r, _ = parts[arm]
            line = (-r[0][1], -r[1][1], -r[2][1])  # shoulder to hand, the arm's -Y
            tr, _ = parts["Torso"]
            facing = (-tr[0][2], -tr[2][2])  # the torso's -Z, flat
            up = math.degrees(math.asin(max(-1.0, min(1.0, line[1]))))
            flat = math.hypot(line[0], line[2])
            off = 180.0
            if flat > 1e-6 and math.hypot(*facing) > 1e-6:
                cos = (line[0] * facing[0] + line[2] * facing[1]) / (flat * math.hypot(*facing))
                off = math.degrees(math.acos(max(-1.0, min(1.0, cos))))
            zone = low <= up <= high and off <= wide
            standing = tr[1][1] >= upright  # the torso's +Y against the world's up
            lines.append((t, line, up, off, zone and standing, zone and not standing))
        for check, slot in (("Salute held", 4), ("Salute tilted", 5)):
            for i, (t, _, up, off, *_) in enumerate(lines):
                if not lines[i][slot] or (i and lines[i - 1][slot]):
                    continue  # a stay is read once, from its first sample
                j = i
                while j + 1 < len(lines) and lines[j + 1][slot]:
                    j += 1
                note(check, (j - i + 1) / fps, t, f"{arm} {up:.0f} up, {off:.0f} off its facing, in the zone to {lines[j][0]}")
                if check == "Salute held" and frames is not None and (j - i + 1) / fps > AUDIT[check]:
                    for k in range(i, j + 1):  # every frame it is held, not its first
                        frames.setdefault(lines[k][0], set()).add(check)
    return worst


def eyes(data):
    """Where the head looks over a clip: its face's pitch (degrees, + up) at its lowest and highest, and when."""
    low, high = (math.inf, None), (-math.inf, None)
    for t, parts, _, _ in poses(data):
        r, _ = parts["Head"]
        pitch = math.degrees(math.asin(max(-1.0, min(1.0, -r[1][2]))))  # the face is the head's -Z
        low, high = min(low, (pitch, t)), max(high, (pitch, t))
    return low, high


def aim(data):
    """A throw's arm against the line ahead, where the body faces its target: (seconds after the release, degrees up,
    degrees out to the arm's own side) at the Release marker and 0.1, 0.2 and 0.35 s on, for an export that carries a Release (a throw); [] for any other clip. The throw missed that line three times before it was measured."""
    release = data.get("Release")
    at = next((m["T"] for m in data.get("Markers", []) if m["Name"] == "Release"), None)
    if not release or at is None or "Frames" not in data:
        return []
    arm = f"{release.get('Hand', 'Left')} Arm"
    side = -1.0 if arm == "Left Arm" else 1.0
    rows = list(poses(data))
    found = []
    for after in (0.0, 0.1, 0.2, 0.35):
        _, parts, _, _ = min(rows, key=lambda row: abs(row[0] - at - after))
        r, _ = parts[arm]
        line = (-r[0][1], -r[1][1], -r[2][1])  # shoulder to hand: down the arm, its -Y
        found.append((after, math.degrees(math.asin(max(-1.0, min(1.0, line[1])))),
                      math.degrees(math.atan2(side * line[0], -line[2]))))
    return found


def report(name, data, lift=None):
    worst = audit(data, lift=lift)
    over = 0
    side = data.get("Side", "export")
    print(f"{name} ({side}, {len(data.get('Frames', data.get('Samples', [])))} poses)")
    for check, limit in AUDIT.items():
        if check == "Knee the wrong way" and check not in worst:  # a clip that keys no knee
            continue
        value, t, what = worst.get(check, (0.0, None, ""))
        bad = value > limit
        over += bad
        unit = UNITS.get(check, " studs")
        where = f" at {t} ({what})" if t is not None and value > 0 else ""
        print(f"  {check:20} {max(value, 0.0):6.3f}{unit}{where}{'   OVER' if bad else ''}")
    if "Beat" in worst:
        value, t, what = worst["Beat"]
        print(f"  {'Beat':20} {value:6.3f}x at {t} ({what}; the clip's own beat, for information)")
    if "Shoulder cap" in worst:
        value, t, what = worst["Shoulder cap"]
        print(f"  {'Shoulder cap':20} {value:6.3f} studs at {t} ({what}; inherent to R6, for information)")
    if "Salute tilted" in worst:
        value, t, what = worst["Salute tilted"]
        print(f"  {'Salute tilted':20} {value:6.3f} s at {t} ({what}; the body tilted past {SALUTE_UPRIGHT:.0f} deg, "
              f"so no salute: for information)")
    (low, tl), (high, th) = eyes(data)
    print(f"  {'Eyes':20} {low:+.1f} to {high:+.1f} deg (at {tl} and {th}; the face's pitch, + up, for information: "
          f"level on a target unless a beat says otherwise)")
    throw = aim(data)
    if throw:
        print(f"  {'Aim':20} " + "; ".join(f"{'release' if after == 0 else f'+{after:g} s'} {up:+.0f} up, {out:.0f} out"
                                           for after, up, out in throw)
              + " (deg: the throwing arm against the line ahead, for information: from the camera straight behind, "
                "aimed is within about 15 of it and under 15 up; from a camera eased to the side, read it against your own target)")
    if "Frames" in data and (data.get("Speed") or data.get("TurnRate")):
        for leg, r in feet(data).items():
            print(f"  Feet {leg:9}       sole centre slides {r['centre']:.3f} st/step; floor corner {r['drift']:.3f} "
                  f"st/step (a foot rocking or pivoting); lands at {r['land']:.1f} st/s; lowest {r['lowest']:+.3f}")
    print(f"AUDIT {'PASS' if not over else f'FAIL: {over} over'}")
    return over


# --- the command line --------------------------------------------------------------------------------------------------

def curves(data, start=None, end=None, every=1):
    """Prints a clip's or a dump's motion frame by frame, relative to the root: t, the torso's lean (degrees, + ahead), the
    hips' height over the floor, and the speeds in studs a second of the head, the blade's and the gun's fists, the
    blade's tip and the muzzle, with a bar for the head and for the tip: one speed peak a stroke, a settle that still
    moves, a hold that doesn't die (the clip review's velocity curve)."""
    hip = (0.0, -1.0, 0.0)  # the torso's underside, in its own frame
    rows = []
    for t, parts, weapons, _ in poses(data):
        torso = parts["Torso"]
        lean = math.degrees(math.atan2(-torso[0][2][1], torso[0][1][1]))  # its up, tipped toward -Z
        row = {"t": t, "lean": lean, "hips": point(torso, hip)[1] - FLOOR,
               "head": parts["Head"][1],
               "blade": point(parts["Right Arm"], (0.0, -1.0, 0.0)), "gun": point(parts["Left Arm"], (0.0, -1.0, 0.0))}
        if "HeldRight" in weapons:
            blade = mul(mul(weapons["HeldRight"], cframe(WEAPONS["HeldRightBlade"][1])), inverse(cframe(WEAPONS["HeldRightBlade"][2])))
            row["tip"] = point(blade, (0.0, WEAPONS["HeldRightBlade"][3][1] / 2, 0.0))
            row["muzzle"] = point(weapons["HeldLeft"], (0.0, 0.0, -WEAPONS["HeldLeft"][3][2] / 2))
        rows.append(row)
    print(f"{'t':>6} {'lean':>6} {'hips':>5} {'head':>6} {'blade':>6} {'gun':>6} {'tip':>6} {'muzzle':>6}   head / tip")
    for i in range(1, len(rows), every):
        a, b = rows[i - 1], rows[i]
        if (start is not None and b["t"] < start) or (end is not None and b["t"] > end):
            continue
        dt = (b["t"] - a["t"]) or 1e-9
        speed = {k: math.dist(a[k], b[k]) / dt for k in ("head", "blade", "gun", "tip", "muzzle") if k in b}
        bars = f"{'#' * min(round(speed['head'] / 2), 20):20} {'=' * min(round(speed.get('tip', 0.0) / 4), 30)}"
        print(f"{b['t']:6.3f} {b['lean']:6.1f} {b['hips']:5.2f} {speed['head']:6.1f} {speed['blade']:6.1f} {speed['gun']:6.1f} "
              f"{speed.get('tip', 0.0):6.1f} {speed.get('muzzle', 0.0):6.1f}   {bars}")


def option(args, flag, count):
    """Takes `flag` and its `count` values out of `args`: (the values or None, the rest)."""
    if flag not in args:
        return None, args
    i = args.index(flag)
    return args[i + 1:i + 1 + count], args[:i] + args[i + 1 + count:]


def main(argv):
    if len(argv) >= 2 and argv[0] == "audit":
        failed = sum(bool(report(path, load(path))) for path in argv[1:])
        return 1 if failed else 0
    if len(argv) >= 2 and argv[0] == "curves":
        span, rest = option(argv[2:], "--span", 2)
        every, rest = option(rest, "--every", 1)
        curves(load(argv[1]), *(float(v) for v in span or (0.0, 1e9)), int(every[0]) if every else 1)
        return 0
    if len(argv) == 2 and argv[0] == "feet":
        clip = load(argv[1])
        for leg, r in feet(clip).items():
            print(f"{leg:9} drift {r['drift']:.3f} st/step  lands at {r['land']:.1f} st/s  "
                  f"skims the floor {r['graze']} frames a cycle  lowest {r['lowest']:+.3f} st")
        return 0
    if len(argv) >= 2 and argv[0] == "fk":
        out, rest = option(argv[2:], "--out", 1)
        clip = load(argv[1])
        times = [float(t) for t in rest] or default_times(clip)
        text = json.dumps(sample(clip, times), separators=(",", ":"))
        if out:
            with open(out[0], "w", encoding="utf-8") as f:
                f.write(text)
            print(f"{clip['Name']}: {len(times)} samples of the export's FK -> {out[0]}")
        else:
            print(text)
        return 0
    if len(argv) >= 2 and argv[0] == "wrists":
        rest = [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1]
        for path in argv[1:]:
            clip = load(path)
            added = set()
            for frame in clip["Frames"]:
                for arm, (joint, _) in WRISTS.items():
                    if arm in frame["Poses"] and joint not in frame["Poses"]:
                        frame["Poses"][joint] = rest
                        added.add(joint)
            with open(path, "w", encoding="utf-8") as f:
                f.write(json.dumps(clip, separators=(",", ":")))
            print(f"{clip['Name']}: {', '.join(sorted(added)) or 'nothing'} keyed at rest -> {path}")
        return 0
    if len(argv) >= 3 and argv[0] == "compare":
        tol, rest = option(argv[1:], "--tol", 2)
        every, rest = option(rest, "--all", 0)
        studs, degrees = (float(tol[0]), float(tol[1])) if tol else TOLERANCE
        a, b = load(rest[0]), load(rest[1])
        matched, worst, missing, free = compare(a, b, every is not None)
        print(f"{a.get('Clip')} ({a.get('Side')}) against {b.get('Clip')} ({b.get('Side')}): "
              f"{matched} sample times in common")
        if a.get("Clip") != b.get("Clip"):
            print("  note: the two files name different clips")
        if free:
            print(f"  not driven, so not checked: {', '.join(free)}")
        over = []
        for (group, name), (d, td, g, tg) in worst.items():
            flag = d > studs or g > degrees
            if flag:
                over.append(name)
            print(f"  {group:10} {name:10} {d:.5f} studs at {td:<7} {g:.3f} deg at {tg}{'   OVER' if flag else ''}")
        for name in missing:
            print(f"  missing on one side: {name}")
        ok = matched > 0 and not over and not missing
        reason = "" if matched else ": no sample times in common"
        print(f"{'PASS' if ok else 'FAIL'} (within {studs:g} stud and {degrees:g} degree){reason}")
        return 0 if ok else 1
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
