# Git 冲突解决指南

## 📋 问题场景

当你手动上传文件到服务器后，使用 `git pull` 更新时可能会遇到冲突：

```
error: Your local changes to the following files would be overwritten by merge:
        frontend/src/pages/Query.tsx
        frontend/src/pages/Scan.tsx
        frontend/src/styles/Page.css
Please commit your changes or stash them before you merge.

error: The following untracked working tree files would be overwritten by merge:
        backend/src/fix-timezone.ts
        frontend/src/components/ConfirmDialog.tsx
        frontend/src/styles/ConfirmDialog.css
Please move or remove them before you merge.
Aborting
```

---

## 🎯 解决方案

### 快速解决（一键命令）

```bash
cd /opt/scan-code && \
cp db.sqlite /tmp/backup_$(date +%Y%m%d_%H%M%S).sqlite && \
git stash && \
rm -f backend/src/fix-timezone.ts frontend/src/components/ConfirmDialog.tsx frontend/src/styles/ConfirmDialog.css && \
git pull origin main && \
cd frontend && npm run build && cd .. && \
pm2 delete scan-code-backend && \
pm2 start npm --name "scan-code-backend" -- start && \
pm2 save && \
pm2 list
```

### 分步执行

#### 步骤 1：备份数据库

```bash
cp /opt/scan-code/db.sqlite /tmp/backup_$(date +%Y%m%d_%H%M%S).sqlite
```

#### 步骤 2：暂存本地修改

```bash
cd /opt/scan-code
git stash push -m "手动上传的文件 - $(date +%Y%m%d_%H%M%S)"
```

**说明：**
- 暂存已修改的文件（Query.tsx, Scan.tsx, Page.css）
- 不会丢失，可以用 `git stash pop` 恢复

#### 步骤 3：删除未跟踪的文件

```bash
rm -f backend/src/fix-timezone.ts
rm -f frontend/src/components/ConfirmDialog.tsx
rm -f frontend/src/styles/ConfirmDialog.css
```

**说明：**
- 这些文件在远程仓库中已存在
- 删除后会被 git pull 下载最新版本

#### 步骤 4：拉取最新代码

```bash
git pull origin main
```

#### 步骤 5：构建前端

```bash
cd frontend
npm run build
```

#### 步骤 6：重启服务（避免多实例）

```bash
cd ..
pm2 delete scan-code-backend
pm2 start npm --name "scan-code-backend" -- start
pm2 save
```

**重要：**
- 使用 `pm2 delete` 然后重新启动，避免出现多个实例
- 不要使用 `pm2 restart`，可能会创建重复实例

#### 步骤 7：验证

```bash
pm2 list
ls -lh db.sqlite
```

---

## 🔧 PM2 多实例问题

### 问题现象

```
┌────┬────────────────────┬──────────┬──────┬───────────┬──────────┐
│ id │ name               │ mode     │ ↺    │ status    │ memory   │
├────┼────────────────────┼──────────┼──────┼───────────┼──────────┤
│ 0  │ scan-code-backend  │ fork     │ 3    │ online    │ 20.8mb   │
│ 0  │ scan-code-backend  │ fork     │ 3    │ online    │ 70.5mb   │
└────┴────────────────────┴──────────┴──────┴───────────┴──────────┘
```

出现两个后端服务！

### 解决方法

```bash
# 删除所有实例
pm2 delete scan-code-backend

# 重新启动一个实例
cd /opt/scan-code/backend
pm2 start npm --name "scan-code-backend" -- start

# 保存配置
pm2 save

# 验证（应该只有一个）
pm2 list
```

### 正确的重启方式

```bash
# ✅ 推荐方式 1：reload（零停机）
pm2 reload scan-code-backend

# ✅ 推荐方式 2：delete + start
pm2 delete scan-code-backend
cd /opt/scan-code/backend
pm2 start npm --name "scan-code-backend" -- start
pm2 save

# ✅ 推荐方式 3：使用 ID
pm2 restart 0

# ❌ 避免使用：restart（可能创建多实例）
pm2 restart scan-code-backend  # 不推荐
```

---

## 📊 冲突类型说明

### 1. 已修改的文件

```
error: Your local changes to the following files would be overwritten by merge:
        frontend/src/pages/Query.tsx
```

**原因：**
- 你手动上传的文件与远程仓库的版本不同
- Git 检测到本地有未提交的修改

**解决：**
- 使用 `git stash` 暂存本地修改
- 或使用 `git reset --hard` 放弃本地修改（慎用）

### 2. 未跟踪的文件

```
error: The following untracked working tree files would be overwritten by merge:
        backend/src/fix-timezone.ts
```

**原因：**
- 本地有文件，但 Git 没有跟踪
- 远程仓库中也有同名文件

**解决：**
- 删除本地文件：`rm -f 文件路径`
- 或移动到其他位置：`mv 文件路径 /tmp/`

---

## 🛡️ 数据安全

### 备份策略

```bash
# 每次更新前备份
cp /opt/scan-code/db.sqlite /tmp/backup_$(date +%Y%m%d_%H%M%S).sqlite

# 查看备份
ls -lh /tmp/backup_*.sqlite

# 恢复备份（如果需要）
cp /tmp/backup_YYYYMMDD_HHMMSS.sqlite /opt/scan-code/db.sqlite
pm2 restart scan-code-backend
```

### Git 不会影响数据库

```bash
# .gitignore 已配置
db.sqlite
db.sqlite3
db.sqlite.backup*
```

数据库文件不会被 Git 管理，`git pull` 不会影响它。

---

## ✅ 验证清单

### 更新后检查

- [ ] 只有一个后端服务实例
- [ ] 服务状态为 online
- [ ] 数据库文件存在且大小正常
- [ ] 前端可以访问
- [ ] 新功能正常工作

### 验证命令

```bash
# 1. 检查服务
pm2 list

# 2. 检查数据库
ls -lh /opt/scan-code/db.sqlite
sqlite3 /opt/scan-code/db.sqlite "SELECT COUNT(*) FROM scans;"

# 3. 检查日志
pm2 logs scan-code-backend --lines 20

# 4. 测试 API
curl http://localhost:3001/api/health
```

---

## 🚀 最佳实践

### 推荐的更新流程

1. **备份数据库**
   ```bash
   cp db.sqlite /tmp/backup_$(date +%Y%m%d_%H%M%S).sqlite
   ```

2. **清理本地修改**
   ```bash
   git stash  # 或 git reset --hard
   ```

3. **拉取最新代码**
   ```bash
   git pull origin main
   ```

4. **构建前端**
   ```bash
   cd frontend && npm run build
   ```

5. **重启服务**
   ```bash
   pm2 delete scan-code-backend
   cd /opt/scan-code/backend
   pm2 start npm --name "scan-code-backend" -- start
   pm2 save
   ```

6. **验证**
   ```bash
   pm2 list
   ```

### 避免手动上传文件

- ✅ 使用 `git pull` 更新
- ✅ 使用更新脚本
- ❌ 避免手动 scp 上传文件

---

## 📝 常见问题

### Q1: git stash 后如何恢复？

```bash
# 查看暂存列表
git stash list

# 恢复最新的暂存
git stash pop

# 恢复指定的暂存
git stash apply stash@{0}
```

### Q2: 如何完全放弃本地修改？

```bash
# 危险操作！会丢失所有本地修改
git reset --hard origin/main
git clean -fd
```

### Q3: 如何查看本地和远程的差异？

```bash
# 查看差异
git diff origin/main

# 查看文件列表
git diff --name-only origin/main
```

### Q4: PM2 实例过多怎么办？

```bash
# 删除所有实例
pm2 delete all

# 重新启动
cd /opt/scan-code/backend
pm2 start npm --name "scan-code-backend" -- start
pm2 save
```

---

## 🔗 相关文档

- [部署指南](DEPLOY.md)
- [更新指南](README.md#更新项目)
- [数据库修复指南](DATABASE_DEPLOY_FIX.md)
- [时区修复指南](docs/TIMEZONE_FIX_GUIDE.md)

---

**遇到 Git 冲突不要慌，按照本指南操作即可安全解决！** 🎉
