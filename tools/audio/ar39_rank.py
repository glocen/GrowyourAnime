"""AR39, the sound rescue: the shortlist batch's picks ranked and pre-screened, from the files Faber's batch writes.

The batch (AR39, "The briefs, and the first batch") runs `Shortlist.Run` on each brief in Studio and writes
build/scratch/modulo/ar39/<brief>.json: each pick's fields and its measures over its slice, never audio. This reads
those numbers and nothing else; nobody here hears a sound, so whether one convinces stays UNVERIFIED.

What it does, per brief:
- **Pre-screens each pick** on the gates one take can show alone (AR39, "The technical gates"). The gates themselves
  are measured later on Faber's mixdown of the cue at its game gains; this only keeps a pick that would fail one from
  reaching an arrangement.
  - contact (2): a hit's envelope tops within 10 ms after the slice's start (a swipe's top is placed on its beat by
    its arrangement, so its time is shown, not screened);
  - harshness (7): no third-octave band between 2 and 6 kHz 10 dB or more over its two neighbours' mean;
  - weight (5): the share under 120 Hz, at most half for a HeavyHit body; the loss through the phone's curve, estimated
    from the third-octave spectrum (the bands under 200 Hz and over 8 kHz taken away);
  - cuts (6): the largest step in the slice's first and last 3 ms, over 0.25 marked: its fades must cover it.
- **Variation (8):** two picks of one asset are one recording; one creator's titles that differ only in their numbers
  are marked as one series; the averaged spectra's cosine similarity (on magnitudes, 10^(dB/20)) is 0.97 or more for
  a pair too alike.
- **Ranks** the screened picks by the shortlist's own score (the brief's match, licensed first), then takes a varied
  set greedily: the best, then each next whose recording, series and spectrum differ from every one taken.

Writes rank.md and rank.png beside the files: the tables, and each varied set's envelope (dB, 2 ms a column) over its
spectrogram (third octaves, 10 ms a column), in the table's order.

    py tools/audio/ar39_rank.py [folder]     the batch's folder, build/scratch/modulo/ar39/ by default
    py tools/audio/ar39_rank.py --selftest   a batch made from our own AR13 takes (build/handoff/Audio/test6/),
                                             measured as the batch measures, then ranked: the tool proven on files

A pick's keys are read as the batch writes them, any case. Each measure's accepted names are in KEYS: one more name
there is all a different batch needs.
"""
import json
import re
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))

REPO = Path(__file__).resolve().parents[2]
FOLDER = REPO / "build" / "scratch" / "modulo" / "ar39"
ROLES = {"LightHitBody": "LightHit", "LightHitSnap": "LightHit", "HeavyHitBody": "HeavyHit",
         "ShadeTellPaper": "ShadeSwipe", "ShadeSwipeAir": "ShadeSwipe"}
BEFORE_MS, ENV_MS, FRAME_MS = 20.0, 2.0, 10.0   # the envelope starts 20 ms before the slice, 2 ms a value
CENTRES = 50 * 2 ** (np.arange(25) / 3)         # third octaves, 50 Hz to 12.7 kHz
TOO_ALIKE, CONTACT_MS, HARSH_DB, STEP, LOW_MAX = 0.97, 10.0, 10.0, 0.25, 0.5
KEEP = 6                                        # a varied set's size, per brief

KEYS = {
    "id": ("Id", "AssetId"), "title": ("Title", "Name"), "creator": ("Creator", "CreatorName", "Author"),
    "licensed": ("Licensed",), "keyword": ("Keyword",), "start": ("From", "Start"), "stop": ("To", "Stop"),
    "score": ("Score",), "env": ("Envelope", "Env"), "spec": ("Spectrogram", "Spec"),
    "avg": ("Spectrum", "Average", "Bands", "ThirdOctaves"), "low120": ("Under120", "Low120", "ShareUnder120"),
    "lufs": ("Loudness", "LUFS"), "peak": ("SamplePeak", "PeakDb"), "peakAt": ("SamplePeakAt", "PeakAt", "PeakTime"),
    "stepIn": ("StepIn", "EdgeIn", "FirstStep"), "stepOut": ("StepOut", "EdgeOut", "LastStep"),
}


# --- reading the batch -------------------------------------------------------------------------------------------------

def flat(d, into=None):
    """A pick's keys, nested tables opened one level, all lower case."""
    into = {} if into is None else into
    for k, v in d.items():
        if isinstance(v, dict) and k.lower() in ("measures", "measure", "slice", "fields"):
            flat(v, into)
        else:
            into[k.lower()] = v
    return into


def pick(raw):
    d = flat(raw)
    out = {}
    for name, names in KEYS.items():
        out[name] = next((d[n.lower()] for n in names if n.lower() in d), None)
    return out


def read(path):
    data = json.loads(path.read_text(encoding="utf-8"))
    rows = data if isinstance(data, list) else next(
        (v for k, v in data.items() if k.lower() in ("picks", "results", "hits")), [])
    return [pick(r) for r in rows]


# --- the pre-screen ----------------------------------------------------------------------------------------------------

def peak_ms(p):
    """Where the envelope tops, in ms after the slice's start."""
    env = np.asarray(p["env"], dtype=float)
    return float(np.argmax(env)) * ENV_MS - BEFORE_MS


def harsh(p):
    """The most any band between 2 and 6 kHz stands over its two neighbours' mean, in dB."""
    a = np.asarray(p["avg"], dtype=float)
    idx = [i for i in range(1, len(a) - 1) if 2000 <= CENTRES[i] <= 6000]
    return max((a[i] - (a[i - 1] + a[i + 1]) / 2 for i in idx), default=0.0)


def phone_loss(p):
    """What the phone's curve takes, in dB, estimated from the third octaves: the bands under 200 Hz and over 8 kHz
    taken away. An estimate from bands, not the filter's own slope."""
    a = 10 ** (np.asarray(p["avg"], dtype=float) / 10)
    keep = (CENTRES[:len(a)] >= 200) & (CENTRES[:len(a)] <= 8000)
    return 10 * np.log10(a.sum() / max(a[keep].sum(), 1e-30))


def screen(p, role):
    """The pre-screen's misses, as words; empty when it passes."""
    miss = []
    # a hit's top lands on its contact, the slice's start; a swipe's top is placed on its beat by its arrangement
    if role != "ShadeSwipe" and p["env"] is not None and not -2.0 <= peak_ms(p) <= CONTACT_MS:
        miss.append(f"peak {peak_ms(p):+.0f} ms")
    if p["avg"] is not None and harsh(p) >= HARSH_DB:
        miss.append(f"harsh {harsh(p):.0f} dB")
    if role == "HeavyHit" and p["low120"] is not None and p["low120"] > LOW_MAX:
        miss.append(f"{p['low120']:.0%} under 120 Hz")
    return miss


def series(p):
    """One creator's titles that differ only in their numbers are one series."""
    return (str(p["creator"]).lower(), re.sub(r"[\d#_\-\s]+", " ", str(p["title"]).lower()).strip())


def alike(p, q):
    a, b = (10 ** (np.asarray(x["avg"], dtype=float) / 20) for x in (p, q))
    n = min(len(a), len(b))
    return float(a[:n] @ b[:n] / max(np.linalg.norm(a[:n]) * np.linalg.norm(b[:n]), 1e-30))


def varied(ranked):
    """The best, then each next whose recording, series and spectrum differ from every one taken."""
    taken = []
    for p in ranked:
        if len(taken) == KEEP:
            break
        if all(p["id"] != q["id"] and series(p) != series(q) and alike(p, q) < TOO_ALIKE for q in taken):
            taken.append(p)
    return taken


# --- writing ----------------------------------------------------------------------------------------------------------

def fmt(v, f):
    return "" if v is None else format(v, f)


def table(brief, picks):
    role = ROLES.get(brief, "?")
    passed = [p for p in picks if not p["miss"]]
    ranked = sorted(passed, key=lambda p: -(p["score"] or 0))
    chosen = varied(ranked)
    lines = [f"## {brief} (for {role}): {len(picks)} picks, {len(passed)} through the pre-screen, {len(chosen)} varied", "",
             "| Set | Id | Title | Creator | Licensed | Score | Peak at, ms | LUFS | Under 120 Hz | Phone loss, dB | "
             "Harsh, dB | Steps in/out | Pre-screen |",
             "|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
    order = chosen + [p for p in ranked if p not in chosen] + [p for p in picks if p["miss"]]
    for p in order:
        mark = str(chosen.index(p) + 1) if p in chosen else ""
        steps = "" if p["stepIn"] is None else f"{p['stepIn']:.2f}/{p['stepOut']:.2f}"
        steps += " (fade)" if p["stepIn"] is not None and max(p["stepIn"], p["stepOut"]) > STEP else ""
        at = "" if p["env"] is None else format(peak_ms(p), "+.0f")
        low = fmt(p["low120"], ".0%")
        loss = "" if p["avg"] is None else format(phone_loss(p), ".1f")
        sharp = "" if p["avg"] is None else format(harsh(p), ".1f")
        lines.append(
            f"| {mark} | {p['id']} | {p['title']} | {p['creator']} | {'yes' if p['licensed'] else 'no'} | "
            f"{fmt(p['score'], '.2f')} | {at} | {fmt(p['lufs'], '.1f')} | {low} | {loss} | {sharp} | {steps} | "
            f"{'; '.join(p['miss']) or 'passes'} |")
    pairs = [(i + 1, j + 1, alike(a, b)) for i, a in enumerate(chosen) for j, b in enumerate(chosen) if j > i]
    if pairs:
        lines += ["", "The varied set's pairs, cosine similarity of the averaged spectra (under 0.97 each): "
                  + ", ".join(f"{i}-{j} {s:.3f}" for i, j, s in pairs) + "."]
    return lines + [""], chosen


def png(path, px):
    import struct
    import zlib

    raw = b"".join(b"\x00" + row.tobytes() for row in px)

    def chunk(kind, body):
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body))
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", px.shape[1], px.shape[0], 8, 0, 0, 0, 0))
                     + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def picture(sets, path):
    """Each varied set, one row a pick: its envelope (60 dB deep) over its spectrogram (50 Hz at the foot, 60 dB
    deep, 4 pixels a band), both one pixel a millisecond from 20 ms before the slice. Briefs apart by a lighter bar."""
    rows, wide = [], 0
    for brief, chosen in sets:
        for p in chosen:
            env = np.asarray(p["env"] or [-90], dtype=float)
            env = np.clip((env - env.max()) / 60 + 1, 0, 1)
            px_ms = 1                                     # both strips one pixel a millisecond, so they line up
            step = round(ENV_MS * px_ms)
            e = np.zeros((40, len(env) * step))
            for i, v in enumerate(env):
                e[40 - max(round(v * 38), 1):, i * step:(i + 1) * step] = 0.85
            spec = np.asarray(p["spec"] or [[-90]], dtype=float)
            s = np.clip((spec - spec.max()) / 60 + 1, 0, 1).T[::-1]
            s = np.repeat(np.repeat(s, 4, axis=0), round(FRAME_MS * px_ms), axis=1)
            w = max(e.shape[1], s.shape[1])
            block = np.vstack([np.pad(e, ((0, 0), (0, w - e.shape[1]))), np.full((2, w), 0.3),
                               np.pad(s, ((0, 0), (0, w - s.shape[1])))])
            rows.append(block)
            rows.append(np.full((4, w), 0.15))
            wide = max(wide, w)
        rows.append(np.full((10, max(wide, 1)), 0.5))
    rows = [np.pad(r, ((0, 0), (0, wide - r.shape[1]))) for r in rows]
    png(path, (np.vstack(rows) * 255).astype(np.uint8))


def rank(folder):
    files = sorted(p for p in folder.glob("*.json") if p.stem in ROLES)
    if not files:
        raise SystemExit(f"no brief's file in {folder}: expected one of {', '.join(f'{b}.json' for b in ROLES)}")
    lines = ["# AR39: the shortlist batch's picks, ranked and pre-screened", "",
             f"Made by `tools/audio/ar39_rank.py` from {', '.join(f.name for f in files)}. Nothing was heard: whether a "
             "sound convinces stays UNVERIFIED. The pre-screen holds a pick to the gates one take shows alone; the gates "
             "are measured on Faber's mixdown of each cue. A pick's numbers: its envelope's top after the slice's "
             "start; its loudness; its share of energy under 120 Hz; the phone's curve's loss, estimated from its third "
             "octaves; its worst band between 2 and 6 kHz over its neighbours; the largest steps at its ends ('fade': "
             "over 0.25, its fades must cover it). Set: the varied set's order.", ""]
    sets = []
    for f in files:
        picks = read(f)
        for p in picks:
            p["miss"] = screen(p, ROLES[f.stem])
        more, chosen = table(f.stem, picks)
        lines += more
        sets.append((f.stem, chosen))
    (folder / "rank.md").write_text("\n".join(lines), encoding="utf-8", newline="\n")
    picture(sets, folder / "rank.png")
    print(f"wrote {folder / 'rank.md'} and rank.png: " + ", ".join(f"{b} {len(c)}" for b, c in sets))


# --- the self-test: our own takes, measured as the batch measures --------------------------------------------------------

def measures(x, rate, title, n):
    """One pick's measures from its samples, as the batch defines them: the slice runs from the onset (the first
    sample within 40 dB of the peak) to the sound's end, 400 ms at most; the matrices from 20 ms before its start to
    100 ms after its end."""
    import audiokit as ak

    top = np.abs(x).max()
    on = int(np.argmax(np.abs(x) > top * 10 ** (-40 / 20)))
    length = min(len(x) - on, round(0.4 * rate))
    x = np.concatenate([np.zeros(round(0.2 * rate)), x, np.zeros(round(0.2 * rate))])
    on += round(0.2 * rate)
    win = x[on - round(BEFORE_MS / 1000 * rate):on + length + round(0.1 * rate)]
    hop = round(ENV_MS / 1000 * rate)
    env = [20 * np.log10(max(np.sqrt(np.mean(win[i:i + hop] ** 2)), 1e-9)) for i in range(0, len(win) - hop + 1, hop)]
    edges = CENTRES * 2 ** (-1 / 6)
    edges = np.append(edges, CENTRES[-1] * 2 ** (1 / 6))

    def octs(seg):
        power = np.abs(np.fft.rfft(seg * np.hanning(len(seg)), 8192)) ** 2
        f = np.fft.rfftfreq(8192, 1 / rate)
        return [10 * np.log10(power[(f >= a) & (f < b)].sum() + 1e-12) for a, b in zip(edges, edges[1:])]
    frame = round(FRAME_MS / 1000 * rate)
    spec = [octs(win[i:i + frame]) for i in range(0, len(win) - frame + 1, frame)]
    sl = x[on:on + length]
    power = np.abs(np.fft.rfft(sl, 8192)) ** 2
    f = np.fft.rfftfreq(8192, 1 / rate)
    three = round(0.003 * rate)
    return dict(Id=n, Title=title, Creator="Modulo (ours, AR13)", Licensed=False, Keyword="selftest", From=0.0,
                To=round(length / rate, 3), Score=round(1.0 - n * 0.01, 2), Envelope=env, Spectrogram=spec, Spectrum=octs(sl),
                Under120=float(power[f < 120].sum() / power.sum()), Loudness=ak.loudness(sl),
                SamplePeak=20 * np.log10(np.abs(sl).max()), SamplePeakAt=float(np.argmax(np.abs(sl)) / rate),
                StepIn=float(np.abs(np.diff(sl[:three])).max()), StepOut=float(np.abs(np.diff(sl[-three:])).max()))


def selftest():
    from pedalboard.io import AudioFile

    src = REPO / "build" / "handoff" / "Audio" / "test6"
    out = REPO / "build" / "scratch" / "modulo" / "ar39_selftest"
    out.mkdir(parents=True, exist_ok=True)
    # the sparks are one series (one creator, numbered titles); the heavy layers differ (the sub must fail weight)
    groups = {"LightHitBody": "LightHitSpark", "HeavyHitBody": "Heavy", "ShadeSwipeAir": "ShadeSwipe"}
    for brief, stem in groups.items():
        picks = []
        for n, path in enumerate(sorted(src.glob(f"{stem}*.ogg")), 1):
            with AudioFile(str(path)) as f:
                x, rate = f.read(f.frames)[0].astype(np.float64), f.samplerate
            picks.append(measures(x, rate, path.stem, n))
        # one pick twice, the second as a different slice of the same asset: the variation check must drop it
        if picks:
            picks.append(dict(picks[0], Title=picks[0]["Title"] + " again", Score=picks[0]["Score"] - 0.005))
        (out / f"{brief}.json").write_text(json.dumps({"Brief": brief, "Picks": picks}), encoding="utf-8")
        print(f"{brief}: {len(picks)} picks from {stem}*.ogg")
    rank(out)


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        selftest()
    else:
        rank(Path(sys.argv[1]) if len(sys.argv) > 1 else FOLDER)
