#!/usr/bin/env python
"""把演示制度 JSON 导出为可导入的 MySQL 脚本。

用法（仓库根目录）：
    .\\.venv\\Scripts\\python.exe .\\project\\database\\mysql\\seeds\\tools\\export_seed_sql.py

输出：project/database/mysql/seeds/demo-policies.sql

说明：
- 只生成 INSERT/DELETE，不生成建表语句。建表由数据库负责人（单成宇）按
  `project/docs/development/制度数据字段表.md` 维护，避免两处 DDL 打架。
- 脚本可重复执行：先按 id 删除再插入，不会产生重复数据。
- 表名与字段名严格按字段表，改名前先改字段表。
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

SEEDS = Path(__file__).resolve().parent.parent
DEMO = SEEDS / "demo-policies"
OUT = SEEDS / "demo-policies.sql"

DOC_COLS = ["id", "title", "doc_no", "issuer", "category", "source_type", "source_note", "created_at"]
VER_COLS = ["id", "document_id", "version_no", "status", "effective_date", "expiry_date",
            "replaced_by", "published_date", "summary"]
CHUNK_COLS = ["id", "version_id", "clause_no", "section_path", "order_no", "content"]


def sql_value(value) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, int):
        return str(value)
    text = str(value).replace("\\", "\\\\").replace("'", "''")
    return f"'{text}'"


def insert(table: str, cols: list[str], row: dict) -> str:
    values = ", ".join(sql_value(row.get(c)) for c in cols)
    return f"INSERT INTO `{table}` ({', '.join('`' + c + '`' for c in cols)}) VALUES ({values});"


def main() -> int:
    files = sorted(DEMO.glob("d*.json"))
    if not files:
        print(f"[FAIL] {DEMO} 下没有数据文件", file=sys.stderr)
        return 1

    docs, vers, chunks = [], [], []
    for path in files:
        data = json.loads(path.read_text(encoding="utf-8"))
        docs.append(data["document"])
        for ver in data.get("versions", []):
            vers.append(ver)
            chunks.extend(ver.get("chunks", []))

    lines = [
        "-- 奖助学金演示制度数据（自动生成，勿手工编辑）",
        "-- 生成器：project/database/mysql/seeds/tools/export_seed_sql.py",
        f"-- 规模：{len(docs)} 份制度 / {len(vers)} 个版本 / {len(chunks)} 条条款",
        "-- 数据性质：全部为虚构演示数据，不得对外宣称是真实政策",
        "-- 前置条件：documents / document_versions / chunks 三表已按字段表建好",
        "",
        "SET NAMES utf8mb4;",
        "",
        "-- 可重复执行：先清空演示数据",
        "DELETE FROM `chunks` WHERE `id` LIKE 'c%';",
        "DELETE FROM `document_versions` WHERE `id` LIKE 'v%';",
        "DELETE FROM `documents` WHERE `id` LIKE 'd%';",
        "",
        "-- documents",
    ]
    lines += [insert("documents", DOC_COLS, d) for d in docs]
    lines += ["", "-- document_versions"]
    lines += [insert("document_versions", VER_COLS, v) for v in vers]
    lines += ["", "-- chunks"]
    lines += [insert("chunks", CHUNK_COLS, c) for c in chunks]
    lines += ["", f"-- 结束：{len(docs)} / {len(vers)} / {len(chunks)}", ""]

    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"[OK] 写出 {OUT}")
    print(f"[OK] {len(docs)} documents / {len(vers)} versions / {len(chunks)} chunks")
    print(f"[OK] 文件大小 {OUT.stat().st_size} 字节，{len(lines)} 行")
    return 0


if __name__ == "__main__":
    sys.exit(main())
