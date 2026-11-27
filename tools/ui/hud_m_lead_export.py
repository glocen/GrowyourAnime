"""AR68 M: the top-left's A, the card and the blade (research's pick, 2026-11-27, 14:29), as the game's pieces for
Faber's build, cut from the same drawing as the target (tools/ui/hud_m_lead_targets.py, its a_* layers).

    py tools/ui/hud_m_lead_export.py <out> [ground=build/captures/ar68/m/noplate_day.png]

Writes <out>/images/<Name>.png at the kit's 4 px a point, each on alpha at its own box (Pad 0), and <out>/m_lead.json:
each image's record as UIKit.Images reads it, where each is laid in the lead group's points (the frame's points less
GROUP), the live parts over them (the fills' reveals, the leading edge, the experience, the marks, the words) with
their fonts, sizes and colours, and every roster name's size to fit the blade.

Then the check: the images laid from their files at their boxes, with the live parts, against the target drawn whole,
in four states (the PSNR printed); and <out>/m_lead_check.png: the laid plate over the ground (a game frame with the
lead plate hidden) at 4 px a point in the four states and at the phone's size, then each image alone at full size and
at 64 px tall over dark.
"""
import json
import math
import re
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import hud_m_lead_targets as lt  # noqa: E402
import style_frames as sf  # noqa: E402

PPP = lt.PPP
REPO = lt.REPO
# The lead group's top left in the frame's points: the old MLeadPlate's top edge (its image's row 22, group y 5.5) lies
# at frame y 63.0 in Faber's m_day_fight (852x480, 1.5 px a point), its left edge on the screen's.
GROUP = (0.0, 57.5)
CANVAS = (-8, 40, 248, 104)                   # past the screen's left edge, so the tab's slanted foot is whole
NAME_ROOM = (70.0, 167.0)                     # the name's run on the blade: its marks end 21.3 after it, 4 in from the edge
NAME_LEAST = 12.0
STATES = [  # (what, share, lag, health words, name, the last hit's words)
    ("full health", 1.0, 1.0, "4,061", "ROOK", None),
    ("in a fight: 62%, the last hit's chip to 69%", 0.62, 0.69, "2,518", "ROOK", "-284"),
    ("low: 12%, the chip to 30%", 0.12, 0.30, "487", "ROOK", "-731"),
    ("the roster's widest name, fitted", 0.62, 0.62, "2,518", None, None),
]


def g(x, y):
    """A frame point in the lead group's points."""
    return round(x - GROUP[0], 3), round(y - GROUP[1], 3)


def gbox(b):
    x, y = g(b[0], b[1])
    return [x, y, b[2], b[3]]


def bbox(img, thr=1.5 / 255):
    """An image's whole-point box in the frame's points: everything over `thr` alpha."""
    ys, xs = np.nonzero(img[..., 3] > thr)
    x0, x1 = math.floor(lt.CX0 + xs.min() / PPP), math.ceil(lt.CX0 + (xs.max() + 1) / PPP)
    y0, y1 = math.floor(lt.CY0 + ys.min() / PPP), math.ceil(lt.CY0 + (ys.max() + 1) / PPP)
    assert x0 > lt.CX0 and y0 > lt.CY0 and x1 < lt.CX0 + lt.CW and y1 < lt.CY0 + lt.CH, (x0, y0, x1, y1)
    return x0, y0, x1 - x0, y1 - y0


def cut(img, b):
    x, y, w, h = b
    px, py = int((x - lt.CX0) * PPP), int((y - lt.CY0) * PPP)
    return img[py:py + h * PPP, px:px + w * PPP]


def paste(canvas, piece, b):
    x, y, w, h = b
    px, py = int((x - lt.CX0) * PPP), int((y - lt.CY0) * PPP)
    out = np.zeros_like(canvas)
    out[py:py + h * PPP, px:px + w * PPP] = piece
    return lt.over(canvas, out)


def roster():
    text = (REPO / "src/shared/Definitions/Voidkin.luau").read_text(encoding="utf-8")
    return [n.upper() for n in re.findall(r'\{ Id = "[a-z]+", Name = "([^"]+)"', text)]


def measure(names, size, track):
    """Each name's width in points at `size` in Montserrat Black with `track` after each letter (as SVG spaces it)."""
    script = ("document.fonts.load('%spx MontBlack').then(() => { const c = document.createElement('canvas')"
              ".getContext('2d'); c.font = '%spx MontBlack'; const o = {}; for (const n of %s) o[n] = c.measureText(n)"
              ".width + %s * n.length; document.body.setAttribute('data-w', JSON.stringify(o)); });"
              % (size, size, json.dumps(names), track))
    html = (f'<!doctype html><html><head><meta charset="utf-8"><style>{lt.css()}</style></head><body>'
            f'<span style="font-family:MontBlack">.</span><script>{script}</script></body></html>')
    with tempfile.TemporaryDirectory() as tmp:
        page = Path(tmp) / "m.html"
        page.write_text(html, encoding="utf-8")
        dom = subprocess.run([sf.CHROME, "--headless=new", "--disable-gpu", "--allow-file-access-from-files",
                              f"--user-data-dir={Path(tmp) / 'p'}", "--virtual-time-budget=4000", "--dump-dom",
                              page.as_uri()], capture_output=True, text=True, timeout=120).stdout
    m = re.search(r'data-w="([^"]+)"', dom)
    assert m, dom[-400:]
    return json.loads(m.group(1).replace("&quot;", '"'))


def fitted(widths):
    room = NAME_ROOM[1] - NAME_ROOM[0]
    size = lt.A_NAME["size"]
    return {n: round(max(NAME_LEAST, min(size, size * room / w)), 2) for n, w in widths.items()}


def pieces():
    """The images, each cut at its own box, in the frame's points."""
    plate, bust, fill, lag, tab = lt.a_plate(), lt.a_bust(), lt.a_health(), lt.a_lag(), lt.a_tab()
    hp = bbox(lag)
    return {
        "MLeadPlate": (plate, bbox(plate)),
        "MLeadBustRook": (bust, bbox(bust)),
        "MHealthLag": (lag, hp),
        "MHealthFill": (fill, hp),
        "MLevelTab": (tab, bbox(tab)),
    }


def drawn(share, lag, name_width):
    """The target as drawn whole, in a state (option_a's composition)."""
    x0, x1 = lt.a_hp_span()
    xs, xl = x0 + (x1 - x0) * share, x0 + (x1 - x0) * max(lag, share)
    img = lt.over(lt.a_plate(), lt.a_bust())
    img = lt.over(img, lt.reveal(lt.a_lag(), xl))
    img = lt.over(img, lt.reveal(lt.a_health(), xs))
    if 0 < share < 0.99:
        img = lt.over(img, lt.a_edge(xs))
    img = lt.over(img, lt.a_xp())
    img = lt.over(img, lt.a_tab())
    return lt.over(img, lt.a_marks(name_width))


def laid(images, recs, share, lag, name_width):
    """The same state laid from the image files at their boxes, the live parts drawn over them."""
    x0, x1 = lt.a_hp_span()
    xs, xl = x0 + (x1 - x0) * share, x0 + (x1 - x0) * max(lag, share)
    c = np.zeros(lt.GX.shape + (4,))
    for name, clip in (("MLeadPlate", None), ("MLeadBustRook", None), ("MHealthLag", xl), ("MHealthFill", xs),
                       ("MLevelTab", None)):
        piece = lt.read_png(images / f"{name}.png")
        piece[..., :3] *= piece[..., 3:4]
        whole = paste(np.zeros_like(c), piece, recs[name])
        if clip is not None:
            whole = lt.reveal(whole, clip)
        if name == "MLevelTab":
            if 0 < share < 0.99:
                c = lt.over(c, lt.a_edge(xs))
            c = lt.over(c, lt.a_xp())
        c = lt.over(c, whole)
    return lt.over(c, lt.a_marks(name_width))


def psnr(a, b):
    mse = float(np.mean((a - b) ** 2))
    return 99.0 if mse == 0 else 10 * math.log10(1 / mse)


def texts(state, sizes, widths):
    what, share, lag, words, name, taken = state
    name = name or max(widths, key=widths.get)
    t = lt.a_texts(name=name, hp=words, name_size=sizes.get(name, lt.A_NAME["size"]))
    if taken:
        t.append(dict(t=taken, x=188, y=79.5, size=12, face="MontBlack", fill="#FF6B6B", stroke=1.1, anchor="end"))
    return name, t


def export(out, ground):
    images = out / "images"
    images.mkdir(parents=True, exist_ok=True)
    work = out / "work"
    work.mkdir(exist_ok=True)
    lt.set_grid(*CANVAS)
    made = pieces()
    recs, records = {}, {}
    for name, (img, b) in made.items():
        lt.write_png(images / f"{name}.png", lt.unpremul(cut(img, b)))
        recs[name] = b
        records[name] = dict(file=f"images/{name}.png", Pixels=[b[2] * PPP, b[3] * PPP], Points=[b[2], b[3]], Pad=0)
    names = roster()
    widths = measure(names, lt.A_NAME["size"], lt.A_NAME["track"])
    sizes = fitted(widths)
    x_lo, x_hi = lt.a_hp_span()
    hb = recs["MHealthFill"]
    reveal = dict(root=round(x_lo - hb[0], 3), span=round(x_hi - x_lo, 3), least=round(x_lo - hb[0] + 2.5, 3))
    hx0, hx1 = lt.A_HP[:2]
    xl = lt.a_sl(hx0 - 1, lt.A_XP[0])[0] - 0.2
    edge = "the dark Edge: a UIStroke #0B0C10, opaque, {w} pt, and the same word again 1 pt lower in #0B0C10 under it"
    lays = [
        dict(image="MLeadPlate", box=gbox(recs["MLeadPlate"]), Z=1,
             note="the card and the blade, their shadow and ink, the health's and the experience's troughs"),
        dict(image="MLeadBustRook", box=gbox(recs["MLeadBustRook"]), Z=2,
             note="the lead's bust, MLeadBust<Name> at its own box (Rook's here): held by the card's sides and foot, "
                  "the hair free over the card's top"),
        dict(image="today's portrait art (CardFace<Name> and CardHead<Name>, or CardFaceUnknown<Rarity>)",
             box=gbox((15, 68, 46, 46)), Z=2, when="the lead has no MLeadBust<Name>",
             note="square, clipped to this box, inside the card's slant"),
        dict(image="MHealthLag", box=gbox(hb), Z=3,
             note="the last hit's chip: the image whole inside a clipping frame at this box, the frame Root + Span "
                  "times the chip's share wide (see live.health). On a hit it holds at the old share, then drains to "
                  "the new one a beat after the fill; on a heal it moves with the fill"),
        dict(image="MHealthFill", box=gbox(hb), Z=4,
             note="the health: the image whole (never stretched: its grain stays still) inside a clipping frame at "
                  "this box, the frame Root + Span times the share wide, at least Least while any is left; its moving "
                  "end is straight"),
        dict(image="MLevelTab", box=gbox(recs["MLevelTab"]), Z=7, note="the level's tab on the card's foot"),
    ]
    live = dict(
        health=dict(Root=reveal["root"], Span=reveal["span"], Least=reveal["least"],
                    note="the clip's width from its box's left: Root + Span x share (Root: where the trough's slanted "
                         "foot starts; Span: to its top right corner, so all health fills it all)"),
        edge=dict(z=5, width=0.8, colour="#FFF4EC", transparency=0.1, top=g(0, lt.A_HP[2])[1],
                  height=lt.A_HP[3] - lt.A_HP[2],
                  note="a Frame, its right edge at the fill's clip's right; shown while 0 < share < 0.99"),
        xp=dict(z=6, box=gbox((round(xl, 2), lt.A_XP[0], round(hx1 - hx0, 2), round(lt.A_XP[1] - lt.A_XP[0], 2))),
                colour=lt.XP, lit=lt.XP_LIT,
                note="a Frame, the share to the next level of the box wide, a gradient from lit at its top to colour"),
        marks=dict(z=8, centreY=g(0, 89.6)[1], gem=dict(size=8.0, after=6.0), mark=dict(size=8.6, after=11.0),
                   note="the kit's gem (the type) and class mark: the gem's centre `after` past the name's right "
                        "(TextBounds), the mark's centre `after` past the gem's. The target paints them lacquered "
                        "(the finish's)"),
        texts=[
            dict(what="the lead's name, upper case", x=g(lt.A_NAME["x"], 0)[0], baseline=g(0, lt.A_NAME["y"])[1],
                 anchor="left", size=lt.A_NAME["size"], tracking=lt.A_NAME["track"], colour=lt.CREAM,
                 edge=edge.format(w=1.3),
                 fit=f"its room is {NAME_ROOM[1] - NAME_ROOM[0]:g} wide from x: a name wider steps its size down to "
                     f"fit (by TextBounds), never under {NAME_LEAST:g}; never cut short (names: each name's size as "
                     "measured here)"),
            dict(what="health: the share, two spaces, a slash, two spaces, the most ('2,518  /  4,061'), one weight",
                 x=round(g((hx0 + hx1) / 2 + (lt.A_YB - 104) * lt.A_K, 0)[0], 3), baseline=g(0, 107.6)[1],
                 anchor="centre", size=9.4, tracking=0.3, colour="#FFFFFF", edge=edge.format(w=1.2)),
            dict(what="the level", x=g(14.5, 0)[0], baseline=g(0, 119.0)[1], anchor="centre", size=11.5,
                 colour="#FFFFFF", edge=edge.format(w=1.2)),
            dict(what="the last hit's damage, rising as today", x=g(188, 0)[0], baseline=g(0, 79.5)[1],
                 anchor="right", size=12, colour="#FF6B6B", edge=edge.format(w=1.1),
                 note="not in the picked target: placed over the blade's right end, on the world, clear of the name's "
                      "row; research's eye in the game"),
        ],
        font="Montserrat (rbxasset://fonts/families/Montserrat.json), Heavy, every word; sizes are the frame's em: "
             "set over the build's measured scale for Montserrat as for Oswald (Em)",
    )
    doc = dict(
        about="AR68 M, the top-left: A, the card and the blade (research's pick, 2026-11-27, 14:29), for the game's "
              "plate. Points are the 568 frame's, in the lead group's: the frame's less group.offset. Each image is "
              "laid at its box as it is (Pad 0, no slices). Z orders the plate's parts from 1. MLeadPlate, "
              "MHealthFill and MLevelTab replace today's images of those names; MHealthLag and MLeadBustRook are new.",
        group=dict(offset=list(GROUP), note="the group's top left in the frame's points, from the old plate's top edge "
                                            "in m_day_fight (to half a point)"),
        pixelsPerPoint=PPP, images=records, lays=lays, live=live, names=sizes,
        colours=dict(ember=lt.EMBER, emberHot=lt.EMBER_HOT, slate=lt.SLATE_TOP, ink="#0B0C10", text=lt.CREAM,
                     health=lt.RED_MID, lag=lt.LAG, xp=lt.XP))
    (out / "m_lead.json").write_text(json.dumps(doc, indent=1), encoding="utf-8", newline="\n")
    return doc, recs, sizes, widths


def check(out, ground, doc, recs, sizes, widths):
    images, work = out / "images", out / "work"
    scores, cells = [], []
    for i, st in enumerate(STATES):
        what, share, lag = st[:3]
        name, tx = texts(st, sizes, widths)
        nw = lt.name_w(sizes.get(name, lt.A_NAME["size"]), lt.A_NAME["track"]) if name == "ROOK" else None
        if nw is None:
            nw = measure([name], sizes[name], lt.A_NAME["track"])[name] - lt.A_NAME["track"]
        a = laid(images, recs, share, lag, nw)
        scores.append((what, round(psnr(a, drawn(share, lag, nw)), 1)))
        art = work / f"laid_{i}.png"
        lt.write_png(art, lt.unpremul(a))
        html = lt.frame_html(ground, art, tx)
        big = work / f"big_{i}.png"
        sf.shoot(html, big, lt.W, lt.H, scale=PPP)
        zx, zy, zw, zh = lt.ZOOM
        lt.crop(big, work / f"zoom_{i}.png", zx * PPP, zy * PPP, zw * PPP, zh * PPP)
        cells.append((what, work / f"zoom_{i}.png"))
        if i == 1:
            sf.shoot(html, work / "phone.png", lt.W, lt.H, scale=1.5)

    def img(p, w=None, h=None, bg=""):
        st = f"width:{w}px;" if w else f"height:{h}px;"
        return f'<img src="{Path(p).as_uri()}" style="{st}display:block;{bg}">'
    zooms = "".join(f'<td><div class="l">{w}</div>{img(p, 900)}</td>' + ("</tr><tr>" if k % 2 else "")
                    for k, (w, p) in enumerate(cells))
    alone = "".join(f'<tr><td class="l">{n}<br>{r["Points"][0]} x {r["Points"][1]} pt</td>'
                    f'<td>{img(images / (n + ".png"), w=r["Pixels"][0] // 2)}</td>'
                    f'<td>{img(images / (n + ".png"), h=64)}</td></tr>' for n, r in doc["images"].items())
    html = (f'<!doctype html><html><head><meta charset="utf-8"><style>{lt.css()} body{{margin:0;background:#101216;'
            f'color:#E8E2D6;font-family:Builder;font-size:22px}} td{{padding:8px;vertical-align:top}} .l{{margin:6px 0}}'
            f' h1{{font-size:28px;margin:18px 12px 4px}} p{{margin:0 12px 8px;color:#B9B2A6}}</style></head><body>'
            f'<h1>AR68 M, the top-left: A as the game’s pieces, laid from the export</h1>'
            f'<p>The images at their boxes and the live parts as the json says, over Faber’s frame with the lead plate '
            f'hidden (noplate_day), at 4 px a point; then the fight state at the phone’s size; then each image '
            f'alone at half its pixels and at 64 px tall, over dark. The words are Chrome’s Montserrat Black, as '
            f'Roblox’s Heavy would draw them.</p><table><tr>{zooms}</tr></table>'
            f'<table><tr><td>{img(work / "phone.png", 852)}</td></tr></table><table>{alone}</table>'
            f'</body></html>')
    rows = sum(max(r["Pixels"][1] // 2, 64) + 20 for r in doc["images"].values())
    sf.shoot(html, out / "m_lead_check.png", 1880, 140 + 2 * (360 + 60) + 480 + 30 + rows, scale=1)
    return scores


def main(out, ground):
    out, ground = Path(out).resolve(), Path(ground).resolve()
    doc, recs, sizes, widths = export(out, ground)
    for n, r in doc["images"].items():
        print(n, r["Points"], "at", recs[n], "(group", gbox(recs[n]), ")")
    print("names:", ", ".join(f"{n} {sizes[n]:g}" for n in sorted(sizes, key=sizes.get)[:6]), "...")
    print("ROOK measured", round(widths["ROOK"], 2), "vs name_w", round(lt.name_w(16.5, 1.2), 2))
    for what, p in check(out, ground, doc, recs, sizes, widths):
        print(f"laid against drawn, {what}: PSNR {p} dB")
    for f in (out / "work").iterdir():
        f.unlink()
    (out / "work").rmdir()


if __name__ == "__main__":
    a = sys.argv[1:]
    opts = dict(x.split("=", 1) for x in a[1:])
    main(a[0], opts.get("ground", str(REPO / "build/captures/ar68/m/noplate_day.png")))
