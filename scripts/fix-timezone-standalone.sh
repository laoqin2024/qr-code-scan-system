#!/bin/bash

# 时区修复脚本 - 独立版本
# 用途：修复数据库中的时间字段，从 UTC 转换为 UTC+8

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

clear
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}⏰ 时区修复脚本${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

print_warning "本脚本将修复数据库中的时间字段"
print_warning "将所有时间从 UTC 转换为 UTC+8（北京时间）"
echo ""
print_error "⚠️  重要提示："
echo "  1. 本脚本只能运行一次！"
echo "  2. 重复运行会导致时间错误（再次 +8 小时）"
echo "  3. 运行前会自动备份数据库"
echo ""

read -p "是否继续？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "已取消"
    exit 0
fi

# 检测项目目录
if [ -f "db.sqlite" ]; then
    PROJECT_DIR=$(pwd)
    print_success "检测到项目目录: $PROJECT_DIR"
elif [ -f "/opt/scan-code/db.sqlite" ]; then
    PROJECT_DIR="/opt/scan-code"
    cd "$PROJECT_DIR"
    print_success "使用项目目录: $PROJECT_DIR"
else
    print_error "未找到数据库文件"
    echo "请在项目根目录运行此脚本，或确保 /opt/scan-code/db.sqlite 存在"
    exit 1
fi

# 检查 sqlite3 是否安装
if ! command -v sqlite3 &> /dev/null; then
    print_error "sqlite3 未安装"
    echo "请先安装 sqlite3："
    echo "  Ubuntu/Debian: sudo apt-get install sqlite3"
    echo "  CentOS/RHEL: sudo yum install sqlite"
    exit 1
fi

# 备份数据库
echo ""
print_info "📦 备份数据库..."

BACKUP_DIR="/var/backups/scan-code"
if [ ! -d "$BACKUP_DIR" ] || [ ! -w "$BACKUP_DIR" ]; then
    BACKUP_DIR="$HOME/.scan-code-backups"
fi
if [ ! -d "$BACKUP_DIR" ]; then
    BACKUP_DIR="/tmp/scan-code-backups"
fi

mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/db.sqlite.before_timezone_fix_$TIMESTAMP"

cp db.sqlite "$BACKUP_FILE"
print_success "数据库已备份到: $BACKUP_FILE"

# 验证备份
if sqlite3 "$BACKUP_FILE" "PRAGMA integrity_check;" > /dev/null 2>&1; then
    print_success "备份文件验证通过"
else
    print_error "备份文件验证失败"
    exit 1
fi

# 显示当前数据统计
echo ""
print_info "📊 当前数据统计..."

SCAN_COUNT=$(sqlite3 db.sqlite "SELECT COUNT(*) FROM scans;")
USER_COUNT=$(sqlite3 db.sqlite "SELECT COUNT(*) FROM users;")
CUSTOMER_COUNT=$(sqlite3 db.sqlite "SELECT COUNT(*) FROM customers;")
PRODUCT_COUNT=$(sqlite3 db.sqlite "SELECT COUNT(*) FROM products;")

echo "  扫码记录: $SCAN_COUNT 条"
echo "  用户: $USER_COUNT 个"
echo "  客户: $CUSTOMER_COUNT 个"
echo "  产品: $PRODUCT_COUNT 个"

# 显示示例时间（修复前）
echo ""
print_info "🕐 修复前的时间示例..."

SAMPLE_SCAN=$(sqlite3 db.sqlite "SELECT created_at FROM scans ORDER BY id DESC LIMIT 1;" 2>/dev/null || echo "")
if [ -n "$SAMPLE_SCAN" ]; then
    echo "  扫码记录最新时间: $SAMPLE_SCAN"
fi

SAMPLE_USER=$(sqlite3 db.sqlite "SELECT created_at FROM users ORDER BY id DESC LIMIT 1;" 2>/dev/null || echo "")
if [ -n "$SAMPLE_USER" ]; then
    echo "  用户最新时间: $SAMPLE_USER"
fi

# 执行时区修复
echo ""
print_info "⏰ 开始修复时区..."

# 创建临时 SQL 文件
TMP_SQL="/tmp/fix_timezone_$TIMESTAMP.sql"

cat > "$TMP_SQL" << 'EOF'
-- 时区修复 SQL
-- 将所有时间字段从 UTC 转换为 UTC+8

BEGIN TRANSACTION;

-- 1. 修复扫码记录时间
UPDATE scans 
SET created_at = datetime(created_at, '+8 hours')
WHERE created_at IS NOT NULL;

-- 2. 修复用户时间
UPDATE users 
SET created_at = datetime(created_at, '+8 hours')
WHERE created_at IS NOT NULL;

-- 3. 修复客户时间
UPDATE customers 
SET created_at = datetime(created_at, '+8 hours')
WHERE created_at IS NOT NULL;

-- 4. 修复产品时间
UPDATE products 
SET created_at = datetime(created_at, '+8 hours')
WHERE created_at IS NOT NULL;

-- 5. 修复审计日志时间（如果存在）
UPDATE audit_logs 
SET created_at = datetime(created_at, '+8 hours')
WHERE created_at IS NOT NULL;

COMMIT;
EOF

# 执行 SQL
if sqlite3 db.sqlite < "$TMP_SQL"; then
    print_success "时区修复完成"
else
    print_error "时区修复失败"
    print_warning "正在恢复备份..."
    cp "$BACKUP_FILE" db.sqlite
    print_success "已恢复备份"
    rm -f "$TMP_SQL"
    exit 1
fi

# 清理临时文件
rm -f "$TMP_SQL"

# 验证数据库完整性
echo ""
print_info "🔍 验证数据库完整性..."

if sqlite3 db.sqlite "PRAGMA integrity_check;" > /dev/null 2>&1; then
    print_success "数据库完整性检查通过"
else
    print_error "数据库完整性检查失败"
    print_warning "正在恢复备份..."
    cp "$BACKUP_FILE" db.sqlite
    print_success "已恢复备份"
    exit 1
fi

# 显示修复后的时间
echo ""
print_info "🕐 修复后的时间示例..."

SAMPLE_SCAN_AFTER=$(sqlite3 db.sqlite "SELECT created_at FROM scans ORDER BY id DESC LIMIT 1;" 2>/dev/null || echo "")
if [ -n "$SAMPLE_SCAN_AFTER" ]; then
    echo "  扫码记录最新时间: $SAMPLE_SCAN_AFTER"
fi

SAMPLE_USER_AFTER=$(sqlite3 db.sqlite "SELECT created_at FROM users ORDER BY id DESC LIMIT 1;" 2>/dev/null || echo "")
if [ -n "$SAMPLE_USER_AFTER" ]; then
    echo "  用户最新时间: $SAMPLE_USER_AFTER"
fi

# 验证数据统计
echo ""
print_info "📊 验证数据统计..."

SCAN_COUNT_AFTER=$(sqlite3 db.sqlite "SELECT COUNT(*) FROM scans;")
USER_COUNT_AFTER=$(sqlite3 db.sqlite "SELECT COUNT(*) FROM users;")
CUSTOMER_COUNT_AFTER=$(sqlite3 db.sqlite "SELECT COUNT(*) FROM customers;")
PRODUCT_COUNT_AFTER=$(sqlite3 db.sqlite "SELECT COUNT(*) FROM products;")

echo "  扫码记录: $SCAN_COUNT_AFTER 条"
echo "  用户: $USER_COUNT_AFTER 个"
echo "  客户: $CUSTOMER_COUNT_AFTER 个"
echo "  产品: $PRODUCT_COUNT_AFTER 个"

if [ "$SCAN_COUNT" = "$SCAN_COUNT_AFTER" ] && \
   [ "$USER_COUNT" = "$USER_COUNT_AFTER" ] && \
   [ "$CUSTOMER_COUNT" = "$CUSTOMER_COUNT_AFTER" ] && \
   [ "$PRODUCT_COUNT" = "$PRODUCT_COUNT_AFTER" ]; then
    print_success "数据数量验证通过"
else
    print_error "数据数量不一致！"
    print_warning "正在恢复备份..."
    cp "$BACKUP_FILE" db.sqlite
    print_success "已恢复备份"
    exit 1
fi

# 完成
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 时区修复完成！${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

print_info "📋 修复信息:"
echo "  项目目录: $PROJECT_DIR"
echo "  备份文件: $BACKUP_FILE"
echo "  修复记录: $SCAN_COUNT 条扫码记录"
echo "  修复用户: $USER_COUNT 个用户"
echo "  修复客户: $CUSTOMER_COUNT 个客户"
echo "  修复产品: $PRODUCT_COUNT 个产品"
echo ""

print_info "🔧 下一步操作:"
echo "  1. 重启后端服务: pm2 restart scan-code-backend"
echo "  2. 浏览器访问并验证时间显示"
echo "  3. 检查新扫码记录的时间是否正确"
echo ""

print_warning "⚠️  重要提示："
echo "  - 本脚本已运行，请勿再次运行！"
echo "  - 新数据会自动使用正确的时区"
echo "  - 如需恢复，使用备份文件: $BACKUP_FILE"
echo ""

print_info "💾 恢复命令（如果需要）:"
echo "  cp $BACKUP_FILE $PROJECT_DIR/db.sqlite"
echo "  pm2 restart scan-code-backend"
echo ""
