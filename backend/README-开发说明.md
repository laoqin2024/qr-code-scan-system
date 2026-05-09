# 后端开发说明

## 目录结构

- `src/routes/` 路由模块
- `src/middleware/` 权限中间件
- `src/types.ts` 类型定义
- `src/db.ts` 数据库连接与初始化
- `src/schema.sql` 数据库建表脚本
- `src/app.ts` 主应用入口
- `src/server.ts` 启动脚本

## 启动

1. `npm install`
2. `npm run dev`

## 注意
- 默认端口 3001
- JWT 密钥在 `.env` 文件中
- 数据库文件自动生成
