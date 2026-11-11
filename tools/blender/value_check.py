"""The value check of frames: grayscale, 3 tones (dark below 0.15, light from 0.5), a 64 px thumbnail. Run in Blender: value_check.py -- <out.png> <frame.png> ..."""
import sys
from pathlib import Path
import bpy
import numpy as np
args = sys.argv[sys.argv.index("--") + 1:]
out = Path(args[0]).resolve()
LUMA = np.array([0.2126, 0.7152, 0.0722])
def load(path):
    image = bpy.data.images.load(str(Path(path).resolve()))
    w, h = image.size
    data = np.empty(w * h * 4, dtype=np.float32)
    image.pixels.foreach_get(data)
    bpy.data.images.remove(image)
    return data.reshape(h, w, 4)[::-1]
rows = []
for path in args[1:]:
    rgba = load(path)
    h, w = rgba.shape[:2]
    y0, y1 = h // 5, h
    crop = rgba[y0:y1, :, :3]
    grey = crop @ LUMA
    tones = np.where(grey < 0.15, 0.05, np.where(grey < 0.5, 0.35, 0.95))
    small = 64
    sy = (np.arange(small) * grey.shape[0] / small).astype(int)
    sx = (np.arange(round(small * grey.shape[1] / grey.shape[0])) * grey.shape[0] / small).astype(int)
    thumb = crop[sy][:, sx]
    up = np.kron(thumb, np.ones((3, 3, 1)))
    pad = np.zeros((crop.shape[0], up.shape[1], 3))
    pad[:min(up.shape[0], pad.shape[0]), :, :] = up[:pad.shape[0]]
    rows.append(np.concatenate([crop, np.dstack([grey] * 3), np.dstack([tones] * 3), pad], axis=1))
sheet = np.concatenate(rows, axis=0)
sheet = np.dstack([sheet, np.ones(sheet.shape[:2])]).astype(np.float32)
image = bpy.data.images.new("value", sheet.shape[1], sheet.shape[0], alpha=True)
image.pixels.foreach_set(sheet[::-1].ravel())
image.filepath_raw = str(out)
image.file_format = "PNG"
image.save()
print("[value]", sheet.shape)
