"""Resume the official Ollama model download without deleting partial blobs."""
import json
from pathlib import Path
import time
import urllib.request

MODEL = "qwen3:1.7b"
EXPECTED_DIGEST = "8f68893c685c3ddff2aa3fffce2aa60a30bb2da65ca488b61fff134a4d1730e7"
request = urllib.request.Request(
    "http://127.0.0.1:11434/api/pull",
    data=json.dumps({"model": MODEL, "stream": True}).encode(),
    headers={"Content-Type": "application/json"},
)
last_status = None
last_print = 0
with urllib.request.urlopen(request, timeout=900) as response:
    for line in response:
        event = json.loads(line)
        if event.get("error"):
            raise RuntimeError(event["error"])
        status = event.get("status")
        if status != last_status or time.monotonic() - last_print > 10:
            print(json.dumps(event), flush=True)
            last_status = status
            last_print = time.monotonic()
        if status == "success":
            print(f"COMPLETE: {MODEL}", flush=True)

with urllib.request.urlopen("http://127.0.0.1:11434/api/tags", timeout=15) as response:
    tag = next(model for model in json.load(response)["models"] if model["name"] == MODEL)
if tag.get("digest") != EXPECTED_DIGEST:
    raise RuntimeError("The official Ollama tag changed. Review the new model before updating the pinned digest.")
root = Path(__file__).resolve().parents[1]
record = {"source": "https://ollama.com/library/" + MODEL, "tag": tag,
          "expected_digest": EXPECTED_DIGEST,
          "model_cache": str(root / ".local" / "ollama-models"),
          "runtime_options": {"num_ctx": 2048, "num_thread": 4, "keep_alive": 0, "think": False}}
record_path = root / ".local" / "models" / "ollama-qwen3-1.7b.json"
record_path.parent.mkdir(parents=True, exist_ok=True)
record_path.write_text(json.dumps(record, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"Model provenance: {record_path}", flush=True)
