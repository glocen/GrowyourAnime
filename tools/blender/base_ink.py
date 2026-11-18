"""The base's drawn edge: its ink hull's thickness, and the hull for the shapes the kit's boxes don't give one.

The kit draws an edge by an inverted hull on the atlas's ink texel (lantern_row_kit.Mesh: a box asked for `ink` gets a
larger box turned inside out). The base's is thinner than Lantern Row's (the director, 2026-11-15: "we js make those
outline a bit less thick just a little bit less thic"), and every machine wears it (the same night: "the toon outline
some machine lacked it"): a machine's turned and round shapes, which the kit's box hull never covered, get theirs here.

Numbers only, on a mesh's record as blcommon.export_mesh_json writes it: nothing here needs Blender.
"""
import numpy as np

INK = 0.11            # the base's hull, studs; Lantern Row keeps the kit's 0.14
SHARED = 0.14         # the kit's own
INK_UV = (0.8297, 0.0625)   # the atlas's ink texel in a record's frame: kit.sw_uv("ink", 0.2, 0.5), V from the top
SWATCHES = ("steel", "girder", "bone", "concrete", "yellow", "rubber", "ceramic", "copper", "power", "cyan", "lamp",
            "beacon", "dark", "ink", "void", "abyss")   # base_kit.SWATCHES, in the atlas's order
WELL = 27             # base_kit.SWATCHES' "well" (AR40), the second row's twelfth: a light's dark bed
SOLID = {"steel", "girder", "bone", "concrete", "yellow", "ceramic", "copper", "abyss", "print", "well"}   # what a hull is drawn round
HULLED = ("Generator", "GeneratorWheel", "GeneratorDemand", "Breaker", "BreakerChamber", "BreakerWaiting", "Bay", "BatteryRack",
          "BatteryCell", "Showcase", "Door", "Training", "TrainingCrown", "BaySleeping", "SleepingStone",
          "Generator2", "Generator3", "Generator2Wheel", "Generator2Pinion", "Generator3Pinion", "Generator2Demand",
          "Generator3Demand", "Forge", "ForgeRam", "ForgeGear", "Condenser", "CondenserCore",
          "Breaker2", "Breaker3", "BreakerHinge", "BreakerLid", "Bay2", "Bay3", "BayCog", "BayCogOuter",
          "BatteryRack2", "BatteryRack3", "TrainingCrown2", "TrainingCrown3",
          "Forge2", "Forge3", "Condenser2", "Condenser3")   # the machines, and the plinth
LEAST = (0.25, 0.8)   # a shape worth an edge: its thinnest side, and its middle one. Under it, an edge would swallow it


def Mesh(ink_t=INK):
    """The kit's mesh, with the base's hull."""
    import lantern_row_kit as kit
    return kit.Mesh(ink_t)


def _arrays(record):
    return (np.array(record["p"], np.float64).reshape(-1, 3), np.array(record["f"], np.int64).reshape(-1, 9),
            np.array(record["t"], np.float64).reshape(-1, 2), np.array(record["n"], np.float64).reshape(-1, 3))


def _store(record, p, f, t, n):
    mid = (p.min(0) + p.max(0)) / 2                       # a record stays centred on its own box
    record["c"] = [round(float(c + m), 5) for c, m in zip(record["c"], mid)]
    record["p"] = np.round(p - mid, 5).ravel().tolist()
    record["f"] = f.ravel().tolist()
    record["t"] = np.round(t, 5).ravel().tolist()
    record["n"] = np.round(n, 4).ravel().tolist()
    return record


def _names(t, f):
    """Each triangle's swatch, by its first corner's place in the atlas."""
    uv = t[f[:, 6]]
    cell = np.floor(uv[:, 0] * 16).astype(int) + 16 * np.floor(uv[:, 1] * 8).astype(int)
    return [SWATCHES[c] if uv[i, 1] < 0.125 and 0 <= c < len(SWATCHES) else "well" if c == WELL else "print"
            for i, c in enumerate(cell)]


def _shells(p, f):
    """The triangles of each shape: joined wherever corners meet."""
    seen = {}
    weld = np.array([seen.setdefault(tuple(v), len(seen)) for v in np.round(p, 3)])
    parent = list(range(len(seen)))

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    for tri in weld[f[:, :3]].tolist():
        a, b, c = (find(i) for i in tri)
        parent[b] = a
        parent[find(c)] = a
    root = np.array([find(i) for i in weld[f[:, 0]].tolist()])
    return weld, [np.nonzero(root == r)[0] for r in np.unique(root)]


def _moves(p, weld, tris, f, by):
    """How far each welded corner of these triangles moves so that every face it touches moves `by` along its own
    normal: a box's corner goes out on all three of its faces, a round shape's along its skin."""
    corners = p[f[tris, :3]]
    normal = np.cross(corners[:, 1] - corners[:, 0], corners[:, 2] - corners[:, 0])
    normal /= np.maximum(np.linalg.norm(normal, axis=1), 1e-12)[:, None]
    touching = {}
    for k, tri in enumerate(weld[f[tris, :3]].tolist()):
        for w in tri:
            touching.setdefault(w, set()).add(tuple(np.round(normal[k], 2)))
    moves = {}
    for w, faces in touching.items():
        a = np.array(sorted(faces))
        d = np.linalg.lstsq(a, np.full(len(a), by), rcond=None)[0]
        far = np.linalg.norm(d)
        moves[w] = d * min(1.0, 2.5 * abs(by) / max(far, 1e-12))
    return moves, normal


def _own(a, b, low, high):
    """Whether the hull from a to b is this shape's own: on its middle, and larger on two sides at least (an open
    tube's hull is no longer than its tube)."""
    grown = np.sort((b - a) - (high - low))
    return np.abs((a + b) / 2 - (low + high) / 2).max() < 0.03 and grown[0] > -0.01 and grown[1] > 0.1


def thin(record, by=SHARED - INK):
    """The hull a record already has, drawn in by `by`: the kit's 0.14 down to the base's."""
    p, f, t, n = _arrays(record)
    ink = np.array([name == "ink" for name in _names(t, f)])
    if not ink.any():
        return record
    shared = np.intersect1d(f[ink, :3], f[~ink, :3])      # a hull's corner that a shape also uses gets its own
    for v in shared.tolist():
        p = np.vstack((p, p[v]))
        rows = f[:, :3][ink]
        rows[rows == v] = len(p) - 1
        f[np.nonzero(ink)[0], :3] = rows
    seen = {}
    weld = np.array([seen.setdefault(tuple(v), len(seen)) for v in np.round(p, 3)])
    tris = np.nonzero(ink)[0]
    moves, _ = _moves(p, weld, tris, f, by)               # a hull's faces look inward: along them is in
    for v in np.unique(f[tris, :3]).tolist():
        p[v] = p[v] + moves[weld[v]]
    return _store(record, p, f, t, n)


def hull(record, by=INK):
    """A hull round every shape of the record that is worth an edge and has none. Run again, it adds nothing."""
    p, f, t, n = _arrays(record)
    names = _names(t, f)
    weld, shells = _shells(p, f)
    boxes = [(p[f[s, :3].ravel()].min(0), p[f[s, :3].ravel()].max(0), {names[i] for i in s}) for s in shells]
    inks = [(low, high) for low, high, worn in boxes if worn == {"ink"}]
    t = np.vstack((t, INK_UV))
    added = 0
    for s, (low, high, worn) in zip(shells, boxes):
        size = np.sort(high - low)
        if not worn <= SOLID or worn == {"well"} or size[0] < LEAST[0] or size[1] < LEAST[1]:
            continue                                      # a well alone is a bed under a light: no edge of its own
        if any(_own(a, b, low, high) for a, b in inks):
            continue                                      # it has its edge
        moves, normal = _moves(p, weld, s, f, by)
        new = {}
        for v in np.unique(f[s, :3]).tolist():
            new[v] = len(p)
            p = np.vstack((p, p[v] + moves[weld[v]]))
        for k, tri in enumerate(f[s].tolist()):
            n = np.vstack((n, -normal[k]))
            a, b, c = (new[v] for v in tri[:3])
            f = np.vstack((f, [a, c, b, len(n) - 1, len(n) - 1, len(n) - 1, len(t) - 1, len(t) - 1, len(t) - 1]))
        added += len(s)
    return _store(record, p, f, t, n) if added else record
