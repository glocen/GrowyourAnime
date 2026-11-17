"""The Void Breaker's sky (AR12, delivery 3). The director, 2026-11-15: "a galaxy like Ui but well well composed mature
and beautifull and even animated if possible", then, on the first mock's spiral: "not a literal galaxy form just paletee
of colors and stars it need a bit more composition". So: a galaxy's colours and its stars, and no galaxy's shape.

Plain numpy, no Blender: the sheet draws its still from it (screens_vivid_sheet.py) and the motion test its frames
(void_breaker_motion.py). Three layers, as the game would stack them:

    ground()  the still night: one river of colour on a diagonal, rose to violet to blue to teal, dust lanes across
              it, the small stars gathered along it, and one knot of stars where the eye should rest. Nothing in it moves.
    mist()    a thin mist of the river's colours, in the chambers' row only, that drifts along it.
    glints()  the few large stars, each breathing on its own clock.

Colours are straight, never premultiplied, in a picture's own values (0 to 1). Sizes are in points; `k` is pixels a point.
"""
import math

import numpy as np

STARS = ("#DCE6FF", "#FFFFFF", "#FFE9D0", "#BFD0FF", "#F1D9FF")


def rgb(code):
    return np.array([int(code[i:i + 2], 16) for i in (1, 3, 5)], np.float32) / 255


def lattices(rng, count):
    return [rng.random((64, 64), dtype=np.float32) for _ in range(count)]


def vnoise(g, x, y, wrap=None):
    """Smooth noise, 0 to 1, read anywhere: a lump to a unit. `wrap`: it repeats every that many units across."""
    n = g.shape[0]
    xi, yi = np.floor(x).astype(np.int32), np.floor(y).astype(np.int32)
    fx, fy = x - xi, y - yi
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    x0, x1 = (xi, xi + 1) if wrap is None else (xi % wrap, (xi + 1) % wrap)
    x0, x1, y0, y1 = x0 % n, x1 % n, yi % n, (yi + 1) % n
    return (g[y0, x0] * (1 - fx) + g[y0, x1] * fx) * (1 - fy) + (g[y1, x0] * (1 - fx) + g[y1, x1] * fx) * fy


def fbm(gs, x, y, wrap=None):
    """Noise on noise, each layer twice as fine and half as strong: one lattice a layer."""
    total = sum(vnoise(g, x * 2 ** i, y * 2 ** i, None if wrap is None else wrap * 2 ** i) / 2 ** i for i, g in enumerate(gs))
    return total / (2 - 2 ** (1 - len(gs)))


def ramp(t, stops):
    at = [s[0] for s in stops]
    cols = np.array([rgb(s[1]) for s in stops])
    return np.stack([np.interp(t, at, cols[:, i]) for i in range(3)], axis=-1).astype(np.float32)


def over(dst, colour, a):
    """A colour over a picture by the cover `a`. The picture has three planes (solid) or four (with its own cover)."""
    colour = np.asarray(colour, np.float32)
    if colour.ndim == 1:
        colour = colour[None, None, :]
    if dst.shape[-1] == 3:
        dst += (colour - dst) * a[..., None]
        return
    da = dst[..., 3]
    out = a + da * (1 - a)
    dst[..., :3] = (colour * a[..., None] + dst[..., :3] * (da * (1 - a))[..., None]) / np.maximum(out, 1e-6)[..., None]
    dst[..., 3] = out


def dot(px, cx, cy, r, colour, a, soft=1.0):
    """A small round light, in pixels. `soft`: 1 a star's point, higher a haze."""
    reach = int(math.ceil(r * 3.2 * soft)) + 1
    x0, y0 = int(cx) - reach, int(cy) - reach
    x1, y1 = min(x0 + 2 * reach + 1, px.shape[1]), min(y0 + 2 * reach + 1, px.shape[0])
    x0, y0 = max(x0, 0), max(y0, 0)
    if x1 <= x0 or y1 <= y0:
        return
    y, x = np.mgrid[y0:y1, x0:x1].astype(np.float32)
    d2 = ((x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2) / (r * r)
    over(px[y0:y1, x0:x1], colour, (a * np.exp(-d2 / (2 * soft * soft))).astype(np.float32))


def points(rows, cols, k):
    """Each pixel's place, in points."""
    y, x = np.mgrid[0:rows, 0:cols].astype(np.float32)
    return (x + 0.5) / k, (y + 0.5) / k


def along(look, xp, yp):
    """A place measured on the river: how far along it (0 to 1) and how far off its middle (points)."""
    (ax, ay), (bx, by) = look["river"]
    length = math.hypot(bx - ax, by - ay)
    ux, uy = (bx - ax) / length, (by - ay) / length
    return ((xp - ax) * ux + (yp - ay) * uy) / length, -(xp - ax) * uy + (yp - ay) * ux


def ground(rows, cols, k, look, seed=5):
    """The still night, solid."""
    rng = np.random.default_rng(seed)
    gs = lattices(rng, 16)
    xp, yp = points(rows, cols, k)
    w, h = cols / k, rows / k
    fx, fy = look["focus"]
    # the night: darkest at the corners
    px = ramp(np.hypot((xp - fx) / w * 1.15, (yp - fy) / h * 0.9), ((0.0, "#0E0B2C"), (0.4, "#090722"), (0.75, "#050414"), (1.1, "#020208")))
    # the river: noise bent by noise makes strands, and its banks wander
    u, v = xp / look["cell"], yp / look["cell"]
    q1, q2 = fbm(gs[0:4], u, v), fbm(gs[4:8], u + 5.2, v + 1.3)
    strand = fbm(gs[8:12], u + 2.6 * q1, v + 2.6 * q2)
    s, off = along(look, xp, yp)
    bank = np.exp(-((off + (q1 - 0.5) * look["width"] * 1.1) / look["width"]) ** 2)
    light = bank * np.clip((strand - 0.2) / 0.45, 0, 1) ** 1.2
    lanes = np.clip((fbm(gs[12:16], u * 1.6 + 2.2 * q2, v * 1.6 + 2.2 * q1) - 0.54) / 0.14, 0, 1)
    light *= 1 - 0.75 * lanes  # dust across it
    colour = ramp(np.clip(s + (q2 - 0.5) * 0.3, 0, 1), look["palette"])
    colour += (light ** 2)[..., None] * (1 - colour) * 0.38  # paler where it's thick
    over(px, colour, np.clip(light * look["glow"], 0, 1).astype(np.float32))
    # a breath of the last colour low on the right and of the river's violet high on the left, to hold the corners
    over(px, rgb(look["palette"][-1][1]), (np.clip((xp / w - 0.45) * 1.6, 0, 1) * np.clip((yp / h - 0.45) * 1.8, 0, 1) * q1 ** 1.5 * 0.42).astype(np.float32))
    over(px, rgb(look["breath"]), (np.clip((0.42 - xp / w) * 2.4, 0, 1) * np.clip((0.3 - yp / h) * 3.4, 0, 1) * q2 ** 1.5 * 0.5).astype(np.float32))
    # where the eye rests: a soft bloom, and a knot of stars in it
    d = np.hypot(xp - fx, yp - fy)
    over(px, rgb("#E9B8FF"), (np.exp(-(d / 30.0) ** 2) * (0.35 + 0.65 * strand) * 0.4).astype(np.float32))
    over(px, rgb("#FFE9F4"), (np.exp(-(d / 8.0) ** 2) * 0.38).astype(np.float32))
    for _ in range(int(w * h / look["per"])):  # the small stars: most faint, gathered along the river
        mag = rng.random() ** 4.0
        if rng.random() < 0.55:
            (ax, ay), (bx, by) = look["river"]
            t, o = rng.uniform(-0.1, 1.1), rng.normal(0, look["width"] * 0.9)
            length = math.hypot(bx - ax, by - ay)
            sx, sy = ax + (bx - ax) * t + o * (by - ay) / length, ay + (by - ay) * t - o * (bx - ax) / length
        else:
            sx, sy = rng.random() * w, rng.random() * h
        dot(px, sx * k, sy * k, (0.17 + 0.4 * mag) * k, rgb(STARS[rng.integers(len(STARS))]), 0.14 + 0.86 * mag)
    for _ in range(34):  # the knot
        mag = rng.random() ** 2.0
        dot(px, (fx + rng.normal(0, 13.0)) * k, (fy + rng.normal(0, 8.0)) * k, (0.2 + 0.42 * mag) * k,
            rgb(STARS[rng.integers(len(STARS))]), 0.3 + 0.7 * mag)
    return px


def ease(t):
    t = np.clip(t, 0, 1)
    return t * t * (3 - 2 * t)


def lumps(y0, y1, cols, k, shift=0.0, seed=33):
    """The mist's own lumps over the rows y0 to y1, 0 to 1, moved `shift` points along: they repeat across the field's
    width, so the mist meets itself when it comes round. With them, each pixel's place in points."""
    rng = np.random.default_rng(seed)
    gs = lattices(rng, 8)
    y, x = np.mgrid[y0:y1, 0:cols].astype(np.float32)
    xp, yp = (x + 0.5) / k, (y + 0.5) / k
    count = 5
    cell = cols / k / count
    u, v = (xp + shift) / cell, yp / cell
    q = fbm(gs[0:4], u, v, count)
    n = fbm(gs[4:8], u + 1.4 * q, v * 1.5 + 1.4 * q, count)
    return ease((n - 0.42) / 0.3) ** 1.3, xp, yp


def held(look, xp, yp):
    """Where the mist lies, 0 to 1: on the river, thinning to nothing off it and at the band's two edges, so no line
    shows where it stops; and thin round the knot of stars, which stays sharp."""
    top, foot = look["band"]
    off = along(look, xp, yp)[1]
    edge = ease((yp - top) / 40.0) * ease((foot - yp) / 40.0) * np.exp(-(off / (look["width"] * 1.5)) ** 2)
    return edge * (1 - 0.85 * np.exp(-(np.hypot(xp - look["focus"][0], yp - look["focus"][1]) / 26.0) ** 2))


def mist(rows, cols, k, look, shift=0.0, seed=33):
    """A thin mist of the river's own colours, in the band `look["band"]` (points down the field), moved `shift`
    points along it: lumps() where held() lets it lie."""
    top, foot = look["band"]
    y0, y1 = max(int(top * k), 0), min(int(foot * k) + 1, rows)
    out = np.zeros((rows, cols, 4), np.float32)
    n, xp, yp = lumps(y0, y1, cols, k, shift, seed)
    # never paler than the river (the director, 2026-11-15, on the pale strands tried first: "that white gas trail is
    # kinda odd remove it")
    out[y0:y1, :, :3] = ramp(np.clip(along(look, xp, yp)[0], 0, 1), look["palette"])
    out[y0:y1, :, 3] = n * held(look, xp, yp) * look["mist"]
    return out


def glints(rows, cols, k, stars, t=0.0):
    """The large stars: a point, a halo and four thin rays. `stars`: (x, y, size, colour, period, phase) each, in
    points and seconds. Each breathes between 0.55 and 1 of its light."""
    out = np.zeros((rows, cols, 4), np.float32)
    for sx, sy, size, colour, period, phase in stars:
        lit = 0.775 + 0.225 * math.sin(2 * math.pi * (t / period + phase))
        col, cx, cy, r = rgb(colour), sx * k, sy * k, size * k
        reach = int(r * 7) + 2
        x0, y0 = max(int(cx) - reach, 0), max(int(cy) - reach, 0)
        x1, y1 = min(int(cx) + reach + 1, cols), min(int(cy) + reach + 1, rows)
        if x1 <= x0 or y1 <= y0:
            continue
        y, x = np.mgrid[y0:y1, x0:x1].astype(np.float32)
        dx, dy = (x + 0.5 - cx) / r, (y + 0.5 - cy) / r
        halo = 0.3 * np.exp(-(dx * dx + dy * dy) / 5.0)
        rays = 0.75 * np.maximum(np.exp(-(dy * 5.5) ** 2 - np.abs(dx) / 2.2), np.exp(-(dx * 5.5) ** 2 - np.abs(dy) / 2.2))
        core = np.exp(-(dx * dx + dy * dy) / 0.32)
        over(out[y0:y1, x0:x1], col, np.clip((halo + rays) * lit, 0, 1).astype(np.float32))
        over(out[y0:y1, x0:x1], np.ones(3, np.float32), np.clip(core * lit, 0, 1).astype(np.float32))
    return out


STREAK = dict(tail=54.0, root=1.1, tip=0.3, core=1.5, glow=4.5, glow_cover=0.55)  # points: the falling star's parts


def streak(rows, cols, k, start, end, s, parts=STREAK):
    """A falling star, `s` of its way from start to end (points): a bright head in a soft glow, and a tail that thins
    behind it, `tail` points long, `root` thick at the head and `tip` at its end. Pale, and tied to nothing: it never
    takes a rarity's colour, and it's never the reveal's. Made to be caught at the smallest phone on first sight
    (research's must-fix, TR41, 2026-11-17)."""
    out = np.zeros((rows, cols, 4), np.float32)
    if not 0.0 <= s <= 1.0:
        return out
    ax, ay = start[0] * k, start[1] * k
    bx, by = end[0] * k, end[1] * k
    hx, hy = ax + (bx - ax) * s, ay + (by - ay) * s
    length = math.hypot(bx - ax, by - ay)
    ux, uy = (bx - ax) / length, (by - ay) / length
    tail = parts["tail"] * k
    y, x = np.mgrid[0:rows, 0:cols].astype(np.float32)
    on, across = (x - hx) * ux + (y - hy) * uy, -(x - hx) * uy + (y - hy) * ux
    fade = math.sin(math.pi * s) ** 0.6
    along = np.clip(1 + on / tail, 0, 1)  # 1 at the head, 0 at the tail's end
    thick = (parts["tip"] + (parts["root"] - parts["tip"]) * along) * k
    body = np.where((on <= 0) & (on > -tail), along ** 1.6, 0.0) * np.exp(-(across / thick) ** 2)
    r2 = on * on + across * across
    glow = parts["glow_cover"] * np.exp(-r2 / (parts["glow"] * k) ** 2)
    head = np.exp(-(r2 / (parts["core"] * k) ** 2) ** 1.5)
    over(out, rgb("#CFE0FF"), np.clip(glow * fade, 0, 1).astype(np.float32))
    over(out, rgb("#CFE0FF"), np.clip(body * 0.85 * fade, 0, 1).astype(np.float32))
    over(out, np.ones(3, np.float32), np.clip(head * fade, 0, 1).astype(np.float32))
    return out


def lay(px, layer):
    """A layer with its own cover over a solid picture."""
    px += (layer[..., :3] - px) * layer[..., 3:]
    return px


# The Breaker's own sky, in points from its panel's corner (the panel is drawn by screens_vivid_sheet.py). The river
# climbs gently from the left to the right through the chambers' row, so the four windows (their middles at 62, 165,
# 268 and 371 points across) each hold their own colour of one sky: rose, violet, blue, teal. Every plate with a
# number on it lies over the sky, solid.
PANEL = (66.0, 60.0, 684.0, 306.0)  # x, y, w, h on the 812 by 375 screen
BREAKER = dict(
    river=((-30.0, 150.0), (700.0, 50.0)), width=50.0, cell=120.0, glow=1.0, per=150.0,
    palette=((0.0, "#D44FB4"), (0.125, "#D44FB4"), (0.265, "#9A4FE8"), (0.405, "#5580FF"), (0.545, "#2CC4DC"), (0.75, "#34DCC2"),
             (1.0, "#34DCC2")),
    breath="#7A52EC",  # the corner over the title
    focus=(286.0, 106.0),  # where the eye rests: in the third chamber's window, off its middle
    band=(62.0, 204.0), mist=0.3,  # the chambers' row, where the mist drifts, and how much it covers at most
    drift=2.5,  # points a second: the mist takes about 38 s to cross a window
    # the large stars: x, y, size, colour, seconds a breath, where in its breath it starts
    glints=((528.0, 21.0, 1.5, "#DCE6FF", 4.6, 0.0), (398.0, 90.0, 1.1, "#FFE9D0", 3.4, 0.3),
            (38.0, 142.0, 1.0, "#BFD0FF", 5.2, 0.6), (94.0, 84.0, 0.9, "#F1D9FF", 3.9, 0.8),
            (250.0, 46.0, 0.9, "#DCE6FF", 4.2, 0.45), (300.0, 294.0, 0.9, "#BFD0FF", 5.0, 0.15)),
    streak=((419.0, 81.0), (323.0, 160.0)),  # a falling star's path: the fourth chamber's window, corner to corner
    shards=((62.0, 118.0), (165.0, 118.0)),  # where a working chamber's shard floats
)


def sky(k, t=0.0, base=None, look=BREAKER, size=PANEL[2:]):
    """The Breaker's sky at `t` seconds, solid, `k` pixels a point. `base`: ground() made once, for a run of frames."""
    rows, cols = round(size[1] * k), round(size[0] * k)
    px = ground(rows, cols, k, look) if base is None else base.copy()
    lay(px, mist(rows, cols, k, look, look["drift"] * t))
    lay(px, glints(rows, cols, k, look["glints"], t))
    return px
