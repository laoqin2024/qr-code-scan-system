# 项目目录结构说明

本文档详细说明项目的目录结构和文件组织。

## 📁 根目录结构

```
scan-code/
├── backend/                 # 后端服务（Node.js + Express）
├── frontend/                # 前端应用（React + TypeScript）
├── scripts/                 # 脚本工具
├── docs/                    # 文档
├── logs/                    # 日志文件
├── backups/                 # 数据库备份
├── node_modules/            # 根依赖（工作区）
├── db.sqlite               # SQLite数据库
├── package.json            # 根依赖配置
├── README.md               # 项目说明
├── QUICK_START.md          # 快速开始指南
├── DELIVERY_CHECKLIST.md   # 部署清单
└── NETWORK_ACCESS.md       # 网络访问配置
```

---

## 🔙 后端目录（backend/）

```
backend/
├── src/
│   ├── middleware/
│   │   └── auth.ts                 # 认证中间件
│   ├── routes/
│   │   ├── audit-logs.ts          # 审计日志路由
│   │   ├── auth.ts                # 认证路由
│   │   ├── customers.ts           # 客户管理路由
│   │   ├── permissions.ts         # 权限管理路由
│   │   ├── products.ts            # 产品管理路由
│   │   ├── scans.ts               # 扫码管理路由
│   │   └── users.ts               # 用户管理路由
│   ├── app.ts                     # Express应用配置
│   ├── db.ts                      # 数据库连接
│   ├── server.ts                  # 服务器入口
│   ├── types.ts                   # TypeScript类型定义
│   ├── init-db-v2.ts             # 数据库初始化脚本
│   ├── schema-v2.sql             # 数据库表结构
│   └── migrate-v3.ts             # 数据库迁移脚本
├── node_modules/                  # 后端依赖
├── .env                          # 环境变量配置
├── package.json                  # 后端依赖配置
├── tsconfig.json                 # TypeScript配置
└── README.md                     # 后端说明文档
```

### 关键文件说明

**src/app.ts**
- Express应用配置
- 中间件注册
- 路由注册
- CORS配置

**src/db.ts**
- SQLite数据库连接
- 数据库初始化
- 连接池管理

**src/middleware/auth.ts**
- JWT认证
- 权限检查
- 角色验证

**src/routes/**
- 各模块的API路由
- 请求处理
- 数据验证
- 权限控制

---

## 🎨 前端目录（frontend/）

```
frontend/
├── src/
│   ├── components/
│   │   ├── Navbar.tsx             # 导航栏组件
│   │   ├── Navbar.css             # 导航栏样式
│   │   └── ProtectedRoute.tsx     # 路由守卫组件
│   ├── pages/
│   │   ├── Login.tsx              # 登录页面
│   │   ├── Scan.tsx               # 扫码录入页面
│   │   ├── Query.tsx              # 查询记录页面
│   │   ├── Customers.tsx          # 客户管理页面
│   │   ├── Products.tsx           # 产品管理页面
│   │   ├── Users.tsx              # 用户管理页面
│   │   ├── PermissionManagement.tsx  # 权限管理页面
│   │   ├── SystemManagement.tsx   # 系统管理页面
│   │   └── AuditLogs.tsx          # 审计日志页面
│   ├── styles/
│   │   ├── Page.css               # 页面通用样式
│   │   └── Scan.css               # 扫码页面样式
│   ├── api.ts                     # API接口定义
│   ├── types.ts                   # TypeScript类型定义
│   ├── App.tsx                    # 根组件
│   └── main.tsx                   # 应用入口
├── public/                        # 静态资源
├── node_modules/                  # 前端依赖
├── index.html                     # HTML模板
├── package.json                   # 前端依赖配置
├── tsconfig.json                  # TypeScript配置
├── vite.config.ts                 # Vite配置
└── README.md                      # 前端说明文档
```

### 关键文件说明

**src/api.ts**
- Axios实例配置
- API接口定义
- 请求拦截器
- 响应拦截器

**src/types.ts**
- TypeScript类型定义
- 接口定义
- 枚举定义

**src/App.tsx**
- 路由配置
- 全局状态
- 主题配置

**src/components/ProtectedRoute.tsx**
- 路由守卫
- 权限验证
- 重定向逻辑

**src/pages/**
- 各功能页面组件
- 业务逻辑
- 状态管理

---

## 🔧 脚本目录（scripts/）

```
scripts/
├── tests/                         # 测试脚本
│   ├── test-api.sh               # API接口测试
│   ├── test-customer-admin-permissions.sh  # 客户管理员权限测试
│   ├── test-scan-permissions.sh  # 扫码权限测试
│   ├── test-query-permissions.sh # 查询权限测试
│   ├── test-initialize-system.sh # 系统初始化测试
│   └── ...                       # 更多测试脚本
├── start.sh                      # 启动脚本
├── stop.sh                       # 停止脚本
├── status.sh                     # 状态检查脚本
├── start-network.sh              # 局域网启动脚本
└── migrate-add-created-by.sh     # 数据库迁移脚本
```

### 脚本说明

**start.sh**
- 启动后端和前端开发服务器
- 检查端口占用
- 后台运行

**stop.sh**
- 停止所有服务
- 清理进程

**status.sh**
- 检查服务状态
- 显示运行信息

**start-network.sh**
- 启动局域网访问模式
- 显示局域网IP地址

**migrate-add-created-by.sh**
- 数据库迁移脚本
- 添加created_by字段
- 数据备份

---

## 📚 文档目录（docs/）

```
docs/
├── guides/                        # 使用指南
│   └── 权限管理使用指南.md
├── reports/                       # 功能报告
│   ├── 审计日志功能实施报告.md
│   ├── 初始化系统功能完成报告.md
│   ├── 产品筛选联动功能完成报告.md
│   ├── 用户管理权限修复完成报告.md
│   ├── 清空测试数据功能完善报告.md
│   ├── 权限系统v3完整实施报告.md
│   ├── 多客户权限优化完成报告.md
│   └── ...                       # 更多功能报告
└── archive/                       # 归档文档
    └── ...                       # 历史文档
```

### 文档分类

**guides/**
- 用户使用指南
- 管理员手册
- 操作说明

**reports/**
- 功能实施报告
- 问题修复报告
- 优化方案

**archive/**
- 历史文档
- 废弃文档
- 参考资料

---

## 📊 日志目录（logs/）

```
logs/
├── backend.log                    # 后端日志
└── frontend.log                   # 前端日志
```

### 日志说明

**backend.log**
- 后端服务日志
- API请求日志
- 错误日志

**frontend.log**
- 前端构建日志
- 开发服务器日志
- 错误日志

---

## 💾 备份目录（backups/）

```
backups/
├── db.sqlite.backup               # 数据库备份
├── db.sqlite.backup-v3            # 版本备份
└── db.sqlite.backup-before-created-by-*  # 迁移前备份
```

### 备份说明

- 自动备份：重要操作前自动备份
- 手动备份：可手动复制db.sqlite
- 恢复：复制备份文件覆盖db.sqlite

---

## 🗄️ 数据库文件

**db.sqlite**
- SQLite数据库文件
- 包含所有业务数据
- 轻量级，无需安装

### 数据库表结构

- users - 用户表
- customers - 客户表
- products - 产品表
- scans - 扫码记录表
- user_product_permissions - 用户产品权限表
- audit_logs - 审计日志表

---

## 📦 依赖管理

### 根目录（工作区）

**package.json**
- 工作区配置
- 共享依赖
- 脚本命令

### 后端依赖

**backend/package.json**
- Express
- TypeScript
- better-sqlite3
- jsonwebtoken
- bcrypt
- cors

### 前端依赖

**frontend/package.json**
- React
- TypeScript
- Vite
- React Router
- Axios

---

## 🔒 配置文件

### 后端配置

**backend/.env**
```env
PORT=3001
JWT_SECRET=your-secret-key
NODE_ENV=development
```

**backend/tsconfig.json**
- TypeScript编译配置
- 模块解析
- 输出目录

### 前端配置

**frontend/vite.config.ts**
- Vite构建配置
- 代理配置
- 插件配置

**frontend/tsconfig.json**
- TypeScript编译配置
- JSX配置
- 路径别名

---

## 📝 文件命名规范

### 组件文件
- PascalCase: `Navbar.tsx`, `ProtectedRoute.tsx`
- 样式文件同名: `Navbar.css`

### 页面文件
- PascalCase: `Login.tsx`, `Scan.tsx`

### 工具文件
- camelCase: `api.ts`, `types.ts`

### 脚本文件
- kebab-case: `start.sh`, `test-api.sh`

### 文档文件
- 中文: `权限管理使用指南.md`
- 英文: `README.md`, `QUICK_START.md`

---

## 🎯 最佳实践

### 目录组织
- 按功能模块组织
- 相关文件放在一起
- 避免过深的嵌套

### 文件管理
- 定期清理无用文件
- 及时归档历史文档
- 保持目录结构清晰

### 版本控制
- 使用.gitignore排除
  - node_modules/
  - dist/
  - .env
  - *.log
  - db.sqlite（可选）

---

**最后更新：** 2025-01-06  
**版本：** v5.0
