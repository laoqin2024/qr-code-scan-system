#!/bin/bash

# 二维码扫码系统 - 启动脚本

echo "=================================="
echo "  二维码扫码系统 - 启动脚本"
echo "=================================="
echo ""

# 检查是否在项目根目录
if [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    echo "❌ 错误: 请在项目根目录运行此脚本"
    exit 1
fi

# 检查 node_modules 是否存在
if [ ! -d "backend/node_modules" ]; then
    echo "📦 安装后端依赖..."
    cd backend && npm install && cd ..
fi

if [ ! -d "frontend/node_modules" ]; then
    echo "📦 安装前端依赖..."
    cd frontend && npm install && cd ..
fi

# 检查数据库是否初始化
if [ ! -f "db.sqlite" ]; then
    echo "🗄️  初始化数据库..."
    cd backend && npm run init && cd ..
fi

# 启动后端服务
echo ""
echo "🚀 启动后端服务 (端口 3001)..."
cd backend
npm run dev > ../backend.log 2>&1 &
BACKEND_PID=$!
cd ..

# 等待后端启动
sleep 3

# 检查后端是否启动成功
if curl -s http://localhost:3001/api/customers > /dev/null 2>&1; then
    echo "✅ 后端服务启动成功"
else
    echo "⚠️  后端服务可能未完全启动，请检查 backend.log"
fi

# 启动前端服务
echo ""
echo "🚀 启动前端服务 (端口 5173)..."
cd frontend
npm run dev > ../frontend.log 2>&1 &
FRONTEND_PID=$!
cd ..

# 等待前端启动
sleep 3

echo ""
echo "=================================="
echo "✅ 系统启动完成！"
echo "=================================="
echo ""
echo "📱 访问地址: http://localhost:5173"
echo ""
echo "👤 登录账号:"
echo "   管理员: admin / admin"
echo "   操作员: operator / operator"
echo ""
echo "📝 日志文件:"
echo "   后端: backend.log"
echo "   前端: frontend.log"
echo ""
echo "🛑 停止服务:"
echo "   kill $BACKEND_PID $FRONTEND_PID"
echo ""
echo "或者运行: ./stop.sh"
echo "=================================="
