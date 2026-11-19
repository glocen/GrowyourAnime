"""AR43, the director's word of 14:56: "i do not look like this green ui makeover i liked the old one before but maybe we
can use a bit more gradiant and animation and make it much better". The screens Home opens go back from AR40's C to
Seam, the screen's own palette (Config.UIKit's Palettes.Seam, the Voidkin screen's and the bag's). "Maybe" makes the
gradients and motion a blockout direction (research, 14:56), with research's measure: the gradients lift Seam (lighter
tops, lit edges, never a deeper fall to black), and one direction is clearly brighter than today's.

The blockout, on Reinforce's ready state at the smallest phone, drawn in code over equipment_pages' frame:
    A  Seam today, flat as the game's Voidkin screen.
    B  Lit glass: Seam's violet lifted at every top, hairlines lit from above, a bloom where the gear sits in its
       rarity's colour, the press a white-to-lavender gradient.
    C  Bright dusk: B's light on mid-violets, clearly brighter than today, a slow drift from magenta at the left to
       blue at the right, never teal.
Under them, the idle motion in four beats of its 2.4 s loop (B and C share it): a comet circling the ring, a sheen
crossing the lit press, a glint running down the chosen row's glass.

The director's word of 14:59, with a screenshot of another game's Equipment screen (kept out of the repo, for the
function only): "it would be cool for the left ui button to return to equipement be like this". Equipment's three
screens get a rail down the left again: Reinforce, Jewels and War Emblems as round buttons on one line, the chosen one
larger and lit with its word, switching between them. Back stays at the top left, to Home, and the band's title reads
Equipment. Drawn in every direction, in its palette; the marks are the shipped page icons.

    blender -b --factory-startup --python tools/blender/seam_rich.py -- <abs out>

Writes seam_rich.png. A blockout: nothing here is cut. The directions' drawing is seam_kit.py's, where B, research's
verdict (15:04), became the kit every screen Home opens wears.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
import upgrade_pages as up  # noqa: E402
import equipment_pages as ep  # noqa: E402
import seam_kit as sk  # noqa: E402

W, H, SMALL = up.W, up.H, up.SMALL
STYLES, LOOP = sk.STYLES, sk.LOOP


def render(key, phase=0.0):
    """One phone at the sheet's pixels, its words drawn in."""
    sk.wear(key, phase)
    sheet = ui.Sheet(W, H, "#000000")
    ep.phone(sheet, 0, 0, dict(ep.REINFORCE_STATES[0][1]))
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    return sheet.px


def main():
    out = bl.out_dir()
    ui.K = K = 2
    gap, head = 24, 64
    crop = (0, 56, 568, 316)                         # the rail, the chosen row and the work, for the idle beats
    cw, ch = crop[2] - crop[0], crop[3] - crop[1]
    width = gap + 3 * (W + gap)
    across = 3                                       # the idle's beats, three a row
    strips_y = head + H + 56
    height = strips_y + 2 * (ch + 48) + 150
    sheet = ui.Sheet(width, height, "#101117")
    t = sheet.tile(0, 0, width, height)
    t.text(gap, 18, 20, "AR43, Equipment back in Seam, richer, with its rail down the left: three directions at the "
                        "smallest phone (568 x 320), on the director's words of 14:56 and 14:59", "#EDE6D6", bold=0.2)
    for n, key in enumerate("ABC"):
        x = gap + n * (W + gap)
        t.text(x, head - 4, SMALL, STYLES[key]["words"], "#B4AC9C")
        rs.paste(sheet.px, render(key), round(x * K), round((head + 16) * K))
    for row, key in enumerate("BC"):
        for k, phase in enumerate((0.1, 0.43, 0.76)):
            y = strips_y + row * (ch + 48)
            if k == 0:
                t.text(gap, y - 4, SMALL, f"{key}'s idle, a {LOOP:g} s loop: the comet circles the ring and the chosen "
                                          "button, the sheen crosses the press, a glint runs down the chosen row, a "
                                          "light runs down the rail", "#B4AC9C")
            px = render(key, phase)
            x = gap + (k % across) * (W + gap)
            part = px[crop[1] * K:crop[3] * K, crop[0] * K:crop[2] * K]
            rs.paste(sheet.px, part, round(x * K), round((y + 16) * K))
            t.text(x + 4, y + 20 + ch, SMALL, f"{phase * LOOP:.2f} s", "#8E8676")
    notes = [
        "The motion beyond the idle, for the picked direction's strips: the screen rises 12 points as it fades in over "
        "0.22 s (out3); the rows cascade",
        "in from 24 points left, 0.035 s apart; the work's ring draws round once (0.3 s) as the gear pops in (Pop); "
        "a row tapped slides the glass to it. A rail button tapped grows to its size (0.18 s, Back 1.2) as the last "
        "one shrinks, and the work crossfades.",
        "Every colour stays violet: no teal or green but the rise's own green. The press, the levels and the item's "
        "rarity carry the light; the panels",
        "lift toward their tops so nothing reads as a black fall. Rates are research's seeds; every other number is a "
        "stand-in.",
    ]
    for n, words in enumerate(notes):
        t.text(gap + 8, height - 130 + n * 24, SMALL, words, "#B4AC9C")
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "seam_rich.png")


if __name__ == "__main__":
    main()
