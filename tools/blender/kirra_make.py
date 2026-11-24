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
import blcommon as bl  # noqa: E402
import kirra_make_takes as kt  # noqa: E402
import kirra_sheet as ks  # noqa: E402
import rook_make_takes as rmt  # noqa: E402
import rook_sheet as rs  # noqa: E402

NAME, TAKE = "Kirra", "A"
LINKS, PER = 8, 12            # the tail's links, and its points to a link
THICK = (0.05, 0.046)         # by turns, so two links' overlap never shares a plane
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
        b.ribbon([pts[i] for i in idx], [widths[i] for i in idx], lambda v, idx=idx: shade_(u[idx[0]] + v * (u[idx[-1]] - u[idx[0]])),
                 side=across[idx[0]], thick=THICK[j % 2], turn=[twist[i] - twist[idx[0]] for i in idx])
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


def finish(key, made, out):
    extra = {"Scarf": ("Scarf", "Torso"), "Tie": ("Tie", "Head"), **{p: (p, "Torso") for p in BLADES},
             **{f"Scarf{k + 1}": (f"Scarf{k + 1}", "Torso" if k == 0 else f"{NAME}_Scarf{k}") for k in range(LINKS)}}
    hand = out / "handoff"
    recipe = am.handoff(NAME, made, hand, points(), extra=extra,
                        make="tools/blender/anime_make.py and kirra_make.py: R6's own blocks and round head with the clothes and "
                             "the face drawn on them, the hair one mesh with its tie; built pieces: the scarf's turn and knot, "
                             "its long tail as a chain, the two blades on joints of their own.")
    (hand / f"{NAME}.recipe.json").write_text(json.dumps(recipe_joints(recipe), indent=1))
    folder = hand / "model"
    folder.mkdir(parents=True, exist_ok=True)
    (folder / f"{NAME}.recipe.json").write_text((hand / f"{NAME}.recipe.json").read_text())
    bpy.ops.wm.save_as_mainfile(filepath=str(folder / "kirra_model.blend"), copy=True)
    kt.measured(key, made)


def model_run(out):
    rmt.TAKES[TAKE] = lambda joints, folder: kt.take_a(joints, folder, pieces=pieces)
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
    {"model": model_run, "sheet": sheet_run}[rest[0] if rest else "model"](OUT)
