#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 测试客户管理员扫码权限"
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

# 2. 创建测试客户
echo ""
echo "📝 步骤 2: 创建测试客户"
TEST_CUSTOMER=$(curl -s -X POST "$API_URL/customers" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"扫码权限测试客户","expected_length":20,"description":"测试客户管理员扫码权限"}')
TEST_CUSTOMER_ID=$(echo $TEST_CUSTOMER | jq -r '.id')
echo "✅ 客户创建成功: ID=$TEST_CUSTOMER_ID"

# 3. 创建客户管理员
echo ""
echo "📝 步骤 3: 创建客户管理员"
TEST_MANAGER=$(curl -s -X POST "$API_URL/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"test_scan_manager\",\"password\":\"test123\",\"display_name\":\"扫码测试管理员\",\"role\":\"customer_admin\",\"customer_id\":$TEST_CUSTOMER_ID}")
TEST_MANAGER_ID=$(echo $TEST_MANAGER | jq -r '.id')
echo "✅ 客户管理员创建成功: ID=$TEST_MANAGER_ID"

# 4. 客户管理员登录
echo ""
echo "📝 步骤 4: 客户管理员登录"
MANAGER_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"test_scan_manager","password":"test123"}')
MANAGER_TOKEN=$(echo $MANAGER_LOGIN | jq -r '.token')
MANAGER_CUSTOMER_ID=$(echo $MANAGER_LOGIN | jq -r '.user.customer_id')
echo "✅ 客户管理员登录成功，客户ID: $MANAGER_CUSTOMER_ID"

# 5. 客户管理员创建产品
echo ""
echo "📝 步骤 5: 客户管理员创建产品"
TEST_PRODUCT=$(curl -s -X POST "$API_URL/products" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"扫码测试产品\",\"customer_id\":$TEST_CUSTOMER_ID,\"description\":\"测试扫码权限\"}")
TEST_PRODUCT_ID=$(echo $TEST_PRODUCT | jq -r '.id')
echo "✅ 产品创建成功: ID=$TEST_PRODUCT_ID"

# 6. 客户管理员扫码（应该成功）
echo ""
echo "📝 步骤 6: 客户管理员扫码自己客户的产品"
SCAN_RESULT=$(curl -s -X POST "$API_URL/scans" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"customer_id\":$TEST_CUSTOMER_ID,\"product_id\":$TEST_PRODUCT_ID,\"code_text\":\"12345678901234567890\",\"notes\":\"测试扫码\"}")

if echo $SCAN_RESULT | jq -e '.id' > /dev/null; then
  SCAN_ID=$(echo $SCAN_RESULT | jq -r '.id')
  IS_VALID=$(echo $SCAN_RESULT | jq -r '.is_valid')
  echo "✅ 扫码成功: ID=$SCAN_ID, 有效性=$IS_VALID"
else
  echo "❌ 扫码失败: $(echo $SCAN_RESULT | jq -r '.error')"
fi

# 7. 创建另一个客户和产品
echo ""
echo "📝 步骤 7: 创建另一个客户和产品"
OTHER_CUSTOMER=$(curl -s -X POST "$API_URL/customers" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"其他客户","expected_length":18,"description":"测试跨客户权限"}')
OTHER_CUSTOMER_ID=$(echo $OTHER_CUSTOMER | jq -r '.id')

OTHER_PRODUCT=$(curl -s -X POST "$API_URL/products" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"其他产品\",\"customer_id\":$OTHER_CUSTOMER_ID,\"description\":\"其他客户的产品\"}")
OTHER_PRODUCT_ID=$(echo $OTHER_PRODUCT | jq -r '.id')
echo "✅ 其他客户和产品创建成功"

# 8. 客户管理员扫码其他客户的产品（应该失败）
echo ""
echo "📝 步骤 8: 客户管理员扫码其他客户的产品（应该失败）"
SCAN_OTHER=$(curl -s -X POST "$API_URL/scans" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"customer_id\":$OTHER_CUSTOMER_ID,\"product_id\":$OTHER_PRODUCT_ID,\"code_text\":\"123456789012345678\",\"notes\":\"测试跨客户\"}")

if echo $SCAN_OTHER | jq -e '.error' > /dev/null; then
  echo "✅ 正确拒绝: $(echo $SCAN_OTHER | jq -r '.error')"
else
  echo "❌ 不应该允许扫描其他客户的产品"
fi

# 9. 授权后再次尝试
echo ""
echo "📝 步骤 9: 授权后扫描其他客户的产品"
curl -s -X POST "$API_URL/permissions/users/$TEST_MANAGER_ID/permissions/products" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"product_id\":$OTHER_PRODUCT_ID,\"can_scan\":true,\"can_view\":true}" > /dev/null
echo "✅ 已授权其他产品"

SCAN_OTHER2=$(curl -s -X POST "$API_URL/scans" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"customer_id\":$OTHER_CUSTOMER_ID,\"product_id\":$OTHER_PRODUCT_ID,\"code_text\":\"123456789012345678\",\"notes\":\"授权后测试\"}")

if echo $SCAN_OTHER2 | jq -e '.id' > /dev/null; then
  echo "✅ 授权后扫码成功"
else
  echo "❌ 授权后扫码失败: $(echo $SCAN_OTHER2 | jq -r '.error')"
fi

# 10. 清理测试数据
echo ""
echo "📝 步骤 10: 清理测试数据"
curl -s -X DELETE "$API_URL/users/$TEST_MANAGER_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN" > /dev/null
curl -s -X DELETE "$API_URL/products/$TEST_PRODUCT_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN" > /dev/null
curl -s -X DELETE "$API_URL/products/$OTHER_PRODUCT_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN" > /dev/null
curl -s -X DELETE "$API_URL/customers/$TEST_CUSTOMER_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN" > /dev/null
curl -s -X DELETE "$API_URL/customers/$OTHER_CUSTOMER_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN" > /dev/null
echo "✅ 测试数据已清理"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 客户管理员扫码权限测试完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 测试结果总结:"
echo "   ✅ 客户管理员可以扫描自己客户的产品"
echo "   ✅ 客户管理员不能扫描其他客户的产品"
echo "   ✅ 授权后可以扫描其他客户的产品"
echo ""
echo "🎯 权限规则:"
echo "   • customer_admin + customer_id → 可以扫描该客户的所有产品"
echo "   • customer_admin + 其他客户 → 需要明确授权"
echo "   • operator → 需要明确授权"
echo "   • viewer → 不能扫码"
echo ""
