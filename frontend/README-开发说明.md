# 前端开发说明

## 目录结构

- `src/pages/` 主要页面组件
- `src/components/` 通用组件
- `src/api.ts` axios 实例与 API 封装
- `src/types.ts` 类型定义

## 页面说明

- `Login.tsx` 登录页，输入用户名密码，获取 token
- `Customers.tsx` 客户维护，管理员可增删改查
- `Products.tsx` 产品维护，管理员可增删改查
- `Scan.tsx` 扫码录入，选择客户/产品，输入二维码，自动校验长度
- `Query.tsx` 查询扫码记录，支持筛选

## 启动

1. `npm install`
2. `npm run dev`

## 注意
- 需后端服务已启动并允许跨域
- 代理已配置 `/api` 到后端 3001
