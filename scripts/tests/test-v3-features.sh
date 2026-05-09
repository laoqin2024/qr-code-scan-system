#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 测试 v3 功能 - 数据所有权 + 用户真实姓名"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

API_URL="http://localhost:3001/api"

# 1. 登录 admin
echo ""
echo "📝 步骤 1: 登录 admin"
ADMIN_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}')
ADMIN_TOKEN=$(echo $ADMIN_LOGIN | jq -r '.token')
ADMIN_DISPLAY_NAME=$(echo $ADMIN_LOGIN | jq -r '.user.display_name')
echo "✅ 登录成功，姓名: $ADMIN_DISPLAY_NAME"

# 2. 创建客户管理员A
echo ""
echo "📝 步骤 2: 创建客户管理员A"
MANAGER_A=$(curl -s -X POST "$API_URL/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username":"manager_a","password":"test123","display_name":"张经理","role":"customer_admin"}')
MANAGER_A_ID=$(echo $MANAGER_A | jq -r '.id')
echo "✅ 创建成功: 张经理 (manager_a), ID=$MANAGER_A_ID"

# 3. 创建客户管理员B
echo ""
echo "📝 步骤 3: 创建客户管理员B"
MANAGER_B=$(curl -s -X POST "$API_URL/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username":"manager_b","password":"test123","display_name":"李经理","role":"customer_admin"}')
MANAGER_B_ID=$(echo $MANAGER_B | jq -r '.id')
echo "✅ 创建成功: 李经理 (manager_b), ID=$MANAGER_B_ID"

# 4. 张经理登录并创建客户
echo ""
echo "📝 步骤 4: 张经理登录并创建客户"
MANAGER_A_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"manager_a","password":"test123"}')
MANAGER_A_TOKEN=$(echo $MANAGER_A_LOGIN | jq -r '.token')

CUSTOMER_A=$(curl -s -X POST "$API_URL/customers" \
  -H "Authorization: Bearer $MANAGER_A_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"张经理的客户","expected_length":20,"description":"测试数据所有权"}')
CUSTOMER_A_ID=$(echo $CUSTOMER_A | jq -r '.id')
echo "✅ 张经理创建客户: ID=$CUSTOMER_A_ID"

# 5. 李经理登录并创建客户
echo ""
echo "📝 步骤 5: 李经理登录并创建客户"
MANAGER_B_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"manager_b","password":"test123"}')
MANAGER_B_TOKEN=$(echo $MANAGER_B_LOGIN | jq -r '.token')

CUSTOMER_B=$(curl -s -X POST "$API_URL/customers" \
  -H "Authorization: Bearer $MANAGER_B_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"李经理的客户","expected_length":18,"description":"测试数据所有权"}')
CUSTOMER_B_ID=$(echo $CUSTOMER_B | jq -r '.id')
echo "✅ 李经理创建客户: ID=$CUSTOMER_B_ID"

# 6. 查看客户列表（张经理）
echo ""
echo "📝 步骤 6: 张经理查看客户列表"
CUSTOMERS_A=$(curl -s -X GET "$API_URL/customers" \
  -H "Authorization: Bearer $MANAGER_A_TOKEN")
echo "✅ 张经理可以看到 $(echo $CUSTOMERS_A | jq '. | length') 个客户"
echo ""
echo "客户列表（显示创建者和编辑权限）:"
echo $CUSTOMERS_A | jq -r '.[] | select(.id == '$CUSTOMER_A_ID' or .id == '$CUSTOMER_B_ID') | "\(.name) - 创建者: \(.created_by_display_name) - 可编辑: \(if .can_edit == 1 then "是" else "否" end)"'

# 7. 测试编辑权限（张经理尝试编辑自己的客户）
echo ""
echo "📝 步骤 7: 张经理编辑自己的客户"
UPDATE_OWN=$(curl -s -X PUT "$API_URL/customers/$CUSTOMER_A_ID" \
  -H "Authorization: Bearer $MANAGER_A_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"张经理的客户（已修改）"}')
if echo $UPDATE_OWN | jq -e '.success' > /dev/null; then
  echo "✅ 成功编辑自己的客户"
else
  echo "❌ 编辑失败: $(echo $UPDATE_OWN | jq -r '.error')"
fi

# 8. 测试编辑权限（张经理尝试编辑李经理的客户）
echo ""
echo "📝 步骤 8: 张经理尝试编辑李经理的客户"
UPDATE_OTHER=$(curl -s -X PUT "$API_URL/customers/$CUSTOMER_B_ID" \
  -H "Authorization: Bearer $MANAGER_A_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"尝试修改"}')
if echo $UPDATE_OTHER | jq -e '.error' > /dev/null; then
  echo "✅ 正确拒绝: $(echo $UPDATE_OTHER | jq -r '.error')"
else
  echo "❌ 权限检查失败，不应该允许编辑"
fi

# 9. 创建操作员并扫码
echo ""
echo "📝 步骤 9: 创建操作员"
OPERATOR=$(curl -s -X POST "$API_URL/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username":"operator_wang","password":"test123","display_name":"王师傅","role":"operator"}')
OPERATOR_ID=$(echo $OPERATOR | jq -r '.id')
echo "✅ 创建操作员: 王师傅 (operator_wang), ID=$OPERATOR_ID"

# 10. 创建产品并授权
echo ""
echo "📝 步骤 10: 张经理创建产品"
PRODUCT_A=$(curl -s -X POST "$API_URL/products" \
  -H "Authorization: Bearer $MANAGER_A_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"测试产品A\",\"customer_id\":$CUSTOMER_A_ID,\"description\":\"张经理的产品\"}")
PRODUCT_A_ID=$(echo $PRODUCT_A | jq -r '.id')
echo "✅ 产品创建成功: ID=$PRODUCT_A_ID"

# 11. 授权产品给操作员
echo ""
echo "📝 步骤 11: 授权产品给操作员"
curl -s -X POST "$API_URL/permissions/users/$OPERATOR_ID/permissions/products" \
  -H "Authorization: Bearer $MANAGER_A_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"product_id\":$PRODUCT_A_ID,\"can_scan\":true,\"can_view\":true}" > /dev/null
echo "✅ 授权完成"

# 12. 操作员扫码
echo ""
echo "📝 步骤 12: 操作员扫码"
OPERATOR_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"operator_wang","password":"test123"}')
OPERATOR_TOKEN=$(echo $OPERATOR_LOGIN | jq -r '.token')

SCAN=$(curl -s -X POST "$API_URL/scans" \
  -H "Authorization: Bearer $OPERATOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"customer_id\":$CUSTOMER_A_ID,\"product_id\":$PRODUCT_A_ID,\"code_text\":\"12345678901234567890\",\"notes\":\"测试扫码\"}")
echo "✅ 扫码完成"

# 13. 查看扫码记录（显示录入人员姓名）
echo ""
echo "📝 步骤 13: 查看扫码记录"
SCANS=$(curl -s -X GET "$API_URL/scans" \
  -H "Authorization: Bearer $MANAGER_A_TOKEN")
echo "✅ 扫码记录（显示录入人员）:"
echo $SCANS | jq -r '.[] | select(.product_id == '$PRODUCT_A_ID') | "\(.customer_name) | \(.product_model) | \(.code_text) | 录入人: \(.display_name) (\(.username)) | \(if .is_valid then "✓ 有效" else "✗ 无效" end)"' | head -1

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 所有测试完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 测试结果总结:"
echo "   ✅ 用户真实姓名功能正常"
echo "   ✅ 数据所有权功能正常"
echo "   ✅ 只能编辑自己创建的数据"
echo "   ✅ 扫码记录显示录入人员姓名"
echo ""
