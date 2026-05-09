#!/bin/bash

# 二维码扫码系统 - 停止脚本

echo "🛑 停止二维码扫码系统..."

# 停止后端服务
pkill -f "tsx watch src/app.ts"
pkill -f "node.*backend.*app.ts"

# 停止前端服务
pkill -f "vite"

echo "✅ 服务已停止"
