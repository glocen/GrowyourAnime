"""The Tower's run: the director's package of 2026-11-16, item 6 (docs/archive/director-package-2026-11-16.md); TR29.

Run:  py tools/balance/tower.py          (from the project folder)
Reads src/shared/Config/Tower.luau, the home of the Tower's numbers since TR29 (the floor's level, the foe's health
share, the heal cap, the rises, fast floors, Credits and chests), and seeds.json's "tower" for the foe's build share
(enemyFrac), which Config.Tower's Lift is read from. The Tower's chest row is research's fit, printed by T5.

One Voidkin climbs. Each floor is one enemy Voidkin; health carries from floor to floor and nothing heals between
floors. In a fight, Regen (and Lifesteal) heal, but never more than HealCap of the lead's health in one floor.
A foe Fast.Gap levels or more under the lead falls to the first hit and costs nothing. The run ends at the first
floor lost. Built on attributes.py's fighters, so the Basic Attributes are in it. Nothing here is a measurement of play.
"""
import math, random, re, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import attributes as at  # noqa: E402
import chests  # noqa: E402
import sim  # noqa: E402
from sim import S, G, dps, line  # noqa: E402

ENEMY_FRAC = S["tower"]["enemyFrac"]   # seeds.json, "tower": the foe's build share (Config.Tower.Lift is read from it)
FIRST_HIT = 0.5    # seconds from a fast floor's landing to the lead's first hit (a guess)
BETWEEN = 10.0     # seconds between runs: the results read, Config's Rest, the step back into the ring (a guess)
CPK = S["pace"]["creditsPerKillPerG"]

# Research's fit (T5). Each is a choice, labelled as one, judged in play.
TOWER_SHARE = 0.5         # of play after the first hour spent in the Tower at launch (a guess; T5 shows 0.25 and 1)
CREDITS_VS_GROUND = 0.5   # the Tower pays half a ground's Credits an hour: it pays the gear, the grounds the Credits
CHESTS_AN_HOUR = 15       # Tower chests an hour of runs at launch: about the elites' stream on Lantern Row
UNCOMMON_OR_BETTER = 0.4  # of the Tower's chests: well above an elite's chest on Lantern Row (row 2, 8.6%)
LAUNCH_LEVEL = 10         # the launch lead after Lantern Row's hour (its ladder ends at 9)


def config():
    src = sim.lua("src/shared/Config/Tower.luau")

    def num(pat):
        return float(re.search(pat, src)[1])
    chest = re.search(r"Chest = \{([^}]*)\}", src)[1]
    return {
        "levelPerFloor": num(r"LevelPerFloor = ([\d.]+)"),
        "hpShare": num(r"\n\tHealth = ([\d.]+)"),
        "healCap": num(r"HealCap = ([\d.]+)"),
        "rise": num(r"\n\tRise = ([\d.]+)"),
        "fastGap": num(r"Fast = \{ Gap = ([\d.]+)"),
        "fastRise": num(r"Fast = \{ Gap = [\d.]+, Rise = ([\d.]+)"),
        "share": num(r"Credits = \{ Share = ([\d.]+)"),
        "record": num(r"Credits = \{ Share = [\d.]+, Record = ([\d.]+)"),
        "chest": {k: float(re.search(rf"{k} = ([\d.]+)", chest)[1]) for k in ("Base", "PerFloor", "Most")},
    }


CFG = config()


def foe_level(floor, cfg=CFG):
    return min(60, max(1, math.floor(1 + (floor - 1) * cfg["levelPerFloor"] + 0.5)))


def enemy_at(floor, rng, cfg=CFG, rare_share=0.0):
    rarity = "Rare" if rng.random() < rare_share else "Common"
    e = at.fighter_attr(foe_level(floor, cfg), ENEMY_FRAC, rarity, rng.choice(at.CLASSES), rng.choice(list(at.SPECS)))
    e["hp"] *= cfg["hpShare"]
    return e


def climb(me, level, rng, cfg=CFG, cap=None, fast=True, rare_share=0.0, max_floors=400):
    """One run: (floors won, seconds, the foe levels of the hard floors won, the fast floors won)."""
    cap = cfg["healCap"] if cap is None else cap
    hp, t, hard, quick = me["hp"], 0.0, [], 0
    for f in range(1, max_floors + 1):
        if fast and foe_level(f, cfg) <= level - cfg["fastGap"]:
            quick += 1
            t += FIRST_HIT + cfg["fastRise"]
            continue
        e = enemy_at(f, rng, cfg, rare_share)
        mine, theirs = dps(me, e), dps(e, me)
        kill = e["hp"] / mine
        heal = min(cap * me["hp"], (me["regen"] + min(mine * me["lifesteal"], S["lifesteal"]["perSecondCapOfMaxHp"] * me["hp"])) * kill)
        lost = theirs * kill - heal
        if lost >= hp:
            return f - 1, t + hp / max(1e-9, theirs - heal / kill), hard, quick
        hp = min(me["hp"], hp - lost)
        hard.append(foe_level(f, cfg))
        t += kill + cfg["rise"]
    return max_floors, t, hard, quick


def lead(level, frac=0.7, cls="Warrior"):
    return at.fighter_attr(level, frac, "Common", cls, "balanced", 0.03 if frac > 0.5 else 0.0)


def runs_of(level, rng, n=60, frac=0.7, cfg=CFG):
    return [climb(lead(level, frac, rng.choice(at.CLASSES)), level, rng, cfg) for _ in range(n)]


def chest_sum(n, c):
    return sum(min(c["Most"], c["Base"] + c["PerFloor"] * k) for k in range(1, n + 1))


def paid(run, rule, share, chest, cfg=CFG):
    """(Credits, chests) a run pays, the chest's chance rising with the floor's number. 'builder': every floor pays.
    'research': only the hard floors pay; a fast floor is the free ride to them."""
    floors, _, hard, quick = run
    levels = hard if rule == "research" else [foe_level(f, cfg) for f in range(1, quick + 1)] + hard
    credits = sum(share * CPK * G(lv) for lv in levels)
    first = quick if rule == "research" else 0
    return credits, chest_sum(floors, chest) - chest_sum(first, chest)


def hourly(runs, rule, share, chest):
    per = [paid(r, rule, share, chest) for r in runs]
    secs = sum(r[1] + BETWEEN for r in runs) / len(runs)
    n = 3600 / secs
    return n, n * sum(p[0] for p in per) / len(per), n * sum(p[1] for p in per) / len(per), secs


def ground_credits(level, launch):
    """Credits an hour on a ground (seeds "pace"); at launch the lead farms Lantern Row, whose ladder ends at 9."""
    return S["pace"]["killsPerHour"] * CPK * G(min(level, S["grounds"][0]["to"]) if launch else level)


def report_floors(runs=60, seed=5):
    rng = random.Random(seed)
    print("\n== T1. Floors won by one run, by level and build, with fast floors (median of runs) ==")
    line("level", "class", "frac 0.4", "frac 0.7", "frac 1.0", "min at 0.7", "fast at 0.7", w=12)
    for L in (5, 10, 15, 30, 45, 60):
        for c in at.CLASSES:
            cells, mins, quick = [], 0, 0
            for frac in (0.4, 0.7, 1.0):
                res = sorted(climb(lead(L, frac, c), L, rng) for _ in range(runs))
                med = res[len(res) // 2]
                cells.append(med[0])
                if frac == 0.7:
                    mins, quick = med[1] / 60, med[3]
            line(L if c == "Warrior" else "", c, *cells, f"{mins:.1f}", quick, w=12)


def report_cap(runs=60, seed=6):
    rng = random.Random(seed)
    print("\n== T2. The heal cap: floors won at level 30, on budget, by cap (median) ==")
    line("class", *[f"cap {c:.0%}" for c in (0.0, 0.1, 0.15, 0.25, 1.0)], w=12)
    for c in at.CLASSES:
        row = []
        for cap in (0.0, 0.1, 0.15, 0.25, 1.0):
            res = sorted(climb(lead(30, 0.7, c), 30, rng, cap=cap)[0] for _ in range(runs))
            row.append(res[len(res) // 2])
        line(c, *row, w=12)


def report_pool(runs=200, seed=8):
    rng = random.Random(seed)
    print("\n== T3. The pool: floors won on budget, Commons only against one Rare in four (TR29's pool) ==")
    line("level", "pool", "10% win under", "median", "90% under", w=14)
    for L in (10, 15, 30):
        for name, share in (("Commons", 0.0), ("1 Rare in 4", 0.25)):
            res = sorted(climb(lead(L, 0.7, rng.choice(at.CLASSES)), L, rng, rare_share=share)[0] for _ in range(runs))
            line(L if share == 0 else "", name, res[runs // 10], res[runs // 2], res[9 * runs // 10], w=14)


def report_rewards(rule, share, chest, title, runs=60, seed=9):
    rng = random.Random(seed)
    print(f"\n== {title} ==")
    line("level", "floors", "run min", "fast s", "runs / h", "Cr / h vs Row", "vs own ground", "chests / run", "chests / h", w=13)
    for L in (5, 10, 15, 30, 45, 60):
        rs = runs_of(L, rng, runs)
        n, cr, ch, secs = hourly(rs, rule, share, chest)
        fl = sorted(r[0] for r in rs)[len(rs) // 2]
        fast_s = sum(r[3] for r in rs) / len(rs) * (FIRST_HIT + CFG["fastRise"])
        line(L, fl, f"{secs / 60:.1f}", f"{fast_s:.0f}", f"{n:.0f}", f"{cr / ground_credits(L, True):.0%}",
             f"{cr / ground_credits(L, False):.0%}", f"{ch / n:.2f}", f"{ch:.0f}", w=13)
    print("Cr / h vs Row: the Tower's Credits an hour of runs against Lantern Row's at the same time (launch);"
          " vs own ground: against a ground at the lead's level (when the grounds open).")


def launch_ground_hazard(r, hours_on_ground):
    """Expected Lantern Row chests of rarity r or better in that many hours there (Config.Chests, a player alone)."""
    cfg, kills = chests.config(), chests.rates(1)
    i = chests.RARITIES.index(r)
    oc, ot = cfg["drop"]["Ordinary"]
    ec, et = cfg["drop"]["Elite"]
    first, after = cfg["keeper"]
    better = lambda row: sum(chests.odds(cfg["ladder"], row)[i:])
    per_hour = kills["Pack"] * oc * better(ot) + kills["Elite"] * ec * better(et) + kills["Keeper"] * better(after)
    return per_hour * hours_on_ground + (better(first) if hours_on_ground >= chests.KEEPER_FIRST_AT else 0.0)


def fit(runs=80, seed=10):
    rng = random.Random(seed)
    rs = runs_of(LAUNCH_LEVEL, rng, runs)
    n = hourly(rs, "research", 1.0, {"Base": 0, "PerFloor": 0.01, "Most": 1})[0]
    tower_cr = hourly(rs, "research", 1.0, {"Base": 0, "PerFloor": 0, "Most": 0})[1]
    share = CREDITS_VS_GROUND * ground_credits(LAUNCH_LEVEL, True) / tower_cr
    lo, hi = 0.0, 0.2
    for _ in range(50):
        p = (lo + hi) / 2
        c = hourly(rs, "research", share, {"Base": 0, "PerFloor": p, "Most": 0.5})[2]
        lo, hi = (p, hi) if c < CHESTS_AN_HOUR else (lo, p)
    chest = {"Base": 0, "PerFloor": round(hi, 4), "Most": 0.5}
    c = hourly(rs, "research", share, chest)[2]
    q = {"Uncommon": UNCOMMON_OR_BETTER}
    for r in ("Rare", "Epic", "Legendary"):
        lo_h, hi_h = chests.TARGET[r]
        T = (lo_h + hi_h) / 2
        q[r] = (math.log(2) - launch_ground_hazard(r, 1 + (1 - TOWER_SHARE) * (T - 1))) / (c * TOWER_SHARE * (T - 1))
    row = [1 - q["Uncommon"], q["Uncommon"] - q["Rare"], q["Rare"] - q["Epic"], q["Epic"] - q["Legendary"], q["Legendary"]]
    return round(share, 2), chest, [round(100 * x, 2) for x in row], c, n


def first_at(r, row, c, s):
    """Median hours of play to a first chest of rarity r or better at launch, the Tower taking share s after hour 1."""
    i = chests.RARITIES.index(r)
    q = sum(row[i:]) / 100
    lo, hi = 0.0, 2000.0
    for _ in range(60):
        T = (lo + hi) / 2
        h = launch_ground_hazard(r, min(T, 1) + (1 - s) * max(0, T - 1)) + c * q * s * max(0, T - 1)
        lo, hi = (T, hi) if h < math.log(2) else (lo, T)
    return hi


def report_fit():
    share, chest, row, c, n = fit()
    print("\n== T5. Research's fit (TR29) ==")
    print(f"Credits.Share {share} (the Tower's Credits an hour at level {LAUNCH_LEVEL}, on budget, half Lantern Row's);"
          f" Chest PerFloor {chest['PerFloor']}, Most {chest['Most']}, on hard floors only;"
          f" {c:.1f} chests an hour of runs ({n:.0f} runs).")
    print(f"The Tower's chest row (Common, Uncommon, Rare, Epic, Legendary, %): {row}")
    line("first of", "Tower 1/4", "Tower 1/2", "all Tower", "the window", w=14)
    for r in ("Rare", "Epic", "Legendary"):
        lo, hi = chests.TARGET[r]
        line(r, *[f"{first_at(r, row, c, s):.1f} h" for s in (0.25, 0.5, 1.0)], f"{lo:g} to {hi:g} h", w=14)
    report_rewards("research", share, chest, "T6. The rewards on research's fit")


if __name__ == "__main__":
    at.sim.ROSTER.extend(at.sim.roster())
    at.fit_profiles()
    print("Tower. Config.Tower:", {k: v for k, v in CFG.items()}, "| enemyFrac", ENEMY_FRAC)
    report_floors()
    report_cap()
    report_pool()
    report_rewards("builder", CFG["share"], CFG["chest"], "T4. The rewards on today's Config (the builder's seeds, TR29)")
    report_fit()
