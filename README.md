# 二维码扫码防错系统

一个基于 React + Node.js 的企业级二维码扫码管理系统，支持多客户、多产品、多用户的权限管理。

## 🚀 一键部署

### 自动化部署（推荐）

在生产服务器上执行以下命令，自动完成部署：

```bash
bash <(curl -fsSL https://gitee.com/laoqin1/qr-code-scan-system/raw/main/scripts/deploy.sh)
```

或使用 GitHub（国外服务器）：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/laoqin2024/qr-code-scan-system/main/scripts/deploy.sh)
```

**部署脚本会自动：**
- ✅ 检查并安装依赖（Git、Node.js、编译工具）
- ✅ 克隆项目代码
- ✅ 配置环境变量
- ✅ 安装项目依赖
- ✅ 构建前端
- ✅ 初始化数据库
- ✅ 配置 Nginx（可选）
- ✅ 配置 PM2（可选）
- ✅ 启动服务

**详细文档：** [部署指南](DEPLOY.md) | [完整文档](docs/DEPLOYMENT_GUIDE.md)

---

## 📋 系统简介

本系统用于二维码扫描验证，支持设定期望长度，自动检测长度不足或超出的情况，帮助企业提高扫码准确率。

### 核心功能

- ✅ 二维码扫码录入（支持扫码枪）
- ✅ 实时长度验证
- ✅ 多客户、多产品管理
- ✅ 细粒度权限控制
- ✅ 扫码记录查询与导出
- ✅ 审计日志追踪
- ✅ 系统管理功能

---

## 🎯 适用场景

- 生产线质量控制
- 仓储物流管理
- 产品追溯系统
- 防伪验证系统

---

## 🛠 技术栈

### 前端
- React 18
- TypeScript
- Vite
- React Router
- Axios

### 后端
- Node.js
- Express
- TypeScript
- SQLite
- JWT认证

---

## 📦 手动部署

### 前置要求

- Node.js >= 16
- npm >= 8

### 安装

```bash
# 克隆项目
git clone <repository-url>
cd scan-code

# 安装依赖
npm install
```

### 启动开发环境

```bash
# 启动后端和前端
./scripts/start.sh

# 或分别启动
cd backend && npm run dev    # 后端: http://localhost:3001
cd frontend && npm run dev   # 前端: http://localhost:5173
```

### 默认账号

```
用户名: admin
密码: admin123
```

---

## 📁 项目结构

```
scan-code/
├── backend/                 # 后端服务
│   ├── src/
│   │   ├── routes/         # API路由
│   │   ├── middleware/     # 中间件
│   │   ├── app.ts          # Express应用
│   │   ├── db.ts           # 数据库
│   │   └── types.ts        # 类型定义
│   ├── package.json
│   └── README.md
├── frontend/                # 前端应用
│   ├── src/
│   │   ├── components/     # 组件
│   │   ├── pages/          # 页面
│   │   ├── styles/         # 样式
│   │   ├── api.ts          # API接口
│   │   └── types.ts        # 类型定义
│   ├── package.json
│   └── README.md
├── scripts/                 # 脚本工具
│   ├── start.sh            # 启动脚本
│   ├── stop.sh             # 停止脚本
│   ├── status.sh           # 状态检查
│   ├── start-network.sh    # 局域网启动
│   ├── migrate-add-created-by.sh  # 数据库迁移
│   └── tests/              # 测试脚本
├── docs/                    # 文档
│   ├── guides/             # 使用指南
│   ├── reports/            # 功能报告
│   └── archive/            # 归档文档
├── logs/                    # 日志文件
├── backups/                 # 数据库备份
├── db.sqlite               # 数据库文件
├── package.json            # 根依赖
├── README.md               # 本文件
├── QUICK_START.md          # 快速开始
├── DELIVERY_CHECKLIST.md   # 部署清单
└── NETWORK_ACCESS.md       # 网络访问配置
```

---

## 🔐 权限系统

### 角色定义

| 角色 | 说明 | 权限 |
|------|------|------|
| super_admin | 超级管理员 | 所有权限 |
| customer_admin | 客户管理员 | 管理自己创建的客户、产品、用户 |
| operator | 操作员 | 扫码录入、查看自己的记录 |
| viewer | 查看者 | 查看授权产品的记录 |

### 权限模型

基于 **创建者关系（created_by）** 的权限模型：
- 客户管理员可以管理自己创建的所有资源
- 超级管理员可以管理所有资源
- 操作员和查看者需要明确授权

详见：[权限管理使用指南](docs/guides/权限管理使用指南.md)

---

## 📊 功能模块

### 1. 扫码录入
- 支持扫码枪自动提交
- 实时长度验证
- 连续扫码模式
- 今日统计展示

### 2. 查询记录
- 多条件筛选（客户、产品、时间、状态）
- 分页显示
- 数据导出

### 3. 客户管理
- 客户CRUD
- 期望长度设置
- 创建者追踪

### 4. 产品管理
- 产品CRUD
- 客户关联
- 产品筛选联动

### 5. 用户管理（超级管理员）
- 用户CRUD
- 角色分配
- 状态管理（启用/禁用）

### 6. 权限管理（超级管理员）
- 产品授权
- 批量授权
- 权限撤销

### 7. 系统管理（超级管理员）
- 清理测试数据
- 删除错误记录
- 初始化系统

### 8. 审计日志
- 操作记录查询
- 多维度筛选
- 统计分析
- 日志导出

---

## 🚀 部署指南

### 开发环境

```bash
# 启动开发服务器
./scripts/start.sh
```

### 生产环境

详见：[部署清单](DELIVERY_CHECKLIST.md)

**关键步骤：**
1. 构建前端：`cd frontend && npm run build`
2. 配置环境变量
3. 启动后端：`cd backend && npm start`
4. 配置 Nginx 反向代理
5. 配置 PM2 进程管理

### 局域网访问

```bash
# 启动局域网访问模式
./scripts/start-network.sh
```

详见：[网络访问配置](NETWORK_ACCESS.md)

---

## 🔧 配置说明

### 后端配置

**backend/.env:**
```env
PORT=3001
JWT_SECRET=your-secret-key
NODE_ENV=production
```

### 前端配置

**开发环境：** Vite自动代理到后端

**生产环境：** 需要配置Nginx反向代理

---

## 📝 数据库

### 数据库类型
SQLite（轻量级、无需安装）

### 数据库文件
`db.sqlite`

### 备份
自动备份到 `backups/` 目录

### 迁移
```bash
# 执行数据库迁移
./scripts/migrate-add-created-by.sh
```

---

## 🧪 测试

### 功能测试

```bash
# 运行所有测试
cd scripts/tests
./test-*.sh
```

### 测试脚本

- `test-api.sh` - API接口测试
- `test-customer-admin-permissions.sh` - 客户管理员权限测试
- `test-scan-permissions.sh` - 扫码权限测试
- `test-query-permissions.sh` - 查询权限测试
- `test-initialize-system.sh` - 系统初始化测试
- 更多测试脚本见 `scripts/tests/`

---

## 📚 文档

### 使用指南
- [权限管理使用指南](docs/guides/权限管理使用指南.md)

### 功能报告
- [审计日志功能实施报告](docs/reports/审计日志功能实施报告.md)
- [初始化系统功能完成报告](docs/reports/初始化系统功能完成报告.md)
- [产品筛选联动功能完成报告](docs/reports/产品筛选联动功能完成报告.md)
- [用户管理权限修复完成报告](docs/reports/用户管理权限修复完成报告.md)
- 更多报告见 `docs/reports/`

### 开发文档
- [前端README](frontend/README.md)
- [后端README](backend/README.md)

---

## 🔄 版本历史

### v5.0 (2025-01-06)
- ✅ 添加审计日志功能
- ✅ 完善权限系统
- ✅ 优化用户体验
- ✅ 项目结构整理

### v4.0 (2025-01-06)
- ✅ 添加初始化系统功能
- ✅ 完善系统管理
- ✅ 修复产品筛选联动

### v3.0 (2025-01-06)
- ✅ 重构权限系统（基于created_by）
- ✅ 添加用户管理功能
- ✅ 添加权限管理功能

### v2.0 (2025-01-05)
- ✅ 添加多客户支持
- ✅ 优化扫码体验
- ✅ 添加查询功能

### v1.0 (2025-01-04)
- ✅ 基础功能实现
- ✅ 用户认证
- ✅ 扫码录入

---

## 🐛 故障排查

### 常见问题

**1. 无法启动后端**
- 检查端口3001是否被占用
- 检查Node.js版本
- 查看 `logs/backend.log`

**2. 无法启动前端**
- 检查端口5173是否被占用
- 清除node_modules重新安装
- 查看 `logs/frontend.log`

**3. 数据库错误**
- 检查db.sqlite文件权限
- 尝试从backups恢复
- 重新初始化数据库

**4. 权限问题**
- 检查用户角色
- 查看审计日志
- 联系管理员

---

## 🤝 贡献

欢迎提交Issue和Pull Request！

### 提交规范

```
feat: 新功能
fix: 修复bug
docs: 文档更新
style: 代码格式
refactor: 重构
test: 测试
chore: 构建/工具
```

---

## 📞 支持

如有问题，请：
1. 查看文档
2. 查看审计日志
3. 联系开发团队

---

## 📄 许可证

MIT License

---

**开发团队**  
**最后更新：** 2025-01-06  
**版本：** v5.0
