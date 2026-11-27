"""AR62 piece 1: the passed small icons (Modulo's tools/ui/hud_icons.py, research's pass of 00:56) as one transparent image
each, for the game. Each is painted at its size on the target (page points), so its ink keeps the target's weight, inside
PAD page points of room on every side. Writes <out>/<Name>.png (PX square) and check_dark.png (each on a dark ground,
for the content check). Uploaded under the group as UIKit's Hud* images (docs/asset-log.md).

    py tools/ui/hud_icon_export.py [out]   (default build/scratch/faber/icons)
"""
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import hud_finish as hf  # noqa: E402
import hud_icons as hi  # noqa: E402
import style_frames as sf  # noqa: E402

OUT = ROOT / "build" / "scratch" / "faber" / "icons"
PAD = 2.0    # page points of room round each icon: its ink stands 1.6 outside
PX = 128
ICONS = [    # (name, painter, size on the target in page points, hue): hud_finish's calls
    ("HudEye", hi.eye, 17, None),
    ("HudAutoOn", hi.auto, 17, "#FFC63C"),
    ("HudAutoOff", hi.auto, 17, "#AEB9C9"),
    ("HudSkull", hi.skull, 14.5, None),
    ("HudGemRed", hi.gem, 12.5, hf.GEM_RED),
    ("HudClassWarrior", hi.sword, 11.5, None),
]


def shoot(svg: str, out: Path, w: int, h: int, ground: str = "transparent"):
    page = (f'<!doctype html><html><head><meta charset="utf-8"><style>html,body{{margin:0;background:{ground}}}'
            f' svg{{display:block}}</style></head><body>{svg}</body></html>')
    with tempfile.TemporaryDirectory() as tmp:
        f = Path(tmp) / "page.html"
        f.write_text(page, encoding="utf-8")
        subprocess.run([sf.CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--default-background-color=00000000",
                        "--force-device-scale-factor=1", f"--user-data-dir={Path(tmp) / 'profile'}",
                        f"--window-size={w},{h}", "--virtual-time-budget=2000", f"--screenshot={out}", f.as_uri()],
                       check=True, capture_output=True, timeout=120)


def icon_svg(paint, size, hue, px):
    P = hf.Page(hf.TAKES["F2"])
    paint(P, PAD, PAD, size, hue)
    w = size + 2 * PAD
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{px}" height="{px}" viewBox="0 0 {w} {w}">'
            f'<defs>{"".join(P.defs)}</defs>{"".join(P.parts)}</svg>')


def main():
    global OUT
    if len(sys.argv) > 1:
        OUT = Path(sys.argv[1]).resolve()
    OUT.mkdir(parents=True, exist_ok=True)
    for name, paint, size, hue in ICONS:
        shoot(icon_svg(paint, size, hue, PX), OUT / f"{name}.png", PX, PX)
        print("drew", name)
    # the check sheet: the single exports on a dark ground (inline SVGs would share their gradients' ids)
    names = [n for n, *_ in ICONS]
    ins = sum((["-i", str(OUT / f"{n}.png")] for n in names), [])
    chain, last = [], "0"
    for i in range(len(names)):
        tag = "out" if i == len(names) - 1 else f"s{i}"
        chain.append(f"[{last}][{i + 1}]overlay={6 + i * (PX + 4)}:6[{tag}]")
        last = tag
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "lavfi", "-i", f"color=c=0x151A26:s={len(names) * (PX + 4) + 8}x{PX + 12}",
                    *ins, "-filter_complex", ";".join(chain), "-map", "[out]", "-frames:v", "1", str(OUT / "check_dark.png")], check=True)
    print("drew check_dark")


if __name__ == "__main__":
    main()
