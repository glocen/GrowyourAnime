"""AR54's block-in: the yard's plan laid again for Stage III's footprints, seen from the gate (docs/asset-requests.md,
AR54). The plan and its measure are base_fit's; this stands it and looks.

Every machine stands at its spot in the kit's own model, each at the stage its base's level gives it here (level 1,
Stage I; level 3, Stage III), stood by the handoff's own stage tables. On AR54's plan the floor is the plain deck, and
the ground is blocked in over it: each machine's Stage III footprint as a pad, the generator's ring, and a line of
current from the heart to each machine (dark to what sleeps). The kit's floors are drawn for today's places, so the
floor's own pictures, the flood masts and the transformers wait for the finish. The gate's plate stands raised
(PLATE_UP), over the held eye's frame. Nothing is exported and no kit file is written over.

    guard.ps1 tools/blender/base_fit_block.py <abs out> see <plan|today> <1|3> [fast] [held] [player] [strip] [road] [above]
    guard.ps1 tools/blender/base_fit_block.py <abs out> sheet

`see` writes <out>/<plan|today><level>_<view>.png at the smallest phone's pixels (852 by 480), by day:
  held     the builder's gate's eye of TR51's captures: 10 up, 11.5 before the gate's line, looking level
  player   the game's camera at its start zoom behind a player on the gate's line, 20 degrees down
  strip    the same camera behind a visitor in the Strip's middle, facing the gate
  road     a level eye, 10 up, from the Strip's far side: the plate, read from the road
  above    from over the gate, looking down the yard
`sheet` writes base_fit_gate.png (the gate's eye at Stage I and Stage III, today's plan over AR54's, and each frame at
64 px high), base_fit_plan.png (both plans from straight above, every footprint at Stage III, with the measures) and
base_fit_plate.png (the plate from the gate and from the Strip).
"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_fit as fit  # noqa: E402
import base_light as day  # noqa: E402

plan, base, look, kit, bl = day.plan, day.base, day.look, day.kit, day.bl
rs = plan.rs

SIZE = fit.SIZE
PLANS = {"plan": fit.PLAN, "today": fit.TODAY}
NAMES = {"plan": "AR54's plan", "today": "Today's plan"}
PLATE_UP = 21.6                         # the plate's middle: its underside at 19.4, over the held eye's frame (18.8 there)
# AR54's lines of current: each machine's line comes from the heart, or on from the machine before it
LINES = dict(breaker="generator", door="generator", bay1="generator", bay2="generator", training="bay1", forge="bay2",
             bay6="bay1", condenser="generator", bay3="generator", bay4="bay3", lab="generator", battery="lab",
             bay5="generator")
FLOORS = {"Court1": "Yard", "YardLive": "Yard", "YardBack": "Yard", "WingsLive": "Wings", "WingsBack": "Wings"}
LIVE, DARK, PAD, ASLEEP = "#BFEFF5", "#2A2F45", "#A2A7BC", "#3A4154"
KINDS = dict(generator="#FFD23E", breaker="#8CF6FF", door="#FF963C", bay="#788CFF", battery="#78FF8C",
             training="#FF6EA0", forge="#E6E6E6", condenser="#BE8CFF", lab="#5A5A6E", asleep="#46507A")


def awake(name, level):
    return fit.shown(name, level)[0] not in ("asleep", "lab")


def stand(yard, spots, level):
    """Every machine at its spot, each piece of its stage where the handoff's table stands it."""
    for name, (x, inward, turn) in spots.items():
        kind, stage = fit.shown(name, level)
        c, s = math.cos(math.radians(turn)), math.sin(math.radians(turn))
        for i, (piece, (across, front, up)) in enumerate(fit.rows(kind, stage)):
            yard.stock.stand(piece, f"{name}_{i}", (x + across * c - front * s, -inward + across * s + front * c, up), turn)
        if kind == "bay":                                           # a worker's size, on each bay that works
            yard.person((x, -inward), f"Worker{name}")


def ground(yard, spots, level):
    """AR54's ground, blocked in over the plain deck: the pads, the ring and the lines."""
    import bpy
    live, dark = look.glowing("FitLive", LIVE, 1.6), look.painted("FitDark", DARK, DARK)
    pad, asleep = look.painted("FitPad", PAD, PAD), look.painted("FitAsleep", ASLEEP, ASLEEP)
    gx, gz, _ = spots["generator"]
    for name, (x0, x1, z0, z1, _) in fit.boxes(spots, 3).items():
        if name != "generator":
            yard.kit.block(f"FitPad{name}", (x1 - x0, z1 - z0, 0.05), ((x0 + x1) / 2, -(z0 + z1) / 2, 0.115),
                           pad if awake(name, level) else asleep)
    for name, source in LINES.items():
        (ax, az, _), (bx, bz, _) = spots[source], spots[name]
        if source == "generator":                                   # from the ring's edge
            reach = math.hypot(bx - ax, bz - az)
            ax, az = ax + (bx - ax) * base.RING / reach, az + (bz - az) * base.RING / reach
        length = math.hypot(bx - ax, bz - az)
        yard.kit.block(f"FitLine{name}", (length, 0.7, 0.03), ((ax + bx) / 2, -(az + bz) / 2, 0.075),
                       live if awake(name, level) else dark, rot=(0, 0, math.atan2(-(bz - az), bx - ax)))
    steps, verts, faces = 96, [], []
    for i in range(steps):
        a = 2 * math.pi * i / steps
        for r in (base.RING - 0.4, base.RING + 0.4):
            verts.append((gx + r * math.sin(a), -gz + r * math.cos(a), 0.09))
        j = 2 * i
        faces.append((j, j + 1, (j + 3) % (2 * steps), (j + 2) % (2 * steps)))
    mesh = bpy.data.meshes.new("FitRing")
    mesh.from_pydata(verts, [], faces)
    mesh.materials.append(live)
    ring = bpy.data.objects.new("FitRing", mesh)
    yard.scene.collection.objects.link(ring)
    yard.kit.pieces.append(ring)


def see(out: Path, which, level, fast, only=()):
    import bpy  # noqa: F401
    spots = PLANS[which]
    look.SIZE = SIZE
    if which == "plan":
        base.PLATE_UP = PLATE_UP
    d = day.light("day")
    look.FOG.update(colour=look.srgb(d["fog"][0]), density=d["fog"][1], azimuth=d.get("glow_az", 0.0),
                    away=look.srgb(d["fog_away"]) if "fog_away" in d else None)
    scene = bl.reset_scene()
    yard = plan.Yard(scene, level, fit.HAND / "maps")
    yard.kit.block("Lot", (plan.PLOT, plan.PLOT, 0.4), (0, -plan.PLOT / 2, -0.23), yard.flat["lot"])
    for i, (name, x, along, turn) in enumerate(plan.plan(1)[0]):
        if which == "plan":
            if name in ("FloodMast", "Transformer"):                # theirs are today's places: the finish's
                continue
            name = FLOORS.get(name, name)
        yard.stock.stand(name, f"K{i}", (x, along, 0.0), turn)
    stand(yard, spots, level)
    if which == "plan":
        ground(yard, spots, level)
    yard.kit.block("Strip", (3 * plan.PLOT, plan.STRIP, 0.4), (0, plan.STRIP / 2, -0.22), yard.stone)
    yard.kit.block("Ground", (5 * plan.PLOT, 4 * plan.PLOT, 0.4), (0, plan.STRIP / 2, -0.3), yard.flat["ground"])
    for obj in yard.kit.pieces:
        if obj.name.startswith(("PowerSpan", "Court", "Yard", "Wings", "Fit")):
            obj.visible_shadow = False
    height, back = fit.HELD
    mid = plan.STRIP / 2
    views = {"held": ((0.0, back, height), (0.0, -100.0, height)), "player": plan.behind((0.0, 0.0), -1),
             "strip": plan.behind((0.0, mid), -1), "road": ((0.0, plan.STRIP - 4.0, height), (0.0, -100.0, height)),
             "above": ((0.0, 30.0, 96.0), (0.0, -58.0, 0.0))}
    views = {name: view for name, view in views.items() if not only or name in only}
    stands = {"player": (0.0, 0.0), "strip": (0.0, mid)}
    for name in views:
        if name in stands:
            yard.person(stands[name], f"Stand{name}")
    look.sky(scene, d)
    look.sun(scene, d)
    r = scene.render
    for engine in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            r.engine = engine
            break
        except TypeError:
            continue
    r.resolution_x, r.resolution_y, r.resolution_percentage = *look.SIZE, 100
    scene.view_settings.view_transform = "Standard"
    scene.eevee.taa_render_samples = 8 if fast else 32
    for attr, val in (("use_shadows", True), ("shadow_ray_count", 2), ("use_raytracing", False)):
        try:
            setattr(scene.eevee, attr, val)
        except AttributeError:
            pass
    for name, (eye, target) in views.items():
        scene.camera = plan.camera(scene, name, eye, target)
        for obj in bpy.data.objects:                                # a player stands only in their own view
            if obj.name.startswith("Stand"):
                obj.hide_render = not obj.name.startswith(f"Stand{name}")
        path = out / f"{which}{level}_{name}"
        rs.save(look.finish(look.render_linear(scene, path.with_suffix(".exr")), d), path.with_suffix(".png"))
        path.with_suffix(".exr").unlink(missing_ok=True)
    print(f"AR54: {which} at level {level} done, {len(yard.kit.pieces)} objects")


# --- the sheets -----------------------------------------------------------------------------------------------------

def drawn(spots, px=5):
    """A plan from straight above, the gate at the foot: every footprint at Stage III, each spot, the way in, the
    square's edge, the gate's 51 degrees, the ring and the generator's own clear. Returns the picture and its words."""
    import numpy as np
    m, f = fit.measure(spots, 3), fit.fit_numbers()
    side = int(fit.PLOT * px)
    page = rs.canvas(side, side, look.srgb("#8E97AE")[:3])
    yy, xx = np.mgrid[0:side, 0:side]
    x, z = fit.PLOT / 2 - (xx + 0.5) / px, fit.PLOT - (yy + 0.5) / px   # as the gate sees it: across runs to the left

    def ink(mask, code, alpha=1.0):
        page[mask, :3] = page[mask, :3] * (1 - alpha) + np.array(look.srgb(code)[:3], np.float32) * alpha

    g = m["boxes"]["generator"]
    ink((np.abs(x) < f["Avenue"] / 2) & (z < g[2]), "#A9B2C8")                                   # the way in
    half = fit.PLOT / 2 - f["Margin"]
    edge = np.maximum.reduce([np.abs(x) - half, f["Apron"] - z, z - (fit.PLOT - f["Kept"])])
    ink(np.abs(edge) < 0.25, "#4A5270")                                                         # the square's edge
    slope = math.tan(math.radians(m["halfView"]))
    ink(np.abs(np.abs(x) - slope * (z + f["Back"])) < 0.3 * math.hypot(1, slope), "#E0483C")    # the gate's view
    gx, gz, _ = spots["generator"]
    r = np.hypot(x - gx, z - gz)
    ink(np.abs(r - base.RING) < 0.4, "#F6FCFF")
    ink((np.abs(r - m["ring"][0]) < 0.25) & ((np.arctan2(z - gz, x - gx) * 40 % 2) < 1), "#16182A")   # its own clear
    words = []
    for name, (x0, x1, z0, z1, _) in m["boxes"].items():
        kind = fit.kind_of(name)
        if kind == "bay" and int(name[3:]) > 4:
            kind = "asleep"
        inside = (x > x0) & (x < x1) & (z > z0) & (z < z1)
        ink(inside, "#16182A")
        ink(inside & (x > x0 + 0.3) & (x < x1 - 0.3) & (z > z0 + 0.3) & (z < z1 - 0.3), KINDS[kind])
        sx, sz, _ = spots[name]
        ink(np.hypot(x - sx, z - sz) < 0.7, "#16182A")
        words.append((int((fit.PLOT / 2 - x1) * px) + 4, int((fit.PLOT - z1) * px) + 5, 11, name,
                      "#F6FCFF" if kind in ("asleep", "lab") else "#16182A"))
    return page, words


def lines_of(which):
    """A plan's measures, as the sheet's lines."""
    spots, made = PLANS[which], []
    for stage in (1, 2, 3):
        m = fit.measure(spots, stage)
        d, a, b = m["least"][0]
        made.append(f"Stage {'I' * stage}: {'PASS' if m['passes'] else 'FAIL'}. Least clear {d} ({a} to {b}); widest corner "
                    f"{m['widest'][0]} of {m['halfView']} ({m['widest'][1]}); the Breaker {m['breaker']} s")
    m = fit.measure(spots, 3)
    made.append(f"The generator's own clear: {m['ring'][0]} from its spot (to the {m['ring'][1]}); the kit's ring is {base.RING:g}")
    for level in (1, 3):
        shares, _ = fit.seen(spots, level)
        made.append(f"Seen by the game's camera at the gate, level {level} (and its top):")
        row = [f"{n} {round(100 * shares[n][0])}% ({round(100 * shares[n][1])}%)" for n in fit.TOUCHED[level]
               if n not in ("breaker", "door")]
        made += ["   " + ", ".join(row[:4]), "   " + ", ".join(row[4:])]
    return made


def sheet(out: Path):
    rs.OUT = out
    w, h = SIZE
    pad, head, ground = 10, 24, (0.93, 0.93, 0.94)
    rows = [("today", "player", "Today's plan, the game's camera behind a player on the gate's line"),
            ("plan", "player", "AR54's plan, the same camera"),
            ("plan", "held", "AR54's plan, the builder's held eye of TR51's captures, to compare with them")]
    board = rs.canvas(2 * (w + pad) + pad, len(rows) * (h + head) + pad + 30 + 80, ground)
    words = [(pad, 8, 17, "AR54, the yard at Stage III: from the gate, by day, the smallest phone's pixels. Left: level 1, "
              "every machine at Stage I. Right: level 3, every machine at Stage III", "#16182A")]
    small = []
    for row, (which, view, what) in enumerate(rows):
        y = 30 + row * (h + head) + head
        words.append((pad, y - 18, 14, what, "#16182A"))
        for col, level in enumerate((1, 3)):
            file = out / f"{which}{level}_{view}.png"
            if not file.exists():
                continue
            page = rs.load(file)
            page[..., 3] = 1.0
            rs.paste(board, page, pad + col * (w + pad), y)
            small.append(rs.shrink(page, 64 / h))
    y = 30 + len(rows) * (h + head) + 10
    for i, tile in enumerate(small):
        rs.paste(board, tile, pad + i * (tile.shape[1] + 6), y)
    rs.paste(board, rs.text_layer(board.shape[1], board.shape[0], words), 0, 0)
    rs.save(board, out / "base_fit_gate.png")

    px = 5
    side = int(fit.PLOT * px)
    board = rs.canvas(2 * (side + pad) + pad, side + 64 + 190, ground)
    words = [(pad, 8, 17, "AR54, the plan from above, the gate at the foot: every footprint at Stage III. Red: the gate's 51 "
              "degrees. The frame: part 7's square. Dashed: the generator's own clear", "#16182A")]
    for col, which in enumerate(("today", "plan")):
        x = pad + col * (side + pad)
        page, labels = drawn(PLANS[which], px)
        rs.paste(board, page, x, 56)
        words.append((x, 34, 15, NAMES[which], "#16182A"))
        words += [(x + lx, 56 + ly, size, text, code) for lx, ly, size, text, code in labels]
        for i, line in enumerate(lines_of(which)):
            words.append((x, 56 + side + 10 + i * 17, 12, line, "#16182A"))
    rs.paste(board, rs.text_layer(board.shape[1], board.shape[0], words), 0, 0)
    rs.save(board, out / "base_fit_plan.png")

    shots = [("today1_held", "Today, from the gate: the name is cut"), ("plan1_held", f"Raised to {PLATE_UP:g}: out of the gate's view"),
             ("plan1_strip", "Raised, the game's camera from the Strip's middle"), ("plan1_road", "Raised, a level eye from the Strip's far side")]
    board = rs.canvas(2 * (w + pad) + pad, 2 * (h + head) + pad + 30, ground)
    words = [(pad, 8, 17, "AR54, the gate's plate (TR51's must-fix 1): raised over the truss on two posts", "#16182A")]
    for i, (name, what) in enumerate(shots):
        x, y = pad + (i % 2) * (w + pad), 30 + (i // 2) * (h + head) + head
        words.append((x, y - 18, 14, what, "#16182A"))
        file = out / f"{name}.png"
        if file.exists():
            page = rs.load(file)
            page[..., 3] = 1.0
            rs.paste(board, page, x, y)
    rs.paste(board, rs.text_layer(board.shape[1], board.shape[0], words), 0, 0)
    rs.save(board, out / "base_fit_plate.png")
    print("AR54: sheets done")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    if args[0] == "sheet":
        return sheet(out)
    see(out, args[1], int(args[2]), "fast" in args, tuple(a for a in args[3:] if a != "fast"))


if __name__ == "__main__":
    main()
