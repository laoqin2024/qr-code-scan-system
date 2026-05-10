#!/bin/bash

# 手动配置 Nginx 的脚本

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

echo "🔧 手动配置 Nginx"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 检测项目目录
if [ -f "package.json" ] && [ -d "backend" ]; then
    PROJECT_DIR=$(pwd)
else
    PROJECT_DIR="/opt/scan-code"
fi

print_info "项目目录: $PROJECT_DIR"

# 收集配置信息
echo ""
read -p "请输入前端端口 [默认: 6006]: " FRONTEND_PORT
FRONTEND_PORT=${FRONTEND_PORT:-6006}

read -p "请输入后端端口 [默认: 3001]: " BACKEND_PORT
BACKEND_PORT=${BACKEND_PORT:-3001}

echo ""
echo "配置服务器地址（用于 Nginx 的 server_name）："
echo "  - 填写服务器 IP（如 192.168.8.91）"
echo "  - 填写 _ 表示匹配所有请求（推荐）"
echo ""
read -p "请输入服务器地址 [默认: _]: " SERVER_HOST
SERVER_HOST=${SERVER_HOST:-_}

# 验证输入
if [ "$SERVER_HOST" = "0.0.0.0" ]; then
    print_warning "检测到 0.0.0.0，自动修正为 _"
    SERVER_HOST="_"
fi

echo ""
print_info "配置信息:"
echo "  项目目录: $PROJECT_DIR"
echo "  前端端口: $FRONTEND_PORT"
echo "  后端端口: $BACKEND_PORT"
echo "  服务器地址: $SERVER_HOST"
echo ""

# 检测 Nginx 配置目录
print_info "检测 Nginx 配置目录..."

if [ -d "/etc/nginx/sites-available" ]; then
    # Debian/Ubuntu 风格
    NGINX_CONF="/etc/nginx/sites-available/scan-code"
    NGINX_ENABLED="/etc/nginx/sites-enabled/scan-code"
    USE_SITES_AVAILABLE=true
    print_success "检测到 Debian/Ubuntu 系统"
    print_info "配置文件: $NGINX_CONF"
elif [ -d "/etc/nginx/conf.d" ]; then
    # CentOS/RHEL 风格
    NGINX_CONF="/etc/nginx/conf.d/scan-code.conf"
    USE_SITES_AVAILABLE=false
    print_success "检测到 CentOS/RHEL 系统"
    print_info "配置文件: $NGINX_CONF"
else
    print_error "无法确定 Nginx 配置目录"
    echo ""
    echo "请手动创建配置文件，内容如下："
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat << EOF
server {
    listen $FRONTEND_PORT;
    server_name $SERVER_HOST;
    
    location / {
        root $PROJECT_DIR/frontend/dist;
        try_files \$uri \$uri/ /index.html;
    }
    
    location /api {
        proxy_pass http://localhost:$BACKEND_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_cache_bypass \$http_upgrade;
    }
    
    access_log /var/log/nginx/scan-code-access.log;
    error_log /var/log/nginx/scan-code-error.log;
}
EOF
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
fi

echo ""
read -p "是否继续创建配置文件？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "已取消"
    exit 0
fi

# 创建配置文件
print_info "创建 Nginx 配置文件..."

sudo tee "$NGINX_CONF" > /dev/null << EOF
server {
    listen $FRONTEND_PORT;
    server_name $SERVER_HOST;
    
    # 前端静态文件
    location / {
        root $PROJECT_DIR/frontend/dist;
        try_files \$uri \$uri/ /index.html;
        
        # 缓存静态资源
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # API 代理
    location /api {
        proxy_pass http://localhost:$BACKEND_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # 日志
    access_log /var/log/nginx/scan-code-access.log;
    error_log /var/log/nginx/scan-code-error.log;
}
EOF

print_success "配置文件已创建: $NGINX_CONF"

# 创建软链接（仅 Debian/Ubuntu）
if [ "$USE_SITES_AVAILABLE" = true ]; then
    print_info "创建软链接..."
    sudo ln -sf "$NGINX_CONF" "$NGINX_ENABLED"
    print_success "软链接已创建: $NGINX_ENABLED"
fi

echo ""

# 测试配置
print_info "测试 Nginx 配置..."
if sudo nginx -t; then
    print_success "配置测试通过"
else
    print_error "配置测试失败"
    echo ""
    echo "请检查配置文件: $NGINX_CONF"
    exit 1
fi

echo ""

# 重启 Nginx
print_info "重启 Nginx..."
if sudo systemctl restart nginx 2>/dev/null || sudo service nginx restart; then
    print_success "Nginx 已重启"
else
    print_error "Nginx 重启失败"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_success "Nginx 配置完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 配置信息:"
echo "  配置文件: $NGINX_CONF"
echo "  前端端口: $FRONTEND_PORT"
echo "  后端端口: $BACKEND_PORT"
echo ""
echo "🌐 访问地址:"
echo "  http://服务器IP:$FRONTEND_PORT"
echo ""
echo "🔍 验证命令:"
echo "  curl http://localhost:$FRONTEND_PORT"
echo "  sudo nginx -t"
echo "  sudo systemctl status nginx"
echo ""
echo "📝 查看日志:"
echo "  sudo tail -f /var/log/nginx/scan-code-access.log"
echo "  sudo tail -f /var/log/nginx/scan-code-error.log"
