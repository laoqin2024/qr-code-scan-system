# 项目更新部署指南

## 📋 概述

本文档介绍如何更新已部署的二维码扫码防错系统。

---

## 🚀 快速更新（推荐）

使用自动化更新脚本：

```bash
# 进入项目目录
cd /opt/scan-code  # 或你的项目目录

# 运行更新脚本
bash scripts/update.sh
```

脚本会自动完成：
1. ✅ 备份数据库
2. ✅ 拉取最新代码
3. ✅ 更新依赖
4. ✅ 构建前端
5. ✅ 数据库迁移（如需要）
6. ✅ 重启服务

---

## 🔧 手动更新步骤

如果需要手动控制更新过程：

### 1. 备份数据库

```bash
cd /opt/scan-code
mkdir -p backups
cp db.sqlite backups/db.sqlite.backup_$(date +%Y%m%d_%H%M%S)
```

### 2. 拉取最新代码

```bash
# 查看当前状态
git status

# 如有未提交的更改，先暂存
git stash

# 拉取最新代码
git pull origin main  # 或你的分支名

# 恢复暂存的更改（如需要）
git stash pop
```

### 3. 更新依赖

```bash
# 更新后端依赖
cd backend
npm install

# 更新前端依赖
cd ../frontend
npm install
```

### 4. 构建前端

```bash
cd frontend
npm run build
```

### 5. 数据库迁移（如有）

```bash
cd backend
npm run migrate-v3  # 如果有新的迁移脚本
```

### 6. 重启服务

**使用 PM2:**
```bash
pm2 restart scan-code-backend
pm2 logs  # 查看日志确认启动成功
```

**使用 systemd:**
```bash
sudo systemctl restart scan-code
sudo systemctl status scan-code
```

**手动启动:**
```bash
# 停止旧进程
kill $(cat backend.pid)

# 启动新进程
cd backend
nohup npm start > ../logs/backend.log 2>&1 & echo $! > ../backend.pid
```

### 7. 重启 Nginx（如需要）

```bash
sudo nginx -t  # 测试配置
sudo systemctl restart nginx
```

---

## 📦 不同类型的更新

### 仅前端更新

如果只修改了前端代码：

```bash
cd /opt/scan-code/frontend
git pull
npm install  # 如果依赖有变化
npm run build
# 无需重启后端服务
```

### 仅后端更新

如果只修改了后端代码：

```bash
cd /opt/scan-code/backend
git pull
npm install  # 如果依赖有变化
pm2 restart scan-code-backend
```

### 配置文件更新

如果更新了 Nginx 配置：

```bash
cd /opt/scan-code
git pull
sudo cp nginx.conf /etc/nginx/sites-available/scan-code
sudo nginx -t
sudo systemctl restart nginx
```

### 数据库结构更新

如果有数据库结构变更：

```bash
# 1. 备份数据库（重要！）
cp db.sqlite backups/db.sqlite.backup_$(date +%Y%m%d_%H%M%S)

# 2. 拉取代码
git pull

# 3. 运行迁移脚本
cd backend
npm run migrate-v3

# 4. 重启服务
pm2 restart scan-code-backend
```

---

## 🔄 版本回滚

如果更新后出现问题，可以回滚：

### 回滚代码

```bash
# 查看提交历史
git log --oneline -10

# 回滚到指定版本
git reset --hard <commit-hash>

# 或回滚到上一个版本
git reset --hard HEAD~1

# 重新构建和重启
cd frontend && npm run build
cd ../backend
pm2 restart scan-code-backend
```

### 恢复数据库

```bash
# 查看备份文件
ls -lh backups/

# 恢复指定备份
cp backups/db.sqlite.backup_20260510_143000 db.sqlite

# 重启服务
pm2 restart scan-code-backend
```

---

## 🔍 更新后检查

### 1. 检查服务状态

```bash
# PM2 状态
pm2 status
pm2 logs --lines 50

# Nginx 状态
sudo systemctl status nginx
```

### 2. 检查前端

访问前端地址，确认：
- ✅ 页面正常加载
- ✅ 登录功能正常
- ✅ 主要功能可用

### 3. 检查后端 API

```bash
# 测试健康检查接口
curl http://localhost:3001/api/health

# 测试登录接口
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

### 4. 检查日志

```bash
# PM2 日志
pm2 logs scan-code-backend --lines 100

# Nginx 日志
sudo tail -f /var/log/nginx/scan-code-error.log
sudo tail -f /var/log/nginx/scan-code-access.log
```

---

## 📅 更新策略建议

### 开发环境
- 随时更新到最新代码
- 可以直接使用 `git pull`

### 测试环境
- 每周更新一次
- 更新前做好备份
- 更新后进行完整测试

### 生产环境
- 选择低峰期更新（如凌晨）
- 必须先在测试环境验证
- 更新前通知用户
- 做好完整备份
- 准备回滚方案

---

## ⚠️ 注意事项

### 更新前

1. **备份数据库** - 这是最重要的！
2. **通知用户** - 避免在使用高峰期更新
3. **测试环境验证** - 确保更新不会破坏现有功能
4. **准备回滚方案** - 记录当前版本号

### 更新中

1. **保持冷静** - 遇到错误不要慌
2. **查看日志** - 错误信息通常很有用
3. **逐步操作** - 不要跳过步骤

### 更新后

1. **功能测试** - 测试主要功能
2. **性能监控** - 观察服务器资源使用
3. **用户反馈** - 收集用户使用反馈
4. **保留备份** - 至少保留一周

---

## 🐛 常见问题

### 问题 1: 拉取代码时提示冲突

```bash
# 查看冲突文件
git status

# 方案 1: 暂存本地更改
git stash
git pull
git stash pop

# 方案 2: 放弃本地更改
git reset --hard
git pull
```

### 问题 2: npm install 失败

```bash
# 清理缓存
npm cache clean --force

# 删除 node_modules 重新安装
rm -rf node_modules package-lock.json
npm install
```

### 问题 3: 前端构建失败

```bash
# 检查 Node.js 版本
node --version  # 需要 >= 16

# 清理构建缓存
rm -rf dist node_modules
npm install
npm run build
```

### 问题 4: 服务启动失败

```bash
# 查看详细日志
pm2 logs scan-code-backend --lines 100

# 检查端口占用
lsof -i :3001

# 检查数据库文件
ls -lh db.sqlite
```

### 问题 5: 数据库迁移失败

```bash
# 恢复备份
cp backups/db.sqlite.backup_<timestamp> db.sqlite

# 手动检查迁移脚本
cat backend/src/migrate-v3.ts

# 重新运行迁移
cd backend
npm run migrate-v3
```

---

## 📞 获取帮助

如果遇到无法解决的问题：

1. 查看项目文档：
   - [故障排除](TROUBLESHOOTING.md)
   - [部署指南](docs/DEPLOYMENT_GUIDE.md)

2. 查看日志文件：
   - PM2 日志：`pm2 logs`
   - Nginx 日志：`/var/log/nginx/scan-code-*.log`

3. 回滚到稳定版本，然后寻求技术支持

---

## 📚 相关文档

- [快速开始](QUICK_START.md)
- [部署指南](docs/DEPLOYMENT_GUIDE.md)
- [数据库初始化](DATABASE_INIT.md)
- [故障排除](docs/TROUBLESHOOTING.md)
- [Git 使用指南](GIT_QUICK_START.md)
