"""The Day sky (TR23; the director, 2026-11-16: "we need a day / dusk sky box"): Roblox's six faces, painted by
direction in plain numpy, so no seam and no Blender. Beside AR5's Dusk and Night (build/handoff/LanternRow/sky).

A clear anime day: deep azure overhead falling to pale cyan, and a warm cream band on the horizon, warmest up the
street toward the festival. Cumulus stand in banks round the horizon, two tones and a flat base: white where the high
sun finds them, lavender under each billow. A paler, lower rank stands behind them in the haze, and a few thin wisps
lie high. The sun is painted where the game's one light stands (Config.Lighting.Toward), so the engine's disc is 0.

The frame is the kit's (lantern_row_kit.FACES): Roblox X is X, Roblox Y is Z, Roblox Z is -Y; Ft looks up the street.

    py tools/art/sky_day.py build/handoff/LanternRow/sky [size]

Writes LanternRow_SkyDay_<face>.png (1024 unless a size is given), lantern_row_sky_day_sheet.png (the faces round the
horizon, and three views as the game's camera frames them), and the Day block into lighting.json.
"""
import json
import math
import struct
import sys
import zlib
from pathlib import Path

import numpy as np

FACES = {"Ft": ((0, 1, 0), (0, 0, 1)), "Lf": ((1, 0, 0), (0, 0, 1)), "Bk": ((0, -1, 0), (0, 0, 1)),
         "Rt": ((-1, 0, 0), (0, 0, 1)), "Up": ((0, 0, 1), (1, 0, 0)), "Dn": ((0, 0, -1), (-1, 0, 0))}
SUN = (-0.161, -0.441, 0.883)   # Config.Lighting.Toward, in this frame: high, behind the player walking up the street
# The sky by elevation, in degrees: under the horizon, the warm band, pale cyan, azure, the deep blue overhead.
RAMP = ((-90.0, "#C4D2E6"), (-4.0, "#E6DDD4"), (0.0, "#F7E7D3"), (2.5, "#DCEAF1"), (7.0, "#AED6F3"), (18.0, "#74B5EF"),
        (38.0, "#4390E4"), (65.0, "#2C6FD4"), (90.0, "#2563C8"))
COOL = "#E4EBF2"                # the horizon's band away from the festival: the warmth lies up the street
LIT, CREAM, SHADE, BASE = "#FFFFFF", "#FFF3E0", "#BCC9EE", "#94A8DC"   # a cloud: its lit top, its lit flank, in its own shade, its foot
HAZE = "#E9E4E0"                # what distance does to a cloud near the horizon
SUN_CORE, SUN_HALO = "#FFFDF4", "#FFF1D6"


def rgb(code):
    return np.array([int(code[i:i + 2], 16) for i in (1, 3, 5)], np.float32) / 255


def step(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def wobble(d, k, seed):
    """A cheap hand's wobble by direction: three turned sines, -1 to 1."""
    x, y, z = d[..., 0], d[..., 1], d[..., 2]
    return (np.sin(k * (x * 1.0 + y * 0.7) + seed) * np.sin(k * (y * 1.1 - z * 0.9) + 2.3 * seed)
            + 0.5 * np.sin(2.1 * k * (z + x * 0.6) + 0.7 * seed))


def banks(rng):
    """The clouds as puffs: (azimuth, elevation, radius, squash, base) in degrees. A bank is a row of billows on one flat
    base with towers stacked on it; a far rank stands lower and smaller; wisps lie high and flat."""
    near, far, wisps = [], [], []
    for b in range(7):
        az = 360.0 * (b + rng.uniform(-0.28, 0.28)) / 7
        wide, base, high = rng.uniform(20, 40), rng.uniform(3.6, 5.6), rng.uniform(15, 31)
        x = -wide / 2
        while x < wide / 2:
            r = rng.uniform(3.2, 5.4)
            near.append((az + x, base + r * 0.55, r, 1.0, base))
            x += r * rng.uniform(0.9, 1.3)
        for _ in range(int(rng.integers(1, 3))):                    # a tower: heavy billows heaped up to a round head
            x, el, r = rng.uniform(-wide * 0.28, wide * 0.28), base + 4.5, rng.uniform(5.6, 7.6)
            while el < base + high and r > 2.6:
                near.append((az + x, el, r, 1.0, base))
                for side in (-1, 1):                               # a billow on each shoulder
                    if rng.random() < 0.8:
                        near.append((az + x + side * r * rng.uniform(0.75, 1.1), el - r * rng.uniform(0.0, 0.6), r * rng.uniform(0.5, 0.75), 1.0, base))
                el += r * rng.uniform(0.6, 0.9)
                x += rng.uniform(-0.6, 0.6) * r
                r *= rng.uniform(0.82, 0.97)
    for b in range(11):
        az = 360.0 * (b + rng.uniform(-0.4, 0.4)) / 11
        wide, base = rng.uniform(14, 30), rng.uniform(1.2, 2.4)
        x = -wide / 2
        while x < wide / 2:
            r = rng.uniform(1.6, 3.4)
            far.append((az + x, base + r * 0.6, r, 1.0, base))
            if rng.random() < 0.5:
                far.append((az + x + rng.uniform(-1, 1), base + r * 1.5, r * 0.7, 1.0, base))
            x += r * rng.uniform(0.9, 1.4)
    for _ in range(9):
        az, el = rng.uniform(0, 360), rng.uniform(26, 46)
        for k in range(int(rng.integers(2, 5))):
            wisps.append((az + k * rng.uniform(3, 6), el + rng.uniform(-1.2, 1.2), rng.uniform(3.0, 5.5), 0.22, -90.0))
    return [np.array(p, np.float32) for p in (near, far, wisps)]


NEAR, FAR, WISPS = banks(np.random.default_rng(16))


def body(az, el, puffs):
    """How far inside a rank's nearest puff each pixel is: 1 at a puff's middle, 0 on its edge, under 0 outside."""
    out = np.full(az.shape, -1.0, np.float32)
    for paz, pel, r, squash, base in puffs:
        da = (az - paz + 180.0) % 360.0 - 180.0
        reach = np.abs(da) < r * 1.2 / max(math.cos(math.radians(pel)), 0.2) + 1.0
        if not reach.any():
            continue
        da, de = da[reach] * math.cos(math.radians(pel)), (el[reach] - pel) / squash
        inside = 1.0 - np.sqrt(da * da + de * de) / r
        inside = np.where(el[reach] < base, np.minimum(inside, (el[reach] - base) / 0.5), inside)   # the flat base
        out[reach] = np.maximum(out[reach], inside)
    return out


def paint(d):
    """The sky's colour along each unit direction, an (n, 3) array in, the picture's own values out."""
    d = d.astype(np.float32)
    el = np.degrees(np.arcsin(np.clip(d[:, 2], -1, 1)))
    az = np.degrees(np.arctan2(d[:, 0], d[:, 1])) % 360.0          # 0 up the street, toward the festival
    stops = np.array([e for e, _ in RAMP], np.float32)
    cols = np.stack([rgb(c) for _, c in RAMP])
    out = np.stack([np.interp(el, stops, cols[:, k]) for k in range(3)], axis=1)
    band = np.exp(-np.abs(el) / 3.2)[:, None] * (0.5 - 0.5 * np.cos(np.radians(az)))[:, None] * (el > -6)[:, None]
    out = out + (rgb(COOL) - out) * band * 0.85                    # the warm band cools away from the festival
    sun = np.array(SUN, np.float32) / np.linalg.norm(SUN)
    sun_az = math.degrees(math.atan2(sun[0], sun[1])) % 360.0
    ang = np.degrees(np.arccos(np.clip(d @ sun, -1, 1)))
    out = out + (rgb(SUN_HALO) - out) * (0.5 * np.exp(-ang / 5.0) + 0.16 * np.exp(-ang / 24.0))[:, None]
    low = el < 62.0
    if low.any():
        dl, azl, ell = d[low], az[low], el[low]
        part = out[low]
        w1, w2 = wobble(dl, 23.0, 1.0), wobble(dl, 57.0, 4.0)
        side = np.sin(np.radians(sun_az - azl))                   # which way the sun lies round the horizon, with no jump
        for puffs, alpha, depth, soft, reach in ((FAR, 0.86, 0.62, 0.05, 2.2), (NEAR, 1.0, 0.0, 0.035, 5.0)):
            here = body(azl, ell, puffs) + 0.035 * w1 + 0.018 * w2
            cover = step(0.0, soft, here) * alpha
            # a cloud shades itself: what has cloud between it and the sun, up and round toward it, is in shade
            over = body(azl + side * reach * 0.55, ell + reach, puffs) + 0.05 * w2
            deep = body(azl + side * reach, ell + reach * 2.1, puffs) + 0.05 * w1
            col = rgb(CREAM) + (rgb(LIT) - rgb(CREAM)) * step(0.35, -0.1, over)[:, None]
            col = col + (rgb(SHADE) - col) * step(0.0, 0.3, over)[:, None]
            col = col + (rgb(BASE) - col) * (step(0.05, 0.6, deep) * 0.8)[:, None]
            far = np.clip(depth + (1 - depth) * np.exp(-np.maximum(ell, 0) / 7.5) * 0.6, 0, 1)[:, None]
            col = col + (rgb(HAZE) - col) * far                     # distance takes a cloud toward the horizon's haze
            part = part + (col - part) * cover[:, None]
        high = body(azl, ell, WISPS)
        part = part + (rgb(LIT) - part) * (step(0.0, 0.7, high + 0.12 * w1) * 0.5)[:, None]
        out[low] = part
    out = out + (rgb(SUN_CORE) - out) * step(2.3, 1.7, ang)[:, None]
    return np.clip(out, 0, 1)


def rays(ahead, top, size, half=1.0, wide=None):
    """Each pixel's direction through a face or a view: `half` is the tangent of half its height."""
    f, u = np.array(ahead, np.float32), np.array(top, np.float32)
    r = np.cross(f, u)
    w = wide or size
    ys = (1 - 2 * (np.arange(size, dtype=np.float32) + 0.5) / size) * half
    xs = (2 * (np.arange(w, dtype=np.float32) + 0.5) / w - 1) * half * w / size
    d = f[None, None] + xs[None, :, None] * r[None, None] + ys[:, None, None] * u[None, None]
    return d / np.linalg.norm(d, axis=2, keepdims=True)


def picture(d):
    h, w, _ = d.shape
    rows = [paint(d[y0:y0 + 128].reshape(-1, 3)).reshape(-1, w, 3) for y0 in range(0, h, 128)]
    return np.concatenate(rows)


def save(image, path, rng=None):
    px = image if rng is None else image + (rng.random(image.shape[:2] + (1,), np.float32) - 0.5) / 255   # no banding
    px = (np.clip(px, 0, 1) * 255 + 0.5).astype(np.uint8)
    h, w, _ = px.shape
    rgba = np.dstack([px, np.full((h, w, 1), 255, np.uint8)])
    raw = b"".join(b"\x00" + rgba[y].tobytes() for y in range(h))

    def chunk(kind, body):
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body))

    Path(path).write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
                           + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def view(yaw, pitch, size=(540, 960)):
    """The game's frame looking `yaw` degrees round from up the street and `pitch` up: its 70 degree field, 16 by 9."""
    a, p = math.radians(yaw), math.radians(pitch)
    f = (math.sin(a) * math.cos(p), math.cos(a) * math.cos(p), math.sin(p))
    u = (-math.sin(a) * math.sin(p), -math.cos(a) * math.sin(p), math.cos(p))
    px = picture(rays(f, u, size[0], math.tan(math.radians(35.0)), size[1]))
    horizon = int(size[0] * (0.5 + math.tan(p) / (2 * math.tan(math.radians(35.0)))))
    if 0 <= horizon < size[0]:                                     # a street's worth of ground, so the horizon is judged against it
        px[horizon:] = rgb("#8E88A0") * np.linspace(1.0, 0.78, size[0] - horizon)[:, None, None]
    return px


# The Day block for lighting.json: seeds for Config.Lighting.Phases.Day, moved with this sky from the builder's own
# (TR23), which were set under Roblox's built-in sky. Not measured in the engine: the builder tunes them by playing.
DAY = dict(
    phase="Day",
    sky=dict(faces={f: f"LanternRow_SkyDay_{f}.png" for f in FACES}, StarCount=0, SunAngularSize=0, MoonAngularSize=0,
             note="the sun is painted in the faces where Config.Lighting.Toward stands, so the engine's disc is 0, as at dusk "
                  "and night; the horizon's warm band is strongest in Ft, up the street (-Z)"),
    sun=dict(toward=[-0.161, 0.883, 0.441], elevationDegrees=62.0, colour="#FFE2B8", strength=0.87, shadows=True,
             note="warmer than the first seed (#FFE6C4), so the faces turned to it take the warmth the paving lacked; "
                  "strength is the kit's unit, a third of Brightness: 2.6"),
    ambient=dict(colour="#8A8496", strength=1.0, asOne="#8A8496",
                 note="a lilac nearer grey than the first seed (#6E7398): the shadows keep a violet, the paving loses its "
                      "blue cast"),
    atmosphere=dict(Color="#EFE3D6", Decay="#A9BCE4",
                    start=dict(Density=0.24, Offset=0.2, Haze=0.6, Glare=0.3),
                    note="Color is the faces' own horizon band, so the haze meets the sky without a line; Decay the sky's "
                         "pale blue away from it"),
    bloom=dict(start=dict(Intensity=0.3, Size=24, Threshold=2.2)),
    environmentDiffuseScale=0.5,
    shares=dict(Floor=0.35, Glow=0.45, Lights=0.2,
                note="the builder's own (Config.Lighting.Phases.Day), unmoved: the floors' glow, the kit's glow and the "
                     "street's lights by day. environmentDiffuseScale comes down from 1 so the blue sky tints the ground less"),
    note="seeds, not measurements: set from the painted faces, never seen in the engine")


def main():
    out = Path(sys.argv[1])
    size = int(sys.argv[2]) if len(sys.argv) > 2 else 1024
    out.mkdir(parents=True, exist_ok=True)
    rng = np.random.default_rng(3)
    faces = {}
    for face, (ahead, top) in FACES.items():
        faces[face] = picture(rays(ahead, top, size))
        if size == 1024:
            save(faces[face], out / f"LanternRow_SkyDay_{face}.png", rng)
        print(face, "painted")
    k = 256
    small = {f: px[::size // k, ::size // k] if size >= k else px for f, px in faces.items()}
    views = [view(0, 12), view(120, 12), view(200, 38)]
    sheet = np.full((k + 16 + 540 + 16 + 540, 960 * 2 + 16, 3), 0.07, np.float32)
    for i, f in enumerate(("Ft", "Lf", "Bk", "Rt", "Up", "Dn")):
        sheet[0:k, i * (k + 8):i * (k + 8) + k] = small[f][:k, :k]
    sheet[k + 16:k + 16 + 540, 0:960], sheet[k + 16:k + 16 + 540, 976:1936] = views[0], views[1]
    sheet[k + 32 + 540:k + 32 + 1080, 0:960] = views[2]
    save(sheet, out / ("lantern_row_sky_day_sheet.png" if size == 1024 else f"sky_day_sheet_{size}.png"))
    if size == 1024:
        path = out / "lighting.json"
        book = json.loads(path.read_text(encoding="utf-8"))
        book = {"Day": DAY, **{name: block for name, block in book.items() if name != "Day"}}
        path.write_text(json.dumps(book, indent=1), encoding="utf-8")


if __name__ == "__main__":
    main()
