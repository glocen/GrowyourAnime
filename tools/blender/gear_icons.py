"""AR6, the finish: each kind's fifteen designs in colour, as flat pictures for the gear slots, with the gear frame's
own images (docs/asset-requests.md, AR6, "Colour and frames"). Batch 1 is the Sword, the Short Sword, the Ring and the
Helmet; batch 2 the eight shared kinds.

Pictures only (the director, 2026-11-15: "it should only be 2D cuz gears dont have any visuals on the voidkins it just
for the gears slot images!"): a model here is how a picture is drawn, and nothing but images leaves this script.

The forms are the grey sheets' own (gear_<kind>_sets.py, batch 2's on gear_parts.py): this script only paints them.
A material's key takes its colour from PAINT; a set's stone takes its set's tone; a lit part is warm white. Each design
is rendered twice in Workbench, once lit and once flat as a mask of what glows, and the two are finished here: a warm key from above, a light on the upper edge, the stone's and the edge's own light. Never
flames, a cloud or particles: the light lives in the stone and the edge.

Rarity in three layers (docs/research/gear-icons.md, DESIGN): the object's own material, the slot's light, the frame.
Common to Epic share the kit's button cut in the rarity's colour; Legendary's border is its own, with no crown (the
director, 2026-11-15): its two cuts become lit facets and a second rim of light runs inside.

    blender -b --factory-startup --python tools/blender/gear_icons.py -- build/handoff/UI/gear [kind ...]

A kind is sword, short, ring, helmet, shoulders, chest, gloves, bracers, boots, cloak, amulet, earring, frames, or look
(a few of each, for the look alone). With none, all of them.
Writes images/Gear<Name>.png (256 pixels, the object alone), GearLight.png and GearFrameLegendary.png, a sheet a
kind, and gear_icons.json. Workbench only: no GPU turn.
"""
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_amulet_sets as amulet  # noqa: E402
import gear_boots_sets as boots  # noqa: E402
import gear_bracers_sets as bracers  # noqa: E402
import gear_chest_sets as chest  # noqa: E402
import gear_cloak_sets as cloak  # noqa: E402
import gear_earring_sets as earring  # noqa: E402
import gear_gloves_sets as gloves  # noqa: E402
import gear_helmet_sets as h  # noqa: E402
import gear_parts as gp  # noqa: E402
import gear_ring_sets as r  # noqa: E402
import gear_shoulders_sets as shoulders  # noqa: E402
import gear_short_sword_sets as ss  # noqa: E402
import gear_sword_ladder as g  # noqa: E402
import gear_sword_sets as s  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_kit as kit  # noqa: E402
import ui_sheet as ui  # noqa: E402
from reveal_blockin import blur  # noqa: E402
from ui_sheet import c  # noqa: E402

SIZE = g.SIZE  # a render, in pixels
ICON = 256  # a delivered picture, in pixels
SLOT = 48.0  # the slot the frame's images are drawn for, in points
RARITIES = s.RARITIES

# A key's colour, how metal it is, how rough. Workbench darkens a metal's own colour, so the metals stay low and the
# finish adds the light. The lining is the kit's near-black, never a skin tone (the content check, 2026-11-15).
PAINT = dict(
    iron=("#626877", 0.35, 0.45), steel=("#D8DFE9", 0.3, 0.42), bronze=("#BC7C44", 0.35, 0.4), scrap=("#827A76", 0.3, 0.55),
    brass=("#DDA050", 0.35, 0.32), blued=("#C6CCD6", 0.3, 0.36), rich=("#C6CCD6", 0.3, 0.3), filigree=("#F0E9FA", 0.2, 0.3),
    gilt=("#FFBF45", 0.3, 0.26), ivory=("#F6EEDC", 0.0, 0.5), wood=("#875C3D", 0.0, 0.7), leather=("#4C382E", 0.0, 0.75),
    liner=("#0E0F13", 0.0, 0.9),
    # cloth, batch 2's own, never a metal's colour: a cloak is never painted as plate. Each agrees with its rarity's
    # metal: plain warm wool; a pale slate silk under brass; a dark slate dyed silk under filigree, blue only as blued
    # steel's temper is; a near-black violet velvet, as the gunmetal; a cream white under gilt. The object agrees with
    # its rarity and never wears its colour whole: the frame and the slot's light carry it (research, batch 1's
    # verdict, 2026-11-15).
    wool=("#7C7268", 0.0, 0.85), silk=("#8494A2", 0.0, 0.55), dyed=("#3E4C63", 0.0, 0.6), velvet=("#3E3450", 0.0, 0.7),
    white=("#EFE6D2", 0.0, 0.6),
    cloth=("#5E6070", 0.0, 0.8), cord=("#8C7052", 0.0, 0.8),
    # a glove's leather, a cool charcoal, never a brown that could read as a hand (content check, 2026-11-16)
    hide=("#34343C", 0.0, 0.6))
LIT = "#FFF6DC"  # a lit part: warm white, never red or dark
# A tempered metal is rendered as plain steel, and the finish gives it its own tones from shade to highlight (research,
# 2026-11-15: the frame and the slot's light carry the rarity, the object only agrees with it). Rare is steel first:
# its highlights steel-white, the blue a temper in its mid-tones. Epic is a near-black violet gunmetal: its colour is
# carried by its pale filigree and its glowing stone. Each: its tones by how bright the steel is, from shade to
# highlight, and how far the mid-tones are held down (over 1 keeps more of the metal dark).
TEMPER = dict(blued=(((0.0, "#10151F"), (0.2, "#2C456E"), (0.42, "#7688A6"), (0.7, "#C2CCDA"), (1.0, "#F4F7FB")), 1.0),
              rich=(((0.0, "#0D0B15"), (0.5, "#2E2642"), (0.8, "#6A5F86"), (1.0, "#D8D0EC")), 1.25))
# A set's word gives its stone its tone. Stormcall's is warm white and small; Gloamforge's is never yellow or gold
# beside its violet metal (the content check's conditions for this pass).
TONES = (("Embers", "#FF9E45"), ("Hoarfrost", "#BDEBFF"), ("Gales", "#7FE8C8"), ("Stormcall", "#FFF3D0"),
         ("Gloamforge", "#9FF2F0"), ("Nightloom", "#F0B8FF"))
# A rarity's rim and light in a gear slot: Common's grey, then the director's green, blue and purple, and gold.
RIM = dict(Common="#8A909C", Uncommon="#7CF0A0", Rare="#6FB6FF", Epic="#D29CFF", Legendary="#FFD777")
GLINT = "#FFF3C4"  # Legendary's border: its light
WELL, CHANNEL = "#0B0C10", "#07080B"
# Legendary's slot (research, 2026-11-15): a deep warm umber ground, the light kept to the centre, so gilt keeps its edge.
UMBER, LEGEND_LIGHT = ("#34200E", "#1A1007"), 0.72
NOW = dict(tone=LIT)  # the design being built


def tone(d):
    return next((code for word, code in TONES if word in d["name"]), LIT)


def mix(a, b, t):
    return c(a) * (1 - t) + c(b) * t


def hexed(rgb):
    return "#" + "".join(f"{round(float(v) * 255):02X}" for v in rgb)


def paint(key):
    if key == "stone":  # a set stone, cut and unlit: its tone, a little deeper
        return hexed(mix(NOW["tone"], "#000000", 0.12)), 0.1, 0.15
    if key == "glow":
        return hexed(mix(NOW["tone"], "#FFFFFF", 0.25)), 0.0, 0.2
    if key == "lit":
        return LIT, 0.0, 0.3
    return PAINT[key]


def building(make):
    """A kind's own builder, noting the design it builds so its stone takes its set's tone."""
    def built(d, *more):
        NOW["tone"] = tone(d)
        return make(d, *more)
    return built


# --- a picture ----------------------------------------------------------------------------------------------------------

def render(scene, out):
    scene.render.filepath = str(out / "_gear.png")
    bpy.ops.render.render(write_still=True)
    px = rs.load(out / "_gear.png")
    (out / "_gear.png").unlink()
    return px


def shoot(scene, out, centre, span):
    """The design lit, then flat as a mask of what glows (a lit part red, a glowing stone green), then finished."""
    cam = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
    scene.collection.objects.link(cam)
    scene.camera, cam.data.type, cam.data.ortho_scale, cam.data.clip_end = cam, "ORTHO", span, 200
    cam.location = (centre[0], -40, centre[1])
    cam.rotation_euler = (math.radians(90), 0, 0)
    rs.workbench(scene, SIZE, SIZE)
    shading = scene.display.shading
    shading.show_specular_highlight = True
    shading.cavity_ridge_factor, shading.cavity_valley_factor = 1.8, 1.3
    shading.curvature_ridge_factor, shading.curvature_valley_factor = 1.5, 1.2
    lit = render(scene, out)
    for m in bpy.data.materials:
        key = m.name[5:]
        m.diffuse_color = ((1, 0, 0, 1) if key == "lit" else (0, 1, 0, 1) if key == "glow" else
                           (0, 0, 1, 1) if key in TEMPER else (0, 0, 0, 1))
    metal = next((TEMPER[m.name[5:]] for m in bpy.data.materials if m.users and m.name[5:] in TEMPER), None)
    rs.workbench(scene, SIZE, SIZE, flat=True)
    mask = render(scene, out)
    if metal:
        lit = tempered(lit, mask[..., 2] * mask[..., 3], metal)
    return finish(lit, mask[..., 0] * mask[..., 3], mask[..., 1] * mask[..., 3], NOW["tone"])


def tempered(px, where, metal):
    """A tempered metal's own tones laid over its steel, by how bright the steel is. A design holds one tempered
    metal, never two."""
    stops, hold = metal
    grey = px[..., :3] @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)
    v = np.clip((grey - 0.2) / 0.72, 0, 1) ** hold
    at, tones = [s[0] for s in stops], np.array([c(s[1])[:3] for s in stops])
    tone = np.stack([np.interp(v, at, tones[:, i]) for i in range(3)], axis=-1).astype(np.float32)
    px = px.copy()
    px[..., :3] += (tone - px[..., :3]) * where[..., None]
    return px


def finish(px, lit, glow, stone):
    """What Workbench can't give: a warm key from above, a light on the upper left edge and a shade on the lower
    right, and the light of what's lit. `lit` and `glow` are masks, 0 to 1."""
    rgb, a = px[..., :3].copy(), px[..., 3]
    grey = rgb.mean(axis=-1, keepdims=True)
    rgb = np.clip(grey + (rgb - grey) * 1.18, 0, 1)  # a little more colour
    rgb = np.clip(rgb * 1.06, 0, 1) ** 0.94
    rgb = np.clip(0.5 + (rgb - 0.5) * 1.12, 0, 1)  # values a little further apart
    down = (np.arange(SIZE, dtype=np.float32)[:, None] / SIZE)[..., None]
    rgb = rgb * (1.1 - 0.22 * down) * (c("#FFF4E2") * (1 - down) + c("#F2EEF6") * down)  # warm above, cool below
    step = 4
    moved = np.roll(a, (step, step), axis=(0, 1))  # the shape, moved down and to the right
    back = np.roll(a, (-step, -step), axis=(0, 1))
    edge = blur(np.clip(a - moved, 0, 1), 1.5)[..., None]
    shade = blur(np.clip(a - back, 0, 1), 2.0)[..., None]
    rgb = rgb + (c("#FFF8E8") - rgb) * np.clip(edge * 0.55, 0, 1)
    rgb = rgb * (1 - 0.3 * shade)
    # what's lit: its own face near white, then its light round it, small
    rgb = rgb + (c("#FFFBEE") - rgb) * (0.85 * lit[..., None])
    rgb = rgb + (mix(stone, "#FFFFFF", 0.45) - rgb) * (0.4 * glow[..., None])
    out = np.empty_like(px)
    pm = np.clip(rgb, 0, 1) * a[..., None]
    for field, colour, near, far in ((lit, "#FFD777", (5, 0.95), (22, 0.5)), (glow, stone, (4, 0.6), (16, 0.3))):
        if field.max() < 0.01:
            continue
        halo = np.clip(blur(field, near[0]) * near[1] + blur(field, far[0]) * far[1], 0, 1)[..., None]
        pm = pm + c(colour) * halo * (1 - pm)
        a = a + halo[..., 0] * 0.85 * (1 - a)
    a = np.clip(a, 0, 1)
    out[..., :3] = np.where(a[..., None] > 1e-4, pm / np.maximum(a[..., None], 1e-4), 0)
    out[..., :3] = np.clip(out[..., :3], 0, 1)
    out[..., 3] = a
    return out


# --- the slot -----------------------------------------------------------------------------------------------------------

def light(t, x0, y0, side):
    """The slot's light: brightest a little above the middle, gone before the corners, so it needs no cutting."""
    v = np.hypot(((t.x - x0) / side - 0.5) * 1.15, (t.y - y0) / side - 0.46)
    return (np.clip(1 - v / 0.62, 0, 1) ** 1.3 * 0.62).astype(np.float32)


def border(t, x0, y0, side, z=1.0):
    """Legendary's border, over the slot: a gold rim, the two cuts as lit facets, a second rim of light inside. No
    crown and no studs (the director, 2026-11-15: "only the border need to change")."""
    rim, x1, y1 = RIM["Legendary"], x0 + side, y0 + side
    outer = t.poly(ui.cut_box(x0, y0, x1, y1, 8.0 * z, 0.0, 8.0 * z, 0.0))
    # its light outside only: inside, the slot keeps its own
    ui.over(t.px, c(rim), 0.3 * np.exp(-(np.maximum(outer, 0) / (3.0 * z)) ** 1.4) * np.clip(0.5 + outer * ui.K, 0, 1))
    t.line(outer, 2.0 * z, t.ramp(GLINT, rim, (t.y - y0) / side))
    inner = t.poly(ui.cut_box(x0 + 3.8 * z, y0 + 3.8 * z, x1 - 3.8 * z, y1 - 3.8 * z, 6.0 * z, 0.0, 6.0 * z, 0.0))
    t.line(inner, 0.9 * z, c(GLINT), 0.9)
    for p, q in (((x0, y0 + 8.0 * z), (x0 + 8.0 * z, y0)), ((x1, y1 - 8.0 * z), (x1 - 8.0 * z, y1))):
        facet = np.maximum(ui.sd_segment(t.x, t.y, p, q) - 2.8 * z, outer - 0.9 * z)
        t.glow(facet, 2.4 * z, c(rim), 0.6)
        t.paint(facet, c(GLINT))
        t.paint(np.maximum(ui.sd_segment(t.x, t.y, p, q) - 1.0 * z, outer - 0.9 * z), ui.WHITE)


def slot(sh, x, y, side, rarity, icon, z=1.0, mark=None):
    """A gear slot as the build lays it: the well, the rarity's tint and light, the rim, the picture, and on a weapon
    its class mark seated on the bottom cut. `z` enlarges the frame's own sizes for a close look."""
    pad = 10.0 * z
    t = sh.tile(x - pad, y - pad, side + 2 * pad, side + 2 * pad)
    box = t.poly(ui.cut_box(pad, pad, pad + side, pad + side, 8.0 * z, 0.0, 8.0 * z, 0.0))
    t.glow(box, 4.0 * z, ui.BLACK, 0.22)
    tint, strength = RIM[rarity], 0.8 if rarity == "Common" else 1.0
    inside = np.clip(0.5 - box * ui.K, 0, 1)
    if rarity == "Legendary":  # its own ground, and the light smaller round the same middle
        t.paint(box, t.ramp(*UMBER, (t.y - pad) / side))
        small = side * LEGEND_LIGHT
        glow = light(t, pad + (side - small) * 0.5, pad + (side - small) * 0.46, small)
    else:
        t.paint(box, t.ramp(WELL, CHANNEL, (t.y - pad) / side))
        ui.over(t.px, c(tint), inside * 0.14 * strength)
        glow = light(t, pad, pad, side)
    ui.over(t.px, mix(tint, "#FFFFFF", 0.2), inside * glow * strength)
    if rarity == "Legendary":
        border(t, pad, pad, side, z)
    else:
        t.line(box, 1.6 * z, c(tint))
    fit = 0.94  # the picture's square inside the rim
    small = rs.shrink(icon, side * fit * ui.K / icon.shape[0])
    o = round((side - side * fit) / 2 * ui.K)
    rs.paste(sh.px, small, round(x * ui.K) + o, round(y * ui.K) + o)
    if mark:  # the class mark in its dark seat, on the bottom cut
        m = 5.4 * z
        cx, cy = pad + side - 4.6 * z, pad + side - 4.6 * z
        seat = t.poly(ui.cut_box(cx - m, cy - m, cx + m, cy + m, 3.0 * z, 0, 3.0 * z, 0))
        t.paint(seat - 1.0 * z, c(ui.STROKE))
        t.paint(seat, c(kit.SEAT["well"]))
        t.line(seat, 0.8 * z, c(kit.SEAT["edge"]))
        t.paint(kit.glyph(mark, t, cx, cy, 3.5 * z), c(kit.INK))


# --- the kinds ----------------------------------------------------------------------------------------------------------

def swords(out, designs=None):
    return s.renders(out, designs or s.DESIGNS)


def shorts(out, designs=None):
    return s.renders(out, designs or ss.DESIGNS, ss.more)


def rings(out, designs=None):
    r.DESIGNS = tuple(designs or r.DESIGNS)
    return r.renders(out)


def helmets(out, designs=None):
    h.DESIGNS = tuple(designs or h.DESIGNS)
    return h.renders(out)


def shared(kind):
    """Batch 2's kinds, each drawn on gear_parts.py."""
    def renders(out, designs=None):
        kind.DESIGNS = tuple(designs or kind.DESIGNS)
        return gp.renders(kind, out)
    return renders


SHARED = (("shoulders", shoulders, "the Shoulders", "Shoulders"), ("chest", chest, "Chest Armor", "Chest Armor"),
          ("gloves", gloves, "the Gloves", "Gloves"), ("bracers", bracers, "the Bracers", "Bracers"),
          ("boots", boots, "the Boots", "Boots"), ("cloak", cloak, "the Cloak", "Cloak"),
          ("amulet", amulet, "the Amulet", "Amulet"), ("earring", earring, "the Earring", "Earring I"))

KINDS = dict(
    sword=dict(title="the Sword", slot="Main Hand", designs=s.DESIGNS, renders=swords, mark="Warrior", batch=1),
    short=dict(title="the Short Sword", slot="Off Hand", designs=ss.DESIGNS, renders=shorts, mark="Warrior", batch=1),
    ring=dict(title="Ring I", slot="Ring I", designs=r.DESIGNS, renders=rings, mark=None, batch=1),
    helmet=dict(title="the Helmet", slot="Helmet", designs=h.DESIGNS, renders=helmets, mark=None, batch=1),
    **{key: dict(title=title, slot=slot, designs=kind.DESIGNS, renders=shared(kind), mark=None, batch=2)
       for key, kind, title, slot in SHARED},
)


def file_name(name):
    words = name.rstrip("*").split(",")[0].replace("-", " ").split()
    return "Gear" + "".join(w[:1].upper() + w[1:] for w in words)


def sheet(out, kind, shots, designs, name):
    """A rarity a column, its three designs down it. Each in its slot, close; beside it at 64 and 38 points as the
    build lays it, and the picture alone at 64 pixels over dark."""
    ui.K = K = 2
    big, pitch_x, pitch_y, top = 132.0, 230.0, 176.0, 78.0
    rows = max(sum(1 for d in designs if d["rarity"] == rar) for rar in RARITIES)
    sh = ui.Sheet(1200, top + rows * pitch_y + 64, g.GROUND)
    t = sh.tile(0, 0, sh.w, sh.h)
    t.text(20, 12, 15, f"Grow your Anime: {kind['title']} in colour, in its slot (AR6, batch {kind['batch']}, the "
           "finish)", g.INK)
    t.text(20, 36, 9.5, "Flat pictures for the gear slots only (the director, 2026-11-15). Rarity in three layers: the "
           "object's own material, the slot's light, the frame. Common to Epic share one frame in the rarity's colour; "
           "Legendary's border is its own, with no crown, on a deep umber ground.", g.SOFT_INK)
    t.text(20, 50, 9.5, "Each: its slot seen close; beside it the slot at 64 and at 38 points as the build lays it; under "
           "them the picture alone at 64 pixels over dark." + (" A weapon's class mark sits on the bottom cut."
                                                               if kind["mark"] else ""), g.SOFT_INK)
    for i, rar in enumerate(RARITIES):
        t.text(36 + i * pitch_x, top - 16, 12, rar, RIM[rar])
        for j, d in enumerate([d for d in designs if d["rarity"] == rar]):
            x, y, shot = 36 + i * pitch_x, top + 6 + j * pitch_y, shots[d["name"]]
            slot(sh, x, y, big, rar, shot, big / SLOT, kind["mark"])
            slot(sh, x + big + 16, y, 64.0, rar, shot, 1.0, kind["mark"])
            slot(sh, x + big + 16, y + 78, 38.0, rar, shot, 1.0, kind["mark"])
            tile = sh.tile(x + big + 60, y + 78, 38, 38)
            tile.paint(tile.poly(ui.cut_box(0, 0, 38, 38)), c(g.DARK))
            rs.paste(sh.px, rs.shrink(shot, 64 / SIZE), round((x + big + 63) * K), round((y + 81) * K))
            t.text(x, y + big + 8, 10, d["name"].rstrip("*"), g.INK)
    y = top + rows * pitch_y + 6
    notes = ("Stones take their set's tone: Embers amber, Hoarfrost ice, Gales sea green, Stormcall warm white, Gloamforge "
             "pale cyan, Nightloom lilac. A lit part is warm white, its light gold and small: no flame, cloud or particle.",
             "Not here: Mythical and Dawn, the forge rank's badge, the kinds to come. The slot is drawn from the frame's "
             "own numbers (gear_icons.json); the build lays it from the kit's button slices and the two images delivered.")
    for i, line in enumerate(notes):
        t.text(20, y + i * 15, 9, line, g.SOFT_INK)
    for layer in ui.text_layers(sh.px.shape[1], sh.px.shape[0], sh.items).values():
        rs.paste(sh.px, layer, 0, 0)
    rs.save(sh.px, out / name)
    print("wrote", out / name)


def keep(px, path):
    """A delivered image: its colour carried past its edge, so a scaled picture takes no dark fringe."""
    kit.bleed(px)
    rs.save(px, path)


def frames(out):
    """The frame's two images, at the kit's four pixels a point: the slot's light, white, to tint; Legendary's border,
    in its own colours, sliced like the kit's boxes."""
    ui.K = kit.K
    t = kit.blank(SLOT, SLOT)
    t.px[..., :3], t.px[..., 3] = 1.0, light(t, 0.0, 0.0, SLOT)
    keep(t.px, out / "images" / "GearLight.png")
    pad = 8.0
    t = kit.blank(SLOT + 2 * pad, SLOT + 2 * pad)
    border(t, pad, pad, SLOT)
    keep(t.px, out / "images" / "GearFrameLegendary.png")
    return pad


def manifest(out, pad):
    data = dict(
        note="Regalia's gear in its slots (AR6). Pictures only: nothing here is worn or shown on a Voidkin. "
             "Sizes are in points for a slot of `slot` points, and scale with the slot unless a line says the kit's "
             "slice carries them. DESIGN, untried in Studio.",
        slot=SLOT,
        layers=[
            dict(what="the well", how="the kit's ButtonFill, tinted from `well` to `channel`, top to foot. Legendary: "
                 "tinted from `legendary`'s first colour to its second instead, a deep warm umber", well=WELL,
                 channel=CHANNEL, legendary=list(UMBER)),
            dict(what="the rarity's tint", how="the same ButtonFill over it in the rarity's `rim`, covering 0.14 (Common "
                 "0.112). Legendary: none, its ground is already its own"),
            dict(what="the rarity's light", image="images/GearLight.png", how="white, tinted the rarity's `rim` mixed a "
                 "fifth toward white; laid over the whole slot, covering 1 (Common 0.8); it fades out before the corners, "
                 "so it needs no cutting. Legendary: laid at `legendary` of the slot's size, its top left corner "
                 "`legendaryAt` of the slot's size in from the slot's own, so the light keeps its middle and leaves the "
                 "umber round it", legendary=LEGEND_LIGHT,
                 legendaryAt=[round((1 - LEGEND_LIGHT) * 0.5, 3), round((1 - LEGEND_LIGHT) * 0.46, 3)]),
            dict(what="the rim", how="Common to Epic: the kit's ButtonEdgeBold in the rarity's `rim`. Legendary: "
                 "images/GearFrameLegendary.png in its place, sliced: it reaches `pad` points past the slot on every "
                 "side, and its corners are `corner` points from the image's edge", pad=pad, corner=pad + 14.0),
            dict(what="the picture", how="its square is 0.94 of the slot, centred; the object already sits in it with "
                 "its own margin"),
            dict(what="a weapon's class mark", how="the kit's Class<name> in its seat, 10.8 points across, its middle "
                 "4.6 points in from the slot's right and foot, on the bottom cut; weapons only"),
            dict(what="the forge rank, the lock", how="on the frame's square corners (foot left, top right), never over "
                 "the object; not drawn here"),
        ],
        rim=RIM,
        kinds={k["slot"]: [dict(name=d["name"].rstrip("*"), rarity=d["rarity"], image=f"images/{file_name(d['name'])}.png")
                           for d in k["designs"]] for k in KINDS.values()},
        pixels=[ICON, ICON])
    (out / "gear_icons.json").write_text(json.dumps(data, indent=1), encoding="utf-8", newline="\n")
    print("wrote", out / "gear_icons.json")


def main():
    out = bl.out_dir()
    (out / "images").mkdir(exist_ok=True)
    asked = [a for a in sys.argv[sys.argv.index("--") + 2:]] or list(KINDS) + ["frames"]
    g.PAINT, g.shoot = paint, shoot
    s.sword, r.ring, h.helmet = building(s.sword), building(r.ring), building(h.helmet)
    for _, kind, _, _ in SHARED:
        kind.build = building(kind.build)
    if "look" in asked:  # a few of each, at their own scale: for the look alone, nothing delivered
        for key, kind in KINDS.items():
            few = [d for d in kind["designs"] if d["rarity"] in ("Common", "Rare", "Epic", "Legendary")][::3]
            few += [d for d in kind["designs"] if d["rarity"] == "Uncommon"][:1]
            sheet(out, kind, kind["renders"](out, few), few, f"_look_{key}.png")
        return
    for key in asked:
        if key == "frames":
            manifest(out, frames(out))
            continue
        kind = KINDS[key]
        shots = kind["renders"](out)
        for d in kind["designs"]:
            keep(rs.shrink(shots[d["name"]], ICON / SIZE), out / "images" / f"{file_name(d['name'])}.png")
        sheet(out, kind, shots, kind["designs"], f"gear_{key}_colour.png")


if __name__ == "__main__":
    main()
