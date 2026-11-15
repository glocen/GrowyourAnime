"""The level-up's notice, B (Step, in the card's violet): its images for Faber's build (AR12, "The director's pick",
2026-11-15). The plate is the takes' own drawing (levelup_notice_takes.py) and the motion's numbers are the clip's
(levelup_notice_clip.py); nothing is drawn twice.

Three images, four pixels a point, straight colour:

    LevelUpPlate    the whole plate with its shadow and its glow: its ends keep their size, its middle stretches;
    LevelUpFlash    the block's shape in white, for the flash as the number lands;
    LevelUpSheen    the leaning band of light that crosses the plate once.

The number, the name and "LEVEL UP" are the game's own text, placed by levelup_notice.json.

    blender -b --factory-startup --python tools/blender/levelup_notice_art.py -- build/handoff/UI/hud/levelup

Writes images/, levelup_notice.json and the sheet levelup_notice_images.png: the notice laid from the images beside the
takes' drawing, the landing, and each image as written and at exactly 64 pixels on dark, for the content check.
"""
import json
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import levelup_notice_clip as clip  # noqa: E402

nt = clip.nt
h, kit, ui, c, rs = nt.h, nt.kit, nt.ui, nt.c, nt.h.rs
MG, S, COL = nt.MG, nt.S, nt.VIOLET
TALL, BW = nt.STEP
LEAN = TALL * S
REF = 132.0  # the plate's width as drawn for its image
CUT = (MG + BW + LEAN + 4.2, 0.0, MG + 58.0, 0.0)  # the block and its end; the far end with the plate's own sheen
HALF, CORE = 26.0, 5.0  # the moving sheen: its soft half-width and its bright core's, in points
LINE = "LEVEL UP"
SIZES = {1: 27, 2: 25, 3: 19}  # the number's size by its count of digits
DARK = "#0D0A1C"
SHOWN = (("Rook", 12), ("Lyric", 48), nt.LONG)


def width(who):
    return BW + LEAN + 10 + max(nt.est(who, 16), nt.est(LINE, 11, 1.14)) + 14


def parts():
    """Draws the three images into the kit, each at four pixels a point."""
    kit.keep("LevelUpPlate", nt.plate_tile(REF, TALL, BW, COL), cut=CUT, pad=MG,
             use="the whole plate: shadow, glow, body, block, rim. Under the words. Its width is `plate.width`")
    t = kit.blank(BW + LEAN + 2, TALL)
    t.paint(t.poly([(LEAN + 1, 0), (BW + LEAN + 1, 0), (BW + 1, TALL), (1, TALL)]), c("#FFFFFF"))
    kit.keep("LevelUpFlash", t, use="the block in white, over the plate and under the number: the flash as the number lands")
    t = kit.blank(2 * HALF + LEAN + 2, TALL)
    q = np.abs(t.x - 1 - (TALL - t.y) * S - HALF)
    band = 0.6 * np.clip(1 - q / HALF, 0, 1) ** 1.5 + 0.4 * np.clip(1 - q / CORE, 0, 1)
    ui.over(t.px, c("#F6F1FF"), np.clip(band, 0, 1))
    kit.keep("LevelUpSheen", t, use="the sheen: over the plate and under the words, moved across once after the landing")


PARTS = ("LevelUpPlate", "LevelUpFlash", "LevelUpSheen")
ORIGIN = {"LevelUpPlate": (-MG, -MG), "LevelUpFlash": (-1.0, 0.0)}


def manifest(out):
    data = dict(
        pixelsPerPoint=4,
        note="The level-up's notice (AR12, B). One plate on the left, its top left at `place` on the screen. Every place "
             "is in points from the plate's own top left (its body's box, not its image's: the image reaches 16 past it "
             "on every side). An image's `at` is its own top left, and it's shown at its `points`.",
        place=dict(at=list(nt.NOTICE), why="the lead's card's left edge, under the readout's row (its foot at 230) and "
                                           "over the thumbstick (its top at 289)"),
        plate=dict(tall=TALL, block=BW, lean=S,
                   width=f"{BW + LEAN + 10 + 14:g} + the wider of the name at 16 points and \"{LINE}\" at 11",
                   leans="its ends lean `lean` across per down: the top edge starts tall * lean to the right of the foot's"),
        stack=["LevelUpPlate, stretched to the width", "LevelUpFlash, at the landing only", "LevelUpSheen, while it crosses",
               "the name and the line", "the number"],
        words=dict(
            number=dict(middle=[(BW + LEAN) / 2 - 1, TALL / 2], size=SIZES, colour=COL["on"], weight="bold",
                        note="centred on the block; its size by its count of digits"),
            name=dict(at=[round(BW + (TALL - 13) * S + 10, 2), 8.0], size=16, colour=COL["text"]),
            line=dict(text=LINE, at=[round(BW + (TALL - 32) * S + 10, 2), 28.0], size=11, colour=COL["soft"], spacing=1.14),
            note="`at` is a word's left end and its capitals' top"),
        motion=dict(
            note="DESIGN, as the clip shows it (levelup_notice_clip.mp4); untried in Studio. Seconds.",
            slideIn=dict(seconds=clip.SLIDE, ease="cubic out", start="wholly off the screen's left edge, its glow with it"),
            number=dict(appears="as the plate arrives", fall=clip.FALL, fromSize=clip.FROM, squash=clip.SQUASH,
                        settle=clip.SETTLE, note="it falls from `fromSize` times its size to `squash` (quadratic in), "
                                                 "fading in over the fall's first third, then settles to 1 (quadratic out)"),
            flash=dict(image="LevelUpFlash", at="the landing, the fall's end", strength=0.75, seconds=clip.FLASH,
                       note="its strength falls to nothing, quadratic out"),
            knock=dict(points=clip.KICK, seconds=0.12, note="the whole notice, to the right and back, at the landing"),
            sheen=dict(image="LevelUpSheen", after=clip.SHEEN_AT, seconds=clip.SHEEN, ease="smooth step",
                       travel="its middle from 30 points left of the plate to 30 past its far end, along the foot; the "
                              "band's middle at the foot is 27 from its image's left",
                       note="in the clip it shows only on the plate's own shape. With a box for a clip it would show "
                            "past the leaning ends: fade it in over its first 26 points on the plate and out over its "
                            "last 26, or clip it by the plate's image"),
            hold=dict(seconds=clip.HOLD, note="from its arrival"),
            slideOut=dict(seconds=clip.LEAVE, ease="cubic in", end="where it came from"),
            reducedMotion="it fades in at its place with the number set, no fall, flash, knock or sheen, and fades out"),
        images={n: dict(file=f"images/{n}.png", pixels=[im["px"].shape[1], im["px"].shape[0]], points=[im["w"], im["h"]],
                        **({"at": list(ORIGIN[n])} if n in ORIGIN else {}),
                        **({"cut": [round(v, 2) for v in im["cut"]]} if im["cut"] else {}), use=im["use"])
                for n, im in ((n, kit.IMAGES[n]) for n in PARTS)})
    (out / "levelup_notice.json").write_text(json.dumps(data, indent=1), encoding="utf-8", newline="\n")
    print(f"wrote {out / 'levelup_notice.json'}: {len(PARTS)} images")


def laid(st, x, y, who, n, flash=0.0, sheen=None):
    """The notice from its images and the game's words, as the manifest says."""
    w = width(who)
    st.lay("LevelUpPlate", x, y, w, TALL)
    if flash:
        st.lay("LevelUpFlash", x - 1, y, alpha=flash)
    if sheen is not None:  # how far across, 0 to 1, kept on the plate
        st.lay("LevelUpSheen", x + HALF + (w - LEAN - 2 * HALF) * sheen - HALF - 1, y)
    size = SIZES[len(str(n))]
    nt.word(st, x + (BW + LEAN) / 2 - 1, y + (TALL - size * ui.CAP) / 2, size, str(n), COL["on"], "CENTER", bold=nt.BOLD)
    nt.word(st, x + BW + (TALL - 13) * S + 10, y + 8, 16, who, COL["text"])
    nt.word(st, x + BW + (TALL - 32) * S + 10, y + 28, 11, LINE, COL["soft"], space=1.14)
    return w


def rows():
    """The sheet's pictures: laid from the images, as the takes drew it, and the landing."""
    made = []
    for kind in ("laid", "drawn", "landing"):
        st = kit.Stage(840.0, 76.0, h.PARTS_GROUND)
        st.px[:, round(560 * nt.K4):, :3] = c(h.PALE_GROUND)[:3]
        x = 14.0
        for i, (who, n) in enumerate(SHOWN):
            if kind == "drawn":
                w, _ = nt.step(st, x, 16, COL, who, n)
            else:
                w = laid(st, x, 16, who, n, *(((0.75, None), (0.0, 0.35), (0.0, 0.8))[i] if kind == "landing" else ()))
            x = (200.0, 400.0, 0.0)[i] + 14
        made.append((h.bytes8(h.halve(st.px)), st.items))
    return made


def sheet(out, made):
    ui.K = 2
    m, head = 20.0, 64.0
    sh = ui.Sheet(840 + 2 * m, head + 3 * (22 + 76 + 8) + 30 + 176 + 16, h.GROUND)
    t = sh.tile(0, 0, sh.w, head)
    t.text(m, 14, 17, "Grow your Anime: the level-up's notice, B: its images for the build (AR12)", h.HEAD)
    t.text(m, 40, 10, "Three images, four pixels a point: the plate (its middle stretches), the block's flash, the sheen. "
           "The number, the name and \"LEVEL UP\" are the game's own text (levelup_notice.json).", h.NOTE)
    y = head
    for name, (px, items) in zip((
            "Laid from the images: the shortest, a Mythical's, and the longest name at level 100 (on a pale ground)",
            "As the takes' sheet drew it, for the comparison",
            "The landing, from the images: the block's flash at its start; the sheen a third across; four fifths across"),
            made):
        sh.tile(m, y, 840, 22).text(0, 6, 11, name, h.HEAD)
        h.add(sh, px, items, m, y + 22)
        y += 22 + 76 + 8
    sh.tile(m, y, 840, 30).text(0, 10, 11, "Each image as written, on dark, and at exactly 64 pixels across", h.HEAD)
    y += 30
    ground = ui.Sheet(840, 176, DARK)
    kit.put(sh, ground.px, m * 2, y * 2)
    x = m * 2 + 24
    for name in PARTS:
        px = kit.IMAGES[name]["px"]
        kit.put(sh, px, x, y * 2 + 16)
        kit.put(sh, rs.shrink(px, 64 / px.shape[1]), x + px.shape[1] + 20, y * 2 + 16)
        sh.tile(x / 2, y + 160, 300, 14).text(0, 2, 9, f"{name}.png, {px.shape[1]} by {px.shape[0]}", h.NOTE)
        x += px.shape[1] + 20 + 64 + 40
    kit.finish(sh, out / "levelup_notice_images.png")


def main():
    out = bl.out_dir()
    ui.K = nt.K4
    h.stage("started")
    parts()
    (out / "images").mkdir(exist_ok=True)
    for name in PARTS:
        px = kit.IMAGES[name]["px"].copy()
        kit.bleed(px)
        rs.save(px, out / "images" / f"{name}.png")
    manifest(out)
    made = rows()
    h.stage("the rows")
    sheet(out, made)
    h.stage("the sheet")


if __name__ == "__main__":
    main()
