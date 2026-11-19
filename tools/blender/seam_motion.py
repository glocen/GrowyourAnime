"""AR43: Equipment's motion in Seam's lit glass (research's B, 15:04), as a clip for the director and a strip for
research: the screen opening from Home over the game, Reinforce idling, the rail switching to Jewels and then to War
Emblems, each idling. The beats are AR43's ("Equipment back in Seam, richer"); their numbers are MOTION, for Faber.

    blender -b --factory-startup --python tools/blender/seam_motion.py -- <abs out> [quick]

Writes <out>/frames/f0000.png and on (ffmpeg joins them into seam_motion.mp4; the frames are then deleted) and
seam_motion_strip.png, the opening's and a switch's beats side by side. "quick" writes the strip alone. The game behind
is Faber's phone capture of a fight (build/scratch/faber/stills/burst-phone.png), a stand-in only here.
"""

import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
import upgrade_pages as up  # noqa: E402
import equipment_pages as ep  # noqa: E402
import seam_kit as sk  # noqa: E402

W, H = up.W, up.H
K, FPS = 2, 30
MOTION = dict(
    open_time=0.22, open_rise=12.0,              # the screen rises 12 points as it fades in
    row_start=0.06, row_gap=0.035, row_time=0.20, row_from=24.0,   # the rows cascade in from 24 points left
    work_start=0.10, work_time=0.22,             # the work fades in
    ring_start=0.14, ring_time=0.30,             # the ring draws round once, clockwise from the top
    pop_start=0.14, pop_time=0.24, pop_from=0.8, pop_back=1.2,     # the gear pops in as the ring draws
    switch_time=0.18, switch_back=1.2,           # a rail button tapped grows as the last shrinks
    cross_time=0.18,                             # the rail and the rows crossfade; the work dips: out in the first
)                                                # half, the new page in over the second, never both at once
RING = (433.0, ep.TOP + 50.0, 27.0)              # Reinforce's ring: its middle and radius, in points
STATES = {"Reinforce": dict(ep.REINFORCE_STATES[0][1]),       # the blade chosen on each page
          "Jewels": dict(ep.JEWEL_STATES[1][1]),
          "War Emblems": dict(ep.EMBLEM_STATES[3][1])}
BEHIND = up.REPO / "build" / "scratch" / "faber" / "stills" / "burst-phone.png"
# The clip, in seconds: the game alone, the opening, Reinforce's one loop, the tap on Jewels, the tap on War Emblems.
OPEN_AT, JEWELS_AT, EMBLEMS_AT, END = 0.25, 3.15, 4.75, 6.35


def ease_out(u):
    u = np.clip(u, 0.0, 1.0)
    return 1 - (1 - u) ** 3


def ease_in_out(u):
    u = np.clip(u, 0.0, 1.0)
    return u * u * (3 - 2 * u)


def back_out(u, s):
    u = min(max(u, 0.0), 1.0)
    return 1 + (s + 1) * (u - 1) ** 3 + s * (u - 1) ** 2


def group(i):
    """Which layer a word moves with."""
    x, y = i["x"], i["y"]
    if y < ep.TOP - 4:
        return "band"
    if x < ep.LIST[0] - 2:
        return "rail"
    if x < ep.WORK[0] - 2:
        return f"row{int((y - ep.TOP - 4) // 50)}"
    return "work"


def paint(st, phase=0.0, sizes=None, bare=False):
    """The phone's paints at the idle's phase (its words left in the sheet's items): bare is the frame and the two
    panels, empty."""
    sk.NOW.update(phase=phase, sizes=sizes)
    sheet = ui.Sheet(W, H, "#000000")
    if bare:
        t = sheet.tile(0, 0, W, H)
        ep.frame(t, st["screen"])
        up.panel(t, ep.LIST[0], ep.TOP, ep.LIST[1], ep.FOOT)
        up.panel(t, ep.WORK[0], ep.TOP, ep.WORK[1], ep.FOOT)
    else:
        ep.phone(sheet, 0, 0, st)
    sk.NOW["sizes"] = None
    return sheet


def words(sheet):
    """The sheet's words, a layer per group, each a transparent picture the phone's size."""
    for i in sheet.items:
        i["layer"] = group(i)
    return ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items)


def shifted(img, dx, dy=0):
    """`img` moved by whole pixels, what comes in left clear."""
    out = np.zeros_like(img)
    h, w = img.shape[:2]
    dx, dy = int(round(dx)), int(round(dy))
    xs, xd = (slice(0, w - dx), slice(dx, w)) if dx >= 0 else (slice(-dx, w), slice(0, w + dx))
    ys, yd = (slice(0, h - dy), slice(dy, h)) if dy >= 0 else (slice(-dy, h), slice(0, h + dy))
    out[yd, xd] = img[ys, xs]
    return out


def over(dst, rgb, alpha):
    a = np.clip(alpha, 0, 1)[..., None]
    dst[..., :3] = rgb[..., :3] * a + dst[..., :3] * (1 - a)


def paste_words(dst, layers, names, alpha=1.0, dx=0, dy=0):
    for name in names:
        if name in layers:
            layer = shifted(layers[name], dx, dy)
            over(dst, layer, layer[..., 3] * alpha)


def behind():
    """Faber's fight capture, fitted to the phone's pixels by cover (nearest texel), a little dimmed as Home leaves it."""
    img = rs.load(BEHIND)
    h, w = img.shape[:2]
    scale = max(W * K / w, H * K / h)
    ys = np.clip(((np.arange(H * K) + 0.5) / scale + (h - H * K / scale) / 2).astype(int), 0, h - 1)
    xs = np.clip(((np.arange(W * K) + 0.5) / scale + (w - W * K / scale) / 2).astype(int), 0, w - 1)
    out = img[ys][:, xs].copy()
    out[..., 3] = 1.0
    return out


class Opening:
    """Reinforce's opening, composed from its full and bare paints and its words."""

    def __init__(self):
        st = STATES["Reinforce"]
        full = paint(st)
        self.layers = words(full)
        self.full = full.px.copy()
        self.bare = paint(st, bare=True).px.copy()
        diff = np.abs(self.full[..., :3] - self.bare[..., :3]).sum(-1)
        self.drawn = np.clip(diff / 0.05, 0, 1)
        yy, xx = np.mgrid[0:H * K, 0:W * K] / K
        self.x, self.y = xx, yy
        cx, cy, r = RING
        self.dist = np.hypot(xx - cx, yy - cy)
        self.turn = np.mod(np.arctan2(yy - cy, xx - cx) + math.pi / 2, 2 * math.pi) / (2 * math.pi)
        self.annulus = (self.dist > r - 6) & (self.dist < r + 6)
        self.gear = self.dist < r - 5
        self.work = (xx >= ep.WORK[0] - 2) & (yy >= ep.TOP - 2) & ~self.annulus & ~self.gear

    def screen(self, tau):
        m = MOTION
        out = self.bare.copy()
        for k in range(5):
            y0 = ep.TOP + 4 + k * 50
            band = (self.y >= y0 - 9) & (self.y < y0 + 55) & (self.x >= ep.LIST[0]) & (self.x < ep.LIST[1] + 10)
            a = ease_out((tau - m["row_start"] - k * m["row_gap"]) / m["row_time"])
            dx = -m["row_from"] * (1 - a) * K
            over(out, shifted(self.full, dx), shifted(self.drawn * band, dx) * a)
            paste_words(out, self.layers, [f"row{k}"], a, dx)
        a_work = ease_out((tau - m["work_start"]) / m["work_time"])
        over(out, self.full, self.drawn * self.work * a_work)
        sweep = ease_in_out((tau - m["ring_start"]) / m["ring_time"])
        reveal = np.clip((sweep - self.turn) * 40, 0, 1) if sweep < 1 else 1.0
        over(out, self.full, self.drawn * self.annulus * reveal)
        u = (tau - m["pop_start"]) / m["pop_time"]
        if u > 0:
            s = m["pop_from"] + (1 - m["pop_from"]) * back_out(u, m["pop_back"])
            cx, cy, _ = RING
            sx = np.clip(((cx + (self.x - cx) / s) * K).astype(int), 0, W * K - 1)
            sy = np.clip(((cy + (self.y - cy) / s) * K).astype(int), 0, H * K - 1)
            over(out, self.full[sy, sx], (self.drawn * self.gear)[sy, sx] * min(u * 3, 1.0))
        paste_words(out, self.layers, ["band", "rail"])
        paste_words(out, self.layers, ["work"], a_work)
        return out

    def frame(self, tau, back):
        m = MOTION
        a = ease_out(tau / m["open_time"])
        out = back.copy()
        screen = shifted(self.screen(tau), 0, m["open_rise"] * (1 - a) * K)
        over(out, screen, np.ones(out.shape[:2]) * a)
        return out


def idle(st, layers, phase):
    sheet = paint(st, phase)
    paste_words(sheet.px, layers, layers)
    return sheet.px


def switch(old, new, layers, u, phase):
    """The rail's tap: the tapped button grows (Back 1.2) as the last shrinks; the rail and the rows crossfade, and the
    work dips through its empty panel, so two pages' words never lie on each other."""
    m = MOTION
    e = back_out(u / m["switch_time"], m["switch_back"])
    sizes = {name: sk.RAIL_R for name, _ in sk.RAIL}
    sizes[old] = sk.RAIL_R_CHOSEN + (sk.RAIL_R - sk.RAIL_R_CHOSEN) * e
    sizes[new] = sk.RAIL_R + (sk.RAIL_R_CHOSEN - sk.RAIL_R) * e
    c = ease_in_out(u / m["cross_time"])
    gone = 1 - ease_in_out(2 * u / m["cross_time"])          # the old work, fading out over the first half
    come = ease_in_out(2 * u / m["cross_time"] - 1)          # the new, in over the second
    a, b = paint(STATES[old], phase, sizes).px, paint(STATES[new], phase, sizes).px
    bare = paint(STATES[new], phase, sizes, bare=True).px
    out = a * (1 - c) + b * c
    work = (np.arange(W * K) / K >= ep.WORK[0] - 2)[None, :, None]
    out = np.where(work, bare + (a - bare) * gone + (b - bare) * come, out)
    paste_words(out, layers[new], ["band"])
    paste_words(out, layers[old], ["rail"] + [f"row{k}" for k in range(5)], 1 - c)
    paste_words(out, layers[new], ["rail"] + [f"row{k}" for k in range(5)], c)
    paste_words(out, layers[old], ["work"], gone)
    paste_words(out, layers[new], ["work"], come)
    return out


def strip(out, opening, back, layers):
    """The opening's beats and a switch's, at half the clip's size, for research."""
    picks = [("open", t) for t in (0.0, 0.06, 0.12, 0.18, 0.26, 0.44)] + \
            [("switch", u) for u in (0.0, 0.04, 0.08, 0.12, 0.18, 0.30)]
    cw, ch, gap, head = W, H, 16, 64
    width = gap + 3 * (cw + gap)
    ui.K = 1
    sheet = ui.Sheet(width, head + 4 * (ch + 34) + 60, "#101117")
    t = sheet.tile(0, 0, sheet.px.shape[1], sheet.px.shape[0])
    t.text(gap, 16, 20, "AR43, Equipment's opening and the rail's switch, in Seam's lit glass (half the clip's size)",
           "#EDE6D6", bold=0.2)
    pics = []
    for n, (kind, at) in enumerate(picks):
        ui.K = K
        px = opening.frame(at, back) if kind == "open" else switch("Reinforce", "Jewels", layers, at, 0.0)
        half = px.astype(np.float32).reshape(H, K, W, K, 4).mean(axis=(1, 3))
        x, y = gap + (n % 3) * (cw + gap), head + (n // 3) * (ch + 34)
        pics.append((half, x, y + 22))
        label = f"Opening, {at:.2f} s" if kind == "open" else f"Tap on Jewels, {at:.2f} s"
        t.text(x, y, 14, label, "#B4AC9C")
    ui.K = 1
    for half, x, y in pics:
        rs.paste(sheet.px, half, x, y)
    notes = ["The screen rises 12 points as it fades in, 0.22 s; the rows cascade in from 24 points left, 0.035 s apart;",
             "the ring draws round once as the gear pops in (0.8 to 1, Back 1.2). The tapped button grows as the last "
             "shrinks, 0.18 s, Back 1.2; the rail and rows crossfade in 0.18 s, the work out then in, 0.09 s each."]
    for k, line in enumerate(notes):
        t.text(gap + 4, head + 4 * (ch + 34) + 6 + k * 22, 14, line, "#B4AC9C")
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "seam_motion_strip.png")
    ui.K = K


def main():
    out = bl.out_dir()
    quick = "quick" in sys.argv[sys.argv.index("--") + 1:]
    ui.K = K
    sk.wear("B")
    back = behind()
    opening = Opening()
    layers = {name: words(paint(st)) for name, st in STATES.items()}
    if quick or not (out / "frames").exists():
        strip(out, opening, back, layers)
    if quick:
        return
    frames = out / "frames"
    frames.mkdir(exist_ok=True)
    taps = [(JEWELS_AT, "Reinforce", "Jewels"), (EMBLEMS_AT, "Jewels", "War Emblems")]
    for n in range(int(END * FPS)):
        path = frames / f"f{n:04d}.png"
        if path.exists():                          # a run stopped part way goes on where it was
            continue
        now = n / FPS
        phase = max(now - OPEN_AT - 0.5, 0.0) / sk.LOOP % 1.0
        if now < OPEN_AT:
            px = back
        elif now < OPEN_AT + 0.5:
            px = opening.frame(now - OPEN_AT, back)
        else:
            page, px = "Reinforce", None
            for at, old, new in taps:
                if now >= at + 0.21:
                    page = new
                elif now >= at:
                    px = switch(old, new, layers, now - at, phase)
            if px is None:
                px = idle(STATES[page], layers[page], phase)
        rs.save(px.astype(np.float32), path)


if __name__ == "__main__":
    main()
