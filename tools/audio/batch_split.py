"""A Studio shortlist batch written out, one <brief>.json a brief (tools/studio/Audio/Batch.luau; AR39).

Batch.Part(i) answers with part i of the batch's text between markers, padded past what one MCP answer keeps, so the
MCP host keeps each answer in a file (tool-results/: its MCP content, or the text alone). This joins those files' parts in order, checks every part is
there, and writes each brief's file, as Batch made it, into the folder given. Numbers only: a batch holds no audio.

    py tools/audio/batch_split.py <out folder> <answer file> [<answer file> ...]
"""
import json
import re
import sys
from pathlib import Path

MARK = re.compile(r"<<NL_BATCH (\d+)/(\d+)>>(.*?)<<NL_END>>", re.S)


def main(argv):
    if len(argv) < 3:
        raise SystemExit(__doc__)
    out = Path(argv[1])
    parts, counts = {}, set()
    for name in argv[2:]:
        raw = Path(name).read_text(encoding="utf-8")
        try:  # the host keeps an answer as its MCP content, [{"type": "text", "text": ...}], or as the text itself
            raw = "".join(item.get("text", "") for item in json.loads(raw) if isinstance(item, dict))
        except (ValueError, TypeError, AttributeError):
            pass
        for index, count, body in MARK.findall(raw):
            parts[int(index)] = body
            counts.add(int(count))
    if len(counts) != 1:
        raise SystemExit(f"the parts disagree on how many there are: {sorted(counts)}")
    count = counts.pop()
    missing = [i for i in range(1, count + 1) if i not in parts]
    if missing:
        raise SystemExit(f"parts missing: {missing} of {count}")
    batch = json.loads("".join(parts[i] for i in range(1, count + 1)))
    out.mkdir(parents=True, exist_ok=True)
    for brief, file in batch.items():
        picks = file.get("Picks", [])
        failed = [p.get("Id") for p in picks if "Error" in p]
        (out / f"{brief}.json").write_text(json.dumps(file, ensure_ascii=False), encoding="utf-8")
        print(f"{brief}: {file.get('State')}, {len(picks)} picks, {len(picks) - len(failed)} measured"
              + (f", unmeasured {failed}" if failed else ""))


if __name__ == "__main__":
    main(sys.argv)
