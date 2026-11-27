"""AR68, M (research's pick, 2026-11-27, 13:10): the lead plate and the press as the game's pieces, for Faber's first
build (Turing R1), from the same drawing as the frames (tools/ui/hud_compositions.py, `m_frame`'s pieces).

    py tools/ui/hud_m_export.py <out> [look]

`look`: one of hud_compositions.M_LOOKS, `light` unless named (research picked `a`, slate, at 13:4x on 2026-11-27).

Writes <out>/images/<Name>.png at the kit's 4 pixels a point (Config.UIKit.PixelsPerPoint), each a cut-out on alpha, and
<out>/m_pieces.json: every image's record as UIKit.Images reads it (Pixels, Points, Pad, and Cut in points from the
image's own edge, pad included, as UI.Kit.Skin slices it), where each is laid in the lead's points at 568 (its box
without the pad), its tint if it is drawn white, and the live parts over them (the portrait, the art, the bars, the
texts) with their fonts, sizes and colours.

Then the check: the pieces laid from the json alone, sliced and tinted as Roblox does, against the same pieces drawn in
place by the frame's own code, with the PSNR between the two printed; <out>/m_check.png shows, left to right, the laid
pieces, the drawn ones and the whole frame, at 2x. <out>/m_pieces_sheet.png: every image alone at 2x over dark.
"""
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import hud_compositions as hc  # noqa: E402
import hud_systems as hs  # noqa: E402
import style_frames as sf  # noqa: E402

PPP = 4
T = hs.M_
PAD = 6.0          # the soft shadow's reach (dx 1.2, dy 1.8, blur 1.3) with room
CY = hc.PRESS[1]
CHIP_CUT = (PAD + 6, PAD + 3, PAD + 6, PAD + 3)
LOOK = "light"   # a chip's slanted ends and its soft edge keep their size

# name: (draw, its box x, y, w, h in the lead's points, pad, cut l, t, r, b in points or None, tint if drawn white)
PIECES = {
    "MLeadPlate": (lambda P: hc.m_lead_plate(P, T), (6, 6, 190, 38), PAD, None, None),
    "MLevelTab": (lambda P: hc.m_level_tab(P, T), (24, 38, 30, 14), PAD, None, None),
    "MHealthFill": (lambda P: hc.m_health_fill(P, T, 1.0), (49, 26, 136, 12), 0.0, (4, 0, 4, 0), None),
    "MPressDisc": (lambda P: hc.m_press_disc(P, T), (8, CY - 30, 60, 60), PAD, None, None),
    "MPressRing": (lambda P: hc.m_press_ring(P, T, 1.0, "#FFFFFF"), (8, CY - 30, 60, 60), PAD, None, T["hue"]),
    "MPressGlow": (lambda P: hc.m_press_glow(P, T), (-8, CY - 46, 92, 92), 0.0, None, None),
    "MLabelCard": (lambda P: hc.card(P, hc.slant(74, CY - 18, 50), "slate"), (74, CY - 18, 54, 19), PAD, CHIP_CUT,
                   None),
    "MChip": (lambda P: hc.card(P, hc.slant(70, CY + 7, 60), "paper", soft=True), (70, CY + 7, 64, 19), PAD, CHIP_CUT,
              None),
    "MEye": (lambda P: hs.eye_icon(P, 154, CY + 16.5, 16, hc.M_LOOK["on_paper"], hc.M_LOOK["on_paper"], sw=1.4),
             (145, CY + 12, 18, 9), 1.0, None, None),
}

# where each image is laid (its box without the pad), in the order drawn: Z from 1
LAYS = [
    ("MLeadPlate", (6, 6, 190, 38), "the plate: the portrait's mount, the name card, the health card and both troughs"),
    ("MHealthFill", (49, 26, 136, 12), "the health: from x 49, 3 + 133 times the share of health wide (a nine-slice: "
                                       "both slanted ends keep their shape; at least 8)"),
    ("MLevelTab", (24, 38, 30, 14), "the level's tab, over the portrait's corner"),
    ("MPressGlow", (-8, CY - 46, 92, 92), "only while the press is awake (its skill ready)"),
    ("MPressDisc", (8, CY - 30, 60, 60), "the press's disc and its off-white face"),
    ("MPressRing", (8, CY - 30, 60, 60), "tinted the hue: the share fills clockwise from the top (two halves, each under "
                                         "a rotating UIGradient's transparency, or the kit's own radial fill if it has "
                                         "one); whole when awake"),
    ("MLabelCard", (74, CY - 18, 94, 19), "the press's label: 94 wide awake (the skill's name), 54 while filling "
                                          "(its share)"),
    ("MChip", (70, CY + 7, 64, 19), "Auto's card"),
    ("MChip", (136, CY + 7, 36, 19), "the eye's card"),
    ("MEye", (145, CY + 12, 18, 9), "the eye"),
]

def live(L):
    """The live parts over the images, in the look `L`'s colours."""
    edge = ("a dark edge: a UIStroke #08090C at 92%, 0.75 pt, and the same edge again 0.9 pt lower, under the text"
            if L["text"] else None)
    return {
        "portrait": dict(box=[6, 6, 44, 44], z="after MLeadPlate, under MLevelTab",
                         note="the lead's own portrait (hud_art's Portrait<Voidkin>), clipped to the mount's box"),
        "art": dict(centre=[38, CY], radius=20, z="over MPressDisc, under MPressRing",
                    note="the skill's own art, clipped round; until it is drawn, today's press art; at 55% while filling"),
        "xp": dict(box=[50, 41, 138, 2.2], colour=T["xp"], lit="#FFE7A6", z="over MLeadPlate",
                   note="a Frame over the plate's trough, its width the share to the next level"),
        "autoMark": dict(box=[80, CY + 13, 8, 8], colour=L["mark"], note="a Frame on MChip; Auto on"),
        "texts": [
            dict(what="the lead's name, upper case", x=58, baseline=21, anchor="left", font="Oswald", weight="Bold", size=16,
                 colour=L["on_paper"], tracking=1.0, edge=edge),
            dict(what="the type's gem and the class's mark, the kit's own icons", centres=[[108, 15], [119, 15]],
                 sizes=[10, 11], colour=L["on_paper"]),
            dict(what="the damage taken in the last hit", x=184, baseline=21, anchor="right", font="Oswald", weight="Bold",
                 size=15, colour=T["ally"], edge=edge),
            dict(what="health, a spaced slash, the maximum: '3,682 / 3,732' (research's round: the spacing back)", x=119,
                 baseline=37, anchor="centre", font="Oswald", size=14,
                 runs=[["3,682", "Bold", L["on_slate"]], [" / 3,732", "Regular", "#F3E6D6"]],
                 shadow="0, 1 down, 1.2 blur, #0E131B at 55%"),
            dict(what="the level", x=39, baseline=49.6, anchor="centre", font="Oswald", weight="Bold", size=14,
                 colour=L["on_slate"], edge=edge),
            dict(what="the press's label: its share filling ('62%'), the skill's name awake ('HAYMAKER', tracking 1.2)",
                 x="the card's middle", baseline=CY - 3, anchor="centre", font="Oswald", weight="Bold", size=15,
                 colour=L["on_slate"], edge=edge),
            dict(what="AUTO", x=93, baseline=CY + 22.5, anchor="left", font="Oswald", weight="Bold", size=14, colour=L["on_paper"], edge=edge,
                 tracking=1.0),
        ],
    }


def transparent_shoot(P, out, scale=PPP):
    html = (f'<!doctype html><html><head><meta charset="utf-8"><style>{hs.faces_css()} html,body{{margin:0;'
            f'background:transparent}} svg{{display:block}}</style></head><body>{P.svg()}</body></html>')
    with tempfile.TemporaryDirectory() as tmp:
        page = Path(tmp) / "page.html"
        page.write_text(html, encoding="utf-8")
        subprocess.run([sf.CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
                        "--default-background-color=00000000", f"--force-device-scale-factor={scale}",
                        f"--user-data-dir={Path(tmp) / 'profile'}", f"--window-size={int(P.w)},{int(P.h)}",
                        "--virtual-time-budget=4000", f"--screenshot={out}", page.as_uri()],
                       check=True, capture_output=True, timeout=120)


def bare_page(w, h):
    """A page of the frame's own defs with no ground under it."""
    keep = hc.plate
    hc.plate = lambda size_, ground_: None
    try:
        P = hc.Page(568, "day")
    finally:
        hc.plate = keep
    P.w, P.h = w, h
    return P


def export(out):
    images = out / "images"
    images.mkdir(parents=True, exist_ok=True)
    records = {}
    for name, (draw, (bx, by, bw, bh), pad, cut, tint) in PIECES.items():
        w, h = bw + 2 * pad, bh + 2 * pad
        assert w == int(w) and h == int(h), (name, w, h)
        P = bare_page(w, h)
        P.add(f'<g transform="translate({pad - bx},{pad - by})">')
        draw(P)
        P.add("</g>")
        transparent_shoot(P, images / f"{name}.png")
        rec = dict(file=f"images/{name}.png", Pixels=[round(w * PPP), round(h * PPP)], Points=[w, h], Pad=pad)
        if cut:
            rec["Cut"] = list(cut)
        if tint:
            rec["Tint"] = tint
        records[name] = rec
    lays = [dict(image=n, box=list(b), Z=i + 1, note=note) for i, (n, b, note) in enumerate(LAYS)]
    L = hc.M_LOOK
    doc = dict(about=f"AR68, M: the lead plate and the press, look '{LOOK}', for the first build (R1). Points "
                     "are the 568 frame's, the lead's group from the screen's top left; the game scales them as today's "
                     "HUD. Each image's box is laid without its pad: an image is placed at box minus Pad, sized box plus "
                     "twice Pad (UI.Kit.Skin's rule). Cut counts from the image's own edge, pad included. The foe's side "
                     "and the cut between the sides wait for the next piece.",
               pixelsPerPoint=PPP, images=records, lays=lays, live=live(L), look=LOOK,
               colours=dict(paper=L["paper"], slate=L["slate"], well=L["well"], face=L["face"], textOnPaper=L["on_paper"],
                            textOnSlate=L["on_slate"], hue=T["hue"], health=T["ally"], healthLit=T["ally_lit"],
                            xp=T["xp"]))
    (out / "m_pieces.json").write_text(json.dumps(doc, indent=1), encoding="utf-8", newline="\n")
    return doc


def lay_svg(P, out, rec, box):
    """One image laid as UI.Kit.Skin lays it: placed at box minus Pad, sized box plus twice Pad, its Cut's corners kept
    at their size in points and its middle stretched; a white image takes its Tint (white times the tint)."""
    x, y, w, h = box
    pad = rec["Pad"]
    X, Y, W, H = x - pad, y - pad, w + 2 * pad, h + 2 * pad
    href = (out / rec["file"]).resolve().as_uri()
    pw, ph = rec["Pixels"]
    flt = ""
    if "Tint" in rec:
        fid = P.uid("tint")
        P.defs.append(f'<filter id="{fid}" color-interpolation-filters="sRGB"><feFlood flood-color="{rec["Tint"]}"/>'
                      f'<feComposite in2="SourceGraphic" operator="arithmetic" k1="1" k2="0" k3="0" k4="0"/></filter>')
        flt = f' filter="url(#{fid})"'
    if "Cut" not in rec:
        P.add(f'<image href="{href}" x="{X}" y="{Y}" width="{W}" height="{H}" preserveAspectRatio="none"{flt}/>')
        return
    l, t, r, b = rec["Cut"]
    sx = [0, l * PPP, pw - r * PPP, pw]
    sy = [0, t * PPP, ph - b * PPP, ph]
    dx = [X, X + l, X + W - r, X + W]
    dy = [Y, Y + t, Y + H - b, Y + H]
    P.add(f"<g{flt}>")
    for i in range(3):
        for j in range(3):
            sw, sh, dw, dh = sx[i + 1] - sx[i], sy[j + 1] - sy[j], dx[i + 1] - dx[i], dy[j + 1] - dy[j]
            if sw <= 0 or sh <= 0 or dw <= 0 or dh <= 0:
                continue
            P.add(f'<svg x="{dx[i]}" y="{dy[j]}" width="{dw}" height="{dh}" viewBox="{sx[i]} {sy[j]} {sw} {sh}" '
                  f'preserveAspectRatio="none"><image href="{href}" width="{pw}" height="{ph}"/></svg>')
    P.add("</g>")


def drawn_in_place(P):
    """The same pieces as the frame draws them awake, in place, without the live parts."""
    hc.m_lead_plate(P, T)
    hc.m_health_fill(P, T, 1.0)
    hc.m_level_tab(P, T)
    hc.m_press_glow(P, T)
    hc.m_press_disc(P, T)
    hc.m_press_ring(P, T, 1.0)
    hc.card(P, hc.slant(74, CY - 18, 90), "slate")
    hc.card(P, hc.slant(70, CY + 7, 60), "paper", soft=True)
    hc.card(P, hc.slant(136, CY + 7, 32), "paper", soft=True)
    hs.eye_icon(P, 154, CY + 16.5, 16, hc.M_LOOK["on_paper"], hc.M_LOOK["on_paper"], sw=1.4)


def check(out, doc):
    w, h = 220, 190
    work = out / "work"
    work.mkdir(exist_ok=True)
    P = bare_page(w, h)
    P.add(f'<rect width="{w}" height="{h}" fill="#5A6170"/>')
    for lay in doc["lays"]:
        lay_svg(P, out, doc["images"][lay["image"]], lay["box"])
    hs.shoot(P, work / "laid.png")
    P = bare_page(w, h)
    P.add(f'<rect width="{w}" height="{h}" fill="#5A6170"/>')
    drawn_in_place(P)
    hs.shoot(P, work / "drawn.png")
    P = hc.Page(568, "day")
    hc.m_frame(P, 1.0)
    hs.shoot(P, work / "whole.png")
    r = subprocess.run(["ffmpeg", "-i", str(work / "laid.png"), "-i", str(work / "drawn.png"), "-lavfi", "psnr",
                        "-f", "null", "-"], capture_output=True, text=True)
    psnr = re.search(r"PSNR .*", r.stderr)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(work / "laid.png"), "-i", str(work / "drawn.png"), "-i",
                    str(work / "whole.png"), "-filter_complex",
                    f"[2:v]crop={2 * w}:{2 * h}:0:0[c];[0:v][1:v][c]hstack=3", str(out / "m_check.png")], check=True)
    # the sheet: every image alone at 2x over dark
    y, parts = 6, []
    for n, rec in doc["images"].items():
        parts.append((n, rec, y))
        y += rec["Points"][1] + 16
    S = bare_page(240, int(y))
    S.add(f'<rect width="240" height="{y}" fill="#101117"/>')
    for n, rec, yy in parts:
        pw, ph = rec["Points"]
        S.add(f'<image href="{(out / rec["file"]).resolve().as_uri()}" x="6" y="{yy}" width="{pw}" height="{ph}"/>')
        S.add(f'<text x="{pw + 12}" y="{yy + 10}" font-family="OswB" font-size="8" fill="#8A93A3">{n}</text>')
    hs.shoot(S, out / "m_pieces_sheet.png")
    for f in work.iterdir():
        f.unlink()
    work.rmdir()
    return psnr.group(0) if psnr else r.stderr[-400:]


if __name__ == "__main__":
    dest = Path(sys.argv[1]).resolve()
    LOOK = sys.argv[2] if len(sys.argv) > 2 else "light"
    hc.M_LOOK = hc.M_LOOKS[LOOK]
    dest.mkdir(parents=True, exist_ok=True)
    d = export(dest)
    for n, rec in d["images"].items():
        print(n, rec["Pixels"], "pad", rec["Pad"], "cut", rec.get("Cut"), "tint", rec.get("Tint"))
    print("laid from the json against drawn in place:", check(dest, d))
