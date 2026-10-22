"""Offline BAAI checks and a local Ollama smoke test; no application or ES index is created."""
from __future__ import annotations

import argparse
import importlib.metadata
import json
import math
import os
from pathlib import Path
import subprocess
import sys
import time
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
os.environ["HF_HOME"] = str(ROOT / ".local" / "huggingface-cache")
os.environ["HF_HUB_OFFLINE"] = "1"
os.environ["TRANSFORMERS_OFFLINE"] = "1"
os.environ["TOKENIZERS_PARALLELISM"] = "false"
os.environ["HF_HUB_DISABLE_SYMLINKS_WARNING"] = "1"
MODEL_NAME = "qwen3:1.7b"
EXPECTED_OLLAMA_DIGEST = "8f68893c685c3ddff2aa3fffce2aa60a30bb2da65ca488b61fff134a4d1730e7"
QUERY = "国家奖学金申请材料需要提交什么？"
PASSAGES = [
    "国家奖学金申请人应提交申请表、成绩单和获奖证明，由所在学院审核。",
    "校园食堂早餐供应时间为早晨七点到九点，提供豆浆和包子。",
]


def request_json(endpoint, body=None, timeout=180):
    data = json.dumps(body, ensure_ascii=False).encode("utf-8") if body is not None else None
    request = urllib.request.Request(
        "http://127.0.0.1:11434" + endpoint,
        data=data,
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.load(response)


def embedding():
    import torch
    from sentence_transformers import SentenceTransformer

    torch.set_num_threads(4)
    path = ROOT / ".local" / "models" / "bge-large-zh-v1.5"
    model = SentenceTransformer(str(path), device="cpu", local_files_only=True)
    texts = ["为这个句子生成表示以用于检索相关文章：" + QUERY] + PASSAGES
    vectors = model.encode(texts, batch_size=1, normalize_embeddings=True, show_progress_bar=False)
    scores = (vectors[0] @ vectors[1:].T).tolist()
    norms = [float(math.sqrt(float(vector @ vector))) for vector in vectors]
    assert vectors.shape == (3, 1024), f"Unexpected shape: {vectors.shape}"
    assert all(abs(norm - 1.0) < 0.001 for norm in norms), f"Vectors not normalized: {norms}"
    assert all(math.isfinite(float(value)) for row in vectors for value in row)
    assert scores[0] > scores[1], f"Relevant passage must score higher: {scores}"
    return {"model": "BAAI/bge-large-zh-v1.5", "path": str(path), "device": "cpu", "dimensions": 1024,
            "shape": list(vectors.shape), "l2_norms": norms, "relevant_irrelevant_scores": scores,
            "offline": True, "status": "passed"}


def reranker():
    import torch
    from sentence_transformers import CrossEncoder

    torch.set_num_threads(4)
    path = ROOT / ".local" / "models" / "bge-reranker-base"
    model = CrossEncoder(str(path), device="cpu", max_length=256, local_files_only=True)
    scores = model.predict([[QUERY, passage] for passage in PASSAGES], batch_size=1, show_progress_bar=False).tolist()
    assert len(scores) == 2 and all(math.isfinite(score) for score in scores)
    assert scores[0] > scores[1], f"Relevant passage must rank first: {scores}"
    return {"model": "BAAI/bge-reranker-base", "path": str(path), "device": "cpu", "max_length": 256,
            "batch_size": 1, "relevant_irrelevant_scores": scores, "offline": True, "status": "passed"}


def generation():
    tag = next(model for model in request_json("/api/tags")["models"] if model["name"] == MODEL_NAME)
    assert tag.get("digest") == EXPECTED_OLLAMA_DIGEST, "The Ollama model differs from the verified digest"
    request = {
        "model": MODEL_NAME, "stream": False, "think": False, "keep_alive": 0,
        "options": {"num_ctx": 2048, "num_predict": 120, "temperature": 0, "num_thread": 4},
        "messages": [
            {"role": "system", "content": "请仅根据给定的测试材料，用一句简短的中文回答问题，并在末尾保留材料引用[C:1]。"},
            {"role": "user", "content": "测试材料[C:1]：国家奖学金申请材料包括申请表、成绩单和获奖证明。问题：需要提交哪些材料？"},
        ],
    }
    result = request_json("/api/chat", request, timeout=300)
    answer = result.get("message", {}).get("content", "")
    assert result.get("done") and answer.strip(), "Generation returned no answer"
    assert "申请表" in answer and "成绩单" in answer and "获奖证明" in answer and "[C:1]" in answer, answer
    for _ in range(20):
        loaded = request_json("/api/ps").get("models", [])
        if not any(model["name"].startswith(MODEL_NAME) for model in loaded):
            break
        time.sleep(0.5)
    else:
        raise AssertionError("keep_alive=0 did not unload the generated model")
    return {"model": MODEL_NAME, "endpoint": "http://127.0.0.1:11434/api/chat", "keep_alive": 0,
            "digest": EXPECTED_OLLAMA_DIGEST,
            "num_ctx": 2048, "num_thread": 4, "answer": answer,
            "prompt_eval_count": result.get("prompt_eval_count"), "eval_count": result.get("eval_count"),
            "total_seconds": result.get("total_duration", 0) / 1e9, "unloaded_after_test": True,
            "note": "Synthetic model smoke test; this does not validate the project RAG or live policy data.", "status": "passed"}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--component", choices=["embedding", "reranker", "generation"])
    args = parser.parse_args()
    if args.component:
        started = time.monotonic()
        result = globals()[args.component]()
        result["elapsed_seconds"] = round(time.monotonic() - started, 3)
        print("MODEL_RESULT=" + json.dumps(result, ensure_ascii=False), flush=True)
    else:
        report = {"checked_at": time.strftime("%Y-%m-%dT%H:%M:%S%z"), "python": sys.version,
                  "packages": {package: importlib.metadata.version(package) for package in ["torch", "transformers", "sentence-transformers"]}}
        # Separate processes release CPU model weights before the next component.
        for component in ["embedding", "reranker", "generation"]:
            print(f"Checking {component}...", flush=True)
            child = subprocess.run([sys.executable, str(Path(__file__).resolve()), "--component", component],
                                   encoding="utf-8", errors="replace", capture_output=True, timeout=600)
            print(child.stdout, end="", flush=True)
            if child.stderr:
                print(child.stderr, file=sys.stderr, end="", flush=True)
            if child.returncode:
                raise RuntimeError(f"{component} failed with exit code {child.returncode}")
            line = next(line for line in child.stdout.splitlines() if line.startswith("MODEL_RESULT="))
            report[component] = json.loads(line.removeprefix("MODEL_RESULT="))
        report["status"] = "passed"
        output = ROOT / ".setup" / "logs" / "models-verification.json"
        output.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"All model checks passed. Report: {output}", flush=True)
