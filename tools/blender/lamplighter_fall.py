"""The Lamplighter's fall: delivery 4's block clip (AR7: "Its fall: the Shade's burst into light and paper at keeper
size, with the lantern's light going out last. No wounds, nothing left behind").

blender.exe -b --factory-startup --python tools/blender/lamplighter_fall.py -- <out_dir> [poses|export|audit]

The keeper's own Down, keyed as lamplighter_clips.py keys its clips, on its pole and lantern. It is the Shade's Burst at
its scale and its weight: struck, it sags onto its pole; then the mask lets go and tips back to the sky, and the game
hides the body at Burst, where the Shade's burst plays at keeper size. The pole stays planted where it stood, rocked by
the let-go, and the lantern hangs on it, still lit, swinging and steadying: the last light on the street. It gutters
(Gutter) and goes out (Out), and then the pole and the lantern go to paper too (Gone), so nothing is left behind.
- poses: the key poses from the fight's camera and its left side, the body hidden from Burst as the game hides it.
- export, audit: as lamplighter_clips.py, for this clip alone (Lamplighter_Down.json, named LamplighterDown).
"""
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
import lamplighter_clips as lc  # noqa: E402

READY = lc.READY


def down(t):
    """It took every blow on its pole, and this one it can't. Rocked back, it sags onto the pole and hangs there, the
    head going under the brim. Then whatever held it lets go, the mask first, tipped back until its face is to the
    sky, the coat opening after it, and it is light and paper. The pole stays where it was planted, rocking once, the
    lantern lit on its hook, swinging and steadying. It gutters and goes out, and then the pole goes too."""
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
    t.key(34, "its face to the sky", ease="out", T=(-10, -2, 0, 0, 0, 0.08), crouch=0.08, H=(-62, 2, 0),
          LA=(-72, 0, -8), RA=(26, 0, 34))
    t.mark(34, "Burst")
    # Hidden from here. The unseen arm lets the pole come back over its planted foot: past upright once, and still.
    t.key(44, ease="sine", T=(10, -8, -6, 0.08, 0, 0.02), crouch=0.04, H=(6, 0, 4), LA=READY["LA"], RA=(50, 0, 26))
    t.key(54, "the pole stands", ease="sine", T=READY["T"], crouch=READY["crouch"], H=READY["H"], RA=READY["RA"])
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
    finally:
        bpy.app.handlers.frame_change_post.remove(hide)
        for o in body:
            o.hide_render = False


SHEET = lc.pose_sheet

if __name__ == "__main__":
    lc.CLIPS.clear()
    lc.CLIPS["Down"] = (down, READY)
    lc.pose_sheet = pose_sheet
    lc.main()
