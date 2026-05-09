# 🚀 快速部署

## 一键部署命令

### 方式1：直接执行（推荐）

```bash
bash <(curl -fsSL https://gitee.com/laoqin1/qr-code-scan-system/raw/main/scripts/deploy.sh)
```

或使用 wget：

```bash
bash <(wget -qO- https://gitee.com/laoqin1/qr-code-scan-system/raw/main/scripts/deploy.sh)
```

### 方式2：下载后执行

```bash
# 下载脚本
curl -O https://gitee.com/laoqin1/qr-code-scan-system/raw/main/scripts/deploy.sh

# 添加执行权限
chmod +x deploy.sh

# 运行脚本
./deploy.sh
```

---

## 配置示例

部署过程中会询问以下配置：

| 配置项 | 推荐值 | 说明 |
|--------|--------|------|
| 项目目录 | `/opt/scan-code` | 项目安装位置 |
| Git 仓库 | `2` (Gitee) | 国内服务器选择 Gitee |
| 后端端口 | `3001` | 后端 API 端口 |
| 前端端口 | `80` | 前端访问端口 |
| 服务器地址 | `服务器IP` | 输入实际 IP 或域名 |
| 配置 Nginx | `y` | 推荐配置 |
| 使用 PM2 | `y` | 推荐使用 |

---

## 部署完成后

### 访问系统

```
http://服务器IP
```

### 默认账号

- 超级管理员：`admin` / `admin123`
- 客户管理员：`test` / `test123`

### 管理命令

```bash
# 查看服务状态
pm2 status

# 查看日志
pm2 logs scan-code-backend

# 重启服务
pm2 restart scan-code-backend
```

---

## 详细文档

查看完整部署指南：[docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)

---

**需要帮助？** 查看 [常见问题](docs/DEPLOYMENT_GUIDE.md#常见问题)
