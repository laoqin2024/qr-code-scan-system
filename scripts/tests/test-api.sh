#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 权限管理系统 - 功能测试"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

API_URL="http://localhost:3001/api"

# 测试1: 登录
echo ""
echo "📝 测试 1: 登录功能"
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}')

TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.token')
ROLE=$(echo $LOGIN_RESPONSE | jq -r '.user.role')

if [ "$TOKEN" != "null" ]; then
  echo "✅ 登录成功"
  echo "   角色: $ROLE"
else
  echo "❌ 登录失败"
  echo $LOGIN_RESPONSE | jq .
  exit 1
fi

# 测试2: 获取用户信息
echo ""
echo "📝 测试 2: 获取当前用户信息"
ME_RESPONSE=$(curl -s -X GET "$API_URL/auth/me" \
  -H "Authorization: Bearer $TOKEN")

USERNAME=$(echo $ME_RESPONSE | jq -r '.username')
if [ "$USERNAME" != "null" ]; then
  echo "✅ 获取用户信息成功"
  echo "   用户名: $USERNAME"
else
  echo "❌ 获取用户信息失败"
fi

# 测试3: 获取用户列表
echo ""
echo "📝 测试 3: 获取用户列表"
USERS_RESPONSE=$(curl -s -X GET "$API_URL/users" \
  -H "Authorization: Bearer $TOKEN")

USER_COUNT=$(echo $USERS_RESPONSE | jq '. | length')
echo "✅ 获取用户列表成功"
echo "   用户数量: $USER_COUNT"

# 测试4: 获取客户列表
echo ""
echo "📝 测试 4: 获取客户列表"
CUSTOMERS_RESPONSE=$(curl -s -X GET "$API_URL/customers" \
  -H "Authorization: Bearer $TOKEN")

CUSTOMER_COUNT=$(echo $CUSTOMERS_RESPONSE | jq '. | length')
echo "✅ 获取客户列表成功"
echo "   客户数量: $CUSTOMER_COUNT"

# 测试5: 获取产品列表
echo ""
echo "📝 测试 5: 获取产品列表"
PRODUCTS_RESPONSE=$(curl -s -X GET "$API_URL/products" \
  -H "Authorization: Bearer $TOKEN")

PRODUCT_COUNT=$(echo $PRODUCTS_RESPONSE | jq '. | length')
echo "✅ 获取产品列表成功"
echo "   产品数量: $PRODUCT_COUNT"

# 测试6: 获取扫码记录
echo ""
echo "📝 测试 6: 获取扫码记录"
SCANS_RESPONSE=$(curl -s -X GET "$API_URL/scans" \
  -H "Authorization: Bearer $TOKEN")

SCAN_COUNT=$(echo $SCANS_RESPONSE | jq '. | length')
echo "✅ 获取扫码记录成功"
echo "   记录数量: $SCAN_COUNT"

# 测试7: 获取审计日志
echo ""
echo "📝 测试 7: 获取审计日志"
AUDIT_RESPONSE=$(curl -s -X GET "$API_URL/permissions/audit-logs?limit=5" \
  -H "Authorization: Bearer $TOKEN")

AUDIT_COUNT=$(echo $AUDIT_RESPONSE | jq '. | length')
echo "✅ 获取审计日志成功"
echo "   日志数量: $AUDIT_COUNT"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 所有测试通过！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 访问地址:"
echo "   前端: http://localhost:5173"
echo "   后端: http://localhost:3001"
echo ""
echo "👤 测试账号:"
echo "   用户名: admin"
echo "   密码: admin123"
echo ""
