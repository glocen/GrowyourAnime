"""AR17: the Strip's own pieces (docs/asset-requests.md, AR17). The Strip is the street between the bases, and it
is the void's, not the festival's (the director, 2026-11-16: ground lanterns are Lantern Row's alone). The void has
cracked its stones: a crack of the void's light runs down the street's middle from each sealed end to the crossing and
out to every base's gate, a great shard split in three hangs over the crossing with the light inside it, the lamps
are shards hung in rings of void stone, and shards break out of the ground where nobody has built.

Every piece wears the base kit's own pair of pictures (Base_Kit_Color, Base_Kit_Glow), so nothing new is drawn or
uploaded but the meshes. Made as the base's kit is (base_kit.py): a piece's front faces +Y, its origin is on the
floor, one unit is one stud.

Run (no GPU turn): blender.exe -b --factory-startup --python tools/blender/strip_kit.py -- <out>
  <out> is the handoff folder: meshes and manifest.json
"""

import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_kit as base  # noqa: E402
import base_machines as machines  # noqa: E402

bl, ink, kit, rs = base.bl, base.ink, base.kit, base.rs
Mesh, Piece = base.Mesh, base.Piece
horn, vein, shard = machines.horn, machines.vein, machines.shard

STRIP = 48.0                       # the street's width (Config.World)
SEAL = (10.0, 38.0)                # a sealed gate's closed way: its half width, and its point's height
TILE, BRANCH, HEART = 30.0, 21.0, 9.0   # a crack's tile along the street, a branch to a gate, and the crossing's ring where they end
LAMP = (2.0, 7.7)                  # a post's shard: out from the stone toward +X, and up
SHARDS = {"FarShardLow": (80.0, 16.0), "FarShardMid": (125.0, 22.0), "FarShardTall": (180.0, 30.0)}   # high, wide
# A crack's line: (across, along) points, its half width at each, and its side cracks. A tile's two ends are alike.
WIDE = ([(0, -15), (0.6, -11), (-0.8, -6.5), (0.3, -2), (1.1, 2.5), (-0.5, 7), (0.6, 11.5), (0, 15)], [0.3, 0.5, 0.95, 0.7, 1.1, 0.75, 0.5, 0.3],
        [([(-0.8, -6.5), (-2.9, -4.4), (-3.9, -1.6)], [0.4, 0.24, 0.0]), ([(1.1, 2.5), (3.2, 4.6), (3.5, 7.6), (5.0, 9.2)], [0.45, 0.3, 0.16, 0.0])])
THIN = ([(0, -15), (-0.4, -9), (0.5, -3), (-0.3, 4), (0.4, 10), (0, 15)], [0.3, 0.3, 0.42, 0.3, 0.36, 0.3],
        [([(0.5, -3), (2.0, -1.0), (2.5, 1.4)], [0.2, 0.1, 0.0])])
TWIG = ([(0, -10.5), (0.4, -6), (-0.5, -1), (0.3, 4), (0, 10.5)], [0.18, 0.18, 0.14, 0.1, 0.04], [])
# The crack's rank (research's fix 1, 2026-11-16, 14:09): the main line brightest and widest toward the crossing, the
# branches to the gates thinner and dimmer, so one way reads at once. Where each samples the void's swatch, which is lit
# evenly and runs from near white at its head (1) to deep violet at its foot (0): about 2.7 to 1 in light.
RANK = {"VeinWide": 1.0, "VeinThin": 0.7, "VeinBranch": 0.0}
# Research's fix 3 (2026-11-16, 14:09): from a far gate the great shard was lost in the dusk's haze, so its light is
# brighter, not the shard bigger: its glow strength over the kit's, here and in its manifest entry. Only its light
# brightens; the stone's mask is 0.
BRIGHT = {"CrossingShard": 2.5,
          # AR38, the Void Shop (research's pick C, 2026-11-17, 21:41): the clock's light under the counter's own, the
          # crown's over everything near, so a rare offer reads from far down the Strip
          "VoidShopMinute": 0.8, "VoidShopCrown": 2.2}
# AR38: the Shop's own frame. Its origin is its place in WorldService, 4 studs into its lot from the Strip's edge, and
# its front (+Y) looks at the Strip; SHOP_IN is that 4. The clock's five minutes hang from the slab's front edge on
# its east half (+X here is the world's +X, east, once it faces the Strip: on the left from the counter), the first
# minute the farthest out, clear of the crossing shard's cover and of the way in: each minute's across. A minute is a
# tooth: a blade of void stone (BLADE, its half width) with a crack of the void's light down its middle, as the Strip's
# light lives in its cracks, so at the counter the light stays under the counter's own (research's note, 21:41; in
# grey, whole lit blades filled the view's top left). A spent minute's tooth is gone, so from far off, where the haze
# drowns a thin crack, the clock still reads as a count of dark teeth against the sky. MINUTE is the crack: (its
# length, its half width); MINUTE_ALONG the tooth's root, its blade's middle; CRACK_OUT how far proud the crack stands.
SHOP_IN, SLAB_Z, SLAB_FRONT = 4.0, 12.2, -5.6
SLAB_ENDS = (18.8, -15.8)          # where the slab's full depth ends each side; its points run 2.4 past
MINUTES = (17.0, 14.0, 11.0, 8.0, 5.0)
MINUTE, BLADE, MINUTE_SW = (5.6, 0.6), 1.2, "void"
MINUTE_ALONG = SLAB_FRONT - 0.3
# The brow behind the teeth: (across, half height) along it, a point at each end.
BROW = ((19.6, 0.5), (18.3, 3.1), (15.5, 3.4), (12.5, 3.0), (9.5, 3.4), (6.5, 3.1), (3.6, 2.6), (2.4, 0.5))
# AR20's C (research's pick, 2026-11-16, 17:23): the Strip's stones, Lantern Row's paving times STONES in light, and an
# empty lot's floor, the base's deck under LOT_TINT, lifted from #3A3C52 so the lots beside the crossing aren't black.
STONES, LOT_TINT = 1.35, "#6E7290"
ROW_PAVING = Path(__file__).resolve().parents[2] / "build" / "handoff" / "LanternRow" / "maps" / "LanternRow_Paving_Color.png"
PAVING_NAME = "Strip_Paving_Color.png"
# The crossing's shard: its three parts round the light, each (the way it stands out in degrees, its foot, its tip).
THREE = ((90.0, 8.5, 46.0), (210.0, 11.5, 40.0), (330.0, 10.0, 35.0))
# A place where shards break out of the ground: (across, along, high, half width, the way it leans in degrees, how far).
OUTCROP = ((0.0, 0.0, 7.6, 1.5, 20, 0.2), (-2.0, 1.0, 4.3, 1.0, 160, 0.38), (1.8, -0.8, 5.2, 1.1, 320, 0.4),
           (0.5, 2.1, 2.7, 0.7, 80, 0.15), (-1.1, -1.8, 3.1, 0.8, 230, 0.3))


def crack(m, points, widths, sw="void", lift=0.07, bright=0.5):
    """A crack of the void's light, flat in the stones, on a bed of dark a little wider: a line through `points`
    (across, along), `widths` its half width at each, `bright` where it samples its swatch (1 its head, the brightest)."""
    pts = [Vector((x, y, 0.0)) for x, y in points]
    last = len(pts) - 1

    def edge(k, half, z):
        along = (pts[min(k + 1, last)] - pts[max(k - 1, 0)]).normalized()
        n = Vector((-along.y, along.x, 0.0))
        return pts[k] - n * half + Vector((0, 0, z)), pts[k] + n * half + Vector((0, 0, z))

    for tone, grow, z in ((kit.sw_uv("dark", 0.5, 0.6), 1.0, lift - 0.03), (kit.sw_uv(sw, 0.0, bright), 0.0, lift)):
        for k in range(last):
            r0, l0 = edge(k, widths[k] * (1 + grow) + 0.08 * grow, z)
            r1, l1 = edge(k + 1, widths[k + 1] * (1 + grow) + 0.08 * grow, z)
            m.face([r0, r1, l1, l0], [tone] * 4)


def cracked(name, line, long, note):
    def make():
        m = Mesh(None)
        points, widths, sides = line
        crack(m, points, widths, bright=RANK[name])
        for side, thin in sides:
            crack(m, side, thin, lift=0.075, bright=RANK[name])
        return Piece(name, m, note=f"a crack of the void's light, flat in the stones, {long:g} long from its back to its "
                                   f"front. {note} It glows without a Light. No shadow. Look only: it lies 0.07 over the floor")
    return make


def facing(m, at, r0, r1, thick, sides, sw):
    """A ring stood up to face +Y and -Y, its middle at `at`: a band from `r0` out to `r1`, `thick` through."""
    turned = Mesh(None)
    turned.lathe([(r0, 0.0), (r0, thick), (r1, thick), (r1, 0.0), (r0, 0.0)], (0, 0, 0), sides, sw, caps=False)
    x, y, z = at
    for face, uv in zip(turned.f, turned.uv):
        m.face([(x + turned.v[i][0], y + turned.v[i][2] - thick / 2, z + turned.v[i][1]) for i in face][::-1], uv[::-1])


def strip_post():
    """The Strip's lamp: a slender standing stone of void stone on a steel foot, a vein of the void's light on the
    edge that looks at the street, and a shard of that light hung in a ring of void stone from a peg toward +X."""
    m = Mesh()
    out, up = LAMP
    m.box((1.7, 1.7, 0.4), (0, 0, 0.2), "girder", ink=True)
    stone, widths = [(0, 0, 0.4), (-0.3, 0, 5.4), (0.1, 0, 10.2)], [0.62, 0.52, 0.16]
    horn(m, stone, widths, "abyss", deep=0.9)
    vein(m, stone[:2], widths[:2], (6.0, 0, 3.0), r=0.04)
    horn(m, [(-0.1, 0, 8.7), (out + 0.3, 0, 9.35)], [0.2, 0.12], "abyss", ink=False)
    m.box((0.07, 0.07, 0.56), (out, 0, up + 1.24), "rubber")
    facing(m, (out, 0, up), 0.78, 1.0, 0.16, 8, "abyss")
    shard(m, (out, 0, up + 0.05), 0.36, 1.5, "void")
    return Piece("StripPost", m, lights=[("Lamp", (out, 0.0, up), "#C9B0FF")], solid="the foot, 1.7 square, and the stone",
                 note=f"10.2 high. Its shard hangs in its ring {out:g} out toward +X and {up:g} up: turn the post so +X "
                      "looks at the street's middle. A PointLight at Lamp only where the plan lights one; the shard glows "
                      "anyway")


def seal(name, light, where):
    """A sealed gate across the Strip's end, in the Festival Door's language at three times its size: two standing
    stones of void stone with the arch floating over them and a shard of the way's own light over the keystone. The
    way between them is shut: two dark leaves in a pointed arch, a line of light leaking down their seam and round
    their edge, and a ring of void stone locking them at the middle with a bar out to each side. A fang of void stone
    stands in the gap at each side, so the street ends in stone from wall to wall."""
    m = Mesh()
    half, point = SEAL
    m.box((42.0, 5.0, 0.6), (0, 0, 0.3), "girder", ink=True)
    m.box((42.2, 5.2, 0.12), (0, 0, 0.3), light)
    for sx in (-1, 1):
        stone, widths = [(sx * 13.4, 0, 0.6), (sx * 14.8, 0, 16.0), (sx * 13.6, 0, 30.5)], [3.2, 2.9, 1.9]
        horn(m, stone, widths, "abyss", deep=0.9)
        vein(m, stone, widths, (0, 0, 16.0), sw=light, r=0.2)
        horn(m, [(sx * 11.4, 0, 34.0), (sx * 7.2, 0, 39.0)], [1.6, 1.3], "abyss", deep=0.8)        # the arch, floating
        horn(m, [(sx * 5.7, 0, 40.3), (sx * 2.5, 0, 42.1)], [1.1, 0.85], "abyss", deep=0.8)
        horn(m, [(sx * 21.2, 0, 0.0), (sx * 21.8, 0, 7.0), (sx * 21.0, 0, 14.5)], [2.9, 2.4, 0.3], "abyss", deep=0.9)   # the fang
        horn(m, [(sx * 9.4, 1.0, 17.0), (sx * 4.3, 1.0, 17.0)], [0.45, 0.7], "abyss", deep=0.7)    # the bar
    edge = [(half, 0.6), (half, 25.0), (half - 2.3, 31.0), (half - 6.0, 35.6), (0.0, point)]
    dark = kit.sw_uv("dark", 0.5, 0.6)
    for (x0, z0), (x1, z1) in zip(edge, edge[1:]):
        for sx in (-1, 1):
            pts = [(0, 0.4, z0), (sx * x0, 0.4, z0), (sx * x1, 0.4, z1)] + ([(0, 0.4, z1)] if x1 else [])
            for face in (pts, pts[::-1]):                              # the leaves, seen from both sides
                m.face(face if sx > 0 else face[::-1], [dark] * len(face))
    m.tube([(0, 0.62, 0.7), (0, 0.62, 12.6)], 0.09, light)                                        # the seam, under the lock
    m.tube([(0, 0.62, 21.4), (0, 0.62, point - 0.4)], 0.09, light)                                # and over it
    for sx in (-1, 1):
        m.tube([(sx * (x - 0.25), 0.62, z) for x, z in edge[1:]], 0.07, light)                    # light round the arch's edge
    facing(m, (0, 1.0, 17.0), 3.3, 4.4, 0.9, 10, "abyss")
    m.flat([Vector((0, 1.0, 17.0)) + Vector((3.3 * math.cos(math.tau * i / 10), 0.0, 3.3 * math.sin(math.tau * i / 10)))
            for i in range(10)], "dark")
    horn(m, [(0, 1.3, 15.2), (0, 1.3, 17.0), (0, 1.3, 18.8)], [0.04, 0.8, 0.04], light, ink=False)   # the lock's own shard
    shard(m, (0, 0, 46.0), 1.7, 7.0, light)
    return Piece(name, m, lights=[("Shard", (0.0, 0.0, 46.0), {"void": "#B58CFF", "cyan": "#7CE8FF"}[light])],
                 solid=f"a wall across the whole street: {STRIP:g} wide, 5 deep, as high as it needs",
                 note=f"stands across the Strip's end toward {where}, its front (+Y) looking back down the street. 49.5 "
                      f"high at its shard, the two stones 30.5, the shut way {half * 2:g} wide and {point:g} to its point. "
                      "Shut and dim: only the seam, the arch's edge, the lock's shard and the shard over the keystone "
                      "glow. One PointLight at Shard if the phone's count allows. It opens in its own phase")


def crossing_mark():
    """The crossing's mark, laid in the stones: a ring round the place where the side street meets the Strip, and at
    its heart a well of full black ringed in the void's light, with nothing in it (research's fix 2: it's the second
    strongest shape). The street's cracks end at that ring; the great shard hangs over it."""
    m = Mesh(None)
    z, sides = 0.06, 40
    tone, lit, dark = kit.sw_uv("bone", 0.3, 0.7), kit.sw_uv("void", 0.0, 1.0), kit.sw_uv("ink", 1.0, 0.0)
    m.face([(8.7 * math.cos(math.tau * i / sides), 8.7 * math.sin(math.tau * i / sides), 0.04) for i in range(sides)], [dark] * sides)
    for r0, r1, uv in ((19.0, 19.9, tone), (8.6, HEART + 0.2, lit)):
        for i in range(sides):
            a, b = math.tau * i / sides, math.tau * (i + 1) / sides
            m.face([(r0 * math.cos(a), r0 * math.sin(a), z), (r1 * math.cos(a), r1 * math.sin(a), z),
                    (r1 * math.cos(b), r1 * math.sin(b), z), (r0 * math.cos(b), r0 * math.sin(b), z)], [uv] * 4)
    return Piece("CrossingMark", m, note="lies 0.06 over the stones at the crossing's middle, 39.8 across: a ring, and a well "
                                         f"of full black ringed in the void's light {HEART:g} out, where the street's cracks end, "
                                         "with nothing in it. The inner ring glows. No shadow. Look only")


def crossing_shard():
    """The crossing's own: a great shard of void stone split in three, hanging over the crossing's well with the
    void's light inside it and leaking out between its parts, and four small shards of that light adrift round it.
    It reads from every way into the crossing, and its light carries down the street."""
    m = Mesh()
    for turn, foot, tip in THREE:
        a = math.radians(turn)
        out, flat = Vector((math.cos(a), math.sin(a), 0.0)), (-math.sin(a), math.cos(a), 0.0)
        mid = foot + (tip - foot) * 0.42
        stone, widths = [out * 1.5 + Vector((0, 0, foot)), out * 5.0 + Vector((0, 0, mid)), out * 1.3 + Vector((0, 0, tip))], [0.3, 3.3, 0.3]
        horn(m, stone, widths, "abyss", flat=flat, deep=0.82)
        vein(m, stone, widths, (0, 0, mid), r=0.16)
    shard(m, (0, 0, 24.0), 1.7, 30.0, "void", lean=0.55)
    for turn, far, high, r, long in ((40, 9.5, 15.0, 0.6, 4.0), (135, 11.0, 30.0, 0.5, 3.4), (250, 8.5, 21.0, 0.75, 5.0), (300, 12.0, 37.0, 0.45, 3.0)):
        a = math.radians(turn)
        shard(m, (far * math.cos(a), far * math.sin(a), high), r, long, "void")
    return Piece("CrossingShard", m, lights=[("Heart", (0.0, 0.0, 24.0), "#B58CFF")],
                 solid="none: it hangs 8.5 over the floor, and players walk under it",
                 note="hangs over the crossing's mark, from 8.5 to 46 over the floor, about 17 across. Its three parts are "
                      "void stone; the light inside them and the four small shards glow. One PointLight at Heart. It may "
                      "turn slowly and rise and fall a little, the builder's call. A place for the Void Rift to open, if "
                      "research wants one: the piece asks for nothing")


def outcrop():
    """Shards breaking out of the ground where nobody has built: five of void stone leaning apart, and one of the
    void's light among them."""
    m = Mesh()
    for x, y, high, wide, turn, lean in OUTCROP:
        a = math.radians(turn)
        way, flat = Vector((math.cos(a), math.sin(a), 0.0)), (-math.sin(a), math.cos(a), 0.0)
        foot = Vector((x, y, -0.6))
        horn(m, [foot, foot + way * (lean * high * 0.4) + Vector((0, 0, high * 0.45)), foot + way * (lean * high) + Vector((0, 0, high + 0.6))],
             [wide * 0.8, wide, 0.05], "outcrop", flat=flat, deep=0.8)
    horn(m, [(1.0, 1.0, -0.3), (1.2, 1.1, 1.3), (1.7, 1.3, 3.6)], [0.36, 0.46, 0.04], "void", flat=(0.6, -0.8, 0.0), ink=False)
    return Piece("ShardOutcrop", m, solid="the tallest shard, as a post 2 square, if anything",
                 note="shards breaking out of the ground, 7.6 high and about 6 across: five of void stone, a lighter "
                      "violet than the near pieces' so none stands black against the day sky (AR20), and one of the void's "
                      "light, which glows without a Light. Turned as the plan says, no two look alike")


def far_shard(name):
    high, wide = SHARDS[name]

    def make():
        m = Mesh(None)
        horn(m, [(0, 0, -30.0), (wide * 0.1, 0, high * 0.3), (wide * 0.22, 0, high)], [wide * 0.36, wide * 0.5, 0.3], "far",
             deep=0.8, ink=False)
        return Piece(name, m, note=f"a great shard of void stone, {high:g} high and {wide:g} wide, far past "
                                   "the map's edge: unlit, in a pale void stone painted for the distance, since no haze pales it "
                                   "now (AR20). It leans a little toward +X, and its foot "
                                   "goes 30 under the floor, for where the ground has ended. "
                                   "No hull, no shadow, nobody reaches it")
    return make


def shop():
    """AR38, the Void Shop, the Hanging Stock (research's pick, 2026-11-17, 21:41): a great slab of void stone hanging
    over a counter with nothing holding it up, its front edge a blade's. Under it the counter, three standing stones at
    its back and the shelf between them, where the stock's six lines stand as six small shards of light: the counter's
    own light, the brightest thing near it. The clock's five minutes hang from the slab's front edge on its east half,
    each a tooth of its own (VoidShopMinute), and the crown, the slab's lit rim, is another piece (VoidShopCrown)."""
    m = Mesh()
    mid = SLAB_FRONT - 8.4
    horn(m, [(SLAB_ENDS[0] + 2.4, mid, SLAB_Z), (SLAB_ENDS[0], mid, SLAB_Z), (SLAB_ENDS[1], mid, SLAB_Z),
             (SLAB_ENDS[1] - 2.4, mid, SLAB_Z)], [0.6, 8.4, 8.4, 0.6], "abyss", flat=(0.0, 0.0, 1.0), deep=0.155)
    # The clock's brow: a blade of void stone hanging from the slab's front edge behind the five teeth, its lower edge
    # broken. It is the clock's dark ground: a lit tooth reads against stone, not against the haze, from any distance
    # (research's must-fix, 22:02: in the first pass the sky stood behind the teeth, pale on pale at 160 studs).
    behind = MINUTE_ALONG - 1.0
    horn(m, [(x, behind, SLAB_Z + 0.2 - r) for x, r in BROW], [r for _, r in BROW], "abyss", flat=(0.0, 1.0, 0.0), deep=0.12)
    m.box((16.0, 2.4, 3.2), (0.0, -10.5, 1.6), "abyss", ink=True)                         # the counter
    m.box((16.4, 2.8, 0.25), (0.0, -10.5, 3.32), "girder")
    m.box((16.2, 0.2, 0.2), (0.0, -9.1, 3.3), "lamp")             # its edge toward the player: the counter's own light
    for x, turn, high in ((10.0, -14.0, 7.6), (0.0, 0.0, 8.6), (-10.0, 14.0, 7.6)):         # the stones at its back
        a = math.radians(turn)
        flat = (math.sin(a), math.cos(a), 0.0)
        horn(m, [(x, -18.5, 0.0), (x, -18.5, high * 0.55), (x, -18.5, high)], [4.2, 4.6, 0.4], "abyss", flat=flat, deep=0.22)
    m.box((23.0, 1.6, 0.4), (0.0, -16.9, 3.2), "girder", ink=True)                          # the shelf
    for k in range(6):                                                                     # the stock's six lines
        shard(m, (-8.75 + 3.5 * k, -16.9, 4.6), 0.42, 1.7, "lamp")
    return Piece("VoidShop", m, lights=[("Counter", (0.0, -14.0, 7.0), "#F6FCFF")],
                 solid="the counter, 16 by 2.4 by 3.2, and the three stones at its back; the slab hangs out of reach",
                 note=f"stands at the Shop's place in WorldService ({SHOP_IN:g} into its lot from the Strip's edge), its "
                      f"front (+Y) looking at the Strip. The slab hangs from {SLAB_Z - 1.3:.1f} to {SLAB_Z + 1.3:.1f}, "
                      f"{SLAB_ENDS[0] - SLAB_ENDS[1] + 4.8:g} across and 16.8 deep, its front edge a blade's. Only the "
                      "counter's edge and the shelf's six shards glow: the counter's own light, over the clock's. One "
                      "PointLight at Counter, white. The clock's light and the crown are "
                      "their own pieces, VoidShopMinute (five) and VoidShopCrown")


def shop_minute():
    """One minute of the Shop's clock: a tooth hanging point down from its root in the slab, a blade of void stone with
    a crack of the void's light down its front. Stood five times along the slab's front edge (MINUTES). A minute to run
    shows; a spent one is gone; the running one is shortened from its root by the share still to run."""
    m = Mesh()
    long, wide = MINUTE
    horn(m, [(0.0, 0.0, 0.0), (0.0, 0.0, -2.6), (0.0, 0.0, -long - 0.5)], [BLADE * 0.75, BLADE, 0.05], "abyss",
         flat=(0.0, 1.0, 0.0), deep=0.35)
    out = BLADE * 0.35 + 0.1 - wide * 0.25       # the light's front ridge 0.1 proud of the blade's, its sides clear of it
    horn(m, [(0.0, out, -0.2), (0.0, out, -2.6), (0.0, out, -long - 0.2)], [wide * 0.75, wide, 0.04],
         MINUTE_SW, flat=(0.0, 1.0, 0.0), deep=0.25, ink=False)
    return Piece("VoidShopMinute", m,
                 note=f"its origin is its root, in the slab's underside, and it hangs {long + 0.5:g} down from it. Five "
                      f"stand on the VoidShop's own turn, at its frame's across {', '.join(f'{x:g}' for x in MINUTES)}, "
                      f"along {MINUTE_ALONG:g}, up {SLAB_Z:g}: the first minute at 17. A minute still to run shows; a "
                      "spent one is hidden. The running one shows the share of its minute left: its height (the "
                      "MeshPart's Y) times that share, its root kept where it is. The crack glows under the counter's "
                      "light (research, 21:41). No collision")


def shop_crown():
    """The Shop's crown: a line of the void's light round the slab's edge, lit only while a rare offer is in."""
    m = Mesh(None)
    mid, r, z = SLAB_FRONT - 8.4, 8.4 + 0.12, SLAB_Z
    east, west = SLAB_ENDS[0] + 2.7, SLAB_ENDS[1] - 2.7
    ring = [(east, mid), (SLAB_ENDS[0], mid + r), (SLAB_ENDS[1], mid + r), (west, mid), (SLAB_ENDS[1], mid - r),
            (SLAB_ENDS[0], mid - r), (east, mid)]
    m.tube([(x, y, z) for x, y in ring], 0.24, "void")
    return Piece("VoidShopCrown", m, lights=[("Crown", (2.0, mid, SLAB_Z + 3.0), "#B58CFF")],
                 note="stands on the VoidShop's own place and turn, round its slab's edge. Shown only while a rare offer "
                      "is in, for its five minutes; hidden otherwise. Its glow is the brightest of the Shop's, so a lit "
                      "crown reads from far down the Strip and the side street. One PointLight at Crown while it's lit, "
                      "if the phone's count allows. No collision")


PIECES = {"StripPost": strip_post,
          "VeinWide": cracked("VeinWide", WIDE, TILE, "The wide one, for near the crossing: 2.2 at its widest, two side cracks."),
          "VeinThin": cracked("VeinThin", THIN, TILE, "The thin one, for far down the street: 0.8 at its widest, one side crack."),
          "VeinBranch": cracked("VeinBranch", TWIG, BRANCH, "A branch from the street's crack to a gate, thinner and dimmer "
                                                            "than the street's own: 0.36 at its widest, thinning toward its front."),
          "CrossingShard": crossing_shard, "ShardOutcrop": outcrop,
          "SealCalamity": lambda: seal("SealCalamity", "void", "the Calamity"),
          "SealClash": lambda: seal("SealClash", "cyan", "the Clash Grounds"),
          "CrossingMark": crossing_mark, **{name: far_shard(name) for name in SHARDS},
          "VoidShop": shop, "VoidShopMinute": shop_minute, "VoidShopCrown": shop_crown}


def build(name):
    base.wear()
    return PIECES[name]()


class Stock(base.Stock):
    """The base's stock, with the Strip's pieces beside it."""

    def __init__(self, maps, scene, look_kit):
        super().__init__(maps, scene, look_kit)
        self.maps = maps

    def stand(self, name, tag, at, turn):
        if name in PIECES and name not in self.made:
            piece = build(name)
            mat = self.mats[piece.maps]
            if name in BRIGHT:
                tint, strength = base.MAPS[piece.maps]
                mat = kit.kit_material(self.maps, piece.maps, "Base", (tint, strength * BRIGHT[name]))
            self.made[name] = (piece, piece.mesh.whole().to_object(name, mat))
        return super().stand(name, tag, at, turn)


def paving(out: Path):
    """The Strip's own stones: Lantern Row's paving lifted, in light, by STONES."""
    page = rs.load(ROW_PAVING)
    c = page[..., :3]
    linear = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4) * STONES
    page[..., :3] = base.kit.encode(linear)
    out.mkdir(parents=True, exist_ok=True)
    rs.save(page, out / PAVING_NAME)


def export(out: Path):
    scene = bl.reset_scene()
    paving(out / "maps")
    meshes = out / "meshes"
    meshes.mkdir(parents=True, exist_ok=True)
    listing = {}
    for name in PIECES:
        piece = build(name)
        obj = bpy.data.objects.new(name, piece.mesh.whole().to_object(name, None))
        scene.collection.objects.link(obj)
        tris = bl.export_mesh_json(obj, meshes / f"{name}.json", uv=True)
        record = json.loads((meshes / f"{name}.json").read_text())
        ps = np.array(record["p"], np.float32).reshape(-1, 3)
        tint, strength = base.MAPS[piece.maps]
        listing[name] = dict(
            mesh=f"meshes/{name}.json", triangles=tris, vertices=len(ps), centre=record["c"],
            size=[round(float(v), 3) for v in ps.max(0) - ps.min(0)],
            colour="../Base/maps/Base_Kit_Color.png", glow="../Base/maps/Base_Kit_Glow.png",
            glowTint=tint, glowStrength=round(strength * BRIGHT.get(name, 1.0), 3), collision=piece.solid,
            lights=[dict(name=n, at=[round(at[0], 3), round(at[2], 3), round(-at[1], 3)], colour=c) for n, at, c in piece.lights],
            note=piece.note)
    manifest = dict(
        what="AR17: the Strip's own pieces. Made as the base's kit is, and wearing the base kit's own pair of pictures.",
        unit="1 = 1 stud",
        frame="Roblox's: a piece's front (Blender +Y) is -Z. A MeshPart goes at the piece's place times `centre`. "
              "A light's `at` is in the piece's own frame.",
        surface="one SurfaceAppearance per MeshPart, the base kit's: ColorMap Base_Kit_Color, EmissiveMaskContent "
                "Base_Kit_Glow, EmissiveTint `glowTint`, EmissiveStrength from `glowStrength` (the base kit's own, tuned in "
                "the engine; CrossingShard's is 2.5 times the kit's before AR20's lift, so its light carries to a far "
                "gate: when Config.Lighting lifts the kit's glow for the base and the Strip, the shard keeps this "
                "strength and takes none of the lift, or it blooms into a halo at night). Single sided; the void stone's "
                "ink is in its mesh.",
        maps={f"maps/{PAVING_NAME}": f"the Strip's stones: Lantern Row's paving, {STONES:g} times its light (AR20's C), a "
                                     f"tile {base.kit.PAVING[1]:g} studs square for a Texture on the street's Part",
              "../Base/maps/Base_Deck_Color.png": f"an empty lot's floor, the base's plain deck tinted {LOT_TINT} "
                                                 "(the Texture's Color3), a tile 8 studs square"},
        shadows="CastShadow off on the three cracks, CrossingMark and the far shards.",
        pieces=listing)
    (out / "manifest.json").write_text(json.dumps(manifest, indent=1), encoding="utf-8")
    print(json.dumps({name: entry["triangles"] for name, entry in listing.items()}))


if __name__ == "__main__":
    export(bl.out_dir())
