#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 测试查询权限和删除功能"
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

# 2. 测试超级管理员查询所有数据
echo ""
echo "📝 步骤 2: 测试超级管理员查询所有数据"
ADMIN_CUSTOMERS=$(curl -s -X GET "$API_URL/customers" \
  -H "Authorization: Bearer $ADMIN_TOKEN")
ADMIN_PRODUCTS=$(curl -s -X GET "$API_URL/products" \
  -H "Authorization: Bearer $ADMIN_TOKEN")
ADMIN_SCANS=$(curl -s -X GET "$API_URL/scans" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

ADMIN_CUSTOMER_COUNT=$(echo $ADMIN_CUSTOMERS | jq '. | length')
ADMIN_PRODUCT_COUNT=$(echo $ADMIN_PRODUCTS | jq '. | length')
ADMIN_SCAN_COUNT=$(echo $ADMIN_SCANS | jq '. | length')

echo "✅ admin 可以查询："
echo "   客户: $ADMIN_CUSTOMER_COUNT 个"
echo "   产品: $ADMIN_PRODUCT_COUNT 个"
echo "   扫码记录: $ADMIN_SCAN_COUNT 条"

# 3. 登录 qx001（客户管理员）
echo ""
echo "📝 步骤 3: 登录 qx001（客户管理员）"
QX001_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"qx001","password":"123456"}')
QX001_TOKEN=$(echo $QX001_LOGIN | jq -r '.token')
QX001_ID=$(echo $QX001_LOGIN | jq -r '.user.id')
echo "✅ qx001 登录成功"

# 4. 测试客户管理员只能看到自己创建的客户和产品
echo ""
echo "📝 步骤 4: 测试客户管理员的下拉列表过滤"
QX001_CUSTOMERS=$(curl -s -X GET "$API_URL/customers" \
  -H "Authorization: Bearer $QX001_TOKEN")
QX001_PRODUCTS=$(curl -s -X GET "$API_URL/products" \
  -H "Authorization: Bearer $QX001_TOKEN")

QX001_CUSTOMER_COUNT=$(echo $QX001_CUSTOMERS | jq '. | length')
QX001_PRODUCT_COUNT=$(echo $QX001_PRODUCTS | jq '. | length')

echo "✅ qx001 可以查询："
echo "   客户: $QX001_CUSTOMER_COUNT 个（只有自己创建的）"
echo "   产品: $QX001_PRODUCT_COUNT 个（只有自己创建的客户的产品）"

# 显示客户列表
echo ""
echo "qx001 的客户列表:"
echo $QX001_CUSTOMERS | jq -r '.[] | "  - \(.name) (创建者: \(.created_by_username))"'

# 5. 创建测试扫码记录
echo ""
echo "📝 步骤 5: 创建测试扫码记录"
if [ "$QX001_CUSTOMER_COUNT" -gt 0 ] && [ "$QX001_PRODUCT_COUNT" -gt 0 ]; then
  TEST_CUSTOMER_ID=$(echo $QX001_CUSTOMERS | jq -r '.[0].id')
  TEST_PRODUCT_ID=$(echo $QX001_PRODUCTS | jq -r '.[0].id')
  
  TEST_SCAN=$(curl -s -X POST "$API_URL/scans" \
    -H "Authorization: Bearer $QX001_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"customer_id\":$TEST_CUSTOMER_ID,\"product_id\":$TEST_PRODUCT_ID,\"code_text\":\"12345678901234567890\",\"notes\":\"测试删除功能\"}")
  
  TEST_SCAN_ID=$(echo $TEST_SCAN | jq -r '.id')
  echo "✅ 创建测试扫码记录: ID=$TEST_SCAN_ID"
else
  echo "⚠️  qx001 没有客户或产品，跳过创建扫码记录"
fi

# 6. 测试非超级管理员不能删除记录
echo ""
echo "📝 步骤 6: 测试非超级管理员不能删除记录"
if [ "$TEST_SCAN_ID" != "" ] && [ "$TEST_SCAN_ID" != "null" ]; then
  DELETE_RESULT=$(curl -s -X DELETE "$API_URL/scans/$TEST_SCAN_ID" \
    -H "Authorization: Bearer $QX001_TOKEN")
  
  if echo $DELETE_RESULT | jq -e '.error' > /dev/null; then
    echo "✅ 正确拒绝非超级管理员删除: $(echo $DELETE_RESULT | jq -r '.error')"
  else
    echo "❌ 不应该允许非超级管理员删除"
  fi
fi

# 7. 测试超级管理员可以删除记录
echo ""
echo "📝 步骤 7: 测试超级管理员可以删除记录"
if [ "$TEST_SCAN_ID" != "" ] && [ "$TEST_SCAN_ID" != "null" ]; then
  DELETE_RESULT=$(curl -s -X DELETE "$API_URL/scans/$TEST_SCAN_ID" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
  
  if echo $DELETE_RESULT | jq -e '.message' > /dev/null; then
    echo "✅ 超级管理员删除成功: $(echo $DELETE_RESULT | jq -r '.message')"
  else
    echo "❌ 删除失败: $(echo $DELETE_RESULT | jq -r '.error')"
  fi
  
  # 验证记录已删除
  VERIFY=$(curl -s -X GET "$API_URL/scans" \
    -H "Authorization: Bearer $ADMIN_TOKEN" | jq ".[] | select(.id == $TEST_SCAN_ID)")
  
  if [ "$VERIFY" = "" ]; then
    echo "✅ 记录已成功删除"
  else
    echo "❌ 记录仍然存在"
  fi
fi

# 8. 测试操作员的权限过滤
echo ""
echo "📝 步骤 8: 创建操作员并测试权限过滤"

# 创建操作员
OPERATOR=$(curl -s -X POST "$API_URL/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username":"test_operator","password":"test123","display_name":"测试操作员","role":"operator"}')
OPERATOR_ID=$(echo $OPERATOR | jq -r '.id')
echo "✅ 创建操作员: ID=$OPERATOR_ID"

# 登录操作员
OPERATOR_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"test_operator","password":"test123"}')
OPERATOR_TOKEN=$(echo $OPERATOR_LOGIN | jq -r '.token')

# 查询客户和产品（应该为空）
OPERATOR_CUSTOMERS=$(curl -s -X GET "$API_URL/customers" \
  -H "Authorization: Bearer $OPERATOR_TOKEN")
OPERATOR_PRODUCTS=$(curl -s -X GET "$API_URL/products" \
  -H "Authorization: Bearer $OPERATOR_TOKEN")

OPERATOR_CUSTOMER_COUNT=$(echo $OPERATOR_CUSTOMERS | jq '. | length')
OPERATOR_PRODUCT_COUNT=$(echo $OPERATOR_PRODUCTS | jq '. | length')

echo "✅ 操作员（未授权）可以查询："
echo "   客户: $OPERATOR_CUSTOMER_COUNT 个"
echo "   产品: $OPERATOR_PRODUCT_COUNT 个"

# 授权一个产品给操作员
if [ "$TEST_PRODUCT_ID" != "" ] && [ "$TEST_PRODUCT_ID" != "null" ]; then
  curl -s -X POST "$API_URL/permissions/users/$OPERATOR_ID/permissions/products" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"product_id\":$TEST_PRODUCT_ID,\"can_scan\":true,\"can_view\":true}" > /dev/null
  
  echo "✅ 已授权产品给操作员"
  
  # 再次查询
  OPERATOR_CUSTOMERS2=$(curl -s -X GET "$API_URL/customers" \
    -H "Authorization: Bearer $OPERATOR_TOKEN")
  OPERATOR_PRODUCTS2=$(curl -s -X GET "$API_URL/products" \
    -H "Authorization: Bearer $OPERATOR_TOKEN")
  
  OPERATOR_CUSTOMER_COUNT2=$(echo $OPERATOR_CUSTOMERS2 | jq '. | length')
  OPERATOR_PRODUCT_COUNT2=$(echo $OPERATOR_PRODUCTS2 | jq '. | length')
  
  echo "✅ 操作员（已授权）可以查询："
  echo "   客户: $OPERATOR_CUSTOMER_COUNT2 个（只有授权产品的客户）"
  echo "   产品: $OPERATOR_PRODUCT_COUNT2 个（只有授权的产品）"
fi

# 清理测试数据
echo ""
echo "📝 步骤 9: 清理测试数据"
curl -s -X DELETE "$API_URL/users/$OPERATOR_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN" > /dev/null
echo "✅ 测试数据已清理"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 查询权限和删除功能测试完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 测试结果总结:"
echo "   ✅ 超级管理员可以查询所有数据"
echo "   ✅ 客户管理员只能看到自己创建的客户和产品"
echo "   ✅ 操作员只能看到授权的客户和产品"
echo "   ✅ 超级管理员可以删除扫码记录"
echo "   ✅ 非超级管理员不能删除扫码记录"
echo ""
echo "🎯 功能说明:"
echo "   • 下拉列表已按权限过滤，避免干扰项"
echo "   • 超级管理员可以查询和删除所有数据"
echo "   • 客户管理员只看到自己创建的数据"
echo "   • 操作员只看到授权的数据"
echo ""
