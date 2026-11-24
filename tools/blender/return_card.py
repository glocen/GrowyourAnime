"""AR55, the return card's look, the finish (docs/asset-requests.md, AR55; docs/test-requests.md, TR53): what the base
made while the player was away, on research's pick of 2026-11-23, 19:09, at the smallest phone (568 x 320 points, two
pixels a point).

    the card        A, the Slip: a narrow system slab at the right under the pills, a line a change (the machine's own
                    picture in a small well lit in the machine's colour, the gain large, one soft word), the press across
                    its foot under the right thumb: "Collect", or "Reveal" with a shard ready. It grows up from its foot
                    with each line; the yard and the dock stay in view.
    during a run    a tab hung from the run's line, right of the dare's tab (AR53), in the line's own glass: the shard's
                    picture and its time left. As the shard breaks the tab opens into the notice, two lines, under the
                    line and clear of the fight's middle. After it the tab reads "Ready" until the player is home.

The game's kit builds nearly all of it (Config.UIKit, System: the slab, the rows, the Primary and Ready presses; the
run's line's glass). The cut is the three images the kit lacks: a line's well, its light, and the Ready tab's glow. The
pictures are the game's own, already made. The words are research's (AR55, "Research's pick"). The blockout's three
directions are in git (ec6c82a).

The content check's conditions on the plan are kept: nothing sold or sped up on any piece; "Reveal" promises nothing;
no burst, rays or confetti; the breaking's mark is the shard's own picture.

    blender -b --factory-startup --python tools/blender/return_card.py -- <abs out>
    blender -b --factory-startup --python tools/blender/return_card.py -- <abs build/handoff/UI/return> cut

Writes:
    return_card.png         the card on the yard: one, two and four changes, four and a Mid line, a shard alone, singulars
    return_run.png          the run's tab: breaking, under an unfolded dare, opened into the notice, Ready, a long time
    return_small.png        every phone at 64 pixels high
    return_pictures.png     for the content check: the card and the tab's states at twice the phone's pixels
    return_new.png          for the content check: the cut's files on the slab's teal, the page's dark and white
With `cut`, in place of the last three:
    images/*.png            the cut
    return.json             where everything lies, and what the game's kit builds
    return_cut.png          every image over the page's dark
"""
import gc
import json
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
import upgrade_pages as up  # noqa: E402
import stage_screen as ss  # noqa: E402
import stage_seam as sm  # noqa: E402
import goals_look as gl  # noqa: E402

W, H = ss.W, ss.H
SMALL, TITLE = ss.SMALL, ss.TITLE
P = sm.P
UI = up.REPO / "build" / "handoff" / "UI"
YARD = up.REPO / "build" / "captures" / "tr51" / "phone_stage3_court.png"
# Config.UIKit, System: the deep teal slab in a sand edge, ivory ink; Primary, the one main action's sand plate in ink
SYS = dict(panel=("#34606C", "#2A4E5A"), edge="#E2CFA4", facet="#A9DCD4", glint="#F2FFF9", text="#FFF6E2", soft="#D9E8E2",
           channel="#0E1D23", well="#21414A", main=("#F0E2C4", "#DCCBA6"), ready=("#FFE29A", "#F2C766"), ink="#1E3238")
POWER, ROSE, CYAN, SILVER, CREDITS = ui.CHARGE, "#FF8FAE", "#4FD1FF", "#E6ECF7", "#40DCC6"
HEAD = "While you were away"
NOTICE = ("Your shard broke.", "Its Voidkin waits at home.")
# A line: its picture (and how large it's drawn against its box), the gain, its soft word, its machine's colour
GAINS = {
    "battery": dict(pic=UI / "hud" / "colour" / "images" / "Battery.png", grow=1.0, gain="+12.40 kWh", what="stored",
                    colour=POWER, image="Battery (build/handoff/UI/hud/colour)"),
    "low": dict(pic=UI / "upgrades" / "images" / "StoneLow.png", grow=1.15, gain="+6", what="Low stones", colour=ROSE,
                image="StoneLow (build/handoff/UI/upgrades)"),
    "mid": dict(pic=UI / "upgrades" / "images" / "StoneMid.png", grow=1.15, gain="+1", what="Mid stone", colour=ROSE,
                image="StoneMid (build/handoff/UI/upgrades)"),
    "training": dict(pic=UI / "hud" / "images" / "PortraitRookSmall.png", face=True, grow=1.0, gain="+2 levels", what="Rook",
                     colour=CYAN, image="the Voidkin's own face: the kit's small portrait (Portrait<Name>Small, or "
                                        "PortraitUnknown<Rarity>Small), its face's square"),
    "shard": dict(pic=UI / "shards" / "shard_standard_small.png", grow=1.2, gain="1 shard", what="ready", colour=SILVER,
                  image="the shard's small picture, of the shard that broke (build/handoff/UI/shards)"),
}
ORDER = ("battery", "low", "mid", "training", "shard")
X0, X1, FOOT = 372.0, 560.0, 314.0     # the slab: its sides and its foot, from the screen's top left. 188 wide: the
                                       # battery's line is ten characters as Read.Kwh writes it ("+12.40 kWh")
PITCH, TIGHT = 26.0, 21.0              # a line's height: up to four lines, and with five (186 lie under the pills)
SEAT = 22.0                            # the well, as cut; the game scales it to the line (pitch - 4)
FACE = (110, 112, 148)                 # a small portrait's face: this square of its 368 x 400 pixels (left, top, side)
LINE = (163, 448, 62)                  # the run's line as the game lays it on this phone (build/captures/tr50/line.png)
DARE_TAB = (8, 30, 34, 70)             # AR53's tab, from the line's glass's top left
TAB = (40, 30, 112, 70)                # the base's tab beside it
OPEN = (40, 30, 223, 88)               # opened into the notice: its right 6 short of the Electricity pill
SPOTS = {}
_px = {}


def wide(text, size, bold=False):
    return ss.wide_of(text, size) * (1.05 if bold else 1.0)


def picture(t, key, cx, cy, size, alpha=1.0, g=None):
    """A line's picture, `size` points high, its middle at (cx, cy). A Voidkin's is its face's square."""
    g = g or GAINS[key]
    path = str(g["pic"])
    if path not in _px:
        _px[path] = rs.load(g["pic"])
        if g.get("face"):
            x, y, side = FACE
            _px[path] = _px[path][y:y + side, x:x + side].copy()
    s = size * g["grow"]
    im = rs.shrink(_px[path], s * ui.K / _px[path].shape[0])
    im[..., 3] *= alpha
    t.image(im, cx - im.shape[1] / ui.K / 2, cy - s / 2)


# --- the cut's three images ---------------------------------------------------------------------------------------------

def seat_shape(t):
    return t.poly(ui.cut_box(0, 0, SEAT, SEAT, 4, 1, 4, 1))


def seat(t):
    """A line's well, its top left at 0: the slab's channel falling to its well, a shade under its upper lip, a facet rim."""
    d = seat_shape(t)
    t.paint(d, t.ramp(SYS["channel"], SYS["well"], t.y / SEAT))
    t.paint(d, "#04090B", 0.4 * np.exp(-np.maximum(t.y, 0) / 3.0))
    t.line(d, 1.0, SYS["facet"], 0.45)


def seat_light(t):
    """The light in a well, white: the game tints it the line's machine's colour."""
    d = seat_shape(t)
    t.paint(d + 1.0, "#FFFFFF", 0.6 * np.exp(-(((t.x - SEAT / 2) / 8.0) ** 2 + ((t.y - SEAT * 0.62) / 7.0) ** 2)))


def soft_glow(t):
    """The Ready tab's glow behind the shard's picture, white, its middle the origin: the game tints it."""
    t.paint(np.full_like(t.x, -1.0), "#FFFFFF", 0.6 * np.exp(-(t.x ** 2 + t.y ** 2) / 49.0))


def cut_pieces():
    gl.piece("ReturnSeat", (-4, -4, SEAT + 4, SEAT + 4), seat, use="a line's well, under its picture")
    gl.piece("ReturnSeatLight", (-4, -4, SEAT + 4, SEAT + 4), seat_light, tint="the line's machine's colour",
             use="over the well, under the picture: the machine's light")
    gl.piece("ReturnGlow", (-18, -18, 18, 18), soft_glow, tint="the Breaker's silver",
             use="behind the shard's picture in the run's tab once it reads Ready")


# --- the card -----------------------------------------------------------------------------------------------------------

def slab(t, x0, y0, x1, y1, cut=8.0, alpha=0.95):
    """The kit's system panel, as Panel builds it."""
    pts = lambda dy: ui.cut_box(x0, y0 + dy, x1, y1 + dy, cut, cut * 0.3, cut, cut * 0.3)  # noqa: E731
    t.glow(t.poly(pts(3)), 8.0, "#04090B", 0.5)
    d = t.poly(pts(0))
    t.paint(d, t.ramp(SYS["panel"][0], SYS["panel"][1], (t.y - y0) / (y1 - y0)), alpha)
    t.paint(d, SYS["glint"], 0.10 * np.exp(-np.maximum(t.y - y0, 0) / 16))
    t.line(d, 1.3, SYS["edge"], 0.95)
    return d


def press(t, x0, y0, x1, y1, word):
    """The card's one press, the kit's: Primary's sand plate in ink for "Collect"; the slab's Ready gold for "Reveal"."""
    fill = SYS["ready"] if word == "Reveal" else SYS["main"]
    d = t.poly(ui.cut_box(x0, y0, x1, y1, 6, 2, 6, 2))
    t.glow(d, 5.0, fill[0], 0.32 if word == "Reveal" else 0.16)
    t.paint(d, t.ramp(fill[0], fill[1], (t.y - y0) / (y1 - y0)))
    t.line(d, 1.0, "#FFFFFF", 0.55)
    t.text((x0 + x1) / 2, (y0 + y1) / 2 - TITLE * 0.42, TITLE, word, SYS["ink"], "CENTER", bold=0.45)


def pitch_of(n):
    return PITCH if n <= 4 else TIGHT


def card_top(n):
    return FOOT - (78 + n * pitch_of(n))


def card(t, keys, says=None):
    """The card: its head, a line a change in the machines' order, the press across its foot."""
    n, p = len(keys), pitch_of(len(keys))
    y0, s = card_top(n), pitch_of(len(keys)) - 4
    slab(t, X0, y0, X1, FOOT)
    t.text(X0 + 10, y0 + 7, SMALL, HEAD, SYS["soft"])
    y = y0 + 26
    for key in keys:
        g = dict(GAINS[key], **(says or {}).get(key, {}))
        t.stroke([(X0 + 8, y), (X1 - 8, y)], 1.0, SYS["facet"], 0.22)
        gl.lay(t, "ReturnSeat", X0 + 9, y + 2, scale=s / SEAT)
        gl.lay(t, "ReturnSeatLight", X0 + 9, y + 2, scale=s / SEAT, tint=g["colour"])
        picture(t, key, X0 + 9 + s / 2, y + 2 + s / 2, s - 4 if g.get("face") else s - 5, g=g)
        gx = X0 + 9 + s + 7
        t.text(gx, y + p / 2 - TITLE * 0.42, TITLE, g["gain"], SYS["text"], bold=0.35)
        t.text(X1 - 11, y + p / 2 - SMALL * 0.42, SMALL, g["what"], SYS["soft"], "RIGHT")
        clear = (X1 - 11 - wide(g["what"], SMALL)) - (gx + wide(g["gain"], TITLE, True))
        print(f"line {key:9s} {g['gain']:>10s} | {g['what']:<10s} clear between them {clear:5.1f}")
        assert clear >= 0, (key, clear)                  # by ss.wide_of, which runs wide of the sheet's face
        y += p
    press(t, X0 + 8, FOOT - 50, X1 - 8, FOOT - 6, "Reveal" if "shard" in keys else "Collect")
    SPOTS.setdefault(f"card{n}", (X0 - 10, y0 - 10, X1 + 8, FOOT + 6))


# --- the HUD round it: stand-ins ----------------------------------------------------------------------------------------

def ghost(t, x0, y0, x1, y1, *words):
    d = up.box(t, x0, y0, x1, y1, "#0B0D14", None, 1.0, 5)
    t.line(d, 1.0, "#5A6070", 0.8)
    for k, w in enumerate(words):
        t.text((x0 + x1) / 2, (y0 + y1) / 2 - len(words) * 8 + k * 16 + 1, SMALL, w, "#8A90A0", "CENTER")


def pill(t, x0, y0, x1, y1, colour, words):
    """A pill of the HUD's column: its block in its system's colour, its reading."""
    d = t.poly(ui.cut_box(x0, y0, x1, y1, 5, 2, 5, 2))
    t.glow(d, 5.0, "#04090B", 0.4)
    t.paint(d, t.ramp("#1A222C", "#0D1218", (t.y - y0) / (y1 - y0)), 0.94)
    t.line(d, 1.2, colour, 0.95)
    t.paint(np.maximum(d, t.x - (x0 + y1 - y0)), colour, 0.9)
    t.text(x1 - 7, (y0 + y1) / 2 - SMALL * 0.42, SMALL, words, "#FFFFFF", "RIGHT", bold=0.3)


def hud(t, stored, step=False):
    ghost(t, 8, 77, 155, 150, "the lead's card")
    pill(t, 455, 72, 560, 97, CREDITS, "46,310")
    pill(t, 392, 103, 560, 128, POWER, "2.4 kW      " + stored)
    for k in range(3):
        ghost(t, 203 + k * 56, 262, 253 + k * 56, 304)
    if step:
        ghost(t, 162, 222, 405, 247, "the next step's plate")


def home(t, st):
    """The yard as the player comes back to it (TR51's capture), the HUD's pieces as stand-ins, and the card."""
    if "yard" not in _px:
        px = rs.load(YARD)
        _px["yard"] = rs.shrink(px, W * ui.K / px.shape[1])
    t.px[..., :3], t.px[..., 3] = ui.c("#9DB0BA"), 1.0
    t.image(_px["yard"], 0, 0)
    sm.stand_in(t)
    hud(t, "19.0 kWh")
    card(t, st["keys"], st.get("says"))


# --- during a run, in the Festival --------------------------------------------------------------------------------------

def run_line(t, dare=None):
    """The run's line as StageController builds it. `dare`: the stretch has just started, and its dare's tab is open
    under the line (AR53, research's must-fix of 20:07): the rows `dare` breaks into."""
    acc = sm.ACC[False]
    x0, x1, y0 = LINE
    sm.glass(t, x0, y0, x1, y0 + 40, False, 6, 1.2)
    sm.badge(t, x0 + 7, y0 + 7, 2, False, True)
    tx = x0 + 41
    t.text(tx, y0 + 5, TITLE, "Stretch 2 of 4", P["text"], bold=0.3)
    t.text(x1 - 10, y0 + 7, SMALL, "0 / 10" if dare else "5 / 10", P["soft"], "RIGHT")
    ry, ex = y0 + 31, x1 - 16
    d = t.poly(ui.cut_box(tx, ry - 3, ex - 6, ry + 3, 2, 2, 2, 2))
    t.paint(d, P["channel"])
    t.line(d, 1.0, P["edge"], 0.9)
    if not dare:
        sm.fill(t, tx + 1, tx + (ex - 6 - tx) * 0.5, ry, 1.6, acc, ex - 6)
    disc = t.poly([(ex + 6.5 * np.cos(a), ry + 6.5 * np.sin(a)) for a in np.linspace(0, 2 * np.pi, 24, endpoint=False)])
    t.paint(disc, P["channel"])
    t.line(disc, 1.2, P["edge"])
    for k, row in enumerate(dare or ()):
        t.text(tx, y0 + (51 if len(dare) == 1 else 48 + 18 * k), SMALL, row, P["text"])


def tab_wide(words):
    """The tab follows its words: 72 with five characters."""
    return max(72.0, 14 + 16 + 6 + wide(words, SMALL) + 8)


def festival(t, st):
    """The run's HUD on a stand-in street: the base's tab beside the dare's, under the run's line."""
    ui.world(t, "noon")
    sm.stand_in(t)
    x0, _x1, y0 = LINE
    state, dare = st["state"], st.get("dare")
    hud(t, "31.4 kWh", step=True)
    a = DARE_TAB
    rows = gl.broken(dare, OPEN[2] - 8 - 41) if dare else None
    foot = (a[3] if len(rows) == 1 else OPEN[3]) if rows else 40
    down = foot - 40                                     # the base's tab rides the open dare's foot
    b = OPEN if state == "open" else TAB
    right = b[2] if state == "open" else b[0] + tab_wide(st["words"])
    sm.glass(t, x0 + b[0], y0 + b[1] + down, x0 + right, y0 + b[3] + down, False, 6 if state == "open" else 4, 1.0)
    if rows:                                             # the dare's tab, open to the right
        end = min(OPEN[2], 41 + max(gl.face_wide(r, SMALL) for r in rows) + 10)
        sm.glass(t, x0 + a[0], y0 + a[1], x0 + end, y0 + foot, False, 4 if len(rows) == 1 else 6, 1.0)
        print(f"run sheet, dare {dare!r}: {len(rows)} row(s) in {OPEN[2] - 8 - 41:.0f}, right {end:.0f}")
    else:
        sm.glass(t, x0 + a[0], y0 + a[1], x0 + a[2], y0 + a[3], False, 4, 1.0)
    run_line(t, rows)
    gl.dare_mark(t, x0 + 21, y0 + 57, gl.MARK_H)
    if state == "open":
        picture(t, "shard", x0 + 51, y0 + 64, 20)
        t.text(x0 + 62, y0 + 48, SMALL, NOTICE[0], P["text"], bold=0.3)
        t.text(x0 + 62, y0 + 66, SMALL, NOTICE[1], P["soft"])
    else:
        cy = y0 + 57 + down
        if state == "ready":
            gl.lay(t, "ReturnGlow", x0 + 54, cy, tint=SILVER)
        picture(t, "shard", x0 + 54, cy, 16)
        t.text(x0 + right - 8, cy - SMALL * 0.42, SMALL, st["words"], P["text"] if state == "ready" else P["soft"], "RIGHT",
               bold=0.35 if state == "ready" else 0.0)
    SPOTS.setdefault(f"tab_{state}{'_dare' if dare else ''}", (x0 - 6, y0 - 6, 400, y0 + (124 if dare else 100)))


# --- the sheets ---------------------------------------------------------------------------------------------------------

CARD_CELLS = [
    ("One change: the battery alone", dict(keys=("battery",))),
    ("Two changes", dict(keys=("battery", "low"))),
    ("Four changes, a shard among them: the press is Reveal", dict(keys=("battery", "low", "training", "shard"))),
    ("Four changes and a convert's Mid stone: five lines, at the tighter pitch",
     dict(keys=ORDER, says=dict(shard=dict(gain="2 shards")))),
    ("A shard alone", dict(keys=("shard",))),
    ("Stones and one level: \"level\" is singular at 1",
     dict(keys=("low", "mid", "training"), says=dict(low=dict(gain="+11"), training=dict(gain="+1 level", what="Lyric",
                                                           pic=UI / "hud" / "images" / "PortraitLyricSmall.png")))),
]
CARD_NOTES = [
    "Research's pick, A: a narrow system slab at the right under the pills, from 372 to 560, its foot at 314. A line a",
    "change, in the machines' order: its picture in a small well lit in the machine's colour (the battery's yellow, the",
    "Condenser's rose, the Training machine's cyan, the Breaker's silver), the gain large at 17, one soft word at 14 at",
    "the right. The Training machine's line shows who trained: the Voidkin's own face from the kit's portrait.",
    "The press runs across the foot, 44 tall, under the right thumb: Collect on the kit's sand plate, Reveal",
    "on the slab's Ready gold when a shard is among the lines. The card grows up from its foot: 78 and 26 a line. With",
    "five lines (a convert's Mid stone beside all four) a line is 21, so the card still stands under the Electricity",
    "pill: 186 points lie between that pill and the card's foot, and the card is 182 tall with four lines, 183 with",
    "five. The yard, the dock and the pills stay as they are; the",
    "next step's plate waits while the card is up. The kit builds the slab, the lines' words and the press; the cut is",
    "the well and its light. The slab is 188 wide, 8 more than the blockout's: the game reads kWh to the hundredth",
    "under 100, so the battery's line is ten characters. The words are research's. Stand-ins: the numbers, the names,",
    "the HUD's grey boxes.",
]
RUN_CELLS = [
    ("During a run: the shard breaking at home, its time left, right of the dare's tab", dict(state="breaking", words="12:40")),
    ("A stretch starts: the dare's tab opens for its 3 seconds, in two rows, and the base's tab rides its foot",
     dict(state="breaking", words="12:40", dare="Break a raised shield with your signature.")),
    ("The shard breaks: the tab opens into the notice, two lines, clear of the fight's middle", dict(state="open")),
    ("After it: the tab reads Ready until the player is home", dict(state="ready", words="Ready")),
    ("A long break: the tab follows its words", dict(state="breaking", words="1:42:10")),
    ("A short dare opens on one row, and the base's tab rides that",
     dict(state="breaking", words="12:40", dare="Stand outside every slam.")),
]
RUN_NOTES = [
    "Research's pick, B's tab: the base's state hangs from the",
    "run's line right of the dare's tab, in the line's own glass,",
    "40 tall like its neighbour: the shard's own picture and its",
    "time left, at 14. While the dare's tab is open (AR53) it",
    "rides that tab's foot. As the shard breaks it opens to",
    "the right into the notice, two lines, its right edge 6 short",
    "of the Electricity pill; a notice that falls due while a",
    "dare is open waits for its close. After the notice the",
    "tab reads Ready, a soft silver glow behind the shard, until",
    "the player is home. No shard in the Breaker: no tab.",
    "The kit builds the glass and the words; the cut is the glow.",
    "The open dare stops 6 short of the Electricity pill, as the",
    "notice does, and breaks at a word when it is too long: no",
    "piece under the line lies over another piece of the HUD.",
]


def r2(v):
    return [r2(x) for x in v] if isinstance(v, (list, tuple)) else round(float(v), 2)


def ltwh(box):
    x0, y0, x1, y1 = box
    return r2([x0, y0, x1 - x0, y1 - y0])


def record():
    """return.json: where everything lies and what the game's own kit builds. Points, the smallest phone."""
    images = {name: dict(file=f"images/{name}.png", pixels=[p["px"].shape[1], p["px"].shape[0]],
                         origin=r2([-p["box"][0], -p["box"][1]]), **({"tint": p["tint"]} if p["tint"] else {}), use=p["use"])
              for name, p in gl.PIECES.items()}
    return dict(
        what="AR55, the return card's look, for TR53: research's pick of 2026-11-23, 19:09 (A's card; B's tab for the run; "
             "the notice out of the tab). Every word is research's (docs/asset-requests.md, AR55, 'Research's pick'): this "
             "file holds where words sit, never the words.",
        units="points at the smallest phone (568 x 320); every box is left, top, width, height; a word's y is its capitals' "
              "top; images at 4 pixels a point, edge alpha 0. An image's `origin` is where its lay point sits in it, in "
              "points from its top left (times 4 for pixels)",
        strict="the sheets stand the HUD's pieces where a capture has them on screen (build/captures/tr50/fix-line.png) and "
               "draw the kit's sizes at one to one. The game draws at 0.85 on that phone (Theme.Scale.Floor), so it has "
               "about a sixth more room than the sheets: every fit here is the strict case. Anchor to the pieces (the "
               "Electricity pill's foot, the screen's right and foot, the line's foot), not to these screen numbers",
        sheets=["return_card.png", "return_run.png", "return_cut.png"],
        card=dict(
            note="the kit builds it: Panel in the System palette, a line a change, one Button. Boxes from the screen's top "
                 "left unless said",
            slab=dict(left=X0, right=X1, foot=FOOT, height="78 + lines x pitch", pitch=dict(up_to_four=PITCH, five=TIGHT),
                      corners="8 and 2.4, as the system windows", palette="Config.UIKit, System",
                      stands="under the Electricity pill (its foot at 128): 186 points to the card's foot; the card is 182 "
                             "tall with four lines, 183 with five. The dock, the pills and the lead's card stay; the next "
                             "step's plate waits while the card is up"),
            head=dict(x=10, y=7, size=SMALL, colour=SYS["soft"], frame="from the slab's top left"),
            lines=dict(
                frame="from the slab's top left; line k's top is 26 + k x pitch", order=list(ORDER),
                rule=dict(y=0, inset=8, height=1, colour=SYS["facet"], transparency=0.78),
                seat=dict(images=["ReturnSeat", "ReturnSeatLight"], origin=[9, 2], scale=f"(pitch - 4) / {SEAT:g}",
                          light="ReturnSeatLight tinted the line's colour"),
                picture=dict(centre="the well's middle", height="(pitch - 9) x the picture's grow",
                             face=dict(of="the Training machine's line: the Voidkin's small portrait's face, no frame",
                                       rect=dict(offset=[FACE[0], FACE[1]], size=[FACE[2], FACE[2]], of=[368, 400]),
                                       side="pitch - 8: the well inset 2, so its corners meet the well's cuts"),
                             images={k: GAINS[k]["image"] for k in ORDER}, grow={k: GAINS[k]["grow"] for k in ORDER}),
                colours={k: GAINS[k]["colour"] for k in ORDER},
                gain=dict(x="9 + (pitch - 4) + 7", y="the line's middle", size=TITLE, bold=True, colour=SYS["text"]),
                word=dict(right="11 from the slab's right", y="the line's middle", size=SMALL, colour=SYS["soft"],
                          align="RIGHT"),
                widest="the battery's: ten characters as Read.Kwh writes a gain under 100 ('+12.40 kWh') beside "
                       "'stored'; the slab's 188 holds it in the sheet's face"),
            press=dict(box="inset 8 from the slab's sides, its top 50 over the slab's foot, 44 tall",
                       collect="the kit's Primary button", reveal="the kit's Ready button, when a shard is among the lines",
                       size=TITLE)),
        run=dict(
            note="boxes from the run's line's glass's top left, as AR53's dare (build/handoff/UI/goals/goals.json)",
            tab=dict(box=ltwh(TAB), make="the line's own glass, under it, corners cut 4: the dare's tab's twin, 6 to its "
                                         "right; its place holds when the dare's tab is absent",
                     width="14 + 16 + 6 + its words + 8, never under 72",
                     picture=dict(image=GAINS["shard"]["image"], centre=[54, 57], height=r2(16 * GAINS["shard"]["grow"])),
                     words=dict(right="8 from the tab's right", y=r2(57 - SMALL * 0.42), size=SMALL, colour=P["soft"],
                                text="the time left, as Read gives it"),
                     rides="the open dare's foot while a dare is open (build/handoff/UI/goals/goals.json, dare, line, "
                           "unfolded): its top as far above that foot as above the line's, so 26 lower under one row, 44 "
                           "under two, in goals.json's points",
                     hard="the same tab in the Hard line's glass", none="no shard in the Breaker: no tab"),
            notice=dict(box=ltwh(OPEN), make="the same glass, corners cut 6, opened to the right from the tab",
                        picture=dict(centre=[51, 64], height=r2(20 * GAINS["shard"]["grow"])),
                        lines=[dict(x=62, y=48, size=SMALL, bold=True, colour=P["text"]),
                               dict(x=62, y=66, size=SMALL, colour=P["soft"])],
                        right="6 short of the Electricity pill at this phone", waits="for the dare's close when a dare is open",
                        note="not the kit's toast: that stays one line"),
            ready=dict(glow=dict(image="ReturnGlow", origin=[54, 57], tint=SILVER),
                       words=dict(colour=P["text"], bold=True), until="the player is home")),
        images=images,
        motion="nothing moves here beyond what the kit does. The card's rise, a line's count, the tab's opening and its "
               "fold back to Ready are TR53's block, and research reads them in motion there",
    )


def cut(out):
    """The images, return.json and the cut's own sheet: every image over the page's dark, at half its pixels."""
    images = out / "images"
    images.mkdir(parents=True, exist_ok=True)
    for old in images.glob("*.png"):
        old.unlink()
    for name, p in gl.PIECES.items():
        rs.save(p["px"], images / f"{name}.png")
        a = p["px"][..., 3]
        edge = float(max(a[0].max(), a[-1].max(), a[:, 0].max(), a[:, -1].max()))
        print(f"{name:20s} {a.shape[1]}x{a.shape[0]}  edge alpha {edge * 255:.1f}")
        assert edge * 255 < 1.0, f"{name} has alpha at its edge"
    (out / "return.json").write_text(json.dumps(record(), indent=1), encoding="utf-8", newline="\n")
    grounds(out, "return_cut.png", f"AR55, the return card's cut: {len(gl.PIECES)} images at 4 pixels a point")


def grounds(out, name, title):
    """The cut's files as they are, at their own pixels and at 64 pixels high: over the slab's teal, the page's dark and
    white. The two lights are white images, shown too in the tint the game gives them."""
    ui.K = gl.CUT_K
    gap, cw = 14, 150
    sheet = ui.Sheet(gap + 3 * (cw + gap), 48 + 3 * 60 + gap / 2, "#101117")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(gap, 8, 11, title, "#EDE6D6")
    t.text(gap, 22, 9, "on the slab's teal, the page's dark and white: as cut, as tinted, at 64 pixels high", "#B4AC9C")
    tints = {"ReturnSeat": None, "ReturnSeatLight": POWER, "ReturnGlow": SILVER}
    for col, ground in enumerate((SYS["panel"][1], "#241F3D", "#FFFFFF")):
        x0 = gap + col * (cw + gap)
        up.box(t, x0 - gap / 2, 38, x0 + cw - gap / 2, sheet.h - gap / 2, ground, cut=0.0)
        y = 48
        for piece in gl.PIECES:
            b = gl.PIECES[piece]["box"]
            gl.lay(t, piece, x0 + 4 - b[0], y - b[1])
            if tints[piece]:
                gl.lay(t, piece, x0 + 54 - b[0], y - b[1], tint=tints[piece])
            px = gl.PIECES[piece]["px"]
            t.image(rs.shrink(px, 64 / px.shape[0]), x0 + 110, y)
            y += 60
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / name)


def pictures(out, crops, names):
    """For the content check: the card and the tab's states at twice the phone's pixels."""
    ui.K = 2
    gap = 14
    doubled = [np.repeat(np.repeat(c, 2, axis=0), 2, axis=1) for c in crops]
    per = 3
    rows = [doubled[k:k + per] for k in range(0, len(doubled), per)]
    wide_ = max(sum(c.shape[1] / 2 + gap for c in row) for row in rows) + gap
    tall = 50 + sum(max(c.shape[0] for c in row) / 2 + gap + 22 for row in rows)
    sheet = ui.Sheet(wide_, tall, "#101117")
    t = sheet.tile(0, 0, 1, 1)
    t.text(gap, 16, 20, "AR55's finish: the card and the run's tab, at twice the phone's pixels", "#EDE6D6", bold=0.2)
    y, k = 50, 0
    for row in rows:
        x = gap
        for c in row:
            t.text(x, y + 2, SMALL, names[k], "#B4AC9C")
            rs.paste(sheet.px, c, round(x * 2), round((y + 22) * 2))
            x += c.shape[1] / 2 + gap
            k += 1
        y += max(c.shape[0] for c in row) / 2 + gap + 22
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "return_pictures.png")


def crop(shot, box):
    x0, y0, x1, y1 = (round(v * 2) for v in box)
    return shot[max(y0, 0):y1, max(x0, 0):x1].copy()


def main():
    out = bl.out_dir()
    rs.OUT = out
    cut_pieces()
    common = "at the smallest phone (568 x 320 points)"
    cards = ss.sheet_of(out, "return_card.png", f"AR55, the return card, {common}", CARD_CELLS, H, CARD_NOTES,
                        lambda sheet, ox, oy, st: home(sheet.tile(ox, oy, W, H), st))
    crops = [crop(cards[k], SPOTS[f"card{n}"]) for k, n in ((2, 4), (3, 5), (0, 1))]
    names = ["four changes", "five lines", "one change"]
    groups = [[rs.shrink(shot, 64 / (H * 2)) for shot in cards]]
    del cards
    runs = ss.sheet_of(out, "return_run.png", f"AR55, the base's tab on the run's line, {common}", RUN_CELLS, H, RUN_NOTES,
                       lambda sheet, ox, oy, st: festival(sheet.tile(ox, oy, W, H), st))
    crops += [crop(runs[0], SPOTS["tab_breaking"]), crop(runs[2], SPOTS["tab_open"]), crop(runs[3], SPOTS["tab_ready"])]
    names += ["the tab, breaking", "opened: the notice", "Ready"]
    groups.append([rs.shrink(shot, 64 / (H * 2)) for shot in runs])
    del runs
    gc.collect()
    if sys.argv[-1] == "cut":
        cut(out)
        return
    gap = 12
    sw = groups[0][0].shape[1]
    page = rs.canvas(gap + max(len(g) for g in groups) * (sw + gap), gap + len(groups) * (64 + gap), tuple(rs.rgb("#101117")))
    for r, shots in enumerate(groups):
        for k, shot in enumerate(shots):
            rs.paste(page, shot, gap + k * (sw + gap), gap + r * (64 + gap))
    rs.save(page, out / "return_small.png")
    pictures(out, crops, names)
    grounds(out, "return_new.png", "AR55's finish: the three new files")


if __name__ == "__main__":
    main()
