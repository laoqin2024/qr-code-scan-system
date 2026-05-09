# 部署故障排查指南

## 常见问题及解决方案

### 1. better-sqlite3 编译失败

#### 问题描述

```
npm error gyp ERR! stack Error: `gyp` failed with exit code: 1
ModuleNotFoundError: No module named 'distutils'
```

#### 原因

`better-sqlite3` 是一个原生模块，需要编译。缺少编译工具或 Python distutils 模块。

#### 解决方案

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y build-essential python3 python3-distutils python3-dev
```

**CentOS/RHEL:**
```bash
sudo yum groupinstall -y "Development Tools"
sudo yum install -y python3 python3-devel
```

**手动安装 distutils:**
```bash
# Ubuntu/Debian
sudo apt-get install -y python3-distutils

# 或使用 pip
pip3 install setuptools
```

#### 验证

```bash
# 检查 Python
python3 --version

# 检查编译工具
gcc --version
make --version

# 重新安装
cd /opt/scan-code/backend
rm -rf node_modules package-lock.json
npm install
```

---

### 2. Node.js 版本过低

#### 问题描述

```
npm error Unsupported engine
```

#### 解决方案

**使用 nvm 安装新版本:**
```bash
# 安装 nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# 重新加载配置
source ~/.bashrc

# 安装 Node.js 18+
nvm install 18
nvm use 18

# 验证
node --version
```

---

### 3. 权限不足

#### 问题描述

```
Error: EACCES: permission denied
```

#### 解决方案

```bash
# 方案1：使用 sudo
sudo ./scripts/deploy.sh

# 方案2：修改目录权限
sudo chown -R $USER:$USER /opt/scan-code

# 方案3：使用用户目录
# 部署时选择 ~/scan-code 而不是 /opt/scan-code
```

---

### 4. 端口被占用

#### 问题描述

```
Error: listen EADDRINUSE: address already in use :::3001
```

#### 解决方案

```bash
# 查看端口占用
sudo lsof -i :3001
sudo lsof -i :80

# 杀死占用进程
sudo kill -9 <PID>

# 或修改端口
# 编辑 backend/.env
PORT=8080

# 重启服务
pm2 restart scan-code-backend
```

---

### 5. Git 克隆失败

#### 问题描述

```
fatal: unable to access 'https://github.com/...': Could not resolve host
```

#### 解决方案

```bash
# 检查网络
ping github.com
ping gitee.com

# 使用 Gitee（国内服务器）
# 部署时选择 2 (Gitee)

# 或手动克隆
git clone https://gitee.com/laoqin1/qr-code-scan-system.git /opt/scan-code

# 或下载 zip
wget https://gitee.com/laoqin1/qr-code-scan-system/repository/archive/main.zip
unzip main.zip
mv qr-code-scan-system /opt/scan-code
```

---

### 6. npm 安装超时

#### 问题描述

```
npm error network timeout
```

#### 解决方案

```bash
# 使用淘宝镜像
npm config set registry https://registry.npmmirror.com

# 或使用 cnpm
npm install -g cnpm --registry=https://registry.npmmirror.com
cnpm install

# 增加超时时间
npm config set timeout 60000

# 重试
cd /opt/scan-code/backend
npm install
```

---

### 7. Nginx 配置失败

#### 问题描述

```
nginx: [emerg] could not build server_names_hash
```

#### 解决方案

```bash
# 检查配置语法
sudo nginx -t

# 查看错误日志
sudo tail -f /var/log/nginx/error.log

# 手动修改配置
sudo nano /etc/nginx/sites-available/scan-code

# 重新加载
sudo nginx -s reload

# 或重启
sudo systemctl restart nginx
```

---

### 8. PM2 启动失败

#### 问题描述

```
pm2: command not found
```

#### 解决方案

```bash
# 全局安装 PM2
sudo npm install -g pm2

# 或使用 npx
npx pm2 start npm --name "scan-code-backend" -- start

# 不使用 PM2
cd /opt/scan-code/backend
nohup npm start > ../logs/backend.log 2>&1 &
echo $! > ../backend.pid
```

---

### 9. 数据库初始化失败

#### 问题描述

```
Error: SQLITE_CANTOPEN: unable to open database file
```

#### 解决方案

```bash
# 检查目录权限
ls -la /opt/scan-code

# 修改权限
sudo chown -R $USER:$USER /opt/scan-code

# 手动初始化
cd /opt/scan-code/backend
npm run init-db

# 检查数据库文件
ls -la ../db.sqlite
```

---

### 10. 前端构建失败

#### 问题描述

```
npm error code ELIFECYCLE
```

#### 解决方案

```bash
# 清除缓存
cd /opt/scan-code/frontend
rm -rf node_modules package-lock.json .vite

# 重新安装
npm install

# 重新构建
npm run build

# 检查构建产物
ls -la dist/
```

---

## 完整重新部署

如果遇到无法解决的问题，可以完全重新部署：

```bash
# 1. 停止服务
pm2 delete scan-code-backend
sudo systemctl stop nginx

# 2. 删除旧部署
sudo rm -rf /opt/scan-code

# 3. 安装依赖
sudo apt-get update
sudo apt-get install -y build-essential python3 python3-distutils python3-dev git nodejs npm

# 4. 重新部署
bash <(curl -fsSL https://gitee.com/laoqin1/qr-code-scan-system/raw/main/scripts/deploy.sh)
```

---

## 日志查看

### 后端日志

```bash
# PM2 日志
pm2 logs scan-code-backend

# 文件日志
tail -f /opt/scan-code/logs/backend.log

# npm 日志
cat /root/.npm/_logs/*-debug-0.log
```

### Nginx 日志

```bash
# 访问日志
tail -f /var/log/nginx/scan-code-access.log

# 错误日志
tail -f /var/log/nginx/scan-code-error.log

# 系统日志
sudo journalctl -u nginx -f
```

### 系统日志

```bash
# 查看系统日志
dmesg | tail

# 查看服务状态
systemctl status nginx
pm2 status
```

---

## 性能问题

### 内存不足

```bash
# 检查内存
free -h

# 增加 swap
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 永久生效
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### CPU 占用高

```bash
# 查看进程
top
htop

# 限制 PM2 实例数
pm2 delete scan-code-backend
pm2 start npm --name "scan-code-backend" -i 2 -- start
```

---

## 联系支持

如果以上方法都无法解决问题，请：

1. 收集日志信息
2. 记录错误信息
3. 查看项目 Issues
4. 提交新的 Issue

**GitHub Issues:**
https://github.com/laoqin2024/qr-code-scan-system/issues

**Gitee Issues:**
https://gitee.com/laoqin1/qr-code-scan-system/issues

---

**最后更新：** 2025-01-06  
**版本：** v5.1
