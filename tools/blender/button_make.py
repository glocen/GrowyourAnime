"""AR30: every button in the game in the seam's make, the make the director picked for the Voidkin screen (B, 14:03:
"the B) UI on the left are very good but any other button ui could maybe get reworked"; then "Every button in game").

The feel line (AR30): every button the player presses, on any screen or in the world, is of one make with the Voidkin
screen's rail: quiet, sharp, lit by the seam's light when it's chosen or on. Nothing reads as a toy's bubble.

B's language, carried to every kind: no bright plates at rest. A dark channel holds what can be pressed, cut at its top
left and foot right, edged in the seam's Edge; a word or an icon stands in it in the seam's Text; the seam's Light is the
one bright thing, and it means "this one": the main action's foot, a chosen chip's glass, a mark that's on.
  Main action (Equip, Lead, Break, Open): a slab of dark glass lit from its foot by a bar of Light that washes up into it.
  Second action (Send to work, Sell): the channel, its word, a short line of Light under the word.
  Tabs and chips: one channel split by hairlines; the chosen chip is the rail's chosen tab laid flat, its glass lit from
     its foot line. Sort is its own short channel.
  Icon buttons and Close: the icon stands free, as on the rail; pressed or on, it takes Light and the short line.
  The dock: one channel of three cells, each icon in the colour it means, its short line in that colour.
  A world prompt: a channel plate with the seam's line down its left edge, the key or the tap mark in a cut cap.
Every kind in four states: idle, pressed, chosen or on, unavailable (with its reason, as `docs/ui.md` asks).

blender -b --factory-startup --python tools/blender/button_make.py -- <abs out>
Every number is in authored points (Theme's 812 by 375), drawn at a capture's scale U (its pixels per authored point).
"""
import sys
import textwrap
from pathlib import Path

import numpy as np

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "tools" / "blender"))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
import voidkin_chrome as vc  # noqa: E402
from ui_sheet import c  # noqa: E402
from voidkin_chrome import K, SEAM, Area, Board, glyph, say  # noqa: E402

U_SMALL = 1.1 * 0.85   # the smallest phone's capture: 1.1 pixels a point, drawn at Theme.Scale.Floor (AR29's measure)

ROW = 52.0             # a button's height and its least touch: 44 points on the smallest phone
CUT = 8.0              # the cut corners, top left and foot right, as the bar's channel
WORD = 16.0            # a button's word: Theme.Text.Body, the game's own (Builder Sans Bold in the game)
REASON = 14.0          # a reason under its button, as Kit/Button's Under
ICON = 14.0            # an icon's half size: 24 points drawn on the smallest phone, as the rail's
HAIR = 0.85            # a hairline

# The colours that mean something stay (AR30, "What holds"), with the seam's own.
MEANS = {"Power": "#F2C53D", "Credits": "#3DD6C0", "Map": "#E0566E"}


def wash(t, lo=0.06, hi=0.5, power=3.0):
    """The seam's Light washing up a glass from its foot (t = 1) toward its top (t = 0)."""
    return lo + hi * t ** power


def text_w(text, size, bold=True):
    """About how wide a word is in Blender's face (the game's stands in), from the sheet's own measure."""
    return size * (0.56 if bold else 0.52) * len(text)


def word(items, x, mid, size, text, colour, bold=0.5, align="CENTER"):
    say(items, x, mid - 0.36 * size, size, text, colour, align=align, bold=bold)


# --- the glass and the channel ----------------------------------------------------------------------------------------

def channel(a, x0, y0, x1, y1, u, alpha=0.78, k=CUT):
    d = a.poly(ui.cut_box(x0, y0, x1, y1, k * u, 0, k * u, 0))
    a.paint(d, c(SEAM["Channel"]), alpha)
    a.line(d, HAIR * u, SEAM["Edge"])
    return d


def glass(a, x0, y0, x1, y1, u, lit=1.0, k=CUT, hue=None):
    """Dark glass lit from its foot: a bar of Light along the foot, washing up into it, an outline of Light."""
    light = hue or SEAM["Light"]
    d = a.poly(ui.cut_box(x0, y0, x1, y1, k * u, 0, k * u, 0))
    t = np.clip((a.Y - y0) / max(y1 - y0, 1e-3), 0, 1)
    a.glow(d, 6.0 * u, light, 0.22 * lit)
    a.paint(d, a.vramp(SEAM["Panel"][0], SEAM["Panel"][1], y0, y1), 0.97)
    a.paint(d, c(light), wash(t, 0.06 * lit, 0.5 * lit))
    a.line(d, HAIR * u, light, 0.6 * lit)
    foot = np.maximum(d, (y1 - 2.6 * u) - a.Y)
    a.glow(np.maximum(foot, 0), 6.0 * u, light, 0.5 * lit)
    a.paint(foot, light)
    return d


def underline(a, cx, y, half, u, alpha=1.0, glow=0.3, hue=None):
    """The short line of light under a word or a mark, strongest at its middle."""
    light = hue or SEAM["Light"]
    d = np.maximum(np.abs(a.Y - y) - 0.5 * u, np.abs(a.X - cx) - half)
    prof = 0.15 + 0.85 * np.exp(-((a.X - cx) / (0.6 * half)) ** 2)
    a.glow(np.maximum(d, 0), 2.2 * u, light, glow * prof * alpha)
    a.paint(d, light, prof * alpha)


# --- the kinds --------------------------------------------------------------------------------------------------------

def main_action(a, items, x0, y0, x1, y1, u, label, state="idle", reason=None, hue=None):
    """Equip, Lead, Break, Open: the one thing a screen asks for."""
    mid, cx = (y0 + y1) / 2, (x0 + x1) / 2
    if state == "unavailable":
        channel(a, x0, y0, x1, y1, u, 0.7)
        if reason:
            word(items, cx, mid - 0.5 * WORD * u, WORD * u, label, SEAM["Soft"])
            word(items, cx, mid + 0.56 * WORD * u, REASON * u, reason, SEAM["Soft"], bold=0.0)
        else:
            word(items, cx, mid, WORD * u, label, SEAM["Soft"])
        return
    if state == "pressed":
        y0, y1, mid = y0 + 1.0 * u, y1 + 1.0 * u, mid + 1.0 * u
    glass(a, x0, y0, x1, y1, u, lit={"idle": 1.0, "pressed": 1.45, "on": 0.6}[state], hue=None if state == "on" else hue)
    if state == "on":
        # set, not asked: a mark of Light before the word, the word in Light
        w = text_w(label, WORD * u)
        dx = cx - w / 2 - 7.0 * u
        a.paint(a.poly(vc.diamond(dx, mid, 4.6 * u)), SEAM["Light"])
        word(items, cx + 5.0 * u, mid, WORD * u, label, SEAM["Light"])
    else:
        word(items, cx, mid, WORD * u, label, SEAM["Text"])


def second_action(a, items, x0, y0, x1, y1, u, label, state="idle", reason=None, mark=None):
    """Send to work, Sell, Open one: asked for less."""
    mid, cx = (y0 + y1) / 2, (x0 + x1) / 2
    half = min(0.3 * (x1 - x0), 26.0 * u)
    if state == "pressed":
        y0, y1, mid = y0 + 1.0 * u, y1 + 1.0 * u, mid + 1.0 * u
    if state == "on":
        glass(a, x0, y0, x1, y1, u, 0.75)
        word(items, cx, mid - 1.0 * u, WORD * u, label, SEAM["Text"])
        return
    d = channel(a, x0, y0, x1, y1, u, 0.62 if state == "unavailable" else 0.78)
    if state == "unavailable":
        if reason:
            word(items, cx, mid - 0.5 * WORD * u, WORD * u, label, SEAM["Soft"])
            word(items, cx, mid + 0.56 * WORD * u, REASON * u, reason, SEAM["Soft"], bold=0.0)
        else:
            word(items, cx, mid, WORD * u, label, SEAM["Soft"])
        return
    if state == "pressed":
        t = np.clip((a.Y - y0) / (y1 - y0), 0, 1)
        a.paint(d, c(SEAM["Light"]), wash(t, 0.05, 0.22, 2.0))
        a.line(d, HAIR * u, SEAM["Light"], 0.45)
    underline(a, cx, y1 - 5.0 * u, half if state != "idle" else half * 0.8, u,
              alpha={"idle": 0.55, "pressed": 1.0, "on": 1.0}[state], glow=0.3 if state == "idle" else 0.6)
    if mark:
        # a small mark before the word, in its colour; the pair centred together
        w = text_w(label, WORD * u)
        mark(a, cx - w / 2 - 5.0 * u, mid - 1.2 * u, u, SEAM["Text"])
        cx += 7.0 * u
    word(items, cx, mid - 1.2 * u, WORD * u, label, SEAM["Light"] if state == "on" else SEAM["Text"])


def chip_widths(words, u, size=WORD):
    return [max(ROW * u, text_w(w, size * u) + 2 * 15.0 * u) for w in words]


def chips(a, items, x0, y0, y1, u, words, chosen, pressed=None, off=(), size=WORD, clip=None):
    """The bag's tabs: one channel split by hairlines; the chosen chip is the rail's chosen tab laid flat."""
    widths = chip_widths(words, u, size)
    x1 = x0 + sum(widths)
    channel(a, x0, y0, x1, y1, u)
    mid = (y0 + y1) / 2
    xs = np.cumsum([x0] + widths)
    shown = []
    for i, (w, l, r) in enumerate(zip(words, xs[:-1], xs[1:])):
        cx = (l + r) / 2
        if clip is not None and r > clip:
            break    # a word the panel over it hides
        shown.append(w)
        if i and words[i - 1] != chosen and w != chosen:
            split = np.maximum(np.abs(a.X - l) - 0.5 * HAIR * u, np.abs(a.Y - mid) - ((y1 - y0) / 2 - 13.0 * u))
            a.paint(split, SEAM["Edge"])
        if w == chosen:
            k0 = CUT if i == 0 else 3.0
            glass(a, l + 1.5 * u, y0 + 1.5 * u, r - 1.5 * u, y1 - 1.5 * u, u, 0.9, k=k0)
            word(items, cx, mid - 1.0 * u, size * u, w, SEAM["Text"])
        elif w in off:
            word(items, cx, mid, size * u, w, SEAM["Faint"])
        else:
            if w == pressed:
                underline(a, cx, y1 - 5.0 * u, 0.32 * (r - l), u, 0.8, 0.5)
            word(items, cx, mid - (1.0 * u if w == pressed else 0), size * u, w,
                 SEAM["Text"] if w == pressed else SEAM["Soft"])
    return x1


def sort_chip(a, items, x0, y0, y1, u, value, state="idle"):
    """Sort: its own short channel, the word soft, its value in Text, a small chevron down."""
    size = WORD * u
    w = text_w("Sort: " + value, size) + 2 * 15.0 * u + 14.0 * u
    channel(a, x0, y0, x0 + w, y1, u, 0.62 if state == "unavailable" else 0.78)
    mid = (y0 + y1) / 2
    lx = x0 + 15.0 * u
    off = state == "unavailable"
    ink = SEAM["Faint"] if off else (SEAM["Light"] if state == "on" else SEAM["Text"])
    say(items, lx, mid - 0.36 * size, size, "Sort:", SEAM["Faint"] if off else SEAM["Soft"], align="LEFT", bold=0.3)
    say(items, lx + text_w("Sort: ", size), mid - 0.36 * size, size, value, ink, align="LEFT", bold=0.5)
    vx = x0 + w - 15.0 * u
    a.paint(a.poly([(vx - 5 * u, mid - 2.5 * u), (vx, mid + 2.5 * u), (vx + 5 * u, mid - 2.5 * u),
                    (vx + 5 * u, mid - 0.5 * u), (vx, mid + 4.5 * u), (vx - 5 * u, mid - 0.5 * u)]), ink)
    if state in ("pressed", "on"):
        # pressed, a line rises under it; on (a sort that isn't the default), its value in Light over a short line
        underline(a, x0 + w / 2, y1 - 5.0 * u, 0.3 * w, u, 1.0 if state == "pressed" else 0.8, 0.6)
    return x0 + w


def close_glyph(a, cx, cy, r, colour, alpha=1.0):
    arm = [(-0.92 * r, 0.11 * r), (0.92 * r, 0.11 * r), (0.92 * r, -0.11 * r), (-0.92 * r, -0.11 * r)]
    arms = [a.poly(vc.along_axis(arm, cx, cy, ang)) for ang in (45, -45)]
    # each arm's end cut square to the line it runs along: the kit's sharp ends
    a.paint(np.minimum(*arms), colour, alpha)


def icon_button(a, items, cx, cy, u, name, state="idle"):
    """Close, the favourite, the lock: the icon stands free; pressed or on, it takes Light and its short line."""
    r = ICON * u
    colour = {"idle": SEAM["Text"], "pressed": SEAM["Light"], "on": SEAM["Light"], "unavailable": SEAM["Faint"]}[state]
    if state in ("pressed", "on"):
        a.glow(np.hypot(a.X - cx, a.Y - cy) - r * 0.9, 5.0 * u, SEAM["Light"], 0.16 if state == "on" else 0.3)
        underline(a, cx, cy + r + 6.0 * u, 9.0 * u, u, 1.0, 0.45)
    if name == "Close":
        close_glyph(a, cx, cy, r * 0.82, colour)
    else:
        glyph(a, name, cx, cy, r, colour, on=state == "on")


# --- the dock ---------------------------------------------------------------------------------------------------------

# Today's dock (UIKit.luau, Dock): the wings 60.8 by 44, the middle 70.8 by 54, rising over them.
DOCK_WING, DOCK_MID = (60.8, 52.0), (70.8, 62.0)    # the tap's 52 drawn; the middle rises 10 over the wings
DOCK_MARK = (20.0, 25.0)                              # the marks' half sizes, today's 40 and 50.7
DOCK_CELL = (DOCK_WING[0] * 2 + DOCK_MID[0], DOCK_MID[1])


def dock_glyph(a, name, cx, cy, r, colour, alpha=1.0):
    def P(pts):
        return a.poly([(cx + x * r, cy + y * r) for x, y in pts])
    if name == "Base":
        # a cut house, a bolt through its door: home is where the power is made
        house = P([(-0.86, -0.12), (0, -0.92), (0.86, -0.12), (0.86, 0.9), (-0.86, 0.9)])
        bolt = P([(0.12, -0.36), (-0.34, 0.24), (-0.02, 0.24), (-0.14, 0.72), (0.34, 0.06), (0.02, 0.06)])
        d = np.maximum(house, -(np.maximum(bolt, -bolt - 0.0) - vc.W * r * 0.5))
        d = np.minimum(d, bolt)
    elif name == "Inventory":
        return glyph(a, "Items", cx, cy, r, colour, alpha)
    elif name == "Map":
        # a folded sheet, three panels, a route across it to a diamond
        sheet = P([(-0.94, -0.7), (-0.34, -0.9), (0.34, -0.7), (0.94, -0.9), (0.94, 0.7), (0.34, 0.9), (-0.34, 0.7),
                   (-0.94, 0.9)])
        folds = np.minimum(a.seg((cx - 0.34 * r, cy - 0.9 * r), (cx - 0.34 * r, cy + 0.7 * r)),
                           a.seg((cx + 0.34 * r, cy - 0.7 * r), (cx + 0.34 * r, cy + 0.9 * r))) - vc.W * r * 0.3
        route = np.minimum.reduce([a.seg((cx - 0.66 * r, cy + 0.5 * r), (cx - 0.1 * r, cy + 0.06 * r)),
                                   a.seg((cx - 0.1 * r, cy + 0.06 * r), (cx + 0.3 * r, cy + 0.28 * r)),
                                   a.seg((cx + 0.3 * r, cy + 0.28 * r), (cx + 0.56 * r, cy - 0.2 * r))]) - vc.W * r * 0.4
        pin = P(vc.diamond(0.6, -0.36, 0.26))
        d = np.maximum(sheet, -np.minimum.reduce([folds, route - 0.0, pin + vc.W * r * 0.5]))
        d = np.minimum(d, pin)
    else:
        raise KeyError(name)
    a.paint(d, colour, alpha)
    return d


def dock(a, items, cx, y1, u, states, hues=None, lit=False, new=()):
    """The HUD's dock, as composed today: the bag's cell in the middle rising over Base's and the map's wings. One
    channel holds the three, split by hairlines; each icon in the colour it means, its short line in that colour."""
    hues = hues or {"Base": MEANS["Power"], "Inventory": SEAM["Light"], "Map": MEANS["Map"]}
    (ww, wh), (mw, mh) = DOCK_WING, DOCK_MID
    x0 = cx - (ww + mw / 2) * u
    cells = [("Base", x0, x0 + ww * u, y1 - wh * u), ("Inventory", x0 + ww * u, x0 + (ww + mw) * u, y1 - mh * u),
             ("Map", x0 + (ww + mw) * u, x0 + (2 * ww + mw) * u, y1 - wh * u)]
    k = 9.0 * u
    wings = a.poly(ui.cut_box(x0, y1 - wh * u, x0 + (2 * ww + mw) * u, y1, k, 0, k, 0))
    mid = a.poly(ui.cut_box(cells[1][1] - 2 * u, y1 - mh * u, cells[1][2] + 2 * u, y1, k, 0, 0, 0))
    d = np.minimum(wings, mid)
    a.glow(d, 8.0 * u, SEAM["Channel"], 0.45)
    a.paint(d, c(SEAM["Channel"]), 0.9)
    a.line(d, HAIR * u, SEAM["Edge"])
    for i, (name, l, r, top) in enumerate(cells):
        mx, state, hue = (l + r) / 2, states.get(name, "idle"), hues[name]
        calls = name in new and state != "unavailable"
        if state in ("pressed", "on") or (lit and state == "idle"):
            glass(a, l + 2.0 * u, top + 2.0 * u, r - 2.0 * u, y1 - 2.0 * u, u,
                  {"on": 0.75, "pressed": 1.3, "idle": 1.45 if calls else 1.0}[state], k=7.0 if i == 1 else 3.0,
                  hue=hue)
        colour = SEAM["Faint"] if state == "unavailable" else (SEAM["Text"] if lit else hue)
        rad = DOCK_MARK[1 if i == 1 else 0] * 0.8 * u
        if name == "Inventory":
            glyph(a, "Items", mx, (top + y1) / 2 - 2.5 * u, rad, colour)
        else:
            dock_glyph(a, name, mx, (top + y1) / 2 - 2.5 * u, rad, colour)
        if state == "idle" and not lit:
            underline(a, mx, y1 - 5.0 * u, (12.0 if i == 1 else 9.0) * u, u, 0.8, 0.35, hue=hue)
        if calls:
            # a call: the cell's glass brighter, its whole edge lit in its colour, and over its far corner the pip,
            # standing off the cell on an ink ring as today's does: Light, rimmed in the cell's colour
            k0 = 7.0 if i == 1 else 3.0
            cell = a.poly(ui.cut_box(l + 2.0 * u, top + 2.0 * u, r - 2.0 * u, y1 - 2.0 * u, k0 * u, 0, k0 * u, 0))
            a.glow(np.abs(cell), 6.0 * u, hue, 0.7)
            a.line(cell, 2.2 * u, hue)
            px_, py_ = r - 3.0 * u, top + 3.0 * u
            ring = a.poly(vc.diamond(px_, py_, 10.0 * u))
            a.glow(ring, 6.0 * u, hue, 0.8)
            a.paint(ring, SEAM["Ink"])
            pip = a.poly(vc.diamond(px_, py_, 7.6 * u))
            a.paint(pip, hue)
            a.paint(a.poly(vc.diamond(px_, py_, 4.4 * u)), SEAM["Light"])
    return d


# --- a world prompt ---------------------------------------------------------------------------------------------------

def prompt(a, items, x0, y0, u, title, action, state="idle", key=None, hold=0.6):
    """A world prompt: a channel plate, the seam's line down its left edge, the key (or the tap mark) in a cut cap."""
    h = 60.0 * u
    size = WORD * u
    w = max(text_w(title, size), text_w(action, 0.94 * size, False)) + 62.0 * u
    x1, y1 = x0 + w, y0 + h
    d = channel(a, x0, y0, x1, y1, u, 0.88)
    seam_alpha = {"idle": 1.0, "pressed": 1.0, "on": 1.0, "unavailable": 0.0}[state]
    if seam_alpha:
        line = np.maximum(np.maximum(d, (x0 + 2.4 * u) - a.X), a.X - (x0 + 4.4 * u))
        a.glow(np.maximum(line, 0), 5.0 * u, SEAM["Light"], 0.45)
        a.paint(line, SEAM["Light"])
    # the cap: a cut square with the key's letter, or the tap mark on a phone
    kx, ky, kr = x0 + 26.0 * u, y0 + h / 2, 14.0 * u
    cap = a.poly(ui.cut_box(kx - kr, ky - kr, kx + kr, ky + kr, 5 * u, 0, 5 * u, 0))
    lit = state in ("pressed", "on")
    a.paint(cap, c(SEAM["Light"]) if lit else a.vramp(SEAM["Button"][0], SEAM["Button"][1], ky - kr, ky + kr))
    a.line(cap, HAIR * u, SEAM["Light"] if state != "unavailable" else SEAM["Edge"], 0.7)
    ink = SEAM["Ink"] if lit else (SEAM["Text"] if state != "unavailable" else SEAM["Faint"])
    if key:
        word(items, kx, ky, 0.95 * size, key, ink)
    else:
        a.paint(a.poly(vc.diamond(kx, ky, 6.0 * u)), ink)
    tx = x0 + 48.0 * u
    say(items, tx, y0 + 10.0 * u, size, title, SEAM["Text"] if state != "unavailable" else SEAM["Soft"],
        align="LEFT", bold=0.5)
    say(items, tx, y0 + 33.0 * u, 0.94 * size, action, SEAM["Soft"], align="LEFT")
    if state == "pressed":
        # a hold fills the plate's foot from the cap outward
        bar = np.maximum(np.maximum(d, (y1 - 2.4 * u) - a.Y), a.X - (x0 + (x1 - x0) * hold))
        a.glow(np.maximum(bar, 0), 4.0 * u, SEAM["Light"], 0.5)
        a.paint(bar, SEAM["Light"])
    return x1


# --- the kit sheet ----------------------------------------------------------------------------------------------------

STATES = ("idle", "pressed", "on", "unavailable")
STATE_WORDS = {"idle": "Idle", "pressed": "Pressed", "on": "Chosen or on", "unavailable": "Unavailable"}


def kit_rows(u):
    """Each kind's row: a function drawing it in one state into a cell of the sheet, and the cell's size (authored)."""
    def main(a, items, x, y, state):
        label = {"on": "Leading"}.get(state, "Equip")
        main_action(a, items, x, y, x + 168 * u, y + ROW * u, u, label, state,
                    reason="Warrior only" if state == "unavailable" else None)

    def second(a, items, x, y, state):
        label = "Send to work"
        second_action(a, items, x, y, x + 168 * u, y + ROW * u, u, label, state,
                      reason="Not while leading" if state == "unavailable" else None)

    def chip_row(a, items, x, y, state):
        words = ("All", "Gear", "Jewelry")
        chips(a, items, x, y, y + ROW * u, u, words, chosen="Gear" if state == "on" else "All",
              pressed="Jewelry" if state == "pressed" else None,
              off=("Jewelry",) if state == "unavailable" else ())

    def sorts(a, items, x, y, state):
        sort_chip(a, items, x, y, y + ROW * u, u, "Power" if state == "on" else "Newest", state)

    def icons(a, items, x, y, state):
        for i, name in enumerate(("Close", "Favourite", "Lock")):
            icon_button(a, items, x + (26 + i * 56) * u, y + 26 * u, u, name, state)

    def docks_lit(a, items, x, y, state):
        dock(a, items, x + DOCK_CELL[0] / 2 * u, y + DOCK_CELL[1] * u, u,
             {"Inventory": state} if state != "unavailable" else {"Map": state}, lit=True)

    def docks_new(a, items, x, y, state):
        dock(a, items, x + DOCK_CELL[0] / 2 * u, y + DOCK_CELL[1] * u, u,
             {"Inventory": state} if state != "unavailable" else {"Map": state}, lit=True,
             new=("Inventory",) if state != "on" else ("Base",))

    def readies(a, items, x, y, state):
        ready_chip(a, items, x, y, x + 150 * u, y + ROW * u, u, state=state)

    def claims(a, items, x, y, state):
        label = {"on": "Claimed"}.get(state, "Claim")
        main_action(a, items, x, y, x + 168 * u, y + ROW * u, u, label, state,
                    reason="At base level 4" if state == "unavailable" else None, hue=READY)

    def prompts(a, items, x, y, state):
        title, action = ("Bay 2", "Put a worker in") if state != "unavailable" else ("Bay 3", "Opens at base level 4")
        prompt(a, items, x, y, u, title, action, state)

    return [("Main action", main, 168, ROW), ("Second action", second, 168, ROW), ("Tabs and chips", chip_row, 200, ROW),
            ("Sort", sorts, 168, ROW),
            ("Icon buttons and Close", icons, 168, ROW), ("The dock", docks_lit, 192, DOCK_CELL[1]),
            ("The dock, something new", docks_new, 192, DOCK_CELL[1]),
            ("A shard ready to break", readies, 150, ROW), ("A reward to claim", claims, 168, ROW),
            ("A world prompt", prompts, 210, 60)]


def kit_sheet(out):
    """Each kind in its four states at the smallest phone, on the seam's panel, three times its size and at its own."""
    u = U_SMALL
    pad, colw, gap = 18.0, 236.0, 18.0
    rows = kit_rows(u)
    height = sum(h for _, _, _, h in rows) * u + gap * (len(rows) + 1) + 30
    width = 150 + 4 * colw
    px = rs.canvas(int(width * K), int(height * K), tuple(c(SEAM["Panel"][1])))
    items = []
    y = 30.0
    for title, draw, w, h in rows:
        say(items, 8, y + h * u / 2 - 5, 11, title, SEAM["Soft"], align="LEFT", bold=0.4)
        for i, state in enumerate(STATES):
            x = 150 + i * colw
            a = Area(px, x - pad, y - pad, x + colw - 6, y + h * u + pad)
            draw(a, items, x, y, state)
        y += h * u + gap
    for i, state in enumerate(STATES):
        say(items, 150 + i * colw, 8, 12, STATE_WORDS[state], SEAM["Text"], align="LEFT", bold=0.4)
    for layer in ui.text_layers(px.shape[1], px.shape[0], items).values():
        rs.paste(px, layer, 0, 0)
    b = Board(int(width * K) + 48, int(height * K) + 110 + int(height) + 40)
    b.text(24, 18, 26, "Grow your Anime: every button in the seam's make (AR30), the kit", bold=0.6)
    b.text(24, 54, 14, "Each kind in its four states, drawn at the smallest phone's size, here three times that; under it, "
                       "the same at its own size.", "#B9B0D6")
    b.put(px, 24, 90)
    b.put(rs.shrink(px, 1 / K), 24, 90 + px.shape[0] + 30)
    b.save(out / "buttons_kit.png")


# --- the screens: Faber's captures, today's buttons taken out and drawn in the make --------------------------------------

BUTTONS = REPO / "build" / "handoff" / "UI" / "buttons"
U_IPHONE = 1.13        # the iPhone's 950-pixel capture: today's rail, 68 authored, measures 77 there
WIDE = 950 / 1920      # a 1920-pixel capture brought to the 950 of the others, the phone's own size on the sheet


def step_button(a, x0, y0, x1, y1, u, sign, state="idle"):
    """+ and -: a square channel, its sign in Text."""
    channel(a, x0, y0, x1, y1, u, 0.78, k=6.0)
    cx, cy, r = (x0 + x1) / 2, (y0 + y1) / 2, 7.0 * u
    bar = np.maximum(np.abs(a.X - cx) - r, np.abs(a.Y - cy) - 1.1 * u)
    if sign == "+":
        bar = np.minimum(bar, np.maximum(np.abs(a.Y - cy) - r, np.abs(a.X - cx) - 1.1 * u))
    a.paint(bar, SEAM["Text"])


def rates_mark(a, x, cy, u, colour):
    """Drop rates' mark, three rules of falling length: the odds, longest first."""
    for i, length in enumerate((9.0, 7.0, 4.6)):
        y = cy + (i - 1) * 4.2 * u
        a.paint(np.maximum(np.abs(a.Y - y) - 0.9 * u, np.abs(a.X - (x + length * u / 2)) - length * u / 2), colour)


def frame_over(a, x0, y0, x1, y1, u, ground, lit=False, hue=None, k=CUT):
    """A tile whose contents stay (a chamber, a shard's chip): today's edge painted out, the make's edge drawn on it;
    lit, the glass's light rises from its foot without hiding what's in it."""
    d = a.poly(ui.cut_box(x0, y0, x1, y1, k * u, 0, k * u, 0))
    a.paint(np.abs(d) - 2.2 * u, np.asarray(ground[:3], np.float32))
    light = hue or SEAM["Light"]
    if lit:
        t = np.clip((a.Y - y0) / (y1 - y0), 0, 1)
        a.paint(d, c(light), wash(t, 0.0, 0.32, 3.0))
        a.glow(d, 6.0 * u, light, 0.22)
        a.line(d, HAIR * u, light, 0.7)
        foot = np.maximum(d, (y1 - 2.6 * u) - a.Y)
        a.glow(np.maximum(foot, 0), 6.0 * u, light, 0.5)
        a.paint(foot, light)
    else:
        a.line(d, HAIR * u, SEAM["Edge"])
        underline(a, (x0 + x1) / 2, y1 - 4.0 * u, 0.22 * (x1 - x0), u, 0.6, 0.3, hue=hue)


READY = "#F6DE80"      # Theme.Ready: a shard that's ready, a colour that means something


def ready_chip(a, items, x0, y0, x1, y1, u, words=True, state="idle"):
    """A shard at the Breaker. Ready, it calls: dark glass lit from its foot in Ready's gold and edged in it, as the lit
    dock's cells, "Ready" in that gold (research's must-fix, 14:37: a state that calls keeps its colour's weight).
    Chosen, its edge is the seam's Light. Waiting, it's the plain channel: no gold until it calls."""
    if state == "pressed":
        y0, y1 = y0 + 1.0 * u, y1 + 1.0 * u
    mid = (y0 + y1) / 2
    waiting = state == "unavailable"
    if waiting:
        channel(a, x0, y0, x1, y1, u, 0.82)
    else:
        d = glass(a, x0, y0, x1, y1, u, {"idle": 1.0, "pressed": 1.4, "on": 1.0}[state], k=6.0, hue=READY)
        a.line(d, 1.3 * u, SEAM["Light"] if state == "on" else READY, 1.0 if state == "on" else 0.85)
    sx, r = x0 + 20.0 * u, 11.0 * u
    shard = a.poly([(sx, mid - r), (sx + 0.45 * r, mid - 0.35 * r), (sx + 0.32 * r, mid + 0.7 * r), (sx, mid + r),
                    (sx - 0.4 * r, mid + 0.4 * r), (sx - 0.42 * r, mid - 0.5 * r)])
    a.paint(shard, c("#8C6CF0"), 0.55 if waiting else 1.0)
    a.paint(np.maximum(shard, a.X - sx), c("#B9A4FF"), 0.55 if waiting else 1.0)
    if words:
        top, foot = ("Waiting", "8 s left") if waiting else ("Ready", "Standard")
        say(items, x0 + 38.0 * u, mid - 0.36 * WORD * u - 8.0 * u, WORD * u, top, SEAM["Soft"] if waiting else READY,
            align="LEFT", bold=0.5)
        say(items, x0 + 38.0 * u, mid - 0.36 * REASON * u + 9.0 * u, REASON * u, foot, SEAM["Soft"], align="LEFT")


def load_base(name, scale=1.0):
    px = rs.load(BUTTONS / name)
    if scale != 1.0:
        px = rs.shrink(px, scale)
        px[..., 3] = 1.0
    return vc.enlarge(px)


def chrome_b(px, items, page):
    """AR29's B over a capture that stands as base_items does (the rail and the bar where its are)."""
    base = vc.BASES["items"]
    vc.erase(px, base["rail"], both=False)
    vc.erase(px, base["bar"])
    vc.make_b(px, base, items, vc.BUILT, page)


def finish(px, items):
    for layer in ui.text_layers(px.shape[1], px.shape[0], items).values():
        rs.paste(px, layer, 0, 0)
    return px


def shot_overview():
    """The Overview at the smallest phone: Lead while it leads, Send to work off with its reason."""
    px = vc.screen("overview", vc.make_b)
    items = []
    vc.erase(px, (399, 67, 679, 119))
    a = Area(px, 380, 50, 700, 140)
    main_action(a, items, 401, 70, 536, 116, U_SMALL, "Leading", "on")
    second_action(a, items, 540, 70, 676, 116, U_SMALL, "Send to work", "unavailable", reason="Not while leading")
    return finish(px, items)


def shot_power():
    """The Power screen at the smallest phone: Close, Auto on, the shares' + and -."""
    px = load_base("base_power.png")
    items = []
    for box in ((545, 76, 620, 130), (512, 131, 611, 188), (428, 248, 483, 302), (547, 248, 601, 302),
                (428, 302, 483, 356), (547, 302, 601, 356)):
        vc.erase(px, box)
    a = Area(px, 400, 60, 660, 370)
    icon_button(a, items, 582, 103, U_SMALL, "Close")
    second_action(a, items, 516, 135, 607, 184, U_SMALL, "Auto", "on")
    for y in (251, 305):
        step_button(a, 431, y, 480, y + 48, U_SMALL, "-")
        step_button(a, 550, y, 598, y + 48, U_SMALL, "+")
    return finish(px, items)


def shot_card():
    """An item's card on an iPhone: Equip, the card's X, the bag's chips (Gear now, as the game has them since 13:03)."""
    px = load_base("base_card.png")
    items = []
    chrome_b(px, items, "Items")
    vc.erase(px, (596, 367, 861, 419))
    vc.erase(px, (833, 74, 858, 99))
    vc.erase(px, (457, 72, 586, 122), both=False)
    a = Area(px, 450, 60, 586, 130)
    chips(a, items, 459, 75, 119, U_IPHONE, ("All", "Gear", "Jewelry"), "All", clip=586)
    b = Area(px, 586, 60, 880, 430)
    icon_button(b, items, 845, 86, U_IPHONE, "Close")
    main_action(b, items, 598, 370, 858, 415, U_IPHONE, "Equip")
    return finish(px, items)


def shot_chests():
    """A chest's card on an iPhone: Open one, a second action; Open them all, the main."""
    px = load_base("base_chests.png")
    items = []
    chrome_b(px, items, "Items")
    vc.erase(px, (596, 366, 862, 422))
    vc.erase(px, (833, 74, 858, 99))
    vc.erase(px, (457, 72, 586, 122), both=False)
    chips(Area(px, 450, 60, 586, 130), items, 459, 75, 119, U_IPHONE, ("All", "Gear", "Jewelry"), "All", clip=586)
    b = Area(px, 586, 60, 880, 430)
    icon_button(b, items, 845, 86, U_IPHONE, "Close")
    second_action(b, items, 598, 370, 725, 416, U_IPHONE, "Open")
    main_action(b, items, 731, 370, 858, 416, U_IPHONE, "Open 2")
    return finish(px, items)


def shot_breaker():
    """The Breaker on an iPhone: Close, Take out, Drop rates, the chambers, the ready shards, the dock and the eye."""
    px = load_base("base_breaker.jpg", WIDE)
    u, f = 1.65 * WIDE, WIDE
    items = []
    ground = (0.125, 0.13, 0.155, 1.0)
    vc.erase(px, (686 , 97, 756, 147))
    vc.erase(px, (536, 192, 739, 241))
    a = Area(px, 190, 80, 760, 300)
    icon_button(a, items, 721, 121, u * 1.1, "Close")
    main_action(a, items, 539.5, 194.5, 635, 238, u, "Take out")
    second_action(a, items, 641, 194.5, 736, 238, u, "Drop rates", mark=rates_mark)
    for i, x in enumerate((417, 581, 747, 913)):
        frame_over(a, x * f, 338 * f, (x + 152) * f, 574 * f, u, ground, lit=i == 0)
    vc.erase(px, (410 * f, 622 * f, 1064 * f, 718 * f), both=False)
    a = Area(px, 190, 300, 1064 * f, 370)
    for x in (416, 677, 938):
        ready_chip(a, items, x * f, 627 * f, (x + 246) * f, 712 * f, u, words=x + 246 <= 1064)
    dock_shot(px, items, u, f, lit=True)
    return finish(px, items)


def dock_shot(px, items, u, f, states=None, lit=False, new=()):
    """Today's dock and eye taken out of a 1920 capture; the make's drawn where they stood."""
    vc.erase(px, (792 * f, 745 * f, 1125 * f, 868 * f))
    vc.erase(px, (132 * f, 278 * f, 216 * f, 360 * f))
    a = Area(px, 360, 330, 600, 450)
    dock(a, items, 957.5 * f, 852 * f, u, states or {}, lit=lit, new=new)
    e = Area(px, 50, 120, 130, 200)
    channel(e, 137 * f, 283 * f, 211 * f, 355 * f, u, 0.88)
    eye(e, 174 * f, 319 * f, 12.0 * u, SEAM["Text"])


def eye(a, cx, cy, r, colour, open_=False):
    """The spectate toggle's eye, shut: a lid's line and its lashes, cut straight."""
    lid = np.minimum(a.seg((cx - r, cy - 0.1 * r), (cx, cy + 0.38 * r)), a.seg((cx, cy + 0.38 * r), (cx + r, cy - 0.1 * r)))
    lashes = np.minimum.reduce([a.seg((cx + dx * r, cy + (0.2 if dx else 0.38) * r),
                                      (cx + dx * 1.5 * r, cy + (0.62 if dx else 0.8) * r)) for dx in (-0.55, 0, 0.55)])
    a.paint(np.minimum(lid, lashes) - 0.1 * r, colour)


def shot_hud(lit=False, new=()):
    """At the base on an iPhone: the dock, the eye, and a prompt where the bay's would show."""
    px = load_base("base_hud.jpg", WIDE)
    u, f = 1.65 * WIDE, WIDE
    items = []
    dock_shot(px, items, u, f, lit=lit, new=new)
    a = Area(px, 150, 200, 400, 300)
    prompt(a, items, 172, 226, u, "Bay 1", "Set worker")
    return finish(px, items)


SHOTS = [
    ("overview", "The Overview, the smallest phone", lambda: vc.screen("overview", None), shot_overview),
    ("power", "The Power screen, the smallest phone", lambda: load_base("base_power.png"), shot_power),
    ("card", "An item's card, an iPhone", lambda: load_base("base_card.png"), shot_card),
    ("chests", "A chest's card, an iPhone", lambda: load_base("base_chests.png"), shot_chests),
    ("breaker", "The Breaker, an iPhone", lambda: load_base("base_breaker.jpg", WIDE), shot_breaker),
    ("hud", "At the base, an iPhone: the dock lit (research's pick), the bag with something new",
     lambda: load_base("base_hud.jpg", WIDE), lambda: shot_hud(True, ("Inventory",))),
]


def phone_sheet(out):
    """Each screen, today's and the make's side by side, at the capture's own size."""
    gap, head = 24, 96
    shots = [(key, label, rs.shrink(today(), 1 / K), rs.shrink(make(), 1 / K)) for key, label, today, make in SHOTS]
    w = 950
    height = head + sum(t.shape[0] + 52 for _, _, t, _ in shots) + gap
    b = Board(gap * 3 + w * 2, height)
    b.text(gap, 18, 26, "Grow your Anime: every button in the seam's make (AR30), on the screens", bold=0.6)
    lead = ("Faber's captures as they stand, today's on the left; on the right, their buttons taken out and drawn in the "
            "make, at the capture's own size. The Overview and the Power screen are at the smallest phone; the rest on "
            "an iPhone until Faber's smallest-phone set. The Voidkin screen's rail and bar are AR29's B.")
    for i, line in enumerate(textwrap.wrap(lead, 160)):
        b.text(gap, 52 + i * 18, 14, line, "#B9B0D6")
    y = head
    for key, label, today, made in shots:
        b.text(gap, y + 12, 17, label, bold=0.4)
        b.text(gap * 2 + w, y + 12, 17, "In the seam's make", bold=0.4)
        b.put(today, gap, y + 40)
        b.put(made, gap * 2 + w, y + 40)
        y += today.shape[0] + 52
    b.save(out / "buttons_phone.png")


# --- the cut: the images the make adds to the kit, white on alpha for the game to tint ----------------------------------
# Every button's glass and channel are the kit's own slices (ui_kit.py, `buttons`: the same 8-point cuts at the top left
# and the foot right), tinted and layered as AR30's numbers say. What the kit hasn't got is cut here: the make's small
# marks, the dock's own body, and the short line under a word.

PT = 4.0                       # pixels a point, as the kit's slices
ICON_PX, ICON_R = vc.CUT, vc.CUT_R   # an icon's image, and the half size its glyph is drawn at in it (AR29's 128 and 52)


def _sign(a, cx, cy, s, plus):
    bar = np.maximum(np.abs(a.X - cx) - 7.0 * s, np.abs(a.Y - cy) - 1.1 * s)
    if plus:
        bar = np.minimum(bar, np.maximum(np.abs(a.Y - cy) - 7.0 * s, np.abs(a.X - cx) - 1.1 * s))
    a.paint(bar, "#FFFFFF")


def _chevron(a, cx, cy, s):
    # Sort's chevron, its middle 1 point under the word's middle in the make: drawn here about its own middle
    vx, mid = cx, cy - 1.0 * s
    a.paint(a.poly([(vx - 5 * s, mid - 2.5 * s), (vx, mid + 2.5 * s), (vx + 5 * s, mid - 2.5 * s),
                    (vx + 5 * s, mid - 0.5 * s), (vx, mid + 4.5 * s), (vx - 5 * s, mid - 0.5 * s)]), "#FFFFFF")


# file: (its half extent in points as the make draws it, how to draw it about (cx, cy) at s pixels a point, its use)
CUT_ICONS = {
    "SeamClose": (8.4, lambda a, cx, cy, s: close_glyph(a, cx, cy, 0.82 * ICON * s, "#FFFFFF"),
                  "Close, the X: on every panel, top right"),
    "SeamMark": (1.0, lambda a, cx, cy, s: a.paint(a.poly(vc.diamond(cx, cy, s)), "#FFFFFF"),
                 "the diamond: a set action's mark, a world prompt's tap mark, and the pip's three layers"),
    "SeamChevron": (5.0, _chevron, "Sort's chevron"),
    "SeamRates": (5.1, lambda a, cx, cy, s: rates_mark(a, cx - 4.5 * s, cy, s, "#FFFFFF"), "Drop rates' mark"),
    "SeamPlus": (7.0, lambda a, cx, cy, s: _sign(a, cx, cy, s, True), "Power's +"),
    "SeamMinus": (7.0, lambda a, cx, cy, s: _sign(a, cx, cy, s, False), "Power's -"),
    "DockSeamBase": (1.0, lambda a, cx, cy, s: dock_glyph(a, "Base", cx, cy, s, "#FFFFFF"), "the dock's Base"),
    "DockSeamMap": (1.0, lambda a, cx, cy, s: dock_glyph(a, "Map", cx, cy, s, "#FFFFFF"), "the dock's Map"),
    # two glows drawn about a mark: the pip's ring (a diamond of 10 glowing 6), Close's halo when pressed (a disc of
    # 12.6 glowing 5); each extent leaves the glow faded out at the image's edge
    "SeamPipGlow": (22.0, lambda a, cx, cy, s: a.glow(a.poly(vc.diamond(cx, cy, 10.0 * s)), 6.0 * s, "#FFFFFF", 1.0),
                    "the pip's glow, under its ink ring"),
    "SeamHalo": (23.0, lambda a, cx, cy, s: a.glow(np.hypot(a.X - cx, a.Y - cy) - 0.9 * ICON * s, 5.0 * s, "#FFFFFF",
                                                   1.0), "an icon button's halo, pressed"),
}

TOP = 1.45     # the brightest a glass is lit (a main action pressed, a dock cell calling): what a light layer is cut at


def dock_shape(a, ox, oy):
    """The dock's one channel, its wings and its raised middle united, its top-left corner at (ox, oy), in points."""
    (ww, wh), (mw, mh) = DOCK_WING, DOCK_MID
    y1 = oy + mh
    wings = a.poly(ui.cut_box(ox, y1 - wh, ox + 2 * ww + mw, y1, 9.0, 0, 9.0, 0))
    mid = a.poly(ui.cut_box(ox + ww - 2.0, oy, ox + ww + mw + 2.0, y1, 9.0, 0, 0, 0))
    return np.minimum(wings, mid)


def dock_cells():
    """Each cell's glass: (name, its top-left in the dock's frame, its size, its cut), as `dock` draws it."""
    (ww, wh), (mw, mh) = DOCK_WING, DOCK_MID
    return (("Wing", (2.0, mh - wh + 2.0), (ww - 4.0, wh - 4.0), 3.0),
            ("Mid", (ww + 2.0, 2.0), (mw - 4.0, mh - 4.0), 7.0))


def plate(w, h, pad, draw):
    """An image of w by h points with `pad` round it, 4 pixels a point, drawn by `draw(a)` in points."""
    W, H = int(round((w + 2 * pad) * PT)), int(round((h + 2 * pad) * PT))
    px = np.zeros((H * K, W * K, 4), np.float32)
    a = Area(px, 0, 0, W, H)
    a.X, a.Y = a.X / PT, a.Y / PT
    draw(a)
    return rs.shrink(px, 1 / K)


def cell_light(a, d, y0, y1):
    """A glass's light at TOP in one layer over its fill: the halo outside it, the wash, the outline, the foot's glow.
    The game scales it by its ImageTransparency (1 - lit / TOP), as the make scales its strengths by lit."""
    t = np.clip((a.Y - y0) / (y1 - y0), 0, 1)
    outside = np.clip(0.5 + d * K, 0, 1)                         # inside, the fill covers the halo
    ui.over(a.px, c("#FFFFFF"), outside * 0.22 * TOP * np.exp(-(np.maximum(d, 0) / 6.0) ** 1.4))
    a.paint(d, "#FFFFFF", wash(t, 0.06 * TOP, 0.5 * TOP))
    a.line(d, HAIR, "#FFFFFF", 0.6 * TOP)
    foot = np.maximum(d, (y1 - 2.6) - a.Y)
    a.glow(np.maximum(foot, 0), 6.0, "#FFFFFF", 0.5 * TOP)


def export_cut(out):
    """The images, white on alpha, in `out`/images, and their review sheet."""
    folder = out / "images"
    folder.mkdir(parents=True, exist_ok=True)
    made, edge_free = {}, set()
    for file, (extent, draw, _) in CUT_ICONS.items():
        px = np.zeros((ICON_PX * K, ICON_PX * K, 4), np.float32)
        draw(Area(px, 0, 0, ICON_PX, ICON_PX), ICON_PX / 2, ICON_PX / 2, ICON_R / extent)
        made[file] = rs.shrink(px, 1 / K)
        edge_free.add(file)
    # the dock: its one channel, the channel's edge, its shadow; then each cell's glass in four layers
    (ww, wh), (mw, mh) = DOCK_WING, DOCK_MID
    w = 2 * ww + mw
    made["DockSeamBody"] = plate(w, mh, 0, lambda a: a.paint(dock_shape(a, 0, 0), "#FFFFFF"))
    made["DockSeamEdge"] = plate(w, mh, 0, lambda a: a.line(dock_shape(a, 0, 0), HAIR, "#FFFFFF"))
    made["DockSeamShadow"] = plate(w, mh, 24, lambda a: a.glow(dock_shape(a, 24, 24), 8.0, "#FFFFFF", 1.0))
    edge_free.add("DockSeamShadow")
    for name, _, (cw, ch), k in dock_cells():
        def shape(a, o, cw=cw, ch=ch, k=k):
            return a.poly(ui.cut_box(o, o, o + cw, o + ch, k, 0, k, 0))

        def call(a, shape=shape):
            d = shape(a, 18)
            a.glow(np.abs(d), 6.0, "#FFFFFF", 0.7)
            a.line(d, 2.2, "#FFFFFF")
        made[f"DockSeamGlass{name}"] = plate(cw, ch, 0, lambda a, shape=shape: a.paint(shape(a, 0), "#FFFFFF"))
        made[f"DockSeamLight{name}"] = plate(cw, ch, 18, lambda a, shape=shape, ch=ch: cell_light(a, shape(a, 18), 18,
                                                                                                    18 + ch))
        made[f"DockSeamFoot{name}"] = plate(cw, ch, 0, lambda a, shape=shape, ch=ch: a.paint(
            np.maximum(shape(a, 0), (ch - 2.6) - a.Y), "#FFFFFF"))
        made[f"DockSeamCall{name}"] = plate(cw, ch, 18, call)
        edge_free |= {f"DockSeamLight{name}", f"DockSeamCall{name}"}

    # a glass button's foot, cut clean (the kit's ButtonBase lays a dark band over its line, which the make hasn't):
    # the foot 4 points of the kit's 28-point box; and the foot's glow, 18 up into the box and 18 round it
    def foot(a):
        d = a.poly(ui.cut_box(0, -24.0, 28.0, 4.0, CUT, 0, CUT, 0))
        a.paint(np.maximum(d, (4.0 - 2.6) - a.Y), "#FFFFFF")
    made["SeamFoot"] = plate(28.0, 4.0, 0, foot)

    def foot_glow(a):
        d = a.poly(ui.cut_box(18.0, -10.0, 46.0, 18.0, CUT, 0, CUT, 0))
        a.glow(np.maximum(np.maximum(d, (18.0 - 2.6) - a.Y), 0), 6.0, "#FFFFFF", 1.0)
    made["SeamFootGlow"] = plate(64.0, 36.0, 0, foot_glow)
    edge_free.add("SeamFootGlow")

    # the short line of light under a word, 64 points long in a 76 by 16 image, stretched to its length; its glow apart
    def underline_image(a, glow):
        d = np.maximum(np.abs(a.Y - 8.0) - 0.5, np.abs(a.X - 38.0) - 32.0)
        prof = 0.15 + 0.85 * np.exp(-((a.X - 38.0) / (0.6 * 32.0)) ** 2)
        if glow:
            ui.over(a.px, c("#FFFFFF"), prof * np.exp(-(np.maximum(d, 0) / 2.2) ** 1.4))
        else:
            a.paint(d, "#FFFFFF", prof)
    for file in ("SeamUnderline", "SeamUnderlineGlow"):
        made[file] = plate(76.0, 16.0, 0, lambda a, g=file.endswith("Glow"): underline_image(a, g))
        edge_free.add(file)
    for file, img in made.items():
        if file in edge_free:   # nothing that fades touches its image's edge (the glow under the foot is cut at its top)
            sides = [img[-1, :, 3], img[:, 0, 3], img[:, -1, 3]] + ([] if file == "SeamFootGlow" else [img[0, :, 3]])
            assert max(v.max() for v in sides) < 0.02, (file, [round(float(v.max()), 3) for v in sides])
        rs.save(img, folder / f"{file}.png")
    review(out, made)
    print("cut", len(made), "images into", folder, {k: v.shape[:2] for k, v in made.items()})


def review(out, made):
    """Each image over the seam's panel: the icons in a row at 128 and at 64, the rest at full size and 64 high."""
    gap = 24
    icons = {k: v for k, v in made.items() if v.shape[:2] == (ICON_PX, ICON_PX)}
    rest = {k: v for k, v in made.items() if k not in icons}
    thumbs = {k: rs.shrink(v, 64 / v.shape[0]) if v.shape[0] > 64 else v for k, v in rest.items()}
    width = max(gap + len(icons) * (ICON_PX + gap),
                max(v.shape[1] + thumbs[k].shape[1] for k, v in rest.items()) + 3 * gap)
    height = 60 + ICON_PX + gap + 64 + 80 + sum(v.shape[0] + 50 for v in rest.values()) + 40
    b = Board(width, height, SEAM["Panel"][0])
    b.text(gap, 16, 22, "AR30, the cut: the make's images, white on alpha, at full size and at 64, over the seam's "
           "panel", bold=0.5)
    x = gap
    for file, img in icons.items():
        b.put(img, x, 60)
        b.put(rs.shrink(img, 0.5), x + ICON_PX / 4, 60 + ICON_PX + gap)
        b.text(x, 60 + ICON_PX + gap + 64 + 10, 11, file, SEAM["Soft"])
        x += ICON_PX + gap
    y = 60 + ICON_PX + gap + 64 + 80
    for file, img in rest.items():
        b.text(gap, y - 22, 12, f"{file}, {img.shape[1]} by {img.shape[0]}, and at 64 high", SEAM["Soft"])
        b.put(img, gap, y)
        b.put(thumbs[file], img.shape[1] + 2 * gap, y)
        y += img.shape[0] + 50
    b.save(out / "buttons_cut_review.png")


def check_cut(out):
    """The cut proven: the lit dock rebuilt from the images by AR30's numbers (each layer's tint and opacity, as the
    game lays them), beside the make's own drawing, over a pale ground and the panel. Prints the difference."""
    img = {p.stem: rs.load(p) for p in (out / "images").glob("*.png")}
    img["Items"] = rs.load(out.parent / "voidkin" / "chrome" / "images" / "VoidkinPageItems.png")
    u, pad = PT, 30.0
    (ww, wh), (mw, mh) = DOCK_WING, DOCK_MID
    W, H = int(round((2 * ww + mw + 2 * pad) * u)), int(round((mh + 2 * pad) * u))
    hues = {"Base": MEANS["Power"], "Inventory": SEAM["Light"], "Map": MEANS["Map"]}
    (_, wing_at, _, _), (_, mid_at, _, _) = dock_cells()
    cells = (("Base", "Wing", wing_at, ww, mh - wh), ("Inventory", "Mid", mid_at, ww + mw, 0.0),
             ("Map", "Wing", (wing_at[0] + ww + mw, wing_at[1]), 2 * ww + mw, mh - wh))
    cases = (({}, ("Inventory",)), ({"Base": "pressed", "Map": "on"}, ()))
    rows, worst = [], 0.0
    for ground in ("#A9A79C", SEAM["Panel"][0]):
        for states, new in cases:
            px = np.zeros((H * K, W * K, 4), np.float32)
            px[...] = (*c(ground), 1.0)
            dock(Area(px, 0, 0, W, H), [], (pad + ww + mw / 2) * u, (pad + mh) * u, u, states, lit=True, new=new)
            made = rs.shrink(px, 1 / K)
            built = np.zeros((H, W, 4), np.float32)
            built[...] = (*c(ground), 1.0)

            def lay(name, x, y, tint, opacity, size=None, centre=False, grad=None):
                im = img[name] if size is None else rs.shrink(img[name], size * u / img[name].shape[0])
                h, w = im.shape[:2]
                x0 = int(round((pad + x) * u - (w / 2 if centre else 0)))
                y0 = int(round((pad + y) * u - (h / 2 if centre else 0)))
                colour = grad if grad is not None else c(tint)[None, None, :] * im[..., :3]
                ui.over(built[y0:y0 + h, x0:x0 + w], colour, im[..., 3] * opacity)

            lay("DockSeamShadow", -24, -24, SEAM["Channel"], 0.45)
            lay("DockSeamBody", 0, 0, SEAM["Channel"], 0.9)
            lay("DockSeamEdge", 0, 0, SEAM["Edge"], 1.0)
            for name, kind, (gx, gy), right, top in cells:
                state, calls, hue = states.get(name, "idle"), name in new, hues[name]
                lit = {"on": 0.75, "pressed": 1.3, "idle": TOP if calls else 1.0}[state]
                gh = img[f"DockSeamGlass{kind}"].shape[0]
                t = ((np.arange(gh) + 0.5) / gh)[:, None, None]
                panel = c(SEAM["Panel"][0]) + (c(SEAM["Panel"][1]) - c(SEAM["Panel"][0])) * t
                lay(f"DockSeamGlass{kind}", gx, gy, None, 0.97, grad=panel)
                lay(f"DockSeamLight{kind}", gx - 18, gy - 18, hue, lit / TOP)
                lay(f"DockSeamFoot{kind}", gx, gy, hue, 1.0)
                mx, my = (right - (ww if kind == "Wing" else mw) / 2), (top + mh) / 2 - 2.5
                rad = DOCK_MARK[1 if kind == "Mid" else 0] * 0.8
                lay("Items" if name == "Inventory" else f"DockSeam{name}", mx, my, SEAM["Text"], 1.0,
                    size=ICON_PX * rad / ICON_R, centre=True)
                if calls:
                    lay(f"DockSeamCall{kind}", gx - 18, gy - 18, hue, 1.0)
                    pip = (right - 3.0, top + 3.0)
                    lay("SeamPipGlow", *pip, hue, 0.8, size=ICON_PX * 22.0 / ICON_R, centre=True)
                    for r, ink in ((10.0, SEAM["Ink"]), (7.6, hue), (4.4, SEAM["Light"])):
                        lay("SeamMark", *pip, ink, 1.0, size=ICON_PX * r / ICON_R, centre=True)
            diff = np.abs(made[..., :3] - built[..., :3])
            worst = max(worst, float(diff.mean()))
            print(f"dock rebuilt over {ground}, {states or 'idle'} {new or ''}: mean difference "
                  f"{diff.mean() * 255:.2f} of 255, 99th percentile {np.percentile(diff, 99) * 255:.1f}")
            gap = np.zeros((H, 16, 4), np.float32)
            gap[...] = (*c(SEAM["Panel"][1]), 1.0)
            heat = np.concatenate([np.clip(diff * 4, 0, 1), np.ones((H, W, 1), np.float32)], axis=2)
            rows.append(np.concatenate([made, gap, built, gap, heat], axis=1))
    sheet = np.concatenate([np.concatenate([r, np.zeros((16, r.shape[1], 4), np.float32) + 1.0 * 0], axis=0)
                            for r in rows], axis=0)
    sheet[..., 3] = 1.0
    rs.save(sheet, out / "buttons_cut_check.png")
    assert worst * 255 < 2.0, worst * 255


def main():
    out = bl.out_dir()
    if "cut" in sys.argv[sys.argv.index("--") + 1:]:
        export_cut(out)
        check_cut(out)
        return
    kit_sheet(out)
    phone_sheet(out)


if __name__ == "__main__":
    main()
