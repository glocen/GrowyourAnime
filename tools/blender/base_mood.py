"""The base and the map round it with no mist and less somber (the director, 2026-11-16, 16:50: "imo we should remove
all that in base and around it it way to much + need to be less somber"; docs/decisions.md, the row on the mist).
Research's ask: two or three takes from the player's camera, at day, dusk and night, under the look with no mist, for
research's pick; Faber sets the lighting in the place. Exploration, tier 1: these numbers are a sheet's, not the kit's.
Each take writes its own pictures into the out folder; the delivered ones are never touched.

Today's look beside three takes, each moving more of the levers, so the pick is also a pick of cost:
  A, clear air: the mist gone, the fill and the exposure lifted. Numbers only (Config.Lighting).
  B, clean steel: A's light, the yard re-toned out of grey-violet into light steel and pale concrete, so the void's
     violet is the only violet left; the void's and the current's light brighter; the distance painted into the far
     shards and the Tower asleep, and the empty lots lifted, since no haze pales them now. The base kit's pictures
     redrawn.
  C, bright hours: B under lighter skies and a turned fill, a rose-lilac dusk and a silver moonlit night, lifted
     further. B's pictures, and the dusk's and the night's sky faces painted again for the base and the Strip;
     Lantern Row keeps its own.

Run under the guard:  base_mood.py -- <out> <base|strip> <take> [phases] [fast] [shard=<x>]
  base: the game's start camera in the base. strip: from the crossing, and from the far gate at the base's new size
  (the crossing's shard, whose glow is 2.5 times the kit's, rechecked against the sky with no haze).
"""

import math
import sys
from pathlib import Path

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


# The day as the game has it (Config.Lighting.Phases.Day; sky_day.py's seeds), in the look's units: the sun and the
# fill are the dusk's frame times the game's ratios, the haze the Atmosphere's 0.16 to the dusk's 0.22.
DAY = dict(DUSK, name="Base day", idea="the game's day: the painted azure sky, a warm sun, a lilac fill",
           sky=elevations(sky_day.RAMP), sky_away=elevations(sky_day.RAMP, sky_day.COOL),
           clouds=("#FFFFFF", "#BCC9EE", 0.03, 0.24, 0.56), stars=0.0, moon=None,
           sun=(DUSK["sun"][0], DUSK["sun"][1], "#FFE2B8", 0.87, True), ambient=("#8A8496", 1.0),
           fog=("#EFE3D6", DUSK["fog"][1] * 0.16 / 0.22), fog_away="#A9BCE4", bloom=(1.4, 0.4, (6, 20)))
PHASES = {"day": DAY, "dusk": DUSK, "night": NIGHT}
# The game's shares by phase (Config.Lighting.Phases: Glow, Floor over the dusk's 0.85, Lights).
SHARES = {"day": dict(glow=0.45, floor=0.35 / 0.85, lights=0.2), "dusk": dict(glow=1.0, floor=1.0, lights=1.0),
          "night": dict(glow=1.0, floor=1.1 / 0.85, lights=1.0)}

# --- the takes -------------------------------------------------------------------------------------------------------
# Per phase, what a take changes from today's: ambient (colour, strength), sun (times its strength), exposure, mist
# (times the haze's density: 0 is none), sky, sky_away and clouds (the painted sky), glow (times the kit's and the
# floors' glow), lights (times the pools'). For the whole take: deck (the deck's four tones), swatches (the kit's),
# stones (times the Strip's stones).
CLEAR = {"day": dict(mist=0.0, ambient=("#A3A1B4", 1.0), exposure=1.08),
         "dusk": dict(mist=0.0, ambient=("#4A4F96", 0.55), sun=1.3, exposure=1.2),
         "night": dict(mist=0.0, ambient=("#2C3E86", 0.55), sun=1.4, exposure=1.3)}
STEEL = dict(deck=("#9EA7BC", "#8790A8", "#3A4154", "#BEC6D6"),
             swatches={"steel": ("#8290B0", "#46506E", 0.0), "concrete": ("#C8CAD2", "#82858F", 0.0),
                       "girder": ("#4C5878", "#242C42", 0.0)},
             distance=True, lots="#6E7290")
# The distance, painted in: the far shards ("dark and unlit, the distance pales it") and the Tower asleep ("one dark
# silhouette") were drawn for the haze, and with none they stand as black cut-outs against the sky. Takes B and C give
# them their own swatches, in the atlas's free cells beside the second row: a pale void stone for the far shards, a
# violet slate for the Tower. Only those pieces wear them.
DISTANCE = {"far": ("#9284C8", "#5E5298", 0.0), "tower": ("#7C76AE", "#46427A", 0.0)}
WEARS = {"tower": ("dark", ["TowerSleeping"]), "far": ("abyss", list(strip.SHARDS))}


def more(phases, **each):
    return {p: dict(v, **each) for p, v in phases.items()}


TAKES = {
    "today": dict(name="Today", idea="as the game has it: the haze in every phase, the yard's grey-violet steel",
                  phases={}),
    "A": dict(name="A, clear air", idea="the mist gone, the fill and the exposure lifted; numbers only",
              phases=CLEAR),
    "B": dict(name="B, clean steel", idea="A's light; the yard out of grey-violet into light steel and pale concrete, "
                                          "the void's violet the only violet; its light and the current's brighter",
              phases=more(CLEAR, glow=1.4, lights=1.25), stones=1.2, **STEEL),
    "C": dict(name="C, bright hours", idea="B under lighter skies, the fill's hue turned: a rose-lilac dusk, a silver "
                                           "moonlit night, lifted further",
              phases={"day": dict(CLEAR["day"], exposure=1.12, glow=1.5, lights=1.3),
                      "dusk": dict(CLEAR["dusk"], ambient=("#8C7AAE", 0.62), sun=1.4, sun_colour="#DDB8EC", exposure=1.3,
                                   glow=1.5, lights=1.3,
                                   sky=((-0.2, "#6E5288"), (0.0, "#FFB6C0"), (0.05, "#F8A0BC"), (0.16, "#BC8ED8"),
                                        (0.38, "#7474C4"), (1.0, "#3E4A9C")),
                                   sky_away=((-0.2, "#4E4A86"), (0.0, "#9A8ACC"), (0.08, "#8074BC"), (0.3, "#5A5CA8"),
                                             (1.0, "#3E4A9C")),
                                   clouds=("#FFB0C8", "#6A60AC", 0.03, 0.2, 0.56)),
                      "night": dict(CLEAR["night"], ambient=("#6A76A6", 0.55), sun=1.5, sun_colour="#BCCAF0", exposure=1.45,
                                    glow=1.5, lights=1.3,
                                    sky=((-0.2, "#1C2856"), (0.0, "#8A90D0"), (0.05, "#5E70BC"), (0.2, "#33509C"),
                                         (0.5, "#20367A"), (1.0, "#162860")),
                                    sky_away=((-0.2, "#18244E"), (0.0, "#506AB0"), (0.08, "#3E58A0"), (0.3, "#2A428A"),
                                              (1.0, "#162860")),
                                    clouds=("#7A8CCC", "#26386E", 0.02, 0.18, 0.62))},
              stones=1.35, **STEEL),
}

ORIGINAL = dict(deck=base.DECK_TONES, swatches=dict(base.SWATCHES), maps=dict(base.MAPS))
STONES, LOTS = [1.0], [None]   # the take's share on the Strip's stones; the empty lots' tint (today's #3A3C52)
_tile = plan.tile_material


def tile_material(name, image, studs, tint="#FFFFFF"):
    """The plan's tiled floor, the Strip's stones lit by the take's share: a stand-in for a lighter picture."""
    if name == "LotAsleep" and LOTS[0]:
        tint = LOTS[0]
    mat = _tile(name, image, studs, tint)
    if name == "Stones" and STONES[0] != 1.0:
        mix = next(n for n in mat.node_tree.nodes if n.bl_idname == "ShaderNodeMix")
        mix.inputs[7].default_value = (*[v * STONES[0] for v in look.srgb(tint)], 1)
    return mat


plan.tile_material = tile_material


def painted(make, old, new):
    """A piece built with swatch `old` drawn from `new`'s cell: the mesh builder reads a swatch's cell as it lays a face."""
    def build():
        base.wear()
        keep = base.SWATCH_AT[old]
        base.SWATCH_AT[old] = base.SWATCH_AT[new]
        try:
            return make()
        finally:
            base.SWATCH_AT[old] = keep
    return build


def distance():
    """Takes B and C: the far shards and the Tower asleep in their own swatches (DISTANCE)."""
    for i, (name, swatch) in enumerate(DISTANCE.items()):
        base.SWATCHES[name] = swatch
        n = len(ORIGINAL["swatches"]) + i
        base.SWATCH_AT[name] = ((n % 16) * base.CELL[0], (n // 16) * base.CELL[1])
        old, pieces = WEARS[name]
        for piece in pieces:
            book = strip.PIECES if piece in strip.PIECES else base.PIECES
            book[piece] = painted(book[piece], old, name)


def direction(take, phase, shard=None):
    """Today's phase with the take's changes, and the kit's pictures and glows set for it."""
    t, s = TAKES[take], SHARES[phase]
    p = t["phases"].get(phase, {})
    d = dict(PHASES[phase])
    for key in ("ambient", "exposure", "sky", "sky_away", "clouds"):
        if key in p:
            d[key] = p[key]
    az, el, code, strength, shadow = d["sun"]
    d["sun"] = (az, el, p.get("sun_colour", code), strength * p.get("sun", 1.0), shadow)
    d["fog"] = (d["fog"][0], d["fog"][1] * p.get("mist", 1.0))
    colour, watts, cone = DUSK["string_light"]
    d["string_light"] = (colour, watts * s["lights"] * p.get("lights", 1.0), cone)
    base.DECK_TONES = t.get("deck", ORIGINAL["deck"])
    base.SWATCHES.update(ORIGINAL["swatches"])
    base.SWATCHES.update(t.get("swatches", {}))
    glow = p.get("glow", 1.0)
    for name, (tint, strength) in ORIGINAL["maps"].items():
        base.MAPS[name] = (tint, strength * glow * (s["glow"] if name == "Kit" else s["floor"]))
    STONES[0], LOTS[0] = t.get("stones", 1.0), t.get("lots")
    if shard is not None:
        strip.BRIGHT["CrossingShard"] = shard
    look.DIRECTIONS["M"] = d
    return d


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    where, take = args[0], args[1]
    phases = [a for a in args[2:] if a in PHASES] or list(PHASES)
    fast = "fast" in args
    shard = next((float(a.split("=")[1]) for a in args if a.startswith("shard=")), None)
    if TAKES[take].get("distance"):
        distance()
    for phase in phases:
        folder = out / where / take / phase
        folder.mkdir(parents=True, exist_ok=True)
        direction(take, phase, shard)
        if where == "base":
            plan.see(folder, 1, fast, False, ["home"])
        else:
            base.write_pictures(folder / "maps")
            block.BASE_MAPS = folder / "maps"
            splan.see(folder, ["crossing", "far_new"], fast)
        print(f"MOOD: {where} {take} {phase} done")


if __name__ == "__main__":
    main()
