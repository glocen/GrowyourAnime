"""AR39, the sound rescue: the three pilots' arrangements, as recipes for Faber's mixdown and the cue registry.

Reads the shortlist batch's numbers (build/scratch/modulo/ar39/<brief>.json, as tools/audio/ar39_rank.py does) and our
own AR13 takes (build/handoff/Audio/test6/), and writes each pilot's arrangements in Config.Cues' own shape: the takes
(a library sound's slice of its file, its fades, its time to its top) and the layers (each one's start and volume).
Nothing here hears a sound or holds one: a library sound stays in the library, played by its id and slice. Whether an
arrangement convinces stays UNVERIFIED, and every level is a seed: the gates are measured on Faber's mixdown.

How a recipe is made:
- **A take's slice** starts PRE ms before its onset (the last moment 20 dB under its top, ar39_rank.onset), where its
  file is near silent, and ends where the arrangement says, after its top, with a fall over its Out. A rustle's slice
  starts a set time before its top.
- **A take's Gain** (linear, a new field on a library take) brings every take of one list to that list's level, since a
  library sound can't be levelled offline. Its loudness is the batch's own (the loudest 400 ms, K-weighted), moved by
  the energy its trimmed slice keeps, read from its envelope.
- **A layer's Volume** then sets its list's level to the arrangement's, so one play's layers stand as designed. The
  player's volume (Trim x Volume x Gain) is held under CAP.
- **The estimates,** from the batch's numbers, never a measure: a cue's loudness as its layers' energies summed; its
  top as its layers' tops summed (the worst case); its share under 120 Hz and its loss through the phone's curve from
  each take's bands.

- **Round 2's set** (NO_CODE) has no layer of ours in it: the director heard our code-made layers on 2026-11-17 and
  none is used, so a pilot is library recordings only, layered. It's re-cut on Faber's measures of round 1
  (build/scratch/modulo/ar39/mixdown.json; research's list of 2026-11-17, 23:05), each change named where it's made:
  the engine's Trim counted in the estimate, the takes that topped late or couldn't be played dropped, a tell's top
  pinned under its swipe's, and less of the low thump. The second batch isn't on disk
  yet, so its lists are the first batch's.

    py tools/audio/ar39_arrange.py            writes build/handoff/Audio/ar39/round1.json, round1.luau and round1.md
    py tools/audio/ar39_arrange.py round2     the same for round 2's set
"""
import json
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import ar39_rank as rank  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
OURS = REPO / "build" / "handoff" / "Audio" / "test6"
OUT = REPO / "build" / "handoff" / "Audio" / "ar39"
ROUND = "round1"
PRE, IN = 2.0, 0.003          # ms before the onset a slice starts; the rise the gate asks, s
CAP = 3.0                     # an AudioPlayer's most volume
TRIM = 0.5                    # Config.Cues.Trim
# The pilots' levels against LightHit's, LU (gate 4: HeavyHit 3 to 5 over, ShadeSwipe 3 to 6 under), by the loudest
# 400 ms of one play at the cue's full volume. The relation sets the levels (research, 2026-11-17, 22:30: gate 3 means a
# fight's overlaps, and an exact coincidence is the bus limiter's, never the cues' level). LightHit's own level is where
# the hottest single cue's top, its layers' tops together, stands at ROOM: -4 dBFS, a decibel for the true peak and the
# limiter's 3 for an overlap.
OVER = {"LightHit": 0.0, "HeavyHit": 4.0, "ShadeSwipe": -4.5}
ROOM = 10 ** (-4.0 / 20)

# A library take: its id; how its slice starts ("onset", ("onset", its own ms before it), or ms before its top); ms
# after its top it ends; its fall, ms.
# Lists are by role. One recording never stands twice in a list, nor two of one series.
TAKES = {
    # a skin or cloth contact, its energy from 250 Hz to 2.5 kHz: the whole of a light hit, or a heavy one's contact
    "LibContact": [(9120003720, "onset", 70, 30), (9114773313, "onset", 70, 30), (9113532901, "onset", 45, 20),
                   (9113316991, "onset", 30, 15)],
    # a glove or cloth thud, half its energy under 250 Hz: a light hit's body under a snap
    "LibThud": [(9113574504, "onset", 100, 40), (9113818926, "onset", 60, 25), (9113531442, "onset", 100, 40)],
    # a clap's crack, gone in 30 ms: the attack laid on a body from another recording
    "LibSnap": [(9114763106, "onset", 30, 15), (9114762131, "onset", 20, 10), (9114771788, "onset", 50, 25)],
    # a deep glove thump, most of it under 120 Hz: recorded weight under a contact
    "LibLow": [(9113568059, "onset", 100, 40), (9113514100, "onset", 90, 40)],
    "LibLowLong": [(9113568059, "onset", 130, 50), (9113514100, "onset", 180, 60)],
    # a heavy body, one contact, its weight in the low mids
    "LibHeavyBody": [(9113574140, "onset", 130, 50), (9113531442, "onset", 140, 50), (9113470397, "onset", 110, 50)],
    # a leather or clap snap for the heavy hit's edge
    "LibHeavySnap": [(9113316991, "onset", 30, 15), (9114763106, "onset", 30, 15), (9114762131, "onset", 20, 10)],
    # cloth or a thin blade through the air: the swipe's pass, its top on the beat
    "LibAir": [(9120704978, "onset", 160, 60), (9120972444, "onset", 130, 60), (9120709477, 46, 90, 40)],
    # paper's flick: the tell's tick, 0.2 s before the swipe's top
    "LibFlick": [(9125654187, 6, 30, 15), (9114348719, 30, 60, 30), (9118106802, 60, 60, 30)],
    # paper drawn back, a dry rustle ending in its flick: the longer tell, and the paper on a pass's top
    "LibRustle": [(9125654187, 150, 20, 12), (9126143504, 110, 90, 40), (9118106802, 190, 60, 30)],
}
# Our own takes (tools/audio/test6.py), each list already matched in loudness: played whole.
OUR_TAKES = ("LightHitSpark", "HeavySub", "HeavyTail", "ShadeTell", "ShadeSwipe")

# The arrangements: a pilot's are built differently, never one's pitch copies. A layer: its takes, its role, its start
# (At, s, and Lead as Config.Cues has them), its level under or over the cue's own, dB (a seed).
ARRANGEMENTS = {
    "LightHit": [
        ("LightHit_A1", "one recorded contact, nothing else: a slap of skin or cloth carries the hit whole, in the band "
         "a phone keeps",
         [("LibContact", "body", 0, None, 0.0, False)]),
        ("LightHit_A2", "two recordings split by their bands: a glove or cloth thud for the body, a clap's crack laid on "
         "it for the contact",
         [("LibThud", "body", 0, None, -1.0, False), ("LibSnap", "attack", 0, None, -6.0, False)]),
        ("LightHit_A3", "a recorded contact with recorded weight under it, and our spark as its accent, 10 dB under",
         [("LibContact", "body", 0, None, -1.0, False), ("LibLow", "weight", 0, None, -6.0, False),
          ("LightHitSpark", "accent", 0, None, -11.0, False)]),
    ],
    "HeavyHit": [
        ("HeavyHit_B1", "one recorded heavy body as the base; our sub only reinforces it, and our tail by the hit's "
         "strength. The knocks are gone",
         [("LibHeavyBody", "body", 0, None, -0.5, False), ("HeavySub", "weight", 0, None, -10.0, False),
          ("HeavyTail", "decay", 0, None, -12.0, True)]),
        ("HeavyHit_B2", "two recordings and no synthesis: a deep glove thump for the weight, and the light hit's own "
         "contact over it, so a heavy hit is a light one with a body behind it",
         [("LibLowLong", "weight", 0, None, -3.0, False), ("LibContact", "attack", 0, None, -3.0, False)]),
        ("HeavyHit_B3", "a recorded heavy body with a recorded snap on its edge, and no sub: the body's own lows carry "
         "it. Our tail by the hit's strength",
         [("LibHeavyBody", "body", 0, None, -1.0, False), ("LibHeavySnap", "attack", 0, None, -8.0, False),
          ("HeavyTail", "decay", 0, None, -12.0, True)]),
    ],
    "ShadeSwipe": [
        ("ShadeSwipe_C1", "all recorded: paper's flick for the tell, a pass through the air for the swipe",
         [("LibFlick", "tell", -0.2, "Peak", -9.0, False), ("LibAir", "body", 0, "Peak", -0.5, False)]),
        ("ShadeSwipe_C2", "a paper-edged pass: the air's pass with a sheet's rustle riding its top; the tell stays ours",
         [("ShadeTell", "tell", -0.2, None, -9.5, False), ("LibAir", "body", 0, "Peak", -1.5, False),
          ("LibRustle", "character", 0, "Peak", -6.0, False)]),
        ("ShadeSwipe_C3", "the paper drawn back, then the pass: a longer rustle ending in its flick for the tell, and our "
         "own swipe 10 dB under the recorded pass, for its tone",
         [("LibRustle", "tell", -0.2, "Peak", -7.0, False), ("LibAir", "body", 0, "Peak", -1.0, False),
          ("ShadeSwipe", "accent", 0, "Peak", -11.0, False)]),
    ],
}

# Round 2: library recordings only (research's order after the director's ear, 2026-11-17). Contact comes from a sharp
# glove or clap transient over a body, weight from a low thud out of a second recording. A2's thuds are out (the
# phone's read, research, 22:30); a heavy hit's tail and a swipe's tone, which were ours, are gone with nothing in
# their place until a recording earns it. A tell's level is ("under", a list, dB): its top that far under that list's
# lowest top in the cue, since a tick is read by its top (round 1's tells topped over their swipes).
NO_CODE = {
    "LightHit": [
        ("LightHit_A1", "one recorded contact, nothing else: a slap of skin or cloth carries the hit whole, in the band "
         "a phone keeps",
         [("LibContact", "body", 0, None, 0.0, False)]),
        ("LightHit_A3", "a recorded contact with recorded weight under it from a second recording. Our spark is gone",
         [("LibContact", "body", 0, None, -1.0, False), ("LibLow", "weight", 0, None, -9.0, False)]),
        ("LightHit_A4", "a recorded contact with a clap's crack laid on its edge: the transient from one recording, the "
         "body from another",
         [("LibContact", "body", 0, None, -1.0, False), ("LibSnap", "attack", 0, None, -8.0, False)]),
    ],
    "HeavyHit": [
        ("HeavyHit_B1", "one recorded heavy body, and a deep glove thump from a second recording under it for the "
         "weight, where our sub was",
         [("LibHeavyBody", "body", 0, None, -0.3, False), ("LibLowLong", "weight", 0, None, -12.0, False)]),
        ("HeavyHit_B2", "two recordings: the light hit's own contact, and a deep glove thump 9 dB under it for the "
         "weight, so a heavy hit is a light one with a body behind it (at equal levels the thump put 63% of the cue "
         "under 120 Hz)",
         [("LibContact", "attack", 0, None, -0.5, False), ("LibLowLong", "weight", 0, None, -9.5, False)]),
        ("HeavyHit_B3", "three recordings stacked: a heavy body, a leather or clap snap on its edge, and a deep thump "
         "under both",
         [("LibHeavyBody", "body", 0, None, -1.0, False), ("LibHeavySnap", "attack", 0, None, -8.0, False),
          ("LibLowLong", "weight", 0, None, -11.0, False)]),
    ],
    "ShadeSwipe": [
        ("ShadeSwipe_C1", "paper's flick for the tell, a pass through the air for the swipe",
         [("LibFlick", "tell", -0.2, "Peak", ("under", "LibAir", 2.0), False), ("LibAir", "body", 0, "Peak", 0.0, False)]),
        ("ShadeSwipe_C2", "a paper-edged pass: paper's flick for the tell, then the air's pass with a sheet's rustle "
         "riding its top",
         [("LibFlick", "tell", -0.2, "Peak", ("under", "LibAir", 2.0), False), ("LibAir", "body", 0, "Peak", -1.0, False),
          ("LibRustle", "character", 0, "Peak", -7.0, False)]),
        ("ShadeSwipe_C3", "the paper drawn back, then the pass: a longer rustle ending in its flick for the tell, and "
         "the recorded pass alone",
         [("LibRustle", "tell", -0.2, "Peak", ("under", "LibAir", 2.0), False), ("LibAir", "body", 0, "Peak", 0.0, False)]),
    ],
}
# Round 2's lists, where Faber's measures changed one (round 1's, a take alone, in mixdown.json; the draft's cues in
# mixdown-round2.md):
# - 9120003720 is out of the contacts: alone its top comes 8.0 ms in, with a second top nearly as high at 16.6 ms, and
#   any layer under it tips the cue's top to the later one (A3, A4 and B2, play 1; Faber's correction). The second top
#   follows the first, so no From cuts it off.
# - 9113531442 is out of the heavy body: a kick in two stages, its loudest sample 20.5 ms after its first contact.
# - 9113470397 is out of the heavy body: so quiet a file that its Gain (7.27) passed the player's most volume, and it
#   has no louder part. That leaves the heavy body ONE recording until the second batch is on disk: B1 and B3 can't
#   vary their body yet.
TAKES2 = dict(TAKES)
TAKES2.update({
    "LibContact": [(9114773313, "onset", 70, 30), (9113532901, "onset", 45, 20), (9113316991, "onset", 30, 15)],
    "LibHeavyBody": [(9113574140, "onset", 130, 50)],
})
GAIN_CAP = 3.0   # research, 2026-11-17: every take's Gain stays at or under 3
# A round's set-up. `over`: its own levels over OVER. `trim`: the engine's Trim is counted in a Volume (Faber, measured:
# a player at Volume 1 plays its file as it is, so Trim 0.5 is a plain 6 dB under; round 1's Volumes left it out and
# its cues came out 6 dB under their design). `light`: LightHit's level, LUFS, or None for round 1's rule (ROOM).
# Round 2's is where its draft measured (-43.4 over the loudest 400 ms; -52.2 short-term), so the Volumes stand as they
# were and only the estimate is corrected: research's word is not to chase the level, since the listen is matched to
# today's cue per arrangement. For when the level is set: a recorded contact's top stands 27 dB over its loudness
# (today's LightHit, 25), so these cues top where today's do at about 1.5 LU under today's LightHit.
# Round 2's heavy hit stands 4.2 LU over the light one: the draft, at 4.5, measured 4.5 to 4.8, near gate 4's 5.
SETUPS = {
    "round1": dict(takes=TAKES, cues=ARRANGEMENTS, over={}, trim=False, light=None),
    "round2": dict(takes=TAKES2, cues=NO_CODE, over={"HeavyHit": 4.2}, trim=True, light=-43.4),
}
SET = SETUPS["round1"]
MEASURED = REPO / "build" / "scratch" / "modulo" / "ar39" / "mixdown.json"   # Faber's measures of round 1
# What a deep thump holds in raw energy against a contact or a body at one loudness: K-weighting hears little of it.
# Fitted to the draft's measured shares under 120 Hz (A3 43%, B1 49%, B2 63%: 4.4 to 6.2).
LOW_HEAVY = {"LibLow": 5.5, "LibLowLong": 5.5}
BY_TOP = ("LibFlick", "LibRustle")   # round 2: a tell's takes are matched by their tops, since a tick is read by its top
NOTES = {"round2": " **Round 2:** no layer of ours in any cue, re-cut on Faber's measures of round 1. Its lists are the "
                   "first batch's: the second isn't on disk yet, so the heavy body is one recording until it is."}
LEVEL_WORDS = {
    "round1": "LightHit's own level is where the hottest single cue's top, its layers' tops together, stands at -4 dBFS: "
              "a decibel for the true peak, and the bus limiter's 3 for an overlap.",
    "round2": "LightHit's own level is where round 2's draft measured (-43.4), the engine's Trim now counted in the "
              "estimate: the level isn't chased, since the listen is matched to today's cue. A tell's Volume is set by "
              "its top, 2 dB under the lowest top of its swipe.",
}


# --- the takes' numbers ------------------------------------------------------------------------------------------------

def batch():
    """Every measured pick of the batch, by its id: the raw row and the ranker's reading of it."""
    picks = {}
    for f in sorted(rank.FOLDER.glob("*.json")):
        if f.stem not in rank.ROLES:
            continue
        for raw in json.loads(f.read_text(encoding="utf-8"))["Picks"]:
            if "Error" not in raw and raw["Id"] not in picks:
                picks[raw["Id"]] = (raw, rank.pick(raw))
    return picks


def energy(env, a, b):
    """The envelope's energy from a to b, ms after the slice's start, as the loudest-400-ms measure counts it, dB."""
    i, j = (max(int(round((t + rank.BEFORE_MS) / rank.ENV_MS)), 0) for t in (a, b))
    part = 10 ** (np.asarray(env[i:j], dtype=float) / 10)
    return 10 * np.log10(max(part.sum() * rank.ENV_MS / 400.0, 1e-30))


def bands(p):
    """A take's third-octave powers, summing to 1."""
    a = 10 ** (np.asarray(p["avg"], dtype=float) / 10)
    return a / max(a.sum(), 1e-30)


def library(spec, picks):
    """One library take's recipe and numbers."""
    ident, how, after, out = spec
    how, pre = how if isinstance(how, tuple) else (how, PRE)
    raw, p = picks[ident]
    assert p["licensed"] and ident not in rank.NOT_THE_SOUND, ident
    env = np.asarray(p["env"], dtype=float)
    top = float(np.argmax(env)) * rank.ENV_MS - rank.BEFORE_MS            # ms after the batch's slice start
    start, rise = rank.onset(p)
    first = start - pre if how == "onset" else top - how
    first = max(first, -p["start"] * 1000)                                # never before its file's start
    assert first >= -rank.BEFORE_MS, (ident, first)
    last = top + after
    assert last <= len(env) * rank.ENV_MS - rank.BEFORE_MS, (ident, "past the window")
    # the time to its top: a hit's is its sample's own top when that lies in its rise; else the envelope's step's
    # middle (a rustle's loudest moment is its envelope's, whatever one sample does)
    at = raw["SamplePeakAt"] * 1000
    in_rise = start <= at <= top + 4 if how == "onset" else abs(at - top) <= 4
    peak = at if in_rise else top + rank.ENV_MS / 2
    inside = first <= at <= last
    whole = energy(env, 0.0, (p["stop"] - p["start"]) * 1000)
    kept = energy(env, first, last)
    edge = env[max(int((first + rank.BEFORE_MS) / rank.ENV_MS), 0)] - env.max()
    return {
        "Id": ident, "Title": p["title"], "Creator": p["creator"],
        "From": round(p["start"] + first / 1000, 3), "To": round(p["start"] + last / 1000, 3),
        "Seconds": round((last - first) / 1000, 3), "Peak": round((peak - first) / 1000, 4),
        "In": IN, "Out": out / 1000,
        "lufs": p["lufs"] + kept - whole,                                   # the trimmed slice's, at its file's level
        # dBFS: the slice's sample peak when the trimmed slice keeps it, else the envelope's top and 10 dB for its crest
        "top": p["peak"] if inside else float(env.max()) + 10.0,
        "under120": p["low120"], "bands": bands(p), "phone": float(rank.phone_loss(p)),
        "rise": rise, "edge": float(edge), "series": rank.series(p),
    }


def ours(name):
    """One of our own lists: each take's numbers from its file, measured as the batch measures."""
    from pedalboard.io import AudioFile

    takes = []
    for n, path in enumerate(sorted(OURS.glob(f"{name}_*.ogg")), 1):
        with AudioFile(str(path)) as f:
            x = f.read(f.frames)[0].astype(np.float64)
            m = rank.measures(x, f.samplerate, path.stem, n)
        p = rank.pick(m)
        takes.append({"Title": path.stem, "Creator": "ours (AR13)", "lufs": p["lufs"], "top": p["peak"],
                      "under120": p["low120"], "bands": bands(p), "phone": float(rank.phone_loss(p)),
                      "Seconds": round(len(x) / f.samplerate, 3), "rise": None, "edge": None, "series": (name, n)})
    assert takes, f"no take of ours for {name} in {OURS}"
    return takes


# --- an arrangement's levels and estimates -------------------------------------------------------------------------------

def db(x):
    return 10 * np.log10(max(x, 1e-30))


def arrange(pilot, name, idea, layers, lists, light):
    """The layers' volumes for the cue's level, and what the batch's numbers say of one play."""
    level = light + OVER[pilot] + SET["over"].get(pilot, 0.0) - (OVER[pilot] if pilot in SET["over"] else 0.0)
    play = TRIM if SET["trim"] else 1.0              # what the engine makes of a Volume; round 1 left it out
    rel = db(sum(10 ** (r / 10) for _, _, _, _, r, strength in layers if not strength and not isinstance(r, tuple)))
    out, power, tops, low, raw, phone = [], 0.0, 0.0, 0.0, 0.0, 0.0
    top_of = {}                                      # a list's lowest top in this cue, dBFS

    def top(t, volume):
        return t["top"] + 20 * np.log10(play * volume * t.get("Gain", 1.0))
    for pinned in (False, True):
        for takes, role, at, lead, r, strength in layers:
            if isinstance(r, tuple) != pinned:
                continue
            ts = lists[takes]["takes"]
            got = lists[takes]["level"]              # the list's level at a player's volume of 1 (its takes' gains applied)
            if pinned:                               # its highest top `r[2]` dB under the named list's lowest
                volume = 10 ** ((top_of[r[1]] - r[2] - max(top(t, 1.0) for t in ts)) / 20)
                want = got + 20 * np.log10(play * volume)
            else:
                want = level + r - rel               # this layer's level, LUFS, so the levelled layers sum to the cue's
                volume = 10 ** ((want - got) / 20) / play
            out.append((layers.index((takes, role, at, lead, r, strength)),
                        {"Takes": takes, "Role": role, "At": at, "Lead": lead, "Volume": round(volume, 3),
                         "Strength": strength, "level": want}))
            for t in ts:
                assert not SET["trim"] or t.get("Gain", 1.0) <= GAIN_CAP, (name, takes, t["Title"], "its Gain is over 3")
                assert TRIM * volume * t.get("Gain", 1.0) <= CAP, (name, takes, t["Title"], "over the player's most volume")
            if strength:
                continue
            top_of[takes] = min(top(t, volume) for t in ts)
            e = 10 ** (want / 10)
            power += e
            if at == 0 or not SET["trim"]:           # round 2: a tell 200 ms early never meets the moment's tops
                tops += max(10 ** (top(t, volume) / 20) for t in ts)
            if SET["trim"]:                          # round 2: the share under 120 Hz is of raw energy, not of loudness
                w = LOW_HEAVY.get(takes, 1.0)
                low += e * w * float(np.mean([t["under120"] for t in ts]))
                raw += e * w
            else:                                    # round 1's way, kept so its files stay as Faber measured them
                low += e * float(np.mean([t["under120"] for t in ts]))
                raw += e
            phone += e * float(np.mean([10 ** (-t["phone"] / 10) for t in ts]))
    return {"Name": name, "Pilot": pilot, "Idea": idea, "Layers": [la for _, la in sorted(out, key=lambda x: x[0])],
            "est": {"lufs": db(power), "top": 20 * np.log10(tops), "under120": low / raw, "phone": db(power) + db(phone / power)}}


def measured():
    """What Faber's mixdown of round 1 measured of a recording played alone: its loss through the phone's curve, LU,
    and its share under 120 Hz. By (list, id), and by id alone for a recording that moves to another list."""
    if not MEASURED.exists():
        return {}
    out = {}
    for name, group in json.loads(MEASURED.read_text(encoding="utf-8"))["Takes"].items():
        for ident, _gain, _momentary, short, phone, _peak, _at, under120, *_ in group["Rows"]:
            facts = {"phone": float(short - phone), "under120": float(under120)}
            out[(name, ident)] = facts
            out.setdefault(ident, facts)
    return out


def build():
    picks = batch()
    lists = {}
    heard = measured() if SET["trim"] else {}
    for name, specs in SET["takes"].items():
        takes = [library(s, picks) for s in specs]
        assert len({t["series"] for t in takes}) == len(takes), (name, "two takes of one series")
        for t in takes:                              # round 2: what the mixdown measured of this recording, over the estimate
            t.update(heard.get((name, t["Id"]), heard.get(t["Id"], {})))
        mid = float(np.median([t["lufs"] for t in takes]))
        if SET["trim"] and name in BY_TOP:
            top = float(np.median([t["top"] for t in takes]))
            for t in takes:
                t["Gain"] = round(10 ** ((top - t["top"]) / 20), 3)
            mid = float(np.median([t["lufs"] + 20 * np.log10(t["Gain"]) for t in takes]))
        else:
            for t in takes:
                t["Gain"] = round(10 ** ((mid - t["lufs"]) / 20), 3)
        lists[name] = {"takes": takes, "level": mid, "library": True}
    for name in OUR_TAKES:
        takes = ours(name)
        lists[name] = {"takes": takes, "level": float(np.median([t["lufs"] for t in takes])), "library": False}
    def all_at(light):
        return [arrange(pilot, *a, lists, light) for pilot, group in SET["cues"].items() for a in group]

    if SET["light"] is not None:
        return lists, all_at(SET["light"]), SET["light"]
    # tops move with the level, one for one: solve LightHit's from the hottest cue's top at a trial level
    hot = max(10 ** (c["est"]["top"] / 20) for c in all_at(-36.0))
    light = -36.0 + 20 * np.log10(ROOM / hot)
    return lists, all_at(round(float(light), 1)), round(float(light), 1)


# --- writing ----------------------------------------------------------------------------------------------------------

def luau(lists, cues):
    """The recipes as Config.Cues writes them. Gain is the new field: a library take's own level."""
    lines = [f"-- AR39, {ROUND}: Modulo's arrangements (tools/audio/ar39_arrange.py). Seeds, unheard. Gain is new: a library",
             "-- take's own level inside its list, times its layer's Volume. Our lists stay as Config.Cues has them.",
             "Takes = {"]
    for name, group in lists.items():
        if not group["library"]:
            continue
        lines.append(f"\t{name} = {{")
        for t in group["takes"]:
            lines.append(f"\t\t{{ Id = {t['Id']}, Seconds = {t['Seconds']}, Peak = {t['Peak']}, From = {t['From']}, "
                         f"To = {t['To']}, In = {t['In']}, Out = {t['Out']}, Gain = {t['Gain']} }}, "
                         f"-- {t['Title']}, {t['Creator']}")
        lines.append("\t},")
    lines += ["},", "Cues = {"]
    for c in cues:
        lines.append(f"\t-- {c['Idea']}.")
        lines.append(f"\t{c['Name']} = {{ Layers = {{")
        for la in c["Layers"]:
            lead = f', Lead = "{la["Lead"]}"' if la["Lead"] else ""
            strength = ", Strength = true" if la["Strength"] else ""
            lines.append(f"\t\t{{ Takes = \"{la['Takes']}\", At = {la['At']}{lead}, Volume = {la['Volume']}{strength} }}, "
                         f"-- {la['Role']}")
        lines.append("\t} },")
    lines.append("},")
    return "\n".join(lines) + "\n"


def markdown(lists, cues, light):
    lines = [f"# AR39, {ROUND}: the three pilots' arrangements", "",
             "Made by `tools/audio/ar39_arrange.py` from the first batch's numbers. Nothing was heard: whether one "
             "convinces stays UNVERIFIED. Every level is a seed, and every number under 'estimated' is worked from the "
             "batch's measures of each take, never measured on a mix: the gates are Faber's mixdown's."
             + NOTES.get(ROUND, ""), "",
             f"**The levels:** LightHit at {light:.1f} LUFS (the loudest 400 ms of one play at full volume), HeavyHit "
             f"{SET['over'].get('HeavyHit', OVER['HeavyHit']):+.1f} LU, ShadeSwipe "
             f"{SET['over'].get('ShadeSwipe', OVER['ShadeSwipe']):+.1f} LU: gate 4's relation sets them. "
             + LEVEL_WORDS[ROUND], "",
             "## The arrangements", ""]
    for c in cues:
        e = c["est"]
        lines += [f"### {c['Name']}", "", f"{c['Idea'][0].upper()}{c['Idea'][1:]}.", "",
                  "| Layer | Role | Takes | At, s | Lead | Volume | Level, LUFS |", "|---|---|---|---|---|---|---|"]
        for la in c["Layers"]:
            lines.append(f"| {la['Takes']} | {la['Role']}{' (by strength)' if la['Strength'] else ''} | "
                         f"{len(lists[la['Takes']]['takes'])} | {la['At']} | {la['Lead'] or ''} | {la['Volume']} | "
                         f"{la['level']:.1f} |")
        lines += ["", f"Estimated, one play at full volume, its strength layer left out: {e['lufs']:.1f} LUFS (the loudest "
                  f"400 ms); its top at most {e['top']:.1f} dBFS (its layers' tops together); {e['under120']:.0%} under "
                  f"120 Hz; through the phone's curve {e['phone']:.1f} LUFS.", ""]
    lines += ["## The takes", "",
              "A library take's slice in its file, s; its time to its top; its gain inside its list; its loudness at its "
              "file's level; its top; its rise from its onset; how far under its top its slice starts.", "",
              "| List | Id | Title | Creator | From | To | Peak, ms | Out, ms | Gain | LUFS | Top, dBFS | Rise, ms | Start, dB |",
              "|" + "---|" * 13]
    for name, group in lists.items():
        for t in group["takes"]:
            if group["library"]:
                lines.append(f"| {name} | {t['Id']} | {t['Title']} | {t['Creator']} | {t['From']:.3f} | {t['To']:.3f} | "
                             f"{t['Peak'] * 1000:.0f} | {t['Out'] * 1000:.0f} | {t['Gain']} | {t['lufs']:.1f} | "
                             f"{t['top']:.1f} | {rank.fmt(t['rise'], '.0f')} | {t['edge']:.0f} |")
            else:
                lines.append(f"| {name} | ours | {t['Title']} | {t['Creator']} | whole | | | | | {t['lufs']:.1f} | "
                             f"{t['top']:.1f} | | |")
    return "\n".join(lines) + "\n"


def main():
    global ROUND, SET
    ROUND = sys.argv[1] if len(sys.argv) > 1 else "round1"
    SET = SETUPS[ROUND]
    lists, cues, light = build()
    used = {la["Takes"] for c in cues for la in c["Layers"]}
    lists = {k: v for k, v in lists.items() if k in used}        # a round's files hold only the lists it plays
    OUT.mkdir(parents=True, exist_ok=True)

    def plain(v):
        if isinstance(v, np.ndarray):
            return [round(float(x), 5) for x in v]
        if isinstance(v, (np.floating, np.integer)):
            return float(v)
        return str(v)
    (OUT / f"{ROUND}.json").write_text(json.dumps({"LightHit": light, "Takes": lists, "Cues": cues}, default=plain, indent=1),
                                       encoding="utf-8", newline="\n")
    (OUT / f"{ROUND}.luau").write_text(luau(lists, cues), encoding="utf-8", newline="\n")
    (OUT / f"{ROUND}.md").write_text(markdown(lists, cues, light), encoding="utf-8", newline="\n")
    for c in cues:
        e = c["est"]
        print(f"{c['Name']}: {e['lufs']:.1f} LUFS, top {e['top']:.1f} dBFS, {e['under120']:.0%} under 120 Hz, "
              f"phone {e['phone']:.1f} LUFS; volumes " + ", ".join(str(la["Volume"]) for la in c["Layers"]))
    print(f"wrote {OUT / ROUND}.json, .luau and .md")


if __name__ == "__main__":
    main()
