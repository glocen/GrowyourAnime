"""Rook's Haymaker struck down: B5's block clip (AR8, part B; AR1, section 9). The director, 2026-11-12: "let keep A
and do B5 later like a planned rework": the ram's square hung over the target through the hold and slammed down on
the blow, Rook's clip striking down, the target pinned. Moved into the effects pass, 2026-11-13.

blender.exe -b --factory-startup --python tools/blender/rook_haymaker_down.py -- <out_dir> [poses|export|bare|stamp]

- poses, export, bare: as rook_clips.py, for this one clip. export writes Rook_Haymaker.json under the delivered
  clip's own name (RookHaymaker), so it drops into the replay in its place for the blockout.
- stamp: rook_haymaker_stamp.py's B5 sheets (the game's camera, the headings, 64 px) on the exported clip in <out_dir>.

The delivered clip's length and markers (Charge 8, Strike 57, Shock 58, Step 63, Vent 70) and its long hold; only the
blow changes. A, as delivered, draws the ram back at the camera and punches straight out, 3.4 studs short of the
target, at right angles to a square falling from above. Here the ram goes up over his head through the hold while the
square hangs over the target, and on Strike he drives it straight down into the floor in front of him: the square
comes down with it. One line from his fist to the stamp, the same way, on the same frame.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import rook_clips as rc  # noqa: E402

MARK = rc.MARK
FLOOR = (1.6, 2.9, 0.1)  # where the ram's face meets the floor on Strike: in front of his right foot, clear of his
# legs, short of the target (6)
OVER = (60, 0, 34)       # the arm's hint for reaching it: down and in front, the elbow out


def haymaker(t):
    """He hauls the ram up over his head until the piston creaks open, the taped arm thrown out to mark you, waits a
    beat too long, sinking under it, and then drives it straight down into the floor like a pile driver."""
    t.key(0)
    t.key(8, ease="cubic", T=(4, -10, 0, 0, 0, 0.05), RA=(84, 0, 16), LA=(56, 0, -42), crouch=0.18)
    t.mark(8, "Charge")
    t.key(34, "the ram up", ease="lin", T=(-10, -16, 8, 0, 0, -0.2), RA=(182, 0, 4), LA=("reach", MARK, (-10, 0, -76)),
          crouch=0.22, P=0.3, feet={"Right Leg": (0.62, -0.7)}, TP=(8, 0, 0))  # the hold creeps, as A's: the ram
    t.key(52, "the beat too long", ease="in", T=(-16, -20, 12, 0, 0, -0.28), RA=(196, 0, 4), crouch=0.22, P=0.65,
          TP=(-6, 0, 0))  # tips back over his head as he sinks under it, leaning off to lift it higher
    t.key(55, ease="lin", T=(10, -6, 0, 0, 0, 0.12), RA=(130, 0, 20), LA=(30, 0, -42), crouch=0.32, TP=(0, 0, 20))
    t.key(57, "driven down", T=(34, 4, -5, 0, 0, 0.45), RA=("reach", FLOOR, OVER), LA=(-16, 0, -38), crouch=0.37,
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


if __name__ == "__main__":
    if "stamp" in sys.argv[sys.argv.index("--") + 1:]:
        stamp()
    else:
        rc.CLIPS.clear()
        rc.CLIPS["Haymaker"] = haymaker
        rc.main()
