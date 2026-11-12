"""Upload one asset to the group through Open Cloud with the group's key, fenced like the MCP guard.

The director, 2026-11-12, for Grow your Anime: "yes it does we set up a key from the group for next button, let use it".
The key is read from the environment by name and never printed. A shell call passes no tool hook, so this script is its
own fence (handbook/platform/publishing-and-places.md, "API keys"):

- only POST /assets/v1/assets, then GET of that upload's own operation;
- only a file inside build/upload/, which a file enters after its content check's PASS;
- the creator is always the studio's group (CLAUDE.md, "Places"), and expectedPrice is always 0, so a fee fails the upload.

    py tools/upload/upload_asset.py build/upload/haymaker_bar.png Image "GA Haymaker bar" "Rook's Haymaker bar"

Prints the operation's result as JSON: the asset id, or the error. Log every upload in docs/asset-log.md.
"""

import json
import mimetypes
import os
import sys
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

KEY_VARIABLE = "NEXTBUTTON_OC_KEY"
GROUP_ID = "35516567"
BASE = "https://apis.roblox.com"
CREATE = "/assets/v1/assets"
TYPES = {"Image", "Decal", "Audio", "Animation", "Model"}
ROOT = Path(__file__).resolve().parents[2]
FOLDER = (ROOT / "build" / "upload").resolve()
POLL_EVERY = 2  # seconds between looks at the operation
POLL_FOR = 120


def fail(message: str) -> None:
    print(json.dumps({"ok": False, "error": message}))
    sys.exit(1)


def call(method: str, path: str, key: str, body: bytes | None = None, content_type: str | None = None) -> dict:
    request = urllib.request.Request(BASE + path, data=body, method=method)
    request.add_header("x-api-key", key)
    if content_type:
        request.add_header("Content-Type", content_type)
    try:
        with urllib.request.urlopen(request, timeout=60) as answer:
            return json.loads(answer.read().decode("utf-8") or "{}")
    except urllib.error.HTTPError as error:
        fail(f"{method} {path}: HTTP {error.code}: {error.read().decode('utf-8', 'replace')[:500]}")
    return {}


def main() -> None:
    if len(sys.argv) != 5:
        fail("usage: upload_asset.py <file in build/upload> <Image|Decal|Audio|Animation|Model> <display name> <description>")
    file, kind, name, description = Path(sys.argv[1]).resolve(), sys.argv[2], sys.argv[3], sys.argv[4]
    if FOLDER not in file.parents:
        fail(f"upload only from build/upload/, after the content check's PASS: {file}")
    if not file.is_file():
        fail(f"no such file: {file}")
    if kind not in TYPES:
        fail(f"asset type {kind} isn't one of {sorted(TYPES)}")
    key = os.environ.get(KEY_VARIABLE, "")
    if not key:
        fail(f"{KEY_VARIABLE} isn't set in this shell")

    request = {
        "assetType": kind,
        "displayName": name,
        "description": description,
        "creationContext": {"creator": {"groupId": GROUP_ID}, "expectedPrice": 0},
    }
    boundary = uuid.uuid4().hex
    mime = mimetypes.guess_type(file.name)[0] or "application/octet-stream"
    parts = [
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"request\"\r\nContent-Type: application/json\r\n\r\n".encode(),
        json.dumps(request).encode(),
        f"\r\n--{boundary}\r\nContent-Disposition: form-data; name=\"fileContent\"; filename=\"{file.name}\"\r\n"
        f"Content-Type: {mime}\r\n\r\n".encode(),
        file.read_bytes(),
        f"\r\n--{boundary}--\r\n".encode(),
    ]
    operation = call("POST", CREATE, key, b"".join(parts), f"multipart/form-data; boundary={boundary}")
    path = operation.get("path", "")
    if not path.startswith("operations/"):
        fail(f"no operation in the answer: {json.dumps(operation)[:500]}")
    waited = 0
    while not operation.get("done") and waited < POLL_FOR:
        time.sleep(POLL_EVERY)
        waited += POLL_EVERY
        operation = call("GET", f"/assets/v1/{path}", key)
    if not operation.get("done"):
        fail(f"{path} not done after {POLL_FOR} s")
    response = operation.get("response") or {}
    print(json.dumps({
        "ok": "assetId" in response,
        "assetId": response.get("assetId"),
        "assetType": response.get("assetType"),
        "moderation": (response.get("moderationResult") or {}).get("moderationState"),
        "creator": response.get("creationContext", {}).get("creator"),
        "error": operation.get("error"),
    }))


if __name__ == "__main__":
    main()
