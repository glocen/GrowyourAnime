"""The yard's scripts loaded with Blender closed: stand-ins for bpy, bmesh and mathutils, enough for what is only
numbers and numpy pictures (the plan's placements, the floor's pictures). Nothing that builds a mesh works here."""
import struct, sys, types, zlib
from pathlib import Path
import numpy as np

class _Any:
    def __init__(self, *a, **k): self.a = a
    def __getattr__(self, n): return _Any()
    def __call__(self, *a, **k): return _Any()
    def __iter__(self): return iter(())
    def __mul__(self, o): return self
    __rmul__ = __add__ = __sub__ = __matmul__ = __neg__ = __truediv__ = __mul__
for name in ("bpy", "bmesh", "mathutils", "bpy_extras", "mathutils.noise", "mathutils.geometry"):
    m = types.ModuleType(name)
    m.__getattr__ = lambda n: _Any()
    sys.modules[name] = m
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "blender"))

def save(pixels, path):
    """rook_sheet.save's twin: a float picture, RGB or RGBA or grey, written as an 8-bit PNG."""
    p = np.asarray(pixels, np.float32)
    if p.ndim == 2:
        p = np.stack([p, p, p, np.ones_like(p)], axis=2)
    if p.shape[2] == 3:
        p = np.concatenate([p, np.ones_like(p[..., :1])], axis=2)
    data = (np.clip(p, 0, 1) * 255 + 0.5).astype(np.uint8)
    h, w, _ = data.shape
    rows = b"".join(b"\x00" + data[y].tobytes() for y in range(h))
    chunk = lambda k, d: struct.pack(">I", len(d)) + k + d + struct.pack(">I", zlib.crc32(k + d) & 0xFFFFFFFF)
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(rows, 6)) + chunk(b"IEND", b""))
