"""The Tower's launch loop: the director's package of 2026-11-16, item 6 (docs/archive/director-package-2026-11-16.md).

Run:  py tools/balance/tower.py          (from the project folder)
Proposal stage: the seeds live in TOWER below until the director's yes, then move to seeds.json.

One Voidkin climbs. Each floor is one enemy Voidkin; health carries from floor to floor and nothing heals between
floors. In a fight, Regen (and Lifesteal) heal, but never more than HealCap of the lead's health in one floor.
The run ends at the first floor lost. Built on attributes.py's fighters, so the Basic Attributes are in it.
Nothing here is a measurement of play.
"""
import random, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import attributes as at  # noqa: E402
from sim import S, G, dps, line  # noqa: E402

TOWER = {
    "levelPerFloor": 0.5,     # floor f's enemy stands at level 1 + (f - 1) x this: floor 2L-1 is level L
    "enemyFrac": 0.45,        # the enemy's build: a share of its level's available build (sim.build's frac)
    "enemyHpShare": 0.55,     # an enemy Voidkin's health against a player's lead of its build: a floor is short
    "healCap": 0.15,          # in one floor, healing from every source tops out at this share of the lead's health
}


def enemy_at(floor, rng):
    lv = max(1, round(1 + (floor - 1) * TOWER["levelPerFloor"]))
    e = at.fighter_attr(min(60, lv), TOWER["enemyFrac"], "Common", rng.choice(at.CLASSES), rng.choice(list(at.SPECS)))
    e["hp"] *= TOWER["enemyHpShare"]
    return e


def climb(me, rng, cap=TOWER["healCap"], max_floors=400):
    """Floors won, and seconds spent, by one run."""
    hp, t = me["hp"], 0.0
    for f in range(1, max_floors + 1):
        e = enemy_at(f, rng)
        mine, theirs = dps(me, e), dps(e, me)
        kill = e["hp"] / mine
        heal = min(cap * me["hp"], (me["regen"] + min(mine * me["lifesteal"], S["lifesteal"]["perSecondCapOfMaxHp"] * me["hp"])) * kill)
        lost = theirs * kill - heal
        if lost >= hp:
            return f - 1, t + hp / max(1e-9, theirs - heal / kill)
        hp = min(me["hp"], hp - lost)
        t += kill + 2.5          # the rise to the next platform, about 2.5 s (seed)
    return max_floors, t


def report(runs=60, seed=5):
    print("Tower, proposal run. Seeds:", TOWER)
    rng = random.Random(seed)
    print("\n== T1. Floors won by one run, by level and build (median of runs; minutes) ==")
    line("level", "class", "frac 0.4", "frac 0.7", "frac 1.0", "min at 0.7", w=12)
    for L in (5, 15, 30, 45, 60):
        for c in at.CLASSES:
            cells, mins = [], 0
            for frac in (0.4, 0.7, 1.0):
                res = sorted(climb(at.fighter_attr(L, frac, "Common", c, "balanced", 0.03 if frac > 0.5 else 0.0), rng)
                             for _ in range(runs))
                med = res[len(res) // 2]
                cells.append(med[0])
                if frac == 0.7:
                    mins = med[1] / 60
            line(L if c == "Warrior" else "", c, *cells, f"{mins:.1f}", w=12)
    print("\n== T2. The heal cap: floors won at level 30, on budget, by cap (median) ==")
    line("class", *[f"cap {c:.0%}" for c in (0.0, 0.1, 0.15, 0.25, 1.0)], w=12)
    for c in at.CLASSES:
        me = at.fighter_attr(30, 0.7, "Common", c, "balanced", 0.03)
        row = []
        for cap in (0.0, 0.1, 0.15, 0.25, 1.0):
            res = sorted(climb(me, rng, cap)[0] for _ in range(runs))
            row.append(res[len(res) // 2])
        line(c, *row, w=12)
    print("\n== T3. Rarity: floors won at level 30, on budget, Warrior (median) ==")
    line(*at.RARITIES, w=12)
    row = []
    for r in at.RARITIES:
        res = sorted(climb(at.fighter_attr(30, 0.7, r, "Warrior", "balanced", 0.03), rng)[0] for _ in range(runs))
        row.append(res[len(res) // 2])
    line(*row, w=12)


if __name__ == "__main__":
    at.sim.ROSTER.extend(at.sim.roster())
    at.fit_profiles()
    report()
