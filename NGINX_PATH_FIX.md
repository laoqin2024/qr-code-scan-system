# Nginx 配置文件路径问题解决

## 🔍 问题

部署脚本尝试创建 `/etc/nginx/sites-available/scan-code`，但你的系统没有这个目录。

## 📋 原因

不同的 Linux 发行版使用不同的 Nginx 配置目录结构：

| 系统 | 配置目录 | 文件名要求 |
|------|----------|-----------|
| **Debian/Ubuntu** | `/etc/nginx/sites-available/` | 无要求 |
| **CentOS/RHEL** | `/etc/nginx/conf.d/` | 必须以 `.conf` 结尾 |

你的系统是 **CentOS/RHEL**，应该使用 `/etc/nginx/conf.d/` 目录。

---

## 🚀 快速解决

### 方法 1：使用自动配置脚本（推荐）

```bash
cd /opt/scan-code
bash scripts/configure-nginx.sh
```

脚本会：
1. 自动检测系统类型
2. 选择正确的配置目录
3. 创建配置文件
4. 测试并重启 Nginx

### 方法 2：手动创建配置文件

```bash
# 1. 创建配置文件（注意：文件名必须以 .conf 结尾）
sudo nano /etc/nginx/conf.d/scan-code.conf

# 2. 粘贴以下内容：
```

```nginx
server {
    listen 6006;
    server_name _;
    
    # 前端静态文件
    location / {
        root /opt/scan-code/frontend/dist;
        try_files $uri $uri/ /index.html;
        
        # 缓存静态资源
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

```bash
# 3. 测试配置
sudo nginx -t

# 4. 重启 Nginx
sudo systemctl restart nginx

# 5. 验证
curl http://localhost:6006
```

---

## 🔍 检测你的系统

运行检测脚本：

```bash
cd /opt/scan-code
bash scripts/detect-nginx-path.sh
```

会显示：
- 系统类型
- Nginx 版本
- 配置目录结构
- 现有配置文件

---

## 📊 配置目录对比

### Debian/Ubuntu 风格

```
/etc/nginx/
├── nginx.conf (主配置)
├── sites-available/
│   ├── default
│   └── scan-code (你的配置)
└── sites-enabled/
    ├── default -> ../sites-available/default
    └── scan-code -> ../sites-available/scan-code (软链接)
```

**特点：**
- 配置文件放在 `sites-available/`
- 通过软链接到 `sites-enabled/` 启用
- 文件名无要求

### CentOS/RHEL 风格

```
/etc/nginx/
├── nginx.conf (主配置)
└── conf.d/
    ├── default.conf
    └── scan-code.conf (你的配置)
```

**特点：**
- 配置文件直接放在 `conf.d/`
- 文件名必须以 `.conf` 结尾
- 无需软链接

---

## ⚠️ 注意事项

### 1. 文件名要求

**CentOS/RHEL 系统：**
```bash
# ✅ 正确
/etc/nginx/conf.d/scan-code.conf

# ❌ 错误（不会被加载）
/etc/nginx/conf.d/scan-code
```

### 2. 主配置文件的 include 指令

查看 `/etc/nginx/nginx.conf`：

```nginx
http {
    # CentOS/RHEL
    include /etc/nginx/conf.d/*.conf;
    
    # Debian/Ubuntu
    include /etc/nginx/sites-enabled/*;
}
```

### 3. 端口冲突

如果 `default.conf` 已经监听 80 端口，你的配置使用其他端口（如 6006）不会冲突。

---

## 🔧 已修复的问题

我已经更新了部署脚本，现在会：

1. **自动检测系统类型**
   ```bash
   if [ -d "/etc/nginx/sites-available" ]; then
       # Debian/Ubuntu
   elif [ -d "/etc/nginx/conf.d" ]; then
       # CentOS/RHEL
   fi
   ```

2. **使用正确的路径**
   - Debian/Ubuntu: `/etc/nginx/sites-available/scan-code`
   - CentOS/RHEL: `/etc/nginx/conf.d/scan-code.conf`

3. **正确处理软链接**
   - Debian/Ubuntu: 创建软链接
   - CentOS/RHEL: 不需要软链接

---

## 🎯 立即行动

在你的服务器上执行：

```bash
# 方法 1：自动配置（推荐）
cd /opt/scan-code
bash scripts/configure-nginx.sh

# 方法 2：检测系统
bash scripts/detect-nginx-path.sh

# 方法 3：手动创建
sudo nano /etc/nginx/conf.d/scan-code.conf
# 粘贴配置内容
sudo nginx -t
sudo systemctl restart nginx
```

---

## 📚 相关文档

- [Nginx 配置说明](docs/NGINX_CONFIG_GUIDE.md)
- [503 错误排查](docs/NGINX_503_TROUBLESHOOTING.md)
- [部署指南](DEPLOY.md)
