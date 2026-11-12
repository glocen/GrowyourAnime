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
    off = 1 + min(b["bonusCap"], b0 + pcrit * max(0.0, att["critdmg"] - dfn["critguard"]))
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
    print(f"Hard ceiling of one hit over its plain value: x{1 + b['bonusCap']:.1f} (the bonus bucket's cap). "
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
    print("\n== 7. Electricity: what the bays make against what the Breaker asks ==")
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
    print("\nInfusion: worth gained for the extra electricity (worth uses the value per rarity in the seeds).")
    by = {v["id"]: v for v in ROSTER}

    def worth(p):
        return sum(c * sh["value"][by[v]["rarity"]] for v, c in p.items())
    line("shard", "plain worth, cost", *[f"+{o['lift']:.2f} lift" for o in S["luck"]["infusion"]], "top tier odds", w=22)
    for gid, grade in ((3, "Standard"), (6, "Standard"), (4, "Enriched"), (6, "Enriched"), (4, "Prismatic"), (6, "Prismatic")):
        plain = worth(pool(gid, grade))
        cells = [f"{plain:.1f} for {sh['energy'][grade] * sh['regionFactor'][gid - 1]:.0f}"]
        for o in S["luck"]["infusion"]:
            extra = o["energy"] * sh["regionFactor"][gid - 1]
            cells.append(f"+{worth(pool(gid, grade, o['lift'])) - plain:.2f} for {extra:.0f}")
        p0, p1 = pool(gid, grade), pool(gid, grade, S["luck"]["cap"])
        top = max(p0, key=lambda v: RARITIES.index(by[v]["rarity"]))
        tr = by[top]["rarity"]
        s0 = sum(c for v, c in p0.items() if by[v]["rarity"] == tr)
        s1 = sum(c for v, c in p1.items() if by[v]["rarity"] == tr)
        line(f"g{gid} {grade}", *cells, f"{tr[:3]} {s0:.1%} to {s1:.1%} at cap", w=22)


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
