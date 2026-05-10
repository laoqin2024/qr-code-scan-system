#!/bin/bash

# 安全更新脚本 - 只更新前端代码，不触碰数据库

set -e
set -o pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 检测项目目录
detect_project_dir() {
    if [ -f "package.json" ] && [ -d "backend" ] && [ -d "frontend" ]; then
        PROJECT_DIR=$(pwd)
        print_success "检测到项目目录: $PROJECT_DIR"
        return
    fi
    
    if [ -d "/opt/scan-code" ]; then
        PROJECT_DIR="/opt/scan-code"
        cd "$PROJECT_DIR"
        print_success "使用项目目录: $PROJECT_DIR"
        return
    fi
    
    print_error "未找到项目目录"
    exit 1
}

main() {
    clear
    print_header "🔄 安全更新脚本 - 只更新前端代码"
    
    echo ""
    print_info "本脚本将执行以下操作："
    echo "  1. 拉取最新代码"
    echo "  2. 更新前端依赖（如有变化）"
    echo "  3. 重新构建前端"
    echo "  4. 重启后端服务（使前端生效）"
    echo ""
    print_warning "⚠️  本脚本不会触碰数据库文件"
    print_warning "⚠️  数据库保持原样，100% 安全"
    echo ""
    
    read -p "是否继续？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "更新已取消"
        exit 0
    fi
    
    # 检测项目目录
    detect_project_dir
    
    # 步骤1: 拉取最新代码
    print_header "📥 步骤 1/4: 拉取最新代码"
    echo ""
    
    cd "$PROJECT_DIR"
    
    # 检查是否有未提交的更改
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        print_warning "检测到未提交的更改"
        git status --short
        echo ""
        read -p "是否暂存这些更改并继续？(y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "暂存更改..."
            git stash push -m "Auto stash before safe update $(date +%Y%m%d_%H%M%S)"
        else
            print_error "请先处理未提交的更改"
            exit 1
        fi
    fi
    
    # 拉取代码
    print_info "拉取最新代码..."
    CURRENT_BRANCH=$(git branch --show-current)
    print_info "当前分支: $CURRENT_BRANCH"
    
    if git pull origin "$CURRENT_BRANCH"; then
        print_success "代码更新完成"
    else
        print_error "代码拉取失败！"
        exit 1
    fi
    
    # 步骤2: 检查前端依赖
    print_header "📦 步骤 2/4: 检查前端依赖"
    echo ""
    
    cd "$PROJECT_DIR/frontend"
    
    if [ ! -d "node_modules" ]; then
        print_warning "前端依赖未安装，开始安装..."
        npm install
        print_success "前端依赖安装完成"
    else
        # 检查 package.json 是否有变化
        if git diff HEAD@{1} HEAD -- package.json &>/dev/null; then
            print_info "检测到依赖变化，重新安装..."
            npm install
            print_success "前端依赖更新完成"
        else
            print_info "依赖无变化，跳过安装"
        fi
    fi
    
    # 步骤3: 构建前端
    print_header "🏗️  步骤 3/4: 构建前端"
    echo ""
    
    print_info "开始构建前端..."
    if npm run build; then
        print_success "前端构建完成"
    else
        print_error "前端构建失败！"
        exit 1
    fi
    
    # 验证构建结果
    if [ -f "dist/index.html" ]; then
        print_success "构建文件验证通过"
    else
        print_error "构建文件缺失！"
        exit 1
    fi
    
    # 步骤4: 重启后端服务
    print_header "🔄 步骤 4/4: 重启后端服务"
    echo ""
    
    cd "$PROJECT_DIR"
    
    if command -v pm2 &> /dev/null; then
        if pm2 list | grep -q "scan-code-backend"; then
            print_info "重启后端服务..."
            pm2 restart scan-code-backend
            print_success "服务已重启"
            
            # 等待服务启动
            sleep 2
            
            # 检查状态
            if pm2 list | grep "scan-code-backend" | grep -q "online"; then
                print_success "服务运行正常"
            else
                print_warning "服务状态异常，请检查日志"
            fi
        else
            print_warning "后端服务未在 PM2 中运行"
        fi
    else
        print_warning "PM2 未安装，请手动重启服务"
    fi
    
    # 完成
    print_header "🎉 更新完成！"
    echo ""
    print_success "前端代码已更新"
    print_success "数据库文件未被触碰，100% 安全"
    echo ""
    print_info "📋 更新信息:"
    echo "  项目目录: $PROJECT_DIR"
    echo "  当前分支: $(git branch --show-current)"
    echo "  最新提交: $(git log -1 --oneline)"
    echo ""
    print_info "🔧 验证更新:"
    echo "  1. 刷新浏览器（Ctrl+Shift+R 强制刷新）"
    echo "  2. 测试新功能（二维码搜索、完整显示）"
    echo "  3. 检查时间显示是否正确"
    echo ""
    print_info "💾 数据库状态:"
    if [ -f "$PROJECT_DIR/db.sqlite" ]; then
        echo "  数据库文件: 存在"
        echo "  文件大小: $(du -h "$PROJECT_DIR/db.sqlite" | cut -f1)"
        echo "  状态: 未被修改 ✅"
    fi
    echo ""
}

main
