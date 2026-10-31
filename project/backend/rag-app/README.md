# rag-app · 第一周可运行后端

## 这个模块为什么存在

团队仓库里 `backend/` 下原本是六个微服务骨架（gateway / auth / doc / search / admin / eval），
里面还没有任何 Java 代码。而第一周的开发计划（见 `计划文档 05 章`）要求的是**一个能跑起来的单体后端**：
注册登录、制度与条款管理、有效版本过滤、问答接口，全部在一个进程里。

所以这里单独放一个 `rag-app` 模块，把这周能跑通的东西先落地。它不是最终形态，是**第一周的可运行基线**。

## 和六个服务的关系

| 现在在 rag-app 里 | 第二周拆到 |
| --- | --- |
| `auth/` 注册、登录、JWT、拦截器 | `auth-service` |
| `document/` `clause/` 制度与条款 | `doc-service` |
| `qa/` 问答链路、Python 调用 | `search-service` |
| `config/` 拦截器注册、CORS | `gateway-service` |

拆的时候不需要重写业务逻辑，主要是把包挪进对应模块、把方法调用换成 HTTP 调用。

## 怎么跑

默认用 H2 内存库，零依赖启动：

```bash
mvn -f project/pom.xml -pl backend/rag-app -am spring-boot:run
```

或者进到模块目录：

```bash
cd project/backend/rag-app
mvn spring-boot:run
```

看到 `Started RagDemoApplication` 就绪，服务在 `http://localhost:8080`。
初始管理员账号 `admin / admin123`，启动时自动创建。

换真 MySQL：改 `application.yml` 的 `spring.profiles.active: mysql`，按 `application-mysql.yml` 填地址账号。

## 接口

| 方法 | 路径 | 权限 |
| --- | --- | --- |
| POST | `/api/auth/register` | 公开 |
| POST | `/api/auth/login` | 公开 |
| GET | `/api/auth/me` | 登录 |
| GET | `/api/features` | 公开 |
| GET | `/api/documents?keyword=&status=` | 登录 |
| GET | `/api/documents/{id}` | 登录 |
| POST / PUT / DELETE | `/api/documents...` | ADMIN |
| POST | `/api/documents/{id}/revoke` | ADMIN |
| GET | `/api/clauses?documentId=` | 登录 |
| POST / PUT / DELETE | `/api/clauses...` | ADMIN |
| POST | `/api/qa/ask` | 登录 |

统一返回 `{"code":0,"message":"ok","data":{}}`，HTTP 状态码恒为 200，业务错误看 `code`。

## 这一周验收过的点

- 未登录 401、普通用户改数据 403、管理员正常
- 制度增删改查、废止（`replaced_by` 记录被谁替代）
- 条款新增时自动生成 `chunk_id`（`doc1-c1000` 这种），用事务保证插入与回填一致
- 问答只检索 `status=1` 且未过期的制度；问「排名前百分之多少」只命中 2024 版，2023 版的「前 15%」被版本过滤挡掉
- 无依据时返回 `found=false` 和固定文案，不瞎编

## 已知限制

- H2 内存库，重启数据重置
- `app.python.mock=true` 时检索是 Java 内模拟的；Python 的 `/retrieve` 好了以后改成 `false`
- 没有前端页面，验证靠接口工具
