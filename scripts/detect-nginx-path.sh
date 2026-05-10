#!/bin/bash

# 检测 Nginx 配置路径的脚本

echo "🔍 检测 Nginx 配置路径"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. 检查 Nginx 版本和系统
echo "1️⃣ 系统信息:"
echo ""
echo "操作系统:"
cat /etc/os-release 2>/dev/null | grep "PRETTY_NAME" || uname -a
echo ""
echo "Nginx 版本:"
nginx -v 2>&1
echo ""

# 2. 检查 Nginx 主配置文件
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "2️⃣ Nginx 主配置文件:"
echo ""
NGINX_CONF=$(nginx -t 2>&1 | grep "configuration file" | awk '{print $5}')
echo "路径: $NGINX_CONF"
echo ""

# 3. 检查配置目录结构
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "3️⃣ 配置目录结构:"
echo ""

if [ -d "/etc/nginx/sites-available" ]; then
    echo "✅ /etc/nginx/sites-available/ (Debian/Ubuntu 风格)"
    ls -la /etc/nginx/sites-available/
elif [ -d "/etc/nginx/conf.d" ]; then
    echo "✅ /etc/nginx/conf.d/ (CentOS/RHEL 风格)"
    ls -la /etc/nginx/conf.d/
else
    echo "❌ 未找到标准配置目录"
fi

echo ""

# 4. 查找 scan-code 配置文件
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "4️⃣ 查找 scan-code 配置文件:"
echo ""

SCAN_CODE_CONF=$(find /etc/nginx -name "*scan-code*" 2>/dev/null)
if [ -n "$SCAN_CODE_CONF" ]; then
    echo "✅ 找到配置文件:"
    echo "$SCAN_CODE_CONF"
    echo ""
    echo "文件内容:"
    cat "$SCAN_CODE_CONF"
else
    echo "❌ 未找到 scan-code 配置文件"
fi

echo ""

# 5. 检查主配置文件的 include 指令
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "5️⃣ 主配置文件的 include 指令:"
echo ""
grep -E "^\s*include" /etc/nginx/nginx.conf 2>/dev/null | grep -v "#"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 配置文件应该放在:"
if [ -d "/etc/nginx/sites-available" ]; then
    echo "  /etc/nginx/sites-available/scan-code"
    echo "  并创建软链接到 /etc/nginx/sites-enabled/"
elif [ -d "/etc/nginx/conf.d" ]; then
    echo "  /etc/nginx/conf.d/scan-code.conf"
    echo "  (注意：文件名必须以 .conf 结尾)"
else
    echo "  请检查 /etc/nginx/nginx.conf 中的 include 指令"
fi
