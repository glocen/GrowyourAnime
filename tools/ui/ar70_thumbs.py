"""AR70, the game page's thumbnails: the game's own frames, cropped to 16:9, graded, and the logotype set in one corner
(research's brief of 2026-11-27, 20:17). No new renders: each thumbnail is a Studio capture of the game as it is, so
nothing shows what the game doesn't have (rule 4).

    py tools/ui/ar70_thumbs.py <out_dir> thumbs [key ...]               each take: crop, grade, logotype; 1920 x 1080
    py tools/ui/ar70_thumbs.py <out_dir> one <capture> <cx> <cy> <w> [corner] [grade]   a trial crop of any capture
    py tools/ui/ar70_thumbs.py <out_dir> sheet <refs_dir> <beside_dir>  ours at the store's card size among the top games'

A crop is its centre (cx, cy) and width w, in fractions of the capture's width and height; its height follows from 16:9.
The grade works on the engine's picture, already tone-mapped: back to linear light, an exposure, a contrast round middle
grey, saturation, a bloom from the lights, the shadows a little toward the sky's blue and the highlights toward warm,
and a vignette. The logotype is the icon's (ar70_painted_targets.logo_svg, as C round 2 set it).
"""
import json
import subprocess
import sys
from pathlib import Path

import numpy as np
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
import ar70_painted_targets as pt  # noqa: E402
import hud_m_lead_targets as hl  # noqa: E402
import style_frames as sf  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
W, H = 1920, 1080                     # Roblox's thumbnail, 16:9
WORK = REPO / "build" / "scratch" / "modulo" / "ar70_thumbs"   # gitignored
CARD = (400, 225)                     # about the store's card on a phone (research's brief)
# `violet` takes that much of the saturation out of the blue-violet hues (230 to 300 degrees): the director's "too
# purple" (said six times by 2026-11-24), on a dusk street whose sky and paving are violet
GRADE = dict(exposure=1.08, contrast=1.18, sat=1.28, bloom=0.35, cool=0.0, warm=0.06, vignette=0.32, violet=0.3)
LOGO = dict(size=1.45, margin=(64, 58), grow=("Bangers", 60, 3, 0.86), bright_i=True)
# the takes, once Faber's captures are in build/captures/ar70/: key -> capture, crop (cx, cy, w), corner, grade changes
# the staged shot 1 is lit by day, so its grade holds the light and takes more colour (`DAY`)
DAY = dict(exposure=0.98, sat=1.45, contrast=1.25)
TAKES = {
    # the staged shot 1 (Faber, 2026-11-27, 21:57): a scripted camera on the foes' side, low, at the brightest dusk
    # or day; the game's own camera (21:36) was read WORSE by research at 21:44 (no face, no readable hit, black sky)
    "fight_hit": dict(capture="build/captures/ar70/shot1_staged_rook_hit_dusk00.png", box=(0.46, 0.47, 0.72),
                      corner="br", grade=DAY),
    "fight_face": dict(capture="build/captures/ar70/shot1_staged_rook_step_dusk00.png", box=(0.5, 0.575, 0.75),
                       corner="br", grade=dict(DAY, exposure=1.15, contrast=1.15)),
    "fight_pip": dict(capture="build/captures/ar70/shot1_staged_pip_burst_day00.png", box=(0.5, 0.5, 1.0),
                      corner="br", grade=DAY),
}
TITLES = {"fight_hit": "Rook, the hit", "fight_face": "Rook, the face", "fight_pip": "Pip, the burst",
          "shard": "the shard", "bays": "the bays at work"}


def read(path):
    """The capture as floats in [0, 1], its rows top first."""
    w, h = sf.png_size(path) if str(path).endswith(".png") else probe(path)
    raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", str(path), "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.uint8).reshape(h, w, 3).astype(np.float32) / 255.0


def probe(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=width,height",
                          "-of", "csv=p=0", str(path)], capture_output=True, text=True, check=True).stdout
    w, h = out.strip().split(",")
    return int(w), int(h)


def crop(img, cx, cy, w):
    """The 16:9 box round (cx, cy), `w` of the capture's width, resampled to 1920 x 1080 (cubic)."""
    ih, iw = img.shape[:2]
    bw = w * iw
    bh = bw * H / W
    if bh > ih:
        raise SystemExit(f"crop: {bw:.0f} x {bh:.0f} is taller than the capture's {ih}")
    x0 = min(max(cx * iw - bw / 2, 0), iw - bw)
    y0 = min(max(cy * ih - bh / 2, 0), ih - bh)
    ys = y0 + (np.arange(H) + 0.5) * bh / H - 0.5
    xs = x0 + (np.arange(W) + 0.5) * bw / W - 0.5
    grid = np.meshgrid(ys, xs, indexing="ij")
    out = np.dstack([ndimage.map_coordinates(img[..., c], grid, order=3, mode="nearest") for c in range(3)])
    if bw < W:
        print(f"crop: upscaled {W / bw:.2f}x from {bw:.0f} px wide")
    return np.clip(out, 0, 1)


def grade(img, g):
    lin = np.where(img <= 0.04045, img / 12.92, ((img + 0.055) / 1.055) ** 2.4) * g["exposure"]
    lum = lin @ np.array([0.2126, 0.7152, 0.0722], np.float32)
    # contrast round middle grey, in log light, so the lights and the darks spread evenly
    ll = np.log2(np.maximum(lum, 1e-4) / 0.18)
    k = 2 ** (ll * (g["contrast"] - 1))
    lin = lin * k[..., None]
    lum = lum * k
    sat = np.full(lum.shape, g["sat"], np.float32)
    if g.get("violet"):
        r, gr, b = lin[..., 0], lin[..., 1], lin[..., 2]
        hue = np.degrees(np.arctan2(np.sqrt(3) * (gr - b), 2 * r - gr - b)) % 360
        band = np.clip(1 - np.abs(hue - 265) / 40, 0, 1)        # full at 265, none past 225 and 305
        sat = sat * (1 - g["violet"] * band)
    lin = lum[..., None] + (lin - lum[..., None]) * sat[..., None]
    # the bloom: what's brighter than 0.8 spreads
    hot = np.clip(lin - 0.8, 0, None)
    spread = sum(np.dstack([ndimage.gaussian_filter(hot[..., c], W * r) for c in range(3)]) * w
                 for r, w in ((0.004, 0.5), (0.015, 0.35), (0.05, 0.25)))
    lin = lin + spread * g["bloom"]
    # the split tone: the shadows toward the sky's blue, the highlights toward warm
    t = np.clip(lum, 0, 1)[..., None]
    lin = lin + (1 - t) * np.array([-0.2, 0.1, 1.0]) * g["cool"] * 0.1 + t * np.array([1.0, 0.45, -0.3]) * g["warm"] * 0.1
    # the vignette, an ellipse to the frame
    y, x = np.mgrid[0:H, 0:W].astype(np.float32)
    r = np.sqrt(((x - W / 2) / (W / 2)) ** 2 + ((y - H / 2) / (H / 2)) ** 2) / np.sqrt(2)
    lin = lin * (1 - g["vignette"] * np.clip(r - 0.35, 0, None) ** 1.6 / 0.65 ** 1.6)[..., None]
    lin = np.clip(lin, 0, None)
    lin = lin / (1 + np.maximum(lin - 1, 0))          # a soft shoulder over white
    return np.where(lin <= 0.0031308, lin * 12.92, 1.055 * np.clip(lin, 0, 1) ** (1 / 2.4) - 0.055)


def logo_at(corner, lg):
    """The logotype's centre and baseline for a corner (tl, tr, bl, br), on the 1920 x 1080 canvas."""
    size, (mx, my) = lg["size"], lg["margin"]
    half = 150 * size                 # the logotype's half-width, with its lean
    top = 104 * size * (lg["grow"][3] + 0.75)        # from ANIME's baseline to GROW YOUR's top
    cx = mx + half if corner[1] == "l" else W - mx - half
    base = (my + top) if corner[0] == "t" else H - my - 10 * size
    return cx, base


def compose(art_png, corner, lg, path):
    cx, base = logo_at(corner, lg)
    extra = {k: lg[k] for k in ("grow", "bright_i")}
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">'
           f'<image href="{Path(art_png).as_uri()}" x="0" y="0" width="{W}" height="{H}"/>'
           f'{pt.logo_svg(cx, base, lg["size"], **extra)}</svg>')
    html = (f'<!doctype html><html><head><meta charset="utf-8"><style>{pt.fonts_css()} html,body{{margin:0;background:#000}}'
            f' svg{{display:block}}</style></head><body>{svg}</body></html>')
    sf.shoot(html, path, W, H, scale=1)


def make(out, key, capture, box, corner="br", changes=None):
    g = dict(GRADE, **(changes or {}))
    img = grade(crop(read(capture), *box), g)
    art = WORK / f"art_{key}.png"         # the graded frame without words, kept out of the handoff
    art.parent.mkdir(parents=True, exist_ok=True)
    hl.write_png(art, img)
    path = out / f"thumb_{key}.png"
    compose(art, corner, LOGO, path)
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(path), "-vf",
                    f"scale={CARD[0]}:{CARD[1]}:flags=area", str(out / f"thumb_{key}_card.png")], check=True)
    size = path.stat().st_size
    print(f"{key}: {path} ({size / 1e6:.2f} MB{', over the 3 MB limit' if size > 3e6 else ''})")
    return path


def tile(path, w, h, title, fg):
    return (f'<div class="tile" style="width:{w}px"><img src="{Path(path).as_uri()}" style="width:{w}px;height:{h}px;'
            f'display:block;border-radius:{w * 0.03:.0f}px;object-fit:cover"><div class="t" style="color:{fg};'
            f'font-size:15px">{title}</div></div>')


def sheet(out, refs, beside_out):
    """Ours at the card's size among the 30 top games' first thumbnails, anime games first (internal, kept with the
    references); and ours alone at 1920 wide, then at the card, on Roblox's dark and light pages (for the handoff)."""
    keys = [k for k in TITLES if (out / f"thumb_{k}.png").exists()]
    anime = ["sailor_piece", "anime_vanguards", "anime_last_stand", "jujutsu_infinite", "anime_defenders",
             "arise_crossover", "strongest_battlegrounds", "anime_adventures", "anime_rangers_x", "blox_fruits",
             "king_legacy"]
    others = sorted(f.stem for f in refs.glob("*.png") if f.stem not in anime)
    order = [(refs / f"{n}.png", n.replace("_", " ").title()) for n in anime + others]
    for i, k in zip((3, 9, 16, 22, 27), keys):
        order.insert(i, (out / f"thumb_{k}.png", f"Grow your Anime: {TITLES[k]}"))
    beside_out.mkdir(parents=True, exist_ok=True)
    cols = 6
    cw, ch = CARD
    body = (f'<h1>AR70, the thumbnails among the top games\' at the store\'s card size ({cw} x {ch}): ours are '
            f'"Grow your Anime"</h1><div class="grid" style="width:{cols * (cw + 16)}px">'
            + "".join(tile(f, cw, ch, t, "#E8E2D6") for f, t in order) + "</div>")
    rows = -(-len(order) // cols)
    sf.shoot(pt.page(body), beside_out / "thumbs_beside_card.png", cols * (cw + 16) + 36, 70 + rows * (ch + 44), scale=1)
    print(beside_out / "thumbs_beside_card.png")
    big = "".join(tile(out / f"thumb_{k}.png", 960, 540, TITLES[k], "#E8E2D6") for k in keys)
    rows_html = "".join(f'<div class="grid" style="background:{bg}">'
                        + "".join(tile(out / f"thumb_{k}.png", cw, ch, "Grow your Anime", fg) for k in keys) + "</div>"
                        for bg, fg in (("#111216", "#E8E2D6"), ("#F2F4F5", "#1B1D1F")))
    body = f'<h1>AR70, the thumbnails at half size, then at the card on the dark and light pages</h1><div class="grid">{big}</div>{rows_html}'
    big_rows = -(-len(keys) // 2)
    sf.shoot(pt.page(body, "#1A1C21"), out / "thumbs_sheet.png", 2 * 976 + 36, 70 + big_rows * 590 + 2 * (ch + 80), scale=1)
    print(out / "thumbs_sheet.png")


if __name__ == "__main__":
    out = Path(sys.argv[1]).resolve()
    out.mkdir(parents=True, exist_ok=True)
    mode, rest = sys.argv[2], sys.argv[3:]
    if mode == "thumbs":
        for key in rest or list(TAKES):
            t = TAKES[key]
            make(out, key, REPO / t["capture"], t["box"], t.get("corner", "br"), t.get("grade"))
    elif mode == "one":
        capture, box = Path(rest[0]).resolve(), tuple(float(v) for v in rest[1:4])
        corner = rest[4] if len(rest) > 4 else "br"
        changes = json.loads(rest[5]) if len(rest) > 5 else None
        make(out, Path(rest[0]).stem, capture, box, corner, changes)
    else:
        sheet(out, Path(rest[0]).resolve(), Path(rest[1]).resolve())
