"""AR52's ward, redrawn after the director's verdict (2026-11-26, 12:57: "the shield vfx is to thicc and looks more like
glass"): new targets on the Guard's stage, for research's pick in pairs beside today's build. Scintilla's.

    py tools/fx/ward_targets.py [stage.json] [out_dir] [W1_rim,W2_frame,W3_ripple]
    (default stage: build/handoff/Shade/stage/stage_guard.json; default out: build/handoff/Shade/targets)
    py tools/fx/ward_targets.py --pictures [out_dir]   (default: build/handoff/Shade/fx/pictures)
    W2's build (research's pick): its strokes as three pictures, ink, light and core, for the Beams of GuardShield
    (tools/fx/shade_tells.py): see pictures().

Why the build read as glass: it was a smooth surface with a deep fill, a Fresnel brightening, a sheen and a bright closed
rim, the cues of a glass lens. The vault the director shared draws its held shapes otherwise
(docs/research/vfx-reference.md, "From the vault"):
- 2yroldmiseorb and DemonAuraVFX hold their shapes with no surface at all: thin flat drawn rings, a gapped circle among
  them, each in two or more overlapping copies that fade 1 > 0 > 1 over their life and turn slowly, so a held shape
  breathes and never sits still;
- DemonAuraVFX's curved beams are tapered strokes, faded to nothing at both ends and solid between, with light running
  along them;
- the flipbook sheets draw a ring as uneven, broken, hand-made arcs, an outline pass apart from a fill pass, and the ring
  dies by breaking into pieces, never by a uniform fade.
So every target here is lines only: thin strokes in the shield's azure with a white core, tapered at their ends, wobbling
a little as a hand draws them, edged by a hair of deep azure so they hold on the pale deck by day. No fill, no Fresnel, no
sheen, no boss. The size stays the Guard's look (Config.Combat.Guard.Look): 3.8 across, 1.6 ahead, 0.4 up.

The beats, the same in all three (Definitions.Actions, GuardRaise: Raise 0.3 s, Drop 2.3 s, so Drop is 120 frames after
Raise):
- the raise: the strokes are drawn on, as a brush draws them, over the 8 frames before Raise;
- the click on Raise: the strokes flash for 5 frames;
- the hold: the strokes turn slowly and their light runs along them;
- the glance: the strokes light round the contact, with AR52's core and five needles (shade_targets.glance_free);
- the drop: the strokes are drawn off over 8 frames from Drop;
- the break: AR52's break, unchanged (research, 01:23: the three breaks read alike, so the pick rests on the shield).

Three hero shapes:
- W1, the rim: the shield's edge as three broken arcs of brush line, the lantern's four ribs as short strokes across it.
- W2, the frame: a paper lantern's frame drawn in light, face on: five bowed ribs from its top to its bottom, its top
  and bottom hoops short strokes, light running up the ribs. The frame is the whole shape; nothing closes it.
- W3, the ripple: at rest only a faint gapped ring, turning; where a blow lands, ripples run out over the unseen surface
  and the lantern's ribs show round the contact, then fade. The shield shows itself where it's hit.
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from paintover import hexc, phone_sheets, strip, write_png  # noqa: E402
from shade_targets import (  # noqa: E402
    AZURE, BREAK, GLANCE, GUARD, UP, Stage, back_out, contact, crop, draw_break, ease_out, glance_free, lead_nearer,
    life, on_plane, region, soft,
)

ROOT = Path(__file__).resolve().parents[2]
STAGE = ROOT / "build" / "handoff" / "Shade" / "stage" / "stage_guard.json"
OUT = ROOT / "build" / "handoff" / "Shade" / "targets"

INK = hexc("#163C8C")  # the hair of deep azure that edges every stroke
WHITE = np.array([1.0, 1.0, 1.0])
R = 1.9  # the ward's radius
DROP = 120  # Drop after Raise, in frames
TAU = 2 * math.pi

STROKE = 0.1  # the rim's width at its thickest, in studs: a third of the build's halo band, still read at a phone
RIB = 0.055  # a rib's
INK_W = 0.025  # the ink's hair beyond a stroke's edge
INK_A = 0.5
TURN = 0.35  # the hold's turn, radians a second


# --- strokes in the shield's plane ---------------------------------------------------------------------------------------
def wobble(theta, seed, amp):
    """A hand's unevenness round a ring: three low harmonics, `amp` studs at most."""
    rng = np.random.default_rng(seed)
    out = np.zeros_like(theta)
    for k in (2, 3, 5):
        out = out + rng.uniform(-1, 1) * np.sin(k * theta + rng.uniform(0, TAU)) / k
    return amp * out


def taper(s):
    """A brush stroke's width along it, s from 0 to 1: nothing at both ends, full between."""
    return np.clip(np.sin(np.pi * np.clip(s, 0, 1)), 0, 1) ** 0.55 * ((s >= 0) & (s <= 1))


def arc_stroke(u, v, radius, a0, span, width, drawn, seed):
    """One arc of brush line from angle a0 over span radians, drawn on to `drawn` of its length: (distance to its
    middle line, its width there, where along it, 0 to 1)."""
    r = np.hypot(u, v)
    th = np.arctan2(v, u)
    rel = (th - a0) % TAU
    s = rel / max(span * max(drawn, 1e-3), 1e-6)
    w = width * taper(s) * (rel <= span * drawn)
    d = np.abs(r - radius - wobble(th, seed, 0.03 * radius))
    return d, w, np.clip(s, 0, 1)


def line_stroke(u, v, a, b, width, bow, seed):
    """A straight brush stroke from a to b (plane coordinates), bowed `bow` studs at its middle."""
    a, b = np.asarray(a, float), np.asarray(b, float)
    ab = b - a
    L = float(np.linalg.norm(ab))
    t = ((u - a[0]) * ab[0] + (v - a[1]) * ab[1]) / (L * L)
    n = np.array([-ab[1], ab[0]]) / L
    off = (u - a[0]) * n[0] + (v - a[1]) * n[1]
    rng = np.random.default_rng(seed)
    curve = bow * 4 * t * (1 - t) + 0.012 * np.sin(t * math.pi * rng.uniform(2, 3) + rng.uniform(0, TAU))
    d = np.abs(off - curve)
    return d, width * taper(t), np.clip(t, 0, 1)


def ink_light(d, w, aa, k, core_k=1.0, halo=0.25):
    """A stroke's three passes: its hair of ink, its azure body, its white core where it's thick."""
    body = soft(d - w / 2, aa) * (w > 1e-4)
    edge = soft(d - w / 2 - INK_W, aa) * (w > 1e-4) * (1 - body)
    core = soft(d - w / 5, aa) * np.clip(w / STROKE * 1.4 - 0.4, 0, 1)
    glow = np.exp(-(d / np.maximum(w * 2.2, 1e-3)) ** 2) * (w > 1e-4) * halo
    return edge, body * k + glow * k, core * k * core_k


# --- the three shapes --------------------------------------------------------------------------------------------------
def beats(f):
    """How much of the strokes is drawn, and their light's multiplier (the click), at frame f from Raise."""
    if f < -8 or f > DROP + 8:
        return 0.0, 0.0
    drawn = ease_out(life(f, -8, -1)) * (1 - life(f, DROP, DROP + 8))
    click = 1 + 1.4 * (1 - life(f, 0, 5)) * float(f >= 0)
    return drawn, click


def near(u, v, c, reach):
    """How near each point is to the contact c, 1 on it, by a Gaussian of `reach` studs."""
    return np.exp(-((u - c[0]) ** 2 + (v - c[1]) ** 2) / reach ** 2)


def rim_ribs(u, v, aa, f, drawn, rib_k):
    """W1's strokes, and W3's: three broken arcs of the rim, then four ribs across."""
    turn = TURN * f / 60
    edges, lights, cores = [], [], []
    for i, (a0, span) in enumerate(((0.35, 1.75), (2.35, 1.95), (4.5, 1.6))):
        d, w, _ = arc_stroke(u, v, R, a0 + turn, span, STROKE, drawn, 11 + i)
        e, l, c = ink_light(d, w, aa, 1.0)
        edges.append(e), lights.append(l), cores.append(c)
    if rib_k is not None:
        for j, h in enumerate((-1.05, -0.38, 0.38, 1.05)):
            half = math.sqrt(R * R - h * h) * 0.8 * drawn
            if half < 0.05:
                continue
            bow = -0.07 * np.sign(h)  # lines of a lantern's face seen from just below: bowed toward its middle
            d, w, _ = line_stroke(u, v, (-half, h), (half, h), RIB, bow, 31 + j)
            e, l, c = ink_light(d, w, aa, 1.0, core_k=0.6)
            edges.append(e * rib_k), lights.append(l * rib_k), cores.append(c * rib_k)
    return edges, lights, cores


def frame_ribs(u, v, aa, f, drawn, run_k=1.0):
    """W2's strokes: a lantern's frame face on, five bowed ribs top to bottom and its two hoops; `run_k` the light running
    up the ribs (0: none, as the build's still passes draw them)."""
    W, H = R * 0.92, R * 1.0 * max(drawn, 1e-3)
    edges, lights, cores = [], [], []
    vv = np.clip(v / H, -1, 1)
    inside = np.abs(v) < H
    for i, c in enumerate((-1.0, -0.5, 0.0, 0.5, 1.0)):
        rng = np.random.default_rng(41 + i)
        prof = (1 - vv ** 2) ** 0.62
        uc = c * W * prof + 0.012 * np.sin(vv * 5 + rng.uniform(0, TAU))
        slope = c * W * 0.62 * (1 - vv ** 2 + 1e-3) ** -0.38 * (-2 * vv / H)
        d = np.abs(u - uc) / np.sqrt(1 + slope ** 2)
        s = (vv + 1) / 2
        width = (STROKE if abs(c) == 1 else RIB * 1.2) * taper(s) * inside
        # light running up the rib: a brighter stretch climbing it, each rib a little behind its neighbour
        phase = (f / 50 + 0.17 * i) % 1.4 - 0.2
        run = 1 + 0.9 * run_k * np.exp(-((s - phase) / 0.09) ** 2)
        e, l, co = ink_light(d, width, aa, 1.0, core_k=1.0 if abs(c) == 1 else 0.6)
        edges.append(e), lights.append(l * run), cores.append(co * run)
    for j, h in enumerate((-0.93, 0.93)):  # the hoops: short strokes across its top and its bottom
        half = W * 0.32 * drawn
        if half > 0.05:
            d, w, _ = line_stroke(u, v, (-half, h * H), (half, h * H), STROKE * 0.9, 0.05 * math.copysign(1, h), 51 + j)
            e, l, co = ink_light(d, w, aa, 1.0)
            edges.append(e), lights.append(l), cores.append(co)
    return edges, lights, cores


def ripple(u, v, aa, f, drawn, glance):
    """W3: a faint gapped ring at rest; where a blow lands, ripples out over the unseen surface and the ribs round it."""
    turn = TURN * f / 60
    edges, lights, cores = [], [], []
    for i, (a0, span) in enumerate(((0.2, 2.6), (3.35, 2.6))):
        d, w, _ = arc_stroke(u, v, R, a0 - turn, span, STROKE * 0.75, drawn, 61 + i)
        e, l, c = ink_light(d, w, aa, 0.65, core_k=0.7)
        edges.append(e * 0.7), lights.append(l), cores.append(c)
    if glance is not None and 0 <= glance[0] <= 18:
        g, c0 = glance[0], glance[1:]
        r = np.hypot(u, v)
        disc = soft(r - R, aa)
        fade = 1 - life(g, 2, 18)
        for k in range(3):  # three ripples, 3 frames apart
            gk = g - 3 * k
            if gk < 0:
                continue
            rad = 0.25 + 1.7 * ease_out(life(gk, 0, 14))
            d = np.abs(np.hypot(u - c0[0], v - c0[1]) - rad)
            width = RIB * (1.2 - 0.25 * k) * (1 - life(gk, 4, 14))
            e, l, co = ink_light(d, width, aa, 1.3 - 0.3 * k, core_k=0.7)
            edges.append(e * disc), lights.append(l * disc), cores.append(co * disc)
        show = near(u, v, c0, 1.1) * fade * 1.4  # the ribs, shown round the contact
        _, ls, cs = rim_ribs(u, v, aa, f, drawn, 1.0)
        es, _, _ = rim_ribs(u, v, aa, f, drawn, 1.0)
        for e, l, co in list(zip(es, ls, cs))[3:]:
            edges.append(e * show), lights.append(l * show), cores.append(co * show)
        # the rim nearest the contact, lit
        d, w, _ = arc_stroke(u, v, R, 0.0, TAU - 1e-3, STROKE * 0.75, drawn, 61)
        e, l, co = ink_light(d, w, aa, 1.0)
        rim_near = near(u, v, c0, 1.0) * fade
        edges.append(e * rim_near), lights.append(l * rim_near), cores.append(co * rim_near)
    return edges, lights, cores


def draw_ward(fr, st: Stage, f, shape, glance_at=None, break_at=None):
    drawn, click = beats(f)
    broken = break_at is not None and f >= break_at
    if broken:  # one white frame, then gone: the break's own rows carry it
        b = f - break_at
        if b >= 2:
            return
        click = 3.0
    if drawn <= 0:
        return
    centre = st.root + st.aim * GUARD["Ahead"] + UP * (GUARD["Up"] + 0.3)
    sl = region(fr, [centre + st.side * R * 1.15 * sx + UP * R * 1.15 * sy for sx in (-1, 1) for sy in (-1, 1)])
    u, v, t, _ = on_plane(fr, sl, centre, st.side, UP)
    aa = np.abs(t) / fr.cam.focal * 1.2
    glance = None
    if glance_at is not None and f >= glance_at and not broken:
        p = contact(st, "G2_ward") - centre
        glance = (f - glance_at, float(p @ st.side), float(p @ UP))
    if shape == "W1_rim":
        edges, lights, cores = rim_ribs(u, v, aa, f, drawn, 0.85)
    elif shape == "W2_frame":
        edges, lights, cores = frame_ribs(u, v, aa, f, drawn)
    else:
        edges, lights, cores = ripple(u, v, aa, f, drawn, glance)
    edge = np.clip(sum(edges), 0, 1)
    light = sum(lights) * click
    core = sum(cores) * click
    if glance is not None and shape != "W3_ripple" and glance[0] <= 14:  # the strokes round the contact, lit
        lit = 1 + 2.2 * near(u, v, glance[1:], 0.8) * (1 - life(glance[0], 0, 14))
        light, core = light * lit, core * lit
    occ = st.mask("Lead") if lead_nearer(fr, st) else None
    keep = (1.0 if occ is None else 1 - occ[sl]) * (t > 0)
    fr.lay(sl, edge * keep, INK, INK_A)
    fr.add(sl, light * keep, AZURE, 2.0)
    fr.add(sl, core * keep, WHITE, 1.1)
    if glance is not None and glance[0] <= 8:
        glance_free(fr, st, glance[0], "G2_ward")


# --- the targets -------------------------------------------------------------------------------------------------------
TIMES = [-6, -3, 0, 3, 20, GLANCE, GLANCE + 2, GLANCE + 6, DROP + 4]
BREAKS = [BREAK + b for b in (0, 1, 3, 8, 16)]
SHAPES = ("W1_rim", "W2_frame", "W3_ripple")
PEAK = {"W1_rim": 20, "W2_frame": 20, "W3_ripple": GLANCE + 3}  # W3 shows itself only where it's hit


def render(st: Stage, name, f, broken=False):
    fr = st.frame()
    draw_ward(fr, st, f, name, glance_at=GLANCE, break_at=BREAK if broken else None)
    if broken:
        draw_break(fr, st, f - BREAK, "G2_ward")
    out = fr.render()
    return out if st.hud is None else out * (1 - st.hud) + st.base * st.hud


# --- the build's pictures (W2, research's pick) ------------------------------------------------------------------------
PIC = 512  # pixels a side: the ward is about 150 pixels tall at a phone, so a mip or two above it
EXT = 2.2  # studs from the ward's middle to the picture's edge, both ways: the frame (1.75 wide, 1.9 tall) and its glow
BORDER = 0.15  # studs at the picture's edge over which everything fades out, so a Beam's edge never shows as a line
PICTURES = ROOT / "build" / "handoff" / "Shade" / "fx" / "pictures"
LIGHT_MAX = 1.25  # a stroke's body plus its glow at the most: the light picture's alpha is its share of this


def write_rgba(alpha: np.ndarray, path) -> None:
    """A white picture with straight alpha, for a Beam's Color to tint (white everywhere, so its mips never fringe)."""
    import subprocess
    h, w = alpha.shape
    rgba = np.ones((h, w, 4))
    rgba[..., 3] = np.clip(alpha, 0, 1)
    data = (rgba * 255 + 0.5).astype(np.uint8).tobytes()
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgba", "-s", f"{w}x{h}", "-i", "-",
                    str(path)], input=data, check=True)


def pictures(out=PICTURES):
    """W2's frame, drawn whole (drawn 1, no running light) by frame_ribs, the target's own strokes, as three passes:
    ink (its hair of deep azure, laid under), light (its azure body and glow, added) and core (its white core, added).
    Laid out for a Beam stretched once (TextureMode Stretch, TextureLength 1) from the ward's foot (Attachment0) to its
    top (Attachment1), FaceCamera: the picture's top row lands at Attachment0 (handbook/visuals/vfx-engine-facts.md,
    "Beam"), so row 0 is the frame's foot; across, its columns, the Beam's width, EXT both ways."""
    step = 2 * EXT / PIC
    axis = -EXT + (np.arange(PIC) + 0.5) * step
    u, v = np.meshgrid(axis, axis)  # row r is v = axis[r]: row 0 the foot
    edges, lights, cores = frame_ribs(u, v, step, 0, 1.0, run_k=0.0)
    inner = EXT - np.maximum(np.abs(u), np.abs(v))
    window = np.clip(inner / BORDER, 0, 1) ** 2
    passes = {
        "guard_ward_ink": np.clip(sum(edges), 0, 1) * window,
        "guard_ward_light": np.clip(sum(lights) / LIGHT_MAX, 0, 1) * window,
        "guard_ward_core": np.clip(sum(cores), 0, 1) * window,
    }
    for name, alpha in passes.items():
        write_rgba(alpha, out / f"{name}.png")
        print(name, out / f"{name}.png", f"coverage {float((alpha > 0.02).mean()):.3f}")
    run_sheet(out)
    return passes


RUN_CYCLE = 70  # frames: frame_ribs' light climbs its ribs once every 1.4 x 50 frames
RUN_CELLS = 4  # a Grid4x4 flipbook, looped: 16 pictures over one cycle, 60 x 16 / 70 = 13.7 a second
RUN_CELL = 256  # pixels a cell: the sheet is 1024 a side, Roblox's most


def run_sheet(out=PICTURES):
    """W2's hold, its light running up the ribs: only the light the run adds (frame_ribs with the run less without),
    16 steps of one cycle in a Grid4x4 sheet, left to right then down, each cell laid out as the passes above."""
    step = 2 * EXT / RUN_CELL
    axis = -EXT + (np.arange(RUN_CELL) + 0.5) * step
    u, v = np.meshgrid(axis, axis)
    inner = EXT - np.maximum(np.abs(u), np.abs(v))
    window = np.clip(inner / BORDER, 0, 1) ** 2
    _, still, _ = frame_ribs(u, v, step, 0, 1.0, run_k=0.0)
    base = sum(still)
    cells = []
    for k in range(RUN_CELLS ** 2):
        _, lights, _ = frame_ribs(u, v, step, k * RUN_CYCLE / RUN_CELLS ** 2, 1.0, run_k=1.0)
        cells.append(np.clip(sum(lights) - base, 0, None))
    top = max(float(c.max()) for c in cells)
    rows = [np.concatenate(cells[r * RUN_CELLS:(r + 1) * RUN_CELLS], axis=1) for r in range(RUN_CELLS)]
    sheet = np.concatenate(rows, axis=0) / top * np.tile(window, (RUN_CELLS, RUN_CELLS))
    write_rgba(sheet, out / "guard_ward_run.png")
    print("guard_ward_run", out / "guard_ward_run.png", f"16 cells, the run's light at most {top:.2f} of a stroke's")


def main(argv):
    if argv[:1] == ["--pictures"]:
        pictures(Path(argv[1]) if len(argv) > 1 else PICTURES)
        return
    st = Stage(Path(argv[0]) if argv else STAGE)
    out = Path(argv[1]) if len(argv) > 1 else OUT
    only = argv[2].split(",") if len(argv) > 2 else SHAPES
    out.mkdir(parents=True, exist_ok=True)
    peaks, names = [], []
    for name in only:
        peak = PEAK[name]
        path = out / f"{name}_{st.name}_peak.png"
        write_png(render(st, name, peak), path)
        peaks.append(path)
        names.append(f"{name} ({st.name}, frame {peak})")
        strip([crop(render(st, name, f), st.crop) for f in TIMES], out / f"{name}_{st.name}_strip.png")
        strip([crop(render(st, name, f, broken=True), st.crop) for f in BREAKS], out / f"{name}_{st.name}_break.png")
        (out / f"{name}_{st.name}_strip.txt").write_text(
            "frames from Raise, at 60 a second: " + ", ".join(map(str, TIMES)) + f" (a glance at {GLANCE}, Drop at {DROP})\n"
            f"{name}_{st.name}_break.png: a heavy hit breaks it at frame {BREAK}: " + ", ".join(map(str, BREAKS)) + "\n",
            encoding="utf-8")
        print(name, st.name, "peak", peak)
    sheet = out / f"phone_ward_{st.name}"
    sheet.mkdir(exist_ok=True)
    phone_sheets(peaks, sheet, names)


if __name__ == "__main__":
    main(sys.argv[1:])
