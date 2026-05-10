#!/bin/bash

# 修复 503 错误的快速脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo "🔧 修复 Nginx 503 错误"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 检测项目目录
if [ -f "package.json" ] && [ -d "backend" ]; then
    PROJECT_DIR=$(pwd)
else
    PROJECT_DIR="/opt/scan-code"
fi

print_info "项目目录: $PROJECT_DIR"
cd "$PROJECT_DIR"

# 1. 检查后端服务
print_info "检查后端服务状态..."
if pm2 list | grep -q "scan-code-backend"; then
    print_success "PM2 进程存在"
    
    # 检查进程状态
    if pm2 list | grep "scan-code-backend" | grep -q "online"; then
        print_success "后端服务运行中"
    else
        print_warning "后端服务未运行，尝试重启..."
        pm2 restart scan-code-backend
    fi
else
    print_warning "PM2 进程不存在，启动后端服务..."
    cd "$PROJECT_DIR/backend"
    pm2 start npm --name "scan-code-backend" -- start
    pm2 save
fi

echo ""

# 2. 检查后端端口
print_info "检查后端端口 3001..."
sleep 2
if netstat -tlnp 2>/dev/null | grep -q ":3001" || ss -tlnp 2>/dev/null | grep -q ":3001"; then
    print_success "后端服务正在监听 3001 端口"
else
    print_error "后端服务未在 3001 端口监听"
    print_info "查看 PM2 日志:"
    pm2 logs scan-code-backend --lines 30 --nostream
    exit 1
fi

echo ""

# 3. 测试后端连接
print_info "测试后端 API..."
if curl -s http://localhost:3001/api/health > /dev/null 2>&1; then
    print_success "后端 API 响应正常"
else
    print_warning "后端 API 无响应，检查日志..."
    pm2 logs scan-code-backend --lines 20 --nostream
fi

echo ""

# 4. 检查 Nginx 配置
print_info "检查 Nginx 配置..."
if sudo nginx -t 2>&1 | grep -q "successful"; then
    print_success "Nginx 配置正确"
else
    print_error "Nginx 配置有误"
    sudo nginx -t
    exit 1
fi

echo ""

# 5. 重启 Nginx
print_info "重启 Nginx..."
sudo systemctl restart nginx 2>/dev/null || sudo service nginx restart
print_success "Nginx 已重启"

echo ""

# 6. 测试访问
print_info "等待服务启动..."
sleep 3

echo ""
print_info "测试前端访问（通过 Nginx）..."

# 获取配置的端口
FRONTEND_PORT=$(grep "listen" /etc/nginx/sites-available/scan-code 2>/dev/null | head -1 | awk '{print $2}' | tr -d ';')
if [ -z "$FRONTEND_PORT" ]; then
    FRONTEND_PORT=$(grep "listen" /etc/nginx/conf.d/scan-code.conf 2>/dev/null | head -1 | awk '{print $2}' | tr -d ';')
fi

if [ -n "$FRONTEND_PORT" ]; then
    print_info "前端端口: $FRONTEND_PORT"
    
    if curl -s http://localhost:$FRONTEND_PORT > /dev/null 2>&1; then
        print_success "前端访问正常"
    else
        print_warning "前端访问失败"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_success "修复完成！"
echo ""
echo "📋 服务状态:"
pm2 list
echo ""
echo "🌐 访问地址:"
echo "  前端: http://服务器IP:$FRONTEND_PORT"
echo "  后端: http://服务器IP:3001"
echo ""
echo "🔍 如仍有问题，运行诊断脚本:"
echo "  bash scripts/diagnose-503.sh"
