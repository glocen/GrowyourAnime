"""Combat Power's Platinum, now visibly a colour: a blue-steel finish in two depths, for research's read (the director,
2026-11-15: "let go platnium but i want it to have color not be blend"; AR12, "The director's pick").

The plate, the emblem and the digits' build are combat_power_colour's. A finish here keeps white only at the digits'
top; its middle and foot are a saturated steel blue. Each is shown at rest on all six rarities' lights, rising on a
Rare's (its own neighbour), narrow on all six, and beside the blues and the teal that already mean something.

Mocks only. Every finish is one vertical gradient on the digits, a stroke and one glow image, so the engine can set it.

    blender -b --factory-startup --python tools/blender/combat_power_platinum.py -- build/handoff/UI/voidkin/combat_power

Writes the sheet combat_power_platinum.png.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import combat_power_colour as cp  # noqa: E402

h, kit, ui = cp.h, cp.kit, cp.ui
PW, PH = cp.PW, cp.PH

# The distances are CIEDE2000 from each finish's lower half (its mean from the step to the foot), in plain sight and,
# after the slash, the lower of deuteranopia's and protanopia's (build/scratch/modulo/cp/ramp.py, AR12's measure).
TAKES = (
    dict(key="A", name="Platinum as picked, for comparison", ramp=cp.TAKES[1]["ramp"], glow="#BFD4FF",
         caption="#C9D3E3", stroke=1.2, emblem=True,
         notes=("The sheet the director picked from: white with a cool foot. \"i want it to have color not be blend\".",)),
    dict(key="A1", name="Steel, the brighter", ramp=((0.0, "#FFFFFF"), (0.22, "#D6E4FF"), (0.5, "#7FA8F0"),
                                                       (0.56, "#4C7FD8"), (1.0, "#254E9E")), glow="#5C8CFF",
         caption="#C4D6F7", stroke=1.2, emblem=True,
         notes=("White only on the capitals' top fifth, then a steel blue from the step down. Its lower half stands 24 "
                "from Rare's blue (22 colour-blind), 37 from Frost (33), 45 from Credits' teal (35).",
                "Nearest of all: Regalia's indigo at 12 (11), experience's blue at 17 (16). The band at the step "
                "passes 6 from Rare's blue, a hair's height.")),
    dict(key="A2", name="Cobalt, the deeper", ramp=((0.0, "#FFFFFF"), (0.2, "#C9DBFF"), (0.5, "#5F90EA"),
                                                      (0.56, "#3566C9"), (1.0, "#1B3F8F")), glow="#4A7BF5",
         caption="#BCD0F7", stroke=1.2, emblem=True,
         notes=("The same hue a step deeper: the most colour, and the furthest from every blue. Its lower half stands "
                "33 from Rare's blue (30), 44 from Frost (40), 52 from Credits' teal (42).",
                "Nearest of all: Regalia's indigo at 18 (18), experience's blue at 26 (24). The cost: a darker foot "
                "on a dark plate, held by its glow.")),
)
NEIGHBOURS = (("Rare", cp.RARITY["Rare"]), ("Frost 112", ui.ELEMENTS["Frost"]), ("Credits 1,250", "#40DCC6"),
              ("Agility 48", "#3F9DF2"), ("Experience", "#4E9BFF"), ("Regalia", "#6C7BFF"))
ROW_W, ROW_H = 852.0, 384.0


def row(take):
    """A take at rest on every rarity's light, rising on a Rare's, narrow on all six, and beside its neighbours."""
    st = kit.Stage(ROW_W, ROW_H, h.PARTS_GROUND)
    kit.panel(st, 0, 0, ROW_W, ROW_H, h.ROOMS["Graphite, Voidkin"])
    for i, rarity in enumerate(cp.RARITY):
        x, y = 16.0 + (i % 3) * (PW + 18), 22.0 + (i // 3) * 80
        cp.plate(st, x, y, PW, rarity, take, cp.VALUE)
        cp.text(st, x + 8, y - 15, 9, f"{rarity}, at rest", h.NOTE)
    x = 16.0
    for rarity in cp.RARITY:
        cp.plate(st, x, 182, 124.0, rarity, take, cp.VALUE, narrow=True)
        x += 124 + 14
    cp.text(st, 24, 251, 9, "Rare, rising: the roll about half way", h.NOTE)
    cp.plate(st, 16, 266, PW, "Rare", take, cp.ROSE_TO, rise=cp.PLUS)
    cp.text(st, 24, 334, 9, "beside the blues and the teal that already mean something, at 20 points", h.NOTE)
    cp.digits(st, 24, 352, 20.0, cp.VALUE, take)
    x = 24 + cp.wide(cp.VALUE, 20.0) + 26
    for word, colour in NEIGHBOURS:
        cp.text(st, x, 352, 20.0, word, cp.INK, layer="b_ink", bold=2.4)
        cp.text(st, x, 352, 20.0, word, colour)
        x += len(word) * 20 * 0.5 + 26
    return h.bytes8(h.halve(st.px)), st.items


def sheet(out, rows):
    ui.K = 2
    m, head, cap = 20.0, 78.0, 56.0
    sh = ui.Sheet(ROW_W + 2 * m, head + len(rows) * (cap + ROW_H + 14) + 6, h.GROUND)
    t = sh.tile(0, 0, sh.w, head)
    t.text(m, 14, 17, "Grow your Anime: Combat Power's Platinum, now visibly a colour (AR12)", h.HEAD)
    t.text(m, 40, 10, "The picked finish beside a blue-steel in two depths: white only at the digits' top, a saturated "
           "steel blue from the step to the foot. The plate, the emblem and the stroke don't change.", h.NOTE)
    t.text(m, 54, 10, "Each at rest on all six rarities' lights, narrow as between the two hands, rising on a Rare's, and "
           "beside its neighbours. Distances are CIEDE2000; in brackets, the lower of two colour-blind readings.", h.NOTE)
    y = head
    for take, (px, items) in rows:
        tt = sh.tile(m, y, ROW_W, cap)
        tt.text(0, 6, 13, f"{take['key']}: {take['name']}", h.HEAD)
        for i, line in enumerate(take["notes"]):
            tt.text(0, 26 + i * 14, 10, line, h.NOTE)
        y += cap
        h.add(sh, px, items, m, y)
        y += ROW_H + 14
    cp.finish(sh, out / "combat_power_platinum.png")


def main():
    out = bl.out_dir()
    ui.K = cp.K4
    h.stage("started")
    kit.panels()
    cp.vm.marks()
    rows = [(take, row(take)) for take in TAKES]
    h.stage("the rows")
    kit.IMAGES.clear()
    sheet(out, rows)
    h.stage("the sheet")


if __name__ == "__main__":
    main()
