"""AR70, the icon as a render of a Roblox player: the grade, the logotype and the sheets, from tools/blender/ar70_player.py's
renders (research's order of 2026-11-27, 18:30; the study, docs/research/game-icons.md).

    py tools/ui/ar70_player_targets.py <renders_dir> <out_dir> grade <shot> ...    each shot graded, no words
    py tools/ui/ar70_player_targets.py <renders_dir> <out_dir> icons <shot> ...    graded, with the logotype, at 512/150/100
    py tools/ui/ar70_player_targets.py <renders_dir> <out_dir> sheets <refs_dir> <beside_dir> [shot ...]

The S and T shots (the director's word of 2026-11-27, 23:15: the player and a Voidkin as a silhouette of light) take
the GFX paint-over, `paint()`, from the render's masks (docs/research/gfx-technique.md).

The grade, as the study measured the shipped player icons (bright, lit, black under 5% at 150 px, saturation about 0.5
to 0.6, bloom only on the lights): an exposure, a filmic curve, a bloom from what's brighter than white, a little lift
in the shadows toward the sky's blue, and saturation. The logotype is option (b)'s (ar70_painted_targets.logo_svg),
carried over as research allowed.
"""
import json
import sys
from pathlib import Path

import numpy as np
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
import ar70_icon_targets as it  # noqa: E402
import ar70_painted_targets as pt  # noqa: E402
import hud_m_lead_targets as hl  # noqa: E402
import style_frames as sf  # noqa: E402

GRADES = {  # per shot: exposure, saturation, bloom strength, the logotype's size and its baseline (on the 512 canvas)
    "A": dict(exposure=0.7, sat=1.45, bloom=0.5, logo=(0.96, 478)),
    "B": dict(exposure=0.7, sat=1.45, bloom=0.5, logo=(0.96, 478)),
    "C": dict(exposure=0.6, sat=1.5, bloom=0.5, logo=(0.9, 482), grow=("Bangers", 60, 3, 0.86), bright_i=True),
    "S1": dict(exposure=0.6, sat=1.4, bloom=0.6, logo=(0.9, 482), grow=("Bangers", 60, 3, 0.86), bright_i=True,
               paint="silhouette_hot"),
    "S2": dict(exposure=0.6, sat=1.4, bloom=0.6, logo=(0.9, 482), grow=("Bangers", 60, 3, 0.86), bright_i=True,
               paint="silhouette_hot"),
    "T1": dict(exposure=0.6, sat=1.4, bloom=0.6, paint="silhouette_hot"),
    "T2": dict(exposure=0.6, sat=1.4, bloom=0.6, paint="silhouette_hot"),
    "S1h": dict(exposure=0.6, sat=1.4, bloom=0.6, logo=(0.9, 482), grow=("Bangers", 60, 3, 0.86), bright_i=True,
                paint="silhouette_hot", render="S1"),
}
PAINTS = {  # the GFX paint-overs (paint() above), by name
    "silhouette": dict(core="#36CCFF", core_k=1.5, edge="#F2FDFF", edge_k=3.2, core_w=0.016, eye="#F6FFFF", eye_k=4.0,
                       aura="#1FA4FF", aura_k=1.5, rim="#BDF2FF", rim_k=2.5, rim_w=0.006, lines=20, lines_clear=0.26,
                       lines_k=0.45, vignette=0.45, back_dark=0.4),
    # the same, white-hot inside and the colour at the outline: the first try, kept for the pair
    "silhouette_hot": dict(core="#E6FAFF", core_k=2.6, edge="#2FC4FF", edge_k=2.2, core_w=0.07, eye="#0A3A9A", eye_k=0.25,
                           aura="#1FA4FF", aura_k=1.4, rim="#BDF2FF", rim_k=2.5, rim_w=0.006, lines=20, lines_clear=0.26,
                           lines_k=0.45, vignette=0.45, back_dark=0.4),
}
for _g in GRADES.values():
    if isinstance(_g.get("paint"), str):
        _g["paint"] = PAINTS[_g["paint"]]
TITLES = {"A": "A, the raise", "B": "B, the offer", "C": "C, the smash", "S1": "S1, the silhouette rising",
          "S2": "S2, the silhouette towering"}


def aces(x):
    return np.clip((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0, 1)


def coded(c):
    c = np.clip(c, 0, 1)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)


def blur(rgb, radii):
    n = rgb.shape[0]
    return sum(np.dstack([ndimage.gaussian_filter(rgb[..., c], n * r) for c in range(3)]) * w for r, w in radii)


def hexlin(h, k=1.0):
    c = np.array([int(h[i:i + 2], 16) for i in (1, 3, 5)]) / 255
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4) * k


def paint(rgb, light, ids, marks, g):
    """The GFX paint-over (docs/research/gfx-technique.md), in linear light before the curve, from the render's masks
    (`ids`: the player red, the silhouette green, its eyes blue):
    - the silhouette as one shape of light with no block inside it: white-hot at its heart, its colour toward the
      outline, its eyes dark slits;
    - its aura, the shape's own glow past the outline;
    - the player's rim line on the edges that face the light;
    - speed lines from the shard over the backdrop only, and the corners darkened, so the eye goes to the contact."""
    p = g["paint"]
    h, w = rgb.shape[:2]
    n = h   # the paint's sizes are fractions of the frame's height
    P, K, E = (np.clip(ids[..., c], 0, 1) for c in range(3))
    K = np.clip(K + E, 0, 1)   # the eyes are the figure's too
    inside = ndimage.distance_transform_edt(ndimage.binary_fill_holes(K > 0.5)) / (n * p["core_w"])   # what
    # stands in front of it (the chips) cuts it, but makes no outline inside it
    t = np.clip(inside, 0, 1)[..., None] ** 0.8
    fill = hexlin(p["edge"], p["edge_k"]) * (1 - t) + hexlin(p["core"], p["core_k"]) * t
    fill = fill * (1 - E[..., None]) + hexlin(p["eye"], p["eye_k"]) * E[..., None]
    rgb = rgb * (1 - K[..., None]) + fill * K[..., None]
    aura = sum(ndimage.gaussian_filter(K, n * r) * w for r, w in ((0.006, 0.6), (0.02, 0.45), (0.06, 0.4)))
    rgb = rgb + aura[..., None] * hexlin(p["aura"], p["aura_k"]) * (1 - 0.75 * P[..., None])
    head, kin = np.array(marks["head"]), np.array(marks["kin_head"])
    d = (kin - head) / np.linalg.norm(kin - head)
    step = n * p["rim_w"]
    beyond = ndimage.shift(P, (-d[1] * step, -d[0] * step), order=1, mode="constant")
    rim = ndimage.gaussian_filter(np.clip(P - beyond, 0, 1), n * 0.0015)
    rgb = rgb + rim[..., None] * hexlin(p["rim"], p["rim_k"])
    yy, xx = np.mgrid[0:h, 0:w].astype(float)
    if p.get("lines"):
        sx, sy = marks["shard"]
        r = np.hypot(xx - sx, yy - sy)
        th = np.arctan2(yy - sy, xx - sx)
        rng = np.random.default_rng(5)
        lines = np.zeros_like(r)
        for a, w, k in zip(rng.uniform(-np.pi, np.pi, p["lines"]), rng.uniform(0.4, 1.0, p["lines"]),
                           rng.uniform(0.4, 1.0, p["lines"])):
            off = np.angle(np.exp(1j * (th - a))) * r          # the distance across the line, in pixels
            width = n * 0.006 * w * np.clip(r / (n * 0.5), 0, 1.5)
            lines = np.maximum(lines, k * np.exp(-(off / np.maximum(width, 0.3)) ** 2))
        lines *= np.clip((r - n * p["lines_clear"]) / (n * 0.25), 0, 1)
        rgb = rgb + (lines * (1 - P) * (1 - K))[..., None] * hexlin("#FFFFFF", p["lines_k"])
    if p.get("back_dark"):   # the backdrop deeper away from the contact, so the light and the faces carry the frame
        sx, sy = marks["shard"]
        near = np.exp(-(np.hypot(xx - sx, yy - sy) / (n * 0.3)) ** 2)
        rgb = rgb * (1 - (p["back_dark"] * (1 - near) * (1 - P) * (1 - K)))[..., None]
    far = np.hypot(xx / w - 0.5, yy / h - 0.5) / 0.7071
    rgb = rgb * (1 - p["vignette"] * np.clip((far - 0.35) / 0.65, 0, 1) ** 1.6)[..., None]
    return rgb, (light * (1 - K[..., None]) if light is not None else None)


def grade(lin, g, light=None, ids=None, marks=None):
    """`light` is the render of the lights alone (the Voidkin and the burst on black): it glows past their shapes,
    so they read as light and not as lit things."""
    rgb = lin[..., :3] * g["exposure"]
    if ids is not None and "paint" in g:
        rgb, light = paint(rgb, light, ids, marks, g)
    hot = np.clip(rgb - 1.0, 0, 8)
    rgb = rgb + blur(hot, ((0.006, 0.5), (0.02, 0.35), (0.06, 0.25))) * g["bloom"]
    if light is not None:
        rgb = rgb + blur(light[..., :3] * g["exposure"], ((0.01, 0.35), (0.035, 0.45), (0.09, 0.4))) * g.get("glow", 0.8)
    lum = rgb @ np.array([0.2126, 0.7152, 0.0722])
    rgb = lum[..., None] + (rgb - lum[..., None]) * g["sat"]      # saturation
    rgb = rgb + np.array([0.004, 0.008, 0.016]) * (1 - np.clip(lum, 0, 1))[..., None]   # the shadows toward the sky
    return coded(aces(np.clip(rgb, 0, None)))


def load(renders, shot):
    light, ids = renders / f"{shot}_light.npy", renders / f"{shot}_ids.npy"
    return (np.load(renders / f"{shot}.npy"), np.load(light) if light.exists() else None,
            json.loads((renders / f"{shot}.json").read_text(encoding="utf-8")), np.load(ids) if ids.exists() else None)


def graded(renders, out, shot):
    lin, light, marks, ids = load(renders, GRADES[shot].get("render", shot))
    img = grade(lin, GRADES[shot], light, ids, marks)
    path = out / "work" / f"art_{shot}.png"
    path.parent.mkdir(parents=True, exist_ok=True)
    hl.write_png(path, np.dstack([img, np.ones(img.shape[:2])]))
    return path


def icons(renders, out, shots):
    for shot in shots:
        flat = graded(renders, out, shot)
        size, base = GRADES[shot]["logo"]
        big = out / "work" / f"icon_{shot}_1024.png"
        extra = {k: GRADES[shot][k] for k in ("grow", "bright_i") if k in GRADES[shot]}
        pt.shoot(flat, pt.logo_svg(it.S / 2, base, size, **extra), big)
        made = it.sizes(big, out, shot)
        print(f"{shot}: {made[512]}")


def sheets(out, refs, beside_out, only=()):
    """Ours at 512, then at Roblox's 150, 100 and 64 on its dark and light pages (for the handoff); and beside the
    shipped icons at 150 and 512 (internal, kept with the references). `only` limits them to those shots."""
    keys = [k for k in TITLES if (out / f"icon_{k}.png").exists() and (not only or k in only)]
    ours = {k: out / f"icon_{k}.png" for k in keys}
    big = "".join(pt.tile(ours[k], 512, TITLES[k], "#E8E2D6") for k in keys)
    rows = ""
    for bg, fg in (("#111216", "#E8E2D6"), ("#F2F4F5", "#1B1D1F")):
        cells = "".join(pt.tile(out / f"icon_{k}_150.png", 150, "Grow your Anime", fg) for k in keys)
        cells += "".join(pt.tile(out / f"icon_{k}_100.png", 100, "", fg) for k in keys)
        cells += "".join(pt.tile(ours[k], 64, "", fg) for k in keys)
        rows += f'<div class="grid" style="background:{bg};align-items:flex-start">{cells}</div>'
    what = f"{len(keys)} targets" if len(keys) > 1 else TITLES[keys[0]]
    body = (f'<h1>AR70: the game page icon, a Roblox player, {what}, at 512, then 150, 100 and 64</h1>'
            f'<div class="grid">{big}</div>{rows}')
    sf.shoot(pt.page(body, "#1A1C21"), out / "icon_sheet.png", 1640, 1060, scale=1)
    shipped = sorted(f for f in refs.rglob("*.png") if not f.name.startswith("_"))
    seen, order = set(), []
    for f in shipped:
        if f.stem not in seen:
            seen.add(f.stem)
            order.append((f, f.stem.replace("_", " ").title()))
    for i, k in zip((4, 13, 22), keys):
        order.insert(i, (ours[k], f"Grow your Anime {k}"))
    beside_out.mkdir(parents=True, exist_ok=True)
    for w, cols, width in ((150, 8, 1480), (512, 7, 3740)):
        body = (f'<h1>AR70, a Roblox player, among the shipped icons at {w} px: ours are "Grow your Anime {", ".join(keys)}"</h1>'
                f'<div class="grid" style="width:{cols * (w + 16)}px">'
                + "".join(pt.tile(f, w, t, "#E8E2D6") for f, t in order) + "</div>")
        rows_n = -(-len(order) // cols)
        height = 70 + rows_n * (w + w // 11 + 34)
        sf.shoot(pt.page(body), beside_out / f"player_beside_{w}.png", width, height, scale=1)
        print(beside_out / f"player_beside_{w}.png")
    print(out / "icon_sheet.png")


if __name__ == "__main__":
    renders, out = Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve()
    out.mkdir(parents=True, exist_ok=True)
    mode, rest = sys.argv[3], sys.argv[4:]
    if mode == "grade":
        for s in rest:
            print(graded(renders, out, s))
    elif mode == "icons":
        icons(renders, out, rest)
    else:
        sheets(out, Path(rest[0]).resolve(), Path(rest[1]).resolve(), rest[2:])
