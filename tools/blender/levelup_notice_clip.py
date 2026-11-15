"""The level-up's notice in motion: the director's pick, B (Step, in the card's violet), as a clip for research's
verdict (AR12, "The director's pick", 2026-11-15; the takes: levelup_notice_takes.py).

The motion, as proposed on the takes' sheet. It slides out of the left edge in 0.2 s, the level lands with a pop, one
sheen crosses the whole plate, it holds 2.5 s and leaves the way it came. The levers, each on purpose:

    the slide     ease-out: fast off the edge, settled by the time the eye is on it; ease-in as it leaves;
    the pop       the number falls onto its block from 1.9 times its size, squashes to 0.88 and settles: overshoot;
    the impact    the block flashes white as the number lands, and the plate is knocked 1.5 points and comes back;
    the sheen     the follow-through: one leaning band of light, from the block's end to the plate's far end.

The screen is the takes' own (V2, Block, the lead's card as picked), at dusk (Rook reaches 12) and at noon (a Mythical
reaches 48). The plate, its words and its number are drawn once each, over black and over white, so their cover is
known; every frame is laid from those in numpy, the flash and the sheen under the words. Mocks only.

    blender -b --factory-startup --python tools/blender/levelup_notice_clip.py -- build/handoff/UI/hud/levelup

Writes levelup_notice_clip.mp4 (dusk, then noon, at 30 frames a second) and levelup_notice_clip_frames.png (the corner
up close at ten moments on each street, for a check that can't play it). Frames go through build/scratch/modulo/.
"""
import shutil
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import frames_to_movie as fm  # noqa: E402
import levelup_notice_takes as nt  # noqa: E402

h, kit, ui, c = nt.h, nt.kit, nt.ui, nt.c
rs = h.rs
MG, S = nt.MG, nt.S
FPS = 30
LEAD, SLIDE, HOLD, LEAVE, TAIL = 0.3, 0.2, 2.5, 0.2, 0.3  # seconds: before, the way in, at rest, the way out, after
FALL, SETTLE = 0.12, 0.1  # the number: its fall onto the block, then its squash coming back
FROM, SQUASH = 1.9, 0.88  # the number's size as it appears, and at its lowest
FLASH, KICK = 0.14, 1.5  # the block's flash in seconds; the plate's knock in points
SHEEN_AT, SHEEN = 0.1, 0.5  # the sheen: how long after the landing it starts, and how long it takes to cross
LAYER = (300.0, 44.0 + 2 * MG)  # the notice's own picture, the plate at MG, MG
MOMENTS = (0.07, 0.13, 0.2, 0.27, 0.33, 0.55, 0.67, 0.79, 1.6, 2.8)  # the frames' page, seconds from the slide's start
CORNER = (0.0, 160.0, 290.0, 132.0)  # the page's crop: left, top, width, height


def nothing(*_):
    return 0.0, 0.0


def pictures(sc):
    """A street's screen without the notice, and the notice's plate, words and number, each over black and over white."""
    base = nt.screen(sc, dict(draw=nothing, colour=None))
    made = []
    for ground in ("#000000", "#FFFFFF"):
        st = kit.Stage(*LAYER, ground)
        w, tall = nt.step(st, MG, MG, nt.VIOLET, sc["who"], sc["level"])
        number, words = st.items[:1], st.items[1:]
        blank = h.bytes8(h.halve(kit.Stage(*LAYER, ground).px))
        made.append(((h.bytes8(h.halve(st.px)), []), (blank, words), (blank, number)))
    plate, words, number_ = (tuple(m[i] for m in made) for i in range(3))
    return dict(base=base, plate=plate, words=words, number=number_, w=w, tall=tall,
                at=(number[0]["x"], number[0]["y"] + number[0]["size"] * ui.CAP / 2))


def flat(shot, w, tall):
    """A picture with its words set, at two pixels a point."""
    px, items = shot
    sh = ui.Sheet(w, tall, "#000000")
    h.add(sh, px, items, 0, 0)
    for layer in ui.text_layers(sh.px.shape[1], sh.px.shape[0], sh.items).values():
        rs.paste(sh.px, layer, 0, 0)
    return sh.px[..., :3].copy()


def cover(pair):
    """What a picture drawn over black and over white holds: its colour and how much it covers."""
    black, white = (flat(shot, *LAYER) for shot in pair)
    alpha = np.clip(1 - (white - black).mean(axis=-1), 0, 1)
    return np.dstack([np.clip(black / np.maximum(alpha, 1e-4)[..., None], 0, 1), alpha]).astype(np.float32)


def sized(px, centre, scale):
    """A picture drawn larger or smaller about a point, in its own frame."""
    tall, wide = px.shape[:2]
    ys, xs = np.mgrid[0:tall, 0:wide].astype(np.float32)
    sx, sy = centre[0] + (xs - centre[0]) / scale, centre[1] + (ys - centre[1]) / scale
    x0, y0 = np.clip(np.floor(sx).astype(int), 0, wide - 2), np.clip(np.floor(sy).astype(int), 0, tall - 2)
    fx, fy = np.clip(sx - x0, 0, 1)[..., None], np.clip(sy - y0, 0, 1)[..., None]
    pm = px.copy()
    pm[..., :3] *= pm[..., 3:]
    out = ((pm[y0, x0] * (1 - fx) + pm[y0, x0 + 1] * fx) * (1 - fy)
           + (pm[y0 + 1, x0] * (1 - fx) + pm[y0 + 1, x0 + 1] * fx) * fy)
    inside = ((sx >= 0) & (sx <= wide - 1) & (sy >= 0) & (sy <= tall - 1))[..., None]
    out = out * inside
    out[..., :3] /= np.maximum(out[..., 3:], 1e-6)
    return out


def over(under, top, strength=1.0):
    a = top[..., 3:] * strength
    under[..., :3] = under[..., :3] * (1 - a) + top[..., :3] * a
    under[..., 3:] = under[..., 3:] + a * (1 - under[..., 3:])


def notice(p, t):
    """The notice's own picture at t seconds after it has arrived, and how far its plate is knocked, in points."""
    k = 2
    px = p["plate_px"].copy()
    tall, wide = px.shape[:2]
    ys, xs = np.mgrid[0:tall, 0:wide].astype(np.float32)
    x, y = xs / k - MG, ys / k - MG
    q = x - (p["tall"] - y) * S  # across the plate, along its lean
    body = np.clip((px[..., 3] - 0.9) / 0.1, 0, 1)
    kick = 0.0
    if t >= 0:
        u = t / FALL
        if u < 1:
            scale, show = FROM + (SQUASH - FROM) * u * u, min(u * 3, 1.0)
        else:
            v = min((t - FALL) / SETTLE, 1.0)
            scale, show = SQUASH + (1 - SQUASH) * (1 - (1 - v) ** 2), 1.0
        since = t - FALL  # since the landing
        if since >= 0:  # the flash and the sheen are the plate's, under the words and the number: those stay as set
            flash = 0.75 * max(1 - since / FLASH, 0.0) ** 2
            block = body * np.clip(0.5 - (q - 40.0), 0, 1)  # the block: left of its leaning end
            px[..., :3] += (1 - px[..., :3]) * (flash * block)[..., None]
            kick = KICK * max(1 - since / 0.12, 0.0) * np.sin(min(since / 0.12, 1.0) * np.pi)
            s = (since - SHEEN_AT) / SHEEN
            if 0 <= s <= 1:
                at = -30 + (p["w"] + 60) * (s * s * (3 - 2 * s))
                band = 0.6 * np.clip(1 - np.abs(q - at) / 26.0, 0, 1) ** 1.5 + 0.4 * np.clip(1 - np.abs(q - at) / 5.0, 0, 1)
                px[..., :3] += (c("#F6F1FF") - px[..., :3]) * (np.clip(band, 0, 1) * body)[..., None]
        over(px, p["words_px"])
        over(px, sized(p["number_px"], (p["at"][0] * k, p["at"][1] * k), scale), show)
    else:
        over(px, p["words_px"])
    return px, kick


def frame(p, t):
    """The screen at t seconds from the slide's start (t under 0: before it)."""
    k = 2
    px = p["base_px"].copy()
    rest = nt.NOTICE[0] - MG
    away = -(p["w"] + 2 * MG + 4)  # off the screen's left edge, its glow with it
    end = SLIDE + HOLD
    if t < 0 or t > end + LEAVE:
        return px
    if t < SLIDE:
        u = 1 - (1 - t / SLIDE) ** 3
    elif t <= end:
        u = 1.0
    else:
        u = 1 - ((t - end) / LEAVE) ** 3
    layer, kick = notice(p, t - SLIDE if t >= SLIDE else -1.0)
    x0 = round((away + (rest - away) * u + kick) * k)
    y0 = round((nt.NOTICE[1] - MG) * k)
    a, b = max(-x0, 0), min(layer.shape[1], px.shape[1] - x0)
    if b > a:
        part = px[y0:y0 + layer.shape[0], x0 + a:x0 + b]
        cut = layer[:, a:b]
        part[..., :3] = part[..., :3] * (1 - cut[..., 3:]) + cut[..., :3] * cut[..., 3:]
    return px


def page(out, shots):
    """Ten moments a street, the corner up close."""
    ui.K = 2
    m, head, cap = 20.0, 78.0, 16.0
    _, _, w, tall = CORNER
    per = 22 + 2 * (cap + tall + 6)
    sh = ui.Sheet(5 * w + 2 * m, head + len(shots) * per + 8, h.GROUND)
    t = sh.tile(0, 0, sh.w, head)
    t.text(m, 14, 17, "Grow your Anime: the level-up's notice in motion, B: ten moments on each street (AR12)", h.HEAD)
    t.text(m, 40, 10, "It slides out of the left edge in 0.2 s; the number falls onto its block, squashes and settles, "
           "the block flashes and the plate is knocked 1.5 points; one sheen crosses the whole plate in 0.5 s;", h.NOTE)
    t.text(m, 54, 10, "it holds 2.5 s and leaves the way it came. Seconds are from the slide's start. The clip is "
           "levelup_notice_clip.mp4: dusk, then noon.", h.NOTE)
    y = head
    for name, crops in shots:
        sh.tile(m, y, 5 * w, 22).text(0, 4, 13, name, h.HEAD)
        y += 22
        for i, (at, px) in enumerate(crops):
            x, row = m + (i % 5) * w, y + (i // 5) * (cap + tall + 6)
            sh.tile(x, row, w, cap).text(2, 3, 10, f"{at:.2f} s", h.NOTE)
            kit.put(sh, px, x * 2, (row + cap) * 2)
        y += 2 * (cap + tall + 6)
    kit.finish(sh, out / "levelup_notice_clip_frames.png")


def main():
    out = bl.out_dir()
    ui.K = nt.K4
    h.stage("started")
    kit.panels()
    kit.buttons()
    kit.bars()
    kit.icons()
    h.icons()
    h.card_images()
    nt.lt.vm.marks()
    scenes = (dict(h.SCENES[0], xp=0.06), dict(h.SCENES[1], xp=0.04, covering=False))
    drawn = [pictures(sc) for sc in scenes]
    h.stage("the pictures")
    h.BACKDROPS.clear()
    kit.IMAGES.clear()
    h.IMG.clear()
    ui.K = 2
    for p in drawn:
        base = flat(p["base"], h.W, h.H)
        p["base_px"] = np.dstack([base, np.ones(base.shape[:2], np.float32)])
        p["plate_px"], p["words_px"], p["number_px"] = (cover(p[key]) for key in ("plate", "words", "number"))
    h.stage("their words")
    frames = Path("build/scratch/modulo/levelup/frames").resolve()
    shutil.rmtree(frames, ignore_errors=True)
    frames.mkdir(parents=True)
    count, shots = 0, []
    x0, y0, w, tall = (round(v * 2) for v in CORNER)
    for sc, p in zip(scenes, drawn):
        for i in range(round((LEAD + SLIDE + HOLD + LEAVE + TAIL) * FPS)):
            rs.save(frame(p, i / FPS - LEAD), frames / f"{count:04d}.png")
            count += 1
        crops = [(at, frame(p, at)[y0:y0 + tall, x0:x0 + w].copy()) for at in MOMENTS]
        shots.append((f"{sc['kind'].capitalize()}: {sc['who']} reaches {sc['level']}", crops))
        h.stage(sc["kind"])
    fm.assemble(frames, out / "levelup_notice_clip.mp4", FPS)
    shutil.rmtree(frames, ignore_errors=True)
    page(out, shots)
    h.stage("the page")


if __name__ == "__main__":
    main()
