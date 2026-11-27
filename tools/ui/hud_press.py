"""AR62, the press reopened on the director's word (2026-11-27, by 01:00): "that cooling CD is bad and that fist art is
very bad i want a unique cool art for skills or just the name but make it much better". Research's ask: both directions in
the same fight frame at phone size, each beside a shipped game's skill buttons, and the cooldown as a strip of states.

A, the skill's own art: the Haymaker's own shape, the square of chiselled ember bars that forms round the ram and is
   thrown open on the strike (tools/blender/rook_haymaker_art.py: a cream core, Rook's ember, an ink rim), drawn round a
   white-hot strike, one corner flung open, its chips flying. Each skill's art comes from its own effect's hero shape.
B, the name alone: HAYMAKER lettered as a title card, in Bangers (one of Roblox's faces), white into ember, a heavy ink
   line and a hard shadow, on one ember slash across the press.
Both lay their art on a dark ember face inside the gold ring, so it holds at the smallest phone.

The cooldown, both: the face comes back in its colour, clockwise from the top, behind a gold edge; what is still to
come stays dark and grey. The seconds left stand big in the middle, stroked. The last second turns the count gold and
lights the face's rim. Ready again, the press pops: it swells, flashes and throws a ring. The drained art under a small
count and the thin ring round the outside are gone.

    py tools/ui/hud_press.py <out_dir> <fight plate>

Writes press_states.png (A and B: ready, cooling at 5 s, the last second, the pop, firing, at three times), and for each
of A and B: <k>_close.png (the press's corner at three times), <k>_fight_small.png (F2 on the smallest phone) and
<k>_fight.png (1920 wide); then phone_pair_x4.png, the press's corner of both phone frames side by side, enlarged
four times by ffmpeg (nearest pixel), to judge them at the smallest phone.
"""
import math
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import style_frames as sf  # noqa: E402
import hud_finish as hf  # noqa: E402

COOL = 10                                       # seconds (src/shared/Definitions/Actions.luau, RookHaymaker.Cooldown)
INK = hf.GOLD["ink"]
BAR_INK = "#1E1B22"                             # the Haymaker bar's ink rim (rook_sheet.PALETTE["Ink"])
CREAM, EMBER, EMBER_SHADE = "#FFF1CC", "#FFA630", "#C2410E"
FACE = ((0, "#9A3414"), (0.55, "#4E140A"), (1, "#1C0604"))       # the press's face: an ember glow to near-black at its rim
FACE_COLD = ((0, "#4C4442"), (0.55, "#2A2423"), (1, "#110E0D"))
SWEEP = "#07090D"
EDGE = "#FFD04F"


def radial(P, stops, cx, cy, r):
    gid = P.uid("r")
    s = "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops)
    P.defs.append(f'<radialGradient id="{gid}" gradientUnits="userSpaceOnUse" cx="{cx:.2f}" cy="{cy:.2f}" r="{r:.2f}">'
                  f'{s}</radialGradient>')
    return f"url(#{gid})"


def once(P, key, d):
    if key not in "".join(P.defs):
        P.defs.append(d)


def pts(q):
    return " ".join(f"{x:.2f},{y:.2f}" for x, y in q)


# ---- A, the Haymaker's square, in a box where the face's radius is 27 ------------------------------------------------
# A first try cut the bars with the chisel's slits: at the press's size they read as a window's grid, the strike as its
# broken pane. The bars are clean brush strokes now, pointed at their far ends, and the strike breaks out of the square.
CORNERS = [(-19.0, -10.5), (12.5, -19.0), (19.5, 12.5), (-11.5, 19.0)]   # the square's corners, tilted and leaning back
OPEN = 1                                                                 # the corner flung open (top right)
BAR_W = 6.4


def bar_shape(a, b, w, over=(3.0, 3.0), trim=(0.0, 1.0), point=3.6):
    """A brush stroke from `a` to `b`, `w` wide, running `over` past each end, drawn to a point at its far end."""
    dx, dy = b[0] - a[0], b[1] - a[1]
    n = math.hypot(dx, dy)
    ux, uy = dx / n, dy / n
    nx, ny = -uy, ux
    t0, t1 = -over[0] + trim[0] * n, n * trim[1] + over[1]
    p = lambda t, s: (a[0] + ux * t + nx * s, a[1] + uy * t + ny * s)
    return [p(t0, -w / 2), p(t1 - point, -w / 2), p(t1, w * 0.1), p(t1 - point * 0.6, w / 2), p(t0, w / 2)], (t0, t1), p


def square(P):
    sides = []
    for i in range(4):
        a, b = CORNERS[i], CORNERS[(i + 1) % 4]
        trim = (0.0, 0.66) if i == OPEN - 1 else (0.36, 1.0) if i == OPEN else (0.0, 1.0)
        over = (3.6, 0.0) if i == OPEN - 1 else (0.0, 3.6) if i == OPEN else (3.6, 3.6)
        sides.append(bar_shape(a, b, BAR_W, over=over, trim=trim))
    for q, *_ in sides:   # the ink under them all, so the overlaps share one rim
        P.add(f'<polygon points="{pts(q)}" fill="{BAR_INK}" stroke="{BAR_INK}" stroke-width="3.2" stroke-linejoin="round"/>')
    for q, (t0, t1), p in sides:
        P.add(f'<polygon points="{pts(q)}" fill="{EMBER}"/>')
        # lit toward the strike, shaded away from it: a hard step each side of the ember (the corners run clockwise)
        P.add(f'<polygon points="{pts([p(t0, -BAR_W / 2), p(t1 - 4, -BAR_W / 2), p(t1 - 4, -1.4), p(t0, -1.4)])}" '
              f'fill="{EMBER_SHADE}"/>')
        P.add(f'<polygon points="{pts([p(t0, 0.5), p(t1 - 3.4, 0.5), p(t1 - 1.2, 1.6), p(t0, 2.4)])}" fill="{CREAM}"/>')
    # its chips, flung from the open corner
    cx, cy = CORNERS[OPEN]
    for (dx, dy, s, turn) in ((5.0, -2.0, 3.0, 20), (9.6, -5.6, 2.3, -15)):
        x, y = cx + dx, cy + dy
        q = [(x - s, y - s * 0.6), (x + s, y - s * 0.8), (x + s * 0.8, y + s * 0.7), (x - s * 0.9, y + s * 0.5)]
        P.add(f'<g transform="rotate({turn} {x:.2f} {y:.2f})"><polygon points="{pts(q)}" fill="{EMBER}" '
              f'stroke="{BAR_INK}" stroke-width="1.3" stroke-linejoin="round"/></g>')


def strike(P, hot=False):
    """The ram's strike: the punch's line in from the lower left, and a white-hot burst that breaks out of the square
    through its open corner, ink-rimmed, its rays uneven."""
    k = 1.12 if hot else 1.0
    for (x0, y0, x1, y1, w) in ((-30, 22, -4, 3, 3.2), (-30, 12, -7, -1, 2.0), (-24, 30, -2, 8, 2.0)):
        # each streak tapers from its tail to its head, under the burst
        dx, dy = x1 - x0, y1 - y0
        n = math.hypot(dx, dy)
        nx, ny = -dy / n, dx / n
        q = [(x0, y0), (x1 + nx * w / 2, y1 + ny * w / 2), (x1 + dx / n * 2, y1 + dy / n * 2), (x1 - nx * w / 2, y1 - ny * w / 2)]
        P.add(f'<polygon points="{pts(q)}" fill="{CREAM}" stroke="{BAR_INK}" stroke-width="1.6" stroke-linejoin="round"/>')
    rays = [(10, 19.0), (48, 9.0), (80, 13.0), (118, 7.5), (158, 11.0), (200, 7.5), (240, 10.5), (282, 8.0), (318, 12.5)]

    def star(scale, inner=5.2):
        q = []
        for i, (deg, out) in enumerate(rays):
            a = math.radians(deg - 90)
            nxt = rays[(i + 1) % len(rays)][0] + (360 if i == len(rays) - 1 else 0)
            m = math.radians((deg + nxt) / 2 - 90)
            q += [(math.cos(a) * out * scale * k, math.sin(a) * out * scale * k),
                  (math.cos(m) * inner * scale * k, math.sin(m) * inner * scale * k)]
        return q
    P.add(f'<circle r="{17 * k:.1f}" fill="{radial(P, ((0, "#FFF6D8"), (0.4, "#FFB848"), (1, "#FF7A1E")), 0, 0, 17 * k)}" '
          f'fill-opacity="0.6" filter="url(#glow)"/>')
    P.add(f'<polygon points="{pts(star(1.0))}" fill="{EMBER}" stroke="{BAR_INK}" stroke-width="2.6" stroke-linejoin="round"/>')
    P.add(f'<polygon points="{pts(star(0.7, 4.2))}" fill="{CREAM}"/>')
    P.add(f'<circle r="{4.6 * k:.2f}" fill="#FFFFFF"/>')


def art_a(P, cx, cy, ri, state):
    k = ri / 27
    cid = P.uid("c")
    P.defs.append(f'<clipPath id="{cid}"><circle cx="{cx}" cy="{cy}" r="{ri:.2f}"/></clipPath>')
    P.add(f'<g clip-path="url(#{cid})"><g transform="translate({cx},{cy}) scale({k:.4f})">')
    square(P)
    P.add('<g transform="translate(0.5,-0.5)">')
    strike(P, hot=state == "firing")
    P.add("</g></g></g>")


# ---- B, the name, lettered ------------------------------------------------------------------------------------------------
NAME = "HAYMAKER"
B_FACE = ("Bangers", "Bangers-Regular.ttf")


def art_b(P, cx, cy, ri, state):
    k = ri / 27
    P.add(f'<g transform="translate({cx},{cy}) scale({k:.4f}) rotate(-9)">')
    # one ember slash behind the word, brushed: its ends cut on a slant
    slash = [(-38, -3.5), (35, -9.5), (39, 4.5), (-35, 9.0)]
    P.add(f'<polygon points="{pts(slash)}" fill="{BAR_INK}" stroke="{BAR_INK}" stroke-width="2.6" stroke-linejoin="round"/>')
    P.add(f'<polygon points="{pts(slash)}" fill="{P.lin(("#FF8A2A", "#D2380F"))}"/>')
    P.add(f'<polygon points="{pts([(-36, -2.2), (34.5, -8.2), (35, -6.2), (-35.5, -0.6)])}" fill="#FFC46A"/>')
    hot = state == "firing"
    fill = P.lin(("#FFFFFF", "#FFFFFF", "#FFF0B0") if hot else ("#FFFFFF", "#FFF2C2", "#FFC845"))
    common = (f'x="0" y="7.6" font-family="{B_FACE[0]}" font-size="21" text-anchor="middle" textLength="70" '
              f'lengthAdjust="spacingAndGlyphs" stroke-linejoin="round"')
    P.add(f'<text {common} dx="1.4" dy="2.0" fill="{BAR_INK}" stroke="{BAR_INK}" stroke-width="4.4">{NAME}</text>')
    P.add(f'<text {common} fill="{fill}" stroke="{BAR_INK}" stroke-width="3.6" paint-order="stroke">{NAME}</text>')
    P.add("</g>")


# ---- the press, with the new cooldown -----------------------------------------------------------------------------------
def press(P, art, state="ready", left=None, key=False):
    cx, cy, r = hf.SIG
    ri = r - 6.1
    cooling = state in ("cooling", "last")
    firing, pop = state == "firing", state == "pop"
    if not cooling:   # light only on what matters now: the press when it can be pressed
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{r + (11 if firing or pop else 7)}" fill="{hf.GOLD["glow"]}" '
              f'fill-opacity="{0.75 if firing or pop else 0.5}" filter="url(#glow)"/>')
    if pop:   # ready again: a ring thrown wide, a second fainter behind it
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{r + 10}" fill="none" stroke="#FFFFFF" stroke-opacity="0.9" stroke-width="2.6"/>')
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{r + 16}" fill="none" stroke="#FFE7A0" stroke-opacity="0.45" stroke-width="1.4"/>')
    if firing:
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{r + 9}" fill="none" stroke="#FFFFFF" stroke-opacity="0.85" stroke-width="2.2"/>')
    scale = 0.94 if firing else 1.08 if pop else 1.0
    if scale != 1:
        P.add(f'<g transform="translate({cx},{cy}) scale({scale}) translate({-cx},{-cy})">')
    if state == "cooling":
        fam = dict(hf.GOLD, rim=("#E5D3A2", "#C2A866"), dark="#4A3410")
    elif firing or pop:
        fam = dict(hf.GOLD, rim=("#FFFFFF", "#FFF0B0"))
    else:
        fam = hf.GOLD
    face = radial(P, FACE_COLD if cooling else FACE, cx - 3, cy - 4, ri * 1.15)
    P.press(cx - r, cy - r, 2 * r, 2 * r, r, fam, face, rings=(1.2, 2.0, 0.9, 2.0), grain=0.1)
    if cooling:
        once(P, 'id="cold"', '<filter id="cold"><feColorMatrix type="saturate" values="0.1"/></filter>')
        share = 1 - left / COOL                  # the charge back, clockwise from the top
        a = 2 * math.pi * share
        R1 = ri + 1
        ex, ey = cx + ri * math.sin(a), cy - ri * math.cos(a)
        fx, fy = cx + R1 * math.sin(a), cy - R1 * math.cos(a)
        face_clip, back, still = P.uid("c"), P.uid("c"), P.uid("c")
        # cooling, everything stays on the face, the name's ends too; what has come back, and what is still to come
        P.defs.append(f'<clipPath id="{face_clip}"><circle cx="{cx}" cy="{cy}" r="{ri:.2f}"/></clipPath>')
        P.defs.append(f'<clipPath id="{back}"><path d="M{cx},{cy} L{cx},{cy - R1:.2f} A{R1:.2f} {R1:.2f} 0 '
                      f'{1 if share > 0.5 else 0} 1 {fx:.2f},{fy:.2f} Z"/></clipPath>')
        P.defs.append(f'<clipPath id="{still}"><path d="M{cx},{cy} L{fx:.2f},{fy:.2f} A{R1:.2f} {R1:.2f} 0 '
                      f'{1 if share < 0.5 else 0} 1 {cx},{cy - R1:.2f} Z"/></clipPath>')
        P.add(f'<g clip-path="url(#{face_clip})"><g clip-path="url(#{still})"><g filter="url(#cold)" opacity="0.4">')
        art(P, cx, cy, ri, state)
        P.add(f'</g><circle cx="{cx}" cy="{cy}" r="{ri:.2f}" fill="{SWEEP}" fill-opacity="0.35"/></g>')
        P.add(f'<g clip-path="url(#{back})" opacity="0.8">')
        art(P, cx, cy, ri, state)
        P.add("</g>")
        P.add(f'<line x1="{cx}" y1="{cy}" x2="{ex:.2f}" y2="{ey:.2f}" stroke="{EDGE}" stroke-width="1.8" '
              f'stroke-linecap="round"/></g>')
        if state == "last":   # the last second: the face's rim lit, the count gold
            P.add(f'<circle cx="{cx}" cy="{cy}" r="{ri - 0.9:.2f}" fill="none" stroke="{EDGE}" stroke-width="1.8" '
                  f'stroke-opacity="0.95"/>')
            P.add(f'<circle cx="{cx}" cy="{cy}" r="{ri - 0.9:.2f}" fill="none" stroke="{EDGE}" stroke-width="4" '
                  f'stroke-opacity="0.5" filter="url(#glow)"/>')
        count = P.lin(("#FFFFFF", "#FFE27A", "#FFB43C")) if state == "last" else "#FFFFFF"
        P.word(cx, cy + 10.8, str(left), 31, fill=count, stroke=INK, anchor="middle", ratio=0.2)
    else:
        art(P, cx, cy, ri, state)
        if pop:
            P.add(f'<circle cx="{cx}" cy="{cy}" r="{ri:.2f}" fill="#FFFFFF" fill-opacity="0.3"/>')
    if scale != 1:
        P.add("</g>")
    if key:   # on a keyboard: the key on a chip at the press's top left
        T = P.T
        kx, ky, ks = cx - r * 0.86 - 8, cy - r * 0.86 - 8, 16
        P.press(kx, ky, ks, ks, 2.3, T["steel"], P.lin(T["press"]), rings=(0.8, 0.7, 0.4, 0.8))
        P.word(kx + ks / 2, ky + 11.7, "R", 10.5, anchor="middle", stroke=T["steel"]["ink"], ratio=0.2)


TARGETS = {"A": ("A, the skill's own art", art_a), "B": ("B, the name alone", art_b)}
CELLS = [("ready", "ready", None), ("cooling, 5 s left", "cooling", 5), ("the last second", "last", 1),
         ("ready again: the pop", "pop", None), ("firing", "firing", None), ("ready, on a keyboard", "ready", None)]


def states(T, plate):
    cw, ch, gap, side, top = 128, 104, 6, 120, 20
    P = hf.Page(T)
    uri = Path(plate).resolve().as_uri()
    sw, sh = side + len(CELLS) * (cw + gap) + gap, top + len(TARGETS) * (ch + gap) + gap
    P.add(f'<rect width="{sw}" height="{sh}" fill="#15191F"/>')
    for j, (name, *_) in enumerate(CELLS):
        P.add(f'<text x="{side + gap + j * (cw + gap) + cw / 2}" y="{top - 6}" font-family="Builder Sans" font-size="10" '
              f'fill="#E8EDF4" text-anchor="middle">{sf.esc(name)}</text>')
    for i, (label, art) in enumerate(TARGETS.values()):
        y = top + gap + i * (ch + gap)
        P.add(f'<text x="{side - 4}" y="{y + ch / 2 + 3}" font-family="Builder Sans" font-size="10" fill="#E8EDF4" '
              f'text-anchor="end">{sf.esc(label)}</text>')
        for j, (name, state, left) in enumerate(CELLS):
            keep, P.parts = P.parts, []
            P.add(f'<image href="{uri}" x="0" y="0" width="{hf.W}" height="{hf.H}"/>')
            press(P, art, state, left, key="keyboard" in name)
            inner, P.parts = "".join(P.parts), keep
            P.add(f'<svg x="{side + gap + j * (cw + gap)}" y="{y}" width="{cw}" height="{ch}" viewBox="-17 108 {cw} {ch}">'
                  f'{inner}</svg>')
    return P.svg(sw, sh), sw, sh


def main():
    out, plate = Path(sys.argv[1]).resolve(), sys.argv[2]
    out.mkdir(parents=True, exist_ok=True)
    T = hf.TAKES["F2"]       # research's pick (d11942a3)
    css = hf.faces() + f'@font-face{{font-family:"{B_FACE[0]}";src:url("{(sf.FONTS / B_FACE[1]).as_uri()}")}}'
    svg, sw, sh = states(T, plate)
    sf.shoot(sf.html(svg, css, sw, sh), out / "press_states.png", sw, sh, scale=3)
    keep = hf.signature
    try:
        for k, (_, art) in TARGETS.items():
            hf.signature = lambda P, state="ready", key=False, art=art: press(P, art, state, key=key)
            svg = hf.fight(T, plate)
            close = svg.replace(f'viewBox="0 0 {hf.W} {hf.H}"', 'viewBox="0 36 560 176"').replace(
                f'width="{hf.W}" height="{hf.H}"', 'width="560" height="176"', 1)
            sf.shoot(sf.html(close, css, 560, 176), out / f"{k}_close.png", 560, 176, scale=3)
            sf.shoot(sf.html(svg, css, hf.W, hf.H), out / f"{k}_fight.png", hf.W, hf.H, scale=hf.SCALE)
            sf.shoot(sf.html(svg, css, hf.W, hf.H, zoom=568 / hf.W), out / f"{k}_fight_small.png", 568,
                     round(hf.H * 568 / hf.W), scale=1)
            print("drew", k)
    finally:
        hf.signature = keep
    corner = "crop=150:110:0:58,scale=600:440:flags=neighbor"   # the press and Auto on the 568-wide frame, x4
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(out / "A_fight_small.png"), "-i", str(out / "B_fight_small.png"),
                    "-filter_complex", f"[0]{corner}[a];[1]{corner}[b];[a][b]hstack", str(out / "phone_pair_x4.png")],
                   check=True)
    print("drew phone_pair_x4")


if __name__ == "__main__":
    main()
