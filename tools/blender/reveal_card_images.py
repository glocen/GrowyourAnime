"""AR12, the reveal card's cut images (docs/asset-requests.md, AR12, "The reveal's card, its images"): the low plate
research accepted on reveal_card_vivid_sheet.py's Eclipse sheets, cut into the images the build lays, on research's
three calls: the plate under the name's line, the fourth line's three colours, and the shard's mark in silver.

The plate itself is the kit's panel in Eclipse's colours: no new slice. Four images are new, each from a function of
its own here: a rarity's pip and its facet, a star, and the shard in silver. Nothing of a capture is in one, and no
word: the sheet's words are Blender's face, on the sheet only.

Writes into the handoff folder: images/RarityPip.png, RarityPipFacet.png, Star.png, ShardSilver.png,
reveal_card_images.json (the plate's layers, its four lines, each mark and colour) and reveal_card_images.png, the
images beside the plate laid from them for each thing a shard can give. The check copies (each image over dark, whole
and at 64 pixels) go to build/scratch/modulo/reveal_card_images/.

    blender -b --factory-startup --python tools/blender/reveal_card_images.py -- build/handoff/UI/hud/colour eclipse
"""
import json
import sys
import textwrap
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import reveal_card_vivid_sheet as rc  # noqa: E402

h, kit, ui, rs, c, pv, sv = rc.h, rc.kit, rc.ui, rc.rs, rc.c, rc.pv, rc.sv
K4 = rc.K4
assert rc.ECLIPSE, "give `eclipse` after the folder: the card is cut in Eclipse only"
ROOM, KEPT, STAR = rc.ROOM, rc.KEPT, rc.STAR
CHECK = h.REPO / "build" / "scratch" / "modulo" / "reveal_card_images"

WIDE, HIGH = rc.PLATE[2:]  # the plate
INSET = 16.0  # from the plate's left to its lines, and from its right to "Tap to continue"
ROWS = dict(kind=18.0, rarity=40.0, outcome=64.0)  # each line's middle, under the plate's top
TEXT = 13.0  # the rarity's line and the outcome's; the first line and "Tap to continue" are the screen's smallest
RUN_GAP = 0.4  # between two runs of words on a line, of the text's size
PIP = 14.0  # a pip's box
PIP_AT, PIP_WORDS = 5.0, 14.0  # the pip's middle and its words' start, from the line's left
FACET_ALPHA = 0.55
MARK = TEXT * 1.25  # an outcome's mark, a square
MARK_AT, MARK_WORDS = TEXT * 0.55, TEXT * 1.35  # its middle and its words' start, from the line's left
MARKS = {"Shard": "ShardSilver", "Star": "Star", "CoinMint": "CoinMint"}  # the sheet's mark, the image that's laid
NAMES = ["RarityPip", "RarityPipFacet", "Star", "ShardSilver"]
SHOWN = (("Common", "New"), ("Rare", "Lead"), ("Legendary", "Copy"), ("Mythical", "Sold"))


# --- the images, one function each ----------------------------------------------------------------------------------

def pip():
    """A rarity's pip: a four-point diamond, white inside a dark outline, tinted its rarity's word colour
    (screens_vivid_sheet.pip's shape)."""
    t = kit.blank(PIP, PIP)
    d = h.g_diamond(t, PIP / 2, PIP / 2, 4.4, 5.6)
    t.paint(d - 1.2, c(h.STROKE))
    t.paint(d, ui.WHITE)
    kit.keep("RarityPip", t, "the rarity's word colour", None, 0.0, "beside a rarity's word, its middle on the line's")


def pip_facet():
    """The pip's facet: a smaller diamond off its middle, white, laid over the pip untinted."""
    t = kit.blank(PIP, PIP)
    t.paint(h.g_diamond(t, 6.2, 5.6, 1.5, 2.0), ui.WHITE)
    kit.keep("RarityPipFacet", t, None, None, 0.0, f"on the pip's own box, over it, white at {FACET_ALPHA}")


def star():
    """A star's mark: five points in the conduit's ivory light, so it's no rarity's gold, inside a dark outline. Drawn
    on an icon's box, to be laid at the same size as the shard's and the coin's."""
    m, r = kit.BOX / 2, kit.BOX * 0.42
    t = kit.blank(kit.BOX, kit.BOX)
    d = h._star(t, m, m, r)
    t.paint(d - 2.0, c(h.STROKE))
    t.paint(d, c(STAR))
    kit.keep("Star", t, None, None, 0.0, "a copy's line: one more toward its next star; its colour is its own")


def shard_silver():
    """The shard's mark in Eclipse's silver, for a Voidkin kept: hud_colour_sheet's shard, in the colour its line
    wears."""
    h.shard_icon("ShardSilver", KEPT, "a Voidkin kept, on the reveal's plate; its colours are its own")


def cut_images():
    pip()
    pip_facet()
    star()
    shard_silver()
    return NAMES


# --- the plate, laid from the images ---------------------------------------------------------------------------------

def lay_pip(st, cx, cy, colour):
    st.lay("RarityPip", cx - PIP / 2, cy - PIP / 2, tint=colour)
    st.lay("RarityPipFacet", cx - PIP / 2, cy - PIP / 2, alpha=FACET_ALPHA)


def lay_plate(st, x, y, rarity, outcome, p):
    """The plate as the build lays it: the kit's panel, then four lines."""
    kit.panel(st, x, y, WIDE, HIGH, p)
    left = x + INSET
    pv.word(st, left, y + ROWS["kind"], rc.SMALL, rc.KINDS[outcome], p["soft"])
    lay_pip(st, left + PIP_AT, y + ROWS["rarity"], sv.WORD[rarity])
    pv.runs(st, left + PIP_WORDS, y + ROWS["rarity"], TEXT,
            ((rarity, sv.WORD[rarity]), ("·", p["faint"]), ("Strength", p["soft"]), ("·", p["faint"]), ("Warrior", p["soft"])))
    icon, words, colour = rc.NOTES[outcome]
    st.icon(MARKS[icon], left + MARK_AT, y + ROWS["outcome"], MARK)
    end = pv.runs(st, left + MARK_WORDS, y + ROWS["outcome"], TEXT, ((words, colour),))
    tap = x + WIDE - INSET - pv.width("Tap to continue", rc.SMALL)
    pv.word(st, x + WIDE - INSET, y + ROWS["outcome"], rc.SMALL, "Tap to continue", p["soft"], "RIGHT")
    return tap - (end - TEXT * RUN_GAP)  # the room left between the outcome's words and "Tap to continue"


def plates(p):
    """Each thing a shard can give, on a plate laid from the images, over the sheet's dark."""
    m = 10.0
    st = kit.Stage(2 * (WIDE + 2 * m), 2 * (HIGH + 2 * m), h.PARTS_GROUND)
    room = {}
    for i, (rarity, outcome) in enumerate(SHOWN):
        room[outcome] = lay_plate(st, m + (i % 2) * (WIDE + 2 * m), m + (i // 2) * (HIGH + 2 * m), rarity, outcome, p)
    return (h.bytes8(h.halve(st.px)), st.items), room


def manifest(out, names, room):
    p = ROOM
    images = {}
    for name in names:
        im = kit.IMAGES[name]
        images[name] = dict(file=f"images/{name}.png", pixels=[im["px"].shape[1], im["px"].shape[0]],
                            points=[im["w"], im["h"]], **({"tint": im["tint"]} if im["tint"] else {}), use=im["use"])
    data = dict(
        pixelsPerPoint=K4, palette="A, Eclipse (AR12, the pick of 2026-11-15)", room="Eclipse",
        note="The plate after the reveal, on research's verdict (AR12, \"Research's verdict on the reveal's card, in "
             "Eclipse\"). The plate is the kit's panel (build/handoff/UI/kit/kit.json) in `colours`; the four images here "
             "are its marks, and CoinMint is the HUD's own (hud_colour.json). A white image takes its tint; a dark part "
             "baked into one stays dark. Every measure is in points from the plate's top left; a line's `middle` is the "
             "height its text and its mark are centred on. Words are the build's own; their widths here were measured in "
             "Blender's face, so `room` is a seed. DESIGN, untried in Studio.",
        colours=dict(panel=list(p["panel"]), alpha=p["alpha"], edge=p["edge"], facet=p["facet"], glint=p["glint"],
                     text=p["text"], soft=p["soft"], faint=p["faint"], kept=KEPT, star=STAR, credits=h.CREDITS),
        rarityWords=dict(sv.WORD),
        plate=dict(
            size=[WIDE, HIGH],
            anchor="under the ceremony's name, left-aligned with it, never to the screen, so it holds on the smallest "
                   "phone; the held frame stays undimmed behind it. On the accepted sheet it stood at 113, 256 of an 812 "
                   "by 375 screen. The gap under the name's line is the builder's, from the build's own name.",
            stack=["PanelShadow", "PanelFill tinted `panel` top to foot at `alpha`", "PanelFacet tinted `facet` at 0.07",
                   "PanelEdge tinted `edge` at 0.95", "PanelGlint tinted `glint`"],
            inset=INSET,
            lines=[
                dict(name="kind", middle=ROWS["kind"], size=rc.SMALL, colour="soft", words=dict(rc.KINDS)),
                dict(name="rarity", middle=ROWS["rarity"], size=TEXT,
                     pip=dict(images=["RarityPip", "RarityPipFacet"], box=[PIP, PIP], middle=INSET + PIP_AT,
                              tint="the rarity's word colour", facetAlpha=FACET_ALPHA),
                     wordsFrom=INSET + PIP_WORDS, gap=TEXT * RUN_GAP,
                     runs=["the rarity, in its word colour", "a dot, faint", "the type, soft", "a dot, faint", "the class, soft"]),
                dict(name="outcome", middle=ROWS["outcome"], size=TEXT,
                     mark=dict(box=[MARK, MARK], middle=INSET + MARK_AT), wordsFrom=INSET + MARK_WORDS,
                     note="one colour a line: its mark and its words together",
                     outcomes={outcome: dict(mark=MARKS[icon], words=words, colour=colour,
                                             room=round(room[outcome], 1))
                               for outcome, (icon, words, colour) in rc.NOTES.items()}),
                dict(name="tap", middle=ROWS["outcome"], size=rc.SMALL, colour="soft", words="Tap to continue",
                     align="right", right=INSET,
                     note="`room` on an outcome is what Blender's face leaves between its words and this line; if the "
                          "game's face leaves under about 12, this line goes under the plate's foot, centred"),
            ]),
        images=images)
    (out / "reveal_card_images.json").write_text(json.dumps(data, indent=1), encoding="utf-8", newline="\n")
    print(f"wrote {out / 'reveal_card_images.json'}: {len(images)} images")


def over_dark(px, size=None):
    """An image on the sheet's dark ground: whole, or fitted into a square of `size` pixels."""
    if size:
        px = kit.fit(px, size)
    hh, w = (size, size) if size else px.shape[:2]
    ground = rs.canvas(w, hh, tuple(c(h.PARTS_GROUND)))
    rs.paste(ground, px, (w - px.shape[1]) // 2, (hh - px.shape[0]) // 2)
    return ground


NOTES = (
    "The reveal's plate, cut for the build (AR12), on research's three calls: the low plate under the name's line, the "
    "fourth line's three colours, the shard's mark in silver. The plate is the kit's panel in Eclipse's colours, so "
    "four images are new: a rarity's pip and its facet (the pip white, tinted its rarity's word colour; the facet laid "
    "over it untinted), a star in the conduit's ivory, and the shard in silver. The coin is the HUD's own.",
    "Under them, the plate laid from the images the way reveal_card_images.json says the build lays it, once for each "
    "thing a shard can give. Each line is one colour, its mark and its words together. Stand-ins: Blender's face for "
    "the game's text; \"120\" on the sale's line; Strength and Warrior on every plate.",
)


def sheet(out, names, shot):
    """The images over dark, whole and at 64 pixels, then the plates."""
    ui.K = 2
    m, gap = 20.0, 12.0
    lines = [line for note in NOTES for line in textwrap.wrap(note, 150)]
    shown = names + ["CoinMint"]
    tall = max(kit.IMAGES[n]["px"].shape[0] for n in shown) / 2
    y_whole, y_small = 62.0, 62.0 + tall + 30.0
    y_rows = y_small + 32.0 + 22.0
    wide = shot[0].shape[1] / 2
    sh = ui.Sheet(2 * m + wide, y_rows + 14.0 + shot[0].shape[0] / 2 + 12.0 + len(lines) * 15 + 14, h.GROUND)
    t = sh.tile(0, 0, sh.w, sh.h)
    t.text(m, 14, 17, "Grow your Anime: the reveal's plate, its images as delivered (Eclipse)", h.HEAD)
    t.text(m, 44, 11, "Each image over dark at its own pixels; under them, each at 64 pixels. CoinMint is the HUD's own.", h.HEAD)
    x = m
    for name in shown:
        px = over_dark(kit.IMAGES[name]["px"])
        kit.put(sh, px, x * 2, y_whole * 2)
        t.text(x, y_whole + px.shape[0] / 2 + 4, 9, name, h.NOTE)
        x += max(px.shape[1] / 2, 96.0) + gap
    x = m
    for name in shown:
        kit.put(sh, over_dark(kit.IMAGES[name]["px"], 64), x * 2, y_small * 2)
        x += 32.0 + gap
    t.text(m, y_rows, 10, "The plate laid from the images: a Common kept, a Rare made the lead, a Legendary's copy, a Mythical sold:", h.NOTE)
    h.add(sh, *shot, m, y_rows + 14)
    y = y_rows + 14.0 + shot[0].shape[0] / 2 + 12.0
    for i, line in enumerate(lines):
        t.text(m, y + i * 15, 10, line, h.NOTE)
    kit.finish(sh, out / "reveal_card_images.png")


def main():
    out = bl.out_dir()
    h.stage("started")
    sv.slices()
    names = cut_images()
    h.stage("the images")
    (out / "images").mkdir(exist_ok=True)
    CHECK.mkdir(parents=True, exist_ok=True)
    for name in names:
        px = kit.IMAGES[name]["px"].copy()
        kit.bleed(px)
        rs.save(px, out / "images" / f"{name}.png")
        rs.save(over_dark(kit.IMAGES[name]["px"]), CHECK / f"{name}_whole.png")
        rs.save(over_dark(kit.IMAGES[name]["px"], 64), CHECK / f"{name}_64.png")
    shot, room = plates(ROOM)
    for outcome, left in room.items():
        print(f"room before \"Tap to continue\", {outcome}: {left:.1f} points")
    manifest(out, names, room)
    h.stage("the images saved")
    sheet(out, names, shot)
    kit.IMAGES.clear()
    h.stage("the sheet")


if __name__ == "__main__":
    main()
