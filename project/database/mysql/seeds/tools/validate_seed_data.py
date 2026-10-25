#!/usr/bin/env python
"""制度演示数据自检。

用法（仓库根目录）：
    .\\.venv\\Scripts\\python.exe .\\project\\database\\mysql\\seeds\\tools\\validate_seed_data.py

检查项：
1. 结构：document / versions / chunks 必要字段齐全；
2. 编号：document_id、version_id、chunk_id 全局唯一；
3. 外键：version.document_id、chunk.version_id 能解析；
4. 状态：四种状态齐全；SUPERSEDED 必须有 replaced_by 且指向同制度版本；ABOLISHED 必须有 expiry_date；
5. 日期：published_date <= effective_date；expiry_date >= effective_date；PENDING 的生效日晚于整理日；
6. 覆盖：每个 document 最多一个 ACTIVE；
7. 汇总：_index.json 与实际数据一致。

退出码：全部通过 0，有失败 1。
"""

from __future__ import annotations

import json
import re
import sys
from collections import Counter
from datetime import date
from pathlib import Path

SEEDS = Path(__file__).resolve().parent.parent
DEMO = SEEDS / "demo-policies"
DATASET_DATE = date(2026, 10, 25)

STATUSES = {"ACTIVE", "SUPERSEDED", "ABOLISHED", "PENDING"}
CATEGORIES = {
    "NATIONAL_SCHOLARSHIP",
    "NATIONAL_GRANT",
    "NATIONAL_INSPIRATION",
    "SCHOOL_SCHOLARSHIP",
    "NEED_ASSESSMENT",
    "WORK_STUDY",
    "STUDENT_LOAN",
}

DOC_KEYS = ["id", "title", "issuer", "category", "source_type", "source_note", "created_at"]
VER_KEYS = ["id", "document_id", "version_no", "status", "effective_date", "published_date"]
CHUNK_KEYS = ["id", "version_id", "clause_no", "section_path", "order_no", "content"]

errors: list[str] = []


def fail(msg: str) -> None:
    errors.append(msg)


def parse_date(value: str, where: str) -> date | None:
    try:
        return date.fromisoformat(value)
    except (TypeError, ValueError):
        fail(f"{where}: 日期格式不是 YYYY-MM-DD -> {value!r}")
        return None


def load(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"{path.name}: JSON 解析失败 {exc}")
        return {}


def main() -> int:
    files = sorted(p for p in DEMO.glob("d*.json"))
    if not files:
        fail(f"{DEMO} 下没有找到数据文件")
        return report()

    doc_ids: set[str] = set()
    ver_ids: set[str] = set()
    chunk_ids: set[str] = set()
    ver_doc: dict[str, str] = {}
    ver_status: dict[str, str] = {}
    ver_replaced: dict[str, str | None] = {}
    status_counter: Counter[str] = Counter()
    category_counter: Counter[str] = Counter()
    active_per_doc: Counter[str] = Counter()
    actual: dict[str, dict] = {}

    for path in files:
        data = load(path)
        doc = data.get("document") or {}
        versions = data.get("versions") or []

        for key in DOC_KEYS:
            if not doc.get(key):
                fail(f"{path.name}: document 缺少 {key}")

        did = doc.get("id", "")
        if not re.fullmatch(r"d\d{3}", did or ""):
            fail(f"{path.name}: document.id 不符合 dNNN -> {did!r}")
        if did in doc_ids:
            fail(f"{path.name}: document.id 重复 {did}")
        doc_ids.add(did)

        if doc.get("category") not in CATEGORIES:
            fail(f"{path.name}: category 不在枚举内 -> {doc.get('category')!r}")
        category_counter[doc.get("category", "?")] += 1

        if doc.get("source_type") not in {"PUBLIC", "FAKE_DEMO"}:
            fail(f"{path.name}: source_type 必须是 PUBLIC / FAKE_DEMO")
        note = doc.get("source_note", "")
        if doc.get("source_type") == "FAKE_DEMO" and not note.startswith("虚构演示数据"):
            fail(f"{path.name}: FAKE_DEMO 的 source_note 必须以「虚构演示数据」开头")

        if not versions:
            fail(f"{path.name}: 没有任何版本")

        chunk_total = 0
        for ver in versions:
            for key in VER_KEYS:
                if not ver.get(key):
                    fail(f"{path.name}: version 缺少 {key} ({ver.get('id')})")

            vid = ver.get("id", "")
            if not re.fullmatch(r"v\d{3}", vid or ""):
                fail(f"{path.name}: version.id 不符合 vNNN -> {vid!r}")
            if vid in ver_ids:
                fail(f"{path.name}: version.id 重复 {vid}")
            ver_ids.add(vid)

            if ver.get("document_id") != did:
                fail(f"{path.name}: {vid} 的 document_id 与所属文档不一致")

            status = ver.get("status")
            if status not in STATUSES:
                fail(f"{path.name}: {vid} status 非法 -> {status!r}")
            status_counter[status] += 1
            ver_status[vid] = status
            ver_doc[vid] = did
            ver_replaced[vid] = ver.get("replaced_by")

            if status == "ACTIVE":
                active_per_doc[did] += 1

            eff = parse_date(ver.get("effective_date", ""), f"{vid}.effective_date")
            pub = parse_date(ver.get("published_date", ""), f"{vid}.published_date")
            exp_raw = ver.get("expiry_date")
            exp = parse_date(exp_raw, f"{vid}.expiry_date") if exp_raw else None

            if eff and pub and pub > eff:
                fail(f"{path.name}: {vid} published_date 晚于 effective_date")
            if eff and exp and exp < eff:
                fail(f"{path.name}: {vid} expiry_date 早于 effective_date")
            if status == "ABOLISHED" and not exp:
                fail(f"{path.name}: {vid} 已废止但缺少 expiry_date")
            if status == "PENDING" and eff and eff <= DATASET_DATE:
                fail(f"{path.name}: {vid} 标为 PENDING，但 effective_date {eff} 不晚于整理日")

            chunks = ver.get("chunks") or []
            if not chunks:
                fail(f"{path.name}: {vid} 没有条款")
            orders = []
            for chunk in chunks:
                for key in CHUNK_KEYS:
                    if chunk.get(key) in (None, ""):
                        fail(f"{path.name}: chunk 缺少 {key} ({chunk.get('id')})")

                cid = chunk.get("id", "")
                if not re.fullmatch(r"c\d{3,4}", cid or ""):
                    fail(f"{path.name}: chunk.id 不符合 cNNN -> {cid!r}")
                if cid in chunk_ids:
                    fail(f"{path.name}: chunk.id 重复 {cid}")
                chunk_ids.add(cid)

                if chunk.get("version_id") != vid:
                    fail(f"{path.name}: {cid} 的 version_id 与所属版本不一致")

                body = chunk.get("content", "")
                if not (10 <= len(body) <= 500):
                    fail(f"{path.name}: {cid} 条款长度 {len(body)} 不在 10—500 字之间")

                orders.append(chunk.get("order_no"))
                chunk_total += 1

            if orders and sorted(orders) != list(range(1, len(orders) + 1)):
                fail(f"{path.name}: {vid} 的 order_no 不是从 1 连续递增 -> {orders}")

        expected_chunks = len(versions) and chunk_total
        actual[did] = {
            "file": path.name,
            "versions": len(versions),
            "chunks": chunk_total,
            "chunk_total": expected_chunks,
        }

    for vid, replaced in ver_replaced.items():
        if ver_status.get(vid) == "SUPERSEDED" and not replaced:
            fail(f"{vid} 状态为 SUPERSEDED，但缺少 replaced_by")
        if replaced:
            if replaced not in ver_ids:
                fail(f"{vid} 的 replaced_by 指向不存在的版本 {replaced}")
            elif ver_doc.get(replaced) != ver_doc.get(vid):
                fail(f"{vid} 的 replaced_by 跨制度指向 {replaced}")
            elif replaced == vid:
                fail(f"{vid} 的 replaced_by 指向自身")

    for did, count in active_per_doc.items():
        if count > 1:
            fail(f"{did} 存在 {count} 个 ACTIVE 版本，同一制度最多一个")

    missing = STATUSES - set(status_counter)
    if missing:
        fail(f"状态覆盖不全，缺少 {sorted(missing)}")

    index_path = DEMO / "_index.json"
    if index_path.exists():
        index = load(index_path)
        totals = index.get("totals", {})
        if totals.get("documents") != len(doc_ids):
            fail(f"_index.json totals.documents={totals.get('documents')} 与实际 {len(doc_ids)} 不符")
        if totals.get("versions") != len(ver_ids):
            fail(f"_index.json totals.versions={totals.get('versions')} 与实际 {len(ver_ids)} 不符")
        real_chunks = len(chunk_ids)
        if totals.get("chunks") != real_chunks:
            fail(f"_index.json totals.chunks={totals.get('chunks')} 与实际 {real_chunks} 不符")
        listed = {entry.get("document_id") for entry in index.get("documents", [])}
        if listed != doc_ids:
            fail(f"_index.json 文档清单与目录不一致：缺 {sorted(doc_ids - listed)}，多 {sorted(listed - doc_ids)}")
    else:
        fail("缺少 _index.json")

    if not errors:
        print(f"[OK] {len(doc_ids)} documents / {len(ver_ids)} versions / {len(chunk_ids)} chunks")
        line = " ".join(f"{k}={v}" for k, v in sorted(status_counter.items()))
        print(f"[OK] status coverage: {line}")
        print("[OK] all ids unique, all foreign keys resolved")
        print("[OK] date rules satisfied (published<=effective, expiry>=effective, PENDING effective in future)")
        cats = " ".join(f"{k}={v}" for k, v in sorted(category_counter.items()))
        print(f"[OK] categories: {cats}")
    return report()


def report() -> int:
    if errors:
        for item in errors:
            print(f"[FAIL] {item}")
        print(f"\n{len(errors)} 项检查未通过")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
