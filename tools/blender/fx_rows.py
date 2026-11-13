"""The effects as rows (AR8, "The method"): each effect is a few rows of kit parts (build/handoff/FxKit/, fx_kit.json)
keyed on its clip's markers, for the builder's one player (Config.Effects). This script holds the rows, writes them as
json for the builder, and previews them in grey on the effect's own stage, so the rows are checked at 64 px before the
engine's block-in. The engine's take is the judge; this is the maker's own check.

blender.exe -b --factory-startup --python tools/blender/fx_rows.py -- <out_dir> [B1]

A row is one kit part or one engine object (Part), what it hangs on (On), and its tracks. A track is a list of keys:
[frames after the effect's marker at the clip's 60 a second, the value reached there, the ease on to the next key, as
Roblox names it]. Before a track's first key the row isn't shown; after its last it holds. Values:
- Scale: the part's unit size (fx_kit.json's 'size') times this, per Roblox axis X, Y, Z, at the hit's Area of 5 studs;
  scale it with the Area.
- Spin: degrees round the up axis; negative turns it clockwise seen from above.
- Transparency, Glow (the emissive strength), Size (studs), Brightness, Rate: as Roblox has them.
Particles are given by their emitter's own properties.

B1 (Pip's Lantern Burst, its exit; the director, 2026-11-13: "let do 1"; AR8's method): the lantern's flame let out as
the kit's two-strand coil, wound up round the Shades from the area's edge to a point twice Pip's height. It spins the
way its strands climb, flares white where they meet (70), and from 74 it burns off from its foot: its six bands go
foot first, each flaring hot as it goes, embers rising off the burning edge, the top tongue last, by 84. Two small
flames stand at its feet as the burn starts, the secondary, lower and softer. Two strands, not three: seen from above,
three arms winding out of a centre is the shape B1's content check keeps off every camera (condition 5).
"""
import json
import math
import random
import sys
from pathlib import Path

import bpy
from mathutils import Quaternion, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import fx_kit as kit  # noqa: E402
import pip_burst_fx as pf  # noqa: E402
import pip_clips as pc  # noqa: E402
import r6anim as r6  # noqa: E402
import rook_haymaker_fx as hx  # noqa: E402

KIT = Path(__file__).resolve().parents[2] / "build" / "handoff" / "FxKit" / "fx_kit.json"


# --- the eases, as Roblox names them -------------------------------------------------------------------------------

def ease(name, u):
    u = min(1.0, max(0.0, u))
    if not name or name == "Linear":
        return u
    style, way = name.split()
    power = {"Quad": 2, "Cubic": 3, "Quart": 4}.get(style)
    if style == "Sine":
        f_in = lambda x: 1 - math.cos(x * math.pi / 2)  # noqa: E731
    else:
        f_in = lambda x: x ** power  # noqa: E731
    if way == "In":
        return f_in(u)
    if way == "Out":
        return 1 - f_in(1 - u)
    return f_in(2 * u) / 2 if u < 0.5 else 1 - f_in(2 - 2 * u) / 2


def value(track, t):
    """A track's value at frame t after the marker; None before its first key. Scalars and lists alike."""
    if not track or t < track[0][0]:
        return None
    for (t0, v0, how), (t1, v1, _) in zip(track, track[1:]):
        if t0 <= t <= t1:
            u = ease(how, (t - t0) / (t1 - t0)) if t1 > t0 else 1.0
            if isinstance(v0, list):
                return [a + (b - a) * u for a, b in zip(v0, v1)]
            return v0 + (v1 - v0) * u
    return track[-1][1]


# --- B1: the coil let out, burning off from its foot ----------------------------------------------------------------

AREA = 5.0
COIL = "FxCoil2"
H = 2.0 * AREA / 2.144   # across: the foot's outer edge two Areas wide (the unit coil is 2.144 across)
V = AREA                 # up: the tip 2.2 Areas up, 11 studs at Area 5 (the unit coil's strands climb 2.2)
BANDS = 6
BURN, STEP, GOES = 8, 1.5, 3   # the first band starts going on 74; each next one STEP frames later; each takes GOES
HOT, COOL = (1.0, 0.97, 0.88), (1.0, 0.54, 0.24)  # white-gold, and the flame's orange (#FF8A3D's family, never redder)


def band_tracks(k):
    start = BURN + STEP * (k - 1)
    return {"Transparency": [[0, 0.0, None], [start, 0.0, "Quad In"], [start + GOES, 1.0, None]],
            "Glow": [[0, 2.0, None], [start, 2.0, "Quad Out"], [start + GOES * 0.5, 4.0, "Linear"], [start + GOES, 4.0, None]]}


B1 = {
    "Effect": "Lantern Burst's coil and its exit (AR8, B1)",
    "Clip": "PipLanternBurst", "From": "Burst", "Marker": pf.BURST, "Fps": 60, "Area": AREA,
    "Kit": "build/handoff/FxKit/fx_kit.json: each part's unit 'size', and a coil band's 'offset'",
    "On": "the ground under the lantern's stop, where Config.Effects.LanternBurst.Burst stands its foot",
    "Replaces": "the coil's picture (Config.Effects.LanternBurst.Burst); the heat and the trail stay",
    "Rows": [
        {"Name": "Coil", "Part": [f"{COIL}_Burn{k}" for k in range(1, BANDS + 1)], "Texture": "fx_across_Flame",
         "BlockIn": "fx_across_Grey",
         "Place": "the six bands as one coil: its foot on the ground at On, each band at the coil's centre plus its "
                  "'offset' times the scale; all six share the Scale and Spin, each has its own Transparency and Glow",
         "Tracks": {"Scale": [[0, [round(H * 0.92, 3), V * 0.6, round(H * 0.92, 3)], "Quart Out"],
                              [4, [round(H, 3), V, round(H, 3)], "Linear"],
                              [18.5, [round(H, 3), round(V * 1.12, 3), round(H, 3)], None]],
                    "Spin": [[0, 0.0, "Quart Out"], [18.5, -150.0, None]]},
         "Bands": {f"{COIL}_Burn{k}": band_tracks(k) for k in range(1, BANDS + 1)},
         "Why": "a third grown and already over the target's head on the hit, whole by 70; it turns clockwise from "
                "above, the way its strands climb, and stretches up as it burns; the bands go foot first, each "
                "flaring hot as it fades, the tip last, gone on 84"},
        {"Name": "Flare", "Part": "fx_glow", "On": "the coil's tip", "Kind": "a card or one particle, facing the camera",
         "Color": HOT, "LightEmission": 1,
         "Tracks": {"Size": [[3, 3.0, "Quad Out"], [4, 5.5, "Quad In"], [5, 4.0, "Linear"], [6, 2.0, "Linear"],
                             [7, 0.0, None]]},
         "Why": "the effect's one white, its focal point, on 70 (rule 3)"},
        {"Name": "Embers", "Part": "fx_ember", "Kind": "ParticleEmitter, Shape Disc, EmissionDirection Top",
         "On": "a disc riding the burning edge: from the foot on 74 to the tip on 84, its radius the coil's there",
         "Emitter": {"Rate": 90, "Lifetime": [0.35, 0.6], "Speed": [3, 6], "Acceleration": [0, 4, 0], "Drag": 2,
                     "Size": [[0, 0.5], [1, 0.0]], "Color": [[0, (1.0, 0.84, 0.55)], [1, list(COOL)]],
                     "LightEmission": 1, "FlipbookMode": "Loop", "FlipbookStartRandom": True},
         "Tracks": {"Rate": [[8, 90.0, None], [18.5, 90.0, None], [19, 0.0, None]]},
         "Why": "the burn reads as burning: embers rise off the edge as it climbs; never falling, never red (the kit)"},
        {"Name": "Feet", "Part": "fx_flame", "Kind": "ParticleEmitter, one burst",
         "On": "the coil's two feet, where its strands leave the ground (turned with the Spin)",
         "Emitter": {"Burst": 2, "At": 8, "Lifetime": [0.3, 0.45], "Speed": [0.5, 1.5], "Size": [1.4, 2.0],
                     "Color": [[0, (1.0, 0.86, 0.5)], [1, list(COOL)]], "LightEmission": 0.6,
                     "FlipbookMode": "OneShot"},
         "Why": "the secondary, a breath after the peak, lower and softer, where the burn starts"},
        {"Name": "Light", "Part": "PointLight", "On": "the coil's middle", "Range": 16, "Color": (1.0, 0.69, 0.38),
         "Tracks": {"Brightness": [[0, 1.5, "Quart Out"], [4, 4.0, "Cubic In"], [18.5, 0.0, None]]},
         "Why": "the Shades and the floor lit by it, brightest on the flare"},
    ],
}
EFFECTS = {"B1": B1}


# --- the grey preview on Pip's stage ---------------------------------------------------------------------------------

def coil_mesh(name, lo, hi):
    bm = kit.coil(2, 1.0, lo, hi)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    return mesh


def foot_radius(s):
    """The coil's centre line's radius at s (0 the foot, 1 the tips), in the unit coil."""
    return kit.C_TOP + (kit.C_FOOT - kit.C_TOP) * (1 - s) ** 1.6


def shapes(stage, t):
    """The rows at frame t after the Burst, as the stage's shapes: (kind, shade, where, scale, turn)."""
    rows = {row["Name"]: row for row in B1["Rows"]}
    coil = rows["Coil"]
    scale, spin = value(coil["Tracks"]["Scale"], t), value(coil["Tracks"]["Spin"], t)
    at = stage.lamp[pf.BURST]
    foot = Vector((at.x, at.y, 0.0))
    out = []
    if scale is None:
        return out
    sx, sy, sz = scale  # Roblox X, Y (up), Z
    turn = Quaternion((0.0, 0.0, 1.0), math.radians(spin))
    for k in range(1, BANDS + 1):
        gone = value(coil["Bands"][f"{COIL}_Burn{k}"]["Transparency"], t) or 0.0
        if gone < 0.67:
            out.append((f"band{k}", "white" if gone < 0.34 else "mid", foot, (sx, sz, sy), turn))
    tip = foot + Vector((0.0, 0.0, kit.C_HEIGHT * sy))
    size = value(rows["Flare"]["Tracks"]["Size"], t)
    if size:
        out.append(("ball", "white", tip, (size / 2,) * 3, Quaternion()))
    rng = random.Random(5)
    for a in range(int(BURN), int(BURN + STEP * (BANDS - 1) + GOES) + 1):  # embers let go each frame of the burn
        front = min(1.0, (a - BURN) / (STEP * (BANDS - 1) + GOES))
        for _ in range(3):
            late, angle, spread = rng.random(), rng.uniform(0, 2 * math.pi), rng.uniform(0.7, 1.05)
            life, speed = 60 * rng.uniform(0.35, 0.6), rng.uniform(3, 6) / 60  # frames at the clip's 60; studs a frame
            age = t - a - late
            if 0 <= age <= life:
                r, rise = foot_radius(front) * sx * spread, speed * age + 0.5 * 4 / 3600 * age * age
                place = foot + Vector((r * math.cos(angle), r * math.sin(angle), kit.C_HEIGHT * front * sy + rise))
                size = 0.5 * (1 - age / life)
                out.append(("box", "mid", place, (size, size, size), Quaternion()))
    feet = rows["Feet"]["Emitter"]
    age = t - feet["At"]
    if 0 <= age <= 0.45 * 60:
        for base in (0.0, math.pi):
            angle = base + math.radians(value(coil["Tracks"]["Spin"], feet["At"]))
            r = kit.C_FOOT * sx
            h = 1.7 * (1 - age / (0.45 * 60)) ** 0.7
            if h > 0.15:
                out.append(("cone", "mid", foot + Vector((r * math.cos(angle), r * math.sin(angle), h / 2)),
                            (0.6, 0.6, h), Quaternion()))
    return out


def layout(stage, variant, f):
    t = f - pf.BURST
    return pf.trail(stage, f) + (shapes(stage, t) if 0 <= t <= 30 else [])


def size_of(stage, variant, f):
    top = 0.0
    for kind, _, centre, size, _ in layout(stage, variant, f):
        top = max(top, centre.z + (kit.C_HEIGHT * size[2] if kind.startswith("band") else size[2] / 2))
    return round(top, 2)


_make = pf.Stage.make


def make(self, kind, shade):
    if not kind.startswith("band"):
        return _make(self, kind, shade)
    k = int(kind[4:])
    obj = bpy.data.objects.new(f"Fx.{kind}.{shade}", coil_mesh(kind, (k - 1) / BANDS, k / BANDS))
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(self.materials[shade])
    obj.display.show_shadows, obj.rotation_mode, obj.hide_render = False, "QUATERNION", True
    return obj


SHEET = (64, 66, 67, 68, 69, 70, 72, 74, 75, 76, 77, 78, 80, 82, 84, 86)
STRIP = (66, 68, 70, 73, 75, 77, 79, 81, 83, 86)


def main():
    sys.stdout.reconfigure(line_buffering=True)
    out = bl.out_dir()
    (out / "pip_burst_rows.json").write_text(json.dumps(B1, indent=1) + "\n", encoding="utf-8")
    print(f"wrote {out / 'pip_burst_rows.json'}")
    recipe = json.loads(KIT.read_text())["meshes"]
    unit = recipe[COIL]["size"]
    print(f"the coil at Area {AREA:g}: {H * unit[0]:.1f} studs across its foot, {V * unit[1]:.1f} tall "
          f"(its box), the tip {kit.C_HEIGHT * V:.1f} up; the bands go {pf.BURST + BURN} to "
          f"{pf.BURST + BURN + STEP * (BANDS - 1) + GOES:g}")
    pf.VARIANTS = {"R": ("B1's rows", None)}
    pf.layout, pf.Stage.make = layout, make
    scene, rig, costume, undress, feet, ctl, motors = pc.build()
    frames = pf.key(rig)
    stage = pf.Stage(scene, rig, frames)
    stage.variant = "R"
    cams = {}
    for name in ("fight", "fight50", "hidden"):
        look, spot = pf.staged(name)
        azimuth = math.degrees(math.atan2(-look.x, -look.y))
        cams[name] = hx.camera(scene, name, azimuth, pf.PITCH, pf.EYE / math.cos(math.radians(pf.PITCH)),
                               (spot.x, spot.y, 4.5), 50.0 if name == "fight50" else 70.0)
    at = stage.lamp[pf.BURST]
    cams["side"] = hx.camera(scene, "side", 90.0, 6.0, 34.0, (at.x, 7.0, 4.5), 36.0)
    cams["above"] = hx.camera(scene, "above", -45.0, 62.0, 30.0, (at.x, at.y, 3.0), 50.0)
    bpy.data.objects["Floor"].scale *= 4
    floor = bpy.data.objects["Floor"].data.materials[0]
    dusk = tuple(floor.diffuse_color)
    scene.render.resolution_x, scene.render.resolution_y = 480, 270
    shots = [(cams["fight"], f, ("B1's rows: " if f == SHEET[0] else "") + pf.label(f)) for f in SHEET]
    print(f"wrote {r6.render_shots(scene, shots, out / 'b1_rows_fight.png', columns=4)}")
    tile = (256, 144)
    for name in ("side", "hidden", "above"):
        shots = [(cams[name], f, f"{name} {f}", "R") for f in STRIP]
        print(f"wrote {hx.render_variants(scene, stage, shots, out / f'b1_rows_{name}.png', len(STRIP), tile)}")
    floor.diffuse_color = (0.74, 0.72, 0.68, 1)
    shots = [(cams["fight"], f, f"bright {f}", "R") for f in STRIP]
    print(f"wrote {hx.render_variants(scene, stage, shots, out / 'b1_rows_bright.png', len(STRIP), tile)}")
    floor.diffuse_color = dusk
    shots = [(cams["fight50"], f, f"{f}", "R") for f in STRIP]
    print(f"wrote {hx.render_variants(scene, stage, shots, out / 'b1_rows_64.png', len(STRIP), (75, 64))}")
    pf.SHARE = (66, 67, 68, 70, 72, 74, 76, 78, 80, 82, 84, 86)
    share = pf.share(scene, stage, cams["fight"], ["R"], out / "share.png")["R"]
    tops = {f: size_of(stage, "R", f) for f in pf.SHARE}
    print("share of the screen: " + " ".join(f"{f}:{v:.2%}" for f, v in share.items()))
    print("the top, studs: " + " ".join(f"{f}:{v}" for f, v in tops.items()))
    (out / "b1_rows.json").write_text(json.dumps({"share": share, "top": tops}, indent=1) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
