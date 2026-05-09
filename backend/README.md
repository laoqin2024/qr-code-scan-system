# scan-code-backend

## 启动方法

1. 安装依赖

```
npm install
```

2. 配置环境变量

`.env` 文件已生成，默认端口 3001，JWT 密钥可自定义。

3. 启动开发服务

```
npm run dev
```

4. 数据库文件 `db.sqlite` 会自动生成在项目根目录。

## 主要接口

- POST `/api/auth/login` 登录
- GET `/api/customers` 客户管理（仅管理员）
- POST `/api/customers` 新增客户（仅管理员）
- GET `/api/products` 产品管理（仅管理员）
- POST `/api/products` 新增产品（仅管理员）
- POST `/api/scans` 扫码录入（需登录）
- GET `/api/scans` 查询扫码记录（需登录）
