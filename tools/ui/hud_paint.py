"""AR62, the fight's HUD painted as images (research's call after the director's 02:04 word, docs/asset-requests.md, AR62):
the finish made as pictures, not Roblox's strokes and gradients. Built to our surface study's principles at their
craft (docs/research/anime-crusaders-ui-surface.md, "What our finish should do"; "Our adaptation"):
- every plate a ring stack of one hue in its values, split by ink hairlines, the rim brighter than the fill, at about
  one and a half times F2's depth (7.1 points against 4.6), so it holds at phone size;
- the grounds tinted in their side's hue (azure yours, coral theirs; K2's panels), never near-black, lit from the top
  with a highlight, an inner vignette and our own fine dot pattern at a whisper; pressables lit from below;
- heavy stroked type, 14 points or more; the verb (AUTO) in a slanted heavy face, baked into its button;
- the portrait, the level, the skull, Auto's mark and the damage taken across their plates' edges;
- light only on what matters now: the press, ready.
The press's art comes from tools/blender/press_art.py (T1 or T2, research's pair); until it renders, a placeholder
disc, its burst without the fist.

    py tools/ui/hud_paint.py <out> <fight plate> <today's capture> <shipped frame>

Writes P_fight.png (the 852-point phone), P_fight_small.png (the smallest phone, 568 points: every piece at the same
points, so every word is 14 px or more on both), P_close.png (the top at 3x), compare_today.png (today's game and the
painted frame at the smallest phone, enlarged 2x), compare_phone.png (the same with the shipped frame beside: internal,
scratch only), and images/: each plate alone at 2x on a clear ground with slices.json (its 9-slice margins in
pixels), for the install.
"""
import json
import math
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import style_frames as sf  # noqa: E402
import hud_finish as hf  # noqa: E402
import hud_icons as hi  # noqa: E402
import hud_press as hp  # noqa: E402
import hud_press_art as hpa  # noqa: E402

W, H = hf.W, hf.H
REPO = Path(__file__).resolve().parents[2]
PORTRAIT_SRC = REPO / "build" / "handoff" / "Rook" / "make" / "portraits" / "PortraitRook.png"

# each family: an ink hairline, the hue's dark ring, an ink line, the rim (lit, three stops), a dark line, the ground
AZ = dict(ink="#05122A", dark="#1B4482", rim=("#D2EEFF", "#5AA8FF", "#2A68CF"), line="#081833",
          ground=("#33568A", "#1B2E52"), glow="#5AA8FF")
CO = dict(ink="#1E0606", dark="#86291B", rim=("#FFD6CB", "#FF7358", "#D23F2B"), line="#2A0907",
          ground=("#6A3032", "#3A171B"), glow="#FF7358")
STEEL = dict(ink="#080C14", dark="#28344A", rim=("#F2F6FB", "#AEBCD0", "#7A8AA4"), line="#0B111B",
             ground=("#2A3446", "#4A5872"))                     # a pressable: lit from below
GOLD_ON = dict(STEEL, dark="#6A4206", rim=("#FFF6CF", "#FFD457", "#E09A1A"))
GREY = dict(ink="#0E1015", dark="#454B57", rim=("#FFFFFF", "#C9D0DB", "#8A93A3"), line="#101218")
GOLD = dict(ink="#1A0E00", dark="#6A4206", rim=("#FFF6CF", "#FFD457", "#E09A1A"), line="#2A1700",
            ground=("#FFDA6A", "#E7A01C"))
RINGS = (1.6, 1.5, 0.8, 2.6, 0.6)      # ink, the hue's dark, ink, the rim, the dark line: 7.1 points (F2: 4.6)
SMALL_RINGS = (1.2, 1.0, 0.6, 1.8, 0.5)
HEALTH = dict(outline="#14050A", track=("#5E1526", "#360A15"), fill=("#FFB3BC", "#FF6276", "#D9304B"), lip="#8E1A30")
XP = dict(outline="#061226", track=("#14335C", "#0B1E3A"), fill=("#E6F7FF", "#7CCBFF", "#3E9BEF"), lip="#2A70BE")
POISE = dict(outline="#180D00", track=("#4C2F05", "#2C1B02"), fill=("#FFEAA6", "#FFC23C", "#DE9010"), lip="#9E6204")

CARD = (14, 44, 236, 66)
PORTRAIT = (6, 33, 62, 62)
LEVEL = (3, 83, 32, 21)
EYE = (258, 52, 32, 32)
FOE = (334, 44, 232, 60)    # its x on a phone narrower than 852: kept 12 points inside the right edge
AUTO = (98, 146, 84, 32)
SKULL = (-12, -3, 30)       # from the foe card's corner, across its edge
SIZES = []                  # every word's size in points, as drawn: Roblox's offsets, the same points on every phone


def defs(P):
    """Our own fine dot pattern, for the grounds."""
    P.defs.append('<pattern id="dots" width="2.6" height="2.6" patternUnits="userSpaceOnUse">'
                  '<circle cx="1.3" cy="1.3" r="0.5" fill="#FFFFFF"/></pattern>'
                  '<linearGradient id="fadeDown" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFF" '
                  'stop-opacity="1"/><stop offset="1" stop-color="#FFF" stop-opacity="0.15"/></linearGradient>'
                  '<mask id="dotMask"><rect x="-2000" y="-2000" width="5000" height="5000" fill="url(#fadeDown)"/></mask>')


def plate(P, box, r, fam, rings=RINGS, pressable=False, glow=None, dots=0.06):
    """A painted plate: lifted off the world, its rings, its ground lit (from the top, or from below if pressable),
    our dots at a whisper, the inner vignette, the top highlight. Returns the ground's box."""
    x, y, w, h = box
    if glow:
        P.add(P.rect(x - 3, y - 3, w + 6, h + 6, r + 3, f' fill="{glow[0]}" fill-opacity="{glow[1]}" filter="url(#glow)"'))
    P.add(P.rect(x, y + 1.6, w, h, r, ' fill="#05080E" fill-opacity="0.55" filter="url(#lift)"'))
    a, b, c, d, e = rings
    rim = P.lin(fam["rim"], x2=0, y2=1)
    paints = [(a, fam["ink"]), (b, fam["dark"]), (c, fam["ink"]), (d, rim), (e, fam["line"])]
    i = 0.0
    for width, paint in paints:
        P.add(P.rect(x + i, y + i, w - 2 * i, h - 2 * i, max(r - i, 0), f' fill="{paint}"'))
        i += width
    fx, fy, fw, fh, fr = x + i, y + i, w - 2 * i, h - 2 * i, max(r - i, 0)
    ground = fam["ground"]
    P.add(P.rect(fx, fy, fw, fh, fr, f' fill="{P.lin(ground, x2=0, y2=1)}"'))
    cid = P.uid("c")
    P.defs.append(f'<clipPath id="{cid}">{P.rect(fx, fy, fw, fh, fr)}</clipPath>')
    g = f'<g clip-path="url(#{cid})">'
    if dots:
        g += (f'<rect x="{fx:.2f}" y="{fy:.2f}" width="{fw:.2f}" height="{fh:.2f}" fill="url(#dots)" '
              f'fill-opacity="{dots}" mask="url(#dotMask)"/>')
    vig = min(fw, fh) * 0.16
    g += (P.rect(fx, fy, fw, fh, fr, f' fill="none" stroke="#000" stroke-opacity="0.32" stroke-width="{2 * vig:.1f}" '
                 f'filter="url(#vblur)"'))
    if pressable:   # lit from below: a pale curve along the foot
        g += (f'<rect x="{fx:.2f}" y="{fy + fh - 1.6:.2f}" width="{fw:.2f}" height="1.6" fill="#FFFFFF" '
              f'fill-opacity="0.28"/>')
    else:           # lit from the top: the highlight under the top edge
        g += (f'<rect x="{fx:.2f}" y="{fy:.2f}" width="{fw:.2f}" height="1.6" fill="#FFFFFF" fill-opacity="0.5"/>'
              f'<rect x="{fx:.2f}" y="{fy + 1.6:.2f}" width="{fw:.2f}" height="{fh * 0.42:.2f}" '
              f'fill="#FFFFFF" fill-opacity="0.05"/>')
    g += "</g>"
    P.add(g)
    return fx, fy, fw, fh, fr


def bar(P, x, y, w, h, share, fam, notch=None):
    """A chunky bar: a black outline, the track a dark tint of its hue, the fill lit from the top with a gloss and a
    darker lip, notches for chunks."""
    r = h * 0.32
    P.add(P.rect(x - 1.2, y - 1.2, w + 2.4, h + 2.4, r + 1.2, f' fill="{fam["outline"]}"'))
    P.add(P.rect(x, y, w, h, r, f' fill="{P.lin(fam["track"])}"'))
    fw = max(w * share, 2 * r)
    P.add(P.rect(x, y, fw, h, r, f' fill="{P.lin(fam["fill"])}"'))
    cid = P.uid("c")
    P.defs.append(f'<clipPath id="{cid}">{P.rect(x, y, fw, h, r)}</clipPath>')
    lip = max(h * 0.12, 0.8)
    g = f'<g clip-path="url(#{cid})"><rect x="{x:.2f}" y="{y + h - lip:.2f}" width="{fw:.2f}" height="{lip:.2f}" fill="{fam["lip"]}"/>'
    if h >= 8:
        g += (f'<rect x="{x + 2:.2f}" y="{y + 1.4:.2f}" width="{fw - 4:.2f}" height="{h * 0.26:.2f}" rx="{h * 0.13:.2f}" '
              f'fill="#FFFFFF" fill-opacity="0.38"/>')
    P.add(g + "</g>")
    if notch:
        total, step = notch
        k = step
        while k < total:
            nx = x + w * k / total
            P.add(f'<rect x="{nx - 0.5:.2f}" y="{y + 0.8:.2f}" width="1" height="{h - 1.6:.2f}" fill="{fam["outline"]}" '
                  f'fill-opacity="0.6"/>')
            k += step


def word(P, x, y, s, size, fill="#FFFFFF", stroke="#08101E", anchor="start", ratio=0.2, role="display", slant=0,
         spacing=0.0):
    SIZES.append((size, s))
    if slant:
        P.add(f'<g transform="translate({x:.2f},{y:.2f}) skewX({-slant})">')
        P.word(0, 0, s, size, role=role, fill=fill, stroke=stroke, anchor=anchor, ratio=ratio, spacing=spacing)
        P.add("</g>")
    else:
        P.word(x, y, s, size, role=role, fill=fill, stroke=stroke, anchor=anchor, ratio=ratio, spacing=spacing)


def portrait(P):
    """Rook's own portrait (hud_art.py's render) filling his rarity's frame, his hair rising over its top edge."""
    px, py, pw, _ = PORTRAIT
    P.add(P.rect(px - 1, py, pw + 2, pw + 2, 7, ' fill="#05080E" fill-opacity="0.6" filter="url(#lift)"'))
    fx, fy, fw, fh, fr = plate(P, (px, py, pw, pw), 7, dict(GREY, ground=("#EEF2F7", "#9BA6B8")), rings=SMALL_RINGS,
                               dots=0)
    P.add(f'<circle cx="{fx + fw / 2:.2f}" cy="{fy + fh * 0.42:.2f}" r="{fw * 0.42:.2f}" fill="#FFFFFF" '
          f'fill-opacity="0.55" filter="url(#glow)"/>')
    cid = P.uid("c")
    P.defs.append(f'<clipPath id="{cid}">{P.rect(fx, fy, fw, fh, fr)}'
                  f'<rect x="{fx:.2f}" y="{fy - 14:.2f}" width="{fw:.2f}" height="{fh * 0.5 + 14:.2f}"/></clipPath>')
    w, h = sf.png_size(PORTRAIT_SRC)
    iw = 2.8 * fw                        # he fills 0.28 to 0.71 of the render's width, 0.36 to 0.73 of its height
    ih = iw * h / w
    x, y = fx + fw / 2 - 0.495 * iw, fy + fh + 1 - 0.73 * ih
    P.add(f'<g clip-path="url(#{cid})"><image href="{PORTRAIT_SRC.as_uri()}" x="{x:.2f}" y="{y:.2f}" '
          f'width="{iw:.2f}" height="{ih:.2f}"/></g>')


def level(P, n=26):
    x, y, w, h = LEVEL
    plate(P, (x, y, w, h), 5, GOLD, rings=(1.0, 0.8, 0.5, 1.3, 0.4), dots=0, pressable=True)
    word(P, x + w / 2, y + 15.6, str(n), 15, stroke=GOLD["ink"], anchor="middle", ratio=0.22)


def lead_card(P, health=3682, most=3732, taken="-15"):
    x, y, w, h = CARD
    plate(P, CARD, 9, AZ)
    portrait(P)
    level(P)
    nx = 80
    word(P, nx, y + 22, "ROOK", 17, stroke=AZ["ink"], ratio=0.2, spacing=0.6)
    P.icon("gem", nx + 52, y + 7, 15, hf.GEM_RED)
    P.icon("sword", nx + 70, y + 7.5, 14)
    hx, hy, hw, hh = nx, y + 29, x + w - nx - 10, 18
    bar(P, hx, hy, hw, hh, health / most, HEALTH, notch=(most, 1000))
    word(P, hx + hw / 2, hy + 14.4, f"{health:,}/{most:,}", 14, stroke="#16060B", anchor="middle", ratio=0.22)
    bar(P, hx, hy + hh + 6, hw, 5, 0.38, XP)
    if taken:
        word(P, x + w - 6, y + 7, taken, 17, fill=P.lin(("#FFE0E3", "#FF8A96", "#FF2E4B")), stroke="#2A0610",
             anchor="end", ratio=0.22)


def eye(P):
    x, y, w, h = EYE
    plate(P, EYE, 6, STEEL, rings=SMALL_RINGS, pressable=True, dots=0)
    P.icon("eye", x + 2, y + 2, 28)


def auto(P, on=True):
    x, y, w, h = AUTO
    plate(P, AUTO, 7, GOLD_ON if on else STEEL, rings=SMALL_RINGS, pressable=True, dots=0,
          glow=("#FFC94A", 0.35) if on else None)
    P.icon("auto", x - 9, y - 3, 36, "#FFCB45" if on else "#AEB9C9", ink="#0A101A", o=0.9)
    word(P, x + 30, y + 22.5, "AUTO", 15, stroke=STEEL["ink"], ratio=0.22, slant=10, spacing=0.6)


def foe_card(P, width=W, health=2964, most=4290):
    x, y, w, h = FOE
    x = min(x, width - w - 12)
    plate(P, (x, y, w, h), 9, CO)
    sx, sy, ss = SKULL
    P.icon("skull", x + sx, y + sy, ss)
    # the level on a small dark chip, then the name
    cx, cy, cw, ch = x + 30, y + 7.5, 50, 19
    P.add(P.rect(cx, cy, cw, ch, 4, ' fill="#1A0708" fill-opacity="0.75"'))
    word(P, cx + cw / 2, cy + 14.6, "Lv 26", 14, role="meta", stroke=None, anchor="middle")
    word(P, cx + cw + 8, y + 22, "BRAWLER", 16, stroke=CO["ink"], ratio=0.2, spacing=0.6)
    P.icon("gem", x + w - 26, y + 7, 15, hf.GEM_RED)
    hx, hw = x + 12, w - 24
    bar(P, hx, y + 31, hw, 16, health / most, HEALTH, notch=(most, 1000))
    word(P, hx + hw / 2, y + 44, f"{health:,}/{most:,}", 14, stroke="#16060B", anchor="middle", ratio=0.22)
    bar(P, hx, y + 52, hw, 4, 0.64, POISE)


def press(P):
    """The signature: the thin ring and a placeholder disc (its burst without the fist) until the art renders."""
    cx, cy, r = hf.SIG
    ri = r - hpa.THIN
    P.add(f'<circle cx="{cx}" cy="{cy}" r="{r + 6}" fill="{hf.GOLD["glow"]}" fill-opacity="0.42" filter="url(#glow)"/>')
    P.add(f'<circle cx="{cx}" cy="{cy}" r="{r:.2f}" fill="{hp.INK}"/>')
    cid = P.uid("c")
    P.defs.append(f'<clipPath id="{cid}"><circle cx="{cx}" cy="{cy}" r="{ri:.2f}"/></clipPath>')
    fx, fy = cx - 0.08 * ri, cy - 0.06 * ri
    P.add(f'<g clip-path="url(#{cid})"><circle cx="{cx}" cy="{cy}" r="{ri:.2f}" '
          f'fill="{hpa.ground(P, hpa.DARK, fx, fy, ri * 1.4)}"/>')
    hpa.shards(P, fx, fy, ri, 7, 9, [(hpa.RIM, 1.0), (hpa.HOT_EMBER, 0.62), (hpa.CORE, 0.26)])
    P.add(f'<circle cx="{fx:.2f}" cy="{fy:.2f}" r="{ri * 0.5:.2f}" fill="{hpa.EMBER}" fill-opacity="0.55" '
          f'filter="url(#glow)"/></g>')
    hpa.ring(P, cx, cy, r)


def frame(T, plate_path, w=W, h=H):
    """The fight's HUD over a capture of the fight, on a phone `w` points wide: every piece at the same points."""
    P = hf.Page(T)
    defs(P)
    P.add(f'<image href="{Path(plate_path).resolve().as_uri()}" x="0" y="0" width="{w}" height="{h}"/>')
    foe_card(P, w)
    lead_card(P)
    eye(P)
    press(P)
    auto(P)
    return P.svg(w, h)


# ---- the images for the install ------------------------------------------------------------------------------------------
def alone(T, css, out, name, w, h, draw, margins):
    """One plate alone at 2x on a clear ground; `margins` are its 9-slice edges in points."""
    P = hf.Page(T)
    defs(P)
    pad = 6
    draw(P, (pad, pad, w, h))
    svg = P.svg(w + 2 * pad, h + 2 * pad)
    hp.shoot_clear(svg, css, out / f"{name}.png", w + 2 * pad, h + 2 * pad, 2)
    return {"file": f"{name}.png", "size": [2 * (w + 2 * pad), 2 * (h + 2 * pad)],
            "slice": [math.ceil(2 * (pad + margins))] * 4, "note": f"{w} x {h} points at 2x, {pad} points of shadow and glow round it"}


def images(T, css, out):
    out.mkdir(parents=True, exist_ok=True)
    m = sum(RINGS) + 4
    s = sum(SMALL_RINGS) + 3
    plates = {
        "PaintCardYours": (236, 66, lambda P, b: plate(P, b, 9, AZ), m + 5),
        "PaintCardTheirs": (232, 60, lambda P, b: plate(P, b, 9, CO), m + 5),
        "PaintButton": (84, 32, lambda P, b: plate(P, b, 7, STEEL, rings=SMALL_RINGS, pressable=True, dots=0), s + 4),
        "PaintButtonOn": (84, 32, lambda P, b: plate(P, b, 7, GOLD_ON, rings=SMALL_RINGS, pressable=True, dots=0), s + 4),
        "PaintPortraitCommon": (62, 62, lambda P, b: plate(P, b, 7, dict(GREY, ground=("#F3E3D3", "#C9B39F")),
                                                            rings=SMALL_RINGS, dots=0), s + 4),
        "PaintLevel": (32, 21, lambda P, b: plate(P, b, 5, GOLD, rings=(1.0, 0.8, 0.5, 1.3, 0.4), dots=0, pressable=True), 5),
    }
    listing = {}
    for name, (w, h, draw, margin) in plates.items():
        listing[name] = alone(T, css, out, name, w, h, draw, margin)
    (out / "slices.json").write_text(json.dumps(listing, indent=1), encoding="utf-8")


def compare(out, today, shipped):
    """Today's game, the painted frame and the shipped frame, each 568 wide, enlarged 2x (internal: the shipped frame)."""
    small = out / "P_fight_small.png"
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(today), "-i", str(small), "-filter_complex",
                    "[0:v]scale=568:-1,pad=576:320:0:0:color=0x15191F[a];[1:v]pad=568:320:0:0:color=0x15191F[b];"
                    "[a][b]hstack=inputs=2,scale=iw*2:ih*2:flags=neighbor", str(out / "compare_today.png")], check=True)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(today), "-i", str(small), "-i", str(shipped), "-filter_complex",
                    "[0:v]scale=568:-1,pad=576:355:0:20:color=0x15191F[a];[1:v]pad=576:355:0:20:color=0x15191F[b];"
                    "[2:v]scale=568:-1[c];[a][b][c]hstack=inputs=3,scale=iw*2:ih*2:flags=neighbor",
                    str(out / "compare_phone.png")], check=True)


def main():
    out, plate_path, today, shipped = Path(sys.argv[1]).resolve(), sys.argv[2], sys.argv[3], sys.argv[4]
    out.mkdir(parents=True, exist_ok=True)
    hf.PAINTED = hi.PAINTED
    T = hf.TAKES["F2"]
    css = hf.faces()
    sw, sh = 568, round(H * 568 / W)     # the smallest phone, landscape, in points
    small = frame(T, plate_path, sw, sh)
    sf.shoot(sf.html(small, css, sw, sh), out / "P_fight_small.png", sw, sh, scale=1)
    SIZES.clear()
    svg = frame(T, plate_path)
    sf.shoot(sf.html(svg, css, W, H), out / "P_fight.png", W, H, scale=hf.SCALE)
    least = min(SIZES)
    print(f"the smallest word: {least[0]} points ({least[1]!r}), the same on every phone")
    close = svg.replace(f'viewBox="0 0 {W} {H}"', 'viewBox="0 26 580 170"').replace(
        f'width="{W}" height="{H}"', 'width="580" height="170"', 1)
    sf.shoot(sf.html(close, css, 580, 170), out / "P_close.png", 580, 170, scale=3)
    compare(out, today, shipped)
    images(T, css, out / "images")
    print("drew the painted fight HUD")


if __name__ == "__main__":
    main()
