"""AR62: the style frames. Home at a phone's size over the street by day, Rook on Home's stand, and each take's tokens.

Each take is one set of tokens (TAKES): its neutrals, its hues with one job each, two fonts and one type scale, its strokes
and radii, and one material family. Every piece below is drawn from those tokens only, so a take is the tokens' look and
nothing else. The pieces are the ones Roblox builds: a rounded frame with a stroke (UICorner, UIStroke), a gradient
(UIGradient), an image, a text with an outline. Nothing is skewed, and light stays inside its piece.

    py tools/ui/style_frames.py <out_dir> [A B C]

Writes, for each take: <T>_home.png (Home open), <T>_hud.png (Home closed, the HUD over the street), <T>_grey.png (Home in
greyscale), <T>_small.png (Home at the smallest phone, 568 x 320), <T>_tokens.png; and frames.png, every take beside
today's Home. Drawn at 852 x 480, the phone capture's size, at twice its pixels.

The fonts are Roblox's own, read from build/scratch/modulo/fonts (gitignored: copied from the installed client, never
uploaded). Rook comes from tools/blender/frame_rook.py.
"""
import math
import os
import re
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
FONTS = REPO / "build/scratch/modulo/fonts"
STREET = REPO / "build/captures/ar62/before/hud_street_day.png"
HOME_TODAY = REPO / "build/captures/tr54/home.png"
ROOK = REPO / "build/scratch/modulo/ar62/rook/rook_stand.png"
ROOK_FLOOR = 1453                                   # the floor's row in rook_stand.png (frame_rook.py prints it)
SWORD = REPO / "build/handoff/UI/gear/images/GearAkari.png"
SHARD = REPO / "build/handoff/UI/shards/shard_enriched.png"
W, H = 852, 480
# Where today's HUD sits in the street capture, and where to clone the scene from to cover it (an offset, like a clone
# stamp's), so only the take's HUD reads: the card, the pills and the dock are under the take's own; the eye is filled
# from down the step's own edge, so the edge runs on through it; the pills' ends, top edge and the gap between them
# from the stalls round and above them.
OLD_HUD = [(8, 108, 240, 226, 0, 0), (88, 232, 170, 314, -90, 25), (578, 104, 652, 210, -72, 0), (822, 92, 860, 218, 0, 118),
           (646, 98, 830, 114, 0, -16), (652, 128, 822, 184, 0, -80), (294, 374, 558, 466, 0, 0)]

RARITY = {"Common": "#A7AEBB", "Uncommon": "#5FD98A", "Rare": "#58A9FF", "Epic": "#B784FF", "Legendary": "#FFC94A",
          "Mythical": "#FF6A82"}
TYPES = {"Red": "#EA4B4F", "Orange": "#F4902A", "Blue": "#3F9DF2", "Purple": "#A470F2", "Green": "#42CC7E"}

TAKES = {
    "A": dict(
        name="Graphite", line="Dark and quiet, never black: warm graphite, ivory words, one ivory press. The art is the light.",
        display=("Oswald-Bold.ttf", "Oswald"), body=("BuilderSans-Bold.otf", "Builder Sans"), upper=True, sizes=(18, 26, 38),
        xl=60,   # a run's verdict only (the run's card, research's must-fix 2, 2026-11-26)
        ink="#F3EEE4", ink2="#A9AEB8", text_stroke=None,
        neutrals=[("#17181C", "the dim behind a screen"), ("#23252B", "panel"), ("#30333B", "raised: a button at rest"),
                  ("#4A4F5A", "rim"), ("#A9AEB8", "second words"), ("#F3EEE4", "words, the press")],
        panel=dict(top="#2C2F36", bottom="#202227", stroke="#4A4F5A", sw=1.5, r=14, inner="#FFFFFF", inner_a=0.07, shadow=0.45),
        raised="#30333B", raised_stroke="#4A4F5A",
        press=dict(fill="#F3EEE4", fill2="#DCD5C6", ink="#1B1C20", stroke=None),
        hues=[("#FFC83D", "Power"), ("#B784FF", "alive, for sale"), ("#E8505B", "health"),
              ("#FF6B73", "a fall's words, lifted")],
        fall="#FF6B73",   # words in the health hue: 4.5:1 on the panel, on raised and on the verdict's band (2026-11-26)
        credits="#F3EEE4", health=("#F06A6E", "#C93C48"), xp="#F3EEE4",
        # Today on the panel's own graphite (violet only on what's alive or for sale); Equipment on a dim brass, so its
        # gold lives in the sword and Rook stays the brightest thing (research's must-fixes 1 and 2, 2026-11-26)
        stage=("#ECE5D6", "#B8B0A0"), equip=("#80684A", "#38322B"), today=("#30333B", "#202227"),
        dim=0.55, blur=7,
        material="Matte graphite: a soft top-down gradient, a thin rim, a hairline of light along the top edge. Pictures sit on "
                 "their own lit grounds inside it.",
    ),
    "B": dict(
        name="Pearl", line="Light and clean: pearl cards outlined in ink, ink words, one ink press. Day, not night.",
        display=("Montserrat-Black.ttf", "Montserrat Black"), body=("BuilderSans-Bold.otf", "Builder Sans"), upper=True,
        sizes=(18, 24, 34),
        ink="#1C1E23", ink2="#5F6571", text_stroke=None,
        neutrals=[("#1C1E23", "ink: outlines, words, the press"), ("#5F6571", "second words"), ("#C9C4BA", "a line inside"),
                  ("#ECE8E0", "raised"), ("#F7F4EE", "pearl: the panel"), ("#FFFFFF", "the card's light")],
        panel=dict(top="#FBF9F5", bottom="#EFEBE3", stroke="#1C1E23", sw=2.0, r=16, inner="#FFFFFF", inner_a=0.9, shadow=0.0,
                   hard=(0, 4, "#1C1E23", 0.28)),
        raised="#ECE8E0", raised_stroke="#1C1E23",
        press=dict(fill="#1C1E23", fill2="#1C1E23", ink="#F7F4EE", stroke=None),
        hues=[("#F2B320", "Power"), ("#9A6BFF", "alive, for sale"), ("#E8455A", "health")],
        credits="#1C1E23", health=("#F25A6B", "#D63A50"), xp="#1C1E23",
        stage=("#FFE9DF", "#FFB49C"), equip=("#FFE79A", "#F0AE2E"), today=("#EEE6FF", "#C7B1FF"),
        dim=0.35, blur=7,
        material="Pearl card: near-white, a 2-point ink outline, a hard ink shadow 4 points down. Colour only on the pictures' "
                 "grounds and the meters.",
    ),
    "C": dict(
        name="Cobalt", line="Bold and bright: cobalt plates in thick ink, white words outlined in ink, one green press.",
        display=("DenkOne-Regular.ttf", "Denk One"), body=("BuilderSans-ExtraBold.otf", "Builder Sans"), upper=False,
        sizes=(18, 26, 38),
        ink="#FFFFFF", ink2="#C9D6FF", text_stroke=("#0A0F2C", 5.0),
        neutrals=[("#0A0F2C", "ink: outlines, the words' edge"), ("#152A75", "panel, low"), ("#2447B8", "panel, high"),
                  ("#3A5FD6", "raised"), ("#C9D6FF", "second words"), ("#FFFFFF", "words")],
        panel=dict(top="#2A50C8", bottom="#172C7C", stroke="#0A0F2C", sw=3.0, r=12, inner="#8FA8FF", inner_a=0.45, shadow=0.0,
                   hard=(0, 4, "#0A0F2C", 0.9)),
        raised="#3A5FD6", raised_stroke="#0A0F2C",
        press=dict(fill="#62E36F", fill2="#22A845", ink="#FFFFFF", stroke="#0A0F2C"),
        hues=[("#62E36F", "the press"), ("#FFCC33", "Power"), ("#B784FF", "alive, for sale"), ("#FF4D63", "health")],
        credits="#FFFFFF", health=("#FF6B7C", "#E0334F"), xp="#FFFFFF",
        stage=("#BDE6FF", "#5FAEF2"), equip=("#FFE070", "#F09A1C"), today=("#C9A6FF", "#7A4CF0"),
        dim=0.30, blur=7,
        material="Cobalt plate: a vivid blue gradient, a 3-point ink outline and a hard ink drop, a pale inner rim. Words in "
                 "white with an ink edge, as the genre's hits do.",
    ),
}


def png_size(path):
    with open(path, "rb") as f:
        return struct.unpack(">II", f.read()[16:24])


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


class Page:
    """One SVG page drawn from one take's tokens."""

    def __init__(self, T, key):
        self.T, self.key, self.parts, self.defs = T, key, [], []
        p = T["panel"]
        self.grad("gPanel", p["top"], p["bottom"])
        self.grad("gStage", *T["stage"])
        self.grad("gEquip", *T["equip"], radial=True)
        self.grad("gToday", *T["today"])
        self.grad("gPress", T["press"]["fill"], T["press"]["fill2"])
        self.grad("gHealth", *T["health"])
        self.grad("gShade", None, None)
        self.defs.append('<filter id="soft" x="-20%" y="-20%" width="140%" height="140%">'
                         f'<feDropShadow dx="0" dy="3" stdDeviation="3" flood-color="#000" flood-opacity="{p["shadow"]}"/></filter>')
        self.defs.append(f'<filter id="blur" x="-5%" y="-5%" width="110%" height="110%"><feGaussianBlur stdDeviation="{T["blur"]}"/></filter>')
        self.defs.append('<filter id="smear" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="16"/></filter>')

    def grad(self, gid, top, bottom, radial=False):
        if gid == "gShade":   # a band that darkens toward the bottom: clear, then the panel's own low colour
            c = self.T["panel"]["bottom"]
            self.defs.append(f'<linearGradient id="gShade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{c}" stop-opacity="0"/>'
                             f'<stop offset="0.55" stop-color="{c}" stop-opacity="0.92"/><stop offset="1" stop-color="{c}"/></linearGradient>')
        elif radial:
            self.defs.append(f'<radialGradient id="{gid}" cx="50%" cy="42%" r="70%"><stop offset="0" stop-color="{top}"/>'
                             f'<stop offset="1" stop-color="{bottom}"/></radialGradient>')
        else:
            self.defs.append(f'<linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/>'
                             f'<stop offset="1" stop-color="{bottom}"/></linearGradient>')

    def add(self, s):
        self.parts.append(s)

    # ---- the material family -------------------------------------------------------------------------------------------
    def plate(self, x, y, w, h, r=None, fill="url(#gPanel)", stroke=None, sw=None, inner=True, shadow=True):
        p = self.T["panel"]
        r = p["r"] if r is None else r
        stroke = p["stroke"] if stroke is None else stroke
        sw = p["sw"] if sw is None else sw
        if shadow and p.get("hard"):
            dx, dy, c, a = p["hard"]
            self.add(f'<rect x="{x + dx}" y="{y + dy}" width="{w}" height="{h}" rx="{r}" fill="{c}" fill-opacity="{a}"/>')
        filt = ' filter="url(#soft)"' if shadow and p["shadow"] > 0 else ""
        self.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}"{filt}/>')
        if inner:   # the hairline of light along the top edge, inside the piece
            i = sw + 0.75
            self.add(f'<path d="M{x + r},{y + i} H{x + w - r}" stroke="{p["inner"]}" stroke-opacity="{p["inner_a"]}" stroke-width="1.2" stroke-linecap="round"/>')
        if sw:
            self.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="none" stroke="{stroke}" stroke-width="{sw}"/>')

    def text(self, x, y, s, size, role="body", fill=None, anchor="start", weight=None, stroke=True, spacing=0, opacity=1.0):
        T = self.T
        fam = T["display"][1] if role == "display" else T["body"][1]
        if role == "display" and T["upper"]:
            s = s.upper()
            spacing = spacing or (0.5 if T["display"][1] == "Oswald" else 0)
        fill = fill or T["ink"]
        st = ""
        if stroke and T["text_stroke"] and fill.upper() in ("#FFFFFF", T["ink"].upper(), T["ink2"].upper()):
            c, w_ = T["text_stroke"]
            w_ = w_ * size / 26
            st = f' stroke="{c}" stroke-width="{w_:.2f}" stroke-linejoin="round" paint-order="stroke"'
        ls = f' letter-spacing="{spacing}"' if spacing else ""
        self.add(f'<text x="{x}" y="{y}" font-family="{fam}" font-size="{size}" fill="{fill}" text-anchor="{anchor}"'
                 f' fill-opacity="{opacity}"{ls}{st}>{esc(s)}</text>')

    # ---- glyphs, ours, on a 24-point box --------------------------------------------------------------------------------
    def glyph(self, kind, x, y, size, fill, ink=None):
        k = size / 24
        ink = ink or self.T["panel"]["stroke"]
        outline = self.T["text_stroke"] is not None
        so = f' stroke="{ink}" stroke-width="{2.2 / k:.2f}" stroke-linejoin="round" paint-order="stroke"' if outline else ""
        g = f'<g transform="translate({x},{y}) scale({k:.4f})">'
        if kind == "bolt":
            g += f'<path d="M13.5 1.5 L4 13.5 H10.5 L9.5 22.5 L20 9.5 H13 Z" fill="{fill}"{so}/>'
        elif kind == "coin":
            pts = " ".join(f"{12 + 10.5 * math.cos(math.radians(22.5 + 45 * i)):.2f},{12 + 10.5 * math.sin(math.radians(22.5 + 45 * i)):.2f}" for i in range(8))
            g += (f'<polygon points="{pts}" fill="{fill}"{so}/>'
                  f'<path d="M12 6.5 L16 12 L12 17.5 L8 12 Z" fill="{self.T["panel"]["bottom"]}" fill-opacity="0.85"/>')
        elif kind == "battery":
            g += (f'<rect x="2.5" y="7" width="17" height="10" rx="2.2" fill="none" stroke="{fill}" stroke-width="2"/>'
                  f'<rect x="20" y="10" width="2.2" height="4" rx="0.8" fill="{fill}"/><rect x="5" y="9.5" width="7" height="5" rx="1" fill="{fill}"/>')
        elif kind == "home":   # two cards, the front one with a shard: the lead's things
            g += (f'<rect x="7.5" y="2.5" width="13" height="16" rx="2.5" fill="{fill}" fill-opacity="0.5"/>'
                  f'<rect x="3.5" y="5.5" width="13" height="16" rx="2.5" fill="{fill}"{so}/>'
                  f'<path d="M10 9 L12.6 13.5 L10 18 L7.4 13.5 Z" fill="{self.T["panel"]["bottom"]}"/>')
        elif kind == "base":   # a roof over a bolt: home's power
            g += (f'<path d="M12 2.5 L22 10.5 V21.5 H2 V10.5 Z" fill="{fill}" stroke-linejoin="round"{so}/>'
                  f'<path d="M13 8.5 L8.5 15 H11.6 L10.8 19.5 L15.6 13 H12.4 Z" fill="{self.T["panel"]["bottom"]}"/>')
        elif kind == "map":
            g += (f'<path d="M2 5 L8.5 2.5 L15.5 5 L22 2.5 V19 L15.5 21.5 L8.5 19 L2 21.5 Z" fill="{fill}"{so}/>'
                  f'<path d="M5 17 Q9 9 12 13 T19 7" fill="none" stroke="{self.T["panel"]["bottom"]}" stroke-width="2" stroke-dasharray="2.5 2" stroke-linecap="round"/>')
        elif kind == "cog":
            pts = []
            for i in range(32):
                a = math.radians(i * 360 / 32)
                rr = 11 if (i % 4) in (1, 2) else 8.4
                pts.append(f"{12 + rr * math.cos(a):.2f},{12 + rr * math.sin(a):.2f}")
            g += (f'<path d="M{" L".join(pts)} Z M12 8.2 A3.8 3.8 0 1 0 12.001 8.2 Z" fill="{fill}" fill-rule="evenodd"{so}/>')
        elif kind == "eye":
            g += (f'<path d="M1.5 12 Q12 2 22.5 12 Q12 22 1.5 12 Z" fill="{fill}"{so}/>'
                  f'<circle cx="12" cy="12" r="4.4" fill="{self.T["panel"]["bottom"]}"/><circle cx="13.4" cy="10.6" r="1.4" fill="{fill}"/>')
        elif kind == "gem":   # a type's gem: its hue, a lit facet
            g += (f'<path d="M12 1.5 L21 8 L17.5 21 H6.5 L3 8 Z" fill="{fill}"{so}/>'
                  f'<path d="M12 1.5 L21 8 L12 10.5 L3 8 Z" fill="#FFFFFF" fill-opacity="0.35"/>')
        elif kind == "sword":   # the Warrior's mark
            g += (f'<path d="M17.5 2 L22 2 L22 6.5 L10.5 18 L6 13.5 Z" fill="{fill}"{so}/>'
                  f'<path d="M4 12 L12 20 L10 22 L2 14 Z" fill="{fill}"{so}/><path d="M5 18 L2.5 21.5" stroke="{fill}" stroke-width="3" stroke-linecap="round"/>')
        g += "</g>"
        self.add(g)

    def image(self, path, x, y, w, h, clip=None, extra=""):
        c = f' clip-path="url(#{clip})"' if clip else ""
        self.add(f'<image href="{path.as_uri()}" x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" preserveAspectRatio="xMidYMid meet"{c}{extra}/>')

    def clip_rect(self, cid, x, y, w, h, r):
        self.defs.append(f'<clipPath id="{cid}"><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}"/></clipPath>')

    def svg(self, w=W, h=H, grey=False):
        style = ' style="filter:grayscale(1)"' if grey else ""
        out = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}"{style}>'
               f'<defs>{"".join(self.defs)}</defs>{"".join(self.parts)}</svg>')
        return shard_cut(out) if CHAMFER else out


CHAMFER = os.environ.get("CHAMFER") == "1"
TAP = 66   # a press's least height: 44 pt on the small phone (568 x 320) is 66 here (research's class, 2026-11-26)


def shard_cut(svg):
    """docs/ui.md, rule 3, and the accepted ui_sheet.png: a panel's top-left and bottom-right corners cut on the diagonal,
    the other two square. Every rounded panel, card, clip and rim takes the same cut; pills, bars and small marks keep
    their round ends."""
    def cut(m):
        a = dict(re.findall(r'(\w[\w-]*)="([^"]*)"', m.group(1)))
        try:
            x, y, w, h, r = (float(a.get(k, 0)) for k in ("x", "y", "width", "height", "rx"))
        except ValueError:
            return m.group(0)
        if r < 6 or min(w, h) < 30 or r >= min(w, h) / 2 - 0.5:
            return m.group(0)
        c = r * 0.9
        rest = " ".join(f'{k}="{v}"' for k, v in a.items() if k not in ("x", "y", "width", "height", "rx"))
        d = f"M{x + c:.1f},{y:.1f} H{x + w:.1f} V{y + h - c:.1f} L{x + w - c:.1f},{y + h:.1f} H{x:.1f} V{y + c:.1f} Z"
        return f'<path d="{d}" {rest}/>'
    return re.sub(r"<rect ([^>]*?)/>", cut, svg)


# ---- the world behind -------------------------------------------------------------------------------------------------
def world(P, home_open):
    P.add(f'<image href="{STREET.as_uri()}" x="0" y="0" width="{W}" height="{H}"/>')
    # today's HUD covered by the scene beside it, each through a feathered mask, so no edge reads as a box
    P.defs.append('<filter id="feather" x="-10%" y="-10%" width="120%" height="120%"><feGaussianBlur stdDeviation="8"/></filter>')
    for i, (x0, y0, x1, y1, dx, dy) in enumerate(OLD_HUD):
        P.defs.append(f'<mask id="old{i}"><rect x="{x0}" y="{y0}" width="{x1 - x0}" height="{y1 - y0}" rx="14" fill="#fff" '
                      'filter="url(#feather)"/></mask>')
        smear = ' filter="url(#smear)"' if (dx, dy) == (0, 0) else ""   # a clone stays sharp, as the scene round it
        P.add(f'<g mask="url(#old{i})"><image href="{STREET.as_uri()}" x="{-dx}" y="{-dy}" width="{W}" height="{H}"{smear}/></g>')
    if home_open:   # a screen over the world: the world blurs and dims (a BlurEffect and a dim frame)
        P.add(f'<image href="{STREET.as_uri()}" x="0" y="0" width="{W}" height="{H}" filter="url(#blur)" opacity="1"/>')
        P.add(f'<rect width="{W}" height="{H}" fill="{P.T["neutrals"][0][0] if P.key != "B" else "#2A2C33"}" fill-opacity="{P.T["dim"]}"/>')
    # Roblox's own buttons, top left: drawn as the client draws them, so the frame keeps their room
    P.add('<circle cx="57" cy="51" r="33" fill="#000" fill-opacity="0.62"/><rect x="45" y="39" width="24" height="24" rx="3" fill="#fff" transform="rotate(15 57 51)"/>'
          '<rect x="52" y="46" width="10" height="10" fill="#000" fill-opacity="0.62" transform="rotate(15 57 51)"/>'
          '<rect x="103" y="18" width="144" height="66" rx="33" fill="#000" fill-opacity="0.62"/>'
          '<path d="M127 42 H157 M127 51 H157 M127 60 H157" stroke="#fff" stroke-width="3" stroke-linecap="round"/>'
          '<path d="M193 38 H222 V58 H211 L205 64 V58 H193 Z" fill="none" stroke="#fff" stroke-width="2.6" stroke-linejoin="round"/>'
          '<path d="M200 46 H215 M200 51 H210" stroke="#fff" stroke-width="2.2" stroke-linecap="round"/>')


# ---- the HUD -------------------------------------------------------------------------------------------------------------
def lead_card(P):
    T = P.T
    S, M, L = T["sizes"]
    x, y, w, h = 12, 110, 226, 86
    P.plate(x, y, w, h, r=T["panel"]["r"] - 2)
    # the portrait: Rook's own render, his head and collar, on his stage's ground
    px, py, pw = x + 8, y + 8, 70
    P.clip_rect("portrait", px, py, pw, pw, 8)
    P.add(f'<rect x="{px}" y="{py}" width="{pw}" height="{pw}" rx="8" fill="url(#gStage)"/>')
    rw, rh = png_size(ROOK)
    k = pw / 520   # 520 source pixels across: the head and the collar
    P.add(f'<g clip-path="url(#portrait)"><image href="{ROOK.as_uri()}" x="{px - 237 * k:.1f}" y="{py - 18 * k:.1f}" width="{rw * k:.1f}" height="{rh * k:.1f}"/></g>')
    P.add(f'<rect x="{px}" y="{py}" width="{pw}" height="{pw}" rx="8" fill="none" stroke="{RARITY["Common"]}" stroke-width="2"/>')
    # the level, on a badge on the frame
    bx, by = px - 4, py + pw - 16
    P.plate(bx, by, 34, 24, r=7, fill=T["press"]["fill"], stroke=T["panel"]["stroke"], sw=T["panel"]["sw"], inner=False, shadow=False)
    P.text(bx + 17, by + 18, "22", S, fill=T["press"]["ink"], anchor="middle", stroke=T["press"]["stroke"] is not None)
    # the name, the type's gem, the class
    nx = px + pw + 12
    P.text(nx, y + 32, "Rook", M, role="display")
    name_w = {"Oswald": 64, "Montserrat Black": 84, "Denk One": 58}[T["display"][1]]   # the name's width in each face
    P.glyph("gem", nx + name_w, y + 13, 20, TYPES["Red"])
    P.glyph("sword", nx + name_w + 26, y + 14, 18, T["ink2"])
    # health, current and maximum inside; experience beneath
    hx, hy, hw, hh = nx, y + 42, w - (nx - x) - 10, 22
    P.add(f'<rect x="{hx}" y="{hy}" width="{hw}" height="{hh}" rx="6" fill="#000" fill-opacity="0.45"/>')
    P.add(f'<rect x="{hx}" y="{hy}" width="{hw}" height="{hh}" rx="6" fill="url(#gHealth)"/>')
    P.add(f'<rect x="{hx + 2}" y="{hy + 2}" width="{hw - 4}" height="5" rx="2.5" fill="#fff" fill-opacity="0.22"/>')
    if T["text_stroke"] is None and T["key"] == "B":
        P.add(f'<rect x="{hx}" y="{hy}" width="{hw}" height="{hh}" rx="6" fill="none" stroke="{T["ink"]}" stroke-width="1.5"/>')
    P.text(hx + hw / 2, hy + 17, "3,173/3,173", S, fill="#FFFFFF", anchor="middle",
           stroke=False if T["text_stroke"] is None else True)
    ex, ey = hx, hy + hh + 6
    P.add(f'<rect x="{ex}" y="{ey}" width="{hw}" height="6" rx="3" fill="{T["ink"]}" fill-opacity="0.18"/>')
    P.add(f'<rect x="{ex}" y="{ey}" width="{hw * 0.62:.1f}" height="6" rx="3" fill="{T["xp"]}" fill-opacity="0.9"/>')


def spectate(P):
    T = P.T
    P.plate(14, 206, TAP, TAP, r=TAP / 2, fill="url(#gPanel)")
    P.glyph("eye", 14 + (TAP - 26) / 2, 206 + (TAP - 26) / 2, 26, T["ink2"])


def pills(P):
    T = P.T
    S, M, L = T["sizes"]
    x, w = 650, 188
    P.plate(x, 110, w, 40, r=20)
    P.glyph("coin", x + 10, 118, 24, T["credits"] if T["key"] != "B" else "#1C1E23")
    P.text(x + 44, 139, "55,239", M, role="body")
    P.plate(x, 158, w, 40, r=20)
    power = T["hues"][0][0] if T["hues"][0][1] == "Power" else T["hues"][1][0]
    P.glyph("bolt", x + 10, 166, 24, power)
    P.text(x + 44, 187, "12 kW", M, role="body")
    P.glyph("battery", x + w - 64, 168, 20, T["ink2"])   # the battery and its charge sit to the right, clear of the kW
    P.text(x + w - 14, 185, "4.2", S, role="body", fill=T["ink2"], anchor="end")


def dock(P, active="home"):
    T = P.T
    xs = [310, 390, 470]
    for kind, x in zip(("base", "home", "map"), xs):
        on = kind == active
        y = 460 - TAP if not on else 454 - TAP
        h = TAP if not on else TAP + 6
        if on:   # raised and lifted, with an ivory hairline: a full ivory fill is the press's alone (research, 2026-11-26)
            P.plate(x - 4, y, 80, h, r=T["panel"]["r"] - 2, fill=T["raised"], stroke=T["ink"], sw=1.6)
            P.glyph(kind, x + 20, y + (h - 32) / 2, 32, T["ink"])
        else:
            P.plate(x, y, 72, h, r=T["panel"]["r"] - 2)
            P.glyph(kind, x + 20, y + (h - 32) / 2, 32, T["ink"])


# ---- Home, open ------------------------------------------------------------------------------------------------------------
def home_panel(P):
    T = P.T
    S, M, L = T["sizes"]
    pad = 10
    X, Y, Wd, Ht = 248, 98, 592, 276
    P.plate(X, Y, Wd, Ht)
    cy, ch = Y + pad, Ht - 2 * pad
    r = max(T["panel"]["r"] - 4, 6)
    stroke = T["panel"]["stroke"] if T["key"] != "A" else "#4A4F5A"
    sw = T["panel"]["sw"]

    # Voidkin: Rook on his stand, the brightest, most finished thing on the screen
    vx, vw = X + pad, 224
    P.clip_rect("vcard", vx, cy, vw, ch, r)
    P.add(f'<rect x="{vx}" y="{cy}" width="{vw}" height="{ch}" rx="{r}" fill="url(#gStage)"/>')
    rw, rh = png_size(ROOK)
    fig = 206
    k = fig / rh
    fx = vx + vw / 2 - rw * k / 2
    fy = cy + 6
    floor = fy + ROOK_FLOOR * k
    P.add(f'<g clip-path="url(#vcard)">'
          f'<ellipse cx="{vx + vw / 2}" cy="{floor + 1:.1f}" rx="74" ry="11" fill="#FFFFFF" fill-opacity="0.35"/>'
          f'<ellipse cx="{vx + vw / 2}" cy="{floor + 1:.1f}" rx="50" ry="6.5" fill="#000" fill-opacity="0.28"/>'
          f'<image href="{ROOK.as_uri()}" x="{fx:.1f}" y="{fy:.1f}" width="{rw * k:.1f}" height="{rh * k:.1f}"/>'
          f'<rect x="{vx}" y="{cy + ch - 60}" width="{vw}" height="60" fill="url(#gShade)"/></g>')
    P.add(f'<rect x="{vx}" y="{cy}" width="{vw}" height="{ch}" rx="{r}" fill="none" stroke="{stroke}" stroke-width="{sw}"/>')
    P.glyph("gem", vx + 10, cy + 10, 22, TYPES["Red"])
    P.glyph("sword", vx + 38, cy + 12, 19, T["ink"] if T["key"] != "A" else "#1B1C20")
    P.text(vx + 12, cy + ch - 14, "Rook", L, role="display")
    P.text(vx + vw - 12, cy + ch - 16, "Lv 22", S, anchor="end", fill=T["ink2"])

    # Equipment: the best piece, large, on its rarity's ground
    ex, ew = vx + vw + pad, 170
    P.clip_rect("ecard", ex, cy, ew, ch, r)
    P.add(f'<rect x="{ex}" y="{cy}" width="{ew}" height="{ch}" rx="{r}" fill="url(#gEquip)"/>')
    s = 176
    P.add(f'<g clip-path="url(#ecard)"><image href="{SWORD.as_uri()}" x="{ex + ew / 2 - s / 2:.1f}" y="{cy + 18:.1f}" width="{s}" height="{s}"/>'
          f'<rect x="{ex}" y="{cy + ch - 60}" width="{ew}" height="60" fill="url(#gShade)"/></g>')
    P.add(f'<rect x="{ex}" y="{cy}" width="{ew}" height="{ch}" rx="{r}" fill="none" stroke="{stroke}" stroke-width="{sw}"/>')
    P.plate(ex + 10, cy + 10, 44, 26, r=8, fill=T["panel"]["bottom"] if T["key"] != "B" else "#1C1E23",
            stroke=T["panel"]["stroke"], sw=T["panel"]["sw"] if T["key"] != "A" else 0, inner=False, shadow=False)
    P.text(ex + 32, cy + 29, "+7", S, anchor="middle", fill="#FFFFFF" if T["key"] != "A" else T["ink"])
    P.text(ex + 12, cy + ch - 14, "Equipment", M, role="display")

    # Today, and Settings beneath
    tx, tw = ex + ew + pad, Wd - (ex + ew + pad - X) - pad
    th = ch - pad - TAP   # Today takes what Settings, a press at 44 pt, leaves (research's class, 2026-11-26)
    P.clip_rect("tcard", tx, cy, tw, th, r)
    P.add(f'<rect x="{tx}" y="{cy}" width="{tw}" height="{th}" rx="{r}" fill="url(#gToday)"/>')
    s = 150
    P.add(f'<g clip-path="url(#tcard)"><image href="{SHARD.as_uri()}" x="{tx + tw / 2 - s / 2:.1f}" y="{cy - 6:.1f}" width="{s}" height="{s}"/></g>')
    P.add(f'<rect x="{tx}" y="{cy}" width="{tw}" height="{th}" rx="{r}" fill="none" stroke="{stroke}" stroke-width="{sw}"/>')
    lit = T["press"]["fill"] if T["key"] != "C" else "#FFCC33"
    for i in range(3):
        on = i < 2
        P.add(f'<rect x="{tx + 12 + i * 20}" y="{cy + th - 54}" width="14" height="14" rx="3" transform="rotate(45 {tx + 19 + i * 20} {cy + th - 47})"'
              f' fill="{lit if on else "none"}" stroke="{T["ink"] if T["key"] != "B" else "#1C1E23"}" stroke-opacity="{1 if on else 0.6}" stroke-width="1.6"/>')
    P.text(tx + 12, cy + th - 14, "Today", M, role="display", fill=T["ink"] if T["key"] != "B" else "#1C1E23")
    sy = cy + th + pad
    P.plate(tx, sy, tw, ch - th - pad, r=r, fill=T["raised"], stroke=T["raised_stroke"], sw=sw, shadow=False)
    P.glyph("cog", tx + 14, sy + (ch - th - pad) / 2 - 12, 24, T["ink"])
    P.text(tx + 46, sy + (ch - th - pad) / 2 + 6, "Settings", S, fill=T["ink"])


def frame(T, key, home_open=True, grey=False, size=(W, H)):
    P = Page(dict(T, key=key), key)
    world(P, home_open)
    lead_card(P)
    spectate(P)
    if home_open:
        home_panel(P)
    else:
        pills(P)
    dock(P, "home" if home_open else None)
    return P.svg(grey=grey)


def tokens_page(T, key):
    P = Page(dict(T, key=key), key)
    S, M, L = T["sizes"]
    bg = T["neutrals"][0][0] if key != "B" else "#E4E0D8"
    P.add(f'<rect width="{W}" height="{H}" fill="{bg}"/>')
    ink = T["ink"] if key != "B" else "#1C1E23"
    P.text(24, 44, f"Take {key} · {T['name']}", L, role="display", fill=ink)
    P.add(f'<text x="24" y="70" font-family="{T["body"][1]}" font-size="14" fill="{T["ink2"]}">{esc(T["line"])}</text>')
    # neutrals
    y0 = 96
    P.add(f'<text x="24" y="{y0}" font-family="{T["body"][1]}" font-size="13" fill="{T["ink2"]}">NEUTRALS</text>')
    for i, (c, role) in enumerate(T["neutrals"]):
        y = y0 + 10 + i * 34
        P.add(f'<rect x="24" y="{y}" width="44" height="26" rx="6" fill="{c}" stroke="#FFFFFF" stroke-opacity="0.22" stroke-width="1"/>')
        P.add(f'<text x="76" y="{y + 12}" font-family="{T["body"][1]}" font-size="12" fill="{ink}">{c}</text>'
              f'<text x="76" y="{y + 25}" font-family="{T["body"][1]}" font-size="11" fill="{T["ink2"]}">{esc(role)}</text>')
    # hues, each with one job; then the content's colours
    x1 = 250
    P.add(f'<text x="{x1}" y="{y0}" font-family="{T["body"][1]}" font-size="13" fill="{T["ink2"]}">HUES, ONE JOB EACH</text>')
    hues = list(T["hues"])
    if key != "C":
        hues = [(T["press"]["fill"], "the press (a neutral)")] + hues
    for i, (c, job) in enumerate(hues):
        y = y0 + 10 + i * 34
        P.add(f'<rect x="{x1}" y="{y}" width="44" height="26" rx="6" fill="{c}" stroke="#FFFFFF" stroke-opacity="0.22" stroke-width="1"/>')
        P.add(f'<text x="{x1 + 52}" y="{y + 12}" font-family="{T["body"][1]}" font-size="12" fill="{ink}">{c}</text>'
              f'<text x="{x1 + 52}" y="{y + 25}" font-family="{T["body"][1]}" font-size="11" fill="{T["ink2"]}">{esc(job)}</text>')
    yc = y0 + 10 + len(hues) * 34 + 14
    P.add(f'<text x="{x1}" y="{yc}" font-family="{T["body"][1]}" font-size="13" fill="{T["ink2"]}">CONTENT: RARITY, TYPE</text>')
    for i, (n, c) in enumerate(RARITY.items()):
        P.add(f'<rect x="{x1 + i * 30}" y="{yc + 8}" width="24" height="24" rx="5" fill="{c}"/>')
    for i, (n, c) in enumerate(TYPES.items()):
        P.glyph("gem", x1 + i * 30, yc + 40, 24, c)
    # type
    x2 = 470
    xl = T.get("xl")
    P.add(f'<text x="{x2}" y="{y0}" font-family="{T["body"][1]}" font-size="13" fill="{T["ink2"]}">'
          f'TYPE: TWO FACES, {"FOUR" if xl else "THREE"} SIZES</text>')
    small = f'font-family="{T["body"][1]}" font-size="11" fill="{T["ink2"]}"'
    if xl:   # the verdict's size, for a run's verdict only: the scale drawn tighter so the page keeps its height
        P.text(x2, y0 + 60, f"Cleared {xl}", xl, role="display", fill=ink)
        P.text(x2, y0 + 98, f"Rook {L}", L, role="display", fill=ink)
        P.text(x2, y0 + 128, f"Equipment {M}", M, role="display", fill=ink)
        P.text(x2, y0 + 152, f"3,173/3,173 · 55,239 · {S}", S, fill=ink)
        P.add(f'<text x="{x2}" y="{y0 + 170}" {small}>{esc(T["display"][1])}: names, titles, presses; XL {xl}: a run\'s verdict only.</text>')
        P.add(f'<text x="{x2}" y="{y0 + 184}" {small}>{esc(T["body"][1])}: numbers, the rest. Authored '
              f'{", ".join(str(round(z / 1.28)) for z in (S, M, L, xl))}.</text>')
        y3 = y0 + 204
    else:
        P.text(x2, y0 + 44, f"Rook {L}", L, role="display", fill=ink)
        P.text(x2, y0 + 80, f"Equipment {M}", M, role="display", fill=ink)
        P.text(x2, y0 + 108, f"3,173/3,173 · 55,239 · {S}", S, fill=ink)
        P.add(f'<text x="{x2}" y="{y0 + 130}" {small}>{esc(T["display"][1])}: names, titles, presses. {esc(T["body"][1])}: numbers and the rest.</text>')
        P.add(f'<text x="{x2}" y="{y0 + 146}" {small}>Sizes at 852 x 480; authored {round(S / 1.28)}, {round(M / 1.28)}, '
              f'{round(L / 1.28)} (Theme.Author, 375 high).</text>')
        y3 = 268
    P.add(f'<text x="{x2}" y="{y3}" font-family="{T["body"][1]}" font-size="13" fill="{T["ink2"]}">STROKES AND RADII</text>')
    p = T["panel"]
    radii = [(p["r"], "panel"), (max(p["r"] - 4, 6), "card"), (20, "pill")]
    for i, (rr, what) in enumerate(radii):
        P.plate(x2 + i * 118, y3 + 12, 100, 54, r=rr, shadow=False)
        P.add(f'<text x="{x2 + i * 118 + 50}" y="{y3 + 44}" font-family="{T["body"][1]}" font-size="12" fill="{T["ink"]}" text-anchor="middle">{what} r{rr}</text>')
    strokes = f"rim {p['sw']}" + (f" · words' edge {T['text_stroke'][1] / 2:.1f}" if T["text_stroke"] else "") + " · hairline 1.2"
    P.add(f'<text x="{x2}" y="{y3 + (80 if xl else 86)}" font-family="{T["body"][1]}" font-size="12" fill="{ink}">{strokes}</text>')
    y4 = y3 + (100 if xl else 110)
    P.add(f'<text x="{x2}" y="{y4}" font-family="{T["body"][1]}" font-size="13" fill="{T["ink2"]}">ONE MATERIAL</text>')
    P.plate(x2, y4 + 10, 110, 50, r=p["r"])
    P.plate(x2 + 122, y4 + 10, 110, 50, r=p["r"] - 2, fill="url(#gPress)", stroke=p["stroke"], sw=p["sw"])
    P.text(x2 + 177, y4 + 43, "Equip", M, role="display", fill=T["press"]["ink"], anchor="middle",
           stroke=T["press"]["stroke"] is not None)
    # the material in words, in the free room under the content's colours, whole (it ran off the page beside the plates)
    words = T["material"]
    lines, line = [], ""
    for wd in words.split():
        if len(line) + len(wd) > 34:
            lines.append(line)
            line = ""
        line += (" " if line else "") + wd
    lines.append(line)
    for i, ln in enumerate(lines):
        P.add(f'<text x="{x1}" y="{yc + 92 + i * 15}" font-family="{T["body"][1]}" font-size="11.5" fill="{T["ink2"]}">{esc(ln)}</text>')
    return P.svg()


def font_faces(keys):
    seen, css = set(), []
    for k in keys:
        for file, fam in (TAKES[k]["display"], TAKES[k]["body"]):
            if (file, fam) in seen:
                continue
            seen.add((file, fam))
            css.append(f'@font-face{{font-family:"{fam}";src:url("{(FONTS / file).as_uri()}")}}')
    return "".join(css)


def shoot(html, out, w, h, scale=2):
    with tempfile.TemporaryDirectory() as tmp:
        page = Path(tmp) / "page.html"
        page.write_text(html, encoding="utf-8")
        subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
                        f"--force-device-scale-factor={scale}", f"--user-data-dir={Path(tmp) / 'profile'}",
                        f"--window-size={w},{h}", "--virtual-time-budget=4000", f"--screenshot={out}", page.as_uri()],
                       check=True, capture_output=True, timeout=120)


def html(svg, faces, w=W, h=H, zoom=1.0):
    return (f'<!doctype html><html><head><meta charset="utf-8"><style>{faces} html,body{{margin:0;background:#000}}'
            f' svg{{display:block;width:{w * zoom}px;height:{h * zoom}px}}</style></head><body>{svg}</body></html>')


def main():
    out = Path(sys.argv[1]).resolve()
    keys = [k for k in sys.argv[2:] if k in TAKES] or list(TAKES)
    out.mkdir(parents=True, exist_ok=True)
    faces = font_faces(TAKES)
    for k in keys:
        T = TAKES[k]
        if CHAMFER:   # the shard-cut Home beside the rounded one, for research's pick in the pair (AR62's must-fix 4)
            shoot(html(frame(T, k), faces), out / f"{k}_home_cut.png", W, H)
            shoot(html(frame(T, k), faces, zoom=568 / W), out / f"{k}_small_cut.png", 568, 320, scale=1)
            shoot(html(frame(T, k, home_open=False), faces), out / f"{k}_hud_cut.png", W, H)
            shoot(html(frame(T, k, home_open=False), faces, zoom=568 / W), out / f"{k}_hud_small_cut.png", 568, 320, scale=1)
            continue
        shoot(html(frame(T, k), faces), out / f"{k}_home.png", W, H)
        shoot(html(frame(T, k, home_open=False), faces), out / f"{k}_hud.png", W, H)
        shoot(html(frame(T, k, grey=True), faces), out / f"{k}_grey.png", W, H)
        shoot(html(frame(T, k), faces, zoom=568 / W), out / f"{k}_small.png", 568, 320, scale=1)
        shoot(html(tokens_page(T, k), faces), out / f"{k}_tokens.png", W, H)
        print("drew", k, T["name"])


if __name__ == "__main__":
    main()
