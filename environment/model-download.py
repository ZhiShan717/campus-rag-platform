"""Download pinned BAAI model files from their official Hugging Face repositories."""
from __future__ import annotations

import concurrent.futures
import hashlib
import json
import time
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODELS = ROOT / ".local" / "models"
REPOS = {
    "BAAI/bge-large-zh-v1.5": {"weight": "pytorch_model.bin", "dimensions": 1024,
                                "revision": "79e7739b6ab944e86d6171e44d24c997fc1e0116"},
    "BAAI/bge-reranker-base": {"weight": "model.safetensors", "dimensions": None,
                               "revision": "2cfc18c9415c912f9d8155881c133215df768a70"},
}


def get_json(url):
    with urllib.request.urlopen(url, timeout=60) as response:
        return json.load(response)


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(8 * 1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def download_file(repo, revision, info, target):
    filename = info["rfilename"]
    destination = target / filename
    destination.parent.mkdir(parents=True, exist_ok=True)
    expected_size = info["size"]
    expected_hash = info.get("lfs", {}).get("sha256")
    if destination.exists() and destination.stat().st_size == expected_size:
        if not expected_hash or sha256(destination) == expected_hash:
            print(f"Already verified: {repo}/{filename}", flush=True)
            return
    partial = destination.with_name(destination.name + ".partial")
    if partial.exists() and partial.stat().st_size == expected_size:
        if not expected_hash or sha256(partial) == expected_hash:
            partial.replace(destination)
            print(f"Verified complete partial: {repo}/{filename}", flush=True)
            return
        # Retain a corrupt completed download for inspection and fetch a fresh copy.
        partial.replace(partial.with_name(partial.name + f".corrupt-{time.time_ns()}"))
    for attempt in range(1, 9):
        offset = partial.stat().st_size if partial.exists() else 0
        # Cache-busting applies to the pinned revision; avoids stale signed CDN redirects.
        url = (
            f"https://huggingface.co/{repo}/resolve/{revision}/"
            f"{urllib.parse.quote(filename, safe='/')}?download=true&attempt={time.time_ns()}"
        )
        headers = {"User-Agent": "campus-rag-model-setup/1.0"}
        if offset:
            headers["Range"] = f"bytes={offset}-"
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=90) as response:
                resumed = offset and response.status == 206
                if not resumed:
                    offset = 0
                done = offset
                last_report = time.monotonic()
                with partial.open("ab" if resumed else "wb") as output:
                    while block := response.read(2 * 1024 * 1024):
                        output.write(block)
                        done += len(block)
                        if time.monotonic() - last_report > 15:
                            print(f"{repo}/{filename}: {done}/{expected_size} bytes", flush=True)
                            last_report = time.monotonic()
            if partial.stat().st_size != expected_size:
                raise RuntimeError(f"Size mismatch: expected {expected_size}, got {partial.stat().st_size}")
            if expected_hash and sha256(partial) != expected_hash:
                raise RuntimeError(f"SHA256 mismatch for {repo}/{filename}")
            partial.replace(destination)
            print(f"Verified: {repo}/{filename} ({expected_size} bytes)", flush=True)
            return
        except Exception as error:
            print(f"Retry {attempt}/8 {repo}/{filename}: {error}", flush=True)
            if attempt == 8:
                raise
            time.sleep(min(attempt * 2, 15))


def download_model(repo, settings):
    target = MODELS / repo.split("/")[1]
    target.mkdir(parents=True, exist_ok=True)
    source_file = target / "source-manifest.json"
    if source_file.exists():
        metadata = json.loads(source_file.read_text(encoding="utf-8"))
    else:
        metadata = get_json(f"https://huggingface.co/api/models/{repo}/revision/{settings['revision']}?blobs=true")
        source_file.write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8")
    revision = metadata["sha"]
    if revision != settings["revision"]:
        raise RuntimeError(f"Local source manifest for {repo} differs from the pinned revision.")
    selected = [
        item for item in metadata["siblings"]
        if item["rfilename"] == settings["weight"]
        or item["rfilename"].endswith((".json", ".txt", ".model"))
        and not item["rfilename"].startswith("onnx/")
        or item["rfilename"] == "README.md"
    ]
    print(f"Downloading {repo}@{revision} to {target}", flush=True)
    # Small tokenizer/config files first; only one required weight format per model.
    for item in sorted(selected, key=lambda item: item["size"]):
        download_file(repo, revision, item, target)
    record = {
        "repo_id": repo,
        "revision": revision,
        "source": f"https://huggingface.co/{repo}/tree/{revision}",
        "local_path": str(target),
        "embedding_dimensions": settings["dimensions"],
        "files": [
            {"path": item["rfilename"], "bytes": item["size"], "sha256": sha256(target / item["rfilename"])}
            for item in selected
        ],
    }
    (target / "download-record.json").write_text(json.dumps(record, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"COMPLETE: {repo}@{revision}", flush=True)
    return record


if __name__ == "__main__":
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        futures = [pool.submit(download_model, repo, settings) for repo, settings in REPOS.items()]
        records = [future.result() for future in futures]
    (MODELS / "models-manifest.json").write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")
