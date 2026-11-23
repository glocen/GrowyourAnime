"""AR54's look: the yard laid for Stage III's footprints, stood whole from the handoff and seen as a player sees it
(docs/asset-requests.md, AR54). The plan and its measure are base_fit's; this stands it and looks.

Every kit piece stands where the plan puts it, in the handoff's own pictures; every machine stands at its spot at the
stage its base's level gives it here (level 1, Stage I; level 3, Stage III), stood by the handoff's own stage tables;
and at levels 2 and 3 the levels' own pieces stand as base_levels.py stands them. Nothing is exported.

    guard.ps1 tools/blender/base_fit_look.py <abs out> see <1|2|3> [fast] [view ...]
    guard.ps1 tools/blender/base_fit_look.py <abs out> sheet

`see` writes <out>/yard<level>_<view>.png at the smallest phone's pixels (852 by 480), by day:
  player   the game's camera at its start zoom behind a player on the gate's line, 20 degrees down
  held     the builder's gate's eye of TR51's captures: 10 up, 11.5 before the gate's line, looking level
  left     the same camera behind a player before the ring, turned to the Breaker's side (the left, from the gate)
  right    and turned to the Door's side
  back     and behind the generator, looking on to the back wall
  strip    behind a visitor in the Strip's middle, facing the gate
  road     a level eye, 10 up, from the Strip's far side: the plate, read from the road
  above    from over the gate, looking down the yard
`sheet` writes base_fit_look.png (the frames, and each at 64 px high) and base_fit_plan.png (the plan from straight
above, every footprint at Stage III, with the measures).
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
KINDS = dict(generator="#FFD23E", breaker="#8CF6FF", door="#FF963C", bay="#788CFF", battery="#78FF8C",
             training="#FF6EA0", forge="#E6E6E6", condenser="#BE8CFF", lab="#5A5A6E", asleep="#46507A")
BEFORE, BEHIND = (0.0, 34.0), (0.0, base.ROW + base.RING + 7.0)   # where a player stands for the side views, and for the back's


def stand(yard, spots, level):
    """Every machine at its spot, each piece of its stage where the handoff's table stands it."""
    for name, (x, inward, turn) in spots.items():
        kind, stage = fit.shown(name, level)
        c, s = math.cos(math.radians(turn)), math.sin(math.radians(turn))
        for i, (piece, (across, front, up)) in enumerate(fit.rows(kind, stage)):
            yard.stock.stand(piece, f"{name}_{i}", (x + across * c - front * s, -inward + across * s + front * c, up), turn)
        if kind == "bay":                                           # a worker's size, on each bay that works
            yard.person((x, -inward), f"Worker{name}")


def toward(at, target):
    """The game's camera behind a player at `at` (across, inward), turned toward `target`."""
    from mathutils import Vector
    pitch = math.radians(20.0)
    way = Vector((target[0] - at[0], -(target[1] - at[1]), 0.0)).normalized()
    focus = Vector((at[0], -at[1], 3.0 + look.FOCUS))
    return tuple(focus - way * math.cos(pitch) * look.ZOOM + Vector((0, 0, math.sin(pitch) * look.ZOOM))), tuple(focus)


def see(out: Path, level, fast, only=()):
    import bpy  # noqa: F401
    spots = fit.PLAN
    look.SIZE = SIZE
    d = day.light("day")
    look.FOG.update(colour=look.srgb(d["fog"][0]), density=d["fog"][1], azimuth=d.get("glow_az", 0.0),
                    away=look.srgb(d["fog_away"]) if "fog_away" in d else None)
    scene = bl.reset_scene()
    yard = plan.Yard(scene, level, fit.HAND / "maps")
    yard.kit.block("Lot", (plan.PLOT, plan.PLOT, 0.4), (0, -plan.PLOT / 2, -0.23), yard.flat["lot"])
    for i, (name, x, along, turn) in enumerate(plan.plan(1)[0]):
        yard.stock.stand(name, f"K{i}", (x, along, 0.0), turn)
    stand(yard, spots, level)
    for i, (name, x, inward, up, turn, lean) in enumerate(base.levels.stood(level)):
        obj = yard.stock.stand(name, f"G{i}", (x, -inward, up), turn)
        if lean is not None:                                        # a ring afloat, tilted
            obj.rotation_euler = lean.to_euler()
    yard.kit.block("Strip", (3 * plan.PLOT, plan.STRIP, 0.4), (0, plan.STRIP / 2, -0.22), yard.stone)
    yard.kit.block("Ground", (5 * plan.PLOT, 4 * plan.PLOT, 0.4), (0, plan.STRIP / 2, -0.3), yard.flat["ground"])
    for obj in yard.kit.pieces:
        if obj.name.startswith(("PowerSpan", "Floor") + base.levels.FLAT):
            obj.visible_shadow = False
    height, back = fit.HELD
    mid = plan.STRIP / 2
    views = {"held": ((0.0, back, height), (0.0, -100.0, height)), "player": plan.behind((0.0, 0.0), -1),
             "left": toward(BEFORE, spots["bay3"][:2]), "right": toward(BEFORE, spots["training"][:2]),
             "back": toward(BEHIND, (0.0, plan.PLOT)),
             "strip": plan.behind((0.0, mid), -1), "road": ((0.0, plan.STRIP - 4.0, height), (0.0, -100.0, height)),
             "above": ((0.0, 8.0, 66.0), (0.0, -50.0, 0.0))}
    views = {name: view for name, view in views.items() if not only or name in only}
    stands = {"player": (0.0, 0.0), "strip": (0.0, mid), "left": (BEFORE[0], -BEFORE[1]), "right": (BEFORE[0], -BEFORE[1]),
              "back": (BEHIND[0], -BEHIND[1])}
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
        path = out / f"yard{level}_{name}"
        rs.save(look.finish(look.render_linear(scene, path.with_suffix(".exr")), d), path.with_suffix(".png"))
        path.with_suffix(".exr").unlink(missing_ok=True)
    print(f"AR54: the yard at level {level} done, {len(yard.kit.pieces)} objects")


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


def measures():
    """The plan's measures, as the sheet's lines."""
    spots, made = fit.PLAN, []
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


ROWS = (("yard1_player", "Level 1, every machine at Stage I: the game's camera behind a player on the gate's line"),
        ("yard3_player", "Level 3, every machine at Stage III: the same camera"),
        ("yard1_above", "Level 1, from over the gate"), ("yard3_above", "Level 3, from over the gate"),
        ("yard3_left", "Level 3, a player before the ring, turned to the Breaker's side"),
        ("yard3_right", "Level 3, the same player, turned to the Door's side"),
        ("yard1_back", "Level 1, a player behind the generator, looking on to the back"),
        ("yard3_strip", "Level 3, a visitor in the Strip's middle"),
        ("yard1_held", "The plate from inside, the builder's held eye of TR51's captures: out of the gate's view"),
        ("yard1_road", "The plate from the Strip's far side, a level eye"))


def sheet(out: Path):
    rs.OUT = out
    w, h = SIZE
    pad, head, ground = 10, 24, (0.93, 0.93, 0.94)
    lines = (len(ROWS) + 1) // 2
    board = rs.canvas(2 * (w + pad) + pad, lines * (h + head) + pad + 30 + 2 * 70, ground)
    words = [(pad, 8, 17, "AR54's finish, the yard laid for Stage III: the floor's own pictures, the masts, the pylons "
              "and the plate, by day, at the smallest phone's pixels", "#16182A")]
    small = []
    for i, (name, what) in enumerate(ROWS):
        x, y = pad + (i % 2) * (w + pad), 30 + (i // 2) * (h + head) + head
        words.append((x, y - 18, 14, what, "#16182A"))
        file = out / f"{name}.png"
        if not file.exists():
            continue
        page = rs.load(file)
        page[..., 3] = 1.0
        rs.paste(board, page, x, y)
        small.append(rs.shrink(page, 64 / h))
    y = 30 + lines * (h + head) + 10
    for i, tile in enumerate(small):
        rs.paste(board, tile, pad + (i % 8) * (tile.shape[1] + 6), y + (i // 8) * 70)
    rs.paste(board, rs.text_layer(board.shape[1], board.shape[0], words), 0, 0)
    rs.save(board, out / "base_fit_look.png")

    px = 5
    side = int(fit.PLOT * px)
    board = rs.canvas(side + 2 * pad, side + 64 + 190, ground)
    words = [(pad, 8, 15, "AR54, the plan from above, the gate at the foot: every footprint at Stage III.", "#16182A"),
             (pad, 28, 13, "Red: the gate's 51 degrees. The frame: part 7's square. Dashed: the generator's own clear", "#16182A")]
    page, labels = drawn(fit.PLAN, px)
    rs.paste(board, page, pad, 56)
    words += [(pad + lx, 56 + ly, size, text, code) for lx, ly, size, text, code in labels]
    for i, line in enumerate(measures()):
        words.append((pad, 56 + side + 10 + i * 17, 12, line, "#16182A"))
    rs.paste(board, rs.text_layer(board.shape[1], board.shape[0], words), 0, 0)
    rs.save(board, out / "base_fit_plan.png")
    print("AR54: sheets done")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    if args[0] == "sheet":
        return sheet(out)
    see(out, int(args[1]), "fast" in args, tuple(a for a in args[2:] if a != "fast"))


if __name__ == "__main__":
    main()
