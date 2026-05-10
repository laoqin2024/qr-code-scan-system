#!/bin/bash

# 后端服务诊断脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 后端服务诊断脚本${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检查当前目录
if [ ! -f "package.json" ] || [ ! -d "backend" ]; then
    echo -e "${RED}❌ 错误：请在项目根目录运行此脚本${NC}"
    echo "   cd /opt/scan-code"
    echo "   bash scripts/diagnose-backend.sh"
    exit 1
fi

echo -e "${BLUE}📋 步骤 1: 检查 PM2 服务状态${NC}"
echo ""

if ! command -v pm2 &> /dev/null; then
    echo -e "${RED}❌ PM2 未安装${NC}"
    echo ""
    echo -e "${YELLOW}💡 解决方案：${NC}"
    echo "   npm install -g pm2"
    exit 1
fi

# 显示 PM2 列表
pm2 list

echo ""
echo -e "${BLUE}📋 步骤 2: 查看错误日志（最近 50 行）${NC}"
echo ""

pm2 logs scan-code-backend --lines 50 --nostream

echo ""
echo -e "${BLUE}📋 步骤 3: 检查环境配置${NC}"
echo ""

# 检查 .env 文件
if [ -f "backend/.env" ]; then
    echo -e "${GREEN}✓ backend/.env 存在${NC}"
    echo "  内容:"
    cat backend/.env | sed 's/JWT_SECRET=.*/JWT_SECRET=***/' | sed 's/=/ = /'
else
    echo -e "${RED}❌ backend/.env 不存在${NC}"
    echo ""
    echo -e "${YELLOW}💡 解决方案：${NC}"
    echo "   cd backend"
    echo "   cat > .env << 'EOF'"
    echo "   PORT=3001"
    echo "   JWT_SECRET=your_jwt_secret_here"
    echo "   NODE_ENV=production"
    echo "   EOF"
fi

echo ""
echo -e "${BLUE}📋 步骤 4: 检查数据库${NC}"
echo ""

if [ -f "db.sqlite" ]; then
    echo -e "${GREEN}✓ db.sqlite 存在${NC}"
    echo "  大小: $(du -h db.sqlite | cut -f1)"
    
    # 检查完整性
    if sqlite3 db.sqlite "PRAGMA integrity_check;" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ 数据库完整性检查通过${NC}"
    else
        echo -e "${RED}❌ 数据库已损坏${NC}"
    fi
else
    echo -e "${RED}❌ db.sqlite 不存在${NC}"
    echo ""
    echo -e "${YELLOW}💡 解决方案：${NC}"
    echo "   cp db.sqlite.init db.sqlite"
fi

echo ""
echo -e "${BLUE}📋 步骤 5: 检查依赖${NC}"
echo ""

if [ -d "backend/node_modules" ]; then
    echo -e "${GREEN}✓ backend/node_modules 存在${NC}"
    
    # 检查关键依赖
    MISSING_DEPS=()
    
    if [ ! -d "backend/node_modules/express" ]; then
        MISSING_DEPS+=("express")
    fi
    
    if [ ! -d "backend/node_modules/better-sqlite3" ]; then
        MISSING_DEPS+=("better-sqlite3")
    fi
    
    if [ ! -d "backend/node_modules/bcryptjs" ]; then
        MISSING_DEPS+=("bcryptjs")
    fi
    
    if [ ! -d "backend/node_modules/jsonwebtoken" ]; then
        MISSING_DEPS+=("jsonwebtoken")
    fi
    
    if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
        echo -e "${RED}❌ 缺少依赖: ${MISSING_DEPS[*]}${NC}"
        echo ""
        echo -e "${YELLOW}💡 解决方案：${NC}"
        echo "   cd backend"
        echo "   npm install"
    else
        echo -e "${GREEN}✓ 关键依赖都已安装${NC}"
    fi
else
    echo -e "${RED}❌ backend/node_modules 不存在${NC}"
    echo ""
    echo -e "${YELLOW}💡 解决方案：${NC}"
    echo "   cd backend"
    echo "   npm install"
fi

echo ""
echo -e "${BLUE}📋 步骤 6: 检查端口占用${NC}"
echo ""

if netstat -tlnp 2>/dev/null | grep -q ":3001"; then
    PORT_INFO=$(netstat -tlnp 2>/dev/null | grep ":3001")
    echo -e "${YELLOW}⚠️  端口 3001 已被占用${NC}"
    echo "  $PORT_INFO"
    echo ""
    echo -e "${YELLOW}💡 解决方案：${NC}"
    echo "   # 查看占用进程"
    echo "   lsof -i :3001"
    echo "   # 杀死进程"
    echo "   kill -9 \$(lsof -t -i:3001)"
else
    echo -e "${GREEN}✓ 端口 3001 未被占用${NC}"
fi

echo ""
echo -e "${BLUE}📋 步骤 7: 尝试直接运行后端${NC}"
echo ""

echo "尝试直接运行后端（5秒后自动停止）..."
cd backend

# 设置超时
timeout 5s npm start 2>&1 || true

cd ..

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 诊断完成${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}💡 常见问题和解决方案：${NC}"
echo ""
echo "1. 缺少 .env 文件"
echo "   cd backend && cat > .env << 'EOF'"
echo "   PORT=3001"
echo "   JWT_SECRET=your_jwt_secret_here"
echo "   NODE_ENV=production"
echo "   EOF"
echo ""
echo "2. 数据库不存在"
echo "   cp db.sqlite.init db.sqlite"
echo ""
echo "3. 依赖未安装"
echo "   cd backend && npm install"
echo ""
echo "4. 端口被占用"
echo "   kill -9 \$(lsof -t -i:3001)"
echo ""
echo "5. 数据库路径错误"
echo "   检查 backend/src/db.ts 中的数据库路径"
echo ""
echo "📋 查看完整日志："
echo "   pm2 logs scan-code-backend"
echo ""
echo "🔄 重启服务："
echo "   pm2 delete scan-code-backend"
echo "   cd backend"
echo "   pm2 start npm --name \"scan-code-backend\" -- start"
echo "   pm2 save"
echo ""
