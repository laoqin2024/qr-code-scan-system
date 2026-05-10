# 数据库初始化说明

## 📋 概述

本项目提供两种数据库初始化方式：
1. **使用预置数据库文件**（推荐，快速可靠）
2. **运行初始化脚本**（需要 Node.js 环境）

---

## 🚀 方式一：使用预置数据库文件（推荐）

### 优点
- ✅ 快速：直接复制文件，无需运行脚本
- ✅ 可靠：避免初始化脚本执行失败
- ✅ 一致：所有环境使用相同的初始数据
- ✅ 无依赖：不需要 Node.js 环境

### 使用方法

```bash
# 1. 复制预置数据库文件
cp db.sqlite.init db.sqlite

# 2. 启动服务即可使用
```

### 自动部署脚本支持

部署脚本 `scripts/deploy.sh` 已自动支持此方式：
- 如果存在 `db.sqlite.init` 文件，优先使用
- 如果不存在，则运行初始化脚本

---

## 🔧 方式二：运行初始化脚本

### 前提条件
- Node.js 环境
- 已安装项目依赖

### 使用方法

```bash
# 1. 进入后端目录
cd backend

# 2. 运行初始化脚本
npm run init-db
```

### 注意事项
- 如果数据库已存在数据，脚本会自动跳过初始化
- 如需重新初始化，请先删除数据库文件：`rm db.sqlite`

---

## 👥 默认账号

初始化后的数据库包含以下测试账号：

### 超级管理员
- **用户名**: `admin`
- **密码**: `admin123`
- **权限**: 全局管理，可管理所有客户、产品、用户

### 客户管理员（测试账号）
- **用户名**: `test`
- **密码**: `test123`
- **权限**: 可创建客户、产品、用户（未绑定特定客户）

### 客户管理员（富士康）
- **用户名**: `foxconn_manager`
- **密码**: `manager123`
- **权限**: 管理富士康的产品和操作员

### 客户管理员（比亚迪）
- **用户名**: `byd_manager`
- **密码**: `manager123`
- **权限**: 管理比亚迪的产品和操作员

### 操作员（富士康）
- **用户名**: `operator_zhang`
- **密码**: `operator123`
- **权限**: 扫描 iPhone 15 Pro 和 iPad Air

### 操作员（比亚迪）
- **用户名**: `operator_li`
- **密码**: `operator123`
- **权限**: 扫描海豹电池模组

### 查看者（富士康）
- **用户名**: `viewer_wang`
- **密码**: `viewer123`
- **权限**: 查看 iPhone 15 Pro 记录

---

## 🔄 更新预置数据库文件

如果需要更新仓库中的预置数据库文件：

```bash
# 1. 确保当前数据库处于理想状态
# 2. 创建新的预置文件
cp db.sqlite db.sqlite.init

# 3. 提交到仓库
git add db.sqlite.init
git commit -m "更新预置数据库文件"
git push
```

---

## 🗄️ 数据库结构

初始化后的数据库包含以下表：

- `users` - 用户表
- `customers` - 客户表
- `products` - 产品表
- `user_product_permissions` - 用户产品权限表
- `scan_records` - 扫码记录表
- `audit_logs` - 审计日志表

详细结构请参考 `backend/src/schema-v2.sql`

---

## ⚠️ 安全提示

1. **生产环境必须修改默认密码**
2. 数据库文件 `db.sqlite` 包含敏感数据，不应提交到版本控制
3. 预置文件 `db.sqlite.init` 仅用于初始化，不包含生产数据
4. 定期备份生产数据库

---

## 🐛 故障排除

### 问题：初始化脚本报错 "UNIQUE constraint failed"

**原因**: 数据库已存在数据

**解决方案**:
```bash
# 方案 1: 删除数据库重新初始化
rm db.sqlite
npm run init-db

# 方案 2: 使用预置数据库文件
cp db.sqlite.init db.sqlite
```

### 问题：找不到 db.sqlite.init 文件

**原因**: 文件未从仓库拉取或被误删

**解决方案**:
```bash
# 方案 1: 从仓库重新拉取
git checkout db.sqlite.init

# 方案 2: 运行初始化脚本生成
cd backend
npm run init-db
# 然后创建预置文件
cd ..
cp db.sqlite db.sqlite.init
```

### 问题：数据库文件损坏

**解决方案**:
```bash
# 使用预置文件恢复
rm db.sqlite
cp db.sqlite.init db.sqlite
```

---

## 📚 相关文档

- [快速开始](QUICK_START.md)
- [部署指南](docs/DEPLOYMENT_GUIDE.md)
- [故障排除](docs/TROUBLESHOOTING.md)
