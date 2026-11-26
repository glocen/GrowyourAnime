"""AR62, step 4, the worst screen first: the Arc panel redone from the picked style frame (A, Graphite, with the shard
cut; research, 2026-11-26, 14:24), as targets for research's pick in pairs.

Every piece is drawn from the frame's tokens (tools/ui/style_frames.py, TAKES["A"], its Page and glyphs): one material,
light inside its piece, one ivory press lit, violet nowhere (nothing here is alive or for sale). The ground's picture is
our own render of Lantern Row and its keeper (tools/blender/arc_tile.py), in place of the drawn lantern. Hard's one
accent stays an ember, on its own mark and road only.

Three takes, each in two states, over the street dimmed as a full screen is:
  A  two cards: today's layout kept and fixed. The tile on the left; Normal and Hard as two cards, a press on each.
  B  pick, then one press: the picture large on the left; on the right a Normal | Hard pick, what the pick holds, and
     one Fight press. Hard shut shows its lock on the pick and its reason under it.
  C  the banner: the street and its keeper across the top, Normal and Hard side by side under it, a press on each.
States: "shut" (Normal at its first stretch, Hard shut; the phone capture's state), "open" (Normal at its third
stretch, so Continue; Hard open at its first). One press lit: the hardest open choice the player's power meets.

    py tools/ui/arc_panel.py <out_dir> [A B C]

Writes <take>_shut.png, <take>_open.png, <take>_grey.png, <take>_small.png (568 x 320), and arc_sheet.png: today's
panel beside each take's shut state.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import style_frames as sf  # noqa: E402

sf.CHAMFER = True   # the frame is final with the shard cut (AR62, research's second look, 14:24)
REPO = sf.REPO
TILE = REPO / "build/handoff/UI/arc_panel/arc_tile.png"   # tools/blender/arc_tile.py, 1800 x 1350
TILE_PX = (1800, 1350)
TODAY = REPO / "build/captures/ar62/before/arc_panel.png"
W, H = sf.W, sf.H
T = dict(sf.TAKES["A"], key="A", dim=0.68)   # a full screen dims the world more than Home's panel (0.55)
S, M, L = T["sizes"]
INK, INK2 = T["ink"], T["ink2"]
RIM = "#4A4F5A"
RAISED = T["raised"]
LOW = T["panel"]["bottom"]
EMBER = "#FF7A4A"          # Hard's one accent (AR42's ember, lifted to read on graphite)
PRESS_INK = T["press"]["ink"]

STATES = {
    "shut": dict(normal=dict(at=1, rec="1,613"), hard=dict(shut="Beat the Lamplighter on Normal", rec="4,632")),
    "open": dict(normal=dict(at=3, rec="1,613"), hard=dict(at=1, rec="4,632")),
}
POWER = "6,620"
TAP = 66   # a press's least height: 44 pt on the small phone (568 x 320) is 66 here (research's must-fix 1, 2026-11-26)
HARD_WORDS = "Hard: enemies are 10 levels higher"   # Config.Stages.Offset.Hard


def met(rec):
    return int(POWER.replace(",", "")) >= int(rec.replace(",", ""))


def lit_choice(state):
    """The one press lit, and the mode B's pick opens on: a run in progress is never hidden (research's must-fix 2,
    2026-11-26), else the hardest open mode the player's power meets."""
    for which in ("hard", "normal"):
        if state[which].get("at", 1) > 1:
            return which
    hard = state["hard"]
    return "hard" if "at" in hard and met(hard["rec"]) else "normal"


# ---- pieces --------------------------------------------------------------------------------------------------------------
def glyph(P, kind, x, y, size, fill):
    k = size / 24
    g = f'<g transform="translate({x},{y}) scale({k:.4f})">'
    if kind == "back":       # a heavy chevron, pointing back
        g += f'<path d="M15.5 3.5 L7 12 L15.5 20.5" fill="none" stroke="{fill}" stroke-width="3.6" stroke-linecap="round" stroke-linejoin="round"/>'
    elif kind == "lock":     # shut: a thick shackle on a cut body, its keyhole cut through
        g += (f'<path d="M7.5 11 V7.5 A4.5 4.5 0 0 1 16.5 7.5 V11" fill="none" stroke="{fill}" stroke-width="2.8"/>'
              f'<path d="M5 11 H19 V19.5 L16.5 22 H5 Z M12 14 A1.7 1.7 0 0 0 11 17.1 V19 H13 V17.1 A1.7 1.7 0 0 0 12 14 Z" '
              f'fill="{fill}" fill-rule="evenodd"/>')
    elif kind == "chevron":  # Hard's mark: one upward chevron, cut on the shard's angle
        g += f'<path d="M1.5 18 L12 5 L22.5 18 L16.6 18 L12 12.2 L7.4 18 Z" fill="{fill}"/>'
    elif kind == "check":
        g += f'<path d="M5 12.5 L10 17.5 L19.5 7" fill="none" stroke="{fill}" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"/>'
    elif kind == "keeper":   # the last stretch's mark: a diamond, the keeper's
        g += f'<path d="M12 2 L22 12 L12 22 L2 12 Z" fill="{fill}"/>'
    g += "</g>"
    P.add(g)


def picture(P, cid, x, y, w, h, crop, r=10, shade=True):
    """The ground's render, cropped (cx, cy, cw, ch in the render's pixels), clipped to a card, a dark band at its foot
    for the name."""
    cx, cy, cw, ch = crop
    P.clip_rect(cid, x, y, w, h, r)
    shade_band = (f'<rect x="{x}" y="{y + h * 0.62:.1f}" width="{w}" height="{h * 0.38:.1f}" fill="url(#gShade)"/>'
                  if shade else "")
    P.add(f'<g clip-path="url(#{cid})"><svg x="{x}" y="{y}" width="{w}" height="{h}" viewBox="{cx} {cy} {cw} {ch}" '
          f'preserveAspectRatio="xMidYMid slice"><image href="{TILE.as_uri()}" width="{TILE_PX[0]}" height="{TILE_PX[1]}"/></svg>'
          f'{shade_band}</g>')
    P.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="none" stroke="{RIM}" stroke-width="1.5"/>')


def top_bar(P):
    """Back and the screen's name, beside Roblox's own buttons."""
    P.plate(262, 18, 104, TAP, r=12, fill=RAISED, stroke=RIM, sw=1.5, shadow=False)
    glyph(P, "back", 274, 39, 24, INK)
    P.text(302, 57.5, "Back", S, role="display")
    P.text(384, 60, "Festival of Battles", M, role="display")


def road(P, x, y, w, at, hard, size=28):
    """The run's four stretches, joined: cleared filled, the next ringed, the rest dim; the keeper's last, a diamond."""
    accent = EMBER if hard else INK
    n = 4
    step = (w - size) / (n - 1)
    cy = y + size / 2
    for k in range(n - 1):
        x0, x1 = x + k * step + size, x + (k + 1) * step
        done = k + 1 < at
        P.add(f'<rect x="{x0 + 3:.1f}" y="{cy - 1.5:.1f}" width="{x1 - x0 - 6:.1f}" height="3" rx="1.5" fill="{accent if done else RIM}"/>')
    for k in range(n):
        mx = x + k * step
        stage = k + 1
        if stage < at:
            P.plate(mx, y, size, size, r=7, fill=RAISED, stroke=RIM, sw=1.5, inner=False, shadow=False)
            glyph(P, "check", mx + size * 0.14, y + size * 0.14, size * 0.72, accent)
        elif stage == at:
            P.plate(mx - 3, y - 3, size + 6, size + 6, r=8, fill=RAISED, stroke=accent, sw=2.2, inner=False, shadow=False)
            if stage == n:
                glyph(P, "keeper", mx + size * 0.2, y + size * 0.2, size * 0.6, accent)
            else:
                P.text(mx + size / 2, y + size / 2 + 6.5, str(stage), S, fill=accent, anchor="middle")
        else:
            P.plate(mx, y, size, size, r=7, fill=LOW, stroke=RIM, sw=1.5, inner=False, shadow=False)
            if stage == n:
                glyph(P, "keeper", mx + size * 0.25, y + size * 0.25, size * 0.5, INK2)
            else:
                P.text(mx + size / 2, y + size / 2 + 6.5, str(stage), S, fill=INK2, anchor="middle", opacity=0.8)


def press(P, x, y, w, h, words, lit, hard=False):
    if lit:
        P.plate(x, y, w, h, r=10, fill="url(#gPress)", stroke=T["press"]["fill2"], sw=0, shadow=True)
        P.text(x + w / 2, y + h / 2 + M * 0.36, words, M, role="display", fill=PRESS_INK, anchor="middle")
    else:   # pressable, at rest: raised graphite; Hard's own carries its ember hairline
        P.plate(x, y, w, h, r=10, fill=RAISED, stroke=EMBER if hard else RIM, sw=1.6, shadow=False)
        P.text(x + w / 2, y + h / 2 + M * 0.36, words, M, role="display", anchor="middle")


def recommended(P, x, y, rec, anchor="end", dim=False):
    o = 0.55 if dim else 1.0
    P.text(x, y, f"{rec} CR", S, fill=INK, anchor=anchor, opacity=o)
    width = len(f"{rec} CR") * 9.6
    if anchor == "end":
        P.text(x - width - 8, y, "Recommended", S, fill=INK2, anchor="end", opacity=o)
    else:
        P.text(x, y - 20, "Recommended", S, fill=INK2, opacity=o)


def title(P, x, y, which, size=M, dim=False):
    if which == "hard":
        glyph(P, "chevron", x, y - size * 0.78, size * 0.8, EMBER if not dim else INK2)
        P.text(x + size * 0.9, y, "Hard", size, role="display", opacity=0.6 if dim else 1.0)
    else:
        P.text(x, y, "Normal", size, role="display")


def choice_card(P, x, y, w, h, which, st, lit, narrow=False):
    """A choice as a card, the whole card its press's room (A and C)."""
    shut = "shut" in st
    P.plate(x, y, w, h, r=10, fill=LOW if shut else RAISED, stroke=RIM, sw=1.5, shadow=False)
    title(P, x + 16, y + 38, which, dim=shut)
    recommended(P, x + w - 16, y + 36, st["rec"], dim=shut)
    if shut:
        glyph(P, "lock", x + 16, y + h * 0.62 - 17, 22, INK2)
        P.text(x + 46, y + h * 0.62, st["shut"], S, fill=INK2)
        return
    hard = which == "hard"
    bw = 136 if narrow else min(176, w * 0.42)
    road(P, x + 18, y + h - (44 if narrow else 48), w - bw - (54 if narrow else 66), st["at"], hard, size=26 if narrow else 28)
    P.text(x + w - 16 - bw / 2, y + h - 60, f"Stretch {st['at']} of 4", S, fill=INK2, anchor="middle")
    press(P, x + w - 16 - bw, y + h - 52, bw, 40, "Continue" if st["at"] > 1 else "Fight", lit, hard)


def foot(P, y, state, x0=34, x1=818):
    P.text(x0, y, "Your power", S, fill=INK2)
    P.text(x0 + 110, y, f"{POWER} CR", S, fill=INK)
    if "at" in state["hard"]:
        P.text(x1, y, HARD_WORDS, S, fill=INK2, anchor="end")


# ---- the takes -----------------------------------------------------------------------------------------------------------
def take_a(P, state):
    lit = lit_choice(state)
    P.plate(24, 96, 804, 296)
    picture(P, "tileA", 36, 108, 236, 272, (520, 330, 720, 830))
    P.text(50, 362, "Lantern Row", M, role="display")
    for i, which in enumerate(("normal", "hard")):
        choice_card(P, 284, 108 + i * 140, 532, 132, which, state[which], lit == which)
    foot(P, 428, state)


def take_b(P, state):
    lit = lit_choice(state)
    P.plate(24, 96, 804, 352)
    picture(P, "tileB", 36, 108, 420, 328, (350, 260, 1060, 828))
    P.text(54, 414, "Lantern Row", L, role="display")
    x, w = 470, 346
    pick = "hard" if lit == "hard" else "normal"
    # the pick: Normal | Hard, the chosen raised with an ivory hairline (the dock's rule)
    half = (w - 8) / 2
    for i, which in enumerate(("normal", "hard")):
        bx = x + i * (half + 8)
        on = which == pick
        shut = "shut" in state[which]
        P.plate(bx, 108, half, TAP, r=10, fill=RAISED if on else LOW, stroke=INK if on else RIM, sw=1.6 if on else 1.5,
                inner=on, shadow=False)
        if which == "hard" and shut:
            glyph(P, "lock", bx + half / 2 - 44, 130, 22, INK2)
            P.text(bx + half / 2 + 12, 150, "Hard", M, role="display", anchor="middle", opacity=0.6)
        elif which == "hard":
            glyph(P, "chevron", bx + half / 2 - 42, 128, 22, EMBER)
            P.text(bx + half / 2 + 12, 150, "Hard", M, role="display", anchor="middle")
        else:
            P.text(bx + half / 2, 150, "Normal", M, role="display", anchor="middle")
    st = state[pick]
    hard = pick == "hard"
    under = state["hard"]["shut"] if "shut" in state["hard"] else HARD_WORDS
    P.text(x + w - 4, 198, under, S, fill=INK2, anchor="end")
    # what the pick holds: recommended beside the player's own
    P.text(x + 4, 224, "Recommended", S, fill=INK2)
    P.text(x + 4, 252, f"{st['rec']} CR", M, fill=INK)
    P.text(x + w - 4, 224, "Your power", S, fill=INK2, anchor="end")
    P.text(x + w - 4, 252, f"{POWER} CR", M, fill=INK, anchor="end")
    P.add(f'<rect x="{x}" y="264" width="{w}" height="1.2" fill="{RIM}"/>')
    P.text(x + 4, 290, f"Stretch {st['at']} of 4", S, fill=INK2)
    road(P, x + 8, 302, w - 16, st["at"], hard, size=32)
    press(P, x, 366, w, TAP + 2, "Continue" if st["at"] > 1 else "Fight", True)


def take_c(P, state):
    lit = lit_choice(state)
    P.plate(24, 96, 804, 352)
    # the banner: the street and its keeper across, from his hat to his sash; the name on its left over a band that
    # darkens from the left
    x, y, w, h = 36, 108, 780, 176
    cw = 1800
    ch = cw * h / w
    P.clip_rect("tileC", x, y, w, h, 10)
    P.defs.append(f'<linearGradient id="gBand" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="{LOW}" stop-opacity="0.95"/>'
                  f'<stop offset="0.56" stop-color="{LOW}" stop-opacity="0"/></linearGradient>')
    P.add(f'<g clip-path="url(#tileC)"><svg x="{x}" y="{y}" width="{w}" height="{h}" viewBox="-180 470 {cw} {ch:.0f}" '
          f'preserveAspectRatio="xMidYMid slice"><image href="{TILE.as_uri()}" width="{TILE_PX[0]}" height="{TILE_PX[1]}"/></svg>'
          f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="url(#gBand)"/></g>')
    P.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="10" fill="none" stroke="{RIM}" stroke-width="1.5"/>')
    P.text(56, 206, "Lantern Row", L, role="display")
    P.text(58, 236, "Your power", S, fill=INK2)
    P.text(166, 236, f"{POWER} CR", S, fill=INK)
    for i, which in enumerate(("normal", "hard")):
        choice_card(P, 36 + i * 396, 294, 384, 142, which, state[which], lit == which, narrow=True)
    if "at" in state["hard"]:
        P.text(816, 466, HARD_WORDS, S, fill=INK2, anchor="end")


TAKES = {"A": ("two cards", take_a), "B": ("pick, then one press", take_b), "C": ("the banner", take_c)}


def page(key, state, grey=False):
    P = sf.Page(T, "A")
    sf.world(P, True)
    top_bar(P)
    TAKES[key][1](P, STATES[state])
    return P.svg(grey=grey)


def sheet_html(out, keys, faces):
    cells = [("Today", TODAY)] + [(f"{k}: {TAKES[k][0]}", out / f"{k}_shut.png") for k in keys]
    imgs = "".join(f'<figure><img src="{p.as_uri()}"><figcaption>{sf.esc(n)}</figcaption></figure>' for n, p in cells)
    return (f'<!doctype html><html><head><meta charset="utf-8"><style>{faces} body{{margin:0;background:#101114;'
            f'display:grid;grid-template-columns:852px 852px;gap:12px;padding:12px;font:600 18px "Builder Sans";color:#F3EEE4}}'
            f'figure{{margin:0}} img{{width:852px;height:480px;display:block}} figcaption{{padding:6px 2px}}</style></head>'
            f'<body>{imgs}</body></html>')


def main():
    out = Path(sys.argv[1]).resolve()
    keys = [k for k in sys.argv[2:] if k in TAKES] or list(TAKES)
    out.mkdir(parents=True, exist_ok=True)
    faces = sf.font_faces(["A"])
    for k in keys:
        for state in STATES:
            sf.shoot(sf.html(page(k, state), faces), out / f"{k}_{state}.png", W, H)
        sf.shoot(sf.html(page(k, "shut", grey=True), faces), out / f"{k}_grey.png", W, H)
        sf.shoot(sf.html(page(k, "shut"), faces, zoom=568 / W), out / f"{k}_small.png", 568, 320, scale=1)
        print("drew", k, TAKES[k][0])
    rows = (len(keys) + 2) // 2
    sf.shoot(sheet_html(out, keys, faces), out / "arc_sheet.png", 12 * 3 + 852 * 2, 12 + rows * (480 + 12 + 34), scale=1)


if __name__ == "__main__":
    main()
