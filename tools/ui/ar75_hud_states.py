"""AR75, step 1b: the picked HUD alone, in grey, at a phone's 568 x 320 points, in every state.

Research's pick (docs/requests/AR75.md, "the HUD's pick", 2026-11-28, 00:40): C's versus band in a fight, with A's dock
at the foot at rest. This sheet is the layout the painted frames dress: every element at its size in points, its text
at the game's own sizes (Config.Hud's Text: 14, 17 and 22; docs/ui.md's floor: text 14, a touch target 44), in each
state it takes. The world under it is drawn by step 1's renderer (ar75_frame_layouts.py): at rest, the base as a
neutral plot (its world is the director's pick, judged at rest); in a fight, Lantern Row in grey, from its own plan
(Config/Kits/LanternRow/Plan.json: the 44-stud street, its stalls, houses and lantern strings), since no fight happens
on the base (research, 2026-11-28).

Greys by priority, as in step 1: near white, the lead's health and the press; mid grey, the foe, the strip, the dock;
dark, the quiet chips. Amber marks are notes, never the HUD: a size, a tap area (dashed), a layer.

  py tools/ui/ar75_hud_states.py <out> [J3=<capture> S2=<capture> i01=<capture>]

Writes <out>/hud_<n>_<state>.png (852 x 480, the phone's 1.5x), <out>/ar75_hud_states.png (the sheet) and
<out>/ar75_hud_layout.json (every element's box in points, per state, with its grey and its text size). With
shipped captures, <out>/ar75_hud_beside.png puts the fight and the rest beside them in grey (internal: never committed
or uploaded)."""
import json
import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import ar75_frame_layouts as fl  # noqa: E402

W, H = fl.W, fl.H
SMALL, TITLE, BIG = 14, 17, 22             # Config.Hud's Text
TAP = 44                                   # docs/ui.md, rule 1
FILL = {2: "#EFEFEF", 3: "#ABABAB", 4: "#5E5E5E"}
INK = {2: "#1C1C1C", 3: "#1C1C1C", 4: "#F2F2F2"}
NAME = {2: "#F7F7F7", 3: "#C9C9C9", 4: "#9A9A9A"}
TRACK, EDGE, AMBER = "#3A3A3A", "#1C1C1C", "#FFC978"
EM = 0.68                                  # Builder Sans Bold's mean advance, in ems (for boxes; Chrome sets the text)


def width(s, size):
    return len(s) * size * EM


class Hud:
    """One state's HUD: its SVG, its notes, and the boxes it takes (for the share and the layout file)."""

    def __init__(self):
        self.svg, self.notes, self.boxes = [], [], []
        self.mask = np.zeros((H, W), bool)

    def count(self, name, geom, grey, text=None, circle=False):
        if circle:
            cx, cy, r = geom
            yy, xx = np.mgrid[0:H, 0:W]
            self.mask |= (xx + 0.5 - cx) ** 2 + (yy + 0.5 - cy) ** 2 <= r * r
            box = [cx - r, cy - r, 2 * r, 2 * r]
        else:
            x, y, w, h = geom
            self.mask[max(0, int(y)):max(0, int(math.ceil(y + h))), max(0, int(x)):max(0, int(math.ceil(x + w)))] = True
            box = [x, y, w, h]
        self.boxes.append(dict(name=name, shape="circle" if circle else "rect", box=[round(v, 1) for v in box],
                               grey=grey, text=text))

    def share(self):
        return float(self.mask.mean())


# --------------------------------------------------------------------------------------------------------- drawing
def text(x, y, s, size=SMALL, fill="#F7F7F7", anchor="start", stroke=EDGE, face="Builder", opacity=1.0):
    st = (f' stroke="{stroke}" stroke-width="{size * 0.17:.1f}" paint-order="stroke" stroke-linejoin="round"'
          if stroke else "")
    return (f'<text x="{x:.1f}" y="{y:.1f}" font-family="{face}" font-size="{size}" fill="{fill}" '
            f'text-anchor="{anchor}" opacity="{opacity}"{st}>{s}</text>')


def mid(y0, h, size):
    """The baseline that centres a line of `size` in a box from y0, h high (Builder's caps are about 0.7 em)."""
    return y0 + h / 2 + size * 0.35


def name(hud, label, x, base, s, grey, size=SMALL, anchor="start", opacity=1.0):
    hud.svg.append(text(x, base, s, size, NAME[grey], anchor, opacity=opacity))
    w = width(s, size)
    x0 = x - w if anchor == "end" else x - w / 2 if anchor == "middle" else x
    hud.count(label, (x0, base - size * 0.75, w, size), grey, size)


def note(hud, x, y, s, anchor="start"):
    hud.notes.append(text(x, y, s, 7.5, AMBER, anchor, stroke="#151515"))


def tap(hud, x, y, w, h):
    hud.notes.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="3" fill="none" stroke="{AMBER}" '
                     f'stroke-opacity="0.9" stroke-width="0.7" stroke-dasharray="2 2"/>')


def rect(hud, label, x, y, w, h, grey, s="", r=4.0, size=SMALL, opacity=1.0, dashed=False):
    if dashed:
        hud.svg.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="none" stroke="{FILL[grey]}" '
                       f'stroke-width="1" stroke-dasharray="3 2"/>')
    else:
        hud.svg.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{FILL[grey]}" '
                       f'fill-opacity="{0.94 * opacity:.2f}" stroke="{EDGE}" stroke-width="0.8"/>')
        hud.count(label, (x, y, w, h), grey, size if s else None)
    if s:
        hud.svg.append(text(x + w / 2, mid(y, h, size), s, size, INK[grey] if not dashed else FILL[grey], "middle",
                            stroke=None, opacity=opacity))


def bar(hud, label, x, y, w, h, grey, share, s="", right=False, notches=(), fill=None, opacity=1.0):
    f = fill or FILL[grey]
    fw = max(0.0, w * share)
    fx = x + w - fw if right else x
    hud.svg.append(f'<g opacity="{opacity}"><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{h / 2}" fill="{TRACK}" '
                   f'stroke="{EDGE}" stroke-width="0.8"/>'
                   + (f'<rect x="{fx:.1f}" y="{y}" width="{fw:.1f}" height="{h}" rx="{min(h / 2, fw / 2):.1f}" fill="{f}"/>'
                      if fw > 0 else ""))
    for n in notches:
        nx = x + w * n
        hud.svg.append(f'<line x1="{nx:.1f}" y1="{y - 2}" x2="{nx:.1f}" y2="{y + h + 2}" stroke="{EDGE}" stroke-width="1.6"/>')
    if s:
        hud.svg.append(text(x + w / 2, mid(y, h, SMALL), s, SMALL, "#FFFFFF", "middle"))
    hud.svg.append("</g>")
    hud.count(label, (x, y, w, h), grey, SMALL if s else None)


def portrait(hud, label, cx, cy, r, grey, ring=2.4, keeper=False, opacity=1.0):
    hud.svg.append(f'<g opacity="{opacity}"><circle cx="{cx}" cy="{cy}" r="{r}" fill="{FILL[grey]}" stroke="{EDGE}" '
                   f'stroke-width="{ring}"/><circle cx="{cx}" cy="{cy - r * 0.18:.1f}" r="{r * 0.36:.1f}" fill="#7A7A7A"/>'
                   f'<path d="M{cx - r * 0.62:.1f} {cy + r * 0.78:.1f} Q{cx} {cy + r * 0.05:.1f} {cx + r * 0.62:.1f} '
                   f'{cy + r * 0.78:.1f} Z" fill="#7A7A7A"/>'
                   + (f'<circle cx="{cx}" cy="{cy}" r="{r + 3.5}" fill="none" stroke="{FILL[2]}" stroke-width="1.4"/>'
                      if keeper else "") + "</g>")
    hud.count(label, (cx, cy, r + (3.5 if keeper else 0)), grey, circle=True)


def badge(hud, label, x, y, w, h, grey, s, skull=False):
    rect(hud, label, x, y, w, h, grey, "", r=4)
    tx = x + w / 2 + (5 if skull else 0)
    hud.svg.append(text(tx, mid(y, h, SMALL), s, SMALL, INK[grey], "middle", stroke=None))
    if skull:
        hud.svg.append(f'<circle cx="{x + 9}" cy="{y + h / 2}" r="4.2" fill="{INK[grey]}"/>')


def chip(hud, label, x, y, w, h, grey, s, size=SMALL):
    rect(hud, label, x, y, w, h, grey, s, r=h / 2, size=size)


def gem(hud, cx, cy, r, grey):
    hud.svg.append(f'<path d="M{cx} {cy - r} L{cx + r} {cy} L{cx} {cy + r} L{cx - r} {cy} Z" fill="{FILL[grey]}" '
                   f'stroke="{EDGE}" stroke-width="0.8"/>')


def press(hud, cx, cy, r, charge, ready=False):
    """The signature's press: a disc, its emblem, the charge as a ring; ready, the plate white-hot and the emblem dark
    (Config.Hud), the light hugging its border (docs/ui.md, rule 5: light stays in its piece)."""
    c = 2 * math.pi * (r - 5)
    plate, icon = ("#FBFBFB", "#141414") if ready else ("#D2D2D2", "#6A6A6A")
    s = []
    if ready:
        s.append(f'<circle cx="{cx}" cy="{cy}" r="{r + 2.5}" fill="none" stroke="#FFFFFF" stroke-width="3.5" '
                 f'stroke-opacity="0.9"/>')
    s.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{plate}" stroke="{EDGE}" stroke-width="1.2"/>')
    s.append(f'<circle cx="{cx}" cy="{cy}" r="{r - 5}" fill="none" stroke="#8A8A8A" stroke-width="4"/>')
    s.append(f'<circle cx="{cx}" cy="{cy}" r="{r - 5}" fill="none" stroke="{EDGE}" stroke-width="4" '
             f'stroke-dasharray="{c * charge:.1f} {c:.1f}" transform="rotate(-90 {cx} {cy})"/>')
    k = r * 0.42
    s.append(f'<path d="M{cx} {cy - k} L{cx + k * 0.32} {cy - k * 0.32} L{cx + k} {cy} L{cx + k * 0.32} {cy + k * 0.32} '
             f'L{cx} {cy + k} L{cx - k * 0.32} {cy + k * 0.32} L{cx - k} {cy} L{cx - k * 0.32} {cy - k * 0.32} Z" '
             f'fill="{icon}"/>')
    hud.svg.append("".join(s))
    hud.count("the press", (cx, cy, r), 2, circle=True)


# ------------------------------------------------------------------------------------------------ the HUD's parts
PRESS = (486, 200, 33)                     # 66 points (docs/ui.md), over the right thumb, clear of jump by 16


def lead_band(hud, health=0.62, low=False, fallen=False):
    """The lead's half of the band: portrait at the outer end, level on a badge crossing its foot, name, health with
    its numbers inside, experience beneath. The fill sits at the portrait's side, so the draining end faces the centre."""
    op = 0.42 if fallen else 1.0
    portrait(hud, "lead portrait", 122, 30, 20, 2, opacity=op)
    badge(hud, "lead level", 106, 42, 32, 16, 4, "27")
    name(hud, "lead name", 268, 21, "ROOK", 2, anchor="end", opacity=op)
    nx = 268 - width("ROOK", SMALL)
    gem(hud, nx - 9, 16, 5, 3)
    rect(hud, "lead class", nx - 28, 11, 10, 10, 3, r=2)
    if fallen:
        bar(hud, "lead health", 148, 26, 122, 17, 2, 0.0, "healing  0:42", opacity=1.0)
    else:
        bar(hud, "lead health", 148, 26, 122, 17, 2, health, "2,518 / 4,061" if not low else "731 / 4,061",
            fill="#8E8E8E" if low else None)
    bar(hud, "lead experience", 148, 46, 122, 3, 3, 0.42, opacity=op)


def foe_band(hud, keeper=False, edge=True):
    """The foe's half, the lead's mirrored: its skull beside the level, the type edge's arrow before the first hit;
    a keeper's bar in phases and its own mark round the portrait."""
    portrait(hud, "foe portrait", 446, 30, 20, 3, keeper=keeper)
    badge(hud, "foe level and skull", 424, 42, 42, 16, 4, "64" if keeper else "60", skull=True)
    label = "KEEPER" if keeper else "BRAWLER"
    name(hud, "foe name", 300, 21, label, 3)
    nx = 300 + width(label, SMALL)
    gem(hud, nx + 9, 16, 5, 3)
    if edge:
        hud.svg.append(f'<path d="M{nx + 18} {20} L{nx + 23} {11} L{nx + 28} {20} Z" fill="{FILL[2]}" stroke="{EDGE}" '
                       f'stroke-width="0.8"/>')
    bar(hud, "foe health", 298, 26, 122, 17, 3, 0.86 if not keeper else 0.58,
        "13.2K / 14.5K" if not keeper else "41.6K / 72.0K", right=True, notches=(1 / 3, 2 / 3) if keeper else ())


def step_mark(hud):
    hud.svg.append(f'<path d="M284 13 L298 27 L284 41 L270 27 Z" fill="{FILL[4]}" stroke="{EDGE}" stroke-width="0.8"/>'
                   + text(284, mid(13, 28, SMALL), "3", SMALL, INK[4], "middle", stroke=None))
    hud.count("the ground's step", (271, 14, 26, 26), 4, SMALL)


def auto_eye(hud):
    chip(hud, "AUTO", 148, 58, 48, 20, 4, "AUTO")
    hud.svg.append(f'<circle cx="222" cy="68" r="13" fill="{FILL[4]}" stroke="{EDGE}" stroke-width="0.8"/>'
                   f'<ellipse cx="222" cy="68" rx="7.5" ry="4.2" fill="none" stroke="{INK[4]}" stroke-width="1.4"/>'
                   f'<circle cx="222" cy="68" r="2" fill="{INK[4]}"/>')
    hud.count("the eye", (222, 68, 13), 4, circle=True)
    tap(hud, 146, 46, 52, TAP)
    tap(hud, 200, 46, TAP, TAP)


def lead_chip(hud):
    """At rest the lead's card stays at the band's place, small and quiet: the eye learns one spot."""
    portrait(hud, "lead portrait", 120, 25, 16, 3)
    badge(hud, "lead level", 104, 33, 30, 16, 4, "27")
    name(hud, "lead name", 142, 20, "ROOK", 3)
    bar(hud, "lead health", 142, 26, 96, 7, 3, 1.0)
    bar(hud, "lead experience", 142, 36, 96, 3, 3, 0.42)


def strip(hud):
    """Credits, then kW used of made over its meter, then the battery: one strip, out of a fight."""
    x0, y0, h = 346, 6, 26
    rect(hud, "the strip", x0, y0, 214, h, 3, r=6)
    segs = (("12,450", 74), ("10/91 kW", 86), ("64%", 54))
    x = x0
    for i, (s, w) in enumerate(segs):
        hud.svg.append(f'<circle cx="{x + 11}" cy="{y0 + h / 2}" r="5" fill="{FILL[4]}"/>'
                       + text(x + 20, mid(y0, h, SMALL), s, SMALL, INK[3], stroke=None))
        if i == 1:
            hud.svg.append(f'<rect x="{x + 20}" y="{y0 + h - 5}" width="{w - 26}" height="2.2" fill="#6A6A6A"/>'
                           f'<rect x="{x + 20}" y="{y0 + h - 5}" width="{(w - 26) * 0.11:.1f}" height="2.2" fill="{EDGE}"/>')
        if i:
            hud.svg.append(f'<line x1="{x}" y1="{y0 + 5}" x2="{x}" y2="{y0 + h - 5}" stroke="#6A6A6A" stroke-width="1"/>')
        x += w


DOCK = [("Base", 168), ("Home", 228), ("Play", 288)]


def dock(hud):
    """A's dock at the foot, centred between the thumbs: Base, Home, Play, and one more at most."""
    for s, x in DOCK:
        rect(hud, f"dock {s}", x, 248, 52, 52, 3, r=8)
        hud.svg.append(f'<rect x="{x + 16}" y="254" width="20" height="20" rx="4" fill="{FILL[4]}"/>'
                       + text(x + 26, 292, s, SMALL, INK[3], "middle", stroke=None))
    rect(hud, "dock, one more at most", 348, 248, 52, 52, 3, "+1", r=8, dashed=True)


# ------------------------------------------------------------------------------------------------------ the states
def s_rest(hud):
    lead_chip(hud)
    strip(hud)
    dock(hud)
    tap(hud, 348, 248, 52, 52)


def s_gains(hud):
    lead_chip(hud)
    strip(hud)
    dock(hud)
    chip(hud, "the gains pill", 452, 37, 108, 24, 4, "+31 Credits")
    tap(hud, 452, 27, 108, TAP)
    chip(hud, "an event chip", 440, 76, 120, 22, 4, "Void Shop  4:12")
    chip(hud, "the shards' hint", 166, 218, 236, 22, 4, "65 shards: into the Breaker")


def s_fight(hud, health=0.62, low=False, charge=0.6, ready=False, banked=False, keeper=False):
    lead_band(hud, health, low)
    foe_band(hud, keeper=keeper)
    step_mark(hud)
    auto_eye(hud)
    press(hud, *PRESS, charge, ready)


def frame(state):
    hud = Hud()
    if state == "rest":
        s_rest(hud)
    elif state == "gains":
        s_gains(hud)
    elif state == "fight":
        s_fight(hud)
    elif state == "ready":
        s_fight(hud, charge=1.0, ready=True)
    elif state == "low":
        s_fight(hud, health=0.18, low=True, charge=0.35)
        hud.svg.append('<rect x="170" y="26" width="10" height="17" fill="#D8D8D8"/>')
        hud.svg.append(text(209, mid(26, 17, SMALL), "731 / 4,061", SMALL, "#FFFFFF", "middle"))
        hud.svg.append(text(178, 24, "-312", TITLE, "#D8D8D8", "middle"))
        hud.svg.append('<rect x="146.5" y="24.5" width="125" height="20" rx="10" fill="none" stroke="#FFFFFF" '
                       'stroke-width="1.6" stroke-opacity="0.85"/>')
    elif state == "banked":
        s_fight(hud)
        chip(hud, "a banked reward", 452, 64, 108, 24, 4, "+120 Credits")
    elif state == "keeper":
        s_fight(hud, keeper=True)
    elif state == "fallen":
        lead_band(hud, fallen=True)
    elif state == "return":
        s_return(hud)
    return hud


def s_return(hud):
    """The return panel: the whole screen, once at load with gains (docs/ui.md): Welcome back, the largest gain as one
    big number, the rest as a list, Reveal as its one press when shards are ready; a tap anywhere closes it."""
    hud.svg.append(f'<rect x="0" y="0" width="{W}" height="{H}" fill="#0E0F12" fill-opacity="0.74"/>')
    hud.svg.append(text(284, 56, "Welcome back", BIG, "#F7F7F7", "middle"))
    hud.svg.append(text(284, 78, "away 3 h 12 min", SMALL, "#B5B5B5", "middle"))
    hud.svg.append(text(284, 134, "+1,240", 46, "#FFFFFF", "middle", face="MontBlack"))
    hud.svg.append(text(284, 158, "Credits", TITLE, "#D9D9D9", "middle"))
    for i, s in enumerate(("+86 kWh banked", "+3 Void Shards", "Rook trained: Lv 25 to 27")):
        hud.svg.append(text(284, 188 + i * 19, s, SMALL, "#C9C9C9", "middle"))
    rect(hud, "Reveal", 214, 246, 140, TAP, 2, "Reveal", r=10, size=TITLE)
    hud.svg.append(text(284, 312, "tap anywhere to close", SMALL, "#9A9A9A", "middle"))


STATES = [
    ("rest", "At rest, at the base, nothing new", "The quietest frame: the lead's card small at the band's place, the "
     "strip top right, the dock at the foot between the thumbs. No press: it shows only in a fight (TR3's fix 5)."),
    ("gains", "At rest, something new", "What appears when it changed and leaves when it's read: the gains pill under "
     "the strip, an event chip in its last minutes, the shards' hint over the dock (the base only)."),
    ("fight", "In a fight", "The versus band across the top: the lead left, near white; the foe right, mid grey; the "
     "ground's step between. AUTO and the eye under the lead. The press over the right thumb, charging. The strip, "
     "the dock and the markers hide; hits and their numbers stay at the bodies."),
    ("ready", "The signature ready", "The press white-hot, its emblem dark; the light hugs its own border, never past "
     "it. Nothing else changes."),
    ("low", "The lead low", "The bar at 18% pulses inside its own edge; the hit taken crosses the card's top over the "
     "draining end. No screen-edge glow."),
    ("banked", "A reward banked in a fight", "Its pill shows under the foe's card for a moment, then leaves; the strip "
     "stays hidden."),
    ("keeper", "A keeper", "The foe's bar in phases (notches), a ring of its own round the portrait, the purple bar "
     "kept (TR5) in the painted frame."),
    ("fallen", "The lead fallen", "The card dims; its bar says it's healing at home, with the time, then training. The "
     "foe's half and the press leave."),
    ("return", "The return panel, at load", "The whole screen, once, when a player loads in with gains: Welcome back, "
     "the largest gain as one big number, the rest as a list, Reveal as its one press; a tap anywhere closes it."),
]


# -------------------------------------------------------------------------------------------------------- the world
def world(state):
    """A neutral plot under the HUD: the floor, the machines as plain blocks, the fighters, the camera of step 1."""
    if state in ("rest", "gains", "return"):
        sc, meta = fl.plan_a()
        sx, sy = meta["spawn"]
        fl.mark(sc, sx, sy)
        sc.figure(sx, sy, 0, 1.0, 0.50, 90)
        sc.figure(sx - 3, sy + 3, 0, 1.0, 0.36, 90)
        cam = fl.behind((sx, sy))
        return fl.render_world(sc, cam), sc, cam
    return row_world(state)


ROW = Path(fl.REPO) / "src/shared/Config/Kits/LanternRow/Plan.json"


def row_world(state, stop=112.0):
    """Lantern Row in grey at a pack's stop, from its plan: `across` is x (right walking in), `along` is y. The fight
    is framed on the fight, as in step 1."""
    plan = json.loads(ROW.read_text(encoding="utf-8"))
    sc = fl.Scene()
    fl.floor(sc, -300, 300, stop - 60, stop + 700, 0.70, z=-0.06, step=50)
    fl.floor(sc, -22, 22, stop - 40, stop + 420, 0.80, step=13.333)
    for it in plan["placements"]:
        piece, x, y = it["piece"], it["across"], it["along"]
        if not (stop - 40 <= y <= stop + 420):
            continue
        side = 1 if x > 0 else -1
        if piece in ("StallA", "StallB"):
            sc.box((x + side * 1.5, y, 0), (7.0, 12.0, 3.4), 0.50)
            sc.box((x + side * 1.5, y, 8.6), (9.5, 13.3, 0.8), 0.40)
            for dy in (-6.0, 6.0):
                sc.box((x - side * 2.5, y + dy, 0), (0.6, 0.6, 8.6), 0.36, cast=False)
        elif piece in ("HouseLow", "HouseTall"):
            h = 20.2 if piece == "HouseLow" else 27.2
            sc.box((x + side * 5.0, y, 0), (17.0, 17.9, h), 0.58)
            sc.prism((x + side * 5.0, y, h), 9.0, 4.0, 0.46, n=4, r_top=0.5, cast=False)
        elif piece == "LanternString":
            for px in (-21.9, 21.9):
                sc.box((px, y, 0), (0.7, 0.7, 19.0), 0.42, cast=False)
            for k in range(1, 8):
                lx = -21.9 + k * 43.8 / 8
                sag = 3.2 * (1 - (lx / 21.9) ** 2)
                sc.box((lx, y, 16.6 - sag), (1.1, 1.1, 1.3), 0.90, cast=False)
        elif piece == "Banner":
            sc.box((x, y, 0), (0.5, 0.5, 15.6), 0.40, cast=False)
            sc.box((x - side * 1.3, y, 9.0), (2.4, 0.3, 6.0), 0.52, cast=False)
    a, b = (-2.0, stop - 4.0), (4.5, stop + 3.0)
    f = math.degrees(math.atan2(b[1] - a[1], b[0] - a[0]))
    if state != "fallen":
        sc.figure(a[0], a[1], 0, 1.0, 0.14, f, name="Rook")
    sc.figure(b[0], b[1], 0, 1.75 if state == "keeper" else 1.3, 0.10, f + 180, name="Foe")
    sc.figure(-12, stop, 0, 1.0, 0.50, 90)
    cam = fl.behind(((a[0] + b[0]) / 2, (a[1] + b[1]) / 2 - 1.0), zoom=17.0, pitch=17.0, focus_up=3.4)
    return fl.render_world(sc, cam), sc, cam


def world_layer(state, sc, cam):
    """What lives in the world, not the HUD: one hit's number at the foe's body; at rest, one machine's marker."""
    out = []
    if state in ("fight", "ready", "low", "banked", "keeper"):
        p = cam.project(sc.anchors["Foe"])
        if p is not None:
            out.append(text(p[0] + 18, p[1] + 22, "1,204", BIG, "#F4F1EA", "start"))
    if state in ("rest", "gains"):
        for k, q in sc.anchors.items():
            if k.endswith("_foot") or k in ("Tower", "the void's skyline", "Showcase") or "asleep" in k:
                continue
            p = cam.project(q)
            if p is not None and 110 < p[0] < W - 8 and 40 < p[1] < 240:
                out.append(f'<circle cx="{p[0]:.1f}" cy="{p[1] - 4:.1f}" r="3.2" fill="#5E5E5E" stroke="#fff" '
                           f'stroke-width="0.6"/>')
    return "".join(out)


# --------------------------------------------------------------------------------------------------------- the sheet
LEGEND = ("Research's pick: C's versus band in a fight, A's dock at the foot at rest. Sizes in points at a 16:9 phone's "
          "568 x 320 (the frames at 1.5x); text at the game's own sizes (Config.Hud: 14, 17, 22), touch targets 44 or "
          "more (docs/ui.md). Greys by priority: <b>near white</b>, the lead's health and the press; <b>mid grey</b>, "
          "the foe, the strip, the dock; <b>dark</b>, the quiet chips. Dashed white: Roblox's own. "
          "<span style='color:#FFC978'>Amber dashes: tap areas, never the HUD.</span> Under it, at rest: the base, "
          "layout A (the crescent court, research's pick), its machines marked by dots in the world's layer; in a "
          "fight: Lantern Row in grey, from its plan (no fight happens on the base). Every box, in points, per state: "
          "ar75_hud_layout.json.")


def build(out):
    out.mkdir(parents=True, exist_ok=True)
    layout, cells = {"frame": [W, H], "text": {"small": SMALL, "title": TITLE, "big": BIG}, "tap": TAP, "states": {}}, []
    for n, (key, title, line) in enumerate(STATES, 1):
        hud = frame(key)
        svg_world, sc, cam = world(key)
        svg = svg_world + world_layer(key, sc, cam) + "".join(hud.svg) + fl.roblox() + "".join(hud.notes)
        png = out / f"hud_{n}_{key}.png"
        fl.sf.shoot(fl.page(svg), png, W, H, scale=1.5)
        share = hud.share()
        layout["states"][key] = dict(title=title, share=round(share, 3), elements=hud.boxes)
        cover = "the whole screen" if key == "return" else f"the HUD takes {share:.0%} of the frame"
        cells.append((n, title, line, cover, png))
        print(key, f"{share:.1%}")
    (out / "ar75_hud_layout.json").write_text(json.dumps(layout, indent=1), encoding="utf-8", newline="\n")
    rows = []
    for i in range(0, len(cells), 3):
        tds = "".join(f'<td><div class="t"><b>{n} · {title}</b> <span class="c">({cover})</span></div>'
                      f'<img src="{png.as_uri()}" style="width:852px;display:block"><div class="d">{line}</div></td>'
                      for n, title, line, cover, png in cells[i:i + 3])
        rows.append(f"<tr>{tds}</tr>")
    html = (f'<!doctype html><html><head><meta charset="utf-8"><style>{fl.hm.css()} body{{margin:0;background:#141518;'
            f'color:#E8E2D6;font-family:Builder;font-size:17px}} td{{padding:6px 6px 14px;vertical-align:top;width:852px}}'
            f' h1{{font-size:26px;margin:16px 12px 4px}} p{{margin:0 12px 10px;color:#B9B2A6;max-width:2500px}}'
            f' .t{{margin:4px 0 6px}} .c{{color:#B9B2A6}} .d{{margin-top:6px;color:#CFC8BC;max-width:840px}}'
            f' b{{color:#F2EADB}}</style></head><body><h1>AR75, step 1b: the picked HUD alone, in grey, in every state'
            f'</h1><p>{LEGEND}</p><table>{"".join(rows)}</table></body></html>')
    fl.sf.shoot(html, out / "ar75_hud_states.png", 2600, 1880, scale=1)
    return cells


BESIDE = [("the fight", 3, ("J3", "Jujutsu Infinite, a boss: one thin bar top centre, three small slots at the foot"),
           ("S2", "Sailor Piece, a boss: one column at the left and the boss bar top centre")),
          ("at rest", 2, ("i01", "Anime Crusaders X, its hub: two tile columns at the edges, the hotbar at the foot"),
           None)]


def beside(out, cells, shipped):
    """Internal: our fight and rest frames, each beside shipped frames in grey at the same size (never committed)."""
    pngs = {n: png for n, _, _, _, png in cells}
    rows = []
    for title, n, a, b in BESIDE:
        tds = [f'<td><div class="t"><b>ours, {title}</b></div><img src="{pngs[n].as_uri()}" style="width:852px"></td>']
        for ref in (a, b):
            if ref and ref[0] in shipped:
                tds.append(f'<td><div class="t">{ref[1]} (OBSERVED)</div>'
                           f'<img src="{Path(shipped[ref[0]]).as_uri()}" style="width:852px"></td>')
        rows.append(f'<tr>{"".join(tds)}</tr>')
    html = (f'<!doctype html><html><head><meta charset="utf-8"><style>{fl.hm.css()} body{{margin:0;background:#141518;'
            f'color:#E8E2D6;font-family:Builder;font-size:17px}} td{{padding:6px;vertical-align:top}} img{{display:block}}'
            f' .t{{margin:4px 0 6px}} h1{{font-size:24px;margin:14px 12px 4px}}</style></head><body>'
            f'<h1>AR75, step 1b, beside shipped frames in grey at the same size (internal)</h1>'
            f'<table>{"".join(rows)}</table></body></html>')
    fl.sf.shoot(html, out / "ar75_hud_beside.png", 2620, 1120, scale=1)


if __name__ == "__main__":
    out = Path(sys.argv[1]).resolve()
    cells = build(out)
    shipped = dict(kv.split("=", 1) for kv in sys.argv[2:])
    if shipped:
        beside(out, cells, {k: fl.grey_capture(Path(v).resolve(), out / f"shipped_{k}.png") for k, v in shipped.items()})
