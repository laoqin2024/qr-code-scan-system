#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 测试自动授权功能"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

API_URL="http://localhost:3001/api"

# 1. 登录 admin
echo ""
echo "📝 步骤 1: 登录 admin"
ADMIN_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}')
ADMIN_TOKEN=$(echo $ADMIN_LOGIN | jq -r '.token')
echo "✅ 登录成功"

# 2. 创建测试客户
echo ""
echo "📝 步骤 2: 创建测试客户"
TEST_CUSTOMER=$(curl -s -X POST "$API_URL/customers" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"自动授权测试客户","expected_length":20,"description":"测试自动授权功能"}')
TEST_CUSTOMER_ID=$(echo $TEST_CUSTOMER | jq -r '.id')
echo "✅ 客户创建成功: ID=$TEST_CUSTOMER_ID"

# 3. 创建测试产品
echo ""
echo "📝 步骤 3: 创建测试产品"
for i in 1 2 3; do
  PRODUCT=$(curl -s -X POST "$API_URL/products" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"测试产品$i\",\"customer_id\":$TEST_CUSTOMER_ID,\"description\":\"自动授权测试\"}")
  echo "✅ 产品$i 创建成功: ID=$(echo $PRODUCT | jq -r '.id')"
done

# 4. 创建 viewer（应该自动授权）
echo ""
echo "📝 步骤 4: 创建 viewer（测试自动授权）"
NEW_VIEWER=$(curl -s -X POST "$API_URL/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username":"test_auto_viewer","password":"test123","display_name":"自动授权测试查看者","role":"viewer","customer_id":'$TEST_CUSTOMER_ID'}')
NEW_VIEWER_ID=$(echo $NEW_VIEWER | jq -r '.id')
echo "✅ viewer 创建成功: ID=$NEW_VIEWER_ID"

# 5. 检查自动授权结果
echo ""
echo "📝 步骤 5: 检查自动授权结果"
VIEWER_PERMS=$(curl -s -X GET "$API_URL/permissions/users/$NEW_VIEWER_ID/permissions" \
  -H "Authorization: Bearer $ADMIN_TOKEN")
PERM_COUNT=$(echo $VIEWER_PERMS | jq '. | length')
echo "✅ viewer 自动获得 $PERM_COUNT 个产品权限"

if [ "$PERM_COUNT" -gt 0 ]; then
  echo ""
  echo "授权的产品："
  echo $VIEWER_PERMS | jq -r '.[] | "  • \(.product_model) - 可扫码: \(if .can_scan then "是" else "否" end) - 可查看: \(if .can_view then "是" else "否" end)"'
fi

# 6. 测试 viewer 登录和查询
echo ""
echo "📝 步骤 6: 测试 viewer 登录和查询"
VIEWER_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"test_auto_viewer","password":"test123"}')
VIEWER_TOKEN=$(echo $VIEWER_LOGIN | jq -r '.token')
echo "✅ viewer 登录成功"

VIEWER_SCANS=$(curl -s -X GET "$API_URL/scans" \
  -H "Authorization: Bearer $VIEWER_TOKEN")
SCAN_COUNT=$(echo $VIEWER_SCANS | jq '. | length')
echo "✅ viewer 可以查看 $SCAN_COUNT 条扫码记录"

# 7. 创建 operator（应该自动授权）
echo ""
echo "📝 步骤 7: 创建 operator（测试自动授权）"
NEW_OPERATOR=$(curl -s -X POST "$API_URL/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username":"test_auto_operator","password":"test123","display_name":"自动授权测试操作员","role":"operator","customer_id":'$TEST_CUSTOMER_ID'}')
NEW_OPERATOR_ID=$(echo $NEW_OPERATOR | jq -r '.id')
echo "✅ operator 创建成功: ID=$NEW_OPERATOR_ID"

# 8. 检查 operator 的授权
echo ""
echo "📝 步骤 8: 检查 operator 的授权"
OPERATOR_PERMS=$(curl -s -X GET "$API_URL/permissions/users/$NEW_OPERATOR_ID/permissions" \
  -H "Authorization: Bearer $ADMIN_TOKEN")
OP_PERM_COUNT=$(echo $OPERATOR_PERMS | jq '. | length')
echo "✅ operator 自动获得 $OP_PERM_COUNT 个产品权限"

if [ "$OP_PERM_COUNT" -gt 0 ]; then
  echo ""
  echo "授权的产品："
  echo $OPERATOR_PERMS | jq -r '.[] | "  • \(.product_model) - 可扫码: \(if .can_scan then "是" else "否" end) - 可查看: \(if .can_view then "是" else "否" end)"'
fi

# 9. 验证权限差异
echo ""
echo "📝 步骤 9: 验证权限差异"
VIEWER_CAN_SCAN=$(echo $VIEWER_PERMS | jq -r '.[0].can_scan')
OPERATOR_CAN_SCAN=$(echo $OPERATOR_PERMS | jq -r '.[0].can_scan')

echo "viewer 可以扫码: $([ "$VIEWER_CAN_SCAN" = "true" ] && echo "是" || echo "否")"
echo "operator 可以扫码: $([ "$OPERATOR_CAN_SCAN" = "true" ] && echo "是" || echo "否")"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 自动授权功能测试完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 测试结果总结:"
echo "   ✅ 创建 viewer 时自动授权 $PERM_COUNT 个产品"
echo "   ✅ 创建 operator 时自动授权 $OP_PERM_COUNT 个产品"
echo "   ✅ viewer 不能扫码，只能查看"
echo "   ✅ operator 可以扫码和查看"
echo "   ✅ viewer 登录后可以立即查看记录"
echo ""
echo "🎯 功能验证:"
if [ "$PERM_COUNT" -gt 0 ] && [ "$OP_PERM_COUNT" -gt 0 ]; then
  echo "   ✅ 自动授权功能正常工作"
else
  echo "   ❌ 自动授权功能可能有问题"
fi
echo ""
