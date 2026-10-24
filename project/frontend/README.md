# 前端目录

使用 Vue 3 + Vite + TypeScript，承载校园知识库问答、文档管理、后台管理与评测页面。

工程已于 2026-10-23 初始化，`package.json`、`package-lock.json` 与可运行页面均已就位。当前是**页面骨架**：导航、路由与四个业务页面占位已通，业务接口尚未接入，因为网关路径、鉴权方式和响应结构还没定。

## 工具版本

初始化时锁定的版本，改动前请先和团队对齐：

| 工具 | 版本 |
| --- | --- |
| Node.js | 24.20.0 |
| npm | 11.19.0 |
| Vue | 3.5.44 |
| Vue Router | 5.4.0 |
| Pinia | 4.1.0 |
| Vite | 8.3.5 |
| TypeScript | 6.0.x |
| vue-tsc | 3.3.x |
| Vitest | 4.1.x |
| ESLint | 10.x（含 oxlint） |
| Prettier | 3.9.x |

## 常用命令

```bash
npm install          # 按 package-lock.json 安装依赖
npm run dev          # 开发服务器，固定 http://127.0.0.1:5173
npm run build        # 类型检查 + 生产构建，产物在 dist/
npm run test:unit    # Vitest 单元测试，加 -- --run 单次执行
npm run lint         # oxlint + ESLint，带 --fix
npm run format       # Prettier 格式化 src/
```

## 目录职责

```text
frontend/
├── public/                 # 原样发布的公共静态资源
├── src/
│   ├── api/                # 网关请求封装与按业务划分的接口调用
│   ├── assets/             # 由前端构建工具处理的图片、样式、字体等资源
│   ├── components/         # 多个页面复用的界面组件
│   ├── composables/        # 可复用的 Vue 组合式逻辑
│   ├── layouts/            # 页面框架与导航布局
│   ├── router/             # 路由与页面访问控制
│   ├── stores/             # 跨页面共享状态
│   ├── types/              # 共享 TypeScript 类型与接口数据类型
│   ├── utils/              # 与界面无关的通用工具
│   └── views/
│       ├── qa/             # 问答、历史会话与引用展示
│       ├── documents/      # 知识库文档上传、列表与处理状态
│       ├── admin/          # 用户、角色与知识库管理
│       └── evaluation/     # 问答质量评测与结果查看
└── tests/
    ├── unit/               # 单元与组件测试
    └── e2e/                # 用户操作流程测试
```

空目录用 `.gitkeep` 保留，添加实际文件后可删除对应占位文件。目录中的页面名称仅划分开发位置，不表示页面或功能已经实现。

## 下一步接入

1. 与网关负责人确认登录方式、权限、请求路径、响应结构、错误格式，以及流式问答与引用数据契约，再补 `src/api/` 下的具体接口函数和 `src/types/` 下的数据类型。
2. 接口地址通过 `VITE_API_BASE_URL` 配置，示例在 `.env.example`；本地覆盖写 `.env.local`，该文件已被忽略。开发代理在网关端口确定后加到 `vite.config.ts` 的 `server.proxy`。
3. 按页面补充关键交互测试，写进 `tests/unit/`；端到端流程等业务可用后再在 `tests/e2e/` 落地。

## 接入边界

- 浏览器通过网关访问后端业务接口；网关路径与开发代理配置在接口契约确定后填写。
- 前端不直连 MySQL，也不持有 MinIO 管理员凭据。文档上传与下载方式由后端接口和权限契约确定。
- 前端构建变量会进入浏览器产物，只能保存可公开的地址和开关。数据库密码、对象存储密钥、LLM Key、个人登录令牌不得放入前端代码或构建变量。
- 组件共享交互，`views/` 组织业务页面；请求逻辑集中在 `api/`，避免各页面分别定义相互冲突的接口与数据格式。
