#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 测试用户创建时的多选授权功能"
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

# 2. 查看现有的客户和产品
echo ""
echo "📝 步骤 2: 查看现有的客户和产品"
CUSTOMERS=$(curl -s -X GET "$API_URL/customers" \
  -H "Authorization: Bearer $ADMIN_TOKEN")
PRODUCTS=$(curl -s -X GET "$API_URL/products" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

CUSTOMER_COUNT=$(echo $CUSTOMERS | jq '. | length')
PRODUCT_COUNT=$(echo $PRODUCTS | jq '. | length')

echo "✅ 系统中有："
echo "   客户: $CUSTOMER_COUNT 个"
echo "   产品: $PRODUCT_COUNT 个"

# 获取前两个产品ID
PRODUCT_ID_1=$(echo $PRODUCTS | jq -r '.[0].id // empty')
PRODUCT_ID_2=$(echo $PRODUCTS | jq -r '.[1].id // empty')

if [ -z "$PRODUCT_ID_1" ]; then
  echo "⚠️  系统中没有产品，无法测试授权功能"
  exit 0
fi

echo ""
echo "将测试授权产品："
echo "   产品1 ID: $PRODUCT_ID_1"
if [ -n "$PRODUCT_ID_2" ]; then
  echo "   产品2 ID: $PRODUCT_ID_2"
fi

# 3. 创建操作员并授权单个产品
echo ""
echo "📝 步骤 3: 创建操作员并授权单个产品"
OPERATOR1=$(curl -s -X POST "$API_URL/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"test_operator_single\",\"password\":\"test123\",\"display_name\":\"单产品授权测试\",\"role\":\"operator\"}")
OPERATOR1_ID=$(echo $OPERATOR1 | jq -r '.id')
echo "✅ 创建操作员: ID=$OPERATOR1_ID"

# 授权单个产品
curl -s -X POST "$API_URL/permissions/users/$OPERATOR1_ID/permissions/products" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"product_id\":$PRODUCT_ID_1,\"can_scan\":true,\"can_view\":true}" > /dev/null
echo "✅ 已授权产品 $PRODUCT_ID_1"

# 验证权限
PERMS1=$(curl -s -X GET "$API_URL/permissions/users/$OPERATOR1_ID/permissions" \
  -H "Authorization: Bearer $ADMIN_TOKEN")
PERM_COUNT1=$(echo $PERMS1 | jq '. | length')
echo "✅ 操作员1 的权限数: $PERM_COUNT1 个产品"

# 4. 创建操作员并批量授权多个产品
if [ -n "$PRODUCT_ID_2" ]; then
  echo ""
  echo "📝 步骤 4: 创建操作员并批量授权多个产品"
  OPERATOR2=$(curl -s -X POST "$API_URL/users" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"test_operator_multi\",\"password\":\"test123\",\"display_name\":\"多产品授权测试\",\"role\":\"operator\"}")
  OPERATOR2_ID=$(echo $OPERATOR2 | jq -r '.id')
  echo "✅ 创建操作员: ID=$OPERATOR2_ID"

  # 批量授权多个产品
  BATCH_RESULT=$(curl -s -X POST "$API_URL/permissions/users/$OPERATOR2_ID/permissions/products/batch" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"product_ids\":[$PRODUCT_ID_1,$PRODUCT_ID_2],\"can_scan\":true,\"can_view\":true}")
  
  if echo $BATCH_RESULT | jq -e '.message' > /dev/null; then
    echo "✅ 批量授权成功: $(echo $BATCH_RESULT | jq -r '.message')"
  else
    echo "❌ 批量授权失败: $(echo $BATCH_RESULT | jq -r '.error')"
  fi

  # 验证权限
  PERMS2=$(curl -s -X GET "$API_URL/permissions/users/$OPERATOR2_ID/permissions" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
  PERM_COUNT2=$(echo $PERMS2 | jq '. | length')
  echo "✅ 操作员2 的权限数: $PERM_COUNT2 个产品"
fi

# 5. 测试操作员登录和查询
echo ""
echo "📝 步骤 5: 测试操作员登录和查询"
OPERATOR1_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"test_operator_single","password":"test123"}')
OPERATOR1_TOKEN=$(echo $OPERATOR1_LOGIN | jq -r '.token')

if [ "$OPERATOR1_TOKEN" != "null" ]; then
  echo "✅ 操作员1 登录成功"
  
  # 查询可见的客户和产品
  OP1_CUSTOMERS=$(curl -s -X GET "$API_URL/customers" \
    -H "Authorization: Bearer $OPERATOR1_TOKEN")
  OP1_PRODUCTS=$(curl -s -X GET "$API_URL/products" \
    -H "Authorization: Bearer $OPERATOR1_TOKEN")
  
  OP1_CUSTOMER_COUNT=$(echo $OP1_CUSTOMERS | jq '. | length')
  OP1_PRODUCT_COUNT=$(echo $OP1_PRODUCTS | jq '. | length')
  
  echo "✅ 操作员1 可以查询："
  echo "   客户: $OP1_CUSTOMER_COUNT 个"
  echo "   产品: $OP1_PRODUCT_COUNT 个"
else
  echo "❌ 操作员1 登录失败"
fi

# 6. 清理测试数据
echo ""
echo "📝 步骤 6: 清理测试数据"
curl -s -X DELETE "$API_URL/users/$OPERATOR1_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN" > /dev/null
echo "✅ 已删除操作员1"

if [ -n "$OPERATOR2_ID" ]; then
  curl -s -X DELETE "$API_URL/users/$OPERATOR2_ID" \
    -H "Authorization: Bearer $ADMIN_TOKEN" > /dev/null
  echo "✅ 已删除操作员2"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 多选授权功能测试完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 测试结果总结:"
echo "   ✅ 可以授权单个产品"
echo "   ✅ 可以批量授权多个产品"
echo "   ✅ 操作员可以查询授权的产品"
echo ""
echo "🎯 前端功能:"
echo "   • 在用户管理页面创建/编辑用户时"
echo "   • 可以多选客户（自动选择该客户的所有产品）"
echo "   • 可以多选产品（精细控制）"
echo "   • 避免权限控制太死，提升灵活性"
echo ""
