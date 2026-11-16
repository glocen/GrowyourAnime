"""AR6's batch sheet: a batch's kinds on one sheet for one verdict, a row each, its fifteen in their rarity's threes.

A row reads a kind's ladder; a column reads one set down every kind. Each kind's own sheet (gear_<kind>_sets.py) keeps
its names, its notes, the slot's 38 points and the silhouettes: this one only sets the kinds side by side.

    blender -b --factory-startup --python tools/blender/gear_batch_sheet.py -- <out> batch2 [kind ...]

Renders the kinds named (every one still missing if none is named), keeps each shot at the tile's size in <out>/cache,
and writes gear_<batch>_sheet.png once the batch's every kind is in. Four kinds take about six minutes, so a batch goes
in two runs. Workbench only: no GPU turn.
"""
import importlib
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_parts as p  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
from ui_sheet import c  # noqa: E402

g = p.g
K = 2
TILE, PITCH, GAP, LABEL = 56.0, 59.0, 12.0, 76.0   # points: a tile, its step within a rarity, the step between rarities
TOP, ROW = 110.0, 64.0
GROUP = 2 * PITCH + TILE + GAP

BATCHES = dict(
    batch2=dict(
        title="Grow your Anime: AR6's batch 2, the eight shared kinds, in grey, for one verdict",
        kinds=(("shoulders", "Shoulders"), ("chest", "Chest Armor"), ("gloves", "Gloves"), ("bracers", "Bracers"),
               ("boots", "Boots"), ("cloak", "Cloak"), ("amulet", "Amulet"), ("earring", "Earring")),
        notes=(
            "Each kind's view: Shoulders, a mantle from the front and above; Chest Armor, a breastplate turned a little; "
            "Gloves, the right hand's back; Bracers, a vambrace, the elbow high; Boots, the right boot's outer side;",
            "Cloak, from behind; Amulet, a necklace's loop and its pendant; Earring, one hook and its drop. The Cloak's "
            "plain three are Wool, Hooded and Scrap, and its Lanternsteel is Lanternweave.",
            "A Legendary is named alone, each with its one new form. No flame and no cloud anywhere: a light is a stone or "
            "a line. Not here yet: colour, frames.",
            "For the verdict: does each read as its kind, and apart from its neighbours? Does a set read as one down its "
            "column? Does each Legendary outrank its row's Epics by shape?",
        ),
    ),
    batch3=dict(
        title="Grow your Anime: AR6's batch 3, the eight class weapons, in grey, for one verdict",
        kinds=(("great_axe", "Great Axe"), ("shield", "Shield"), ("staff", "Staff"), ("tome", "Tome"),
               ("dagger", "Dagger"), ("throwing_blades", "Throwing Blades"), ("crystal_baton", "Crystal Baton"),
               ("codex", "Codex")),
        notes=(
            "Two kinds a class, its main hand then its off hand: the Tank's Great Axe and Shield, the Mage's Staff and "
            "Tome, the Assassin's Dagger and Throwing Blades, the Healer's Crystal Baton and Codex.",
            "Each pair keeps apart from its neighbours: the Staff is an open ring, never a crystal; the Baton is short and "
            "holds a cut crystal; the Tome is thick and heavy, the Codex slim and light; the Dagger is one fang, the "
            "Throwing Blades a fan of three.",
            "A Legendary is named alone, each with its one new form. No flame and no cloud anywhere: a light is a stone or "
            "a line. Not here yet: colour, frames, the class mark.",
            "For the verdict: does each read as its kind, and apart from its neighbours? Does a set read as one down its "
            "column? Does each Legendary outrank its row's Epics by shape?",
        ),
    ),
)

# A set keeps its column on every kind, so a word must stand in each name of its column.
SETS = dict(Common=("Iron", "Bronze", "Scrap"), Uncommon=("Lanternsteel", "Rowsmith", "Stallguard"),
            Rare=("Embers", "Hoarfrost", "Gales"), Epic=("Stormcall", "Gloamforge", "Nightloom"))
ALIKE = {"Iron": ("Wool",), "Bronze": ("Hooded",), "Lanternsteel": ("Lanternweave",)}   # the Cloak's own plain words


def order(kind, designs):
    """The kind's fifteen names in the sheet's order, each set in its column."""
    by = {r: [d["name"] for d in designs if d["rarity"] == r] for r in p.RARITIES}
    for r, words in SETS.items():
        for name, word in zip(by[r], words):
            assert any(w in name for w in (word,) + ALIKE.get(word, ())), f"{kind}: {name} stands in {word}'s column"
    return [n for r in p.RARITIES for n in by[r]]


def render(kind, cache):
    module = importlib.import_module(f"gear_{kind}_sets")
    p.check_names(module.DESIGNS)
    names = order(kind, module.DESIGNS)
    factor = TILE * K / g.SIZE
    shots = p.renders(module, bl.out_dir(), keep=lambda name, shot: rs.shrink(shot, factor))
    np.save(cache / f"{kind}.npy", np.stack([shots[n] for n in names]))


def sheet(out, name, cache):
    batch = BATCHES[name]
    ui.K = K
    width = 20 + LABEL + 5 * GROUP - GAP + 20
    notes_y = TOP + len(batch["kinds"]) * ROW + 8
    sh = ui.Sheet(width, notes_y + 15 * len(batch["notes"]) + 14, g.GROUND)
    t = sh.tile(0, 0, sh.w, sh.h)
    t.text(20, 12, 15, batch["title"], g.INK)
    t.text(20, 36, 9.5, "A row is a kind, its fifteen in their rarity's threes; a column is a set, carried down every kind. "
           "Each kind's own sheet keeps its names, its notes, the slot's 38 points and the silhouettes.", g.SOFT_INK)
    for i, r in enumerate(p.RARITIES):
        x = 20 + LABEL + i * GROUP
        t.text(x, 70, 12, r, g.NOTE)
        if r == "Legendary":
            t.text(x, 90, 7.5, "each its own", g.SOFT_INK)
        for j, word in enumerate(SETS.get(r, ())):
            t.text(x + j * PITCH + TILE / 2, 90, 7.5, word, g.SOFT_INK, align="CENTER")
    for k, (kind, label) in enumerate(batch["kinds"]):
        y = TOP + k * ROW
        t.text(20, y + TILE / 2 - 6, 10.5, label, g.INK)
        shots = np.load(cache / f"{kind}.npy")
        for n, shot in enumerate(shots):
            x = 20 + LABEL + (n // 3) * GROUP + (n % 3) * PITCH
            tile = sh.tile(x, y, TILE, TILE)
            tile.paint(tile.poly(ui.cut_box(0, 0, TILE, TILE, 4, 0, 4, 0)), c(g.CELL))
            rs.paste(sh.px, shot, round(x * K), round(y * K))
    for i, line in enumerate(batch["notes"]):
        t.text(20, notes_y + i * 15, 9, line, g.SOFT_INK)
    for layer in ui.text_layers(sh.px.shape[1], sh.px.shape[0], sh.items).values():
        rs.paste(sh.px, layer, 0, 0)
    rs.save(sh.px, out / f"gear_{name}_sheet.png")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    name, wanted = args[0], args[1:]
    cache = out / "cache"
    cache.mkdir(exist_ok=True)
    kinds = [k for k, _ in BATCHES[name]["kinds"]]
    for kind in wanted or [k for k in kinds if not (cache / f"{k}.npy").exists()]:
        render(kind, cache)
    missing = [k for k in kinds if not (cache / f"{k}.npy").exists()]
    if missing:
        print("Still to render:", ", ".join(missing))
    else:
        sheet(out, name, cache)


if __name__ == "__main__":
    main()
