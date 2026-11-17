"""The base's and the Strip's own light: AR20's C, bright hours (research's pick, 2026-11-16, 17:23, with round 2's
fill). From the director's word of 16:50: "imo we should remove all that in base and around it it way to much + need
to be less somber". No mist in any phase; a clean pale yard by day, a rose-lilac dusk, a silver moonlit night; the void
the world's one dark. Lantern Row keeps its own light and sky.

The paint is in the kits: base_kit.py's steel, girders, concrete and deck, and the far pieces' swatches; strip_kit.py's
paving and empty lots. This script holds the light, in the look's units, and writes:
  sky   the dusk's and the night's six faces for the base and the Strip (the day keeps sky_day.py's), and lighting.json,
        each phase in Roblox's terms, as Config.Lighting.Clear takes them (Faber's seeds, tuned by playing)
  see   a check from the player's camera: the start camera in the base, or the crossing and the far gate on the Strip

Run under the guard:  base_light.py -- <out> sky | see <base|strip> [day] [dusk] [night] [fast]
"""

import json
import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "art"))
import sky_day  # noqa: E402
import strip_plan as splan  # noqa: E402

block, strip = splan.block, splan.strip
plan, base, look, kit, bl = block.plan, block.base, block.look, block.kit, block.bl

DUSK, NIGHT = dict(look.DIRECTIONS["M"]), dict(look.DIRECTIONS["N"])


def elevations(ramp, horizon=None):
    """sky_day's ramp, by elevation in degrees, as the look's stops (the direction's height, from -0.2 up)."""
    out = []
    for el, code in ramp:
        z = round(max(math.sin(math.radians(el)), -0.2), 4)
        if el == 0.0 and horizon:
            code = horizon
        if not out or z > out[-1][0]:
            out.append((z, code))
    return tuple(out)


# The day as the game had it (Config.Lighting.Phases.Day; sky_day.py's seeds), in the look's units: the sun and the
# fill are the dusk's frame times the game's ratios.
DAY = dict(DUSK, name="Base day", idea="the game's day: the painted azure sky, a warm sun, a lilac fill",
           sky=elevations(sky_day.RAMP), sky_away=elevations(sky_day.RAMP, sky_day.COOL),
           clouds=("#FFFFFF", "#BCC9EE", 0.03, 0.24, 0.56), stars=0.0, moon=None,
           sun=(DUSK["sun"][0], DUSK["sun"][1], "#FFE2B8", 0.87, True), ambient=("#8A8496", 1.0),
           fog=DUSK["fog"], fog_away="#A9BCE4", bloom=(1.4, 0.4, (6, 20)))
BEFORE = {"day": DAY, "dusk": DUSK, "night": NIGHT}
# The game's shares by phase (Config.Lighting.Phases: Glow, Floor over the dusk's 0.85, Lights), and its Floor.
SHARES = {"day": dict(glow=0.45, floor=0.35 / 0.85, lights=0.2), "dusk": dict(glow=1.0, floor=1.0, lights=1.0),
          "night": dict(glow=1.0, floor=1.1 / 0.85, lights=1.0)}
FLOOR = {"day": 0.35, "dusk": 0.85, "night": 1.1}

# C, per phase, over the light before: the fill (colour, strength), the sun (times its strength, and its colour), the
# exposure, and the painted sky (its ramp toward the sun, away from it, and the clouds).
C = {
    "day": dict(ambient=("#A3A1B4", 1.0), exposure=1.12),
    "dusk": dict(ambient=("#8C7AAE", 0.62), sun=1.4, sun_colour="#DDB8EC", exposure=1.3,
                 sky=((-0.2, "#6E5288"), (0.0, "#FFB6C0"), (0.05, "#F8A0BC"), (0.16, "#BC8ED8"), (0.38, "#7474C4"),
                      (1.0, "#3E4A9C")),
                 sky_away=((-0.2, "#4E4A86"), (0.0, "#9A8ACC"), (0.08, "#8074BC"), (0.3, "#5A5CA8"), (1.0, "#3E4A9C")),
                 clouds=("#FFB0C8", "#6A60AC", 0.03, 0.2, 0.56)),
    "night": dict(ambient=("#6A76A6", 0.55), sun=1.5, sun_colour="#BCCAF0", exposure=1.45,
                  sky=((-0.2, "#1C2856"), (0.0, "#8A90D0"), (0.05, "#5E70BC"), (0.2, "#33509C"), (0.5, "#20367A"),
                       (1.0, "#162860")),
                  sky_away=((-0.2, "#18244E"), (0.0, "#506AB0"), (0.08, "#3E58A0"), (0.3, "#2A428A"), (1.0, "#162860")),
                  clouds=("#7A8CCC", "#26386E", 0.02, 0.18, 0.62)),
}
GLOW, LIGHTS = 1.5, 1.3   # in every phase: the kit's and the floors' glow, and the pools', times the game's own
SHARD = strip.BRIGHT["CrossingShard"]   # the crossing's shard keeps its own glow: none of the lift (research's pick, fix 3)
MAPS = dict(base.MAPS)
FACES_NAME = {"dusk": "Dusk", "night": "Night"}


def direction(phase):
    """A phase in C's light, in the look's units."""
    p = C[phase]
    d = dict(BEFORE[phase])
    for key in ("ambient", "exposure", "sky", "sky_away", "clouds"):
        if key in p:
            d[key] = p[key]
    az, el, code, strength, shadow = d["sun"]
    d["sun"] = (az, el, p.get("sun_colour", code), strength * p.get("sun", 1.0), shadow)
    d["fog"] = (d["fog"][0], 0.0)   # no mist
    colour, watts, cone = DUSK["string_light"]
    d["string_light"] = (colour, watts * SHARES[phase]["lights"] * LIGHTS, cone)
    return d


def light(phase):
    """The look and the kit's glows set for a phase: what a render sees."""
    d, s = direction(phase), SHARES[phase]
    for name, (tint, strength) in MAPS.items():
        base.MAPS[name] = (tint, strength * GLOW * (s["glow"] if name == "Kit" else s["floor"]))
    strip.BRIGHT["CrossingShard"] = SHARD / GLOW
    look.DIRECTIONS["M"] = d
    return d


def roblox(phase):
    """A phase as Config.Lighting takes it: the look's sun strength times 3 is Brightness, its fill's colour times
    strength is Ambient ("asOne"), its exposure's log2 is ExposureCompensation."""
    d, p = direction(phase), C[phase]
    amb, k = d["ambient"]
    sun = d["sun"]
    out = dict(Ambient=kit.hex_of(np.array(look.srgb(amb), np.float32) * k), Brightness=round(sun[3] * 3, 2),
               Exposure=round(math.log2(d.get("exposure", 1.0)), 2), Floor=round(FLOOR[phase] * GLOW, 3),
               Glow=round(SHARES[phase]["glow"] * GLOW, 3))
    if "sun_colour" in p:
        out["Sun"] = p["sun_colour"]
    if phase in FACES_NAME:
        out["Sky"] = {f: f"sky/Base_Sky{FACES_NAME[phase]}_{f}.png" for f in kit.FACES}
    return out


def skies(out: Path):
    """The dusk's and the night's six faces, drawn by direction as Lantern Row's are (lantern_row_kit.skies)."""
    sky = out / "sky"
    sky.mkdir(parents=True, exist_ok=True)
    for phase, name in FACES_NAME.items():
        look.DIRECTIONS["M"] = direction(phase)
        kit.skies(sky, "M")
        for face in kit.FACES:
            (sky / f"LanternRow_SkyDusk_{face}.png").replace(sky / f"Base_Sky{name}_{face}.png")
    numbers = dict(
        what="AR20's C, bright hours: the base's and the Strip's light in every phase (research's pick, 2026-11-16, "
             "17:23). Lantern Row keeps its own.",
        atmosphere=dict(Density=0, Haze=0, Glare=0, note="no mist in any phase (the director, 16:50)"),
        phases={phase.capitalize(): roblox(phase) for phase in C},
        lift=dict(Glow=GLOW, Lights=LIGHTS, note="the kit's glow (Glow.Kit) and each phase's Floor and Glow are already "
                                                  "lifted above; the pools' and the lead's light take Lights times "
                                                  "theirs. The crossing's shard takes none of the lift"),
        sky=dict(note="Base_Sky<Phase>_<face>.png, faces as Lantern Row's (Ft up the side street, -Z): drawn to be seen "
                      "under the phase's Exposure; the day keeps the game's own day sky"),
        shard=dict(CrossingShard=SHARD, note="its EmissiveStrength over the kit's before the lift: the same light as today"))
    (out / "lighting.json").write_text(json.dumps(numbers, indent=1), encoding="utf-8")
    print(json.dumps(numbers["phases"]))


def see(out: Path, where, phases, fast):
    for phase in phases:
        folder = out / where / phase
        folder.mkdir(parents=True, exist_ok=True)
        light(phase)
        if where == "base":
            plan.see(folder, 1, fast, False, ["home"])
        else:
            base.write_pictures(folder / "maps")
            block.BASE_MAPS = folder / "maps"
            splan.see(folder, ["crossing", "far"], fast)
        print(f"LIGHT: {where} {phase} done")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    if args[0] == "sky":
        skies(out)
    else:
        see(out, args[1], [a for a in args[2:] if a in C] or list(C), "fast" in args)


if __name__ == "__main__":
    main()
