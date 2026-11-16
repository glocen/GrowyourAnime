"""AR5 section 1: Lantern Row's look, the direction sheet (docs/asset-requests.md). Three rough directions, A, B and C,
each one frame of the street from the player's camera: Rook fighting two Shades in the middle distance, the avatar in
front of the camera, the street 44 studs between the stall fronts (docs/design.md, "The world, in grey").

Rough blocks, no finish: only what the engine can draw. A sky of our own picture (a gradient and painted clouds, as six
cube faces would hold it), one directional light (Roblox has one sun or moon), a flat ambient, PointLights in the
lanterns, Atmosphere as fog by distance, bloom, flat-colour maps with their shading painted in (a gradient up each
shape), and outlines as geometry (an inverted hull: a second shell, flipped, one-sided, which a MeshPart draws as is).
Eevee renders it to linear light; the bloom and the tone curve are applied here, in numpy, the same for all three.

The staging is the game's (Config.Combat.Replay and Lead): the struck Shade 9 studs ahead of the avatar and Lead.Side to
its right, Rook beyond it at Lead.Frame degrees, the camera at Roblox's start zoom (12.5 studs, the take's), pitched
Replay.Pitch down, FOV 70. The fighters wear their delivered maps and play their own clips: Rook at Haymaker's Shock,
the struck Shade in Hit, the other in Attack's wind-up.

Run, one direction per run (memory stays low), then the sheet:
  blender.exe -b --factory-startup --python tools/blender/lantern_row_look.py -- <out> A [fast]
  blender.exe -b --factory-startup --python tools/blender/lantern_row_look.py -- <out> sheet
Writes <out>/<D>_frame.png (the frame), <D>_fighters.png (the fighters alone, lit by the same street), <D>.json (the
measures and the cost), and lantern_row_look.png (the sheet). Eevee, no Cycles: no lock needed.
"""

import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import r6anim as r6  # noqa: E402
import r6rig  # noqa: E402
import rook_clips as rc  # noqa: E402
import rook_haymaker_fx as hx  # noqa: E402  (the knuckles' place on the ram)
import rook_sheet as rs  # noqa: E402
import shade_clips as sc  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
COMBAT = "src/shared/Config/Combat.luau"
ROOK = REPO / "build" / "scratch" / "modulo" / "rook" / "model"
SHADE = REPO / "build" / "scratch" / "modulo" / "shade" / "model"
SIZE = (960, 540)
FRAME = 58             # the scene's frame: Rook's Haymaker at Shock (58), the piston home
HIT_START = 54         # the struck Shade's Hit starts here: frame 4 of it, the blow just in
ATTACK_START = 38      # the other's Attack: frame 20, turned away, the sleeve about to come round
ZOOM, FOV, FOCUS = 12.5, 70.0, 1.5   # Roblox's start zoom (the take's TAKE_ZOOM), its default FOV, the focus over the root
STRIKE_GAP = 4.5       # studs from the struck Shade to Rook: staged so the ram meets it on this frame
HALF = 22.0            # half the street, stall front to stall front


# --- the three directions ---------------------------------------------------------------------------------------------
# Colours are sRGB codes. sky: (elevation, colour) stops from below the horizon to the zenith. sun: (azimuth from the
# street's far end, positive to the right; elevation; colour; strength; shadows). ambient: the flat fill. fog: colour,
# density a stud past 20 studs. lantern: (colours in turn, strength, a PointLight every n lanterns, its power, range).
# ink: outline (colour, studs thick, which shapes). bloom: (threshold, intensity, sigma px).

DIRECTIONS = {
    "A": {
        "name": "Painted dusk",
        "idea": "the sun low behind you, gold on the fight; ahead a pink band under a violet sky, warm wood, a low skyline",
        "sky": ((-0.2, "#3A2A55"), (0.0, "#E9A0B4"), (0.06, "#F28CA8"), (0.17, "#A673C2"), (0.38, "#4A4A9C"), (1.0, "#1E2258")),
        "clouds": ("#F29AB4", "#7A4F9A", 0.03, 0.22, 0.55),
        "moon": None, "stars": 0.0,
        "sun": (195.0, 9.0, "#FFBE8A", 3.4, True),
        "ambient": ("#5B4F86", 0.38),
        "fog": ("#DC94AC", 0.0065),
        "lantern": (("#FFE7B8", "#FFE7B8", "#66F0FF"), 1.8, 3, 1700.0, 24.0),
        "ink": ("#1C1026", 0.12, "big"),
        "wood": ("#9A6248", "#4E2E33"), "post": ("#5A2E2E", "#2E1A22"), "awning": ("#D0444F", "#F4E5CC"),
        "cloth": ("#F3E6CC", "#2A1A2E"), "noren": ("#2E2A5E", "#F3E6CC"), "house": ("#5A4A78", "#2E2648"),
        "roof": ("#2D2648", "#1E1A34"), "ground": ("#6E5E72", "#54475E"), "joint": "#4A3F55",
        "window": ("#FFC98A", 2.5, 0.35), "paper": ("#FFF2DC", 0.4),
        "bloom": (0.85, 0.65, (6, 18)), "exposure": 1.0, "fighter_light": None, "skyline": (12.0, 14.0, 17.0, 20.0),
    },
    "B": {
        "name": "Ink night",
        "idea": "blue hour gone to night: a dark street in heavy ink, a painted moon, the lanterns mostly cyan and blooming",
        "sky": ((-0.2, "#0C1630"), (0.0, "#2F8FA6"), (0.06, "#1F5584"), (0.22, "#14275A"), (0.5, "#0B1338"), (1.0, "#060A22")),
        "clouds": ("#2C5E8E", "#0E1A40", 0.02, 0.18, 0.62),
        "moon": ((14.0, 24.0), 0.045, "#EAF6FF"), "stars": 0.9,
        "sun": (200.0, 48.0, "#9DB6FF", 0.9, True),   # the moon's light comes from behind the camera's left; its picture is ahead
        "ambient": ("#22306A", 0.55),
        "fog": ("#1C3E66", 0.005),
        "lantern": (("#6CF8FF", "#6CF8FF", "#FFE9C2"), 2.6, 2, 2600.0, 22.0),
        "ink": ("#05040B", 0.2, "all"),
        "wood": ("#3A2A3A", "#171019"), "post": ("#22161E", "#0E0A10"), "awning": ("#28307A", "#3AB8CC"),
        "cloth": ("#D8E8F0", "#0E1022"), "noren": ("#141838", "#7FE8F5"), "house": ("#1C2040", "#0C0E20"),
        "roof": ("#101226", "#080914"), "ground": ("#48506A", "#323850"), "joint": "#232838",
        "window": ("#7FE8F5", 2.2, 0.5), "paper": ("#E6F6FF", 0.9),
        "bloom": (0.7, 1.0, (7, 22)), "exposure": 1.05, "skyline": (18.0, 24.0, 28.0, 34.0),
        "fighter_light": ("#FFF1DD", 900.0, 12.0),   # a soft PointLight over each fighter, carried with it
    },
    "C": {
        "name": "Last light",
        "idea": "golden hour, the sun low across the street and long shadows, pastel stalls in clean cel colour, lanterns just lit",
        "sky": ((-0.2, "#C99AA8"), (0.0, "#FFD8A2"), (0.08, "#FFBC90"), (0.24, "#EEA8C0"), (0.5, "#A9AEE2"), (1.0, "#7E8ED6")),
        "clouds": ("#FFF1DC", "#D79CB6", 0.04, 0.32, 0.5),
        "moon": None, "stars": 0.0,
        "sun": (130.0, 24.0, "#FFCB92", 4.0, True),
        "ambient": ("#B89DBE", 0.55),
        "fog": ("#F4C6AA", 0.0075),
        "lantern": (("#FFE2B0", "#FFE2B0", "#7CF2FF"), 1.3, 3, 900.0, 18.0),
        "ink": ("#4A2C3E", 0.08, "big"),
        "wood": ("#D29572", "#94604E"), "post": ("#A2584C", "#6A3A38"), "awning": ("#E8766E", "#FCEED6"),
        "cloth": ("#FCF0DA", "#4A2C3E"), "noren": ("#86CDBB", "#FCF0DA"), "house": ("#B596B4", "#8C7096"),
        "roof": ("#7A5E8A", "#5E4870"), "ground": ("#CDB29C", "#B39784"), "joint": "#9C8274",
        "window": ("#FFE6B8", 0.8, 0.2), "paper": ("#FFF6E8", 0.2),
        "bloom": (1.1, 0.35, (6, 16)), "exposure": 1.0, "fighter_light": None, "skyline": (15.0, 19.0, 24.0, 28.0),
    },
}


# Round 2 (research's verdict, 2026-11-12): B's structure in A's hour, held at dusk. The afterglow is only at the street's
# far end: the sky and the fog take `sky` and `fog` toward `glow_az` and `sky_away` and `fog_away` from it, as Roblox's
# Atmosphere takes Color toward the sun and Decay away. The one directional light is high, so the fight is lit the same
# from either end. string_light: one SpotLight a string, straight down (colour, power, cone degrees): the warm pools.
DIRECTIONS["M"] = {
    "name": "Lantern dusk, the merge",
    "idea": "B's dark street and lit fight in A's hour: warm lanterns, cyan between, warm pools, a pink afterglow at the street's end",
    "sky": ((-0.2, "#4A2E5E"), (0.0, "#F4A0B2"), (0.05, "#EC88AC"), (0.14, "#9C66B8"), (0.32, "#3A3A8A"), (1.0, "#141A48")),
    "sky_away": ((-0.2, "#2A2658"), (0.0, "#6A58A4"), (0.08, "#4E4692"), (0.3, "#2A2E6C"), (1.0, "#141A48")),
    "glow_az": 0.0,
    "clouds": ("#E890B0", "#4A3E86", 0.03, 0.2, 0.56),
    "moon": None, "stars": 0.35,
    "sun": (200.0, 62.0, "#A9B4FF", 0.55, True),
    "ambient": ("#3A3F7C", 0.42),
    "fog": ("#CC7CA0", 0.0045), "fog_away": "#4A4290",
    "lantern": (("#FFE7B8", "#FFE7B8", "#66F0FF"), 2.4, 0, 0.0, 0.0),
    "string_light": ("#FFD49A", 6600.0, 54.0),
    "ink": ("#0C0A16", 0.14, "big"),
    "wood": ("#4E3242", "#20151F"), "post": ("#3C1F28", "#170E15"), "awning": ("#B8404C", "#E8D8C0"),
    "cloth": ("#F0E4CC", "#1E1426"), "noren": ("#262454", "#F0E4CC"), "house": ("#2C2C56", "#151532"),
    "roof": ("#191936", "#0E0E22"), "ground": ("#766C84", "#585066"), "joint": "#383244",
    "window": ("#FFC98A", 2.0, 0.25), "paper": ("#FFF2DC", 0.5),
    "bloom": (0.8, 0.8, (6, 20)), "exposure": 1.0, "skyline": (14.0, 18.0, 22.0, 26.0),
    # one PointLight, carried by the lead: ahead of him toward his target and over their heads (studs ahead, studs up).
    # It lights his front and the floor between them; a Shade, its back to the camera, stays a dark shape on that floor.
    "fighter_light": ("#FFF1DD", 1050.0, 12.0), "fighter_light_ahead": (1.8, 5.2),
}


def srgb(code):
    return rs.srgb(code)[:3]


# --- materials: flat painted colour, the fog over everything ------------------------------------------------------------

FOG = {}


def _fogged(mat, shader_out):
    """Mixes a material's shader toward the Atmosphere's colour by its distance from the camera, as Roblox's Atmosphere
    fogs geometry, and plugs it into the output."""
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    cam = nodes.new("ShaderNodeCameraData")
    sub = nodes.new("ShaderNodeMath")
    sub.operation, sub.inputs[1].default_value = "SUBTRACT", 20.0
    clamp = nodes.new("ShaderNodeMath")
    clamp.operation, clamp.inputs[1].default_value = "MAXIMUM", 0.0
    mul = nodes.new("ShaderNodeMath")
    mul.operation, mul.inputs[1].default_value = "MULTIPLY", -FOG["density"]
    exp = nodes.new("ShaderNodeMath")
    exp.operation = "EXPONENT"
    inv = nodes.new("ShaderNodeMath")
    inv.operation, inv.inputs[0].default_value = "SUBTRACT", 1.0
    links.new(cam.outputs["View Distance"], sub.inputs[0])
    links.new(sub.outputs[0], clamp.inputs[0])
    links.new(clamp.outputs[0], mul.inputs[0])
    links.new(mul.outputs[0], exp.inputs[0])
    links.new(exp.outputs[0], inv.inputs[1])
    fog = nodes.new("ShaderNodeEmission")
    fog.inputs["Color"].default_value = (*FOG["colour"], 1)
    fog.inputs["Strength"].default_value = 1.0
    if FOG.get("away") is not None:  # Color toward the glow, Decay away from it, by where the camera looks
        geo = nodes.new("ShaderNodeNewGeometry")
        dot = nodes.new("ShaderNodeVectorMath")
        dot.operation = "DOT_PRODUCT"
        a = math.radians(FOG["azimuth"])
        dot.inputs[1].default_value = (-math.sin(a), -math.cos(a), 0.0)  # Incoming points at the camera
        side = nodes.new("ShaderNodeMapRange")
        side.inputs[1].default_value, side.inputs[2].default_value = -0.2, 0.9
        tint = nodes.new("ShaderNodeMix")
        tint.data_type = "RGBA"
        tint.inputs[6].default_value = (*FOG["away"], 1)
        tint.inputs[7].default_value = (*FOG["colour"], 1)
        links.new(geo.outputs["Incoming"], dot.inputs[0])
        links.new(dot.outputs["Value"], side.inputs[0])
        links.new(side.outputs[0], tint.inputs[0])
        links.new(tint.outputs[2], fog.inputs["Color"])
    mix = nodes.new("ShaderNodeMixShader")
    links.new(inv.outputs[0], mix.inputs[0])
    links.new(shader_out, mix.inputs[1])
    links.new(fog.outputs[0], mix.inputs[2])
    out = next(n for n in nodes if n.type == "OUTPUT_MATERIAL")
    links.new(mix.outputs[0], out.inputs["Surface"])


def _new(name):
    mat = bpy.data.materials.new(name)
    try:
        mat.use_nodes = True
    except Exception:
        pass
    mat.use_backface_culling = False
    nodes = mat.node_tree.nodes
    p = next((n for n in nodes if n.type == "BSDF_PRINCIPLED"), None) or nodes.new("ShaderNodeBsdfPrincipled")
    if not any(n.type == "OUTPUT_MATERIAL" for n in nodes):
        nodes.new("ShaderNodeOutputMaterial")
    p.inputs["Roughness"].default_value = 0.9
    for key in ("Specular IOR Level", "Specular"):
        if key in p.inputs:
            p.inputs[key].default_value = 0.15
    return mat, p


def painted(name, top, bottom, axis="Z"):
    """A flat colour with its shading painted in: `bottom` at the shape's foot to `top` at its head (Generated
    coordinates: one gradient per shape, as a painted map of a kit piece would hold it)."""
    mat, p = _new(name)
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    coord = nodes.new("ShaderNodeTexCoord")
    sep = nodes.new("ShaderNodeSeparateXYZ")
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (*srgb(bottom), 1)
    ramp.color_ramp.elements[1].color = (*srgb(top), 1)
    ramp.color_ramp.elements[1].position = 0.85
    links.new(coord.outputs["Generated"], sep.inputs[0])
    links.new(sep.outputs[axis], ramp.inputs[0])
    links.new(ramp.outputs["Color"], p.inputs["Base Color"])
    _fogged(mat, p.outputs[0])
    return mat


def striped(name, a, b, count, axis="Y"):
    """Two flat colours in stripes along a shape (an awning's cloth), shaded darker toward its low edge."""
    mat, p = _new(name)
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    coord = nodes.new("ShaderNodeTexCoord")
    sep = nodes.new("ShaderNodeSeparateXYZ")
    mul = nodes.new("ShaderNodeMath")
    mul.operation, mul.inputs[1].default_value = "MULTIPLY", float(count)
    frac = nodes.new("ShaderNodeMath")
    frac.operation = "FRACT"
    step = nodes.new("ShaderNodeMath")
    step.operation, step.inputs[1].default_value = "GREATER_THAN", 0.5
    mix = nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.inputs[6].default_value = (*srgb(a), 1)
    mix.inputs[7].default_value = (*srgb(b), 1)
    links.new(coord.outputs["Generated"], sep.inputs[0])
    links.new(sep.outputs[axis], mul.inputs[0])
    links.new(mul.outputs[0], frac.inputs[0])
    links.new(frac.outputs[0], step.inputs[0])
    links.new(step.outputs[0], mix.inputs[0])
    links.new(mix.outputs[2], p.inputs["Base Color"])
    _fogged(mat, p.outputs[0])
    return mat


def printed(name, image, cloth, ink, u_axis, v_axis, repeat=(1.0, 1.0)):
    """Cloth printed with our own script: the glyph picture (white on black) mixes `cloth` and `ink`, laid on the shape's
    own two axes (Generated), as a Decal or a painted map would."""
    mat, p = _new(name)
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    coord = nodes.new("ShaderNodeTexCoord")
    sep = nodes.new("ShaderNodeSeparateXYZ")
    comb = nodes.new("ShaderNodeCombineXYZ")
    mu = nodes.new("ShaderNodeMath")
    mu.operation, mu.inputs[1].default_value = "MULTIPLY", repeat[0]
    mv = nodes.new("ShaderNodeMath")
    mv.operation, mv.inputs[1].default_value = "MULTIPLY", repeat[1]
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = image
    tex.extension = "REPEAT"
    tex.interpolation = "Linear"
    mix = nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.inputs[6].default_value = (*srgb(cloth), 1)
    mix.inputs[7].default_value = (*srgb(ink), 1)
    links.new(coord.outputs["Generated"], sep.inputs[0])
    links.new(sep.outputs[u_axis], mu.inputs[0])
    links.new(sep.outputs[v_axis], mv.inputs[0])
    links.new(mu.outputs[0], comb.inputs[0])
    links.new(mv.outputs[0], comb.inputs[1])
    links.new(comb.outputs[0], tex.inputs["Vector"])
    links.new(tex.outputs["Color"], mix.inputs[0])
    links.new(mix.outputs[2], p.inputs["Base Color"])
    _fogged(mat, p.outputs[0])
    return mat


def glowing(name, code, strength, base=None):
    """A lit paper or a lit window: emission (Neon, or a SurfaceAppearance's glow), fogged with the rest."""
    mat, p = _new(name)
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    em = nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = (*srgb(code), 1)
    em.inputs["Strength"].default_value = strength
    if base:
        p.inputs["Base Color"].default_value = (*srgb(base), 1)
        add = nodes.new("ShaderNodeAddShader")
        links.new(p.outputs[0], add.inputs[0])
        links.new(em.outputs[0], add.inputs[1])
        _fogged(mat, add.outputs[0])
    else:
        _fogged(mat, em.outputs[0])
    return mat


def ink_material(code):
    """The outline shell: flat dark, unlit, one-sided (the hull's inside faces the camera only round the silhouette)."""
    mat = bpy.data.materials.new("Ink")
    try:
        mat.use_nodes = True
    except Exception:
        pass
    nodes = mat.node_tree.nodes
    for n in list(nodes):
        if n.type != "OUTPUT_MATERIAL":
            nodes.remove(n)
    if not any(n.type == "OUTPUT_MATERIAL" for n in nodes):
        nodes.new("ShaderNodeOutputMaterial")
    em = nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = (*srgb(code), 1)
    _fogged(mat, em.outputs[0])
    mat.use_backface_culling = True
    try:
        mat.use_backface_culling_shadow = True
    except AttributeError:
        pass
    return mat


# --- our own script: glyphs for the signs and the cloth ----------------------------------------------------------------

GLYPH_SEED = 23


def _curve(p0, p1, p2, n=40):
    t = np.linspace(0, 1, n)[:, None]
    return (1 - t) ** 2 * np.array(p0, float) + 2 * t * (1 - t) * np.array(p1, float) + t ** 2 * np.array(p2, float)


def _brush(ink, xx, yy, points, radii, soft=0.012):
    """A brush dragged through `points`, its width changing along the way: thick where it presses, thin where it lifts."""
    for (x, y), r in zip(points, radii):
        np.maximum(ink, np.clip((r - np.hypot(xx - x, yy - y)) / soft, 0, 1), out=ink)


def glyph(rng, cell=128):
    """One letter of Lantern Row's hand: a sprig of flame over a small cup. Four or five unequal wedges fan from one
    root over a wide angle, the longest curling; a short thin cup sits under the root; a thin echo arc hangs below
    it; one round dot stands off to a side. Every letter leans on a diagonal and may be mirrored.

    What two draws taught (the content check, round 2): a long pressed bowl shrinks to a stem at 16 px, and a stem
    with two prongs is an E, an F or a pi at any lean; a tall wedge near upright over a hooked foot is a J. So the cup
    is short and thin, the wedges carry the letter, there are never fewer than four, and a draw whose longest wedge
    ends within 25 degrees of upright or level is refused. The dot is round: a tailed drop is a shape moderation
    reads badly alone (handbook/platform/rules-and-moderation.md, "Traps")."""
    yy, xx = (np.mgrid[0:cell, 0:cell] + 0.5) / cell
    while True:
        turn = (rng.integers(0, 4) + 0.5) * math.pi / 2 + rng.uniform(-0.2, 0.2)
        flip = rng.choice((-1.0, 1.0))
        n = int(rng.integers(4, 6))
        span = math.radians(rng.uniform(115, 165))
        centre = math.radians(rng.uniform(-18, 18))
        leans = centre + (np.arange(n) - (n - 1) / 2) * span / (n - 1) + rng.uniform(-0.1, 0.1, n)
        heights = rng.permutation(np.array([0.40, 0.29, 0.21, 0.15, 0.25])[:n])
        tall = leans[int(np.argmax(heights))]
        final = math.degrees(turn + flip * tall) % 90.0   # 0 or 90: upright or level, once placed
        if 25.0 <= final <= 65.0:
            break
    ink = np.zeros((cell, cell), np.float32)
    c, s_ = math.cos(turn), math.sin(turn)

    def place(points):
        q = np.array(points, float) - (0.5, 0.56)   # the letter's middle, a little over its root
        q[:, 0] *= flip
        return np.stack([q[:, 0] * c - q[:, 1] * s_, q[:, 0] * s_ + q[:, 1] * c], 1) * 1.04 + 0.5

    root = np.array((0.5, 0.60))
    for i in range(n):
        lean = leans[i]
        along = np.array((math.sin(lean), -math.cos(lean)))
        base = root + along * 0.05 + np.array((math.cos(lean), math.sin(lean))) * rng.uniform(-0.015, 0.015)
        tip = base + heights[i] * along
        curl = (0.10 if heights[i] > 0.35 else 0.035) * rng.choice((-1.0, 1.0))
        bend = (base + tip) / 2 + curl * np.array((math.cos(lean), math.sin(lean)))
        t = np.linspace(0, 1, 30)
        _brush(ink, xx, yy, place(_curve(base, bend, tip, 30)), 0.009 + 0.052 * np.sin(math.pi * np.clip(t * 1.5, 0, 1)) * (1 - t) ** 0.6)
    cup = _curve((0.36, 0.63), (0.5, 0.63 + rng.uniform(0.16, 0.22)), (0.64, 0.63), 60)
    _brush(ink, xx, yy, place(cup), 0.009 + 0.026 * np.sin(math.pi * np.linspace(0, 1, 60)))
    side = rng.choice((-1.0, 1.0))
    reach = rng.uniform(0.12, 0.3)   # the echo: a thin arc under the cup, short or long. No tassel: two small parallel
    e = _curve((0.5 - side * 0.14, 0.86), (0.5 + side * 0.04, 0.97), (0.5 + side * reach, 0.9 - reach * 0.3), 24)  # dashes read as a quote mark
    _brush(ink, xx, yy, place(e), 0.006 + 0.014 * np.sin(math.pi * np.linspace(0, 1, 24)))
    low = int(np.argmin(heights))                                   # the dot, beyond the shortest wedge
    out = root + (heights[low] + 0.17) * np.array((math.sin(leans[low]), -math.cos(leans[low])))
    _brush(ink, xx, yy, place(np.array([out])), [0.034])
    return ink


def glyph_images(folder: Path, seed=None):
    """Eight letters, white on black: a column of four (banners) and a row of four (boards and curtains)."""
    rng = np.random.default_rng(GLYPH_SEED if seed is None else seed)
    glyphs = [glyph(rng) for _ in range(8)]
    column = np.concatenate(glyphs[:4], axis=0)   # 128 x 512: read top to bottom
    row = np.concatenate(glyphs[4:], axis=1)      # 512 x 128
    images = {}
    for name, ink in (("glyph_column", column), ("glyph_row", row)):
        rgba = np.ones((*ink.shape, 4), np.float32)
        rgba[..., :3] = ink[..., None]
        path = folder / f"{name}.png"
        rs.save(rgba, path)
        images[name] = bpy.data.images.load(str(path))
    images["all"] = glyphs
    return images


SCRIPT_SHEET = "lantern_row_script.png"


def glyph_preview(folder: Path, seed=None):
    """The eight letters as they'll be met: large; at the sizes a sign shows them from the street (32, 16 and 10 px),
    dark on cloth and pale on a dark curtain; and the 16 px tiles again blown up five times, pixel for pixel, since
    that's the size where a letter shows if there is one."""
    rng = np.random.default_rng(GLYPH_SEED if seed is None else seed)
    glyphs = [glyph(rng) for _ in range(8)]
    cloth, ink, dark, pale = (np.array(srgb_code(c), np.float32) for c in ("#F0E4CC", "#1E1426", "#262454", "#F0E4CC"))
    page = rs.canvas(8 * 136 + 16, 128 + 4 * 52 + 40 + 2 * 92, tuple(cloth))

    def tile(g, size, a, b):
        small = rs.shrink(np.dstack([g, g, g, np.ones_like(g)]), size / 128)[..., 0]
        out = np.ones((small.shape[0], small.shape[1], 4), np.float32)
        out[..., :3] = a[None, None] * (1 - small[..., None]) + b[None, None] * small[..., None]
        return out

    for i, g in enumerate(glyphs):
        rs.paste(page, tile(g, 128, cloth, ink), 12 + i * 136, 10)
    y = 150
    for size, (a, b) in ((32, (cloth, ink)), (16, (cloth, ink)), (10, (cloth, ink)), (16, (dark, pale))):
        for i, g in enumerate(glyphs):
            rs.paste(page, tile(g, size, a, b), 12 + i * (size + 6), y)
        y += 52
    for a, b in ((cloth, ink), (dark, pale)):
        for i, g in enumerate(glyphs):
            rs.paste(page, np.repeat(np.repeat(tile(g, 16, a, b), 5, axis=0), 5, axis=1), 12 + i * 92, y)
        y += 92
    rs.save(page, folder / SCRIPT_SHEET)


def srgb_code(code):
    """A colour code as it's stored in a PNG (no linearising): for pictures composed here, not rendered."""
    return tuple(int(code[i:i + 2], 16) / 255 for i in (1, 3, 5))


# --- the street --------------------------------------------------------------------------------------------------------

class Kit:
    """Every environment piece made, with its outline if it takes one, so the cost can be counted."""

    def __init__(self, d, images):
        self.d, self.images, self.pieces, self.lights = d, images, [], []
        c = d
        ink_code, self.ink_t, self.ink_on = c["ink"]
        self.ink = ink_material(ink_code)
        self.m = {
            "wood": painted("Wood", *c["wood"]), "post": painted("Post", *c["post"]),
            "house": painted("House", *c["house"]), "roof": painted("Roof", *c["roof"]),
            "awning": striped("Awning", c["awning"][0], c["awning"][1], 5),
            "noren": printed("Noren", images["glyph_row"], c["noren"][0], c["noren"][1], "Y", "Z", (1.0, 1.0)),
            "banner": printed("Banner", images["glyph_column"], c["cloth"][0], c["cloth"][1], "Y", "Z", (1.0, 1.0)),
            "board": printed("Board", images["glyph_row"], c["wood"][1], c["cloth"][0], "Y", "Z", (1.0, 1.0)),
            "window": glowing("Window", c["window"][0], c["window"][1]),
            "paper": glowing("Paper", c["paper"][0], c["paper"][1], base=c["paper"][0]),
            "cable": painted("Cable", c["post"][1], c["post"][1]),
        }
        self.m["lanterns"] = [glowing(f"Lantern{i}", code, c["lantern"][1]) for i, code in enumerate(c["lantern"][0])]

    def add(self, obj, big=False, ink=True):
        if ink and (self.ink_on == "all" or (big and self.ink_on == "big")):
            obj.data.materials.append(self.ink)
            mod = obj.modifiers.new("Ink", "SOLIDIFY")
            mod.thickness, mod.offset, mod.use_flip_normals, mod.material_offset = self.ink_t, 1.0, True, 1
            mod.use_rim = False
        self.pieces.append(obj)
        return obj

    def block(self, name, size, at, mat, big=False, rot=(0, 0, 0)):
        obj = bl.box(name, size, mat)
        obj.location, obj.rotation_euler = at, rot
        return self.add(obj, big)


def ground(kit):
    c = kit.d
    mat, p = _new("Paving")
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    coord = nodes.new("ShaderNodeTexCoord")
    brick = nodes.new("ShaderNodeTexBrick")
    brick.inputs["Color1"].default_value = (*srgb(c["ground"][0]), 1)
    brick.inputs["Color2"].default_value = (*srgb(c["ground"][1]), 1)
    brick.inputs["Mortar"].default_value = (*srgb(c["joint"]), 1)
    brick.inputs["Scale"].default_value = 0.8
    brick.inputs["Mortar Size"].default_value = 0.02
    brick.inputs["Brick Width"].default_value = 1.6
    brick.inputs["Row Height"].default_value = 1.0
    links.new(coord.outputs["Object"], brick.inputs["Vector"])
    links.new(brick.outputs["Color"], p.inputs["Base Color"])
    _fogged(mat, p.outputs[0])
    kit.block("Street", (2 * HALF, 900, 0.4), (0, 420, -0.2), mat)
    kit.block("Under", (200, 900, 0.4), (0, 420, -0.25), painted("Under", c["ground"][1], c["ground"][1]))


def stall(kit, side, y, rng, i):
    """One stall on a side (+1 right, -1 left), its front on the stall line: a counter, a back wall, two posts, a sloped
    striped awning, a printed curtain hung from it, a board on top."""
    x0 = side * HALF
    w = 11.0
    out = side  # away from the street
    kit.block(f"Counter{i}", (2.4, w, 3.2), (x0 + out * 1.2, y, 1.6), kit.m["wood"], big=True)
    kit.block(f"Back{i}", (0.6, w, 9.0), (x0 + out * 6.2, y, 4.5), kit.m["wood"], big=True)
    for k in (-1, 1):
        kit.block(f"Post{i}{k}", (0.6, 0.6, 9.4), (x0 + out * 0.3, y + k * (w / 2 - 0.3), 4.7), kit.m["post"], big=True)
    tilt = math.atan2(1.6, 6.6)
    kit.block(f"Awning{i}", (7.6, w + 1.2, 0.3), (x0 + out * 2.6, y, 9.3), kit.m["awning"], big=True,
              rot=(0, out * tilt, 0))
    kit.block(f"Noren{i}", (0.08, w - 1.6, 2.2), (x0 - out * 0.9, y, 7.4), kit.m["noren"])
    kit.block(f"Board{i}", (0.35, w * 0.55, 1.7), (x0 + out * 5.8, y, 11.4), kit.m["board"], big=True)
    if rng.random() < 0.7:  # goods on the counter: a row of small lit jars, or boxes
        for j in range(4):
            kit.block(f"Goods{i}{j}", (0.9, 1.2, 0.9), (x0 + out * 0.9, y - 3.6 + j * 2.4, 3.65),
                      kit.m["paper"] if rng.random() < 0.4 else kit.m["post"])


def house(kit, side, y, h, i):
    """A building behind the stalls: a block with a gabled roof and lit windows, its shape the skyline."""
    x = side * (HALF + 16)
    kit.block(f"House{i}", (16, 15, h), (x, y, h / 2), kit.m["house"], big=True)
    for k in (-1, 1):  # the roof's two slopes, a ridge along the street
        kit.block(f"Roof{i}{k}", (10.4, 16.4, 0.6), (x + k * 4.3, y, h + 2.6), kit.m["roof"], big=True,
                  rot=(0, -k * math.radians(32), 0))
    for row in range(int(h // 6)):
        for col in (-1, 1):
            if (i * 7 + row * 3 + col) % 5 > 1 + kit.d["window"][2] * 2:  # not every window lit
                continue
            kit.block(f"Win{i}{row}{col}", (0.2, 2.0, 2.4), (x - side * 8.05, y + col * 3.6, 3.5 + row * 6.0), kit.m["window"])


def banner(kit, side, y, i):
    """A tall printed flag on a pole at the stall line, between stalls."""
    x0 = side * (HALF - 0.4)
    kit.block(f"Pole{i}", (0.3, 0.3, 15.0), (x0, y, 7.5), kit.m["post"], big=True)
    kit.block(f"Flag{i}", (0.06, 2.0, 6.4), (x0, y + 1.15, 10.6), kit.m["banner"])


def lantern_strings(kit, scene, near=0.0):
    """Strings across the street every 12 studs, zig-zagging, sagging, a paper lantern every 3.6 studs, a PointLight
    in every n-th one near the camera."""
    colours, strength, every, power, reach = kit.d["lantern"]
    count = 0
    for s in range(0, 34):
        y = -6 + s * 12.0
        a, b = Vector((-HALF + 0.4, y, 18.4)), Vector((HALF - 0.4, y + 6.0, 18.4))
        for end in (a, b):
            kit.block(f"StringPole{s}{end.x:.0f}", (0.3, 0.3, 19.0), (end.x, end.y, 9.5), kit.m["post"], big=True)
        points = []
        for t in np.linspace(0, 1, 13):
            p = a.lerp(b, t)
            p.z -= 3.0 * (1 - (2 * t - 1) ** 2)
            points.append(p)
        cable = bl.tube_along(f"Cable{s}", points, [0.06] * len(points), sides=4, material=kit.m["cable"])
        kit.pieces.append(cable)
        if kit.d.get("string_light") and abs(y - near) < 150:
            code, watts, cone = kit.d["string_light"]
            mid = a.lerp(b, 0.5)
            spot = light(kit, scene, f"StringLight{s}", Vector((mid.x, mid.y, mid.z - 4.2)), code, watts, 40.0, kind="SPOT")
            spot.data.spot_size, spot.data.spot_blend = math.radians(cone), 0.7
        n = 12
        for j in range(1, n):
            t = j / n
            p = a.lerp(b, t)
            p.z -= 3.0 * (1 - (2 * t - 1) ** 2) + 0.8
            mat = kit.m["lanterns"][count % len(colours)]
            body = bl.sphere(f"Lantern{s}_{j}", 0.5, segments=10, rings=6, material=mat)
            body.data.transform(Matrix.Diagonal((1.0, 1.0, 1.25, 1.0)))
            caps = [bl.cylinder(f"Cap{s}_{j}_{k}", 0.36, 0.14, segments=10, material=kit.m["cable"]) for k in (0, 1)]
            caps[0].location.z, caps[1].location.z = 0.6, -0.6
            lamp = bl.join([body, *caps], f"Lantern{s}_{j}")
            lamp.location = p
            kit.add(lamp, big=False, ink=False)
            if every and count % every == 0 and abs(y - near) < 140:
                light(kit, scene, f"LanternLight{s}_{j}", p - Vector((0, 0, 0.9)), colours[count % len(colours)], power, reach)
            count += 1


def light(kit, scene, name, at, code, power, reach, shadow=False, kind="POINT"):
    data = bpy.data.lights.new(name, kind)
    data.energy, data.color = power, srgb(code)
    data.shadow_soft_size = 0.6
    data.use_shadow = shadow
    try:
        data.use_custom_distance, data.cutoff_distance = True, reach
    except AttributeError:
        pass
    obj = bpy.data.objects.new(name, data)
    obj.location = at
    scene.collection.objects.link(obj)
    kit.lights.append(obj)
    return obj


def paper_in_air(kit, rng, near=0.0):
    """Life in the air: torn paper and petals of it, drifting at every height over the fight and down the street."""
    for i in range(70):
        y = near + (rng.uniform(2, 110) if near < 100 else -rng.uniform(2, 110))
        obj = bl.box(f"Scrap{i}", (0.55, 0.38, 0.03), kit.m["paper"])
        obj.location = (rng.uniform(-HALF + 2, HALF - 2), y, rng.uniform(2.5, 14))
        obj.rotation_euler = tuple(rng.uniform(0, math.tau, 3))
        kit.add(obj)


def street(scene, d, images, near=0.0):
    kit = Kit(d, images)
    rng = np.random.default_rng(5)
    ground(kit)
    i = 0
    for side in (-1, 1):
        for k in range(30):
            y = -10 + k * 14.0
            stall(kit, side, y, rng, i)
            if k % 2 == 1:
                banner(kit, side, y + 7.0, i)
            i += 1
        for k in range(26):
            house(kit, side, -8 + k * 16.0 + (side > 0) * 6, float(rng.choice(d["skyline"])), i)
            i += 1
    lantern_strings(kit, scene, near)
    paper_in_air(kit, rng, near)
    return kit


# --- the sky, the sun, the ambient ---------------------------------------------------------------------------------------

def sky(scene, d):
    """The world: what the camera sees is our painted sky (a gradient by elevation, painted cloud bands, a moon and
    stars where a direction has them); what lights the scene is a flat ambient (Lighting.Ambient and OutdoorAmbient)."""
    world = bpy.data.worlds.new(d["name"])
    try:
        world.use_nodes = True
    except Exception:
        pass
    scene.world = world
    nodes, links = world.node_tree.nodes, world.node_tree.links
    for n in list(nodes):
        nodes.remove(n)
    out = nodes.new("ShaderNodeOutputWorld")
    coord = nodes.new("ShaderNodeTexCoord")
    sep = nodes.new("ShaderNodeSeparateXYZ")
    links.new(coord.outputs["Generated"], sep.inputs[0])
    norm = nodes.new("ShaderNodeVectorMath")
    norm.operation = "NORMALIZE"
    links.new(coord.outputs["Generated"], norm.inputs[0])
    dirs = nodes.new("ShaderNodeSeparateXYZ")
    links.new(norm.outputs[0], dirs.inputs[0])
    remap = nodes.new("ShaderNodeMapRange")
    remap.inputs[1].default_value, remap.inputs[2].default_value = -0.2, 1.0
    links.new(dirs.outputs["Z"], remap.inputs[0])
    ramp = nodes.new("ShaderNodeValToRGB")
    els = ramp.color_ramp.elements
    stops = d["sky"]
    while len(els) < len(stops):
        els.new(0.5)
    for el, (e, code) in zip(els, stops):
        el.position = (e + 0.2) / 1.2
        el.color = (*srgb(code), 1)
    links.new(remap.outputs[0], ramp.inputs[0])
    colour = ramp.outputs["Color"]
    if "sky_away" in d:  # the afterglow at one end only
        away = nodes.new("ShaderNodeValToRGB")
        els = away.color_ramp.elements
        stops = d["sky_away"]
        while len(els) < len(stops):
            els.new(0.5)
        for el, (e, code) in zip(els, stops):
            el.position = (e + 0.2) / 1.2
            el.color = (*srgb(code), 1)
        links.new(remap.outputs[0], away.inputs[0])
        a = math.radians(d["glow_az"])
        dot = nodes.new("ShaderNodeVectorMath")
        dot.operation = "DOT_PRODUCT"
        dot.inputs[1].default_value = (math.sin(a), math.cos(a), 0.0)
        links.new(norm.outputs[0], dot.inputs[0])
        side = nodes.new("ShaderNodeMapRange")
        side.inputs[1].default_value, side.inputs[2].default_value = -0.2, 0.9
        links.new(dot.outputs["Value"], side.inputs[0])
        both = nodes.new("ShaderNodeMix")
        both.data_type = "RGBA"
        links.new(side.outputs[0], both.inputs[0])
        links.new(away.outputs["Color"], both.inputs[6])
        links.new(colour, both.inputs[7])
        colour = both.outputs[2]
    # clouds: long bands of noise, squashed in elevation, lit on top and dark under
    lit, dark, low, high, cover = d["clouds"]
    scale = nodes.new("ShaderNodeVectorMath")
    scale.operation = "MULTIPLY"
    scale.inputs[1].default_value = (1.2, 1.2, 9.0)
    links.new(norm.outputs[0], scale.inputs[0])
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 2.2
    noise.inputs["Detail"].default_value = 3.0
    links.new(scale.outputs[0], noise.inputs["Vector"])
    shape = nodes.new("ShaderNodeValToRGB")
    shape.color_ramp.elements[0].position, shape.color_ramp.elements[1].position = cover, cover + 0.06
    links.new(noise.outputs["Fac"], shape.inputs[0])
    band = nodes.new("ShaderNodeMapRange")  # only between low and high elevations
    band.inputs[1].default_value, band.inputs[2].default_value = low, high
    links.new(dirs.outputs["Z"], band.inputs[0])
    ping = nodes.new("ShaderNodeMath")
    ping.operation = "PINGPONG"
    ping.inputs[1].default_value = 0.5
    links.new(band.outputs[0], ping.inputs[0])
    win = nodes.new("ShaderNodeMath")
    win.operation, win.inputs[1].default_value = "MULTIPLY", 2.0
    links.new(ping.outputs[0], win.inputs[0])
    amount = nodes.new("ShaderNodeMath")
    amount.operation = "MULTIPLY"
    links.new(shape.outputs["Color"], amount.inputs[0])
    links.new(win.outputs[0], amount.inputs[1])
    shade = nodes.new("ShaderNodeMix")
    shade.data_type = "RGBA"
    shade.inputs[6].default_value = (*srgb(dark), 1)
    shade.inputs[7].default_value = (*srgb(lit), 1)
    links.new(noise.outputs["Fac"], shade.inputs[0])
    cloud = nodes.new("ShaderNodeMix")
    cloud.data_type = "RGBA"
    links.new(amount.outputs[0], cloud.inputs[0])
    links.new(colour, cloud.inputs[6])
    links.new(shade.outputs[2], cloud.inputs[7])
    colour = cloud.outputs[2]
    if d["stars"]:
        vor = nodes.new("ShaderNodeTexVoronoi")
        vor.inputs["Scale"].default_value = 90.0
        links.new(norm.outputs[0], vor.inputs["Vector"])
        pin = nodes.new("ShaderNodeMath")
        pin.operation, pin.inputs[1].default_value = "LESS_THAN", 0.035
        links.new(vor.outputs["Distance"], pin.inputs[0])
        high_only = nodes.new("ShaderNodeMath")
        high_only.operation = "MULTIPLY"
        above = nodes.new("ShaderNodeMath")
        above.operation, above.inputs[1].default_value = "GREATER_THAN", 0.18
        links.new(dirs.outputs["Z"], above.inputs[0])
        links.new(pin.outputs[0], high_only.inputs[0])
        links.new(above.outputs[0], high_only.inputs[1])
        star = nodes.new("ShaderNodeMix")
        star.data_type = "RGBA"
        star.inputs[7].default_value = (0.9, 0.95, 1.0, 1)
        f = nodes.new("ShaderNodeMath")
        f.operation, f.inputs[1].default_value = "MULTIPLY", d["stars"]
        links.new(high_only.outputs[0], f.inputs[0])
        links.new(f.outputs[0], star.inputs[0])
        links.new(colour, star.inputs[6])
        colour = star.outputs[2]
    if d["moon"]:
        (az, el), radius, code = d["moon"]
        a, e = math.radians(az), math.radians(el)
        towards = (math.sin(a) * math.cos(e), math.cos(a) * math.cos(e), math.sin(e))
        dot = nodes.new("ShaderNodeVectorMath")
        dot.operation = "DOT_PRODUCT"
        dot.inputs[1].default_value = towards
        links.new(norm.outputs[0], dot.inputs[0])
        disc = nodes.new("ShaderNodeMapRange")
        disc.inputs[1].default_value, disc.inputs[2].default_value = math.cos(radius), math.cos(radius * 0.96)
        links.new(dot.outputs["Value"], disc.inputs[0])
        moon = nodes.new("ShaderNodeMix")
        moon.data_type = "RGBA"
        moon.inputs[7].default_value = (*[v * 2.2 for v in srgb(code)], 1)
        links.new(disc.outputs[0], moon.inputs[0])
        links.new(colour, moon.inputs[6])
        colour = moon.outputs[2]
    seen = nodes.new("ShaderNodeBackground")
    links.new(colour, seen.inputs["Color"])
    fill = nodes.new("ShaderNodeBackground")
    fill.inputs["Color"].default_value = (*srgb(d["ambient"][0]), 1)
    fill.inputs["Strength"].default_value = d["ambient"][1]
    path = nodes.new("ShaderNodeLightPath")
    mix = nodes.new("ShaderNodeMixShader")
    links.new(path.outputs["Is Camera Ray"], mix.inputs[0])
    links.new(fill.outputs[0], mix.inputs[1])
    links.new(seen.outputs[0], mix.inputs[2])
    links.new(mix.outputs[0], out.inputs["Surface"])


def sun(scene, d):
    """The one directional light (Lighting's sun or moon): from `azimuth` degrees off the street's far end."""
    az, el, code, strength, shadow = d["sun"]
    data = bpy.data.lights.new("Sun", "SUN")
    data.energy, data.color, data.angle = strength, srgb(code), math.radians(3.0)
    data.use_shadow = shadow
    obj = bpy.data.objects.new("Sun", data)
    a, e = math.radians(az), math.radians(el)
    towards = Vector((math.sin(a) * math.cos(e), math.cos(a) * math.cos(e), math.sin(e)))
    obj.rotation_euler = (-towards).to_track_quat("-Z", "Y").to_euler()
    scene.collection.objects.link(obj)


# --- the fighters ----------------------------------------------------------------------------------------------------

def fighter_material(name, folder, maps, tint, strength):
    """The delivered maps as Roblox draws them: the colour, its roughness and metalness, and the glow, which Roblox
    multiplies by the colour map ((mask x strength x tint + light) x colour). Eevee's glow is scaled to sit where the
    sheets' did; the shape of it is what counts here."""
    mat, p = _new(name)
    nodes, links = mat.node_tree.nodes, mat.node_tree.links

    def image(file, data):
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(str(folder / file), check_existing=True)
        if data:
            tex.image.colorspace_settings.name = "Non-Color"
        return tex

    colour = image(maps["Color"], False)
    links.new(colour.outputs["Color"], p.inputs["Base Color"])
    if "Roughness" in maps:
        links.new(image(maps["Roughness"], True).outputs["Color"], p.inputs["Roughness"])
    if "Metalness" in maps:
        links.new(image(maps["Metalness"], True).outputs["Color"], p.inputs["Metallic"])
    glow = image(maps["Emissive"], True)
    m1 = nodes.new("ShaderNodeMix")
    m1.data_type, m1.blend_type = "RGBA", "MULTIPLY"
    m1.inputs[0].default_value = 1.0
    links.new(colour.outputs["Color"], m1.inputs[6])
    m1.inputs[7].default_value = (*srgb(tint), 1)
    m2 = nodes.new("ShaderNodeMix")
    m2.data_type, m2.blend_type = "RGBA", "MULTIPLY"
    m2.inputs[0].default_value = 1.0
    links.new(m1.outputs[2], m2.inputs[6])
    links.new(glow.outputs["Color"], m2.inputs[7])
    links.new(m2.outputs[2], p.inputs["Emission Color"])
    p.inputs["Emission Strength"].default_value = strength
    _fogged(mat, p.outputs[0])
    return mat


def dress(objs, mat):
    for obj in objs:
        obj.data.materials.clear()
        obj.data.materials.append(mat)


def fighters():
    """Rook and two Shades, posed from their own clips at FRAME, and the player's avatar, a plain grey R6. Returns
    {name: rig}, the costume objects of the three fighters, and every object the avatar is made of."""
    scene, rook, costume, undress, feet = rc.build()
    take = rc.Take(rook, feet, "Haymaker", 0)
    rc.haymaker(take)
    rc.ground(rook, feet, [take])
    rook_recipe = json.loads((ROOK / "Rook.recipe.json").read_text())
    dress(costume.values(), fighter_material("RookSkin", ROOK, rook_recipe["maps"], rook_recipe["emissive"]["tint"],
                                             rook_recipe["emissive"]["hot"] * 0.12))
    real_reset, real_stage = bl.reset_scene, r6.stage
    bl.reset_scene = lambda: bpy.context.scene
    r6.stage = lambda *a, **k: None
    shades, worn = [], []
    shade_recipe = json.loads((SHADE / "Shade.recipe.json").read_text())
    emissive = shade_recipe["emissive"]
    try:
        for n, (clip, start) in enumerate(((sc.hit, HIT_START), (sc.attack, ATTACK_START))):
            before = set(bpy.data.objects)
            _, rig, _, wear, f = sc.build("Strength")
            wear("Brawler")
            t = sc.Take(rig, f, clip.__name__.title(), start)
            clip(t)
            rc.ground(rig, f, [t])
            made = [o for o in bpy.data.objects if o not in before]
            body = [o for o in made if o.name in {p["name"] for p in shade_recipe["pieces"]}]
            masks = [o for o in made if o.name in {p["name"] for p in shade_recipe["masks"].values()}]
            dress(body, fighter_material(f"ShadeBody{n}", SHADE, shade_recipe["maps"], emissive["tints"]["Strength"],
                                         emissive["strength"] * 0.06))
            dress(masks, fighter_material(f"ShadeMask{n}", SHADE, shade_recipe["maps"], emissive["mask_tint"],
                                          emissive["mask_strength"] * 0.06))
            worn += [o for o in body + masks if not o.hide_render]
            for o in made:  # out of the next build's way: it looks its pieces up by their own names
                o.name = f"S{n}" + o.name[len("Shade"):] if o.name.startswith("Shade") else o.name
            shades.append(rig)
    finally:
        bl.reset_scene, r6.stage = real_reset, real_stage
    grey = (0.64, 0.64, 0.65)
    before = set(bpy.data.objects)
    avatar = r6.build_rig("Avatar", {"Torso": (0.42, 0.45, 0.52), "Head": (0.85, 0.80, 0.70), "Right Arm": grey,
                                     "Left Arm": grey, "Right Leg": (0.30, 0.33, 0.40), "Left Leg": (0.30, 0.33, 0.40),
                                     "Face": (0.1, 0.1, 0.12)})
    avatar_objs = [o for o in bpy.data.objects if o not in before]
    for part, codes in (("Torso", ("#6E7486", "#4E5466")), ("Head", ("#D9CDB8", "#B8AC98")), ("Right Arm", ("#A6A6AA", "#808086")),
                        ("Left Arm", ("#A6A6AA", "#808086")), ("Right Leg", ("#4E5466", "#3A3F4E")), ("Left Leg", ("#4E5466", "#3A3F4E"))):
        dress([avatar.parts[part]], painted(f"Avatar{part}", *codes))
    face = next(o for o in avatar_objs if o.name.endswith(".Face"))
    dress([face], painted("AvatarFace", "#1E1E24", "#1E1E24"))
    for name in ("Floor", "Floor.001", "Floor.002"):
        if name in bpy.data.objects:
            bpy.data.objects.remove(bpy.data.objects[name], do_unlink=True)
    return scene, {"Rook": rook, "Shade1": shades[0], "Shade2": shades[1], "Avatar": avatar}, \
        [o for o in costume.values()] + worn, avatar_objs


FAR = 380.0  # studs up the street the far-end view stands, looking back at the gate


def stage_them(rigs, far=False):
    """Where the game puts them (Config.Combat.Replay and Lead), in Roblox studs. `far`: the same staging turned round
    at the street's far end, the player walking back toward the gate. Returns the eye, the camera's look, the places."""
    replay = r6.luau_table(COMBAT, "Replay = {")
    lead = r6.luau_table(COMBAT, "Lead = {")
    dummy = Vector((0.0, 0.0, -replay["Behind"]))
    avatar = Vector((-lead["Side"], 0.0, 0.0))
    a = math.radians(lead["Frame"])
    beyond = Vector((math.sin(a), 0.0, -math.cos(a)))
    rook = dummy + beyond * STRIKE_GAP
    slot = -math.radians(r6.luau_table(COMBAT, "Slots = {")["Spacing"])
    toward = (dummy - rook).normalized()  # the struck Shade's slot round Rook; the other stands one slot round, camera side
    turned = Vector((toward.x * math.cos(slot) - toward.z * math.sin(slot), 0.0,
                     toward.x * math.sin(slot) + toward.z * math.cos(slot)))
    other = rook + turned * STRIKE_GAP
    y = r6rig.ROOT_HEIGHT
    up = Vector((0, y, 0))
    focus = avatar + Vector((0, y + FOCUS, 0))
    p = math.radians(replay["Pitch"])
    eye = focus + Vector((0, math.sin(p) * ZOOM, math.cos(p) * ZOOM))
    look = Vector((0, -math.sin(p), -math.cos(p)))

    def turn(v, point=True):
        return Vector((-v.x, v.y, -v.z - (FAR if point else 0.0))) if far else Vector(v)

    dummy, avatar, rook, other, eye = (turn(v) for v in (dummy, avatar, rook, other, eye))
    r6.place_root(rigs["Avatar"], 0, avatar + up, turn(Vector((0, 0, -1)), False))
    r6.place_root(rigs["Shade1"], 0, dummy + up, (rook - dummy).normalized())
    r6.place_root(rigs["Rook"], 0, rook + up, (dummy - rook).normalized())
    r6.place_root(rigs["Shade2"], 0, other + up, (rook - other).normalized())
    return eye, turn(look, False), {"dummy": dummy, "rook": rook, "other": other, "avatar": avatar, "pitch": replay["Pitch"]}


# --- the picture: bloom and the tone curve -----------------------------------------------------------------------------

def blur(channel, sigma):
    """A Gaussian blur, padded with its edge first: the FFT's blur is circular, and unpadded a bright thing at the
    frame's top bled into its foot (AR17's crossing, 2026-11-16)."""
    pad = int(math.ceil(3 * sigma))
    padded = np.pad(channel, pad, mode="edge")
    h, w = padded.shape
    fy, fx = np.fft.fftfreq(h)[:, None], np.fft.rfftfreq(w)[None, :]
    kernel = np.exp(-2 * (math.pi * sigma) ** 2 * (fx ** 2 + fy ** 2))
    return np.fft.irfft2(np.fft.rfft2(padded) * kernel, s=(h, w))[pad:-pad, pad:-pad]


def finish(linear, d):
    """Bloom on what's past the threshold (two sizes, like Roblox's Bloom with its Size), then a filmic tone curve and
    sRGB. The same for every direction, so they compare."""
    threshold, intensity, sigmas = d["bloom"]
    rgb = linear[..., :3] * d["exposure"]
    lum = rgb @ np.array([0.2126, 0.7152, 0.0722], np.float32)
    over = rgb * (np.clip(lum - threshold, 0, None) / np.maximum(lum, 1e-4))[..., None]
    glow = np.zeros_like(rgb)
    for sigma in sigmas:
        for ch in range(3):
            glow[..., ch] += blur(over[..., ch], sigma) * 0.5
    rgb = rgb + intensity * glow
    x = rgb
    mapped = np.clip((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0, 1)
    encoded = np.where(mapped <= 0.0031308, mapped * 12.92, 1.055 * np.power(mapped, 1 / 2.4) - 0.055)
    out = np.empty_like(linear)
    out[..., :3], out[..., 3] = encoded, linear[..., 3]
    return out


def render_linear(scene, path: Path) -> np.ndarray:
    r = scene.render
    r.image_settings.file_format = "OPEN_EXR"
    r.image_settings.color_depth = "32"
    r.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    image = bpy.data.images.load(str(path))
    w, h = image.size
    data = np.empty(w * h * 4, dtype=np.float32)
    image.pixels.foreach_get(data)
    bpy.data.images.remove(image)
    return data.reshape(h, w, 4)[::-1].copy()


# --- measures --------------------------------------------------------------------------------------------------------

def value(rgba):
    return rgba[..., :3] @ np.array([0.2126, 0.7152, 0.0722], np.float32)


def grow(mask, n):
    out = mask.copy()
    for _ in range(n):
        m = out.copy()
        m[1:] |= out[:-1]; m[:-1] |= out[1:]; m[:, 1:] |= out[:, :-1]; m[:, :-1] |= out[:, 1:]
        out = m
    return out


def measures(frame, cut, mask_ids):
    """Value and edge: the fighters' own value against the street round them, how much of the frame outshines them,
    and the step in value across their outline; each fighter's height on the screen."""
    v = value(frame)
    body = cut[..., 3] > 0.5
    ring = grow(body, 14) & ~body
    inner = body & ~grow(~body, 2)
    edge_out = grow(body, 3) & ~body
    q = float(np.percentile(v[body], 75))
    result = {
        "fighters_median": round(float(np.median(v[body])), 3),
        "fighters_p75": round(q, 3),
        "around_median": round(float(np.median(v[ring])), 3),
        "frame_median": round(float(np.median(v[~body])), 3),
        "brighter_than_fighters_p75": round(float((v[~body] > q).mean()), 3),
        "edge_step": round(float(abs(np.median(v[inner & grow(edge_out, 3)]) - np.median(v[edge_out]))), 3),
    }
    seen = {"Rook": mask_ids["Rook"] & ~mask_ids["Shades"] & body, "Shades": mask_ids["Shades"] & body}
    for name, ids in mask_ids.items():
        rows = np.where(ids.any(axis=1))[0]
        if len(rows):
            result[f"{name}_screen_height"] = round(float((rows[-1] - rows[0] + 1) / frame.shape[0]), 3)
        mine = seen[name]
        if mine.any():
            ring_n = grow(mine, 14) & ~body
            result[f"{name}_median"] = round(float(np.median(v[mine])), 3)
            result[f"{name}_p90"] = round(float(np.percentile(v[mine], 90)), 3)
            result[f"{name}_around"] = round(float(np.median(v[ring_n])), 3)
            rim = mine & grow(~mine, 3)                   # its own outline, inside
            floor = grow(mine, 4) & ~body                 # and what lies just outside it: the floor behind
            if rim.any() and floor.any():
                result[f"{name}_edge"] = round(float(abs(np.median(v[rim]) - np.median(v[floor]))), 3)
    if result.get("Rook_around"):
        result["lead_over_around"] = round(result["Rook_median"] / result["Rook_around"], 2)
        lead_q = float(np.percentile(v[seen["Rook"]], 75))   # the Shades are dark by design: the lead's own top quarter
        result["lead_p75"] = round(lead_q, 3)
        result["brighter_than_lead_p75"] = round(float((v[~body] > lead_q).mean()), 3)
    return result


def cost(kit, eye, reach=220.0):
    """What a phone draws from here: the pieces (each a Part or MeshPart) and triangles within `reach` studs of the
    camera, outline shells included, and the lights."""
    dg = bpy.context.evaluated_depsgraph_get()
    eye_b = r6.point_to_blender(eye)
    parts = tris = shells = 0
    for obj in kit.pieces:
        if (obj.matrix_world.translation - eye_b).length > reach and obj.name not in ("Street", "Under"):
            continue
        ev = obj.evaluated_get(dg)
        mesh = ev.to_mesh()
        mesh.calc_loop_triangles()
        tris += len(mesh.loop_triangles)
        ev.to_mesh_clear()
        parts += 1
        shells += any(m.type == "SOLIDIFY" for m in obj.modifiers)
    return {"reach_studs": reach, "parts": parts, "outline_shells": shells, "triangles": tris,
            "point_lights": len(kit.lights)}


# --- a direction -----------------------------------------------------------------------------------------------------

def hit_square(scene, rigs, places):
    """Haymaker's Strike square (Config.Effects.Haymaker: Strike's Side and Bar, Ahead of the knuckles), four bars across
    the line of the blow. The game draws it unlit and casts no light with it: here it glows and the bloom does the rest."""
    strike = r6.luau_table("src/shared/Config/Effects.luau", "Strike = {")
    ahead = r6.luau_number("src/shared/Config/Effects.luau", "Ahead")
    side, bar = strike["Side"], strike["Bar"]
    knuckles = rigs["Rook"].parts["Right Arm"].matrix_world @ Vector(hx.KNUCKLES)
    line = (r6.point_to_blender(places["dummy"]) - r6.point_to_blender(places["rook"])).normalized()
    centre = knuckles + line * ahead
    across = line.cross(Vector((0, 0, 1))).normalized()
    mat = glowing("HaymakerHot", "#FFB24A", 9.0)
    turn = line.to_track_quat("Y", "Z").to_euler()
    made = []
    for i, (dx, dz, w, h) in enumerate(((0, side / 2, side + bar * 0.3, bar * 0.3), (0, -side / 2, side + bar * 0.3, bar * 0.3),
                                        (side / 2, 0, bar * 0.3, side), (-side / 2, 0, bar * 0.3, side))):
        obj = bl.box(f"Square{i}", (w, 0.06, h), mat)
        obj.location = centre + across * dx + Vector((0, 0, dz))
        obj.rotation_euler = turn
        made.append(obj)
    return made


def direction(out: Path, key: str, fast: bool, far=False, hit=False):
    d = DIRECTIONS[key]
    tag = key + ("_far" if far else "") + ("_hit" if hit else "")
    FOG.update(colour=srgb(d["fog"][0]), density=d["fog"][1], azimuth=d.get("glow_az", 0.0),
               away=srgb(d["fog_away"]) if "fog_away" in d else None)
    scene, rigs, worn, avatar_objs = fighters()
    eye, look, places = stage_them(rigs, far)
    scene.frame_set(FRAME - 1 if hit else FRAME)
    bpy.context.view_layer.update()
    extra = hit_square(scene, rigs, places) if hit else []
    images = glyph_images(out)
    kit = street(scene, d, images, near=FAR if far else 0.0)
    sky(scene, d)
    sun(scene, d)
    if d["fighter_light"]:
        code, power, reach = d["fighter_light"]
        ahead = d.get("fighter_light_ahead")
        if ahead:
            root, target = r6.point_to_blender(places["rook"]), r6.point_to_blender(places["dummy"])
            light(kit, scene, "LeadLight", root + (target - root).normalized() * ahead[0] + Vector((0, 0, ahead[1])), code, power, reach)
        else:
            for name in ("Rook", "Shade1", "Shade2"):
                root = r6.point_to_blender(places[{"Rook": "rook", "Shade1": "dummy", "Shade2": "other"}[name]])
                light(kit, scene, f"Over{name}", root + Vector((0, -2.0, 7.0)), code, power, reach)
    camera = r6.fixed_camera(scene, eye, eye + look * 10, FOV, "Player")
    scene.camera = camera
    camera.data.clip_end = 2000
    r = scene.render
    for engine in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            r.engine = engine
            break
        except TypeError:
            continue
    r.resolution_x, r.resolution_y, r.resolution_percentage = *SIZE, 100
    scene.view_settings.view_transform = "Standard"
    scene.eevee.taa_render_samples = 8 if fast else 48
    for attr, val in (("use_shadows", True), ("shadow_ray_count", 2), ("use_raytracing", False)):
        try:
            setattr(scene.eevee, attr, val)
        except AttributeError:
            pass
    linear = render_linear(scene, out / f"{tag}_frame.exr")
    frame = finish(linear, d)
    rs.save(frame, out / f"{tag}_frame.png")
    # the fighters alone: the street still lights and shades them, but the camera doesn't see it
    hide = kit.pieces + avatar_objs + extra
    for obj in hide:
        obj.visible_camera = False
    r.film_transparent = True
    ids = {}
    cut_linear = render_linear(scene, out / f"{tag}_fighters.exr")
    cut = finish(cut_linear, d)
    rs.save(cut, out / f"{tag}_fighters.png")
    # each fighter's own silhouette, for its height on the screen
    fighters_objs = {"Rook": [o for o in worn if o.name.startswith("Rook_")],
                     "Shades": [o for o in worn if not o.name.startswith("Rook_")]}
    for name, objs in fighters_objs.items():
        others = [o for o in worn if o not in objs]
        for o in others:
            o.visible_camera = False
        scene.eevee.taa_render_samples = 1
        alone = render_linear(scene, out / f"{tag}_{name}.exr")
        ids[name] = alone[..., 3] > 0.5
        for o in others:
            o.visible_camera = True
    result = {"direction": tag, "name": d["name"], "idea": d["idea"], "measures": measures(frame, cut, ids),
              "cost": cost(kit, eye), "frame": FRAME - 1 if hit else FRAME, "camera": {"eye": list(eye), "pitch": places["pitch"], "fov": FOV, "zoom": ZOOM},
              "fighter_tris": {"Rook": 7236, "Shade": 2444 + 2968}}
    (out / f"{tag}.json").write_text(json.dumps(result, indent=1))
    for name in (f"{tag}_frame.exr", f"{tag}_fighters.exr", f"{tag}_Rook.exr", f"{tag}_Shades.exr"):
        (out / name).unlink(missing_ok=True)
    print(json.dumps(result, indent=1))


# --- the sheet -------------------------------------------------------------------------------------------------------

def window(v, h, w, avoid):
    """The darkest and brightest h x w patch of a value picture, kept off the fighters' own place."""
    total = np.pad(np.cumsum(np.cumsum(v, 0), 1), ((1, 0), (1, 0)))
    sums = total[h:, w:] - total[:-h, w:] - total[h:, :-w] + total[:-h, :-w]
    ay, ax, ah, aw = avoid
    ys, xs = np.mgrid[0:sums.shape[0], 0:sums.shape[1]]
    overlap = (np.clip(np.minimum(ys + h, ay + ah) - np.maximum(ys, ay), 0, None) *
               np.clip(np.minimum(xs + w, ax + aw) - np.maximum(xs, ax), 0, None)) / (h * w)
    free = overlap < 0.2
    dark = np.unravel_index(np.argmin(np.where(free, sums, np.inf)), sums.shape)
    bright = np.unravel_index(np.argmax(np.where(free, sums, -np.inf)), sums.shape)
    return dark, bright


def corners(frame, cut):
    """The fighters, cut out as lit, over the frame's darkest and its brightest patch of their own size."""
    alpha = cut[..., 3] > 0.05
    rows, cols = np.where(alpha.any(1))[0], np.where(alpha.any(0))[0]
    y0, y1, x0, x1 = rows[0], rows[-1] + 1, cols[0], cols[-1] + 1
    pad_y, pad_x = (y1 - y0) // 6, (x1 - x0) // 6
    y0, y1 = max(0, y0 - pad_y), min(frame.shape[0], y1 + pad_y)
    x0, x1 = max(0, x0 - pad_x), min(frame.shape[1], x1 + pad_x)
    h, w = y1 - y0, x1 - x0
    piece = cut[y0:y1, x0:x1]
    v = value(frame).astype(np.float64)
    dark, bright = window(v, h, w, (y0, x0, h, w))
    shots = []
    for (yy, xx) in (dark, bright):
        patch = frame[yy:yy + h, xx:xx + w].copy()
        rs.paste(patch, piece, 0, 0)
        shots.append((patch, (int(yy), int(xx))))
    return shots, (int(y0), int(x0), int(h), int(w))


def sheet(out: Path):
    rs.OUT = out  # text_layer renders its words there
    W, H = 1640, 2060
    page = rs.canvas(W, H, (0.075, 0.07, 0.085))
    ink, soft = "#F2ECE2", "#B9B2C4"
    text = [(24, 18, 26, "Lantern Row's look: three directions from the player's camera (AR5, section 1). Rough blocks, no finish.", ink),
            (24, 54, 15, "Rook at Haymaker's Shock, a Shade struck, a Shade winding up; the avatar in front. Camera: 12.5 studs, 20 degrees down, FOV 70 "
                         "(Config.Combat.Replay, Lead). Eevee in linear light, then one bloom and one tone curve for all three.", soft)]
    y = 92
    for key in ("A", "B", "C"):
        facts = json.loads((out / f"{key}.json").read_text())
        frame = rs.load(out / f"{key}_frame.png")
        cut = rs.load(out / f"{key}_fighters.png")
        m, c = facts["measures"], facts["cost"]
        text.append((24, y, 22, f"{key}. {facts['name']}: {facts['idea']}", ink))
        rs.paste(page, frame, 24, y + 34)
        phone = rs.shrink(frame, 0.5)
        x = 24 + 960 + 24
        rs.paste(page, phone, x, y + 34)
        text.append((x, y + 34 + 274, 13, "about a phone's size on a desktop screen (480 x 270)", soft))
        shots, _ = corners(frame, cut)
        small = []
        for patch, _ in shots:
            k = min(190 / patch.shape[1], 150 / patch.shape[0])
            small.append(rs.shrink(patch, k))
        grey = rs.grey(rs.shrink(frame, 0.2))
        rs.paste(page, grey, x, y + 330)
        text.append((x, y + 330 + 112, 12, "value", soft))
        rs.paste(page, small[0], x + 205, y + 330)
        text.append((x + 205, y + 330 + small[0].shape[0] + 4, 12, "over its darkest", soft))
        rs.paste(page, small[1], x + 205 + small[0].shape[1] + 12, y + 330)
        text.append((x + 205 + small[0].shape[1] + 12, y + 330 + small[1].shape[0] + 4, 12, "over its brightest", soft))
        line = (f"Value (0 black, 1 white): Rook {m['Rook_median']:.2f}, his top tenth {m['Rook_p90']:.2f}, against {m['Rook_around']:.2f} round him; "
                f"the Shades {m['Shades_median']:.2f} against {m['Shades_around']:.2f}; {100 * m['brighter_than_fighters_p75']:.0f}% of the frame "
                f"outshines the fighters' top quarter; their edge steps {m['edge_step']:.2f}. Rook stands {100 * m.get('Rook_screen_height', 0):.0f}% of the screen.")
        text.append((24, y + 34 + 548, 14, line, soft))
        text.append((24, y + 34 + 570, 14, f"Cost within {c['reach_studs']:.0f} studs: {c['parts']} pieces ({c['outline_shells']} with an outline shell), "
                                           f"{c['triangles']:,} triangles, {c['point_lights']} PointLights; the fighters add 7,236 (Rook) and 5,412 a Shade.", soft))
        y += 34 + 548 + 70
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out / "lantern_row_look.png")


TARGETS = {"lead": 1.3, "outshine": 0.10, "edge": 0.15}  # research's, at round 1's verdict (AR5 section 1)


def against_targets(m):
    """One frame's measures in words, against research's three targets."""
    holds = lambda ok: "holds" if ok else "short"
    return (f"The lead {m['lead_over_around']:.2f}x what's round him ({m['Rook_median']:.2f} against {m['Rook_around']:.2f}; target 1.3x): "
            f"{holds(m['lead_over_around'] >= TARGETS['lead'])}.  A Shade's edge against the floor {m['Shades_edge']:.2f} (target 0.15): "
            f"{holds(m['Shades_edge'] >= TARGETS['edge'])}.  Of the frame, {100 * m['brighter_than_lead_p75']:.0f}% outshines the lead's top quarter, "
            f"{100 * m['brighter_than_fighters_p75']:.0f}% the three fighters' (target 10%).")


def sheet2(out: Path):
    """Round 2: the merge from the gate, from the far end and with a hit's light; round 1's three beside it for the
    director's pick; the redrawn script."""
    rs.OUT = out
    W, H = 1640, 2256
    page = rs.canvas(W, H, (0.075, 0.07, 0.085))
    ink, soft = "#F2ECE2", "#B9B2C4"
    facts = {tag: json.loads((out / f"{tag}.json").read_text()) for tag in ("M", "M_far", "M_hit", "A", "B", "C")}
    d = DIRECTIONS["M"]
    text = [(24, 18, 26, "Lantern Row's look, round 2: the merge, from both ends and with a hit in it (AR5, section 1). Rough blocks, no finish.", ink),
            (24, 54, 15, "The same fight and camera as round 1 (Rook at Haymaker's Shock, a Shade struck, a Shade winding up; 12.5 studs, 20 degrees down, "
                         "FOV 70). The pick is among A, B, C and the merge.", soft)]
    y = 92
    frame, cut = rs.load(out / "M_frame.png"), rs.load(out / "M_fighters.png")
    m, c = facts["M"]["measures"], facts["M"]["cost"]
    text.append((24, y, 22, f"M. {d['name']}: {d['idea']}", ink))
    rs.paste(page, frame, 24, y + 34)
    x = 24 + 960 + 24
    rs.paste(page, rs.shrink(frame, 0.5), x, y + 34)
    text.append((x, y + 34 + 274, 13, "about a phone's size on a desktop screen (480 x 270)", soft))
    shots, _ = corners(frame, cut)
    small = [rs.shrink(patch, min(190 / patch.shape[1], 150 / patch.shape[0])) for patch, _ in shots]
    rs.paste(page, rs.grey(rs.shrink(frame, 0.2)), x, y + 330)
    text.append((x, y + 330 + 112, 12, "value", soft))
    rs.paste(page, small[0], x + 205, y + 330)
    text.append((x + 205, y + 330 + small[0].shape[0] + 4, 12, "over its darkest", soft))
    rs.paste(page, small[1], x + 205 + small[0].shape[1] + 12, y + 330)
    text.append((x + 205 + small[0].shape[1] + 12, y + 330 + small[1].shape[0] + 4, 12, "over its brightest", soft))
    text.append((24, y + 34 + 548, 14, against_targets(m), soft))
    text.append((24, y + 34 + 570, 14, f"Cost within {c['reach_studs']:.0f} studs: {c['parts']} pieces ({c['outline_shells']} with an outline shell), "
                                       f"{c['triangles']:,} triangles, {c['point_lights']} lights (one SpotLight a string, one PointLight carried by the lead).", soft))
    text.append((24, y + 34 + 592, 14, "Wrong in it: the Shades stand between the camera and the lead and hide half of him; they are lit by nothing of their own, "
                                       "so two of the three fighters are dark shapes; the stalls have no light of their own yet.", soft))
    y += 34 + 548 + 92
    k = 788 / 960
    for i, (tag, title) in enumerate((("M_far", "The same fight from the street's far end, looking back at the gate"),
                                      ("M_hit", "One frame earlier, Haymaker's Strike: the hit's square at the knuckles (unlit, no light cast; the bloom is the glow)"))):
        fx = 24 + i * (788 + 16)
        text.append((fx, y, 16, title, ink))
        rs.paste(page, rs.shrink(rs.load(out / f"{tag}_frame.png"), k), fx, y + 26)
        mm = facts[tag]["measures"]
        text.append((fx, y + 26 + 448, 13, f"Lead {mm['lead_over_around']:.2f}x what's round him; a Shade's edge {mm['Shades_edge']:.2f}"
                                           f"{'' if mm['Shades_edge'] >= TARGETS['edge'] else ' (short of 0.15)'}; "
                                           f"{100 * mm['brighter_than_lead_p75']:.0f}% of the frame outshines the lead's top quarter.", soft))
    text.append((24, y + 26 + 468, 13, "Wrong in them: from the far end there's no afterglow, the stalls sink near black and it reads closer to night than to blue hour; "
                                       "the struck Shade hides half of the hit's square from this camera.", soft))
    y += 26 + 468 + 38
    text.append((24, y, 16, "Round 1's three, as they were, for the pick", ink))
    k = 520 / 960
    for i, key in enumerate(("A", "B", "C")):
        fx = 24 + i * (520 + 16)
        rs.paste(page, rs.shrink(rs.load(out / f"{key}_frame.png"), k), fx, y + 26)
        mm = facts[key]["measures"]
        text.append((fx, y + 26 + 296, 13, f"{key}. {facts[key]['name']}: lead {mm['Rook_median'] / mm['Rook_around']:.2f}x what's round him; "
                                           f"{100 * mm['brighter_than_fighters_p75']:.0f}% outshines the fighters.", soft))
    y += 26 + 296 + 36
    text.append((24, y, 16, "The script, redrawn: a sprig of flame over a small cup, every letter on a diagonal. Large; at a sign's sizes from the street "
                            "(32, 16 and 10 px), dark on cloth and pale on a curtain; then the 16 px tiles five times their size.", ink))
    rs.paste(page, rs.load(out / SCRIPT_SHEET), 24, y + 28)
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out / "lantern_row_look_round2.png")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    if args and args[0] == "sheet":
        sheet(out)
        return
    if args and args[0] == "sheet2":
        sheet2(out)
        return
    if args and args[0] == "glyphs":
        glyph_images(out)
        glyph_preview(out, int(args[1]) if len(args) > 1 else None)
        return
    direction(out, args[0] if args else "A", "fast" in args, "far" in args, "hit" in args)


if __name__ == "__main__":
    main()
