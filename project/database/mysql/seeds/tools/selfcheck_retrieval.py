#!/usr/bin/env python
"""数据侧自测：用最朴素的关键词匹配跑一遍 12 道题。

用途：在 Java/Python 检索服务还没实现时，先证明「题目、期望命中、排除集合、数据」
四者是自洽的——即一个最简单的检索器就能拿到期望条款，且不会误抓旧版/废止条款。

注意：这不是检索服务的验收。真实服务的分词、同义词、排序由张睿轩负责；
本脚本只做数据侧回归，防止「题目标错了」「数据缺条款」这类低级问题。

用法（仓库根目录）：
    .\\.venv\\Scripts\\python.exe .\\project\\database\\mysql\\seeds\\tools\\selfcheck_retrieval.py
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

SEEDS = Path(__file__).resolve().parent.parent
DEMO = SEEDS / "demo-policies"
REPO = SEEDS.parents[2]
CASES = REPO / "tests" / "fixtures" / "qa-cases.json"

ACTIVE_ONLY = {"ACTIVE"}
MIN_SCORE = 2.0


def cjk_grams(text: str) -> set[str]:
    text = re.sub(r"[\s，。；：、（）()「」“”\"'？?！!]", "", text)
    grams = set()
    for i in range(len(text) - 1):
        grams.add(text[i:i + 2])
    for token in re.findall(r"[A-Za-z0-9]+", text):
        grams.add(token.lower())
    return grams


def load_chunks() -> list[dict]:
    out = []
    for path in sorted(DEMO.glob("d*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        doc = data["document"]
        for ver in data["versions"]:
            if ver["status"] not in ACTIVE_ONLY:
                continue
            for chunk in ver["chunks"]:
                out.append({
                    "id": chunk["id"],
                    "title": doc["title"],
                    "version": ver["version_no"],
                    "clause_no": chunk["clause_no"],
                    "section": chunk["section_path"],
                    "content": chunk["content"],
                })
    return out


def search(question: str, chunks: list[dict], top_k: int = 3) -> list[tuple[float, dict]]:
    q = cjk_grams(question)
    scored = []
    for chunk in chunks:
        body = cjk_grams(chunk["content"] + chunk["title"] + chunk["section"])
        hit = q & body
        if not hit:
            continue
        score = len(hit) / max(1.0, len(q) ** 0.5)
        scored.append((score, chunk))
    scored.sort(key=lambda x: (-x[0], x[1]["id"]))
    return scored[:top_k]


def main() -> int:
    if not CASES.exists():
        print(f"[FAIL] 找不到题目文件 {CASES}", file=sys.stderr)
        return 1

    chunks = load_chunks()
    cases = json.loads(CASES.read_text(encoding="utf-8"))["cases"]
    print(f"数据：{len(chunks)} 条现行条款（只取 ACTIVE 版本）")
    print(f"题目：{len(cases)} 道\n")

    passed = failed = 0
    rows = []
    for case in cases:
        hits = search(case["question"], chunks)
        hit_ids = [c["id"] for _, c in hits]
        top = hits[0][0] if hits else 0.0
        expect = set(case["expected_chunk_ids"])
        exclude = set(case["excluded_chunk_ids"])

        if case["expected_mode"] == "NO_EVIDENCE":
            ok = top < MIN_SCORE
            detail = f"最高分 {top:.1f}（阈值 {MIN_SCORE}）" if not ok else f"最高分 {top:.1f}，正确判为无依据"
        else:
            missing = expect - set(hit_ids)
            polluted = exclude & set(hit_ids)
            ok = not missing and not polluted
            bits = []
            if missing:
                bits.append(f"漏命中 {sorted(missing)}")
            if polluted:
                bits.append(f"误命中 {sorted(polluted)}")
            detail = "；".join(bits) if bits else "命中全部期望条款"

        rows.append((case["id"], case["type"], "PASS" if ok else "FAIL", hit_ids, detail))
        passed += ok
        failed += not ok

    for cid, ctype, status, hit_ids, detail in rows:
        print(f"[{status}] {cid} {ctype:<13} top3={hit_ids}  {detail}")

    print(f"\n结果：{passed} 通过 / {failed} 失败（共 {len(rows)} 题）")
    print("说明：这是数据侧自测，用朴素二字词匹配，不代表真实检索服务效果。")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
