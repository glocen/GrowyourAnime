"""The pair sheet: a build beside its target in one image, for a verdict in pairs (docs/test-requests.md, TR63, item 1;
AGENTS.md, "Every action, world, effect and screen"). One step after tools/capture/grab.ps1 and moments.py: give it a
frame of the build and the target's image, and it makes:

  row 1   build | target       both at the same phone height, side by side
  row 2   target | build       the order swapped, so neither is always seen first
  row 3   the squint           row 1 brought down to a thumbnail's sharpness and back up
  row 4   greyscale            row 1 without its colour: does the value alone still read?
  row 5   silhouettes          with --silhouette, each as a black shape at 64 px on white (a character, a key pose)

Run from the project root:
  py tools/capture/pairs.py <build.png> <target.png> <out.png>
  py tools/capture/pairs.py <build.png> <target.png> <out.png> --height 540 --silhouette
  py tools/capture/pairs.py <build.png> <target.png> <out.png> --silhouette --key 0x1a1a1a:0.08
  py tools/capture/pairs.py --cases           its own cases, in build/scratch/pairs-cases (wiped at the start)

--height h        the phone height both are brought to, 720 by default (a landscape phone's capture)
--thumb t         the squint's thumbnail height, 96 by default
--silhouette      add row 5: the shape from each image's alpha, or from --key where it has none
--key colour:sim  the backdrop colour to key out for a silhouette (ffmpeg colorkey's colour and similarity)

Nothing is installed: ffmpeg and ffprobe only, as moments.py uses them. The tiles carry no text, since this ffmpeg's drawtext
crashes: <out>.txt says what each row and column is. A transparent image is laid on the gutter's grey, so its
transparency reads as backdrop, not as black.
"""

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GUTTER = 6  # px of grey between the tiles and round the sheet
GREY = "0x2a2a2e"
SILHOUETTE = 64  # px, the height a shape is read at


class Refused(Exception):
    pass


def ff(*args: str) -> None:
    subprocess.run(["ffmpeg", "-hide_banner", "-nostdin", "-loglevel", "error", "-y", *args], check=True)


def probe(path: Path) -> tuple[int, int, bool]:
    """The image's width, height, and whether it carries alpha."""
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=width,height,pix_fmt", "-of", "json", str(path)],
        capture_output=True, text=True, check=True,
    ).stdout
    stream = json.loads(out)["streams"][0]
    fmt = stream.get("pix_fmt", "")
    return int(stream["width"]), int(stream["height"]), (fmt.startswith(("rgba", "bgra", "argb", "abgr", "ya", "yuva", "gbrap")))


def even(n: float) -> int:
    return max(2, int(round(n / 2)) * 2)


def sheet(build: Path, target: Path, out: Path, height: int = 720, thumb: int = 96, silhouette: bool = False, key: str | None = None) -> dict:
    for name, path in (("build", build), ("target", target)):
        if not path.is_file():
            raise Refused(f"the {name} image is missing: {path}")
    (bw, bh, ba), (tw, th, ta) = probe(build), probe(target)
    h = even(height)
    wb, wt = even(bw * h / bh), even(tw * h / th)
    q = max(8, even(thumb))
    qb, qt = even(wb * q / h), even(wt * q / h)
    g = GUTTER

    def tile(label: str) -> str:
        return f"pad=iw+{2 * g}:ih+{2 * g}:{g}:{g}:color={GREY}[{label}]"

    # each input read once: split when the shapes need it too
    graph = [f"[{i}:v]split=2[in{i}][cut{i}]" for i in (0, 1)] if silhouette else [f"[{i}:v]null[in{i}]" for i in (0, 1)]
    # each brought to the phone height and laid on the grey, so transparency reads as backdrop
    for i, (w, name) in enumerate(((wb, "b"), (wt, "t"))):
        graph.append(f"color=c={GREY}:s={w}x{h}:d=1[{name}bg]")
        graph.append(f"[in{i}]scale={w}:{h}:flags=lanczos,setsar=1,format=rgba[{name}s]")
        graph.append(f"[{name}bg][{name}s]overlay=shortest=1,format=rgb24,split=4[{name}1][{name}2][{name}3][{name}4]")
    for name in ("b", "t"):
        graph.append(f"[{name}1]{tile(name + '1p')}")
        graph.append(f"[{name}2]{tile(name + '2p')}")
    # the squint: down to the thumbnail and back up, the same size as row 1
    graph.append(f"[b3]scale={qb}:{q}:flags=area,scale={wb}:{h}:flags=bilinear,{tile('b3p')}")
    graph.append(f"[t3]scale={qt}:{q}:flags=area,scale={wt}:{h}:flags=bilinear,{tile('t3p')}")
    # greyscale, by value
    graph.append(f"[b4]hue=s=0,format=rgb24,{tile('b4p')}")
    graph.append(f"[t4]hue=s=0,format=rgb24,{tile('t4p')}")
    graph.append("[b1p][t1p]hstack=2[r1]")
    graph.append("[t2p][b2p]hstack=2[r2]")
    graph.append("[b3p][t3p]hstack=2[r3]")
    graph.append("[b4p][t4p]hstack=2[r4]")
    rows = ["[r1]", "[r2]", "[r3]", "[r4]"]
    full = wb + wt + 4 * g
    extra: list[str] = []
    if silhouette:
        for i, (has, name, path) in enumerate(((ba, "b", build), (ta, "t", target))):
            if key:
                colour, _, sim = key.partition(":")
                cut = f"format=rgba,colorkey={colour}:{sim or '0.08'}:0"
            elif has:
                cut = "format=rgba"
            else:
                raise Refused(f"a silhouette needs alpha or --key, and the {('build', 'target')[i]} image has no alpha: {path}")
            sw = even((bw, tw)[i] * SILHOUETTE / (bh, th)[i])
            # the shape black on white: its alpha, turned over
            extra.append(f"[cut{i}]{cut},scale={sw}:{SILHOUETTE}:flags=area,format=rgba,alphaextract,format=gray,negate,format=rgb24,pad=iw+{2 * g}:ih+{2 * g}:{g}:{g}:color=white[{name}5]")
        extra.append(f"[b5][t5]hstack=2,pad={full}:ih+{2 * g}:(ow-iw)/2:{g}:color={GREY}[r5]")
        rows.append("[r5]")
    graph += extra
    graph.append(f"{''.join(rows)}vstack={len(rows)},pad=iw+{2 * g}:ih+{2 * g}:{g}:{g}:color={GREY}[out]")
    out.parent.mkdir(parents=True, exist_ok=True)
    ff("-i", str(build), "-i", str(target), "-filter_complex", ";".join(graph), "-map", "[out]", "-frames:v", "1", str(out))
    tile_h = h + 2 * g
    said = [
        f"{out.name}: the build {build} beside the target {target}, at {h} px tall",
        f"row 1, y {g} to {g + tile_h}: build (left, {wb} px wide) | target (right, {wt} px)",
        f"row 2: target (left) | build (right), the order swapped",
        f"row 3: row 1 at a {q} px thumbnail's sharpness (the squint)",
        f"row 4: row 1 in greyscale",
    ]
    if silhouette:
        said.append(f"row 5: build | target as black shapes at {SILHOUETTE} px" + (f", keyed from {key}" if key else ", from their alpha"))
    out.with_suffix(".txt").write_text("\n".join(said) + "\n", encoding="utf-8")
    return {"Width": full + 2 * g, "Build": wb, "Target": wt, "Tile": tile_h}


# ---- its own cases --------------------------------------------------------------------------------------------------

def pixel(path: Path, x: int, y: int) -> tuple[int, int, int]:
    raw = subprocess.run(
        ["ffmpeg", "-hide_banner", "-nostdin", "-loglevel", "error", "-i", str(path), "-vf", f"crop=1:1:{x}:{y}", "-frames:v", "1", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
        capture_output=True, check=True,
    ).stdout
    return raw[0], raw[1], raw[2]


def cases() -> int:
    work = ROOT / "build" / "scratch" / "pairs-cases"
    shutil.rmtree(work, ignore_errors=True)
    work.mkdir(parents=True)
    passed = failed = 0

    def check(what: str, ok: bool, said: str = "") -> None:
        nonlocal passed, failed
        if ok:
            passed += 1
        else:
            failed += 1
            print(f"FAIL  {what}" + (f" ({said})" if said else ""))

    def near(a: tuple[int, int, int], b: tuple[int, int, int], by: int = 24) -> bool:
        return all(abs(x - y) <= by for x, y in zip(a, b))

    red, blue = work / "red.png", work / "blue.png"
    ff("-f", "lavfi", "-i", "color=c=0xd02020:s=320x200:d=1", "-frames:v", "1", str(red))
    ff("-f", "lavfi", "-i", "color=c=0x2040d0:s=500x500:d=1", "-frames:v", "1", str(blue))
    out = work / "sheet.png"
    sheet(red, blue, out, height=360)
    w, h, _ = probe(out)
    g, tile = GUTTER, 360 + 2 * GUTTER
    wb, wt = even(320 * 360 / 200), even(500 * 360 / 500)
    # two sizes scaled to one height
    check("two sizes, one height: the sheet's width is both at 360 px tall", w == wb + wt + 6 * g, f"{w} for {wb + wt + 6 * g}")
    check("four rows of one height", h == 4 * tile + 2 * g, f"{h} for {4 * tile + 2 * g}")
    # the order swapped: build left on row 1, target left on row 2
    row1, row2 = g + tile // 2, g + tile + tile // 2
    left, right = 2 * g + 20, 2 * g + wb + 2 * g + 20
    check("row 1: the build on the left", near(pixel(out, left, row1), (0xd0, 0x20, 0x20)), str(pixel(out, left, row1)))
    check("row 1: the target on the right", near(pixel(out, right, row1), (0x20, 0x40, 0xd0)), str(pixel(out, right, row1)))
    check("row 2: the order swapped, the target first", near(pixel(out, left, row2), (0x20, 0x40, 0xd0)), str(pixel(out, left, row2)))
    # the greyscale row has no colour
    row4 = g + 3 * tile + tile // 2
    grey = pixel(out, left, row4)
    check("row 4: greyscale", max(grey) - min(grey) <= 3, str(grey))
    check("its key says what each row is", out.with_suffix(".txt").is_file() and "order swapped" in out.with_suffix(".txt").read_text(encoding="utf-8"))
    # a missing file is named
    try:
        sheet(work / "nothing.png", blue, work / "never.png")
        check("a missing file is refused", False)
    except Refused as error:
        check("a missing file is refused, and named", "nothing.png" in str(error) and "build" in str(error), str(error))
    check("and nothing is written", not (work / "never.png").exists())
    # a silhouette from alpha: a figure on a clear ground, black on white at 64 px
    figure = work / "figure.png"
    ff("-f", "lavfi", "-i", "color=c=0x00000000:s=200x400:d=1,format=rgba,drawbox=x=60:y=40:w=80:h=320:color=0xffd040@1:t=fill:replace=1", "-frames:v", "1", str(figure))
    shaped = work / "shaped.png"
    sheet(figure, figure, shaped, height=240, silhouette=True)
    sw, sh, _ = probe(shaped)
    tile2 = 240 + 2 * g
    top5 = g + 4 * tile2 + g + g  # row 5's shapes start past its own pad and the tile's
    sx = (sw - 2 * (even(200 * 64 / 400) + 2 * g)) // 2  # the shapes' row is centred
    middle = pixel(shaped, sx + g + even(200 * 64 / 400) // 2, top5 + 32)
    edge = pixel(shaped, sx + g + 1, top5 + 32)
    check("row 5: the figure black", near(middle, (0, 0, 0), 30), str(middle))
    check("row 5: its ground white", near(edge, (255, 255, 255), 30), str(edge))
    check("five rows with the shapes", sh == 4 * tile2 + (SILHOUETTE + 4 * g) + 2 * g, f"{sh} for {4 * tile2 + SILHOUETTE + 6 * g}")
    try:
        sheet(red, blue, work / "never2.png", silhouette=True)
        check("a silhouette without alpha or a key is refused", False)
    except Refused as error:
        check("a silhouette without alpha or a key is refused, and says why", "alpha" in str(error), str(error))
    print(f"PAIRS CASES {'PASSED' if failed == 0 else 'FAILED'}: {passed} passed, {failed} failed")
    return 0 if failed == 0 else 1


def main() -> int:
    if "--cases" in sys.argv[1:]:
        return cases()
    parser = argparse.ArgumentParser(description="The pair sheet: a build beside its target (TR63).")
    parser.add_argument("build", type=Path)
    parser.add_argument("target", type=Path)
    parser.add_argument("out", type=Path)
    parser.add_argument("--height", type=int, default=720)
    parser.add_argument("--thumb", type=int, default=96)
    parser.add_argument("--silhouette", action="store_true")
    parser.add_argument("--key")
    args = parser.parse_args()
    try:
        made = sheet(args.build, args.target, args.out, args.height, args.thumb, args.silhouette, args.key)
    except Refused as error:
        print(f"refused: {error}", file=sys.stderr)
        return 2
    print(f"made {args.out} ({made['Width']} px wide), its key in {args.out.with_suffix('.txt')}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
