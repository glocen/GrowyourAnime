"""AR52's targets: the Guard's shield and the Dasher's line, painted over frozen frames of the game, for research's pick in
pairs (AGENTS.md, "Every action, world, effect and screen"). Scintilla's.

    py tools/fx/shade_targets.py <stage.json> [out_dir] [G1_pane,G2_ward,G3_wall | D1_lane,D2_chevrons]
    (default out: build/handoff/Shade/targets; default: the Guard's three on a Guard stage, the Dasher's two on a Dasher's)

A stage, written at the capture as AR58's and AR61's:
    {"Picture": "guard_deck.png", "Camera": {"CFrame": [12], "Fov": deg, "Viewport": [w, h]}, "Kind": "Guard"|"Dasher",
     "Points": {"ShadeRoot": [x,y,z], "ShadeChest": [...], "LeadRoot": [...], "LeadChest": [...], "Aim": [x,y,z]?},
     "Ground": y, "Masks": {"Lead": "lead_mask.png", "Shade": "shade_mask.png"}, "Hud": "hud_mask.png",
     "Crop": [x, y, w, h], "Name": "guard_deck"}
The shield faces the lead (LeadRoot - ShadeRoot, flat). The Dasher's aim is Aim - ShadeRoot when given (fixed at Line),
else toward the lead. A body's mask (the frame minus the same frame with that body hidden) lays the body back over what
lies behind it: both bodies over the lane on the street; the lead over the shield when it stands nearer the camera.

The two tells read apart by one rule: the shield is cool (azure: "it's blocking"), the line warm (amber: "it's coming at
you"). Each is one hue with a white core. Neither is a hue effects already carry: the heal's mint, the critical's gold,
Frost's pale cyan, Storm's pink, the plain hit's white, and no violet (alive or for sale only) and nothing red (the
content check's condition on AR52). The shield's cool azure is the mask's warm cream's opposite, so a raised shield reads
apart from the mask (research's condition, AR52, 2026-11-24). Nothing here is Lantern Row's: a Shade fights on every
ground, so no lantern ribs or paper (the grey block's spec drops them).

The Guard (Definitions.Actions, GuardRaise: Raise 0.3 s, Drop 2.3 s; Config.Combat.Guard.Look: 3.4 wide, 3.8 high, 1.6
ahead, 0.4 up). Feel line: a Guard shuts its sleeves and a pane of blue light snaps up before it; your fighter's blows
skate off it, each one lighting the pane where it lands, until a heavy one shatters it open. Its levers, the same frames
in every technique so only the hero shape differs:
- anticipation: the shield grows out of the meeting sleeves over the 8 frames before Raise (Back Out, overshoot 8%);
- punctuation, the click: on Raise its rim flashes and a thin ring snaps off its edge;
- the glance, read where it lands: the pane lights round the contact and a ripple runs out over it, a small white core
  (under 2 studs, no light), and five needles skating back off toward the attacker;
- the break, a release: the pane flashes white and is gone in 2 frames, a ring out from the contact along the blow,
  twelve shards of it flung on along the blow and out, turning and slowing, gone by 20 frames, and a light for 8.
Three hero shapes:
- G1, the pane: a tall pane curved round the Guard's front (a slice of a 3.2-stud cylinder), its corners rounded;
- G2, the ward: a round shield, a flat disc of light 3.8 across held before the chest;
- G3, the wall: an arc of wall rising off the street round the Guard's front, bright at its foot and its top, as the
  Support's veil is a whole column of it (AR58's S2): the Shades' shields one family, each in its owner's hue.

The Dasher (DasherLunge: Line 0.2667 s, Lunge 1.0, Land 1.25; Config.Combat.Dasher.Line: Half 2, and the lunge's Most 12
plus Past 2): the hit takes whoever stands within 2 studs of the line, 14 long, so the lane drawn is that 4 by 14,
truthfully (TR44's question: can the player tell why it hit?). Feel line: a Dasher folds behind its mask's point and a lane
of amber light cuts open along the street to your fighter, filling toward you like a fuse; then it is down the lane in a
streak, and the lane flashes as it lands. The levers: the cut (the lane opens from its feet to its end in 4 frames on
Line), the fuse (a brighter fill from its feet that reaches the end on Land: the time left to move), the lunge's streak
from Lunge, the flash on Land and the close over 6 frames. The same lane is meant for the keeper's slam footprint (TR44,
still grey): one look for "a strike lands here". Two hero shapes:
- D1, the lane: the lane's two edges bright, its far end pointed on past the hit's end, a faint fill, the fuse a brighter
  fill with a bright front across it;
- D2, the chevrons: seven chevrons the lane's width pointing down it, faint from the cut, each lit as the fuse reaches it.

Frames at 60 a second, from Raise (the Guard) and from Line (the Dasher). Every strip's tiles share their stage's one frozen
frame, so the lunge's streak crosses a Dasher still folded at its tell: the strip judges the lane's life, not the body's.
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
OUT = ROOT / "build" / "handoff" / "Shade" / "targets"
UP = np.array([0.0, 1.0, 0.0])

AZURE = hexc("#3F8CFF")  # the shield's light
AZURE_DEEP = hexc("#163C8C")  # laid under it, so the pane holds on the pale deck
AMBER = hexc("#FF9A1F")  # the line's light
AMBER_DEEP = hexc("#7A3A00")  # laid under it
WHITE = hexc("#FFFFFF")

GUARD = {"Wide": 3.4, "High": 3.8, "Ahead": 1.6, "Up": 0.4}  # Config.Combat.Guard.Look
LINE = {"Half": 2.0, "Length": 14.0, "Edge": 0.35}  # Config.Combat.Dasher.Line, the lunge's Most + Past
LAND = 59  # Land after Line, in frames: (1.25 - 0.2667) s
LUNGE = 44  # Lunge after Line


# --- time --------------------------------------------------------------------------------------------------------------
def clamp01(t):
    return min(max(t, 0.0), 1.0)


def life(f, a, b):
    return clamp01((f - a) / (b - a)) if b > a else float(f >= a)


def ease_out(t):
    t = clamp01(t)
    return 1 - (1 - t) ** 3


def back_out(t, over=1.7):
    """Back Out: past 1 and back, the snap."""
    t = clamp01(t) - 1
    return 1 + (over + 1) * t ** 3 + over * t ** 2


def flat(v):
    v = np.array(v, float)
    v[1] = 0
    n = np.linalg.norm(v)
    return v / n if n > 1e-6 else np.array([0.0, 0.0, -1.0])


# --- the stage ---------------------------------------------------------------------------------------------------------
class Stage:
    def __init__(self, path: Path):
        data = json.loads(path.read_text(encoding="utf-8"))
        self.name = data.get("Name", path.stem)
        self.kind = data.get("Kind", "Guard")
        self.picture = (path.parent / data["Picture"]).resolve()
        self.camera = data["Camera"]
        v = {k: np.array(p, float) for k, p in data["Points"].items()}
        self.root, self.chest = v["ShadeRoot"], v["ShadeChest"]
        self.lead_root, self.lead_chest = v["LeadRoot"], v["LeadChest"]
        self.aim = flat((v["Aim"] if "Aim" in v else self.lead_root) - self.root)
        self.side = np.cross(UP, self.aim)
        self.ground = float(data.get("Ground", self.root[1] - 3.0))
        self.base = read_png(self.picture)
        self.crop = data.get("Crop")
        hud = data.get("Hud")
        self.hud = read_png((path.parent / hud).resolve())[..., :1] if hud else None
        self.masks = {k: read_png((path.parent / m).resolve())[..., 0] for k, m in data.get("Masks", {}).items()}

    def frame(self) -> Frame:
        return Frame(self.picture, self.camera, base=self.base)

    def mask(self, *names):
        """The union of the named bodies' masks, or None."""
        out = None
        for n in names:
            m = self.masks.get(n)
            if m is not None:
                out = m if out is None else np.maximum(out, m)
        return out


# --- rays onto surfaces ------------------------------------------------------------------------------------------------
def rays(fr: Frame, sl):
    """Each pixel's ray in the slice: the camera's position and its world direction, scaled so t is the depth."""
    cam = fr.cam
    X, Y = fr.xx[sl], fr.yy[sl]
    local = np.stack([(X - cam.cx) / cam.focal, -(Y - cam.cy) / cam.focal, -np.ones_like(X)], -1).astype(np.float64)
    return cam.pos, local @ cam.rot.T


def region(fr: Frame, pts, pad=24):
    """The frame's slice round a set of world points' projections."""
    xy = np.array([fr.at(p) for p in pts])
    x0, y0 = xy.min(0) - pad
    x1, y1 = xy.max(0) + pad
    x0, x1 = int(max(0, x0)), int(min(fr.w, x1 + 1))
    y0, y1 = int(max(0, y0)), int(min(fr.h, y1 + 1))
    return slice(y0, max(y0, y1)), slice(x0, max(x0, x1))


def on_plane(fr, sl, origin, U, V):
    """Where each pixel's ray meets the plane through origin spanned by U and V: (u, v, depth, ray·normal)."""
    pos, d = rays(fr, sl)
    N = np.cross(U, V)
    dn = d @ N
    t = ((origin - pos) @ N) / np.where(np.abs(dn) < 1e-9, 1e-9, dn)
    P = pos + d * t[..., None]
    rel = P - origin
    return rel @ U, rel @ V, t, dn / np.linalg.norm(d, axis=-1)


def on_cylinder(fr, sl, centre, radius, facing):
    """A vertical cylinder's two hits, near and far: (arc length from `facing`, height, depth, cos to the normal)."""
    pos, d = rays(fr, sl)
    o = (pos - centre)[[0, 2]]
    dx, dz = d[..., 0], d[..., 2]
    a = dx * dx + dz * dz
    b = 2 * (o[0] * dx + o[1] * dz)
    c = o @ o - radius * radius
    disc = b * b - 4 * a * c
    ok = disc > 0
    sq = np.sqrt(np.where(ok, disc, 0))
    face = math.atan2(facing[2], facing[0])
    out = []
    for sign in (-1, 1):
        t = (-b + sign * sq) / (2 * np.where(a < 1e-12, 1e-12, a))
        P = pos + d * t[..., None]
        nx, nz = (P[..., 0] - centre[0]) / radius, (P[..., 2] - centre[2]) / radius
        ang = np.arctan2(nz, nx) - face
        ang = (ang + math.pi) % (2 * math.pi) - math.pi
        cos = np.abs(nx * dx + nz * dz) / np.linalg.norm(d, axis=-1)
        out.append((ang * radius, P[..., 1], np.where(ok & (t > 0), t, np.inf), cos))
    return out


def soft(sd, aa):
    """Inside-ness of a signed distance (negative inside), anti-aliased over aa studs."""
    return np.clip(0.5 - sd / np.maximum(aa, 1e-4), 0, 1)


def band(sd, w):
    """A band of light on an edge: 1 on it, fading over w either side."""
    return np.exp(-(sd / max(w, 1e-4)) ** 2)


def rounded_rect(u, v, hu, hv, r):
    q = np.stack([np.abs(u) - hu + r, np.abs(v) - hv + r], -1)
    return np.linalg.norm(np.maximum(q, 0), axis=-1) + np.minimum(np.maximum(q[..., 0], q[..., 1]), 0) - r


def seg_dist(u, v, a, b):
    pa = np.stack([u - a[0], v - a[1]], -1)
    ba = np.array(b, float) - np.array(a, float)
    h = np.clip((pa @ ba) / (ba @ ba), 0, 1)
    return np.linalg.norm(pa - h[..., None] * ba, axis=-1)


def paint(fr: Frame, sl, inside, light, colour, deep, fill, occ):
    """A surface's light and its laid colour, under the bodies in `occ` (a mask of the whole frame)."""
    keep = 1.0 if occ is None else 1 - occ[sl]
    fr.lay(sl, inside * fill * keep, deep, 1.0)
    fr.add(sl, light * keep, colour, 1.0)


# --- the Guard ---------------------------------------------------------------------------------------------------------
def guard_state(f):
    """The shield's size and strength at frame f from Raise; glances and the break are laid on by the caller."""
    if f < -8:
        return 0.0, 0.0
    grow = back_out(life(f, -8, 0))
    return max(grow, 0.0), min(1.0, life(f, -8, -3) + 0.2)


def glance_light(s, h, g, s0, h0):
    """The pane round a glance's contact g frames after it: a lit patch, and a ripple running out over the surface."""
    if g is None or g < 0 or g > 14:
        return 0.0
    ds, dh = s - s0, h - h0
    dist = np.hypot(ds, dh)
    patch = np.exp(-(dist / 0.45) ** 2) * (1 - life(g, 0, 10)) * 3.2
    # the burst: short rays of light running out over the surface from the contact, eight of them, gone by 8 frames
    ang = np.arctan2(dh, ds)
    rays_ = np.cos(ang * 4) ** 16 + 0.6 * np.cos(ang * 4 + math.pi / 4) ** 24
    reach = 0.5 + 0.9 * ease_out(g / 5)
    burst = rays_ * np.exp(-(dist / reach) ** 2) * (1 - life(g, 0, 8)) * 2.6
    r = 0.4 + 1.8 * ease_out(g / 12)
    ripple = np.exp(-((dist - r) / 0.09) ** 2) * (1 - life(g, 1, 12)) * 0.6 * float(g >= 2)
    return patch + burst + ripple


def shield_shade(sd, s, h, cos, f, grow, strength, glance, flash, aa):
    """One look for the three shapes: a thin deep fill, the surface brighter where it turns away (its fresnel), a rim with
    a white core, a soft sheen across, the click on Raise, a glance's light, the break's white flash."""
    inside = soft(sd, aa)
    fres = np.clip(1 - cos, 0, 1) ** 1.5
    click = 1 + 1.6 * (1 - life(f, 0, 5)) * float(f >= 0)
    rim = band(np.maximum(sd, -10) + 0.06, 0.07) * 2.6 * click + band(sd + 0.12, 0.28) * 0.7 * click
    sheen = np.exp(-(((s * 0.8 + h * 0.6) - 0.6) / 0.35) ** 2) * 0.35
    body = inside * (0.16 + 0.55 * fres + sheen)
    light = (body + rim * (sd > -0.6)) * strength
    if glance is not None:
        light = light + inside * glance_light(s, h, *glance)
    light = light * (1 + 3.5 * flash)
    return inside * strength, light


def draw_guard(fr: Frame, st: Stage, f, shape, glance_at=None, break_at=None):
    grow, strength = guard_state(f)
    broken = break_at is not None and f >= break_at
    flash = 0.0
    if broken:  # one white frame, then the pane bursts outward as it goes, its rim the last of it
        b = f - break_at
        flash = 0.45 if b == 0 else 0.0
        if 1 <= b < 4:
            grow, strength = 1 + 0.07 * b, 0.75 * (1 - b / 4)
        elif b >= 4:
            grow = 0.0
    if grow <= 0 or strength <= 0:
        return
    G = GUARD
    occ = st.mask("Lead") if lead_nearer(fr, st) else None
    glance = None
    centre = st.root + st.aim * G["Ahead"] + UP * G["Up"]
    if glance_at is not None and f >= glance_at and not broken:
        glance = [f - glance_at, 0.25, contact(st, shape)[1]]  # its height made the surface's own below
    hw, hh = G["Wide"] / 2 * grow, G["High"] / 2 * grow
    if shape == "G2_ward":
        R = 1.9 * grow
        sl = region(fr, [centre + st.side * R * sx + UP * R * sy for sx in (-1, 1) for sy in (-1, 1)])
        u, v, t, cos = on_plane(fr, sl, centre + UP * 0.3, st.side, UP)
        if glance is not None:
            glance[2] -= centre[1] + 0.3
        cos = np.abs(cos)
        aa = t / fr.cam.focal * 1.2
        sd = np.hypot(u, v) - R
        inside, light = shield_shade(sd, u, v, cos, f, grow, strength, glance, flash, aa)
        dome = np.clip(1 - np.hypot(u, v) / max(R, 1e-3), 0, 1)  # a flat disc lit as a boss: brighter to its middle
        light = light + soft(sd, aa) * (0.28 + 0.5 * dome ** 2) * strength * (1 + 3.5 * flash)
        inside = np.where(t > 0, inside, 0)
        paint(fr, sl, inside, np.where(t > 0, light, 0), AZURE, AZURE_DEEP, 0.32, occ)
    else:
        if shape == "G1_pane":
            R = 3.2
            axis = st.root + st.aim * (G["Ahead"] - R)
            yc, top, bottom = centre[1], hh, -hh
        else:  # G3_wall: off the street round the Guard's front, its top above the head
            R = G["Ahead"] + 0.2
            axis = st.root.copy()
            hw = R * math.radians(68) * grow
            foot, height = st.ground, (st.chest[1] - st.ground + 1.9) * grow
            yc, top, bottom = foot + height / 2, height / 2, -height / 2
        if glance is not None:
            glance[2] -= yc
        span = [axis + R * (math.cos(a) * np.array([1, 0, 0]) + math.sin(a) * np.array([0, 0, 1])) + UP * (yc - axis[1] + dy)
                for a in np.linspace(math.atan2(st.aim[2], st.aim[0]) - hw / R, math.atan2(st.aim[2], st.aim[0]) + hw / R, 9)
                for dy in (top, bottom)]
        sl = region(fr, span)
        hits = on_cylinder(fr, sl, axis, R, st.aim)
        insides, lights = [], []
        for s, y, t, cos in hits:
            h = y - yc
            aa = np.where(np.isfinite(t), t, 1e3) / fr.cam.focal * 1.2
            if shape == "G1_pane":
                sd = rounded_rect(s, h, hw, hh, 0.7 * grow)
                inside, light = shield_shade(sd, s, h, cos, f, grow, strength, glance, flash, aa)
            else:
                sd_side = np.abs(s) - hw
                sd = np.maximum(sd_side, np.abs(h) - top)
                inside, light = shield_shade(sd, s, h, cos, f, grow, strength, glance, flash, aa)
                rise = np.clip((h - bottom) / (top - bottom), 0, 1)
                edges = np.clip(1 - np.maximum(sd_side + 0.8, 0) / 0.8, 0, 1)  # the arc's ends fade out, no hard side
                foot_rim = band(h - bottom - 0.06, 0.09) * 2.4 + band(h - bottom, 0.4) * 0.6
                top_rim = band(h - top + 0.06, 0.08) * 1.8
                body = (0.6 - 0.55 * rise) * soft(sd, aa)
                light = (light * 0.45 + (foot_rim * (np.abs(h - bottom) < 0.8) + top_rim + body * 0.6) * strength) * edges
                inside = inside * (0.55 - 0.45 * rise) * edges
            ok = np.isfinite(t)
            insides.append(np.where(ok, inside, 0))
            lights.append(np.where(ok, light, 0) * (1.0 if not insides[:-1] else 0.55))  # the far side, seen through
        paint(fr, sl, np.clip(insides[0] + insides[1] * 0.5, 0, 1), lights[0] + lights[1], AZURE, AZURE_DEEP, 0.3, occ)
    if glance is not None and glance[0] <= 8:
        glance_free(fr, st, glance[0], shape)


def contact(st: Stage, shape):
    """Where a blow from the lead meets the shield, about chest high."""
    ahead = GUARD["Ahead"] if shape != "G3_wall" else GUARD["Ahead"] + 0.2
    return st.root + st.aim * ahead + UP * (GUARD["Up"] + 0.35) + st.side * 0.25


def glance_free(fr: Frame, st: Stage, g, shape):
    """A glance's free light, over everything: a small white core and five needles skating back toward the attacker."""
    p = contact(st, shape)
    k = 1 - life(g, 0, 6)
    fr.core(p, 0.16 * (1 + 0.5 * life(g, 0, 2)), AZURE, 3.2 * k)
    rng = np.random.default_rng(7)
    for i in range(5):
        a = math.radians(-50 + 25 * i + rng.uniform(-6, 6))
        d = st.aim * math.cos(a) + st.side * math.sin(a)
        d = d + UP * rng.uniform(0.1, 0.5)
        d /= np.linalg.norm(d)
        reach = 0.4 + 1.6 * ease_out(life(g, 0, 7))
        head = p + d * reach
        tail = p + d * max(reach - 0.9, 0.15)
        fr.streak(tail, head, 0.07, 0.02, AZURE, 2.2 * (1 - life(g, 3, 8)))


def draw_break(fr: Frame, st: Stage, b, shape):
    """b frames after the break: a ring out from the contact along the blow, twelve shards flung on and out, a light."""
    if b < 0 or b > 22:
        return
    p = contact(st, shape)
    if b <= 8:
        fr.glow(p, 2.6, AZURE, 0.5 * (1 - life(b, 0, 8)))
        fr.core(p, 0.3, WHITE, 2.4 * (1 - life(b, 0, 4)))
    rng = np.random.default_rng(11)
    for i in range(12):
        # from the pane's two sides, outward past the body and up, never into it (the content check's condition 3)
        sign = 1 if i % 2 else -1
        s0, h0 = sign * rng.uniform(0.7, 1.7), rng.uniform(-1.6, 1.6)
        start = st.root + st.aim * GUARD["Ahead"] + UP * (GUARD["Up"] + h0) + st.side * s0
        out = st.side * sign * rng.uniform(0.6, 1.0) + UP * (0.9 + h0 * 0.3) + st.aim * rng.uniform(0.3, 0.8)
        out /= np.linalg.norm(out)
        speed = rng.uniform(16, 24)  # studs a second at the break, Drag 3: well clear of the body before they slow
        travel = (1 - math.exp(-3 * b / 60)) / 3
        pos = start + out * speed * travel
        k = 1 - life(b, 6, 14)
        size = rng.uniform(0.22, 0.42) * (1 - 0.4 * life(b, 0, 14))
        spin = rng.uniform(0, math.pi) + b * rng.uniform(0.15, 0.35)
        a = st.side * math.cos(spin) + UP * math.sin(spin)  # a sliver of the pane, turning
        fr.streak(pos - a * size, pos + a * size, 0.2 * size / 0.3, 0.03, AZURE, 2.0 * k, soft=0.5)
        fr.streak(pos - a * size * 0.6, pos + a * size * 0.8, 0.06, 0.01, WHITE, 1.4 * k, soft=0.5)
        fr.glow(pos, size * 0.5, AZURE, 0.5 * k)


def lead_nearer(fr: Frame, st: Stage):
    return fr.cam.project(st.lead_chest)[1] < fr.cam.project(st.root + st.aim * GUARD["Ahead"])[1]


# --- the Dasher --------------------------------------------------------------------------------------------------------
def draw_line(fr: Frame, st: Stage, f, shape):
    if f < 0 or f > LAND + 8:
        return
    L, half = LINE["Length"], LINE["Half"]
    tip = 1.2  # the point, on past the hit's end
    cut = ease_out(life(f, 0, 4))
    reach = (L + tip) * cut
    fuse = L * life(f, 0, LAND)  # linear: the honest timer
    landed = f >= LAND
    close = 1 - life(f, LAND, LAND + 6)
    flash = 0.7 if LAND <= f < LAND + 2 else 0.0
    feet = np.array([st.root[0], st.ground + 0.04, st.root[2]])
    corners = [feet + st.side * sx * half * 1.2 + st.aim * va for sx in (-1, 1) for va in (-0.5, L + tip + 0.5)]
    sl = region(fr, corners)
    u, v, t, cos = on_plane(fr, sl, feet, st.side, st.aim)  # u across, v along
    ok = t > 0
    aa = np.where(ok, t, 1e3) / fr.cam.focal * 1.3
    occ = st.mask("Lead", "Shade")
    width = half * (0.25 + 0.75 * ease_out(life(f, 1, 5)))
    inside_len = soft(v - reach, aa) * soft(-v, aa)
    strength = close * (1 + flash)
    if shape == "D1_lane":
        body_w = np.where(v > L, width * np.clip((L + tip - v) / tip, 0, 1), width)  # the point
        sd = np.maximum(np.abs(u) - body_w, -v)
        sd = np.maximum(sd, v - reach)
        inside = soft(sd, aa)
        edge = band(np.abs(u) - body_w, 0.06) * 3.0 + band(np.abs(u) - body_w, 0.22) * 0.8
        edge = edge * inside_len * soft(-(v - 0.6), 0.6)  # the edges start a little out of its feet
        tipglow = band(v - L - tip * 0.98, 0.08) * 0
        filled = soft(v - fuse, aa) * inside
        front = band(v - fuse, 0.10) * 2.4 * soft(np.abs(u) - body_w, aa) * float(not landed) * float(f > 2)
        light = inside * 0.22 + filled * 0.55 + edge + front + tipglow
        laid = inside * 0.22 + filled * 0.18
    else:  # D2_chevrons
        light = np.zeros_like(u)
        laid = np.zeros_like(u)
        for i in range(7):
            vc = 1.2 + i * 2.0
            if vc > reach:
                continue
            arm = [(-width, vc - 1.1), (0.0, vc + 0.25), (width, vc - 1.1)]
            d = np.minimum(seg_dist(u, v, arm[0], arm[1]), seg_dist(u, v, arm[1], arm[2]))
            sd = d - 0.24
            lit = 1.0 if fuse >= vc - 0.6 or landed else 0.0
            shape_in = soft(sd, aa)
            light = light + shape_in * (0.35 + 1.0 * lit) + band(d, 0.06) * (0.6 + 2.2 * lit)
            laid = laid + shape_in * (0.25 + 0.2 * lit)
        edge_hint = band(np.abs(u) - width, 0.05) * 0.5 * soft(v - reach, aa) * soft(-v, aa)
        light = light + edge_hint
    light = np.where(ok, light * strength, 0)
    laid = np.where(ok, np.clip(laid, 0, 1) * close, 0)
    paint(fr, sl, laid, light, AMBER, AMBER_DEEP, 1.0, occ)
    # the lunge: a streak from Lunge to Land, its head down the lane at chest height
    if LUNGE <= f <= LAND + 4:
        g = life(f, LUNGE, LAND)
        chest = st.chest[1] - st.ground
        head = feet + st.aim * (12 * g) + UP * chest
        tail = feet + st.aim * max(12 * g - 5.5, 0) + UP * chest
        k = 1 - life(f, LAND, LAND + 4)
        fr.streak(tail, head, 0.05, 0.55, AMBER, 1.6 * k)
        fr.streak(tail, head, 0.02, 0.18, WHITE, 1.6 * k)
    if LAND <= f <= LAND + 6:
        g = f - LAND
        p = feet + st.aim * 12 + UP * (st.chest[1] - st.ground)
        fr.core(p, 0.3, AMBER, 3.0 * (1 - life(g, 0, 5)))
        fr.spikes(p, 7, 1.6 * (0.5 + 0.5 * ease_out(g / 4)), 0.12, AMBER, 1.8 * (1 - life(g, 1, 6)), seed=3, up=0.2)


# --- the targets -------------------------------------------------------------------------------------------------------
GLANCE, BREAK = 40, 70  # the strip's glance and break, frames from Raise
TARGETS = {
    "G1_pane": ("Guard", GLANCE + 1, [-6, -3, 0, 3, GLANCE, GLANCE + 2, GLANCE + 6], [BREAK + b for b in (0, 1, 3, 8, 16)]),
    "G2_ward": ("Guard", GLANCE + 1, [-6, -3, 0, 3, GLANCE, GLANCE + 2, GLANCE + 6], [BREAK + b for b in (0, 1, 3, 8, 16)]),
    "G3_wall": ("Guard", GLANCE + 1, [-6, -3, 0, 3, GLANCE, GLANCE + 2, GLANCE + 6], [BREAK + b for b in (0, 1, 3, 8, 16)]),
    "D1_lane": ("Dasher", 30, [0, 2, 4, 20, 40, LUNGE + 7, LAND, LAND + 3], []),
    "D2_chevrons": ("Dasher", 30, [0, 2, 4, 20, 40, LUNGE + 7, LAND, LAND + 3], []),
}


def render(st: Stage, name, f, broken=False):
    kind = TARGETS[name][0]
    fr = st.frame()
    if kind == "Guard":
        draw_guard(fr, st, f, name, glance_at=GLANCE, break_at=BREAK if broken else None)
        if broken:
            draw_break(fr, st, f - BREAK, name)
    else:
        draw_line(fr, st, f, name)
    out = fr.render()
    return out if st.hud is None else out * (1 - st.hud) + st.base * st.hud


def crop(img, box):
    if not box:
        return img
    x, y, w, h = box
    return img[y:y + h, x:x + w]


def main(argv):
    st = Stage(Path(argv[0]))
    out = Path(argv[1]) if len(argv) > 1 else OUT
    only = argv[2].split(",") if len(argv) > 2 else None
    out.mkdir(parents=True, exist_ok=True)
    peaks, names = [], []
    for name, (kind, peak, times, breaks) in TARGETS.items():
        if (only and name not in only) or (not only and kind != st.kind):
            continue
        path = out / f"{name}_{st.name}_peak.png"
        write_png(render(st, name, peak), path)
        peaks.append(path)
        names.append(f"{name} ({st.name}, frame {peak})")
        strip([crop(render(st, name, f), st.crop) for f in times], out / f"{name}_{st.name}_strip.png")
        note = f"frames from {'Raise' if kind == 'Guard' else 'Line'}, at 60 a second: " + ", ".join(map(str, times)) + "\n"
        if breaks:
            strip([crop(render(st, name, f, broken=True), st.crop) for f in breaks], out / f"{name}_{st.name}_break.png")
            note += f"{name}_{st.name}_break.png: a heavy hit breaks it at frame {BREAK}: " + ", ".join(map(str, breaks)) + "\n"
        (out / f"{name}_{st.name}_strip.txt").write_text(note, encoding="utf-8")
        print(name, st.name, "peak", peak)
    if peaks:
        sheet = out / f"phone_{st.name}"
        sheet.mkdir(exist_ok=True)
        phone_sheets(peaks, sheet, names)


if __name__ == "__main__":
    main(sys.argv[1:])
