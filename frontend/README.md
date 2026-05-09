# 二维码扫码防错系统 - 前端

基于 React + TypeScript + Vite 构建的现代化 Web 应用。

## 📋 目录

- [技术栈](#技术栈)
- [功能模块](#功能模块)
- [项目结构](#项目结构)
- [开发指南](#开发指南)
- [构建部署](#构建部署)
- [环境配置](#环境配置)

---

## 🛠 技术栈

- **框架：** React 18
- **语言：** TypeScript
- **构建工具：** Vite
- **路由：** React Router v6
- **HTTP客户端：** Axios
- **样式：** CSS Modules

---

## 📦 功能模块

### 1. 用户认证
- 登录/登出
- 密码修改
- 权限控制

### 2. 扫码录入
- 二维码扫描
- 实时长度验证
- 扫码枪模式
- 连续扫码模式
- 今日统计

### 3. 查询记录
- 多条件筛选
- 分页显示
- 数据导出

### 4. 客户管理
- 客户CRUD
- 期望长度设置

### 5. 产品管理
- 产品CRUD
- 客户关联

### 6. 用户管理（超级管理员）
- 用户CRUD
- 角色分配
- 状态管理

### 7. 权限管理（超级管理员）
- 产品授权
- 批量授权
- 权限撤销

### 8. 系统管理（超级管理员）
- 清理测试数据
- 删除错误记录
- 初始化系统

### 9. 审计日志
- 操作记录查询
- 多维度筛选
- 统计分析
- 日志导出

---

## 📁 项目结构

```
frontend/
├── public/              # 静态资源
├── src/
│   ├── api.ts          # API接口定义
│   ├── types.ts        # TypeScript类型定义
│   ├── App.tsx         # 根组件
│   ├── main.tsx        # 入口文件
│   ├── components/     # 公共组件
│   │   ├── Navbar.tsx          # 导航栏
│   │   ├── Navbar.css
│   │   └── ProtectedRoute.tsx  # 路由守卫
│   ├── pages/          # 页面组件
│   │   ├── Login.tsx           # 登录页
│   │   ├── Scan.tsx            # 扫码录入
│   │   ├── Query.tsx           # 查询记录
│   │   ├── Customers.tsx       # 客户管理
│   │   ├── Products.tsx        # 产品管理
│   │   ├── Users.tsx           # 用户管理
│   │   ├── PermissionManagement.tsx  # 权限管理
│   │   ├── SystemManagement.tsx      # 系统管理
│   │   └── AuditLogs.tsx       # 审计日志
│   └── styles/         # 样式文件
│       ├── Page.css            # 页面通用样式
│       └── Scan.css            # 扫码页面样式
├── index.html          # HTML模板
├── package.json        # 依赖配置
├── tsconfig.json       # TypeScript配置
├── vite.config.ts      # Vite配置
└── README.md           # 本文件
```

---

## 🚀 开发指南

### 安装依赖

```bash
cd frontend
npm install
```

### 启动开发服务器

```bash
npm run dev
```

访问：http://localhost:5173

### 构建生产版本

```bash
npm run build
```

构建产物在 `dist/` 目录

### 预览生产构建

```bash
npm run preview
```

---

## 🔧 环境配置

### 开发环境

开发环境使用 Vite 的代理功能，自动转发 API 请求到后端。

**vite.config.ts:**
```typescript
export default defineConfig({
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:3001',
        changeOrigin: true,
      },
    },
  },
});
```

### 生产环境

生产环境需要配置 Nginx 反向代理：

```nginx
location /api {
    proxy_pass http://localhost:3001;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
}
```

---

## 🎨 样式规范

### CSS组织

- **Page.css:** 页面通用样式（表格、表单、卡片等）
- **Scan.css:** 扫码页面专用样式
- **Navbar.css:** 导航栏样式

### 命名规范

- 使用 kebab-case 命名 CSS 类
- 组件样式使用 BEM 命名法
- 全局样式使用语义化命名

### 响应式设计

- 移动端优先
- 使用 CSS Grid 和 Flexbox
- 断点：768px（平板）、1024px（桌面）

---

## 🔐 权限系统

### 角色定义

| 角色 | 权限 |
|------|------|
| super_admin | 所有权限 |
| customer_admin | 管理自己创建的客户、产品、用户 |
| operator | 扫码录入、查看自己的记录 |
| viewer | 查看授权产品的记录 |

### 路由守卫

使用 `ProtectedRoute` 组件保护路由：

```tsx
<Route 
  path="/users" 
  element={
    <ProtectedRoute requiredRole="super_admin">
      <Users />
    </ProtectedRoute>
  } 
/>
```

### API权限

所有 API 请求自动携带 JWT Token：

```typescript
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers['Authorization'] = `Bearer ${token}`;
  }
  return config;
});
```

---

## 📊 状态管理

### 本地存储

使用 localStorage 存储：
- `token`: JWT认证令牌
- `user`: 用户信息（username, role, display_name）

### 组件状态

使用 React Hooks 管理组件状态：
- `useState`: 本地状态
- `useEffect`: 副作用处理
- `useRef`: DOM引用

---

## 🎯 核心功能实现

### 1. 扫码录入

**特点：**
- 支持扫码枪自动提交
- 实时长度验证
- 连续扫码模式
- 今日统计展示

**关键代码：**
```typescript
// 扫码枪检测
const handleCodeChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
  const value = e.target.value;
  setCodeText(value);
  
  // 300ms内没有新输入则自动提交
  if (autoSubmit && value.trim()) {
    clearTimeout(autoSubmitTimerRef.current);
    autoSubmitTimerRef.current = setTimeout(() => {
      form.requestSubmit();
    }, 300);
  }
};
```

### 2. 权限管理

**特点：**
- 多选授权
- 批量操作
- 实时更新

**关键代码：**
```typescript
// 批量授权
const handleBatchGrant = async () => {
  await permissionAPI.batchGrantPermissions(userId, {
    product_ids: selectedProducts,
    can_scan: true,
    can_view: true,
  });
};
```

### 3. 审计日志

**特点：**
- 多维度筛选
- 分页查询
- CSV导出

**关键代码：**
```typescript
// 导出CSV
const handleExport = () => {
  auditLogAPI.exportCSV({
    user_id: filterUserId,
    action: filterAction,
    start_time: filterStartTime,
    end_time: filterEndTime,
  });
};
```

---

## 🐛 调试技巧

### 开发工具

- React DevTools
- Redux DevTools（如果使用）
- Network面板（查看API请求）

### 常见问题

**1. API请求失败**
- 检查后端是否启动
- 检查代理配置
- 查看Network面板

**2. 路由跳转失败**
- 检查路由配置
- 检查权限守卫
- 查看Console错误

**3. 样式不生效**
- 检查CSS导入
- 检查类名拼写
- 清除浏览器缓存

---

## 📝 代码规范

### TypeScript

- 使用接口定义类型
- 避免使用 `any`
- 使用可选链和空值合并

### React

- 使用函数组件
- 使用 Hooks
- 避免不必要的重渲染

### 命名规范

- 组件：PascalCase
- 函数：camelCase
- 常量：UPPER_SNAKE_CASE
- 文件：kebab-case

---

## 🔄 版本历史

### v5.0 (2025-01-06)
- ✅ 添加审计日志功能
- ✅ 完善权限系统
- ✅ 优化用户体验

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

## 📚 相关文档

- [后端README](../backend/README.md)
- [快速开始](../QUICK_START.md)
- [部署指南](../DELIVERY_CHECKLIST.md)
- [网络访问配置](../NETWORK_ACCESS.md)
- [权限管理指南](../docs/guides/权限管理使用指南.md)

---

## 🤝 贡献指南

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

### 开发流程

1. 创建功能分支
2. 开发并测试
3. 提交代码
4. 创建Pull Request
5. 代码审查
6. 合并到主分支

---

## 📞 联系方式

如有问题，请联系开发团队。

---

**最后更新：** 2025-01-06  
**版本：** v5.0
