"""Balance simulator for the model in docs/balance.md.

Run:  py tools/balance/sim.py          (from the project folder)
Reads tools/balance/seeds.json and the table in docs/roster.md.
Prints a report. Nothing here is a measurement of play: it tests the
structure of the math and the seed numbers against each other.
"""
import json, random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
S = json.loads((ROOT / "tools/balance/seeds.json").read_text(encoding="utf-8"))
RARITIES = ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical"]
ROSTER = []


def G(level):
    g = S["growth"]
    return 1 + g["a"] * (level - 1) + g["b"] * (level - 1) ** 2


def roster():
    rows = []
    for text in (ROOT / "docs/roster.md").read_text(encoding="utf-8").splitlines():
        cells = [c.strip() for c in text.strip().strip("|").split("|")]
        if len(cells) == 12 and cells[2] in RARITIES:
            rows.append(dict(id=cells[0], name=cells[1], rarity=cells[2], type=cells[3],
                             cls=cells[4], element=cells[5], zone=int(cells[6]), apt=int(cells[7])))
    return rows


# ---------------------------------------------------------------- builds

SPECS = {
    # units: where the choosable stat points (emblems and jewels) go. ratings: split of rating points.
    "balanced": dict(units=dict(hp=1 / 3, atk=1 / 3, df=1 / 3), ratings=None, critdmg=0.5, guard=0.5),
    "glass":    dict(units=dict(atk=1.0), ratings=dict(crit=0.55, pen=0.30, hit=0.15), critdmg=1.0, guard=0.0),
    "bruiser":  dict(units=dict(hp=0.6, df=0.4), ratings=dict(block=0.35, critres=0.25, dodge=0.15, eres=0.25), critdmg=0.0, guard=1.0),
    "element":  dict(units=dict(elem=1.0), ratings=dict(hit=0.4, pen=0.2, dodge=0.2, eres=0.2), critdmg=0.0, guard=0.5),
}


def build(level, ground, frac, rarity="Common", cls="Warrior", spec="balanced"):
    """Stats of one fighter. ground is 1..6; frac is the share of that ground's available build it has."""
    sh, base, cm = S["shares"], S["base"], S["classMult"][cls]
    av = S["available"][ground - 1]
    tier_level = S["grounds"][ground - 1]["to"]
    gl, gt, g60 = G(level), G(min(tier_level, level + 9)), G(S["growth"]["maxLevel"])
    unit = {k: base[k] / sh["base"] for k in base}          # one share point of a stat, per G
    stars = round(av["stars"] * frac)
    st = {}
    for k in ("hp", "atk", "def"):
        own = base[k] * S["rarityBase"][rarity] * cm[k] * gl
        own *= 1 + S["starPctOfBase"] * stars                # stars: a percent of the fighter's own base only
        gear = sh["gear"] * unit[k] * S["gearRarity"][av["gear"]] * gt * frac
        forge = gear * S["forge"]["fullBonusOfGearBase"] * av["forge"] / S["forge"]["maxRank"]
        res = sh["research"] * unit[k] * av["research"] * frac * g60
        st[k] = own + gear + forge + res
    sp = SPECS[spec]
    # A choosable point spent on one stat alone buys three times that stat: it gives up the other two.
    # Defence and elemental attack have their own price, set so a point of each is worth about a point of the others.
    ch = S["choosable"]
    choos = (sh["emblems"] * av["emblems"] + sh["jewels"] * av["jewels"]) * frac * gt * ch["singleStatFactor"]
    solo = len(sp["units"]) < 3
    st["hp"] += choos * sp["units"].get("hp", 0) * unit["hp"]
    st["atk"] += choos * sp["units"].get("atk", 0) * unit["atk"]
    st["def"] += choos * sp["units"].get("df", 0) * unit["def"] * (ch["defFactor"] if solo else 1)
    st["elem"] = choos * sp["units"].get("elem", 0) * unit["atk"] * ch["elemFactor"]
    st["critguard"] = S["crit"]["guardMaxFromItems"] * sp["guard"] * av["jewels"] * frac
    r = S["ratings"]
    acquired = (0.4 * S["gearRarity"][av["gear"]] + 0.35 * av["emblems"] + 0.25 * av["jewels"]) * frac
    pts = r["fullBuildPointsPerG"] * gt * acquired
    split = sp["ratings"] or {k: 1 / len(r["list"]) for k in r["list"]}
    for k in r["list"]:
        st[k] = pts * split.get(k, 0)
    st["critdmg"] = S["crit"]["baseDamage"] + S["crit"]["maxFromItems"] * sp["critdmg"] * av["jewels"] * frac
    st["level"] = level
    st["lifesteal"] = 0.0
    return st


def enemy(level, hp=0.0, atk=0.0, keeper=False):
    e = dict(hp=hp, atk=atk, elem=0.0, level=level, critdmg=0.5, critguard=0.0, lifesteal=0.0)
    e["def"] = S["enemy"]["def"] * G(level)
    for k in S["ratings"]["list"]:
        e[k] = 0.0
    if keeper:
        for k, v in S["enemy"]["keeperRatingsPerG"].items():
            e[k] = v * G(level)
    return e


# ---------------------------------------------------------------- the hit

def rate(cap, mine, theirs, level):
    k = S["ratings"]["K"] * G(level)
    return cap * mine / (mine + theirs + k) if mine > 0 else 0.0


def coef_per_second():
    a = S["attack"]
    return sum(a["comboCoefs"]) / a["comboSeconds"] + a["signatureCoef"] / a["signatureEvery"]


def dps(att, dfn, type_rel=0, bonus=0.0, reduce=0.0):
    """Expected damage a second. type_rel: +1 the attacker has the type advantage, -1 the disadvantage."""
    c, b = S["ratings"]["caps"], S["buckets"]
    hit = 1 - rate(c["dodge"], dfn["dodge"], att["hit"], dfn["level"])
    pen = rate(c["pen"], att["pen"], 0, dfn["level"])
    d = dfn["def"] * (1 - pen)
    mit = min(S["defense"]["cap"], d / (d + S["defense"]["K"] * G(att["level"])))
    pcrit = min(c["crit"], c["critFloor"] + rate(c["critSpan"], att["crit"], dfn["critres"], dfn["level"]))
    pblock = rate(c["block"], dfn["block"], att["hit"], att["level"])
    b0 = min(b["bonusCap"], bonus + (b["typeAdvantage"] if type_rel > 0 else 0))
    r0 = min(b["reduceCap"], reduce + (b["typeDisadvantage"] if type_rel < 0 else 0))
    # A critical multiplies outside the bucket, with no ceiling (the director, 2026-11-15, night).
    off = (1 + b0) * (1 + pcrit * max(0.0, att["critdmg"] - dfn["critguard"]))
    dfm = 1 - min(b["reduceCap"], r0 + pblock * b["blockReduce"])
    phys = att["atk"] * (1 - mit) * off * dfm
    eres = rate(c["eres"], dfn["eres"], 0, att["level"])
    elem = att["elem"] * (1 - eres) * (1 + b0) * dfm
    return hit * (phys + elem) * coef_per_second()


def duel(a, b, hp_factor=1.0, rel=0):
    """Seconds for a to beat b, and for b to beat a. Lifesteal counts as slower loss."""
    da, db = dps(a, b, rel), dps(b, a, -rel)
    cap = S["lifesteal"]["perSecondCapOfMaxHp"]
    heal_a = min(da * a["lifesteal"], cap * a["hp"])
    heal_b = min(db * b["lifesteal"], cap * b["hp"])
    ta = b["hp"] * hp_factor / max(1e-9, da - heal_b)
    tb = a["hp"] * hp_factor / max(1e-9, db - heal_a)
    return ta, tb


def mark(ta, tb):
    return "=" if abs(ta - tb) < 0.02 * ta else ("W" if ta < tb else "L")


# ---------------------------------------------------------------- reports

def line(*cells, w=13):
    print("".join(str(c).ljust(w) for c in cells))


def report_growth():
    print("\n== 1. Growth and where power comes from ==")
    line("level", "G(level)")
    for lv in (1, 10, 20, 30, 40, 50, 60):
        line(lv, f"{G(lv):.2f}")
    full = build(60, 6, 1.0)
    naked = build(60, 6, 0.0)
    print("\nFull launch build against a bare fighter, same level 60, Common Warrior, balanced:")
    for k in ("hp", "atk", "def"):
        line(k, f"bare {naked[k]:.0f}", f"full {full[k]:.0f}", f"x{full[k] / naked[k]:.2f}")
    print("\nRarity, full build, attack: " + ", ".join(
        f"{r} x{build(60, 6, 1.0, r)['atk'] / full['atk']:.3f}" for r in RARITIES))
    half_myth = build(60, 6, 0.5, "Mythical")
    print(f"A Common at a full build has {full['atk']:.0f} attack; a Mythical at half a build has {half_myth['atk']:.0f}.")
    sh = S["shares"]
    add = sum(v for k, v in sh.items() if k != "base") / sh["base"]
    mult = 1.0
    for k, v in sh.items():
        if k != "base":
            mult *= 1 + v / sh["base"]
    print(f"\nThe same sources, added: x{1 + add:.2f}. If each multiplied the last: x{mult:.2f}.")


def report_extremes():
    print("\n== 2. The ceilings: the most any build can do ==")
    ref_e = enemy(60)
    bare = dps(build(60, 6, 0.0), ref_e)
    line("build", "dps", "vs bare", w=32)
    cases = (("bare Common", dict(frac=0.0)), ("on budget Common", dict(frac=S["onBudget"])),
             ("full Common balanced", dict(frac=1.0)), ("full Common glass", dict(frac=1.0, spec="glass")),
             ("full Mythical glass", dict(frac=1.0, spec="glass", rarity="Mythical")),
             ("full Mythical Assassin glass", dict(frac=1.0, spec="glass", rarity="Mythical", cls="Assassin")))
    for name, kw in cases:
        f = kw.pop("frac")
        d = dps(build(60, 6, f, **kw), ref_e)
        line(name, f"{d:.0f}", f"x{d / bare:.2f}", w=32)
    best = build(60, 6, 1.0, "Mythical", "Assassin", "glass")
    top = dps(best, ref_e, +1, bonus=0.5)
    print(f"With the type advantage and the largest effect bonus (+50%) on top: x{top / bare:.2f} of a bare Common.")
    b = S["buckets"]
    print(f"Hard ceiling of one hit over its plain value: x{1 + b['bonusCap']:.1f} (the bonus bucket's cap), before a critical, which has none. "
          f"Floor: x{1 - b['reduceCap']:.2f} after the defender's bucket, then mitigation's cap of {S['defense']['cap']:.0%}.")
    caps = S["earnBucketCaps"]
    print("Earning rates, the most every bonus together can reach: " +
          ", ".join(f"{k} x{1 + v:.2f}" for k, v in caps.items()) + ".")


def tune_enemies():
    """Author enemy health and attack from the on-budget build, so the targets hold by construction."""
    out = []
    e = S["enemy"]
    for g in S["grounds"]:
        mid, end = (g["from"] + g["to"]) // 2, g["to"]
        me_mid, me_end = build(mid, g["id"], S["onBudget"]), build(end, g["id"], S["onBudget"])
        ttk = dict(ordinary=e["ttk"]["ordinary"], elite=e["ttk"]["elite"], keeper=e["ttk"]["keeperByGround"][g["id"] - 1])
        loss = dict(ordinary=e["ordinaryHpLossPerKill"], elite=e["eliteHpLoss"], keeper=e["keeperHpLoss"])
        row = dict(g=g["id"])
        for kind, lv, me in (("ordinary", mid, me_mid), ("elite", mid, me_mid), ("keeper", end, me_end)):
            en = enemy(lv, keeper=(kind == "keeper"))
            mine = dps(me, en)
            hp = mine * ttk[kind]
            ls = S["lifesteal"]
            heal = min(mine * ls["typical"] * S["onBudget"], ls["perSecondCapOfMaxHp"] * me["hp"])
            want = me["hp"] * loss[kind] / ttk[kind] + heal    # the enemy dps wanted, typical lifesteal counted
            en["atk"] = 1.0
            row[kind] = enemy(lv, hp, want / dps(en, me), keeper=(kind == "keeper"))
            row[kind]["at"] = lv
        out.append(row)
    return out


def scaled(e, level):
    """The same enemy authored at another level of its ground: health and attack follow the growth curve."""
    k = G(level) / G(e["at"])
    out = dict(e)
    out.update(hp=e["hp"] * k, atk=e["atk"] * k, level=level)
    out["def"] = S["enemy"]["def"] * G(level)
    return out


def report_ttk(enemies):
    print("\n== 3. Fights against the game, ground by ground ==")
    print("Enemy health and attack are set so a Common Warrior on budget meets the targets. The rest is what follows.")
    line("ground", "ordinary hp", "keeper hp", "bare", "on budget", "full", "adv.", "disadv.", w=12)
    for row, g in zip(enemies, S["grounds"]):
        mid = (g["from"] + g["to"]) // 2
        o = row["ordinary"]

        def t(f, rel=0):
            return o["hp"] / dps(build(mid, g["id"], f), o, rel)
        line(g["id"], f"{o['hp']:.0f}", f"{row['keeper']['hp']:.0f}", f"{t(0):.1f}s", f"{t(S['onBudget']):.1f}s",
             f"{t(1):.1f}s", f"{t(S['onBudget'], 1):.1f}s", f"{t(S['onBudget'], -1):.1f}s", w=12)
    print("\nThe keeper: seconds to beat it, and health left at the end (below 0 means the lead falls first).")
    line("ground", "bare", "half", "on budget", "full", "on b. adv.", "on b. disadv.", w=16)
    for row, g in zip(enemies, S["grounds"]):
        k = row["keeper"]
        cells = []
        for f, rel in ((0, 0), (0.5, 0), (S["onBudget"], 0), (1, 0), (S["onBudget"], 1), (S["onBudget"], -1)):
            me = build(g["to"], g["id"], f)
            me["lifesteal"] = S["lifesteal"]["typical"] * f
            ta, tb = duel(me, k, rel=rel)
            cells.append(f"{ta:.0f}s {1 - ta / tb:+.0%}")
        line(g["id"], *cells, w=16)
    print("\nThe same keeper by class, on budget, no type edge, no lifesteal (a Healer alone heals itself a little every 10 s):")
    line("ground", *S["classMult"].keys(), w=16)
    for row, g in zip(enemies, S["grounds"]):
        k = row["keeper"]
        cells = []
        for cls in S["classMult"]:
            me = build(g["to"], g["id"], S["onBudget"], cls=cls)
            ta = k["hp"] / dps(me, k)
            lost = dps(k, me) * ta - (S["healerSelfHealPer10s"] * me["hp"] * ta / 10 if cls == "Healer" else 0)
            cells.append(f"{ta:.0f}s {1 - lost / me['hp']:+.0%}")
        line(g["id"], *cells, w=16)
    print("\nWalking into a new ground: the lead that beat the last keeper, in the last ground's build, against the new ground's first enemies.")
    for row, g in list(zip(enemies, S["grounds"]))[1:]:
        prev = S["grounds"][g["id"] - 2]
        me = build(g["from"], prev["id"], S["onBudget"])
        o = scaled(row["ordinary"], g["from"])
        secs = o["hp"] / dps(me, o)
        last = scaled(row["ordinary"], g["to"])
        me2 = build(g["to"], g["id"], S["onBudget"])
        print(f"  ground {g['id']}: first enemies {secs:.1f}s a kill, {dps(o, me) * secs / me['hp']:.0%} of health lost; "
              f"last enemies in this ground's build {last['hp'] / dps(me2, last):.1f}s")


def report_pvp():
    print("\n== 4. Champion against champion (the Clash Grounds) ==")
    f = S["clash"]["hpFactor"]
    names = list(SPECS)
    print(f"Legendary Warriors at a full build, arena health x{f}. Each cell: seconds for the row to beat the column; W, L or = for the row.")
    line("", *names, w=16)
    for a in names:
        cells = []
        for b in names:
            ta, tb = duel(build(60, 6, 1, "Legendary", spec=a), build(60, 6, 1, "Legendary", spec=b), f)
            cells.append(f"{ta:.0f}s {mark(ta, tb)}")
        line(a, *cells, w=16)
    print("Balanced Legendaries by class (row against column):")
    cl = list(S["classMult"])
    line("", *cl, w=16)
    for a in cl:
        cells = []
        for b in cl:
            ta, tb = duel(build(60, 6, 1, "Legendary", a), build(60, 6, 1, "Legendary", b), f)
            cells.append(f"{ta:.0f}s {mark(ta, tb)}")
        line(a, *cells, w=16)
    ta, tb = duel(build(60, 6, 1, "Legendary"), build(60, 6, 1, "Legendary"), f, rel=1)
    print(f"Type advantage alone, equal builds: {ta:.0f}s against {tb:.0f}s.")
    ta, tb = duel(build(60, 6, 1, "Common"), build(60, 6, 0.5, "Mythical"), f)
    print(f"A full Common against a half-built Mythical: {ta:.0f}s against {tb:.0f}s.")
    ta, tb = duel(build(60, 6, 1, "Mythical"), build(60, 6, 1, "Common"), f)
    print(f"A full Mythical against a full Common: {ta:.0f}s against {tb:.0f}s.")


def pool(ground, grade, lift=0.0):
    """Chance of each Voidkin from one shard of this ground and grade."""
    here = [v for v in ROSTER if v["zone"] <= ground]
    have = [r for r in RARITIES if any(v["rarity"] == r for v in here)]
    # Tiers the pool lacks are dropped, and the rest keep their proportions.
    w = {r: float(S["shards"]["pools"][grade][r]) for r in have}
    live = [r for r in have if w[r] > 0]
    for r in (live[-2:] if len(live) > 2 else live[-1:] if len(live) == 2 else []):
        w[r] *= 1 + lift
    total = sum(w.values())
    out = {}
    for r in live:
        group = [v for v in here if v["rarity"] == r]
        # Fighters of this ground and the one before it are featured: more likely than older ones of their tier.
        fw = {v["id"]: (S["shards"]["featuredWeight"] if v["zone"] >= ground - 1 else 1) for v in group}
        for v in group:
            out[v["id"]] = w[r] / total * fw[v["id"]] / sum(fw.values())
    return out


def report_pools():
    print("\n== 5. What a shard holds, by ground ==")
    by = {v["id"]: v for v in ROSTER}
    first = dict(Standard=1, Enriched=S["shards"]["enrichedFromGround"], Prismatic=S["shards"]["prismaticFromGround"])
    for g in S["grounds"]:
        for grade in ("Standard", "Enriched", "Prismatic"):
            if g["id"] < first[grade]:
                continue
            p = pool(g["id"], grade)
            tiers = {}
            for vid, c in p.items():
                tiers[by[vid]["rarity"]] = tiers.get(by[vid]["rarity"], 0) + c
            top = max(p, key=lambda v: (RARITIES.index(by[v]["rarity"]), p[v]))
            print(f"  ground {g['id']} {grade:<10}" + "  ".join(f"{r[:3]} {c:.0%}" for r, c in tiers.items() if c > 0)
                  + f"   top: {by[top]['name']} {p[top]:.1%}")


def ground_on_day(hours):
    t = 0.0
    for g in S["grounds"]:
        t += g["paceHours"]
        if hours < t:
            return g["id"]
    return 6


def report_ownership(n=1500):
    print("\n== 6. What players own after 7, 30 and 90 days ==")
    print("Assumes the pace table, the drop rates in the seeds, and that every shard found gets broken.")
    rng = random.Random(11)
    by = {v["id"]: v for v in ROSTER}
    pools = {(g, gr): pool(g, gr) for g in range(1, 7) for gr in S["shards"]["pools"]}
    need = {r: sum(c) for r, c in S["shards"]["starCopies"].items()}
    for pname, pr in S["profiles"].items():
        snaps = {7: [], 30: [], 90: []}
        for _ in range(n):
            own = {rng.choice(["rook", "kirra", "pip"]): 1, "watt": 1}
            carry = {"Standard": 0.0, "Enriched": 0.0, "Prismatic": 0.0}
            for day in range(1, 91):
                g = ground_on_day((day - 0.5) * pr["hoursPerDay"])
                carry["Standard"] += S["shards"]["perHour"]["Standard"] * pr["hoursPerDay"]
                carry["Enriched"] += S["shards"]["perHour"]["Enriched"] * pr["hoursPerDay"] if g >= S["shards"]["enrichedFromGround"] else 0
                carry["Prismatic"] += pr["prismaticPerDay"] if g >= S["shards"]["prismaticFromGround"] else 0
                for grade in carry:
                    while carry[grade] >= 1:
                        carry[grade] -= 1
                        p = pools[(g, grade)]
                        vid = rng.choices(list(p), weights=list(p.values()))[0]
                        own[vid] = own.get(vid, 0) + 1
                if day in snaps:
                    snaps[day].append((g, dict(own)))
        print(f"\n  {pname}: {pr['hoursPerDay']} h a day")
        line("  day", "ground", f"owned/{len(ROSTER)}", "5 types", "5 classes", "Epic+", "a Legend.", "a Mythical", "7-star", w=12)
        for day, rows in snaps.items():
            m = len(rows)

            def avg(fn):
                return sum(fn(o) for _, o in rows) / m
            line(f"  {day}", f"{sum(g for g, _ in rows) / m:.1f}", f"{avg(len):.1f}",
                 f"{avg(lambda o: len({by[v]['type'] for v in o}) == 5):.0%}",
                 f"{avg(lambda o: len({by[v]['cls'] for v in o}) == 5):.0%}",
                 f"{avg(lambda o: sum(RARITIES.index(by[v]['rarity']) >= 3 for v in o)):.1f}",
                 f"{avg(lambda o: any(by[v]['rarity'] == 'Legendary' for v in o)):.0%}",
                 f"{avg(lambda o: any(by[v]['rarity'] == 'Mythical' for v in o)):.0%}",
                 f"{avg(lambda o: sum(c - 1 >= need[by[v]["rarity"]] for v, c in o.items())):.1f}", w=12)


def report_energy():
    print("\n== 7. Electricity before TR18 (section 14 replaces it once built) ==")
    sh, bays = S["shards"], S["bays"]
    line("ground", "per min", "factor", *[f"{p} cover" for p in S["profiles"]], *[f"{p} chamber" for p in S["profiles"]], w=15)
    r = S["rift"]
    online_speed = 1 + (r["speed"] - 1) * r["seconds"] / (r["everyMinutes"] * 60)
    for i, g in enumerate(S["grounds"]):
        mid = (g["from"] + g["to"]) // 2
        here = [v for v in ROSTER if v["zone"] <= g["id"]]
        apt = sum(sorted((v["apt"] for v in here), reverse=True)[:bays["workersByGround"][i]]) * 0.85
        rate_min = apt * bays["perMinutePerAptitude"] * (1 + bays["perLevel"] * (mid * 0.8 - 1))
        cover, busy = [], []
        for pr in S["profiles"].values():
            online = pr["hoursPerDay"]
            offline = min(24 - online, pr["sessions"] * bays["batteryHoursByGround"][i])
            supply = rate_min * 60 * (online + offline)
            n = dict(Standard=sh["perHour"]["Standard"] * online,
                     Enriched=sh["perHour"]["Enriched"] * online if g["id"] >= sh["enrichedFromGround"] else 0,
                     Prismatic=pr["prismaticPerDay"] if g["id"] >= sh["prismaticFromGround"] else 0)
            demand = sum(n[k] * sh["energy"][k] for k in n) * sh["regionFactor"][i]
            work = sum(n[k] * sh["breakSeconds"][k] for k in n)
            capacity = bays["chambersByGround"][i] * 3600 * (online * online_speed + (24 - online))
            cover.append(f"x{supply / demand:.2f}")
            busy.append(f"{work / capacity:.0%}")
        line(g["id"], f"{rate_min:.1f}", sh["regionFactor"][i], *cover, *busy, w=15)
    print(f"The Rift, for a player online all the time: x{online_speed:.2f} Breaker speed on average.")
    print("\nLuck at its cap (Breaker tuning; infusion is voltage since 2026-11-15 and leaves the odds alone).")
    by = {v["id"]: v for v in ROSTER}
    line("shard", "top tier odds", w=22)
    for gid, grade in ((3, "Standard"), (6, "Standard"), (4, "Enriched"), (6, "Enriched"), (4, "Prismatic"), (6, "Prismatic")):
        p0, p1 = pool(gid, grade), pool(gid, grade, S["luck"]["cap"])
        top = max(p0, key=lambda v: RARITIES.index(by[v]["rarity"]))
        tr = by[top]["rarity"]
        s0 = sum(c for v, c in p0.items() if by[v]["rarity"] == tr)
        s1 = sum(c for v, c in p1.items() if by[v]["rarity"] == tr)
        line(f"g{gid} {grade}", f"{tr[:3]} {s0:.1%} to {s1:.1%} at cap", w=22)


def report_pace():
    print("\n== 8. Pace: how long the launch lasts, and what things should cost ==")
    p = S["pace"]
    total = 0.0
    line("ground", "hours", "sum", "kills/level", "credits/h", "forge rank", *[f"{k} day" for k in S["profiles"]], w=12)
    for g in S["grounds"]:
        total += g["paceHours"]
        mid = (g["from"] + g["to"]) // 2
        levels = g["to"] - g["from"] + 1
        income = p["killsPerHour"] * p["creditsPerKillPerG"] * G(mid)
        rank = income * g["paceHours"] * p["forgeShareOfIncome"] / (14 * S["forge"]["ranksPerGround"])
        line(g["id"], g["paceHours"], total, f"{g['paceHours'] * p['killsPerHour'] / levels:.0f}", f"{income:.0f}",
             f"{rank:.0f}", *[f"{total / pr['hoursPerDay']:.0f}" for pr in S["profiles"].values()], w=12)
    c = S["clash"]
    print("\nClash reward by strength ratio (the beaten champion over the winner): " +
          ", ".join(f"{x} pays x{max(c['ratioMin'], min(c['ratioMax'], x)):.1f}" for x in (0.1, 0.5, 1.0, 1.5, 3.0)))


# ---------------------------------------------------------------- health carries (TR12)

def lua(path):
    return (ROOT / path).read_text(encoding="utf-8")


def game():
    """The game's own numbers, read from src/shared/Config (their home), so the run follows every tune."""
    import re
    en = lua("src/shared/Config/Enemies.luau")
    kinds = {}
    for kind in ("Ordinary", "Elite"):
        m = re.search(kind + r" = \{ Health = ([\d.]+), Attack = ([\d.]+), Defence = ([\d.]+)", en)
        kinds[kind] = dict(hp=float(m[1]), atk=float(m[2]), df=float(m[3]))
    world = lua("src/shared/Config/World.luau")
    stops = [dict(kind=m[1], count=int(m[2] or 1), level=int(m[3])) for m in
             re.finditer(r'\{ Kind = "(\w+)", Def = "\w+"(?:, Count = (\d+))?, Level = (\d+) \}', world)]
    row = re.search(r"Row = \{.*?FirstPack = ([\d.]+).*?Spacing = ([\d.]+)", world, re.S)
    combat = lua("src/shared/Config/Combat.luau")
    notice = float(re.search(r"Shade = \{\s*Notice = ([\d.]+)", combat)[1])
    stats = lua("src/shared/Config/Stats.luau")
    regen = re.search(r"Regen = \{ Base = ([\d.]+), Class = \{([^}]*)\}", stats)
    growth = lua("src/shared/Config/Growth.luau")
    early = [int(x) for x in re.search(r"Early = \{([\d, ]*)\}", growth)[1].replace(" ", "").split(",") if x]
    training = re.search(r"Training = \{ Share = ([\d.]+)", growth)
    back = re.search(r"Back = \{ Elite = ([\d.]+), Keeper = ([\d.]+) \}", world)
    respawn = re.search(r"Respawn = ([\d.]+)", world)
    drops_lua = lua("src/shared/Config/Drops.luau")
    drops = re.search(r"Share = \{ Ordinary = ([\d.]+), Elite = ([\d.]+), Keeper = ([\d.]+)", drops_lua)
    return dict(kinds=kinds, stops=stops, spacing=float(row[2]) * 16, notice=notice, early=early,
                regen=float(regen[1]) if regen else None,
                regen_class={k: float(v) for k, v in re.findall(r"(\w+) = ([\d.]+)", regen[2])} if regen else {},
                training=float(training[1]) if training else None,
                drops={"Pack": float(drops[1]), "Elite": float(drops[2])},
                keeper_share=float(drops[3]), shard_chance=float(re.search(r"ShardChance = ([\d.]+)", drops_lua)[1]),
                back={"Elite": float(back[1]), "Keeper": float(back[2])} if back else None,
                respawn=float(respawn[1]),
                xp_per_g=float(re.search(r"XpPerKillPerG = ([\d.]+)", growth)[1]))


def kills_per_level(level, early):
    if level <= len(early):
        return early[level - 1]
    for i, g in enumerate(S["grounds"]):
        if level <= g["to"]:
            return g["paceHours"] * S["pace"]["killsPerHour"] / (g["to"] - g["from"] + 1)
    return None


def xp_per_kill(level):
    return round(10 * G(level))


def xp_to_next(level, early):
    if level >= S["growth"]["maxLevel"]:
        return None
    return round(kills_per_level(level, early) * xp_per_kill(level))


def shade(kind, level, gm):
    k = gm["kinds"][kind]
    e = enemy(level, hp=k["hp"] * G(level), atk=k["atk"] * G(level))
    e["def"] = k["df"] * G(level)
    return e


def circuit(cls, start, regen_base, gm, rng, swing=1.1, beat=0.6, dt=0.05, board=None):
    """One walk down Lantern Row on what the lead carries: each stop in turn, every Shade of a pack on it at once.
    `board`, if given, is level -> the stat board's multipliers at that level (section 12), or None for none.
    Returns the health share at the end of each pack, and the stop it fell at (None if it reached the elite)."""
    level, xp = start, 0
    up = {}

    def lead(level):
        me = build(level, 1, 0.0, cls=cls)
        up.clear()
        up.update((board(level) if board else None) or {})
        for k in ("hp", "atk", "def"):
            me[k] *= up.get(k, 1.0)
        return me

    me = lead(level)
    hp = me["hp"]
    mult = gm["regen_class"].get(cls, 1.0)
    shares, fell = [], None
    for index, stop in enumerate(gm["stops"]):
        if stop["kind"] != "Pack":
            break
        # The walk in: from the gate, or from the last stop, until the pack notices; the player's own pace added.
        walk = (gm["spacing"] * (0.4 if index == 0 else 1) - gm["notice"]) / 16 + rng.uniform(0.5, 4)
        hp = min(me["hp"], hp + regen_base * mult * up.get("regen", 1.0) * G(level) * walk)
        foes = [dict(e=shade("Ordinary", stop["level"], gm), late=rng.uniform(0.3, 2.0), next=0.0) for _ in range(stop["count"])]
        for f in foes:
            f["hp"] = f["e"]["hp"]
        pace = min(1.25, max(0.75, rng.gauss(1, 0.12)))  # time lost to walking, slots, skips and flinches
        t, lead_next = 0.0, 0.0
        while any(f["hp"] > 0 for f in foes) and hp > 0:
            t += dt
            live = [f for f in foes if f["hp"] > 0]
            target = min(live, key=lambda f: f["late"])
            if t >= lead_next and t >= target["late"]:
                mine = dps(me, target["e"]) * beat * pace
                crit = rng.random() < S["ratings"]["caps"]["critFloor"]
                target["hp"] -= mine / (1 + S["ratings"]["caps"]["critFloor"] * 0.5) * (1.5 if crit else 1)
                lead_next = t + beat
                if target["hp"] <= 0:
                    xp += xp_per_kill(stop["level"])
                    need = xp_to_next(level, gm["early"])
                    while need is not None and xp >= need:
                        xp -= need
                        level += 1
                        share = hp / me["hp"]
                        me = lead(level)
                        hp = share * me["hp"]
                        need = xp_to_next(level, gm["early"])
            for f in live:
                if t >= f["late"] and t >= f["next"]:
                    theirs = dps(f["e"], me) * swing
                    crit = rng.random() < S["ratings"]["caps"]["critFloor"]
                    hp -= theirs / (1 + S["ratings"]["caps"]["critFloor"] * 0.5) * (1.5 if crit else 1)
                    f["next"] = t + swing
            if hp > 0:
                hp = min(me["hp"], hp + regen_base * mult * up.get("regen", 1.0) * G(level) * dt)
        if hp <= 0:
            fell = index
            break
        shares.append(hp / me["hp"])
    return shares, fell


def report_carry(runs=400, sweep=None, starts=(1, 3)):
    gm = game()
    print("\n== 9. Health carries (TR12): Lantern Row on what the lead carries ==")
    print("A model, not a measurement: the game's own enemy and street numbers (src/shared/Config), a bare lead, every")
    print("Shade of a pack on it at once after a walk in of 0.3 to 2 s, its kill time spread 12% for movement, the walk")
    print("between stops at 16 studs a second plus 0.5 to 4 s of the player's own pace. Regen a second, always.")
    print(f"Regen in the game now: Base {gm['regen']} a second at level 1, times G; class {gm['regen_class']}.")
    print("Each cell: health share at Pack 2's end, median [10th to 90th]; falls before the elite, in 100 runs.")
    import random
    sweep = sorted(set(sweep or (0, 4, 8, 12, 16, 20, 24)) | ({gm["regen"]} if gm["regen"] else set()))
    leads = (("Rook", "Warrior"), ("Kirra", "Assassin"), ("Pip", "Mage"), ("Lyric", "Healer"))
    for start in starts:
        print(f"\nA lead starting the street at level {start}" + (" (a new account: level 2 at its second kill)" if start == 1 else " (a later circuit)") + ":")
        line("regen /s L1", "of max /s", "empty->full", *[f"{n} ({c})" for n, c in leads], w=21)
        for base in sweep:
            cells = []
            for name, cls in leads:
                rng = random.Random(f"{name}{start}{base}")
                ends, falls = [], 0
                for _ in range(runs):
                    shares, fell = circuit(cls, start, base, gm, rng)
                    falls += fell is not None
                    ends.append(shares[1] if len(shares) > 1 else 0.0)
                ends.sort()
                q = lambda p: ends[min(len(ends) - 1, int(p * len(ends)))]
                cells.append(f"{q(0.5):.0%} [{q(0.1):.0%}-{q(0.9):.0%}] {100 * falls / runs:.0f}")
            mark_now = " <" if base == gm["regen"] else ""
            line(f"{base}{mark_now}", f"{base / S['base']['hp']:.2%}", f"{S['base']['hp'] / base:.0f}s" if base else "never", *cells, w=21)


def row_xp_per_kill(gm):
    """What a kill in Lantern Row pays on average: its packs' and its elite's, each as Config.Drops shares it (the
    game's Rules.Training does the same)."""
    kills = xp = 0.0
    for s in gm["stops"]:
        if s["kind"] in gm["drops"]:
            kills += s["count"]
            xp += s["count"] * gm["xp_per_g"] * G(s["level"]) * gm["drops"][s["kind"]]
    return xp / kills


def train_rate(gm):
    """The Training machine's experience a second: a fixed Share of what fighting earns in Lantern Row (the director,
    2026-11-14: "Fixed rate, no cap")."""
    return gm["training"] * S["pace"]["killsPerHour"] / 3600 * row_xp_per_kill(gm)


def train(level, seconds, gm):
    """Levels the Training machine gives across `seconds`, from the start of `level`, at its fixed rate, no cap."""
    xp = 0.0
    rate = train_rate(gm)
    while seconds > 0:
        need = xp_to_next(level, gm["early"])
        if need is None:
            break
        t = (need - xp) / rate
        if t > seconds:
            xp += rate * seconds
            break
        seconds -= t
        xp, level = 0.0, level + 1
    return level + xp / (xp_to_next(level, gm["early"]) or 1)


def report_training():
    gm = game()
    share = gm["training"] or 1 / 3
    gm["training"] = share
    rate = train_rate(gm) * 60
    print("\n== 10. The Training machine (TR12): what time away gives ==")
    print(f"A fixed {rate:.1f} experience a minute at any level, with no cap (the director, 2026-11-14): {share:.2f} of what")
    print(f"fighting earns in Lantern Row, {row_xp_per_kill(gm):.1f} a kill on average over its packs and elite, "
          f"{S['pace']['killsPerHour']} kills an hour. Each level costs more, so it slows as levels rise.")
    line("from level", "a level here", "1 hour", "a night (8 h)", "a day (24 h)", "a week (168 h)", w=15)
    for level in (1, 5, 15, 30):
        per = xp_to_next(level, gm["early"]) / rate
        line(level, f"{per:.0f} min", *[f"{train(level, h * 3600, gm):.1f}" for h in (1, 8, 24, 168)], w=15)
    top = max(g["to"] for g in S["grounds"])
    low, high = 0, 1
    while train(1, high * 3600, gm) < top:
        high *= 2
    while high - low > 1:
        mid = (low + high) // 2
        low, high = (mid, high) if train(1, mid * 3600, gm) < top else (low, mid)
    print(f"From level 1 to the last level, {top}: {high} hours in the machine ({high / 24:.0f} days).")


# ---------------------------------------------------------------- the elite's and the keeper's cooldowns (TR10)

HOME_AND_BACK = 10  # the builder's guess: the shortcut home after a win, then the plot's Festival Door back to the gate


def laps(players, hours, elite_back, keeper_back, gm, rng, wait_keeper=False, warm=1):
    """Players running Lantern Row at once, each from a random start within a lap, for `hours` after `warm` hours (so
    the start's bunching is gone): every pack up when reached (their
    Respawn is short against a lap), the elite shared on the server's one timer (one that finds it fighting joins and is
    paid in full; one that finds it down goes on), each player's own keeper resting from their win (one that finds it
    resting walks back down the street, or with wait_keeper waits it out). Kill times are the seeds' (enemy.ttk), a pack's
    Shades one after another; the walks are section 9's. Returns per player an hour: laps, pack, elite and keeper kills."""
    import heapq
    ttk = S["enemy"]["ttk"]
    fade = 4.0  # a keeper's try: its fades and its win's pause
    street = (gm["spacing"] * 0.4 + gm["spacing"] * (len(gm["stops"]) - 1)) / 16
    begin, end = warm * 3600, (warm + hours) * 3600
    events = [(rng.uniform(0, 240), p, 0) for p in range(players)]
    heapq.heapify(events)
    elite_fight, elite_down = -1.0, -1.0
    rest = [-1.0] * players
    count = [dict(laps=0, Pack=0, Elite=0, Keeper=0) for _ in range(players)]

    def walk(index):
        return (gm["spacing"] * (0.4 if index == 0 else 1) - gm["notice"]) / 16 + rng.uniform(0.5, 4)

    while events:
        t, p, i = heapq.heappop(events)
        if t >= end:
            continue
        stop = gm["stops"][i]
        nxt = (i + 1) % len(gm["stops"])
        on = 1 if t >= begin else 0
        if stop["kind"] == "Pack":
            count[p]["Pack"] += stop["count"] * on
            t += stop["count"] * ttk["ordinary"]
        elif stop["kind"] == "Elite":
            if t < elite_fight:  # joins the fight under way
                count[p]["Elite"] += on
                t = elite_fight
            elif t >= elite_down:
                count[p]["Elite"] += on
                elite_fight = t + ttk["elite"]
                elite_down = elite_fight + elite_back
                t = elite_fight
        else:  # the keeper
            count[p]["laps"] += on
            if t < rest[p] and wait_keeper:
                t = rest[p]
            if t >= rest[p]:
                count[p]["Keeper"] += on
                t += ttk["keeperByGround"][0] + fade
                rest[p] = t + keeper_back
                t += HOME_AND_BACK
            else:
                t += street
            heapq.heappush(events, (t + walk(0), p, 0))
            continue
        heapq.heappush(events, (t + walk(nxt), p, nxt))
    return [{k: v / hours for k, v in c.items()} for c in count]


def report_cooldowns(runs=40):
    import random
    gm = game()
    seeds = gm["back"] or {"Elite": 120, "Keeper": 300}
    share = {"Pack": gm["drops"]["Pack"], "Elite": gm["drops"]["Elite"], "Keeper": gm["keeper_share"]}
    shard = gm["shard_chance"]
    print("\n== 11. The elite's and the keeper's cooldowns (TR10): what an hour on Lantern Row gives ==")
    print("A model, not a measurement: the seeds' kill times, section 9's walks, every pack up when reached; the elite on the")
    print(f"server's one timer, each player's keeper on their own. A win's way home and back: {HOME_AND_BACK} s, the builder's guess.")
    print("Each player starts within a lap of the others; an hour is counted after an hour's warm-up. Income: Credits, against before.")
    print(f"Today's seeds: the elite back {seeds['Elite']:.0f} s after its fall, the keeper {seeds['Keeper']:.0f} s after each player's win.")
    print("Elite and keeper kills are the Jewels' source (docs/balance.md), so they're the Jewels' pace; income in Credits.")
    line("players", "cooldowns", "keeper rests", "laps /h", "elite /h", "keeper /h", "jewel kills /h", "income", "shards /h", w=15)
    base = {}
    for players in (1, 4, 8):
        for name, elite_back, keeper_back, wait in (("before", gm["respawn"], 0, False),
                                                     ("seeds", seeds["Elite"], seeds["Keeper"], False),
                                                     ("seeds", seeds["Elite"], seeds["Keeper"], True)):
            rng = random.Random(11 + players)
            rows = []
            for _ in range(runs):
                rows += laps(players, 1, elite_back, keeper_back, gm, rng, wait_keeper=wait)
            mean = {k: sum(r[k] for r in rows) / len(rows) for k in rows[0]}
            income = sum(mean[k] * share[k] for k in share)
            shards = sum(mean[k] * min(1, shard * share[k]) for k in share)
            key = players
            if name == "before":
                base[key] = (income, mean["Elite"] + mean["Keeper"])
            rel = f"{income / base[key][0]:.0%}" if key in base else ""
            line(players, name, "waits" if wait else ("walks back" if keeper_back else "-"), f"{mean['laps']:.1f}",
                 f"{mean['Elite']:.1f}", f"{mean['Keeper']:.1f}", f"{mean['Elite'] + mean['Keeper']:.1f}", rel, f"{shards:.1f}", w=15)


# ---------------------------------------------------------------- Speed (TR14)

SPEED_LEADS = (("Rook", "Warrior", 4.5), ("Kirra", "Assassin", 4.5), ("a Tank", "Tank", 4.5), ("Pip", "Mage", 14.5),
               ("Lyric", "Healer", 12))  # each kit's combo reach (Definitions.Actions); a Tank fights in reach as Rook does
STEP = 3  # studs a lead steps to its next slot after a kill, twice a pack: the builder's guess


def speed_config():
    """Speed's seeds and the lead's walks, from src/shared/Config (their home)."""
    import re
    stats = lua("src/shared/Config/Stats.luau")
    m = re.search(r"Speed = \{ Class = \{([^}]*)\}.*?Nudge = ([\d.]+)", stats)
    combat = lua("src/shared/Config/Combat.luau")
    return dict(cls={k: float(v) for k, v in re.findall(r"(\w+) = ([\d.]+)", m[1])}, nudge=float(m[2]),
                follow=float(re.search(r"FollowWalk = ([\d.]+)", combat)[1]),
                leash=float(re.search(r"Leash = ([\d.]+)", combat)[1]),
                shade=float(re.search(r"Shade = \{.*?WalkSpeed = ([\d.]+)", combat, re.S)[1]))


def pack_cycle(speed, reach, cfg, gm):
    """One of Lantern Row's packs and the walk to the next, in seconds: the lead walks in from its leash alone until the
    pack notices it, then they close together to its reach; the three Shades fall at the seeds' kill time, the lead
    stepping to its next slot twice; then the player walks on at 16. Returns the cycle and its closing part."""
    alone = max(0.0, cfg["leash"] - gm["notice"]) / speed
    together = max(0.0, gm["notice"] - reach) / (speed + cfg["shade"])
    steps = 2 * STEP / speed
    fight = 3 * S["enemy"]["ttk"]["ordinary"]
    walk = (gm["spacing"] - cfg["leash"]) / 16 + 2.25
    return alone + together + steps + fight + walk, alone + together + steps


def report_speed():
    gm = game()
    cfg = speed_config()
    print("\n== 13. Speed (TR14): kills an hour by class on Lantern Row's packs ==")
    print("A model, not a measurement. A lead walks at its Speed in a fight only: in from the leash "
          f"({cfg['leash']:g} studs) alone until the pack")
    print(f"notices it ({gm['notice']:g}), then with the Shades walking in ({cfg['shade']:g}) to its reach; "
          f"{STEP} studs to its next slot twice a pack. Kill time is")
    print(f"the seeds' ({S['enemy']['ttk']['ordinary']:g} s an Ordinary), the same for every class, so only Speed "
          "differs. The player waits for each pack (an")
    print(f"upper bound on what Speed gives), then walks on at 16. Following, every lead walks {cfg['follow']:g}, "
          "whatever its Speed.")
    print("Seeds: " + ", ".join(f"{k} {v:g}" for k, v in cfg["cls"].items()) + f"; a Voidkin's own nudge up to {cfg['nudge']:g}.")
    line("lead", "Speed", "closing s", "at 16 s", "kills /h", "at 16", "ahead", w=12)
    for name, cls, reach in SPEED_LEADS:
        speed = cfg["cls"][cls] + (1 if name == "Kirra" else 0)
        cycle, closing = pack_cycle(speed, reach, cfg, gm)
        base, base_closing = pack_cycle(16, reach, cfg, gm)
        kills, kills16 = 3 * 3600 / cycle, 3 * 3600 / base
        line(name, f"{speed:g}", f"{closing:.2f}", f"{base_closing:.2f}", f"{kills:.0f}", f"{kills16:.0f}",
             f"{kills / kills16 - 1:+.1%}", w=12)
    slow, fast = pack_cycle(cfg["cls"]["Tank"], 4.5, cfg, gm)[0], pack_cycle(cfg["cls"]["Assassin"] + 1, 4.5, cfg, gm)[0]
    print(f"Kirra against a Tank: {slow / fast - 1:+.1%} kills an hour; the closing is "
          f"{pack_cycle(cfg['cls']['Tank'], 4.5, cfg, gm)[1]:.2f} s against "
          f"{pack_cycle(cfg['cls']['Assassin'] + 1, 4.5, cfg, gm)[1]:.2f} s a pack.")


# ---------------------------------------------------------------- the base as a power plant (TR18)

def report_power():
    """Generation against demand in kW, the battery in kWh, per ground (docs/design.md, "Power"). Each machine draws its
    rating while it works; a shard costs its chamber's rating times its break time, times its ground's factor."""
    pw, sh, bays = S["power"], S["shards"], S["bays"]
    print("\n== 14. The base as a power plant (TR18): kW and kWh ==")
    line("ground", "gen kW", "breaker kW", "train kW", "Auto, no batt", "Std kWh", "Enr kWh", "Pri kWh",
         *[f"{p} cover" for p in S["profiles"]], w=13)
    for i, g in enumerate(S["grounds"]):
        mid = (g["from"] + g["to"]) // 2
        f = sh["regionFactor"][i]
        here = [v for v in ROSTER if v["zone"] <= g["id"]]
        apt = sum(sorted((v["apt"] for v in here), reverse=True)[:bays["workersByGround"][i]]) * 0.85
        gen = apt * pw["kwPerAptitude"] * (1 + bays["perLevel"] * (mid * 0.8 - 1))
        brk = bays["chambersByGround"][i] * pw["breakerKwPerChamber"] * f
        trn = pw["trainingKw"] * f
        kwh = {k: pw["breakerKwPerChamber"] * f * sh["breakSeconds"][k] / 3600 for k in ("Standard", "Enriched", "Prismatic")}
        cover = []
        for pr in S["profiles"].values():
            online = pr["hoursPerDay"]
            away = min(24 - online, pr["sessions"] * bays["batteryHoursByGround"][i])
            supply = gen * (online + away) - trn * (online + away)  # the Training machine runs whenever the plant does
            n = dict(Standard=sh["perHour"]["Standard"] * online,
                     Enriched=sh["perHour"]["Enriched"] * online if g["id"] >= sh["enrichedFromGround"] else 0,
                     Prismatic=pr["prismaticPerDay"] if g["id"] >= sh["prismaticFromGround"] else 0)
            demand = sum(n[k] * kwh[k] for k in n)
            cover.append(f"x{supply / demand:.1f}" if demand else "-")
        line(g["id"], f"{gen:.0f}", f"{brk:.0f}", f"{trn:.0f}", f"{min(1, gen / (brk + trn)):.0%}",
             f"{kwh['Standard']:.2f}", f"{kwh['Enriched']:.1f}", f"{kwh['Prismatic']:.0f}", *cover, w=13)
    g1 = (3 * 6 + 2 * 6)  # Watt (3) and Rook (2) at level 1: the director's own example, 30 kW
    spare = g1 - pw["trainingKw"]
    print(f"Ground 1 at its start, Watt and Rook at level 1: {g1} kW. With the Training machine at full, {spare} kW spare.")
    print(f"The battery: {pw['batteryKwh']} kWh, full from empty in {pw['batteryKwh'] / spare:.1f} h of that spare; "
          f"overflow sells at {pw['creditsPerKwh']} Credits a kWh.")
    v = pw["voltage"]
    print(f"Voltage (infusion): Low halves a shard's time left, High breaks it now. The price: the energy its chamber "
          f"would still draw over the time saved, x{v['premium']:.2f}, x the ground's factor; none under "
          f"{v['minSavedSeconds']} s saved. A fresh shard at full power, ground 1, against hours of the spare:")
    line("grade", "break", "Low saves", "kWh", "High saves", "kWh", "High, g6", w=12)
    for grade in ("Standard", "Enriched", "Prismatic"):
        t = sh["breakSeconds"][grade] / 3600
        cells = []
        for left in (v["lowTimeLeft"], v["highTimeLeft"]):
            saved = t * (1 - left)
            kwh = saved * pw["breakerKwPerChamber"] * v["premium"]
            cells += [f"{saved:.2f} h", f"{kwh:.1f}" if saved * 3600 >= v["minSavedSeconds"] else "not offered"]
        g6 = t * pw["breakerKwPerChamber"] * v["premium"] * sh["regionFactor"][5]
        line(grade, f"{t:.2f} h", *cells, f"{g6:.0f}" if t * 3600 >= v["minSavedSeconds"] else "-", w=12)
    print(f"The battery holds {pw['batteryKwh']} kWh today; its cap grows with the base (docs/design.md, 'The base').")
    print(f"Short of power with the battery empty, a machine runs at its share of its rating, never under "
          f"{pw['minSpeed']:.0%}: a Standard shard then takes {30 / max(pw['minSpeed'], 0.01):.0f} s at worst.")


# ---------------------------------------------------------------- the base's levels and its machines' (TR21)

def on_budget_level(hours):
    """The Voidkin level an on-budget player stands at after this many hours of play, levels spread evenly in a ground."""
    t = 0.0
    for g in S["grounds"]:
        if hours <= t + g["paceHours"]:
            n = g["to"] - g["from"] + 1
            return g["from"] + (hours - t) / g["paceHours"] * n
        t += g["paceHours"]
    return S["grounds"][-1]["to"]


def earned(h0, h1, step=1 / 60):
    """Credits from kills between two marks of play time, on budget, before any bonus (seeds "pace")."""
    p = S["pace"]
    total, h = 0.0, h0
    while h < h1 - 1e-9:
        dh = min(step, h1 - h)
        total += p["killsPerHour"] * p["creditsPerKillPerG"] * G(int(on_budget_level(h + dh / 2))) * dh
        h += dh
    return total


def nice(x):
    """Rounded to two significant figures, as a price reads."""
    if x <= 0:
        return 0
    k = 10 ** max(0, len(str(int(x))) - 2)
    return int(round(x / k) * k)


def base_prices():
    """The base's levels at launch and every machine level under them, priced on the Credits earned in time windows."""
    b = S["baseLevels"]
    launch = sum(g["paceHours"] for g in S["grounds"])
    marks = {1: 0.0}
    marks.update({int(k): v for k, v in b["atHours"].items()})
    levels = {}
    for lv in range(2, b["launchCap"] + 1):
        window = earned(marks[lv - 1], marks[lv])
        levels[lv] = dict(at=marks[lv], window=window, price=nice(window * b["shareOfWindow"][str(lv)]))
    # A machine's ceiling is set by the base's level. Its levels under each base level are spread evenly over that base
    # level's time (the last band runs to the launch's end), and each costs its share of the machines' budget over its
    # own slice of time, split across the machines standing at that base level.
    cap = {int(k): v for k, v in b["machineCeiling"].items()}
    count = {int(k): v for k, v in b["machines"].items()}
    ends = [marks[lv] for lv in range(1, b["launchCap"] + 1)] + [launch]
    machine = {}
    for lv in range(1, b["launchCap"] + 1):
        first = 2 if lv == 1 else cap[lv - 1] + 1
        last = cap[lv]
        span = (ends[lv] - ends[lv - 1]) / (last - first + 1)
        for m in range(first, last + 1):
            h1 = ends[lv - 1] + (m - first + 1) * span
            h0 = h1 - span
            cost = earned(h0, h1) * b["machineShareOfIncome"] / count[lv]
            machine[m] = dict(at=h1, level=on_budget_level(h1), price=nice(cost), n=count[lv])
    return levels, machine, launch


def report_base():
    b = S["baseLevels"]
    print("\n== 15. The base's levels and its machines' at launch (TR21): Credits ==")
    levels, machine, launch = base_prices()
    total = earned(0, launch)
    print(f"Kills' Credits over the launch's {launch:g} h, on budget, before bonuses: {total:,.0f}.")
    line("base level", "lands at", "Voidkin lv", "earned in window", "share", "price", "bays", w=17)
    for lv, d in levels.items():
        line(lv, f"{d['at'] * 60:.0f} min" if d['at'] < 1 else f"{d['at']:.1f} h", f"{on_budget_level(d['at']):.0f}",
             f"{d['window']:,.0f}", f"{b['shareOfWindow'][str(lv)]:.0%}", f"{d['price']:,}", b["bays"][str(lv)], w=17)
    print("A machine's ceiling by the base's level: " +
          ", ".join(f"{k}: {v}" for k, v in b["machineCeiling"].items()) +
          f". The machines take {b['machineShareOfIncome']:.0%} of the income between them, priced as if " +
          ", ".join(f"{v} stand at base level {k}" for k, v in b["machines"].items()) + ".")
    line("machine lv", "bought at", "Voidkin lv", "price", "x machines", w=13)
    spent = 0
    for m, d in machine.items():
        spent += d["price"] * d["n"]
        when = f"{d['at'] * 60:.0f} min" if d["at"] < 1 else f"{d['at']:.1f} h"
        line(m, when, f"{d['level']:.0f}", f"{d['price']:,}", f"{d['price'] * d['n']:,}", w=13)
    base_spent = sum(d["price"] for d in levels.values())
    forge = total * S["pace"]["forgeShareOfIncome"]
    print(f"Spent over the launch: the base {base_spent:,} ({base_spent / total:.0%}), the machines {spent:,} "
          f"({spent / total:.0%}), the forge {forge:,.0f} ({S['pace']['forgeShareOfIncome']:.0%}); "
          f"left for the shop and the rest {1 - (base_spent + spent + forge) / total:.0%}.")
    first = levels[2]
    by = earned(0, first["at"])
    print(f"Level 2 in the first session: {by:,.0f} Credits earned by {first['at'] * 60:.0f} min, the price "
          f"{first['price']:,}, so {by - first['price']:,.0f} are left for the forge and the machines by then.")

if __name__ == "__main__":
    ROSTER.extend(roster())
    assert len(ROSTER) >= 30, f"roster rows read: {len(ROSTER)}"
    print(f"Balance run. Roster rows: {len(ROSTER)}. Seeds: tools/balance/seeds.json.")
    report_growth()
    report_extremes()
    E = tune_enemies()
    report_ttk(E)
    report_pvp()
    report_pools()
    report_ownership()
    report_energy()
    report_pace()
    report_carry()
    report_training()
    report_cooldowns()
    report_speed()
    report_power()
    report_base()
