"""AR62's press, round 3: the disc is the art (research's study before the third round, docs/asset-requests.md, AR62,
2026-11-27). Two targets for the pair research brings the director, both the Haymaker's Strike rendered from Rook's
make (tools/blender/press_art.py):
- T1, the move rendered: the fist lit, driving at you through its ember burst. The burst is drawn in the Haymaker's own
  stroke (a cream core, Rook's ember, an ink rim: tools/blender/rook_haymaker_art.py), and the art fills the disc.
- T2, the impact frame: the same instant in two tones, the fist one ink silhouette against a white-hot burst.
For both, the gold drops to a thin ring and the shared cooldown stays. Cooling, the art greys under a dark veil and
comes back clockwise from the top behind a gold edge, the ring's arc lit as it comes, the count big and white. The last
second is gold; ready again, the pop; firing, the press shrinks inside a white ring.

    py tools/ui/hud_press_art.py <out> <render.png> <fight plate> [fist_x fist_y zoom]

`fist_x fist_y`: where the fist is in the render, 0 to 1 from its top left; `zoom`: the render's width in disc
diameters. Writes press_states.png (T1 and T2 in every state, at 3x), fight_T1.png, fight_T2.png, their _small
(the smallest phone) and phone_x4.png (both presses from the smallest phone, enlarged).
"""
import math
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import style_frames as sf  # noqa: E402
import hud_finish as hf  # noqa: E402
import hud_press as hp  # noqa: E402

EMBER = "#FFA630"                                   # Rook's glow (his recipe's tint)
CORE, HOT_EMBER, RIM = "#FFF1CC", "#F2701C", "#1E1B22"   # the Haymaker's stroke: core, ember, ink (rook_haymaker_art.py)
DARK = ((0, "#62200A"), (0.45, "#2C0D05"), (1, "#0B0606"))     # T1's ground behind the burst
WHITE_HOT = ((0, "#FFFFFF"), (0.32, "#FFF7DC"), (0.68, "#FFC45A"), (1, "#E8561A"))   # T2's
SILHOUETTE = "#140D12"
RING = ("#FFF1B8", "#F2B636", "#9A6410")            # the thin ring, light to dark
THIN = 4.0                                          # the ring's width, points: the face's radius is the press's less this


def ground(P, stops, fx, fy, r):
    return hp.radial(P, stops, fx, fy, r)


def shards(P, fx, fy, ri, seed, count, layers, reach=(0.3, 1.5), width=(0.07, 0.16)):
    """Strokes thrown out from the fist: each a long wedge, drawn in `layers` from the widest (fill, width share)."""
    rng = random.Random(seed)
    turn = rng.uniform(0, 2 * math.pi)
    out = []
    for i in range(count):
        a = turn + 2 * math.pi * (i + rng.uniform(-0.3, 0.3)) / count
        r0, r1 = ri * reach[0] * rng.uniform(0.8, 1.3), ri * reach[1] * rng.uniform(0.85, 1.1)
        w = ri * rng.uniform(*width)
        ux, uy = math.cos(a), math.sin(a)
        for fill, share in layers:
            h = w * share
            out.append(f'<path d="M{fx + ux * r0:.2f},{fy + uy * r0:.2f} L{fx + ux * r1 - uy * h:.2f},{fy + uy * r1 + ux * h:.2f} '
                       f'L{fx + ux * (r1 + w):.2f},{fy + uy * (r1 + w):.2f} L{fx + ux * r1 + uy * h:.2f},{fy + uy * r1 - ux * h:.2f} Z" '
                       f'fill="{fill}"/>')
    P.add("".join(out))


def picture(P, uri, cx, cy, ri, at, silhouette=False):
    """The render laid so its fist lands at the disc's chosen point."""
    fx, fy, zoom, (tx, ty) = at
    size = zoom * 2 * ri
    x, y = cx + tx * ri - fx * size, cy + ty * ri - fy * size
    filt = ""
    if silhouette:
        fid = P.uid("s")
        P.defs.append(f'<filter id="{fid}" x="0" y="0" width="100%" height="100%"><feFlood flood-color="{SILHOUETTE}"/>'
                      f'<feComposite in2="SourceAlpha" operator="in"/></filter>')
        filt = f' filter="url(#{fid})"'
    P.add(f'<image href="{uri}" x="{x:.2f}" y="{y:.2f}" width="{size:.2f}" height="{size:.2f}"{filt}/>')


def art(P, take, cx, cy, ri, uri, at):
    """The disc's whole picture, clipped to the face."""
    cid = P.uid("c")
    P.defs.append(f'<clipPath id="{cid}"><circle cx="{cx}" cy="{cy}" r="{ri:.2f}"/></clipPath>')
    fx, fy = cx + at[3][0] * ri, cy + at[3][1] * ri
    P.add(f'<g clip-path="url(#{cid})">')
    if take == "T1":
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{ri:.2f}" fill="{ground(P, DARK, fx, fy, ri * 1.4)}"/>')
        shards(P, fx, fy, ri, 7, 9, [(RIM, 1.0), (HOT_EMBER, 0.62), (CORE, 0.26)])
        P.add(f'<circle cx="{fx:.2f}" cy="{fy:.2f}" r="{ri * 0.5:.2f}" fill="{EMBER}" fill-opacity="0.55" filter="url(#glow)"/>')
        picture(P, uri, cx, cy, ri, at)
    else:
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{ri:.2f}" fill="{ground(P, WHITE_HOT, fx, fy, ri * 1.35)}"/>')
        shards(P, fx, fy, ri, 11, 16, [(SILHOUETTE, 1.0)], reach=(0.78, 1.6), width=(0.02, 0.05))
        picture(P, uri, cx, cy, ri, at, silhouette=True)
    P.add("</g>")


def ring(P, cx, cy, r, lit=None, hot=False):
    """The thin ring: an ink line, a gold band, an ink line. `lit`: the share of its arc lit gold, clockwise from the top."""
    band = r - THIN / 2
    fill = "#FFFFFF" if hot else P.lin(RING[:2] + RING[2:], x2=0, y2=1)
    P.add(f'<circle cx="{cx}" cy="{cy}" r="{r - 0.6:.2f}" fill="none" stroke="{hp.INK}" stroke-width="1.4"/>'
          f'<circle cx="{cx}" cy="{cy}" r="{band:.2f}" fill="none" stroke="{fill}" stroke-width="{THIN - 1.6:.2f}"/>'
          f'<circle cx="{cx}" cy="{cy}" r="{r - THIN + 0.4:.2f}" fill="none" stroke="{hp.INK}" stroke-width="1.0"/>')
    if lit is not None:   # cooling: the band dimmed, its arc lit as the press comes back
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{band:.2f}" fill="none" stroke="#3A3226" stroke-width="{THIN - 1.6:.2f}"/>')
        if lit > 0:
            a = 2 * math.pi * lit
            P.add(f'<path d="M{cx},{cy - band:.2f} A{band:.2f} {band:.2f} 0 {1 if a > math.pi else 0} 1 '
                  f'{cx + band * math.sin(a):.2f},{cy - band * math.cos(a):.2f}" fill="none" stroke="{hp.EDGE}" '
                  f'stroke-width="{THIN - 1.4:.2f}"/>')


def press(P, take, uri, at, state="ready", left=None, key=False):
    cx, cy, r = hf.SIG
    ri = r - THIN
    cooling = state in ("cooling", "last")
    firing, pop = state == "firing", state == "pop"
    if not cooling:   # light only on what matters now
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{r + (11 if firing or pop else 6)}" fill="{hf.GOLD["glow"]}" '
              f'fill-opacity="{0.7 if firing or pop else 0.42}" filter="url(#glow)"/>')
    if pop:
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{r + 10}" fill="none" stroke="#FFFFFF" stroke-opacity="0.9" stroke-width="2.6"/>')
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{r + 16}" fill="none" stroke="#FFE7A0" stroke-opacity="0.45" stroke-width="1.4"/>')
    if firing:
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{r + 9}" fill="none" stroke="#FFFFFF" stroke-opacity="0.85" stroke-width="2.2"/>')
    scale = 0.94 if firing else 1.08 if pop else 1.0
    if scale != 1:
        P.add(f'<g transform="translate({cx},{cy}) scale({scale}) translate({-cx},{-cy})">')
    P.add(f'<circle cx="{cx}" cy="{cy}" r="{r:.2f}" fill="{hp.INK}"/>')
    if cooling:
        a = 2 * math.pi * (1 - left / hp.COOL)
        grey = P.uid("g")
        P.defs.append(f'<filter id="{grey}"><feColorMatrix type="saturate" values="0"/><feComponentTransfer>'
                      f'<feFuncR type="linear" slope="0.42"/><feFuncG type="linear" slope="0.42"/>'
                      f'<feFuncB type="linear" slope="0.46"/></feComponentTransfer></filter>')
        P.add(f'<g filter="url(#{grey})">')
        art(P, take, cx, cy, ri, uri, at)
        P.add("</g>")
        R1 = ri + 1
        back = P.uid("c")
        P.defs.append(f'<clipPath id="{back}"><path d="M{cx},{cy} L{cx},{cy - R1:.2f} A{R1:.2f} {R1:.2f} 0 '
                      f'{1 if a > math.pi else 0} 1 {cx + R1 * math.sin(a):.2f},{cy - R1 * math.cos(a):.2f} Z"/></clipPath>')
        P.add(f'<g clip-path="url(#{back})">')
        art(P, take, cx, cy, ri, uri, at)
        P.add("</g>")
        P.add(f'<line x1="{cx}" y1="{cy}" x2="{cx + ri * math.sin(a):.2f}" y2="{cy - ri * math.cos(a):.2f}" stroke="{hp.EDGE}" '
              f'stroke-width="1.8" stroke-linecap="round"/>')
        ring(P, cx, cy, r, lit=1.0 if state == "last" else 1 - left / hp.COOL)
        if state == "last":
            P.add(f'<circle cx="{cx}" cy="{cy}" r="{r - THIN / 2:.2f}" fill="none" stroke="{hp.EDGE}" stroke-width="4" '
                  f'stroke-opacity="0.5" filter="url(#glow)"/>')
        count = P.lin(("#FFFFFF", "#FFE27A", "#FFB43C")) if state == "last" else "#FFFFFF"
        P.word(cx, cy + 10.8, str(left), 31, fill=count, stroke=hp.INK, anchor="middle", ratio=0.2)
    else:
        art(P, take, cx, cy, ri, uri, at)
        if pop:
            P.add(f'<circle cx="{cx}" cy="{cy}" r="{ri:.2f}" fill="#FFFFFF" fill-opacity="0.22"/>')
        ring(P, cx, cy, r, hot=firing or pop)
    if scale != 1:
        P.add("</g>")
    if key:
        T = P.T
        kx, ky, ks = cx - r * 0.86 - 8, cy - r * 0.86 - 8, 16
        P.press(kx, ky, ks, ks, 2.3, T["steel"], P.lin(T["press"]), rings=(0.8, 0.7, 0.4, 0.8))
        P.word(kx + ks / 2, ky + 11.7, "R", 10.5, anchor="middle", stroke=T["steel"]["ink"], ratio=0.2)


def grid(T, plate, uri, at, rows, cols):
    """Rows (label, take); columns (label, state, seconds left, on a keyboard); each cell the press over the same ground."""
    cw, ch, gap, side, top = 128, 104, 6, 150, 20
    P = hf.Page(T)
    ground_uri = Path(plate).resolve().as_uri()
    sw, sh = side + len(cols) * (cw + gap) + gap, top + len(rows) * (ch + gap) + gap
    P.add(f'<rect width="{sw}" height="{sh}" fill="#15191F"/>')
    for j, (label, *_) in enumerate(cols):
        P.add(f'<text x="{side + gap + j * (cw + gap) + cw / 2}" y="{top - 6}" font-family="Builder Sans" font-size="10" '
              f'fill="#E8EDF4" text-anchor="middle">{sf.esc(label)}</text>')
    for i, (label, take) in enumerate(rows):
        y = top + gap + i * (ch + gap)
        P.add(f'<text x="{side - 4}" y="{y + ch / 2 + 3}" font-family="Builder Sans" font-size="10" fill="#E8EDF4" '
              f'text-anchor="end">{sf.esc(label)}</text>')
        for j, (_, state, left, key) in enumerate(cols):
            keep, P.parts = P.parts, []
            P.add(f'<image href="{ground_uri}" x="0" y="0" width="{hf.W}" height="{hf.H}"/>')
            press(P, take, uri, at, state, left, key)
            inner, P.parts = "".join(P.parts), keep
            P.add(f'<svg x="{side + gap + j * (cw + gap)}" y="{y}" width="{cw}" height="{ch}" viewBox="-17 108 {cw} {ch}">'
                  f'{inner}</svg>')
    return P.svg(sw, sh), sw, sh


def main():
    out, render, plate = Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve(), sys.argv[3]
    fx, fy, zoom = (float(v) for v in sys.argv[4:7]) if len(sys.argv) > 6 else (0.5, 0.5, 1.3)
    at = (fx, fy, zoom, (-0.08, -0.06))   # the fist a little up and left of the middle: the burst has room to throw
    out.mkdir(parents=True, exist_ok=True)
    T = hf.TAKES["F2"]
    css = hf.faces()
    uri = render.as_uri()
    cols = [("ready", "ready", None, False), ("cooling, 5 s left", "cooling", 5, False), ("the last second", "last", 1, False),
            ("ready again: the pop", "pop", None, False), ("firing", "firing", None, False),
            ("ready, on a keyboard", "ready", None, True)]
    svg, sw, sh = grid(T, plate, uri, at, [("T1, the move rendered", "T1"), ("T2, the impact frame", "T2")], cols)
    sf.shoot(sf.html(svg, css, sw, sh), out / "press_states.png", sw, sh, scale=3)
    keep = hf.signature
    for take in ("T1", "T2"):
        try:
            hf.signature = lambda P, state="ready", key=False, take=take: press(P, take, uri, at, state, key=key)
            svg = hf.fight(T, plate)
        finally:
            hf.signature = keep
        sf.shoot(sf.html(svg, css, hf.W, hf.H), out / f"fight_{take}.png", hf.W, hf.H, scale=hf.SCALE)
        sf.shoot(sf.html(svg, css, hf.W, hf.H, zoom=568 / hf.W), out / f"fight_small_{take}.png", 568,
                 round(hf.H * 568 / hf.W), scale=1)
        hp.enlarge(out / f"fight_small_{take}.png", out / f"phone_x4_{take}.png", crop="150:110:0:58")
    print("drew the press's art, T1 and T2")


if __name__ == "__main__":
    main()
