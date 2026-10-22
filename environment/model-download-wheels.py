"""Fetch large CPU-model dependencies from official PyPI with resumable ranges."""
from __future__ import annotations

import concurrent.futures
import hashlib
import json
from pathlib import Path
import threading
import time
import urllib.parse
import urllib.request

from packaging.tags import sys_tags
from packaging.utils import parse_wheel_filename

ROOT = Path(__file__).resolve().parents[1]
DESTINATION = ROOT / ".local" / "model-wheels"
PACKAGES = {"scipy": "1.17.1", "numpy": "2.4.6", "transformers": "5.20.2",
            "scikit-learn": "1.9.1", "sympy": "1.14.0", "hf-xet": "1.7.0", "tokenizers": "0.23.3"}
CHUNK = 1024 * 1024
TAGS = {tag: index for index, tag in enumerate(sys_tags())}
PRINT_LOCK = threading.Lock()


def log(message):
    with PRINT_LOCK:
        print(message, flush=True)


def digest(path):
    hasher = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            hasher.update(block)
    return hasher.hexdigest()


def metadata(name, version):
    for attempt in range(8):
        try:
            request = urllib.request.Request(f"https://pypi.org/pypi/{name}/{version}/json", headers={"User-Agent": "campus-rag-model-setup/1.0"})
            with urllib.request.urlopen(request, timeout=60) as response:
                data = json.load(response)
            break
        except Exception as error:
            log(f"Metadata retry {attempt + 1}/8 {name}: {error}")
            if attempt == 7:
                raise
            time.sleep(min(1 + attempt, 5))
    candidates = []
    for item in data["urls"]:
        if item["filename"].endswith(".whl"):
            tags = parse_wheel_filename(item["filename"])[3]
            scores = [TAGS[tag] for tag in tags if tag in TAGS]
            if scores:
                candidates.append((min(scores), item))
    item = min(candidates, key=lambda candidate: candidate[0])[1]
    if urllib.parse.urlparse(item["url"]).hostname != "files.pythonhosted.org":
        raise RuntimeError("Expected the official PyPI file host")
    return item


def download_part(item, index):
    start = index * CHUNK
    end = min(start + CHUNK, item["size"]) - 1
    folder = DESTINATION / (item["filename"] + ".parts")
    folder.mkdir(parents=True, exist_ok=True)
    output = folder / f"part-{index:04d}"
    wanted = end - start + 1
    if output.exists() and output.stat().st_size == wanted:
        return
    for attempt in range(6):
        try:
            request = urllib.request.Request(item["url"], headers={"Range": f"bytes={start}-{end}", "User-Agent": "campus-rag-model-setup/1.0"})
            with urllib.request.urlopen(request, timeout=90) as response:
                if response.status != 206 or response.headers.get("Content-Range", "").split("/")[0] != f"bytes {start}-{end}":
                    raise RuntimeError("The official wheel host did not honor the byte range")
                partial = output.with_suffix(".partial")
                with partial.open("wb") as stream:
                    for block in iter(lambda: response.read(128 * 1024), b""):
                        stream.write(block)
            if partial.stat().st_size != wanted:
                raise RuntimeError("Incomplete wheel range")
            partial.replace(output)
            return
        except Exception as error:
            log(f"Retry {attempt + 1}/6 {item['filename']} part {index}: {error}")
            if attempt == 5:
                raise
            time.sleep(1 + attempt)


if __name__ == "__main__":
    DESTINATION.mkdir(parents=True, exist_ok=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=7) as pool:
        items = list(pool.map(lambda pair: metadata(*pair), PACKAGES.items()))
    pending = []
    for item in items:
        path = DESTINATION / item["filename"]
        if path.exists() and path.stat().st_size == item["size"] and digest(path) == item["digests"]["sha256"]:
            log(f"Already verified: {path.name}")
        else:
            pending.append(item)
    with concurrent.futures.ThreadPoolExecutor(max_workers=24) as pool:
        futures = {pool.submit(download_part, item, index): (item, index)
                   for item in pending for index in range((item["size"] + CHUNK - 1) // CHUNK)}
        complete = 0
        for future in concurrent.futures.as_completed(futures):
            future.result()
            complete += 1
            log(f"Wheel ranges complete: {complete}/{len(futures)}")
    for item in pending:
        path = DESTINATION / item["filename"]
        folder = DESTINATION / (item["filename"] + ".parts")
        partial = path.with_suffix(".whl.partial")
        with partial.open("wb") as output:
            for index in range((item["size"] + CHUNK - 1) // CHUNK):
                with (folder / f"part-{index:04d}").open("rb") as part:
                    for block in iter(lambda: part.read(128 * 1024), b""):
                        output.write(block)
        if partial.stat().st_size != item["size"] or digest(partial) != item["digests"]["sha256"]:
            raise RuntimeError(f"PyPI SHA256 verification failed: {path.name}")
        partial.replace(path)
        log(f"Verified official wheel: {path.name} ({item['size']} bytes)")
    (DESTINATION / "pypi-download-record.json").write_text(json.dumps(items, indent=2), encoding="utf-8")
    log("All official PyPI wheel downloads passed SHA256 verification.")
