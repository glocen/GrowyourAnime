"""AR42: the stages' tile pictures cut for Faber (research's second look, 16:55: competent, and it passes for Faber's
install). The screens' glass, presses, roads and ring are Seam's kit (build/handoff/UI/seam); the chevrons are
SeamChevron, the lock the Voidkin screen's Lock, the check UIKit's Tick on a lit disc. What's new is the four pictures,
lit and shut, in full colour, as stage_seam.py draws them: the Shade, the elite, Stage 3's bigger elite and the
Lamplighter's lantern, the Shade on its light (research's must-fix 1, 16:34). One picture serves Normal and Hard: the
mode is in the bloom behind it.

    blender -b --factory-startup --python tools/blender/stage_cut.py -- <abs out>

Writes build/handoff/UI/stages: images/ (4 pixels a point), stages.json, and stages_cut.png: each picture on its bed
as the game lays it, on Normal and on Hard, shut, at the phone's own pixels and at 64 pixels high. Each image is
checked against stage_seam.py's drawing on the same bed; the fit is printed and kept in stages.json.
"""

import json
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402,F401
import foe_cards as fc  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
import upgrade_pages as up  # noqa: E402
import seam_kit as sk  # noqa: E402
import stage_screen as ss  # noqa: E402
import stage_seam as sq  # noqa: E402  (on import: the pictures' Seam colours, the Shade on its light)

K = 4
HANDOFF = up.REPO / "build" / "handoff" / "UI" / "stages"
H = float(sq.PIC)                    # a picture is the bed's full height: 86 points
W = 100.0                            # and 100 across, centred in the bed (122.75 at the smallest phone)
BED_W = 122.0
KINDS = [("StageShade", "shade", "Stage 1: a Shade"), ("StageElite", "elite", "Stage 2: an elite"),
         ("StageEliteBig", "big", "Stage 3: a bigger elite"), ("StageLantern", "lantern", "the Lamplighter")]
MADE = {}


def picture(kind, shut):
    """One picture on a clear tile, placed as stage_seam.window places it: its middle 2 under the bed's, s 0.42 of H."""
    t = fc.clear(W, H)
    ss.picture(t, kind, W / 2, H / 2 + 2, H * 0.42, dim=shut)
    return t.px.copy()


def bed(sheet, x, y, state, hard):
    """A tile's bed at the smallest phone, as stage_seam.window draws it: the dark socket, the bloom unless shut."""
    t = sheet.tile(x, y, BED_W, H)
    d = t.poly(ui.cut_box(0, 0, BED_W, H, 4, 4, 4, 4))
    t.paint(d, up.shade(t, sk.SOCKET_DARK, 0, H))
    if state != "shut":
        strength = sq.PIC_BLOOM[(state, hard)]
        t.paint(d, sq.ACC[hard]["bloom"], strength * np.exp(-(((t.x - BED_W / 2) / (BED_W * 0.38)) ** 2 +
                                                              ((t.y - H / 2 - 8) / (H * 0.42)) ** 2)))
    t.line(d, 1.0, sq.P["edge"], 0.8)
    return t


def fit(kind, name, shut):
    """The image laid on its bed beside the drawing on the same bed: the mean and 99th centile of their difference."""
    pair = ui.Sheet(2 * BED_W, H, "#000000")
    state = "shut" if shut else "next"
    drawn = bed(pair, 0, 0, state, False)
    bed(pair, BED_W, 0, state, False)
    ss.picture(drawn, kind, BED_W / 2, H / 2 + 2, H * 0.42, dim=shut)
    rs.paste(pair.px, MADE[name], round((BED_W + (BED_W - W) / 2) * K), 0)
    w = round(BED_W * K)
    diff = np.abs(pair.px[:, :w, :3] - pair.px[:, w:2 * w, :3])
    return float(diff.mean()), float(np.percentile(diff, 99))


def sheet_of(path):
    """Each picture on its bed: Normal's next and open, Hard's next, shut; then at the phone's 2 pixels a point and at
    64 pixels high, next and shut."""
    ui.K = K
    gap, head, label, under = 12.0, 34.0, 22.0, 20.0
    cols = [("Normal, next", "next", False), ("Normal, open", "open", False), ("Hard, next", "next", True),
            ("shut", "shut", False)]
    width = gap + len(cols) * (BED_W + gap) + 2 * (BED_W / 2 + gap) + 2 * (32 + gap)
    height = head + len(KINDS) * (H + label + under) + gap
    sheet = ui.Sheet(width, height, "#101117")
    t = sheet.tile(0, 0, width, height)
    t.text(gap, 10, 16, "AR42, the tile pictures on their beds; then at a phone's pixels and at 64 high", "#EDE6D6",
           bold=0.2)
    for r, (name, kind, said) in enumerate(KINDS):
        y = head + r * (H + label + under)
        t.text(gap, y, 14, f"{name}, {said}", "#B4AC9C")
        y += label
        x = gap
        cells = {}
        for words, state, hard in cols:
            bed(sheet, x, y, state, hard)
            img = MADE[name + ("Shut" if state == "shut" else "")]
            rs.paste(sheet.px, img, round((x + (BED_W - W) / 2) * K), round(y * K))
            cells[state, hard] = sheet.px[round(y * K):round((y + H) * K), round(x * K):round((x + BED_W) * K)].copy()
            t.text(x + BED_W / 2, y + H + 2, 12, words, "#8C8577", "CENTER")
            x += BED_W + gap
        for state in ("next", "shut"):                       # the phone's own pixels, two a point
            small = rs.shrink(cells[state, False], 0.5)
            rs.paste(sheet.px, small, round(x * K), round((y + H / 4) * K))
            x += BED_W / 2 + gap
        for state in ("next", "shut"):                       # 64 pixels high, a quarter of that in this sheet's points
            small = rs.shrink(cells[state, False], 64 / (H * K))
            rs.paste(sheet.px, small, round(x * K), round((y + H / 2 - 8) * K))
            x += 32 + gap
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, path)


def stages_json(fits):
    acc = {("hard" if hard else "normal"): dict(edge=a["edge"], lit=list(a["lit"]), road=list(a["road"]),
                                                  bloom=a["bloom"], glow=a["glow"]) for hard, a in sq.ACC.items()}
    return dict(
        what="AR42, the stages' tile pictures (research's second look, 2026-11-19, 16:55: passed for Faber's install). "
             "The rest of the picker, the results card and the run's line are Seam's kit (../seam/seam.json) laid as "
             "tools/blender/stage_seam.py draws them. From tools/blender/stage_cut.py; drawn in code, no image input",
        pixelsPerPoint=K,
        images={name + suffix: dict(file=f"images/{name}{suffix}.png", pixels=[round(W * K), round(H * K)],
                                    points=[W, H], stage=said, state="shut" if suffix else "open",
                                    fit=dict(mean=round(fits[name + suffix][0], 5), p99=round(fits[name + suffix][1], 5)))
                for name, _, said in KINDS for suffix in ("", "Shut")},
        lay=dict(
            picture="an ImageLabel the bed's full height (86 points at the smallest phone), 100 by 86, centred across "
                    "the bed, over the bed and its bloom; the bed clips it. The open picture on every open tile, the "
                    "shut one on a shut tile, on Normal and on Hard alike",
            bed=dict(fill=list(sk.SOCKET_DARK), edge=sq.P["edge"], edgeTransparency=0.2, corner=4,
                     note="a Frame inset 6 points in the tile; UIGradient Rotation 90, fill top to foot"),
            bloom=dict(image="ScreenBloom (../seam)", middle=[0.5, round((H / 2 + 8) / H, 3)],
                       laid=[round(5 * BED_W * 0.38, 1), round(5 * H * 0.42, 1)],
                       strength={"next, normal": sq.PIC_BLOOM[("next", False)],
                                 "next, hard": sq.PIC_BLOOM[("next", True)],
                                 "open, normal": sq.PIC_BLOOM[("open", False)],
                                 "open, hard": sq.PIC_BLOOM[("open", True)]},
                       note="behind the picture, under it in the bed: the mode's bloom colour at ImageTransparency "
                            "1 - strength; none on a shut tile. Its middle as a fraction of the bed, its size in "
                            "points (ScreenBloom drawn out to 2.5 radii each way)"),
            lock="the Voidkin screen's Lock (Config.Hud), the soft colour, 26 points, its middle across the bed's and "
                 "53 points under its top, on a shut tile",
            check="on a cleared tile: a lit disc of 10 points' radius, its middle 15 in from the bed's top right (the "
                  "mode's lit pair down it), UIKit's Tick in ink across it, 11 by 9",
            chevrons="SeamChevron, the ember edge, on Hard's badge and the switch"),
        palette=dict(accent=acc, ready=sq.READY, ground=list(sq.GROUND), tile=list(sq.TILE), shut=list(sq.SHUT),
                     note="Hard keeps Normal's value (research's must-fix 2): ground, tile and shut are one for both"))


def main():
    sk.wear("B")
    ui.K = K
    out = HANDOFF / "images"
    out.mkdir(parents=True, exist_ok=True)
    for name, kind, _ in KINDS:
        for suffix, shut in (("", False), ("Shut", True)):
            px = picture(kind, shut)
            edge = max(px[:, 0, 3].max(), px[:, -1, 3].max(), px[0, :, 3].max())
            if edge > 0.02:
                print(f"warning: {name}{suffix} reaches its canvas's side or top ({edge:.3f})")
            MADE[name + suffix] = px
            rs.save(px.astype(np.float32), out / f"{name}{suffix}.png")
    fits = {}
    for name, kind, _ in KINDS:
        for suffix, shut in (("", False), ("Shut", True)):
            fits[name + suffix] = fit(kind, name + suffix, shut)
            print(f"fit {name}{suffix}: mean {fits[name + suffix][0]:.4f}, 99th {fits[name + suffix][1]:.4f}")
    sheet_of(HANDOFF / "stages_cut.png")
    (HANDOFF / "stages.json").write_text(json.dumps(stages_json(fits), indent=2), encoding="utf-8", newline="\n")
    print(f"cut: {len(MADE)} images and stages.json into {HANDOFF}")


if __name__ == "__main__":
    main()
