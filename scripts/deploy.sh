#!/bin/bash

# 二维码扫码防错系统 - 自动化部署脚本
# 适用于生产服务器部署

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

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

# 检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        return 1
    fi
    return 0
}

# 主函数
main() {
    clear
    print_header "🚀 二维码扫码防错系统 - 自动化部署脚本"
    
    echo ""
    print_info "本脚本将帮助您完成以下操作："
    echo "  1. 检查系统环境"
    echo "  2. 安装必要的依赖"
    echo "  3. 克隆项目代码"
    echo "  4. 配置环境变量"
    echo "  5. 安装项目依赖"
    echo "  6. 构建前端"
    echo "  7. 初始化数据库"
    echo "  8. 配置 Nginx"
    echo "  9. 配置 PM2"
    echo "  10. 启动服务"
    echo ""
    
    read -p "是否继续？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "部署已取消"
        exit 0
    fi
    
    # 步骤1: 检查系统环境
    print_header "📋 步骤 1/10: 检查系统环境"
    check_environment
    
    # 步骤2: 收集配置信息
    print_header "⚙️  步骤 2/10: 配置部署参数"
    collect_config
    
    # 步骤3: 安装依赖
    print_header "📦 步骤 3/10: 安装系统依赖"
    install_dependencies
    
    # 步骤4: 克隆项目
    print_header "📥 步骤 4/10: 克隆项目代码"
    clone_project
    
    # 步骤5: 配置环境变量
    print_header "🔧 步骤 5/10: 配置环境变量"
    configure_env
    
    # 步骤6: 安装项目依赖
    print_header "📦 步骤 6/10: 安装项目依赖"
    install_project_deps
    
    # 步骤7: 构建前端
    print_header "🏗️  步骤 7/10: 构建前端"
    build_frontend
    
    # 步骤8: 初始化数据库
    print_header "🗄️  步骤 8/10: 初始化数据库"
    init_database
    
    # 步骤9: 配置 Nginx
    print_header "🌐 步骤 9/10: 配置 Nginx"
    configure_nginx
    
    # 步骤10: 配置并启动服务
    print_header "🚀 步骤 10/10: 启动服务"
    start_services
    
    # 完成
    print_header "🎉 部署完成！"
    show_summary
}

# 检查系统环境
check_environment() {
    print_info "检查操作系统..."
    OS=$(uname -s)
    print_success "操作系统: $OS"
    
    print_info "检查必要命令..."
    
    # 检查 git
    if check_command git; then
        GIT_VERSION=$(git --version)
        print_success "Git: $GIT_VERSION"
    else
        print_error "Git 未安装"
        NEED_GIT=true
    fi
    
    # 检查 node
    if check_command node; then
        NODE_VERSION=$(node --version)
        print_success "Node.js: $NODE_VERSION"
    else
        print_error "Node.js 未安装"
        NEED_NODE=true
    fi
    
    # 检查 npm
    if check_command npm; then
        NPM_VERSION=$(npm --version)
        print_success "npm: $NPM_VERSION"
    else
        print_error "npm 未安装"
        NEED_NPM=true
    fi
    
    # 检查 nginx
    if check_command nginx; then
        NGINX_VERSION=$(nginx -v 2>&1)
        print_success "Nginx: $NGINX_VERSION"
        HAS_NGINX=true
    else
        print_warning "Nginx 未安装（可选）"
        HAS_NGINX=false
    fi
    
    # 检查 pm2
    if check_command pm2; then
        PM2_VERSION=$(pm2 --version)
        print_success "PM2: $PM2_VERSION"
        HAS_PM2=true
    else
        print_warning "PM2 未安装（推荐安装）"
        HAS_PM2=false
    fi
    
    echo ""
}

# 收集配置信息
collect_config() {
    # 项目目录
    read -p "请输入项目安装目录 [默认: /opt/scan-code]: " INSTALL_DIR
    INSTALL_DIR=${INSTALL_DIR:-/opt/scan-code}
    print_info "项目目录: $INSTALL_DIR"
    
    # Git 仓库
    echo ""
    echo "请选择 Git 仓库:"
    echo "  1. GitHub (推荐国外服务器)"
    echo "  2. Gitee (推荐国内服务器)"
    read -p "请选择 [1/2, 默认: 2]: " GIT_CHOICE
    GIT_CHOICE=${GIT_CHOICE:-2}
    
    if [ "$GIT_CHOICE" = "1" ]; then
        GIT_REPO="https://github.com/laoqin2024/qr-code-scan-system.git"
    else
        GIT_REPO="https://gitee.com/laoqin1/qr-code-scan-system.git"
    fi
    print_info "Git 仓库: $GIT_REPO"
    
    # 后端端口
    echo ""
    read -p "请输入后端服务端口 [默认: 3001]: " BACKEND_PORT
    BACKEND_PORT=${BACKEND_PORT:-3001}
    print_info "后端端口: $BACKEND_PORT"
    
    # 前端端口
    read -p "请输入前端服务端口 [默认: 80]: " FRONTEND_PORT
    FRONTEND_PORT=${FRONTEND_PORT:-80}
    print_info "前端端口: $FRONTEND_PORT"
    
    # 域名或IP
    echo ""
    read -p "请输入服务器域名或IP [默认: localhost]: " SERVER_HOST
    SERVER_HOST=${SERVER_HOST:-localhost}
    print_info "服务器地址: $SERVER_HOST"
    
    # JWT Secret
    echo ""
    print_info "生成 JWT Secret..."
    JWT_SECRET=$(openssl rand -base64 32 2>/dev/null || cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
    print_success "JWT Secret 已生成"
    
    # 是否配置 Nginx
    echo ""
    if [ "$HAS_NGINX" = true ]; then
        read -p "是否配置 Nginx 反向代理？(y/n) [默认: y]: " SETUP_NGINX
        SETUP_NGINX=${SETUP_NGINX:-y}
    else
        SETUP_NGINX=n
    fi
    
    # 是否使用 PM2
    echo ""
    if [ "$HAS_PM2" = true ]; then
        read -p "是否使用 PM2 管理进程？(y/n) [默认: y]: " USE_PM2
        USE_PM2=${USE_PM2:-y}
    else
        USE_PM2=n
    fi
    
    # 确认配置
    echo ""
    print_header "📋 配置确认"
    echo "项目目录: $INSTALL_DIR"
    echo "Git 仓库: $GIT_REPO"
    echo "后端端口: $BACKEND_PORT"
    echo "前端端口: $FRONTEND_PORT"
    echo "服务器地址: $SERVER_HOST"
    echo "配置 Nginx: $SETUP_NGINX"
    echo "使用 PM2: $USE_PM2"
    echo ""
    
    read -p "确认以上配置？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "部署已取消"
        exit 0
    fi
}

# 安装系统依赖
install_dependencies() {
    print_info "安装编译工具和依赖..."
    
    if [[ "$OS" == "Linux" ]]; then
        # 检测 Linux 发行版
        if [ -f /etc/debian_version ]; then
            # Debian/Ubuntu
            print_info "检测到 Debian/Ubuntu 系统"
            sudo apt-get update
            
            # 安装编译工具
            print_info "安装编译工具..."
            sudo apt-get install -y build-essential python3 python3-distutils python3-dev
            
            # 安装 Git 和 Node.js
            [ "$NEED_GIT" = true ] && sudo apt-get install -y git
            [ "$NEED_NODE" = true ] && sudo apt-get install -y nodejs npm
            
        elif [ -f /etc/redhat-release ]; then
            # CentOS/RHEL
            print_info "检测到 CentOS/RHEL 系统"
            
            # 安装编译工具
            print_info "安装编译工具..."
            sudo yum groupinstall -y "Development Tools"
            sudo yum install -y python3 python3-devel
            
            # 安装 Git 和 Node.js
            [ "$NEED_GIT" = true ] && sudo yum install -y git
            [ "$NEED_NODE" = true ] && sudo yum install -y nodejs npm
        fi
    elif [[ "$OS" == "Darwin" ]]; then
        # macOS
        print_info "检测到 macOS 系统"
        if ! check_command brew; then
            print_error "请先安装 Homebrew: https://brew.sh"
            exit 1
        fi
        
        # macOS 通常已有编译工具
        [ "$NEED_GIT" = true ] && brew install git
        [ "$NEED_NODE" = true ] && brew install node
    fi
    
    print_success "系统依赖安装完成"
    
    # 安装 PM2（如果需要）
    if [ "$USE_PM2" = "y" ] && [ "$HAS_PM2" = false ]; then
        print_info "安装 PM2..."
        sudo npm install -g pm2
        print_success "PM2 安装完成"
    fi
}

# 克隆项目
clone_project() {
    # 检查目录是否存在
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "目录 $INSTALL_DIR 已存在"
        read -p "是否删除并重新克隆？(y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "删除旧目录..."
            sudo rm -rf "$INSTALL_DIR"
        else
            print_info "使用现有目录"
            cd "$INSTALL_DIR"
            print_info "拉取最新代码..."
            git pull
            return
        fi
    fi
    
    # 创建父目录
    PARENT_DIR=$(dirname "$INSTALL_DIR")
    sudo mkdir -p "$PARENT_DIR"
    
    # 克隆项目
    print_info "克隆项目..."
    cd "$PARENT_DIR"
    sudo git clone "$GIT_REPO" "$(basename $INSTALL_DIR)"
    
    # 设置权限
    sudo chown -R $USER:$USER "$INSTALL_DIR"
    
    cd "$INSTALL_DIR"
    print_success "项目克隆完成"
}

# 配置环境变量
configure_env() {
    cd "$INSTALL_DIR/backend"
    
    # 创建 .env 文件
    print_info "创建 .env 文件..."
    cat > .env << EOF
PORT=$BACKEND_PORT
JWT_SECRET=$JWT_SECRET
NODE_ENV=production
EOF
    
    print_success ".env 文件创建完成"
}

# 安装项目依赖
install_project_deps() {
    cd "$INSTALL_DIR"
    
    # 安装根依赖
    print_info "安装根依赖..."
    npm install
    
    # 安装后端依赖
    print_info "安装后端依赖..."
    cd backend
    npm install
    
    # 安装前端依赖
    print_info "安装前端依赖..."
    cd ../frontend
    npm install
    
    cd "$INSTALL_DIR"
    print_success "项目依赖安装完成"
}

# 构建前端
build_frontend() {
    cd "$INSTALL_DIR/frontend"
    
    print_info "构建前端..."
    npm run build
    
    print_success "前端构建完成"
}

# 初始化数据库
init_database() {
    cd "$INSTALL_DIR/backend"
    
    print_info "初始化数据库..."
    npm run init-db
    
    print_success "数据库初始化完成"
    print_info "默认账号:"
    echo "  超级管理员: admin / admin123"
    echo "  客户管理员: test / test123"
}

# 配置 Nginx
configure_nginx() {
    if [ "$SETUP_NGINX" != "y" ]; then
        print_info "跳过 Nginx 配置"
        return
    fi
    
    print_info "生成 Nginx 配置..."
    
    NGINX_CONF="/etc/nginx/sites-available/scan-code"
    
    sudo tee "$NGINX_CONF" > /dev/null << EOF
server {
    listen $FRONTEND_PORT;
    server_name $SERVER_HOST;
    
    # 前端静态文件
    location / {
        root $INSTALL_DIR/frontend/dist;
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
    
    # 创建软链接
    if [ -d "/etc/nginx/sites-enabled" ]; then
        sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/
    fi
    
    # 测试配置
    print_info "测试 Nginx 配置..."
    sudo nginx -t
    
    # 重启 Nginx
    print_info "重启 Nginx..."
    sudo systemctl restart nginx || sudo service nginx restart
    
    print_success "Nginx 配置完成"
}

# 启动服务
start_services() {
    cd "$INSTALL_DIR/backend"
    
    if [ "$USE_PM2" = "y" ]; then
        # 使用 PM2
        print_info "使用 PM2 启动服务..."
        
        # 停止旧进程
        pm2 delete scan-code-backend 2>/dev/null || true
        
        # 启动后端
        pm2 start npm --name "scan-code-backend" -- start
        
        # 保存 PM2 配置
        pm2 save
        
        # 设置开机自启
        pm2 startup
        
        print_success "服务已启动（PM2）"
    else
        # 直接启动
        print_info "启动后端服务..."
        nohup npm start > ../logs/backend.log 2>&1 &
        echo $! > ../backend.pid
        
        print_success "服务已启动"
    fi
}

# 显示部署总结
show_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉 部署成功！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📋 部署信息:"
    echo "  项目目录: $INSTALL_DIR"
    echo "  后端端口: $BACKEND_PORT"
    echo "  前端端口: $FRONTEND_PORT"
    echo ""
    echo "🌐 访问地址:"
    if [ "$SETUP_NGINX" = "y" ]; then
        echo "  前端: http://$SERVER_HOST:$FRONTEND_PORT"
    else
        echo "  前端: 需要手动配置 Web 服务器"
    fi
    echo "  后端: http://$SERVER_HOST:$BACKEND_PORT"
    echo ""
    echo "👤 默认账号:"
    echo "  超级管理员: admin / admin123"
    echo "  客户管理员: test / test123"
    echo ""
    echo "🔧 管理命令:"
    if [ "$USE_PM2" = "y" ]; then
        echo "  查看状态: pm2 status"
        echo "  查看日志: pm2 logs scan-code-backend"
        echo "  重启服务: pm2 restart scan-code-backend"
        echo "  停止服务: pm2 stop scan-code-backend"
    else
        echo "  查看日志: tail -f $INSTALL_DIR/logs/backend.log"
        echo "  停止服务: kill \$(cat $INSTALL_DIR/backend.pid)"
    fi
    echo ""
    echo "📚 文档:"
    echo "  项目文档: $INSTALL_DIR/README.md"
    echo "  快速开始: $INSTALL_DIR/QUICK_START.md"
    echo "  部署清单: $INSTALL_DIR/DELIVERY_CHECKLIST.md"
    echo ""
    echo "⚠️  安全提示:"
    echo "  1. 请及时修改默认密码"
    echo "  2. 配置防火墙规则"
    echo "  3. 定期备份数据库"
    echo "  4. 启用 HTTPS（推荐）"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# 错误处理
trap 'print_error "部署过程中发生错误，请检查日志"; exit 1' ERR

# 运行主函数
main
