"""TR69 A's two reads, their looks for research's pick in pairs (AGENTS.md, "Every action, world, effect and screen"):
the target ring under the lead's target and the glint on a Shade's mask before its ordinary swing. Painted over the
street stage at the player's camera (the Festival place at night, a Brawler 26 studs up the street, Rook held at Hit3;
build/handoff/Fight/stage/stage_street.json), beside today's grey blocks. Scintilla's.

    py tools/fx/fight_read_targets.py [stage.json] [out_dir] [R1_cut,R2_collar,...]
    py tools/fx/fight_read_targets.py --pictures [out_dir]   (default: build/handoff/Fight/pictures)
    The build of research's pick (R4 and G1, 2026-11-26, 19:06): their strokes as white pictures with straight alpha,
    tinted in the game: see pictures().

Feel lines:
- The ring: the player sees at a glance which foe their Voidkin is on, and it's quieter than every hit. It sits under
  the foe in the foe's type colour (HudConfig.Card.Types) at Combat.Ring.Radius, as the grey block does.
- The glint: the mask flashes a beat before the swing, so the strike can be read and Called. It starts with the swing
  and lasts Combat.Glint.Seconds (0.3 s, 18 frames).

The ring's three looks, each with its lever:
- R1, the cut ring: four arcs with a white core and an ink hair, snapping in from 1.45 times its radius over 8 frames
  (Back Out: the lock-on's snap) and turning slowly after (12 degrees a second: alive, never busy).
- R2, the collar: a low wall of light standing round the foe, fading upward over 0.55 studs, on a bright floor line.
  Upright, so it reads at the player's low camera, where a flat ring is a thin ellipse. It rises in over 6 frames.
- R3, the brackets: four corner ticks round the foe's feet with inward teeth, over a faint ring, closing in over 8.
- R4, the mark, an alternative to the ring (tier 2, research's to weigh): at the player's camera the lead usually stands
  between the camera and its target, and its body hides most of a ring at the target's feet (this stage: all but an arc
  on the far side). A small cut chevron over the foe's head, in R1's make (the type's colour, a white core, an ink
  hair), drops in over 6 frames (Back Out) and bobs 0.08 studs once a second.
The glint's three, each starting on the swing's first frame (anticipation's flag):
- G1, the star: a four-point star at the mask's eye line, a white core with the type's fringe, out in 2 frames and
  drawn back in by 18.
- G2, the lit face: the mask itself flares white-hot with a halo in the type's colour, eased back over 18.
- G3, the ping: a thin ring of the type's colour runs out from the mask over 14 frames, a white flick at its start.
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from paintover import hexc, phone_sheets, read_png, strip, write_png  # noqa: E402
from shade_targets import Stage, back_out, band, clamp01, ease_out, life, on_plane, region  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
STAGE = ROOT / "build" / "handoff" / "Fight" / "stage" / "stage_street.json"
OUT = ROOT / "build" / "handoff" / "Fight" / "targets"
RING = {"Radius": 2.4, "Width": 0.2, "Transparency": 0.25, "Lift": 0.06}  # Config.Combat.Ring
TYPES = {"Red": "#EA4B4F", "Orange": "#F4902A", "Blue": "#3F9DF2", "Purple": "#A470F2", "Green": "#42CC7E"}
TYPE = "Red"  # the Brawler's (Definitions: brawler, Type Red)
INK = hexc("#1A1020")
WHITE = np.array([1.0, 1.0, 1.0])

# name: (what, peak frame, the strip's frames). Ring frames from the target's pick; glint frames from the swing's start.
TARGETS = {
    "R0_today": ("ring", 10, [0, 4, 10, 30]),
    "R1_cut": ("ring", 10, [0, 2, 4, 6, 8, 10, 30, 60]),
    "R2_collar": ("ring", 10, [0, 2, 4, 6, 8, 10, 30, 60]),
    "R3_brackets": ("ring", 10, [0, 2, 4, 6, 8, 10, 30, 60]),
    "R4_mark": ("ring", 10, [0, 2, 4, 6, 8, 10, 30, 60]),
    "G0_today": ("glint", 0, [-2, 0, 4, 9, 14, 18]),
    "G1_star": ("glint", 2, [-2, 0, 1, 2, 4, 8, 12, 18]),
    "G2_face": ("glint", 2, [-2, 0, 1, 2, 4, 8, 12, 18]),
    "G3_ping": ("glint", 3, [-2, 0, 1, 3, 6, 9, 12, 18]),
}


class Street(Stage):
    def __init__(self, path: Path):
        super().__init__(path)
        data = json.loads(path.read_text(encoding="utf-8"))
        self.today = read_png((path.parent / data["Today"]).resolve())
        part = data["MaskParts"][0]
        m = np.array(part["CFrame"], float)
        self.mask_at = m[:3]
        rot = m[3:].reshape(3, 3)
        self.mask_look = -rot[:, 2]
        self.mask_up = rot[:, 1]
        self.mask_size = np.array(part["Size"], float)
        x, y = self.frame().at(self.root)
        self.crop = [int(x) - 380, int(y) - 300, 760, 440]
        self.type = hexc(TYPES[TYPE])

    def occlusion(self, fr, sl, depth, behind_shade=True):
        """The bodies over a light at `depth`: the avatar always (it's nearest), the lead where the light lies behind
        it, the Shade where the light lies behind its middle."""
        occ = self.masks["Avatar"][sl].copy()
        lead_d = fr.cam.project(self.lead_root)[1]
        occ = np.maximum(occ, self.masks["Lead"][sl] * (depth > lead_d))
        if behind_shade:
            shade_d = fr.cam.project(self.root)[1]
            occ = np.maximum(occ, self.masks["Shade"][sl] * (depth > shade_d))
        return occ


def floor_slice(fr, st, reach):
    c = np.array([st.root[0], st.ground + RING["Lift"], st.root[2]])
    pts = [c + np.array([dx, 0, dz]) * reach for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1), (0.7, 0.7), (-0.7, -0.7), (0.7, -0.7), (-0.7, 0.7))]
    sl = region(fr, pts, pad=10)
    u, v, depth, cos = on_plane(fr, sl, c, np.array([1.0, 0, 0]), np.array([0, 0, 1.0]))
    return sl, u, v, depth, np.abs(cos)


def px_aa(fr, depth, cos):
    """A pixel's footprint on the floor in studs, so edges stay one pixel soft at any distance and slant."""
    return depth / fr.cam.focal / np.maximum(cos, 0.08)


def draw_ring(fr, st, name, f):
    R, colour = RING["Radius"], st.type
    if name == "R0_today":
        sl, u, v, depth, cos = floor_slice(fr, st, R + 0.4)
        aa = px_aa(fr, depth, cos)
        r = np.hypot(u, v)
        a = np.clip(0.5 - (np.abs(r - R) - RING["Width"] / 2) / aa, 0, 1) * (1 - RING["Transparency"])
        occ = st.occlusion(fr, sl, depth)
        fr.lay(sl, a * (1 - occ), colour, 1.0)
        return
    if name == "R1_cut":
        grow = back_out(life(f, 0, 8), 1.2)
        radius = R * (1.45 - 0.45 * grow)
        alpha = ease_out(life(f, 0, 5))
        sl, u, v, depth, cos = floor_slice(fr, st, R * 1.5 + 0.4)
        aa = px_aa(fr, depth, cos)
        r = np.hypot(u, v)
        turn = math.radians(12) * max(f, 0) / 60
        ang = (np.arctan2(v, u) - turn) % (math.pi / 2)  # four arcs, each a quarter less its gap
        gap = math.radians(18)
        arc = np.clip(0.5 + np.minimum(ang - gap / 2, math.pi / 2 - gap / 2 - ang) * radius / aa, 0, 1)
        width = 0.16
        body = np.clip(0.5 - (np.abs(r - radius) - width / 2) / aa, 0, 1) * arc
        core = np.clip(0.5 - (np.abs(r - radius) - 0.025) / aa, 0, 1) * arc
        ink = np.clip(0.5 - (np.abs(r - radius - width / 2 - 0.03) - 0.03) / aa, 0, 1) * arc
        occ = 1 - st.occlusion(fr, sl, depth)
        fr.lay(sl, ink * occ * alpha, INK, 0.55)
        fr.lay(sl, body * occ * alpha, colour, 0.9)
        fr.add(sl, body * occ * alpha, colour, 0.35)
        fr.add(sl, core * occ * alpha, WHITE, 0.9)
        return
    if name == "R2_collar":
        rise = ease_out(life(f, 0, 6))
        H = 0.55 * rise
        if H <= 0.01:
            return
        c = np.array([st.root[0], st.ground, st.root[2]])
        pts = [c + np.array([dx * R, h, dz * R]) for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)) for h in (0, 0.6)]
        sl = region(fr, pts, pad=12)
        from shade_targets import on_cylinder
        for s_, height, depth, cos in on_cylinder(fr, sl, c, R, st.aim):
            h = height - st.ground
            inside = (h >= 0) & (h <= H) & np.isfinite(depth)
            fade = np.where(inside, (1 - np.clip(h / max(H, 1e-3), 0, 1)) ** 1.6, 0)
            occ = 1 - st.occlusion(fr, sl, np.where(np.isfinite(depth), depth, 1e9))
            fr.lay(sl, fade * occ * 0.55, colour, 1.0)
            fr.add(sl, fade * occ, colour, 0.5)
        sl2, u, v, depth, cos = floor_slice(fr, st, R + 0.3)
        aa = px_aa(fr, depth, cos)
        r = np.hypot(u, v)
        line = np.clip(0.5 - (np.abs(r - R) - 0.035) / aa, 0, 1)
        occ = 1 - st.occlusion(fr, sl2, depth)
        fr.lay(sl2, line * occ * rise, colour, 1.0)
        fr.add(sl2, line * occ * rise, WHITE, 0.8)
        return
    if name == "R3_brackets":
        close = back_out(life(f, 0, 8), 1.0)
        half = R * 0.82 * (1.35 - 0.35 * close)  # the square's half side
        alpha = ease_out(life(f, 0, 4))
        sl, u, v, depth, cos = floor_slice(fr, st, half * 1.5 + 0.4)
        aa = px_aa(fr, depth, cos)
        # turn the square so a corner points at the camera's side: brackets read square-on from any angle
        q = np.radians(45)
        x, y = u * math.cos(q) - v * math.sin(q), u * math.sin(q) + v * math.cos(q)
        ax, ay = np.abs(x), np.abs(y)
        arm, w = half * 0.42, 0.13
        on_x = (np.abs(ax - half) < w / 2 + aa / 2) & (ay > half - arm) & (ay < half + w / 2)
        on_y = (np.abs(ay - half) < w / 2 + aa / 2) & (ax > half - arm) & (ax < half + w / 2)
        tooth = (np.abs(ax - (half - w)) < w * 0.7) & (np.abs(ay - (half - w)) < w * 0.7)  # the inward tooth at the corner
        tick = (on_x | on_y | tooth).astype(np.float32)
        r = np.hypot(u, v)
        faint = np.clip(0.5 - (np.abs(r - R) - 0.04) / aa, 0, 1) * 0.35
        occ = 1 - st.occlusion(fr, sl, depth)
        fr.lay(sl, tick * occ * alpha, colour, 0.92)
        fr.add(sl, tick * occ * alpha, colour, 0.4)
        fr.lay(sl, faint * occ * alpha, colour, 1.0)
        return
    if name == "R4_mark":
        drop = back_out(life(f, 0, 6), 1.4)
        alpha = ease_out(life(f, 0, 4))
        bob = 0.08 * math.sin(2 * math.pi * max(f - 8, 0) / 60) if f > 8 else 0.0
        top = st.mask_at[1] + st.mask_size[1] / 2
        apex = np.array([st.root[0], top + 0.55 + 1.0 * (1 - drop) + bob, st.root[2]])
        px = fr.cam.px(apex, 1.0)
        a = fr.at(apex)
        wings = [a + np.array([-0.5, -0.46]) * px, a + np.array([0.5, -0.46]) * px]
        for w_ in wings:  # the ink hair, the type's colour, the white core
            fr.streak(w_, a, 0.2 * px, 0.2 * px, INK, ink=0.6 * alpha, screen=True)
        for w_ in wings:
            fr.streak(w_, a, 0.14 * px, 0.14 * px, colour, 1.3 * alpha, screen=True)
        for w_ in wings:
            fr.streak(w_, a, 0.045 * px, 0.045 * px, WHITE, 1.4 * alpha, screen=True)


def mask_face(fr, st):
    """The mask's eye line, on its front, and how many pixels a stud spans there."""
    p = st.mask_at + st.mask_look * st.mask_size[2] * 0.3 + st.mask_up * st.mask_size[1] * 0.08
    return p, fr.cam.px(p, 1.0)


def draw_glint(fr, st, name, f):
    colour = st.type
    p, s = mask_face(fr, st)
    c = fr.at(p)
    depth = fr.cam.project(p)[1]
    if name == "G1_star":
        if f < 0 or f > 18:
            return
        k = ease_out(life(f, 0, 2)) * (1 - life(f, 4, 18) ** 1.5)
        size = (0.6 + 0.9 * ease_out(life(f, 0, 2))) * (1 - 0.5 * life(f, 4, 18))
        for (dx, dy), length, width in (((0, -1), 1.25, 0.16), ((0, 1), 1.0, 0.16), ((-1, 0), 0.8, 0.12), ((1, 0), 0.8, 0.12)):
            tip = c + np.array([dx, dy]) * length * size * s
            fr.streak(c, tip, width * s * size, 0.02 * s, colour, 1.6 * k, screen=True)
            fr.streak(c, tip, width * 0.4 * s * size, 0.01 * s, WHITE, 2.4 * k, screen=True)
        fr.glow(p, 0.35 * size, colour, 0.9 * k)
        fr.glow(p, 0.12 * size, WHITE, 2.5 * k, falloff=3)
    elif name == "G2_face":
        if f < 0 or f > 18:
            return
        k = ease_out(life(f, 0, 1.5)) * (1 - ease_out(life(f, 2, 18)))
        sl = region(fr, [st.mask_at + d * st.mask_size.max() * 0.7 for d in (np.array([1, 0, 0]), np.array([-1, 0, 0]), np.array([0, 1, 0]), np.array([0, -1, 0]))], pad=40)
        face = st.masks["Shade"][sl] * (fr.yy[sl] < fr.at(st.mask_at - st.mask_up * st.mask_size[1] * 0.45)[1])
        lead_d = fr.cam.project(st.lead_root)[1]
        face = face * (1 - st.masks["Lead"][sl] * (depth > lead_d)) * (1 - st.masks["Avatar"][sl])
        fr.add(sl, face, WHITE, 0.22 * k)  # lit, its cuts kept: a blown face reads as a blob
        fr.glow(p, 1.1, colour, 0.55 * k)
    elif name == "G3_ping":
        if f < 0 or f > 18:
            return
        t = life(f, 0, 14)
        radius = (0.5 + 1.7 * ease_out(t)) * s
        k = 1 - t ** 1.2
        sl = fr.box(c, radius + 0.3 * s)
        d = np.hypot(fr.xx[sl] - c[0], fr.yy[sl] - c[1])
        w = max(0.06 * s * (1 - 0.5 * t), 1.2)
        fr.add(sl, band(d - radius, w), colour, 1.6 * k)
        fr.add(sl, band(d - radius, w * 0.4), WHITE, 1.2 * k)
        flick = 1 - life(f, 0, 3)
        if flick > 0:
            fr.glow(p, 0.3, WHITE, 2.2 * flick, falloff=3)
            fr.glow(p, 0.7, colour, 0.8 * flick)


def render(st, name, f):
    what = TARGETS[name][0]
    if name == "G0_today":  # today's grey glint: the masks at Peak, eased back over 0.3 s (MaskGlint), as captured
        k = 0.0 if f < 0 else (1 - ease_out(life(f, 0, 18)))
        out = st.base * (1 - k) + st.today * k
        return out
    fr = st.frame()
    (draw_ring if what == "ring" else draw_glint)(fr, st, name, f)
    out = fr.render()
    return out if st.hud is None else out * (1 - st.hud) + st.base * st.hud


def crop(img, box):
    x, y, w, h = box
    return img[max(0, y):y + h, max(0, x):x + w]


# --- the build's pictures (R4 and G1, research's pick) ---------------------------------------------------------------
PICTURES = ROOT / "build" / "handoff" / "Fight" / "pictures"
SOFT = 0.6  # a stroke's soft share, as Frame.streak draws it
# R4's chevron in studs, its apex at the origin, its wings up and out; the picture's middle sits MARK_CENTRE over the apex.
MARK = {"Wing": (0.5, 0.46), "Ink": 0.2, "Light": 0.14, "Core": 0.045, "Side": 1.4, "Pixels": 256}
MARK_CENTRE = MARK["Wing"][1] / 2
# G1's star at size 1 (its Size track grows it to 1.5 at the peak): arms up, down and to each side, the colour's widths
# at the root tapering to Tip; the core's at Core of them. Its two glows as the target's: radius, falloff.
STAR = {"Arms": (((0, 1), 1.25, 0.16), ((0, -1), 1.0, 0.16), ((-1, 0), 0.8, 0.12), ((1, 0), 0.8, 0.12)),
        "Tip": 0.02 / 1.5, "Core": 0.4, "CoreTip": 0.01 / 1.5, "Side": 2.8, "Pixels": 512,
        "Glow": (0.35, 2.0), "CoreGlow": (0.12, 3.0)}


def grid(side: float, pixels: int):
    """Studs across (u, right) and up (v) at each pixel's middle: row 0 is the picture's top."""
    step = side / pixels
    axis = -side / 2 + (np.arange(pixels) + 0.5) * step
    u, v = np.meshgrid(axis, axis[::-1])
    return u, v, step


def stroke(u, v, a, b, width_a, width_b, step):
    """Frame.streak's tapered stroke in studs, as coverage 0 to 1."""
    a, b = np.asarray(a, float), np.asarray(b, float)
    d = b - a
    t = np.clip(((u - a[0]) * d[0] + (v - a[1]) * d[1]) / max(float(d @ d), 1e-9), 0, 1)
    dist = np.hypot(u - (a[0] + t * d[0]), v - (a[1] + t * d[1]))
    wid = (width_a + (width_b - width_a) * t) / 2
    return np.clip(1 - (dist - wid * (1 - SOFT)) / np.maximum(wid * SOFT * 2, 0.6 * step), 0, 1) ** 2


def union(*alphas):
    out = np.zeros_like(alphas[0])
    for a in alphas:
        out = 1 - (1 - out) * (1 - np.clip(a, 0, 1))
    return out


def pictures(out=PICTURES):
    """R4's mark as three passes (ink, light, core) and G1's star as two (light, core), each white with straight alpha
    for the game to tint: the ink in INK, the light in the foe's type colour, the core white. Each pass is the target's
    own strokes at their own gain (the light added at 1.3 for R4 and 1.6 for G1, the core at 1.4 and 2.4), so its alpha
    is that gain's coverage; the chevron's two strokes meet at the apex by union, never added twice.
    The mark: its picture's middle stands MARK_CENTRE studs over the apex, MARK["Side"] studs a side. The star: its
    middle at the mask's eye line, STAR["Side"] studs a side at size 1."""
    out.mkdir(parents=True, exist_ok=True)
    u, v, step = grid(MARK["Side"], MARK["Pixels"])
    v = v + MARK_CENTRE  # the apex at the origin, the picture's middle MARK_CENTRE over it
    wx, wy = MARK["Wing"]

    def chevron(width):
        return union(*[stroke(u, v, w, (0, 0), width, width, step) for w in ((-wx, wy), (wx, wy))])

    passes = {
        "fight_mark_ink": chevron(MARK["Ink"]),
        "fight_mark_light": np.clip(1.3 * chevron(MARK["Light"]), 0, 1),
        "fight_mark_core": np.clip(1.4 * chevron(MARK["Core"]), 0, 1),
    }
    u, v, step = grid(STAR["Side"], STAR["Pixels"])
    r = np.hypot(u, v)

    def glow(radius, falloff):
        return np.exp(-(r / radius) ** falloff)

    arms = [stroke(u, v, (0, 0), np.array(d) * n, w, STAR["Tip"], step) for d, n, w in STAR["Arms"]]
    cores = [stroke(u, v, (0, 0), np.array(d) * n, w * STAR["Core"], STAR["CoreTip"], step) for d, n, w in STAR["Arms"]]
    passes["fight_glint_light"] = union(1.6 * union(*arms), 0.9 * glow(*STAR["Glow"]))
    passes["fight_glint_core"] = union(2.4 * union(*cores), 2.5 * glow(*STAR["CoreGlow"]))
    from ward_targets import write_rgba
    for name, alpha in passes.items():
        edge = max(float(alpha[0].max()), float(alpha[-1].max()), float(alpha[:, 0].max()), float(alpha[:, -1].max()))
        assert edge < 0.01, f"{name} reaches its edge ({edge:.3f})"
        write_rgba(alpha, out / f"{name}.png")
        print(name, f"coverage {float((alpha > 0.02).mean()):.3f}")
    return passes


def main(argv):
    if argv[:1] == ["--pictures"]:
        pictures(Path(argv[1]) if len(argv) > 1 else PICTURES)
        return
    st = Street(Path(argv[0]) if argv else STAGE)
    out = Path(argv[1]) if len(argv) > 1 else OUT
    only = argv[2].split(",") if len(argv) > 2 else None
    out.mkdir(parents=True, exist_ok=True)
    groups = {"ring": ([], []), "glint": ([], [])}
    for name, (what, peak, times) in TARGETS.items():
        if only and name not in only:
            continue
        path = out / f"{name}_{st.name}_peak.png"
        write_png(render(st, name, peak), path)
        groups[what][0].append(path)
        groups[what][1].append(f"{name} (frame {peak})")
        strip([crop(render(st, name, f), st.crop) for f in times], out / f"{name}_{st.name}_strip.png")
        beat = "the target's pick" if what == "ring" else "the swing's start"
        (out / f"{name}_{st.name}_strip.txt").write_text(f"frames from {beat}, at 60 a second: " + ", ".join(map(str, times)) + "\n", encoding="utf-8")
        print(name, "peak", peak)
    for what, (peaks, names) in groups.items():
        if peaks:
            sheet = out / f"phone_{what}_{st.name}"
            sheet.mkdir(exist_ok=True)
            phone_sheets(peaks, sheet, names, cols=2)


if __name__ == "__main__":
    main(sys.argv[1:])
