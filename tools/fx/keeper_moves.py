"""The Lamplighter's swing and challenge, in grey, as rows files for tools/fx/rows_take.py. Scintilla's.

    py tools/fx/keeper_moves.py [out_dir]        (default: build/handoff/Lamplighter/fx)

Both are their actions' own effects, so the rows' logic case takes them only once KeeperSwing and KeeperChallenge name
them as their Effect (Definitions.Actions): the builder takes them with that line.

KeeperSwing. Feel line: the keeper sweeps its pole round at your fighter's chest, the foot cutting a pale arc that snaps
off where it passes, the great lantern dragging a fainter one behind. Hero: the trail behind the pole's foot (PoleFoot),
from eight frames before Strike to four after, widest on Strike; a crescent cut on Strike where the foot is. The lantern's
trail is lower, softer and later: the weight swinging round after the blow.

KeeperChallenge. Feel line: the keeper stamps its pole and its lantern answers. Warm light drops down the pole and
strikes the street at its foot, so from the player's camera the challenge lands where the keeper stands. Built to
research's lean, F1, the drop (AR7, "Research's pick, F1 against F2"; built ahead of the director's word, research,
2026-11-26, 23:20), from its target (tools/fx/keeper_flare_targets.py, f1_drop), in frames from Stamp:
- the lantern flares on Lift (its own glow, cold 1.2 to hot 3) and jolts brighter on Stamp, with a halo round it;
- the hero, a lance of warm light out of the lantern down the pole, speeding up over 3 frames (the lever: acceleration
  into the stamp), a glow, an amber body and a gold core, wider at the lantern; it holds to 6, then burns out from the
  lantern down by 20, thinning;
- on 3, where it strikes the pole's foot: a flat pool of light on the street, a gold point, a fan of short sparks, and
  a light on the street and the legs.
Every layer is light and sparks, never a flame's shape (research's must-fix). Each layer of the lance is one beam from
its top to its foot, drawn out by Reach. Its foot is a beam with no width, held where the pole struck; its top is the
end of another, the wick, from the foot up to the lantern and cut back down it after the hold, since a beam is cut
back from its High end only.

Written at the keeper's scale (Area 1.5, as KeeperSignature), so studs are as seen. KeeperSwing is grey: every colour
its grey.

F1's sizes are the target's times SEEN. The target was drawn at 66 px a stud (keeper_flare_targets.py, PX), but at the
keeper's entrance the game draws about 26: the lantern, 3.5 to 4 studs across, is about 90 px wide in the target's own
view and in today's take, and the lance's beam measures the same. Built at the target's studs, every layer stood at
two fifths of its target and the lantern hid its halo (fix round 1, AR7, 2026-11-27). A card's light falls off at
0.45 of its half-size (fx_glow), so a glow of the target's radius r is a card 2 r / 0.45 across.
"""
import json
import sys
from pathlib import Path

from hit_sparks import LINE, c3, needles, sheet_rows, v3
from shade_tells import at_beat

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "handoff" / "Lamplighter" / "fx"
AREA = 1.5  # the keeper's scale (Definitions.Enemies), as KeeperSignature is written
LANTERN_COLD, LANTERN_HOT = 1.2, 3.0  # the lantern's glow (Lamplighter.recipe.json, emissive)
GOLD = (255, 199, 107)  # F1's hot core, warm, never white (keeper_flare_targets.py)
AMBER = (255, 117, 23)  # F1's lance and pool
WARM = (224, 122, 22)  # C4's band #E07A16: the glow round the lance and the lantern (the target's deep ember, kept
# off red)
SEEN = 2.5  # the target's stud in the game's, at the keeper's entrance (above)
FALL = 0.45  # fx_glow's falloff: its light at e^-1 this share of its half-size out
OVER = round(1.1 * SEEN, 3)  # studs over the lantern's middle the lance starts, out of its top (the target)
HOLD, GONE = 6, 20  # frames from Stamp: the lance whole to HOLD, burnt down to the foot by GONE


def trail(body, beat, keys_width, lag, why):
    return {
        "Kind": "Beam",
        "From": beat,
        "Body": body,
        "Image": "fx_beam",
        "Grey": "fx_beam",
        "Color": c3(LINE),
        "Beam": {"FaceCamera": True, "LightEmission": 1, "LightInfluence": 0, "TextureMode": "Stretch", "TextureSpeed": 0, "Segments": 1},
        "Trail": {"Back": 0, "Beyond": 0},
        "Tracks": {
            "At": [[keys_width[0][0], v3(0, 0, 0)]],
            "Width": keys_width,
            "Lag": [[keys_width[0][0], lag]],
            "Transparency": [[keys_width[0][0], 0.6, "Quad Out"], [0, 0.05, "Quad In"], [keys_width[-1][0], 1]],
        },
        "Why": why,
    }


def effect(name, why, rows, action, grey=True):
    return {"Schema": "rows/1", "Effect": name, "Why": why, "Area": AREA, "Grey": grey, "Action": action, "Rows": rows}


def swing():
    sweep = trail("PoleFoot", "Strike", [[-8, 0.2, "Quad In"], [0, 1.4, "Quad Out"], [4, 0]], 5,
                  "the hero: the pole's foot cutting a pale arc round to the blow, widest on Strike")
    drag = trail("Lantern", "Strike", [[-4, 0.2, "Sine InOut"], [4, 0.9, "Quad Out"], [14, 0]], 7,
                 "the lantern's weight dragged round after the blow: lower, softer, later")
    drag["Tracks"]["Transparency"] = [[-4, 0.8, "Quad Out"], [4, 0.45, "Quad In"], [14, 1]]
    cut = at_beat(sheet_rows("Cut", "crescent", 0.3, [[0, 3], [0.15, 4.4], [1, 4.8]], 0.3, 0,
                             "the cut where the pole's foot passes on Strike"), "Cut", "Strike")
    for row in cut.values():
        row["Body"] = "PoleFoot"
        row["Hold"] = True
    return effect("KeeperSwing", "The keeper's swing, KeeperSwing's own effect: the grey block-in (Scintilla).",
                  {"Sweep": sweep, "Drag": drag, **cut}, "KeeperSwing")


def challenge():
    stamp = 14  # Stamp, in frames from Lift (Definitions.Actions: Lift 0.7333, Stamp 0.9667)
    gaze = {
        "Kind": "Glow",
        "From": "Lift",
        "Part": ["Lamplighter_Lantern"],
        "Tracks": {"Glow": [[-4, LANTERN_COLD, "Quad Out"], [3, LANTERN_HOT, "Sine InOut"], [stamp, LANTERN_HOT * 0.85, "Quad Out"],
                            [stamp + 1, LANTERN_HOT * 1.3, "Quad Out"], [stamp + 5, LANTERN_HOT * 0.8, "Quad In"], [30, LANTERN_COLD]]},
        "Why": "the lantern flares as it lifts its face to you, it has heard you, and jolts brighter with the stamp",
    }
    beam = {"FaceCamera": True, "LightEmission": 1, "LightInfluence": 0, "TextureMode": "Stretch", "TextureSpeed": 0,
            "Segments": 1}

    def strength(base):
        """A layer's transparency over its life, from the target's strength: in over 2 frames, whole to HOLD, then
        falling away by GONE; base its strength at the peak."""
        return [[0, round(1 - 0.35 * base, 3), "Linear"], [2, round(1 - base, 3), "Linear"],
                [HOLD, round(1 - base, 3), "Quad Out"], [12, round(1 - 0.37 * base, 3), "Linear"], [GONE, 1]]

    def glow(r):  # a card whose light reaches as far as the target's glow of radius r (target studs)
        return round(2 * r * SEEN / FALL, 2)

    def thin(width):  # the lance thins to half from 4 to 16
        return [[0, width, "Linear"], [4, width, "Sine InOut"], [16, round(width / 2, 3)]]

    rows = {
        "Gaze": gaze,
        "Foot": {"Kind": "Beam", "From": "Stamp", "Body": "PoleFoot", "Hold": True, "Image": "fx_beam", "Grey": "",
                 "Beam": beam, "Tracks": {"At": [[0, v3(0, 0, 0)]], "Width": [[0, 0]], "Foot": [[0, 0]], "Top": [[0, 0.01]]},
                 "Why": "where the pole struck the street, held: the lance's foot (no width, never drawn)"},
        "Wick": {"Kind": "Beam", "From": "Stamp", "Body": "Lantern", "Low": "Foot.Low", "Image": "fx_beam", "Grey": "",
                 "Beam": beam, "Tracks": {"At": [[0, v3(0, 0, 0)]], "Width": [[0, 0]], "Top": [[0, OVER]],
                                          "Reach": [[0, 1, "Linear"], [HOLD, 1, "Quad In"], [GONE, 0]]},
                 "Why": "the lance's top: out of the lantern, then burning down the lance to the foot (no width, never drawn)"},
    }
    # (name, colour, width at the lantern, at the foot, peak strength, Brightness, why)
    layers = (("Glow", WARM, 1.0, 0.7, 0.3, 1, "its glow in the air round it"),
              ("Lance", AMBER, 0.32, 0.2, 0.9, 1.2, "the hero: a lance of warm light dropping out of the lantern down the pole"),
              ("Core", GOLD, 0.12, 0.05, 1, 2.5, "its gold core, hot at the lantern"))
    for name, colour, top, foot, base, bright, why in layers:
        fade = strength(base)
        rows[name] = {
            "Kind": "Beam", "From": "Stamp", "Body": "Lantern", "Low": "Wick.High", "High": "Foot.Low",
            "Taper": round(foot / top, 3), "Image": "fx_beam", "Grey": "", "Color": c3(colour),
            "Beam": {**beam, "Brightness": bright},
            "Tracks": {"At": [[0, v3(0, 0, 0)]], "Width": thin(round(top * SEEN, 3)), "Transparency": strength(base),
                       "Reach": [[0, 0.12, "Quad In"], [3, 1]]},  # down the pole, speeding up: on the foot on 3
            "Why": why + ": drawn down from the lantern to the foot, speeding up, then burnt out from the top down"}
    rows["Halo"] = {"Kind": "Card", "From": "Stamp", "Body": "Lantern", "Image": "fx_glow", "Color": c3(WARM), "Tracks": {
        "At": [[0, v3(0, 0, 0)]], "Size": [[0, glow(1.0), "Quad Out"], [HOLD, glow(1.2), "Linear"], [GONE, glow(0.9)]],
        "Transparency": [[0, 0.75, "Linear"], [2, 0.45, "Linear"], [HOLD, 0.45, "Quad In"], [GONE, 1]]},
        "Why": "the lantern answers: a warm halo round it as the lance leaves, dying as it burns down (the target's 1.2 "
               "studs of radius: its light shows round the lantern, which hides its middle)"}
    rows["Flare"] = {"Kind": "Card", "From": "Stamp", "Body": "Lantern", "Image": "fx_glow", "Color": c3(AMBER), "Tracks": {
        "At": [[0, v3(0, 0, 0)]], "Size": [[0, glow(0.36), "Quad Out"], [2, glow(0.5), "Linear"], [GONE, glow(0.36)]],
        "Transparency": [[0, 0.5, "Linear"], [2, 0, "Linear"], [HOLD, 0, "Quad In"], [GONE, 1]]},
        "Why": "the lantern's own flare, hot at its heart (inside the lantern, only its rim shows: its heart needs a card "
               "drawn toward the camera)"}

    def on_street(row):
        row.update({"From": "Stamp", "Body": "PoleFoot", "Ground": True, "Hold": True})
        return row
    rows["Pool"] = on_street({"Kind": "Emitter", "Image": "fx_glow", "Grey": "", "Emitter": {
        "Lifetime": [round(17 / 60, 4), round(17 / 60, 4)], "Speed": [0.01, 0.01], "EmissionDirection": "Top",
        "Orientation": "VelocityPerpendicular",  # flat on the street, facing up
        "LockedToPart": False, "Rotation": [0, 0], "RotSpeed": [0, 0],
        "Size": [[0, 0.8 * SEEN], [0.3, 2.2 * SEEN], [1, 2.4 * SEEN]],  # out over 5 frames, easing (the target: 0.6 to 1.8 studs across)
        "Transparency": [[0, 0], [0.35, 0.55], [1, 1]], "Color": c3(AMBER), "LightEmission": 1, "LightInfluence": 0,
        "Brightness": 1.6, "ZOffset": 0.3},
        "Emit": [[3, 1]], "Tracks": {"At": [[0, v3(0, 0, 0)]]},
        "Why": "where the lance strikes: a flat pool of light on the street at the pole's foot, spreading and dying"})
    rows["Point"] = on_street({"Kind": "Emitter", "Image": "fx_glow", "Grey": "", "Emitter": {
        "Lifetime": [round(14 / 60, 4), round(14 / 60, 4)], "Speed": [0.01, 0.01], "EmissionDirection": "Top",
        "LockedToPart": False, "Rotation": [0, 0], "RotSpeed": [0, 0], "Size": [[0, 0.5 * SEEN], [0.3, 0.8 * SEEN], [1, 0.7 * SEEN]],
        "Transparency": [[0, 0], [0.4, 0.3], [1, 1]], "Color": c3(GOLD), "LightEmission": 1, "LightInfluence": 0,
        "Brightness": 2, "ZOffset": 0.6},
        "Emit": [[3, 1]], "Tracks": {"At": [[0, v3(0, 0.25 * SEEN, 0)]]},
        "Why": "the strike's gold point at the foot, facing the camera"})
    sparks = needles(6, [9 * SEEN, 15 * SEEN], [0.12, 0.2], 65, 0.55 * SEEN, 3, direction="Top", colour=GOLD)
    sparks["Tracks"]["At"] = [[0, v3(0, 0.1 * SEEN, 0)]]
    sparks["Why"] = "a fan of short sparks off the strike, up and out, fast then slow, never falling: light, not fire"
    rows["Sparks"] = on_street(sparks)
    rows["Shine"] = on_street({"Kind": "Light", "Color": c3(AMBER), "Range": 9 * SEEN, "Tracks": {
        "At": [[2, v3(0, 0.8 * SEEN, 0)]], "Brightness": [[2, 0, "Linear"], [3, 3, "Quad Out"], [GONE, 0]]},
        "Why": "the strike lights the street and the keeper's legs"})
    return effect("KeeperChallenge", "The keeper's challenge, KeeperChallenge's own effect: research's lean F1, the drop "
                  "(Scintilla).",
                  rows, "KeeperChallenge", grey=False)


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else OUT
    out.mkdir(parents=True, exist_ok=True)
    for data in (swing(), challenge()):
        path = out / f"{data['Effect']}.rows.json"
        path.write_bytes((json.dumps(data, indent=2) + "\n").encode("utf-8"))
        print(f"wrote {path.relative_to(ROOT).as_posix() if path.is_relative_to(ROOT) else path}")


if __name__ == "__main__":
    main()
