# 部署问题快速解决指南

## 🚨 你当前的问题

**症状：**
- Ubuntu 系统
- 自动部署脚本执行后，Nginx 配置文件未生成
- `/etc/nginx/sites-available/` 和 `/etc/nginx/conf.d/` 都没有 scan-code 配置

**可能原因：**
1. 权限问题 - sudo 命令失败
2. 脚本提前退出 - 某步骤出错
3. 用户选择跳过 - 交互时选择了不配置 Nginx

---

## ⚡ 立即解决（5分钟）

### 步骤 1：诊断问题

```bash
cd /opt/scan-code
bash scripts/diagnose-deployment.sh
```

这会显示：
- 系统信息
- Nginx 状态和配置目录
- PM2 进程状态
- 端口监听情况
- 权限检查

### 步骤 2：手动配置 Nginx

```bash
cd /opt/scan-code
bash scripts/configure-nginx.sh
```

按提示输入：
- 前端端口：`6006`
- 后端端口：`3001`
- 服务器地址：`_` （或你的服务器 IP）

### 步骤 3：启动/修复服务

```bash
cd /opt/scan-code
bash scripts/fix-503.sh
```

这会：
- 检查并启动后端服务
- 验证端口监听
- 重启 Nginx
- 显示服务状态

### 步骤 4：验证

```bash
# 检查服务状态
pm2 list
sudo systemctl status nginx

# 测试访问
curl http://localhost:6006

# 浏览器访问
# http://你的服务器IP:6006
```

---

## 📋 优化方案总结

### 短期（本周）- 修复和改进

**已完成：**
- ✅ 诊断脚本
- ✅ 手动配置脚本
- ✅ 503 错误修复脚本
- ✅ 系统路径自动检测

**待完成：**
- ⏳ 改进部署脚本的错误处理
- ⏳ 添加详细日志系统
- ⏳ 改进交互提示

### 中期（2周）- 智能化

**功能：**
- 智能系统检测（自动识别 Ubuntu/CentOS）
- 智能权限管理（自动请求 sudo）
- 智能环境检测（Python/Node.js 版本）
- 改进的交互体验（清晰提示、输入验证）
- 详细的日志系统（记录所有操作）

### 长期（1月）- 企业级

**功能：**
- Python 虚拟环境支持
- SSL/HTTPS 自动配置
- Let's Encrypt 证书申请
- 域名配置和验证
- 数据库自动备份
- 监控和告警
- 容器化支持（Docker）
- CI/CD 集成

---

## 🎯 优先级建议

### P0 - 立即（今天）
```bash
# 1. 诊断问题
bash scripts/diagnose-deployment.sh

# 2. 手动配置
bash scripts/configure-nginx.sh

# 3. 修复服务
bash scripts/fix-503.sh
```

### P1 - 本周
- 修复部署脚本权限问题
- 添加错误处理和日志
- 改进交互提示

### P2 - 2周内
- 智能系统检测
- Python 虚拟环境
- SSL/HTTPS 支持

### P3 - 1月内
- 容器化支持
- CI/CD 集成
- 监控告警

---

## 📚 相关文档

### 问题排查
- [Nginx 503 错误排查](NGINX_503_TROUBLESHOOTING.md)
- [Nginx 配置说明](NGINX_CONFIG_GUIDE.md)
- [Nginx 路径问题](../NGINX_PATH_FIX.md)

### 优化方案
- [优化方案总览](DEPLOYMENT_OPTIMIZATION_PLAN.md)
- [模块设计详解](DEPLOYMENT_OPTIMIZATION_MODULES.md)

### 使用指南
- [部署指南](../DEPLOY.md)
- [更新指南](../UPDATE_GUIDE.md)
- [数据库初始化](../DATABASE_INIT.md)

---

## 💡 关键要点

### 1. 配置文件路径

| 系统 | 配置目录 | 文件名 |
|------|----------|--------|
| Ubuntu/Debian | `/etc/nginx/sites-available/` | `scan-code` |
| CentOS/RHEL | `/etc/nginx/conf.d/` | `scan-code.conf` |

### 2. server_name 配置

```nginx
server_name 192.168.8.91;  # ✅ 服务器 IP
server_name example.com;   # ✅ 域名
server_name _;             # ✅ 匹配所有（推荐）
server_name 0.0.0.0;       # ❌ 错误！
```

### 3. 外部访问

```nginx
listen 6006;  # 默认就是 listen 0.0.0.0:6006
              # 已经允许外部访问！
```

### 4. 权限问题

```bash
# 检查权限
sudo touch /etc/nginx/sites-available/.test
sudo rm /etc/nginx/sites-available/.test

# 如果失败，检查 sudo 配置
sudo -v
```

---

## 🔧 常用命令

### Nginx
```bash
# 测试配置
sudo nginx -t

# 重启服务
sudo systemctl restart nginx

# 查看状态
sudo systemctl status nginx

# 查看日志
sudo tail -f /var/log/nginx/scan-code-error.log
```

### PM2
```bash
# 查看进程
pm2 list

# 查看日志
pm2 logs scan-code-backend

# 重启服务
pm2 restart scan-code-backend

# 启动服务
cd /opt/scan-code/backend
pm2 start npm --name "scan-code-backend" -- start
pm2 save
```

### 端口检查
```bash
# 检查端口占用
netstat -tlnp | grep 3001
ss -tlnp | grep 6006

# 查看所有监听端口
netstat -tlnp
ss -tlnp
```

---

## 📞 需要帮助？

1. **运行诊断脚本**
   ```bash
   bash scripts/diagnose-deployment.sh > diagnosis.log 2>&1
   ```

2. **查看日志**
   ```bash
   pm2 logs scan-code-backend --lines 100
   sudo tail -100 /var/log/nginx/scan-code-error.log
   ```

3. **提供信息**
   - 系统版本：`cat /etc/os-release`
   - 错误信息：诊断脚本输出
   - 日志文件：PM2 和 Nginx 日志

---

## ✅ 成功标志

部署成功后，你应该看到：

```bash
# PM2 状态
pm2 list
# scan-code-backend | online

# 端口监听
netstat -tlnp | grep 3001
# node 进程监听 3001

netstat -tlnp | grep 6006
# nginx 进程监听 6006

# 测试访问
curl http://localhost:6006
# 返回 HTML 内容

# 浏览器访问
# http://服务器IP:6006
# 显示登录页面
```

---

**现在就开始解决问题吧！** 🚀

```bash
cd /opt/scan-code
bash scripts/diagnose-deployment.sh
bash scripts/configure-nginx.sh
bash scripts/fix-503.sh
```
