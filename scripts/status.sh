#!/bin/bash

# 二维码扫码系统 - 项目状态检查

echo "=================================="
echo "  二维码扫码系统 - 状态检查"
echo "=================================="
echo ""

# 检查后端服务
echo "🔍 检查后端服务 (端口 3001)..."
if curl -s http://localhost:3001/api/customers > /dev/null 2>&1; then
    echo "✅ 后端服务运行正常"
    
    # 测试登录接口
    LOGIN_RESULT=$(curl -s -X POST http://localhost:3001/api/auth/login \
        -H "Content-Type: application/json" \
        -d '{"username":"admin","password":"admin"}')
    
    if echo "$LOGIN_RESULT" | grep -q "token"; then
        echo "✅ 登录接口正常"
    else
        echo "❌ 登录接口异常"
    fi
else
    echo "❌ 后端服务未运行"
fi

echo ""

# 检查前端服务
echo "🔍 检查前端服务 (端口 5173)..."
if curl -s http://localhost:5173 > /dev/null 2>&1; then
    echo "✅ 前端服务运行正常"
else
    echo "❌ 前端服务未运行"
fi

echo ""

# 检查数据库
echo "🔍 检查数据库..."
if [ -f "db.sqlite" ]; then
    echo "✅ 数据库文件存在"
    DB_SIZE=$(du -h db.sqlite | cut -f1)
    echo "   文件大小: $DB_SIZE"
else
    echo "❌ 数据库文件不存在"
fi

echo ""

# 检查进程
echo "🔍 检查运行进程..."
BACKEND_PROC=$(ps aux | grep -E "tsx watch src/app.ts" | grep -v grep | wc -l)
FRONTEND_PROC=$(ps aux | grep -E "vite" | grep -v grep | wc -l)

if [ $BACKEND_PROC -gt 0 ]; then
    echo "✅ 后端进程运行中 ($BACKEND_PROC 个)"
else
    echo "❌ 后端进程未运行"
fi

if [ $FRONTEND_PROC -gt 0 ]; then
    echo "✅ 前端进程运行中 ($FRONTEND_PROC 个)"
else
    echo "❌ 前端进程未运行"
fi

echo ""
echo "=================================="
echo "📱 访问地址: http://localhost:5173"
echo "👤 管理员: admin / admin"
echo "👤 操作员: operator / operator"
echo "=================================="
