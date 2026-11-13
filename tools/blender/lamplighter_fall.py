"""The Lamplighter's fall: delivery 4 (AR7: "Its fall: the Shade's burst into light and paper at keeper size, with the
lantern's light going out last. No wounds, nothing left behind"), its block clip polished to the final.

blender.exe -b --factory-startup --python tools/blender/lamplighter_fall.py -- <out_dir> [poses|export|audit]

The keeper's own Down, keyed as lamplighter_clips.py keys its clips, on its pole and lantern. It is the Shade's Burst at
its scale and its weight: struck, it sags onto its pole; then the mask lets go and it tips back to the sky, dragging the
pole over with it, and the game hides the body at Burst, where the Shade's burst plays at keeper size. The pole stays
planted where it stood: let go, it springs back past upright and wobbles out, each swing about half the last, and the
lantern hangs on it, still lit, swinging after it and steadying, alone. It gutters (Gutter) and goes out (Out), and then
the pole and the lantern go to paper too (Gone), so nothing is left behind.
- poses: the key poses from the fight's camera and its left side, the body hidden from Burst as the game hides it; and
  the pole's lean frame by frame, from the mask's let-go until it stands.
- export, audit: as lamplighter_clips.py, for this clip alone (Lamplighter_Down.json, named LamplighterDown).
"""
import math
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
import lamplighter_clips as lc  # noqa: E402

READY = lc.READY
ALONG = 2.5  # how far up the pole the hidden hand holds it while the pole rocks
TOWARD = -105.0  # the heading from the pole's foot to the keeper, a little behind it: the way it falls
# The rock once let go (research: "it must read as let go, not as pushed"): a planted pole sprung back, its lean on
# each turn, degrees toward the keeper (minus: away), each swing about half the last, then still. A sine between turns
# is the spring's own motion, at rest on each turn and fastest through upright.
ROCK = ((34, 9.0), (40, -4.0), (46, 1.8), (52, -0.8), (58, 0.0))
# the hidden body at its ready, a quarter stud toward the pole, so its arm reaches the first swing away
HIDDEN_T = (*READY["T"][:3], READY["T"][3] + 0.25, *READY["T"][4:])


def rock(t, f, lean, hint, label=None, ease="sine", **changes):
    """Keys the body at clip frame `f` with the hand putting the grip where the planted pole leans `lean` degrees toward
    the keeper (TOWARD). An arm turns at its shoulder and can't reach every place, so its aim is solved, not given:
    aimed ALONG up the leant pole, measured, and moved by what the grip missed, until it misses by under 0.005."""
    x, fw, _ = t.props["plant"]
    a, h = math.radians(lean), math.radians(TOWARD)
    way = (math.sin(a) * math.sin(h), math.sin(a) * math.cos(h), math.cos(a))
    aim = [x + ALONG * way[0], fw + ALONG * way[1], ALONG * way[2]]
    for tries in range(8):
        keys, beats = len(t.keys), len(t.beats)
        t.key(f, label, ease, RA=("grip", tuple(aim), hint), **changes)
        bpy.context.scene.frame_set(t.start + f)
        bpy.context.view_layer.update()
        g = lc.grip_at(t.motors)
        got = (g.x, -g.z, g.y)
        r = math.dist(got, (x, fw, 0.0))
        miss = [p + r * w - q for p, w, q in zip((x, fw, 0.0), way, got)]
        if max(abs(m) for m in miss) < 0.005 or tries == 7:
            print(f"  the rock's turn at {f}: lean {lean:+g}, the grip {r:.2f} up the pole, missed by "
                  f"{max(abs(m) for m in miss):.3f} after {tries + 1} aims")
            return t
        del t.keys[keys:], t.beats[beats:]  # tried, not kept: the next try keys the frame over
        aim = [p + m for p, m in zip(aim, miss)]


def down(t):
    """It took every blow on its pole, and this one it can't. Rocked back, it sags onto the pole and hangs there, the
    head going under the brim. Then whatever held it lets go, the mask first, tipped back until its face is to the
    sky, the pole dragged over with it, the coat opening after it, and it is light and paper. The pole stays where it
    was planted: with nothing on it, it springs back past upright and wobbles out, the lantern lit on its hook,
    swinging after it and steadying. It gutters and goes out, and then the pole goes too."""
    t.key(0, ease="out")
    t.pole(0, under=True)  # planted straight under the grip, as Hit's: it stands upright where the hidden arm leaves it
    # the planted pole carries the grip's jolt about three times up to its hook, so the blow is Hit's size at the
    # shoulder, and the lantern is held back from flinging over its hook
    t.key(4, "struck", ease="sine", T=(-5, -13, -2, 0, 0, -0.1), crouch=0.1, H=(-12, 8, 8), LA=(-44, 0, -30),
          RA=(42, 0, 29))
    t.lamp(0)
    t.lamp(4, "sine", (-20.0, 0.0), 0.5)
    t.lamp(12)
    t.key(16, "onto its pole", ease="sine", T=(14, -2, -9, 0.1, 0, 0.08), crouch=0.22, H=(30, 0, 6), LA=(-4, 0, -10),
          RA=(52, 0, 30))
    t.key(26, "the mask lets go", ease="in", T=(0, -4, -2, 0.04, 0, 0.0), crouch=0.14, H=(-40, 3, 2), LA=(-46, 0, -10),
          RA=(36, 0, 32))
    # tipping back, it drags the pole over with it, the hand still on it
    rock(t, 34, ROCK[0][1], (26, 0, 34), "its face to the sky", T=(-10, -2, 0, 0, 0, 0.08), crouch=0.08,
         H=(-62, 2, 0), LA=(-72, 0, -8))
    t.mark(34, "Burst")
    # Hidden from here: the unseen body stands back at its ready on the first turn and holds, and only the hand moves,
    # putting the grip where each turn of the rock leans the pole
    rock(t, ROCK[1][0], ROCK[1][1], READY["RA"], "let go, sprung back", T=HIDDEN_T, crouch=READY["crouch"],
         H=READY["H"], LA=READY["LA"])
    for f, lean in ROCK[2:-1]:
        rock(t, f, lean, READY["RA"])
    rock(t, ROCK[-1][0], ROCK[-1][1], READY["RA"], "the pole stands")
    t.key(64, "it gutters")
    t.mark(64, "Gutter")
    t.key(80, "out")
    t.mark(80, "Out")
    t.mark(88, "Gone")
    t.key(96)


def pose_sheet(scene, cams, take, out):
    """lamplighter_clips.pose_sheet with the body hidden from Burst, as the game hides it: the pole and the lantern
    stay."""
    burst = take.start + next(round(s * lc.FPS) for s, name in take.markers if name == "Burst")
    body = [o for o in bpy.data.objects if o.name.startswith(f"{lc.NAME}_") and o.name not in (lc.POLE, lc.LAMP)]

    def hide(scene, *_):
        for o in body:
            o.hide_render = scene.frame_current > burst  # shown on the Burst frame itself, as the flare covers it

    bpy.app.handlers.frame_change_post.append(hide)
    try:
        SHEET(scene, cams, take, out)
        # the rock, every second frame from the fight's camera: dragged over, let go, sprung back, wobbling out
        shots = [(cams["fight"], take.start + f, f"{f}") for f in range(30, 62, 2)]
        scene.render.resolution_x, scene.render.resolution_y = 200, 240
        print(f"wrote {lc.r6.render_shots(scene, shots, out / f'rock_{take.name}.png', columns=8)}")
    finally:
        bpy.app.handlers.frame_change_post.remove(hide)
        for o in body:
            o.hide_render = False


SHEET = lc.pose_sheet
PROPS = lc.props


def props(rig, ctl, motors, rest, takes):
    """lamplighter_clips.props, then the pole's lean frame by frame, degrees toward the keeper (minus: away), from the
    mask's let-go until it stands: the rock's measure."""
    facts = PROPS(rig, ctl, motors, rest, takes)
    for take in takes:
        line = []
        for f in range(24, 67, 2):
            bpy.context.scene.frame_set(take.start + f)
            v = ctl["plant"].location
            u = (lc.grip_at(motors) - lc.W(v.x, v.y)).normalized()
            lean = math.degrees(math.acos(max(-1.0, min(1.0, u.y))))
            toward = math.degrees(math.atan2(u.x, -u.z))
            line.append(f"{f} {lean * math.cos(math.radians(toward - TOWARD)):+.1f}")
        print(f"  the pole's lean toward the keeper: {', '.join(line)}")
    return facts


EXPORT = lc.r6.export


def export(*args, **kwargs):
    """r6anim.export, its Source this script: the clip traces to what made it."""
    return EXPORT(*args, **{**kwargs, "source": "tools/blender/lamplighter_fall.py"})


if __name__ == "__main__":
    lc.CLIPS.clear()
    lc.CLIPS["Down"] = (down, READY)
    lc.pose_sheet = pose_sheet
    lc.props = props
    lc.r6.export = export
    lc.main()
