"""The Support Shade's looks (AR58), as rows files for tools/fx/rows_take.py, built to research's pick of the targets
(A, the tether, for the cast and the mend; S2, the veil, for the shield: build/handoff/Support/targets/). Scintilla's.

    py tools/fx/support_looks.py [out_dir]        (default: build/handoff/Support/fx)

Feel line: at the back of a pack a slight veiled Shade lifts its sleeves and a light gathers between them and holds; on
its cast a beam snaps from that light to a hurt Shade in front, which bursts with light as it comes back up, or a veil of
light ribbons rises round it and holds. You see who's doing it.

One hue, the heal number's mint (UIKit.Numbers.Heal), white only in a core; bright, one hero shape at a time (the
director's "that simple", 2026-11-25). The Neon pieces take the mint itself (Neon draws its colour lit); every other
light lays a deeper mint (DEEP) as colour, since added or pale it read white on the pale deck (research's quarter,
2026-11-25). Light only: no wound, nothing falling or sticking. The content check's conditions (AR58, "Scintilla's
targets"): the motes stay round and rising.

- SupportCast, the cast's own effect (its action names it): the hero, a lit mint ball (the kit's sphere in Neon)
  gathering between the sleeves as they rise to Cast, its mint light on the air round it, held while they're up, a few
  short needles turning off it, let go from Lower; each sleeve's end lit a little. Who casts.
- SupportLink, played once on the caster when its cast lands (a heal or a shield), at the one it's for (its Target): a
  mint beam from the caster's light to that body, drawn out in 2 frames, held to 8, thinned and gone by 22, a white
  thread down it; a mint flash with a white core at the caster as it goes. The link.
- SupportHeal, played once at the mended one's foot on the Heal (FighterController's HEALS, SupportCast), its rows 2
  frames after the link starts, as the beam arrives: a white star at its chest, gone in a sixth of a second, in a bright
  mint glow filling the chest; a mint shell of light (the kit's sphere) swelling round the body and fading: the dome;
  14 needles thrown out leaning up, fast then slow; a hoop opening at its feet; round motes rising and slowing.
- SupportShield, worn on the shielded one while ShieldUntil holds (ShieldLook "SupportShield"), ended at once: ten
  broad mint bands rising round it from its feet in 8 frames and turning slowly, a stud apart so the body shows between
  them, a hoop at their foot and one riding up to their top at the head's. Round the body, so it never reads as the
  Guard's lens held in front.

Written at a body of scale 1 (Area 1).
"""
import json
import math
import sys
from pathlib import Path

from hit_sparks import FRONT, LAYER, c3, needles, v3

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "handoff" / "Support" / "fx"
FAR = 3600
HOLD = 60  # frames from Cast to Lower (Definitions.Actions, SupportCast: 0.4 to 1.4 s)
MINT = (111, 230, 149)  # UIKit.Numbers.Heal, #6FE695: the Neon pieces (a Neon part draws its colour lit)
DEEP = (38, 204, 98)  # #26CC62, the same hue deeper: every light laid as colour. The heal's mint, added or laid pale,
# read white on the pale deck (research's quarter, 2026-11-25, must-fix 2: "white only in the core")
WHITE = (255, 255, 255)
ORB = v3(0, 2.5, -1.2)  # the caster's light from its root: between the raised sleeves, ahead of its mask (a card isn't
# drawn over the body: behind the mask it was hidden, 2026-11-25 take)
# Effects.Once's rows ride the body from its foot (no Body rows there: the Track case), so these count from the foot
ORB_FOOT = v3(0, 5.5, -1.2)  # the caster's light: its root stands 3 over its foot
CHEST_FOOT = v3(0, 3.6, -0.9)  # a stud before its chest, toward the lead and so the usual camera: inside the torso the body hid it
CHEST_CORE = v3(0, 3.4, 0)  # inside its chest: a particle there drawn toward the camera (ZOffset) clears the body from any side
LAND = 2  # the beam's frames to reach the one it's for: the mend's rows wait for it
BEAM = {"FaceCamera": True, "LightEmission": 1, "LightInfluence": 0, "TextureMode": "Stretch", "TextureSpeed": 0, "Segments": 1}
# a mint beam lays its colour: added light goes white on the pale deck and the hue is lost. Only a core adds.
LAID = {**BEAM, "LightEmission": 0.25}
LAID_GLOW = 0.35  # an emitter's LightEmission when it lays its mint


def ball(at, scale, transparency, why, body="HumanoidRootPart", colour=MINT, **extra):
    """A lit ball or a shell of light: the kit's sphere in flat Neon (Rows.Mesh with no look). Scale is its diameter / 2."""
    row = {"Kind": "Mesh", "Part": ["FxShell"], "Color": c3(colour),
           "Tracks": {"At": [[scale[0][0], at]], "Scale": scale, "Transparency": transparency}, "Why": why}
    if body:
        row["Body"] = body
    row.update(extra)
    return row


def effect(name, why, rows, action=None):
    data = {"Schema": "rows/1", "Effect": name, "Why": why, "Area": 1, "Grey": False, "Rows": rows}
    if action:
        data["Action"] = action
    return data


def card(colour, at, size, transparency, why, body="HumanoidRootPart", **extra):
    row = {"Kind": "Card", "Image": "fx_glow", "Color": c3(colour),
           "Tracks": {"At": [[size[0][0], at]], "Size": size, "Transparency": transparency}, "Why": why}
    if body:
        row["Body"] = body
    row.update(extra)
    return row


def cast():
    rows = {
        # research's quarter, must-fix 3: a glint where A has a lit mint ball. The ball is the kit's sphere in Neon, so
        # it's lit from any side and its bloom whitens its middle (the core); the halo is its light on the air round it
        "Orb": ball(ORB, [[-24, 0.12, "Quad Out"], [-4, 0.62, "Back Out"], [HOLD // 2, 0.55, "Sine InOut"], [HOLD, 0.62, "Quad In"],
                          [HOLD + 8, 0]],
                    [[-24, 0.3, "Quad Out"], [-4, 0, "Linear"], [HOLD, 0, "Quad In"], [HOLD + 8, 1]],
                    "the hero: a lit mint ball gathering between the sleeves as they rise, held while it casts: who casts",
                    From="Cast"),
        "Halo": card(DEEP, ORB,
                     [[-24, 0.8, "Quad Out"], [-4, 4.2, "Sine InOut"], [HOLD // 2, 3.8, "Sine InOut"], [HOLD, 4.1, "Quad In"], [HOLD + 8, 0]],
                     [[-24, 0.8, "Quad Out"], [-4, 0, "Linear"], [HOLD, 0.05, "Quad In"], [HOLD + 8, 1]],
                     "its mint light on the air round it", From="Cast"),
    }
    rows["Halo"]["Tracks"]["Brightness"] = [[-24, 1.5], [FAR, 1.5]]
    for side, part in (("Left", "Left Arm"), ("Right", "Right Arm")):
        rows[f"Sleeve{side}"] = card(DEEP, v3(0, -1.1, 0),  # the sleeve's end
                                     [[-12, 0.3, "Quad Out"], [0, 1.0, "Sine InOut"], [HOLD, 0.9, "Quad In"], [HOLD + 8, 0]],
                                     [[-12, 0.9, "Quad Out"], [0, 0.35, "Linear"], [HOLD, 0.4, "Quad In"], [HOLD + 8, 1]],
                                     "each sleeve's end lit a little, feeding the light between them", body=part, From="Cast")
    turning = needles(0, [2.5, 3.5], [0.18, 0.26], 180, 0.55, 0)
    turning["Emitter"]["Color"] = c3(DEEP)
    turning["Emitter"]["LightEmission"] = LAID_GLOW
    turning["Emitter"]["Drag"] = 6
    turning["Emitter"]["EmissionDirection"] = "Top"
    turning["Emit"] = []
    turning["From"] = "Cast"
    turning["Body"] = "HumanoidRootPart"
    turning["Tracks"] = {"At": [[-4, ORB]], "Rate": [[-4, 14], [HOLD, 14], [HOLD + 1, 0]]}
    turning["Why"] = "a few short needles turning off the held light, so it lives while it holds"
    rows["OrbNeedles"] = turning
    return effect("SupportCast", "The Support's cast, SupportCast's own effect: the held light (AR58, target A, Scintilla).", rows, "SupportCast")


def link():
    rows = {
        "Link": {
            "Kind": "Beam", "Image": "fx_beam", "Color": c3(DEEP), "Beam": LAID,
            "High": "Target",
            "Tracks": {
                "At": [[0, ORB_FOOT]],
                "Foot": [[0, 0]],  # its low end at its place: the caster's light
                "Reach": [[0, 0, "Quad Out"], [LAND, 1]],
                "Width": [[0, 1.2, "Quad Out"], [8, 1.0, "Quad In"], [22, 0.35]],
                "Transparency": [[0, 0, "Linear"], [12, 0.1, "Quad In"], [22, 1]],
            },
            "Why": "the link: a beam from the caster's light to the one it's for, drawn out in 2 frames, held, thinned",
        },
        "LinkCore": {
            "Kind": "Beam", "Image": "fx_beam", "Color": c3(WHITE), "Beam": BEAM,
            "High": "Target", "Like": "Link",
            "Tracks": {
                "At": [[0, ORB_FOOT]],
                "Foot": [[0, 0]],  # its low end at its place: the caster's light
                "Reach": [[0, 0, "Quad Out"], [LAND, 1]],
                "Width": [[0, 0.22, "Quad Out"], [8, 0.18, "Quad In"], [22, 0.05]],
            },
            "Why": "its white core: a thread down the mint, the only white in it",
        },
        "Flash": card(DEEP, ORB_FOOT, [[0, 2.6, "Quad Out"], [3, 3.0, "Quad In"], [10, 0]], [[0, 0.1, "Quad In"], [10, 1]],
                      "the held light going: a mint flash at the caster as the beam leaves", body=None),
        "FlashCore": card(WHITE, ORB_FOOT, [[0, 0.7, "Quad Out"], [3, 0.9, "Quad In"], [8, 0]], [[0, 0.1, "Quad In"], [8, 1]],
                          "its white core", body=None),
    }
    rows["Flash"]["Tracks"]["Brightness"] = [[0, 1.6], [10, 1.6]]
    return effect("SupportLink", "A Support's cast landing: the beam to the one it's for (AR58, target A, Scintilla).", rows)


def heal():
    chest = CHEST_FOOT
    # research's quarter, must-fix 1: the peak had no mass. A's is a mint glow filling the chest behind a white star,
    # inside a dome. The star and the glow are single particles pushed toward the camera (ZOffset), as the hit sparks
    # are: as cards at the chest the body hid them from the three-quarter camera (the next look, 2026-11-25). They sit
    # inside the chest, drawn 2 studs toward the camera, more than the torso's half-width: a stud before the chest, the
    # body hid most of them when the mended one faced away (the deck stage's side take, 2026-11-25)
    def flash(image, colour, emission, life, size, transparency, z, why):
        return {"Kind": "Emitter", "Image": image,
                "Emitter": {"Lifetime": [life, life], "Speed": [0, 0], "Rotation": [0, 0], "Size": size,
                            "Transparency": transparency, "Color": c3(colour), "LightEmission": emission,
                            "LightInfluence": 0, "ZOffset": z},
                "Emit": [[LAND, 1]], "Tracks": {"At": [[LAND, CHEST_CORE]]}, "Why": why}

    rows = {
        "Core": flash("fx_glow", WHITE, 1, 10 / 60, [[0, 0.8], [0.2, 2.0], [1, 0]], [[0, 0], [0.3, 0.1], [1, 1]], 2.2,
                      "the hero's heart: a white core at its chest as the beam arrives, gone in a sixth of a second"),
        "Star": flash("fx_spark", WHITE, 1, 12 / 60, [[0, 1.6], [0.25, 3.4], [1, 0.6]], [[0, 0], [0.4, 0.1], [1, 1]], 2.3,
                      "the white star over it"),
        "Glow": flash("fx_glow", DEEP, 0.35, 22 / 60, [[0, 3.6], [0.2, 5.4], [1, 2.0]], [[0, 0], [0.3, 0.05], [1, 1]], 2.0,
                      "the mint glow filling the chest behind the star"),
        "Dome": ball(v3(0, 3.0, 0),  # round the body: the root stands 3 over the foot
                     [[LAND, 0.6, "Quad Out"], [LAND + 6, 2.4, "Sine Out"], [LAND + 22, 2.7]],
                     [[LAND, 0.5, "Quad Out"], [LAND + 6, 0.75, "Quad In"], [LAND + 22, 1]],
                     "the dome: the kit's sphere as a mint shell of light, swelling round it and fading", body=None),
    }
    rows["Glow"]["Emitter"]["Brightness"] = 2
    burst = needles(14, [10, 15], [0.26, 0.4], 70, 1.0, LAND, direction="Top")
    burst["Emitter"]["Color"] = c3(DEEP)
    burst["Emitter"]["LightEmission"] = LAID_GLOW
    burst["Tracks"] = {"At": [[LAND, chest]]}
    burst["Why"] = "14 needles thrown out of its chest leaning up, fast then slow: light leaving it, never falling"
    rows["Needles"] = burst
    rows["Hoop"] = {
        "Kind": "Mesh", "Part": ["FxHoop"], "Color": c3(MINT), "Ground": True,
        "Tracks": {
            "At": [[LAND, v3(0, 0.05, 0)]],
            "Scale": [[LAND, v3(1.0, 0.3, 1.0), "Quad Out"], [LAND + 14, v3(2.8, 0.2, 2.8)]],
            "Transparency": [[LAND, 0.15, "Quad In"], [LAND + 18, 1]],
            "Glow": [[LAND, 3, "Quad Out"], [LAND + 18, 1]],
        },
        "Why": "a hoop opening at its feet: where the light lands",
    }
    rows["Motes"] = {
        "Kind": "Emitter", "Image": "fx_glow",
        "Emitter": {
            "EmissionDirection": "Top", "SpreadAngle": [25, 25], "Lifetime": [0.6, 0.9], "Speed": [3, 5], "Drag": 3,
            "Acceleration": v3(0, 0, 0), "Size": [[0, 0.32], [0.5, 0.26], [1, 0]], "Transparency": [[0, 0.1], [0.7, 0.3], [1, 1]],
            "Color": c3(DEEP), "LightEmission": LAID_GLOW, "LightInfluence": 0, "ZOffset": FRONT,
        },
        "Emit": [[LAND + 3, 6], [LAND + 9, 4]],
        "Tracks": {"At": [[LAND, v3(0, 1.4, 0)]], "Radius": [[LAND, 0.9]]},
        "Why": "round motes rising off it and slowing, after the burst: never falling, never sticking",
    }
    return effect("SupportHeal", "A Support's mend, at the mended one's foot: the burst (AR58, target A, Scintilla).", rows)


def shield():
    rise, radius, height = 8, 1.7, 5.6  # to the head's top and past it (S2)
    rows = {
        "Veil": {
            "Kind": "Point", "Body": "HumanoidRootPart", "Ground": True,
            "Tracks": {"At": [[0, v3(0, 0, 0)]], "Spin": [[0, 0, "Linear"], [FAR, 20 * FAR // 60]]},  # 20 a second
            "Why": "the veil's place, turning slowly: its ribbons ride it",
        },
    }
    # research's quarter, must-fix 4: S2's are broad mint bands, these were thin and pale. Ten, a stud apart round the
    # body, so from any side they stay bands with the body seen between them, never a wall (take 1's barrel)
    count = 10
    for i in range(count):
        a = i / count * 2 * math.pi
        top = round(height * (0.78 + 0.22 * ((i * 37) % 5) / 4), 3)
        rows[f"Ribbon{i + 1:02d}"] = {
            "Kind": "Beam", "On": "Veil", "Image": "fx_beam", "Color": c3(DEEP), "Beam": LAID, "Taper": 0.4, "FootFade": 0.3,
            "Tracks": {
                "At": [[0, v3(round(math.cos(a) * radius, 3), 0, round(math.sin(a) * radius, 3))]],
                "Top": [[0, 0, "Quad Out"], [rise, top], [FAR, top]],
                "Width": [[0, 0.8, "Quad Out"], [rise, 0.6], [FAR, 0.6]],
                "Transparency": [[0, 0], [FAR, 0]],
            },
            "Why": "the hero: broad mint bands rising round it from its feet and holding" if i == 0 else "a band",
        }
    rows["Foot"] = {
        "Kind": "Mesh", "Body": "HumanoidRootPart", "Ground": True, "Part": ["FxHoop"],
        "Color": c3(MINT),
        "Tracks": {
            "Scale": [[0, v3(1.3, 0.3, 1.3), "Back Out"], [rise, v3(radius, 0.35, radius)], [FAR, v3(radius, 0.35, radius)]],
            "Transparency": [[0, 0, "Quad Out"], [rise + 4, 0.1], [FAR, 0.1]],
            "Glow": [[0, 4, "Quad Out"], [rise + 4, 3], [FAR, 3]],
        },
        "Why": "the ribbons' foot: a hoop round the shielded one",
    }
    rows["Crown"] = {  # rides the root (3 over the foot), not grounded, so it climbs with the ribbons and turns
        "Kind": "Mesh", "Body": "HumanoidRootPart", "Part": ["FxHoop"],
        "Color": c3(MINT),
        "Tracks": {
            "At": [[0, v3(0, -2.9, 0), "Quad Out"], [rise, v3(0, 2.0, 0)], [FAR, v3(0, 2.0, 0)]],  # the head's top
            "Scale": [[0, v3(radius, 0.4, radius)], [FAR, v3(radius * 0.92, 0.4, radius * 0.92)]],
            "Spin": [[0, 0, "Linear"], [FAR, 20 * FAR // 60]],
            "Transparency": [[0, 0, "Quad Out"], [rise + 4, 0.1], [FAR, 0.1]],
            "Glow": [[0, 4, "Quad Out"], [rise + 4, 3], [FAR, 3]],
        },
        "Why": "the ribbons' top: a hoop riding up with them, the shield's edge",
    }
    return effect("SupportShield", "A Support's shield, worn while it holds: the veil (AR58, target S2, Scintilla).", rows)


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else OUT
    out.mkdir(parents=True, exist_ok=True)
    for data in (cast(), link(), heal(), shield()):
        path = out / f"{data['Effect']}.rows.json"
        path.write_bytes((json.dumps(data, indent=1) + "\n").encode("utf-8"))
        print(f"wrote {path.relative_to(ROOT).as_posix() if path.is_relative_to(ROOT) else path}")


if __name__ == "__main__":
    main()
