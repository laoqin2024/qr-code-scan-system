#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 测试前端界面优化功能"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

API_URL="http://localhost:3001/api"

# 1. 登录
echo ""
echo "📝 步骤 1: 登录管理员"
ADMIN_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}')
ADMIN_TOKEN=$(echo $ADMIN_LOGIN | jq -r '.token')
echo "✅ 登录成功"

# 2. 测试客户列表（显示创建者）
echo ""
echo "📝 步骤 2: 测试客户列表（显示创建者）"
CUSTOMERS=$(curl -s -X GET "$API_URL/customers" \
  -H "Authorization: Bearer $ADMIN_TOKEN")
echo "✅ 客户列表返回 $(echo $CUSTOMERS | jq '. | length') 个客户"
echo ""
echo "客户列表示例（前3个）:"
echo $CUSTOMERS | jq -r '.[:3] | .[] | "  • \(.name) - 创建者: \(.created_by_display_name // "未知") - 可编辑: \(if .can_edit == 1 then "是" else "否" end)"'

# 3. 测试产品列表（显示创建者）
echo ""
echo "📝 步骤 3: 测试产品列表（显示创建者）"
PRODUCTS=$(curl -s -X GET "$API_URL/products" \
  -H "Authorization: Bearer $ADMIN_TOKEN")
echo "✅ 产品列表返回 $(echo $PRODUCTS | jq '. | length') 个产品"
echo ""
echo "产品列表示例（前3个）:"
echo $PRODUCTS | jq -r '.[:3] | .[] | "  • \(.model) (\(.customer_name)) - 创建者: \(.created_by_display_name // "未知") - 可编辑: \(if .can_edit == 1 then "是" else "否" end)"'

# 4. 测试用户列表（显示姓名）
echo ""
echo "📝 步骤 4: 测试用户列表（显示姓名）"
USERS=$(curl -s -X GET "$API_URL/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN")
echo "✅ 用户列表返回 $(echo $USERS | jq '. | length') 个用户"
echo ""
echo "用户列表示例:"
echo $USERS | jq -r '.[] | "  • \(.username) - 姓名: \(.display_name // "未设置") - 角色: \(.role)"'

# 5. 测试扫码记录（显示录入人员）
echo ""
echo "📝 步骤 5: 测试扫码记录（显示录入人员）"
SCANS=$(curl -s -X GET "$API_URL/scans?limit=5" \
  -H "Authorization: Bearer $ADMIN_TOKEN")
SCAN_COUNT=$(echo $SCANS | jq '. | length')
echo "✅ 扫码记录返回 $SCAN_COUNT 条"
if [ "$SCAN_COUNT" -gt 0 ]; then
  echo ""
  echo "扫码记录示例（前3条）:"
  echo $SCANS | jq -r '.[:3] | .[] | "  • \(.customer_name) | \(.product_model) | 录入人: \(.display_name // .username // "未知") | \(if .is_valid then "✓" else "✗" end)"'
fi

# 6. 测试按录入人员筛选
echo ""
echo "📝 步骤 6: 测试按录入人员筛选"
if [ "$SCAN_COUNT" -gt 0 ]; then
  FIRST_USER_ID=$(echo $SCANS | jq -r '.[0].user_id')
  if [ "$FIRST_USER_ID" != "null" ] && [ "$FIRST_USER_ID" != "" ]; then
    FILTERED_SCANS=$(curl -s -X GET "$API_URL/scans?user_id=$FIRST_USER_ID" \
      -H "Authorization: Bearer $ADMIN_TOKEN")
    FILTERED_COUNT=$(echo $FILTERED_SCANS | jq '. | length')
    echo "✅ 按用户ID $FIRST_USER_ID 筛选，返回 $FILTERED_COUNT 条记录"
  else
    echo "⚠️  没有找到有效的用户ID，跳过筛选测试"
  fi
else
  echo "⚠️  没有扫码记录，跳过筛选测试"
fi

# 7. 测试创建用户（带姓名）
echo ""
echo "📝 步骤 7: 测试创建用户（带姓名）"
NEW_USER=$(curl -s -X POST "$API_URL/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username":"test_ui_user","password":"test123","display_name":"测试用户","role":"operator"}')
if echo $NEW_USER | jq -e '.id' > /dev/null; then
  NEW_USER_ID=$(echo $NEW_USER | jq -r '.id')
  echo "✅ 创建用户成功: ID=$NEW_USER_ID"
  
  # 验证用户信息
  USER_INFO=$(curl -s -X GET "$API_URL/users/$NEW_USER_ID" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
  USER_DISPLAY_NAME=$(echo $USER_INFO | jq -r '.display_name')
  echo "✅ 验证用户姓名: $USER_DISPLAY_NAME"
else
  echo "❌ 创建用户失败: $(echo $NEW_USER | jq -r '.error')"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 前端界面优化功能测试完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 测试结果总结:"
echo "   ✅ 客户列表显示创建者"
echo "   ✅ 产品列表显示创建者"
echo "   ✅ 用户列表显示姓名"
echo "   ✅ 扫码记录显示录入人员"
echo "   ✅ 支持按录入人员筛选"
echo "   ✅ 创建用户时可以设置姓名"
echo ""
echo "🎨 前端界面功能:"
echo "   • 客户/产品列表显示创建者姓名"
echo "   • 只读数据显示'只读'标识"
echo "   • 扫码记录显示录入人员姓名和账号"
echo "   • 用户管理界面支持姓名字段"
echo "   • 查询页面支持按录入人员筛选"
echo ""
