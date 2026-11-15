"""What every sound script here shares: the sources, the filters, the levelling, the file and its numbers.

Sounds made by us (AGENTS.md, rule 2; the director, 2026-11-15) are synthesised by these scripts on this PC with numpy,
scipy, pedalboard and pyloudnorm, and nothing else. Nobody here can hear them, so every file is read back as written
and measured: its length, its true peak, its loudness, how fast it peaks, where its energy sits, and how alike its
takes are. Only the director's ear accepts one (docs/research/sound.md).

A take is always made from its name and its number, so a script writes the same files every time.

    py tools/audio/<cue>.py            writes that cue's takes into build/handoff/Audio/test6/
    py tools/audio/test6.py            writes all six cues, their numbers (test6.json, test6_numbers.md) and their picture
"""
import json
import struct
import zlib
from pathlib import Path

import numpy as np
import pyloudnorm
from pedalboard.io import AudioFile
from scipy import signal

RATE = 48000
OUT = Path(__file__).resolve().parents[2] / "build" / "handoff" / "Audio" / "test6"
CEILING = -1.5  # dBTP a take is levelled to before it's written; the check is -1 on the file read back
LOW_HZ, HIGH_HZ = 250.0, 2500.0  # the bands' edges, as tools/studio/Audio/Waveform.luau splits them
WEIGHT_HZ = 150.0  # under it a phone's speaker gives nothing


# --- sources ----------------------------------------------------------------------------------------------------------

def rng(name, take):
    return np.random.default_rng(zlib.crc32(f"{name}:{take}".encode()))


def clock(seconds):
    return np.arange(round(seconds * RATE)) / RATE


def noise(seconds, r):
    return r.standard_normal(round(seconds * RATE))


def tone(freq, seconds=None, phase=0.0):
    """A sine. `freq` in Hz: one number, or one per sample for a tone that moves."""
    if np.isscalar(freq):
        return np.sin(2 * np.pi * freq * clock(seconds) + phase)
    return np.sin(2 * np.pi * np.cumsum(freq) / RATE + phase)


def glide(a, b, seconds, curve=1.0):
    """From a to b over the time, in pitch (so equal steps sound equal). `curve` over 1 leaves late, under 1 early."""
    u = np.linspace(0, 1, round(seconds * RATE)) ** curve
    return a * (b / a) ** u


def decay(seconds, t60, attack=0.001):
    """An envelope: up in `attack`, then falling 60 dB every `t60`."""
    t = clock(seconds)
    return np.minimum(t / attack, 1.0) * 10 ** (-3 * np.maximum(t - attack, 0) / t60)


def swell(seconds, peak, sharp=1.5, floor=0.02):
    """An envelope that rises to its top at `peak` seconds and falls to the end. It starts at `floor`, never from
    nothing, so a rising sound has no silent head."""
    t = clock(seconds)
    up = floor + (1 - floor) * np.sin(np.clip(t / peak, 0, 1) * np.pi / 2) ** (2 * sharp)
    down = np.cos(np.clip((t - peak) / max(seconds - peak, 1e-6), 0, 1) * np.pi / 2) ** (2 * sharp)
    return np.where(t < peak, up, down)


def spark(r, partials, seconds, t60, click=(2500.0, 9000.0), click_gain=0.7):
    """A spark's tick: a click of filtered noise a few milliseconds long, and a short ring of a few partials.
    `partials` are (Hz, gain, how long it rings against `t60`) each. The Shade's hurt, the light hit and the burst's
    ticks are this one family in three registers."""
    ring = sum(g * tone(f, seconds, r.uniform(0, 2 * np.pi)) * decay(seconds, t60 * d, 0.0008) for f, g, d in partials)
    snap = band(noise(seconds, r) * decay(seconds, 0.012, 0.0003), *click)
    return ring / max(np.abs(ring).max(), 1e-9) + click_gain * snap / max(np.abs(snap).max(), 1e-9)


def at(total, pieces):
    """Lays pieces on one line: (seconds from the start, samples, gain) each, summed."""
    out = np.zeros(round(total * RATE))
    for when, x, gain in pieces:
        i = round(when * RATE)
        x = x[:max(len(out) - i, 0)]
        out[i:i + len(x)] += x * gain
    return out


# --- filters ----------------------------------------------------------------------------------------------------------

def band(x, low=None, high=None, order=2):
    """Keeps what's between `low` and `high` Hz (either may be left out). Causal, so nothing rings before a hit."""
    if low and high:
        sos = signal.butter(order, (low, high), "bandpass", fs=RATE, output="sos")
    elif low:
        sos = signal.butter(order, low, "highpass", fs=RATE, output="sos")
    else:
        sos = signal.butter(order, high, "lowpass", fs=RATE, output="sos")
    return signal.sosfilt(sos, x)


def moving_band(x, freq, q):
    """A band-pass whose middle moves: `freq` in Hz, one per sample. A state-variable filter, a sample at a time."""
    f = 2 * np.sin(np.pi * np.minimum(freq, RATE / 6.5) / RATE)
    damp = 1.0 / q
    low = mid = 0.0
    out = np.empty(len(x))
    for i, (sample, fi) in enumerate(zip(x.tolist(), f.tolist())):
        low += fi * mid
        mid += fi * (sample - low - damp * mid)
        out[i] = mid
    return out


def drive(x, amount):
    """Soft saturation: the harmonics a small speaker can play. The level it comes back at is its own."""
    return np.tanh(x * amount) / np.tanh(amount)


def ends(x, head=0.0005, tail=0.004):
    """A fade at both ends, so a file never starts or stops on a click it didn't mean."""
    x = x.copy()
    a, b = max(round(head * RATE), 1), max(round(tail * RATE), 1)
    x[:a] *= np.linspace(0, 1, a)
    x[-b:] *= np.linspace(1, 0, b)
    return x


# --- measures ---------------------------------------------------------------------------------------------------------

def db(v):
    return 20 * np.log10(max(float(v), 1e-9))


def true_peak(x):
    """The peak between the samples too, read at four times the rate, in dBTP."""
    return db(np.abs(signal.resample_poly(np.concatenate([np.zeros(64), x, np.zeros(64)]), 4, 1)).max())


def loudness(x):
    """The loudest 0.4 s, K-weighted: the momentary loudness's maximum, in LUFS. A short sound is one window."""
    meter = pyloudnorm.Meter(RATE, block_size=0.4)
    n, hop = round(0.4 * RATE), round(0.05 * RATE)
    x = np.concatenate([x, np.zeros(max(n - len(x), 0))])
    return max(float(meter.integrated_loudness(x[i:i + n])) for i in range(0, len(x) - n + 1, hop))


def envelope(x, window=0.002):
    n = max(round(window * RATE), 1)
    return np.sqrt(np.convolve(x * x, np.ones(n) / n, "same"))


def spectrum(x):
    power = np.abs(np.fft.rfft(x * np.hanning(len(x)), max(len(x), 8192))) ** 2
    return np.fft.rfftfreq(max(len(x), 8192), 1 / RATE), power


def third_octaves(x):
    """Energy in third-octave bands from 50 Hz to 16 kHz, in dB: a sound's colour as a short list."""
    freqs, power = spectrum(x)
    edges = 50 * 2 ** (np.arange(0, 26) / 3)
    return np.array([10 * np.log10(power[(freqs >= a) & (freqs < b)].sum() + 1e-12) for a, b in zip(edges, edges[1:])])


def share(x, low=0.0, high=RATE):
    """The share of a sound's energy between two frequencies."""
    freqs, power = spectrum(x)
    return float(power[(freqs >= low) & (freqs < high)].sum() / power.sum())


def numbers(x):
    """A take's numbers, from its samples as the file holds them."""
    freqs, power = spectrum(x)
    total = power.sum()
    env = envelope(x)
    top = np.abs(x).max()
    return dict(
        seconds=round(len(x) / RATE, 3),
        truePeak=round(true_peak(x), 2),
        loudness=round(loudness(x), 1),
        toPeakMs=round(float(np.argmax(env)) / RATE * 1000, 1),
        headMs=round(float(np.argmax(np.abs(x) > top * 10 ** (-40 / 20))) / RATE * 1000, 2),
        low=round(float(power[freqs < LOW_HZ].sum() / total), 3),
        mid=round(float(power[(freqs >= LOW_HZ) & (freqs < HIGH_HZ)].sum() / total), 3),
        high=round(float(power[freqs >= HIGH_HZ].sum() / total), 3),
        above150=round(float(power[freqs >= WEIGHT_HZ].sum() / total), 3),
        centre=round(float((freqs * power).sum() / total)))


def alike(a, b):
    """How alike two takes are, 0 to 1: their colours (third-octave bands) and their shapes (envelopes) together.
    Also how far apart their pitch sits, in semitones, by their spectra's middles."""
    ca, cb = third_octaves(a), third_octaves(b)
    keep = (ca > ca.max() - 50) | (cb > cb.max() - 50)
    colour = float(np.corrcoef(ca[keep], cb[keep])[0, 1])
    n = min(len(a), len(b))
    ea, eb = envelope(a[:n], 0.005), envelope(b[:n], 0.005)
    shape = float(np.corrcoef(ea, eb)[0, 1])
    fa, pa = spectrum(a)
    fb, pb = spectrum(b)
    semis = 12 * np.log2((fa * pa).sum() / pa.sum() / ((fb * pb).sum() / pb.sum()))
    return round(max(colour, 0) * max(shape, 0), 3), round(float(semis), 2)


# --- the file ---------------------------------------------------------------------------------------------------------

def levelled(takes):
    """Each take's true peak at the ceiling, then the louder ones brought down to the quietest: a layer's takes
    differ in pitch and shape, never in level."""
    takes = [ends(x) for x in takes]
    takes = [x * 10 ** ((CEILING - true_peak(x)) / 20) for x in takes]
    quiet = min(loudness(x) for x in takes)
    return [x * 10 ** ((quiet - loudness(x)) / 20) for x in takes]


def write(path, x):
    """Writes a take as a 48 kHz mono OGG and returns it read back, the samples the game will play."""
    path.parent.mkdir(parents=True, exist_ok=True)
    gain = 1.0
    for _ in range(6):
        with AudioFile(str(path), "w", samplerate=RATE, num_channels=1, quality="192 kbps") as f:
            f.write((x * gain).astype(np.float32)[None])
        with AudioFile(str(path)) as f:
            back = f.read(f.frames)[0].astype(np.float64)
        if true_peak(back) <= -1.0:
            return back
        gain *= 10 ** (-0.5 / 20)  # the encoder can lift a peak: half a decibel down and again
    raise SystemExit(f"{path.name}: its true peak stays over -1 dBTP")


def layer(cue, name, takes, weight=(WEIGHT_HZ, 0.5), **facts):
    """Writes a layer's takes, measures the files, checks them, and returns the layer's record. `weight` is the
    check that a phone plays it: the least share of its energy above a frequency."""
    made = [write(OUT / f"{name}_{i + 1}.ogg", x) for i, x in enumerate(levelled(takes))]
    rows = [dict(file=f"{name}_{i + 1}.ogg", **numbers(x)) for i, x in enumerate(made)]
    pairs = [dict(takes=[i + 1, j + 1], alike=alike(made[i], made[j])[0], semitones=alike(made[i], made[j])[1])
             for i in range(len(made)) for j in range(i + 1, len(made))]
    checks = dict(
        truePeak=all(r["truePeak"] <= -1.0 for r in rows),
        head=all(r["headMs"] <= 5.0 for r in rows),
        takesDiffer=all(p["alike"] < 0.97 or abs(p["semitones"]) >= 0.5 for p in pairs),
        weight=all(share(x, weight[0]) >= weight[1] for x in made))
    record = dict(cue=cue, layer=name, takes=rows, pairs=pairs, checks=checks,
                  weightCheck=f"at least {weight[1]:.0%} of its energy above {weight[0]:g} Hz", **facts)
    print(f"{name}: {len(rows)} takes, " + ", ".join(f"{k} {'ok' if v else 'FAILS'}" for k, v in checks.items()))
    record["samples"] = made
    return record


# --- the sheet --------------------------------------------------------------------------------------------------------

def sheet(records):
    """The numbers for every layer written: test6.json for the build, test6_numbers.md to read."""
    data = dict(
        note="AR13, the sound test: Modulo's layers, made by script (tools/audio/). 48 kHz mono OGG. Every number is "
             "measured on the file read back. truePeak in dBTP; loudness is the loudest 0.4 s, K-weighted, in LUFS; "
             "toPeakMs is where the envelope tops; headMs is the time before the sound is within 40 dB of its peak; "
             "low, mid and high are energy shares split at 250 and 2,500 Hz; above150 is the share a phone can play; "
             "centre is the spectrum's middle in Hz. A pair's `alike` is 0 to 1 (colour times shape), `semitones` how "
             "far apart the two takes' middles sit.",
        layers=[{k: v for k, v in r.items() if k != "samples"} for r in records])
    (OUT / "test6.json").write_text(json.dumps(data, indent=1), encoding="utf-8", newline="\n")
    lines = ["# AR13, the sound test: the layers' numbers", "",
             "Made by `tools/audio/`, measured on each file read back. Nobody has heard them: the director's ear decides.", "",
             "| File | Length, s | True peak, dBTP | Loudness, LUFS | To peak, ms | Head, ms | Low | Mid | High | Above 150 Hz | Middle, Hz |",
             "|---|---|---|---|---|---|---|---|---|---|---|"]
    for r in records:
        for t in r["takes"]:
            lines.append(f"| `{t['file']}` | {t['seconds']} | {t['truePeak']} | {t['loudness']} | {t['toPeakMs']} | "
                         f"{t['headMs']} | {t['low']:.0%} | {t['mid']:.0%} | {t['high']:.0%} | {t['above150']:.0%} | "
                         f"{t['centre']} |")
    lines += ["", "## How alike the takes are, and the checks", "",
              "| Layer | Pairs: alike (0 to 1), semitones apart | True peak | Head | Takes differ | Weight above 150 Hz |",
              "|---|---|---|---|---|---|"]
    for r in records:
        pairs = "; ".join(f"{p['takes'][0]}-{p['takes'][1]}: {p['alike']}, {p['semitones']:+}" for p in r["pairs"])
        c = r["checks"]
        lines.append(f"| `{r['layer']}` | {pairs} | " + " | ".join(
            "pass" if c[k] else "FAILS" for k in ("truePeak", "head", "takesDiffer", "weight")) + " |")
    lines += ["", "`test6_layers.png` shows each layer's first take, a wave over its spectrum through time (50 Hz at the "
              "foot to 20 kHz, 60 dB deep, 600 pixels a second). Rows, top to bottom: "
              + ", ".join(r["layer"] for r in records) + "."]
    (OUT / "test6_numbers.md").write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    print(f"wrote {OUT / 'test6.json'} and test6_numbers.md: {len(records)} layers")


def picture(records, path):
    """Each layer's first take as a picture: its wave over its spectrum through time (50 Hz to 20 kHz, 60 dB deep).
    One row a layer, 600 pixels a second, so shapes compare by eye. A grey PNG, written by hand."""
    rows, wide = [], max(round(len(r["samples"][0]) / RATE * 600) for r in records) + 8
    for r in records:
        x = r["samples"][0]
        f, t, s = signal.spectrogram(x, RATE, nperseg=1024, noverlap=1024 - 80, nfft=4096)
        want = 50 * (20000 / 50) ** np.linspace(1, 0, 96)
        img = 10 * np.log10(s[np.searchsorted(f, want).clip(0, len(f) - 1)] + 1e-14)
        img = np.clip((img - img.max()) / 60 + 1, 0, 1)
        wave = np.zeros((40, img.shape[1]))
        peaks = np.abs(x[:img.shape[1] * 80].reshape(-1, 80)).max(axis=1) if len(x) >= 80 else np.zeros(1)
        peaks = peaks / max(peaks.max(), 1e-9)
        for i, p in enumerate(peaks[:img.shape[1]]):
            wave[20 - round(p * 19):20 + round(p * 19) + 1, i] = 0.85
        block = np.vstack([wave, np.full((2, img.shape[1]), 0.3), img])
        rows.append(np.hstack([block, np.zeros((block.shape[0], wide - block.shape[1]))]))
        rows.append(np.full((6, wide), 0.3))
    px = (np.vstack(rows) * 255).astype(np.uint8)
    raw = b"".join(b"\x00" + row.tobytes() for row in px)

    def chunk(kind, body):
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body))
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", px.shape[1], px.shape[0], 8, 0, 0, 0, 0))
                     + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))
    print(f"wrote {path}: {px.shape[1]}x{px.shape[0]}, rows top to bottom: " + ", ".join(r["layer"] for r in records))
