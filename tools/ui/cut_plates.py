"""Draws the Voidkin screen's two cut plates as white-on-alpha slices for the game to tint (AR29, B; Modulo's numbers in
docs/asset-requests.md, "B's numbers for Faber"): the chosen page's tab of glass, its top left cut 8.5 points and its
foot left 3.4, and the bar's channel, its top left and foot right cut 6.8. The kit's own panel is cut at all four
corners (tools/blender/ui_kit.py, `panel`), so neither shape is in it. And the base's machine plate (AR65's must-fix 2,
on AR62's tokens, Theme.Frame): the shard cut at its top left and foot right, Cut.Share of the card's radius (7.2), its
rim Stroke.Rim (1.2) wide. Each plate is drawn at the kit's 4 pixels a
point and laid as a nine-slice (UI.Kit.Skin), so its cuts and edge keep their size at any length:
  <Name>Fill  the plate, solid
  <Name>Edge  its outline, its width inside its edge (0.85 points; the machine plate's 1.2)
  <Name>Glow  its glow, falling off over 5 points outside it (the tab only), Pad 5

Pure Python (zlib), no other package: each pixel is the share of 4 x 4 samples inside, so the cuts are anti-aliased.

    py tools/ui/cut_plates.py build/scratch/faber/ar29/plates
    py tools/ui/cut_plates.py build/upload MachinePlate      only one plate's images
"""

import os
import struct
import sys
import zlib

PPP = 4  # pixels a point, the kit's (Config.UIKit.PixelsPerPoint)
SS = 4  # samples a side in each pixel
EDGE = 0.85  # the outline's width, points
GLOW = 5.0  # the glow's reach, points

# name: (width and height in points, cuts clockwise from the top left (tl, tr, br, bl), slice insets left, top,
# right, bottom in points, whether it has a glow, its outline's width in points)
PLATES = {
    "VoidkinTab": (16.0, (8.5, 0.0, 0.0, 3.4), (9, 9, 2, 4), True, EDGE),
    "VoidkinChannel": (16.0, (6.8, 0.0, 6.8, 0.0), (8, 8, 8, 8), False, EDGE),
    "MachinePlate": (20.0, (7.2, 0.0, 7.2, 0.0), (9, 9, 9, 9), False, 1.2),
}


def cut_box(x0, y0, x1, y1, tl, tr, br, bl):
    """A box with its corners cut, clockwise from the top left (as tools/blender/ui_sheet.py draws it)."""
    pts = [(x0, y0 + tl), (x0 + tl, y0)] if tl else [(x0, y0)]
    pts += [(x1 - tr, y0), (x1, y0 + tr)] if tr else [(x1, y0)]
    pts += [(x1, y1 - br), (x1 - br, y1)] if br else [(x1, y1)]
    pts += [(x0 + bl, y1), (x0, y1 - bl)] if bl else [(x0, y1)]
    return pts


def distance(pts):
    """The signed distance to a convex polygon, clockwise on screen (y down): the largest of its edges' half-planes,
    negative inside. Outside a corner it measures to the corner's mitre, so a glow keeps the cut's shape."""
    lines = []
    for i, (ax, ay) in enumerate(pts):
        bx, by = pts[(i + 1) % len(pts)]
        dx, dy = bx - ax, by - ay
        n = (dx * dx + dy * dy) ** 0.5
        # Clockwise on screen with y down, the outward normal is (dy, -dx).
        lines.append((dy / n, -dx / n, ax, ay))

    def sd(x, y):
        return max(nx * (x - ax) + ny * (y - ay) for nx, ny, ax, ay in lines)

    return sd


def draw(size_pt, pad_pt, cuts, alpha):
    """An image of a plate `size_pt` points square with `pad_pt` around it: `alpha(sd)` for each sample's signed
    distance in points, averaged over the pixel's samples."""
    side = round((size_pt + 2 * pad_pt) * PPP)
    sd = distance(cut_box(pad_pt, pad_pt, pad_pt + size_pt, pad_pt + size_pt, *cuts))
    rows = []
    for py in range(side):
        row = bytearray()
        for px in range(side):
            total = 0.0
            for sy in range(SS):
                for sx in range(SS):
                    x = (px + (sx + 0.5) / SS) / PPP
                    y = (py + (sy + 0.5) / SS) / PPP
                    total += alpha(sd(x, y))
            a = round(255 * total / (SS * SS))
            row += bytes((255, 255, 255, a))
        rows.append(bytes(row))
    return side, rows


def png(path, side, rows):
    raw = b"".join(b"\x00" + r for r in rows)
    chunk = lambda kind, data: struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", side, side, 8, 6, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(raw, 9)))
        f.write(chunk(b"IEND", b""))


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "build/scratch/faber/ar29/plates"
    only = sys.argv[2] if len(sys.argv) > 2 else None  # one plate's name: only its images
    os.makedirs(out, exist_ok=True)
    for name, (size, cuts, insets, glow, edge) in PLATES.items():
        if only and name != only:
            continue
        made = {
            "Fill": (0.0, lambda d: 1.0 if d <= 0 else 0.0),
            "Edge": (0.0, lambda d, edge=edge: 1.0 if -edge <= d <= 0 else 0.0),
        }
        if glow:
            made["Glow"] = (GLOW, lambda d: 1.0 if d <= 0 else max(0.0, 1 - d / GLOW) ** 2)
        for layer, (pad, alpha) in made.items():
            side, rows = draw(size, pad, cuts, alpha)
            png(os.path.join(out, f"{name}{layer}.png"), side, rows)
            l, t, r, b = insets
            cut = (l + pad, t + pad, r + pad, b + pad)
            print(f"{name}{layer}: {side} px, {side / PPP:g} points, Cut = {{ {', '.join(f'{v:g}' for v in cut)} }}, Pad = {pad:g}")


if __name__ == "__main__":
    main()
