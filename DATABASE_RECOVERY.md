# 数据库恢复指南

## 🚨 如果数据库损坏了怎么办？

### 快速恢复步骤

#### 方法 1：从备份恢复（推荐）

```bash
# 1. 进入项目目录
cd /opt/scan-code

# 2. 查看可用的备份
ls -lh backups/

# 3. 选择最新的备份恢复
cp backups/db.sqlite.backup_YYYYMMDD_HHMMSS db.sqlite

# 4. 验证数据库
sqlite3 db.sqlite "PRAGMA integrity_check;"

# 5. 重启服务
pm2 restart scan-code-backend
```

#### 方法 2：使用预置数据库文件

```bash
# 1. 进入项目目录
cd /opt/scan-code

# 2. 使用预置的初始化数据库
cp db.sqlite.init db.sqlite

# 3. 重启服务
pm2 restart scan-code-backend
```

**⚠️ 注意：** 使用预置文件会丢失所有扫码数据，只保留初始账号。

---

## 📋 update.sh 脚本的数据库保护机制

### 1. 更新前检查

```bash
# 检查数据库完整性
sqlite3 db.sqlite "PRAGMA integrity_check;"

# 如果损坏，会提示：
# ❌ 数据库文件已损坏！
# ⚠️  建议从备份恢复或重新初始化
# 是否继续更新？(y/n) [默认: n]:
```

### 2. 自动备份

```bash
# 备份到 backups/ 目录
backups/db.sqlite.backup_20260510_143000

# 验证备份文件完整性
# 如果备份失败，更新会自动取消
```

### 3. 临时保护

```bash
# 拉取代码前，数据库被移到安全位置
/tmp/db.sqlite.updating.$$

# 代码拉取完成后，自动恢复
# 如果拉取失败，数据库会自动恢复
```

### 4. 错误自动恢复

```bash
# 如果更新过程中出错：
# 1. 自动提示恢复数据库备份
# 2. 自动恢复临时移动的数据库
# 3. 提供详细的恢复指南
```

### 5. 最终验证

```bash
# 更新完成后自动验证：
✓ 数据库完整性验证通过
✓ 前端构建文件存在
✓ 后端服务运行正常
```

---

## 🔍 检查数据库状态

### 检查数据库完整性

```bash
cd /opt/scan-code
sqlite3 db.sqlite "PRAGMA integrity_check;"
```

**正常输出：**
```
ok
```

**异常输出：**
```
*** in database main ***
Page 5: btreeInitPage() returns error code 11
```

### 查看数据库信息

```bash
# 查看文件大小
ls -lh db.sqlite

# 查看表结构
sqlite3 db.sqlite ".tables"

# 查看记录数
sqlite3 db.sqlite "SELECT COUNT(*) FROM scan_records;"
```

---

## 💾 备份管理

### 查看所有备份

```bash
cd /opt/scan-code
ls -lh backups/
```

### 手动创建备份

```bash
cd /opt/scan-code
mkdir -p backups
cp db.sqlite backups/db.sqlite.backup_$(date +%Y%m%d_%H%M%S)
```

### 清理旧备份

```bash
# update.sh 会自动保留最近 10 个备份
# 手动清理（保留最近 5 个）
cd /opt/scan-code/backups
ls -t db.sqlite.backup_* | tail -n +6 | xargs rm
```

---

## 🔄 完整的恢复流程

### 场景 1：更新后数据库损坏

```bash
# 1. 停止服务
pm2 stop scan-code-backend

# 2. 查看备份
cd /opt/scan-code
ls -lh backups/

# 3. 恢复最新备份
cp backups/db.sqlite.backup_20260510_143000 db.sqlite

# 4. 验证
sqlite3 db.sqlite "PRAGMA integrity_check;"

# 5. 重启服务
pm2 restart scan-code-backend

# 6. 测试
curl http://localhost:3001/api/health
```

### 场景 2：备份也损坏了

```bash
# 1. 尝试其他备份
cd /opt/scan-code
ls -lh backups/

# 2. 逐个验证备份
for backup in backups/db.sqlite.backup_*; do
    echo "检查: $backup"
    sqlite3 "$backup" "PRAGMA integrity_check;"
done

# 3. 使用最早的完好备份
cp backups/db.sqlite.backup_YYYYMMDD_HHMMSS db.sqlite

# 4. 重启服务
pm2 restart scan-code-backend
```

### 场景 3：所有备份都损坏

```bash
# 1. 使用预置数据库（会丢失数据）
cd /opt/scan-code
cp db.sqlite.init db.sqlite

# 2. 重启服务
pm2 restart scan-code-backend

# 3. 重新开始扫码
# 默认账号：admin / admin123
```

---

## 🛡️ 预防措施

### 1. 定期手动备份

```bash
# 添加到 crontab（每天凌晨 2 点备份）
0 2 * * * cd /opt/scan-code && cp db.sqlite backups/db.sqlite.daily_$(date +\%Y\%m\%d).backup
```

### 2. 备份到其他位置

```bash
# 备份到其他服务器或云存储
scp /opt/scan-code/db.sqlite user@backup-server:/backups/
```

### 3. 更新前手动备份

```bash
# 在运行 update.sh 前
cd /opt/scan-code
cp db.sqlite /tmp/db.sqlite.manual_backup
```

### 4. 使用正确的更新方式

```bash
# ✅ 正确：从项目根目录运行
cd /opt/scan-code
bash scripts/update.sh

# ❌ 错误：在 scripts 目录运行
cd /opt/scan-code/scripts
bash update.sh  # 可能导致问题
```

---

## 📊 数据库维护

### 优化数据库

```bash
cd /opt/scan-code
sqlite3 db.sqlite "VACUUM;"
```

### 分析数据库

```bash
sqlite3 db.sqlite "ANALYZE;"
```

### 导出数据

```bash
# 导出为 SQL
sqlite3 db.sqlite .dump > db_backup.sql

# 导出特定表
sqlite3 db.sqlite "SELECT * FROM scan_records;" > scan_records.csv
```

---

## 🚨 紧急联系

如果以上方法都无法解决问题：

1. **保留现场**
   ```bash
   # 不要删除任何文件
   # 保留所有备份
   # 记录错误信息
   ```

2. **收集信息**
   ```bash
   # 系统信息
   uname -a
   
   # 磁盘空间
   df -h
   
   # 数据库状态
   ls -lh db.sqlite*
   
   # 服务日志
   pm2 logs scan-code-backend --lines 100
   ```

3. **寻求帮助**
   - 查看项目文档
   - 联系技术支持
   - 提供收集的信息

---

## ✅ 验证恢复成功

```bash
# 1. 数据库完整性
sqlite3 db.sqlite "PRAGMA integrity_check;"
# 输出：ok

# 2. 服务状态
pm2 list
# scan-code-backend 应该是 online

# 3. API 测试
curl http://localhost:3001/api/health
# 应该返回 {"status":"ok"}

# 4. 前端访问
curl http://localhost:6006
# 应该返回 HTML 内容

# 5. 登录测试
# 浏览器访问并登录
```

---

**记住：** 定期备份是最好的保护！🛡️
