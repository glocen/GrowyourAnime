"""AR22: the empty gear slots' marks. Each is its slot's own Epic piece from AR6, its detail and ornament kept, in one
faint tone and inset, so an empty slot on the Voidkin's sheet names its piece at a glance and a worn item still outshines
it (the director, by 21:32: "the empty gears slot decal need a rework it sooo simple like the chest arm  shoulder"; on
the grey, 21:57: "need to looks more detailed "epic" and the shoulder only show 1 shoulder", and "All of them").

A mark is white on alpha; the slot tints it. Its form is the piece's silhouette with its parts' lines cut through, and
its inset is in its alpha: the shadow of the well's lip along its upper inner edge, the light caught along its lower one.
The two hands take each class's pair (gear_icons.json's `hands`).

Writes `images/SlotEmpty<Kind>.png` (the hands `SlotEmptyMainHand<Class>`, `SlotEmptyOffHand<Class>`),
`slot_marks.json`, and the review sheet `slot_marks_grey.png`: every mark in A's empty slot, and A's doll at the smallest
phone, empty beside filled.

Run: blender --background --factory-startup --python tools/blender/slot_marks.py -- build/handoff/UI/slots
"""
import json
import math
import sys
import textwrap
import types
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_bracers_sets as bracers  # noqa: E402
import gear_cloak_sets as cloak  # noqa: E402
import gear_icons as gi  # noqa: E402
import gear_parts as gp  # noqa: E402
import gear_shoulders_sets as shoulders  # noqa: E402
import inventory_directions as inv  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
from ui_sheet import c  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
GEAR = REPO / "build" / "handoff" / "UI" / "gear"
K = inv.K
P = inv.LACQUER
SIDE = 128  # a mark's pixels
SLOT, POINTS = 44.0, 32.0  # drawn at 32 points, centred, in A's 44 point slot
TINT, OPACITY = P["faint"], 0.9  # the slot's ImageColor3 and 1 - its ImageTransparency
SMALLEST = 0.85  # Theme.Scale.Floor: the smallest phone held sideways
LUMA = np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)

# Each slot kind (Definitions/Gear.luau: a ring or an earring is one kind for its two slots) and the Epic piece its mark
# is drawn from: of AR6's three Epic sets, the one whose outline reads clearest at 44 points, Stormcall's most often.
KINDS = (("Helmet", "GloamforgeHelm"), ("Shoulders", "StormcallPauldrons"), ("Chest Armor", "StormcallCuirass"),
         ("Gloves", "GloamforgeGauntlets"), ("Bracers", "StormcallVambraces"), ("Boots", "GloamforgeGreaves"),
         ("Cloak", "StormcallMantle"), ("Amulet", "NightloomTalisman"), ("Ring", "StormcallLoop"),
         ("Earring", "StormcallEardrop"))
EPIC = {"Sword": "StormcallBlade", "Short Sword": "GloamforgeEdge", "Great Axe": "StormcallGreataxe",
        "Shield": "StormcallBulwark", "Staff": "StormcallStave", "Tome": "StormcallGrimoire", "Dagger": "StormcallFang",
        "Throwing Blades": "StormcallTalons", "Crystal Baton": "StormcallSceptre", "Codex": "StormcallFolio"}
# Pieces slender enough to thin to a line at 44 points: their form is grown by a few pixels, so each still reads as a
# solid piece, never a line icon (research's ask)
THIN = {"StormcallEardrop", "StormcallBlade", "GloamforgeEdge", "StormcallGreataxe", "StormcallStave", "StormcallFang",
        "StormcallTalons", "StormcallSceptre"}


def shifted(a, dx, dy):
    return np.roll(np.roll(a, dy, 0), dx, 1)


def spread(a, r, fn):
    out = a.copy()
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dx * dx + dy * dy <= r * r:
                out = fn(out, shifted(a, dx, dy))
    return out


def blur(a, r):
    out = np.zeros_like(a)
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            out += shifted(a, dx, dy)
    return out / (2 * r + 1) ** 2


# --- the posed pieces: AR6's own models, built by AR6's builders and finished as AR6's pictures, posed for a mark ------

CLOTH = cloak.cloth_point


def posed(kind, name, make=None, change=None, **view):
    """An Epic design of `kind` built by AR6's builder (or by `make(d)`, a scene and its parts), its design changed by
    `change` and the kind's view by `view` for this render alone, then finished as AR6's pictures are, at 256 px."""
    gi.g.PAINT, gi.g.shoot = gi.paint, gi.shoot
    d = dict(next(x for x in kind.DESIGNS if x["name"] == name), **(change or {}))
    saved = {k: getattr(kind, k) for k in view}
    for k, v in view.items():
        setattr(kind, k, v)
    try:
        one = types.SimpleNamespace(DESIGNS=(d,), build=gi.building(make or kind.build), FILL=kind.FILL, LEAST=1.0,
                                    DROP=kind.DROP)
        shot = gp.renders(one, bl.out_dir())[d["name"]]
    finally:
        for k, v in saved.items():
            setattr(kind, k, v)
    return rs.shrink(shot, 256 / gi.SIZE)


def lone_pauldron(d, lean=25.0, step=0.24, grow=0.12):
    """A pauldron alone, for the mark (the director: "the shoulder only show 1 shoulder"). AR6's cop on its own reads
    as a head in every view tried (a full dome, its stone an eye, its crest horns), so the mark's is built as a pauldron
    is drawn: the Epic cop's shell open on the neck's side, its dark inside showing, its lames tiered under it, each
    tucked under the one above and wider than it; the design's filigree line and stone kept, the stone off toward the
    outside, and its crest laid on its face round the stone as an emblem, so the outline stays a pauldron's. Then leant
    `lean` degrees out over the arm."""
    sh = shoulders

    def parts():
        key, tall, deep, a0, a1 = d["key"], sh.SHALLOW, sh.DEEP, -40.0, 220.0
        out = [gp.lathe("Cop", [(r, z * tall) for r, z in sh.COP], key, a0, a1, deep=deep),
               gp.lathe("Liner", [(r * 0.95, z * tall - 0.03) for r, z in sh.COP], "liner", a0, a1, thick=0.02,
                        deep=deep)]
        if d["line"]:
            out.append(sh.arc_rim("Line", 0.93, 0.025, d["line"], 0.42 * tall, a0, a1))
        for k in range(d["lames"]):
            z, r = -0.04 - step * k, 0.92 + grow * k
            out.append(gp.lathe("Lame", [(r, z), (r + grow + 0.02, z - step - 0.06)], d["lame_mat"], a0, a1,
                                thick=0.05, deep=deep))
        a = math.radians(35.0)
        at = (0.9 * math.sin(a), -0.9 * deep * math.cos(a) - 0.04, 0.45 * tall)
        plate = gp.flat("Crest", gp.set_ornament(d["orn"], 0.4, (0, -0.12)), 0.05, d["trim"], y=0.0)
        out.append(gp.move(plate, Matrix.Translation(at) @ Matrix.Rotation(-a, 4, "Z")))
        out += gp.stone_of(d, 0.9, at)
        for obj in out:
            gp.move(obj, Matrix.Rotation(math.radians(lean), 4, "Y"))
        return out
    return gp.scene_of(parts, sh.TILT, sh.SPIN)


def face_crest_bracer(d):
    """The bracer stood up with its crest laid flat on its face round the stone, as an emblem: standing out from its
    side, the crest read as a mug's handle (research, 22:16)."""
    def parts():
        out = bracers.sleeve(dict(d, orn=None))
        at = bracers.face(0.05, 0.06)
        out.append(gp.flat("Crest", gp.set_ornament(d["orn"], 0.4, (0, at[2] - 0.12)), 0.05, d["trim"],
                           y=at[1] + 0.04))
        return out
    return gp.scene_of(parts, bracers.TILT, bracers.SPIN)


def widened(k):
    """The cloth flaring out toward its hem, by `k` of its width at the hem."""
    def point(d, a, v, inset=0.0, length=1.0):
        x, y, z = CLOTH(d, a, v, inset, length)
        s = 1.0 + k * v
        return (x * s, y * s, z)
    return point


# The three kinds whose mark is posed afresh from AR6's model rather than drawn from its picture, each in its view.
POSED = {
    "StormcallPauldrons": lambda: posed(shoulders, "Stormcall Pauldrons", lone_pauldron, TILT=25.0, SPIN=-25.0),
    # research's fix 1: stood up, with the cuff's flare and its two straps; its crest laid on its face. Leant 30 degrees
    # and seen a little more from above, so the cuff's open notch shows at its top: bolt upright, it read as a cup
    "StormcallVambraces": lambda: posed(bracers, "Stormcall Vambraces", face_crest_bracer, change=dict(flare=True),
                                        SLANT=-30.0, TILT=25.0),
    # research's fix 2: the hem wider than the shoulders; the crest stands where a hood's peak would
    "StormcallMantle": lambda: posed(cloak, "Stormcall Mantle", cloth_point=widened(0.45), SPIN=166.0),
}


def mark(stem, px=None):
    """The piece's mark at the picture's 256 pixels: its cover, white."""
    if px is None:
        px = POSED[stem]() if stem in POSED else rs.load(GEAR / "images" / f"Gear{stem}.png")
    luma = px[..., :3] @ LUMA
    solid = np.clip((px[..., 3] - 0.25) / 0.5, 0, 1)
    # its parts' lines: the render's own dark seams between parts and in its crevices, kept off the outline
    lines = np.clip((blur(luma, 3) - luma - 0.04) / 0.1, 0, 1) * (spread(solid, 4, np.minimum) > 0.5)
    lines = spread(lines, 2, np.maximum)
    if stem in THIN:
        solid = spread(solid, 5, np.maximum)
    form = solid * (1.0 - 0.85 * lines)
    # the inset: the lip's shadow inside the upper left edge, the light inside the lower right, about 0.75 points wide
    d = 6
    shade = blur(np.clip(solid - shifted(solid, d, d), 0, 1), 2) * solid
    catch = blur(np.clip(solid - shifted(solid, -d, -d), 0, 1), 2) * solid
    alpha = np.clip(form * 0.62 - 0.42 * shade + 0.38 * catch, 0, 1) * solid
    out = np.ones(alpha.shape + (4,), dtype=np.float32)
    out[..., 3] = alpha
    return rs.shrink(out, SIDE / alpha.shape[0])


def tinted(img, side_px):
    out = rs.shrink(img, side_px / img.shape[0]) if side_px < img.shape[0] else img.copy()
    out[..., :3] = c(TINT)[:3]
    out[..., 3] *= OPACITY
    return out


def marks_all():
    """Every mark by its file stem, and the json's map."""
    data = json.loads((GEAR / "gear_icons.json").read_text(encoding="utf-8"))
    files, table = {}, {}
    for kind, stem in KINDS:
        name = "SlotEmpty" + kind.replace(" ", "")
        files[name] = mark(stem)
        table[kind] = f"images/{name}.png"
    for hand in ("Main Hand", "Off Hand"):
        table[hand] = {}
        for cls, pair in data["hands"].items():
            name = "SlotEmpty" + hand.replace(" ", "") + cls
            files[name] = mark(EPIC[pair[hand]])
            table[hand][cls] = f"images/{name}.png"
    return files, table


def cell(sheet, x, y, s, img):
    """A's empty slot, `s` points, its mark in it: as the slot will draw it."""
    t = sheet.tile(x - 4, y - 4, s + 8, s + 8)
    X, Y = t.x + x - 4, t.y + y - 4
    t.X, t.Y = X, Y
    d = inv.rrect(t, x, y, x + s, y + s, 2.0)
    t.paint(d, inv.vramp(t, inv.mix(P["well"][0], P["top"], 0.4), P["well"][1], y, y + s), 0.9)
    t.line(d, 1.0, c(P["brass_dim"]), 0.7)
    side = s * POINTS / SLOT
    m = tinted(img, side * ui.K)
    rs.paste(sheet.px, m, round((x + (s - side) / 2) * ui.K), round((y + (s - side) / 2) * ui.K))


def doll_shots(files):
    """A's three states, the doll's column cut out at the smallest phone, the marks in the empty slots."""
    original = inv.a_cell

    def a_cell(scr, p, x, y, s, stem, who, chosen=False, target=False, slot=None):
        if stem is not None or not slot:
            return original(scr, p, x, y, s, stem, who, chosen, target, slot)
        original(scr, p, x, y, s, None, who, chosen, target, None)
        if slot in ("Main Hand", "Off Hand"):
            name = "SlotEmpty" + slot.replace(" ", "") + who["cls"]
        else:
            name = "SlotEmpty" + {"Ring I": "Ring", "Ring II": "Ring", "Earring I": "Earring",
                                  "Earring II": "Earring"}.get(slot, slot).replace(" ", "")
        side = s * POINTS / SLOT
        scr.paste(tinted(files[name], side * K), x + (s - side) / 2, y + (s - side) / 2)

    inv.a_cell = a_cell
    shots = []
    try:
        for state, who, chosen in inv.STATES:
            sheet = ui.Sheet(inv.W, inv.H, P["top"])
            inv.draw_a(inv.Screen(sheet, 0, 0), state, who, chosen)
            for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
                rs.paste(sheet.px, layer, 0, 0)
            x0, y0, x1, y1 = (round(v * K) for v in (104.0, 40.0, inv.A_BAG - 4.0, 375.0))
            shots.append(rs.shrink(sheet.px[y0:y1, x0:x1], SMALLEST))
    finally:
        inv.a_cell = original
    return shots


def review(out, files, table, shots):
    sheet = ui.Sheet(1180, 1060, "#15120F")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(20, 14, 18, "Grow your Anime: the empty slots' marks, from the Epic pieces (AR22)", P["text"],
           bold=0.2 * ui.K)
    head = ("Each is its slot's Epic piece from AR6, its detail kept, in one faint tone and inset: the piece's form with "
            "its parts' lines cut through, the lip's shadow along its upper edge and the light caught along its lower. White on alpha; the "
            f"slot tints it A's faint {TINT} at {OPACITY:.0%} and draws it at {POINTS:.0f} points in its {SLOT:.0f}.")
    rows = textwrap.wrap(head, 180)
    for k, line in enumerate(rows):
        t.text(20, 42 + k * 16, 11.5, line, P["soft"])
    y = 42 + 16 * len(rows) + 14
    # every kind at 44 points (two pixels a point), and the same at twice the size
    t.text(20, y, 13, "The ten kinds, in A's empty slot at 44 points; then twice the size", P["text"])
    y += 22
    top = y
    for i, (kind, _) in enumerate(KINDS):
        x = 20 + i * 54
        cell(sheet, x, y, SLOT, files["SlotEmpty" + kind.replace(" ", "")])
    for i, (kind, _) in enumerate(KINDS):
        x = 580 + (i % 5) * 116
        yy = y + (i // 5) * 112
        cell(sheet, x, yy, 88.0, files["SlotEmpty" + kind.replace(" ", "")])
        t.text(x + 44, yy + 92, 9.5, kind, P["soft"], "CENTER")
    y += 60
    t.text(20, y, 13, "The hands, each class's pair", P["text"])
    y += 22
    hands = table["Main Hand"]
    for i, cls in enumerate(hands):
        x = 20 + (i % 3) * 180
        yy = y + (i // 3) * 76
        cell(sheet, x, yy, SLOT, files[f"SlotEmptyMainHand{cls}"])
        cell(sheet, x + 50, yy, SLOT, files[f"SlotEmptyOffHand{cls}"])
        t.text(x + 102, yy + 16, 11, cls, P["soft"])
    y = top + 240
    t.text(20, y, 13, "A's doll at the smallest phone (0.85, 1.7 pixels a point): Rook's empties beside his worn "
           "pieces; Lyric, a Healer, her hands empty; a new account, all empty", P["text"])
    y += 22
    x = 20.0
    for shot in shots:
        rs.paste(sheet.px, shot, round(x * ui.K), round(y * ui.K))
        x += shot.shape[1] / ui.K + 20
    y += shots[0].shape[0] / ui.K + 16
    notes = ("Today's plain marks were flat signs; these are the Epic pieces themselves, so the slot says what goes there "
             "and a held item, lit in its rarity, still outshines it. The Shoulders' mark is one pauldron, built for the "
             "mark from the Stormcall pair's cop, lames and stone, its crest laid on its face: AR6's cop alone reads as a "
             "head. The bracer stands, leaning a little, its cuff flared and open, its straps across it, its crest laid "
             "on its face. The cloak's hem is wider than its shoulders, and its crest stands where a hood's peak would. "
             "The rings and the earrings share their kind's mark.",
             "Not here: the marks for kinds to come (Mythical, Dawn), and any motion.")
    for n in notes:
        for line in textwrap.wrap(n, 180):
            t.text(20, y, 11, line, P["soft"])
            y += 16
    sheet.px = sheet.px[:round((y + 10) * ui.K)].copy()
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "slot_marks_grey.png")
    print(f"wrote {out / 'slot_marks_grey.png'} {sheet.px.shape[1]}x{sheet.px.shape[0]}")


def deliver(out, files, table):
    (out / "images").mkdir(parents=True, exist_ok=True)
    for name, img in files.items():
        rs.save(rs.bleed(img), out / "images" / f"{name}.png")
    note = ("The empty slots' marks (AR22): white on alpha, the slot tints them. Each is drawn at `points` in a slot of "
            "`slot` points, centred, tinted `tint` at `transparency`. `marks` keys a slot by its kind "
            "(Definitions/Gear.luau: either ring is Ring, either earring Earring); each hand's by the lead's class.")
    doc = dict(note=note, pixels=[SIDE, SIDE], slot=SLOT, points=POINTS, tint=TINT, transparency=round(1 - OPACITY, 2),
               marks=table)
    (out / "slot_marks.json").write_text(json.dumps(doc, indent=1) + "\n", encoding="utf-8")
    print(f"wrote {len(files)} marks and {out / 'slot_marks.json'}")


def main():
    out = bl.out_dir()
    for who in (inv.ROOK, inv.LYRIC):
        inv.FIGURES[who["who"]] = inv.figure_render(who["blend"])
    files, table = marks_all()
    shots = doll_shots(files)
    review(out, files, table, shots)
    deliver(out, files, table)


if __name__ == "__main__":
    main()
