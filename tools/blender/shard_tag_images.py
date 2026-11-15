"""Where a shard came from: the festival tag's images for the build (AR12, "Where a shard came from: the festival tag";
the block passed research's verdict, 2026-11-15: a quarter of the shard's height at 96 points and a third at 50).

The drawing is the block's own (shard_tag_block.py). This writes what the build needs, for Lantern Row and Drum Court:

    images/ShardTag<Ground>.png      the tag with its thread, in colour
    images/ShardTagMark<Ground>.png  its mark on a disc of the ground's colour, for a small shard's foot
    shard_tag.json                   each ground's colours, where a tag hangs and how large, the mark's and the chip's rules
    shard_tag_images.png             the images as delivered, then stacked by the json's own numbers at the build's sizes

A size in the json is counted as the build counts it: the side a shard's picture is shown at (Config.Hud.ShardArt). The
block counted the crystal's height, which is BODY of that side.

    blender -b --factory-startup --python tools/blender/shard_tag_images.py -- build/handoff/UI/shards/tag

Workbench only, and only for the sheet's words.
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import reveal_blockin as rb  # noqa: E402
import rook_sheet as rs  # noqa: E402
import shard_tag_block as b  # noqa: E402
import ui_kit as kit  # noqa: E402
import ui_sheet as ui  # noqa: E402
from ui_sheet import c  # noqa: E402

PIXELS = 8  # pixels a point in a delivered image
BODY = b.BODY / 1024.0  # the crystal's height against its picture's side
TAG, PLAQUE, TIE = b.TAG, 24.0, b.TIE  # the tag's image in points, its plaque's height, where its thread is tied in it
SHOULDER = (b.SHOULDER[0] * BODY, b.SHOULDER[1] * BODY)  # where the thread is tied, from the picture's middle, in sides
THIRD, QUARTER = 50.0 / BODY, 96.0 / BODY  # the picture's side up to which the tag is a third, and from which a quarter
DISC, DISC_AT, DISC_LEAST = 16.0 * 13.0 / 13.2 / 40.0 * BODY, (0.3 * BODY, 0.36 * BODY), 14.0  # the mark's image, in sides
BAND = 3.6  # the band along a 26-point chip's foot, in points
FILE = {"Lantern Row": "LanternRow", "Drum Court": "DrumCourt"}


def share(side):
    """The plaque's height against the crystal's: a third up to THIRD, a quarter from QUARTER, a straight line between."""
    t = min(max((side - THIRD) / (QUARTER - THIRD), 0.0), 1.0)
    return 1 / 3 + (1 / 4 - 1 / 3) * t


def tag_box(side):
    """Where a tag's image lies on a shard's picture shown `side` points across: its left and top from the picture's
    middle, its width and its height, in points."""
    k = side * BODY * share(side) / PLAQUE
    return SHOULDER[0] * side - TIE[0] * k, SHOULDER[1] * side - TIE[1] * k, TAG[0] * k, TAG[1] * k


def mark_box(side):
    """The same for the mark's disc at a small shard's foot."""
    d = max(DISC * side, DISC_LEAST)
    return DISC_AT[0] * side - d / 2, DISC_AT[1] * side - d / 2, d, d


def laid(sh, px, x, y, w):
    """A delivered image, `w` points wide with its corner at x, y."""
    rs.paste(sh.px, rs.shrink(px, w * ui.K / px.shape[1]), round(x * ui.K), round(y * ui.K))


def manifest(out, tags, discs):
    data = dict(
        pixelsPerPoint=PIXELS,
        note="The festival tag (AR12). A shard's picture keeps its place and size; the tag is laid over it. Every size "
             "here is in points, and `side` is the side a shard's picture is shown at, as Config.Hud.ShardArt counts "
             "it. DESIGN, untried in Studio.",
        tag=dict(
            when="the large picture is shown (the side is Config.Hud.ShardArt.Large or more)",
            image=dict(points=list(TAG), plaque=PLAQUE, tie=list(TIE)),
            tieAt=[round(v, 4) for v in SHOULDER],
            tieAtNote="where the thread's top is tied, from the picture's middle, in sides: right and up of it",
            plaque=dict(third=dict(upToSide=round(THIRD, 1), ofSide=round(BODY / 3, 4)),
                        quarter=dict(fromSide=round(QUARTER, 1), ofSide=round(BODY / 4, 4)),
                        between="a straight line"),
            plaqueNote="the plaque's height in points is side times `ofSide`; the image is shown plaque / 24 times its "
                       "own points, its `tie` on `tieAt` (research, 2026-11-15: a quarter of the crystal at 96 points "
                       "and a third at 50, so the mark stays about the same height on screen)",
            boxes={str(s): [round(v, 2) for v in tag_box(s)] for s in (50, 60, 72, 96, 134)},
            boxesNote="worked out for five sides: the image's left and top from the picture's middle, its width, its height"),
        mark=dict(
            when="the small picture is shown, down to a chip",
            image=dict(points=[16.0, 16.0]),
            side=round(DISC, 4), least=DISC_LEAST,
            middle=[round(v, 4) for v in DISC_AT],
            note="the image's side is the picture's side times `side`, never under `least` points; its middle lies at "
                 "`middle`, in sides, from the picture's middle: at the crystal's foot, on the right"),
        chip=dict(when="a chip, where the picture is 26 points", band=BAND,
                  note="no image: a band of the ground's colour along the chip's foot, `band` points high, inside the "
                       "chip's own edge"),
        name=dict(lines=["the ground, small", "the grade and \"Shard\", large"],
                  note="everywhere a shard's name is shown: \"Lantern Row\" over \"Prismatic Shard\""),
        grounds={name: dict(colour=f["body"], second=f["second"], tag=f"images/ShardTag{FILE[name]}.png",
                            mark=f"images/ShardTagMark{FILE[name]}.png",
                            pixels=dict(tag=[tags[name].shape[1], tags[name].shape[0]],
                                        mark=[discs[name].shape[1], discs[name].shape[0]]))
                 for name, f in b.FESTIVALS.items()},
        later="the other four grounds' tags are drawn when their grounds are built. Mask Parade's leads with gold and "
              "carries the mask in violet (research, 2026-11-15).")
    (out / "shard_tag.json").write_text(json.dumps(data, indent=1), encoding="utf-8", newline="\n")
    print("wrote", out / "shard_tag.json")


def sheet(out, tags, discs, big, small):
    ui.K = 2
    sh = ui.Sheet(1180, 640, b.GROUND)
    t = sh.tile(0, 0, sh.w, sh.h)
    t.text(20, 12, 15, "Grow your Anime: the festival tag's images for the build (AR12)", b.INK)
    t.text(20, 36, 9.5, "Two grounds, two images each, in colour: the tag with its thread, and its mark on a disc for a small "
           "shard's foot. Places and sizes are in shard_tag.json, counted on the side a shard's picture is shown at.", b.SOFT_INK)

    # The images as delivered, four pixels of theirs to a point of this sheet, on the Breaker's dark and on a pale ground.
    y = 62.0
    for j, ground in enumerate((b.ROOM, "#D9D4E6")):
        tile = sh.tile(20 + j * 574, y, 566, 196)
        tile.paint(tile.poly(ui.cut_box(0, 0, 566, 196)), c(ground))
        ink = b.INK if j == 0 else "#17141F"
        x = 44.0 + j * 574
        for name in b.FESTIVALS:
            laid(sh, tags[name], x, y + 14, TAG[0] * 4)
            t.text(x + TAG[0] * 2, y + 178, 8.5, f"ShardTag{FILE[name]}", ink, "CENTER")
            laid(sh, discs[name], x + 146, y + 46, 64.0)
            t.text(x + 178, y + 178, 8.5, f"ShardTagMark{FILE[name]}", ink, "CENTER")
            x += 276

    # Stacked by the json's numbers at the sides the build shows.
    y = 272.0
    t.text(20, y, 10, "Stacked from the images by the json's own numbers. The number under a shard is its picture's side, as "
           "the build counts it: a chamber's is 72, and 60 at its least.", b.SOFT_INK)
    for j, name in enumerate(b.FESTIVALS):
        ty = y + 18 + j * 172
        tile = sh.tile(20, ty, 1140, 164)
        tile.paint(tile.poly(ui.cut_box(0, 0, 1140, 164)), c(b.ROOM))
        t.text(28, ty + 6, 9, name, b.INK)
        x = 96.0
        for side, grade in ((134, "Prismatic"), (96, "Enriched"), (72, "Prismatic"), (72, "Standard"), (60, "Enriched"),
                            (50, "Standard")):
            cx, cy = x + side / 2, ty + 142 - side * 0.52
            b.put(sh, rs.shrink(big[grade], side * ui.K / 1024.0), cx, cy)
            bx, by, bw, _ = tag_box(side)
            laid(sh, tags[name], cx + bx, cy + by, bw)
            t.text(cx, ty + 146, 8.5, f"{side}", b.SOFT_INK, "CENTER")
            x += side + 26
        x += 20
        for side, grade in ((48, "Prismatic"), (40, "Enriched"), (32, "Standard")):
            cx, cy = x + side / 2, ty + 142 - side * 0.52
            b.put(sh, rs.shrink(small[grade], side * ui.K / 256.0), cx, cy)
            bx, by, bw, _ = mark_box(side)
            laid(sh, discs[name], cx + bx, cy + by, bw)
            t.text(cx, ty + 146, 8.5, f"{side}", b.SOFT_INK, "CENTER")
            x += side + 30
        t.text(x - 96, ty + 30, 8.5, "the small picture: its mark", b.SOFT_INK, "CENTER")
        x += 24
        for grade in b.GRADES:
            b.chip(sh, small[grade], name, x, ty + 100)
            x += 36
        t.text(x - 54, ty + 146, 8.5, "a chip's 26", b.SOFT_INK, "CENTER")
        t.text(x - 54, ty + 30, 8.5, "a band, no image", b.SOFT_INK, "CENTER")
    rb.finish(sh, out / "shard_tag_images.png")


def main():
    out = bl.out_dir()
    (out / "images").mkdir(exist_ok=True)
    tags, discs = {}, {}
    for name in b.FESTIVALS:
        for kind, store, px in (("ShardTag", tags, b.tag(name)[0]), ("ShardTagMark", discs, b.token(name))):
            px = rs.shrink(px, PIXELS / b.DRAWN)
            kit.bleed(px)
            rs.save(px, out / "images" / f"{kind}{FILE[name]}.png")
            store[name] = px
            print(f"{kind}{FILE[name]}: {px.shape[1]} by {px.shape[0]}")
    manifest(out, tags, discs)
    big = {g: rs.load(b.SHARDS / f"shard_{g.lower()}.png") for g in b.GRADES}
    small = {g: rs.load(b.SHARDS / f"shard_{g.lower()}_small.png") for g in b.GRADES}
    sheet(out, tags, discs, big, small)


if __name__ == "__main__":
    main()
