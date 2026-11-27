"""TR73's duel matrix: Studio's raw duels (DuelService, NL_Debug "DuelRead") into one table per pair.

    py tools/balance/duel_matrix.py build/captures/tr73/duels.json [build/captures/tr73/matrix.md]

The input is DuelRead's answer, or its Results list: one row per fight. Each row of the output is one batch (the lead,
the rival, their levels, the rule turned off), its numbers the median over its fights unless named a mean or a count.
"Melee" and "Ranged" name the side by its class (DuelService: Mage and Healer are ranged). MEASURED in Studio's fights;
the AI's own choices aren't seeded, so two batches differ by more than their rolls.
"""

import json
import statistics
import sys
from collections import OrderedDict
from pathlib import Path


def median(values):
    values = [v for v in values if v is not None]
    return statistics.median(values) if values else None


def mean(values):
    values = [v for v in values if v is not None]
    return statistics.fmean(values) if values else None


def fmt(value, digits=1):
    if value is None:
        return "-"
    if isinstance(value, float):
        return f"{value:.{digits}f}"
    return str(value)


def side_of(row, role):
    """The side of `row` playing `role` ("Melee" or "Ranged"), and whether it's the lead."""
    if row["Lead"]["Role"] == role:
        return row["Lead"], "Lead"
    if row["Rival"]["Role"] == role:
        return row["Rival"], "Rival"
    return None, None


def summarize(rows):
    groups = OrderedDict()
    for row in rows:
        key = (row["LeadDef"], row["RivalDef"], row["LeadLevel"], row["RivalLevel"], row.get("Off") or "")
        groups.setdefault(key, []).append(row)
    lines = [
        "| Lead | Rival | Levels | Off | Fights | Lead wins | Rival wins | Time-outs | Seconds | Melee first swing | Melee first hit "
        "| Under 6 | 6 to 13 | Over 13 | Uptime L / R | Flinches L / R | Flinched s L / R | Pushes L / R | Studs L / R "
        "| Skips L / R | Dodged L / R | End health L / R |",
        "|" + "---|" * 22,
    ]
    for (lead, rival, ll, rl, off), fights in groups.items():
        wins = {"Lead": 0, "Rival": 0, "Time": 0}
        for f in fights:
            wins[f["Winner"]] = wins.get(f["Winner"], 0) + 1
        melee = [side_of(f, "Melee")[0] for f in fights]
        swing = median([m.get("FirstSwing") for m in melee if m])
        hit = median([m.get("FirstHit") for m in melee if m])
        total = [f["Seconds"] for f in fights]
        share = lambda band: mean([f["Ranges"][band] / max(f["Seconds"], 1e-6) for f in fights])

        def pair(key, digits=1, fn=median):
            return f"{fmt(fn([f['Lead'][key] for f in fights]), digits)} / {fmt(fn([f['Rival'][key] for f in fights]), digits)}"

        lines.append(
            f"| {lead} | {rival} | {ll} / {rl} | {off or 'none'} | {len(fights)} | {wins['Lead']} | {wins['Rival']} | {wins['Time']} "
            f"| {fmt(median(total))} | {fmt(swing, 2)} | {fmt(hit, 2)} | {fmt(share('Near'), 2)} | {fmt(share('Mid'), 2)} | {fmt(share('Far'), 2)} "
            f"| {pair('Uptime', 2)} | {pair('Flinches', 0)} | {pair('Flinched')} | {pair('Pushes', 0)} | {pair('Pushed')} "
            f"| {pair('Skips', 0)} | {pair('Dodged', 0)} | {pair('Ended', 2)} |"
        )
    return lines


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    source = Path(sys.argv[1])
    data = json.loads(source.read_text(encoding="utf-8"))
    rows = data["Results"] if isinstance(data, dict) else data
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else source.with_name("matrix.md")
    head = [
        f"# TR73's duel matrix ({len(rows)} fights, from `{source.as_posix()}`)",
        "",
        "Medians over each batch's fights; the range bands and the counts' shares are means. L the lead, R the rival. "
        "A rival never skips and never flinches (FightService), so the lead's side carries both rules.",
        "",
    ]
    out.write_text("\n".join(head + summarize(rows)) + "\n", encoding="utf-8")
    print(f"{out}: {len(rows)} fights")
    return 0


if __name__ == "__main__":
    sys.exit(main())
