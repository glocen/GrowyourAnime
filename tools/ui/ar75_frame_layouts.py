"""AR75, step 1: the whole frame in grey. Three layouts of the base and the HUD, each at rest and in a fight.

The director, 2026-11-28, by 00:20 and 00:23: the whole HUD and the base "a hot mess", and "everything in that screen"
to be overhauled. Research's brief (docs/requests/AR75.md): the composition first, in grey: what sits where, its size
and its priority, the fight the loudest thing, then the lead's health and the signature, everything else quiet; the
world's labels never in the HUD's layer; the whole place laid out too (where the machines stand, the floor's zones, the
backdrop, the player's mark).

Each layout is a plan of the 128-stud plot (the game's machines at their Stage III footprints, Config.World.Fit.Prints)
and a HUD scheme. The plot is drawn by a small projection renderer: boxes and prisms in greys, lit by one sun, hazed
with distance, cast shadows on the floor, from Roblox's camera (70 degrees vertical, 12.5 studs behind the head,
20 degrees down) at a 16:9 phone's 568 x 320 points. The HUD is drawn in the same points, in four greys by priority.

  py tools/ui/ar75_frame_layouts.py <out> [--today <rest capture> <fight capture>] [--beside <png>...]

Writes <out>/<A|B|C>_<rest|fight>.png (852 x 480, the phone's 1.5x), <out>/<A|B|C|today>_plan.png, and
<out>/ar75_layouts.png, the sheet. With --beside, <out>/ar75_beside.png adds the shipped frames, grey, at the same size
(internal: never committed or uploaded)."""
import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import hud_m_lead_targets as hm  # noqa: E402
import style_frames as sf  # noqa: E402

W, H = 568, 320
FOV = 70.0
SUN = np.array([-0.45, -0.55, 0.70])
SUN = SUN / np.linalg.norm(SUN)
SKY_TOP, SKY_LOW = 0.80, 0.90
HAZE = 0.88


# ---------------------------------------------------------------------------------------------------- the geometry
class Scene:
    def __init__(self):
        self.faces = []      # (pts Nx3, grey, layer, two_sided, name)
        self.casters = []    # (pts Mx3 of the object's hull, base z)
        self.anchors = {}    # name -> (x, y, z)

    def poly(self, pts, grey, layer=2, two=False):
        self.faces.append((np.asarray(pts, float), grey, layer, two))

    def box(self, c, size, grey, turn=0.0, layer=2, cast=True, top=None):
        (x, y, z0), (w, d, h) = c, size
        a = math.radians(turn)
        ca, sa = math.cos(a), math.sin(a)
        def p(u, v, z):
            return (x + u * ca - v * sa, y + u * sa + v * ca, z)
        u0, u1, v0, v1, z1 = -w / 2, w / 2, -d / 2, d / 2, z0 + h
        b = [p(u0, v0, z0), p(u1, v0, z0), p(u1, v1, z0), p(u0, v1, z0)]
        t = [p(u0, v0, z1), p(u1, v0, z1), p(u1, v1, z1), p(u0, v1, z1)]
        tl = layer if h > 0.35 else 1
        self.poly(t, top if top is not None else grey, 0 if layer == 0 else tl)
        if h > 0.35 or layer == 0:
            side_layer = 2 if layer == 0 else layer
            for i in range(4):
                j = (i + 1) % 4
                self.poly([b[i], b[j], t[j], t[i]], grey, side_layer)
        if cast and h > 0.6:
            self.casters.append((np.array(t + b), z0))

    def prism(self, c, r, h, grey, n=28, layer=2, cast=True, top=None, r_top=None):
        x, y, z0 = c
        rt = r if r_top is None else r_top
        ang = [2 * math.pi * k / n for k in range(n)]
        b = [(x + r * math.cos(t), y + r * math.sin(t), z0) for t in ang]
        t = [(x + rt * math.cos(a), y + rt * math.sin(a), z0 + h) for a in ang]
        tl = layer if h > 0.35 else 1
        self.poly(t, top if top is not None else grey, 0 if layer == 0 else tl)
        if h > 0.35 or layer == 0:
            for i in range(n):
                j = (i + 1) % n
                self.poly([b[i], b[j], t[j], t[i]], grey, 2)
        if cast and h > 0.6:
            self.casters.append((np.array(t + b), z0))

    def disc_v(self, c, r, grey, turn=0.0, n=24, z_mid=0.0):
        x, y, _ = c
        a = math.radians(turn)
        pts = [(x + r * math.cos(t) * math.cos(a), y + r * math.cos(t) * math.sin(a), z_mid + r * math.sin(t))
               for t in [2 * math.pi * k / n for k in range(n)]]
        self.poly(pts, grey, 2, two=True)

    def figure(self, x, y, z0=0.0, s=1.0, grey=0.2, face=90.0, name=None):
        """An R6 body, 5 studs at s = 1: legs, torso and arms, head, facing `face` degrees (90 is into the plot)."""
        turn = face - 90.0
        a = math.radians(turn)
        ca, sa = math.cos(a), math.sin(a)
        def at(u):
            return (x + u * s * ca, y + u * s * sa)
        self.box((x, y, z0), (2 * s, 1 * s, 2 * s), grey, turn)
        self.box((x, y, z0 + 2 * s), (2 * s, 1 * s, 2 * s), grey, turn)
        for u in (-1.5, 1.5):
            ax, ay = at(u)
            self.box((ax, ay, z0 + 2 * s), (1 * s, 1 * s, 2 * s), grey, turn)
        self.box((x, y, z0 + 4 * s), (1.2 * s, 1.2 * s, 1.2 * s), grey, turn)
        if name:
            self.anchors[name] = (x, y, z0 + 5.4 * s)
            self.anchors[name + "_foot"] = (x, y, z0)


# ---------------------------------------------------------------------------------------------------- the machines
G_MACHINE, G_DARK, G_LIGHT, G_ASLEEP = 0.46, 0.38, 0.93, 0.30


def generator(sc, x, y, z0=0.0, dais=15.0):
    sc.prism((x, y, z0), dais, 2.4, 0.56, n=40)
    sc.prism((x, y, z0 + 2.4), 9.0, 3.0, G_DARK, n=32)
    for k in range(6):
        t = 2 * math.pi * k / 6
        sc.box((x + 9.6 * math.cos(t), y + 9.6 * math.sin(t), z0 + 2.4), (1.6, 1.6, 22.0), G_DARK, turn=math.degrees(t))
    sc.prism((x, y, z0 + 5.4), 3.2, 8.0, 0.55, n=20)
    sc.prism((x, y, z0 + 13.4), 5.2, 7.0, G_LIGHT, n=24, cast=False)
    sc.prism((x, y, z0 + 20.4), 4.0, 1.4, 0.55, n=24)
    sc.prism((x, y, z0 + 24.4), 10.4, 1.4, G_DARK, n=32, cast=False)
    sc.anchors["Generator"] = (x, y, z0 + 27.5)


def breaker(sc, x, y, turn=0.0, z0=0.0):
    a = math.radians(turn)
    sc.box((x, y, z0), (34.6, 9.9, 6.0), G_MACHINE, turn)
    for u in (-10.0, 0.0, 10.0):
        cx, cy = x + u * math.cos(a), y + u * math.sin(a)
        sc.prism((cx, cy, z0 + 6.0), 3.4, 7.0, G_DARK, n=18)
        sc.prism((cx, cy, z0 + 13.0), 2.0, 0.6, G_LIGHT, n=18, cast=False)
    for u in (-16.0, 16.0):
        sc.box((x + u * math.cos(a), y + u * math.sin(a), z0 + 6.0), (2.2, 2.2, 14.0), G_DARK, turn)
    sc.anchors["Void Breaker"] = (x, y, z0 + 20.5)


def bay(sc, x, y, turn=0.0, z0=0.0, n=1, worker=True, asleep=False):
    g = G_ASLEEP if asleep else G_MACHINE
    a = math.radians(turn)
    sc.prism((x, y, z0), 5.4, 0.8, g, n=24)
    for u in (-5.2, 5.2):
        sc.box((x + u * math.cos(a), y + u * math.sin(a), z0 + 0.8), (1.5, 1.5, 14.2), G_DARK if not asleep else g, turn)
    sc.box((x, y, z0 + 13.8), (12.0, 1.8, 1.8), G_DARK if not asleep else g, turn)
    if worker and not asleep:
        sc.figure(x, y, z0 + 0.8, 1.0, 0.30, turn + 90)
    sc.anchors[f"Bay {n}"] = (x, y, z0 + 16.0)


def battery(sc, x, y, turn=0.0, z0=0.0):
    sc.box((x, y, z0), (6.5, 4.5, 13.4), G_MACHINE, turn)
    for k in range(3):
        sc.box((x, y, z0 + 3 + 3.4 * k), (4.6, 4.7, 1.6), G_LIGHT, turn, cast=False)
    sc.anchors["Battery"] = (x, y, z0 + 14.0)


def training(sc, x, y, turn=0.0, z0=0.0):
    sc.box((x, y, z0), (9.8, 13.0, 4.6), G_MACHINE, turn)
    sc.box((x, y, z0 + 4.6), (1.6, 1.6, 5.8), G_DARK, turn)
    sc.box((x, y, z0 + 9.6), (7.0, 1.4, 1.0), G_DARK, turn)
    sc.anchors["Training"] = (x, y, z0 + 10.8)


def condenser(sc, x, y, turn=0.0, z0=0.0):
    sc.box((x, y, z0), (11.6, 9.3, 7.0), G_MACHINE, turn)
    sc.prism((x, y, z0 + 7.0), 3.6, 4.8, G_DARK, n=20)
    sc.prism((x, y, z0 + 9.0), 4.2, 0.9, G_LIGHT, n=20, cast=False)
    sc.anchors["Condenser"] = (x, y, z0 + 12.0)


def door(sc, x, y, turn=0.0, z0=0.0):
    sc.box((x, y, z0), (10.0, 5.0, 1.0), G_MACHINE, turn)
    a = math.radians(turn)
    for u in (-5.4, 5.4):
        sc.box((x + u * math.cos(a), y + u * math.sin(a), z0 + 1.0), (1.8, 2.4, 11.0), G_DARK, turn)
    sc.box((x, y, z0 + 11.4), (12.6, 2.4, 1.8), G_DARK, turn)
    sc.disc_v((x, y, 0), 4.6, 0.95, turn, z_mid=z0 + 6.6)
    sc.anchors["Door"] = (x, y, z0 + 13.6)


def asleep(sc, x, y, size, name, turn=0.0, z0=0.0):
    sc.box((x, y, z0), size, G_ASLEEP, turn)
    sc.anchors[name] = (x, y, z0 + size[2] + 0.5)


def showcase(sc, x, y, z0=0.0):
    sc.prism((x, y, z0), 3.2, 1.4, 0.55, n=24)
    sc.prism((x, y, z0 + 1.4), 2.6, 0.12, G_LIGHT, n=24, cast=False)
    sc.figure(x, y, z0 + 1.52, 1.0, 0.30, 270)
    sc.anchors["Showcase"] = (x, y, z0 + 7.2)


def mark(sc, x, y, z0=0.0):
    """The player's mark: a small inlay where they stand, never a tile and a ring."""
    sc.prism((x, y, z0), 2.3, 0.05, 0.56, n=24, cast=False)
    sc.prism((x, y, z0 + 0.05), 1.5, 0.06, 0.86, n=24, cast=False)


def strip_inlay(sc, a, b, width, grey, z=0.0):
    (x0, y0), (x1, y1) = a, b
    L = math.hypot(x1 - x0, y1 - y0)
    sc.box(((x0 + x1) / 2, (y0 + y1) / 2, z), (width, L, 0.06), grey, math.degrees(math.atan2(y1 - y0, x1 - x0)) - 90,
           cast=False)


def floor(sc, x0, x1, y0, y1, grey, z=0.0, step=8.0, layer=0):
    for xa in np.arange(x0, x1, step):
        for ya in np.arange(y0, y1, step):
            xb, yb = min(xa + step, x1), min(ya + step, y1)
            sc.poly([(xa, ya, z), (xb, ya, z), (xb, yb, z), (xa, yb, z)], grey, layer)


def surroundings(sc, back_wall=5.0):
    """What every plan shares: the ground round the plot, its low wall and pylons, the plot's Tower behind it, the
    neighbours' Towers, and the void's skyline far off."""
    floor(sc, -260, 260, -40, 420, 0.70, z=-0.06, step=40)
    for x0, x1, y0, y1 in ((-64, -63, 0, 128), (63, 64, 0, 128), (-64, 64, 127, 128)):
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        sc.box((cx, cy, 0), (x1 - x0, y1 - y0, back_wall), 0.60)
    for px in range(-64, 65, 16):
        sc.box((px, 128, 0), (1.8, 1.8, back_wall + 4), 0.48)
    for py in range(0, 129, 16):
        sc.box((-64, py, 0), (1.8, 1.8, back_wall + 4), 0.48)
        sc.box((64, py, 0), (1.8, 1.8, back_wall + 4), 0.48)
    sc.box((0, 160, 0), (32, 32, 96), 0.66)
    sc.anchors["Tower"] = (0, 160, 96)
    for nx in (-160, 160):
        sc.box((nx, 160, 0), (32, 32, 96), 0.72)
        sc.box((nx, 64, 0), (128, 128, back_wall), 0.68)
    rng = np.random.default_rng(7)
    for k in range(9):
        x = -480 + k * 120 + rng.uniform(-30, 30)
        h = rng.uniform(90, 190)
        sc.prism((x, 470 + rng.uniform(-40, 40), 0), rng.uniform(14, 24), h, 0.74, n=5, r_top=1.5, cast=False)
    sc.anchors["the void's skyline"] = (-240, 470, 150)


# -------------------------------------------------------------------------------------------------------- the plans
def plan_a():
    """A, the crescent court: a round court at the yard's middle, where the fight and the training happen, the
    machines in a crescent round it, the Generator raised behind it as the yard's hero, and the current drawn in the
    floor from every bay to the Generator, so the loop is seen."""
    sc = Scene()
    surroundings(sc)
    floor(sc, -63, 63, 0, 127, 0.66)
    sc.prism((0, 50, 0), 22.0, 0.30, 0.50, n=48, layer=1)
    sc.prism((0, 50, 0.30), 20.0, 0.02, 0.80, n=48, layer=1)
    for a in (150, 128, 52, 30):
        t = math.radians(a)
        strip_inlay(sc, (46 * math.cos(t) * 0.86, 50 + 46 * math.sin(t) * 0.86), (0, 92), 1.0, 0.42, z=0.0)
    strip_inlay(sc, (0, 4), (0, 28), 6.0, 0.58)
    generator(sc, 0, 100, dais=16.0)
    breaker(sc, -38, 36, turn=-70)
    for n, a in ((1, 150), (2, 128), (3, 52), (4, 30)):
        t = math.radians(a)
        bx, by = 46 * math.cos(t), 50 + 46 * math.sin(t)
        bay(sc, bx, by, turn=math.degrees(t) + 90, n=n)
    door(sc, 42, 20, turn=60)
    condenser(sc, 48, 52, turn=90)
    training(sc, 48, 108, turn=90)
    battery(sc, -24, 116)
    asleep(sc, -50, 112, (11.0, 8.8, 8.0), "Forge (asleep)")
    asleep(sc, 26, 120, (9.2, 9.2, 1.4), "Lab (asleep)")
    showcase(sc, -24, 20)
    return sc, dict(spawn=(0, 12), fight=((-2.0, 46.0), (4.5, 53.0)), player=(-12.0, 50.0),
                    zones=[("the court: the fight and the training", (0, 50)),
                           ("the current, floor inlays to the heart", (-20, 76))])


def plan_b():
    """B, the terraces: the plot rises in three steps from the gate, the plaza where the player arrives and the fight
    happens, the work terrace (Breaker, Condenser, battery), and the heart terrace (the Generator with the four bays
    round it). The rising floor fills the frame to the Tower: no empty plane, no horizon."""
    sc = Scene()
    surroundings(sc, back_wall=9.0)
    floor(sc, -63, 63, 0, 36, 0.66)
    sc.box((0, 61, 0), (126, 46, 3.0), 0.60, layer=0, cast=False, top=0.62)
    sc.box((0, 105.5, 0), (126, 43, 7.0), 0.56, layer=0, cast=False, top=0.58)
    for k in range(4):
        sc.box((0, 35.7 + k * 0.9, 0), (22, 1.0, 0.75 * (k + 1)), 0.70, layer=0, cast=False)
    for k in range(5):
        sc.box((0, 83.0 + k * 0.9, 3.0), (22, 1.0, 0.8 * (k + 1)), 0.66, layer=0, cast=False)
    sc.prism((0, 22, 0), 13.0, 0.02, 0.80, n=40, layer=1)
    strip_inlay(sc, (0, 2), (0, 9), 6.0, 0.58)
    generator(sc, 0, 108, z0=7.0, dais=14.0)
    for n, (bx, by, t) in enumerate(((-30, 97, 20), (-48, 114, 40), (30, 97, -20), (48, 114, -40)), 1):
        bay(sc, bx, by, turn=t, z0=7.0, n=n)
    breaker(sc, -30, 60, turn=0, z0=3.0)
    condenser(sc, 30, 58, z0=3.0)
    battery(sc, 50, 74, z0=3.0)
    door(sc, 44, 20, turn=90)
    training(sc, -46, 22, turn=0)
    asleep(sc, 50, 46, (11.0, 8.8, 8.0), "Forge (asleep)", z0=3.0)
    asleep(sc, -54, 46, (9.2, 9.2, 1.4), "Lab (asleep)", z0=3.0)
    showcase(sc, -26, 17)
    return sc, dict(spawn=(0, 6), fight=((-2.0, 20.0), (4.5, 27.0)), player=(-12.0, 24.0),
                    zones=[("the plaza: arrival and the fight", (0, 22)), ("the work terrace, +3", (0, 62)),
                           ("the heart terrace, +7", (0, 118))])


def plan_c():
    """C, two quarters on an avenue: the way in runs straight to the Generator at its end; the power quarter on the
    left (the four bays in an arc round the battery), the making quarter on the right (the Breaker facing the avenue,
    the Condenser, the Training machine). The fight takes the forecourt on the avenue."""
    sc = Scene()
    surroundings(sc)
    floor(sc, -63, 63, 0, 127, 0.68)
    sc.box((-37, 79, 0), (52, 96, 0.04), 0.60, cast=False)
    sc.box((37, 74, 0), (52, 106, 0.04), 0.73, cast=False)
    sc.box((0, 44, 0), (20, 88, 0.05), 0.52, cast=False)
    strip_inlay(sc, (0, 2), (0, 86), 1.0, 0.86, z=0.05)
    sc.prism((0, 34, 0.05), 9.5, 0.02, 0.82, n=36, layer=1)
    generator(sc, 0, 104, dais=16.0)
    breaker(sc, 36, 36, turn=90)
    condenser(sc, 44, 72, turn=180)
    training(sc, 32, 102, turn=180)
    battery(sc, -38, 66)
    for n, a in enumerate((110, 150, 190, 230), 1):
        t = math.radians(a)
        bx, by = -38 + 18 * math.cos(t), 66 + 18 * math.sin(t)
        bay(sc, bx, by, turn=math.degrees(t) + 90, n=n)
        strip_inlay(sc, (bx, by), (-38, 66), 0.8, 0.44, z=0.04)
    strip_inlay(sc, (-38, 66), (-12, 96), 1.0, 0.44, z=0.04)
    door(sc, 24, 12, turn=-30)
    asleep(sc, 52, 116, (11.0, 8.8, 8.0), "Forge (asleep)")
    asleep(sc, -30, 112, (9.2, 9.2, 1.4), "Lab (asleep)")
    showcase(sc, -22, 12)
    return sc, dict(spawn=(0, 10), fight=((-2.0, 32.0), (4.5, 39.0)), player=(-12.0, 36.0),
                    zones=[("the avenue and its forecourt", (0, 30)), ("the power quarter", (-38, 96)),
                           ("the making quarter", (40, 96))])


def plan_today():
    """Today's plan, as laid (src/shared/Config/Kits/Base/Plan.json): the star round the Generator. Plan view only."""
    import json
    plan = json.loads((REPO / "src/shared/Config/Kits/Base/Plan.json").read_text())["layout"]
    sc = Scene()
    floor(sc, -63, 63, 0, 127, 0.66)
    s = plan["stations"]
    # the plan's `across` is +X to the left as the spawn looks: mirror it so left is left
    def p(k):
        return -s[k]["across"], s[k]["inward"]
    generator(sc, *p("generator"))
    breaker(sc, *p("breaker"), turn=0)
    door(sc, *p("door"))
    battery(sc, *p("battery"))
    training(sc, *p("training"))
    bay(sc, *p("bay1"), n=1)
    bay(sc, *p("bay2"), n=2)
    for n, lb in enumerate(plan["laterBays"][:2], 3):
        bay(sc, -lb["across"], lb["inward"], n=n)
    for k, v in plan.get("sleeping", {}).items():
        if k == "condenser":
            condenser(sc, -v["across"], v["inward"])
        else:
            asleep(sc, -v["across"], v["inward"], (9, 9, 4), f"{k.title()} (asleep)")
    showcase(sc, -plan["showcase"]["across"], plan["showcase"]["inward"])
    return sc, dict(spawn=(-plan["spawn"]["across"], plan["spawn"]["inward"]), zones=[])


REPO = Path(__file__).resolve().parents[2]
PLANS = {"A": plan_a, "B": plan_b, "C": plan_c}


# ------------------------------------------------------------------------------------------------------- the render
class Camera:
    def __init__(self, eye, target, fov=FOV, w=W, h=H):
        self.e = np.asarray(eye, float)
        f = np.asarray(target, float) - self.e
        self.f = f / np.linalg.norm(f)
        r = np.cross(self.f, [0, 0, 1.0])
        self.r = r / np.linalg.norm(r)
        self.u = np.cross(self.r, self.f)
        self.fpx = (h / 2) / math.tan(math.radians(fov) / 2)
        self.w, self.h = w, h

    def cam(self, p):
        d = np.asarray(p, float) - self.e
        return np.stack([d @ self.r, d @ self.u, d @ self.f], -1)

    def screen(self, c):
        return np.stack([self.w / 2 + c[..., 0] / c[..., 2] * self.fpx, self.h / 2 - c[..., 1] / c[..., 2] * self.fpx], -1)

    def project(self, p):
        c = self.cam(p)
        return None if c[2] <= 0.3 else self.screen(c)


def behind(at, z_foot=0.0, zoom=12.5, pitch=20.0, focus_up=4.5, heading=(0, 1)):
    fx, fy = at
    hx, hy = heading
    focus = np.array([fx, fy, z_foot + focus_up])
    p = math.radians(pitch)
    eye = focus + np.array([-hx * math.cos(p), -hy * math.cos(p), math.sin(p)]) * zoom
    return Camera(eye, focus)


def clip_near(c, near=0.3):
    out = []
    n = len(c)
    for i in range(n):
        a, b = c[i], c[(i + 1) % n]
        ina, inb = a[2] > near, b[2] > near
        if ina:
            out.append(a)
        if ina != inb:
            t = (near - a[2]) / (b[2] - a[2])
            out.append(a + (b - a) * t)
    return np.array(out) if len(out) >= 3 else None


def shade(pts, grey, eye):
    n = np.cross(pts[1] - pts[0], pts[2] - pts[0])
    nn = np.linalg.norm(n)
    n = n / nn if nn > 1e-9 else np.array([0, 0, 1.0])
    lit = 0.70 + 0.34 * max(0.0, float(n @ SUN)) - 0.06 * max(0.0, -float(n @ SUN))
    g = min(1.0, grey * lit)
    d = np.linalg.norm(pts.mean(0) - eye)
    k = 1 - math.exp(-d / 360.0)
    return g * (1 - k) + HAZE * k, n


def hexg(g):
    v = int(round(max(0.0, min(1.0, g)) * 255))
    return f"#{v:02x}{v:02x}{v:02x}"


def render_world(sc, cam):
    """The scene as SVG polygons, painted back to front: the floors first, then the floor's flat inlays, the cast
    shadows, then every standing face by distance."""
    sky = (f'<defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{hexg(SKY_TOP)}"/>'
           f'<stop offset="1" stop-color="{hexg(SKY_LOW)}"/></linearGradient></defs>'
           f'<rect width="{W}" height="{H}" fill="url(#sky)"/>')
    layers = {0: [], 1: [], 2: []}
    for pts, grey, layer, two in sc.faces:
        g, n = shade(pts, grey, cam.e)
        cen = pts.mean(0)
        if not two and float(n @ (cam.e - cen)) <= 0:
            continue
        c = clip_near(cam.cam(pts))
        if c is None:
            continue
        s = cam.screen(c)
        if s[:, 0].max() < -50 or s[:, 0].min() > W + 50 or s[:, 1].max() < -50 or s[:, 1].min() > H + 50:
            continue
        layers[layer].append((float(np.linalg.norm(cen - cam.e)), s, g))
    out = [sky]
    def draw(items, stroke=True):
        for _, s, g in sorted(items, key=lambda t: -t[0]):
            d = " ".join(f"{x:.2f},{y:.2f}" for x, y in s)
            st = f' stroke="{hexg(g * 0.82)}" stroke-width="0.35" stroke-linejoin="round"' if stroke else \
                f' stroke="{hexg(g)}" stroke-width="0.25"'
            out.append(f'<polygon points="{d}" fill="{hexg(g)}"{st}/>')
    draw(layers[0], stroke=False)
    draw(layers[1], stroke=False)
    for hull, z0 in sc.casters:
        flat = hull - SUN[None, :] * ((hull[:, 2] - z0) / SUN[2])[:, None]
        flat[:, 2] = z0 + 0.02
        c = cam.cam(flat)
        if (c[:, 2] <= 0.3).any():
            continue
        s = cam.screen(c)
        hull2 = convex_hull(s)
        d = " ".join(f"{x:.2f},{y:.2f}" for x, y in hull2)
        out.append(f'<polygon points="{d}" fill="#000" fill-opacity="0.13"/>')
    draw(layers[2])
    return "".join(out)


def convex_hull(p):
    pts = sorted(set(map(tuple, np.round(p, 3))))
    if len(pts) < 3:
        return pts
    def half(seq):
        h = []
        for q in seq:
            while len(h) >= 2 and (h[-1][0] - h[-2][0]) * (q[1] - h[-2][1]) - (h[-1][1] - h[-2][1]) * (q[0] - h[-2][0]) <= 0:
                h.pop()
            h.append(q)
        return h
    lo, hi = half(pts), half(pts[::-1])
    return lo[:-1] + hi[:-1]


def render_plan(sc, size=320, span=150.0, labels=True, extra=None):
    """The plot from above, the gate at the foot: every face that looks up, painted from low to high."""
    s = size / span
    def xy(p):
        return size / 2 + p[0] * s, size - 12 - (p[1] + 4) * s * 0.92 - 0
    items = []
    for pts, grey, layer, two in sc.faces:
        n = np.cross(pts[1] - pts[0], pts[2] - pts[0])
        if np.linalg.norm(n) < 1e-9 or abs(n[2]) / np.linalg.norm(n) < 0.5:
            continue
        if (np.abs(pts[:, 0]) > 70).any() or (pts[:, 1] < -6).any() or (pts[:, 1] > 134).any():
            continue
        items.append((float(pts[:, 2].mean()), layer, [xy(p) for p in pts], grey))
    out = [f'<rect width="{size}" height="{size}" fill="#2a2c30"/>']
    for z, layer, poly, g in sorted(items, key=lambda t: (t[0], t[1])):
        g2 = min(1.0, g * (0.86 + 0.012 * z))
        d = " ".join(f"{x:.2f},{y:.2f}" for x, y in poly)
        out.append(f'<polygon points="{d}" fill="{hexg(g2)}" stroke="{hexg(g2 * 0.8)}" stroke-width="0.3"/>')
    gx0, gy0 = xy((-10, 0))
    gx1, _ = xy((10, 0))
    out.append(f'<rect x="{gx0:.1f}" y="{gy0:.1f}" width="{gx1 - gx0:.1f}" height="4" fill="#e9e5da"/>')
    out.append(f'<text x="{(gx0 + gx1) / 2:.1f}" y="{gy0 + 12:.1f}" font-family="Builder" font-size="8" fill="#e9e5da" '
               f'text-anchor="middle">gate</text>')
    if labels:
        for name, (x, y, z) in sc.anchors.items():
            if name.endswith("_foot") or name in ("Tower", "the void's skyline") or abs(x) > 70 or y > 134:
                continue
            px, py = xy((x, y))
            out.append(f'<text x="{px:.1f}" y="{py + 2.5:.1f}" font-family="Builder" font-size="6.5" fill="#fff" '
                       f'stroke="#111" stroke-width="1.6" paint-order="stroke" text-anchor="middle">{name}</text>')
    for txt, (x, y) in (extra or []):
        px, py = xy((x, y))
        out.append(f'<text x="{px:.1f}" y="{py:.1f}" font-family="Builder" font-size="6.5" fill="#ffd9a8" '
                   f'stroke="#111" stroke-width="1.6" paint-order="stroke" text-anchor="middle">{txt}</text>')
    return out, xy


# ---------------------------------------------------------------------------------------------------------- the HUD
P2, P3, P4 = ("#EFEFEF", "#1C1C1C", "#1C1C1C"), ("#ABABAB", "#2B2B2B", "#1C1C1C"), ("#5E5E5E", "#242424", "#F2F2F2")


def label(x, y, t, size=6.2, fill="#1C1C1C", anchor="middle", weight="Builder"):
    return (f'<text x="{x:.1f}" y="{y:.1f}" font-family="{weight}" font-size="{size}" fill="{fill}" '
            f'text-anchor="{anchor}">{t}</text>')


def rect(x, y, w, h, pri, t="", r=4.0, t2=""):
    fill, stroke, ink = pri
    s = (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" fill-opacity="0.94" stroke="{stroke}" '
         f'stroke-width="0.8"/>')
    if t:
        s += label(x + w / 2, y + h / 2 + (2.2 if not t2 else -0.6), t, 6.0 if h >= 12 else 5.0, ink)
    if t2:
        s += label(x + w / 2, y + h / 2 + 6.0, t2, 4.6, ink)
    return s, w * h


def circ(x, y, r, pri, t="", t2=""):
    fill, stroke, ink = pri
    s = f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" fill-opacity="0.94" stroke="{stroke}" stroke-width="0.8"/>'
    if t:
        s += label(x, y + (2.0 if not t2 else -0.8), t, 6.0 if r >= 12 else 4.8, ink)
    if t2:
        s += label(x, y + 6.0, t2, 4.6, ink)
    return s, math.pi * r * r


def bar(x, y, w, h, pri, share=0.62, t=""):
    fill, stroke, ink = pri
    s = (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{h / 2}" fill="#3A3A3A" stroke="{stroke}" stroke-width="0.8"/>'
         f'<rect x="{x}" y="{y}" width="{w * share:.1f}" height="{h}" rx="{h / 2}" fill="{fill}"/>')
    if t:
        s += label(x + w / 2, y + h / 2 + 2.0, t, min(6.0, h * 0.62), "#1C1C1C" if pri is not P4 else "#F2F2F2")
    return s, w * h


def dashed_circle(x, y, r, t):
    return (f'<circle cx="{x}" cy="{y}" r="{r}" fill="none" stroke="#fff" stroke-opacity="0.75" stroke-width="0.8" '
            f'stroke-dasharray="3 2"/>' + label(x, y + 2, t, 5.6, "#fff"))


def dashed_rect(x, y, w, h, t, col="#fff"):
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="3" fill="none" stroke="{col}" stroke-opacity="0.8" '
            f'stroke-width="0.8" stroke-dasharray="3 2"/>' + label(x + w / 2, y + h / 2 + 2, t, 5.6, col))


STICK, JUMP = (102, 276, 28), (471, 276, 28)   # measured on the director's phone capture (bug3), scaled to 320 high


def roblox():
    return (dashed_rect(8, 6, 92, 26, "Roblox's buttons") + dashed_circle(*STICK, "move (Roblox)")
            + dashed_circle(*JUMP, "jump (Roblox)"))


def portrait(x, y, r, pri):
    s, a = circ(x, y, r, pri)
    s += (f'<circle cx="{x}" cy="{y - r * 0.18}" r="{r * 0.36}" fill="#7A7A7A"/>'
          f'<path d="M{x - r * 0.62} {y + r * 0.78} Q{x} {y + r * 0.05} {x + r * 0.62} {y + r * 0.78} Z" fill="#7A7A7A"/>')
    return s, a


def hud(scheme, state):
    """One scheme's HUD in one state: its SVG, and its share of the frame (Roblox's own and the world's left out)."""
    parts, area = [], 0.0
    def add(sa):
        nonlocal area
        s, a = sa
        parts.append(s)
        area += a
    if scheme == "1":   # corners
        if state == "fight":
            add(portrait(30, 58, 19, P2))
            add(rect(52, 41, 150, 12, P2, "ROOK  ·  Lv 27", r=2))
            add(bar(52, 56, 150, 13, P2, 0.62, "2,518 / 4,061"))
            add(bar(52, 71.5, 150, 2.4, P3, 0.42))
            add(rect(194, 6, 180, 11, P3, "Lv 60  BRAWLER  ·  skull", r=2))
            add(bar(184, 19, 200, 8, P3, 0.86))
            add(circ(486, 200, 33, P2, "HAYMAKER", "the press, 66 pt, ring = charge"))
            add(circ(506, 22, 13, P4, "AUTO"))
            add(circ(538, 22, 13, P4, "eye"))
        else:
            add(portrait(24, 54, 14, P3))
            add(rect(41, 42, 120, 10, P3, "ROOK  ·  Lv 27", r=2))
            add(bar(41, 55, 120, 8, P3, 1.0))
            add(rect(400, 8, 160, 20, P3, "Credits  ·  kW made / used  ·  battery", r=3))
            add(rect(452, 32, 108, 16, P4, "+31 Credits  ·  collect", r=8))
            add(rect(222, 272, 40, 40, P3, "Base", r=6))
            add(rect(266, 272, 40, 40, P3, "Home", r=6))
            add(rect(310, 272, 40, 40, P3, "Play", r=6))
    elif scheme == "2":   # the foot console
        if state == "fight":
            add(rect(204, 6, 160, 11, P3, "Lv 60  BRAWLER  ·  skull", r=2))
            add(bar(164, 19, 240, 8, P3, 0.86))
            add(rect(148, 262, 222, 52, P4, "", r=8))
            add(portrait(170, 288, 19, P2))
            add(rect(194, 268, 150, 10, P2, "ROOK  ·  Lv 27", r=2))
            add(bar(194, 282, 160, 13, P2, 0.62, "2,518 / 4,061"))
            add(bar(194, 298, 160, 2.4, P3, 0.42))
            add(circ(392, 282, 29, P2, "HAYMAKER", "the press, 58 pt"))
            add(rect(300, 250, 28, 11, P4, "AUTO", r=3))
            add(rect(331, 250, 22, 11, P4, "eye", r=3))
        else:
            add(rect(400, 8, 160, 20, P3, "Credits  ·  kW made / used  ·  battery", r=3))
            add(rect(148, 262, 222, 52, P4, "", r=8))
            add(portrait(170, 288, 17, P3))
            add(bar(194, 270, 160, 7, P3, 1.0, ""))
            add(rect(212, 280, 32, 30, P3, "Base", r=5))
            add(rect(250, 280, 32, 30, P3, "Home", r=5))
            add(rect(288, 280, 32, 30, P3, "Play", r=5))
            add(rect(326, 284, 40, 22, P4, "+31", r=5, t2="collect"))
    else:   # the versus band
        if state == "fight":
            add(portrait(124, 26, 15, P2))
            add(rect(142, 9, 132, 9, P2, "ROOK  ·  Lv 27", r=2))
            add(bar(142, 21, 132, 12, P2, 0.62, "2,518 / 4,061"))
            add(rect(276, 16, 16, 16, P4, "", r=2))
            parts.append(label(284, 44, "stage", 4.6, "#fff"))
            add(rect(294, 9, 132, 9, P3, "BRAWLER  ·  Lv 60", r=2))
            add(bar(294, 21, 132, 12, P3, 0.86, ""))
            add(portrait(444, 26, 15, P3))
            add(rect(142, 37, 30, 11, P4, "AUTO", r=3))
            add(rect(175, 37, 22, 11, P4, "eye", r=3))
            add(circ(486, 200, 33, P2, "HAYMAKER", "the press, 66 pt"))
        else:
            add(portrait(124, 26, 15, P3))
            add(rect(142, 9, 120, 9, P3, "ROOK  ·  Lv 27", r=2))
            add(bar(142, 21, 120, 9, P3, 1.0))
            add(rect(400, 8, 160, 20, P3, "Credits  ·  kW made / used  ·  battery", r=3))
            add(rect(452, 32, 108, 16, P4, "+31 Credits  ·  collect", r=8))
            add(rect(10, 92, 40, 40, P3, "Base", r=6))
            add(rect(10, 136, 40, 40, P3, "Home", r=6))
            add(rect(10, 180, 40, 40, P3, "Play", r=6))
    return "".join(parts) + roblox(), area / (W * H)


SCHEMES = {"A": "1", "B": "2", "C": "3"}
SCHEME_NAMES = {"1": "corners", "2": "the foot console", "3": "the versus band"}


def world_marks(sc, cam, state, fight_names=("Rook", "Brawler")):
    """At rest, a small marker over each machine (its name on approach); in a fight, none, and the fight is ringed."""
    out = []
    if state == "rest":
        for name, p in sc.anchors.items():
            if name.endswith("_foot") or name in ("Tower", "the void's skyline", "Showcase") or "asleep" in name:
                continue
            s = cam.project(p)
            if s is None or not (8 < s[0] < W - 8 and 8 < s[1] < H - 8):
                continue
            out.append(f'<circle cx="{s[0]:.1f}" cy="{s[1] - 4:.1f}" r="3.2" fill="#5E5E5E" stroke="#fff" stroke-width="0.6"/>'
                       + label(s[0], s[1] - 9.5, name, 4.6, "#fff"))
    else:
        pts = [cam.project(sc.anchors[n]) for n in fight_names] + [cam.project(sc.anchors[n + "_foot"]) for n in fight_names]
        pts = np.array([p for p in pts if p is not None])
        x0, y0 = pts.min(0) - (22, 12)
        x1, y1 = pts.max(0) + (22, 6)
        out.append(f'<rect x="{x0:.1f}" y="{y0:.1f}" width="{x1 - x0:.1f}" height="{y1 - y0:.1f}" rx="6" fill="none" '
                   f'stroke="#fff" stroke-width="0.9" stroke-dasharray="4 2.5"/>'
                   + label((x0 + x1) / 2, y1 + 8, "1 · THE FIGHT: the loudest thing; hits and numbers at the bodies", 5.4, "#fff"))
        for n in fight_names:
            s = cam.project(sc.anchors[n])
            if s is not None:
                out.append(f'<circle cx="{s[0] + 9:.1f}" cy="{s[1] - 6:.1f}" r="5" fill="none" stroke="#fff" '
                           f'stroke-width="0.6" stroke-dasharray="1.5 1.5"/>')
    return "".join(out)


def frame_svg(key, state):
    sc, meta = PLANS[key]()
    a, b = meta["fight"]
    if state == "fight":
        f = math.degrees(math.atan2(b[1] - a[1], b[0] - a[0]))
        sc.figure(a[0], a[1], z_of(key, a), 1.0, 0.14, f, name="Rook")
        sc.figure(b[0], b[1], z_of(key, b), 1.3, 0.10, f + 180, name="Brawler")
        px, py = meta["player"]
        sc.figure(px, py, z_of(key, (px, py)), 1.0, 0.50, 90)
        mx, my = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
        cam = behind((mx, my - 1.0), z_foot=z_of(key, a), zoom=17.0, pitch=17.0, focus_up=3.4)
    else:
        sx, sy = meta["spawn"]
        mark(sc, sx, sy, z_of(key, (sx, sy)))
        sc.figure(sx, sy, z_of(key, (sx, sy)), 1.0, 0.50, 90)
        rx, ry = sx - 3.0, sy + 3.0
        sc.figure(rx, ry, z_of(key, (rx, ry)), 1.0, 0.36, 90)
        cam = behind((sx, sy), z_foot=z_of(key, (sx, sy)))
    world = render_world(sc, cam)
    marks = world_marks(sc, cam, state)
    h, share = hud(SCHEMES[key], state)
    return world + marks + h, share


def z_of(key, p):
    if key != "B":
        return 0.0
    y = p[1]
    return 0.0 if y < 38 else 3.0 if y < 84 else 7.0


def plan_svg(key):
    sc, meta = (plan_today() if key == "today" else PLANS[key]())
    if key != "today":
        sx, sy = meta["spawn"]
        sc.anchors["spawn"] = (sx, sy, 0)
        mark(sc, sx, sy, z_of(key, (sx, sy)))
    else:
        sx, sy = meta["spawn"]
        sc.anchors["spawn"] = (sx, sy, 0)
    out, xy = render_plan(sc, extra=meta.get("zones"))
    return "".join(out)


# --------------------------------------------------------------------------------------------------------- the pages
def page(svg, w=W, h=H):
    return (f'<!doctype html><html><head><meta charset="utf-8"><style>{hm.css()} html,body{{margin:0;background:#000}}'
            f' svg{{display:block}}</style></head><body><svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
            f'viewBox="0 0 {w} {h}">{svg}</svg></body></html>')


def grey_capture(src, out, w=852, h=480):
    """A capture as a grey frame at the phone's size, fitted whole (a 16:10 frame gets bars), for reading beside ours."""
    import subprocess
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(src), "-vf",
                    f"scale={w}:{h}:force_original_aspect_ratio=decrease,pad={w}:{h}:(ow-iw)/2:(oh-ih)/2:color=0x141518,hue=s=0", str(out)], check=True)
    return out


NOTES = {
    "today": "Today. The world's labels float in the HUD's layer, the foe's card under VOID BREAKER; four HUD blocks on "
             "four edges (about 27% of the frame); the base a pale open plane; the player's avatar in front of the fight.",
    "A": "A · the crescent court + the HUD in corners. The fight and the training take a round court at the yard's "
         "middle; the machines stand in a crescent round it; the Generator raised behind it, the current drawn in the "
         "floor from each bay to it. HUD: the lead top left, the foe's thin bar top centre, the press over the right "
         "thumb; AUTO and the eye small at the top right; at rest the dock at the foot, the strip and one gains pill top right.",
    "B": "B · the terraces + the foot console. The plot rises in three steps: the plaza (arrival, the fight), the work "
         "terrace (+3: Breaker, Condenser, battery), the heart terrace (+7: the Generator, the four bays round it): "
         "the floor fills the frame to the Tower. HUD: only the foe on top; everything yours in one console between "
         "the thumbs, which holds the dock at rest.",
    "C": "C · two quarters on an avenue + the versus band. The way in runs straight to the Generator; the power quarter "
         "left (four bays in an arc round the battery, their current to the heart), the making quarter right "
         "(Breaker facing the avenue, Condenser, Training). HUD: both fighters' bars mirrored across the top, the "
         "press at the right thumb; at rest the dock a column at the left edge.",
}


def build(out, today=None, beside=()):
    out.mkdir(parents=True, exist_ok=True)
    shares = {}
    for key in PLANS:
        for state in ("rest", "fight"):
            svg, share = frame_svg(key, state)
            shares[(key, state)] = share
            sf.shoot(page(svg), out / f"{key}_{state}.png", W, H, scale=1.5)
        sf.shoot(page(plan_svg(key), 320, 320), out / f"{key}_plan.png", 320, 320, scale=1.5)
    sf.shoot(page(plan_svg("today"), 320, 320), out / "today_plan.png", 320, 320, scale=1.5)
    if today:
        grey_capture(today[0], out / "today_rest.png")
        grey_capture(today[1], out / "today_fight.png")
    rows = []
    keys = (["today"] if today else []) + list(PLANS)
    for key in keys:
        share = "" if key == "today" else (f"HUD's share of the frame: {shares[(key, 'fight')]:.0%} in a fight, "
                                           f"{shares[(key, 'rest')]:.0%} at rest")
        rows.append((key, NOTES[key], share))
    write_sheet(out, rows, beside)
    return shares


LEGEND = ("Greys by priority: <b>near white</b>, the lead's health and the signature's press (2nd after the fight); "
          "<b>mid grey</b>, the foe, the strip, the dock (3rd); <b>dark</b>, the quiet: AUTO, the eye, the gains pill, "
          "the world's markers. Dashed white: Roblox's own (its buttons, the thumbstick, jump) and the fight's place. "
          "The world in greys, the fighters darkest so the fight is the frame's strongest contrast. Sizes in points at "
          "a 16:9 phone's 568 x 320; the frames at 852 x 480.")


PAIRS = {"today": ("Anime Crusaders X, its hub at rest", "about 14%: two tile columns at the edges, the hotbar at the foot (OBSERVED)"),
         "A": ("Sailor Piece, a boss fight", "about 27%, in one column and the top centre (OBSERVED)"),
         "B": ("Jujutsu Infinite, a raid", "about 2%: one skill slot and a thin bar at the foot (OBSERVED)"),
         "C": ("Jujutsu Infinite, a boss", "about 5%: one thin bar top centre, three small slots at the foot (OBSERVED)")}


def write_sheet(out, rows, beside=None):
    """The sheet: each layout at rest, in a fight and from above; with `beside`, its paired shipped frame in grey at
    the same size between the fight and the plan (internal)."""
    def img(p, w):
        return f'<img src="{Path(p).as_uri()}" style="width:{w}px;display:block">'
    body = ['<h1>AR75, step 1: the whole frame in grey. Three layouts of the base and the HUD, beside today&#39;s.</h1>'
            f'<p>{LEGEND}</p>']
    for key, note, share in rows:
        cells = [f'<td><div class="l">at rest, from the spawn</div>{img(out / f"{key}_rest.png", 852)}</td>',
                 f'<td><div class="l">in a fight</div>{img(out / f"{key}_fight.png", 852)}</td>']
        if beside and key in beside:
            name, cover = PAIRS[key]
            cells.append(f'<td><div class="l">beside it: {name}, HUD {cover}</div>{img(beside[key], 852)}</td>')
        cells.append(f'<td><div class="l">the plot from above</div>{img(out / f"{key}_plan.png", 480)}</td>')
        body.append(f'<div class="row"><div class="note"><b>{note}</b><br>{share}</div><table><tr>{"".join(cells)}'
                    f'</tr></table></div>')
    width = 2240 + (870 if beside else 0)
    html = (f'<!doctype html><html><head><meta charset="utf-8"><style>{hm.css()} body{{margin:0;background:#141518;'
            f'color:#E8E2D6;font-family:Builder;font-size:17px}} td{{padding:5px;vertical-align:top}} .l{{margin:4px 0}}'
            f' h1{{font-size:26px;margin:16px 12px 4px}} p{{margin:0 12px 10px;color:#B9B2A6;max-width:2100px}}'
            f' .note{{margin:14px 12px 2px;max-width:{width - 40}px;color:#D9D3C7}} b{{color:#F2EADB}}</style></head><body>'
            f'{"".join(body)}</body></html>')
    name = "ar75_beside.png" if beside else "ar75_layouts.png"
    sf.shoot(html, out / name, width, 130 + len(rows) * 590, scale=1)


def main(args):
    beside, today = {}, None
    if "--beside" in args:
        i = args.index("--beside")
        pairs, args = args[i + 1:], args[:i]
        out0 = Path(args[0]).resolve()
        for kv in pairs:
            k, v = kv.split("=", 1)
            beside[k] = grey_capture(Path(v).resolve(), out0 / f"shipped_{k}.png")
    if "--today" in args:
        i = args.index("--today")
        today, args = (Path(args[i + 1]).resolve(), Path(args[i + 2]).resolve()), args[:i] + args[i + 3:]
    out = Path(args[0]).resolve()
    shares = build(out, today)
    if beside:
        rows = [(k, NOTES[k], "" if k == "today" else f"HUD's share of the frame: {shares[(k, 'fight')]:.0%} in a fight, "
                 f"{shares[(k, 'rest')]:.0%} at rest") for k in (["today"] if today else []) + list(PLANS)]
        write_sheet(out, rows, beside)
    for k, v in shares.items():
        print(k, f"{v:.1%}")


if __name__ == "__main__":
    main(sys.argv[1:])
