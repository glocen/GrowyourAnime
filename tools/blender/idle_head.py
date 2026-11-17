"""How far each idle's head turns, nods and tilts against her root, frame by frame (AR27: the head stays level and
faces front through the whole loop; its life is the stance, the breath and the Voidkin's own secondary motion).

py tools/blender/idle_head.py [clip.json ...]

Plain Python, no Blender. With no paths it reads every lead's delivered idle (build/handoff/<Lead>/clips/<Lead>_Idle.json).
Each frame's head is the clip's Torso and Head Transforms on R6's RootJoint and Neck (r6rig.JOINTS), so it's the
head the game plays. It fails (exit 1) when a head turns or tilts past the rule's bounds.
"""
import json
import math
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kirra_scarf_step_fx as k  # noqa: E402  (the CFrame sums)

ROOT = Path(__file__).resolve().parents[2]
LEADS = ("Rook", "Kirra", "Pip", "Lyric", "Watt")
BASE = [[-1, 0, 0], [0, 0, 1], [0, 1, 0]]  # R6's joints' rotation (r6rig._BASE)
NECK_C0 = BASE, [0, 1, 0]
NECK_C1 = BASE, [0, -0.5, 0]
TURN = 4.0  # degrees: the most a head may turn from her front, on its own or left by the torso's turn
TILT = 2.0  # degrees: the most it may tilt to a side (cocked)


def head(poses):
    """The head's rotation in her root's frame (x right, y up, z back)."""
    torso = k.compose(k.compose(k.R6_ROOT, k.cframe(poses["Torso"])), k.inverse(k.R6_ROOT))
    h = k.compose(k.compose(k.compose(torso, NECK_C0), k.cframe(poses["Head"])), k.inverse(NECK_C1))
    return h[0]


def angles(r):
    """(turn, nod, tilt) in degrees: + turns to her left, nods up, tilts her left ear down."""
    col = lambda j: [r[0][j], r[1][j], r[2][j]]  # noqa: E731
    right, front = col(0), [-c for c in col(2)]
    turn = math.degrees(math.atan2(-front[0], -front[2]))
    nod = math.degrees(math.asin(max(-1.0, min(1.0, front[1]))))
    tilt = math.degrees(math.asin(max(-1.0, min(1.0, -right[1]))))
    return turn, nod, tilt


def check(path):
    clip = json.loads(Path(path).read_text(encoding="utf-8"))
    rows = [angles(head(f["Poses"])) for f in clip["Frames"]]
    worst = {}
    for i, name in enumerate(("turn", "nod", "tilt")):
        f = max(range(len(rows)), key=lambda n: abs(rows[n][i]))
        worst[name] = (rows[f][i], f)
    lo, hi = min(r[1] for r in rows), max(r[1] for r in rows)
    ok = abs(worst["turn"][0]) <= TURN and abs(worst["tilt"][0]) <= TILT
    print(f"{Path(path).name}: {len(rows)} frames; the most turn {worst['turn'][0]:+.1f} at {worst['turn'][1]}, "
          f"tilt {worst['tilt'][0]:+.1f} at {worst['tilt'][1]}, nod {lo:+.1f} to {hi:+.1f}: "
          f"{'level and front' if ok else 'FAILS'} (within {TURN:g} and {TILT:g})")
    return ok


def main():
    paths = sys.argv[1:] or [ROOT / "build" / "handoff" / n / "clips" / f"{n}_Idle.json" for n in LEADS]
    if not all([check(p) for p in paths]):
        sys.exit(1)


if __name__ == "__main__":
    main()
