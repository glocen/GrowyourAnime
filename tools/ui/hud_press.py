"""AR62, the signature press: the skill's name, lettered (the director, 2026-11-27, by 01:00: "that cooling CD is bad and
that fist art is very bad i want a unique cool art for skills or just the name but make it much better").

Research picked B, the name alone (1a516afc), over A, the skill's own art (948e7269; the pair's pictures stay in
build/handoff/UI/hud_overhaul/press/, A's code in git). This is B's finish, with the pick's three must-fixes:
    1. cooling, the count and the word never cut each other: the word steps out whole and the count takes the disc;
    2. the same lettering holds the long names, on two lines at a readable height (LANTERN BURST, the longest at launch;
       HANDS OF THE VOID, the roster's longest);
    3. a clear gap between the word and Auto.

The name is set in Bangers (one of Roblox's faces), white into gold, a heavy ink line and a hard shadow, on one ember slash
across a dark ember face inside the gold ring. A name goes on one line when it fits the line at size 17 or more, and
otherwise on two, split where the longer line is shortest, at 18 at most. The widths are Bangers' own, measured in Chrome.

The cooldown: the word steps out, and the face comes back in its ember, clockwise from the top, behind a gold edge, over
a grey face. The seconds left stand big in the middle, stroked. The last second turns the count gold and lights the face's
rim. Ready again, the word steps back in as the press swells, flashes and throws a ring.

    py tools/ui/hud_press.py <out_dir> <fight plate>

Writes, into <out_dir>:
- press_states.png: HAYMAKER ready, cooling at 5 s, in the last second, ready again, firing and on a keyboard, at 3x;
- press_names.png: each launch signature and HANDS OF THE VOID, ready, cooling and firing, at 3x; and
  press_names_phone_x4.png, the same ready at the smallest phone, enlarged four times (nearest pixel, by ffmpeg);
- close.png (the press's corner at 3x), fight.png (1920 wide), fight_small.png (the smallest phone) and phone_x4.png
  (its corner, enlarged four times);
- images/, for the game (Slate.Press.Art.Images): each launch signature's name as one transparent picture,
  Press<Name>.png, and the face, PressFace.png and PressFaceCold.png, each 256 px for the press's 80 points.
It prints each name's lines and size, and the narrowest gap between a name and Auto.
"""
import json
import math
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import style_frames as sf  # noqa: E402
import hud_finish as hf  # noqa: E402

COOL = 10                                       # seconds (src/shared/Definitions/Actions.luau, RookHaymaker.Cooldown)
INK = hf.GOLD["ink"]
BAR_INK = "#1E1B22"                             # the Haymaker bar's ink (rook_sheet.PALETTE["Ink"])
FACE = ((0, "#9A3414"), (0.55, "#4E140A"), (1, "#1C0604"))       # the press's face: an ember glow to near-black at its rim
FACE_COLD = ((0, "#4C4442"), (0.55, "#2A2423"), (1, "#110E0D"))
EDGE = "#FFD04F"

FONT = ("Bangers", "Bangers-Regular.ttf")
CAP = 0.75            # Bangers' caps over its em (measured in Chrome: 75 of 100)
LINE = 62             # the widest a line may be, in the face's units (its radius 27): the slash stops well short of Auto
SQUEEZE = 0.94        # a line may be drawn down to 94% of its own width
ONE = (17, 19)        # a one-line name's size: at least, at most
TWO = 18              # a two-line name's size, at most
LAUNCH = {"Haymaker": "Rook", "Scarf Step": "Kirra", "Lantern Burst": "Pip", "Ground Wire": "Watt", "Held Note": "Lyric"}
LONGEST = "Hands of the Void"                   # Umbriel's (docs/roster.md), the roster's longest
BOX = 80                                        # the points round the press's middle each game picture covers


def radial(P, stops, cx, cy, r):
    gid = P.uid("r")
    s = "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops)
    P.defs.append(f'<radialGradient id="{gid}" gradientUnits="userSpaceOnUse" cx="{cx:.2f}" cy="{cy:.2f}" r="{r:.2f}">'
                  f'{s}</radialGradient>')
    return f"url(#{gid})"


def pts(q):
    return " ".join(f"{x:.2f},{y:.2f}" for x, y in q)


# ---- the name's lines, by Bangers' own widths -------------------------------------------------------------------------
def measure(texts):
    """Each text's width in Bangers at one em, from Chrome's own layout of the face."""
    font = (sf.FONTS / FONT[1]).as_uri()
    page = (f'<!doctype html><html><head><meta charset="utf-8"><style>@font-face{{font-family:"M";src:url("{font}")}}'
            f'</style></head><body><pre id="out"></pre><script>document.fonts.load(\'100px "M"\').then(() => {{'
            f'const c = document.createElement("canvas").getContext("2d"); c.font = \'100px "M"\'; const r = {{}};'
            f'for (const t of {json.dumps(sorted(texts))}) r[t] = c.measureText(t).width;'
            f'document.getElementById("out").textContent = JSON.stringify(r);}});</script></body></html>')
    with tempfile.TemporaryDirectory() as tmp:
        p = Path(tmp) / "measure.html"
        p.write_text(page, encoding="utf-8")
        dom = subprocess.run([sf.CHROME, "--headless=new", "--disable-gpu", "--allow-file-access-from-files",
                              f"--user-data-dir={Path(tmp) / 'profile'}", "--virtual-time-budget=4000", "--dump-dom",
                              p.as_uri()], capture_output=True, text=True, timeout=120, check=True).stdout
    got = json.loads(dom[dom.index('<pre id="out">') + 14:dom.index("</pre>")].replace("&quot;", '"'))
    return {t: w / 100 for t, w in got.items()}


def splits(name):
    words = name.upper().split()
    return [(" ".join(words[:i]), " ".join(words[i:])) for i in range(1, len(words))]


def layout(name, widths):
    """The name's lines and size: one line at 17 or more, else two, split where the longer line is shortest."""
    up = name.upper()
    one = min(ONE[1], LINE / (widths[up] * SQUEEZE))
    if one >= ONE[0] or " " not in up:
        return [up], one
    w, lines = min((max(widths[a], widths[b]), [a, b]) for a, b in splits(name))
    return lines, min(TWO, LINE / (w * SQUEEZE))


def slash_shape(lines, size, widths):
    """The ember slash under the lines: as wide as the widest line and a little more, its ends brushed on a slant."""
    wide = max(min(widths[t] * size, LINE) for t in lines)
    hw = min(wide / 2 + 3.5, LINE / 2 + 3)
    hh = 6.4 if len(lines) == 1 else 10.6
    return [(-hw - 2, -hh + 1), (hw - 2, -hh - 2), (hw + 2, hh - 1), (-hw + 2, hh + 1)], hw, hh


TURN = -9   # the name's slant, degrees


def lettering(P, cx, cy, ri, name, widths, hot=False):
    lines, size = layout(name, widths)
    k = ri / 27
    P.add(f'<g transform="translate({cx},{cy}) scale({k:.4f}) rotate({TURN})">')
    slash, hw, hh = slash_shape(lines, size, widths)
    P.add(f'<polygon points="{pts(slash)}" fill="{BAR_INK}" stroke="{BAR_INK}" stroke-width="2.6" stroke-linejoin="round"/>')
    P.add(f'<polygon points="{pts(slash)}" fill="{P.lin(("#FF8A2A", "#D2380F"))}"/>')
    P.add(f'<polygon points="{pts([(-hw - 0.5, -hh + 2.3), (hw - 1.6, -hh - 0.6), (hw - 1.3, -hh + 1.4), (-hw, -hh + 4.0)])}" '
          f'fill="#FFC46A"/>')
    cap, lead = CAP * size, 0.2 * size
    bases = [cap / 2] if len(lines) == 1 else [-lead / 2, cap + lead / 2]
    fill = P.lin(("#FFFFFF", "#FFFFFF", "#FFF0B0") if hot else ("#FFFFFF", "#FFF2C2", "#FFC845"))
    for text, y in zip(lines, bases):
        natural = widths[text] * size
        fit = f' textLength="{LINE}" lengthAdjust="spacingAndGlyphs"' if natural > LINE else ""
        common = (f'x="0" y="{y:.2f}" font-family="{FONT[0]}" font-size="{size:.2f}" text-anchor="middle"{fit} '
                  f'stroke-linejoin="round"')
        P.add(f'<text {common} dx="{0.067 * size:.2f}" dy="{0.095 * size:.2f}" fill="{BAR_INK}" stroke="{BAR_INK}" '
              f'stroke-width="{0.21 * size:.2f}">{sf.esc(text)}</text>')
        P.add(f'<text {common} fill="{fill}" stroke="{BAR_INK}" stroke-width="{0.171 * size:.2f}" '
              f'paint-order="stroke">{sf.esc(text)}</text>')
    P.add("</g>")


def reach(name, widths):
    """The farthest right, in the frame's points, the name's slash comes: its corners turned with it."""
    cx, cy, r = hf.SIG
    k = (r - 6.1) / 27
    lines, size = layout(name, widths)
    t = math.radians(TURN)
    return max(cx + k * (x * math.cos(t) - y * math.sin(t)) for x, y in slash_shape(lines, size, widths)[0]) + 1.3 * k


# ---- the press, with its cooldown -------------------------------------------------------------------------------------
def press(P, name, widths, state="ready", left=None, key=False):
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
    P.press(cx - r, cy - r, 2 * r, 2 * r, r, fam, radial(P, FACE_COLD if cooling else FACE, cx - 3, cy - 4, ri * 1.15),
            rings=(1.2, 2.0, 0.9, 2.0), grain=0.1)
    if cooling:   # the word steps out; the face's ember comes back, clockwise from the top, behind a gold edge
        a = 2 * math.pi * (1 - left / COOL)
        R1 = ri + 1
        back = P.uid("c")
        P.defs.append(f'<clipPath id="{back}"><path d="M{cx},{cy} L{cx},{cy - R1:.2f} A{R1:.2f} {R1:.2f} 0 '
                      f'{1 if a > math.pi else 0} 1 {cx + R1 * math.sin(a):.2f},{cy - R1 * math.cos(a):.2f} Z"/></clipPath>')
        P.add(f'<g clip-path="url(#{back})"><circle cx="{cx}" cy="{cy}" r="{ri:.2f}" '
              f'fill="{radial(P, FACE, cx - 3, cy - 4, ri * 1.15)}" fill-opacity="0.9"/></g>')
        P.add(f'<line x1="{cx}" y1="{cy}" x2="{cx + ri * math.sin(a):.2f}" y2="{cy - ri * math.cos(a):.2f}" stroke="{EDGE}" '
              f'stroke-width="1.8" stroke-linecap="round"/>')
        if state == "last":   # the last second: the face's rim lit, the count gold
            P.add(f'<circle cx="{cx}" cy="{cy}" r="{ri - 0.9:.2f}" fill="none" stroke="{EDGE}" stroke-width="1.8"/>')
            P.add(f'<circle cx="{cx}" cy="{cy}" r="{ri - 0.9:.2f}" fill="none" stroke="{EDGE}" stroke-width="4" '
                  f'stroke-opacity="0.5" filter="url(#glow)"/>')
        count = P.lin(("#FFFFFF", "#FFE27A", "#FFB43C")) if state == "last" else "#FFFFFF"
        P.word(cx, cy + 10.8, str(left), 31, fill=count, stroke=INK, anchor="middle", ratio=0.2)
    else:
        lettering(P, cx, cy, ri, name, widths, hot=firing)
        if pop:
            P.add(f'<circle cx="{cx}" cy="{cy}" r="{ri:.2f}" fill="#FFFFFF" fill-opacity="0.22"/>')
    if scale != 1:
        P.add("</g>")
    if key:   # on a keyboard: the key on a chip at the press's top left
        T = P.T
        kx, ky, ks = cx - r * 0.86 - 8, cy - r * 0.86 - 8, 16
        P.press(kx, ky, ks, ks, 2.3, T["steel"], P.lin(T["press"]), rings=(0.8, 0.7, 0.4, 0.8))
        P.word(kx + ks / 2, ky + 11.7, "R", 10.5, anchor="middle", stroke=T["steel"]["ink"], ratio=0.2)


# ---- the sheets -----------------------------------------------------------------------------------------------------------
def grid(T, plate, rows, cols, widths):
    """Rows (label, name); columns (label, state, seconds left, on a keyboard); each cell the press over the same ground."""
    cw, ch, gap, side, top = 128, 104, 6, 168, 20
    P = hf.Page(T)
    uri = Path(plate).resolve().as_uri()
    sw, sh = side + len(cols) * (cw + gap) + gap, top + len(rows) * (ch + gap) + gap
    P.add(f'<rect width="{sw}" height="{sh}" fill="#15191F"/>')
    for j, (label, *_) in enumerate(cols):
        P.add(f'<text x="{side + gap + j * (cw + gap) + cw / 2}" y="{top - 6}" font-family="Builder Sans" font-size="10" '
              f'fill="#E8EDF4" text-anchor="middle">{sf.esc(label)}</text>')
    for i, (label, name) in enumerate(rows):
        y = top + gap + i * (ch + gap)
        P.add(f'<text x="{side - 4}" y="{y + ch / 2 + 3}" font-family="Builder Sans" font-size="10" fill="#E8EDF4" '
              f'text-anchor="end">{sf.esc(label)}</text>')
        for j, (_, state, left, key) in enumerate(cols):
            keep, P.parts = P.parts, []
            P.add(f'<image href="{uri}" x="0" y="0" width="{hf.W}" height="{hf.H}"/>')
            press(P, name, widths, state, left, key)
            inner, P.parts = "".join(P.parts), keep
            P.add(f'<svg x="{side + gap + j * (cw + gap)}" y="{y}" width="{cw}" height="{ch}" viewBox="-17 108 {cw} {ch}">'
                  f'{inner}</svg>')
    return P.svg(sw, sh), sw, sh


def enlarge(src, out, crop=None):
    vf = (f"crop={crop}," if crop else "") + "scale=iw*4:ih*4:flags=neighbor"
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(src), "-vf", vf, str(out)], check=True)


def shoot_clear(svg, css, out, w, h, scale):
    """A picture with a clear ground, for the game."""
    page = (f'<!doctype html><html><head><meta charset="utf-8"><style>{css} html,body{{margin:0;background:transparent}}'
            f' svg{{display:block;width:{w}px;height:{h}px}}</style></head><body>{svg}</body></html>')
    with tempfile.TemporaryDirectory() as tmp:
        p = Path(tmp) / "page.html"
        p.write_text(page, encoding="utf-8")
        subprocess.run([sf.CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
                        "--default-background-color=00000000", f"--force-device-scale-factor={scale}",
                        f"--user-data-dir={Path(tmp) / 'profile'}", f"--window-size={w},{h}", "--virtual-time-budget=4000",
                        f"--screenshot={out}", p.as_uri()], check=True, capture_output=True, timeout=120)


def images(T, css, out, widths):
    """Slate.Press.Art.Images: each name alone, and the two faces, each over BOX points round the press's middle."""
    cx, cy, r = hf.SIG
    ri = r - 6.1
    out.mkdir(parents=True, exist_ok=True)
    view = f'viewBox="{cx - BOX / 2} {cy - BOX / 2} {BOX} {BOX}"'
    for name in LAUNCH:
        P = hf.Page(T)
        lettering(P, cx, cy, ri, name, widths)
        shoot_clear(P.svg(BOX, BOX).replace(f'viewBox="0 0 {BOX} {BOX}"', view), css,
                    out / f"Press{name.replace(' ', '')}.png", BOX, BOX, 256 / BOX)
    for stem, stops in (("PressFace", FACE), ("PressFaceCold", FACE_COLD)):
        P = hf.Page(T)
        P.add(f'<circle cx="{cx}" cy="{cy}" r="{ri:.2f}" fill="{radial(P, stops, cx - 3, cy - 4, ri * 1.15)}"/>')
        shoot_clear(P.svg(BOX, BOX).replace(f'viewBox="0 0 {BOX} {BOX}"', view), css, out / f"{stem}.png", BOX, BOX,
                    256 / BOX)


def main():
    out, plate = Path(sys.argv[1]).resolve(), sys.argv[2]
    out.mkdir(parents=True, exist_ok=True)
    T = hf.TAKES["F2"]       # research's pick (d11942a3)
    css = hf.faces() + f'@font-face{{font-family:"{FONT[0]}";src:url("{(sf.FONTS / FONT[1]).as_uri()}")}}'
    names = [*LAUNCH, LONGEST]
    widths = measure({t for n in names for t in [n.upper(), *[s for pair in splits(n) for s in pair]]})
    for n in names:
        lines, size = layout(n, widths)
        print(f"{n}: {' / '.join(lines)} at {size:.1f} (caps {CAP * size:.1f} points; at the smallest phone "
              f"{CAP * size * (hf.SIG[2] - 6.1) / 27 * 568 / hf.W:.1f} px)")
    print(f"the narrowest gap to Auto: {hf.AUTO[0] - max(reach(n, widths) for n in names):.1f} points")

    cols = [("ready", "ready", None, False), ("cooling, 5 s left", "cooling", 5, False), ("the last second", "last", 1, False),
            ("ready again: the pop", "pop", None, False), ("firing", "firing", None, False),
            ("ready, on a keyboard", "ready", None, True)]
    svg, sw, sh = grid(T, plate, [("HAYMAKER (Rook)", "Haymaker")], cols, widths)
    sf.shoot(sf.html(svg, css, sw, sh), out / "press_states.png", sw, sh, scale=3)
    rows = [(f"{n} ({who})", n) for n, who in LAUNCH.items()] + [(f"{LONGEST} (the longest)", LONGEST)]
    svg, sw, sh = grid(T, plate, rows, [cols[0], cols[1], cols[4]], widths)
    sf.shoot(sf.html(svg, css, sw, sh), out / "press_names.png", sw, sh, scale=3)
    svg, sw, sh = grid(T, plate, rows, [cols[0]], widths)
    small = round(sw * 568 / hf.W), round(sh * 568 / hf.W)
    sf.shoot(sf.html(svg, css, sw, sh, zoom=568 / hf.W), out / "names_small.png", *small, scale=1)
    enlarge(out / "names_small.png", out / "press_names_phone_x4.png")
    (out / "names_small.png").unlink()

    keep = hf.signature
    try:
        hf.signature = lambda P, state="ready", key=False: press(P, "Haymaker", widths, state, key=key)
        svg = hf.fight(T, plate)
    finally:
        hf.signature = keep
    close = svg.replace(f'viewBox="0 0 {hf.W} {hf.H}"', 'viewBox="0 36 560 176"').replace(
        f'width="{hf.W}" height="{hf.H}"', 'width="560" height="176"', 1)
    sf.shoot(sf.html(close, css, 560, 176), out / "close.png", 560, 176, scale=3)
    sf.shoot(sf.html(svg, css, hf.W, hf.H), out / "fight.png", hf.W, hf.H, scale=hf.SCALE)
    sf.shoot(sf.html(svg, css, hf.W, hf.H, zoom=568 / hf.W), out / "fight_small.png", 568, round(hf.H * 568 / hf.W), scale=1)
    enlarge(out / "fight_small.png", out / "phone_x4.png", crop="150:110:0:58")
    images(T, css, out / "images", widths)
    print("drew the press")


if __name__ == "__main__":
    main()
