"""Kirra in the make (docs/asset-requests.md, AR60): the picked take, A the night runner, as the files the builder
installs. The design is kirra_make_takes.py's `take_a`, with research's three must-fixes in it and the kit (the hair
as a few broad sweeps, folds that read on dark cloth); the make and the handoff are the kit's (anime_make.py).

She keeps the first Kirra's joints (kirra_model.py), so her clips still work them:
- the two blades, a piece each, ride a Motor6D of their own on the Torso at the grip. At rest each lies on the
  first Kirra's sheath line (kirra_sheet.SHEATHS), its grip's middle where her fist closed on it, so a clip that keys
  it into her hand finds it there; it is bare steel now, held by the strap, a little longer.
- the scarf's long tail is a chain of eight links, each on a joint at its root: the first on the Torso at the knot,
  each next on the one before. Its line is the take's (kirra_make_takes.TAIL_LONG), not the first Kirra's ten-stud S,
  so the clips are keyed again on it (kirra_clips.py, `clips` below). The turn round her neck, the knot and the short
  tail are one piece on the Torso; the hair's tie rides the Head.

    blender.exe -b --factory-startup --python tools/blender/kirra_make.py -- <out_dir> model
    blender.exe -b --factory-startup --python tools/blender/kirra_make.py -- <out_dir> sheet

`model` builds her and writes <out_dir>/handoff (Kirra_Color.png, Kirra_Roughness.png, a mesh a piece and
Kirra.recipe.json, as tools/studio/ModelRecipe.luau reads them) and <out_dir>/handoff/model/kirra_model.blend, which
kirra_clips.py reads (KIRRA_MODEL=<that folder>) to key her clips on the new body. It then draws her from those files
into <out_dir>/shots and <out_dir>/layers. `sheet` lays kirra_make_sheet.png: those pictures and the maps; the
fight's foe is kirra_make_takes.py's `shade`, drawn into the same <out_dir>.
"""
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import anime_make as am  # noqa: E402
from anime_make import tone  # noqa: E402
import blcommon as bl  # noqa: E402
import kirra_make_takes as kt  # noqa: E402
import kirra_sheet as ks  # noqa: E402
import rook_make_takes as rmt  # noqa: E402
import rook_sheet as rs  # noqa: E402

NAME, TAKE = "Kirra", "A"
LINKS, PER = 8, 12            # the tail's links, and its points to a link
THICK = (0.05,)                # the band's thickness; a link's overlap into the next is 0.7 of it, tucked inside
BLADES = {"BladeR": "Right", "BladeL": "Left"}
TIP = 2.3                     # the blade's length from the pommel's end (the first Kirra's was 2.05)
STEEL = ("#E8ECF2", "#7B8395")
turn = lambda q: [round(q[0], 4), round(q[2], 4), round(-q[1], 4)]  # noqa: E731  the kit's frame to Roblox's


def sheath_line(side):
    """The first Kirra's blade line at rest: the pommel's end, the way to the tip, the way across (its back)."""
    top, tip = (Vector(p) for p in ks.SHEATHS[side])
    d = (tip - top).normalized()
    beta = math.atan2(d.x, d.z)
    return top, d, Vector((math.cos(beta), 0, -math.sin(beta)))


def tail_frames():
    """The long tail's line, LINKS * PER even steps along it: (points, the way along, the way across, widths, twist
    in degrees, and how far along each point is)."""
    dense = [Vector(q) for q in am.smooth2(kt.TAIL_LONG, 240)]
    run = np.concatenate([[0.0], np.cumsum([(b - a).length for a, b in zip(dense, dense[1:])])])
    count = LINKS * PER
    at = np.linspace(0, run[-1], count + 1)
    pts = [Vector([float(np.interp(s, run, [p[i] for p in dense])) for i in range(3)]) for s in at]
    u = at / run[-1]
    key = np.linspace(0, 1, len(kt.TAIL_LONG))   # the take's twist and width are given at its points, about evenly spaced
    twist, widths = np.interp(u, key, kt.TAIL_TURN), np.interp(u, key, np.linspace(*kt.TAIL_WIDTH, len(kt.TAIL_LONG)))
    along, across, s = [], [], Vector((1, 0, 0))
    for i, q in enumerate(pts):
        d = (pts[min(i + 1, count)] - pts[max(i - 1, 0)]).normalized()
        s = (s - d * s.dot(d)).normalized()   # the ribbon's own way of carrying its width along (am.Built.ribbon)
        along.append(d)
        across.append(Matrix.Rotation(math.radians(twist[i]), 3, d) @ s)
    return pts, along, across, widths, twist, u


def tail_chain(colour, ends):
    """The long tail as LINKS pieces, Scarf1 to Scarf8, each one step past its end so a bend opens no gap."""
    pts, _, across, widths, twist, u = tail_frames()
    shade_ = kt.tail_shade(colour, ends)
    links = []
    for j in range(LINKS):
        idx = list(range(j * PER, min((j + 1) * PER + 2, len(pts))))
        b = am.Built(f"Scarf{j + 1}")
        tuck = [i >= (j + 1) * PER for i in idx]   # the steps past its end, inside the next link: a little smaller
        b.ribbon([pts[i] for i in idx], [widths[i] * (0.94 if t else 1.0) for i, t in zip(idx, tuck)],
                 lambda v, idx=idx: shade_(u[idx[0]] + v * (u[idx[-1]] - u[idx[0]])), side=across[idx[0]],
                 thick=[THICK[0] * (0.7 if t else 1.0) for t in tuck], turn=[twist[i] - twist[idx[0]] for i in idx],
                 caps=(j == 0, j == LINKS - 1))
        links.append(b)
    return links


def blade(piece, grip_colour):
    top, d, _ = sheath_line(BLADES[piece])
    b = am.Built(piece)
    # the grip's middle (0.23 along a 0.46 grip) where her fist closed on the first Kirra's (ks.GRIP from the pommel)
    b.blade(top + d * (ks.GRIP - 0.23), top + d * TIP, 0.24, (grip_colour, "#6E7686", *STEEL), grip=0.46, thick=0.05, guard=0.07)
    return b


def pieces(colour, ends, guards):
    return [kt.scarf(colour, ends, long_tail=False), *(blade(p, guards) for p in BLADES), *tail_chain(colour, ends)]


# --- her blades as gear (AR60 reopened, the director, 2026-11-27, 12:47: "what are those toy sword like behind kirra") --
# The toy read: flat grey slabs with a white edge, too long and thin for her, no hilt, wrap, guard or sheath. Each
# option is a blade (its hilt, guard and steel, on the blade's own joint, its grip's middle where it always was, so
# her clips still draw it) and a sheath on the Torso it rests in, in her clothes' colours. Measured along the blade's
# line from the pommel's end, studs.

PEWTER, IRON, TEAL, NIGHT = "#A3AAB8", "#343947", "#1FA39A", "#1B1F2B"
LIGHT_DIR = Vector((0.3, -0.7, 0.65)).normalized()   # from behind her and above, where the game's camera mostly is


def axes(side):
    """The blade's line at rest: the pommel's end, the way along, across its width, through its thickness."""
    top, d, _ = sheath_line(side)
    n = Vector((0, 1, 0))
    n = (n - d * n.dot(d)).normalized()
    return top, d, d.cross(n).normalized(), n


def turned(b, side, rings, colour, sides=8, offset=22.5, caps=True):
    """A piece turned along the blade's line: `rings` (how far along, half its width, half its thickness, and a shift
    through its thickness); `colour(i, k)` for the stretch `i` between two rings and its side `k` round, or one colour a
    stretch. Each face takes a little of the light's fall, as the kit's built pieces do."""
    top, d, s, n = axes(side)
    angles = [math.radians(offset + 360 / sides * k) for k in range(sides)]
    pts = [[top + d * at + s * (w * math.cos(a)) + n * (t * math.sin(a) + sh) for a in angles] for at, w, t, sh in
           ((r + (0.0,))[:4] for r in rings)]
    base = colour if callable(colour) else (lambda i, k: colour[i])

    def shade(i, k):
        a = angles[k] + math.radians(180 / sides)
        out = (s * math.cos(a) + n * math.sin(a)).normalized()
        return tone(base(i, k), 0.62 + 0.48 * max(0.0, out.dot(LIGHT_DIR)))
    b.tube(pts, shade, caps=(tone(base(0, 0), 0.7), tone(base(len(rings) - 2, 0), 0.7)) if caps else None, smooth=False)


def ring_pommel(b, side, at, radius, tube_r, colour, segments=16):
    """A ring at the pommel's end, in the plane of the blade's width."""
    top, d, s, n = axes(side)
    centre = top + d * at
    rings = []
    for j in range(segments + 1):
        f = 2 * math.pi * j / segments
        r = d * math.cos(f) + s * math.sin(f)
        q = centre + r * radius
        rings.append([q + r * tube_r * math.cos(a) + n * tube_r * math.sin(a) for a in (0.0, math.pi / 2, math.pi, 1.5 * math.pi)])
    b.tube(rings, lambda i, k: tone(colour, (1.0, 0.8, 0.6, 0.8)[k]), smooth=False)


def steel(b, side, start, end, half_w, point, thick=0.022):
    """The steel from the collar to its point: a ridge down the middle, its two bevels lit and dark."""
    turned(b, side, [(start, half_w, thick), (end - point, half_w, thick), (end, 0.004, 0.003)],
           lambda i, k: "#E6EAF0" if k in (0, 3) else "#8A92A3", sides=4, offset=0.0, caps=False)


def bound_grip(b, side, a, b_, w, t, base, cord, turns, cw=0.022, rise=0.01):
    """A grip from `a` to `b_` in `base`, bound by `turns` thin raised turns of `cord`: one colour with fine lines,
    never equal stripes (round 1's banded grips read as candy, and so did teal turns on dark)."""
    step = (b_ - a) / turns
    rings, cols = [(a, w, t)], []
    for i in range(turns):
        c = a + step * (i + 0.5)
        rings += [(c - cw, w, t), (c - cw, w + rise, t + rise), (c + cw, w + rise, t + rise), (c + cw, w, t)]
        cols += [base, cord, cord, cord]
    rings.append((b_, w, t))
    cols.append(base)
    turned(b, side, rings, cols)


def lacquer(guards):
    """1, the lacquered pair: a pewter cap, a grip in teal cord bound with fine dark turns, a round iron guard with a pewter rim,
    a pewter collar; each in a slim black lacquer sheath with a pewter mouth and tip, one teal cord, and a dark
    leather loop on the strap. 1.75 studs, the first was 2.3. (Round 1's navy lacquer sank into her navy top.)"""
    sheath_col = "#12151D"

    def blade_(piece):
        side = BLADES[piece]
        b = am.Built(piece)
        turned(b, side, [(0.0, 0.05, 0.05), (0.012, 0.082, 0.078), (0.06, 0.082, 0.078)], [PEWTER, PEWTER])
        bound_grip(b, side, 0.06, 0.555, 0.074, 0.066, tone(TEAL, 0.78), NIGHT, 6, cw=0.01, rise=0.006)
        turned(b, side, [(0.555, 0.15, 0.13), (0.565, 0.172, 0.15), (0.615, 0.172, 0.15), (0.625, 0.15, 0.13)], [PEWTER, IRON, PEWTER])
        turned(b, side, [(0.625, 0.1, 0.05), (0.68, 0.1, 0.05)], [PEWTER])
        steel(b, side, 0.68, 1.75, 0.1, 0.2)
        return b

    def sheaths():
        b = am.Built("Sheaths")
        for side in BLADES.values():
            r = [(0.63, 0.128, 0.072), (0.72, 0.128, 0.072), (0.72, 0.124, 0.068), (0.9, 0.124, 0.068), (0.9, 0.134, 0.078),
                 (0.94, 0.134, 0.078), (0.94, 0.124, 0.068), (1.7, 0.112, 0.062), (1.7, 0.118, 0.066), (1.82, 0.09, 0.05),
                 (1.86, 0.05, 0.03)]
            cols = [PEWTER, sheath_col, sheath_col, TEAL, TEAL, sheath_col, sheath_col, PEWTER, PEWTER, PEWTER]   # a colour a
            # stretch between two rings: the mouth, one cord (two, beside the grip's turns, read as stripes), the tip
            turned(b, side, r, cols)
            turned(b, side, [(1.24, 0.15, 0.088), (1.34, 0.15, 0.088)], [guards])   # the strap's loop
        return b
    return blade_, sheaths


def knives(guards):
    """2, the runner's knives: shorter and broader, a pewter ring at the pommel, a grip in the sheath's leather bound
    with dark turns, a pewter crossbar; each in a dark leather sheath with a teal mouth, two buckled straps, a lighter stitched
    edge and a rounded end, in a dark brown that stands off her navy. 1.5 studs."""
    leather, stitch = "#4A3A32", "#A38C7A"

    def blade_(piece):
        side = BLADES[piece]
        b = am.Built(piece)
        ring_pommel(b, side, -0.07, 0.07, 0.022, PEWTER)
        bound_grip(b, side, 0.0, 0.48, 0.07, 0.064, leather, NIGHT, 4, cw=0.012, rise=0.006)
        turned(b, side, [(0.48, 0.26, 0.07), (0.54, 0.26, 0.07)], [PEWTER], sides=4, offset=45.0)
        steel(b, side, 0.54, 1.5, 0.13, 0.26, thick=0.026)
        return b

    def sheaths():
        b = am.Built("Sheaths")
        for side in BLADES.values():
            r = [(0.545, 0.16, 0.078), (0.63, 0.16, 0.078), (0.63, 0.152, 0.072), (0.78, 0.152, 0.072), (0.78, 0.166, 0.084),
                 (0.85, 0.166, 0.084), (0.85, 0.152, 0.072), (1.13, 0.15, 0.07), (1.13, 0.164, 0.082), (1.2, 0.164, 0.082),
                 (1.2, 0.148, 0.07), (1.46, 0.13, 0.064), (1.54, 0.08, 0.044), (1.57, 0.03, 0.02)]
            body = {0: TEAL, 3: guards, 4: guards, 7: guards, 8: guards}   # the mouth, the two straps

            def col(i, k, body=body):
                if i in body:
                    return body[i]
                return stitch if k in (3, 7) and i != 12 else leather   # the stitched edges, along its two sides
            turned(b, side, r, col)
            for at in (0.815, 1.165):   # the two buckles, on the strap's outside
                turned(b, side, [(at - 0.03, 0.04, 0.012, -0.09), (at + 0.03, 0.04, 0.012, -0.09)], [PEWTER], sides=4, offset=45.0)
        return b
    return blade_, sheaths


def gear_pieces(option):
    def make(colour, ends, guards):
        blade_, sheaths = option(guards)
        return [kt.scarf(colour, ends, long_tail=False), *(blade_(p) for p in BLADES), sheaths(), *tail_chain(colour, ends)]
    return make


TARGET_WORDS = dict(
    stem="kirra_gear",
    beside="AR60 reopened: Kirra today, the cut with the lacquered pair, the still with the runner's knives, square on between two "
           "Anime Vanguards units at the same height. Internal: the two are reference.",
    title="AR60 REOPENED: KIRRA'S BLADES AS GEAR, AND HER OWN FACE",
    about="The director, 12:47: the blades on her back read as toys, and the Voidkin share one face. Two targets, each a face "
          "and a set of gear; research may pick a face from one and the gear from the other. Rook first, his face the kit's.",
    row="Rook, Kirra today, 1 and 2, and a Brawler",
)


def targets_run(out, keys):
    """The two targets beside today's Kirra and Rook: the takes' sheet (its beside part internal), then the gear from
    behind beside an Anime Vanguards unit, and the faces with Pip's (internal: build/reference/takes/)."""
    rmt.TAKES = {"Rook": kt.TAKES["Rook"], "A": lambda j, f: kt.take_a(j, f, pieces=pieces),
                 "B": lambda j, f: kt.take_a(j, f, pieces=gear_pieces(lacquer), face_draw=kt.face_cut),
                 "C": lambda j, f: kt.take_a(j, f, pieces=gear_pieces(knives), face_draw=kt.face_still)}
    rmt.SAID = {"Rook": ("Rook", ("in the game: the kit's face",)),
                "A": ("Kirra today", ("in the game: the kit's face recoloured,", "bare blades 2.3 studs, no hilt")),
                "B": ("1, the cut", ("the lacquered pair: cord-bound grips,", "round guards, black lacquer sheaths, 1.75 studs")),
                "C": ("2, the still", ("the runner's knives: ring pommels, crossbars,", "buckled brown leather sheaths, 1.5 studs"))}
    rmt.VIEWS.update(back=(0, 6), back34=(326, 6))
    if "takes" in keys:
        rmt.takes_run(out, [k for k in keys if k in rmt.WHO] or list(rmt.WHO), finish=kt.measured)
        if not (out / "layers" / "Shade_foe.npz").exists():
            rmt.shade_run(out)
    if "sheet" in keys:
        rmt.sheet_run(out, TARGET_WORDS, list(kt.BESIDE))
        gear_sheet(out)


def gear_sheet(out):
    shots = out / "shots"
    k_ = 0.46
    per = rmt.SHOT / rmt.SPAN * k_
    gap, W = 24, 2400
    ink, soft, paper, pale = "#EDE6D6", "#B4AC9C", "#101117", "#DFE1E6"
    av = rmt.reference(kt.BESIDE[0][0], per, kt.BESIDE[0][1])
    views = (("back", "from behind"), ("back34", "from behind her left"), ("game", "the game's camera"))
    full = {(k, v): rs.trim(rs.load(shots / f"{k}_{v}.png")) for k in "ABC" for v, _ in views}
    tiles = {key: rs.shrink(t, k_) for key, t in full.items()}
    tall = max(t.shape[0] for t in tiles.values())
    close_h = 420
    page = rs.canvas(W, 70 + tall + 60 + 36 + close_h + 50, rs.rgb(paper))
    text = [(gap, 16, 20, "Her gear from behind, at the same pixels a stud as an Anime Vanguards unit (reference, a front view: "
                         "the reference holds none from behind). Today, then 1 and 2.", ink)]
    rs.fill(page, 0, 56, W, tall + 14, rs.rgb(pale))
    x = gap
    rs.paste(page, av, x, 56 + tall - av.shape[0])
    x += av.shape[1] + gap
    for k in "ABC":
        for v, said in (views[0], views[2]):   # from behind her left is in the close-ups below
            t = tiles[(k, v)]
            rs.paste(page, t, x, 56 + tall - t.shape[0])
            text.append((x, 56 + tall + 22, 14, f"{rmt.SAID[k][0]}, {said}", soft))
            x += t.shape[1] + 10
        x += gap
    # the hilts up close: each back view's top at its own size, twice the size above
    y = 56 + tall + 60
    text.append((gap, y, 18, "The hilts and sheaths up close: from behind and from behind her left, twice the size above.", ink))
    x = gap
    for k, v in ((k, v) for k in "ABC" for v in ("back", "back34")):
        t = full[(k, v)]
        mid = t.shape[1] // 2
        close = t[: close_h, max(0, mid - 190): mid + 190]
        rs.paste(page, close, x, y + 36)
        text.append((x, y + 36 + close.shape[0] + 8, 14, rmt.SAID[k][0], soft))
        x += close.shape[1] + 12
    rs.paste(page, rs.text_layer(W, page.shape[0], text), 0, 0)
    rs.save(page, rmt.internal("kirra_gear_back_beside.png"))
    # the faces: Rook's, Kirra's today and her two, and Pip's take (its own face comes with AR63's make)
    busts = [(rmt.SAID[k][0], shots / f"{k}_bust.png") for k in ("Rook", "A", "B", "C")]
    pip = rmt.REPO / "build" / "scratch" / "modulo" / "pip" / "shots" / "A_bust.png"
    if pip.exists():
        busts.append(("Pip, take A (the kit's face)", pip))
    imgs = [(name, rs.load(p)) for name, p in busts]
    bw = imgs[0][1].shape[1]
    face_page = rs.canvas(W, 700, rs.rgb(paper))
    text = [(gap, 16, 20, "The faces in the lead card's pose: half size, then at the card's size on the smallest phone and twice it.", ink)]
    x = gap
    for name, img in imgs:
        half = rs.shrink(img, 0.5)
        rs.paste(face_page, half, x, 56)
        small, twice = rs.shrink(img, rmt.CARD), rs.shrink(img, rmt.CARD * 2)
        rs.paste(face_page, small, x, 56 + half.shape[0] + 12)
        rs.paste(face_page, twice, x + small.shape[1] + 10, 56 + half.shape[0] + 12)
        text.append((x, 56 + half.shape[0] + 12 + twice.shape[0] + 8, 14, name, soft))
        x += half.shape[1] + gap
    rs.paste(face_page, rs.text_layer(W, face_page.shape[0], text), 0, 0)
    rs.save(face_page, (out / "kirra_faces.png").resolve())


def recipe_joints(recipe):
    """The blades' and the chain's joints, as the first Kirra's recipe gave them (kirra_model.export)."""
    pts, along, across, *_ = tail_frames()
    for entry in recipe["pieces"]:
        piece = entry["name"][len(NAME) + 1:]
        if piece in BLADES:
            top, d, back = sheath_line(BLADES[piece])
            at = top + d * ks.GRIP
            entry.update({"motor": piece, "pivot": turn(at), "grip": {"at": turn(at), "length": turn(d), "back": turn(back)}})
        elif piece.startswith("Scarf") and piece[5:].isdigit():
            j = int(piece[5:]) - 1
            entry.update({"motor": piece, "pivot": turn(pts[j * PER]), "along": turn(along[j * PER]), "across": turn(across[j * PER])})
    recipe["scarf"] = {
        "joints": [f"Scarf{k + 1}" for k in range(LINKS)], "length": round(sum((b - a).length for a, b in zip(pts, pts[1:])), 3),
        "note": "The long tail is a chain: each link rides a Motor6D at its root, named as the piece, on the link before it "
                "(the first on the Torso, at the knot), so they're made root to tip. A joint's frame is its pivot with the "
                "model's axes at rest. With every Transform at rest the tail hangs as drawn, back past her left shoulder and "
                "down behind her. 'along' is the band's line at the pivot and 'across' its width. Each link runs a step past "
                "its end into the next, so a bend opens no gap. The turn round her neck, the knot and the short tail are the "
                "Kirra_Scarf piece on the Torso. It casts a shadow."}
    recipe["blades"] = {
        "note": "Each blade is one piece on a Motor6D of its own on the Torso, named in 'motor', its frame at 'pivot' (the "
                "grip's middle) with the model's axes at rest. With its Transform at rest it lies crossed on her back, under "
                "the strap, on the first Kirra's line; a clip that draws it keys it into her fist and puts it back. 'grip' is "
                "the blade's frame at rest: 'length' from pommel to point, 'back' its spine. No sheaths: the steel is bare."}
    return recipe


def points():
    pts = tail_frames()[0]
    out = [("Knot", "Torso", kt.KNOT, "the scarf's knot: Scarf Step's line leaves from here"),
           ("ScarfTip", f"{NAME}_Scarf{LINKS}", tuple(pts[-1]), "the long tail's end"),
           ("Chest", "Torso", (0, 0.6, 3.2), "where a hit lands")]
    for piece, side in BLADES.items():
        top, d, _ = sheath_line(side)
        out.append((f"Tip{piece[-1]}", f"{NAME}_{piece}", tuple(top + d * TIP), "the blade's point: a cut's arc"))
    return out


PICK = dict(gear=None, face=None)   # research's pick of the reopened targets: lacquer or knives; kt.face_cut or kt.face_still


def made_pieces():
    return gear_pieces(PICK["gear"]) if PICK["gear"] else pieces


def finish(key, made, out):
    sheathed = {"Sheaths": ("Sheaths", "Torso")} if PICK["gear"] else {}
    extra = {"Scarf": ("Scarf", "Torso"), "Tie": ("Tie", "Head"), **{p: (p, "Torso") for p in BLADES}, **sheathed,
             **{f"Scarf{k + 1}": (f"Scarf{k + 1}", "Torso" if k == 0 else f"{NAME}_Scarf{k}") for k in range(LINKS)}}
    hand = out / "handoff"
    recipe = am.handoff(NAME, made, hand, points(), extra=extra,
                        make="tools/blender/anime_make.py and kirra_make.py: R6's own blocks and round head with the clothes and "
                             "the face drawn on them, the hair one mesh with its tie; built pieces: the scarf's turn and knot, "
                             "its long tail as a chain, the two blades on joints of their own"
                             + (", their sheaths one piece on the torso." if PICK["gear"] else "."))
    (hand / f"{NAME}.recipe.json").write_text(json.dumps(recipe_joints(recipe), indent=1))
    folder = hand / "model"
    folder.mkdir(parents=True, exist_ok=True)
    (folder / f"{NAME}.recipe.json").write_text((hand / f"{NAME}.recipe.json").read_text())
    bpy.ops.wm.save_as_mainfile(filepath=str(folder / "kirra_model.blend"), copy=True)
    kt.measured(key, made)


def model_run(out):
    rmt.TAKES[TAKE] = lambda joints, folder: kt.take_a(joints, folder, pieces=made_pieces(), face_draw=PICK["face"])
    rmt.takes_run(out, [TAKE], finish=lambda key, made: finish(key, made, out))


def sheet_run(out):
    rmt.proof_run(out, TAKE, title="KIRRA IN THE MAKE: THE MODEL FOR THE INSTALL", about="Common / Blue / Assassin / Void.",
                  whose="her", stem="kirra_make", beside=list(kt.BESIDE), tag="AR60: the finish")
    proof = rs.load(out / "kirra_make.png")
    recipe = json.loads((out / "handoff" / f"{NAME}.recipe.json").read_text())
    gap, W, side = 24, proof.shape[1], 560
    ink, soft, paper = "#EDE6D6", "#B4AC9C", "#101117"
    low = rs.canvas(W, 60 + side + 30, rs.rgb(paper))
    text = [(gap, 14, 18, "What goes up: the one picture every piece wears, at 0.55 of its size. Nothing of hers glows.", ink)]
    x = gap
    rs.paste(low, rs.shrink(rs.load(out / "handoff" / recipe["maps"]["Color"]), side / am.ATLAS), x, 50)
    text.append((x, 50 + side + 8, 14, recipe["maps"]["Color"], soft))
    x += side + gap
    facts = [f"{recipe['tris']} triangles in {len(recipe['pieces'])} pieces", f"{recipe['texels_per_stud']} texels a stud on the body",
             "pieces: " + ", ".join(f"{p['name'][len(NAME) + 1:]} {p['tris']}" for p in recipe["pieces"][:9]),
             "  " + ", ".join(f"{p['name'][len(NAME) + 1:]} {p['tris']}" for p in recipe["pieces"][9:]),
             "joints of their own: BladeR, BladeL (on the Torso, at the grip),",
             f"  Scarf1 to Scarf{LINKS} (a chain from the knot, {recipe['scarf']['length']} studs)",
             "points: " + ", ".join(p["name"] for p in recipe["points"])]
    text += [(x, 60 + i * 24, 15, line, soft) for i, line in enumerate(facts)]
    rs.paste(low, rs.text_layer(W, low.shape[0], text), 0, 0)
    whole = rs.canvas(W, proof.shape[0] + low.shape[0], rs.rgb(paper))
    whole[:proof.shape[0]], whole[proof.shape[0]:] = proof, low
    rs.save(whole, (out / "kirra_make_sheet.png").resolve())


if __name__ == "__main__":
    rmt.TAKES, rmt.SAID = dict(kt.TAKES), dict(kt.SAID)
    rmt.SAID[TAKE] = ("Kirra, the finish", ("A, the night runner, with research's three must-fixes",))
    OUT = rs.OUT = bl.out_dir()
    rest = sys.argv[sys.argv.index("--") + 2:]
    if rest and rest[0] == "targets":
        targets_run(OUT, rest[1:] or ("takes", "sheet"))
    else:
        {"model": model_run, "sheet": sheet_run}[rest[0] if rest else "model"](OUT)
