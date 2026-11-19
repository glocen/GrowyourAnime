"""AR43: Reinforce in motion, for research's verdict and the director's (docs/ui.md, rule 5; AR43, "Motion": a strip each
for the Menu opening, a tab switch, a press, a reinforce succeeding and one failing, with each beat's timing).

Here, the three that happen inside Reinforce: a press (a worn gear's row tapped), a reinforce that succeeds and one that
fails. The opening and the tab switch wait on the director's yes to Home (2026-11-19, 10:4x). Every part is drawn once by
upgrade_pages.py's own functions, its words set in one render a sheet, and every frame is laid from those pictures in
numpy, the effects drawn on each frame. The screen is upgrade_pages.py's: when its frame changes, these strips follow.

The levers, by strip:
    a press   the row squeezes as it's touched and springs back past its size (Back): that overshoot is the press's feel.
              The row's glass glides to it (ease-out, no overshoot: it's a marker, not a thing) and the work slides a
              few points as it crossfades. Nothing waits on the server.
    success   anticipation while the server answers: the press dims, a stone flies up into the ring (ease-in, sucked
              in), the ring breathes in (ease-in) and the gear rises a little. The hit on the server's yes: a flash, six
              sparks, the level pops at its rung in green, and the stat counts up. Follow-through: one shine crosses the
              gear. Settle: the glow falls, and the next rank's odds and cost fade in.
    fail      the same anticipation (the client can't know). Then quieter: a crack across the ring, the gear dims and
              sinks, a small shake; the level stays, in red. The cost counts down all the same.

Numbers: Config.Hud's Motion (Press, Count, Burst, Shine) and Pop, read from src/shared/Config/Hud.luau, never retyped.
The rest are this sheet's seeds (SEEDS), for Config.Hud.Motion when Faber builds them. The server answers at
SEEDS["Answer"], a stand-in for its round trip.

    blender -b --factory-startup --python tools/blender/upgrade_motion.py -- <abs out> [movie]

Writes upgrade_motion_<strip>.png, each strip's beats at the phone's size with their times, and upgrade_motion_close.png,
the hits at the phone's full pixels. With `movie`, instead upgrade_motion.mp4: each strip at real speed, then at a
quarter speed, at 60 frames a second. Its frames go through <out>/_frames, removed after; a run the memory guard stopped
goes on from the frames already there.
"""

import re
import shutil
import sys
from pathlib import Path

import bpy
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import frames_to_movie as fm  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
import upgrade_pages as up  # noqa: E402

W, H, K = up.W, up.H, 2
SMALL, TOP, FOOT = up.SMALL, up.TOP, up.FOOT
P = up.P                                   # the screen's own colours, Seam
GOOD, HURT = ui.GOOD, up.HURT
LIST, WORK = (up.STRIP + 6, 300), (306, 550)  # the list's and the work's panels, as upgrade_pages.menu lays them
FPS, SLOW = 60, 4
LEAD, TAIL = 0.25, 0.45                    # seconds of rest before a strip's touch and after its end
CAPTION = 28                               # points under the phone in the movie, for the strip's name

SEEDS = dict(
    Glide=0.2,       # a marker (a chosen row's glass) gliding to its new place, ease-out
    Slide=8.0,       # points the work slides as it crossfades
    Leave=0.1,       # the old work's fade, slow at first
    Cross=0.16,      # the new work's, from the touch
    Answer=0.4,      # the stand-in server's yes or no, from the touch
    Fly=0.22,        # a stone's flight from the cost's pill into the ring, ease-in; Stones of them, Apart apart
    Stones=3,
    Apart=0.035,
    Wave=26.0,       # a success: a ring of light thrown out from the ring this many points, over WaveFor
    WaveFor=0.32,
    Inhale=16.0,     # how far outside the ring its breath starts, in points
    Lift=0.05,       # how much the gear grows while it charges
    Pending=0.6,     # the press's light while the server answers
    Flash=0.14,      # the hit's flash
    Kick=0.1,        # a success: the gear's pop, of its size
    Texts=0.3,       # a success: the next rank's lines fade in this long after the yes (a fail's, at half)
    Crack=0.06,      # a fail: the crack draws across the ring, then fades over CrackFade
    CrackFade=0.4,
    Dim=0.55,        # a fail: the gear's light at its lowest
    Sink=0.04,       # a fail: how much the gear shrinks
    Shake=2.0,       # a fail: the work's shake, in points, three swings over ShakeFor
    ShakeFor=0.24,
    Settle=0.8,      # a success's glow, gone by then
)
S = SEEDS
CRACK = [(-22, -9), (-10, -2), (-5, -8), (3, 2), (8, -2), (22, 10)]  # a fail's crack, inside the ring, from its middle

HELM = dict(slot="Helmet", rank=(5, 6), stat=("Health", "1,840", "1,932", "+92"), stone="Mid", need=4, have=14,
            credits="900", rate=80)    # stand-ins; Helmet's stat is Health (Config.Chests), +5 to +6 research's 80%
READY, ROSE, FAILED = up.READY, up.STATES[3][1], up.STATES[4][1]


def config():
    """Config.Hud's Motion and Pop, as the game reads them."""
    src = (up.REPO / "src" / "shared" / "Config" / "Hud.luau").read_text(encoding="utf-8")
    motion = src[src.index("\tMotion = {"):]

    def table(text, name):
        body = re.search(rf"\b{name} = \{{([^{{}}]*)\}}", text).group(1)
        return {k: float(v) for k, v in re.findall(r"(\w+) = (-?[\d.]+)", body)}

    got = {name: table(motion, name) for name in ("Press", "Count", "Burst", "Shine")}
    at = src.index("\tPop = {")
    pop = src[at:src.index("\n\t}", at)]
    got["Pop"] = {k: float(v) for k, v in re.findall(r"^\t\t(\w+) = (-?[\d.]+),", pop, re.M)}
    got["Pop"]["Level"] = table(pop, "Rungs")["Level"]
    return got


C = config()


def stage(words):
    """A line in the log with this process's memory, so a stop by the memory guard says where it came."""
    import ctypes
    from ctypes import wintypes

    class Counters(ctypes.Structure):
        _fields_ = [("cb", wintypes.DWORD), ("faults", wintypes.DWORD)] + [
            (name, ctypes.c_size_t) for name in ("peak", "now", "a", "b", "c", "d", "e", "f")]

    got = Counters()
    got.cb = ctypes.sizeof(got)
    kernel, psapi = ctypes.windll.kernel32, ctypes.windll.psapi
    kernel.GetCurrentProcess.restype = wintypes.HANDLE
    psapi.GetProcessMemoryInfo.argtypes = [wintypes.HANDLE, ctypes.POINTER(Counters), wintypes.DWORD]
    psapi.GetProcessMemoryInfo(kernel.GetCurrentProcess(), ctypes.byref(got), got.cb)
    print(f"[motion] {words}: {got.now / 2 ** 20:.0f} MB (peak {got.peak / 2 ** 20:.0f})", flush=True)


# --- easing ---------------------------------------------------------------------------------------------------------

def span(t, a, d):
    return float(np.clip((t - a) / d, 0.0, 1.0)) if d > 0 else float(t >= a)


def out3(u):
    return 1 - (1 - u) ** 3


def in3(u):
    return u ** 3


def smooth(u):
    return u * u * (3 - 2 * u)


def back_out(u, s):
    v = u - 1
    return 1 + (s + 1) * v ** 3 + s * v ** 2


def expo_out(u):
    return 1.0 if u >= 1 else 1 - 2 ** (-10 * u)


def squeeze(t):
    """A press's size at t seconds from the touch (Config.Hud.Motion.Press)."""
    p = C["Press"]
    s = p["Squeeze"]
    if t < 0:
        return 1.0
    if t < p["In"]:
        return 1 - (1 - s) * out3(t / p["In"])
    if t < p["Least"]:
        return s
    return s + (1 - s) * back_out(span(t, p["Least"], p["Out"]), p["Back"])


def swell(age):
    """A pop's shape, 0 to 1 to 0: up to its peak eased out, settled eased in and out (Config.Hud.Pop)."""
    p = C["Pop"]
    peak = p["Peak"] * p["Seconds"]
    if age < 0 or age >= p["Seconds"]:
        return 0.0
    if age < peak:
        return out3(age / peak)
    return 1 - smooth((age - peak) / (p["Seconds"] - peak))


def popped(age):
    """A level's size as it pops at its rung."""
    return 1 + C["Pop"]["Swell"] * (C["Pop"]["Level"] - 1) * swell(age)


def shake(age):
    f = S["ShakeFor"]
    if age < 0 or age > f:
        return 0.0
    return S["Shake"] * float(np.sin(age / f * 3 * 2 * np.pi)) * (1 - age / f)


# --- pictures -------------------------------------------------------------------------------------------------------

class Pic:
    """A picture premultiplied by its cover, its corner at x, y in the phone's pixels."""

    def __init__(self, px, x=0, y=0):
        self.px, self.x, self.y = px, x, y


def canvas(tall=H):
    return np.zeros((round(tall * K), W * K, 4), dtype=np.float32)


def scaled(px, cx, cy, s):
    """A premultiplied picture drawn s times its size about its own pixel cx, cy."""
    px = px.astype(np.float32)
    tall, wide = px.shape[:2]
    ys, xs = np.mgrid[0:tall, 0:wide].astype(np.float32)
    sx, sy = cx + (xs + 0.5 - cx) / s - 0.5, cy + (ys + 0.5 - cy) / s - 0.5
    x0, y0 = np.floor(sx).astype(int), np.floor(sy).astype(int)
    fx, fy = (sx - x0)[..., None], (sy - y0)[..., None]
    pad = np.pad(px, ((1, 1), (1, 1), (0, 0)))
    x0, y0 = np.clip(x0 + 1, 0, wide), np.clip(y0 + 1, 0, tall)
    return ((pad[y0, x0] * (1 - fx) + pad[y0, x0 + 1] * fx) * (1 - fy)
            + (pad[y0 + 1, x0] * (1 - fx) + pad[y0 + 1, x0 + 1] * fx) * fy)


def put(dst, pic, dx=0.0, dy=0.0, alpha=1.0, scale=1.0, about=None, dim=1.0):
    """Lays a picture over dst, moved dx, dy points, `scale` times its size about the phone's point `about` (its own
    middle when None), its light times `dim`."""
    if alpha <= 0:
        return
    src = pic.px
    x0, y0 = round(pic.x + dx * K), round(pic.y + dy * K)
    if scale != 1.0:
        ax, ay = (src.shape[1] / 2, src.shape[0] / 2) if about is None else (about[0] * K - x0, about[1] * K - y0)
        src = scaled(src, ax, ay, scale)
    h, w = src.shape[:2]
    a0, b0, a1, b1 = max(x0, 0), max(y0, 0), min(x0 + w, dst.shape[1]), min(y0 + h, dst.shape[0])
    if a1 <= a0 or b1 <= b0:
        return
    s = src[b0 - y0:b1 - y0, a0 - x0:a1 - x0].astype(np.float32)
    d = dst[b0:b1, a0:a1]
    cover = s[..., 3:] * alpha
    d[..., :3] = s[..., :3] * (alpha * dim) + d[..., :3] * (1 - cover)
    d[..., 3:] = cover + d[..., 3:] * (1 - cover)


def fx(cx, cy, r, draw):
    """An effect drawn round the phone's point cx, cy, `r` points every way: draw(tile, centre)."""
    sh = ui.Sheet(2 * r, 2 * r, "#000000")
    sh.px[:] = 0
    draw(sh.tile(0, 0, 2 * r, 2 * r), np.array([r, r], dtype=np.float32))
    px = sh.px
    px[..., :3] *= px[..., 3:]
    return Pic(px, round((cx - r) * K), round((cy - r) * K))


# --- baking: each part drawn once, its words set in one render a sheet ----------------------------------------------

class Job:
    def __init__(self, name, draw=None, keep=None, items=(), origin=(0, 0)):
        self.name, self.draw, self.keep, self.items, self.origin = name, draw, keep or (lambda i: True), items, origin


def bake(jobs, slot=(W, H), across=3, rows=2, gap=8):
    """Each job's picture, cropped to what it covers. A job draws in a slot of its own; its words are kept by `keep`,
    and `items` are words given outright, in the slot's points."""
    ui.K = K
    out = {}
    sw, sh = slot
    for at in range(0, len(jobs), across * rows):
        book = jobs[at:at + across * rows]
        down = (len(book) + across - 1) // across
        sheet = ui.Sheet(across * (sw + gap), down * (sh + gap), "#000000")
        sheet.px[:] = 0
        spots = []
        for k, j in enumerate(book):
            ox, oy = (k % across) * (sw + gap), (k // across) * (sh + gap)
            spots.append((ox, oy))
            if j.draw:
                n = len(sheet.items)
                j.draw(sheet.tile(ox, oy, sw, sh))
                made = sheet.items[n:]
                del sheet.items[n:]
                sheet.items += [i for i in made if j.keep(dict(i, x=i["x"] - ox, y=i["y"] - oy))]
            sheet.items += [dict(i, x=i["x"] + ox, y=i["y"] + oy) for i in j.items]
        if sheet.items:
            for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
                ui.over(sheet.px, layer[..., :3], layer[..., 3])
        sheet.px[..., :3] *= sheet.px[..., 3:]
        for j, (ox, oy) in zip(book, spots):
            x0, y0 = round(ox * K), round(oy * K)
            px = sheet.px[y0:y0 + round(sh * K), x0:x0 + round(sw * K)]
            seen = np.argwhere(px[..., 3] > 1 / 512)
            if not len(seen):
                out[j.name] = Pic(np.zeros((1, 1, 4), dtype=np.float32))
                continue
            (r0, c0), (r1, c1) = seen.min(0), seen.max(0)
            r0, c0, r1, c1 = max(r0 - 12, 0), max(c0 - 12, 0), min(r1 + 13, px.shape[0]), min(c1 + 13, px.shape[1])
            out[j.name] = Pic(px[r0:r1, c0:c1].astype(np.float16), c0 - round(j.origin[0] * K),
                              r0 - round(j.origin[1] * K))         # half precision: the PC's memory is short
        del sheet
        stage(f"baked {', '.join(str(j.name)[:24] for j in book[:2])}")
    return out


def stamp_key(i):
    return i["text"], i["colour"], i["size"], i["align"], i["bold"]


def stamp_job(i):
    """A line of words alone, anchored where its item stands: laid with put(dst, pic, item x, item y)."""
    ax = {"LEFT": 10, "CENTER": 100, "RIGHT": 190}[i["align"]]
    return Job(stamp_key(i), items=[dict(i, x=ax, y=10)], origin=(ax, 10))


def word(x, y, size, text, colour, align="LEFT", bold=0.0):
    return dict(x=x, y=y, size=size, text=text, colour=colour, align=align, layer="plain", shear=0.0, bold=bold)


def dry(draw):
    """The words a drawing sets, where it sets them, in the phone's points."""
    sheet = ui.Sheet(W, H, "#000000")
    draw(sheet.tile(0, 0, W, H))
    return sheet.items


class patched:
    """upgrade_pages' own functions swapped for a while (work() calls them by name)."""

    def __init__(self, **fns):
        self.fns = fns

    def __enter__(self):
        self.old = {k: getattr(up, k) for k in self.fns}
        for k, v in self.fns.items():
            setattr(up, k, v)

    def __exit__(self, *_):
        for k, v in self.old.items():
            setattr(up, k, v)


def nothing(*_, **__):
    return None


SEEN = {}


def bare_work(t, st):
    """upgrade_pages.work without its panel, its ring, its gear and its press: SEEN says where those stand."""
    real_cell = up.cell

    def cell(t_, x, y, s, rarity, image, rank=None):
        if s == 40:
            SEEN["gear"] = (x, y, s, rarity, image)
            return None
        SEEN["stone"] = (x, y, s, image)
        return real_cell(t_, x, y, s, rarity, image, rank)

    def ring(t_, cx, cy, r, lit):
        SEEN["ring"] = (cx, cy, r)

    def press(t_, *a, **k):
        SEEN["press"] = (a, k)

    real_pic = up.pic

    def pic(t_, path, x, y, size, tint=None, alpha=1.0):
        if Path(path).name.startswith("Stone") and size == 22:     # the cost's pill
            SEEN["pill"] = (x, y, size, path)
        return real_pic(t_, path, x, y, size, tint, alpha)

    with patched(cell=cell, ring=ring, press=press, panel=nothing, pic=pic):
        up.work(t, st, *WORK)


def full_work(t, st):
    with patched(panel=nothing):
        up.work(t, st, *WORK)


def is_static(i):
    """The work's words that never change here: the gear's name, the two Reinforce, the dot between the odds."""
    return i["y"] in (TOP + 6, TOP + 28) or i["text"] == "·"


def is_left(i):
    """The level and the stat now, on the work's left: they pop and count."""
    return i["x"] == WORK[0] + 10 and i["y"] in (TOP + 44, TOP + 66)


# --- the list's parts, as upgrade_pages.gear_list lays them -----------------------------------------------------------

def row_y(k):
    return TOP + 4 + k * 50


def row_middle(k):
    return (LIST[0] + LIST[1]) / 2, row_y(k) + 23


def level_word(k, level, colour):
    return word(LIST[0] + 54 + up.wide_of("Reinforce", SMALL) * 0.8 + 3, row_y(k) + 24, SMALL, f"+{level}", colour,
                bold=0.35)


def list_part(t, part, k=0):
    x0, x1 = LIST
    if part == "panel":
        up.panel(t, x0, TOP, x1, FOOT)
        return
    rows = t.sheet.tile(t.ox, t.oy, W, FOOT - 1)
    y = row_y(k)
    if part == "glass":
        up.tab_glass(rows, x0 + 3, y, x1 - 3, y + 46)
        rows.paint(rows.poly([(x1 - 3, y + 15), (x1 + 6, y + 23), (x1 - 3, y + 31)]), P["light"])
    elif part == "well":
        up.box(rows, x0 + 3, y, x1 - 3, y + 46, P["well"], P["edge"], 1.0, cuts=(6, 0, 0, 0))
    else:
        slot, name, rarity, image, level = up.WORN[k]
        up.cell(rows, x0 + 6, y + 3, 40, rarity, up.GEAR / image)
        if y + 40 > FOOT:
            return
        rows.text(x0 + 54, y + 5, SMALL, name, P["text"], bold=0.3)
        rows.text(x0 + 54, y + 24, SMALL, "Reinforce", P["soft"])
        if part == "front":
            i = level_word(k, level, P["light"])
            rows.text(i["x"], i["y"], SMALL, i["text"], i["colour"], bold=i["bold"])


# --- the layers -------------------------------------------------------------------------------------------------------

L, STAMPS, COUNTS = {}, {}, {}


def make(times):
    """Every picture the strips lay. `times` are every moment a strip is drawn at, for the counted numbers' stamps."""
    band_items = dry(lambda t: up.band(t, "Equipment"))
    credits = next(i for i in band_items if i["text"][:1].isdigit() and "," in i["text"])
    ready_items = dry(lambda t: bare_work(t, READY))
    texts = {name: [i for i in dry(lambda t, st=st: bare_work(t, st)) if not is_static(i) and not is_left(i)]
             for name, st in (("ready", READY), ("rose", ROSE), ("failed", FAILED))}
    level, stat = sorted((i for i in ready_items if is_left(i)), key=lambda i: i["y"])
    (gx, gy, gs, rarity, image), (sx, sy, ss, stone) = SEEN["gear"], SEEN["pill"]
    cx, cy, r = SEEN["ring"]
    args, kws = SEEN["press"]
    real_press, real_ring = up.press, up.ring
    stage("the words found")
    jobs = [
        Job("band", lambda t: up.band(t, "Equipment"), keep=lambda i: i["text"] != credits["text"]),
        Job("tabs", lambda t: up.tabs(t, "Equipment")),
        Job("pages", lambda t: up.pages(t, "Equipment", "Reinforce")),
        Job("list_panel", lambda t: list_part(t, "panel")),
        Job("row_glass", lambda t: list_part(t, "glass", 0)),
        Job("work_panel", lambda t: up.panel(t, WORK[0], TOP, WORK[1], FOOT)),
        Job("work_static", lambda t: bare_work(t, READY), keep=is_static),
        Job("gear", lambda t: up.cell(t, gx, gy, gs, rarity, image)),
        Job("stone", lambda t: up.pic(t, stone, sx, sy, ss)),
        Job("press", lambda t: real_press(t, *args, **kws)),
        Job("work_ready", lambda t: full_work(t, READY)),
        Job("work_helm", lambda t: full_work(t, HELM)),
    ]
    jobs += [Job(f"ring_{name}", lambda t, lit=lit: real_ring(t, cx, cy, r, lit))
             for name, lit in (("light", None), ("good", GOOD), ("hurt", HURT))]
    jobs += [Job(f"texts_{name}", items=items) for name, items in texts.items()]
    for k in range(len(up.WORN)):
        jobs += [Job(f"well{k}", lambda t, k=k: list_part(t, "well", k)),
                 Job(f"front{k}", lambda t, k=k: list_part(t, "front", k))]
    jobs.append(Job("front0_bare", lambda t: list_part(t, "bare", 0)))
    L.update(bake(jobs, across=2, rows=1))        # small books: the PC has little memory free beside two Studios

    a = S["Answer"]
    count = C["Count"]["Seconds"]
    cost, start = int(READY["credits"].replace(",", "")), int(credits["text"].replace(",", ""))
    now, after = (int(v.replace(",", "")) for v in (READY["stat"][1], ROSE["stat"][1]))
    COUNTS["credits"] = sorted({round(start - cost * expo_out(span(t, a, count))) for t in times} | {start, start - cost})
    COUNTS["stat"] = sorted({round(now + (after - now) * expo_out(span(t, a, count))) for t in times} | {now, after})
    words = {
        "level": [dict(level, text=f"+{READY['rank'][0]}"), dict(level, text=f"+{ROSE['rank'][0]}", colour=GOOD),
                  dict(level, text=f"+{READY['rank'][0]}", colour=HURT)],
        "row": [level_word(0, READY["rank"][0], P["light"]), level_word(0, ROSE["rank"][0], GOOD),
                level_word(0, READY["rank"][0], HURT)],
        "credits": [dict(credits, text=f"{v:,}") for v in COUNTS["credits"]],
        "stat": [dict(stat, text=f"{READY['stat'][0]} {v:,}") for v in COUNTS["stat"]],
        "caption": [word(12, H + 7, SMALL, f"{n + 1}. {name}, {speed}", "#B4AC9C")
                    for n, (_, name, *_) in enumerate(STRIPS) for speed in ("real speed", "a quarter speed")],
    }
    jobs = {stamp_key(i): stamp_job(i) for name, group in words.items() if name != "caption" for i in group}
    STAMPS.update(bake(list(jobs.values()), slot=(200, 40), across=10, rows=5))
    wide = [stamp_job(i) for i in words["caption"]]           # a caption is longer than a number's slot
    STAMPS.update(bake(wide, slot=(W, 30), across=1, rows=len(wide)))
    WORDS.update(words)
    GEO.update(ring=(cx, cy, r), gear=(gx + gs / 2, gy + gs / 2), stone=(sx + ss / 2, sy + ss / 2),
               press=((args[0] + args[2]) / 2, (args[1] + args[3]) / 2), cost=cost, start=start, now=now, after=after)


WORDS, GEO = {}, {}


def made(times, out):
    """make(), or what an earlier run made, kept beside the frames while this script, the pages' and Config.Hud are
    unchanged: a run stopped by the memory guard starts again without Blender's text renders, the heaviest part."""
    import hashlib
    import pickle

    here = Path(__file__).resolve().parent
    sources = [Path(__file__).resolve(), here / "upgrade_pages.py", here / "ui_sheet.py",
               up.REPO / "src" / "shared" / "Config" / "Hud.luau"]
    key = hashlib.sha1(b"".join(p.read_bytes() for p in sources)).hexdigest()
    path = out / "_motion_bake.pkl"
    if path.exists():
        with path.open("rb") as f:
            kept = pickle.load(f)
        if kept["key"] == key:
            for name, store in (("L", L), ("STAMPS", STAMPS), ("COUNTS", COUNTS), ("WORDS", WORDS), ("GEO", GEO)):
                store.update(kept[name])
            print("[motion] the bake kept from the last run", flush=True)
            return
    make(times)
    with path.open("wb") as f:
        pickle.dump(dict(key=key, L=L, STAMPS=STAMPS, COUNTS=COUNTS, WORDS=WORDS, GEO=GEO), f)


def stamp(group, k):
    i = WORDS[group][k]
    return STAMPS[stamp_key(i)], i["x"], i["y"]


def counted(group, value):
    """The stamp of a counted number nearest `value`."""
    values = COUNTS[group]
    k = int(np.argmin(np.abs(np.array(values) - value)))
    return stamp(group, k)


def lay(dst, got, alpha=1.0, scale=1.0, dx=0.0):
    pic, x, y = got
    put(dst, pic, x + dx, y, alpha=alpha, scale=scale)


# --- the strips -------------------------------------------------------------------------------------------------------

BASES = {}


def ground():
    """The screen without what moves: its backing, the band (its Credits laid apart), the tabs, the pages, the two
    panels."""
    c = canvas()
    c[..., :3], c[..., 3] = ui.c(P["backing"]), 1.0
    for name in ("band", "tabs", "pages", "list_panel", "work_panel"):
        put(c, L[name])
    return c


def frame_base():
    """The press's: the ground with its Credits; the rows move."""
    if "frame" not in BASES:
        BASES["frame"] = ground()
        lay(BASES["frame"], counted("credits", GEO["start"]))
    return BASES["frame"].copy()


def reinforce_base():
    """A reinforce's: the ground with the rows, the blade chosen; its Credits and its level count on each frame."""
    if "reinforce" not in BASES:
        c = ground()
        for k in range(len(up.WORN)):
            put(c, L[f"well{k}"])
        put(c, L["row_glass"])
        for k in range(len(up.WORN)):
            put(c, L["front0_bare" if k == 0 else f"front{k}"])
        BASES["reinforce"] = c
    return BASES["reinforce"].copy()


def strip_press(t):
    """A worn gear's row tapped: the helmet, while the blade is chosen."""
    dst, chosen = frame_base(), 2
    g = out3(span(t, 0, S["Glide"]))
    for k in range(len(up.WORN)):
        if k != chosen:
            put(dst, L[f"well{k}"])
    put(dst, L[f"well{chosen}"], scale=squeeze(t), about=row_middle(chosen))
    put(dst, L["row_glass"], dy=(row_y(chosen) - row_y(0)) * g)
    for k in range(len(up.WORN)):
        if k != chosen:
            put(dst, L[f"front{k}"])
    put(dst, L[f"front{chosen}"], scale=squeeze(t), about=row_middle(chosen))
    o, n = smooth(span(t, 0, S["Leave"])), out3(span(t, 0, S["Cross"]))   # no dip: the new one starts on the touch
    put(dst, L["work_ready"], dx=-S["Slide"] * o, alpha=1 - o)
    put(dst, L["work_helm"], dx=S["Slide"] * (1 - n), alpha=n)
    return dst


def strip_reinforce(t, won):
    dst = reinforce_base()
    a = S["Answer"]
    age = t - a
    cx, cy, r = GEO["ring"]
    count = C["Count"]["Seconds"]
    e = expo_out(span(t, a, count))
    lay(dst, counted("credits", GEO["start"] - GEO["cost"] * e))   # the cost leaves on the answer, either way
    turn = out3(span(t, a, 0.08))
    if won:
        lay(dst, stamp("row", 0), alpha=1 - turn)
        lay(dst, stamp("row", 1), alpha=turn, scale=popped(age))
    else:
        lay(dst, stamp("row", 0), alpha=1 - turn)
        lay(dst, stamp("row", 2), alpha=turn)
    sx = 0.0 if won else shake(age)
    put(dst, L["work_static"], dx=sx)
    put(dst, L["ring_light"], dx=sx, alpha=1 - turn)
    put(dst, L["ring_good" if won else "ring_hurt"], dx=sx, alpha=turn)
    # anticipation: the ring breathes in while the server answers
    if 0.06 <= t < a + 0.03:
        u = span(t, 0.06, a - 0.06)

        def breath(tile, c):
            rr = r + S["Inhale"] * (1 - in3(u))
            d = np.hypot(tile.x - c[0], tile.y - c[1]) - rr
            tile.glow(np.abs(d) - 0.8, 4.0, P["light"], 0.35 * u)
            tile.paint(np.abs(d) - 0.8, P["light"], 0.25 + 0.6 * u)
            tile.paint(np.hypot(tile.x - c[0], tile.y - c[1]) - (r - 2), P["glint"], 0.14 * u)
        put(dst, fx(cx, cy, r + S["Inhale"] + 12, breath), dx=sx)
    # the gear: it rises as it charges, then pops (a success) or dims and sinks (a fail)
    rise = 1 + S["Lift"] * in3(span(t, 0.06, a - 0.06))
    gear, dim = L["gear"], 1.0
    if age >= 0 and won:
        rise = 1 + S["Lift"] * (1 - out3(span(age, 0, C["Pop"]["Seconds"]))) + S["Kick"] * swell(age)
        sh = C["Shine"]
        u = span(age, sh["Delay"], sh["Seconds"])
        if 0 < u < 1:
            gear = shine(gear, u)
    elif age >= 0:
        rise = 1 + S["Lift"] - (S["Lift"] + S["Sink"]) * out3(span(age, 0, 0.1)) + S["Sink"] * smooth(span(age, 0.15, 0.4))
        dim = 1 - (1 - S["Dim"]) * (out3(span(age, 0, 0.08)) - smooth(span(age, 0.2, 0.45)))
    put(dst, gear, dx=sx, scale=rise, about=(GEO["gear"][0] + sx, GEO["gear"][1]), dim=dim)
    # the cost goes in: stones leave the pill and arc up into the ring, sucked in (ease-in)
    (fx0, fy0), (fx1, fy1) = GEO["stone"], (cx, cy)
    for k in range(int(S["Stones"])):
        u = span(t, k * S["Apart"], S["Fly"])
        if not 0 < u < 1:
            continue
        e2 = u * u
        bend = (fx0, fy1)                          # the arc rises first, then turns in toward the ring
        x = (1 - e2) ** 2 * fx0 + 2 * (1 - e2) * e2 * bend[0] + e2 ** 2 * fx1
        y = (1 - e2) ** 2 * fy0 + 2 * (1 - e2) * e2 * bend[1] + e2 ** 2 * fy1
        put(dst, L["stone"], dx=x - fx0, dy=y - fy0, scale=1 - 0.4 * e2, about=(x, y),
            alpha=1.0 if u < 0.75 else 1 - (u - 0.75) / 0.25)
    # the hit
    if age >= 0:
        f = (1 - span(age, 0, S["Flash"])) ** 2
        if won and f > 0:
            def flash(tile, c):
                d = np.hypot(tile.x - c[0], tile.y - c[1]) - (r - 1)
                tile.glow(d, 6.0, "#FFFFFF", 0.6 * f)
                tile.paint(d, "#FFFFFF", 0.85 * f)
            put(dst, fx(cx, cy, r + 24, flash))
        elif f > 0:
            def dull(tile, c):
                d = np.hypot(tile.x - c[0], tile.y - c[1]) - (r - 1)
                tile.paint(d, "#FFD2CC", 0.3 * f)
            put(dst, fx(cx, cy, r + 4, dull), dx=sx)
        if won and age < S["WaveFor"]:
            v = age / S["WaveFor"]

            def wave(tile, c):
                rr = r + S["Wave"] * out3(v)
                d = np.abs(np.hypot(tile.x - c[0], tile.y - c[1]) - rr) - (0.4 + 2.2 * (1 - v))
                tile.glow(d, 4.0, GOOD, 0.5 * (1 - v))
                tile.paint(d, tile.ramp("#FFFFFF", GOOD, np.full(tile.x.shape, min(v * 2.5, 1.0))), (1 - v) ** 1.5)
            put(dst, fx(cx, cy, int(r + S["Wave"] + 10), wave))
        b = C["Burst"]
        if won and age < b["Seconds"]:
            v = age / b["Seconds"]
            put(dst, fx(cx, cy, int(r + b["Reach"] + b["Size"] + 6), lambda tile, c: sparks(tile, c, r, v)))
        if not won and age < S["Crack"] + S["CrackFade"]:
            grow, fade = span(age, 0, S["Crack"]), span(age, S["Crack"], S["CrackFade"])
            put(dst, fx(cx, cy, 44, lambda tile, c: crack(tile, c, grow, fade)), dx=sx)
    # the words: the level pops (or turns red), the stat counts, the next rank's lines fade in
    if won:
        lay(dst, stamp("level", 0), alpha=1 - turn)
        lay(dst, stamp("level", 1), alpha=turn, scale=popped(age))
        lay(dst, counted("stat", GEO["now"] + (GEO["after"] - GEO["now"]) * e))
    else:
        lay(dst, stamp("level", 0), dx=sx, alpha=1 - turn)
        lay(dst, stamp("level", 2), dx=sx, alpha=turn)
        lay(dst, counted("stat", GEO["now"]), dx=sx)
    later = out3(span(age, S["Texts"] * (1 if won else 0.5), S["Cross"]))
    put(dst, L["texts_ready"], dx=sx, alpha=1 - later)
    put(dst, L["texts_rose" if won else "texts_failed"], dx=sx, alpha=later)
    # the press: it squeezes, and its light waits on the answer
    p = C["Press"]
    dim = 1.0 if t < p["Least"] else S["Pending"] + (1 - S["Pending"]) * span(t, a, 0.1)
    put(dst, L["press"], dx=sx, scale=squeeze(t), about=(GEO["press"][0] + sx, GEO["press"][1]), dim=dim)
    return dst


def shine(pic, u):
    """One light band across a picture, leaning Angle, Width of it across (Config.Hud.Motion.Shine)."""
    sh = C["Shine"]
    px = pic.px.astype(np.float32)
    tall, wide = px.shape[:2]
    ys, xs = np.mgrid[0:tall, 0:wide].astype(np.float32) / K
    q = xs - (ys - tall / K / 2) * np.tan(np.radians(sh["Angle"]))
    size = wide / K
    at = -0.2 * size + 1.4 * size * smooth(u)
    band = np.clip(1 - np.abs(q - at) / (sh["Width"] * size / 2 + 1), 0, 1) * 0.8
    px[..., :3] += (px[..., 3:] - px[..., :3]) * band[..., None]
    return Pic(px, pic.x, pic.y)


def sparks(tile, c, r, v):
    """Config.Hud.Motion.Burst's sparks, flung from the ring's edge, slowing and shrinking."""
    b = C["Burst"]
    n = int(b["Count"])
    for k in range(n):
        ang = k * 2 * np.pi / n
        d = np.array([np.cos(ang), np.sin(ang)], dtype=np.float32)
        s = b["Size"] * (1 - v) ** 0.8
        p0 = c + d * (r - 4 + b["Reach"] * out3(v))
        p1, mid, side = p0 + d * s, p0 + d * s * 0.4, np.array([-d[1], d[0]]) * s * 0.18
        poly = tile.poly([tuple(p0), tuple(mid + side), tuple(p1), tuple(mid - side)])
        tile.glow(poly, 3.0, GOOD, 0.5 * (1 - v))
        tile.paint(poly, GOOD, (1 - v) ** 0.5)
        tile.stroke([tuple(p0 + d * s * 0.2), tuple(p0 + d * s * 0.7)], max(s * 0.08, 0.4), "#FFFFFF", (1 - v) ** 0.5)


def crack(tile, c, grow, fade):
    """A fail's crack, drawn across the ring over `grow` and gone with `fade`."""
    pts = [c + np.array(p, dtype=np.float32) for p in CRACK]
    lengths = [float(np.hypot(*(b - a))) for a, b in zip(pts, pts[1:])]
    left = grow * sum(lengths)
    part = [tuple(pts[0])]
    for (a, b), n in zip(zip(pts, pts[1:]), lengths):
        if left <= 0:
            break
        part.append(tuple(a + (b - a) * min(left / n, 1.0)))
        left -= n
    if len(part) < 2:
        return
    alpha = 1 - fade
    d = np.minimum.reduce([ui.sd_segment(tile.x, tile.y, a, b) for a, b in zip(part, part[1:])])
    tile.glow(d - 0.8, 2.5, HURT, 0.4 * alpha)
    tile.stroke(part, 1.6, HURT, 0.85 * alpha)
    tile.stroke(part, 0.6, "#FFE2DC", 0.7 * alpha)


A = SEEDS["Answer"]
STRIPS = [
    ("press", "A press: a worn gear's row tapped", strip_press, 0.5, [
        (-0.1, "at rest: the blade chosen"), (0.03, "touched: the helmet's row sinks"),
        (0.06, "squeezed; the glass sets off, the blade's work leaves"), (0.1, "released: the helmet's work slides in"),
        (0.15, "past its size (Back)"), (0.2, "the glass arrives"), (0.25, "settled"), (0.45, "at rest")]),
    ("success", "A reinforce that succeeds", lambda t: strip_reinforce(t, True), A + 1.2, [
        (-0.1, "at rest"), (0.04, "touched: the press sinks"), (0.15, "the cost's stones arc into the ring"),
        (0.32, "the ring breathes in, the gear rises"), (A + 0.02, "the yes: a flash"),
        (A + 0.1, "a ring of light, sparks; +8 pops; the stat counts"), (A + 0.3, "the shine crosses"),
        (A + 0.42, "the next rank's lines fade in"), (A + 1.1, "settled")]),
    ("fail", "A reinforce that fails", lambda t: strip_reinforce(t, False), A + 0.9, [
        (-0.1, "at rest"), (0.04, "touched: the press sinks"), (0.15, "the cost's stones arc into the ring"),
        (0.32, "the ring breathes in, the gear rises"), (A + 0.03, "the no: a crack, the ring turns red"),
        (A + 0.08, "the gear dims and sinks; a shake"), (A + 0.3, "the lines say why; the cost spent"),
        (A + 0.8, "settled: +7 stays")]),
]


def moments(duration, rate):
    return [-LEAD + i / rate for i in range(round((LEAD + duration + TAIL) * rate) + 1)]


# --- the sheets and the movie ---------------------------------------------------------------------------------------

def notes():
    p, cnt, b, sh, pop = C["Press"], C["Count"], C["Burst"], C["Shine"], C["Pop"]
    peak = pop["Peak"] * pop["Seconds"]
    return [
        f"Config.Hud.Motion, as the game has it: a press squeezes to {p['Squeeze']} in {p['In']} s, held to "
        f"{p['Least']} s, back over {p['Out']} s past its size (Back {p['Back']}); a number counts over "
        f"{cnt['Seconds']} s, expo out;",
        f"Burst: {int(b['Count'])} sparks, {b['Reach']:g} points out, {b['Size']:g} long, over {b['Seconds']} s; "
        f"Shine: {sh['Seconds']} s, {sh['Delay']} s after the hit; Pop: the level at rung {int(pop['Level'])}, "
        f"{popped(peak):.2f} times its size at {peak:.3f} s, settled by {pop['Seconds']} s.",
        "Seeds, this sheet's, for Config.Hud.Motion: " + ", ".join(f"{k} {v:g}" for k, v in list(S.items())[:10]) + ",",
        ", ".join(f"{k} {v:g}" for k, v in list(S.items())[10:]) + ". The server answers at "
        f"{S['Answer']} s, a stand-in. The frame is the Menu of 03:37; under Home it changes, and these strips follow.",
    ]


def opaque(px):
    return np.dstack([px[..., :3], np.ones(px.shape[:2], dtype=np.float32)])


def beat_sheet(out, key, name, beats, draw):
    """A strip's beats at the phone's size, four across, each with its time and what happens."""
    frames = [rs.shrink(opaque(draw(at)), 0.5) for at, _ in beats]   # each made small at once, at the phone's K
    ui.K = 1
    gap, head, cap = 14, 50, 22
    across = 4
    down = (len(beats) + across - 1) // across
    lines = notes()
    sheet = ui.Sheet(gap + across * (W + gap), head + down * (H + cap + gap) + len(lines) * 20 + 16, "#101117")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(gap, 14, 18, f"AR43, Reinforce in motion: {name.lower()}, at the smallest phone (568 x 320 points)",
           "#EDE6D6", bold=0.2)
    for k, ((at, words), px) in enumerate(zip(beats, frames)):
        x, y = gap + (k % across) * (W + gap), head + (k // across) * (H + cap + gap)
        t.text(x, y + 3, 13, f"{at:+.2f} s   {words}", "#B4AC9C")
        rs.paste(sheet.px, px, x, y + cap)
    for k, words in enumerate(lines):
        t.text(gap, head + down * (H + cap + gap) + k * 20, 12, words, "#B4AC9C")
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / f"upgrade_motion_{key}.png")
    ui.K = K


CLOSE = [("success", A + 0.02, "the yes: a flash"), ("success", A + 0.08, "the ring of light, the sparks, +8 at its peak"),
         ("success", A + 0.3, "the shine"), ("fail", A + 0.03, "the no: the crack"),
         ("fail", A + 0.1, "dimmed, sunk, shaken"), ("fail", A + 0.8, "settled")]


def close_sheet(out):
    """The hits up close, at the phone's full pixels: the work and the band's Credits (rule: UI is read up close)."""
    x0, y0, x1, y1 = WORK[0] - 6, 4, WORK[1] + 8, FOOT + 4
    draws = {key: draw for key, _, draw, *_ in STRIPS}
    frames = [opaque(draws[key](at)[y0 * K:y1 * K, x0 * K:x1 * K]) for key, at, _ in CLOSE]   # at the phone's K
    ui.K = 1
    cw, chh = (x1 - x0) * K, (y1 - y0) * K
    gap, head, cap, across = 14, 44, 22, 3
    sheet = ui.Sheet(gap + across * (cw + gap), head + 2 * (chh + cap + gap), "#101117")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(gap, 12, 18, "AR43, Reinforce in motion: the hits up close, at the phone's full pixels", "#EDE6D6", bold=0.2)
    for k, ((key, at, words), px) in enumerate(zip(CLOSE, frames)):
        x, y = gap + (k % across) * (cw + gap), head + (k // across) * (chh + cap + gap)
        t.text(x, y + 3, 13, f"{key}, {at:+.2f} s   {words}", "#B4AC9C")
        rs.paste(sheet.px, px, x, y + cap)
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "upgrade_motion_close.png")
    ui.K = K


class Film:
    """Frames written one by one through a single image, so memory stays flat. A frame already on disk is kept, so a
    run the memory guard stopped goes on where it was."""

    def __init__(self, folder):
        self.folder, self.n, self.image, self.made = folder, 0, None, 0
        folder.mkdir(parents=True, exist_ok=True)
        done = sorted(folder.glob("*.png"))
        if done:
            done[-1].unlink()                  # the last may have been cut off mid-write
            print(f"[motion] going on from frame {len(done) - 1}", flush=True)

    def wants(self):
        """Whether the next frame still has to be made; if not, it's counted as made."""
        if (self.folder / f"{self.n:04d}.png").exists():
            self.n += 1
            return False
        return True

    def add(self, px):
        tall, wide = px.shape[:2]
        if self.image is None:
            self.image = bpy.data.images.new("Frame", wide, tall, alpha=False)
            self.buf = np.ones((tall, wide, 4), dtype=np.float32)
        self.buf[..., :3] = np.clip(px[::-1, :, :3], 0, 1)
        self.image.pixels.foreach_set(self.buf.ravel())
        self.image.filepath_raw = str(self.folder / f"{self.n:04d}.png")
        self.image.file_format = "PNG"
        self.image.save()
        self.n += 1
        self.made += 1
        if self.made % 60 == 0:
            stage(f"frame {self.n}")


def main():
    """`movie` makes the movie only (the sheets come without it); run it again after a stop and it goes on."""
    out = bl.out_dir()
    movie = "movie" in sys.argv[sys.argv.index("--") + 2:]
    stage("started")
    times = {round(t, 6) for _, _, _, dur, beats in STRIPS for rate in (FPS, FPS * SLOW)
             for t in moments(dur, rate)} | {at for *_, beats in STRIPS for at, _ in beats} | {at for _, at, _ in CLOSE}
    made(times, out)
    print(f"[motion] baked {len(L)} layers and {len(STAMPS)} stamps")
    if not movie:
        for key, name, draw, _, beats in STRIPS:
            beat_sheet(out, key, name, beats, draw)
            stage(f"the {key} sheet")
        close_sheet(out)
        return
    film = Film(out / "_frames")
    for n, (key, name, draw, dur, _) in enumerate(STRIPS):
        for speed, rate in ((0, FPS), (1, FPS * SLOW)):
            caption = stamp("caption", 2 * n + speed)
            for t in moments(dur, rate):
                if not film.wants():
                    continue
                frame = canvas(H + CAPTION)
                frame[..., :3], frame[..., 3] = ui.c("#101117"), 1.0
                frame[:H * K] = draw(t)
                lay(frame, caption)
                film.add(frame)
        print(f"[motion] {key}: {film.n} frames so far", flush=True)
    fm.assemble(film.folder, out / "upgrade_motion.mp4", FPS)
    shutil.rmtree(film.folder)
    (out / "_motion_bake.pkl").unlink(missing_ok=True)


if __name__ == "__main__":
    main()
