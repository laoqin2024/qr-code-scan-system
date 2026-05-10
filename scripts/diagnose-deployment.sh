#!/bin/bash

# 诊断部署问题的脚本

echo "🔍 诊断部署状态"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. 系统信息
echo "1️⃣ 系统信息:"
echo ""
cat /etc/os-release | grep -E "NAME|VERSION"
echo ""

# 2. Nginx 状态
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "2️⃣ Nginx 状态:"
echo ""
if command -v nginx &> /dev/null; then
    echo "✅ Nginx 已安装"
    nginx -v 2>&1
    echo ""
    echo "Nginx 运行状态:"
    systemctl status nginx --no-pager | head -5
else
    echo "❌ Nginx 未安装"
fi

echo ""

# 3. Nginx 配置目录
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "3️⃣ Nginx 配置目录:"
echo ""

if [ -d "/etc/nginx/sites-available" ]; then
    echo "✅ /etc/nginx/sites-available/ 存在"
    echo ""
    echo "目录内容:"
    ls -lh /etc/nginx/sites-available/
    echo ""
    echo "权限:"
    ls -ld /etc/nginx/sites-available/
else
    echo "❌ /etc/nginx/sites-available/ 不存在"
fi

echo ""

if [ -d "/etc/nginx/sites-enabled" ]; then
    echo "✅ /etc/nginx/sites-enabled/ 存在"
    echo ""
    echo "目录内容:"
    ls -lh /etc/nginx/sites-enabled/
else
    echo "❌ /etc/nginx/sites-enabled/ 不存在"
fi

echo ""

# 4. 查找 scan-code 配置
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "4️⃣ 查找 scan-code 配置:"
echo ""

SCAN_CODE_CONF=$(find /etc/nginx -name "*scan-code*" 2>/dev/null)
if [ -n "$SCAN_CODE_CONF" ]; then
    echo "✅ 找到配置文件:"
    echo "$SCAN_CODE_CONF"
else
    echo "❌ 未找到 scan-code 配置文件"
fi

echo ""

# 5. PM2 状态
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "5️⃣ PM2 状态:"
echo ""

if command -v pm2 &> /dev/null; then
    echo "✅ PM2 已安装"
    pm2 --version
    echo ""
    echo "PM2 进程列表:"
    pm2 list
else
    echo "❌ PM2 未安装"
fi

echo ""

# 6. 项目目录
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "6️⃣ 项目目录:"
echo ""

if [ -d "/opt/scan-code" ]; then
    echo "✅ /opt/scan-code 存在"
    echo ""
    echo "目录结构:"
    ls -lh /opt/scan-code/
    echo ""
    echo "前端构建:"
    if [ -d "/opt/scan-code/frontend/dist" ]; then
        echo "✅ frontend/dist 存在"
        ls -lh /opt/scan-code/frontend/dist/ | head -5
    else
        echo "❌ frontend/dist 不存在"
    fi
    echo ""
    echo "数据库:"
    if [ -f "/opt/scan-code/db.sqlite" ]; then
        echo "✅ db.sqlite 存在"
        ls -lh /opt/scan-code/db.sqlite
    else
        echo "❌ db.sqlite 不存在"
    fi
else
    echo "❌ /opt/scan-code 不存在"
fi

echo ""

# 7. 端口监听
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "7️⃣ 端口监听:"
echo ""

echo "后端端口 3001:"
if netstat -tlnp 2>/dev/null | grep -q ":3001" || ss -tlnp 2>/dev/null | grep -q ":3001"; then
    echo "✅ 3001 端口有进程监听"
    netstat -tlnp 2>/dev/null | grep ":3001" || ss -tlnp 2>/dev/null | grep ":3001"
else
    echo "❌ 3001 端口无进程监听"
fi

echo ""

echo "前端端口 6006:"
if netstat -tlnp 2>/dev/null | grep -q ":6006" || ss -tlnp 2>/dev/null | grep -q ":6006"; then
    echo "✅ 6006 端口有进程监听"
    netstat -tlnp 2>/dev/null | grep ":6006" || ss -tlnp 2>/dev/null | grep ":6006"
else
    echo "❌ 6006 端口无进程监听"
fi

echo ""

# 8. Python 环境
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "8️⃣ Python 环境:"
echo ""

if command -v python3 &> /dev/null; then
    echo "✅ Python3 已安装"
    python3 --version
else
    echo "❌ Python3 未安装"
fi

echo ""

# 9. Node.js 环境
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "9️⃣ Node.js 环境:"
echo ""

if command -v node &> /dev/null; then
    echo "✅ Node.js 已安装"
    node --version
else
    echo "❌ Node.js 未安装"
fi

if command -v npm &> /dev/null; then
    echo "✅ npm 已安装"
    npm --version
else
    echo "❌ npm 未安装"
fi

echo ""

# 10. 权限检查
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔟 权限检查:"
echo ""

echo "当前用户: $(whoami)"
echo "用户组: $(groups)"
echo ""

echo "测试 Nginx 配置目录写权限:"
if sudo touch /etc/nginx/sites-available/.test 2>/dev/null; then
    echo "✅ 有写权限"
    sudo rm /etc/nginx/sites-available/.test
else
    echo "❌ 无写权限"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 诊断完成！"
echo ""
echo "📋 建议操作:"
echo "  1. 如果 Nginx 配置文件不存在，运行: bash scripts/configure-nginx.sh"
echo "  2. 如果后端未运行，运行: bash scripts/fix-503.sh"
echo "  3. 如果需要重新部署，运行: bash scripts/deploy.sh"
