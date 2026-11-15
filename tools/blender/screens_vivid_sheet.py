"""AR12, delivery 3 (docs/asset-requests.md, AR12, "Delivery 3, the older screens, vivid"): each screen built all dark
gets its room's colour, words wear their meaning's colour, and the battery's text becomes a charge bar in kWh. This draws
the sheets research judges before any image is made: today beside vivid, at a phone's size.

The Breaker first, as a galaxy (the director, 2026-11-15: "the void breaker should be a galaxy like Ui but well well
composed mature and beautifull and even animated if possible", then on the first mock's spiral: "not a literal galaxy
form just paletee of colors and stars it need a bit more composition"). Today's side is Faber's own take of the build (TR9,
Machine), a still cut to the phone's screen:

    ffmpeg -ss 11 -i build/captures/tr9/machine_retake.mkv -frames:v 1 -vf crop=936:430:811:599 build/scratch/modulo/d3/breaker_line.png
    ffmpeg -ss 15 -i build/captures/tr9/machine_retake.mkv -frames:v 1 -vf crop=936:430:811:599 build/scratch/modulo/d3/breaker_ready.png

The galaxy's side keeps that layout and is drawn over the same still, so the world behind is the game's own. The sky is
void_sky.py's. The pieces are the kit's slices and AR12's icons; the numbers are research's seeds
(tools/balance/seeds.json, "power"). Text is Blender's face standing in for the game's.

    blender -b --factory-startup --python tools/blender/screens_vivid_sheet.py -- build/handoff/UI/hud/colour
    ... -- build/scratch/modulo/d3/motion motion    the screen over black and over white, for void_breaker_motion.py
"""
import sys
import textwrap
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import hud_colour_sheet as h  # noqa: E402
import void_sky as vs  # noqa: E402

kit, ui, rs, c = h.kit, h.ui, h.rs, h.c
W, H, K4 = h.W, h.H, h.K4
STILLS = h.REPO / "build" / "scratch" / "modulo" / "d3"
POWER = h.POWER
# A rarity's word. The frames' own colours, but for two: Common's steel is too dim for a small word on a plate, so its
# word is paler; Mythical's word takes its trim, since its light is too dark to read.
WORD = {"Common": "#AEB4C0", "Uncommon": "#7CF0A0", "Rare": "#6FB6FF", "Epic": "#D29CFF", "Legendary": "#FFD777",
        "Mythical": "#FF8794"}
BATTERY = (6, 60)  # stored, the cap, in kWh: a sample that pays Low voltage and falls short of High
# Voltage (the director, 2026-11-15: "let use real electrician words", then "Faster break"; docs/design.md, "Infusion
# is voltage"): stored energy buys time, never luck. Low halves a shard's time left, High breaks it now. The prices are
# research's for a Drum Court Enriched, 15 min, the ground's factor 1.5, rounded up to a whole kWh (research,
# 2026-11-15; tools/balance/seeds.json, "voltage"). A Standard is offered none, since it would save under a minute, and
# Lantern Row has only Standards. A level: its name, its kWh, what it saves, what that leaves.
VOLTAGE = (("Low voltage", 4, "\u22127 min 30", "7 min 30 left"), ("High voltage", 8, "Breaks now", ""))
# Drop rates (the director, 2026-11-15: "drop rate is that simple", and "it obviously dont contain everything the odd
# are off"): every Voidkin a shard can give, under each rarity's total, to 100%. A Lantern Row Standard: the pool's
# totals (seeds.json, "pools") over the ground's Voidkin (docs/roster.md, "Lantern Row's shards at launch"), a rarity's
# total shared evenly among its Voidkin.
RATES = (("Common", 60, ("Rook", "Kirra", "Pip", "Watt")), ("Uncommon", 30, ("Sable",)), ("Rare", 9, ("Lyric",)),
         ("Epic", 1, ("Marigold",)))

PX, PY, PW, PH = vs.PANEL  # the screen's panel: it covers the built one's on the still
DX, DY, DW, DH = PX + 430.0, PY + 40.0, PW - 442.0, PH - 52.0  # the chosen shard's panel
# The galaxy's room. Its panel is the sky itself; these are its plates, which lie over the sky and hold every number.
# The lights are Power's: what's spent here is the battery's charge, and gold is the one warm thing in a cool sky.
GALAXY = dict(kit.PALETTES["Void Violet"], panel=("#17123F", "#0B0926"), alpha=1.0, edge="#5F5BCB", facet="#9CA4FF",
              glint="#DDE2FF", text="#F5F2FF", soft="#BDBAE6", faint="#8683BA", channel="#04030C", well="#080616",
              button=("#1F1A55", "#120F36"), pressed=("#0D0A28", "#17123F"), ground="#161238", accent=POWER)
GLASS = "#0A0824"  # a window's glass
SMALL = 11  # the smallest text on the screen (research, 2026-11-15: 9 and 10 came out at about 7 pt on a phone)
EMBER = "#F29A3B"  # the rim of a gold light on the night


def veil(*stops):
    """How much of a tile's body shows, down its height: (share of the height, cover) pairs."""
    at, cover = [s[0] for s in stops], [s[1] for s in stops]
    return lambda rows, cols: np.interp(np.linspace(0, 1, rows), at, cover).astype(np.float32)[:, None]


def filled(st, x, y, w, hh, p, glow=0.5):
    """A box filled with the room's colour, as the screen's main action is (h.main_button), without its label."""
    accent = p["accent"]
    st.lay("ButtonShadow", x, y, w, hh)
    st.lay("ButtonRingGlow", x, y, w, hh, tint=accent, alpha=glow)
    st.lay("ButtonFill", x, y, w, hh, tint=(h.mix(accent, h.PALE[accent], 0.3), h.mix(accent, h.DEEP[accent], 0.4)))
    st.lay("ButtonEdgeBold", x, y, w, hh, tint=h.DEEP[accent])
    st.lay("ButtonBase", x, y, w, hh, tint=h.PALE[accent])


def box(st, x, y, w, hh, p, state="rest", alpha=1.0):
    """A plate inside the panel: a shard in the line, the battery's. `lit` wears a ring in the room's colour."""
    if state == "lit":  # the glow lies under the plate, so the plate keeps its own colour
        st.lay("ButtonRingGlow", x, y, w, hh, tint=p["accent"], alpha=0.7)
    st.lay("ButtonFill", x, y, w, hh, tint=p["button"], alpha=1.0 if state == "lit" else alpha)
    st.lay("ButtonEdge", x, y, w, hh, tint=p["edge"])
    if state == "lit":
        st.lay("ButtonRing", x, y, w, hh, tint=p["accent"])


def pip(st, cx, cy, colour):
    """A rarity's pip beside its word, so the colour is never the word's only sign of what it names."""
    t = kit.blank(14, 14)
    d = h.g_diamond(t, 7, 7, 4.4, 5.6)
    t.paint(d - 1.2, c(h.STROKE))
    t.paint(d, c(colour))
    t.paint(h.g_diamond(t, 6.2, 5.6, 1.5, 2.0), c("#FFFFFF"), 0.55)
    h.place(st, t, cx - 7, cy - 7)


def arrow(st, cx, cy, colour):
    t = kit.blank(16, 10)
    t.paint(np.maximum(np.abs(t.x - 6.5) - 5.0, np.abs(t.y - 5) - 0.8), c(colour))
    t.paint(t.poly(((9.5, 1.2), (14.5, 5.0), (9.5, 8.8))), c(colour))
    h.place(st, t, cx - 8, cy - 5)


def lock(st, cx, cy, colour, size=24.0):
    k = size / 24.0
    t = kit.blank(24 * k, 28 * k)
    x, y = (t.x - 12 * k) / k, (t.y - 14 * k) / k
    ring = np.maximum(np.abs(np.hypot(x, y + 3.0) - 5.2) - 1.3, y + 2.0)
    t.paint(np.minimum(ring, np.maximum(np.abs(x) - 8.0, np.abs(y - 4.5) - 6.0)) * k, c(colour), 0.9)
    t.paint((np.hypot(x, y - 4.0) - 1.8) * k, c("#000000"), 0.6)
    h.place(st, t, cx - 12 * k, cy - 14 * k)


def light(st, cx, cy, r, colour, strength=0.42):
    """A soft light behind a shard: the void's lavender while it works, gold when it's broken."""
    t = kit.blank(4 * r, 4 * r)
    d = np.hypot(t.x - 2 * r, t.y - 2 * r)
    cover = strength * np.exp(-(np.maximum(d - r * 0.3, 0) / (r * 0.7)) ** 1.4) * np.clip((2 * r - d) / (0.8 * r), 0, 1)
    ui.over(t.px, c(colour), cover.astype(np.float32))  # it dies out before the tile's own edge
    h.place(st, t, cx - 2 * r, cy - 2 * r)


SPLIT = 100.0 / 144.0  # where a chamber's window ends and its plate begins
HEAD = 21.0 / 144.0  # the strip at its top that holds its name


def sky_box(st, x, y, w, hh):
    """The sky as it lies inside a tile's shape, to lay again over a glow that would cloud the window."""
    fill = kit.IMAGES["ButtonFill"]
    px = kit.stretch(fill["px"], fill["cut"], w, hh).copy()
    px[..., :3] = st.sky[round((y - PY) * K4):round((y - PY) * K4) + px.shape[0],
                         round((x - PX) * K4):round((x - PX) * K4) + px.shape[1]]
    return px


def chamber(st, x, y, w, hh, p, index, state, left=0.0, seconds="", name="Standard", chosen=False):
    """A chamber is a window on the sky, with a strip at its top for its name and a plate at its foot: the shard floats
    in the window, the words and the numbers sit on the plate. Strip and plate are solid."""
    cx, plate = x + w / 2, y + hh * SPLIT
    st.lay("ButtonShadow", x, y, w, hh)
    if state == "locked":  # a dimmer window with nothing in it yet: the void not opened. Its lock is on the plate
        st.lay("ButtonFill", x, y, w, hh, tint=GLASS,
               window=veil((0, 1.0), (HEAD, 1.0), (HEAD + 0.04, 0.13), (SPLIT - 0.06, 0.13), (SPLIT, 1.0), (1, 1.0)))
        st.lay("ButtonEdge", x, y, w, hh, tint=p["edge"], alpha=0.55)
        st.text(x + 9, y + 7, SMALL, f"Chamber {index}", p["faint"])
        lock(st, cx - 22, plate + 8.5, p["soft"], 11.0)
        st.text(cx - 13, plate + 4, 12, "Locked", p["soft"])
        st.text(cx, plate + 18, SMALL, "Upgrade the", p["faint"], "CENTER")
        st.text(cx, plate + 30, SMALL, "Breaker", p["faint"], "CENTER")
        return
    if state == "ready":  # the glow lies under the glass, so the window stays clear
        st.lay("ButtonRingGlow", x, y, w, hh, tint=p["accent"], alpha=0.8)
        rs.paste(st.px, sky_box(st, x, y, w, hh), round(x * K4), round(y * K4))
    st.lay("ButtonFill", x, y, w, hh, tint=GLASS,
           window=veil((0, 1.0), (HEAD, 1.0), (HEAD + 0.04, 0.1), (SPLIT - 0.06, 0.1), (SPLIT, 1.0), (1, 1.0)))
    if state == "ready":  # the payoff: the window blazes gold, and the plate is filled as a main action is
        accent = p["accent"]
        st.lay("ButtonFill", x, y, w, hh, tint=(h.mix(accent, h.PALE[accent], 0.3), h.mix(accent, h.DEEP[accent], 0.4)),
               window=veil((0, 0.0), (SPLIT - 0.004, 0.0), (SPLIT, 1.0), (1, 1.0)))
        st.lay("ButtonRing", x, y, w, hh, tint=accent)
        st.text(x + 9, y + 7, SMALL, f"Chamber {index}", h.PALE[accent])
        light(st, cx, y + 58, 36.0, EMBER, 0.42)  # amber at its rim: yellow thinned over the night turns olive
        light(st, cx, y + 58, 22.0, accent, 0.5)
        light(st, cx, y + 58, 13.0, h.PALE[accent], 0.7)
        st.icon("Shard", cx, y + 58, 52.0)
        st.text(cx, plate + 6, 15, "Ready", h.INK, "CENTER")
        st.text(cx, plate + 26, SMALL, "Tap to open", h.INK, "CENTER")
        return
    st.lay("ButtonEdge", x, y, w, hh, tint=p["edge"])
    if chosen:  # the room's ring, and no glow: a glow would cloud its window
        st.lay("ButtonRing", x, y, w, hh, tint=p["accent"])
    st.text(x + 9, y + 7, SMALL, f"Chamber {index}", h.PALE[p["accent"]] if chosen else p["soft"])
    light(st, cx, y + 58, 27.0, h.VOIDKIN, 0.36)
    st.icon("Shard", cx, y + 58, 50.0)
    st.text(cx, plate + 4, 11, name, p["text"], "CENTER")
    kit.bar(st, x + 10, plate + 19.5, w - 20, 6.0, left, p, POWER)
    st.text(cx, plate + 29, SMALL, seconds, h.PALE[POWER], "CENTER")


def chip(st, x, y, w, hh, p, top, under, state="rest"):
    st.lay("ButtonShadow", x, y, w, hh)
    box(st, x, y, w, hh, p, "lit" if state != "rest" else "rest")
    st.icon("Shard", x + 19, y + hh / 2, 26.0)
    st.text(x + 36, y + 10, 12, top, POWER if state == "ready" else p["text"])
    st.text(x + 36, y + 28, SMALL, under, p["soft"])


def battery(st, x, y, p):
    """The battery, where a sentence was: its mark, a charge bar, and what it holds against its cap, in Power's yellow."""
    stored, cap = BATTERY
    box(st, x - 8, y - 7, 262, 28, p)  # its own quiet plate, solid, over the sky
    st.icon("Battery", x + 11, y + 7, 22.0)
    kit.bar(st, x + 27, y + 2, 132, 10.0, stored / cap, p, POWER)
    st.text(x + 167, y + 1, 13, f"{stored} / {cap} kWh", POWER)


def chevron(st, cx, cy, colour, down=False):
    t = kit.blank(12, 12)
    pts = ((2.4, 4.0), (6.0, 7.6), (9.6, 4.0)) if down else ((4.4, 2.4), (8.0, 6.0), (4.4, 9.6))
    t.paint(np.minimum(h.seg(t, pts[0], pts[1], 1.5), h.seg(t, pts[1], pts[2], 1.5)), c(colour))
    h.place(st, t, cx - 6, cy - 6)


def rates(st, y, p):
    """Drop rates, open: each rarity's total in its colour beside its pip, its Voidkin under it in two columns, each
    with its own chance. The totals add to 100%."""
    st.text(DX + 12, y, 12, "Drop rates", p["text"])
    chevron(st, DX + DW - 18, y + 6, p["soft"], True)
    y += 17.0
    half = (DW - 24) / 2
    for rarity, total, who in RATES:
        colour = WORD[rarity]
        pip(st, DX + 18, y + 5.5, colour)
        st.text(DX + 29, y, 12, rarity, colour)
        st.text(DX + DW - 12, y, 12, f"{total}%", colour, "RIGHT")
        t = kit.blank(DW - 24, 2)
        t.paint(np.abs(t.y - 1) - 0.4, c(colour), 0.3)
        h.place(st, t, DX + 12, y + 14.0)
        y += 17.5
        for i, name in enumerate(who):
            x, ry = DX + 29 + (i % 2) * half, y + (i // 2) * 14.5
            st.text(x, ry, SMALL, name, p["text"])
            st.text(x + half - 25, ry, SMALL, f"{total / len(who):g}%", p["soft"], "RIGHT")
        y += ((len(who) + 1) // 2) * 14.5 + 0.5


def night(st, sky):
    """The panel, its body the sky: the kit's own shadow, edge and glints, and the sky cut to the panel's shape. `sky`:
    the sky's picture at the kit's size, or one flat colour (the motion test's two grounds)."""
    fill = kit.IMAGES["PanelFill"]
    px = kit.stretch(fill["px"], fill["cut"], PW, PH).copy()
    px[..., :3] = sky if isinstance(sky, np.ndarray) else c(sky)
    st.sky = px[..., :3].copy()
    st.lay("PanelShadow", PX, PY, PW, PH)
    rs.paste(st.px, px, round(PX * K4), round(PY * K4))
    st.lay("PanelEdge", PX, PY, PW, PH, tint=GALAXY["edge"], alpha=0.95)
    st.lay("PanelGlint", PX, PY, PW, PH, tint=GALAXY["glint"])


def breaker(p, world, state, sky):
    """The Breaker in Machine, as Faber built it, as a galaxy. `state`: "line", an Enriched chosen in its chamber, its
    voltage showing and its drop rates one tap away; "ready", two chambers broken, the first chosen, its drop rates
    open."""
    st = kit.Stage.__new__(kit.Stage)
    st.w, st.h, st.items = W, H, []
    st.px = world if world is not None else rs.canvas(round(W * K4), round(H * K4), tuple(c("#5B7FA6")))
    night(st, sky)
    st.text(PX + 14, PY + 11, 17, "Void Breaker", p["text"])
    battery(st, PX + 196, PY + 13, p)
    kit.button(st, PX + PW - 72, PY + 6, 60, 30, "Close", p)
    # the chambers
    st.text(PX + 14, PY + 44, 11, "Chambers", p["soft"])
    ready = state == "ready"
    cells = ((("ready", 0, "", "Standard"),) * 2 if ready else
             (("work", 0.02, "15 min left", "Enriched"), ("work", 0.35, "10 s left", "Standard"))) + (("locked", 0, "", ""),) * 2
    for i, (kind, left, seconds, name) in enumerate(cells):
        chamber(st, PX + 14 + i * 103, PY + 60, 96, 144, p, i + 1, kind, left, seconds, name, not ready and i == 0)
    # what's ready, waiting and in the bag
    st.text(PX + 14, PY + 214, 11, "Ready, waiting and in the bag", p["soft"])
    row = ((("Ready", "Standard", "ready"), ("Ready", "Standard", "ready")) if ready else
           (("Standard", "Waiting, 1st", "rest"), ("Standard", "Waiting, 2nd", "rest"))) + (("Standard", "In the bag · 72", "rest"),)
    for i, (top, under, kind) in enumerate(row):
        chip(st, PX + 14 + i * 137, PY + 232, 131, 50, p, top, under, kind)
    # the chosen shard: its own panel, a step lighter than the screen's
    kit.panel(st, DX, DY, DW, DH, p)
    st.text(DX + 12, DY + 10, 13, "Lantern Row shard · Standard" if ready else "Drum Court shard · Enriched", p["text"])
    if ready:  # its chamber says Ready; here, the one filled action, then everything it can give
        h.main_button(st, DX + 12, DY + 30, DW - 24, 44, "Open", p)
        rates(st, DY + 83, p)
    else:
        st.text(DX + 12, DY + 28, SMALL, "Chamber 1 · 15 min left", p["soft"])
        stored = BATTERY[0]
        for i, (name, price, saves, leaves) in enumerate(VOLTAGE):
            y = DY + 48 + i * 54
            if price <= stored:  # the one the battery can pay is the screen's main action
                filled(st, DX + 12, y, 118, 44, p)
                ink = h.INK
            else:
                kit.button(st, DX + 12, y, 118, 44, "", p, "disabled")
                ink = p["faint"]
            st.text(DX + 71, y + 8, 13, name, ink, "CENTER")
            st.text(DX + 71, y + 24, SMALL, f"{price} kWh", ink, "CENTER")
            if price <= stored:  # what it buys: time, in Power's light
                st.text(DX + 142, y + 7, 14, saves, h.PALE[POWER])
                st.text(DX + 142, y + 26, SMALL, leaves, p["soft"])
            else:  # what it would buy, and the refusal: how many kWh short (research, 2026-11-15)
                st.text(DX + 142, y + 7, 13, saves, p["soft"])
                st.text(DX + 142, y + 25, 12, f"{price - stored} kWh short", POWER)
        kit.button(st, DX + 12, DY + 166, DW - 24, 44, "Drop rates", p)  # one tap away (docs/ui.md, screen 3)
        chevron(st, DX + DW - 28, DY + 188, p["soft"])
    return h.bytes8(h.halve(st.px)), st.items


def words_strip(p):
    """Each coloured word this room may hold, on the room's own plates, to judge them side by side."""
    st = kit.Stage(W, 44.0, h.GROUND)
    kit.panel(st, 0, 2, W, 40, p)
    box(st, 470, 8, 332, 28, p)
    for i, (rarity, colour) in enumerate(WORD.items()):
        x = 14 + i * 76 + (12 if i > 1 else 0)
        pip(st, x + 5, 22, colour)
        st.text(x + 15, 16, 12, rarity, colour)
    st.icon("Battery", 490, 22, 20.0)
    st.text(504, 16, 12, f"{BATTERY[0]} / {BATTERY[1]} kWh", POWER)
    st.text(600, 16, 12, f"{VOLTAGE[1][1] - BATTERY[0]} kWh short", POWER)
    st.icon("CoinMint", 706, 22, 18.0)
    st.text(718, 16, 12, "1,250", h.CREDITS)
    pip(st, 768, 22, WORD["Legendary"])
    st.text(776, 16, 12, "0.1%", WORD["Legendary"])
    return h.bytes8(h.halve(st.px)), st.items


NOTES = (
    "The director, 2026-11-15: \"the void breaker should be a galaxy like Ui but well well composed mature and beautifull "
    "and even animated if possible\", then \"not a literal galaxy form just paletee of colors and stars\"; and before them, "
    "more colour for each all-dark screen, the Epic chance in purple, the battery's text reworked in energy colours. The "
    "layout is Faber's Machine, unchanged.",
    "The panel is a window on the void: a galaxy's colours and its stars, and no galaxy's shape. One river of colour runs "
    "through the chambers' row, so the four windows hold rose, violet, blue and teal of one sky, and a knot of stars in "
    "the third is where the eye rests. A chamber is a window with a plate at its foot: the shard floats in the window, in the void's lavender. A locked "
    "chamber is a dimmer window. Every number and every odd sits on a solid plate; nothing moves behind a word.",
    "The lights are Power's yellow, the one warm colour in a cool sky: the battery's charge, the voltage the battery can "
    "pay (the screen's one filled action), a chamber that's ready. Words wear their meaning's colour: a rarity's name and "
    "total in its colour beside a pip of it; kWh and time saved in Power's yellow.",
    "The battery: a charge bar in kWh on its own plate, with the battery's mark (on the HUD the bolt already means "
    "generation in kW; the battery's mark means the store). Voltage (the director, 2026-11-15, \"Faster break\") buys time, "
    "never luck: Low halves the time left, High breaks the shard now. A button holds its name over its price in kWh, and "
    "what it saves stands beside it. One the battery can't pay says how many kWh short. A Standard is offered none (it "
    "would save under a minute), and Lantern Row has only Standards, so the chosen shard is a Drum Court Enriched, "
    "15 min left. Numbers: research's seeds (the battery 60 kWh; that Enriched's Low 4 and High 8); 6 stored is a sample.",
    "Drop rates (the director, 2026-11-15: \"drop rate is that simple\") are one tap away, and on the second sheet they're "
    "open: every Voidkin the shard can give, under each rarity's total, to 100%.",
    "In motion (the test: vivid3_breaker_motion.mp4): a thin mist of the river's colours drifts along the chambers' row, "
    "about 38 s to cross a window; six large stars breathe, each on its own clock; a working shard's light breathes; now and then a falling star crosses a window. "
    "Nothing else moves, and with reduced motion on it's this still. Darker and stiller than the reveal it leads to.",
    "Stand-ins: Blender's face for the game's text; the Legendary 0.1% on the strip; a rarity's total shared evenly among "
    "its Voidkin (15% for each of four Commons). Today's still predates the names and voltage as time.",
)


def sheet(out, name, title, labels, before, after, notes, strip=None):
    ui.K = 2
    m, gap = 20.0, 16.0
    lines = [line for note in notes for line in textwrap.wrap(note, 300)]
    extra = 62.0 if strip else 0.0
    sh = ui.Sheet(2 * m + 2 * W + gap, 62 + H + 14 + extra + len(lines) * 15 + 14, h.GROUND)
    t = sh.tile(0, 0, sh.w, sh.h)
    t.text(m, 14, 17, title, h.HEAD)
    for i, label in enumerate(labels):
        t.text(m + i * (W + gap), 44, 11, label, h.HEAD)
    kit.put(sh, before, m * 2, 62 * 2)
    h.add(sh, *after, m + W + gap, 62)
    y = 62 + H + 14
    if strip:
        t.text(m, y, 10, "The coloured words this room may hold, on its plates:", h.NOTE)
        h.add(sh, *strip, m, y + 14)
        y += extra
    for i, line in enumerate(lines):
        t.text(m, y + i * 15, 10, line, h.NOTE)
    kit.finish(sh, out / name)


def slices():
    ui.K = K4
    kit.panels()
    kit.buttons()
    kit.bars()
    kit.icons()
    h.icons()


def world(state):
    """The game's own world behind the screen: Faber's still, at the sheet's size and at the kit's."""
    still = rs.load(STILLS / f"breaker_{state}.png")
    small = h.bytes8(h.resize(still, round(W * 2), round(H * 2)))
    big = np.ascontiguousarray(h.resize(still, round(W * K4), round(H * K4)))
    big[..., 3] = 1.0
    return small, big


def motion(out):
    """The screen with its words over a black sky and over a white one, at 2 pixels a point: the motion test works
    out from the pair what covers the sky and by how much (void_breaker_motion.py)."""
    slices()
    for name, flat in (("black", "#000000"), ("white", "#FFFFFF")):
        ui.K = K4
        shot = breaker(GALAXY, world("line")[1], "line", flat)
        ui.K = 2
        sh = ui.Sheet(W, H, "#000000")
        h.add(sh, *shot, 0, 0)
        for layer in ui.text_layers(sh.px.shape[1], sh.px.shape[0], sh.items).values():
            rs.paste(sh.px, layer, 0, 0)
        np.save(out / f"screen_{name}.npy", h.bytes8(sh.px)[..., :3])
        h.stage(f"the screen over {name}")


def main():
    out = bl.out_dir()
    if (sys.argv[sys.argv.index("--") + 2:] or ["sheet"])[0] == "motion":
        return motion(out)
    h.stage("started")
    slices()
    p = GALAXY
    sky = vs.sky(K4)
    h.stage("the sky")
    shots, befores = {}, {}
    for state in ("line", "ready"):
        befores[state], big = world(state)
        shots[state] = breaker(p, big, state, sky)
        del big
        h.stage(f"the Breaker, {state}")
    del sky
    strip = words_strip(p)
    kit.IMAGES.clear()
    labels = ("Today: Faber's take of the build (TR9, Machine), all in Graphite", "Galaxy: the same screen, a window on the void")
    sheet(out, "vivid3_breaker.png", "Grow your Anime: the Breaker, today and as a galaxy. An Enriched in its chamber, and its voltage",
          labels, h.floats(befores["line"]), shots["line"], NOTES, strip)
    h.stage("the Breaker's sheet")
    sheet(out, "vivid3_breaker_ready.png", "Grow your Anime: the Breaker, today and as a galaxy. Two shards broken, the first one's drop rates",
          labels, h.floats(befores["ready"]), shots["ready"],
          ("A ready chamber: its window blazes gold round the shard and its plate is filled in Power's yellow with ink words. "
           "Open is the screen's one filled button; the ready shards in the line wear the room's ring.",
           "Drop rates, open (the director, 2026-11-15: \"drop rate is that simple\", and \"it obviously dont contain everything "
           "the odd are off\"): each rarity's total in its colour beside its pip, its Voidkin under it, each with its own "
           "chance. A Lantern Row Standard: Common 60, Uncommon 30, Rare 9, Epic 1, to 100% (research's seeds, the roster's "
           "eight for the ground; an even share inside a rarity is assumed). A longer list scrolls inside this panel."))
    h.stage("the ready sheet")


if __name__ == "__main__":
    main()
