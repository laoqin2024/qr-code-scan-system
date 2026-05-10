#!/bin/bash

# 二维码扫码防错系统 - 项目更新脚本
# 用于已部署项目的更新升级

set -e  # 遇到错误立即退出
set -o pipefail  # 管道命令中任何一个失败都会导致整个管道失败

# 全局变量
DB_BACKUP_FILE=""
DB_TEMP_MOVED=false
STASHED=false

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
    print_header "🔄 二维码扫码防错系统 - 项目更新脚本"
    
    echo ""
    print_info "本脚本将帮助您完成以下操作："
    echo "  1. 备份当前数据库"
    echo "  2. 拉取最新代码"
    echo "  3. 安装/更新依赖"
    echo "  4. 构建前端"
    echo "  5. 数据库迁移（如需要）"
    echo "  6. 重启服务"
    echo ""
    
    read -p "是否继续？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "更新已取消"
        exit 0
    fi
    
    # 检测项目目录
    detect_project_dir
    
    # 检查 PM2
    check_pm2
    
    # 步骤1: 备份数据库
    print_header "💾 步骤 1/6: 备份数据库"
    backup_database
    
    # 步骤2: 拉取最新代码
    print_header "📥 步骤 2/6: 拉取最新代码"
    pull_code
    
    # 步骤3: 更新依赖
    print_header "📦 步骤 3/6: 更新依赖"
    update_dependencies
    
    # 步骤4: 构建前端
    print_header "🏗️  步骤 4/6: 构建前端"
    build_frontend
    
    # 步骤5: 数据库迁移
    print_header "🗄️  步骤 5/6: 数据库迁移"
    migrate_database
    
    # 步骤6: 重启服务
    print_header "🔄 步骤 6/6: 重启服务"
    restart_services
    
    # 完成
    print_header "🎉 更新完成！"
    
    # 最终验证
    print_info "执行最终验证..."
    echo ""
    
    # 验证数据库
    if [ -f "$PROJECT_DIR/db.sqlite" ]; then
        if sqlite3 "$PROJECT_DIR/db.sqlite" "PRAGMA integrity_check;" > /dev/null 2>&1; then
            print_success "✓ 数据库完整性验证通过"
        else
            print_error "✗ 数据库验证失败！"
            print_warning "建议恢复备份: cp $DB_BACKUP_FILE db.sqlite"
        fi
    else
        print_error "✗ 数据库文件不存在！"
    fi
    
    # 验证前端构建
    if [ -d "$PROJECT_DIR/frontend/dist" ] && [ -f "$PROJECT_DIR/frontend/dist/index.html" ]; then
        print_success "✓ 前端构建文件存在"
    else
        print_error "✗ 前端构建文件缺失！"
    fi
    
    # 验证后端服务
    sleep 2
    if pm2 list | grep -q "scan-code-backend.*online"; then
        print_success "✓ 后端服务运行正常"
    else
        print_error "✗ 后端服务未正常运行！"
    fi
    
    echo ""
    show_summary
}

# 错误处理函数
handle_error() {
    local exit_code=$?
    local line_number=$1
    
    print_error "更新过程中发生错误（退出码: $exit_code，行号: $line_number）"
    
    # 如果有数据库备份，提供恢复选项
    if [ -n "$DB_BACKUP_FILE" ] && [ -f "$DB_BACKUP_FILE" ]; then
        echo ""
        print_warning "检测到数据库备份文件"
        read -p "是否恢复数据库备份？(y/n) [默认: y]: " RESTORE_DB
        RESTORE_DB=${RESTORE_DB:-y}
        
        if [[ $RESTORE_DB =~ ^[Yy]$ ]]; then
            print_info "恢复数据库..."
            cd "$PROJECT_DIR"
            cp "$DB_BACKUP_FILE" db.sqlite
            print_success "数据库已恢复"
        fi
    fi
    
    # 如果数据库在临时位置，恢复它
    if [ "$DB_TEMP_MOVED" = true ] && [ -f "/tmp/db.sqlite.updating.$$" ]; then
        print_info "恢复临时移动的数据库..."
        cd "$PROJECT_DIR"
        mv /tmp/db.sqlite.updating.$$ db.sqlite
        print_success "数据库已恢复"
    fi
    
    echo ""
    print_error "更新失败！请检查错误信息"
    echo ""
    echo "📋 故障排除："
    echo "  1. 查看完整日志"
    echo "  2. 检查网络连接"
    echo "  3. 检查磁盘空间: df -h"
    echo "  4. 查看服务状态: pm2 list"
    echo "  5. 查看服务日志: pm2 logs"
    echo ""
    echo "🔄 恢复选项："
    if [ -n "$DB_BACKUP_FILE" ]; then
        echo "  恢复数据库: cp $DB_BACKUP_FILE db.sqlite"
    fi
    echo "  查看备份列表: ls -lh backups/"
    echo ""
    
    exit 1
}

# 设置错误捕获
trap 'handle_error $LINENO' ERR
}

# 检测项目目录
detect_project_dir() {
    # 如果在项目目录内运行
    if [ -f "package.json" ] && [ -d "backend" ] && [ -d "frontend" ]; then
        PROJECT_DIR=$(pwd)
        print_success "检测到项目目录: $PROJECT_DIR"
        return
    fi
    
    # 常见安装位置
    COMMON_DIRS=(
        "/opt/scan-code"
        "$HOME/scan-code"
        "/var/www/scan-code"
    )
    
    for dir in "${COMMON_DIRS[@]}"; do
        if [ -d "$dir" ] && [ -f "$dir/package.json" ]; then
            PROJECT_DIR="$dir"
            print_success "检测到项目目录: $PROJECT_DIR"
            return
        fi
    done
    
    # 手动输入
    print_warning "未能自动检测项目目录"
    read -p "请输入项目目录路径: " PROJECT_DIR
    
    if [ ! -d "$PROJECT_DIR" ]; then
        print_error "目录不存在: $PROJECT_DIR"
        exit 1
    fi
    
    cd "$PROJECT_DIR"
}

# 检查 PM2
check_pm2() {
    if check_command pm2; then
        USE_PM2=true
        print_success "检测到 PM2"
    else
        USE_PM2=false
        print_warning "未检测到 PM2，将使用手动重启"
    fi
}

# 备份数据库
backup_database() {
    cd "$PROJECT_DIR"
    
    if [ ! -f "db.sqlite" ]; then
        print_warning "数据库文件不存在，跳过备份"
        DB_BACKUP_FILE=""
        return
    fi
    
    # 检查数据库文件完整性
    print_info "检查数据库完整性..."
    if ! sqlite3 db.sqlite "PRAGMA integrity_check;" > /dev/null 2>&1; then
        print_error "数据库文件已损坏！"
        print_warning "建议从备份恢复或重新初始化"
        read -p "是否继续更新？(y/n) [默认: n]: " CONTINUE_WITH_BAD_DB
        CONTINUE_WITH_BAD_DB=${CONTINUE_WITH_BAD_DB:-n}
        if [[ ! $CONTINUE_WITH_BAD_DB =~ ^[Yy]$ ]]; then
            print_error "更新已取消"
            exit 1
        fi
    else
        print_success "数据库完整性检查通过"
    fi
    
    BACKUP_DIR="backups"
    mkdir -p "$BACKUP_DIR"
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    DB_BACKUP_FILE="$BACKUP_DIR/db.sqlite.backup_$TIMESTAMP"
    
    print_info "备份数据库到: $DB_BACKUP_FILE"
    
    # 使用 cp 而不是 mv，确保原文件不被破坏
    if cp db.sqlite "$DB_BACKUP_FILE"; then
        print_success "数据库备份完成"
        
        # 验证备份文件
        if sqlite3 "$DB_BACKUP_FILE" "PRAGMA integrity_check;" > /dev/null 2>&1; then
            print_success "备份文件验证通过"
        else
            print_error "备份文件验证失败！"
            rm -f "$DB_BACKUP_FILE"
            print_error "更新已取消"
            exit 1
        fi
    else
        print_error "数据库备份失败！"
        print_error "更新已取消"
        exit 1
    fi
    
    # 保留最近10个备份
    print_info "清理旧备份（保留最近10个）..."
    ls -t "$BACKUP_DIR"/db.sqlite.backup_* 2>/dev/null | tail -n +11 | xargs -r rm
    
    echo ""
    print_info "💾 备份信息："
    echo "  备份文件: $DB_BACKUP_FILE"
    echo "  备份大小: $(du -h "$DB_BACKUP_FILE" | cut -f1)"
    echo "  恢复命令: cp $DB_BACKUP_FILE db.sqlite"
    echo ""
}

# 拉取最新代码
pull_code() {
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
            git stash push -m "Auto stash before update $(date +%Y%m%d_%H%M%S)"
            STASHED=true
        else
            print_error "请先处理未提交的更改"
            exit 1
        fi
    fi
    
    # 临时移动数据库文件到安全位置
    print_info "保护数据库文件..."
    if [ -f "db.sqlite" ]; then
        mv db.sqlite /tmp/db.sqlite.updating.$$
        DB_TEMP_MOVED=true
        print_success "数据库已移至安全位置"
    fi
    
    # 拉取最新代码
    print_info "拉取最新代码..."
    
    # 获取当前分支
    CURRENT_BRANCH=$(git branch --show-current)
    print_info "当前分支: $CURRENT_BRANCH"
    
    # 拉取代码
    if git pull origin "$CURRENT_BRANCH"; then
        print_success "代码更新完成"
    else
        print_error "代码拉取失败！"
        
        # 恢复数据库
        if [ "$DB_TEMP_MOVED" = true ]; then
            mv /tmp/db.sqlite.updating.$$ db.sqlite
            print_info "数据库已恢复"
        fi
        
        exit 1
    fi
    
    # 恢复数据库文件
    if [ "$DB_TEMP_MOVED" = true ]; then
        mv /tmp/db.sqlite.updating.$$ db.sqlite
        print_success "数据库已恢复到项目目录"
    fi
    
    # 如果之前暂存了更改，询问是否恢复
    if [ "$STASHED" = true ]; then
        echo ""
        read -p "是否恢复之前暂存的更改？(y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "恢复暂存的更改..."
            git stash pop
        else
            print_info "更改已保存在 stash 中，可使用 'git stash pop' 恢复"
        fi
    fi
}

# 更新依赖
update_dependencies() {
    cd "$PROJECT_DIR"
    
    # 检查是否需要更新依赖
    print_info "检查依赖更新..."
    
    # 更新后端依赖
    if [ -f "backend/package.json" ]; then
        print_info "更新后端依赖..."
        cd backend
        
        # 检查 package.json 是否有变化
        if git diff HEAD@{1} HEAD -- package.json &>/dev/null; then
            print_info "检测到依赖变化，重新安装..."
            npm install
        else
            print_info "依赖无变化，跳过安装"
        fi
        
        cd ..
    fi
    
    # 更新前端依赖
    if [ -f "frontend/package.json" ]; then
        print_info "更新前端依赖..."
        cd frontend
        
        if git diff HEAD@{1} HEAD -- package.json &>/dev/null; then
            print_info "检测到依赖变化，重新安装..."
            npm install
        else
            print_info "依赖无变化，跳过安装"
        fi
        
        cd ..
    fi
    
    print_success "依赖更新完成"
}

# 构建前端
build_frontend() {
    cd "$PROJECT_DIR/frontend"
    
    print_info "构建前端..."
    npm run build
    
    print_success "前端构建完成"
}

# 数据库迁移
migrate_database() {
    cd "$PROJECT_DIR/backend"
    
    # 检查是否有迁移脚本
    if [ -f "src/migrate-v3.ts" ]; then
        print_info "检测到数据库迁移脚本"
        read -p "是否执行数据库迁移？(y/n) [默认: n]: " RUN_MIGRATION
        RUN_MIGRATION=${RUN_MIGRATION:-n}
        
        if [ "$RUN_MIGRATION" = "y" ]; then
            print_info "执行数据库迁移..."
            npm run migrate-v3 || print_warning "迁移脚本执行失败或已执行过"
        else
            print_info "跳过数据库迁移"
        fi
    else
        print_info "无需数据库迁移"
    fi
}

# 重启服务
restart_services() {
    cd "$PROJECT_DIR"
    
    if [ "$USE_PM2" = true ]; then
        print_info "使用 PM2 重启服务..."
        
        # 查找 PM2 进程
        PM2_APPS=$(pm2 jlist 2>/dev/null | grep -o '"name":"[^"]*scan-code[^"]*"' | cut -d'"' -f4 || echo "")
        
        if [ -z "$PM2_APPS" ]; then
            print_warning "未找到 PM2 进程，尝试启动..."
            cd backend
            pm2 start npm --name "scan-code-backend" -- start
            pm2 save
        else
            print_info "重启 PM2 进程: $PM2_APPS"
            for app in $PM2_APPS; do
                pm2 restart "$app"
            done
        fi
        
        print_success "服务重启完成"
        
        # 显示状态
        echo ""
        pm2 list
        
    else
        print_warning "请手动重启服务"
        echo ""
        echo "如果使用 systemd:"
        echo "  sudo systemctl restart scan-code"
        echo ""
        echo "如果使用 nohup:"
        echo "  1. 停止服务: kill \$(cat backend.pid)"
        echo "  2. 启动服务: cd backend && nohup npm start > ../logs/backend.log 2>&1 & echo \$! > ../backend.pid"
    fi
    
    # 重启 Nginx（如果需要）
    if check_command nginx; then
        echo ""
        read -p "是否重启 Nginx？(y/n) [默认: n]: " RESTART_NGINX
        RESTART_NGINX=${RESTART_NGINX:-n}
        
        if [ "$RESTART_NGINX" = "y" ]; then
            print_info "重启 Nginx..."
            sudo systemctl restart nginx || sudo service nginx restart
            print_success "Nginx 重启完成"
        fi
    fi
}

# 显示更新总结
show_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉 更新成功！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📋 更新信息:"
    echo "  项目目录: $PROJECT_DIR"
    echo "  当前分支: $(git branch --show-current)"
    echo "  最新提交: $(git log -1 --oneline)"
    echo ""
    
    if [ -d "$PROJECT_DIR/backups" ]; then
        LATEST_BACKUP=$(ls -t "$PROJECT_DIR/backups"/db.sqlite.backup_* 2>/dev/null | head -1)
        if [ -n "$LATEST_BACKUP" ]; then
            echo "💾 数据库备份:"
            echo "  最新备份: $LATEST_BACKUP"
            echo ""
        fi
    fi
    
    echo "🔧 常用命令:"
    if [ "$USE_PM2" = true ]; then
        echo "  查看日志: pm2 logs"
        echo "  查看状态: pm2 status"
        echo "  重启服务: pm2 restart scan-code-backend"
    fi
    echo "  查看 Git 日志: git log --oneline -10"
    echo "  回滚到上一版本: git reset --hard HEAD~1"
    echo ""
    if [ -n "$DB_BACKUP_FILE" ]; then
        echo "⚠️  如遇问题:"
        echo "  1. 查看日志排查错误"
        echo "  2. 恢复数据库备份: cp $DB_BACKUP_FILE db.sqlite"
        echo "  3. 回滚代码: git reset --hard <commit-hash>"
        echo ""
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# 运行主函数
main
