#!/bin/bash

# 二维码扫码系统 - 局域网启动脚本

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🌐 二维码扫码系统 - 局域网启动"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 检查是否在项目根目录
if [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    echo "❌ 错误: 请在项目根目录运行此脚本"
    exit 1
fi

# 停止旧进程
echo "🛑 停止旧进程..."
pkill -f "tsx watch src/app.ts" 2>/dev/null
pkill -f "vite" 2>/dev/null
sleep 2

# 启动后端服务
echo ""
echo "🚀 启动后端服务..."
cd backend
npm run dev > ../backend.log 2>&1 &
BACKEND_PID=$!
cd ..

# 等待后端启动
sleep 3

# 启动前端服务
echo "🚀 启动前端服务..."
cd frontend
npm run dev > ../frontend.log 2>&1 &
FRONTEND_PID=$!
cd ..

# 等待前端启动
sleep 3

# 获取本机IP
LOCAL_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 系统启动完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📱 访问地址:"
echo ""
echo "   本机访问:"
echo "   http://localhost:5173"
echo ""
echo "   局域网访问:"
echo "   http://${LOCAL_IP}:5173"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 使用说明:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. 本机访问: 使用 localhost 地址"
echo "2. 局域网访问: 其他设备使用局域网IP地址"
echo "3. 确保设备在同一局域网内"
echo "4. 防火墙需允许 5173 和 3001 端口"
echo ""
echo "👤 登录账号:"
echo "   管理员: admin / admin"
echo "   操作员: operator / operator"
echo ""
echo "🛑 停止服务: ./stop.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
