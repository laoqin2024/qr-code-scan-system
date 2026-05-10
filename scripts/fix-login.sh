#!/bin/bash

# 快速修复登录问题

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔧 快速修复登录问题${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检查当前目录
if [ ! -f "package.json" ] || [ ! -d "backend" ]; then
    echo -e "${RED}❌ 错误：请在项目根目录运行此脚本${NC}"
    echo "   cd /opt/scan-code"
    echo "   bash scripts/fix-login.sh"
    exit 1
fi

echo -e "${YELLOW}⚠️  此操作将：${NC}"
echo "   1. 备份当前数据库到 /var/backups/scan-code/"
echo "   2. 使用 db.sqlite.init 重新初始化数据库"
echo "   3. 重启后端服务"
echo ""
echo -e "${RED}⚠️  警告：这将丢失所有扫码数据！${NC}"
echo ""
read -p "是否继续？(yes/no) [默认: no]: " CONFIRM
CONFIRM=${CONFIRM:-no}

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}操作已取消${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}📋 步骤 1: 备份当前数据库${NC}"

# 创建备份目录
if [ -d "/var/backups" ] && [ -w "/var/backups" ]; then
    BACKUP_DIR="/var/backups/scan-code"
elif [ -n "$HOME" ]; then
    BACKUP_DIR="$HOME/.scan-code-backups"
else
    BACKUP_DIR="/tmp/scan-code-backups"
fi

mkdir -p "$BACKUP_DIR"

# 备份数据库
if [ -f "db.sqlite" ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/db.sqlite.before_fix_$TIMESTAMP"
    cp db.sqlite "$BACKUP_FILE"
    echo -e "${GREEN}✓ 数据库已备份到: $BACKUP_FILE${NC}"
else
    echo -e "${YELLOW}⚠️  当前没有数据库文件${NC}"
fi

echo ""
echo -e "${BLUE}📋 步骤 2: 重新初始化数据库${NC}"

# 删除旧数据库
if [ -f "db.sqlite" ]; then
    rm -f db.sqlite
    echo -e "${GREEN}✓ 已删除旧数据库${NC}"
fi

# 使用预置数据库
if [ -f "db.sqlite.init" ]; then
    cp db.sqlite.init db.sqlite
    echo -e "${GREEN}✓ 已使用 db.sqlite.init 初始化数据库${NC}"
else
    echo -e "${RED}❌ db.sqlite.init 不存在${NC}"
    echo -e "${YELLOW}尝试运行初始化脚本...${NC}"
    cd backend
    npm run init-db
    cd ..
fi

# 验证数据库
if [ -f "db.sqlite" ]; then
    if sqlite3 db.sqlite "PRAGMA integrity_check;" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ 数据库完整性验证通过${NC}"
    else
        echo -e "${RED}❌ 数据库验证失败${NC}"
        exit 1
    fi
    
    # 检查用户
    ADMIN_EXISTS=$(sqlite3 db.sqlite "SELECT COUNT(*) FROM users WHERE username='admin';")
    TEST_EXISTS=$(sqlite3 db.sqlite "SELECT COUNT(*) FROM users WHERE username='test';")
    
    if [ "$ADMIN_EXISTS" = "1" ]; then
        echo -e "${GREEN}✓ admin 账号已创建${NC}"
    else
        echo -e "${RED}❌ admin 账号不存在${NC}"
    fi
    
    if [ "$TEST_EXISTS" = "1" ]; then
        echo -e "${GREEN}✓ test 账号已创建${NC}"
    else
        echo -e "${RED}❌ test 账号不存在${NC}"
    fi
else
    echo -e "${RED}❌ 数据库初始化失败${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}📋 步骤 3: 重启后端服务${NC}"

# 重启 PM2 服务
if command -v pm2 &> /dev/null; then
    if pm2 list | grep -q "scan-code-backend"; then
        pm2 restart scan-code-backend
        echo -e "${GREEN}✓ 后端服务已重启${NC}"
        
        # 等待服务启动
        sleep 3
        
        # 检查状态
        if pm2 list | grep "scan-code-backend" | grep -q "online"; then
            echo -e "${GREEN}✓ 后端服务运行正常${NC}"
        else
            echo -e "${RED}❌ 后端服务启动失败${NC}"
            echo "   查看日志: pm2 logs scan-code-backend"
        fi
    else
        echo -e "${YELLOW}⚠️  后端服务未在 PM2 中运行${NC}"
        echo "   启动服务:"
        echo "   cd backend"
        echo "   pm2 start npm --name \"scan-code-backend\" -- start"
        echo "   pm2 save"
    fi
else
    echo -e "${YELLOW}⚠️  PM2 未安装，请手动重启服务${NC}"
fi

echo ""
echo -e "${BLUE}📋 步骤 4: 测试登录${NC}"

# 等待服务完全启动
sleep 2

# 测试 admin 登录
echo "测试 admin 登录..."
ADMIN_LOGIN=$(curl -s -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}')

if echo "$ADMIN_LOGIN" | grep -q "token"; then
    echo -e "${GREEN}✓ admin 登录成功${NC}"
else
    echo -e "${RED}❌ admin 登录失败${NC}"
    echo "   响应: $ADMIN_LOGIN"
fi

# 测试 test 登录
echo "测试 test 登录..."
TEST_LOGIN=$(curl -s -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test123"}')

if echo "$TEST_LOGIN" | grep -q "token"; then
    echo -e "${GREEN}✓ test 登录成功${NC}"
else
    echo -e "${RED}❌ test 登录失败${NC}"
    echo "   响应: $TEST_LOGIN"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 修复完成！${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📋 默认账号：${NC}"
echo "   超级管理员:"
echo "     用户名: admin"
echo "     密码: admin123"
echo ""
echo "   客户管理员:"
echo "     用户名: test"
echo "     密码: test123"
echo ""
echo -e "${YELLOW}💾 数据库备份：${NC}"
if [ -n "$BACKUP_FILE" ]; then
    echo "   备份文件: $BACKUP_FILE"
    echo "   恢复命令: cp $BACKUP_FILE $(pwd)/db.sqlite"
fi
echo ""
echo -e "${YELLOW}💡 提示：${NC}"
echo "   - 请在生产环境中修改默认密码"
echo "   - 如需恢复旧数据，使用上面的恢复命令"
echo "   - 查看服务日志: pm2 logs scan-code-backend"
echo ""
