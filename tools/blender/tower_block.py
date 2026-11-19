"""AR41: the Tower's platforms, the grey block (docs/asset-requests.md, AR41, "Three directions, planned"). A run's next
platform gathers above the pair at a win, locks with one pulse round its rim, and they leap up to it. Three directions,
each a platform and its gathering:

    A, the Shutter: eight stone wedges fly in on straight lines through the middle, from twice the radius out and 6
       below, faster as they close, each dragging a straight streak; a raised lip, the light in a dark groove.
    B, the Circuit: a head of light runs once round the rim, slow to fast, drawing the collar behind it; then the deck
       closes from the rim to the middle as a shrinking ring; the light in the dark seam between collar and deck.
    C, the Updraft: twelve straight streaks rise from the lower deck's rim and lean in, on lines through the middle, to
       the new rim; the rim forms where they arrive, the deck thickens, the keel (radius 6, 3.5 deep) last.

The beats (seconds from the win): the gathering 0 to 0.35 on an ease-in, Back's small overshoot at the lock; the pulse
0.35 to 0.6 (the rim's light flares and settles, a short upright band lifts off the rim); a stand-in leap 0.75 to
1.25 (`Config.Tower.Leap` of `Rise`), the camera following; set down to 1.5. Sizes are `Config.Tower.Platform`.

Views: `leap`, the player's camera (12.5 studs, 20 degrees down, FOV 70) behind the avatar on floor 5, turned toward
the base, from the win to the set-down on floor 6; `yard`, behind a player in the base's back yard 45 studs off,
turned up to the stack; `top`, high over the new disc looking down, for the symbol check (the content check's condition 3).
Grey: the yard at base level 2 under the place's dusk, the effect a near-white light. Rendered in Blender; nothing is
seen in Studio, nothing exported.

blender.exe -b --factory-startup --python-exit-code 1 --python tools/blender/tower_block.py -- <abs out> render leap|yard|top [A B C]
blender.exe -b --factory-startup --python-exit-code 1 --python tools/blender/tower_block.py -- <abs out> sheet
blender.exe -b --factory-startup --python-exit-code 1 --python tools/blender/tower_block.py -- <abs out> movie leap|yard
"""

import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

RADIUS, HEIGHT, THICK = 14.0, 12.0, 1.0          # Config.Tower.Platform
STAND = 0.55                                     # Config.Tower.Stand: the avatar this share of the radius behind
LEAP = (0.75, 1.25)                              # the stand-in leap, seconds from the win; Rise 2.5 x Leap 0.5 = 1.25
GATHER, PULSE = 0.35, 0.6                        # the lock, and the pulse's end
FLOOR = 5                                        # the floor stood on; the new disc is FLOOR + 1
RATE = 30
SPANS = {"leap": (-0.1, 1.5), "yard": (-0.1, 0.8), "top": (-0.1, 0.7)}
DIRECTIONS = ("A", "B", "C")
NAMES = {"A": "the Shutter", "B": "the Circuit", "C": "the Updraft"}
GREY = "#F2EEFA"                                 # the light: near white, a breath of the void's violet
STONE, DECK, BED = ("#A9ABB3", "#8C8E96"), "#9C9EA6", "#2A2C33"
GLOW = 1.0                                       # the rim's light at rest: light, not clipped
FLARE = 3.0                                      # its flare over rest at the lock
A_DROP = 2.0                                     # A: the wedges' start, studs below. The player's eye is 3.2 under the
                                                 # new deck: from 6 below, the near wedge went through the lens
SETTLE = 0.18                                    # Back's overshoot at the lock, studs up
WEDGES, STREAKS = 8, 12


def clamp(v, lo=0.0, hi=1.0):
    return max(lo, min(hi, v))


def ease_in(u):
    return clamp(u) ** 2


def ease_out(u):
    return 1.0 - (1.0 - clamp(u)) ** 3


def span(t, a, b):
    return clamp((t - a) / (b - a))


def times(view):
    """The moments drawn: every frame at RATE from the player's camera; the beats alone from the yard and above (the
    motion is judged from the player's camera; the others are for the ring's read and the symbols)."""
    if view != "leap":
        return [(i, at) for i, (_, at) in enumerate(BEATS[view])]
    a, b = SPANS[view]
    n = round((b - a) * RATE)
    return [(i, a + i / RATE) for i in range(n + 1)]


# --- geometry ----------------------------------------------------------------------------------------------------------

def sector(r0, r1, z0, z1, a0=0.0, a1=2 * math.pi, n=None):
    """A closed annular sector, radii r0 to r1, heights z0 to z1, angles a0 to a1 (a whole ring when they span 2 pi)."""
    full = abs(a1 - a0) >= 2 * math.pi - 1e-6
    n = n or max(3, round(abs(a1 - a0) / (2 * math.pi) * 96))
    count = n if full else n + 1
    verts, faces = [], []
    for k in range(count):
        a = a0 + (a1 - a0) * k / n
        c, s = math.cos(a), math.sin(a)
        verts += [(r0 * c, r0 * s, z0), (r1 * c, r1 * s, z0), (r1 * c, r1 * s, z1), (r0 * c, r0 * s, z1)]
    for k in range(n):
        i, j = 4 * k, 4 * ((k + 1) % count)
        for e in range(4):
            e2 = (e + 1) % 4
            faces.append((i + e, j + e, j + e2, i + e2))
    if not full:
        last = 4 * (count - 1)
        faces += [(0, 1, 2, 3), (last + 3, last + 2, last + 1, last)]
    return verts, faces


def cone(radius, depth, n=48):
    """The keel: a broad shallow cone, its top at z 0, its point at -depth."""
    verts = [(radius * math.cos(2 * math.pi * k / n), radius * math.sin(2 * math.pi * k / n), 0.0) for k in range(n)]
    verts += [(0.0, 0.0, -depth), (0.0, 0.0, 0.0)]
    tip, top = n, n + 1
    faces = [(k, (k + 1) % n, tip) for k in range(n)] + [((k + 1) % n, k, top) for k in range(n)]
    return verts, faces


def solid(scene, name, geo, mat, parent=None):
    import bpy
    data = bpy.data.meshes.new(name)
    data.from_pydata(geo[0], [], geo[1])
    data.materials.append(mat)
    obj = bpy.data.objects.new(name, data)
    scene.collection.objects.link(obj)
    if parent is not None:
        obj.parent = parent
    return obj


def empty(scene, name, at=(0.0, 0.0, 0.0)):
    import bpy
    obj = bpy.data.objects.new(name, None)
    obj.location = at
    scene.collection.objects.link(obj)
    return obj


def glow_knob(mat):
    return next(n for n in mat.node_tree.nodes if n.type == "EMISSION").inputs["Strength"]


class Streak:
    """A straight streak of light, even in width (a thin six-sided tube), brightest at its head and thinning to
    nothing at its tail: the content check's condition 1."""

    def __init__(self, scene, name, width):
        import stage_land_block as slb
        self.part = slb.Part(scene, name, slb.band(6), power=2.0, floor=0.0)
        self.part.obj.rotation_mode = "QUATERNION"
        self.width = width

    def show(self, tail, head, strength):
        from mathutils import Vector
        tail, head = Vector(tail), Vector(head)
        d = head - tail
        if d.length < 0.05 or strength <= 0.002:
            self.part.hide()
            return
        self.part.obj.rotation_quaternion = d.normalized().to_track_quat("Z", "Y")
        self.part.show(tuple(tail), (self.width, self.width, d.length), strength)

    def hide(self):
        self.part.hide()


# --- one platform: its parts, built at its middle, its deck's top at z 0 ------------------------------------------------

class Platform:
    """One direction's platform at a floor. `gathering` makes the parts the gathering moves; otherwise it stands."""

    def __init__(self, scene, mats, direction, tag, centre, gathering=False):
        import bpy
        import stage_land_block as slb
        import lantern_row_look as look
        self.scene, self.direction, self.tag, self.centre = scene, direction, tag, centre
        self.root = empty(scene, f"{tag}Root", centre)
        self.light = look.glowing(f"{tag}Rim", GREY, GLOW)
        self.knob = glow_knob(self.light)
        self.objects, self.groups, self.streaks, self.segments = [], [], [], []
        stone, deck, bed = mats["stone"], mats["deck"], mats["bed"]
        if direction == "A":
            gap = 0.17 / RADIUS                          # the seam's width at the rim, in radians: straight seams
            for k in range(WEDGES):
                a0, a1 = 2 * math.pi * k / WEDGES + gap / 2, 2 * math.pi * (k + 1) / WEDGES - gap / 2
                g = empty(scene, f"{tag}Wedge{k}")
                g.parent = self.root
                parts = [solid(scene, f"{tag}Deck{k}", sector(0.0, 12.4, -THICK, 0.0, a0, a1), deck, g),
                         solid(scene, f"{tag}Lip{k}", sector(12.4, RADIUS, -THICK, 0.35, a0, a1), stone, g),
                         # the groove round the lip's outer face, and the light in it: read from above and below
                         solid(scene, f"{tag}Groove{k}", sector(RADIUS - 0.01, RADIUS + 0.04, -0.9, 0.25, a0, a1), bed, g),
                         solid(scene, f"{tag}Light{k}", sector(RADIUS + 0.02, RADIUS + 0.1, -0.62, -0.08, a0, a1),
                               self.light, g)]
                self.groups.append((g, (a0 + a1) / 2, parts))
                self.objects += parts
            # inside the wedges, so a seam looks into dark, never through to the sky (condition 2)
            self.objects.append(solid(scene, f"{tag}Under", sector(0.0, RADIUS - 0.1, -0.95, -0.05), bed, self.root))
            self.under = self.objects[-1]
            if gathering:
                self.streaks = [Streak(scene, f"{tag}Streak{k}", 0.16) for k in range(WEDGES)]
        elif direction == "B":
            self.deck = solid(scene, f"{tag}Deck", sector(0.0, 11.9, -THICK, 0.0), deck, self.root)
            self.objects.append(self.deck)
            n = 48
            for k in range(n):
                a0, a1 = 2 * math.pi * k / n, 2 * math.pi * (k + 1) / n
                # the seam runs through, collar to deck: its light shows on the top and on the underside
                parts = [solid(scene, f"{tag}Collar{k}", sector(12.7, RADIUS, -THICK, 0.3, a0, a1, 2), stone, self.root),
                         solid(scene, f"{tag}Foot{k}", sector(13.2, RADIUS, -1.5, -THICK, a0, a1, 2), stone, self.root),
                         solid(scene, f"{tag}Seam{k}", sector(11.9, 12.7, -0.95, -0.08, a0, a1, 2), bed, self.root),
                         solid(scene, f"{tag}Light{k}", sector(12.05, 12.55, -0.1, -0.06, a0, a1, 2), self.light, self.root),
                         solid(scene, f"{tag}Below{k}", sector(12.05, 12.55, -0.97, -0.93, a0, a1, 2), self.light,
                               self.root)]
                self.segments.append((a1, parts))
                self.objects += parts
            if gathering:
                self.head = Streak(scene, f"{tag}Head", 0.3)
                self.arc = [Streak(scene, f"{tag}Arc{k}", 0.22) for k in range(6)]
        else:
            self.deck = solid(scene, f"{tag}Deck", sector(0.0, RADIUS, -THICK, 0.0), deck, self.root)
            # the light on the underside at the rim, in its bed: the updraft's side, read from below
            self.rim = [solid(scene, f"{tag}Bed", sector(12.2, RADIUS, -THICK - 0.04, -THICK + 0.02), bed, self.deck),
                        solid(scene, f"{tag}Light", sector(12.7, 13.5, -THICK - 0.07, -THICK - 0.02), self.light, self.deck)]
            self.keel = solid(scene, f"{tag}Keel", cone(6.0, 3.5), stone, self.root)
            self.keel.location = (0.0, 0.0, -THICK)
            self.tip = solid(scene, f"{tag}Tip", cone(0.7, 0.9, 12), self.light, self.root)
            self.tip.location = (0.0, 0.0, -THICK - 3.5 + 0.35)
            self.objects += [self.deck, *self.rim, self.keel, self.tip]
            if gathering:
                self.streaks = [Streak(scene, f"{tag}Streak{k}", 0.16) for k in range(STREAKS)]
        if gathering:
            self.band = slb.Part(scene, f"{tag}Band", slb.band(96), power=2.0, floor=0.0)
            data = bpy.data.lights.new(f"{tag}Wash", "POINT")
            data.color, data.use_shadow, data.shadow_soft_size = (0.95, 0.93, 1.0), False, 2.0
            self.wash = bpy.data.objects.new(f"{tag}Wash", data)
            self.wash.parent = self.root
            self.wash.location = (0.0, 0.0, -6.0)          # under the new disc: its light falls on the pair below
            scene.collection.objects.link(self.wash)

    def show(self, on):
        for o in self.objects:
            o.hide_render = not on
        for s in self.streaks:
            s.hide()
        if hasattr(self, "band"):
            self.band.hide()
            self.wash.hide_render = True
        if hasattr(self, "head"):
            self.head.hide()
            for a in self.arc:
                a.hide()

    def world(self, x, y, z):
        c = self.centre
        return (c[0] + x, c[1] + y, c[2] + z)

    def frame(self, t):
        """The gathering at t seconds from the win (before it, nothing; after the pulse, the platform at rest)."""
        self.show(t >= 0.0)
        if t < 0.0:
            return
        u = ease_in(t / GATHER)
        settle = SETTLE * math.sin(math.pi * span(t, GATHER, GATHER + 0.1)) if t >= GATHER else 0.0
        self.root.location = (self.centre[0], self.centre[1], self.centre[2] + settle)
        pulse = span(t, GATHER, PULSE)
        flare = FLARE * (1 - pulse) ** 2 if GATHER <= t <= PULSE else 0.0
        self.knob.default_value = GLOW + flare
        getattr(self, f"gather_{self.direction}")(t, u)
        if GATHER <= t <= PULSE:                            # the pulse: one upright band lifts off the rim and fades
            tall = 0.2 + 1.8 * ease_out(pulse)
            self.band.show(self.world(0.0, 0.0, 0.3 + settle), (RADIUS + 0.1, RADIUS + 0.1, tall), 2.0 * (1 - pulse) ** 2)
            self.wash.hide_render = False
            self.wash.data.energy = 2500.0 * (1 - pulse) ** 2
        elif t < GATHER:
            self.wash.hide_render = False
            self.wash.data.energy = 800.0 * u

    def gather_A(self, t, u):
        """Each wedge flies in on a straight line through the middle (no spin), from 2r out and A_DROP below."""
        for k, (g, mid, parts) in enumerate(self.groups):
            away = 1.0 - u
            out = (RADIUS * away * math.cos(mid), RADIUS * away * math.sin(mid), -A_DROP * away)
            g.location = out
            for p in parts:
                p.hide_render = False
            self.knob.default_value = max(self.knob.default_value, 0.0) if t >= GATHER else 0.6 + 1.4 * u
            if t < GATHER:
                rim = ((RADIUS + 0.06) * math.cos(mid), (RADIUS + 0.06) * math.sin(mid), -0.35)   # the lip's light
                head = self.world(rim[0] + out[0], rim[1] + out[1], rim[2] + out[2])
                back = min(0.35, 0.12 + 0.5 * u) * 1.0       # the streak's length, as a share of the whole path
                was = 1.0 - ease_in(clamp(t / GATHER - back))
                tail = self.world(rim[0] + RADIUS * was * math.cos(mid), rim[1] + RADIUS * was * math.sin(mid),
                                  rim[2] - A_DROP * was)
                self.streaks[k].show(tail, head, 1.2 + 1.6 * u)
        self.under.hide_render = t < GATHER - 0.03

    def gather_B(self, t, u):
        """The head runs once round the rim, slow to fast, drawing the collar; then the deck closes as a shrinking
        ring (never blades: the content check's condition 4)."""
        run = 0.2
        swept = 2 * math.pi * ease_in(t / run)
        for end, parts in self.segments:
            for p in parts:
                p.hide_render = end > swept + 1e-6
        if t < run:
            a = swept
            c, s = math.cos(a), math.sin(a)
            r = 13.3
            self.head.show(self.world(r * c, r * s, -0.2), self.world(r * c, r * s, 1.6), 2.6)
            for k, arc in enumerate(self.arc):           # the trail behind the head, a chord at a time, fading
                b0, b1 = a - (k + 1) * 0.12 * (0.3 + u), a - k * 0.12 * (0.3 + u)
                if b0 < 0:
                    arc.hide()
                    continue
                arc.show(self.world(r * math.cos(b0), r * math.sin(b0), 0.4), self.world(r * math.cos(b1), r * math.sin(b1), 0.4),
                         1.8 * (1 - k / 6) ** 1.5)
        inner = 12.15 * (1.0 - ease_in(span(t, run, GATHER)))
        import bpy
        old = self.deck.data
        self.deck.data = bpy.data.meshes.new(f"{self.tag}DeckAt")
        geo = sector(inner, 12.15, -THICK, 0.0) if inner > 0.05 else sector(0.0, 12.15, -THICK, 0.0)
        self.deck.data.from_pydata(geo[0], [], geo[1])
        self.deck.data.materials.append(old.materials[0])
        bpy.data.meshes.remove(old)
        self.deck.hide_render = t < run
        self.knob.default_value = max(self.knob.default_value, GLOW)

    def gather_C(self, t, u):
        """Twelve straight streaks rise from the lower rim, leaning in on lines through the middle; the rim where they
        arrive, then the deck thickens, the keel last."""
        rise = 0.3
        s = ease_in(t / rise)
        for k, streak in enumerate(self.streaks):
            a = 2 * math.pi * k / STREAKS
            c, n = math.cos(a), math.sin(a)

            def at(v):
                r = 15.5 + (13.6 - 15.5) * v
                return self.world(r * c, r * n, -HEIGHT + HEIGHT * v)
            if t < rise + 0.05:
                length = 0.2 + 0.35 * s
                head = min(s, 1.0)
                tail = clamp(head - length) if t < rise else clamp(1.0 - (1 - (t - rise) / 0.05) * length)
                streak.show(at(tail), at(head), 1.4 + 1.4 * s)
        arrived = t >= rise - 0.02
        for p in self.rim:
            p.hide_render = not arrived
        thick = ease_out(span(t, rise - 0.02, GATHER))
        self.deck.scale = (1.0, 1.0, max(0.03, thick))
        self.deck.hide_render = not arrived
        keel = ease_out(span(t, rise + 0.02, GATHER + 0.03))
        self.keel.location = (0.0, 0.0, -THICK * max(0.03, thick))
        self.keel.scale = (1.0, 1.0, max(0.02, keel))
        self.keel.hide_render = keel <= 0.0
        self.tip.location = (0.0, 0.0, -THICK * max(0.03, thick) - 3.5 * keel + 0.35)
        self.tip.hide_render = keel < 0.95


# --- the scene ---------------------------------------------------------------------------------------------------------

class Pair:
    """The avatar and the lead, our own boxes (a player's size), and their stand-in leap."""

    def __init__(self, scene, kit, mat, avatar, lead):
        self.parts = []
        for who, (x, y) in (("Avatar", avatar), ("Lead", lead)):
            for part, size, z in (("Legs", (2, 1, 2), 1), ("Body", (4, 1, 2), 3), ("Head", (1.2, 1.2, 1.2), 4.6)):
                obj = kit.block(f"{who}{part}", size, (x, y, z), mat)
                self.parts.append((obj, z))
        self.avatar = avatar

    def at(self, t, floor_z):
        u = span(t, *LEAP)
        z = floor_z + HEIGHT * (2 * u - u * u)              # a straight rise that slows to the new deck (stand-in)
        for obj, dz in self.parts:
            obj.location.z = z + dz
        return z


def build(view):
    import bpy
    from mathutils import Vector
    import base_kit as base
    import base_plan as plan
    import blcommon as bl
    import lantern_row_look as look

    out = bl.out_dir()
    d = look.DIRECTIONS["M"]
    look.FOG.update(colour=look.srgb(d["fog"][0]), density=d["fog"][1], azimuth=d.get("glow_az", 0.0),
                    away=look.srgb(d["fog_away"]) if "fog_away" in d else None)
    scene = bl.reset_scene()
    base.write_pictures(out / "maps")
    yard = plan.Yard(scene, 2, out / "maps")
    yard.plot(0.0, 1)
    yard.kit.block("Ground", (5 * plan.PLOT, 4 * plan.PLOT, 0.4), (0, plan.STRIP / 2, -0.3), yard.flat["ground"])
    for obj in yard.kit.pieces:
        if obj.name.startswith(("PowerSpan", "Court", "Yard", "Wings")):
            obj.visible_shadow = False
    look.sky(scene, d)
    look.sun(scene, d)
    r = scene.render
    for engine in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            r.engine = engine
            break
        except TypeError:
            continue
    r.resolution_x, r.resolution_y, r.resolution_percentage = *look.SIZE, 100
    scene.view_settings.view_transform = "Standard"
    scene.eevee.taa_render_samples = 8
    for attr, val in (("use_shadows", True), ("shadow_ray_count", 1), ("use_raytracing", False)):
        try:
            setattr(scene.eevee, attr, val)
        except AttributeError:
            pass
    mats = dict(stone=look.painted("TowerStone", *STONE), deck=look.painted("TowerDeck", DECK, DECK),
                bed=look.painted("TowerBed", BED, BED), column=look.painted("TowerColumn", "#7C7E86", "#686A72"))
    ring = Vector(yard.at(0.0, 1, *plan.TOWER_AT))
    toward = (Vector((0.0, -plan.PLOT / 2, 0.0)) - ring)
    toward.z = 0.0
    toward.normalize()
    side = Vector((toward.y, -toward.x, 0.0))
    yard.kit.block("TowerRingMark", (10.0, 10.0, 0.06), (ring.x, ring.y, 0.03), yard.flat["spawn"])
    stacks = {}
    for direction in DIRECTIONS:
        floors = {f: Platform(scene, mats, direction, f"{direction}F{f}", (ring.x, ring.y, f * HEIGHT),
                              gathering=f == FLOOR + 1) for f in (FLOOR - 2, FLOOR - 1, FLOOR, FLOOR + 1)}
        stacks[direction] = floors
    column = solid(scene, "TowerColumn", sector(0.0, 2.0, 0.0, 1.0, n=32), mats["column"])     # TowerController's, 4 wide
    column.location = (ring.x, ring.y, 0.0)
    avatar = ring - toward * STAND * RADIUS
    lead = avatar + toward * 3.0 + side * 2.5
    pair = Pair(scene, yard.kit, yard.flat["spawn"], (avatar.x, avatar.y), (lead.x, lead.y))
    cam = plan.camera(scene, f"Cam{view}", (0, 0, 0), (0, 1, 0))
    scene.camera = cam
    return scene, d, dict(stacks=stacks, column=column, pair=pair, ring=ring, toward=toward, side=side, cam=cam)


def place(view, w, direction, t):
    """Everything at t seconds from the win, for `direction`."""
    from mathutils import Vector
    import lantern_row_look as look
    for dr, floors in w["stacks"].items():
        for f, p in floors.items():
            if dr != direction:
                p.show(False)
            elif f == FLOOR + 1:
                p.frame(t)
            elif f == FLOOR - 2:
                p.show(t < 0.0)                          # at the win the stack drops its lowest (TowerController)
            else:
                p.show(True)
    lowest = FLOOR - 2 if t < 0.0 else FLOOR - 1                 # the lowest standing disc (TowerController's 3)
    high = lowest * HEIGHT - THICK - {"A": 0.3, "B": 1.8, "C": 3.8}[direction]
    w["column"].scale = (1.0, 1.0, max(0.01, high))
    z = w["pair"].at(t, FLOOR * HEIGHT)
    cam, toward, ring = w["cam"], w["toward"], w["ring"]
    if view == "leap":
        pitch = math.radians(20.0)
        focus = Vector((*w["pair"].avatar, z + 3.0 + look.FOCUS))
        eye = focus - toward * math.cos(pitch) * look.ZOOM + Vector((0, 0, math.sin(pitch) * look.ZOOM))
    elif view == "yard":
        eye = ring + toward * 57.5 + w["side"] * 8.0 + Vector((0, 0, 9.0))     # behind a player 45 off, in the yard
        focus = ring + Vector((0, 0, (FLOOR + 0.5) * HEIGHT))
    else:
        top = ring + Vector((0, 0, (FLOOR + 1) * HEIGHT))
        eye = top - toward * 18.0 + Vector((0, 0, 40.0))
        focus = top
    cam.location = eye
    cam.rotation_euler = (Vector(focus) - Vector(eye)).to_track_quat("-Z", "Y").to_euler()


def disc_share(scene, cam, ring, w, h):
    """The new disc's share of the frame: its rim projected, clipped to the frame, its area over the frame's."""
    from bpy_extras.object_utils import world_to_camera_view
    from mathutils import Vector
    pts = []
    z = (FLOOR + 1) * HEIGHT
    for k in range(64):
        a = 2 * math.pi * k / 64
        p = world_to_camera_view(scene, cam, Vector((ring.x + RADIUS * math.cos(a), ring.y + RADIUS * math.sin(a), z)))
        if p.z <= 0:
            return None
        pts.append((p.x, p.y))
    for edge in ((0, 0.0, 1), (0, 1.0, -1), (1, 0.0, 1), (1, 1.0, -1)):     # clip to the frame, edge by edge
        axis, lim, keep = edge
        inside = (lambda q: (q[axis] - lim) * keep >= 0)
        kept = []
        for i, cur in enumerate(pts):
            prev = pts[i - 1]
            if inside(cur):
                if not inside(prev):
                    kept.append(cut(prev, cur, axis, lim))
                kept.append(cur)
            elif inside(prev):
                kept.append(cut(prev, cur, axis, lim))
        pts = kept
        if not pts:
            return 0.0
    return abs(sum(pts[i - 1][0] * pts[i][1] - pts[i][0] * pts[i - 1][1] for i in range(len(pts)))) / 2


def cut(p, q, axis, lim):
    k = (lim - p[axis]) / (q[axis] - p[axis])
    return (p[0] + (q[0] - p[0]) * k, p[1] + (q[1] - p[1]) * k)


def render(out, view, directions):
    import lantern_row_look as look
    import rook_sheet as rs
    scene, d, w = build(view)
    measures = {}
    for direction in directions:
        folder = out / view / direction
        folder.mkdir(parents=True, exist_ok=True)
        for i, t in times(view):
            place(view, w, direction, t)
            path = folder / f"f{i:03d}.png"
            px = look.finish(look.render_linear(scene, path.with_suffix(".exr")), d)
            rs.save(px, path)
            path.with_suffix(".exr").unlink(missing_ok=True)
            grey = px[..., :3] @ [0.2126, 0.7152, 0.0722]
            share = disc_share(scene, w["cam"], w["ring"], *look.SIZE)
            measures[f"{direction} {i}"] = dict(t=round(t, 3), white=round(float((grey >= 243 / 255).mean()), 5),
                                                disc=None if share is None else round(share, 4))
        print(direction, view, "done")
    path = out / f"{view}_measures.json"
    old = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}
    path.write_text(json.dumps({**old, **measures}), encoding="utf-8")


# --- the sheets and the movies -----------------------------------------------------------------------------------------

BEATS = {"leap": [("gathering", 0.13), ("closing fast", 0.27), ("the lock", 0.37), ("the pulse", 0.47),
                  ("the leap", 1.0), ("set down", 1.4)],
         "yard": [("gathering", 0.13), ("closing fast", 0.27), ("the lock", 0.37), ("the pulse", 0.47), ("at rest", 0.8)],
         "top": [("gathering", 0.13), ("closing fast", 0.27), ("the lock", 0.37), ("the pulse", 0.47), ("at rest", 0.7)]}
SAID = {"leap": "the player's camera, floor 5 to 6", "yard": "from the yard, looking up", "top": "from above (symbols)"}


def drawn(out, view):
    return [dr for dr in DIRECTIONS if (out / view / dr).is_dir()]


def sheet(out):
    import textwrap
    import numpy as np
    import lantern_row_look as look
    import rook_sheet as rs
    import ui_sheet as ui

    w, h = look.SIZE
    measures = {v: json.loads((out / f"{v}_measures.json").read_text(encoding="utf-8"))
                for v in SPANS if (out / f"{v}_measures.json").exists()}

    def index(view, t):
        marks = times(view)
        return min(range(len(marks)), key=lambda k: abs(marks[k][1] - t))

    def tile(view, direction, t):
        return rs.load(out / view / direction / f"f{index(view, t):03d}.png")

    gap, tw, th, left = 14, w // 2, h // 2, 170
    cols = max(len(b) for b in BEATS.values())
    rows = [(v, dr) for v in ("leap", "yard", "top") if v in measures for dr in drawn(out, v)]
    lines = []
    for dr in drawn(out, "leap") if "leap" in measures else []:
        m = [val for key, val in measures["leap"].items() if key.startswith(dr)]
        white = max(x["white"] for x in m)
        over = sum(1 for x in m if x["white"] > 0.03)
        lock = min(m, key=lambda x: abs(x["t"] - 0.37))
        lines.append(f"{dr} from the player's camera: peak near-white {white:.1%}, frames over 3% {over}; "
                     f"the new disc at the lock {0 if lock['disc'] is None else lock['disc']:.0%} of the frame")
    notes = ["The player's camera: 12.5 studs behind the avatar, 20 degrees down, FOV 70, on floor 5 turned toward the base; "
             "it follows a stand-in leap (0.75 to 1.25 s), a straight rise slowing to the new deck. The yard: behind a "
             "player in the base's back yard 45 studs off, looking up. From above: for the symbols. In grey, the yard at "
             "base level 2 by the game's day (AR40's C); the effect near-white."] + lines
    text = [ln for n in notes for ln in textwrap.wrap(n, 230)]
    height = 60 + len(rows) * (th + gap) + 20 + len(text) * 19
    ui.K = 1
    page = ui.Sheet(left + cols * (tw + gap) + gap, height, "#14151C")
    t = page.tile(0, 0, page.w, page.h)
    t.text(gap, 14, 20, "Grow your Anime, the Tower's platforms (AR41): three directions in grey, at the beats", "#EDE6D6", bold=0.2)
    y = 52
    for view, direction in rows:
        t.text(gap, y + th // 2 - 20, 14, f"{direction}, {NAMES[direction].split(' ', 1)[1]}", "#EDE6D6")
        t.text(gap, y + th // 2, 13, SAID[view], "#B4AC9C")
        for k, (said, at) in enumerate(BEATS[view]):
            x = left + gap + k * (tw + gap)
            rs.paste(page.px, rs.shrink(tile(view, direction, at), 0.5), x, y)
            t.text(x + 4, y + 4, 12, f"{said}, {at:.2f} s", "#EDE6D6")
        y += th + gap
    for k, ln in enumerate(text):
        t.text(gap, y + 8 + k * 19, 14, ln, "#B4AC9C")
    for layer in ui.text_layers(page.px.shape[1], page.px.shape[0], page.items).values():
        rs.paste(page.px, layer, 0, 0)
    rs.save(page.px, out / "tower_beats.png")

    # the read at 64 pixels high, over dark: the lock, the pulse and at rest, every view, shown three times over
    small, blow = 64, 3
    sw = round(w * small / h)
    picks = [("the lock", 0.37), ("the pulse", 0.47), ("at rest", 0.7)]
    page = ui.Sheet(left + len(picks) * (sw * blow + gap) + gap, 50 + len(rows) * (small * blow + gap) + 10, "#14151C")
    t = page.tile(0, 0, page.w, page.h)
    t.text(gap, 14, 20, "The Tower's platforms (AR41), in grey: the read at 64 pixels high", "#EDE6D6", bold=0.2)
    y = 48
    for view, direction in rows:
        t.text(gap, y + small * blow // 2 - 10, 14, f"{direction}, {SAID[view]}", "#EDE6D6")
        for k, (_, at) in enumerate(picks):
            px = rs.shrink(tile(view, direction, min(at, SPANS[view][1])), small / h)
            rs.paste(page.px, np.repeat(np.repeat(px, blow, axis=0), blow, axis=1), left + gap + k * (sw * blow + gap), y)
        y += small * blow + gap
    for layer in ui.text_layers(page.px.shape[1], page.px.shape[0], page.items).values():
        rs.paste(page.px, layer, 0, 0)
    rs.save(page.px, out / "tower_64.png")

    # each direction's strip: every frame at 30, each view, a quarter size
    qw, qh, per = w // 4, h // 4, 8
    for direction in DIRECTIONS:
        views = [v for v in ("leap", "yard", "top") if v in measures and direction in drawn(out, v)]
        if not views:
            continue
        blocks = [math.ceil(len(times(v)) / per) * (qh + 22) for v in views]
        page = ui.Sheet(per * (qw + 8) + 2 * gap, 60 + sum(b + 30 for b in blocks) + 20, "#14151C")
        t = page.tile(0, 0, page.w, page.h)
        t.text(gap, 14, 20, f"The Tower's platforms (AR41), {direction}, {NAMES[direction]}, in grey: every frame at 30 a second",
               "#EDE6D6", bold=0.2)
        y = 50
        for v, block in zip(views, blocks):
            t.text(gap, y, 14, SAID[v], "#B4AC9C")
            y += 22
            for k, (i, at) in enumerate(times(v)):
                x0, y0 = gap + (k % per) * (qw + 8), y + (k // per) * (qh + 22)
                rs.paste(page.px, rs.shrink(rs.load(out / v / direction / f"f{i:03d}.png"), 0.25), x0, y0)
                m = measures[v][f"{direction} {i}"]
                t.text(x0, y0 + qh + 2, 12, f"{at:+.2f} s" + (f"  white {m['white']:.1%}" if m["white"] >= 0.005 else ""),
                       "#EDE6D6" if 0.0 <= at <= PULSE else "#8E887C")
            y += block + 8
        for layer in ui.text_layers(page.px.shape[1], page.px.shape[0], page.items).values():
            rs.paste(page.px, layer, 0, 0)
        rs.save(page.px, out / f"tower_{direction}.png")


def movie(out, view):
    """The view's directions one after another, at 30 a second, as an MP4 (Blender's own encoder)."""
    import bpy
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = 960, 540, 100
    scene.render.fps = RATE
    se = scene.sequence_editor_create()
    strips = se.strips if hasattr(se, "strips") else se.sequences
    files = []
    for direction in drawn(out, view):
        shots = sorted((out / view / direction).glob("f*.png"))
        files += [f"{direction}/{s.name}" for s in shots] + [f"{direction}/{shots[-1].name}"] * 12
    first = strips.new_image("Frames", str(out / view / files[0]), 1, 1)
    first.directory = str(out / view) + "/"
    first.elements[0].filename = files[0]
    for name in files[1:]:
        first.elements.append(name)
    scene.frame_start, scene.frame_end = 1, len(files)
    settings = scene.render.image_settings
    if hasattr(settings, "media_type"):
        settings.media_type = "VIDEO"
    settings.file_format = "FFMPEG"
    scene.render.ffmpeg.format, scene.render.ffmpeg.codec = "MPEG4", "H264"
    scene.render.ffmpeg.constant_rate_factor = "HIGH"
    scene.render.filepath = str(out / f"tower_{view}.mp4")
    bpy.ops.render.render(animation=True)


def by_day():
    """The game's day as the kit wears it since AR40's pick (C), as `shop_look.by_day`: the block is judged by day
    first. `dusk` on the command line keeps the look's dusk instead."""
    sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "colour"))
    import ar40_see as seen
    seen.lighting(seen.EVERY[seen.KIT])
    seen.day.light("day")


def main():
    import blcommon as bl
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    if "dusk" not in args and args[0] in ("render", "still"):
        by_day()
    args = [a for a in args if a != "dusk"]
    if args[0] == "render":
        render(out, args[1], [a for a in args[2:] if a in DIRECTIONS] or list(DIRECTIONS))
    elif args[0] == "still":                       # still <view> <directions...> <t> [<t> ...]: a few moments
        import lantern_row_look as look
        import rook_sheet as rs
        scene, d, w = build(args[1])
        for direction in [a for a in args[2:] if a in DIRECTIONS]:
            for at in [a for a in args[2:] if a not in DIRECTIONS]:
                place(args[1], w, direction, float(at))
                path = out / f"still_{args[1]}_{direction}_{float(at):.2f}.png"
                rs.save(look.finish(look.render_linear(scene, path.with_suffix(".exr")), d), path)
                path.with_suffix(".exr").unlink(missing_ok=True)
    elif args[0] == "montage":                     # montage <name> <still files...>: three to a row, half size
        import numpy as np
        import rook_sheet as rs
        shots = [rs.shrink(rs.load(out / name), 0.5) for name in args[2:]]
        h, w = shots[0].shape[:2]
        rows = math.ceil(len(shots) / 3)
        page = np.zeros((rows * (h + 6), 3 * (w + 6), shots[0].shape[2]), dtype=shots[0].dtype)
        for k, px in enumerate(shots):
            rs.paste(page, px, (k % 3) * (w + 6), (k // 3) * (h + 6))
        rs.save(page, out / args[1])
    elif args[0] == "sheet":
        sheet(out)
    elif args[0] == "movie":
        movie(out, args[1])


if __name__ == "__main__":
    main()
