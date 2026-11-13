"""Rook's Haymaker struck down: B5's block clip (AR8, part B; AR1, section 9). The director, 2026-11-12: "let keep A
and do B5 later like a planned rework": the ram's square hung over the target through the hold and slammed down on
the blow, Rook's clip striking down, the target pinned. Moved into the effects pass, 2026-11-13.

blender.exe -b --factory-startup --python tools/blender/rook_haymaker_down.py -- <out_dir> [poses|export|audit|bare|stamp|path|compare <old json>]

- poses, export, audit, bare: as rook_clips.py, for this one clip. export writes Rook_Haymaker.json under the
  delivered clip's own name (RookHaymaker), so it drops into the replay in its place.
- stamp: rook_haymaker_stamp.py's B5 sheets (the game's camera, the headings, 64 px) on the exported clip in <out_dir>.
- path: the ram's face frame by frame through the hold and the blow, and how far off upright each frame's move is.
- compare: the hold and the blow from his side and from the game's, the clip at <old json> beside the one in <out_dir>.

The delivered clip's length and markers (Charge 8, Strike 57, Shock 58, Step 63, Vent 70) and its long hold; only the
blow changes. A, as delivered, draws the ram back at the camera and punches straight out, 3.4 studs short of the
target, at right angles to a square falling from above. Here the ram goes up over his head through the hold while the
square hangs over the target, and on Strike he drives it straight down into the floor in front of him: the square
comes down with it. One line from his fist to the stamp, the same way, on the same frame.

The polish (research's fixes 1 and 2, AR8 B5): the hold creeps, the ram hauled higher and tipped further back until 52,
the most cocked frame, twice as fast after 44; then over the top by 54 and one upright line down onto the floor, so
the last frames drop vertically on screen.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import rook_clips as rc  # noqa: E402

MARK = rc.MARK
FLOOR = (1.6, 2.9, 0.1)  # where the ram's face meets the floor on Strike: in front of his right foot, clear of his
# legs, short of the target (6)
OVER = (60, 0, 34)       # the arm's hint for reaching it: down and in front, the elbow out
# the ram's face on the way down (research's fix 2): over the top by 54, then one upright line onto FLOOR
HIGH, MID, LOW = (1.9, 2.3, 5.1), (1.8, 2.35, 3.6), (1.8, 2.25, 2.1)


def haymaker(t):
    """He hauls the ram up over his head until the piston creaks open, the taped arm thrown out to mark you, waits a
    beat too long, sinking under it, and then drives it straight down into the floor like a pile driver."""
    t.key(0)
    t.key(8, ease="cubic", T=(4, -10, 0, 0, 0, 0.05), RA=(84, 0, 16), LA=(56, 0, -42), crouch=0.18)
    t.mark(8, "Charge")
    t.key(34, "the ram up", ease="lin", T=(-4, -16, 8, 0, 0, -0.1), RA=(172, 0, 4), LA=("reach", MARK, (-10, 0, -76)),
          crouch=0.24, P=0.25, feet={"Right Leg": (0.62, -0.7)}, TP=(8, 0, 0))  # the hold builds (research's fix 1):
    t.key(44, ease="lin", T=(-10, -18, 9, 0, 0, -0.2), RA=(182, 0, 4), crouch=0.06, P=0.55)  # hauled up, rising
    t.key(52, "the beat too long", ease="lin", T=(-22, -24, 14, 0, 0, -0.42), RA=(198, 0, 4), crouch=0.04, P=0.85,
          TP=(-6, 0, 0))  # then tipped back as he leans off under it: the whole hold creeps, and 52 is the most cocked
    # the blow (fix 2): over the top by 54, then straight down onto the floor, so the last frames drop upright on screen
    t.key(54, ease="lin", T=(0, -8, 4, 0, 0, 0.06), RA=("reach", HIGH, (150, 0, 10)), LA=(14, 0, -58), crouch=0.08,
          TP=(0, 0, 10))  # the taped arm lets go of its mark as he comes over
    t.key(55, ease="lin", T=(12, -2, 0, 0, 0, 0.15), RA=("reach", MID, (100, 0, 20)), LA=(30, 0, -42), crouch=0.2,
          TP=(0, 0, 20))
    t.key(56, ease="lin", T=(24, 2, -3, 0, 0, 0.3), RA=("reach", LOW, (75, 0, 28)), crouch=0.3)
    t.key(57, "driven down", T=(34, 4, -5, 0, 0, 0.45), RA=("reach", FLOOR, OVER), LA=(-16, 0, -38), crouch=0.34,
          feet={"Left Leg": (-0.55, 0.7)}, TP=(-25, 0, 0))
    t.mark(57, "Strike")
    t.key(58, only="P", P=0.0)
    t.mark(58, "Shock")
    t.key(63, "his weight on it", T=(30, 8, -3, 0, 0, 0.48), RA=("reach", FLOOR, OVER), LA=(-24, 0, -40), crouch=0.3,
          feet={"Right Leg": (0.64, -0.55)}, TP=(15, 0, 0))
    t.mark(63, "Step")
    t.mark(70, "Vent")
    t.key(76, ease="cubic", T=(22, 6, 0, 0, 0, 0.5), RA=(52, 0, 18), crouch=0.32, TP=(0, 0, 0))
    t.key(100, T=(8, 4, 0, 0, 0, 0.3), RA=(36, 0, 22), LA=(30, 0, -10), crouch=0.16,
          feet={"Right Leg": (0.7, -0.2), "Left Leg": (-0.55, 0.6)})
    t.key(120, T=rc.HUB["T"], RA=rc.HUB["RA"], LA=rc.HUB["LA"], crouch=rc.HUB["crouch"], feet=rc.HUB["feet"])


def stamp():
    """B5's sheets on this clip: rook_haymaker_stamp.py with its clip swapped for the one exported here."""
    import rook_haymaker_stamp as st
    st.CLIP = Path(sys.argv[sys.argv.index("--") + 1]).resolve() / "Rook_Haymaker.json"
    if not st.CLIP.exists():
        raise SystemExit(f"No {st.CLIP}: run the export first")
    sys.argv += ["B5"]
    st.main()


def path():
    """The ram's face frame by frame, in stage directions (right, forward, up), from the hold to his weight on it; and
    how far off straight down each frame's move is, seen from his side, where a forward move shows most."""
    import math

    import r6anim as r6
    from mathutils import Vector
    scene, rig, costume, undress, feet = rc.build()
    take = rc.Take(rig, feet, "Haymaker", 0)
    haymaker(take)
    rc.ground(rig, feet, [take])
    before = None
    for f in range(30, 66):
        scene.frame_set(f)
        p = r6.to_roblox(rig.parts["Right Arm"].matrix_world) @ Vector(rc.KNUCKLES)
        at = (p.x, -p.z, p.y)  # right, forward, up
        line = f"{f}: right {at[0]:5.2f} forward {at[1]:5.2f} up {at[2]:5.2f}"
        if before is not None:
            d = [a - b for a, b in zip(at, before)]
            line += (f"   moved {math.hypot(*d):4.2f}: forward {d[1]:5.2f} up {d[2]:5.2f}, "
                     f"{math.degrees(math.atan2(abs(d[1]), abs(d[2]))):3.0f} deg off upright")
        print(line)
        before = at


def compare(before):
    """The hold and the blow before and after the polish, frame by frame, from his side (where a forward blow shows
    most) and from behind his right shoulder: the clip at `before`, then the one exported in <out_dir>."""
    import r6anim as r6
    import rook_haymaker_stamp as st
    out = Path(sys.argv[sys.argv.index("--") + 1]).resolve()
    scene, rig, costume, undress, feet = rc.build()
    cams = rc.cameras(scene, rig)
    frames = (34, 40, 44, 48, 52, 53, 54, 55, 56, 57, 58)
    scene.render.resolution_x, scene.render.resolution_y = 220, 250
    for name, clip in (("before", Path(before).resolve()), ("after", out / "Rook_Haymaker.json")):
        for joint in rig.joints.values():
            joint.animation_data_clear()
        st.CLIP = clip
        st.key(rig)
        shots = [(cams[view], f, f"{name} {f}" if view == "side" else f"{f}") for view in ("side", "game") for f in frames]
        print(f"wrote {r6.render_shots(scene, shots, out / f'compare_{name}.png', columns=len(frames))}")


if __name__ == "__main__":
    if "path" in sys.argv[sys.argv.index("--") + 1:]:
        path()
    elif "compare" in sys.argv[sys.argv.index("--") + 1:]:
        compare(sys.argv[-1])
    elif "stamp" in sys.argv[sys.argv.index("--") + 1:]:
        stamp()
    else:
        rc.CLIPS.clear()
        rc.CLIPS["Haymaker"] = haymaker
        rc.main()
