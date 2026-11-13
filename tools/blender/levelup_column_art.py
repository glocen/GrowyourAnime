"""The level-up column's light (AR8, C; research's pass, fix 2): its Beam picture, and a sheet of it beside the flat one.

blender.exe -b --factory-startup --python tools/blender/levelup_column_art.py -- <out_dir>

On the noon sky the flat column was a hard-edged pane darker than the sky: tinted glass, not light. Its picture:
- levelup_column.png, 256 x 128. Across its width is across the Beam; down its height is along it, its top row at the
  foot (a Beam runs its picture's height along it, handbook/visuals/vfx-engine-facts.md, "Beam"), stretched once. It
  changes only smoothly down its height, so it is one continuous light from foot to top, with nothing in it that could
  fall. A white core going pale, then to experience's blue (Config.Hud.Card.Xp) over its sides, where it thins to
  nothing at the edges: a bright interior with a darker, saturated edge (docs/research/vfx-reference.md, rule 3).
  Toward the foot and the top, where the Beam's own transparency fades it, the core goes over to a pale blue, so at
  night it goes out as blue light, not grey. Its clear pixels carry the blue, so no dark rim comes in where it is
  filtered. Shown with the Beam's Color white, so its own colours show.
Faber's motion stays as built: the Beam's length, width, transparency along it and their timing are his Config's
(Config.Effects.LevelUp), copied here only to draw the sheet.
- levelup_column_sheet.png: the flat column and the new one, as Effects.LevelUp lays them at three moments, behind a
  grey stand-in lead with the sleeve over it, on the noon sky and at night; then the peak at phone size, and the picture
  alone. Drawn flat, in straight alpha over the ground's colour: the game's own tone and bloom aren't drawn.
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402

XP = "#4E9BFF"                 # Config.Hud.Card.Xp, the thread's blue
CORE, PALE = "#FFFFFF", "#CFE6FF"
ENDS = (0.5, 0.95)            # how far the middle goes over to the blue at the foot, and at the top
PX = (256, 128)
K = 4                          # supersampling across, then a box down

# Config.Effects.LevelUp as built (Faber's), to lay the beams as the game does
COLUMN = dict(seconds=0.7, over=5, wide=0.6, climb=0.3, peak=0.25, narrow=0.5, opaque=0.85, foot=0.4, fade=0.25)
SLEEVE = dict(delay=0.08, seconds=0.6, over=1, wide=0.75, alpha=0.3)
TALL = 6.0                     # the stand-in lead, feet to the top of its hat, in studs
MOMENTS = (0.07, 0.175, 0.42)  # seconds: climbing, the column's peak (Peak x Seconds), its foot after its top

NOON_SKY, NOON_LOW, NOON_GROUND = rs.rgb("#5FADDA"), rs.rgb("#AFB8D6"), rs.rgb("#A9B0C6")
NIGHT_SKY, NIGHT_LOW, NIGHT_GROUND = rs.rgb("#0E1018"), rs.rgb("#1A1D29"), rs.rgb("#23262F")
LEAD, LEAD_DARK = rs.rgb("#8A8D96"), rs.rgb("#5E616B")


# --- the picture -----------------------------------------------------------------------------------------------------

def smooth(e0, e1, x):
    u = np.clip((x - e0) / (e1 - e0), 0, 1)
    return u * u * (3 - 2 * u)


def profile(x, v):
    """Colour (sRGB) and alpha across the beam, x from -1 to 1, `v` of the way from its foot to its top: white in the
    middle, pale, then the blue at the sides, where it thins to nothing. Toward its foot and its top, where the Beam's
    own transparency fades it, the middle goes over to the pale blue, so it goes out as blue light, never as grey."""
    d = np.abs(x)
    core, pale, xp = (np.array(rs.rgb(c)) for c in (CORE, PALE, XP))
    t = smooth(0.12, 0.66, d)[..., None]
    rgb = np.where(t < 0.5, core + (pale - core) * (t * 2), pale + (xp - pale) * (t * 2 - 1))
    ends = (np.maximum(ENDS[0] * (1 - smooth(0.0, 0.22, v)), ENDS[1] * smooth(0.5, 1.0, v)))[..., None]
    rgb = rgb + (pale + (xp - pale) * 0.5 - rgb) * ends * (1 - t)
    alpha = (1 - smooth(0.42, 1.0, d)) ** 1.3
    return rgb, alpha


def picture():
    w, h = PX
    xs = (np.arange(w * K) + 0.5) / (w * K) * 2 - 1
    vs = (np.arange(h) + 0.5) / h               # the top row is the foot (Attachment0)
    X, V = np.meshgrid(xs, vs)
    rgb, alpha = profile(X, V)
    pm = np.concatenate([rgb * alpha[..., None], alpha[..., None]], axis=-1).reshape(h, w, K, 4).mean(axis=2)
    a = pm[..., 3:4]
    rgb = np.where(a > 1e-4, pm[..., :3] / np.maximum(a, 1e-4), np.array(rs.rgb(XP)))
    pic = np.concatenate([rgb, a], axis=-1)
    pic[:, 0, 3] = pic[:, -1, 3] = 0.0  # the outer pixels clear, so its edge can never clamp to a line
    return pic.astype(np.float32)


# --- the beams as Effects.LevelUp lays them --------------------------------------------------------------------------

def ease(u):
    c = min(max(u, 0.0), 1.0)
    return 1 - (1 - c) * (1 - c)


def pop(t, peak):
    if t <= 0 or t >= 1:
        return 0.0
    if t < peak:
        return ease(t / peak)
    u = (t - peak) / (1 - peak)
    return 1 - u * u * (3 - 2 * u)


def climb(t, height, width, narrow):
    c = COLUMN
    top = height * (ease(t / c["climb"]) + 0.2 * max(0.0, t - c["climb"]) / (1 - c["climb"]))
    u = min(max((t - c["peak"]) / (1 - c["peak"]), 0.0), 1.0)
    return top * u * u, top, width * (1 - narrow * u * u), pop(t, c["peak"])


def beams(age):
    """(foot, top, width, opaque) of the column and the sleeve at `age` seconds, in studs."""
    c, s = COLUMN, SLEEVE
    out = {}
    tc = age / c["seconds"]
    if 0 < tc < 1:
        foot, top, width, p = climb(tc, TALL + c["over"], TALL * c["wide"], c["narrow"])
        out["column"] = (foot, top, width, p * c["opaque"])
    ts = (age - s["delay"]) / s["seconds"]
    if 0 < ts < 1:
        foot, top, width, p = climb(ts, TALL + s["over"], TALL * s["wide"], c["narrow"] / 2)
        out["sleeve"] = (foot, top, width, p * s["alpha"])
    return out


def along(v, opaque):
    """How opaque the beam is `v` of the way from its foot to its top: Effects.LevelUp's Transparency, inverted."""
    c = COLUMN
    keys = ((0.0, 1 - opaque * c["foot"]), (0.2, 1 - opaque), (1 - c["fade"], 1 - opaque), (1.0, 1.0))
    return 1 - np.interp(v, [k[0] for k in keys], [k[1] for k in keys])


# --- the sheet -------------------------------------------------------------------------------------------------------

def ground(w, h, floor, sky, low, earth):
    """Sky from `sky` at the top to `low` at the horizon (a little over the floor's row), the ground below."""
    out = rs.canvas(w, h, earth)
    horizon = int(floor * 0.82)
    t = (np.arange(horizon) / max(horizon - 1, 1))[:, None]
    out[:horizon, :, :3] = (np.array(sky) * (1 - t) + np.array(low) * t)[:, None, :]
    return out


def lay(target, cx, floor, s, beam, tex):
    """One beam facing the camera, its foot and top in studs over the floor's row, centred on cx, `s` pixels a stud.
    tex None: the flat column, the Beam's Color the blue with no picture."""
    foot, top, width, opaque = beam
    if opaque <= 0 or width <= 0:
        return
    y0, y1 = floor - top * s, floor - foot * s
    x0, x1 = cx - width * s / 2, cx + width * s / 2
    rows = np.arange(max(int(y0), 0), min(int(np.ceil(y1)), target.shape[0]))
    cols = np.arange(max(int(x0), 0), min(int(np.ceil(x1)), target.shape[1]))
    if not len(rows) or not len(cols):
        return
    v = (floor - (rows + 0.5) - foot * s) / max((top - foot) * s, 1e-6)
    u = ((cols + 0.5) - cx) / (width * s / 2)
    a_along = along(np.clip(v, 0, 1), opaque)[:, None]
    if tex is None:
        rgb = np.broadcast_to(np.array(rs.rgb(XP)), (len(cols), 3))
        a_across = np.ones(len(cols))
    else:  # stretched once along it: the picture's top row at the foot
        across = np.clip(((u + 1) / 2 * tex.shape[1]).astype(int), 0, tex.shape[1] - 1)
        down = np.clip((np.clip(v, 0, 1) * tex.shape[0]).astype(int), 0, tex.shape[0] - 1)
        rgb, a_across = tex[down][:, across, :3], tex[down][:, across, 3]
    if rgb.ndim == 2:
        rgb, a_across = np.broadcast_to(rgb[None], (len(rows), len(cols), 3)), np.broadcast_to(a_across[None], (len(rows), len(cols)))
    # cover: how much of each edge pixel the beam's rectangle covers, so its sides are drawn as Roblox draws them
    cover_x = np.clip(np.minimum(cols + 1, x1) - np.maximum(cols, x0), 0, 1)
    cover_y = np.clip(np.minimum(rows + 1, y1) - np.maximum(rows, y0), 0, 1)
    a = a_along * a_across * cover_y[:, None] * cover_x[None, :]
    patch = target[rows[0]:rows[-1] + 1, cols[0]:cols[-1] + 1, :3]
    patch[:] = rgb * a[..., None] + patch * (1 - a[..., None])


def lead(target, cx, floor, s):
    """A grey block stand-in for the lead, TALL studs with its hat: legs, body, arms, head, a tall hat."""
    def box(x0, x1, y0, y1, colour):
        rs.fill(target, int(round(cx + x0 * s)), int(round(floor - y1 * s)), int(round((x1 - x0) * s)),
                int(round((y1 - y0) * s)), colour)
    box(-1, 1, 0, 2, LEAD_DARK)
    box(-1, 1, 2, 4, LEAD)
    box(-1.9, -1.05, 2.05, 4, LEAD_DARK)
    box(1.05, 1.9, 2.05, 4, LEAD_DARK)
    box(-0.6, 0.6, 4, 5.0, LEAD)
    box(-1.2, 1.2, 4.85, 5.05, LEAD_DARK)
    for i in range(8):  # the hat's cone, in steps
        half = 0.75 * (1 - i / 8)
        box(-half, half, 5.05 + i * (TALL - 5.05) / 8, 5.05 + (i + 1) * (TALL - 5.05) / 8, LEAD_DARK)


def scene_at(w, h, cx, floor, s, age, tex, night):
    """The lead at `age` of its level-up: the column behind it, the sleeve over it, supersampled twice."""
    k = 2
    sky = (NIGHT_SKY, NIGHT_LOW, NIGHT_GROUND) if night else (NOON_SKY, NOON_LOW, NOON_GROUND)
    big = ground(w * k, h * k, floor * k, *sky)
    now = beams(age)
    if "column" in now:
        lay(big, cx * k, floor * k, s * k, now["column"], tex)
    lead(big, cx * k, floor * k, s * k)
    if "sleeve" in now:
        lay(big, cx * k, floor * k, s * k, now["sleeve"], tex)
    return rs.shrink(big, 1 / k)


def main():
    out = bl.out_dir()
    rs.OUT = out
    tex = picture()
    rs.save(tex, out / "levelup_column.png")
    for v in (0.0, 0.1, 0.5, 0.8, 1.0):
        r = min(int(v * PX[1]), PX[1] - 1)
        core, edge = tex[r, PX[0] // 2], tex[r, round(PX[0] * 0.2)]
        print(f"the picture {v:.0%} along: middle {np.round(core * 255).astype(int)}, a fifth in {np.round(edge * 255).astype(int)}")
    for age in MOMENTS:
        print(f"  {age:.3f} s: " + ", ".join(f"{k} foot {b[0]:.2f} top {b[1]:.2f} wide {b[2]:.2f} opaque {b[3]:.2f}"
                                             for k, b in beams(age).items()))

    pw, ph, s = 214, 430, 30          # a moment's panel, its pixels a stud
    floor, cx = ph - 46, pw // 2
    gap, x0 = 8, 40
    W = x0 * 2 + 6 * pw + 5 * gap + 3 * gap
    tile = (470, 215)                 # a phone screen's tile, as the captures show it
    H = 150 + 2 * (ph + 46) + 40 + 2 * tile[1] + 10 + 110
    page = rs.canvas(W, H, rs.PAPER)
    ink, soft = "#1E1B22", "#6A655E"
    text = [(x0, 26, 44, "THE LEVEL-UP COLUMN'S LIGHT", ink),
            (x0, 84, 18, "AR8, C, research's pass, fix 2. Left in each group, the column as built: the blue, flat. Right, the new picture with "
                         "the Beam's Color white. The motion, width and transparency", ink),
            (x0, 106, 18, "along it are Faber's, unchanged. A grey stand-in lead, 6 studs with its hat, the sleeve over it. Drawn flat over the "
                          "ground's colour, without the game's tone or bloom.", ink)]
    y = 150
    for night in (False, True):
        text.append((x0, y, 18, "At night" if night else "On the noon sky", ink))
        for m, age in enumerate(MOMENTS):
            for n, t in enumerate((None, tex)):
                x = x0 + (m * 2 + n) * (pw + gap) + m * 3 * gap
                rs.paste(page, scene_at(pw, ph, cx, floor, s, age, t, night), x, y + 26)
                if not night:
                    text.append((x + 6, y + 26 + ph + 4, 13, f"{'flat' if t is None else 'new'}, {age:g} s"
                                 + (" (the peak)" if age == 0.175 else ""), soft))
        y += ph + 46
    text.append((x0, y + 4, 18, "The peak at a phone's size (the captures' tile): flat on the left, new on the right; noon, then night", ink))
    ts = tile[1] / 2 * 1.45 / TALL     # the lead about three quarters of the tile's half height, as in the captures
    for n, (night, t) in enumerate(((False, None), (False, tex), (True, None), (True, tex))):
        rs.paste(page, scene_at(tile[0], tile[1], int(tile[0] * 0.58), int(tile[1] * 0.86), ts, 0.175, t, night),
                 x0 + (n % 2) * (tile[0] + 10), y + 30 + (n // 2) * (tile[1] + 10))
    sw = swatch(tex)
    rs.paste(page, sw, x0 + 2 * (tile[0] + 10) + 30, y + 30)
    text.append((x0 + 2 * (tile[0] + 10) + 30, y + 30 + sw.shape[0] + 6, 13,
                 "The picture alone, stretched as a beam standing up, fully opaque", soft))
    y += 30 + 2 * tile[1] + 10 + 12
    for i, words in enumerate((
            "levelup_column.png, 256 x 128: across it is across the Beam, down it along the Beam (its top row the foot). White in "
            "the middle, pale, then the thread's blue #4E9BFF at the sides,",
            "thinning to nothing at the edges; toward its foot and top the middle goes over to a pale blue, where the Beam's "
            "own transparency fades it.",
            "For the Beam: Texture this picture, TextureMode Stretch, TextureLength 1, Color white (a Beam's Color tints its picture). "
            "LightEmission, Segments, widths, transparency and timing as built.")):
        text.append((x0, y + i * 22, 15, words, soft))
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out / "levelup_column_sheet.png")


def swatch(tex, w=150, h=420):
    """The picture as a beam standing up, at full opacity, on the noon sky and at night: its top row at the foot."""
    out = rs.canvas(2 * w + 10, h, rs.PAPER)
    across = np.clip((np.arange(w) + 0.5) / w * tex.shape[1], 0, tex.shape[1] - 1).astype(int)
    down = np.clip((1 - (np.arange(h) + 0.5) / h) * tex.shape[0], 0, tex.shape[0] - 1).astype(int)
    pic = tex[down][:, across]
    for i, back in enumerate((NOON_SKY, NIGHT_SKY)):
        rs.fill(out, i * (w + 10), 0, w, h, back)
        rs.paste(out, pic, i * (w + 10), 0)
    return out


if __name__ == "__main__":
    main()
