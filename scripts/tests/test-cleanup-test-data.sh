#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 测试清空测试数据功能"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

API_URL="http://localhost:3001/api"

# 1. 登录 admin
echo ""
echo "📝 步骤 1: 登录 admin"
ADMIN_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}')
ADMIN_TOKEN=$(echo $ADMIN_LOGIN | jq -r '.token')
echo "✅ admin 登录成功"

# 2. 创建测试数据
echo ""
echo "📝 步骤 2: 创建测试数据"

# 创建测试客户
TEST_CUSTOMER=$(curl -s -X POST "$API_URL/customers" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"测试客户","expected_length":20,"description":"这是一个测试客户"}')
TEST_CUSTOMER_ID=$(echo $TEST_CUSTOMER | jq -r '.id')
echo "✅ 创建测试客户: ID=$TEST_CUSTOMER_ID"

# 创建测试产品
TEST_PRODUCT=$(curl -s -X POST "$API_URL/products" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"test产品\",\"customer_id\":$TEST_CUSTOMER_ID,\"description\":\"测试产品\"}")
TEST_PRODUCT_ID=$(echo $TEST_PRODUCT | jq -r '.id')
echo "✅ 创建测试产品: ID=$TEST_PRODUCT_ID"

# 创建测试用户
TEST_USER=$(curl -s -X POST "$API_URL/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username":"test_user_cleanup","password":"test123","display_name":"测试用户","role":"operator"}')
TEST_USER_ID=$(echo $TEST_USER | jq -r '.id')
echo "✅ 创建测试用户: ID=$TEST_USER_ID"

# 3. 查看创建的测试数据
echo ""
echo "📝 步骤 3: 查看创建的测试数据"

CUSTOMERS=$(curl -s -X GET "$API_URL/customers" -H "Authorization: Bearer $ADMIN_TOKEN")
TEST_CUSTOMER_COUNT=$(echo $CUSTOMERS | jq '[.[] | select(.name | contains("测试") or contains("test"))] | length')
echo "测试客户数量: $TEST_CUSTOMER_COUNT"

PRODUCTS=$(curl -s -X GET "$API_URL/products" -H "Authorization: Bearer $ADMIN_TOKEN")
TEST_PRODUCT_COUNT=$(echo $PRODUCTS | jq '[.[] | select(.model | contains("测试") or contains("test"))] | length')
echo "测试产品数量: $TEST_PRODUCT_COUNT"

USERS=$(curl -s -X GET "$API_URL/users" -H "Authorization: Bearer $ADMIN_TOKEN")
TEST_USER_COUNT=$(echo $USERS | jq '[.[] | select(.username | contains("test") or (.display_name != null and (.display_name | contains("测试"))))] | length')
echo "测试用户数量: $TEST_USER_COUNT"

# 4. 执行清空测试数据
echo ""
echo "📝 步骤 4: 执行清空测试数据"
CLEANUP_RESULT=$(curl -s -X POST "$API_URL/scans/cleanup-test-data" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

if echo $CLEANUP_RESULT | jq -e '.message' > /dev/null; then
  echo "✅ 清空成功"
  echo ""
  echo "删除统计:"
  echo "  客户: $(echo $CLEANUP_RESULT | jq -r '.deleted_customers')"
  echo "  产品: $(echo $CLEANUP_RESULT | jq -r '.deleted_products')"
  echo "  用户: $(echo $CLEANUP_RESULT | jq -r '.deleted_users')"
  echo "  扫码记录: $(echo $CLEANUP_RESULT | jq -r '.deleted_scans')"
  echo "  权限记录: $(echo $CLEANUP_RESULT | jq -r '.deleted_permissions')"
  echo "  审计日志: $(echo $CLEANUP_RESULT | jq -r '.deleted_audit_logs')"
else
  echo "❌ 清空失败: $(echo $CLEANUP_RESULT | jq -r '.error')"
  exit 1
fi

# 5. 验证测试数据已清空
echo ""
echo "📝 步骤 5: 验证测试数据已清空"

CUSTOMERS_AFTER=$(curl -s -X GET "$API_URL/customers" -H "Authorization: Bearer $ADMIN_TOKEN")
TEST_CUSTOMER_COUNT_AFTER=$(echo $CUSTOMERS_AFTER | jq '[.[] | select(.name | contains("测试") or contains("test"))] | length')
echo "测试客户数量: $TEST_CUSTOMER_COUNT_AFTER"

PRODUCTS_AFTER=$(curl -s -X GET "$API_URL/products" -H "Authorization: Bearer $ADMIN_TOKEN")
TEST_PRODUCT_COUNT_AFTER=$(echo $PRODUCTS_AFTER | jq '[.[] | select(.model | contains("测试") or contains("test"))] | length')
echo "测试产品数量: $TEST_PRODUCT_COUNT_AFTER"

USERS_AFTER=$(curl -s -X GET "$API_URL/users" -H "Authorization: Bearer $ADMIN_TOKEN")
TEST_USER_COUNT_AFTER=$(echo $USERS_AFTER | jq '[.[] | select(.username | contains("test") or (.display_name != null and (.display_name | contains("测试"))))] | length')
echo "测试用户数量: $TEST_USER_COUNT_AFTER"

# 6. 验证 admin 账号仍然存在
echo ""
echo "📝 步骤 6: 验证 admin 账号仍然存在"
ADMIN_USER=$(echo $USERS_AFTER | jq '.[] | select(.username == "admin")')
if [ "$ADMIN_USER" != "" ]; then
  echo "✅ admin 账号仍然存在"
else
  echo "❌ admin 账号被删除了！"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 测试完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 测试结果总结:"

if [ "$TEST_CUSTOMER_COUNT_AFTER" -eq 0 ]; then
  echo "   ✅ 测试客户已全部清空"
else
  echo "   ❌ 还有 $TEST_CUSTOMER_COUNT_AFTER 个测试客户未清空"
fi

if [ "$TEST_PRODUCT_COUNT_AFTER" -eq 0 ]; then
  echo "   ✅ 测试产品已全部清空"
else
  echo "   ❌ 还有 $TEST_PRODUCT_COUNT_AFTER 个测试产品未清空"
fi

if [ "$TEST_USER_COUNT_AFTER" -eq 0 ]; then
  echo "   ✅ 测试用户已全部清空"
else
  echo "   ❌ 还有 $TEST_USER_COUNT_AFTER 个测试用户未清空"
fi

if [ "$ADMIN_USER" != "" ]; then
  echo "   ✅ admin 账号保留正常"
else
  echo "   ❌ admin 账号被误删"
fi

echo ""
echo "🎯 功能说明:"
echo "   • 清空测试数据会删除所有包含"测试"或"test"的数据"
echo "   • 包括客户、产品、用户、扫码记录、权限记录和审计日志"
echo "   • admin 账号（ID=1）会被保留"
echo "   • 使用事务确保数据一致性"
echo "   • 正确处理外键约束，不会留下孤立数据"
echo ""
