"""A blockout drawn from a camera with Studio and Blender closed: plain parts in flat colours, the handoff's own meshes in
their own pictures, a sun, the lights' pools, a rim light, fog, a sky, beams of light laid over it, and a bloom on what
glows. For judging shapes, layout, colour blocks and where the energy goes from the player's camera when no renderer
fits in memory. It is not the game's light: the verdict that counts is the one in Studio.

numpy and scipy only. A picture takes some seconds and well under 300 MB.
"""
import math
import struct
import zlib
from pathlib import Path

import numpy as np
from scipy.ndimage import gaussian_filter

import parts as pt

SIZE, OVER = (960, 540), 2
ZOOM, FOV, FOCUS, PITCH = 12.5, 70.0, 1.5, 20.0      # the game's camera: Roblox's start zoom, its FOV, the replay's pitch
NEAR = 0.4
SKY = ((-0.2, "#16143A"), (0.0, "#4A3F86"), (0.08, "#342F74"), (0.3, "#1C1E54"), (1.0, "#0C1030"))   # the dusk, away from its glow
FOG, HAZE = "#2A2660", 0.0032
AMBIENT, SUN, SUN_FROM = ("#3A3F7C", 0.55), ("#A9B4FF", 0.6), (0.35, 0.55, 0.76)


def rgb(code):
    return np.array([int(code[i:i + 2], 16) / 255.0 for i in (1, 3, 5)]) ** 2.2


def behind(across, along, heading=-1, floor=0.6):
    """The game's camera behind a player standing at (across, along), looking into the plot (-1) or out to the Strip (+1)."""
    pitch = math.radians(PITCH)
    focus = np.array((across, along, floor + 3.0 + FOCUS))
    return focus + np.array((0.0, -heading * math.cos(pitch), math.sin(pitch))) * ZOOM, focus


class Scene:
    """What a picture is drawn from: triangles, each flat in a colour or wearing a picture, and the pictures."""

    def __init__(self):
        self.p, self.uv, self.tex, self.colour, self.glow, self.cull = [], [], [], [], [], []
        self.pictures = []

    def picture(self, colour, glow=None, strength=1.0):
        """A piece's pictures, sRGB-coded in 0 to 1: its colour, and its glow's mask. Returns the picture's number."""
        colour = np.asarray(colour, np.float32)[..., :3] ** 2.2
        mask = np.zeros(colour.shape[:2], np.float32) if glow is None else np.asarray(glow, np.float32)
        mask = mask[..., 0] if mask.ndim == 3 else mask
        self.pictures.append((colour, mask * strength))
        return len(self.pictures) - 1

    def mesh(self, record, picture, at, turn=0.0, scale=1.0, spin=0.0):
        """A handoff mesh (blcommon.export_mesh_json's record) stood where a plan puts it: `at` is across, along and
        up, `turn` degrees anticlockwise from above. `spin` turns it about its own X first, in degrees (a rotor)."""
        p = np.array(record["p"], np.float32).reshape(-1, 3) + np.array(record["c"], np.float32)
        own = np.stack((p[:, 0], -p[:, 2], p[:, 1]), axis=1)                     # Roblox's frame back to the plan's
        if spin:
            c, s = math.cos(math.radians(spin)), math.sin(math.radians(spin))
            own = np.stack((own[:, 0], own[:, 1] * c - own[:, 2] * s, own[:, 1] * s + own[:, 2] * c), axis=1)
        c, s = math.cos(math.radians(turn)), math.sin(math.radians(turn))
        world = np.stack((own[:, 0] * c - own[:, 1] * s, own[:, 0] * s + own[:, 1] * c, own[:, 2]), axis=1) * scale
        world += np.array(at, np.float32)
        f = np.array(record["f"], np.int64).reshape(-1, 9)
        t = np.array(record["t"], np.float32).reshape(-1, 2)
        self.p.append(world[f[:, 0:3]])
        self.uv.append(t[f[:, 6:9]])
        n = len(f)
        self.tex.append(np.full(n, picture, np.int32))
        self.colour.append(np.zeros((n, 3), np.float32))
        self.glow.append(np.zeros(n, np.float32))
        self.cull.append(np.ones(n, bool))

    def parts(self, parts):
        """Plain parts (parts.py), flat in their colour, seen from both sides."""
        tris, colours, glows = [], [], []
        for p in parts:
            base, glow = rgb(p["colour"]), p["glow"]
            for face in pt.faces(p):
                for k in range(1, len(face) - 1):
                    tris.append((face[0], face[k], face[k + 1]))
                    colours.append(base)
                    glows.append(glow)
        if not tris:
            return
        n = len(tris)
        self.p.append(np.array(tris, np.float32))
        self.uv.append(np.zeros((n, 3, 2), np.float32))
        self.tex.append(np.full(n, -1, np.int32))
        self.colour.append(np.array(colours, np.float32))
        self.glow.append(np.array(glows, np.float32))
        self.cull.append(np.zeros(n, bool))

    def stacked(self):
        return tuple(np.concatenate(v) for v in (self.p, self.uv, self.tex, self.colour, self.glow, self.cull))


def _clip(tri, uv):
    """A triangle in the camera's frame cut at the near plane, with its picture's places: a fan of triangles."""
    poly = []
    for i in range(3):
        a, b, ua, ub = tri[i], tri[(i + 1) % 3], uv[i], uv[(i + 1) % 3]
        if a[2] >= NEAR:
            poly.append((a, ua))
        if (a[2] >= NEAR) != (b[2] >= NEAR):
            t = (NEAR - a[2]) / (b[2] - a[2])
            poly.append((a + (b - a) * t, ua + (ub - ua) * t))
    return [(np.array([poly[0][0], poly[k][0], poly[k + 1][0]]), np.array([poly[0][1], poly[k][1], poly[k + 1][1]]))
            for k in range(1, len(poly) - 1)]


def draw(scene, lights, eye, target, size=SIZE, over=OVER, haze=1.0, beams=(), rim=None, sun=1.0):
    """The picture. `scene` is a Scene, or plain parts. `beams` are lines of light laid over it, each a dict of `points`
    (across, along, up), `colour`, `width` in studs and `power`. `rim` is a back light's colour and strength."""
    if not isinstance(scene, Scene):
        plain = Scene()
        plain.parts(scene)
        scene = plain
    wide, high = size[0] * over, size[1] * over
    eye, target = np.asarray(eye, float), np.asarray(target, float)
    fwd = pt.unit(target - eye)
    right = pt.unit(np.cross(fwd, pt.UP))
    up = np.cross(right, fwd)
    cam = np.stack((right, up, fwd)).astype(np.float32)
    focal = (high / 2) / math.tan(math.radians(FOV) / 2)
    P, UV, TEX, COL, GLOW, CULL = scene.stacked()
    normals = np.cross(P[:, 1] - P[:, 0], P[:, 2] - P[:, 0])
    length = np.linalg.norm(normals, axis=1)
    keep = length > 1e-9
    normals = normals / np.maximum(length, 1e-9)[:, None]
    facing = np.sum(normals * (P[:, 0] - eye.astype(np.float32)), axis=1) < 0
    keep &= facing | ~CULL
    C = (P - eye.astype(np.float32)) @ cam.T                                     # every corner in the camera's frame
    keep &= (C[..., 2] >= NEAR).any(axis=1)
    index = np.nonzero(keep)[0]
    C, uvs = C[index], UV[index]
    cut = (C[..., 2] < NEAR).any(axis=1)
    tri_c, tri_uv, tri_id = [C[~cut]], [uvs[~cut]], [index[~cut]]
    for k in np.nonzero(cut)[0]:
        for c, t in _clip(C[k], uvs[k]):
            tri_c.append(c[None].astype(np.float32))
            tri_uv.append(t[None].astype(np.float32))
            tri_id.append(index[k:k + 1])
    C, uvs, ids = np.concatenate(tri_c), np.concatenate(tri_uv), np.concatenate(tri_id)
    iz = 1.0 / C[..., 2]
    sx, sy = wide / 2 + C[..., 0] * iz * focal, high / 2 - C[..., 1] * iz * focal
    on = (sx.max(1) >= 0) & (sx.min(1) <= wide) & (sy.max(1) >= 0) & (sy.min(1) <= high)
    sx, sy, iz, uvs, ids = sx[on], sy[on], iz[on], uvs[on], ids[on]
    near_z = np.zeros((high, wide), np.float32)                                  # 1 / depth: larger is nearer
    owner = np.full((high, wide), -1, np.int32)
    U, V = np.zeros((high, wide), np.float32), np.zeros((high, wide), np.float32)
    xs, ys = np.arange(wide, dtype=np.float32) + 0.5, np.arange(high, dtype=np.float32) + 0.5
    uoz, voz = uvs[..., 0] * iz, uvs[..., 1] * iz
    rows = zip(sx.tolist(), sy.tolist(), iz.tolist(), uoz.tolist(), voz.tolist(), ids.tolist())
    for (ax, bx, cx), (ay, by, cy), (ia, ib, ic), (ua, ub, uc), (va, vb, vc), who in rows:
        x0, x1 = max(int(min(ax, bx, cx)), 0), min(int(max(ax, bx, cx)) + 1, wide - 1)
        y0, y1 = max(int(min(ay, by, cy)), 0), min(int(max(ay, by, cy)) + 1, high - 1)
        if x1 < x0 or y1 < y0:
            continue
        area = (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)
        if abs(area) < 1e-9:
            continue
        px, py = xs[None, x0:x1 + 1], ys[y0:y1 + 1, None]
        w0 = ((bx - px) * (cy - py) - (by - py) * (cx - px)) / area
        w1 = ((cx - px) * (ay - py) - (cy - py) * (ax - px)) / area
        w2 = 1.0 - w0 - w1
        depth = w0 * ia + w1 * ib + w2 * ic
        zone = near_z[y0:y1 + 1, x0:x1 + 1]
        hit = (w0 >= -1e-5) & (w1 >= -1e-5) & (w2 >= -1e-5) & (depth > zone)
        if not hit.any():
            continue
        zone[hit] = depth[hit]
        owner[y0:y1 + 1, x0:x1 + 1][hit] = who
        if TEX[who] >= 0:
            U[y0:y1 + 1, x0:x1 + 1][hit] = ((w0 * ua + w1 * ub + w2 * uc) / depth)[hit]
            V[y0:y1 + 1, x0:x1 + 1][hit] = ((w0 * va + w1 * vb + w2 * vc) / depth)[hit]
    right, up, fwd = cam
    stops = np.array([s for s, _ in SKY])
    tones = np.array([rgb(c) for _, c in SKY])
    amb, sun_tone = (rgb(AMBIENT[0]) * AMBIENT[1]).astype(np.float32), (rgb(SUN[0]) * SUN[1] * sun).astype(np.float32)
    sun_from, fog_tone = pt.unit(SUN_FROM).astype(np.float32), rgb(FOG).astype(np.float32)
    image, shine = np.zeros((high, wide, 3), np.float32), np.zeros((high, wide, 3), np.float32)
    px = (xs - wide / 2) / focal
    for y0 in range(0, high, 120):                                   # in strips, so a picture stays small in memory
        rows = slice(y0, min(y0 + 120, high))
        py = (high / 2 - ys[rows]) / focal
        rays = px[None, :, None] * right + py[:, None, None] * up + fwd          # every pixel's ray, and where it lands
        seen = owner[rows] >= 0
        depth = np.where(seen, 1.0 / np.maximum(near_z[rows], 1e-6), 0.0).astype(np.float32)
        spot = eye.astype(np.float32) + rays * depth[..., None]
        reach = np.linalg.norm(rays, axis=2)
        span, looks = reach * depth, rays / reach[..., None]
        sky = np.stack([np.interp(looks[..., 2], stops, tones[:, c]) for c in range(3)], axis=2)
        who = np.where(seen, owner[rows], 0)
        base, normal, glow, worn = COL[who], normals[who], GLOW[who][..., None], TEX[who]
        for k in np.unique(worn):
            if k < 0:
                continue
            colour, mask = scene.pictures[k]
            at = seen & (worn == k)
            iy = np.clip((V[rows][at] % 1.0 * colour.shape[0]).astype(np.int32), 0, colour.shape[0] - 1)
            ix = np.clip((U[rows][at] % 1.0 * colour.shape[1]).astype(np.int32), 0, colour.shape[1] - 1)
            base[at] = colour[iy, ix]
            glow[at] = mask[iy, ix][:, None]
        toward = -np.sum(normal * looks, axis=2, keepdims=True)
        normal = normal * np.sign(toward)                                         # toward the eye
        toward = np.abs(toward)
        light = amb * (0.75 + 0.25 * normal[..., 2:3]) + sun_tone * np.maximum(np.sum(normal * sun_from, axis=2, keepdims=True), 0.0)
        for lamp in lights:
            to = np.array(lamp["at"], np.float32) - spot
            far = np.linalg.norm(to, axis=2, keepdims=True)
            fall = np.maximum(1.0 - far / lamp["reach"], 0.0) ** 2
            face = np.maximum(np.sum(normal * to, axis=2, keepdims=True) / np.maximum(far, 1e-6), 0.0)
            light = light + rgb(lamp["colour"]).astype(np.float32) * lamp["power"] * fall * (0.25 + 0.75 * face)
        if rim:
            light = light + rgb(rim[0]).astype(np.float32) * rim[1] * (1.0 - toward) ** 3 * (0.4 + 0.6 * np.maximum(normal[..., 2:3], 0.0))
        emit = base * glow * 1.6
        lit = base * light * 2.2 * (1.0 - np.minimum(glow, 1.0)) + emit
        fog = 1.0 - np.exp(-HAZE * haze * span)[..., None]
        image[rows] = np.where(seen[..., None], lit * (1.0 - fog) + emit * fog * 0.55 + fog_tone * fog, sky)
        shine[rows] = np.where(seen[..., None], emit * (1.0 - fog * 0.45), 0.0)
    eye32 = eye.astype(np.float32)
    for beam in beams:                                               # lines of light, over the picture and behind what hides them
        tone, power, width = rgb(beam["colour"]).astype(np.float32), beam["power"], beam["width"]
        core = tone * 0.25 + 0.75
        pts = (np.array(beam["points"], np.float32) - eye32) @ cam.T
        if len(pts) == 1:
            pts = np.concatenate((pts, pts))
        for a, b in zip(pts[:-1], pts[1:]):
            if a[2] < NEAR and b[2] < NEAR:
                continue
            if a[2] < NEAR:
                a = a + (b - a) * (NEAR - a[2]) / (b[2] - a[2])
            if b[2] < NEAR:
                b = b + (a - b) * (NEAR - b[2]) / (a[2] - b[2])
            ax, ay, bx, by = (wide / 2 + a[0] / a[2] * focal, high / 2 - a[1] / a[2] * focal,
                              wide / 2 + b[0] / b[2] * focal, high / 2 - b[1] / b[2] * focal)
            ia, ib = 1.0 / a[2], 1.0 / b[2]
            w = max(width * focal * max(ia, ib), 0.55 * over)
            pad = int(4.5 * w) + 2
            x0, x1 = max(int(min(ax, bx)) - pad, 0), min(int(max(ax, bx)) + pad, wide - 1)
            y0, y1 = max(int(min(ay, by)) - pad, 0), min(int(max(ay, by)) + pad, high - 1)
            if x1 < x0 or y1 < y0:
                continue
            gx, gy = xs[None, x0:x1 + 1], ys[y0:y1 + 1, None]
            run = (bx - ax) ** 2 + (by - ay) ** 2
            t = np.clip(((gx - ax) * (bx - ax) + (gy - ay) * (by - ay)) / run, 0.0, 1.0) if run > 1e-9 else np.zeros_like(gx + gy)
            d2 = (gx - ax - t * (bx - ax)) ** 2 + (gy - ay - t * (by - ay)) ** 2
            shown = (ia + (ib - ia) * t) >= near_z[y0:y1 + 1, x0:x1 + 1] * 0.985
            veil = math.exp(-HAZE * haze / max(ia, ib) * 0.5)
            add = (np.exp(-d2 / w ** 2)[..., None] * core + 0.3 * np.exp(-d2 / (3.2 * w) ** 2)[..., None] * tone) * (shown * power * veil)[..., None]
            image[y0:y1 + 1, x0:x1 + 1] += add
            shine[y0:y1 + 1, x0:x1 + 1] += add
    for sigma, gain in ((3.0 * over, 0.45), (11.0 * over, 0.35)):
        image = image + gain * np.stack([gaussian_filter(shine[..., c], sigma) for c in range(3)], axis=2)
    image = image.reshape(size[1], over, size[0], over, 3).mean(axis=(1, 3))
    return (np.clip(image, 0.0, 1.0) ** (1 / 2.2) * 255.0 + 0.5).astype(np.uint8)


def save(image, path: Path):
    high, wide, _ = image.shape
    rows = b"".join(b"\x00" + image[y].tobytes() for y in range(high))

    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", wide, high, 8, 2, 0, 0, 0))
                     + chunk(b"IDAT", zlib.compress(rows, 6)) + chunk(b"IEND", b""))
