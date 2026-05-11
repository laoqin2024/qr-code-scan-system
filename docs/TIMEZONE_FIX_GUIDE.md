# 时区修复独立脚本使用指南

## 📦 脚本信息

**文件名**: `fix-timezone-standalone.sh`
**大小**: 8KB
**用途**: 修复数据库中的时间字段，从 UTC 转换为 UTC+8（北京时间）

---

## ⚠️ 重要提示

### 只能运行一次！

- ❌ **不要重复运行**：重复运行会导致时间再次 +8 小时
- ✅ **自动备份**：运行前会自动备份数据库
- ✅ **完整性检查**：运行后会验证数据库完整性
- ✅ **数据验证**：确保数据数量不变

---

## 🚀 使用方法

### 方法 1：直接在服务器上运行（推荐）

```bash
# 1. 上传脚本到服务器
scp /tmp/scan-code-update/fix-timezone-standalone.sh root@192.168.8.91:/tmp/

# 2. SSH 登录服务器
ssh root@192.168.8.91

# 3. 进入项目目录
cd /opt/scan-code

# 4. 运行脚本
bash /tmp/fix-timezone-standalone.sh
```

### 方法 2：在项目目录运行

```bash
# 如果脚本已在项目目录
cd /opt/scan-code
bash fix-timezone-standalone.sh
```

---

## 📋 脚本执行流程

### 1. 检查环境

```
✅ 检测项目目录
✅ 检查数据库文件
✅ 检查 sqlite3 是否安装
```

### 2. 备份数据库

```
📦 备份位置优先级：
1. /var/backups/scan-code/
2. ~/.scan-code-backups/
3. /tmp/scan-code-backups/

备份文件名：
db.sqlite.before_timezone_fix_YYYYMMDD_HHMMSS
```

### 3. 显示当前数据

```
📊 当前数据统计：
- 扫码记录: X 条
- 用户: X 个
- 客户: X 个
- 产品: X 个

🕐 修复前的时间示例：
- 扫码记录最新时间: 2025-05-10 03:30:00
- 用户最新时间: 2025-05-10 02:15:00
```

### 4. 执行时区修复

```
⏰ 修复内容：
- 扫码记录时间 +8 小时
- 用户时间 +8 小时
- 客户时间 +8 小时
- 产品时间 +8 小时
- 审计日志时间 +8 小时
```

### 5. 验证结果

```
🔍 验证数据库完整性
📊 验证数据数量
🕐 显示修复后的时间

修复后的时间示例：
- 扫码记录最新时间: 2025-05-10 11:30:00
- 用户最新时间: 2025-05-10 10:15:00
```

---

## 📊 执行示例

```bash
root@server:/opt/scan-code# bash /tmp/fix-timezone-standalone.sh

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏰ 时区修复脚本
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  本脚本将修复数据库中的时间字段
⚠️  将所有时间从 UTC 转换为 UTC+8（北京时间）

❌ ⚠️  重要提示：
  1. 本脚本只能运行一次！
  2. 重复运行会导致时间错误（再次 +8 小时）
  3. 运行前会自动备份数据库

是否继续？(y/n) y

✅ 检测到项目目录: /opt/scan-code

ℹ️  📦 备份数据库...
✅ 数据库已备份到: /var/backups/scan-code/db.sqlite.before_timezone_fix_20250510_114500
✅ 备份文件验证通过

ℹ️  📊 当前数据统计...
  扫码记录: 150 条
  用户: 5 个
  客户: 3 个
  产品: 10 个

ℹ️  🕐 修复前的时间示例...
  扫码记录最新时间: 2025-05-10 03:30:00
  用户最新时间: 2025-05-10 02:15:00

ℹ️  ⏰ 开始修复时区...
✅ 时区修复完成

ℹ️  🔍 验证数据库完整性...
✅ 数据库完整性检查通过

ℹ️  🕐 修复后的时间示例...
  扫码记录最新时间: 2025-05-10 11:30:00
  用户最新时间: 2025-05-10 10:15:00

ℹ️  📊 验证数据统计...
  扫码记录: 150 条
  用户: 5 个
  客户: 3 个
  产品: 10 个
✅ 数据数量验证通过

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ 时区修复完成！
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ️  📋 修复信息:
  项目目录: /opt/scan-code
  备份文件: /var/backups/scan-code/db.sqlite.before_timezone_fix_20250510_114500
  修复记录: 150 条扫码记录
  修复用户: 5 个用户
  修复客户: 3 个客户
  修复产品: 10 个产品

ℹ️  🔧 下一步操作:
  1. 重启后端服务: pm2 restart scan-code-backend
  2. 浏览器访问并验证时间显示
  3. 检查新扫码记录的时间是否正确

⚠️  ⚠️  重要提示：
  - 本脚本已运行，请勿再次运行！
  - 新数据会自动使用正确的时区
  - 如需恢复，使用备份文件: /var/backups/scan-code/db.sqlite.before_timezone_fix_20250510_114500

ℹ️  💾 恢复命令（如果需要）:
  cp /var/backups/scan-code/db.sqlite.before_timezone_fix_20250510_114500 /opt/scan-code/db.sqlite
  pm2 restart scan-code-backend
```

---

## ✅ 验证修复结果

### 1. 重启服务

```bash
pm2 restart scan-code-backend
```

### 2. 检查时间显示

```bash
# 查看最新扫码记录的时间
sqlite3 /opt/scan-code/db.sqlite "SELECT id, code_text, created_at FROM scans ORDER BY id DESC LIMIT 5;"
```

### 3. 浏览器验证

```
1. 访问 http://192.168.8.91:6006
2. 进入查询页面
3. 查看扫码记录的时间
4. 确认时间是否为北京时间
```

### 4. 测试新数据

```
1. 进入扫码页面
2. 扫描一个新的二维码
3. 查看记录时间
4. 确认新数据使用正确时区
```

---

## 🚨 如果出现问题

### 问题 1：时间修复错误

```bash
# 恢复备份
cp /var/backups/scan-code/db.sqlite.before_timezone_fix_YYYYMMDD_HHMMSS /opt/scan-code/db.sqlite

# 重启服务
pm2 restart scan-code-backend
```

### 问题 2：数据库损坏

```bash
# 查找备份
ls -lh /var/backups/scan-code/
ls -lh ~/.scan-code-backups/
ls -lh /tmp/scan-code-backups/

# 恢复最新备份
cp /var/backups/scan-code/db.sqlite.before_timezone_fix_YYYYMMDD_HHMMSS /opt/scan-code/db.sqlite

# 验证
sqlite3 /opt/scan-code/db.sqlite "PRAGMA integrity_check;"

# 重启服务
pm2 restart scan-code-backend
```

### 问题 3：sqlite3 未安装

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install sqlite3

# CentOS/RHEL
sudo yum install sqlite
```

---

## 📝 注意事项

### 运行前

- ✅ 确保数据库文件存在
- ✅ 确保有足够的磁盘空间（备份需要）
- ✅ 确保 sqlite3 已安装
- ✅ 确认只运行一次

### 运行中

- ✅ 不要中断脚本执行
- ✅ 观察输出信息
- ✅ 确认备份成功
- ✅ 确认验证通过

### 运行后

- ✅ 重启后端服务
- ✅ 验证时间显示
- ✅ 测试新数据
- ✅ 保留备份文件

---

## 💡 常见问题

### Q1: 脚本可以运行多次吗？

**A**: ❌ 不可以！只能运行一次。重复运行会导致时间再次 +8 小时。

### Q2: 如果不小心运行了两次怎么办？

**A**: 使用备份恢复：
```bash
cp /var/backups/scan-code/db.sqlite.before_timezone_fix_YYYYMMDD_HHMMSS /opt/scan-code/db.sqlite
pm2 restart scan-code-backend
```

### Q3: 新数据还需要修复吗？

**A**: ❌ 不需要！新数据会自动使用正确的时区（UTC+8）。

### Q4: 备份文件在哪里？

**A**: 优先级顺序：
1. `/var/backups/scan-code/`
2. `~/.scan-code-backups/`
3. `/tmp/scan-code-backups/`

### Q5: 如何验证修复成功？

**A**: 
1. 查看脚本输出的修复前后时间对比
2. 浏览器查看扫码记录时间
3. 新扫码一条记录，查看时间是否正确

---

## 🎯 总结

### 脚本特点

- ✅ 独立运行，不依赖 Node.js
- ✅ 自动备份数据库
- ✅ 完整性检查
- ✅ 数据验证
- ✅ 详细的输出信息
- ✅ 错误自动恢复

### 使用场景

- ✅ 历史数据时间显示错误（UTC 时间）
- ✅ 需要将时间转换为北京时间
- ✅ 一次性修复所有历史数据

### 安全保障

- ✅ 运行前自动备份
- ✅ 验证备份文件
- ✅ 检查数据库完整性
- ✅ 验证数据数量
- ✅ 提供恢复命令

---

**准备好了吗？上传脚本并运行吧！** 🚀

```bash
scp /tmp/scan-code-update/fix-timezone-standalone.sh root@192.168.8.91:/tmp/
ssh root@192.168.8.91
cd /opt/scan-code
bash /tmp/fix-timezone-standalone.sh
```
