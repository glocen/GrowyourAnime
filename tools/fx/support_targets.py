"""AR58's targets: the Support's cast with its mend, and its shield, as paint-overs on a frame of the game (tools/fx/paintover.py).
Scintilla's. Each target is a peak frame and a strip of its life, for research's pick in pairs (AGENTS.md, "The pick").

    py tools/fx/support_targets.py <stage.json> [out_dir] [A_tether,B_lob,...]   (default: build/handoff/Support/targets, all)

The stage is read in the game's Client at the capture: the picture (the viewport cropped from a lossless grab.ps1 frame), its
camera (CFrame:GetComponents(), FieldOfView, ViewportSize), and the world points of the Support (each arm's end, chest, head)
and of the one it mends or shields (chest, head, feet). Its "Check" holds WorldToViewportPoint of each point, to prove the
projection. An optional "Hud" mask (the same frame with every ScreenGui off, differenced inside the HUD's boxes) lays the
HUD back over the light, as the game draws it. build/handoff/Support/targets/stage_deck.json is the first.

The brief for all of them (research's pass of 2026-11-24, 21:21; the director's "that simple", 2026-11-25, 00:58 to 01:00):
- the main read: a link from the Support to the one it mends, and a caster's light that holds at a pack's distance;
- one hero shape, one hue (the heal number's mint, UIKit.Numbers.Heal), a white core, bright: never 2D cartoon fire.

The cast and the mend, three techniques:
- A, the tether: a light gathers between the raised sleeves and holds; on Cast a beam snaps from it to the hurt one, which
  bursts (core, needles leaning up, a dome swelling out).
- B, the lob: the gathered light is thrown in an arc over the pack and lands as a fountain on the hurt one; its trail
  hangs a moment, the link.
- C, the halo and the pillar: a ring of light crowns the caster while it casts; on Cast a pillar of light drops on the hurt
  one and the same ring crowns it a moment, the link by likeness.
The shield, two shapes:
- S1, the bubble: the tether's beam, then a lit shell round the one shielded, snapping up with a small overshoot.
- S2, the veil: the tether's beam, then a column of light rising round it, rimmed at its top and its foot.

Frames count from the cast's Cast marker at 60 a second (Definitions.Actions, SupportCast: sleeves up in 0.4 s, held 1.0 s).
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from paintover import Frame, hexc, phone_sheets, read_png, strip, write_png  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "handoff" / "Support" / "targets"
MINT = hexc("#6FE695")  # UIKit.Numbers.Heal: the mend's light and its number, one colour
WHITE = hexc("#FFFFFF")
UP = np.array([0.0, 1.0, 0.0])


def ease_out(t):
    t = min(max(t, 0.0), 1.0)
    return 1 - (1 - t) ** 3


def life(f, a, b):
    """0 before frame a, rising to 1 at b."""
    return min(max((f - a) / max(b - a, 1e-6), 0.0), 1.0)


def fade(f, a, b):
    """1 until frame a, falling to 0 at b."""
    return 1.0 - life(f, a, b)


class Stage:
    def __init__(self, path: Path):
        data = json.loads(path.read_text(encoding="utf-8"))
        self.path = path
        self.picture = (path.parent / data["Picture"]).resolve()
        self.camera = data["Camera"]
        v = {k: np.array(p, float) for k, p in data["Points"].items()}
        self.left, self.right = v["SupportLeft"], v["SupportRight"]
        self.chest, self.head = v["SupportChest"], v["SupportHead"]
        self.m_chest, self.m_head, self.m_feet = v["MendedChest"], v["MendedHead"], v["MendedFeet"]
        self.scale = data.get("Scale", 1.0)  # the mended one's scale: its shapes grow with it
        # the caster's light: between the sleeves' ends, a little toward the one it mends
        toward = self.m_chest - (self.left + self.right) / 2
        toward[1] = 0
        toward /= max(np.linalg.norm(toward), 1e-6)
        self.orb = (self.left + self.right) / 2 + toward * 0.35 + UP * 0.15
        self.base = read_png(self.picture)
        self.crop = data.get("Crop")  # [x, y, w, h] of the strip's tiles, in the picture's pixels
        # the HUD's pixels (white in a mask the picture's size): laid back over the light, as the game draws it
        hud = data.get("Hud")
        self.hud = read_png((path.parent / hud).resolve())[..., :1] if hud else None

    def frame(self) -> Frame:
        return Frame(self.picture, self.camera, base=self.base)


# --- shared pieces ------------------------------------------------------------------------------------------------------
def caster_light(fr: Frame, s: Stage, f: float, k: float = 1.0):
    """The light held between the sleeves: gathers from -24 (the sleeves rising), full at -4, held through the cast,
    let go at Lower (+60). Its few short needles turn slowly, so it lives while it holds."""
    g = life(f, -24, -4) * fade(f, 58, 68) * k
    if g <= 0:
        return
    pulse = 1 + 0.12 * math.sin(f / 60 * 2 * math.pi * 1.6)
    fr.core(s.orb, 0.32 * pulse * (0.4 + 0.6 * g), MINT, 3.2 * g)
    fr.glow(s.orb, 1.3 * pulse, MINT, 0.55 * g)
    for side in (s.left, s.right):
        fr.glow(side, 0.45, MINT, 0.9 * g)
    fr.spikes(s.orb, 6, 1.1 * pulse, 0.12, MINT, k=1.4 * g, seed=int(f // 6) + 3, spread=(0.55, 1.0), inner=0.2)


def beam(fr: Frame, s: Stage, f: float, until_frame=2, hold_to=8, gone=22, k=1.0):
    """The link: a beam from the caster's light to the hurt one's chest, drawn in `until_frame` frames, held, thinned."""
    if f < 0 or f > gone:
        return
    reach = ease_out(life(f, 0, until_frame)) if until_frame > 0 else 1.0
    end = s.orb + (s.m_chest - s.orb) * reach
    w = 0.42 * (1 - 0.65 * life(f, hold_to, gone))
    a = fade(f, hold_to + 4, gone) * k
    fr.streak(s.orb, end, w * 2.6, w * 2.0, MINT, 0.45 * a, soft=0.95)  # its glow
    fr.streak(s.orb, end, w, w * 0.8, MINT, 2.6 * a, soft=0.55)  # its core, white by its strength
    if reach < 1:
        fr.core(end, 0.3, MINT, 3 * a)


def burst(fr: Frame, s: Stage, f: float, at: float, k: float = 1.0, up=0.35, seed=7):
    """The mend's hero on the hurt one: a white-hot core, needles leaning up, a dome swelling out and fading."""
    t = f - at
    if t < 0 or t > 34:
        return
    sc = s.scale
    hot = math.exp(-t / 4.5) * k
    fr.core(s.m_chest, 0.55 * sc * (1 + 0.4 * ease_out(t / 6)), MINT, 5.0 * hot)
    n_len = (2.4 + 2.6 * ease_out(t / 8)) * sc
    fr.spikes(s.m_chest, 14, n_len, 0.28 * sc, MINT, k=2.4 * fade(t, 3, 14) * k, seed=seed, up=up, spread=(0.45, 1.0),
              inner=0.18 + 0.25 * life(t, 2, 12))
    r = (1.5 + 1.6 * ease_out(t / 18)) * sc
    fr.dome(s.m_chest, r, MINT, fill=0.16 * fade(t, 4, 26) * k, rim=1.25 * fade(t, 6, 28) * k, rim_width=0.22)
    feet = s.m_feet + UP * 0.05
    fr.ring(feet, (1.0 + 1.8 * ease_out(t / 14)) * sc, 0.1 * sc, MINT, k=1.3 * fade(t, 6, 20) * k)
    rise_motes(fr, s, t, k)


def rise_motes(fr: Frame, s: Stage, t: float, k=1.0, n=9, seed=11):
    """Light lifting off the mended one: motes rising and slowing, after the burst."""
    rng = np.random.default_rng(seed)
    for i in range(n):
        start = 4 + rng.uniform(0, 10)
        tt = t - start
        if tt < 0:
            continue
        ang = rng.uniform(0, 2 * math.pi)
        rad = rng.uniform(0.5, 1.4) * s.scale
        h = ease_out(tt / 40) * rng.uniform(2.5, 4.5) * s.scale
        p = s.m_feet + np.array([math.cos(ang) * rad, 0.4 + h, math.sin(ang) * rad])
        fr.glow(p, 0.13 * s.scale, MINT, 2.2 * fade(tt, 18, 38) * k, falloff=2.5)


# --- the targets --------------------------------------------------------------------------------------------------------
def target_a(fr: Frame, s: Stage, f: float):
    caster_light(fr, s, f)
    beam(fr, s, f)
    burst(fr, s, f, at=2)


def target_b(fr: Frame, s: Stage, f: float):
    flight = 11
    caster_light(fr, s, f, k=1.0 if f < 0 or f > 16 else 0.35)
    if 0 <= f <= 30:
        reach = min(f / flight, 1.0)
        hang = fade(f, flight + 2, 30)
        lift = 2.6 * s.scale
        head = fr.arc(s.orb, s.m_chest, lift, 0.14, 0.5, MINT, k=1.6 * hang, until=max(reach, 0.02))
        fr.arc(s.orb, s.m_chest, lift, 0.4, 1.3, MINT, k=0.3 * hang, until=max(reach, 0.02))
        if reach < 1:
            fr.core(head, 0.45, MINT, 4.0)
            fr.glow(head, 1.2, MINT, 0.8)
    t = f - flight
    if 0 <= t <= 34:
        # the fountain: needles thrown up, a column of light, the dome
        fr.streak(s.m_feet, s.m_feet + UP * (4.5 * s.scale * ease_out(t / 5)), 1.6 * s.scale, 0.5 * s.scale, MINT,
                  1.1 * fade(t, 4, 16), soft=0.95)
        burst(fr, s, f, at=flight, up=0.95, seed=5)


def facing(fr: Frame, p, lean=0.8):
    """A ring's normal: up, leaned toward the camera."""
    to = fr.cam.pos - np.asarray(p, float)
    to /= np.linalg.norm(to)
    return UP + to * lean


def target_c(fr: Frame, s: Stage, f: float):
    g = life(f, -24, -6) * fade(f, 58, 68)
    crown = s.head + UP * 1.05
    if g > 0:
        # the halo leans toward the camera, so it reads as a ring and not a line at the game's low view
        lean = facing(fr, crown)
        flare = 1 + 0.6 * math.exp(-max(f, 0) / 5) * (1 if f >= 0 else 0)
        fr.ring(crown, 0.85 * (0.7 + 0.3 * g), 0.1, MINT, k=3.0 * g * flare, normal=lean)
        fr.glow(crown, 0.9, MINT, 0.45 * g * flare)
        fr.glow(s.orb, 0.6, MINT, 0.5 * g)
    t = f
    if 0 <= t <= 34:
        top = s.m_feet + UP * 14
        w = 1.1 * s.scale * (1 - 0.6 * life(t, 4, 16))
        a = fade(t, 6, 18)
        fr.streak(top, s.m_feet, w * 2.4, w * 2.0, MINT, 0.5 * a, soft=0.95)
        fr.streak(top, s.m_feet, w * 0.8, w * 0.7, MINT, 2.8 * a, soft=0.5)
        fr.spikes(s.m_feet + UP * 0.1, 16, 3.2 * s.scale * (0.6 + 0.4 * ease_out(t / 6)), 0.25, MINT, k=2.2 * fade(t, 3, 14),
                  seed=9, flat=0.32, inner=0.1)
        fr.ring(s.m_feet + UP * 0.05, (1.2 + 1.6 * ease_out(t / 12)) * s.scale, 0.11, MINT, k=1.6 * fade(t, 4, 18))
        echo = s.m_head + UP * 1.05
        fr.ring(echo, 0.9 * s.scale, 0.1, MINT, k=2.8 * fade(t, 12, 34) * life(t, 0, 3), normal=facing(fr, echo))
        fr.core(s.m_chest, 0.5 * s.scale, MINT, 3.5 * math.exp(-t / 5))
        fr.dome(s.m_chest, (1.4 + 1.2 * ease_out(t / 16)) * s.scale, MINT, fill=0.12 * fade(t, 4, 22),
                rim=1.0 * fade(t, 6, 26))
        rise_motes(fr, s, t)


def shield_snap(t):
    """The shell's size: snapping up from 0.6 with a small overshoot, settled by frame 10."""
    if t < 0:
        return 0.0
    if t < 5:
        return 0.6 + 0.48 * ease_out(t / 5)
    return 1.08 - 0.08 * ease_out((t - 5) / 5)


def target_s1(fr: Frame, s: Stage, f: float):
    caster_light(fr, s, f)
    beam(fr, s, f, gone=16)
    t = f - 2
    if t >= 0:
        sc = s.scale
        size = shield_snap(t)
        breathe = 1 + 0.03 * math.sin(t / 60 * 2 * math.pi * 0.8)
        centre = (s.m_chest + s.m_feet) / 2 + UP * 0.5 * sc
        r = 2.5 * sc * size * breathe
        flash = 1 + 1.6 * math.exp(-t / 4)
        fr.dome(centre, r, MINT, fill=0.10, rim=0.95 * flash, rim_width=0.16)
        fr.ring(s.m_feet + UP * 0.05, r * 0.92, 0.1 * sc, MINT, k=1.1 * flash)
        fr.glow(centre + UP * r * 0.55 + np.array([-0.4, 0, 0]) * r, 0.35 * r, WHITE, 0.25)  # its catch-light


def target_s2(fr: Frame, s: Stage, f: float):
    caster_light(fr, s, f)
    beam(fr, s, f, gone=16)
    t = f - 2
    if t >= 0:
        sc = s.scale
        rise = ease_out(t / 8)
        flash = 1 + 1.4 * math.exp(-t / 4)
        top_h = 5.6 * sc * rise
        base = s.m_feet + UP * 0.05
        r = 1.7 * sc
        for i in range(14):
            a = i / 14 * 2 * math.pi + t * 0.004
            off = np.array([math.cos(a) * r, 0, math.sin(a) * r])
            fr.streak(base + off, base + off + UP * top_h * (0.75 + 0.25 * ((i * 37) % 5) / 4), 0.16 * sc, 0.02, MINT,
                      0.75 * flash, soft=0.9)
        fr.ring(base, r, 0.11 * sc, MINT, k=1.6 * flash)
        fr.ring(base + UP * top_h * 0.9, r * 0.92, 0.08 * sc, MINT, k=1.2 * flash)
        fr.streak(base, base + UP * top_h, r * 2.3, r * 2.0, MINT, 0.12, soft=1.0)  # the veil's fill, faint


TARGETS = {
    "A_tether": (target_a, 3, (-14, 0, 3, 8, 16, 30, 58)),
    "B_lob": (target_b, 8, (-14, 0, 4, 8, 12, 20, 40)),
    "C_halo_pillar": (target_c, 2, (-14, 0, 2, 8, 16, 30, 58)),
    "S1_bubble": (target_s1, 6, (-14, 0, 3, 6, 12, 60, 200)),
    "S2_veil": (target_s2, 8, (-14, 0, 3, 8, 14, 60, 200)),
}


def render(s: Stage, fn, f: float) -> np.ndarray:
    fr = s.frame()
    fn(fr, s, f)
    out = fr.render()
    return out if s.hud is None else out * (1 - s.hud) + s.base * s.hud


def crop(img, box):
    if not box:
        return img
    x, y, w, h = box
    return img[y:y + h, x:x + w]


def main(argv):
    stage = Stage(Path(argv[0]))
    out = Path(argv[1]) if len(argv) > 1 else OUT
    only = argv[2].split(",") if len(argv) > 2 else None
    out.mkdir(parents=True, exist_ok=True)
    for name, (fn, peak, times) in TARGETS.items():
        if only and name not in only:
            continue
        write_png(render(stage, fn, peak), out / f"{name}_peak.png")
        tiles = [crop(render(stage, fn, f), stage.crop) for f in times]
        strip(tiles, out / f"{name}_strip.png")
        (out / f"{name}_strip.txt").write_text(
            "frames from the cast's Cast marker, at 60 a second: " + ", ".join(str(t) for t in times) + "\n", encoding="utf-8")
        print(name, "peak", peak, "strip", times)
    names = [n for n in TARGETS if (out / f"{n}_peak.png").exists()]
    phone_sheets([out / f"{n}_peak.png" for n in names], out, names)


if __name__ == "__main__":
    main(sys.argv[1:])
