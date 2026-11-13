"""The effects as rows (AR8, "The method"): each effect is a few rows of kit parts (build/handoff/FxKit/, fx_kit.json)
keyed on its clip's markers, for the builder's one player (Config.Effects). This script holds the rows, writes them as
json for the builder, and previews them in grey on the effect's own stage, so the rows are checked at 64 px before the
engine's block-in. The engine's take is the judge; this is the maker's own check.

blender.exe -b --factory-startup --python tools/blender/fx_rows.py -- <out_dir> [B1 | Finish | Signature [Back] | B5 [Close | Small] [<clip>]]
(Finish: B1's rows with fix 3's look, and its sheets before and after; Back: only the sheets behind the keeper the
content check asked for, round the hat at 64 px; Close, Small: only B5's close sheet, or its 64 px sheets; B5's clip
defaults to the delivered Rook_Haymaker.json)

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
foot first, each flaring hot and cut two frames in (never faded), embers rising off the burning edge, the top tongue
last, by 84. Two small
flames stand at its feet as the burn starts, the secondary, lower and softer. Two strands, not three: seen from above,
three arms winding out of a centre is the shape B1's content check keeps off every camera (condition 5).

B1's finish (research's fix 3, "a ragged, brighter tongue edge on the burning front as it eats upward; and a darker
saturated edge on a bright core along the bands"): the coil's bands take fx_fire_Flame, drawn for the engine's self-lit
look, and a Front row puts the kit's FxCoil2_Front<b> at the top of each band as it burns, bright tongues off its edge.
Previewed on a plain stage through fx_kit.engine's model of the self-lit look (the bands and fronts by an id pass, a
mild bloom), before and after, at noon and dusk: a model, so the engine's take beside the grey is the judge.

Signature (the Lamplighter's, AR7 section 7 with option 1's clip; AR8's order 3): section 7's three Beams carry over,
and the hold's glow card becomes a light and a small shell. Through the hold the lantern's own paper climbs toward its
hot glow, a light in it falls on your fighter, and a shell of warm light hugs the drum, swelling; from 100 the light and
the shell are drawn into the paper, gone by 104 (the content check's condition a), and the paper alone flares on the
Wrench. A straight streak follows the fall, clear of the keeper's head (condition b). On the Slam the paper goes dim and
the light leaps up out of the street where it landed: the column, its foot letting go on 123, climbing away by 140, chips
flung up off its edge, a light on the street. Previewed on the art's own stage (lamplighter_signature_art.py), which
lays the Beams per pixel from their pictures; the paper's glow and the lights aren't drawn there.

B5 (Rook's Haymaker, AR8's order 4; research's fix 3, "a bright interior and a darker, saturated edge"): the stamp's
square as a framed plate standing up. Effects.luau's stampAt keeps its geometry (w, h, z, bar, gone each frame); its
grey Parts become four FxBar strokes on fx_across_Ember, dark-rimmed with a hot core down each, round an FxPlate on
fx_rise_Ember, bright at its foot, the edge that leads down. The plate charges through the hang, flashes on Strike and
is gone by the third frame after, before the stamp lies flat: nothing glows on the floor. Fix 1's draw-in is offered
in the numbers: the square forms loose, 1.2 of its side with thin bars, and is drawn tight as the ram is, slowly, then
fast into the beat too long. Previewed on rook_haymaker_stamp.py's stage, the target pinned; the parts drawn unlit,
as their glow mask draws them, over the lit stage, the plate at its transparency.
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
import fx_kit as kit  # noqa: E402
import lamplighter_clips as lc  # noqa: E402
import lamplighter_signature_art as sa  # noqa: E402  (the column's numbers and pictures, and its per-pixel stage)
import lamplighter_signature_fx as sig  # noqa: E402  (the keeper's stage, its clip, markers and cameras)
import pip_burst_fx as pf  # noqa: E402
import pip_clips as pc  # noqa: E402
import r6anim as r6  # noqa: E402
import rook_clips as rc  # noqa: E402
import rook_haymaker_fx as hx  # noqa: E402
import rook_haymaker_stamp as st  # noqa: E402  (B5's stage: the target, the avatar, the cameras, the clip's keys)

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
H = 0.7 * 2.0 * AREA / 2.144  # across: 0.7 of two Areas (the unit coil is 2.144 across), so it hugs the Shades
# rather than ballooning past them: research's fix 1, tuned live by Faber (AR8, "Fixes 1 and 2", e8aac57)
V = AREA                 # up: the tip 2.2 Areas up, 11 studs at Area 5 (the unit coil's strands climb 2.2)
BANDS = 6
BURN, STEP, GOES = 8, 1.5, 3   # the first band starts going on 74; each next one STEP frames later; each takes GOES
CUT = 2  # frames into its burn a band is cut, whole until then: never faded (B1's finish, in the engine, 758c83b)
HOT, COOL = (1.0, 0.97, 0.88), (1.0, 0.54, 0.24)  # white-gold, and the flame's orange (#FF8A3D's family, never redder)


def band_tracks(k):
    """Band k's burn: it flares from 2 to 4 from its start and is cut CUT frames in, its front covering the cut. Never
    a fade: in the engine a half-gone band over a dark Shade or a dusk sky read rose, redder than #FF8A3D (B1's finish,
    the content check's conditions 1 and 4)."""
    start = BURN + STEP * (k - 1)
    return {"Transparency": [[0, 0.0, None], [start + CUT, 0.0, None], [start + CUT, 1.0, None]],
            "Glow": [[0, 2.0, None], [start, 2.0, "Quad Out"], [start + GOES * 0.5, 4.0, "Linear"], [start + GOES, 4.0, None]]}


COIL_SCALE = [[0, [round(H * 0.92, 3), V * 0.6, round(H * 0.92, 3)], "Quart Out"], [4, [round(H, 3), V, round(H, 3)], "Linear"],
              [18.5, [round(H, 3), round(V * 1.12, 3), round(H, 3)], None]]
FIRE_LOOK, FRONT_GLOW = "fx_fire_Flame", 3.0  # fix 3: the bands on fire (fx_kit.fire); the front brighter than they are


def front_tracks(b):
    """The front where band b meets b + 1: shown as band b starts to burn, held until band b + 1 has started, then gone,
    so the line of tongues climbs a band every STEP frames, from 74 to the tips' band."""
    on, off = BURN + STEP * (b - 1), BURN + STEP * b + 0.5
    return {"Transparency": [[0, 1.0, None], [on, 1.0, "Linear"], [on + 0.5, 0.0, None], [off, 0.0, "Quad In"],
                             [off + 1.0, 1.0, None]],
            "Glow": [[0, FRONT_GLOW, None]]}


B1 = {
    "Effect": "Lantern Burst's coil and its exit (AR8, B1)",
    "Clip": "PipLanternBurst", "From": "Burst", "Marker": pf.BURST, "Fps": 60, "Area": AREA,
    "Kit": "build/handoff/FxKit/fx_kit.json: each part's unit 'size', and a coil band's 'offset'",
    "On": "the ground under the lantern's stop, where Config.Effects.LanternBurst.Burst stands its foot",
    "Replaces": "the coil's picture (Config.Effects.LanternBurst.Burst); the heat and the trail stay",
    "Rows": [
        {"Name": "Coil", "Part": [f"{COIL}_Burn{k}" for k in range(1, BANDS + 1)], "Texture": FIRE_LOOK,
         "BlockIn": "fx_across_Grey",
         "Place": "the six bands as one coil: its foot on the ground at On, each band at the coil's centre plus its "
                  "'offset' times the scale; all six share the Scale and Spin, each has its own Transparency and Glow",
         "Tracks": {"Scale": COIL_SCALE, "Spin": [[0, 0.0, "Quart Out"], [18.5, -150.0, None]]},
         "Bands": {f"{COIL}_Burn{k}": band_tracks(k) for k in range(1, BANDS + 1)},
         "Why": "a third grown and already over the target's head on the hit, whole by 70; it turns clockwise from "
                "above, the way its strands climb, and stretches up as it burns; the bands go foot first, each "
                "flaring hot and cut two frames in, never faded (half-gone, it read rose over a dark Shade or a dusk "
                "sky), the front covering the cut, the tip last, gone on 84. On fire (fix 3): a dark saturated rim, "
                "then the flame's orange, gold, and a white core licking up each strand, drawn for the Glow of 2"},
        {"Name": "Front", "Part": [f"{COIL}_Front{b}" for b in range(1, BANDS)], "Texture": "fx_rise_Flame",
         "BlockIn": "fx_rise_Grey", "On": "Coil",
         "Place": "on the coil's frame, its spin included, each at its centre times the scale as the bands are; "
                  "its Scale the coil's own keys",
         "Tracks": {"Scale": COIL_SCALE},
         "Bands": {f"{COIL}_Front{b}": front_tracks(b) for b in range(1, BANDS)},
         "Why": "fix 3: the burning edge, a white line across each strand with a ragged row of tongues licking up it, "
                "brighter than the bands; it climbs a band every 1.5 frames from 74 and goes with the tips' band"},
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
        {"Name": "Light", "Part": "PointLight", "On": "the coil's middle", "Range": 8, "Color": (1.0, 0.66, 0.22),
         "Tracks": {"Brightness": [[0, 1.5, "Quart Out"], [4, 4.0, "Sine InOut"], [8, 3.2, "Linear"],
                                   [18.5, 0.0, None]]},
         "Why": "the Shades and the floor under the coil lit by it in the flame's amber, peaking on the flare and "
                "falling with the burn (research's fix 2, tuned live by Faber)"},
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


# --- the keeper's signature: the lantern's light gathered, then let out of the street (AR7, AR8's order 3) -----------

LIGHT, LOOK, WRENCH, SLAM = sig.LIGHT, sig.LOOK, sig.WRENCH, sig.SLAM
S = sig.S                    # studs a keeper's unit
SHELL_UNIT = 2.0             # FxShell's unit size (fx_kit.json)
CHIP_UNIT = (1.0, 0.1424, 0.3469)  # FxChip1's, X Y Z: long, thin, wide
STREAK = {"Width": 3.3, "Beyond": 0.9, "Lag": 5, "From": 5, "Last": 10}  # studs; frames after the Wrench (111 to 116)


def mix(a, b, u=0.5):
    return tuple(round(x + (y - x) * u, 3) for x, y in zip(sa.rs.rgb(a), sa.rs.rgb(b)))


def per_frame(values):
    """A track keyed on every frame, straight between them: the column's numbers as the art drew them."""
    keys = [[t, round(v, 3), "Linear"] for t, v in values]
    keys[-1][2] = None
    return keys


def column_tracks():
    ts = [t for t in sa.TIMES if sa.column_at(t)]
    c = {t: sa.column_at(t) for t in ts}
    clear = per_frame([(t, 1 - c[t]["opaque"]) for t in ts])
    clear[-1][2] = "Linear"
    clear.append([ts[-1] + 1, 1.0, None])  # gone the frame after its last
    return {
        "Foot": per_frame([(t, c[t]["foot"] * S) for t in ts]),
        "Top": per_frame([(t, c[t]["top"] * S) for t in ts]),
        "Width": per_frame([(t, c[t]["width"] * S) for t in ts]),
        "Spike": per_frame([(t, c[t]["spike"] * S) for t in ts]),
        "Transparency": clear,
        "HaloWidth": per_frame([(t, sa.HALO * sa.FLASH.get(t, 1.0) * c[t]["width"] * S) for t in ts]),
    }


def chip_rows(chips):
    """Each chip as the art flings it (lamplighter_signature_art.art): out and up off the column's edge from a breath
    after the peak, shrinking to nothing over 18 frames, never falling. Offsets in studs from where the lantern lands,
    in the keeper's frame: X its right, Y up, Z toward its back."""
    out = []
    for i, (angle, reach, lift, lag) in enumerate(chips):
        start, offset, scale = sa.CHIPS + lag, [], []
        for a in (0, 2, 4, 6, 9, 12, 15, 18):
            d = sa.CHIP_EDGE * sa.WIDE + 5.0 * reach * hx.out_fast(a / 10)
            up = 0.8 + 5.5 * lift * hx.out_fast(a / 14)
            offset.append([start + a, [round(d * math.cos(angle) * S, 2), round(up * S, 2),
                                       round(-d * math.sin(angle) * S, 2)], "Linear"])
            scale.append([start + a, round(1.4 * sa.CHIP_SIZE * (1 - a / 18) ** 0.8 * S, 3), "Linear"])
        offset[-1][2] = scale[-1][2] = None
        out.append({"Part": f"FxChip{i % 3 + 1}", "Color": "cyan" if i % 2 == 0 else "warm",
                    "Turn": [round(math.degrees(angle), 1), 45.0, -34.4],
                    "Tracks": {"Offset": offset, "Scale": scale}})
    return out


def keeper(chips):
    cyan, warm = sa.rs.rgb(sa.CYAN), sa.rs.rgb(sa.WARM)
    lamp_light = mix(sa.CORE, sa.CYAN, 0.4)
    col = column_tracks()
    return {
        "Effect": "The Lamplighter's signature (AR7 section 7, option 1's clip; AR8's order 3)",
        "Clip": "LamplighterSignature", "Fps": 60, "Markers": dict(sig.MARKS),
        "Kit": "build/handoff/FxKit/fx_kit.json, and the column's three pictures beside these rows",
        "Colors": {"cyan": [round(v, 3) for v in cyan], "warm": [round(v, 3) for v in warm]},
        "Units": "studs; a row's keys are frames after its From marker, at the clip's 60",
        "Rows": [
            {"Name": "Paper", "From": "Light", "Part": "Lamplighter_Lantern's SurfaceAppearance",
             "Kind": "EmissiveStrength on the model's own lantern (its recipe: 1.2 cold, 3.0 hot)",
             "Tracks": {"EmissiveStrength": [[0, 1.2, "Sine InOut"], [52, 2.2, "Quad In"], [60, 2.6, "Linear"],
                                             [62, 3.0, "Linear"], [63, 3.0, "Quad Out"], [68, 2.4, "Linear"],
                                             [74, 2.4, "Quart Out"], [75, 0.4, "Sine InOut"], [116, 1.2, None]]},
             "Why": "the light gathers in the paper through the hold (1.2 to 2.2 at the look, 96), climbs as the light "
                    "and shell are drawn into it (to 104), flares to its top on the Wrench for two frames (106, 107), "
                    "holds hot through the fall, and goes dim on the Slam: its light has gone into the street. It "
                    "relights to 1.2 by 160. Only the paper glows from 104 to 118 (condition a)"},
            {"Name": "HoldLight", "From": "Light", "Part": "PointLight", "On": "the lantern's drum, its middle",
             "Range": 14, "Shadows": False, "Color": lamp_light,
             "Tracks": {"Brightness": [[0, 0.0, "Quad Out"], [6, 1.2, "Sine InOut"], [52, 2.4, "Quad In"],
                                       [56, 3.2, "Quad In"], [60, 0.0, None]]},
             "Why": "lamplight on your fighter and the street under the lantern, building to the look; drawn into "
                    "the paper from 100, out by 104 (condition a)"},
            {"Name": "Shell", "From": "Light", "Part": "FxShell", "Texture": "fx_rise_Warm", "BlockIn": "fx_rise_Grey",
             "On": "welded at the drum's middle, turning with the lantern",
             "Tracks": {"Scale": [[0, [1.6, 1.9, 1.6], "Quad Out"], [8, [1.75, 2.1, 1.75], "Sine InOut"],
                                  [52, [1.9, 2.25, 1.9], "Linear"], [56, [1.9, 2.25, 1.9], "Quad In"],
                                  [60, [1.5, 1.75, 1.5], None]],
                        "Transparency": [[0, 1.0, "Quad Out"], [8, 0.6, "Sine InOut"], [52, 0.45, "Linear"],
                                         [56, 0.4, "Quad In"], [60, 1.0, None]],
                        "Glow": [[0, 1.5, "Sine InOut"], [52, 3.0, "Linear"], [60, 3.0, None]]},
             "Why": "the hold's glow made a shape: warm light hugging the paper's belly, 3.2 by 3.8 studs swelling to "
                    "3.8 by 4.5 at the look (the drum is 3 by 3.45, so its rims stand out of it), then drawn in and "
                    "gone by 104 (condition a). Its edge keeps a gap to the hat at every heading (measured)"},
            {"Name": "Streak", "From": "Wrench", "Part": "Beam", "Texture": "lamplighter_column_tip",
             "BlockIn": "fx_beam, Color grey", "FaceCamera": True, "Width": STREAK["Width"], "LightEmission": 1,
             "LightInfluence": 0, "Color": [1, 1, 1], "TextureMode": "Stretch", "TextureLength": 1, "TextureSpeed": 0,
             "Segments": 10,
             "Attachment0": "the drum's middle, one drum radius (1.5) back along its motion: the streak starts at the "
                            "drum's trailing edge, never on it",
             "Attachment1": "where the drum's middle was Lag frames before, Beyond studs further back",
             "Beyond": STREAK["Beyond"],
             "Tracks": {"Lag": [[STREAK["From"], STREAK["Lag"], None]],
                        "Transparency": [[STREAK["From"], 0.15, "Linear"], [STREAK["Last"], 0.15, None],
                                         [STREAK["Last"] + 1, 1.0, None]]},
             "Why": "one straight streak behind the falling lantern, round at the drum and pointed at its tail, in the "
                    "column's light (condition b: straight, light colours). It's gone before 117, where the drum "
                    "itself passes the face from behind and left of your fighter (measured)"},
            {"Name": "Shaft", "From": "Slam", "Part": "Beam", "Texture": "lamplighter_column",
             "BlockIn": "fx_beam, Color grey", "On": "the ground under the drum's middle on the Slam",
             "FaceCamera": True, "TextureMode": "Wrap", "TextureLength": round(sa.PERIOD * S, 3),
             "TextureSpeed": sa.CLIMB, "LightEmission": sa.EMISSION, "LightInfluence": 0, "Color": [1, 1, 1],
             "Segments": 20, "FootFade": round(sa.FOOT * S, 2), "Taper": sa.TAPER,
             "Attachment0": "On, Foot up", "Attachment1": "On, Top up",
             "Tracks": {k: col[k] for k in ("Foot", "Top", "Width", "Transparency")},
             "Why": "section 7's column: lamplight widest at the foot (Width0 the track's Width, Width1 that times "
                    "Taper), the paper lantern's ribs climbing it (one rib a TextureLength; they must run up, toward "
                    "Attachment1: flip TextureSpeed's sign if they run down). Its Transparency fades its first "
                    "FootFade studs in, over the track's value. It leaps: its height in its first five frames (13.5 "
                    "studs by 123), then foot and top climb away together on an ease-in (30 studs by 139), its light "
                    "held until the climb is under way (to 132) and gone by 140"},
            {"Name": "Tip", "From": "Slam", "Part": "Beam", "Texture": "lamplighter_column_tip",
             "BlockIn": "fx_beam, Color grey", "FaceCamera": True, "TextureMode": "Stretch", "TextureLength": 1,
             "TextureSpeed": 0, "LightEmission": sa.EMISSION, "LightInfluence": 0, "Color": [1, 1, 1], "Segments": 10,
             "Attachment0": "the Shaft's Attachment1", "Attachment1": "Spike studs over it",
             "Width": "the Shaft's width at its top, Width0 and Width1: its Width times its Taper",
             "Tracks": {"Spike": col["Spike"]},
             "Why": "the needle over the shaft, footed on its top: the width there and the shaft's Transparency"},
            {"Name": "Halo", "From": "Slam", "Part": "Beam", "Texture": "lamplighter_column_halo",
             "BlockIn": "none", "FaceCamera": True, "TextureMode": "Stretch", "TextureLength": 1, "TextureSpeed": 0,
             "LightEmission": 1, "LightInfluence": 0, "Color": [1, 1, 1], "Segments": 10, "ZOffset": -0.5,
             "Taper": sa.TAPER,
             "Attachment0": "the Shaft's Attachment0", "Attachment1": "the Tip's Attachment1",
             "Tracks": {"Width": col["HaloWidth"]},
             "Why": f"the column's glow behind it, {sa.HALO} times its width, so the shaft reads crisp with a soft "
                    "edge; wider on the slam and the frame after (the flash), hugging the shaft as it tapers; the "
                    "shaft's Transparency"},
            {"Name": "Chips", "From": "Slam", "Kind": "MeshParts, no texture, Material Neon, Color by name, unlit "
             "by the scene; each its own Offset and Scale (uniform: the chip's unit size times it), turned by Turn "
             "(degrees: about Y, then its own X, then its own Z)",
             "On": "the Shaft's On", "Each": chip_rows(chips),
             "Why": "the secondary, a breath after the peak: angular bits of the light flung up and out off the "
                    "column's edge, cyan and warm by turns, shrinking as they rise; never falling, never on the floor"},
            {"Name": "SlamLight", "From": "Slam", "Part": "PointLight", "On": "the Shaft's On, 4 studs up",
             "Range": 20, "Shadows": False, "Color": mix(sa.CORE, sa.CYAN, 0.6),
             "Tracks": {"Brightness": [[0, 5.0, "Quart Out"], [3, 3.0, "Sine InOut"], [22, 0.0, None]]},
             "Why": "the street, your fighter and the keeper lit by the column, brightest on the slam"},
        ],
        "Faber": "the hitstop (rung 8), the shake, the struck lead's flash and the camera's lift through the hold stay "
                 "yours, on the same markers. Lantern Row's Config already drives the lantern's glow at 3.0 through "
                 "the signature: the Paper row replaces that for this clip",
    }


def keeper_layers(stage, f):
    """The rows on clip frame f, as the art's stage lays them (lamplighter_signature_art.art's layers)."""
    rows, out, p = stage.rows, [], stage.hit
    t = f - LIGHT
    shell = rows["Shell"]["Tracks"]
    scale, clear = value(shell["Scale"], t), value(shell["Transparency"], t)
    if scale is not None and clear < 0.99 and f < len(stage.turns):
        w, h = scale[0] * SHELL_UNIT / S, scale[1] * SHELL_UNIT / S
        out.append({"kind": "solid", "layer": "shell", "boxes": [(stage.lamp[f], (w, w, h), stage.turns[f])],
                    "colour": sa.WARM, "opaque": 1 - clear, "emission": 1.0})
    streak, t = rows["Streak"], f - WRENCH
    lag, clear = value(streak["Tracks"]["Lag"], t), value(streak["Tracks"]["Transparency"], t)
    lag = getattr(stage, "lag", None) or lag
    last = getattr(stage, "last", None)
    if lag and clear is not None and (clear < 0.99 if last is None else t <= last) and f < SLAM:
        head = stage.lamp[f]
        way = (head - stage.lamp[f - 1]).normalized()
        tail = stage.lamp[f - int(round(lag))]
        a0, a1 = head - way * lc.LAMP_R, tail + (tail - head).normalized() * (streak["Beyond"] / S)
        out.append({"kind": "beam", "layer": "trail", "a0": a0, "a1": a1, "width": streak["Width"] / S, "pic": "tip",
                    "wrap": False, "opaque": 0.85, "emission": 1.0})
    t, col = f - SLAM, rows["Shaft"]["Tracks"]
    clear = value(col["Transparency"], t)
    if clear is not None and clear < 0.99:
        foot, top, width = (value(col[k], t) / S for k in ("Foot", "Top", "Width"))
        spike = value(rows["Tip"]["Tracks"]["Spike"], t) / S
        a, b = Vector((p.x, p.y, foot)), Vector((p.x, p.y, top))
        c = b + Vector((0.0, 0.0, spike))
        halo, taper = value(rows["Halo"]["Tracks"]["Width"], t) / S, rows["Shaft"]["Taper"]
        out.append({"kind": "beam", "layer": "halo", "a0": a, "a1": c, "width": halo,
                    "width1": halo * rows["Halo"]["Taper"], "pic": "halo", "wrap": False, "opaque": 1 - clear,
                    "emission": 1.0})
        out.append({"kind": "beam", "layer": "shaft", "a0": a, "a1": b, "width": width, "width1": width * taper,
                    "pic": "column", "wrap": True, "scroll": sa.CLIMB * t / 60, "fade": sa.FOOT, "opaque": 1 - clear,
                    "emission": sa.EMISSION})
        out.append({"kind": "beam", "layer": "tip", "a0": b, "a1": c, "width": width * taper, "pic": "tip",
                    "wrap": False, "opaque": 1 - clear, "emission": sa.EMISSION})  # footed on the shaft's top
    for name, colour in (("cyan", sa.CYAN), ("warm", sa.WARM)):
        boxes = []
        for chip in rows["Chips"]["Each"]:
            if chip["Color"] != name:
                continue
            at, k = value(chip["Tracks"]["Offset"], t), value(chip["Tracks"]["Scale"], t)
            if at is None or k < 0.02:
                continue
            h, pitch, roll = (math.radians(v) for v in chip["Turn"])
            turn = Quaternion((0, 0, 1), h) @ Quaternion((1, 0, 0), pitch) @ Quaternion((0, 1, 0), -roll)
            size = (k * CHIP_UNIT[0] / S, k * CHIP_UNIT[2] / S, k * CHIP_UNIT[1] / S)  # Blender x, y, z
            boxes.append((Vector((p.x + at[0] / S, p.y - at[2] / S, at[1] / S)), size, turn))
        if boxes:
            out.append({"kind": "solid", "layer": f"chip{colour}", "boxes": boxes, "colour": colour, "opaque": 1.0,
                        "emission": 0.4})
    return out


class KeeperStage(sa.Stage):
    """The art's stage, laying the rows; the shell is a ball, the lantern's turn read on every frame."""

    def __init__(self, scene, lantern, frames):
        super().__init__(scene, lantern, frames)
        self.rows = {row["Name"]: row for row in keeper(self.chips)["Rows"]}
        self.show, rest, self.turns = False, None, []
        for f in range(frames):
            scene.frame_set(f)
            r6._refresh()
            q = lantern.matrix_world.to_quaternion()
            rest = q.copy() if rest is None else rest
            self.turns.append(q @ rest.inverted())
        self.show = True

    def box(self, layer, n):
        if layer != "shell":
            return super().box(layer, n)
        pool = self.boxes.setdefault(layer, [])
        while len(pool) <= n:
            bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=0.5)
            obj = bpy.context.active_object
            obj.name = "Art.shell"
            obj.data.materials.append(self.code)
            obj.display.show_shadows, obj.rotation_mode, obj.hide_render = False, "QUATERNION", True
            pool.append(obj)
        return pool[n]


def gap(m, hat):
    """Clear pixels between masks m and hat, 0 where they touch, minus the pixels they share; None if either is empty."""
    if not m.any() or not hat.any():
        return None
    if (m & hat).any():
        return -float((m & hat).sum())
    pa, pb = np.argwhere(sa.edge(m)), np.argwhere(sa.edge(hat))
    return round(float(np.sqrt(((pa[:, None, :] - pb[None, :, :]) ** 2).sum(-1)).min()) - 1, 1)


def layer_gap(scene, stage, camera, f, size, tmp, pics, layer, drum, hat):
    """At `size` from `camera` on frame f: the gap between the head and hat (the drum hidden) and what's seen of
    `layer` (a Beam where its picture shows, over 0.03), and between the head and hat and the drum."""
    stage.mode, scene.camera = "art", camera
    scene.render.resolution_x, scene.render.resolution_y = size
    stage.show = False
    scene.frame_set(f)

    def hidden(objs):
        kept = [o.hide_render for o in objs]
        for o in objs:
            o.hide_render = True
        picture = sa.render(scene, tmp, flat=True)[..., :3]
        for o, k in zip(objs, kept):
            o.hide_render = k
        return picture

    every, no_drum = sa.render(scene, tmp, flat=True)[..., :3], hidden(drum)
    drum_m = np.abs(no_drum - every).max(-1) > 0.01
    hat_m = np.abs(hidden(drum + hat) - no_drum).max(-1) > 0.01
    stage.show = True
    scene.frame_set(f)
    item = next((i for i in stage.items if i["layer"] == layer), None)
    if item is None:
        return None, gap(drum_m, hat_m)
    stage.reveal(layer)
    seen = np.abs(sa.render(scene, tmp, flat=True)[..., :3] - every).max(-1) > 0.01
    stage.reveal(None)
    if item["kind"] == "beam" and seen.any():
        eye, rays = sa.camera_rays(scene, camera, *size)
        px = np.nonzero(seen)
        rgb, a = sa.lay(item, pics, eye, rays, px)
        seen = np.zeros_like(seen)
        seen[px] = a * rgb.max(-1) > 0.03
    return gap(seen, hat_m), gap(drum_m, hat_m)


SHEET_K = (LIGHT, 60, 84, LOOK, 100, 102, 104, WRENCH, 110, 112, 114, 116, 117, SLAM, 119, 121, 124, 127, 130, 136)
CROSSING = tuple(range(112, 120))
# the content check's ask: the headings behind the keeper where the measured gap closes, through the hold and on the
# streak's last frames
BACK_HOLD = ((-165, -150, -135, -120), (48, 80, 84, 88, 92, 96, 100))
BACK_STREAK = ((-180, -165, -150), (114, 115, 116))


def patch(scene, camera, stage, f, size, tile, hat, scale=2, box=(100, 80)):
    """`sa.close_up`'s crop of a tile already shot: the 64 px pixels round the hat and the lantern, enlarged, unfiltered."""
    middle = (sum((o.matrix_world.translation for o in hat), Vector()) / len(hat) + stage.lamp[f]) / 2
    at = sa.world_to_camera_view(scene, camera, middle)
    w, h = size
    cx = int(np.clip(at.x * w - box[0] / 2, 0, w - box[0]))
    cy = int(np.clip((1 - at.y) * h - box[1] / 2, 0, h - box[1]))
    return sa.edged(np.repeat(np.repeat(tile[cy:cy + box[1], cx:cx + box[0]], scale, axis=0), scale, axis=1))


def back_rows(scene, stage, sweep, headings, frames, tmp, pics, hat, bare):
    """For each heading: a row at 64 px round the hat with the rows drawn, and with `bare` a row of the same frames
    without them (the drum and the keeper alone)."""
    rows = []
    for az in headings:
        cam = sweep[az]
        size = sig.keeper_64(scene, cam)
        drawn = []
        for f in frames:
            drawn.append(patch(scene, cam, stage, f, size, sa.shoot(scene, stage, cam, f, size, tmp, pics)[0], hat))
        rows.append(sa.sheet(drawn, len(frames)))
        if bare:
            alone = []
            for f in frames:
                stage.show = False
                scene.camera = cam
                scene.render.resolution_x, scene.render.resolution_y = size
                scene.frame_set(f)
                tile = sa.render(scene, tmp)[..., :3]
                stage.show = True
                alone.append(patch(scene, cam, stage, f, size, tile, hat))
            rows.append(sa.sheet(alone, len(frames)))
    return sa.stack(rows)


def main_back(scene, stage, sweep, floor_m, dusk, bright, tmp, pics, hat, out):
    """The content check's sheet: behind the keeper at 64 px, on the dark floor and the bright one, with a labelled
    overview to read the 64 px rows by."""
    r = scene.render
    for name, (headings, frames) in (("hold", BACK_HOLD), ("streak", BACK_STREAK)):
        for colour, floor in ((dusk, "dark"), (bright, "bright")):
            floor_m.diffuse_color = colour
            path = out / f"sig_rows_back64_{name}_{floor}.png"
            sa.rs.save(back_rows(scene, stage, sweep, headings, frames, tmp, pics, hat, colour == dusk), path)
            print(f"wrote {path}")
        floor_m.diffuse_color = dusk
        r.stamp_font_size = 14
        tiles = [sa.edged(sa.shoot(scene, stage, sweep[az], f, (256, 144), tmp, pics, label=f"{az} {f}")[0])
                 for az in headings for f in frames]
        path = out / f"sig_rows_back_{name}.png"
        sa.rs.save(sa.sheet(tiles, len(frames)), path)
        print(f"wrote {path}")
    tmp.unlink(missing_ok=True)


def main_signature(out, back=False):
    tmp = out / "_tile.png"
    pics = {"column": sa.column_picture(), "tip": sa.tip_picture(), "halo": sa.halo_picture()}
    for name, pic in pics.items():
        sa.rs.save(pic, out / f"lamplighter_{sa.FILES[name]}.png")
    sa.art = keeper_layers  # the art's stage lays the rows
    scene, rig, costume, *_ = lc.build(out)
    frames = sig.key(rig)
    stage = KeeperStage(scene, costume[lc.LAMP], frames)
    rows = keeper(stage.chips)
    (out / "lamplighter_signature_rows.json").write_text(json.dumps(rows, indent=1) + "\n", encoding="utf-8")
    print(f"wrote {out / 'lamplighter_signature_rows.json'}; it lands at {tuple(round(v * S, 2) for v in stage.hit.xy)} "
          f"studs from the keeper")
    scene.render.dither_intensity = 0.0
    r = scene.render
    r.use_stamp_date = r.use_stamp_render_time = r.use_stamp_camera = r.use_stamp_lens = False
    r.use_stamp_scene = r.use_stamp_filename = r.use_stamp_frame = r.use_stamp_time = False
    r.use_stamp_note = True
    game = sig.game_camera(scene, "game")
    cams = {"game": game, "ring": lc.cameras(scene, rig)["ring"],
            "flank": lc.stage_camera(scene, -90.0, 4.0, 30.0, (0.0, 2.0, 6.0), fov=40.0, name="flank")}
    bpy.context.view_layer.update()
    g = game.matrix_world.translation.copy()
    reach, pitch = math.hypot(g.x, g.y), math.degrees(math.atan2(g.z - 4.5, math.hypot(g.x, g.y)))
    sweep = {az: lc.stage_camera(scene, az, pitch, reach, (0.0, 0.0, 4.5), fov=70.0, name=f"sweep {az}")
             for az in range(-180, 180, 15)}
    bpy.context.view_layer.update()
    floor = bpy.data.objects["Floor"]
    floor.scale *= 4
    floor_m = floor.data.materials[0]
    dusk, bright = tuple(floor_m.diffuse_color), (0.74, 0.72, 0.68, 1)
    drum, hat = [costume[lc.LAMP]], [costume[f"{lc.NAME}_Head"]]
    lead = [o for o in scene.objects if o.name.startswith("Fx.Lead")]
    body = [o for o in costume.values() if not o.hide_render]
    if back:
        main_back(scene, stage, sweep, floor_m, dusk, bright, tmp, pics, hat, out)
        return

    # the game's camera, the whole signature
    r.stamp_font_size = 22
    tiles = [sa.edged(sa.shoot(scene, stage, game, f, (480, 270), tmp, pics, label=sig.label(f))[0]) for f in SHEET_K]
    sa.rs.save(sa.sheet(tiles, 5), out / "sig_rows_game.png")
    print(f"wrote {out / 'sig_rows_game.png'}")

    # condition d: 112 to 119 from straight behind your fighter and from its left, at 64 px and larger, dark and bright
    r.stamp_font_size = 14
    rows64, rows_big = [], []
    for colour in (dusk, bright):
        floor_m.diffuse_color = colour
        for az in (-30, 0):
            cam = sweep[az]
            size = sig.keeper_64(scene, cam)
            rows64.append(sa.sheet([sa.edged(sa.shoot(scene, stage, cam, f, size, tmp, pics)[0]) for f in CROSSING],
                                   len(CROSSING)))
            rows_big.append(sa.sheet([sa.edged(sa.shoot(scene, stage, cam, f, (256, 144), tmp, pics,
                                                        label=f"{az} {f}" + (" bright" if colour == bright else ""))[0])
                                      for f in CROSSING], len(CROSSING)))
    floor_m.diffuse_color = dusk
    sa.rs.save(sa.stack(rows64), out / "sig_rows_d64.png")
    sa.rs.save(sa.stack(rows_big), out / "sig_rows_d.png")
    print(f"wrote {out / 'sig_rows_d64.png'}, {out / 'sig_rows_d.png'}")

    # the hold at 64 px, close round the hat, from the game's camera, the ring's and the flank's
    held = (LIGHT, 60, 84, LOOK, 100, 102, 104, WRENCH, 110, 114, 116)
    sa.rs.save(sa.stack([sa.sheet([sa.edged(sa.close_up(scene, stage, cams[n], f, sig.keeper_64(scene, cams[n]), tmp,
                                                        pics, hat)) for f in held], len(held))
                         for n in ("game", "ring", "flank")]), out / "sig_rows_hold64.png")
    print(f"wrote {out / 'sig_rows_hold64.png'}")

    # condition 6 through the hold: the shell's gap to the head and hat at 64 px, every 4 frames, from every heading
    measures = {"shell_gap": {}, "streak_gap": {}}
    for name, cam in list(cams.items()) + [(f"sweep {az}", c) for az, c in sweep.items()]:
        size = sig.keeper_64(scene, cam)
        row = {f: layer_gap(scene, stage, cam, f, size, tmp, pics, "shell", drum, hat) for f in range(LIGHT, 105, 4)}
        seen = [(v[0], f) for f, v in row.items() if v[0] is not None]
        measures["shell_gap"][name] = {"least": min(seen) if seen else None,
                                       "frames": {f: v[0] for f, v in row.items()}}
        print(f"shell {name}: least {measures['shell_gap'][name]['least']}; "
              + " ".join(f"{f}:{v[0]}/{v[1]}" for f, v in row.items()))

    # condition b: the streak's gap to the head and hat at 64 px on its last frames, from every heading, by its lag
    for lag in (5, 3, 2):
        stage.lag = lag
        for f in (114, 115, 116, 117):
            stage.last = f - WRENCH
            row = {az: layer_gap(scene, stage, cam, f, sig.keeper_64(scene, cam), tmp, pics, "trail", drum, hat)
                   for az, cam in sweep.items()}
            seen = [(v[0], az) for az, v in row.items() if v[0] is not None]
            measures["streak_gap"][f"lag {lag}, {f}"] = {"least": min(seen) if seen else None,
                                                         "headings": {az: v[0] for az, v in row.items()}}
            print(f"streak lag {lag} on {f}: least {min(seen) if seen else None}; "
                  + " ".join(f"{az}:{v[0]}/{v[1]}" for az, v in row.items()))
    stage.lag = stage.last = None

    # condition c: the column at the new landing, section 7's numbers again
    share, covered = {}, {}
    for f in sig.SHARE:
        drawn, bare = sa.shoot(scene, stage, game, f, (480, 270), tmp, pics)
        changed = np.abs(drawn - bare).max(-1)
        share[f] = round(float((changed > 0.03).mean()), 4)
        if SLAM <= f <= SLAM + 4:
            seen = sa.masks(scene, stage, game, f, (480, 270), tmp, lead, body)
            covered[f] = {k: round(float((changed[m] > 0.15).mean()), 3) for k, m in seen.items()}
    measures.update(share=share, covered_over_015=covered, apex_over_frame_top_degrees=sa.apex_over_top(stage, game),
                    landing_studs=[round(v * S, 2) for v in stage.hit.xy],
                    tile_at_64={n: list(sig.keeper_64(scene, c)) for n, c in cams.items()})
    print(json.dumps({k: measures[k] for k in ("share", "covered_over_015", "apex_over_frame_top_degrees")}))
    (out / "sig_rows.json").write_text(json.dumps(measures, indent=1) + "\n", encoding="utf-8")
    tmp.unlink(missing_ok=True)


# --- B5: Rook's square, a framed plate standing up (AR8's order 4; Config.Effects.Haymaker.Stamp) --------------------

STAMP = {"Side": 4.6, "Bar": 0.85, "Rise": 21, "Over": 5.6, "Clear": 1, "Top": 6.4, "Forms": 0.65, "FormBar": 0.3,
         "Drop": 4, "Stretch": 0.35, "Narrow": 0.15, "Squash": (0.55, 0.3, 0.26, 0.24), "Spread": 1.3, "Spreads": 1.55,
         "SpreadGain": 0.05, "Eat": 3, "Eaten": 12, "Run": {"Reach": 4.5, "Frames": 8, "Life": 9, "Width": 0.5},
         "Tighten": "Quad Out"}  # Config.Effects.Haymaker.Stamp as it stands; stampAt's hang eases 1 - (1 - u)^2
DRAWN = STAMP | {"Forms": 1.2, "Tighten": "Quad In"}  # fix 1, offered: formed loose and drawn tight, as the ram is
DEPTH, RAILS, PANE = 0.5, 0.9, 0.06  # studs: a stroke's depth; the rails' share of it; the plate's
PLATE = [[-21, 0.85, "Quad In"], [-6, 0.35, "Linear"], [-1, 0.35, "Linear"], [0, 0.15, "Linear"], [3, 1.0, None]]
GLOW = [[-21, 1.0, "Linear"], [-1, 1.0, "Linear"], [0, 2.0, "Quad Out"], [2, 1.0, None]]
TARGET_TOP = 5.8   # the stand-in Shade's top (its mask's), what stampAt measures off a body's box
B5_SHEET = (36, 40, 44, 48, 51, 52, 53, 54, 55, 56, 57, 58, 59, 61, 64, 70)
B5_HANG = (36, 40, 44, 47, 49, 51, 53)
B5_64 = (40, 48, 52, 54, 55, 56, 57, 58, 60, 64)
B5_CLOSE = (40, 48, 51, 55, 56, 57, 58, 61)

B5 = {
    "Effect": "Haymaker's stamp in its art (AR8, B5): the ram's square as a framed plate standing up",
    "Clip": "RookHaymaker", "From": "Strike", "Marker": st.STRIKE, "Fps": 60,
    "Kit": "build/handoff/FxKit/fx_kit.json: FxBar and FxPlate, each 1 x 1 x 1 studs, so a Size is in studs",
    "On": "stampAt's square (Effects.luau): its facing, and w, h, z, bar and gone each frame, as they are",
    "Replaces": "the stamp's four grey Parts and the floor's two; the charge on the ram and the punctuation stay",
    "Rows": [
        {"Name": "Posts", "Part": "FxBar", "Count": 2, "Texture": "fx_across_Ember", "BlockIn": "fx_across_Grey",
         "Place": "facing * CFrame.new(sign * w / 2, z + h / 2, 0) * CFrame.Angles(0, 0, math.pi / 2): FxBar lies "
                  "along X, so a post is turned upright",
         "Size": "Vector3.new(h + bar, bar, Depth)", "Tracks": {"Transparency": "gone, as now", "Glow": GLOW},
         "Why": "the posts run the full height, so the square's outer corners are theirs"},
        {"Name": "Rails", "Part": "FxBar", "Count": 2, "Texture": "fx_across_Ember", "BlockIn": "fx_across_Grey",
         "Place": "facing * CFrame.new(0, z + h * (index - 1), 0)",
         "Size": "Vector3.new(w, bar, Depth * Rails)", "Tracks": {"Transparency": "gone, as now", "Glow": GLOW},
         "Why": "between the posts, their ends inside them; a little shallower, so no rail's face lies in a post's"},
        {"Name": "Plate", "Part": "FxPlate", "Texture": "fx_rise_Ember", "BlockIn": "fx_rise_Grey",
         "Place": "facing * CFrame.new(0, z + h / 2, 0)",
         "Size": "Vector3.new(w - bar, h - bar, Pane); hidden while either side is under 0.02",
         "Tracks": {"Transparency": PLATE, "Glow": GLOW},
         "Why": "the bright interior, at its brightest where it leads down; it charges through the hang, flashes on "
                "Strike and is gone by the third frame after, before the stamp lies flat: no light left on the floor"},
        {"Name": "Runs", "Part": "FxBar", "Count": 2, "Texture": "fx_across_Ember", "BlockIn": "fx_across_Grey",
         "Place": "where the floor's bars run now, turned face up: * CFrame.Angles(math.pi / 2, 0, 0)",
         "Size": "Vector3.new(reach - w / 2 + 0.01, Run.Width * (1 - run) + 0.05, 0.16)",
         "Why": "hard strokes along the floor, never a pool (the content check, section 9's condition 2)"},
    ],
    "Config": {"Forms": DRAWN["Forms"], "Tighten": DRAWN["Tighten"], "Depth": DEPTH, "Rails": RAILS, "Pane": PANE,
               "Why": "fix 1, offered: Forms over 1 and an ease in, so the square forms loose, 1.2 of its side with "
                      "thin bars, and is drawn tight with the ram, slowly, then fast into the beat too long (the ram "
                      "creeps back twice as fast from 44); its top edge stays where it was (12.5 studs up at the "
                      "start, 12.6 at the end, over the preview's Shade), so the phone's framing holds"},
    "Glow": "the emissive strength through the glow mask, on the frames from Strike; the take checks the rim stays "
            "darker than the core on a bright sky, and at 2 on Strike blooms no halo",
    "Never": "a light at the landing (a PointLight on the floor is a pool); the plate left lying on the floor",
}


def stamp_square(s, f):
    """stampAt at f frames from Strike, with the numbers `s`: w, h, z, bar, gone and the floor's run; None before."""
    if f < -s["Rise"]:
        return None
    over = max(s["Over"], TARGET_TOP + s["Clear"])
    top = over + (s["Top"] - s["Over"])
    run, gone = None, 0.0
    if f < -s["Drop"]:
        e = ease(s["Tighten"], (f + s["Rise"]) / max(1, s["Rise"] - s["Drop"] - 2))
        w = h = s["Side"] * (s["Forms"] + (1 - s["Forms"]) * e)
        z, bar = over + (top - over) * e, s["FormBar"] + (s["Bar"] - s["FormBar"]) * e
    elif f < 0:
        fast = min(1.0, max(0.0, (f + s["Drop"]) / max(1, s["Drop"] - 1)))
        u = min(1.0, max(0.0, (f + s["Drop"]) / s["Drop"]))
        w, h = s["Side"] * (1 - s["Narrow"] * fast), s["Side"] * (1 + s["Stretch"] * fast)
        z, bar = 0.04 + (top - 0.04) * (1 - u * u), s["Bar"]
    else:
        k = math.floor(f)
        h = s["Side"] * s["Squash"][min(k, len(s["Squash"]) - 1)]
        w = s["Side"] * (s["Spread"] if k == 0 else s["Spreads"] + s["SpreadGain"] * min(1.0, max(0.0, (f - 1) / 10)))
        z = 0.04
        gone = min(1.0, max(0.0, (f - s["Eat"]) / s["Eaten"]))
        bar = s["Bar"] * (1 - gone) + 0.02
        if f <= s["Run"]["Life"]:
            run = hx.out_fast(f / s["Run"]["Frames"])
    return {"w": w, "h": h, "z": z, "bar": bar, "gone": gone, "run": run}


def kit_mesh(name, bm):
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    return mesh


def kit_image(name, pixels):
    image = bpy.data.images.new(name, pixels.shape[1], pixels.shape[0], alpha=True)
    image.pixels.foreach_set(np.ascontiguousarray(pixels, dtype=np.float32).ravel())
    return image


class SquareStage(st.Stage):
    """rook_haymaker_stamp.py's stage, the target pinned, the stamp in the kit's parts by layer ("solid": the charge,
    the punctuation and the runs; "frame": the four strokes; "plate"), or the grey Parts as the game draws them now
    (`look` "grey"). `numbers`: STAMP or DRAWN."""

    def __init__(self, scene, rig, knuckles):
        super().__init__(scene, rig, knuckles)
        self.look, self.numbers, self.only = "art", DRAWN, None
        self.images = {f"fx_{k}_{p}": kit_image(f"fx_{k}_{p}", getattr(kit, k)(p)) for k in ("across", "rise") for p in ("Ember", "Grey")}
        self.bar_mesh, self.pane_mesh = kit_mesh("FxBar", kit.bar()), kit_mesh("FxPlate", kit.plate())
        self.parts = {"charge": [self.kit_part(self.bar_mesh) for _ in range(4)],
                      "solid": [self.kit_part(self.bar_mesh) for _ in range(6)],
                      "frame": [self.kit_part(self.bar_mesh) for _ in range(4)], "plate": [self.kit_part(self.pane_mesh)]}
        kit.textured(self.parts["solid"][0], self.images["fx_across_Ember"])
        kit.textured(self.parts["plate"][0], self.images["fx_rise_Ember"])
        for obj in self.parts["charge"]:  # the charge rides the ram's face
            obj.parent = rig.parts["Right Arm"]
        self.grey = [self.box("white") for _ in range(4)]
        self.alpha, self.used = {}, {}

    @staticmethod
    def kit_part(mesh):
        obj = bpy.data.objects.new(f"Fx.{mesh.name}", mesh)
        bpy.context.scene.collection.objects.link(obj)
        obj.display.show_shadows, obj.hide_render = False, True
        return obj

    def put(self, layer, centre, turn, scale):
        obj = self.parts[layer][self.used[layer]]
        self.used[layer] += 1
        obj.location, obj.rotation_euler, obj.scale = centre, tuple(math.radians(a) for a in turn), scale

    def set(self, scene, *_):
        f = scene.frame_current
        self.place_avatar(scene)
        if scene.camera:
            eye = scene.camera.matrix_world.translation
            self.facing = (Vector((eye.x, eye.y)) - Vector(st.TARGET)).normalized()
        self.target.location = (st.TARGET[0], st.TARGET[1], 0.0)  # pinned: the strike pushes nothing (tier 2, signed)
        self.used = {layer: 0 for layer in self.parts}
        self.alpha = {"charge": 0.0, "solid": 0.0, "frame": 0.0, "plate": 1.0}
        grey_used = 0
        # the charge, drawn tight on the ram's face through the hold and cut at the strike, as st draws it
        if st.WIND - 6 <= f < st.STRIKE:
            side = 2.9 - 1.1 * st.clamp((f - st.WIND + 6) / (st.HELD - st.WIND + 6)) ** 2 - 0.1 * st.clamp((f - st.HELD) / 4)
            for i in range(4):
                across, sign = i < 2, 1 if i % 2 else -1
                at = Vector(hx.KNUCKLES) + (Vector((0, sign * side / 2, 0)) if across else Vector((sign * side / 2, 0, 0)))
                self.put("charge", at, (90, 0, 0) if across else (90, 0, 90), (side + 0.2, 0.2, 0.2))
        # the punctuation, thrown open across the line at the ram on Strike and Shock
        if f in (st.STRIKE, st.SHOCK):
            side, width = (3.0, 0.8) if f == st.STRIKE else (3.7, 0.7)
            x, y, z = self.knuckles
            for sign in (-1, 1):
                self.put("solid", (x, y + 0.3, z + sign * side / 2), (0, 0, 0), (side + width, 0.1, width))
                self.put("solid", (x + sign * side / 2, y + 0.3, z), (0, 90, 0), (side + width, 0.1, width))
        sq = stamp_square(self.numbers, f - st.STRIKE)
        if sq:
            fx, fy = self.facing
            across, yaw = Vector((fy, -fx, 0.0)), math.degrees(math.atan2(-fx, fy))
            foot = Vector((st.TARGET[0], st.TARGET[1], 0.0))
            up = Vector((0.0, 0.0, 1.0))
            w, h, z, bar = sq["w"], sq["h"], sq["z"], sq["bar"]
            if self.look == "grey":
                for sign in (-1, 1):
                    for obj, at, size in ((self.grey[grey_used], foot + across * sign * w / 2 + up * (z + h / 2), (bar, 0.1, h + bar)),
                                          (self.grey[grey_used + 1], foot + up * (z + h * (sign + 1) / 2), (w + bar, 0.1, bar))):
                        obj.location, obj.scale, obj.rotation_euler, obj.hide_render = at, size, (0, 0, math.radians(yaw)), sq["gone"] > 0.5
                    grey_used += 2
            elif sq["gone"] < 1:
                for sign in (-1, 1):
                    self.put("frame", foot + across * sign * w / 2 + up * (z + h / 2), (0, 90, yaw), (h + bar, DEPTH, bar))
                    self.put("frame", foot + up * (z + h * (sign + 1) / 2), (0, 0, yaw), (w, DEPTH * RAILS, bar))
                self.alpha["frame"] = sq["gone"]
                pane = value(PLATE, f - st.STRIKE)
                if pane is not None and pane < 1 and w - bar > 0.02 and h - bar > 0.02:
                    self.put("plate", foot + up * (z + h / 2), (0, 0, yaw), (w - bar, PANE, h - bar))
                    self.alpha["plate"] = pane
            if sq["run"] is not None and self.look != "grey":
                run, r = sq["run"], self.numbers["Run"]
                reach = w / 2 + r["Reach"] * run
                for sign in (-1, 1):
                    self.put("solid", foot + across * sign * (w / 2 + reach) / 2 + up * 0.08, (90, 0, yaw),
                             (reach - w / 2 + 0.01, 0.16, r["Width"] * (1 - run) + 0.05))
        for obj in self.grey[grey_used:]:
            obj.hide_render = True
        self.reveal(self.only)

    def reveal(self, layer):
        """Shows only `layer`'s parts in use ("base": none of them; None: all)."""
        self.only = layer
        for name, pool in self.parts.items():
            for n, obj in enumerate(pool):
                obj.hide_render = n >= self.used.get(name, 0) or layer not in (None, name)

    def layers(self):
        """The layers drawn this frame, front first, with their transparency."""
        return [(name, self.alpha[name]) for name in ("charge", "solid", "frame", "plate") if self.used.get(name) and self.alpha[name] < 1]


def b5_tile(scene, stage, camera, f, size, tmp, label=""):
    """One tile: the lit stage without the stamp, and the parts drawn unlit (as their glow mask shows them) over it at
    their transparency, front layers first. Returns the tile and the bare stage (row 0 the top)."""
    scene.camera = camera
    r, shading = scene.render, scene.display.shading
    r.resolution_x, r.resolution_y = size
    r.use_stamp, r.stamp_note_text = bool(label), label
    scene.frame_set(f)

    def shot(layer, flat):
        stage.reveal(layer)
        shading.light = "FLAT" if flat else "STUDIO"
        shading.show_shadows = shading.show_cavity = shading.show_object_outline = not flat
        r.filepath = str(tmp)
        bpy.ops.render.render(write_still=True)
        return sa.rs.load(tmp)

    base = shot("base", False)
    out, drawn = base.copy(), stage.layers()
    if drawn:
        bare = shot("base", True)
        taken = np.zeros(base.shape[:2], dtype=bool)
        for layer, t in drawn:
            pic = shot(layer, True)
            m = (np.abs(pic[..., :3] - bare[..., :3]).max(-1) > 0.02) & ~taken
            out[m, :3] = out[m, :3] * t + pic[m, :3] * (1 - t)
            taken |= m
    stage.reveal(None)
    shading.light = "STUDIO"
    shading.show_shadows = shading.show_cavity = shading.show_object_outline = True
    return out, base


def main_b5(out, clip=None, only=None):
    tmp = out / "_tile.png"
    if clip:
        st.CLIP = Path(clip).resolve()
    (out / "rook_haymaker_rows.json").write_text(json.dumps(B5, indent=1) + "\n", encoding="utf-8")
    print(f"wrote {out / 'rook_haymaker_rows.json'}; the clip {st.CLIP}")
    scene, rig, *_ = rc.build()
    st.key(rig)
    scene.frame_set(st.STRIKE)
    knuckles = tuple(rig.parts["Right Arm"].matrix_world @ Vector(hx.KNUCKLES))
    stage = SquareStage(scene, rig, knuckles)
    fight = st.game_camera(scene, "fight", 70.0)
    turned = {h: st.game_camera(scene, f"h{h}", 70.0) for h in st.HEADINGS}
    floor = bpy.data.objects["Floor"]
    floor.scale *= 4
    floor_m = floor.data.materials[0]
    shading = scene.display.shading
    dusk, night = tuple(floor_m.diffuse_color), tuple(shading.background_color)

    def weather(pale):
        floor_m.diffuse_color = (0.74, 0.72, 0.68, 1) if pale else dusk
        shading.background_color = (0.62, 0.74, 0.86) if pale else night

    r = scene.render
    r.dither_intensity = 0.0
    r.use_stamp_date = r.use_stamp_render_time = r.use_stamp_camera = r.use_stamp_lens = False
    r.use_stamp_scene = r.use_stamp_filename = r.use_stamp_frame = r.use_stamp_time = False
    r.use_stamp_note = True

    # 64 px at every heading round the target (section 9's condition 4): the game's whole view, its 70 degrees, 64 px
    # tall; a heading a row from 0, every 45 degrees
    if only in (None, "Small"):
        for pale in (True, False):
            weather(pale)
            rows = [sa.sheet([sa.edged(b5_tile(scene, stage, turned[h], f, (114, 64), tmp)[0]) for f in B5_64], len(B5_64))
                    for h in st.HEADINGS]
            sa.rs.save(sa.stack(rows).repeat(3, axis=0).repeat(3, axis=1), out / f"b5_art_64_{'pale' if pale else 'dusk'}.png")

    # close on the square from the game's side, the avatar out of the way: the art itself, pale sky and dusk
    if only in (None, "Close"):
        look, _ = st.staged("fight")
        close = hx.camera(scene, "close", math.degrees(math.atan2(-look.x, -look.y)), 8.0, 34.0,
                          (st.TARGET[0], st.TARGET[1], 6.5), 24.0)
        r.stamp_font_size = 16
        rows = []
        for pale in (True, False):
            weather(pale)
            rows.append(sa.sheet([sa.edged(b5_tile(scene, stage, close, f, (288, 324), tmp, label=f"{'pale' if pale else 'dusk'} {f}")[0])
                                  for f in B5_CLOSE], len(B5_CLOSE)))
        sa.rs.save(sa.stack(rows), out / "b5_art_close.png")
    if only:
        tmp.unlink(missing_ok=True)
        return

    # the game's camera, the whole stamp on the polished clip, on a pale sky and at dusk
    share = {}
    for pale in (True, False):
        weather(pale)
        r.stamp_font_size = 22
        tiles = []
        for f in B5_SHEET:
            tile, base = b5_tile(scene, stage, fight, f, (480, 270), tmp, label=("pale sky: " if pale and f == B5_SHEET[0] else "") + st.label(f))
            tiles.append(sa.edged(tile))
            if pale:
                share[f] = round(float((np.abs(tile[..., :3] - base[..., :3]).max(-1) > 0.03).mean()), 4)
        sa.rs.save(sa.sheet(tiles, 4), out / f"b5_art_{'pale' if pale else 'dusk'}.png")

    # the hang: the grey as it is, the art on today's numbers, the art drawn in (fix 1, offered)
    weather(True)
    r.stamp_font_size = 15
    rows = []
    for look, numbers, name in (("grey", STAMP, "grey now"), ("art", STAMP, "art, today's numbers"), ("art", DRAWN, "art, drawn in")):
        stage.look, stage.numbers = look, numbers
        rows.append(sa.sheet([sa.edged(b5_tile(scene, stage, fight, f, (320, 180), tmp, label=f"{name}: {f}" if f == B5_HANG[0] else f"{f}")[0])
                              for f in B5_HANG], len(B5_HANG)))
    stage.look, stage.numbers = "art", DRAWN
    sa.rs.save(sa.stack(rows), out / "b5_art_hang.png")

    top ={name: {f: round(sq["z"] + sq["h"] + sq["bar"] / 2, 2) for f in range(-21, -3, 3) if (sq := stamp_square(n, f))}
           for name, n in (("today", STAMP), ("drawn", DRAWN))}
    measures = {"share_pale": share, "top_edge_studs_by_frame_from_strike": top, "target_top": TARGET_TOP}
    print(json.dumps(measures))
    (out / "b5_art.json").write_text(json.dumps(measures, indent=1) + "\n", encoding="utf-8")
    tmp.unlink(missing_ok=True)


# --- B1's finish (research's fix 3): the coil on fire, as the engine draws it ------------------------------------------

FINISH = (68, 70, 72, 74, 75, 76, 77, 78, 79, 80, 82, 83)
FINISH_CLOSE = (70, 75, 78)
LIGHT_ON = {"pale": 0.6, "dusk": 0.2}  # the light on a kit mesh, as engine()'s `light`: noon's pad, Lantern Row's dusk


def blur(img, r):
    """Three box blurs of radius r down each axis: near enough a gaussian, for the bloom."""
    for axis in (0, 1):
        for _ in range(3):
            pad = [(0, 0)] * img.ndim
            pad[axis] = (r + 1, r)
            c = np.cumsum(np.pad(img, pad, mode="edge"), axis=axis)
            img = (np.take(c, range(2 * r + 1, c.shape[axis]), axis=axis) - np.take(c, range(0, c.shape[axis] - 2 * r - 1), axis=axis)) / (2 * r + 1)
    return img


class FireStage:
    """The coil round a stand-in Shade on the pad, its bands and fronts as kit meshes in the unit coil, under one empty
    that takes the rows' Scale and Spin. Drawn in three passes: the lit stage, the parts' textures flat, and each part's
    id; then each part's texels through fx_kit.engine at its Glow, over the stage at its Transparency, with a mild bloom
    (a model of the engine's: the take is the judge)."""

    def __init__(self):
        self.scene = scene = bl.reset_scene()
        scene.render.engine = "BLENDER_WORKBENCH"
        scene.view_settings.view_transform = "Standard"
        scene.display.render_aa = "OFF"
        scene.render.film_transparent = False
        shading = scene.display.shading
        shading.background_type = "VIEWPORT"
        floor = bpy.data.objects.new("Floor", bpy.data.meshes.new("Floor"))
        floor.data.from_pydata([(-60, -60, 0), (60, -60, 0), (60, 60, 0), (-60, 60, 0)], [], [(0, 1, 2, 3)])
        self.floor_m = bpy.data.materials.new("Floor")
        floor.data.materials.append(self.floor_m)
        target = bpy.data.objects.new("Target", bpy.data.meshes.new("Target"))
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1.0)
        bm.to_mesh(target.data)
        bm.free()
        target.scale, target.location = (2.0, 1.0, TARGET_TOP), (0.0, 0.0, TARGET_TOP / 2)
        target_m = bpy.data.materials.new("Target")
        target_m.diffuse_color = (0.16, 0.16, 0.2, 1)
        target.data.materials.append(target_m)
        for obj in (floor, target):
            scene.collection.objects.link(obj)
        self.root = bpy.data.objects.new("Coil", None)
        scene.collection.objects.link(self.root)
        self.images = {n: kit_image(n, f(p)) for n, f, p in (("fx_across_Flame", kit.across, "Flame"), (FIRE_LOOK, kit.fire, "Flame"),
                                                             ("fx_rise_Flame", kit.rise, "Flame"))}
        self.parts = {}
        for k in range(1, BANDS + 1):
            self.parts[f"{COIL}_Burn{k}"] = self.part(f"{COIL}_Burn{k}", kit.coil(2, 1.0, (k - 1) / BANDS, k / BANDS))
        for b in range(1, BANDS):
            self.parts[f"{COIL}_Front{b}"] = self.part(f"{COIL}_Front{b}", kit.front(2, 1.0, b / BANDS, 40 + b))
            kit.textured(self.parts[f"{COIL}_Front{b}"], self.images["fx_rise_Flame"])
        self.ids = {name: i + 1 for i, name in enumerate(self.parts)}
        for name, obj in self.parts.items():
            obj.color = (self.ids[name] / 16, 0.0, 0.0, 1.0)
        data = bpy.data.cameras.new("Camera")
        data.sensor_fit, data.angle = "VERTICAL", math.radians(40)
        self.camera = bpy.data.objects.new("Camera", data)
        scene.collection.objects.link(self.camera)
        scene.camera = self.camera
        az, el, dist, aim = math.radians(25), math.radians(12), 27.0, Vector((0.0, 0.0, 5.6))
        way = Vector((math.sin(az) * math.cos(el), -math.cos(az) * math.cos(el), math.sin(el)))
        self.camera.location = aim + way * dist
        self.camera.rotation_euler = (-way).to_track_quat("-Z", "Y").to_euler()

    def part(self, name, bm):
        obj = bpy.data.objects.new(name, kit_mesh(name, bm))
        self.scene.collection.objects.link(obj)
        obj.parent = self.root
        obj.display.show_shadows = False
        kit.textured(obj, self.images[FIRE_LOOK])
        return obj

    def weather(self, pale):
        self.floor_m.diffuse_color = (0.74, 0.72, 0.68, 1) if pale else (0.12, 0.11, 0.15, 1)
        self.scene.display.shading.background_color = (0.62, 0.74, 0.86) if pale else (0.05, 0.05, 0.1)

    def tile(self, f, look, pale, size, label=""):
        """The tile at clip frame f: look "before" (fx_across_Flame, no front) or "after" (fx_fire_Flame and the fronts)."""
        t = f - pf.BURST
        rows = {row["Name"]: row for row in B1["Rows"]}
        coil, front = rows["Coil"], rows["Front"]
        scale, spin = value(COIL_SCALE, t), value(coil["Tracks"]["Spin"], t) or 0.0
        self.root.scale = (scale[0], scale[2], scale[1])
        self.root.rotation_euler = (0.0, 0.0, math.radians(spin))
        state = {}
        for name, obj in self.parts.items():
            tracks = (coil if "Burn" in name else front)["Bands"][name]
            clear = value(tracks["Transparency"], t)
            clear = 1.0 if clear is None else clear
            if look == "before" and "Front" in name:
                clear = 1.0
            state[name] = (value(tracks["Glow"], t) or 1.0, clear)
            if "Burn" in name:
                kit.textured(obj, self.images["fx_across_Flame" if look == "before" else FIRE_LOOK])
        self.weather(pale)
        scene, shading, r = self.scene, self.scene.display.shading, self.scene.render
        r.resolution_x, r.resolution_y = size[0] * 2, size[1] * 2
        out = {}
        for pass_, light, colour, shown in (("base", "STUDIO", "MATERIAL", False), ("tex", "FLAT", "TEXTURE", True),
                                            ("id", "FLAT", "OBJECT", True)):
            for name, obj in self.parts.items():
                obj.hide_render = not shown or state[name][1] >= 0.999
            shading.light, shading.color_type = light, colour
            if pass_ == "id":  # the sky and the stage read as no part (white is past every id)
                shading.background_color = (1.0, 1.0, 1.0)
            shading.show_shadows = shading.show_cavity = pass_ == "base"
            r.use_stamp = pass_ == "base" and bool(label)
            r.stamp_note_text = label
            r.filepath = str(self.tmp)
            bpy.ops.render.render(write_still=True)
            out[pass_] = sa.rs.load(self.tmp)
        base, tex, ids = out["base"], out["tex"][..., :3], out["id"][..., 0]
        keys = kit.to_srgb(np.arange(16, dtype=np.float32) / 16)
        which = np.abs(ids[..., None] - keys[None, None, :]).argmin(-1)
        glow, clear = np.zeros(which.shape, np.float32), np.ones(which.shape, np.float32)
        for name, i in self.ids.items():
            m = which == i
            glow[m], clear[m] = state[name]
        lin = kit.to_linear(tex)
        x = lin * lin * glow[..., None] + LIGHT_ON["pale" if pale else "dusk"] * lin
        shown = (1 - clear)[..., None]
        pic = base[..., :3] * (1 - shown) + kit.to_srgb(kit.aces(x)) * shown
        over = np.maximum(x - 1.0, 0.0) * shown
        pic = np.clip(pic + 0.18 * blur(over, max(2, size[1] // 60)), 0, 1)
        h, w = size[1], size[0]
        small = pic.reshape(h, 2, w, 2, 3).mean(axis=(1, 3))
        return np.concatenate([small, np.ones((h, w, 1), np.float32)], axis=-1)


def main_b1_finish(out):
    """B1's finish: the sheet (before and after on the pad at noon, after at dusk, from the game's side), the close one
    (70, 75, 78 large), and the 64 px rows; texels through the engine's model. The rows json with them."""
    (out / "pip_burst_rows.json").write_text(json.dumps(B1, indent=1) + "\n", encoding="utf-8")
    print(f"wrote {out / 'pip_burst_rows.json'}")
    stage = FireStage()
    stage.tmp = out / "_tile.png"
    r = stage.scene.render
    r.use_stamp_date = r.use_stamp_render_time = r.use_stamp_camera = r.use_stamp_lens = False
    r.use_stamp_scene = r.use_stamp_filename = r.use_stamp_frame = r.use_stamp_time = False
    r.use_stamp_note = True
    r.stamp_font_size = 22
    rows, small = [], []
    for look, pale in (("before", True), ("after", True), ("after", False)):
        tiles = [stage.tile(f, look, pale, (240, 320), f"{look}, {'noon' if pale else 'dusk'}: {f}" if f == FINISH[0] else f"{f}")
                 for f in FINISH]
        rows.append(sa.sheet([sa.edged(t) for t in tiles], len(tiles)))
        if look == "after":
            small.append(sa.sheet([sa.edged(t.reshape(64, 5, 48, 5, 4).mean(axis=(1, 3))) for t in tiles], len(tiles)))
    sa.rs.save(sa.stack(rows), out / "b1_finish.png")
    sa.rs.save(sa.stack(small).repeat(3, axis=0).repeat(3, axis=1), out / "b1_finish_64.png")
    r.stamp_font_size = 26
    close = [sa.sheet([sa.edged(stage.tile(f, look, pale, (480, 640), f"{look}, {'noon' if pale else 'dusk'}: {f}")) for f in FINISH_CLOSE], 3)
             for look, pale in (("before", True), ("after", True), ("after", False))]
    sa.rs.save(sa.stack(close), out / "b1_finish_close.png")
    stage.tmp.unlink(missing_ok=True)


def main():
    sys.stdout.reconfigure(line_buffering=True)
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    if "B5" in args:
        main_b5(out, next((a for a in args if a.endswith(".json")), None), next((a for a in ("Close", "Small") if a in args), None))
        return
    if "Signature" in args:
        main_signature(out, back="Back" in args)
        return
    if "Finish" in args:
        main_b1_finish(out)
        return
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
