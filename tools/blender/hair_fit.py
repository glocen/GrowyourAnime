"""How a Voidkin's hair sits on its head, measured on the delivered meshes, not on the egg they were laid over (AR60,
2026-11-27: "the hair is still not attached to kira head"). Pure numpy, no Blender. -- py hair_fit.py <make folder> <Name>

Reported, in studs:
  - the rim: round the head in sectors, the hair's lowest point near the head and its gap to the head's surface there;
  - lying down: the most the hair stands off the head below its middle (where the side and back hair must lie on it);
  - the outline: in the front, side and back views, at the lowest height the hair reaches on each side of the head,
    how far its outline stands past the head's. A hair that ends in the air overhangs; one that flows into the head
    doesn't.
The hair's tail and anything hanging far from the head (over 0.35 off) are left out of the rim and the outline."""
import json
import sys
from pathlib import Path

import numpy as np

NEAR = 0.35        # studs off the head: nearer is the hair on the head; farther, a tail or a lock hanging clear
SECTORS = 24


def load(path):
    d = json.loads(Path(path).read_text(encoding="utf-8"))
    p = np.array(d["p"], np.float64).reshape(-1, 3) + np.array(d["c"])
    return p, np.array(d["f"], np.int64).reshape(-1, 9)[:, :3]   # a triangle: its 3 points, 3 normals, 3 uv


def surface_points(p, f, k=10):
    """Points spread over every triangle, `k` to an edge: the head's surface, dense enough to measure to."""
    out = []
    for i in range(k + 1):
        for j in range(k + 1 - i):
            a, b = i / k, j / k
            out.append(p[f[:, 0]] * (1 - a - b) + p[f[:, 1]] * a + p[f[:, 2]] * b)
    return np.concatenate(out)


def nearest(q, pts, chunk=400):
    """Each of `q`'s distance to the nearest of `pts`."""
    d = np.empty(len(q))
    for s in range(0, len(q), chunk):
        block = q[s:s + chunk]
        d[s:s + chunk] = np.sqrt(((block[:, None, :] - pts[None, :, :]) ** 2).sum(-1).min(1))
    return d


def measure(folder, name):
    folder = Path(folder)
    hair, hf = load(folder / f"{name}_Hair.json")
    head, ef = load(folder / f"{name}_Head.json")
    skin = surface_points(head, ef)
    mid = np.array([0.0, (head[:, 1].min() + head[:, 1].max()) / 2, 0.0])
    mid[[0, 2]] = (head[:, [0, 2]].min(0) + head[:, [0, 2]].max(0)) / 2
    gap = nearest(hair, skin)
    rel = hair - mid
    # outside the head or in it: farther from the middle than the skin's nearest point is
    near_skin = skin[np.argmin(((hair[:, None, :] - skin[None, ::7, :]) ** 2).sum(-1), axis=1) * 7]
    inside = (np.linalg.norm(rel[:, [0, 2]], axis=1) < np.linalg.norm((near_skin - mid)[:, [0, 2]], axis=1) - 1e-3) & \
             (rel[:, 1] < (near_skin - mid)[:, 1] + 0.05)
    on = gap < NEAR
    # the face looks along -Z (Roblox); degrees round from the face's middle
    ang = np.degrees(np.arctan2(rel[:, 0], -rel[:, 2]))
    top, chin = head[:, 1].max(), head[:, 1].min()
    res = dict(head=dict(top=round(top, 3), chin=round(chin, 3), middle=round(mid[1], 3)))

    rim = []
    for s in range(SECTORS):
        a0 = -180 + 360 * s / SECTORS
        m = on & (((ang - a0) % 360) < 360 / SECTORS)
        if not m.any():
            continue
        i = np.where(m)[0][np.argmin(hair[m, 1])]
        rim.append(dict(at=round(a0 + 180 / SECTORS), low=round(hair[i, 1], 3), gap=round(gap[i], 3)))
    res["rim"] = rim

    below = on & (hair[:, 1] < mid[1]) & ~inside
    res["standoff below the middle"] = round(float(gap[below].max()) if below.any() else 0.0, 3)

    views = {}
    for view, axis, sides in (("front", 0, ("her right", "her left")), ("side", 2, ("face", "back"))):
        for sign, label in zip((-1, 1), sides):
            # the silhouettes' widths on this side, height by height; where the hair's is the outline, and how far
            # past the head's it stands at the lowest of those heights (a shelf in the air if it's well over 0)
            hs, ks = hair[on & (np.sign(rel[:, axis]) == sign)], skin[np.sign(skin[:, axis] - mid[axis]) == sign]
            best = None
            for y in np.arange(chin, top, 0.02):
                hw = np.abs(hs[np.abs(hs[:, 1] - y) < 0.015][:, axis] - mid[axis])
                kw = np.abs(ks[np.abs(ks[:, 1] - y) < 0.015][:, axis] - mid[axis])
                if len(hw) and len(kw) and hw.max() > kw.max() + 0.005:
                    best = (y, hw.max() - kw.max())
                    break
            if best:
                views[f"{view}, {label}"] = dict(lowest=round(best[0], 3), past_head=round(best[1], 3))
    res["outline"] = views
    return res


if __name__ == "__main__":
    folder, name = sys.argv[1], sys.argv[2]
    r = measure(folder, name)
    print(f"{name}: head chin {r['head']['chin']}, middle {r['head']['middle']}, top {r['head']['top']}")
    print("the rim, round from the face (degrees: lowest height, gap to the head):")
    print("  " + "  ".join(f"{q['at']:>4}: {q['low']:.2f} {q['gap']:.3f}" for q in r["rim"]))
    gaps = [q["gap"] for q in r["rim"]]
    print(f"  rim gap: most {max(gaps):.3f}, mean {np.mean(gaps):.3f}")
    print(f"standing off the head below its middle, at most: {r['standoff below the middle']:.3f}")
    for k, v in r["outline"].items():
        print(f"outline, {k}: lowest {v['lowest']:.2f}, past the head's outline there {v['past_head']:.3f}")
