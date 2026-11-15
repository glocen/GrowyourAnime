"""AR12, delivery 3 (docs/asset-requests.md, AR12, "Delivery 3, the older screens, vivid"): after the bays, "the
reveal". The ceremony is already the reveal's own art (AR3); what's still all dark is the card that follows it
(src/client/Controllers/Main/BaseController.luau, "The card that's there today"). This draws the sheets research
judges before any image is made: today beside vivid, at a phone's size.

Today's side is Faber's own takes of the build (TR4), cut to the phone's screen:

    ffmpeg -ss 4.8 -i build/captures/tr4/take_common_sound.mp4 -frames:v 1 -vf crop=936:430:15:13 build/scratch/modulo/d3r/card_common.png
    ffmpeg -ss 7.3 -i build/captures/tr4/take_mythical_sound.mp4 -frames:v 1 -vf crop=936:430:15:13 build/scratch/modulo/d3r/card_mythical.png
    ffmpeg -ss 5.0 -i build/captures/tr4/take_mythical_sound.mp4 -frames:v 1 -vf crop=936:430:15:13 build/scratch/modulo/d3r/held_mythical.png

The first sheet keeps the build's card where it stands, in the reveal's room ("Void Violet, vivid",
hud_colour_sheet.ROOMS). The second offers a place for it (tier 2, not built): a low plate under the name the ceremony
has just set, over the held frame undimmed, so the Voidkin and its frame stay seen. Text is Blender's face standing in
for the game's.

    blender -b --factory-startup --python tools/blender/reveal_card_vivid_sheet.py -- build/handoff/UI/hud/colour
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import hud_colour_sheet as h  # noqa: E402
import power_vivid_sheet as pv  # noqa: E402
import screens_vivid_sheet as sv  # noqa: E402

kit, ui, rs, c = h.kit, h.ui, h.rs, h.c
W, H, K4 = h.W, h.H, h.K4
STILLS = h.REPO / "build" / "scratch" / "modulo" / "d3r"
ROOM = dict(h.ROOMS["Void Violet, vivid"], alpha=1.0)  # solid here: the mock is drawn over the built card
SMALL = sv.SMALL
STAR = ui.LIGHT  # a star's light: ivory, so it's no rarity's gold
CARD = (246.0, 100.0, 322.0, 178.0)  # the build's card, measured on the still (2 points over, to cover it)
PLATE = (113.0, 256.0, 320.0, 84.0)  # the offered place: under the name's line, clear of the frame

# What the card's fourth line says, by what the shard gave (the build's own words), each in its meaning's colour beside
# its mark: a Voidkin kept is the Voidkin's lavender, a copy is a star's light, a sale is Credits' teal.
NOTES = {
    "New": ("Shard", "In your collection", h.VOIDKIN),
    "Lead": ("Shard", "Your lead: it fights beside you", h.VOIDKIN),
    "Copy": ("Star", "One more toward its next star", STAR),
    "Sold": ("CoinMint", "Sold for 120 Credits", h.CREDITS),
}
KINDS = {"New": "A new Voidkin", "Lead": "A new Voidkin", "Copy": "A copy", "Sold": "Already at its last star"}


def star(st, cx, cy, r, colour):
    t = kit.blank(4 * r, 4 * r)
    d = h._star(t, 2 * r, 2 * r, r)
    t.paint(d - 1.0, c(h.STROKE))
    t.paint(d, c(colour))
    h.place(st, t, cx - 2 * r, cy - 2 * r)


def mark(st, name, cx, cy, size, colour):
    if name == "Star":
        star(st, cx, cy, size * 0.42, colour)
    else:
        st.icon(name, cx, cy, size)


def note(st, x, cy, size, outcome):
    """The outcome's line: its mark, then its words in the meaning's colour. Returns where it ends."""
    icon, words, colour = NOTES[outcome]
    mark(st, icon, x + size * 0.55, cy, size * 1.25, colour)
    return pv.runs(st, x + size * 1.35, cy, size, ((words, colour),))


def line(st, x, cy, size, rarity, p):
    """Rarity, type and class: the rarity's word in its colour beside its pip, the rest soft."""
    sv.pip(st, x + 5, cy, sv.WORD[rarity])
    return pv.runs(st, x + 14, cy, size, ((rarity, sv.WORD[rarity]), ("·", p["faint"]), ("Strength", p["soft"]),
                                          ("·", p["faint"]), ("Warrior", p["soft"])))


def card(p, world, rarity, outcome):
    """The build's card, where it stands: five lines on one panel, in the reveal's room."""
    st = pv.stage_over(world)
    x, y, w, hh = CARD
    kit.panel(st, x, y, w, hh, p)
    pv.breath(st, x + 96, y + 52, 150.0, 60.0, h.VOIDKIN, 0.12)  # a breath of the void's light behind the name
    pv.word(st, x + 20, y + 27.5, SMALL, KINDS[outcome], p["soft"])
    pv.word(st, x + 20, y + 59, 21, "Rook", p["text"])
    line(st, x + 20, y + 90, 13, rarity, p)
    note(st, x + 20, y + 117, 13, outcome)
    pv.word(st, x + 20, y + 142, SMALL, "Tap to continue", p["soft"])
    return h.bytes8(h.halve(st.px)), st.items


def plate(p, world, rarity, outcome):
    """Offered: a low plate under the name the ceremony set, so the card never stands over the Voidkin. The name isn't
    said twice: the ceremony's own stays the only one."""
    st = pv.stage_over(world)
    x, y, w, hh = PLATE
    kit.panel(st, x, y, w, hh, p)
    pv.word(st, x + 16, y + 18, SMALL, KINDS[outcome], p["soft"])
    line(st, x + 16, y + 40, 13, rarity, p)
    note(st, x + 16, y + 64, 13, outcome)
    pv.word(st, x + w - 16, y + 64, SMALL, "Tap to continue", p["soft"], "RIGHT")
    return h.bytes8(h.halve(st.px)), st.items


def notes_strip(p):
    """The card's fourth line for each thing a shard can give, on the room's panel."""
    st = kit.Stage(W, 44.0, h.GROUND)
    kit.panel(st, 0, 2, W, 40, p)
    x = 16.0
    for outcome in NOTES:
        x = note(st, x, 22, 12, outcome) + 16
    return h.bytes8(h.halve(st.px)), st.items


def rarities_strip(p):
    """Each rarity's word on the room's panel, beside its pip."""
    st = kit.Stage(W, 44.0, h.GROUND)
    kit.panel(st, 0, 2, W, 40, p)
    x = 16.0
    for rarity, colour in sv.WORD.items():
        sv.pip(st, x + 5, 22, colour)
        x = pv.runs(st, x + 14, 22, 12, ((rarity, colour),)) + 14
    return h.bytes8(h.halve(st.px)), st.items


def measures(p):
    for ground_name, ground in (("the panel's top", p["panel"][0]), ("its middle", h.mix(*p["panel"], 0.5))):
        words = (("text", p["text"]), ("soft", p["soft"]), ("faint", p["faint"]), ("the Voidkin's lavender", h.VOIDKIN),
                 ("a star's light", STAR), ("Credits", h.CREDITS)) + tuple(sv.WORD.items())
        said = ", ".join(f"{name} {pv.contrast(colour, ground):.1f}" for name, colour in words)
        print(f"contrast on {ground_name} ({ground}): {said}")


CARD_NOTES = (
    "Delivery 3 (the director, 2026-11-15: \"we need to add more colors and appealing to each old full dark ui\"): after the "
    "bays, the reveal. The ceremony is already the reveal's own art; what's still all dark is the card that follows it. "
    "Here it stands where the build puts it, with the build's five lines, in the reveal's room: Void Violet, vivid.",
    "Words wear their meaning's colour: the rarity's word in its colour beside its pip, type and class soft; the fourth "
    "line beside its mark, in the Voidkin's lavender when it's kept, a star's ivory light for a copy, Credits' teal for a "
    "sale. The card has no button, so nothing is filled: a tap anywhere goes on.",
    "The take's own card shows no third line (the test's show has no definition's row); a real shard's reads as drawn.",
    "Stand-ins: Blender's face for the game's text; \"120\" on the sale's line; the world behind is the still's own.",
)
PLATE_NOTES = (
    "For research and Faber, tier 2, not built. Today the card stands over the middle of the held frame: it covers the "
    "name's end and half of the Voidkin, and the screen dims behind it, so the reveal's last picture is lost the moment it "
    "lands. The offer: a low plate under the name's line, over the held frame undimmed. The Voidkin, its frame and the "
    "rarity's light stay whole, and the name is said once, by the ceremony.",
    "The plate keeps the build's other four lines: what it is, rarity, type and class, what became of it, and \"Tap to "
    "continue\" at its right. It costs Faber the card's place and size, the dim, and the name's line dropped.",
)


def world(name):
    still = rs.load(STILLS / f"{name}.png")
    small = h.bytes8(h.resize(still, round(W * 2), round(H * 2)))
    big = np.ascontiguousarray(h.resize(still, round(W * K4), round(H * K4)))
    big[..., 3] = 1.0
    return small, big


def main():
    out = bl.out_dir()
    h.stage("started")
    sv.slices()
    p = ROOM
    measures(p)
    before_common, big = world("card_common")
    shot_card = card(p, big, "Common", "New")
    del big
    h.stage("the card")
    before_mythical, _ = world("card_mythical")
    _, big = world("held_mythical")
    shot_plate = plate(p, big, "Mythical", "New")
    del big, _
    h.stage("the plate")
    strips_card = (("The fourth line, for each thing a shard can give:", notes_strip(p)),
                   ("Each rarity's word on this room's panel:", rarities_strip(p)))
    kit.IMAGES.clear()
    pv.sheet(out, "vivid3_reveal_card.png", "Grow your Anime: the card after the reveal, today and in Void Violet vivid. A Common, new",
             ("Today: Faber's take of the build (TR4), the card in Graphite", "Void Violet, vivid: the same card in the reveal's room"),
             h.floats(before_common), shot_card, CARD_NOTES, strips_card)
    h.stage("the card's sheet")
    pv.sheet(out, "vivid3_reveal_card_offer.png", "Grow your Anime: the card after the reveal, today and an offered place. A Mythical, new",
             ("Today: Faber's take of the build (TR4)", "Offered (tier 2, not built): a low plate under the name, the held frame undimmed"),
             h.floats(before_mythical), shot_plate, PLATE_NOTES, ())
    h.stage("the offer's sheet")


if __name__ == "__main__":
    main()
