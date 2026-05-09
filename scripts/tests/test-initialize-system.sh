#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 测试初始化系统功能"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

API_URL="http://localhost:3001/api"

# 1. 登录 admin
echo ""
echo "📝 步骤 1: 登录 admin"
ADMIN_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}')
ADMIN_TOKEN=$(echo $ADMIN_LOGIN | jq -r '.token')
ADMIN_ID=$(echo $ADMIN_LOGIN | jq -r '.user.id')
echo "✅ admin 登录成功 (ID: $ADMIN_ID)"

# 2. 查看当前数据统计
echo ""
echo "📝 步骤 2: 查看当前数据统计"

CUSTOMERS=$(curl -s -X GET "$API_URL/customers" -H "Authorization: Bearer $ADMIN_TOKEN")
CUSTOMER_COUNT=$(echo $CUSTOMERS | jq '. | length')
echo "客户数量: $CUSTOMER_COUNT"

PRODUCTS=$(curl -s -X GET "$API_URL/products" -H "Authorization: Bearer $ADMIN_TOKEN")
PRODUCT_COUNT=$(echo $PRODUCTS | jq '. | length')
echo "产品数量: $PRODUCT_COUNT"

USERS=$(curl -s -X GET "$API_URL/users" -H "Authorization: Bearer $ADMIN_TOKEN")
USER_COUNT=$(echo $USERS | jq '. | length')
NON_ADMIN_COUNT=$(echo $USERS | jq '[.[] | select(.id != 1)] | length')
echo "用户数量: $USER_COUNT (其中非 admin: $NON_ADMIN_COUNT)"

SCANS=$(curl -s -X GET "$API_URL/scans" -H "Authorization: Bearer $ADMIN_TOKEN")
SCAN_COUNT=$(echo $SCANS | jq '. | length')
echo "扫码记录: $SCAN_COUNT"

# 3. 执行初始化系统
echo ""
echo "📝 步骤 3: 执行初始化系统"
echo "⚠️  这将删除所有数据（除了 admin 账号）"

INIT_RESULT=$(curl -s -X POST "$API_URL/scans/initialize-system" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

if echo $INIT_RESULT | jq -e '.message' > /dev/null; then
  echo "✅ 初始化成功"
  echo ""
  echo "删除统计:"
  echo "  客户: $(echo $INIT_RESULT | jq -r '.deleted_customers')"
  echo "  产品: $(echo $INIT_RESULT | jq -r '.deleted_products')"
  echo "  用户: $(echo $INIT_RESULT | jq -r '.deleted_users')"
  echo "  扫码记录: $(echo $INIT_RESULT | jq -r '.deleted_scans')"
  echo "  权限记录: $(echo $INIT_RESULT | jq -r '.deleted_permissions')"
  echo "  审计日志: $(echo $INIT_RESULT | jq -r '.deleted_audit_logs')"
else
  echo "❌ 初始化失败: $(echo $INIT_RESULT | jq -r '.error')"
  exit 1
fi

# 4. 验证数据已清空
echo ""
echo "📝 步骤 4: 验证数据已清空"

CUSTOMERS_AFTER=$(curl -s -X GET "$API_URL/customers" -H "Authorization: Bearer $ADMIN_TOKEN")
CUSTOMER_COUNT_AFTER=$(echo $CUSTOMERS_AFTER | jq '. | length')
echo "客户数量: $CUSTOMER_COUNT_AFTER"

PRODUCTS_AFTER=$(curl -s -X GET "$API_URL/products" -H "Authorization: Bearer $ADMIN_TOKEN")
PRODUCT_COUNT_AFTER=$(echo $PRODUCTS_AFTER | jq '. | length')
echo "产品数量: $PRODUCT_COUNT_AFTER"

USERS_AFTER=$(curl -s -X GET "$API_URL/users" -H "Authorization: Bearer $ADMIN_TOKEN")
USER_COUNT_AFTER=$(echo $USERS_AFTER | jq '. | length')
echo "用户数量: $USER_COUNT_AFTER"

SCANS_AFTER=$(curl -s -X GET "$API_URL/scans" -H "Authorization: Bearer $ADMIN_TOKEN")
SCAN_COUNT_AFTER=$(echo $SCANS_AFTER | jq '. | length')
echo "扫码记录: $SCAN_COUNT_AFTER"

# 5. 验证 admin 账号仍然存在
echo ""
echo "📝 步骤 5: 验证 admin 账号仍然存在"
ADMIN_USER=$(echo $USERS_AFTER | jq '.[] | select(.username == "admin")')

if [ "$ADMIN_USER" != "" ]; then
  echo "✅ admin 账号仍然存在"
  echo "   ID: $(echo $ADMIN_USER | jq -r '.id')"
  echo "   用户名: $(echo $ADMIN_USER | jq -r '.username')"
  echo "   角色: $(echo $ADMIN_USER | jq -r '.role')"
  echo "   状态: $(echo $ADMIN_USER | jq -r '.is_active')"
else
  echo "❌ admin 账号被删除了！"
  exit 1
fi

# 6. 测试 admin 是否可以登录
echo ""
echo "📝 步骤 6: 测试 admin 是否可以登录"
ADMIN_LOGIN_TEST=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}')
ADMIN_TOKEN_TEST=$(echo $ADMIN_LOGIN_TEST | jq -r '.token')

if [ "$ADMIN_TOKEN_TEST" != "null" ] && [ "$ADMIN_TOKEN_TEST" != "" ]; then
  echo "✅ admin 可以正常登录"
else
  echo "❌ admin 无法登录"
  exit 1
fi

# 7. 测试创建新数据
echo ""
echo "📝 步骤 7: 测试创建新数据"

# 创建客户
NEW_CUSTOMER=$(curl -s -X POST "$API_URL/customers" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"测试客户","expected_length":20,"description":"初始化后的测试"}')
NEW_CUSTOMER_ID=$(echo $NEW_CUSTOMER | jq -r '.id')

if [ "$NEW_CUSTOMER_ID" != "null" ] && [ "$NEW_CUSTOMER_ID" != "" ]; then
  echo "✅ 可以创建新客户 (ID: $NEW_CUSTOMER_ID)"
else
  echo "❌ 无法创建新客户"
fi

# 创建产品
NEW_PRODUCT=$(curl -s -X POST "$API_URL/products" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"测试产品\",\"customer_id\":$NEW_CUSTOMER_ID,\"description\":\"初始化后的测试\"}")
NEW_PRODUCT_ID=$(echo $NEW_PRODUCT | jq -r '.id')

if [ "$NEW_PRODUCT_ID" != "null" ] && [ "$NEW_PRODUCT_ID" != "" ]; then
  echo "✅ 可以创建新产品 (ID: $NEW_PRODUCT_ID)"
else
  echo "❌ 无法创建新产品"
fi

# 创建用户
NEW_USER=$(curl -s -X POST "$API_URL/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username":"test_after_init","password":"test123","display_name":"初始化后测试","role":"operator"}')
NEW_USER_ID=$(echo $NEW_USER | jq -r '.id')

if [ "$NEW_USER_ID" != "null" ] && [ "$NEW_USER_ID" != "" ]; then
  echo "✅ 可以创建新用户 (ID: $NEW_USER_ID)"
else
  echo "❌ 无法创建新用户"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 测试完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 测试结果总结:"

if [ "$CUSTOMER_COUNT_AFTER" -eq 0 ]; then
  echo "   ✅ 所有客户已清空"
else
  echo "   ❌ 还有 $CUSTOMER_COUNT_AFTER 个客户未清空"
fi

if [ "$PRODUCT_COUNT_AFTER" -eq 0 ]; then
  echo "   ✅ 所有产品已清空"
else
  echo "   ❌ 还有 $PRODUCT_COUNT_AFTER 个产品未清空"
fi

if [ "$USER_COUNT_AFTER" -eq 1 ]; then
  echo "   ✅ 只保留了 admin 账号"
else
  echo "   ❌ 用户数量不正确: $USER_COUNT_AFTER (应该是 1)"
fi

if [ "$SCAN_COUNT_AFTER" -eq 0 ]; then
  echo "   ✅ 所有扫码记录已清空"
else
  echo "   ❌ 还有 $SCAN_COUNT_AFTER 条扫码记录未清空"
fi

if [ "$ADMIN_USER" != "" ]; then
  echo "   ✅ admin 账号保留正常"
else
  echo "   ❌ admin 账号被误删"
fi

if [ "$ADMIN_TOKEN_TEST" != "null" ] && [ "$ADMIN_TOKEN_TEST" != "" ]; then
  echo "   ✅ admin 可以正常登录"
else
  echo "   ❌ admin 无法登录"
fi

if [ "$NEW_CUSTOMER_ID" != "null" ] && [ "$NEW_PRODUCT_ID" != "null" ] && [ "$NEW_USER_ID" != "null" ]; then
  echo "   ✅ 系统功能正常，可以创建新数据"
else
  echo "   ❌ 系统功能异常"
fi

echo ""
echo "🎯 功能说明:"
echo "   • 初始化系统会删除所有数据"
echo "   • 只保留超级管理员账号（ID=1）"
echo "   • admin 账号状态会被重置（is_active=1, customer_id=NULL）"
echo "   • 使用事务确保数据一致性"
echo "   • 初始化后系统可以正常使用"
echo ""
