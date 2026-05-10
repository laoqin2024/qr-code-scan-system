#!/bin/bash

# 登录问题诊断脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 登录问题诊断脚本${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检查当前目录
if [ ! -f "package.json" ] || [ ! -d "backend" ]; then
    echo -e "${RED}❌ 错误：请在项目根目录运行此脚本${NC}"
    echo "   cd /opt/scan-code"
    echo "   bash scripts/diagnose-login.sh"
    exit 1
fi

echo -e "${BLUE}📋 步骤 1: 检查数据库文件${NC}"
echo ""

# 检查数据库文件是否存在
if [ ! -f "db.sqlite" ]; then
    echo -e "${RED}❌ db.sqlite 不存在${NC}"
    echo ""
    if [ -f "db.sqlite.init" ]; then
        echo -e "${YELLOW}💡 解决方案：${NC}"
        echo "   cp db.sqlite.init db.sqlite"
        echo "   pm2 restart scan-code-backend"
    else
        echo -e "${RED}❌ db.sqlite.init 也不存在${NC}"
        echo -e "${YELLOW}💡 解决方案：${NC}"
        echo "   cd backend"
        echo "   npm run init-db"
    fi
    exit 1
else
    echo -e "${GREEN}✓ db.sqlite 存在${NC}"
    echo "  大小: $(du -h db.sqlite | cut -f1)"
fi

if [ -f "db.sqlite.init" ]; then
    echo -e "${GREEN}✓ db.sqlite.init 存在${NC}"
    echo "  大小: $(du -h db.sqlite.init | cut -f1)"
else
    echo -e "${YELLOW}⚠️  db.sqlite.init 不存在${NC}"
fi

echo ""
echo -e "${BLUE}📋 步骤 2: 检查数据库完整性${NC}"
echo ""

# 检查数据库完整性
if sqlite3 db.sqlite "PRAGMA integrity_check;" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 数据库完整性检查通过${NC}"
else
    echo -e "${RED}❌ 数据库已损坏${NC}"
    echo ""
    echo -e "${YELLOW}💡 解决方案：${NC}"
    echo "   rm db.sqlite"
    echo "   cp db.sqlite.init db.sqlite"
    echo "   pm2 restart scan-code-backend"
    exit 1
fi

echo ""
echo -e "${BLUE}📋 步骤 3: 检查用户表${NC}"
echo ""

# 检查用户表是否存在
if sqlite3 db.sqlite "SELECT name FROM sqlite_master WHERE type='table' AND name='users';" | grep -q "users"; then
    echo -e "${GREEN}✓ users 表存在${NC}"
else
    echo -e "${RED}❌ users 表不存在${NC}"
    echo ""
    echo -e "${YELLOW}💡 解决方案：数据库未初始化${NC}"
    echo "   rm db.sqlite"
    echo "   cp db.sqlite.init db.sqlite"
    echo "   pm2 restart scan-code-backend"
    exit 1
fi

echo ""
echo -e "${BLUE}📋 步骤 4: 检查 admin 和 test 账号${NC}"
echo ""

# 检查 admin 账号
ADMIN_EXISTS=$(sqlite3 db.sqlite "SELECT COUNT(*) FROM users WHERE username='admin';" 2>/dev/null)
if [ "$ADMIN_EXISTS" = "1" ]; then
    echo -e "${GREEN}✓ admin 账号存在${NC}"
    ADMIN_INFO=$(sqlite3 db.sqlite "SELECT id, username, role, is_active FROM users WHERE username='admin';")
    echo "  信息: $ADMIN_INFO"
    
    # 检查是否激活
    ADMIN_ACTIVE=$(sqlite3 db.sqlite "SELECT is_active FROM users WHERE username='admin';")
    if [ "$ADMIN_ACTIVE" = "1" ]; then
        echo -e "${GREEN}  ✓ 账号已激活${NC}"
    else
        echo -e "${RED}  ❌ 账号已禁用${NC}"
        echo ""
        echo -e "${YELLOW}💡 解决方案：${NC}"
        echo "   sqlite3 db.sqlite \"UPDATE users SET is_active=1 WHERE username='admin';\""
    fi
else
    echo -e "${RED}❌ admin 账号不存在${NC}"
    echo ""
    echo -e "${YELLOW}💡 解决方案：${NC}"
    echo "   rm db.sqlite"
    echo "   cp db.sqlite.init db.sqlite"
    echo "   pm2 restart scan-code-backend"
fi

# 检查 test 账号
TEST_EXISTS=$(sqlite3 db.sqlite "SELECT COUNT(*) FROM users WHERE username='test';" 2>/dev/null)
if [ "$TEST_EXISTS" = "1" ]; then
    echo -e "${GREEN}✓ test 账号存在${NC}"
    TEST_INFO=$(sqlite3 db.sqlite "SELECT id, username, role, is_active FROM users WHERE username='test';")
    echo "  信息: $TEST_INFO"
    
    # 检查是否激活
    TEST_ACTIVE=$(sqlite3 db.sqlite "SELECT is_active FROM users WHERE username='test';")
    if [ "$TEST_ACTIVE" = "1" ]; then
        echo -e "${GREEN}  ✓ 账号已激活${NC}"
    else
        echo -e "${RED}  ❌ 账号已禁用${NC}"
        echo ""
        echo -e "${YELLOW}💡 解决方案：${NC}"
        echo "   sqlite3 db.sqlite \"UPDATE users SET is_active=1 WHERE username='test';\""
    fi
else
    echo -e "${RED}❌ test 账号不存在${NC}"
    echo ""
    echo -e "${YELLOW}💡 解决方案：${NC}"
    echo "   rm db.sqlite"
    echo "   cp db.sqlite.init db.sqlite"
    echo "   pm2 restart scan-code-backend"
fi

echo ""
echo -e "${BLUE}📋 步骤 5: 测试密码哈希${NC}"
echo ""

# 获取 admin 密码哈希
ADMIN_HASH=$(sqlite3 db.sqlite "SELECT password_hash FROM users WHERE username='admin';" 2>/dev/null)
if [ -n "$ADMIN_HASH" ]; then
    echo "admin 密码哈希: ${ADMIN_HASH:0:20}..."
    
    # 测试密码
    cd backend
    ADMIN_PASSWORD_TEST=$(node -e "const bcrypt = require('bcryptjs'); bcrypt.compare('admin123', '$ADMIN_HASH').then(r => console.log(r));" 2>/dev/null)
    cd ..
    
    if [ "$ADMIN_PASSWORD_TEST" = "true" ]; then
        echo -e "${GREEN}✓ admin 密码 'admin123' 验证通过${NC}"
    else
        echo -e "${RED}❌ admin 密码 'admin123' 验证失败${NC}"
        echo ""
        echo -e "${YELLOW}💡 解决方案：密码可能被修改了${NC}"
        echo "   rm db.sqlite"
        echo "   cp db.sqlite.init db.sqlite"
        echo "   pm2 restart scan-code-backend"
    fi
fi

# 获取 test 密码哈希
TEST_HASH=$(sqlite3 db.sqlite "SELECT password_hash FROM users WHERE username='test';" 2>/dev/null)
if [ -n "$TEST_HASH" ]; then
    echo "test 密码哈希: ${TEST_HASH:0:20}..."
    
    # 测试密码
    cd backend
    TEST_PASSWORD_TEST=$(node -e "const bcrypt = require('bcryptjs'); bcrypt.compare('test123', '$TEST_HASH').then(r => console.log(r));" 2>/dev/null)
    cd ..
    
    if [ "$TEST_PASSWORD_TEST" = "true" ]; then
        echo -e "${GREEN}✓ test 密码 'test123' 验证通过${NC}"
    else
        echo -e "${RED}❌ test 密码 'test123' 验证失败${NC}"
        echo ""
        echo -e "${YELLOW}💡 解决方案：密码可能被修改了${NC}"
        echo "   rm db.sqlite"
        echo "   cp db.sqlite.init db.sqlite"
        echo "   pm2 restart scan-code-backend"
    fi
fi

echo ""
echo -e "${BLUE}📋 步骤 6: 检查后端服务${NC}"
echo ""

# 检查 PM2 服务
if command -v pm2 &> /dev/null; then
    if pm2 list | grep -q "scan-code-backend"; then
        PM2_STATUS=$(pm2 list | grep "scan-code-backend" | awk '{print $10}')
        if echo "$PM2_STATUS" | grep -q "online"; then
            echo -e "${GREEN}✓ 后端服务运行中${NC}"
        else
            echo -e "${RED}❌ 后端服务状态异常: $PM2_STATUS${NC}"
            echo ""
            echo -e "${YELLOW}💡 解决方案：${NC}"
            echo "   pm2 restart scan-code-backend"
            echo "   pm2 logs scan-code-backend"
        fi
    else
        echo -e "${RED}❌ 后端服务未启动${NC}"
        echo ""
        echo -e "${YELLOW}💡 解决方案：${NC}"
        echo "   cd backend"
        echo "   pm2 start npm --name \"scan-code-backend\" -- start"
        echo "   pm2 save"
    fi
else
    echo -e "${YELLOW}⚠️  PM2 未安装${NC}"
fi

# 检查端口
if netstat -tlnp 2>/dev/null | grep -q ":3001"; then
    echo -e "${GREEN}✓ 端口 3001 正在监听${NC}"
else
    echo -e "${RED}❌ 端口 3001 未监听${NC}"
    echo ""
    echo -e "${YELLOW}💡 解决方案：${NC}"
    echo "   pm2 restart scan-code-backend"
    echo "   pm2 logs scan-code-backend"
fi

echo ""
echo -e "${BLUE}📋 步骤 7: 测试登录 API${NC}"
echo ""

# 测试登录 API
echo "测试 admin 登录..."
ADMIN_LOGIN_RESULT=$(curl -s -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' 2>/dev/null)

if echo "$ADMIN_LOGIN_RESULT" | grep -q "token"; then
    echo -e "${GREEN}✓ admin 登录成功${NC}"
else
    echo -e "${RED}❌ admin 登录失败${NC}"
    echo "  响应: $ADMIN_LOGIN_RESULT"
fi

echo ""
echo "测试 test 登录..."
TEST_LOGIN_RESULT=$(curl -s -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test123"}' 2>/dev/null)

if echo "$TEST_LOGIN_RESULT" | grep -q "token"; then
    echo -e "${GREEN}✓ test 登录成功${NC}"
else
    echo -e "${RED}❌ test 登录失败${NC}"
    echo "  响应: $TEST_LOGIN_RESULT"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 诊断完成${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}💡 如果所有检查都通过但仍无法登录，请检查：${NC}"
echo "   1. 浏览器控制台是否有错误"
echo "   2. 网络请求是否正确发送到后端"
echo "   3. 后端日志: pm2 logs scan-code-backend"
echo "   4. Nginx 配置是否正确"
echo ""
