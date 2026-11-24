"""AR48's even-elements check, summarised (docs/design.md, "States in a fight", "The elements stay even").

Run:  py tools/balance/elements_even.py <runs file>
The runs file holds the lines tools/studio/ElementsEven.luau writes (element|round|key=value|...); lines starting
with # are notes. Prints each element's clear time and damage taken (mean and sd), their spread and each against the
mean, and the noise: Storm and Void are both plain against Shades today (Shock waits on poise; Shades don't heal, so
Sap has nothing to cut), so the gap between them is what ten runs can't tell apart. A measurement of the replay, not a
prediction of what players will do.
"""
import math
import statistics as st
import sys

PLAIN = ("Storm", "Void")


def read(path):
    rows = {}
    for line in open(path, encoding="utf-8"):
        if line.startswith("#") or "|" not in line:
            continue
        parts = line.strip().split("|")
        kv = dict(p.split("=", 1) for p in parts[2:] if "=" in p)
        if kv.get("clear", "none") == "none" or kv.get("fell") == "true":
            print("left out (no clear, or a fall):", line.strip())
            continue
        rows.setdefault(parts[0], []).append((float(kv["clear"]), float(kv["taken"]), int(kv.get("freezes", 0))))
    return rows


def main():
    rows = read(sys.argv[1])
    print(f"{'':6} {'n':>2} {'clear s':>17} {'taken':>17} freezes")
    for el, rs in rows.items():
        c, t = [r[0] for r in rs], [r[1] for r in rs]
        print(f"{el:6} {len(rs):2} {st.mean(c):7.1f} (sd {st.stdev(c):4.1f}) {st.mean(t):7.1f} (sd {st.stdev(t):4.1f}) {st.mean([r[2] for r in rs]):7.1f}")
    for i, name in enumerate(("clear", "taken")):
        means = {el: st.mean(r[i] for r in rs) for el, rs in rows.items()}
        lo, hi, mean = min(means, key=means.get), max(means, key=means.get), st.mean(means.values())
        print(f"{name}: spread {100 * (means[hi] / means[lo] - 1):.1f}% ({hi} over {lo}); against the mean "
              + ", ".join(f"{el} {100 * (m / mean - 1):+.1f}%" for el, m in means.items()))
        if all(p in rows for p in PLAIN):
            plain = [r[i] for p in PLAIN for r in rows[p]]
            a, b = ([r[i] for r in rows[p]] for p in PLAIN)
            print(f"  noise: {PLAIN[0]} against {PLAIN[1]}, both plain, {100 * (st.mean(a) / st.mean(b) - 1):+.1f}%; "
                  f"a {len(a)}-run mean's 95% band about {100 * 1.96 * st.stdev(plain) / math.sqrt(len(a)) / st.mean(plain):.1f}%")
            for el in rows:
                if el not in PLAIN:
                    v = [r[i] for r in rows[el]]
                    se = math.sqrt(st.variance(v) / len(v) + st.variance(plain) / len(plain))
                    print(f"  {el} against the plain pair: {100 * (st.mean(v) / st.mean(plain) - 1):+.1f}% ({(st.mean(v) - st.mean(plain)) / se:+.1f} se)")


if __name__ == "__main__":
    main()
