## 开发文档：二维码扫码存储与查询系统

### 一、系统概述

这是一个基于 Web 的二维码扫码录入与查询系统，支持：
- 客户名称维护
- 产品型号维护
- 用户登录与权限控制
- 不同客户不同二维码长度校验
- 二维码扫码录入保存
- 按客户/产品/时间查询
- 时间保留到秒

---

### 二、技术栈

- 前端：`React + Vite + TypeScript`
- 后端：`Node.js + Express + TypeScript`
- 数据库：`SQLite`
- 身份验证：简单 JWT 或 session 机制
- 开发方式：前后端分离

---

### 三、项目目录结构

```
/frontend
  package.json
  tsconfig.json
  vite.config.ts
  /src
    main.tsx
    App.tsx
    api.ts
    types.ts
    /pages
      Login.tsx
      Customers.tsx
      Products.tsx
      Scan.tsx
      Query.tsx
    /components
      ProtectedRoute.tsx

 /backend
  package.json
  tsconfig.json
  /src
    app.ts
    server.ts
    /routes
      auth.ts
      customers.ts
      products.ts
      scans.ts
    db.ts
    schema.sql
    types.ts
```

---

### 四、数据库设计

#### 1. `users`
- `id`：INTEGER PK
- `username`：TEXT 唯一
- `password_hash`：TEXT
- `role`：TEXT（`admin` / `operator`）
- `created_at`：TEXT

#### 2. `customers`
- `id`：INTEGER PK
- `name`：TEXT
- `expected_length`：INTEGER
- `description`：TEXT
- `created_at`：TEXT

#### 3. `products`
- `id`：INTEGER PK
- `model`：TEXT
- `customer_id`：INTEGER（关联 `customers.id`）
- `description`：TEXT
- `created_at`：TEXT

#### 4. `scans`
- `id`：INTEGER PK
- `customer_id`：INTEGER
- `product_id`：INTEGER
- `code_text`：TEXT
- `code_length`：INTEGER
- `is_valid`：BOOLEAN
- `error_reason`：TEXT
- `created_at`：TEXT（保留到秒）
- `notes`：TEXT

---

### 五、后端 API 设计

#### Auth
- `POST /api/auth/login`
  - 请求：`{ username, password }`
  - 返回：`{ token, role }`

- `GET /api/auth/me`
  - 获取当前用户信息

#### 客户管理
- `GET /api/customers`
- `POST /api/customers`
  - 请求：`{ name, expected_length, description }`
- `PUT /api/customers/:id`
- `DELETE /api/customers/:id`

#### 产品管理
- `GET /api/products`
- `POST /api/products`
  - 请求：`{ model, customer_id, description }`
- `PUT /api/products/:id`
- `DELETE /api/products/:id`

#### 扫码录入
- `POST /api/scans`
  - 请求：`{ customer_id, product_id, code_text, notes? }`
  - 处理逻辑：
    - 计算 `code_length`
    - 对比 `customer.expected_length`
    - 生成 `is_valid`
    - 生成 `error_reason`
    - 保存记录

#### 查询
- `GET /api/scans`
  - 支持参数：
    - `customer_id`
    - `product_id`
    - `start_time`
    - `end_time`
    - `is_valid`

---

### 六、前端页面与交互

#### `Login`
- 输入用户名和密码
- 调用登录接口
- 登录成功后跳转主页面

#### `Customers`
- 展示客户列表
- 新增客户
- 编辑客户
- 删除客户
- 关键字段：客户名称、二维码期望长度、描述

#### `Products`
- 展示产品型号列表
- 新增产品型号
- 编辑产品型号
- 删除产品型号
- 关键字段：型号、关联客户、描述

#### `Scan`
- 选择客户
- 选择产品
- 输入或粘贴二维码文本
- 实时校验长度
- 异常长度显示红色警告
- 提交保存
- 显示保存结果和错误原因

#### `Query`
- 筛选条件：
  - 客户
  - 产品
  - 起始时间
  - 结束时间
  - 是否有效
- 展示结果：
  - 客户名称
  - 产品型号
  - 二维码内容
  - 长度
  - 校验状态
  - 录入时间（到秒）

---

### 七、二维码防错校验逻辑

核心规则：
- 每个客户配置一个 `expected_length`
- 扫码时取二维码实际长度 `code_length`
- 比较：
  - `code_length == expected_length` => 正常
  - `code_length < expected_length` => 长度不足
  - `code_length > expected_length` => 长度超出
- 前端立即红色报警显示
- 后端也做同样判断并保存异常状态

---

### 八、开发步骤

1. 创建项目目录：`frontend/` 和 `backend/`
2. 初始化依赖：
   - 后端：`Express`, `sqlite3`, `jsonwebtoken`, `bcrypt`, `cors`
   - 前端：`React`, `React Router`, `axios`
3. 设计并创建 SQLite schema
4. 实现后端：
   - 数据库连接
   - 用户登录
   - 客户/产品/扫码/查询接口
   - 权限校验中间件
5. 实现前端：
   - 登录页面
   - 客户管理页面
   - 产品管理页面
   - 扫码录入页面
   - 查询页面
6. 联调测试：
   - 登录与权限
   - 客户/产品维护
   - 正常与异常扫码
   - 查询结果

---

### 九、注意事项

- 先用 SQLite 开发，后期迁 MySQL 可行
- 时间字段统一保存到秒，建议使用 ISO 8601 字符串
- 权限区分：
  - 管理员：可管理客户、产品
  - 操作员：可扫码录入、查询
- 如果你不熟悉任何栈，这个方案是目前最稳妥的全栈组合

---

### 十、后续交付

如果你需要，我可以继续生成：
- `schema.sql` 建表脚本
- 后端 `app.ts` 与路由结构
- 前端页面 `Login.tsx / Scan.tsx / Query.tsx` 设计
- 具体开发命令与启动说明