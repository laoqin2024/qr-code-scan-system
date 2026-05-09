# 部署脚本更新说明

## 版本 v5.1.2

**更新时间：** 2025-01-06

---

## 🎯 更新内容

### 1. 增强互动体验

**之前：**
- 只检测 Nginx 和 PM2 是否已安装
- 未安装时直接跳过，不提供安装选项

**现在：**
- 检测到未安装时，提供详细说明和安装选项
- 用户可以选择是否安装
- 显示每个服务的用途和好处

---

## 📋 新增互动提示

### Nginx 安装提示

当检测到 Nginx 未安装时：

```
⚠️  检测到 Nginx 未安装
Nginx 用于：
  - 反向代理后端 API
  - 托管前端静态文件
  - 提供更好的性能和安全性

是否安装 Nginx？(y/n) [默认: y]:
```

**选择 y：**
- 自动安装 Nginx
- 自动配置反向代理
- 自动启动服务

**选择 n：**
- 跳过 Nginx 安装
- 提示需要手动配置 Web 服务器
- 前端需要单独部署

### PM2 安装提示

当检测到 PM2 未安装时：

```
⚠️  检测到 PM2 未安装
PM2 用于：
  - 进程管理和监控
  - 自动重启崩溃的进程
  - 开机自启动
  - 日志管理

是否安装 PM2？(y/n) [默认: y]:
```

**选择 y：**
- 自动安装 PM2
- 使用 PM2 启动服务
- 配置开机自启

**选择 n：**
- 跳过 PM2 安装
- 使用 nohup 启动服务
- 需要手动管理进程

---

## 🎨 配置确认界面

### 之前

```
📋 配置确认
项目目录: /opt/scan-code
Git 仓库: https://gitee.com/...
后端端口: 3001
前端端口: 80
服务器地址: 192.168.1.100
配置 Nginx: y
使用 PM2: y
```

### 现在

```
📋 配置确认
项目目录: /opt/scan-code
Git 仓库: https://gitee.com/...
后端端口: 3001
前端端口: 80
服务器地址: 192.168.1.100

服务配置:
  Nginx: 将安装并配置
  PM2: 将安装并使用
```

更清晰地显示将要执行的操作。

---

## 🔧 技术改进

### 1. 变量管理

新增变量：
- `NEED_NGINX` - 标记是否需要安装 Nginx
- `NEED_PM2` - 标记是否需要安装 PM2
- `INSTALL_NGINX` - 用户选择是否安装 Nginx
- `INSTALL_PM2` - 用户选择是否安装 PM2

### 2. 安装逻辑

```bash
# 检测阶段
if check_command nginx; then
    HAS_NGINX=true
else
    NEED_NGINX=true
fi

# 配置阶段
if [ "$NEED_NGINX" = true ]; then
    # 显示说明并询问
    read -p "是否安装 Nginx？(y/n) [默认: y]: " INSTALL_NGINX
fi

# 安装阶段
if [ "$INSTALL_NGINX" = "y" ]; then
    sudo apt-get install -y nginx
    HAS_NGINX=true
fi
```

---

## 📊 使用场景

### 场景1：全新服务器（推荐安装所有服务）

```
检测到 Nginx 未安装
是否安装 Nginx？(y/n) [默认: y]: y
✅ Nginx 安装完成

检测到 PM2 未安装
是否安装 PM2？(y/n) [默认: y]: y
✅ PM2 安装完成
```

**结果：** 完整的生产环境配置

### 场景2：已有 Web 服务器（不安装 Nginx）

```
检测到 Nginx 未安装
是否安装 Nginx？(y/n) [默认: y]: n
⚠️  不安装 Nginx，需要手动配置 Web 服务器

检测到 PM2 未安装
是否安装 PM2？(y/n) [默认: y]: y
✅ PM2 安装完成
```

**结果：** 只安装 PM2，手动配置 Apache/Caddy 等

### 场景3：最小化部署（开发/测试环境）

```
检测到 Nginx 未安装
是否安装 Nginx？(y/n) [默认: y]: n
⚠️  不安装 Nginx，需要手动配置 Web 服务器

检测到 PM2 未安装
是否安装 PM2？(y/n) [默认: y]: n
⚠️  不安装 PM2，将使用 nohup 启动服务
```

**结果：** 最小化安装，适合开发测试

---

## ✅ 优势

### 1. 用户友好

- ✅ 清晰的说明文字
- ✅ 默认推荐选项
- ✅ 灵活的选择

### 2. 智能安装

- ✅ 自动检测已安装的服务
- ✅ 只安装需要的服务
- ✅ 避免重复安装

### 3. 适应性强

- ✅ 适合不同的部署场景
- ✅ 支持自定义配置
- ✅ 兼容现有环境

---

## 🔄 升级指南

### 如果你已经克隆了项目

```bash
cd /path/to/scan-code
git pull origin main

# 重新运行部署脚本
./scripts/deploy.sh
```

### 如果使用一键部署

直接运行最新版本：

```bash
bash <(curl -fsSL https://gitee.com/laoqin1/qr-code-scan-system/raw/main/scripts/deploy.sh)
```

---

## 📚 相关文档

- **部署指南：** `docs/DEPLOYMENT_GUIDE.md`
- **故障排查：** `docs/TROUBLESHOOTING.md`
- **快速部署：** `DEPLOY.md`

---

**更新完成时间：** 2025-01-06  
**版本：** v5.1.2  
**状态：** ✅ 已发布
