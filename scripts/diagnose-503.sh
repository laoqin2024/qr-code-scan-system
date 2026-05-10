#!/bin/bash

# 诊断 503 错误的脚本

echo "🔍 诊断 Nginx 503 错误"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. 检查 Nginx 配置
echo "1️⃣ 检查 Nginx 配置文件:"
echo ""
if [ -f /etc/nginx/sites-available/scan-code ]; then
    cat /etc/nginx/sites-available/scan-code
elif [ -f /etc/nginx/conf.d/scan-code.conf ]; then
    cat /etc/nginx/conf.d/scan-code.conf
else
    echo "❌ 未找到 Nginx 配置文件"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 2. 检查 Nginx 监听端口
echo "2️⃣ 检查 Nginx 监听的端口:"
echo ""
sudo netstat -tlnp | grep nginx || sudo ss -tlnp | grep nginx

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 3. 检查后端服务
echo "3️⃣ 检查后端服务（3001 端口）:"
echo ""
sudo netstat -tlnp | grep 3001 || sudo ss -tlnp | grep 3001

if [ $? -ne 0 ]; then
    echo "❌ 后端服务未在 3001 端口监听"
    echo ""
    echo "检查 PM2 进程:"
    pm2 list
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 4. 测试后端连接
echo "4️⃣ 测试后端服务连接:"
echo ""
curl -v http://localhost:3001/api/health 2>&1 | head -20

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 5. 检查 PM2 日志
echo "5️⃣ PM2 日志（最近 20 行）:"
echo ""
pm2 logs --lines 20 --nostream

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 6. 检查 Nginx 错误日志
echo "6️⃣ Nginx 错误日志（最近 10 行）:"
echo ""
sudo tail -10 /var/log/nginx/scan-code-error.log 2>/dev/null || echo "日志文件不存在"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 7. 检查防火墙
echo "7️⃣ 检查防火墙规则:"
echo ""
sudo iptables -L -n | grep 6006 || echo "未找到 6006 端口规则"
sudo firewall-cmd --list-ports 2>/dev/null || echo "firewalld 未运行"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "💡 常见 503 错误原因:"
echo "  1. 后端服务未启动（最常见）"
echo "  2. 后端服务端口错误"
echo "  3. 后端服务崩溃"
echo "  4. 数据库文件权限问题"
echo "  5. 环境变量配置错误"
