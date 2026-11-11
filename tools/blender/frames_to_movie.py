"""Assembles a folder of numbered PNG frames (0000.png, 0001.png, ...) into an H.264 MP4 with Blender's own FFmpeg, so
the review movies the clip scripts' video modes are made for need nothing installed beyond Blender. The fast preview
(preview.py) assembles its movies through assemble().

Run: blender.exe -b --factory-startup --python tools/blender/frames_to_movie.py -- <frames folder> <out.mp4> [fps]
(fps 30 by default: the video modes write every other frame of a 60 fps clip.)
"""

import sys
from pathlib import Path

import bpy


def assemble(folder, out, fps=30) -> Path:
    """The PNG frames in `folder`, in name order, as an H.264 MP4 at `fps`, made in a scene of its own, so the caller's
    scene is left as it was. Returns the movie's path."""
    folder, out = Path(folder).resolve(), Path(out).resolve()
    frames = sorted(folder.glob("*.png"))
    if not frames:
        raise SystemExit(f"[movie] no PNG frames in {folder}")
    scene = bpy.data.scenes.new("Movie")
    editor = scene.sequence_editor_create()
    strip = editor.strips.new_image("frames", str(frames[0]), 1, 1)
    for frame in frames[1:]:
        strip.elements.append(frame.name)
    image = bpy.data.images.load(str(frames[0]))
    width, height = image.size
    bpy.data.images.remove(image)
    render = scene.render
    render.resolution_x, render.resolution_y = width - width % 2, height - height % 2  # H.264 wants even sides
    render.resolution_percentage = 100
    render.fps, render.fps_base = fps, 1.0
    scene.frame_start, scene.frame_end = 1, len(frames)
    render.image_settings.media_type = "VIDEO"
    render.image_settings.file_format = "FFMPEG"
    render.ffmpeg.format = "MPEG4"
    render.ffmpeg.codec = "H264"
    render.ffmpeg.constant_rate_factor = "HIGH"
    render.ffmpeg.ffmpeg_preset = "GOOD"
    render.use_sequencer = True
    render.filepath = str(out)
    bpy.ops.render.render(animation=True, scene=scene.name)
    print(f"[movie] {out.name}: {len(frames)} frames at {fps} fps, {render.resolution_x}x{render.resolution_y}")
    bpy.data.scenes.remove(scene)
    return out


def main():
    args = sys.argv[sys.argv.index("--") + 1:]
    assemble(args[0], args[1], int(args[2]) if len(args) > 2 else 30)


if __name__ == "__main__":
    main()
