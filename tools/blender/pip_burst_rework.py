"""Pip's Lantern Burst, the rework's blockout (AR8, part B; docs/asset-requests.md). The director, 2026-11-12: "the vfx of
the mage skill is kinda odd but we will keep it make a rework planned for it". The effects pass measures it against
docs/research/vfx-reference.md, rule 3: one main shape and three stages, the peak in the first quarter of its life and
an eased fade, the secondary a breath later, lower and softer.

blender.exe -b --factory-startup --python tools/blender/pip_burst_rework.py -- <out_dir> [B D E G]

Grey shapes on the same stage as the first block-in (pip_burst_fx.py, whose sheets, cameras and measures it reuses):
Pip's delivered LanternBurst clip, the stand-in Shades, the avatar where the player's camera looks past it. White is the
main shape, mid grey the secondary. What played was B, a flat flame cut out in ink, held big over the target for most
of its life and boiling in place (build/captures/ar4/pip_burst_boil1x2_burst.png); its grey row stays as the "before".
The heat and the trail are kept; the kick's ring is dropped (AR4, section 7: it added nothing in motion). Each new idea
is already a third grown on the Burst frame, so its first frame clears the target's head, and gone 26 frames later:
- D, the flare: a ball of fire the area's size in four frames, then it lifts off and burns down; a low wall of light
  runs out past the area's edge a breath later, and embers are flung out and up.
- E, the spill: the lantern poured out. Fire runs along the ground to the area's edge and rears up there in a crest,
  waist high round every Shade it holds; a breath later the lantern's own flame stands up in the middle; then the crest
  tears up off the ground and goes out.
- G, the twister: three ribbons of fire spring up round the area's edge and wind in to a point high over the target,
  then unwind upward off the ground and go out; the low wall a breath later.
"""
import math
import random
import sys
from pathlib import Path

import bpy
from mathutils import Quaternion, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import pip_burst_fx as pf  # noqa: E402
import rook_haymaker_fx as hx  # noqa: E402

AREA, BURST = pf.AREA, pf.BURST
LIFE = 26                   # the burst's frames, 66 to 92: gone by the time he gets his hat up
EMBERS, RIBBONS, SEGMENTS = 9, 3, 18


def grow(t, frames):
    """Out fast over `frames`, already a third of the way on the Burst frame itself."""
    return hx.out_fast((t + 1) / (frames + 1))


def low_wall(at, a, frames):
    """The secondary, a breath after the peak: a low wall of light running out past the area's edge, sinking as it
    goes. Mid grey: lower in value than the main shape."""
    if not 0 <= a <= frames:
        return []
    r = AREA * (0.7 + 0.42 * hx.out_fast(a / frames))
    h = 1.1 * (1 - hx.clamp(a / frames)) ** 1.4
    return [("tube", "mid", Vector((at.x, at.y, h / 2)), (r, r, h), Quaternion())] if h > 0.05 else []


def flare(stage, t):
    """D: a ball of fire the area's size in four frames, then it lifts off and burns down; the low wall a breath later,
    and embers flung out and up, slowing as they rise."""
    at, out = stage.lamp[BURST], []
    fade = hx.clamp((t - 4) / (LIFE - 4))
    r = (0.85 + (0.72 * AREA - 0.85) * grow(t, 4)) * (1 - 0.75 * pf.smooth(fade))
    if fade < 1 and r > 0.1:
        out.append(("ball", "white", Vector((at.x, at.y, at.z + 7.0 * fade ** 1.6)), (r, r, 1.15 * r), Quaternion()))
    out += low_wall(at, t - 5, 12)
    for angle, reach, lift, lag in stage.embers:
        a = t - 2 - lag
        if 0 <= a <= 20:
            d, s = AREA * reach * hx.out_fast(a / 9), 0.5 * (1 - a / 20) ** 0.8
            p = Vector((at.x + d * math.cos(angle), at.y + d * math.sin(angle), at.z + lift * a + 0.012 * a * a))
            out.append(("box", "mid", p, (s, s, s), Quaternion()))
    return out


def spill(stage, t):
    """E: fire runs out along the ground to the area's edge and rears up there in a crest, waist high; a breath later
    the lantern's flame stands up in the middle; then the crest tears up off the ground and goes out."""
    at, out = stage.lamp[BURST], []
    run, tear = grow(t, 6), hx.clamp((t - 9) / (LIFE - 9))
    if tear < 1:
        r = (0.6 + (AREA - 0.6) * run) * (1 + 0.08 * tear)
        h, foot = (0.6 + 2.8 * run) * (1 - 0.6 * tear), 3.5 * tear ** 1.5
        out.append(("tube", "white", Vector((at.x, at.y, foot + h / 2)), (r, r, h), Quaternion()))
    a = t - 6
    if 0 <= a <= 16:
        h = 8.0 * hx.out_fast(a / 5) * (1 - 0.5 * hx.clamp((a - 6) / 10))
        rb, foot = 1.5 * (1 - hx.clamp((a - 4) / 12)), 0.2 + 5.0 * hx.clamp((a - 6) / 10) ** 1.5
        if rb > 0.08 and h > 0.2:
            out.append(("flame", "mid", Vector((at.x, at.y, foot + h / 2)), (rb, rb, h), Quaternion()))
    return out


def twister(stage, t, late=7, ease=pf.smooth):
    """G: three ribbons spring up round the area's edge and wind in to a point high over the target; then they unwind
    upward off the ground and go out. The low wall a breath later."""
    at, out = stage.lamp[BURST], []
    head, tail = grow(t, 5), ease((t - late) / (LIFE - late))
    if head - tail > 0.02:
        top, spin, width = 11.0 + 2.0 * tail, 1.8 * hx.out_fast(t / LIFE), 0.9 * (1 - 0.6 * tail)
        for k in range(RIBBONS):
            base, points = stage.bar0 + k * 2 * math.pi / RIBBONS, []
            for i in range(SEGMENTS + 1):
                s = tail + (head - tail) * i / SEGMENTS
                angle, rho = base + 2.6 * math.pi * s * (1 - 0.35 * tail) + spin, AREA * 0.95 * (1 - 0.78 * s)
                points.append(Vector((at.x + rho * math.cos(angle), at.y + rho * math.sin(angle), 0.2 + top * s)))
            for p, q in zip(points, points[1:]):
                span = q - p
                if span.length > 0.05:
                    out.append(("box", "white", (p + q) / 2, (width, width, span.length + 0.1), pf.toward(span)))
    return out + low_wall(at, t - 4, 12)


def before(stage, t):
    """B as it played: the ball on the Burst frame, then the one flame let out (pip_burst_fx.let_out)."""
    if t == 0:
        return [("ball", "white", stage.lamp[BURST], (1.7, 1.7, 1.7), Quaternion())]
    return pf.let_out(stage, t)


def let_go(stage, t):
    """H, G let go sooner: G held its whole coil from 70 to 79; here the foot leaves the ground two frames after the
    peak and fast at first, so the coil is already climbing off the Shades while it is still bright."""
    return twister(stage, t, late=5, ease=lambda x: 1 - (1 - hx.clamp(x)) ** 1.7)


VARIANTS = {"B": ("before, the flame let out", before), "D": ("the flare", flare), "E": ("the spill", spill),
            "G": ("the twister", twister), "H": ("the twister let go sooner", let_go)}


def layout(stage, variant, f):
    out, t = pf.trail(stage, f), f - BURST  # the kick's ring is dropped
    return out + (VARIANTS[variant][1](stage, t) if 0 <= t <= LIFE + 4 else [])


def size_of(stage, variant, f):
    """How tall the effect stands on a frame, and how far it reaches from the lantern's stop."""
    top, reach, at = 0.0, 0.0, stage.lamp[BURST]
    for kind, _, centre, size, _ in layout(stage, variant, f):
        top = max(top, centre.z + (max(size) / 2 if kind in ("box", "ring") else size[2] / 2))
        across = max(size[0], size[1]) if kind in ("cone", "lid", "ball", "flame", "tube") else max(size) / 2
        reach = max(reach, (centre.xy - at.xy).length + across)
    return round(top, 2), round(reach, 2)


_make, _init = pf.Stage.make, pf.Stage.__init__


def make(self, kind, shade):
    """The first block-in's shapes, and an open tube a stud tall about its middle for the walls."""
    if kind != "tube":
        return _make(self, kind, shade)
    bpy.ops.mesh.primitive_cylinder_add(vertices=40, radius=1.0, depth=1.0, end_fill_type="NOTHING")
    obj = bpy.context.active_object
    obj.data.materials.append(self.materials[shade])
    obj.display.show_shadows, obj.rotation_mode, obj.hide_render = False, "QUATERNION", True
    return obj


def init(self, scene, rig, frames):
    _init(self, scene, rig, frames)
    rng = random.Random(23)
    self.embers = [(i * 2 * math.pi / EMBERS + rng.uniform(-0.3, 0.3), rng.uniform(0.6, 1.05), rng.uniform(0.12, 0.28),
                    rng.randint(0, 3)) for i in range(EMBERS)]


if __name__ == "__main__":
    pf.VARIANTS, pf.layout, pf.size_of = VARIANTS, layout, size_of
    pf.Stage.make, pf.Stage.__init__ = make, init
    # the burst's own frames, denser where it peaks; the wind-up was judged at the first block-in
    pf.SHEET = (51, 60, 64, 66, 67, 68, 69, 70, 72, 74, 76, 79, 82, 86, 90, 95)
    pf.STRIP = (64, 66, 67, 68, 70, 72, 75, 79, 84, 92)
    pf.SHARE = (66, 67, 68, 70, 72, 76, 80, 86)
    pf.main()
