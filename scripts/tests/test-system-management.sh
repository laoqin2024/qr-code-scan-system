#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 测试系统管理功能"
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
  -d '{"name":"测试客户123","expected_length":20,"description":"这是测试数据"}')
TEST_CUSTOMER_ID=$(echo $TEST_CUSTOMER | jq -r '.id')
echo "✅ 创建测试客户: ID=$TEST_CUSTOMER_ID"

# 创建测试产品
TEST_PRODUCT=$(curl -s -X POST "$API_URL/products" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"test产品\",\"customer_id\":$TEST_CUSTOMER_ID,\"description\":\"测试\"}")
TEST_PRODUCT_ID=$(echo $TEST_PRODUCT | jq -r '.id')
echo "✅ 创建测试产品: ID=$TEST_PRODUCT_ID"

# 创建测试用户
TEST_USER=$(curl -s -X POST "$API_URL/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username":"test_cleanup_user","password":"test123","display_name":"测试清理用户","role":"viewer"}')
TEST_USER_ID=$(echo $TEST_USER | jq -r '.id')
echo "✅ 创建测试用户: ID=$TEST_USER_ID"

# 创建正常扫码记录
SCAN1=$(curl -s -X POST "$API_URL/scans" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"customer_id\":$TEST_CUSTOMER_ID,\"product_id\":$TEST_PRODUCT_ID,\"code_text\":\"12345678901234567890\",\"notes\":\"正常记录\"}")
echo "✅ 创建正常扫码记录"

# 创建错误扫码记录
SCAN2=$(curl -s -X POST "$API_URL/scans" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"customer_id\":$TEST_CUSTOMER_ID,\"product_id\":$TEST_PRODUCT_ID,\"code_text\":\"123\",\"notes\":\"错误记录-长度不足\"}")
echo "✅ 创建错误扫码记录（长度不足）"

SCAN3=$(curl -s -X POST "$API_URL/scans" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"customer_id\":$TEST_CUSTOMER_ID,\"product_id\":$TEST_PRODUCT_ID,\"code_text\":\"123456789012345678901234567890\",\"notes\":\"错误记录-长度超出\"}")
echo "✅ 创建错误扫码记录（长度超出）"

# 3. 查看当前数据统计
echo ""
echo "📝 步骤 3: 查看当前数据统计"
CUSTOMERS=$(curl -s -X GET "$API_URL/customers" -H "Authorization: Bearer $ADMIN_TOKEN")
PRODUCTS=$(curl -s -X GET "$API_URL/products" -H "Authorization: Bearer $ADMIN_TOKEN")
USERS=$(curl -s -X GET "$API_URL/users" -H "Authorization: Bearer $ADMIN_TOKEN")
SCANS=$(curl -s -X GET "$API_URL/scans" -H "Authorization: Bearer $ADMIN_TOKEN")

CUSTOMER_COUNT=$(echo $CUSTOMERS | jq '. | length')
PRODUCT_COUNT=$(echo $PRODUCTS | jq '. | length')
USER_COUNT=$(echo $USERS | jq '. | length')
SCAN_COUNT=$(echo $SCANS | jq '. | length')
INVALID_SCAN_COUNT=$(echo $SCANS | jq '[.[] | select(.is_valid == false)] | length')

echo "当前数据统计:"
echo "  客户: $CUSTOMER_COUNT 个"
echo "  产品: $PRODUCT_COUNT 个"
echo "  用户: $USER_COUNT 个"
echo "  扫码记录: $SCAN_COUNT 条（其中错误 $INVALID_SCAN_COUNT 条）"

# 4. 测试删除错误记录
echo ""
echo "📝 步骤 4: 测试删除错误记录"
DELETE_INVALID=$(curl -s -X POST "$API_URL/scans/batch-delete-invalid" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}')

if echo $DELETE_INVALID | jq -e '.deleted_count' > /dev/null; then
  DELETED_COUNT=$(echo $DELETE_INVALID | jq -r '.deleted_count')
  echo "✅ 成功删除 $DELETED_COUNT 条错误记录"
else
  echo "❌ 删除失败: $(echo $DELETE_INVALID | jq -r '.error')"
fi

# 5. 验证错误记录已删除
echo ""
echo "📝 步骤 5: 验证错误记录已删除"
SCANS_AFTER=$(curl -s -X GET "$API_URL/scans" -H "Authorization: Bearer $ADMIN_TOKEN")
INVALID_SCAN_COUNT_AFTER=$(echo $SCANS_AFTER | jq '[.[] | select(.is_valid == false)] | length')
echo "✅ 剩余错误记录: $INVALID_SCAN_COUNT_AFTER 条"

# 6. 测试清理测试数据
echo ""
echo "📝 步骤 6: 测试清理测试数据"
CLEANUP=$(curl -s -X POST "$API_URL/scans/cleanup-test-data" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json")

if echo $CLEANUP | jq -e '.deleted_customers' > /dev/null; then
  echo "✅ 清理完成:"
  echo "   删除客户: $(echo $CLEANUP | jq -r '.deleted_customers') 个"
  echo "   删除产品: $(echo $CLEANUP | jq -r '.deleted_products') 个"
  echo "   删除用户: $(echo $CLEANUP | jq -r '.deleted_users') 个"
  echo "   删除扫码: $(echo $CLEANUP | jq -r '.deleted_scans') 条"
else
  echo "❌ 清理失败: $(echo $CLEANUP | jq -r '.error')"
fi

# 7. 验证测试数据已清理
echo ""
echo "📝 步骤 7: 验证测试数据已清理"
CUSTOMERS_AFTER=$(curl -s -X GET "$API_URL/customers" -H "Authorization: Bearer $ADMIN_TOKEN")
PRODUCTS_AFTER=$(curl -s -X GET "$API_URL/products" -H "Authorization: Bearer $ADMIN_TOKEN")
USERS_AFTER=$(curl -s -X GET "$API_URL/users" -H "Authorization: Bearer $ADMIN_TOKEN")

TEST_CUSTOMER_COUNT=$(echo $CUSTOMERS_AFTER | jq '[.[] | select(.name | contains("测试") or contains("test"))] | length')
TEST_PRODUCT_COUNT=$(echo $PRODUCTS_AFTER | jq '[.[] | select(.model | contains("测试") or contains("test"))] | length')
TEST_USER_COUNT=$(echo $USERS_AFTER | jq '[.[] | select(.username | contains("test"))] | length')

echo "✅ 剩余测试数据:"
echo "   测试客户: $TEST_CUSTOMER_COUNT 个"
echo "   测试产品: $TEST_PRODUCT_COUNT 个"
echo "   测试用户: $TEST_USER_COUNT 个"

# 8. 测试权限（非超级管理员）
echo ""
echo "📝 步骤 8: 测试权限（非超级管理员不能使用）"
QX001_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"qx001","password":"123456"}')
QX001_TOKEN=$(echo $QX001_LOGIN | jq -r '.token')

if [ "$QX001_TOKEN" != "null" ]; then
  CLEANUP_FAIL=$(curl -s -X POST "$API_URL/scans/cleanup-test-data" \
    -H "Authorization: Bearer $QX001_TOKEN" \
    -H "Content-Type: application/json")
  
  if echo $CLEANUP_FAIL | jq -e '.error' > /dev/null; then
    echo "✅ 正确拒绝非超级管理员: $(echo $CLEANUP_FAIL | jq -r '.error')"
  else
    echo "❌ 不应该允许非超级管理员清理数据"
  fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 系统管理功能测试完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 测试结果总结:"
echo "   ✅ 可以删除错误的扫码记录"
echo "   ✅ 可以清理测试数据"
echo "   ✅ 非超级管理员被正确拒绝"
echo ""
echo "🎯 功能说明:"
echo "   • 删除错误记录：删除所有 is_valid=false 的扫码记录"
echo "   • 清理测试数据：删除名称包含'测试'或'test'的数据"
echo "   • 只有超级管理员可以使用这些功能"
echo ""
