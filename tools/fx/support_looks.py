"""The Support Shade's looks (AR58), as rows files for tools/fx/rows_take.py, built to research's pick of the targets
(A, the tether, for the cast and the mend; S2, the veil, for the shield: build/handoff/Support/targets/). Scintilla's.

    py tools/fx/support_looks.py [out_dir]        (default: build/handoff/Support/fx)

Feel line: at the back of a pack a slight veiled Shade lifts its sleeves and a light gathers between them and holds; on
its cast a beam snaps from that light to a hurt Shade in front, which bursts with light as it comes back up, or a veil of
light ribbons rises round it and holds. You see who's doing it.

One hue, the heal number's mint (UIKit.Numbers.Heal), with a white core; bright, one hero shape at a time (the
director's "that simple", 2026-11-25). Light only: no wound, nothing falling or sticking. The content check's conditions
(AR58, "Scintilla's targets"): the ring stays plain; the motes stay round and rising.

- SupportCast, the cast's own effect (its action names it): the hero, a light gathering between the sleeves as they rise
  to Cast, a white core in it, held while they're up, a few short needles turning off it, let go from Lower; each
  sleeve's end lit a little. Who casts.
- SupportLink, played once on the caster when its cast lands (a heal or a shield), at the one it's for (its Target): a
  beam from the caster's light to that body, drawn out in 2 frames, held to 8, thinned and gone by 22, a white core
  down it; a flash in the caster's light as it goes. The link. Waits on the builder's hook (a Beam end at the Target,
  and the event that names who it's for), so it isn't taken before.
- SupportHeal, played once at the mended one's foot on the Heal (FighterController's HEALS, SupportCast), its rows 2
  frames after the link starts, as the beam arrives: a white core at its chest, soft and gone in a sixth of a second; a
  mint glow round it; 14 needles thrown out leaning up, fast then slow; a ring swelling round it (the dome's rim); a hoop
  opening at its feet; round motes rising and slowing. The ring fades as it swells: no dark pass, never a held hoop.
- SupportShield, worn on the shielded one while ShieldUntil holds (ShieldLook "SupportShield"), ended at once: 14 tapered
  ribbons of light rising round it from its feet in 8 frames and turning slowly, a hoop at their foot and one riding up
  to their top at the head's. Round the body, so it never reads as the Guard's lens held in front.

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
MINT = (111, 230, 149)  # UIKit.Numbers.Heal, #6FE695
PALE = (214, 255, 228)  # the mint's light near white: a line's core over its mint
WHITE = (255, 255, 255)
ORB = v3(0, 2.5, -1.2)  # the caster's light from its root: between the raised sleeves, ahead of its mask (a card isn't
# drawn over the body: behind the mask it was hidden, 2026-11-25 take)
# Effects.Once's rows ride the body from its foot (no Body rows there: the Track case), so these count from the foot
ORB_FOOT = v3(0, 5.5, -1.2)  # the caster's light: its root stands 3 over its foot
CHEST_FOOT = v3(0, 3.6, -0.9)  # a stud before its chest, toward the lead and so the usual camera: inside the torso the body hid it
LAND = 2  # the beam's frames to reach the one it's for: the mend's rows wait for it
BEAM = {"FaceCamera": True, "LightEmission": 1, "LightInfluence": 0, "TextureMode": "Stretch", "TextureSpeed": 0, "Segments": 1}
# the veil's ribbons lay their mint as colour: added light goes white on the pale deck and the hue is lost
RIBBON = {**BEAM, "LightEmission": 0.35}


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
        "Orb": card(MINT, ORB,
                    [[-24, 0.4, "Quad Out"], [-4, 3.0, "Sine InOut"], [HOLD // 2, 2.6, "Sine InOut"], [HOLD, 2.9, "Quad In"], [HOLD + 8, 0]],
                    [[-24, 0.9, "Quad Out"], [-4, 0, "Linear"], [HOLD, 0.05, "Quad In"], [HOLD + 8, 1]],
                    "the hero: the light gathering between the sleeves as they rise, held while it casts: who casts",
                    From="Cast"),
        "OrbCore": card(WHITE, ORB,
                        [[-20, 0.15, "Quad Out"], [-4, 0.7, "Sine InOut"], [HOLD // 2, 0.6, "Sine InOut"], [HOLD, 0.65, "Quad In"], [HOLD + 6, 0]],
                        [[-20, 0.8, "Quad Out"], [-4, 0.05, "Linear"], [HOLD, 0.1, "Quad In"], [HOLD + 6, 1]],
                        "its white core", From="Cast"),
    }
    for side, part in (("Left", "Left Arm"), ("Right", "Right Arm")):
        rows[f"Sleeve{side}"] = card(MINT, v3(0, -1.1, 0),  # the sleeve's end
                                     [[-12, 0.3, "Quad Out"], [0, 1.0, "Sine InOut"], [HOLD, 0.9, "Quad In"], [HOLD + 8, 0]],
                                     [[-12, 0.9, "Quad Out"], [0, 0.35, "Linear"], [HOLD, 0.4, "Quad In"], [HOLD + 8, 1]],
                                     "each sleeve's end lit a little, feeding the light between them", body=part, From="Cast")
    turning = needles(0, [2.5, 3.5], [0.18, 0.26], 180, 0.55, 0)
    turning["Emitter"]["Color"] = c3(MINT)
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
            "Kind": "Beam", "Image": "fx_beam", "Color": c3(MINT), "Beam": BEAM,
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
                "Width": [[0, 0.45, "Quad Out"], [8, 0.38, "Quad In"], [22, 0.1]],
            },
            "Why": "its white core",
        },
        "Flash": card(WHITE, ORB_FOOT, [[0, 2.6, "Quad Out"], [3, 3.0, "Quad In"], [10, 0]], [[0, 0.2, "Quad In"], [10, 1]],
                      "the held light going: a flash at the caster as the beam leaves", body=None),
    }
    return effect("SupportLink", "A Support's cast landing: the beam to the one it's for (AR58, target A, Scintilla).", rows)


def heal():
    chest = CHEST_FOOT
    rows = {
        "Core": card(WHITE, chest, [[LAND, 0.5, "Quad Out"], [LAND + 2, 1.7, "Quad In"], [LAND + 10, 0]],
                     [[LAND, 0.2, "Quad In"], [LAND + 10, 1]],
                     "the hero's heart: a white core at its chest as the beam arrives, soft (0.2) and gone in a sixth of a second", body=None),
        "Glow": card(MINT, chest, [[LAND, 3.0, "Quad Out"], [LAND + 4, 6.0, "Quad In"], [LAND + 20, 0]],
                     [[LAND, 0.05, "Quad In"], [LAND + 20, 1]], "the mint round it", body=None),
    }
    burst = needles(14, [10, 15], [0.26, 0.4], 70, 1.0, LAND, direction="Top")
    burst["Emitter"]["Color"] = c3(MINT)
    burst["Tracks"] = {"At": [[LAND, chest]]}
    burst["Why"] = "14 needles thrown out of its chest leaning up, fast then slow: light leaving it, never falling"
    rows["Needles"] = burst
    # the dome's rim: the kit's ring, swelling round it as it fades. Plain: no ornament, nothing beside it (the content check)
    ring = {"Lifetime": [0.4, 0.4], "Speed": [0, 0], "Size": [[0, 2.4], [0.4, 4.0], [1, 4.8]], "Rotation": [0, 0],
            "Transparency": [[0, 0], [0.4, 0.25], [1, 1]],  # its rim fades as it swells (A's dome), never a held hoop
            "FlipbookLayout": "Grid4x4", "FlipbookMode": "OneShot", "LightInfluence": 0}
    for name, own, image in (
        ("RimLine", {"Color": c3(PALE), "LightEmission": 1, "ZOffset": FRONT + LAYER}, "fx_ring_line"),
        ("RimFill", {"Color": c3(MINT), "LightEmission": 1, "ZOffset": FRONT}, "fx_ring_fill"),
    ):
        rows[name] = {"Kind": "Emitter", "Image": image, "Emitter": {**ring, **own},
                      "Emit": [[LAND + 1, 1]], "Tracks": {"At": [[LAND + 1, chest]]},
                      "Why": "the dome's rim: a ring swelling round it as it fades" if name == "RimLine" else f"the rim's {name[3:].lower()} pass"}
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
            "Color": c3(MINT), "LightEmission": 1, "LightInfluence": 0, "ZOffset": FRONT,
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
    for i in range(14):
        a = i / 14 * 2 * math.pi
        top = round(height * (0.78 + 0.22 * ((i * 37) % 5) / 4), 3)
        rows[f"Ribbon{i + 1:02d}"] = {
            "Kind": "Beam", "On": "Veil", "Image": "fx_beam", "Color": c3(MINT), "Beam": RIBBON, "Taper": 0.1, "FootFade": 0.3,
            "Tracks": {
                "At": [[0, v3(round(math.cos(a) * radius, 3), 0, round(math.sin(a) * radius, 3))]],
                "Top": [[0, 0, "Quad Out"], [rise, top], [FAR, top]],
                "Width": [[0, 0.5, "Quad Out"], [rise, 0.34], [FAR, 0.34]],
                "Transparency": [[0, 0], [FAR, 0]],
            },
            "Why": "the hero: ribbons of light rising round it from its feet and holding" if i == 0 else "a ribbon",
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
