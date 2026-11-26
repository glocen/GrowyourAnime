"""AR7's targets: the Lamplighter's swing and challenge, painted over frames of the game, for research's pick in pairs
(AGENTS.md, "Every action, world, effect and screen"). Scintilla's.

    py tools/fx/keeper_targets.py <stage.json> [out_dir] [S4_smear,S5_lantern_arc,S6_echoes | C3_pulse,C4_wide_ring]
    (default out: build/handoff/Lamplighter/targets; default: the move's own targets, by the stage's Move)

A stage, written at the capture (the keeper held on its move's beat, Strike or Stamp, as shade_targets.py's):
    {"Picture": "<held frame>.png", "Camera": {...}, "Kind": "Keeper", "Move": "swing"|"challenge",
     "Points": {"ShadeRoot", "ShadeChest", "LeadRoot", "LeadChest"}, "Ground": y,
     "Paths": {"PoleFoot": [[f, x, y, z], ...], "Lantern": [...]},   (f: frames from the held beat, at 60 a second)
     "Steps": [f, ...], "Tiles": {"<f>": "<frame>.png"},             (the keeper's own pose at each strip frame)
     "Masks": {"Lead": ..., "Shade": ...}, "Hud": ..., "Crop": [x, y, w, h], "Name": ...}
Each strip tile is drawn over the keeper's pose at its own frame; the lead, held at Rook's Hit3, lies over what's
behind it in every tile (its mask). The keeper's own body isn't laid back: where the foot passes behind its hip in the
draw-back, the light draws over it, a limit of these targets.

The keeper's light is its lantern's: warm white, the kit's Warm palette, the family of its signature (KeeperSignature's
Paper glow and its column). One hue, a white core. Nothing red, nothing left behind on the street.

The pole's foot is hidden. From the game's camera (behind your fighter, the keeper beyond), the foot stays behind your
fighter's back through both moves: 11.7 studs deep at Strike, your fighter at 10.7, and the stamp lands behind its legs.
So the first targets, drawn at the foot (a sweep, a cut, a ring and rays), showed nothing but the lantern. These are
drawn where the camera sees the keeper's light: the pole's upper shaft, over your fighter's shoulder, and the lantern.
The shaft runs from PoleFoot to HookTip, both points on the pole. The stage samples only the foot and the lantern, so
the hook is solved here from the clip's joints (R6's root and shoulder, the pole's motor at its grip, the recipe's
points), placed in the world by the yaw and offset that fit the sampled foot; the lantern's sampled path, which the fit
never sees, checks it (pole_path).

The swing (Definitions.Actions, KeeperSwing: Strike 0.8 s, Recover 1.0 s). Feel line: the keeper draws its pole back
past its hip like a lance, then sweeps it round and across at your fighter's chest, the lantern flung wide behind its
shoulder. Levers: anticipation (the light grows into the blow), weight (the lantern's lag), punctuation (the blow's
frame). Seen: the hook end sweeps about 120 px over the last four frames, and the lantern is flung about 240 px, the
biggest motion on the screen.
- S4, the smear: the shaft swept into a sheet of light over its last five frames, the leading edge a white line along
  the shaft, the sheet brightest at the hook end where it moves fastest and fading back to its tail. At Strike the
  shaft points nearly into the camera, so the sheet trails it through the follow-through, where it sweeps widest on
  the screen, to frame 8, and is gone by 12. Through the hold before it the upper shaft gathers a glint.
- S5, the lantern's arc (research's pick, redrawn once): the lantern's own swing drawn as a comet over its whole path
  from the hold (frame -8), widest at the lantern and a third as wide at its tail, the deep warm laid under it and a
  white core down it, so the arc itself is the read; the flare lands as its end on Strike and holds three frames, the
  shaft glints along its length, and the tail catches up from frame 4, gone by 12.

The challenge (KeeperChallenge: Lift 0.7333 s, Stamp 0.9667 s). Feel line: it hears you, lifts its face to you, and
stamps its pole once. Both flare the lantern on Lift (it notices you), so only the stamp's read differs:
- C3, the pulse: on Stamp a bead of light runs up the shaft from where it shows over your fighter's shoulder into the
  lantern in four frames, and the lantern bursts: a flash and a ring of light round it, facing the camera.
- C4, the wide ring (research's pick, with its must-fix): on Stamp a band of light runs out over the street from the
  pole's foot to ten studs, the deep warm laid under it and a faint fill inside it, so it reads all the way round past
  your fighter (7.6 studs at its peak), a fainter one a breath behind it; the lantern jolts brighter.

The stage's lead is laid back over the light from its own picture (sRGB), and the HUD from the backdrop, so a tile
taken while the HUD faded shows it whole. The keeper's own body isn't laid back: where light lies behind it, it draws
over it, a limit of these targets.
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from paintover import Frame, blur, hexc, linear_to_srgb, phone_sheets, read_png, strip, write_png  # noqa: E402
from shade_targets import Stage, crop, ease_out, life  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "handoff" / "Lamplighter" / "targets"

WARM = hexc("#FFC98A")  # FxKit.Palettes.Warm's Deep: the light's hue
WARM_MID = hexc("#FFEBC2")  # its Mid: the core's edge
WHITE = hexc("#FFF6E8")  # its core, a warm white

TARGETS = {  # name: (move, peak frame, strip frames)
    "S4_smear": ("swing", 2, [-8, -6, -4, -2, 0, 2, 4, 8, 12]),
    "S5_lantern_arc": ("swing", 2, [-8, -6, -4, -2, 0, 2, 4, 8, 12]),
    "S6_echoes": ("swing", 2, [-8, -6, -4, -2, 0, 2, 4, 8, 12]),
    "C3_pulse": ("challenge", 6, [-16, -14, -10, -4, 0, 2, 4, 8, 12]),
    "C4_wide_ring": ("challenge", 8, [-16, -14, -10, -4, 0, 2, 4, 8, 12]),
}
LIFT = -14  # the challenge's Lift, in frames from Stamp
HOLD = -8  # the swing's hold ends here, in frames from Strike: the lantern starts to move (0.03 studs a frame before)
WARM_DEEP = hexc("#7A4A12")  # the warm laid under the light, so it holds on the pale street and sky
DEEP_INK = 0.4  # its opacity at full strength
RING_BAND = 0.55  # C4's band, in studs inside its radius
RING_FILL = 0.22  # C4's fill at the band's inner edge, from nothing at its centre
RING_REACH = 10.0  # C4's last radius, in studs: at its peak (frame 8) 7.6, its right arc clear of your fighter
SHOWN = 0.45  # the share of the shaft from its foot above which it shows over your fighter's shoulder
SMEAR_FROM = 0.25  # S4's sheet is drawn from here up: below SHOWN, your fighter's own picture covers it where it should
CLIPS = ROOT / "build" / "handoff" / "Lamplighter" / "clips"
RECIPE = ROOT / "build" / "handoff" / "Lamplighter" / "Lamplighter.recipe.json"
BEAT = {"swing": ("Swing", "Strike"), "challenge": ("Challenge", "Stamp")}  # each move's clip and its held beat


# --- the pole's hook, solved from the clip ------------------------------------------------------------------------------
def _cf(c):
    m = np.eye(4)
    m[:3, 3] = c[:3]
    m[:3, :3] = np.array(c[3:12], float).reshape(3, 3)
    return m


def _at(x, y, z):
    m = np.eye(4)
    m[:3, 3] = (x, y, z)
    return m


_ROOT_JOINT = _cf([0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0])  # R6's RootJoint, its C0 and C1 alike
_SHOULDER_C0 = _cf([1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0])  # R6's Right Shoulder
_SHOULDER_C1 = _cf([-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0])


def pole_path(move, foot, lantern):
    """HookTip's path over the foot's frames, in the world: the recipe's points carried through the clip's joints (R6's
    root and right shoulder, then the pole's motor at its grip, whose C0 and C1 are the grip's place: ModelRecipe), in
    the model's own space, then placed by the yaw, scale and offset that best fit the sampled foot. Returns the path and
    the lantern's error against its sampled path (studs, mean and most), which the fit never sees."""
    clip_name, beat = BEAT[move]
    clip = json.loads((CLIPS / f"Lamplighter_{clip_name}.json").read_text(encoding="utf-8"))
    held = next(m["T"] for m in clip["Markers"] if m["Name"] == beat)
    poses = {round(fr["T"] * 60): fr["Poses"] for fr in clip["Frames"]}
    recipe = json.loads(RECIPE.read_text(encoding="utf-8"))
    points = {q["name"]: np.array(q["at"] + [1.0]) for q in recipe["points"]}
    pivot = {q["motor"]: _at(*q["pivot"]) for q in recipe["pieces"] if q.get("motor")}
    inv = np.linalg.inv
    hrp = _at(0, 3, 0)
    arm_rest = hrp @ _SHOULDER_C0 @ inv(_SHOULDER_C1)
    model = {"PoleFoot": [], "HookTip": [], "Lantern": []}
    for f in foot[:, 0]:
        pose = poses[round(held * 60 + f)]
        torso = hrp @ _ROOT_JOINT @ _cf(pose["Torso"]) @ inv(_ROOT_JOINT)
        arm = torso @ _SHOULDER_C0 @ _cf(pose["Right Arm"]) @ inv(_SHOULDER_C1)
        pole = arm @ inv(arm_rest) @ pivot["Pole"] @ _cf(pose["Lamplighter_Pole"]) @ inv(pivot["Pole"])
        lamp = pole @ pivot["Lantern"] @ _cf(pose["Lamplighter_Lantern"]) @ inv(pivot["Lantern"])
        model["PoleFoot"].append((pole @ points["PoleFoot"])[:3])
        model["HookTip"].append((pole @ points["HookTip"])[:3])
        model["Lantern"].append((lamp @ points["Lantern"])[:3])
    a, b = np.array(model["PoleFoot"]), foot[:, 1:]
    best = None
    for yaw in np.radians(np.arange(0, 360, 0.05)):
        rot = np.array([[math.cos(yaw), 0, math.sin(yaw)], [0, 1, 0], [-math.sin(yaw), 0, math.cos(yaw)]])
        q = a @ rot.T
        qc, bc = q - q.mean(0), b - b.mean(0)
        scale = float((qc * bc).sum() / (qc * qc).sum())
        shift = b.mean(0) - scale * q.mean(0)
        err = float(np.linalg.norm(scale * q + shift - b, axis=1).mean())
        if best is None or err < best[0]:
            best = (err, rot, scale, shift)
    _, rot, scale, shift = best
    place = {k: scale * (np.array(v) @ rot.T) + shift for k, v in model.items()}
    miss = np.linalg.norm(place["Lantern"] - lantern[:, 1:], axis=1)
    return np.column_stack([foot[:, 0], place["HookTip"]]), (float(miss.mean()), float(miss.max()))


class KeeperStage(Stage):
    def __init__(self, path: Path):
        super().__init__(path)
        data = json.loads(path.read_text(encoding="utf-8"))
        self.move = data.get("Move", "swing")
        self.paths = {k: np.array(v, float) for k, v in data.get("Paths", {}).items() if v}
        self.tiles = {int(k): (path.parent / v).resolve() for k, v in data.get("Tiles", {}).items()}
        if "HookTip" not in self.paths:
            self.paths["HookTip"], miss = pole_path(self.move, self.paths["PoleFoot"], self.paths["Lantern"])
            print(f"{self.name}: HookTip solved from the clip; the lantern's check {miss[0]:.3f} studs mean, {miss[1]:.3f} most")
            assert miss[1] < 0.05, "the solved pole misses the sampled lantern: the clip or the recipe isn't the stage's"

    def point(self, name, f):
        """Where a sampled point is at frame f, between samples by line; held at the path's ends."""
        p = self.paths[name]
        f = min(max(f, p[0, 0]), p[-1, 0])
        return np.array([np.interp(f, p[:, 0], p[:, c]) for c in (1, 2, 3)])

    def shaft(self, f, u):
        """The point a share u of the way up the pole from its foot to its hook, at frame f."""
        return self.point("PoleFoot", f) + u * (self.point("HookTip", f) - self.point("PoleFoot", f))

    def frame_at(self, f) -> Frame:
        tile = self.tiles.get(f)
        if tile is None or f == 0:
            return self.frame()
        return Frame(tile, self.camera, base=read_png(tile))


def arc(fr: Frame, pts, head_width, colour, k):
    """The comet along pts (oldest first), its whole length kept readable: widest at its head and a third as wide at its
    tail, the deep warm laid under it so it holds over the pale sky and street, a white core down it."""
    n = len(pts)
    widths = [head_width * (0.3 + 0.7 * (i / (n - 1)) ** 0.8) for i in range(n)]
    for i in range(n - 1):
        t = (i + 1) / (n - 1)
        fr.streak(pts[i], pts[i + 1], widths[i] * 0.8, widths[i + 1] * 0.8, WARM_DEEP, soft=0.7,
                  ink=DEEP_INK * (0.5 + 0.5 * t))
    for i in range(n - 1):
        t = (i + 1) / (n - 1)
        fr.streak(pts[i], pts[i + 1], widths[i], widths[i + 1], colour, k * (0.45 + 0.55 * t), soft=0.7)
        fr.streak(pts[i], pts[i + 1], widths[i] * 0.3, widths[i + 1] * 0.3, WHITE, k * 1.1 * (0.3 + 0.7 * t), soft=0.5)


def ground_ring(fr: Frame, centre, radius, band, k, steps=72, fills=5):
    """A ring on the street round centre, as a field of the whole frame: `band` studs wide inside its radius at k, and a
    faint fill inside it rising toward the band (RING_FILL at its edge)."""
    field = np.zeros((fr.h, fr.w), np.float32)
    edges = list(np.linspace(0, radius - band, fills + 1)) + [radius]
    values = [RING_FILL * k * ((a + b) / 2 / radius) ** 2 for a, b in zip(edges[:-2], edges[1:-1])] + [k]
    turn = np.linspace(0, 2 * math.pi, steps + 1)
    for (a, b), v in zip(zip(edges[:-1], edges[1:]), values):
        for t0, t1 in zip(turn[:-1], turn[1:]):
            d0, d1 = np.array([math.cos(t0), 0, math.sin(t0)]), np.array([math.cos(t1), 0, math.sin(t1)])
            quad(fr, [centre + a * d0, centre + b * d0, centre + b * d1, centre + a * d1], v, field)
    return field


def path_pts(st: KeeperStage, name, a, b, step=0.5):
    if b <= a:
        return []
    return [st.point(name, x) for x in np.arange(a, b + 1e-6, step)]


def quad(fr: Frame, corners, value, field):
    """Lays `value` into `field` (the whole frame's) inside a convex quad of world points; the last laid wins."""
    xy = np.array([fr.at(c) for c in corners])
    x0, y0 = np.floor(xy.min(0)).astype(int) - 1
    x1, y1 = np.ceil(xy.max(0)).astype(int) + 2
    x0, y0, x1, y1 = max(x0, 0), max(y0, 0), min(x1, fr.w), min(y1, fr.h)
    if x1 <= x0 or y1 <= y0:
        return
    X, Y = fr.xx[y0:y1, x0:x1] + 0.5, fr.yy[y0:y1, x0:x1] + 0.5
    area = sum(xy[i][0] * xy[(i + 1) % 4][1] - xy[(i + 1) % 4][0] * xy[i][1] for i in range(4))
    sign = 1.0 if area >= 0 else -1.0
    inside = np.ones(X.shape, bool)
    for i in range(4):
        (ax, ay), (bx, by) = xy[i], xy[(i + 1) % 4]
        inside &= ((bx - ax) * (Y - ay) - (by - ay) * (X - ax)) * sign >= 0
    field[y0:y1, x0:x1][inside] = value


def draw_swing(fr: Frame, st: KeeperStage, f, shape):
    grow = ease_out(life(f, -8, -1))  # the light grows into the blow
    if shape == "S4_smear":
        if f < 0:  # the hold before it: a glint gathers along the upper shaft
            fr.streak(st.shaft(f, SHOWN), st.shaft(f, 1.0), 0.05, 0.09, WARM, 1.1 * grow, soft=0.6)
        # The pole turns mostly in depth (11.7 to 19.2 studs deep at Strike), so its hook end sweeps only some 120 px
        # from the hold to the blow: the sheet spans that whole arc, from the hold's end (frame -8), as an anime smear
        # exaggerates its sweep; it trails the pole into the follow-through to frame 8, its tail catching up, gone by 12.
        head = min(f, 8)
        tail = max(-8.0, head - 10) + life(f, 4, 12) * 10
        fade = 1 - life(f, 6, 12)
        if f >= -6 and head > tail and fade > 0:
            sheet = np.zeros((fr.h, fr.w), np.float32)
            slices = max(2, int((head - tail) / 0.25))
            ts = np.linspace(tail, head, slices + 1)
            bands = np.linspace(SMEAR_FROM, 1.0, 9)
            for i in range(slices):
                age = (i + 1) / slices  # 1 at the leading edge
                for j in range(len(bands) - 1):
                    reach = (bands[j + 1] - SMEAR_FROM) / (1 - SMEAR_FROM)  # brightest at the hook end, the fastest
                    quad(fr, [st.shaft(ts[i], bands[j]), st.shaft(ts[i], bands[j + 1]),
                              st.shaft(ts[i + 1], bands[j + 1]), st.shaft(ts[i + 1], bands[j])],
                         age ** 1.4 * (0.2 + 0.8 * reach), sheet)
            whole = (slice(0, fr.h), slice(0, fr.w))
            fr.add(whole, blur(sheet, 1.2), WARM, 1.5 * fade * max(grow, 0.6))
            edge = 1 - life(f, 3, 10)  # the leading edge, white on the blow, gone before the sheet
            fr.streak(st.shaft(head, SMEAR_FROM), st.shaft(head, 1.0), 0.05, 0.14, WHITE, 2.4 * edge, soft=0.5)
    if shape == "S5_lantern_arc":
        # research's redraw (2026-11-26): the comet runs the lantern's whole path from the hold, so the arc is the read
        # and the flare lands as its end. Its tail stays at the hold until the blow is past, then catches up.
        live = ease_out(life(f, HOLD, HOLD + 3)) * (1 - life(f, 5, 12))
        head = min(f, 8.0)
        tail = HOLD + life(f, 4, 12) * (head - HOLD)
        pts = path_pts(st, "Lantern", tail, head, 0.25)
        if len(pts) > 1 and live > 0:
            arc(fr, pts, 0.8, WARM, 1.3 * live)
        p = st.point("Lantern", f)
        flare = float(f >= 0) * (1 - life(f, 3, 9))  # the arc's end: it lands on Strike and holds three frames
        fr.glow(p, 0.9 + 0.5 * flare, WARM, 0.5 + 0.7 * live + 0.8 * flare)
        fr.core(p, 0.24, WHITE, 0.5 * live + 2.4 * flare)
        if 0 <= f <= 3:  # the shaft glints along its length on the blow
            fr.streak(st.shaft(f, SHOWN), st.shaft(f, 1.0), 0.04, 0.07, WHITE, 2.2 * (1 - life(f, 0, 3)), soft=0.5)
    if shape == "S6_echoes":
        # the lantern left behind as afterimages, three a frame and a half apart, each fainter: its weight as speed
        live = ease_out(life(f, -4, 0)) * (1 - life(f, 6, 12))
        for n, k in ((1, 0.9), (2, 0.6), (3, 0.35)):
            then = f - 1.5 * n
            if then >= -6 and live > 0:
                q = st.point("Lantern", then)
                fr.glow(q, 0.75, WARM, 1.2 * k * live, falloff=4.0)
                fr.glow(q, 0.35, WHITE, 0.9 * k * live, falloff=3.0)
        p = st.point("Lantern", f)
        fr.glow(p, 0.9, WARM, 0.5 + 0.8 * live)
        fr.core(p, 0.22, WHITE, 2.6 * (1 - life(f, 0, 6)) * float(f >= 0) + 0.5 * live)


def lantern_flare(fr: Frame, st: KeeperStage, f):
    """The lantern notices you: its glow flares on Lift and settles brighter than before."""
    if "Lantern" not in st.paths:
        return
    rise = life(f, LIFT - 2, LIFT + 1) * (1 - 0.45 * life(f, LIFT + 1, LIFT + 9))
    p = st.point("Lantern", f)
    fr.glow(p, 0.9 + 0.9 * rise, WARM, 0.6 + 1.4 * rise)
    fr.core(p, 0.18 + 0.1 * rise, WHITE, 0.8 + 2.0 * rise)


def draw_challenge(fr: Frame, st: KeeperStage, f, shape):
    lantern_flare(fr, st, f)
    g = f
    if g < 0:
        return
    lamp = st.point("Lantern", f)
    if shape == "C3_pulse" and g <= 14:
        u = SHOWN - 0.1 + (1.1 - SHOWN) * ease_out(g / 4)
        if g <= 5:  # the bead runs up the shaft into the lantern, its trail behind it
            k = 1 - life(g, 4, 6)
            fr.streak(st.shaft(f, max(SHOWN - 0.1, u - 0.3)), st.shaft(f, min(u, 1.0)), 0.02, 0.1, WARM, 1.8 * k, soft=0.6)
            fr.core(st.shaft(f, min(u, 1.0)), 0.16, WHITE, 2.4 * k)
        b = g - 4
        if b >= 0:  # the lantern bursts: a flash, and a ring round it facing the camera
            toward = fr.cam.pos - lamp
            fade = 1 - life(b, 2, 10)
            radius = 0.9 + 1.5 * ease_out(b / 8)
            fr.core(lamp, 0.3 + 0.2 * life(b, 0, 2), WHITE, 3.0 * (1 - life(b, 0, 6)))
            fr.glow(lamp, 1.6, WARM, 1.0 * (1 - life(b, 0, 10)))
            fr.ring(lamp, radius, 0.09 * (1 - 0.5 * life(b, 0, 8)), WARM, 1.6 * fade, normal=toward)
            fr.ring(lamp, radius, 0.035, WHITE, 1.6 * fade, normal=toward)
    if shape == "C4_wide_ring" and g <= 20:
        # research's must-fix (2026-11-26): the ring reads all the way round, not only its arc left of your fighter: a
        # wide band with the deep warm laid under it, so it holds on the pale street, and a faint fill inside it.
        foot = st.point("PoleFoot", 0).copy()
        foot[1] = st.ground + 0.05
        field = np.zeros((fr.h, fr.w), np.float32)
        rims = []
        for behind, strength in ((0, 1.0), (3, 0.45)):  # the ring and a fainter one a breath behind it
            h = g - behind
            if h < 0:
                continue
            r = 0.4 + (RING_REACH - 0.4) * ease_out(h / 16)
            k = (1 - life(h, 4, 18)) * strength
            band = RING_BAND * (1 - 0.4 * life(h, 0, 16))
            field = np.maximum(field, ground_ring(fr, foot, r, min(band, r), k))
            rims.append((r, k))
        if rims:
            whole = (slice(0, fr.h), slice(0, fr.w))
            soft = blur(field, 1.5)
            fr.lay(whole, soft, WARM_DEEP, DEEP_INK)
            fr.add(whole, soft, WARM, 1.6)
            for r, k in rims:
                fr.ring(foot, r, 0.05, WHITE, 1.6 * k)
        if g <= 4:  # the lantern jolts brighter with the stamp
            fr.core(lamp, 0.26, WHITE, 1.8 * (1 - life(g, 0, 4)))


def render(st: KeeperStage, name, f):
    fr = st.frame_at(f)
    (draw_swing if TARGETS[name][0] == "swing" else draw_challenge)(fr, st, f, name)
    out = fr.render()
    picture = linear_to_srgb(fr.base)  # the tile as taken, in the render's own sRGB
    lead = st.masks.get("Lead")
    if lead is not None:  # the lead, nearer the camera, holds still: laid back over the light in every tile
        out = out * (1 - lead[..., None]) + picture * lead[..., None]
    # the HUD from the backdrop, whole: a tile taken while it faded showed its ghost
    return out if st.hud is None else out * (1 - st.hud) + st.base * st.hud


def main(argv):
    st = KeeperStage(Path(argv[0]))
    out = Path(argv[1]) if len(argv) > 1 else OUT
    only = argv[2].split(",") if len(argv) > 2 else None
    out.mkdir(parents=True, exist_ok=True)
    peaks, names = [], []
    for name, (move, peak, times) in TARGETS.items():
        if (only and name not in only) or (not only and move != st.move):
            continue
        path = out / f"{name}_{st.name}_peak.png"
        write_png(render(st, name, peak), path)
        peaks.append(path)
        names.append(f"{name} ({st.name}, frame {peak})")
        strip([crop(render(st, name, f), st.crop) for f in times], out / f"{name}_{st.name}_strip.png")
        beat = "Strike" if move == "swing" else "Stamp"
        (out / f"{name}_{st.name}_strip.txt").write_text(
            f"frames from {beat}, at 60 a second: " + ", ".join(map(str, times)) + "\n", encoding="utf-8")
        print(name, st.name, "peak", peak)
    if peaks:
        sheet = out / f"phone_{st.name}"
        sheet.mkdir(exist_ok=True)
        phone_sheets(peaks, sheet, names)


if __name__ == "__main__":
    main(sys.argv[1:])
