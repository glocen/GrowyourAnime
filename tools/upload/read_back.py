"""Read back the moderation of assets the group uploaded, with the group's key. Read only.

The key is read from the environment by name and never printed, as in upload_asset.py. Its fence: only
GET /assets/v1/assets/<id> with a read mask, and an id is digits only. A shell call passes no tool hook.

    py tools/upload/read_back.py 105763467007985 93148687324383
    py tools/upload/read_back.py --jsonl build/scratch/faber/tr3/ids.jsonl

Prints one line a state ({"Approved": 104, "Reviewing": 4}) and every id that isn't Approved, by name when known.
"""

import json
import os
import sys
import time
import urllib.error
import urllib.request

KEY_VARIABLE = "NEXTBUTTON_OC_KEY"
BASE = "https://apis.roblox.com/assets/v1/assets/"
MASK = "?readMask=moderationResult,creationContext"
GROUP_ID = "35516567"


def state(asset: str, key: str) -> tuple[str, str]:
    request = urllib.request.Request(BASE + asset + MASK, method="GET")
    request.add_header("x-api-key", key)
    try:
        with urllib.request.urlopen(request, timeout=30) as answer:
            body = json.loads(answer.read().decode("utf-8") or "{}")
    except urllib.error.HTTPError as error:
        return f"HTTP {error.code}", ""
    creator = str(((body.get("creationContext") or {}).get("creator") or {}).get("groupId", ""))
    return (body.get("moderationResult") or {}).get("moderationState", "unknown"), creator


def main() -> None:
    args = sys.argv[1:]
    names: dict[str, str] = {}
    if args[:1] == ["--jsonl"] and len(args) == 2:
        for line in open(args[1], encoding="utf-8"):
            if line.strip():
                row = json.loads(line)
                if (row.get("result") or {}).get("ok"):
                    names[row["result"]["assetId"]] = row["name"]
        ids = list(names)
    else:
        ids = args
    if not ids or not all(i.isdigit() for i in ids):
        print(json.dumps({"ok": False, "error": "ids are digits only"}))
        sys.exit(1)
    key = os.environ.get(KEY_VARIABLE, "")
    if not key:
        print(json.dumps({"ok": False, "error": f"{KEY_VARIABLE} isn't set in this shell"}))
        sys.exit(1)
    counts: dict[str, int] = {}
    odd = []
    for asset in ids:
        found, creator = state(asset, key)
        counts[found] = counts.get(found, 0) + 1
        if found != "Approved" or creator != GROUP_ID:
            odd.append({"id": asset, "name": names.get(asset, ""), "state": found, "group": creator})
        time.sleep(0.3)
    print(json.dumps({"ok": not odd, "counts": counts, "not_approved_or_not_group": odd}))


if __name__ == "__main__":
    main()
