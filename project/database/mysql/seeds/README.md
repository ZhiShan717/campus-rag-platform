# 开发样例数据（seeds）

本目录存放可重复导入的开发样例数据。当前只有一套数据集：**奖助学金制度演示数据**。

## 目录

```text
seeds/
├── README.md                      本说明
├── demo-policies/                 演示制度数据集（JSON，供导入脚本与测试共用）
│   ├── _index.json                汇总清单：文档、版本、状态、条款数
│   ├── d001-national-scholarship.json
│   ├── d002-national-inspiration.json
│   ├── d003-school-scholarship.json
│   ├── d004-need-assessment.json
│   ├── d005-national-grant-abolished.json
│   ├── d006-work-study-pending.json
│   ├── d007-student-loan.json
│   └── d008-temporary-aid.json
└── tools/
    └── validate_seed_data.py      数据自检脚本（结构、状态、日期、编号唯一性）
```

## 数据规模

| 项目 | 数量 | 说明 |
| --- | --- | --- |
| 制度 | 8 份 | 覆盖国家奖学金、励志奖学金、校级奖学金、助学金、困难认定、勤工助学、助学贷款、临时补助 |
| 版本 | 10 个 | — |
| 条款 | 43 条 | 单份 3—5 条，均为可独立检索的完整句子 |
| 状态分布 | ACTIVE 5 / SUPERSEDED 2 / ABOLISHED 1 / PENDING 1 | 四种状态齐全，每个状态至少一份 |

## 字段口径

字段定义、枚举、值边界与状态过滤规则见 [制度数据字段表](../../../docs/development/制度数据字段表.md)。改动数据前先读那份表。

## 数据来源与标注

- 全部 8 份均为 `source_type = FAKE_DEMO`，`source_note` 以「虚构演示数据」开头，**不是任何学校的真实文件**。
- 内容参照公开的国家奖助学金政策精神编写，数字（金额、比例、年限）为演示需要设定，不得作为真实政策依据对外引用。
- 演示、答辩、截图时页面或报告必须显示「虚构演示数据」标识；这条和 `docs` 里的能力标注规则一致。

## 导入约定

- JSON 是唯一事实来源；MySQL 导入脚本由单成宇按此结构生成 `INSERT`，Java 实体字段与 `制度数据字段表` 对齐。
- 导入顺序：`documents` → `document_versions` → `chunks`（外键自顶向下）。
- 重复导入应可重跑：脚本按 `id` 先删后插，或使用 `INSERT ... ON DUPLICATE KEY UPDATE`；不要依赖自增主键。
- 本目录不含任何数据库凭据；连接参数由本机 `environment/.env` 提供。

## 自检

```powershell
# 仓库根目录执行
.\.venv\Scripts\python.exe .\project\database\mysql\seeds\tools\validate_seed_data.py
```

通过输出示例：

```text
[OK] 8 documents / 10 versions / 43 chunks
[OK] status coverage: ACTIVE=5 SUPERSEDED=2 ABOLISHED=1 PENDING=1
[OK] all ids unique, all foreign keys resolved
[OK] date rules satisfied (expiry >= effective, PENDING effective in future)
```

任一项失败会打印 `[FAIL]` 并以退出码 1 结束，可直接接到 CI 或提交前检查。

## 变更记录

- 2026-10-25 建立数据集：8 份制度、10 个版本、43 条条款；同时冻结字段表与 8 道首轮测试题。
