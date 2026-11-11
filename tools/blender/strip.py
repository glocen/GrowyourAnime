"""A contact strip of preview frames, in order. Run in Blender:
blender.exe -b --factory-startup --python strip.py -- <frames dir> <out.png> <tile w> <cols> n n n ..."""
import sys
from pathlib import Path
import bpy
import numpy as np
args = sys.argv[sys.argv.index("--") + 1:]
folder, out, width, cols = Path(args[0]).resolve(), Path(args[1]).resolve(), int(args[2]), int(args[3])
def load(path):
    image = bpy.data.images.load(str(path))
    w, h = image.size
    data = np.empty(w * h * 4, dtype=np.float32)
    image.pixels.foreach_get(data)
    bpy.data.images.remove(image)
    return data.reshape(h, w, 4)[::-1]
tiles = [load(folder / f"{int(n):04d}.png") for n in args[4:]]
h0, w0 = tiles[0].shape[:2]
height = round(h0 * width / w0)
ys = (np.arange(height) * h0 / height).astype(int)
xs = (np.arange(width) * w0 / width).astype(int)
rows = (len(tiles) + cols - 1) // cols
sheet = np.zeros((rows * height, cols * width, 4), dtype=np.float32)
for i, tile in enumerate(tiles):
    r, c = i // cols, i % cols
    sheet[r * height:(r + 1) * height, c * width:(c + 1) * width] = tile[ys][:, xs]
sheet[..., 3] = 1.0
image = bpy.data.images.new("strip", sheet.shape[1], sheet.shape[0], alpha=True)
image.pixels.foreach_set(sheet[::-1].ravel())
image.filepath_raw = str(out)
image.file_format = "PNG"
image.save()
print("[strip]", sheet.shape)
