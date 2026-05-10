# Nginx 503 错误排查指南

## 🔍 问题描述

访问前端地址（如 http://192.168.8.91:6006）时出现 **503 Service Temporarily Unavailable** 错误。

## 📋 503 错误的含义

- **Nginx 正常运行** ✅
- **Nginx 配置正确** ✅
- **Nginx 监听端口正常** ✅
- **但是后端服务无法响应** ❌

503 错误表示 Nginx 无法连接到后端服务（proxy_pass 指向的地址）。

---

## 🚀 快速修复

### 方法 1：使用自动修复脚本（推荐）

```bash
# 在服务器上执行
cd /opt/scan-code  # 或你的项目目录
bash scripts/fix-503.sh
```

脚本会自动：
1. 检查后端服务状态
2. 重启后端服务（如需要）
3. 验证端口监听
4. 测试 API 连接
5. 重启 Nginx
6. 验证访问

### 方法 2：手动排查

```bash
# 1. 检查后端服务
pm2 list

# 2. 如果后端未运行，启动它
cd /opt/scan-code/backend
pm2 start npm --name "scan-code-backend" -- start
pm2 save

# 3. 检查后端日志
pm2 logs scan-code-backend

# 4. 重启 Nginx
sudo systemctl restart nginx
```

---

## 🔍 详细诊断

### 使用诊断脚本

```bash
cd /opt/scan-code
bash scripts/diagnose-503.sh
```

诊断脚本会检查：
1. Nginx 配置文件
2. Nginx 监听端口
3. 后端服务状态
4. 后端端口监听
5. PM2 进程状态
6. PM2 日志
7. Nginx 错误日志
8. 防火墙规则

---

## 🐛 常见原因和解决方案

### 原因 1：后端服务未启动（最常见）

**症状：**
```bash
pm2 list
# 显示 scan-code-backend 状态为 stopped 或不存在
```

**解决方案：**
```bash
cd /opt/scan-code/backend
pm2 start npm --name "scan-code-backend" -- start
pm2 save
```

### 原因 2：后端服务崩溃

**症状：**
```bash
pm2 logs scan-code-backend
# 显示错误信息，如数据库错误、端口占用等
```

**解决方案：**
```bash
# 查看详细日志
pm2 logs scan-code-backend --lines 100

# 常见错误：
# - 数据库文件不存在或权限问题
# - 端口 3001 被占用
# - 环境变量配置错误
# - 依赖缺失

# 根据错误信息修复后重启
pm2 restart scan-code-backend
```

### 原因 3：后端端口配置错误

**症状：**
```bash
# 后端服务运行，但不在 3001 端口
netstat -tlnp | grep node
# 显示在其他端口，如 3000
```

**解决方案：**
```bash
# 检查后端 .env 文件
cat /opt/scan-code/backend/.env

# 应该包含：
# PORT=3001

# 如果端口不对，修改后重启
pm2 restart scan-code-backend
```

### 原因 4：Nginx 配置的后端地址错误

**症状：**
```bash
cat /etc/nginx/sites-available/scan-code
# proxy_pass 指向错误的地址或端口
```

**解决方案：**
```bash
# 检查 Nginx 配置中的 proxy_pass
sudo nano /etc/nginx/sites-available/scan-code

# 确保 proxy_pass 指向正确的后端地址：
# proxy_pass http://localhost:3001;

# 修改后测试并重启
sudo nginx -t
sudo systemctl restart nginx
```

### 原因 5：数据库文件问题

**症状：**
```bash
pm2 logs scan-code-backend
# 显示数据库相关错误
```

**解决方案：**
```bash
cd /opt/scan-code

# 检查数据库文件
ls -lh db.sqlite

# 如果不存在，使用预置文件初始化
cp db.sqlite.init db.sqlite

# 或运行初始化脚本
cd backend
npm run init-db

# 重启服务
pm2 restart scan-code-backend
```

### 原因 6：权限问题

**症状：**
```bash
pm2 logs scan-code-backend
# 显示 EACCES 或 permission denied 错误
```

**解决方案：**
```bash
cd /opt/scan-code

# 修复文件权限
sudo chown -R $USER:$USER .

# 确保数据库文件可写
chmod 644 db.sqlite

# 重启服务
pm2 restart scan-code-backend
```

### 原因 7：端口被占用

**症状：**
```bash
pm2 logs scan-code-backend
# 显示 EADDRINUSE 错误
```

**解决方案：**
```bash
# 查找占用 3001 端口的进程
sudo lsof -i :3001

# 或
sudo netstat -tlnp | grep 3001

# 杀死占用进程
sudo kill -9 <PID>

# 重启服务
pm2 restart scan-code-backend
```

---

## 📊 验证修复

### 1. 检查后端服务

```bash
# 检查 PM2 状态
pm2 list
# scan-code-backend 应该显示 online

# 检查端口监听
netstat -tlnp | grep 3001
# 应该显示 node 进程监听 3001 端口
```

### 2. 测试后端 API

```bash
# 测试健康检查接口
curl http://localhost:3001/api/health

# 应该返回类似：
# {"status":"ok"}
```

### 3. 检查 Nginx

```bash
# 检查 Nginx 状态
sudo systemctl status nginx
# 应该显示 active (running)

# 检查 Nginx 配置
sudo nginx -t
# 应该显示 test is successful
```

### 4. 测试前端访问

```bash
# 通过 Nginx 访问前端
curl http://localhost:6006

# 应该返回 HTML 内容
```

### 5. 浏览器访问

打开浏览器访问：
- 前端：http://服务器IP:6006
- 应该能看到登录页面

---

## 🔧 Nginx 配置说明

### 正确的配置示例

```nginx
server {
    listen 6006;  # 前端端口
    server_name 192.168.8.91;
    
    # 前端静态文件
    location / {
        root /opt/scan-code/frontend/dist;
        try_files $uri $uri/ /index.html;
    }
    
    # API 代理到后端
    location /api {
        proxy_pass http://localhost:3001;  # 后端地址
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
    }
    
    # 日志
    access_log /var/log/nginx/scan-code-access.log;
    error_log /var/log/nginx/scan-code-error.log;
}
```

### 配置要点

1. **listen 端口**：前端访问端口（6006）
2. **root 路径**：前端构建文件路径
3. **proxy_pass**：后端服务地址（http://localhost:3001）
4. **location /api**：API 请求代理到后端

---

## 📝 日志查看

### PM2 日志

```bash
# 实时查看日志
pm2 logs scan-code-backend

# 查看最近 100 行
pm2 logs scan-code-backend --lines 100

# 只看错误日志
pm2 logs scan-code-backend --err

# 清空日志
pm2 flush
```

### Nginx 日志

```bash
# 查看访问日志
sudo tail -f /var/log/nginx/scan-code-access.log

# 查看错误日志
sudo tail -f /var/log/nginx/scan-code-error.log

# 查看最近的错误
sudo tail -50 /var/log/nginx/scan-code-error.log
```

---

## 🚨 紧急恢复

如果以上方法都无效，尝试完全重启：

```bash
# 1. 停止所有服务
pm2 delete scan-code-backend
sudo systemctl stop nginx

# 2. 检查端口占用
sudo lsof -i :3001
sudo lsof -i :6006

# 3. 重新启动
cd /opt/scan-code/backend
pm2 start npm --name "scan-code-backend" -- start
pm2 save

sudo systemctl start nginx

# 4. 验证
pm2 list
sudo systemctl status nginx
curl http://localhost:3001/api/health
curl http://localhost:6006
```

---

## 📞 获取帮助

如果问题仍未解决：

1. **收集诊断信息**
   ```bash
   bash scripts/diagnose-503.sh > diagnosis.log 2>&1
   ```

2. **查看完整日志**
   ```bash
   pm2 logs scan-code-backend --lines 200 > pm2.log
   sudo tail -100 /var/log/nginx/scan-code-error.log > nginx.log
   ```

3. **检查系统资源**
   ```bash
   free -h  # 内存
   df -h    # 磁盘
   top      # CPU
   ```

4. **联系技术支持**，提供以上日志文件

---

## 📚 相关文档

- [更新部署指南](../UPDATE_GUIDE.md)
- [数据库初始化说明](../DATABASE_INIT.md)
- [部署指南](../DEPLOY.md)
- [故障排除](TROUBLESHOOTING.md)
