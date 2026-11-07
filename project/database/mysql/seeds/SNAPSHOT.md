# 第一周数据快照（10.30）

快照日期：2026-10-30
维护：戴月
用途：把第一周交付的数据集冻结成可比对的版本。后续修改数据后，本文件需重新生成。

## 规模

| 项目 | 数量 |
| --- | --- |
| 制度 | 8 份 |
| 版本 | 10 个 |
| 条款 | 43 条 |
| 状态覆盖 | ACTIVE 6 / SUPERSEDED 2 / ABOLISHED 1 / PENDING 1 |

## 文件与校验

| 文件 | 字节 | SHA256（前 16 位） |
| --- | --- | --- |
| `demo-policies/_index.json` | 3632 | `45c4358990228254…` |
| `demo-policies/d001-national-scholarship.json` | 4409 | `46b6e2b4950c12bd…` |
| `demo-policies/d002-national-inspiration.json` | 2383 | `4fe03d8ee026bd32…` |
| `demo-policies/d003-school-scholarship.json` | 1979 | `936893d91726b344…` |
| `demo-policies/d004-need-assessment.json` | 2322 | `b70626db51d526d4…` |
| `demo-policies/d005-national-grant-abolished.json` | 1959 | `3ffde5ea1e494d25…` |
| `demo-policies/d006-work-study-pending.json` | 2029 | `220580a70f5128e0…` |
| `demo-policies/d007-student-loan.json` | 3604 | `3ed15bb681d5b16c…` |
| `demo-policies/d008-temporary-aid.json` | 1667 | `f4627f2ee92dabb5…` |
| `tools/export_seed_sql.py` | 3495 | `eebfcd2c7170c07b…` |
| `tools/selfcheck_retrieval.py` | 4269 | `9ca59eec4fdf6e04…` |
| `tools/validate_seed_data.py` | 9757 | `7f2f5d2bfe8983ad…` |
| `demo-policies.sql` | 18068 | `62bbc34a7ddd8456…` |

完整哈希可用下面命令复核：

```powershell
Get-FileHash .\project\database\mysql\seeds\demo-policies\*.json -Algorithm SHA256
```

## 说明

- 快照对应两个提交：`3476874`（数据集与题目）、`93f38a1`（SQL 导出）；后续如新增题目或调整条款，本快照即失效。
- `demo-policies.sql` 由 `tools/export_seed_sql.py` 生成，与 JSON 同源；两者不一致时以 JSON 为准。
- 全部数据为虚构演示数据，不得作为真实政策依据对外引用。
