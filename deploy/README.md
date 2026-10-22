# 部署目录

| 目录 | 用途 |
| --- | --- |
| `docker/` | 业务服务的容器构建文件及构建说明 |
| `nginx/` | 前端静态资源与网关反向代理配置 |
| `k8s/` | 后续需要时使用的 Kubernetes 清单 |

当前只预留业务部署目录，未生成可部署的业务镜像或配置。开发中间件继续使用唯一维护的 [dev-environment/docker-compose.yml](../dev-environment/docker-compose.yml)，启动入口保持不变：

```powershell
# 在仓库根目录的开发终端运行
.\dev-environment\Start-Services.ps1
# 包含 RocketMQ 的完整环境
.\dev-environment\Start-Services.ps1 -Messaging
```

服务实现并确定构建产物、环境变量与健康检查后，再编写各自 Dockerfile 和业务 Compose。Nginx、Kubernetes 仍为后续部署项；目前没有 `deploy/docker-compose.yml`，手册中的该路径需在业务部署实现后接入。
