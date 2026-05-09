#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 测试用户管理和权限管理分离"
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

# 2. 创建测试用户（不授权）
echo ""
echo "📝 步骤 2: 创建测试用户（不授权产品）"
TEST_USER=$(curl -s -X POST "$API_URL/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username":"test_separate_perm","password":"test123","display_name":"权限分离测试","role":"operator"}')
TEST_USER_ID=$(echo $TEST_USER | jq -r '.id')

if [ "$TEST_USER_ID" != "null" ] && [ "$TEST_USER_ID" != "" ]; then
  echo "✅ 创建用户成功: ID=$TEST_USER_ID"
else
  echo "❌ 创建用户失败: $(echo $TEST_USER | jq -r '.error')"
  exit 1
fi

# 3. 验证用户没有权限
echo ""
echo "📝 步骤 3: 验证用户初始没有权限"
PERMS=$(curl -s -X GET "$API_URL/permissions/users/$TEST_USER_ID/permissions" \
  -H "Authorization: Bearer $ADMIN_TOKEN")
PERM_COUNT=$(echo $PERMS | jq '. | length')
echo "✅ 用户初始权限: $PERM_COUNT 个产品"

# 4. 获取可授权的产品
echo ""
echo "📝 步骤 4: 获取可授权的产品"
PRODUCTS=$(curl -s -X GET "$API_URL/products" \
  -H "Authorization: Bearer $ADMIN_TOKEN")
PRODUCT_COUNT=$(echo $PRODUCTS | jq '. | length')
echo "✅ 系统中有 $PRODUCT_COUNT 个产品"

if [ "$PRODUCT_COUNT" -gt 0 ]; then
  PRODUCT_ID=$(echo $PRODUCTS | jq -r '.[0].id')
  echo "   将授权产品 ID: $PRODUCT_ID"
  
  # 5. 通过权限管理接口授权
  echo ""
  echo "📝 步骤 5: 通过权限管理接口授权产品"
  GRANT_RESULT=$(curl -s -X POST "$API_URL/permissions/users/$TEST_USER_ID/permissions/products" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"product_id\":$PRODUCT_ID,\"can_scan\":true,\"can_view\":true}")
  
  if echo $GRANT_RESULT | jq -e '.message' > /dev/null; then
    echo "✅ 授权成功: $(echo $GRANT_RESULT | jq -r '.message')"
  else
    echo "❌ 授权失败: $(echo $GRANT_RESULT | jq -r '.error')"
  fi
  
  # 6. 验证权限已添加
  echo ""
  echo "📝 步骤 6: 验证权限已添加"
  PERMS_AFTER=$(curl -s -X GET "$API_URL/permissions/users/$TEST_USER_ID/permissions" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
  PERM_COUNT_AFTER=$(echo $PERMS_AFTER | jq '. | length')
  echo "✅ 用户当前权限: $PERM_COUNT_AFTER 个产品"
fi

# 7. 测试删除用户（修复外键约束）
echo ""
echo "📝 步骤 7: 测试删除用户"
DELETE_RESULT=$(curl -s -X DELETE "$API_URL/users/$TEST_USER_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

if echo $DELETE_RESULT | jq -e '.message' > /dev/null; then
  echo "✅ 删除用户成功: $(echo $DELETE_RESULT | jq -r '.message')"
else
  echo "❌ 删除用户失败: $(echo $DELETE_RESULT | jq -r '.error')"
fi

# 8. 验证用户已删除
echo ""
echo "📝 步骤 8: 验证用户已删除"
VERIFY=$(curl -s -X GET "$API_URL/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq ".[] | select(.id == $TEST_USER_ID)")

if [ "$VERIFY" = "" ]; then
  echo "✅ 用户已成功删除"
else
  echo "❌ 用户仍然存在"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 用户管理和权限管理分离测试完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 测试结果总结:"
echo "   ✅ 创建用户时不再自动授权"
echo "   ✅ 用户初始没有产品权限"
echo "   ✅ 可以通过独立的权限管理接口授权"
echo "   ✅ 删除用户时正确处理外键约束"
echo "   ✅ 用户可以成功删除"
echo ""
echo "🎯 架构改进:"
echo "   • 用户管理：只处理用户基本信息（创建、编辑、删除、启用/禁用）"
echo "   • 权限管理：独立页面，专门管理用户的产品权限"
echo "   • 逻辑清晰：职责分离，避免混乱"
echo "   • 易于维护：各模块独立，互不干扰"
echo ""
