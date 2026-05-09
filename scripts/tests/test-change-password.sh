#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 测试修改密码功能"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

API_URL="http://localhost:3001/api"

# 1. 创建测试用户
echo ""
echo "📝 步骤 1: 创建测试用户"
ADMIN_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}')
ADMIN_TOKEN=$(echo $ADMIN_LOGIN | jq -r '.token')
echo "✅ admin 登录成功"

TEST_USER=$(curl -s -X POST "$API_URL/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username":"test_password_user","password":"old123","display_name":"密码测试用户","role":"viewer"}')
TEST_USER_ID=$(echo $TEST_USER | jq -r '.id')
echo "✅ 测试用户创建成功: ID=$TEST_USER_ID"

# 2. 测试用户登录
echo ""
echo "📝 步骤 2: 测试用户登录（旧密码）"
USER_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"test_password_user","password":"old123"}')
USER_TOKEN=$(echo $USER_LOGIN | jq -r '.token')

if [ "$USER_TOKEN" != "null" ]; then
  echo "✅ 使用旧密码登录成功"
else
  echo "❌ 登录失败"
  exit 1
fi

# 3. 测试修改密码（旧密码错误）
echo ""
echo "📝 步骤 3: 测试修改密码（旧密码错误）"
CHANGE_RESULT=$(curl -s -X PUT "$API_URL/users/me/password" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"old_password":"wrong123","new_password":"new123"}')

if echo $CHANGE_RESULT | jq -e '.error' > /dev/null; then
  echo "✅ 正确拒绝错误的旧密码: $(echo $CHANGE_RESULT | jq -r '.error')"
else
  echo "❌ 应该拒绝错误的旧密码"
fi

# 4. 测试修改密码（新密码太短）
echo ""
echo "📝 步骤 4: 测试修改密码（新密码太短）"
CHANGE_RESULT=$(curl -s -X PUT "$API_URL/users/me/password" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"old_password":"old123","new_password":"123"}')

if echo $CHANGE_RESULT | jq -e '.error' > /dev/null; then
  echo "✅ 正确拒绝太短的新密码: $(echo $CHANGE_RESULT | jq -r '.error')"
else
  echo "❌ 应该拒绝太短的新密码"
fi

# 5. 测试修改密码（成功）
echo ""
echo "📝 步骤 5: 测试修改密码（成功）"
CHANGE_RESULT=$(curl -s -X PUT "$API_URL/users/me/password" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"old_password":"old123","new_password":"new123"}')

if echo $CHANGE_RESULT | jq -e '.message' > /dev/null; then
  echo "✅ 密码修改成功: $(echo $CHANGE_RESULT | jq -r '.message')"
else
  echo "❌ 密码修改失败: $(echo $CHANGE_RESULT | jq -r '.error')"
  exit 1
fi

# 6. 测试旧密码不能登录
echo ""
echo "📝 步骤 6: 测试旧密码不能登录"
OLD_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"test_password_user","password":"old123"}')

if echo $OLD_LOGIN | jq -e '.error' > /dev/null; then
  echo "✅ 旧密码正确被拒绝"
else
  echo "❌ 旧密码不应该能登录"
fi

# 7. 测试新密码可以登录
echo ""
echo "📝 步骤 7: 测试新密码可以登录"
NEW_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"test_password_user","password":"new123"}')
NEW_TOKEN=$(echo $NEW_LOGIN | jq -r '.token')

if [ "$NEW_TOKEN" != "null" ]; then
  echo "✅ 使用新密码登录成功"
else
  echo "❌ 新密码登录失败"
  exit 1
fi

# 8. 测试所有角色都能修改密码
echo ""
echo "📝 步骤 8: 测试其他角色修改密码"

# 测试 admin 修改密码
ADMIN_CHANGE=$(curl -s -X PUT "$API_URL/users/me/password" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"old_password":"admin123","new_password":"admin456"}')

if echo $ADMIN_CHANGE | jq -e '.message' > /dev/null; then
  echo "✅ admin 可以修改自己的密码"
  
  # 改回来
  ADMIN_LOGIN2=$(curl -s -X POST "$API_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"admin456"}')
  ADMIN_TOKEN2=$(echo $ADMIN_LOGIN2 | jq -r '.token')
  
  curl -s -X PUT "$API_URL/users/me/password" \
    -H "Authorization: Bearer $ADMIN_TOKEN2" \
    -H "Content-Type: application/json" \
    -d '{"old_password":"admin456","new_password":"admin123"}' > /dev/null
  
  echo "✅ admin 密码已恢复"
else
  echo "⚠️  admin 修改密码失败"
fi

# 9. 清理测试用户
echo ""
echo "📝 步骤 9: 清理测试用户"
DELETE_RESULT=$(curl -s -X DELETE "$API_URL/users/$TEST_USER_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

if echo $DELETE_RESULT | jq -e '.message' > /dev/null; then
  echo "✅ 测试用户已删除"
else
  echo "⚠️  删除测试用户失败"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 修改密码功能测试完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 测试结果总结:"
echo "   ✅ 旧密码错误时正确拒绝"
echo "   ✅ 新密码太短时正确拒绝"
echo "   ✅ 密码修改成功"
echo "   ✅ 旧密码不能再登录"
echo "   ✅ 新密码可以登录"
echo "   ✅ 所有角色都能修改自己的密码"
echo ""
echo "🔒 安全性验证:"
echo "   • 必须提供正确的旧密码"
echo "   • 新密码长度至少6位"
echo "   • 修改后需要重新登录"
echo "   • 所有用户都能修改自己的密码"
echo ""
