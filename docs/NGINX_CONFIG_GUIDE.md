# Nginx 配置说明

## 🎯 配置项详解

### 1. SERVER_HOST（部署脚本中）

**提示信息：**
```
请输入服务器域名或IP [默认: localhost]:
```

**作用：** 用于 Nginx 的 `server_name` 指令

**正确填写：**
- ✅ `192.168.8.91` - 服务器的实际 IP
- ✅ `example.com` - 域名
- ✅ `localhost` - 本地访问
- ✅ `_` - 匹配所有（通配符）
- ❌ `0.0.0.0` - **错误！这不是有效的 server_name**

### 2. listen 指令

**作用：** 指定 Nginx 监听的端口和地址

**语法：**
```nginx
listen 6006;                    # 监听所有接口的 6006 端口（推荐）
listen 0.0.0.0:6006;           # 等同于上面，明确指定所有接口
listen 127.0.0.1:6006;         # 只监听本地，外部无法访问
listen [::]:6006;              # IPv6
```

**推荐配置：**
```nginx
listen 6006;  # 简洁，默认监听所有接口
```

### 3. server_name 指令

**作用：** 域名匹配，用于虚拟主机

**语法：**
```nginx
server_name 192.168.8.91;      # 匹配特定 IP
server_name example.com;       # 匹配域名
server_name *.example.com;     # 通配符
server_name _;                 # 默认服务器，匹配所有
```

**推荐配置：**
```nginx
server_name 192.168.8.91;  # 填写服务器实际 IP
# 或
server_name _;             # 匹配所有请求
```

### 4. proxy_pass 指令

**作用：** 反向代理到后端服务

**语法：**
```nginx
proxy_pass http://localhost:3001;    # 本地后端（推荐）
proxy_pass http://127.0.0.1:3001;   # 等同于上面
proxy_pass http://0.0.0.0:3001;     # ❌ 错误！0.0.0.0 不能用于连接
```

**必须使用：**
```nginx
proxy_pass http://localhost:3001;  # 或 127.0.0.1:3001
```

---

## 🔍 常见误区

### 误区 1：0.0.0.0 可以用于所有地方

**错误认知：**
```nginx
server {
    listen 6006;
    server_name 0.0.0.0;           # ❌ 错误
    
    location /api {
        proxy_pass http://0.0.0.0:3001;  # ❌ 错误
    }
}
```

**正确配置：**
```nginx
server {
    listen 6006;                   # 或 0.0.0.0:6006
    server_name 192.168.8.91;      # 或 _
    
    location /api {
        proxy_pass http://localhost:3001;  # 必须是 localhost
    }
}
```

**原因：**
- `0.0.0.0` 只能用于 `listen` 指令，表示"监听所有接口"
- `server_name` 用于域名匹配，`0.0.0.0` 不是有效的域名
- `proxy_pass` 需要具体的目标地址，`0.0.0.0` 无法连接

### 误区 2：SERVER_HOST 是外部访问地址

**错误理解：**
> "我填 0.0.0.0 就能让外部访问了"

**正确理解：**
- `SERVER_HOST` → `server_name` → 域名匹配
- 外部访问由 `listen` 决定，默认就是监听所有接口
- 填写服务器的实际 IP 或域名即可

### 误区 3：后端服务需要监听 0.0.0.0

**错误配置：**
```bash
# backend/.env
HOST=0.0.0.0  # 不需要这个配置
PORT=3001
```

**正确配置：**
```bash
# backend/.env
PORT=3001  # 只需要端口，默认监听 0.0.0.0
```

**原因：**
- Node.js 默认监听 `0.0.0.0`（所有接口）
- Nginx 通过 `localhost` 连接后端，不需要外部访问后端

---

## ✅ 完整的正确配置

### 部署脚本交互

```bash
请输入后端服务端口 [默认: 3001]: 3001
请输入前端服务端口 [默认: 80]: 6006
请输入服务器域名或IP [默认: localhost]: 192.168.8.91
```

### 生成的 Nginx 配置

```nginx
server {
    listen 6006;
    server_name 192.168.8.91;
    
    # 前端静态文件
    location / {
        root /opt/scan-code/frontend/dist;
        try_files $uri $uri/ /index.html;
        
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # API 代理
    location /api {
        proxy_pass http://localhost:3001;
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

### 后端 .env 配置

```bash
PORT=3001
JWT_SECRET=your_jwt_secret_here
NODE_ENV=production
```

---

## 🌐 访问方式

### 内网访问
```
http://192.168.8.91:6006
```

### 外网访问（如果有公网 IP）
```
http://公网IP:6006
```

### 域名访问（如果配置了域名）
```
http://example.com:6006
```

---

## 🔧 修复错误配置

### 如果你配置成了 0.0.0.0

```bash
# 1. 编辑 Nginx 配置
sudo nano /etc/nginx/sites-available/scan-code

# 2. 找到这一行：
server_name 0.0.0.0;

# 3. 改为：
server_name 192.168.8.91;  # 或 _

# 4. 保存后测试
sudo nginx -t

# 5. 重启 Nginx
sudo systemctl restart nginx
```

### 验证修复

```bash
# 1. 查看配置
cat /etc/nginx/sites-available/scan-code | grep server_name

# 2. 测试访问
curl http://localhost:6006

# 3. 浏览器访问
# http://192.168.8.91:6006
```

---

## 📊 配置对比表

| 场景 | listen | server_name | proxy_pass |
|------|--------|-------------|------------|
| **本地开发** | 5173 | localhost | http://localhost:3001 |
| **内网部署** | 6006 | 192.168.8.91 | http://localhost:3001 |
| **公网部署** | 80 | example.com | http://localhost:3001 |
| **多域名** | 80 | *.example.com | http://localhost:3001 |

---

## 🚨 注意事项

### 1. 防火墙配置

如果外部无法访问，检查防火墙：

```bash
# Ubuntu/Debian
sudo ufw allow 6006

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=6006/tcp
sudo firewall-cmd --reload
```

### 2. 云服务器安全组

如果是云服务器（阿里云、腾讯云等），需要在控制台开放 6006 端口。

### 3. SELinux（CentOS/RHEL）

如果启用了 SELinux，可能需要配置：

```bash
sudo setsebool -P httpd_can_network_connect 1
```

---

## 📚 相关文档

- [Nginx 官方文档 - server_name](http://nginx.org/en/docs/http/server_names.html)
- [Nginx 官方文档 - listen](http://nginx.org/en/docs/http/ngx_http_core_module.html#listen)
- [Nginx 503 错误排查](NGINX_503_TROUBLESHOOTING.md)
- [部署指南](../DEPLOY.md)
