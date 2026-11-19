"""AR43, the board's item 11: the Voidkin screen and the bag in B, like Equipment's, yes or no (research, 2026-11-19,
18:43). A throwaway blockout: Faber's captures of today's screens, each beside the same pixels with B painted over them.
Nothing here is cut or exported; on a yes, Faber builds B from the kit (build/handoff/UI/seam/, Config.UIKit's
SeamGlass), as Equipment's.

B, as seam_kit.py draws it, painted onto a capture:
  - Seam's grounds lifted to SeamGlass's: every violet-black of the panels, wells, edges and buttons by a gain that is
    about 1.8 on the darks, 1.4 on an edge and nothing on the light (Seam's #1A1430 to SeamGlass's #2F2758, and so on);
    the screen's backing lit at its top;
  - each main panel's top sheen, its outline lit from above, and its corner glint;
  - the bloom behind the work, round the doll (the stage keeps its ground: SeamGlass's Ground is Seam's);
  - the chosen chip as the lit press, white falling to lavender, its words in ink.
What isn't Seam's (Rook, the gear, the rarity frames, the numbers' light) keeps its pixels: the lift reads a violet-dark
pixel only. Places are in each capture's own pixels, read off it (SPECS).

    blender -b --factory-startup --python tools/blender/screen_b_look.py -- <abs out>
Reads build/scratch/faber/ar43/stills/{voidkin,bag}-{pc,phone}.*; writes <out>/voidkin_b.png and <out>/bag_b.png.
"""
import os
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import hard_cut as hc  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402

STILLS = Path(os.environ.get("B_STILLS") or Path(__file__).resolve().parents[2] / "build" / "scratch" / "faber" / "ar43"
              / "stills")
GLASS = dict(backing=("#1F1942", "#0D0B1A"), facet="#A89CD8", glint="#F0EAFF", bloom=("#5C48AC", 0.30),
             lit=("#FFFFFF", "#D4C6FF"), ink="#0B0913", sheen=0.11)

# Per capture (Faber's, 18:53, 1.5 pixels a Roblox point): k, the pixels of one of the kit's points (the game lays its
# screens 375 of them tall, so k is the capture's height over 375); panels (x0, y0, x1, y1, top-left cut, foot-right
# cut); presses (the chosen chip's box); bloom ((x, y), (rx, ry)); keep, boxes the lift leaves alone: the stage, whose
# Ground SeamGlass keeps as Seam's (#1E1A2C), and the Voidkin's portraits. All in the capture's own pixels.
SPECS = {
    "voidkin-pc": dict(k=1134 / 375, panels=[(20, 105, 1505, 983, 0, 0), (1517, 105, 2462, 221, 0, 20),
                                             (1517, 236, 2462, 1114, 22, 20)],
                       bloom=((770, 521), (560, 470)), keep=[(24, 109, 1501, 979), (20, 997, 919, 1114)]),
    "voidkin-phone": dict(k=480 / 375, panels=[(12, 97, 450, 395, 0, 0), (458, 98, 840, 163, 0, 9),
                                               (458, 172, 840, 470, 9, 9)],
                          bloom=((230, 230), (190, 160)), keep=[(15, 100, 447, 392), (10, 402, 450, 468)]),
    "bag-pc": dict(k=1134 / 375, panels=[(20, 89, 2471, 1132, 0, 0), (720, 99, 2133, 209, 0, 0),
                                         (2152, 99, 2452, 209, 0, 0)],
                   presses=[(723, 102, 828, 207)], bloom=((360, 559), (320, 470)), keep=[(174, 236, 546, 912)]),
    "bag-phone": dict(k=480 / 375, panels=[(12, 87, 842, 478, 0, 0), (342, 92, 650, 157, 0, 0),
                                           (659, 92, 836, 157, 0, 0)],
                      presses=[(345, 95, 407, 155)], bloom=((170, 260), (150, 190)), keep=[(85, 145, 262, 405)]),
}


def c(code):
    return np.array(rs.rgb(code), dtype=np.float32)


def over(img, colour, a):
    a = np.clip(a, 0, 1)[..., None]
    img[..., :3] = img[..., :3] * (1 - a) + np.asarray(colour, dtype=np.float32) * a


def grid(img):
    gy, gx = np.mgrid[0:img.shape[0], 0:img.shape[1]]
    return gx.astype(np.float32) + 0.5, gy.astype(np.float32) + 0.5


def luma(rgb):
    return rgb @ np.array((0.2126, 0.7152, 0.0722), dtype=np.float32)


def seam_mask(rgb):
    """How much a pixel is Seam's own violet-dark: bluer than green and red, and not light."""
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    bg = np.clip((b / np.maximum(g, 1e-3) - 1.25) / 0.2, 0, 1)   # Seam's are 1.7 to 2.4; a steel grey's 1.1
    br = np.clip((b / np.maximum(r, 1e-3) - 1.0) / 0.1, 0, 1)
    return bg * br * np.clip((0.24 - luma(rgb)) / 0.08, 0, 1)   # Seam is dark; a rarity frame's grey is not Seam's


def lift(img, keep):
    """Seam's grounds to SeamGlass's: a gain on the violet-darks, ~1.8 at a panel's, ~1.4 at an edge's, 1 on the light."""
    rgb = img[..., :3]
    m = seam_mask(rgb)
    x, y = grid(img)
    for x0, y0, x1, y1 in keep:
        m = np.where((x >= x0) & (x < x1) & (y >= y0) & (y < y1), 0.0, m)
    gain = 1 + np.clip(1 - luma(rgb) / 0.45, 0, 1) ** 1.2
    lifted = np.clip(rgb * gain[..., None] * np.array((1.0, 0.98, 1.08), dtype=np.float32), 0, 1)
    img[..., :3] = rgb + (lifted - rgb) * m[..., None]
    return m


def backing_top(img, m, k):
    """B's backing: lit at its top (#1F1942 falling to #0D0B1A), and a faint light along the screen's top edge."""
    x, y = grid(img)
    t = y / img.shape[0]
    back = m * np.clip((0.07 - luma(img[..., :3])) / 0.03, 0, 1)   # the darkest violet: the screen's own backing
    ramp = c(GLASS["backing"][0]) + (c(GLASS["backing"][1]) - c(GLASS["backing"][0])) * np.clip(t, 0, 1)[..., None]
    img[..., :3] = img[..., :3] + (ramp - img[..., :3]) * (back * 0.85)[..., None]
    over(img, c(GLASS["glint"]), 0.06 * np.exp(-y / (40 * k)) * m)


def panel(img, m, k, x0, y0, x1, y1, tl, br):
    """A main panel in B: the sheen at its top, its outline lit from above, the glint at its top-left corner."""
    x, y = grid(img)
    d = ui.sd_polygon(x, y, ui.cut_box(x0, y0, x1, y1, tl, 0, br, 0))
    inside = np.clip(0.5 - d, 0, 1)
    over(img, c(GLASS["glint"]), GLASS["sheen"] * np.exp(-np.maximum(y - y0, 0) / (24 * k)) * inside * (0.4 + 0.6 * m))
    down = np.clip(1 - (y - y0) / ((y1 - y0) * 0.85), 0, 1)
    edge = np.clip(0.5 - (np.abs(d + k / 2) - k / 2), 0, 1)
    over(img, c(GLASS["facet"]), edge * (0.3 + 0.6 * down))
    edge = np.clip(0.5 - (np.abs(d + 0.65 * k) - 0.65 * k), 0, 1)
    over(img, c(GLASS["glint"]), edge * 0.85 * np.exp(-np.hypot(x - x0 - 24 * k, y - y0) / (46 * k)))


def bloom(img, m, at, radii):
    x, y = grid(img)
    (bx, by), (rx, ry) = at, radii
    colour, strength = GLASS["bloom"]
    over(img, c(colour), strength * np.exp(-(((x - bx) / rx) ** 2 + ((y - by) / ry) ** 2)) * m)


def press(img, k, x0, y0, x1, y1):
    """The chosen chip as the lit press: white falling to lavender, its glow, its words turned to ink."""
    x, y = grid(img)
    d = ui.sd_polygon(x, y, ui.cut_box(x0, y0, x1, y1, 5 * k, 5 * k, 5 * k, 5 * k))
    box = img[int(y0):int(y1), int(x0):int(x1), :3]
    lum = luma(img[..., :3])
    ground, words = np.percentile(luma(box), 30), np.percentile(luma(box), 99)
    ink = np.clip((lum - ground) / max(words - ground, 1e-3), 0, 1)
    over(img, c(GLASS["lit"][1]), 0.45 * np.exp(-(np.maximum(d, 0) / (7 * k)) ** 1.4) * (d > 0))
    t = np.clip((y - y0) / (y1 - y0), 0, 1)[..., None]
    fill = c(GLASS["lit"][0]) + (c(GLASS["lit"][1]) - c(GLASS["lit"][0])) * t
    inside = np.clip(0.5 - d, 0, 1)
    face = fill + (c(GLASS["ink"]) - fill) * ink[..., None]
    img[..., :3] = img[..., :3] + (face - img[..., :3]) * inside[..., None]
    edge = np.clip(0.5 - (np.abs(d + k / 2) - k / 2), 0, 1)
    over(img, c("#FFFFFF"), edge * 0.9)


def in_b(still, spec):
    img = still.copy()
    k = spec["k"]
    m = lift(img, spec.get("keep", ()))
    backing_top(img, m, k)
    if "bloom" in spec:
        bloom(img, m, *spec["bloom"])
    for p in spec.get("panels", ()):
        panel(img, m, k, *p)
    for p in spec.get("presses", ()):
        press(img, k, *p)
    return img


def find(name):
    for ext in (".png", ".jpg"):
        if (STILLS / (name + ext)).exists():
            return STILLS / (name + ext)
    return None


def sheet(out, screen, title, words):
    paths = [find(f"{screen}-{size}") for size in ("pc", "phone")]
    if None in paths:
        print(f"skipped {screen}: its stills aren't all in {STILLS}")
        return
    pc, phone = (rs.load(p) for p in paths)
    pc_b, phone_b = in_b(pc, SPECS[f"{screen}-pc"]), in_b(phone, SPECS[f"{screen}-phone"])
    gap, label = 24, 30
    half = 0.5 if pc.shape[1] > 1200 else 1.0
    pc_s, pc_bs = (rs.shrink(p, half) if half != 1 else p for p in (pc, pc_b))
    width = gap + max(2 * pc_s.shape[1], 2 * phone.shape[1]) + 2 * gap
    height = 130 + label + pc_s.shape[0] + gap + label + phone.shape[0] + gap + 50
    page = rs.canvas(width, height, rs.rgb("#101117"))
    ink, soft = "#EDE6D6", "#B4AC9C"
    text = [(gap, 22, 34, title, ink)]
    text += hc.wrapped(gap, 66, 16, words, soft, width - 2 * gap)
    y = 130
    sizes = f"{pc.shape[1]} by {pc.shape[0]}" + (", shown at half" if half != 1 else "")
    text.append((gap, y, 18, f"PC ({sizes}): today's Seam, then B", ink))
    y += label
    rs.paste(page, pc_s, gap, y)
    rs.paste(page, pc_bs, 2 * gap + pc_s.shape[1], y)
    y += pc_s.shape[0] + gap
    text.append((gap, y, 18, f"The smallest phone ({phone.shape[1]} by {phone.shape[0]}, its own pixels): today's, "
                             "then B", ink))
    y += label
    rs.paste(page, phone, gap, y)
    rs.paste(page, phone_b, 2 * gap + phone.shape[1], y)
    text.append((gap, height - 40, 14, "A paintover of Faber's captures, thrown away on a no. On a yes, B is built "
                                       "from the kit (build/handoff/UI/seam/) as Equipment's is.", soft))
    rs.paste(page, rs.text_layer(width, height, text), 0, 0)
    rs.save(page, out / f"{screen}_b.png")


def main():
    out = bl.out_dir()
    rs.OUT = out
    sheet(out, "voidkin", "AR43: THE VOIDKIN SCREEN IN B?",
          "Rook's Overview as the game draws it today, in flat Seam, and the same screen in B, Equipment's lit glass: "
          "the band's and the card's violet lifted at every top, the edges lit from above. The stage keeps its ground, "
          "as SeamGlass keeps Seam's.")
    sheet(out, "bag", "AR43: THE BAG IN B?",
          "Inventory as the game draws it today, in flat Seam, and the same screen in B: the grounds and the wells "
          "lifted, the panels' edges lit from above, a bloom round the doll, the chosen kind a plate of light. The "
          "rarity frames, the gear and the stage keep their own colours.")


if __name__ == "__main__":
    main()
