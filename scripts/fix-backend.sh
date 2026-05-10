#!/bin/bash

# 修复后端服务脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔧 修复后端服务${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检查当前目录
if [ ! -f "package.json" ] || [ ! -d "backend" ]; then
    echo -e "${RED}❌ 错误：请在项目根目录运行此脚本${NC}"
    echo "   cd /opt/scan-code"
    echo "   bash scripts/fix-backend.sh"
    exit 1
fi

PROJECT_DIR=$(pwd)

echo -e "${BLUE}📋 步骤 1: 停止现有服务${NC}"
echo ""

if command -v pm2 &> /dev/null; then
    if pm2 list | grep -q "scan-code-backend"; then
        pm2 delete scan-code-backend
        echo -e "${GREEN}✓ 已停止旧服务${NC}"
    else
        echo -e "${YELLOW}⚠️  服务未在运行${NC}"
    fi
else
    echo -e "${RED}❌ PM2 未安装${NC}"
    echo "   npm install -g pm2"
    exit 1
fi

echo ""
echo -e "${BLUE}📋 步骤 2: 检查并创建 .env 文件${NC}"
echo ""

cd backend

if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env 文件不存在，创建中...${NC}"
    cat > .env << 'EOF'
PORT=3001
JWT_SECRET=your_jwt_secret_key_change_in_production
NODE_ENV=production
EOF
    echo -e "${GREEN}✓ .env 文件已创建${NC}"
else
    echo -e "${GREEN}✓ .env 文件已存在${NC}"
fi

echo "  内容:"
cat .env | sed 's/JWT_SECRET=.*/JWT_SECRET=***/'

cd "$PROJECT_DIR"

echo ""
echo -e "${BLUE}📋 步骤 3: 检查数据库${NC}"
echo ""

if [ ! -f "db.sqlite" ]; then
    echo -e "${YELLOW}⚠️  db.sqlite 不存在${NC}"
    
    if [ -f "db.sqlite.init" ]; then
        echo "  使用 db.sqlite.init 初始化..."
        cp db.sqlite.init db.sqlite
        echo -e "${GREEN}✓ 数据库已初始化${NC}"
    else
        echo -e "${RED}❌ db.sqlite.init 也不存在${NC}"
        echo "  运行初始化脚本..."
        cd backend
        npm run init-db
        cd "$PROJECT_DIR"
    fi
else
    echo -e "${GREEN}✓ db.sqlite 存在${NC}"
    
    # 检查完整性
    if sqlite3 db.sqlite "PRAGMA integrity_check;" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ 数据库完整性检查通过${NC}"
    else
        echo -e "${RED}❌ 数据库已损坏，重新初始化...${NC}"
        rm -f db.sqlite
        cp db.sqlite.init db.sqlite
    fi
fi

echo ""
echo -e "${BLUE}📋 步骤 4: 检查依赖${NC}"
echo ""

cd backend

if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}⚠️  依赖未安装，安装中...${NC}"
    npm install
    echo -e "${GREEN}✓ 依赖安装完成${NC}"
else
    echo -e "${GREEN}✓ 依赖已安装${NC}"
    
    # 检查关键依赖
    MISSING=0
    for pkg in express better-sqlite3 bcryptjs jsonwebtoken cors; do
        if [ ! -d "node_modules/$pkg" ]; then
            echo -e "${RED}  ❌ 缺少 $pkg${NC}"
            MISSING=1
        fi
    done
    
    if [ $MISSING -eq 1 ]; then
        echo ""
        echo -e "${YELLOW}重新安装依赖...${NC}"
        npm install
    fi
fi

cd "$PROJECT_DIR"

echo ""
echo -e "${BLUE}📋 步骤 5: 清理端口占用${NC}"
echo ""

if netstat -tlnp 2>/dev/null | grep -q ":3001"; then
    echo -e "${YELLOW}⚠️  端口 3001 被占用，清理中...${NC}"
    PID=$(lsof -t -i:3001 2>/dev/null)
    if [ -n "$PID" ]; then
        kill -9 $PID
        echo -e "${GREEN}✓ 已清理端口占用${NC}"
    fi
else
    echo -e "${GREEN}✓ 端口 3001 未被占用${NC}"
fi

echo ""
echo -e "${BLUE}📋 步骤 6: 测试后端启动${NC}"
echo ""

echo "测试后端是否能正常启动（5秒测试）..."
cd backend

# 使用 timeout 测试启动
timeout 5s npm start > /tmp/backend-test.log 2>&1 &
TEST_PID=$!

sleep 3

# 检查进程是否还在运行
if ps -p $TEST_PID > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 后端启动成功${NC}"
    kill $TEST_PID 2>/dev/null
    wait $TEST_PID 2>/dev/null
else
    echo -e "${RED}❌ 后端启动失败${NC}"
    echo ""
    echo "错误日志:"
    cat /tmp/backend-test.log
    echo ""
    echo -e "${YELLOW}💡 常见问题：${NC}"
    echo "1. 检查 Node.js 版本: node --version (需要 >= 18)"
    echo "2. 检查数据库路径是否正确"
    echo "3. 检查依赖是否完整安装"
    cd "$PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

echo ""
echo -e "${BLUE}📋 步骤 7: 启动 PM2 服务${NC}"
echo ""

cd backend

# 使用 PM2 启动
pm2 start npm --name "scan-code-backend" -- start

# 保存 PM2 配置
pm2 save

# 设置开机自启
pm2 startup 2>/dev/null || true

cd "$PROJECT_DIR"

echo ""
echo -e "${BLUE}📋 步骤 8: 验证服务状态${NC}"
echo ""

# 等待服务启动
sleep 3

# 检查 PM2 状态
if pm2 list | grep "scan-code-backend" | grep -q "online"; then
    echo -e "${GREEN}✓ PM2 服务运行正常${NC}"
else
    echo -e "${RED}❌ PM2 服务状态异常${NC}"
    pm2 logs scan-code-backend --lines 20 --nostream
    exit 1
fi

# 检查端口
if netstat -tlnp 2>/dev/null | grep -q ":3001"; then
    echo -e "${GREEN}✓ 端口 3001 正在监听${NC}"
else
    echo -e "${RED}❌ 端口 3001 未监听${NC}"
    exit 1
fi

# 测试 API
sleep 2
HEALTH_CHECK=$(curl -s http://localhost:3001/api/health 2>/dev/null)
if [ -n "$HEALTH_CHECK" ]; then
    echo -e "${GREEN}✓ API 响应正常${NC}"
    echo "  响应: $HEALTH_CHECK"
else
    echo -e "${YELLOW}⚠️  API 未响应（可能还在启动中）${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 后端服务修复完成！${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📋 服务信息：${NC}"
echo "  项目目录: $PROJECT_DIR"
echo "  后端端口: 3001"
echo "  数据库: $PROJECT_DIR/db.sqlite"
echo ""
echo -e "${YELLOW}🔧 常用命令：${NC}"
echo "  查看状态: pm2 list"
echo "  查看日志: pm2 logs scan-code-backend"
echo "  重启服务: pm2 restart scan-code-backend"
echo "  停止服务: pm2 stop scan-code-backend"
echo ""
echo -e "${YELLOW}🧪 测试登录：${NC}"
echo "  curl -X POST http://localhost:3001/api/auth/login \\"
echo "    -H \"Content-Type: application/json\" \\"
echo "    -d '{\"username\":\"admin\",\"password\":\"admin123\"}'"
echo ""
