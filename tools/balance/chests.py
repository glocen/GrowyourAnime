"""Chests: the rarities' pace (docs/design.md, "Chests"; docs/balance.md, "Chests"; TR27's seeds to fit).

Run:  py tools/balance/chests.py          (from the project folder)
Reads src/shared/Config/Chests.luau, the home of every chest number, and sim.py's laps of Lantern Row.
A model, not a measurement of play:
- The kill rates are Lantern Row's laps (sim.py, section 11: packs, the shared elite, each player's keeper), taken as
  alike on every ground. The climb is the pace table (seeds "grounds"), a player on budget.
- A keeper's first win comes a quarter of the way through its ground (a guess), its Keeper's Chest then, an Elite
  Chest at every win after.
- The first chest of a rarity "or better" is what a player meets. Each kind of fall is a Poisson stream, so the chance
  of none by T is exp(-H(T)), H the expected count by T: the median first is where H = ln 2.
"""
import math, random, re, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import sim  # noqa: E402
from sim import S, G, line  # noqa: E402

RARITIES = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
TARGET = {"Uncommon": (0.0, 1.0), "Rare": (3.0, 4.0), "Epic": (10.0, 15.0), "Legendary": (35.0, 45.0)}  # hours
KEEPER_FIRST_AT = 0.25   # of the way through a ground (a guess)


def config():
    src = sim.lua("src/shared/Config/Chests.luau")
    drop = {m[1]: (float(m[2]), int(m[3])) for m in re.finditer(r"(\w+) = \{ Chance = ([\d.]+), Tier = (\d+) \}", src)}
    keeper = re.search(r"Keeper = \{ First = (\d+), After = (\d+) \}", src)
    body = src[src.index("Ladder = {"):src.index("ClassLean")]
    ladder = [[float(x) for x in m[1].split(",")] for m in re.finditer(r"\{ ([\d., ]+) \}", body)]
    salvage = {m[1]: float(m[2]) for m in re.finditer(r"(\w+) = ([\d.]+)", src[src.index("Salvage = {"):src.index("Bag =")])}
    return {"drop": drop, "keeper": (int(keeper[1]), int(keeper[2])), "ladder": ladder, "salvage": salvage,
            "sure": int(re.search(r"Sure = (\d+)", src)[1])}


def rates(players=1, runs=40):
    """Kills an hour per player on Lantern Row's laps, at the seeds' cooldowns, the keeper walked back to."""
    gm = sim.game()
    seeds = gm["back"] or {"Elite": 120, "Keeper": 300}
    rng = random.Random(7 + players)
    rows = []
    for _ in range(runs):
        rows += sim.laps(players, 1, seeds["Elite"], seeds["Keeper"], gm, rng)
    return {k: sum(r[k] for r in rows) / len(rows) for k in ("Pack", "Elite", "Keeper")}


def odds(ladder, step):
    row = ladder[min(max(step, 1), len(ladder)) - 1]
    total = sum(row)
    return [w / total for w in row]


def streams(cfg, kills):
    """(start h, end h, chests an hour, step) for every kind of chest along the climb, and the one-offs (time, step)."""
    out, once = [], [(0.0, 1)]   # the account's third kill: a Shade's chest of Lantern Row
    t = 0.0
    for g in S["grounds"]:
        a, b = t, t + g["paceHours"]
        oc, ot = cfg["drop"]["Ordinary"]
        ec, et = cfg["drop"]["Elite"]
        first, after = cfg["keeper"]
        out.append((a, b, kills["Pack"] * oc, g["id"] + ot - 1))
        out.append((a, b, kills["Elite"] * ec, g["id"] + et - 1))
        k0 = a + KEEPER_FIRST_AT * (b - a)
        once.append((k0, g["id"] + first - 1))
        out.append((k0, b, kills["Keeper"], g["id"] + after - 1))
        t = b
    return out, once


def hazard(cfg, kills, r, T):
    """Expected chests of rarity r or better by hour T."""
    i = RARITIES.index(r)
    st, once = streams(cfg, kills)
    h = sum(max(0.0, min(b, T) - a) * n * sum(odds(cfg["ladder"], s)[i:]) for a, b, n, s in st)
    return h + sum(sum(odds(cfg["ladder"], s)[i:]) for t0, s in once if t0 <= T)


def first(cfg, kills, r, q=0.5):
    """Hours until a player has met rarity r or better with chance q."""
    want = -math.log(1 - q)
    lo, hi = 0.0, 400.0
    if hazard(cfg, kills, r, hi) < want:
        return float("inf")
    for _ in range(50):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if hazard(cfg, kills, r, mid) < want else (lo, mid)
    return hi


def report(cfg, title):
    end = sum(g["paceHours"] for g in S["grounds"])
    print(f"\n== {title} ==")
    for players in (1, 8):
        kills = rates(players)
        st, _ = streams(cfg, kills)
        per_h = kills["Pack"] * cfg["drop"]["Ordinary"][0] + kills["Elite"] * cfg["drop"]["Elite"][0] + kills["Keeper"]
        print(f"{players} player(s): {kills['Pack']:.0f} pack, {kills['Elite']:.1f} elite, {kills['Keeper']:.1f} keeper kills an hour;"
              f" about {per_h:.0f} chests an hour, {per_h * end:,.0f} over the climb to level 60 ({end} h).")
        line("rarity or better", "10% have one", "half", "90%", "the target", "", w=18)
        for r in RARITIES[1:]:
            lo, hi = TARGET[r]
            mid = first(cfg, kills, r)
            ok = "yes" if lo <= mid <= hi else "no"
            line(r, f"{first(cfg, kills, r, 0.1):.1f} h", f"{mid:.1f} h", f"{first(cfg, kills, r, 0.9):.1f} h",
                 f"{lo:g} to {hi:g} h", ok, w=18)
    kills = rates(1)
    print("Each ground's mix, a player alone (a share of its chests, every source):")
    line("ground", *RARITIES, "salvage / income", w=14)
    t = 0.0
    for g in S["grounds"]:
        a, b = t, t + g["paceHours"]
        mid = (a + b) / 2
        rows = [(n, s) for x0, x1, n, s in streams(cfg, kills)[0] if x0 <= mid < x1]
        total = sum(n for n, _ in rows)
        mix = [sum(n * odds(cfg["ladder"], s)[i] for n, s in rows) / total for i in range(len(RARITIES))]
        salv = total * sum(m * cfg["salvage"][r] for m, r in zip(mix, RARITIES))
        income = (kills["Pack"] + kills["Elite"] + kills["Keeper"]) * S["pace"]["creditsPerKillPerG"]
        line(g["name"], *[f"{m:.1%}" for m in mix], f"{salv / income:.0%}", w=14)
        t = b
    print("Salvage / income: Credits a G from salvaging every chest's item, against a kill's Credits (seeds \"pace\", the"
          " packs' rate: elites and keepers pay more, so this is an upper bound).")


# Where each rarity starts on the ladder, and how fast its share grows a row: research's shape, so each one comes
# mostly from its grounds (docs/design.md, "Chests"). Row k is read by ground k's packs, ground k-1's elites and
# keepers after their first win, and ground k-2's keeper's first win.
SHAPE = {"Uncommon": (1, 1.4), "Rare": (3, 2.0), "Epic": (5, 2.2), "Legendary": (7, 2.5)}


def fitted(cfg, shape=SHAPE, cap=0.95):
    """A ladder whose row k gives rarity r or better with q_r(k) = A_r x growth_r^(k - start_r) from its start, none
    before, each A_r solved so the median first meets the middle of its window, a player alone. Common is the rest."""
    kills = rates(1)
    rows = len(cfg["ladder"])
    q = {}
    for r in ("Legendary", "Epic", "Rare", "Uncommon"):
        lo, hi = TARGET[r]
        start, growth = shape[r]
        want = (lo + hi) / 2 if r != "Uncommon" else 0.25
        a_lo, a_hi = 1e-7, 1.0
        for _ in range(60):
            a = math.sqrt(a_lo * a_hi)
            q[r] = [min(cap, a * growth ** (k + 1 - start)) if k + 1 >= start else 0.0 for k in range(rows)]
            a_lo, a_hi = (a, a_hi) if first(dict(cfg, ladder=_ladder(q, rows)), kills, r) > want else (a_lo, a)
        q[r] = [min(cap, a_hi * growth ** (k + 1 - start)) if k + 1 >= start else 0.0 for k in range(rows)]
    return _ladder(q, rows)


def _ladder(q, rows):
    out = []
    order = ["Uncommon", "Rare", "Epic", "Legendary"]
    for k in range(rows):
        above = [q.get(r, [0] * rows)[k] for r in order]
        for i in range(len(above) - 2, -1, -1):           # or-better shares never fall going down the ladder
            above[i] = max(above[i], above[i + 1])
        shares = [1 - above[0]] + [above[i] - (above[i + 1] if i + 1 < len(above) else 0) for i in range(len(above))]
        out.append([round(100 * s, 2) for s in shares])
    return out


if __name__ == "__main__":
    sim.ROSTER.extend(sim.roster())
    cfg = config()
    print("Chests. Seeds: src/shared/Config/Chests.luau. A model of a player on budget; not a measurement of play.")
    report(cfg, "C1. Today's seeds (the builder's, TR27)")
    if "--fit" in sys.argv:
        lad = fitted(cfg)
        print("\nFitted ladder (research's shape, SHAPE):")
        for k, row in enumerate(lad, 1):
            print(f"  {k}: {row}")
        report(dict(cfg, ladder=lad), "C2. The fit")
