# 数据库部署问题修复说明

## 🚨 发现的问题

### 问题 1：db.sqlite 被提交到 Git 仓库

**严重性：** 高

**问题描述：**
- 运行时数据库文件 `db.sqlite` 被错误地提交到了 Git 仓库
- 导致每次克隆项目都会带下来这个数据库文件
- 这个数据库可能包含：
  - 已修改的密码
  - 过期的数据
  - 损坏的数据

**影响：**
- 用户部署后无法使用默认账号（admin/admin123）登录
- 数据库状态不可预测
- 安全风险（可能包含敏感数据）

**修复：**
- ✅ 已从 Git 仓库中移除 `db.sqlite`
- ✅ 只保留 `db.sqlite.init` 作为初始化模板
- ✅ `.gitignore` 已正确配置

### 问题 2：deploy.sh 数据库初始化逻辑不安全

**问题描述：**
```bash
# 旧逻辑
if [ -f "db.sqlite" ]; then
    read -p "是否重新初始化？(y/n) [默认: n]"
    if [ "$REINIT_DB" = "n" ]; then
        return  # 直接使用现有数据库，不检查完整性
    fi
fi
```

**问题：**
1. 不检查数据库完整性
2. 不检查数据库是否为空
3. 不验证数据库是否可用
4. 用户可能保留了损坏或空的数据库

---

## ✅ 已修复

### 修复 1：移除 db.sqlite 从 Git

```bash
# 已执行
git rm --cached db.sqlite
git commit -m "fix: 从仓库中移除运行时数据库文件"
git push
```

**效果：**
- 新部署不会再有错误的数据库文件
- 始终使用 `db.sqlite.init` 初始化
- 默认账号可以正常登录

### 修复 2：改进 deploy.sh 数据库初始化逻辑（待实施）

**新逻辑：**
```bash
1. 检查数据库是否存在
   ↓
2. 如果存在，检查完整性
   ↓
3. 如果完整，检查是否有用户数据
   ↓
4. 如果有数据，询问是否保留
   ↓
5. 如果为空或损坏，自动重新初始化
   ↓
6. 使用 db.sqlite.init 或运行初始化脚本
   ↓
7. 验证初始化结果
```

---

## 🚀 立即解决方案

### 对于已部署的服务器

如果你的服务器上已经部署了，但无法登录：

```bash
# 1. 进入项目目录
cd /opt/scan-code

# 2. 删除错误的数据库
rm -f db.sqlite

# 3. 使用预置数据库初始化
cp db.sqlite.init db.sqlite

# 4. 重启服务
pm2 restart scan-code-backend

# 5. 测试登录
# 用户名: admin
# 密码: admin123
```

### 对于新部署

```bash
# 1. 拉取最新代码（已移除 db.sqlite）
git clone https://gitee.com/laoqin1/qr-code-scan-system.git

# 2. 运行部署脚本
cd qr-code-scan-system
bash scripts/deploy.sh

# 3. 数据库会自动使用 db.sqlite.init 初始化
# 4. 默认账号可以正常登录
```

---

## 📋 验证修复

### 检查 Git 仓库

```bash
# 检查 db.sqlite 是否还在仓库中
git ls-files | grep "db.sqlite"

# 应该只看到：
# db.sqlite.init  ✅

# 不应该看到：
# db.sqlite  ❌
```

### 检查 .gitignore

```bash
cat .gitignore | grep "db.sqlite"

# 应该包含：
# db.sqlite
# db.sqlite.backup*
# !db.sqlite.init
```

### 测试部署

```bash
# 1. 克隆项目
git clone https://gitee.com/laoqin1/qr-code-scan-system.git test-deploy
cd test-deploy

# 2. 检查数据库文件
ls -lh db.sqlite*

# 应该只有：
# db.sqlite.init  ✅

# 不应该有：
# db.sqlite  ❌

# 3. 复制初始化数据库
cp db.sqlite.init db.sqlite

# 4. 测试数据库
sqlite3 db.sqlite "SELECT username FROM users WHERE role='super_admin';"

# 应该输出：
# admin  ✅
```

---

## 🛡️ 预防措施

### 1. 确保 .gitignore 正确

```gitignore
# 运行时数据库（不提交）
db.sqlite
db.sqlite.backup*

# 初始化模板（提交）
!db.sqlite.init
```

### 2. 定期检查

```bash
# 检查是否误提交了数据库
git ls-files | grep "db.sqlite$"

# 如果有输出，立即移除
git rm --cached db.sqlite
git commit -m "fix: 移除误提交的数据库文件"
git push
```

### 3. 部署前验证

```bash
# 部署前检查
cd /opt/scan-code
ls -lh db.sqlite*

# 如果 db.sqlite 存在且来自 Git
# 删除它并使用 db.sqlite.init
rm -f db.sqlite
cp db.sqlite.init db.sqlite
```

---

## 📊 问题影响范围

### 受影响的版本

- 所有包含 `db.sqlite` 的提交
- 从该文件被提交到现在的所有部署

### 受影响的用户

- 使用 `deploy.sh` 部署的用户
- 选择保留现有数据库的用户
- 无法使用默认账号登录的用户

### 修复后的效果

- ✅ 新部署始终使用正确的数据库
- ✅ 默认账号可以正常登录
- ✅ 数据库状态可预测
- ✅ 没有安全风险

---

## 🔄 后续改进计划

### 短期（已完成）

- ✅ 从 Git 移除 db.sqlite
- ✅ 验证 .gitignore 配置

### 中期（待实施）

- ⏳ 改进 deploy.sh 数据库初始化逻辑
- ⏳ 添加数据库完整性检查
- ⏳ 添加数据库验证步骤

### 长期

- 数据库迁移机制
- 自动备份机制
- 数据库版本管理

---

## 📞 如果还有问题

### 症状：无法登录

```bash
# 1. 检查数据库
cd /opt/scan-code
sqlite3 db.sqlite "SELECT username, role FROM users;"

# 2. 如果没有 admin 用户，重新初始化
rm -f db.sqlite
cp db.sqlite.init db.sqlite

# 3. 重启服务
pm2 restart scan-code-backend

# 4. 测试登录
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

### 症状：数据库损坏

```bash
# 1. 检查完整性
sqlite3 db.sqlite "PRAGMA integrity_check;"

# 2. 如果损坏，使用备份或重新初始化
cp db.sqlite.init db.sqlite

# 3. 重启服务
pm2 restart scan-code-backend
```

---

**总结：** 主要问题是 `db.sqlite` 被错误地提交到了 Git 仓库，导致部署时使用了错误的数据库。现在已经修复，新部署会正常工作。
