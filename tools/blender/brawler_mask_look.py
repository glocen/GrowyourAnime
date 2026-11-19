"""AR47, the Brawler's mask without its brows, then as the stage tile draws it (research, 18:32): research's look at the
phone's pixels, Normal and Hard, and the content check's at full size and at 64 pixels.

  blender -b --factory-startup --python tools/blender/brawler_mask_look.py -- <abs out>

Lays the layers that hard_ember.py `shade` (Normal) and hard_cut.py `shade` (Hard, AR46's cut) rendered into
<out>/layers, the delivered model on its rig at the game's glow, into Faber's day capture of the street through its own
camera, and writes <out>/brawler_mask_look.png:
  - the near pair and the side Shade, Normal above Hard, at twice the capture's size;
  - the same frames at the smallest phone's pixels: Faber's captures there are 950 by 450 on the device, and Roblox's
    view is 70 degrees tall on every screen, so the capture is shrunk to 450 high. The pair is cut from it at its own
    size, then at four times, nearest, to read;
  - the Brawler alone over dark, Normal and Hard, at full size and at 64 pixels high.
Run hard_ember.py `shade` and hard_cut.py `shade` into the same <out> first.
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import hard_cut as hc  # noqa: E402
import hard_ember as he  # noqa: E402
import rook_sheet as rs  # noqa: E402

PHONE_H = 450   # the smallest phone's capture, in the device's pixels (Faber's, button_make.py)
LOOKS = (("Normal, as the game draws it today", "shade_Normal_", "Normal"),
         ("Hard, AR46's cut: the body's tint white, the cuts coral, the paper's glow off", "cut_shade_", "B"))


def box(spots, half_w, top, pad):
    """The capture's pixels around foes standing at `spots`, `half_w` studs each side and `top` tall."""
    xs, ys = [], []
    for x, z in spots:
        for dx in (-half_w, half_w):
            for y in (0.0, top):
                px, py, _ = he.project((x + dx, y, z))
                xs.append(px)
                ys.append(py)
    x0, y0 = int(min(xs)) - pad, int(min(ys)) - pad
    return x0, y0, int(max(xs)) + pad - x0, int(max(ys)) + pad - y0


def zoomed(img, k):
    return np.repeat(np.repeat(img, k, 0), k, 1)


def main():
    out = bl.out_dir()
    rs.OUT = out
    layers_dir = out / "layers"
    still = rs.load(he.STILL)
    backdrop = still.copy()
    backdrop[..., :3] = he.to_linear(still[..., :3])
    gx, gz = he.ground_points()
    places = [(x, z, 1.0) for _, x, z, _, _ in he.PACK]

    def layer(name):
        return np.load(layers_dir / f"{name}.npy").astype(np.float32)

    frames, alone = {}, {}
    for _, prefix, look in LOOKS:
        shades = [(he.project((x, 0, z))[2], layer(f"{prefix}{name}")) for name, x, z, _, _ in he.PACK]
        frames[prefix] = he.lay(backdrop, shades, places, look, gx, gz)
        alone[prefix] = layer(f"{prefix}near")

    near = box([(he.PACK[0][1], he.PACK[0][2]), (he.PACK[1][1], he.PACK[1][2])], 1.6, 5.3, 26)
    side = box([(he.PACK[2][1], he.PACK[2][2])], 1.6, 5.3, 26)
    one = box([(he.PACK[0][1], he.PACK[0][2])], 1.4, 5.3, 8)
    s = PHONE_H / backdrop.shape[0]
    phone = {prefix: rs.shrink(frame, s) for prefix, frame in frames.items()}
    pbox = tuple(int(round(v * s)) for v in near)
    sbox = tuple(int(round(v * s)) for v in side)

    zoom, k, gap, label = 2, 4, 24, 30
    big_w = near[2] * zoom + gap + side[2] * zoom
    phone_w = pbox[2] + gap + pbox[2] * k + gap + sbox[2] * k
    width = gap + max(big_w, phone_w, 900) + gap
    row_big = max(near[3], side[3]) * zoom
    row_phone = max(pbox[3], sbox[3]) * k
    dark_h = one[3]
    height = 120 + 2 * (label + row_big + gap) + 2 * (label + row_phone + gap) + label + dark_h + 40 + gap + 70
    page = rs.canvas(width, height, rs.rgb("#101117"))
    ink, soft, pale = "#EDE6D6", "#B4AC9C", "#8C8577"
    text = [(gap, 22, 34, "AR47: THE BRAWLER'S MASK AS THE TILE DRAWS IT", ink)]
    text += hc.wrapped(gap, 66, 16, "The delivered Shade, re-baked, in Faber's day capture of the street through its own "
                                   "camera: the near pair and the side Shade. No ink on the paper: two level almond holes, "
                                   "one wider than the other, and the narrower lopsided grin behind its four teeth.", soft,
                       width - 2 * gap)
    y = 120
    for caption, prefix, _ in LOOKS:
        text.append((gap, y, 18, caption + ", twice the capture's size", ink))
        y += label
        x = gap
        for b in (near, side):
            rs.paste(page, zoomed(he.crop(frames[prefix], *b), zoom), x, y)
            x += b[2] * zoom + gap
        y += row_big + gap
    for caption, prefix, _ in LOOKS:
        text.append((gap, y, 18, caption.split(",")[0] + f" at the smallest phone ({PHONE_H} pixels high): the pair at its "
                                 f"own size, then it and the side Shade at {k} times, nearest", ink))
        y += label
        x = gap
        small = he.crop(phone[prefix], *pbox)
        rs.paste(page, small, x, y)
        x += pbox[2] + gap
        for b in (pbox, sbox):
            rs.paste(page, zoomed(he.crop(phone[prefix], *b), k), x, y)
            x += b[2] * k + gap
        y += row_phone + gap
    text.append((gap, y, 18, "Over dark: Normal and Hard at full size, then each at 64 pixels high", ink))
    y += label
    x = gap
    for caption, prefix, _ in LOOKS:
        full = hc.on_dark(alone[prefix], one, 0)
        rs.paste(page, full, x, y)
        text.append((x, y + full.shape[0] + 6, 12, caption.split(",")[0], pale))
        x += full.shape[1] + gap
    for caption, prefix, _ in LOOKS:
        mini = hc.on_dark(alone[prefix], one, 64)
        rs.paste(page, mini, x, y)
        text.append((x, y + 70, 12, caption.split(",")[0], pale))
        x += mini.shape[1] + gap
    # the mask spans 3.8 to 5.9 studs up (Shade.recipe.json: its centre 4.86, 2.11 tall)
    head = he.project((he.PACK[0][1], 5.9, he.PACK[0][2]))[1] - he.project((he.PACK[0][1], 3.8, he.PACK[0][2]))[1]
    note = (f"At the smallest phone the near Brawler's mask is about {abs(head) * s:.0f} pixels tall "
            f"({abs(head):.0f} in the capture), the side one smaller. Roblox draws the world at the device's pixels; a "
            "phone on a low graphics level draws fewer.")
    text += hc.wrapped(gap, height - 60, 15, note, pale, width - 2 * gap)
    rs.paste(page, rs.text_layer(width, height, text), 0, 0)
    rs.save(page, out / "brawler_mask_look.png")
    print(f"wrote {out / 'brawler_mask_look.png'} ({width} by {height}); {note}")


if __name__ == "__main__":
    main()
