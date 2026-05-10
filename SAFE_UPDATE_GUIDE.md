# 更新脚本安全检查清单

## 🛡️ 数据库保护机制

### update.sh 脚本的安全保障

#### 1. 备份位置（已修复）✅

**问题：** 之前备份在项目内 `backups/` 目录
**风险：** 项目目录被删除时，备份也会丢失

**修复后：**
```bash
# 备份位置优先级
1. /var/backups/scan-code/          # 系统标准备份目录（推荐）
2. ~/.scan-code-backups/            # 用户家目录
3. /tmp/scan-code-backups/          # 临时目录（最后选择）
```

**优势：**
- ✅ 备份在项目目录外
- ✅ 即使项目被删除，备份仍然存在
- ✅ 可以恢复到新部署的项目

#### 2. 数据库完整性检查 ✅

```bash
# 更新前检查
sqlite3 db.sqlite "PRAGMA integrity_check;"

# 如果损坏
❌ 数据库文件已损坏！
⚠️  建议从备份恢复或重新初始化
是否继续更新？(y/n) [默认: n]:
```

**保护：**
- ✅ 发现损坏立即提示
- ✅ 默认选择是取消（n）
- ✅ 不会继续破坏数据

#### 3. 备份验证 ✅

```bash
# 备份后验证
sqlite3 backup_file "PRAGMA integrity_check;"

# 如果备份失败
❌ 备份文件验证失败！
❌ 更新已取消
```

**保护：**
- ✅ 确保备份文件可用
- ✅ 备份失败则取消更新
- ✅ 不会继续操作

#### 4. 临时保护机制 ✅

```bash
# 拉取代码前
mv db.sqlite /tmp/db.sqlite.updating.$$

# 拉取代码
git pull

# 拉取完成后
mv /tmp/db.sqlite.updating.$$ db.sqlite
```

**保护：**
- ✅ 数据库不会被 git pull 覆盖
- ✅ 使用进程 ID 避免冲突
- ✅ 拉取失败自动恢复

#### 5. 错误自动恢复 ✅

```bash
trap 'handle_error $LINENO' ERR

handle_error() {
    # 如果有备份，提示恢复
    # 如果数据库在临时位置，自动恢复
    # 提供详细的恢复指南
}
```

**保护：**
- ✅ 任何错误都会被捕获
- ✅ 自动恢复临时移动的数据库
- ✅ 提供恢复命令

---

## 🔒 safe-update.sh 脚本（推荐）

### 特点

**100% 安全，不触碰数据库**

```bash
# 只更新前端代码
1. 拉取最新代码
2. 更新前端依赖
3. 重新构建前端
4. 重启后端服务

# 不会触碰
❌ 数据库文件
❌ 后端代码（不重新安装依赖）
❌ 配置文件
```

### 适用场景

- ✅ 只修改了前端代码
- ✅ 添加了前端功能（如二维码搜索）
- ✅ 修改了前端样式
- ✅ 不涉及数据库结构变化

### 使用方法

```bash
cd /opt/scan-code
bash scripts/safe-update.sh
```

---

## 📊 两个脚本对比

| 项目 | update.sh | safe-update.sh |
|------|-----------|----------------|
| 更新前端 | ✅ | ✅ |
| 更新后端 | ✅ | ❌ |
| 触碰数据库 | ⚠️ 可能 | ❌ 绝不 |
| 备份数据库 | ✅ | ❌ 不需要 |
| 安全性 | 高 | 极高 |
| 适用场景 | 全面更新 | 前端更新 |

---

## 🎯 本次更新建议

### 本次修改内容

1. ✅ 前端：添加二维码搜索功能
2. ✅ 前端：二维码完整显示
3. ✅ 后端：修复时区问题（datetime）
4. ❌ 数据库结构：无变化

### 推荐方案

#### 方案 1：使用 safe-update.sh（最安全）✅

```bash
# 只更新前端
cd /opt/scan-code
bash scripts/safe-update.sh

# 然后手动修复时区（可选）
cd backend
npm run fix-timezone
```

**优势：**
- ✅ 100% 不触碰数据库
- ✅ 前端功能立即生效
- ✅ 时区修复可以稍后执行

#### 方案 2：使用 update.sh（有保护）

```bash
cd /opt/scan-code
bash scripts/update.sh
```

**保护机制：**
- ✅ 自动备份到 /var/backups/scan-code/
- ✅ 完整性检查
- ✅ 备份验证
- ✅ 临时保护
- ✅ 错误恢复

---

## ✅ 安全检查清单

### 更新前

- [ ] 确认有最近的手动备份
- [ ] 检查磁盘空间充足
- [ ] 确认当前数据库完整
- [ ] 记录当前 Git 提交 hash

```bash
# 手动备份
cp /opt/scan-code/db.sqlite /tmp/manual_backup_$(date +%Y%m%d_%H%M%S).sqlite

# 检查磁盘空间
df -h /opt/scan-code

# 检查数据库
sqlite3 /opt/scan-code/db.sqlite "PRAGMA integrity_check;"

# 记录提交
cd /opt/scan-code && git log -1 --oneline
```

### 更新中

- [ ] 观察脚本输出
- [ ] 确认备份成功
- [ ] 确认构建成功
- [ ] 确认服务重启成功

### 更新后

- [ ] 检查数据库文件存在
- [ ] 检查数据库完整性
- [ ] 测试前端功能
- [ ] 检查扫码记录

```bash
# 检查数据库
ls -lh /opt/scan-code/db.sqlite
sqlite3 /opt/scan-code/db.sqlite "PRAGMA integrity_check;"

# 检查服务
pm2 list
pm2 logs scan-code-backend --lines 20

# 测试 API
curl http://localhost:3001/api/health
```

---

## 🚨 如果出现问题

### 问题 1：数据库丢失

```bash
# 查找备份
ls -lh /var/backups/scan-code/
ls -lh ~/.scan-code-backups/
ls -lh /tmp/scan-code-backups/

# 恢复最新备份
cp /var/backups/scan-code/db.sqlite.backup_YYYYMMDD_HHMMSS /opt/scan-code/db.sqlite

# 重启服务
pm2 restart scan-code-backend
```

### 问题 2：数据库损坏

```bash
# 尝试恢复备份
cp /var/backups/scan-code/db.sqlite.backup_YYYYMMDD_HHMMSS /opt/scan-code/db.sqlite

# 验证
sqlite3 /opt/scan-code/db.sqlite "PRAGMA integrity_check;"

# 如果所有备份都损坏
# 使用预置数据库（会丢失数据）
cp /opt/scan-code/db.sqlite.init /opt/scan-code/db.sqlite
```

### 问题 3：服务无法启动

```bash
# 查看日志
pm2 logs scan-code-backend

# 回滚代码
cd /opt/scan-code
git reset --hard HEAD~1

# 重新构建
cd frontend
npm run build

# 重启服务
pm2 restart scan-code-backend
```

---

## 💡 最佳实践

### 1. 定期手动备份

```bash
# 每周备份一次
cp /opt/scan-code/db.sqlite /backup/weekly/db.sqlite.$(date +%Y%m%d).backup
```

### 2. 测试环境先验证

```bash
# 在测试环境先运行
# 确认无问题后再在生产环境运行
```

### 3. 分步更新

```bash
# 第一步：只更新前端（safe-update.sh）
bash scripts/safe-update.sh

# 第二步：验证前端功能正常

# 第三步：修复时区（可选）
cd backend && npm run fix-timezone
```

### 4. 保留回滚点

```bash
# 记录当前提交
git log -1 --oneline > /tmp/before_update.txt

# 如果需要回滚
git reset --hard <commit-hash>
```

---

## 📝 本次更新推荐步骤

### 最安全的方式

```bash
# 1. 手动备份
cp /opt/scan-code/db.sqlite /tmp/manual_backup_$(date +%Y%m%d_%H%M%S).sqlite

# 2. 记录当前状态
cd /opt/scan-code
git log -1 --oneline

# 3. 使用安全更新脚本
bash scripts/safe-update.sh

# 4. 验证前端功能
# 浏览器访问并测试二维码搜索

# 5. 可选：修复时区
cd backend
npm run fix-timezone

# 6. 验证数据库
sqlite3 /opt/scan-code/db.sqlite "PRAGMA integrity_check;"
```

---

## ✅ 总结

### update.sh 安全性

- ✅ 备份到系统安全位置
- ✅ 完整性检查
- ✅ 备份验证
- ✅ 临时保护
- ✅ 错误恢复
- ✅ 安全性：高

### safe-update.sh 安全性

- ✅ 不触碰数据库
- ✅ 只更新前端
- ✅ 无风险
- ✅ 安全性：极高

### 建议

**对于本次更新，推荐使用 safe-update.sh**

原因：
1. 主要是前端改动
2. 100% 不触碰数据库
3. 时区修复可以稍后单独执行
4. 风险最小

---

**记住：安全第一，数据无价！** 🛡️
