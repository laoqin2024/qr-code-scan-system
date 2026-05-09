# 🚀 自动化部署指南

本文档说明如何使用自动化部署脚本在生产服务器上部署二维码扫码防错系统。

## 📋 部署前准备

### 1. 服务器要求

**最低配置：**
- CPU: 2核
- 内存: 2GB
- 硬盘: 10GB
- 操作系统: Linux (Ubuntu/CentOS) 或 macOS

**推荐配置：**
- CPU: 4核
- 内存: 4GB
- 硬盘: 20GB

### 2. 网络要求

- 能够访问 GitHub 或 Gitee
- 开放端口：80（前端）、3001（后端）

### 3. 权限要求

- 需要 sudo 权限（用于安装依赖和配置 Nginx）

---

## 🚀 快速部署

### 方式1：直接运行（推荐）

```bash
# 下载部署脚本
curl -O https://raw.githubusercontent.com/laoqin2024/qr-code-scan-system/main/scripts/deploy.sh

# 或从 Gitee 下载
curl -O https://gitee.com/laoqin1/qr-code-scan-system/raw/main/scripts/deploy.sh

# 添加执行权限
chmod +x deploy.sh

# 运行部署脚本
./deploy.sh
```

### 方式2：克隆后运行

```bash
# 克隆项目
git clone https://github.com/laoqin2024/qr-code-scan-system.git
# 或
git clone https://gitee.com/laoqin1/qr-code-scan-system.git

# 进入项目目录
cd qr-code-scan-system

# 运行部署脚本
./scripts/deploy.sh
```

---

## 📝 部署流程

### 步骤1：检查系统环境

脚本会自动检查：
- 操作系统
- Git
- Node.js
- npm
- Nginx（可选）
- PM2（可选）

### 步骤2：配置部署参数

脚本会交互式询问以下配置：

**项目目录：**
```
请输入项目安装目录 [默认: /opt/scan-code]:
```
建议使用默认值或 `/var/www/scan-code`

**Git 仓库：**
```
请选择 Git 仓库:
  1. GitHub (推荐国外服务器)
  2. Gitee (推荐国内服务器)
请选择 [1/2, 默认: 2]:
```
国内服务器选择 2（Gitee），国外服务器选择 1（GitHub）

**后端端口：**
```
请输入后端服务端口 [默认: 3001]:
```
建议使用默认值 3001

**前端端口：**
```
请输入前端服务端口 [默认: 80]:
```
建议使用 80（HTTP）或 443（HTTPS）

**服务器地址：**
```
请输入服务器域名或IP [默认: localhost]:
```
输入服务器的公网 IP 或域名，例如：`192.168.1.100` 或 `scan.example.com`

**Nginx 配置：**
```
是否配置 Nginx 反向代理？(y/n) [默认: y]:
```
推荐选择 y

**PM2 管理：**
```
是否使用 PM2 管理进程？(y/n) [默认: y]:
```
推荐选择 y

### 步骤3-10：自动执行

脚本会自动完成：
- 安装系统依赖
- 克隆项目代码
- 配置环境变量
- 安装项目依赖
- 构建前端
- 初始化数据库
- 配置 Nginx
- 启动服务

---

## 🎯 部署示例

### 示例1：标准部署（推荐）

```bash
./deploy.sh

# 配置示例：
项目安装目录: /opt/scan-code
Git 仓库: 2 (Gitee)
后端服务端口: 3001
前端服务端口: 80
服务器地址: 192.168.1.100
配置 Nginx: y
使用 PM2: y
```

### 示例2：自定义端口

```bash
./deploy.sh

# 配置示例：
项目安装目录: /var/www/scan-code
Git 仓库: 2 (Gitee)
后端服务端口: 8080
前端服务端口: 8000
服务器地址: scan.example.com
配置 Nginx: y
使用 PM2: y
```

### 示例3：最小化部署（不使用 Nginx 和 PM2）

```bash
./deploy.sh

# 配置示例：
项目安装目录: /opt/scan-code
Git 仓库: 2 (Gitee)
后端服务端口: 3001
前端服务端口: 5173
服务器地址: localhost
配置 Nginx: n
使用 PM2: n
```

---

## ✅ 部署完成后

### 1. 访问系统

**前端地址：**
```
http://服务器IP:前端端口
```

**默认账号：**
- 超级管理员：`admin` / `admin123`
- 客户管理员：`test` / `test123`

### 2. 管理服务

**使用 PM2：**
```bash
# 查看状态
pm2 status

# 查看日志
pm2 logs scan-code-backend

# 重启服务
pm2 restart scan-code-backend

# 停止服务
pm2 stop scan-code-backend

# 删除服务
pm2 delete scan-code-backend
```

**不使用 PM2：**
```bash
# 查看日志
tail -f /opt/scan-code/logs/backend.log

# 停止服务
kill $(cat /opt/scan-code/backend.pid)

# 启动服务
cd /opt/scan-code/backend
nohup npm start > ../logs/backend.log 2>&1 &
echo $! > ../backend.pid
```

### 3. 管理 Nginx

```bash
# 查看状态
sudo systemctl status nginx

# 重启 Nginx
sudo systemctl restart nginx

# 查看配置
cat /etc/nginx/sites-available/scan-code

# 查看日志
tail -f /var/log/nginx/scan-code-access.log
tail -f /var/log/nginx/scan-code-error.log
```

---

## 🔧 常见问题

### 1. 端口被占用

**问题：** 启动失败，提示端口被占用

**解决：**
```bash
# 查看端口占用
sudo lsof -i :3001
sudo lsof -i :80

# 杀死占用进程
sudo kill -9 <PID>

# 或修改端口
# 编辑 backend/.env 修改 PORT
# 重新运行部署脚本
```

### 2. 权限不足

**问题：** 提示权限不足

**解决：**
```bash
# 使用 sudo 运行
sudo ./deploy.sh

# 或修改目录权限
sudo chown -R $USER:$USER /opt/scan-code
```

### 3. Git 克隆失败

**问题：** 无法访问 GitHub/Gitee

**解决：**
```bash
# 检查网络
ping github.com
ping gitee.com

# 使用代理（如果有）
export http_proxy=http://proxy:port
export https_proxy=http://proxy:port

# 或手动下载
wget https://github.com/laoqin2024/qr-code-scan-system/archive/refs/heads/main.zip
unzip main.zip
mv qr-code-scan-system-main /opt/scan-code
```

### 4. Node.js 版本过低

**问题：** Node.js 版本不兼容

**解决：**
```bash
# 安装 nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# 安装 Node.js 16+
nvm install 16
nvm use 16

# 重新运行部署脚本
```

### 5. 数据库初始化失败

**问题：** 数据库初始化失败

**解决：**
```bash
# 删除旧数据库
rm /opt/scan-code/db.sqlite

# 手动初始化
cd /opt/scan-code/backend
npm run init-db
```

### 6. Nginx 配置失败

**问题：** Nginx 配置测试失败

**解决：**
```bash
# 检查配置语法
sudo nginx -t

# 查看错误日志
sudo tail -f /var/log/nginx/error.log

# 手动修改配置
sudo nano /etc/nginx/sites-available/scan-code

# 重新加载
sudo nginx -s reload
```

---

## 🔒 安全加固

### 1. 修改默认密码

```bash
# 登录系统后立即修改密码
# 在用户管理页面修改 admin 和 test 的密码
```

### 2. 配置防火墙

```bash
# Ubuntu/Debian
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp
sudo ufw enable

# CentOS/RHEL
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload
```

### 3. 启用 HTTPS

```bash
# 安装 Certbot
sudo apt-get install certbot python3-certbot-nginx

# 获取证书
sudo certbot --nginx -d scan.example.com

# 自动续期
sudo certbot renew --dry-run
```

### 4. 配置数据库备份

```bash
# 创建备份脚本
cat > /opt/scan-code/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/scan-code/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR
cp /opt/scan-code/db.sqlite $BACKUP_DIR/db.sqlite.$DATE
# 保留最近7天的备份
find $BACKUP_DIR -name "db.sqlite.*" -mtime +7 -delete
EOF

chmod +x /opt/scan-code/backup.sh

# 添加定时任务
crontab -e
# 添加：每天凌晨2点备份
0 2 * * * /opt/scan-code/backup.sh
```

---

## 📊 性能优化

### 1. 启用 Gzip 压缩

编辑 Nginx 配置：
```nginx
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;
```

### 2. 配置缓存

编辑 Nginx 配置：
```nginx
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### 3. 增加 PM2 实例

```bash
# 使用集群模式
pm2 start npm --name "scan-code-backend" -i max -- start
```

---

## 🔄 更新部署

### 更新代码

```bash
cd /opt/scan-code
git pull

# 重新安装依赖（如果有更新）
cd backend && npm install
cd ../frontend && npm install

# 重新构建前端
cd frontend && npm run build

# 重启服务
pm2 restart scan-code-backend
```

### 重新部署

```bash
# 删除旧部署
sudo rm -rf /opt/scan-code

# 重新运行部署脚本
./deploy.sh
```

---

## 📚 相关文档

- [项目 README](../README.md)
- [快速开始](../QUICK_START.md)
- [部署清单](../DELIVERY_CHECKLIST.md)
- [网络访问配置](../NETWORK_ACCESS.md)

---

**最后更新：** 2025-01-06  
**版本：** v5.0
