# 部署脚本智能化模块设计

本文档包含各个智能化模块的详细代码示例和实现方案。

---

## 📋 目录

1. [系统检测模块](#系统检测模块)
2. [权限管理模块](#权限管理模块)
3. [环境检测模块](#环境检测模块)
4. [交互体验模块](#交互体验模块)
5. [日志系统模块](#日志系统模块)
6. [SSL配置模块](#SSL配置模块)
7. [错误处理模块](#错误处理模块)

---

## 系统检测模块

### 功能说明

自动检测系统类型、版本、架构等信息，并根据检测结果选择合适的配置。

### 代码示例

```bash
#!/bin/bash

# 系统检测模块
detect_system() {
    print_header "🔍 检测系统环境"
    
    # 检测发行版
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$NAME
        OS_VERSION=$VERSION_ID
        OS_ID=$ID
        OS_ID_LIKE=$ID_LIKE
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS_NAME=$DISTRIB_ID
        OS_VERSION=$DISTRIB_RELEASE
    else
        OS_NAME=$(uname -s)
        OS_VERSION=$(uname -r)
    fi
    
    # 检测架构
    ARCH=$(uname -m)
    
    # 检测包管理器
    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt"
        PKG_UPDATE="apt-get update"
        PKG_INSTALL="apt-get install -y"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        PKG_UPDATE="dnf check-update"
        PKG_INSTALL="dnf install -y"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        PKG_UPDATE="yum check-update"
        PKG_INSTALL="yum install -y"
    else
        PKG_MANAGER="unknown"
    fi
    
    # 检测 init 系统
    if command -v systemctl &> /dev/null; then
        INIT_SYSTEM="systemd"
        SERVICE_START="systemctl start"
        SERVICE_STOP="systemctl stop"
        SERVICE_RESTART="systemctl restart"
        SERVICE_ENABLE="systemctl enable"
    else
        INIT_SYSTEM="sysvinit"
        SERVICE_START="service"
        SERVICE_STOP="service"
        SERVICE_RESTART="service"
        SERVICE_ENABLE="chkconfig"
    fi
    
    # 检测 Nginx 配置路径
    if [ -d "/etc/nginx/sites-available" ]; then
        NGINX_STYLE="debian"
        NGINX_CONF_DIR="/etc/nginx/sites-available"
        NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"
        NGINX_NEED_SYMLINK=true
        NGINX_CONF_EXT=""
    elif [ -d "/etc/nginx/conf.d" ]; then
        NGINX_STYLE="redhat"
        NGINX_CONF_DIR="/etc/nginx/conf.d"
        NGINX_NEED_SYMLINK=false
        NGINX_CONF_EXT=".conf"
    else
        NGINX_STYLE="unknown"
    fi
    
    # 显示检测结果
    print_success "系统检测完成"
    echo ""
    echo "  发行版: $OS_NAME $OS_VERSION"
    echo "  架构: $ARCH"
    echo "  包管理器: $PKG_MANAGER"
    echo "  Init 系统: $INIT_SYSTEM"
    echo "  Nginx 风格: $NGINX_STYLE"
    echo ""
    
    # 保存到配置文件
    cat > /tmp/scan-code-system-info.conf << EOF
OS_NAME="$OS_NAME"
OS_VERSION="$OS_VERSION"
OS_ID="$OS_ID"
ARCH="$ARCH"
PKG_MANAGER="$PKG_MANAGER"
INIT_SYSTEM="$INIT_SYSTEM"
NGINX_STYLE="$NGINX_STYLE"
NGINX_CONF_DIR="$NGINX_CONF_DIR"
NGINX_NEED_SYMLINK=$NGINX_NEED_SYMLINK
NGINX_CONF_EXT="$NGINX_CONF_EXT"
EOF
}
```

---

## 权限管理模块

### 功能说明

智能检测和管理权限，确保脚本有足够的权限执行操作。

### 代码示例

```bash
# 权限检查模块
check_permissions() {
    print_header "🔐 检查权限"
    
    # 检查是否为 root
    if [ "$EUID" -eq 0 ]; then
        print_warning "检测到 root 用户"
        print_info "建议使用普通用户 + sudo 运行"
        IS_ROOT=true
        HAS_SUDO=true
    else
        IS_ROOT=false
        
        # 检查 sudo 权限
        if sudo -n true 2>/dev/null; then
            print_success "已有 sudo 权限"
            HAS_SUDO=true
        else
            print_info "需要 sudo 权限来安装软件和配置系统"
            echo ""
            read -p "是否授予 sudo 权限？(y/n) [默认: y]: " GRANT_SUDO
            GRANT_SUDO=${GRANT_SUDO:-y}
            
            if [[ $GRANT_SUDO =~ ^[Yy]$ ]]; then
                if sudo -v; then
                    print_success "sudo 权限已获取"
                    HAS_SUDO=true
                else
                    print_error "无法获取 sudo 权限"
                    HAS_SUDO=false
                    return 1
                fi
            else
                print_warning "未授予 sudo 权限，某些功能可能无法使用"
                HAS_SUDO=false
            fi
        fi
    fi
    
    # 保持 sudo 会话（避免超时）
    if [ "$HAS_SUDO" = true ] && [ "$IS_ROOT" != true ]; then
        while true; do
            sudo -n true
            sleep 60
            kill -0 "$$" || exit
        done 2>/dev/null &
        SUDO_REFRESH_PID=$!
        
        # 脚本退出时清理
        trap "kill $SUDO_REFRESH_PID 2>/dev/null" EXIT
    fi
    
    # 检查特定目录的写权限
    check_write_permission "/etc/nginx" "Nginx 配置目录"
    check_write_permission "/opt" "项目安装目录"
    
    echo ""
}

check_write_permission() {
    local dir=$1
    local name=$2
    
    if [ -d "$dir" ]; then
        if sudo touch "$dir/.test" 2>/dev/null; then
            sudo rm "$dir/.test"
            print_success "$name 可写"
        else
            print_error "$name 不可写"
            return 1
        fi
    else
        print_warning "$name 不存在"
    fi
}
```

---

## 环境检测模块

### 功能说明

检测 Python、Node.js、端口占用、磁盘空间等环境信息。

### 代码示例

```bash
# 环境检测模块
detect_environment() {
    print_header "🔍 检测运行环境"
    
    # 检测 Python
    echo ""
    echo "Python 环境:"
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version | awk '{print $2}')
        PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
        PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)
        print_success "Python: $PYTHON_VERSION"
        
        if [ "$PYTHON_MAJOR" -ge 3 ] && [ "$PYTHON_MINOR" -ge 6 ]; then
            PYTHON_OK=true
        else
            print_warning "Python 版本过低，建议 >= 3.6"
            PYTHON_OK=false
        fi
        
        # 检测 pip
        if command -v pip3 &> /dev/null; then
            print_success "pip3: $(pip3 --version | awk '{print $2}')"
        else
            print_warning "pip3 未安装"
        fi
    else
        print_error "Python3 未安装"
        PYTHON_OK=false
    fi
    
    # 检测 Node.js
    echo ""
    echo "Node.js 环境:"
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version | sed 's/v//')
        NODE_MAJOR=$(echo $NODE_VERSION | cut -d. -f1)
        print_success "Node.js: $NODE_VERSION"
        
        if [ "$NODE_MAJOR" -ge 16 ]; then
            NODE_OK=true
        else
            print_warning "Node.js 版本过低，建议 >= 16"
            NODE_OK=false
        fi
    else
        print_error "Node.js 未安装"
        NODE_OK=false
    fi
    
    if command -v npm &> /dev/null; then
        print_success "npm: $(npm --version)"
    else
        print_error "npm 未安装"
    fi
    
    # 检测 Git
    echo ""
    echo "版本控制:"
    if command -v git &> /dev/null; then
        print_success "Git: $(git --version | awk '{print $3}')"
    else
        print_error "Git 未安装"
    fi
    
    # 检测 Nginx
    echo ""
    echo "Web 服务器:"
    if command -v nginx &> /dev/null; then
        print_success "Nginx: $(nginx -v 2>&1 | awk '{print $3}')"
    else
        print_warning "Nginx 未安装"
    fi
    
    # 检测 PM2
    echo ""
    echo "进程管理:"
    if command -v pm2 &> /dev/null; then
        print_success "PM2: $(pm2 --version)"
    else
        print_warning "PM2 未安装"
    fi
    
    # 检测端口占用
    echo ""
    echo "端口检查:"
    check_port_usage 3001 "后端默认端口"
    check_port_usage 6006 "前端推荐端口"
    check_port_usage 80 "HTTP 标准端口"
    check_port_usage 443 "HTTPS 标准端口"
    
    # 检测磁盘空间
    echo ""
    echo "系统资源:"
    DISK_AVAILABLE=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
    DISK_TOTAL=$(df -BG / | tail -1 | awk '{print $2}' | sed 's/G//')
    
    if [ "$DISK_AVAILABLE" -lt 5 ]; then
        print_warning "磁盘空间不足 5GB，当前可用: ${DISK_AVAILABLE}GB / ${DISK_TOTAL}GB"
    else
        print_success "磁盘空间充足: ${DISK_AVAILABLE}GB / ${DISK_TOTAL}GB"
    fi
    
    # 检测内存
    MEM_TOTAL=$(free -g | awk '/^Mem:/{print $2}')
    MEM_AVAILABLE=$(free -g | awk '/^Mem:/{print $7}')
    
    if [ "$MEM_AVAILABLE" -lt 1 ]; then
        print_warning "可用内存不足 1GB，当前: ${MEM_AVAILABLE}GB / ${MEM_TOTAL}GB"
    else
        print_success "可用内存: ${MEM_AVAILABLE}GB / ${MEM_TOTAL}GB"
    fi
    
    echo ""
}

check_port_usage() {
    local port=$1
    local name=$2
    
    if netstat -tlnp 2>/dev/null | grep -q ":$port " || ss -tlnp 2>/dev/null | grep -q ":$port "; then
        print_warning "$name ($port) 已被占用"
        return 1
    else
        print_success "$name ($port) 可用"
        return 0
    fi
}
```

---

## 交互体验模块

### 功能说明

提供友好的交互界面，包括输入验证、配置预览等。

### 代码示例

```bash
# 改进的配置收集模块
collect_config_smart() {
    print_header "⚙️  配置部署参数"
    
    # 项目目录
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📁 项目安装目录"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  建议:"
    echo "    /opt/scan-code     - 生产环境（推荐）"
    echo "    $HOME/scan-code    - 开发环境"
    echo ""
    
    while true; do
        read -p "请输入项目安装目录 [默认: /opt/scan-code]: " INSTALL_DIR
        INSTALL_DIR=${INSTALL_DIR:-/opt/scan-code}
        
        # 验证路径
        if [[ ! "$INSTALL_DIR" =~ ^/ ]]; then
            print_error "请输入绝对路径（以 / 开头）"
            continue
        fi
        
        # 检查目录是否存在
        if [ -d "$INSTALL_DIR" ]; then
            print_warning "目录已存在: $INSTALL_DIR"
            echo ""
            echo "选项:"
            echo "  1. 删除并重新安装"
            echo "  2. 更新现有安装"
            echo "  3. 重新选择目录"
            echo ""
            read -p "请选择 [默认: 2]: " DIR_CHOICE
            DIR_CHOICE=${DIR_CHOICE:-2}
            
            case $DIR_CHOICE in
                1)
                    REINSTALL=true
                    break
                    ;;
                2)
                    REINSTALL=false
                    break
                    ;;
                3)
                    continue
                    ;;
                *)
                    print_error "无效选择"
                    continue
                    ;;
            esac
        else
            REINSTALL=false
            break
        fi
    done
    
    print_info "✓ 项目目录: $INSTALL_DIR"
    
    # 后端端口
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔌 后端服务端口"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  默认: 3001"
    echo "  建议范围: 3000-9000"
    echo ""
    
    while true; do
        read -p "请输入后端服务端口 [默认: 3001]: " BACKEND_PORT
        BACKEND_PORT=${BACKEND_PORT:-3001}
        
        # 验证端口号
        if ! [[ "$BACKEND_PORT" =~ ^[0-9]+$ ]]; then
            print_error "端口号必须是数字"
            continue
        fi
        
        if [ "$BACKEND_PORT" -lt 1024 ] || [ "$BACKEND_PORT" -gt 65535 ]; then
            print_error "端口号范围: 1024-65535"
            continue
        fi
        
        # 检查端口占用
        if ! check_port_usage "$BACKEND_PORT" "后端"; then
            echo ""
            read -p "端口已占用，是否继续使用？(y/n) [默认: n]: " USE_OCCUPIED
            if [[ ! $USE_OCCUPIED =~ ^[Yy]$ ]]; then
                continue
            fi
        fi
        
        break
    done
    
    print_info "✓ 后端端口: $BACKEND_PORT"
    
    # 前端端口（类似逻辑）
    # ... 省略，与后端端口类似 ...
    
    # 服务器地址
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌍 服务器地址配置"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  用途: Nginx 的 server_name（域名匹配）"
    echo ""
    echo "  选项:"
    echo "    1. 服务器 IP（如 192.168.8.91）"
    echo "    2. 域名（如 example.com）"
    echo "    3. _ (匹配所有请求，推荐)"
    echo ""
    echo "  ⚠️  注意: 不要填写 0.0.0.0"
    echo "     (0.0.0.0 不是有效的 server_name)"
    echo ""
    
    # 自动检测 IP
    AUTO_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [ -n "$AUTO_IP" ]; then
        echo "  💡 检测到本机 IP: $AUTO_IP"
        echo ""
    fi
    
    while true; do
        read -p "请输入服务器地址 [默认: _]: " SERVER_HOST
        SERVER_HOST=${SERVER_HOST:-_}
        
        # 验证输入
        if [ "$SERVER_HOST" = "0.0.0.0" ]; then
            print_error "0.0.0.0 不是有效的 server_name"
            print_info "提示: 外部访问由 listen 指令控制，默认已支持"
            echo ""
            continue
        fi
        
        break
    done
    
    print_info "✓ 服务器地址: $SERVER_HOST"
    
    # 配置预览
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 配置预览"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  项目目录: $INSTALL_DIR"
    echo "  后端端口: $BACKEND_PORT"
    echo "  前端端口: $FRONTEND_PORT"
    echo "  服务器地址: $SERVER_HOST"
    echo ""
    echo "  系统类型: $OS_NAME"
    echo "  Nginx 风格: $NGINX_STYLE"
    echo "  配置文件: $NGINX_CONF_DIR/scan-code$NGINX_CONF_EXT"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    read -p "确认以上配置？(y/n) [默认: y]: " CONFIRM
    CONFIRM=${CONFIRM:-y}
    
    if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
        print_warning "已取消，请重新配置"
        exit 0
    fi
    
    print_success "配置确认完成"
    echo ""
}
```

详细的 SSL 配置、日志系统、错误处理等模块请参考项目中的脚本文件。
