"""Basic Attributes: the director's package of 2026-11-16, item 1 (docs/archive/director-package-2026-11-16.md).

Run:  py tools/balance/attributes.py          (from the project folder)
Proposal stage: the seeds live in ATTR below until the director's yes, then move to seeds.json.
It reuses sim.py's hit, duel and Combat Power, so nothing here re-derives the combat math.
Nothing here is a measurement of play: it tests the structure and the seeds against each other.

The model:
- Five attributes. Every point converts to Battle Attributes by one fixed row (CONV), the same for every class.
- A class's Main attribute converts once more by its own row (MAIN): this is where classes differ.
- A Voidkin's own attributes are its class profile x rarity x G(level) x (1 + stars). Gear adds points flat.
- Everything adds. No attribute multiplies another, nothing multiplies an attribute, and Combat Power reads
  only the resolved Battle Attributes, so an attribute is never counted twice.
"""
import math, random, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import sim  # noqa: E402
from sim import S, G, line, dps, edge, fighter, cp, CP_NAMES, SPECS, RARITIES  # noqa: E402

CLASSES = ["Warrior", "Tank", "Assassin", "Mage", "Healer"]
ATTRS = ["might", "finesse", "vigor", "spirit", "insight"]

# ------------------------------------------------------------------ the seeds (proposal)

ATTR = {
    # Battle Attribute points per attribute point, every class.
    "conv": {
        "might":   {"atk": 1.0, "hp": 4.0},
        "finesse": {"atk": 0.4, "hit": 1.2, "crit": 1.6, "dodge": 0.6},
        "vigor":   {"hp": 5.0, "def": 1.0, "block": 0.3},
        "spirit":  {"regen": 0.06, "hp": 6.0, "critres": 4.0, "eres": 3.0},
        "insight": {"atk": 0.4, "pen": 2.5, "hit": 1.0, "hp": 2.0},
    },
    # Each class's Main attribute, and what one point of it gives on top of the row above.
    "main": {
        "Warrior":  ("might",   {"atk": 1.0}),
        "Tank":     ("vigor",   {"atk": 0.5, "hp": 3.0}),
        "Assassin": ("finesse", {"atk": 1.0}),
        "Mage":     ("insight", {"atk": 0.8, "elem": 0.25}),
        "Healer":   ("spirit",  {"atk": 0.7, "regen": 0.04}),
    },
    # A class's shape: the share of its points in each attribute, its Main the largest.
    "shape": {
        "Warrior":  {"might": .40, "finesse": .10, "vigor": .30, "spirit": .10, "insight": .10},
        "Tank":     {"might": .22, "finesse": .10, "vigor": .42, "spirit": .14, "insight": .12},
        "Assassin": {"might": .26, "finesse": .36, "vigor": .22, "spirit": .08, "insight": .08},
        "Mage":     {"might": .24, "finesse": .08, "vigor": .22, "spirit": .10, "insight": .36},
        "Healer":   {"might": .22, "finesse": .08, "vigor": .26, "spirit": .36, "insight": .08},
    },
    # A class's attribute points at level 1, Common, no stars: its shape times the total that keeps the class
    # exactly as strong against everyone as it is today (fit_profiles), rounded.
    "profile": {},
}

TODAY = {c: {"hp": S["base"]["hp"] * S["classMult"][c]["hp"], "atk": S["base"]["atk"] * S["classMult"][c]["atk"],
             "def": S["base"]["def"] * S["classMult"][c]["def"], "regen": 4 * (1.5 if c == "Healer" else 1)}
         for c in CLASSES}
RATING_KEYS = S["ratings"]["list"]
STAT_KEYS = ["hp", "atk", "def", "regen", "elem"] + RATING_KEYS
LEVEL_REGEN = 4.0     # Regen a second at G = 1 that every Voidkin has from its level, as today (no class bonus now)
MIN_SECONDARY = 5   # every class holds at least this many points of finesse and insight at level 1: no dead attribute


def convert(points, cls):
    """Battle Attribute points from attribute points, for one class."""
    out = {k: 0.0 for k in STAT_KEYS}
    main, extra = ATTR["main"][cls]
    for a, n in points.items():
        for k, v in ATTR["conv"][a].items():
            out[k] += v * n
        if a == main:
            for k, v in extra.items():
                out[k] += v * n
    return out


def own_cp(stats):
    w = {k: S["combatPower"]["weights"][n] for k, n in CP_NAMES.items()}
    return sum(w[k] * v for k, v in stats.items() if k in w)


def fit_profiles(level=30):
    """Each class's total points: its shape, scaled until its mean edge against today's panel (every class and
    spec) equals today's same class's. So the classes stand against each other as they do now, and only how each
    one gets there changes. Bisection on the total, at one level (G scales the rest)."""
    frac = S["onBudget"]
    today_panel = [fighter(level, frac, cls=c, spec=sp) for c in CLASSES for sp in SPECS]

    def mean_edge(st):
        return sum(edge(st, p) for p in today_panel) / len(today_panel)

    for c in CLASSES:
        want = mean_edge(fighter(level, frac, cls=c))
        lo, hi = 20.0, 600.0
        for _ in range(40):
            mid = (lo + hi) / 2
            ATTR["profile"][c] = {a: mid * ATTR["shape"][c][a] for a in ATTRS}
            if mean_edge(fighter_attr(level, frac, cls=c)) < want:
                lo = mid
            else:
                hi = mid
        ATTR["profile"][c] = {a: int(round(hi * ATTR["shape"][c][a])) for a in ATTRS}


def own_points(cls, level, rarity="Common", stars=0):
    k = S["rarityBase"][rarity] * G(level) * (1 + S["starPctOfBase"] * stars)
    return {a: n * k for a, n in ATTR["profile"][cls].items()}


def fighter_attr(level, frac, rarity="Common", cls="Warrior", spec="balanced", lifesteal=0.0, extra=None):
    """sim.fighter with its own figure (Health, Attack, Defence, Regen) replaced by the attributes' conversion.
    Gear, forge, emblems, jewels and research stay as sim.build has them. `extra` adds attribute points (gear lines)."""
    st = fighter(level, frac, rarity, cls, spec, lifesteal)
    ground = next(x["id"] for x in S["grounds"] if x["from"] <= level <= x["to"])
    stars = round(S["available"][ground - 1]["stars"] * frac)
    cm, rb = S["classMult"][cls], S["rarityBase"][rarity]
    for k in ("hp", "atk", "def"):                      # take today's own figure out
        st[k] -= S["base"][k] * rb * cm[k] * G(level) * (1 + S["starPctOfBase"] * stars)
    st["regen"] = LEVEL_REGEN * G(level)               # the level's own Regen stays; Spirit adds to it
    pts = own_points(cls, level, rarity, stars)
    for a, n in (extra or {}).items():
        pts[a] = pts.get(a, 0) + n
    for k, v in convert(pts, cls).items():
        st[k] = st.get(k, 0.0) + v
    st["_points"] = pts
    return st


def panel(level, frac, maker):
    return [maker(level, frac, cls=c, spec=sp, lifesteal=ls)
            for c in CLASSES for sp in SPECS for ls in (0.0, S["lifesteal"]["typical"])]


# ------------------------------------------------------------------ reports

def report_fit():
    print("\n== A1. Profiles: each class's level-1 points, and the figure they give against today's ==")
    line("class", "main", *ATTRS, "Health", "Attack", "Defence", "Regen", w=10)
    for c in CLASSES:
        p = ATTR["profile"][c]
        got = convert(p, c)
        got["regen"] += LEVEL_REGEN
        cells = [f"{got[t]:.0f} ({got[t] / TODAY[c][t] - 1:+.0%})" if t != "regen" else f"{got[t]:.1f} ({got[t] / TODAY[c][t] - 1:+.0%})"
                 for t in ("hp", "atk", "def", "regen")]
        line(c, ATTR["main"][c][0], *[p[a] for a in ATTRS], *cells, f"total {sum(p.values())}", w=10)
    print("New at level 1, from the secondary attributes (today a Voidkin's own ratings are 0):")
    line("class", *RATING_KEYS, "elem", w=10)
    for c in CLASSES:
        got = convert(ATTR["profile"][c], c)
        line(c, *[f"{got[k]:.0f}" for k in RATING_KEYS], f"{got['elem']:.1f}", w=10)


def marginal(level, frac=None, step_share=0.02):
    """Edge gained per attribute point, for each class, against a panel of every class and spec on budget.
    Normalised to the class's best attribute: 1.00 is its best, and a figure near 0 is a dead attribute."""
    frac = S["onBudget"] if frac is None else frac
    ps = panel(level, frac, fighter_attr)
    out = {}
    for c in CLASSES:
        row = {}
        for sp in ("balanced",):
            me = fighter_attr(level, frac, cls=c, spec=sp)
            step = step_share * sum(me["_points"].values())
            for a in ATTRS:
                b = fighter_attr(level, frac, cls=c, spec=sp, extra={a: step})
                row[a] = sum(edge(b, p) - edge(me, p) for p in ps) / len(ps) / step
        best = max(row.values())
        out[c] = {a: v / best for a, v in row.items()}
    return out


def report_marginal():
    print("\n== A2. What a point of each attribute is worth to each class (1.00 = that class's best) ==")
    print("Against a panel of every class and spec on budget, balanced spec, same level. Wanted: the Main highest,")
    print("every other attribute worth something to every class, and no attribute the best for everyone.")
    for L in (5, 30, 60):
        m = marginal(L)
        print(f"-- level {L}")
        line("class", *ATTRS, "best", w=10)
        for c in CLASSES:
            line(c, *[f"{m[c][a]:.2f}" for a in ATTRS], max(m[c], key=m[c].get), w=10)


def report_classes():
    print("\n== A3. Class against class, same level and spec, before and after (edge in logs; + the row wins) ==")
    for L in (10, 40):
        for label, maker in (("today", fighter), ("attributes", fighter_attr)):
            print(f"-- level {L}, {label}")
            line("", *CLASSES, w=10)
            for a in CLASSES:
                A = maker(L, S["onBudget"], cls=a)
                line(a, *[f"{edge(A, maker(L, S['onBudget'], cls=b)):+.2f}" for b in CLASSES], w=10)


def report_ttk():
    print("\n== A4. Against the game: seconds to kill an ordinary Shade, and health lost a kill, before and after ==")
    E = sim.tune_enemies()
    line("ground", "class", "kill today", "kill attr", "loss today", "loss attr", w=12)
    for row, g in zip(E, S["grounds"]):
        en = row["ordinary"]
        lv = en["at"]
        for c in CLASSES:
            out = []
            for maker in (fighter, fighter_attr):
                me = maker(lv, S["onBudget"], cls=c)
                t = en["hp"] / dps(me, en)
                loss = dps(en, me) * t / me["hp"]
                out.append((t, loss))
            line(g["id"] if c == "Warrior" else "", c, f"{out[0][0]:.1f}", f"{out[1][0]:.1f}",
                 f"{out[0][1]:.0%}", f"{out[1][1]:.0%}", w=12)


def report_stacking():
    print("\n== A5. One gear budget of attribute points, spent five ways and spread (edge against the panel) ==")
    print("A budget of 25% of the class's own points. 'spread' puts a fifth in each; 'main' all in the Main.")
    for L in (30, 60):
        ps = panel(L, S["onBudget"], fighter_attr)
        print(f"-- level {L}")
        line("class", *[f"all {a}" for a in ATTRS], "spread", "best", w=12)
        for c in CLASSES:
            me = fighter_attr(L, S["onBudget"], cls=c)
            budget = 0.25 * sum(me["_points"].values())
            ways = {f"all {a}": {a: budget} for a in ATTRS}
            ways["spread"] = {a: budget / 5 for a in ATTRS}
            score = {}
            for k, ex in ways.items():
                b = fighter_attr(L, S["onBudget"], cls=c, extra=ex)
                score[k] = sum(edge(b, p) for p in ps) / len(ps) - sum(edge(me, p) for p in ps) / len(ps)
            line(c, *[f"{score[k]:+.3f}" for k in ways], max(score, key=score.get), w=12)


def report_cp(pairs=3000, seed=11):
    print("\n== A6. Combat Power, unchanged weights, read on the resolved Battle Attributes only ==")
    seeds = {k: S["combatPower"]["weights"][n] for k, n in CP_NAMES.items()}
    rng = random.Random(seed)
    rows = []
    for _ in range(pairs):
        L, f = rng.randint(1, 60), rng.uniform(0.2, 1.0)
        def someone(ff):
            return fighter_attr(L, ff, rng.choice(RARITIES), rng.choice(CLASSES), rng.choice(list(SPECS)),
                                rng.choice((0.0, 0.0, S["lifesteal"]["typical"], 0.06)),
                                extra={rng.choice(ATTRS): rng.uniform(0, 0.25) * 100 * G(L)})
        a, b = someone(f), someone(min(1.0, max(0.0, f + rng.uniform(-0.1, 0.1))))
        rows.append((a, b, edge(a, b)))
    for least in (0.02, 0.10):
        n = ok = 0
        for a, b, e in rows:
            if abs(e) >= least:
                n += 1
                ok += (cp(a, seeds) > cp(b, seeds)) == (e > 0)
        print(f"the higher Combat Power wins {ok / n:.0%} of {n} same-level duels with no type edge"
              f" {'(any gap)' if least == 0.02 else '(one wins 10% faster)'}")
    print("Today's figure for the same test is in sim.py's section 16 (97%).")


def report_value():
    print("\n== A7. What a point is worth in Combat Power (weights x conversion), the price of a gear line ==")
    w = {k: S["combatPower"]["weights"][n] for k, n in CP_NAMES.items()}
    line("attribute", "any class", *[f"as {c}'s Main" for c in CLASSES], w=14)
    for a in ATTRS:
        gen = sum(w[k] * v for k, v in ATTR["conv"][a].items())
        mains = []
        for c in CLASSES:
            m, extra = ATTR["main"][c]
            mains.append(f"{gen + sum(w[k] * v for k, v in extra.items()):.1f}" if m == a else "")
        line(a, f"{gen:.1f}", *mains, w=14)


if __name__ == "__main__":
    sim.ROSTER.extend(sim.roster())
    fit_profiles()
    print("Basic Attributes, proposal run. Seeds: ATTR in tools/balance/attributes.py.")
    report_fit()
    report_value()
    report_marginal()
    report_stacking()
    report_classes()
    report_ttk()
    report_cp()
