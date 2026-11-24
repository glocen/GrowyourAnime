"""The Support Shade's looks (AR58), in grey, as rows files for tools/fx/rows_take.py. Scintilla's.

    py tools/fx/support_looks.py [out_dir]        (default: build/handoff/Support/fx)

Feel line: at the back of a pack a slight veiled Shade lifts its sleeves and they light; a hurt Shade in front has a ring
of light climb it as it comes back up, or a veil of light rises round it and holds. You see who's doing it.

- SupportCast, the cast's own effect (its action names it): a light gathering in each sleeve's end as they rise to Cast,
  held while they're up, let go from Lower; a ring opening at its chest on Cast. The hero: the lit sleeves, who casts.
- SupportHeal, free, played at the mended one's foot on the Heal (FighterController's HEALS, SupportCast): a ring of
  light climbing from its feet to its chest, light lifting off it, a glow at its chest as the ring arrives. Light only:
  never a wound closing.
- SupportShield, worn on the shielded one while ShieldUntil holds (ShieldLook "SupportShield"), ended at once: a veil of
  light rising round it from its feet to its shoulders in 8 frames, a crown ring turning slowly at its top, breathing.
  Round the body, so it never reads as the Guard's lens held in front.

Written at a body of scale 1 (Area 1). Grey: every colour drawn in its grey. Kit only.
"""
import json
import sys
from pathlib import Path

from hit_sparks import LINE, WARM, c3, needles, sheet_rows, v3
from shade_tells import at_beat

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "handoff" / "Support" / "fx"
FAR = 3600
HOLD = 60  # frames from Cast to Lower (Definitions.Actions, SupportCast: 0.4 to 1.4 s)


def effect(name, why, rows, action=None):
    data = {"Schema": "rows/1", "Effect": name, "Why": why, "Area": 1, "Grey": True, "Rows": rows}
    if action:
        data["Action"] = action
    return data


def cast():
    rows = {}
    for side, part in (("Left", "Left Arm"), ("Right", "Right Arm")):
        rows[f"Sleeve{side}"] = {
            "Kind": "Card",
            "From": "Cast",
            "Body": part,
            "Image": "fx_glow",
            "Color": c3(WARM),
            "Tracks": {
                "At": [[-12, v3(0, -1.1, 0)]],  # the sleeve's end
                "Size": [[-12, 0.4, "Quad Out"], [0, 1.7, "Sine InOut"], [HOLD // 2, 1.45, "Sine InOut"], [HOLD, 1.6, "Quad In"], [HOLD + 10, 0]],
                "Transparency": [[-12, 0.9, "Quad Out"], [0, 0.15, "Linear"], [HOLD, 0.25, "Quad In"], [HOLD + 10, 1]],
            },
            "Why": "the hero: light gathering in the sleeve's end as it rises, held while it casts: who casts",
        }
    ring = at_beat(sheet_rows("Ring", "ring", 0.32, [[0, 1.4], [1, 3.6]], 0.34, [0, 0],
                              "the cast going out: a ring opening at its chest on Cast"), "Ring", "Cast")
    for row in ring.values():
        row["Body"] = "HumanoidRootPart"
        row["Hold"] = True
        row["Tracks"]["At"] = [[0, v3(0, 0.6, 0)]]
    rows.update(ring)
    return effect("SupportCast", "The Support's cast, SupportCast's own effect: the grey block-in (AR58, Scintilla).", rows, "SupportCast")


def heal():
    climb = 22
    rows = {
        "Climb": {
            "Kind": "Mesh",
            "Part": ["FxHoop"],
            "Look": "fx_rise_Grey",
            "Grey": "fx_rise_Grey",
            "Color": c3(WARM),
            "Tracks": {
                "At": [[0, v3(0, 0.1, 0), "Quad Out"], [climb, v3(0, 3.6, 0)]],
                "Scale": [[0, v3(1.5, 1.2, 1.5), "Quad Out"], [climb, v3(1.05, 0.7, 1.05)]],
                "Transparency": [[0, 0.6, "Quad Out"], [4, 0.1, "Linear"], [climb - 6, 0.2, "Quad In"], [climb, 1]],
                "Glow": [[0, 1.5, "Quad Out"], [climb, 2.5]],
            },
            "Why": "the hero: a ring of light climbing the mended one from its feet to its chest",
        },
        "Lift": {**needles(8, [5, 8], [0.35, 0.5], 25, 0.7, 2, direction="Top"),
                 "Why": "light lifting off it as the ring climbs, slowing"},
        "Chest": {
            "Kind": "Card",
            "Image": "fx_glow",
            "Color": c3(WARM),
            "Tracks": {
                "At": [[climb - 4, v3(0, 3.6, 0.3)]],
                "Size": [[climb - 4, 1.2, "Quad Out"], [climb + 2, 2.6, "Quad In"], [climb + 18, 0]],
                "Transparency": [[climb - 4, 0.6, "Quad Out"], [climb + 2, 0.2, "Quad In"], [climb + 18, 1]],
            },
            "Why": "the ring arriving at its chest: a soft glow, gone in a quarter second",
        },
    }
    lift = rows["Lift"]
    lift["Emitter"]["Drag"] = 3
    lift["Emitter"]["ZOffset"] = 0.2
    lift["Tracks"] = {"At": [[0, v3(0, 0.4, 0)]], "Radius": [[0, 0.9]]}
    return effect("SupportHeal", "A Support's mend, at the mended one's foot: the grey block-in (AR58, Scintilla).", rows)


def shield():
    rise = 8
    veil = {
        "Kind": "Mesh",
        "Body": "HumanoidRootPart",
        "Ground": True,
        "Part": ["FxColumn"],
        "Look": "fx_rise_Grey",
        "Grey": "fx_rise_Grey",
        "Color": c3(LINE),
        "Tracks": {
            "Scale": [[0, v3(1.5, 0.1, 1.5), "Back Out"], [rise, v3(1.45, 2.2, 1.45), "Sine InOut"], [60, v3(1.5, 2.25, 1.5), "Sine InOut"],
                      [120, v3(1.45, 2.2, 1.45)], [FAR, v3(1.45, 2.2, 1.45)]],
            "Transparency": [[0, 0.3, "Quad Out"], [rise + 4, 0.62], [FAR, 0.62]],
            "Glow": [[0, 2.5, "Quad Out"], [rise + 4, 1.2], [FAR, 1.2]],
        },
        "Why": "the hero: a veil of light rising round the shielded one from its feet to its shoulders, and holding",
    }
    crown = {  # rides the root (3 over the foot), not grounded, so it climbs and turns
        "Kind": "Mesh",
        "Body": "HumanoidRootPart",
        "Part": ["FxHoop"],
        "Look": "fx_rise_Grey",
        "Grey": "fx_rise_Grey",
        "Color": c3(LINE),
        "Tracks": {
            "At": [[0, v3(0, -2.8, 0), "Back Out"], [rise, v3(0, 1.3, 0)], [FAR, v3(0, 1.3, 0)]],
            "Scale": [[0, v3(1.6, 0.6, 1.6)], [FAR, v3(1.6, 0.6, 1.6)]],
            "Spin": [[0, 0, "Linear"], [FAR, 30 * FAR // 60]],  # turning slowly, 30 a second
            "Transparency": [[0, 0.2, "Quad Out"], [rise + 4, 0.35], [FAR, 0.35]],
            "Glow": [[0, 2.5, "Quad Out"], [rise + 4, 1.6], [FAR, 1.6]],
        },
        "Why": "the veil's top: a ring turning slowly at its shoulders, the shield's edge",
    }
    return effect("SupportShield", "A Support's shield, worn while it holds: the grey block-in (AR58, Scintilla).", {"Veil": veil, "Crown": crown})


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else OUT
    out.mkdir(parents=True, exist_ok=True)
    for data in (cast(), heal(), shield()):
        path = out / f"{data['Effect']}.rows.json"
        path.write_bytes((json.dumps(data, indent=1) + "\n").encode("utf-8"))
        print(f"wrote {path.relative_to(ROOT).as_posix() if path.is_relative_to(ROOT) else path}")


if __name__ == "__main__":
    main()
