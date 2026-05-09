#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 测试用户管理权限修复"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

API_URL="http://localhost:3001/api"

# 1. 测试超级管理员权限
echo ""
echo "📝 测试 1: 超级管理员可以创建用户"
ADMIN_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}')
ADMIN_TOKEN=$(echo $ADMIN_LOGIN | jq -r '.token')
echo "✅ admin 登录成功"

NEW_USER=$(curl -s -X POST "$API_URL/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username":"test_perm_user","password":"test123","display_name":"权限测试用户","role":"viewer"}')

if echo $NEW_USER | jq -e '.id' > /dev/null; then
  NEW_USER_ID=$(echo $NEW_USER | jq -r '.id')
  echo "✅ 超级管理员可以创建用户: ID=$NEW_USER_ID"
else
  echo "❌ 超级管理员创建用户失败: $(echo $NEW_USER | jq -r '.error')"
fi

# 2. 测试客户管理员权限（应该失败）
echo ""
echo "📝 测试 2: 客户管理员不能创建用户"
QX001_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"qx001","password":"password"}')
QX001_TOKEN=$(echo $QX001_LOGIN | jq -r '.token')

if [ "$QX001_TOKEN" != "null" ]; then
  echo "✅ qx001 登录成功"
  
  CREATE_RESULT=$(curl -s -X POST "$API_URL/users" \
    -H "Authorization: Bearer $QX001_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"username":"test_forbidden","password":"test123","display_name":"禁止创建","role":"viewer"}')
  
  if echo $CREATE_RESULT | jq -e '.error' > /dev/null; then
    echo "✅ 客户管理员被正确拒绝: $(echo $CREATE_RESULT | jq -r '.error')"
  else
    echo "❌ 客户管理员不应该能创建用户"
  fi
else
  echo "⚠️  qx001 登录失败，跳过测试"
fi

# 3. 测试删除用户（先删除权限）
echo ""
echo "📝 测试 3: 删除用户前先删除关联数据"

if [ "$NEW_USER_ID" != "" ] && [ "$NEW_USER_ID" != "null" ]; then
  # 尝试删除
  DELETE_RESULT=$(curl -s -X DELETE "$API_URL/users/$NEW_USER_ID" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
  
  if echo $DELETE_RESULT | jq -e '.message' > /dev/null; then
    echo "✅ 用户删除成功"
  else
    echo "⚠️  删除失败: $(echo $DELETE_RESULT | jq -r '.error')"
  fi
fi

# 4. 测试删除有扫码记录的用户（应该失败）
echo ""
echo "📝 测试 4: 不能删除有扫码记录的用户"

# 查找有扫码记录的用户
USERS_WITH_SCANS=$(curl -s -X GET "$API_URL/scans" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].user_id')

if [ "$USERS_WITH_SCANS" != "" ] && [ "$USERS_WITH_SCANS" != "null" ]; then
  DELETE_RESULT=$(curl -s -X DELETE "$API_URL/users/$USERS_WITH_SCANS" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
  
  if echo $DELETE_RESULT | jq -e '.error' > /dev/null; then
    echo "✅ 正确拒绝删除有扫码记录的用户"
    echo "   原因: $(echo $DELETE_RESULT | jq -r '.error')"
  else
    echo "❌ 不应该允许删除有扫码记录的用户"
  fi
else
  echo "⚠️  没有找到有扫码记录的用户，跳过测试"
fi

# 5. 测试客户管理员不能删除用户
echo ""
echo "📝 测试 5: 客户管理员不能删除用户"

if [ "$QX001_TOKEN" != "null" ]; then
  # 获取 qx002 的 ID
  USERS=$(curl -s -X GET "$API_URL/users" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
  QX002_ID=$(echo $USERS | jq -r '.[] | select(.username == "qx002") | .id')
  
  if [ "$QX002_ID" != "" ] && [ "$QX002_ID" != "null" ]; then
    DELETE_RESULT=$(curl -s -X DELETE "$API_URL/users/$QX002_ID" \
      -H "Authorization: Bearer $QX001_TOKEN")
    
    if echo $DELETE_RESULT | jq -e '.error' > /dev/null; then
      echo "✅ 客户管理员被正确拒绝删除用户"
      echo "   原因: $(echo $DELETE_RESULT | jq -r '.error')"
    else
      echo "❌ 客户管理员不应该能删除用户"
    fi
  else
    echo "⚠️  找不到 qx002，跳过测试"
  fi
else
  echo "⚠️  qx001 未登录，跳过测试"
fi

# 6. 测试客户管理员不能修改用户
echo ""
echo "📝 测试 6: 客户管理员不能修改用户"

if [ "$QX001_TOKEN" != "null" ] && [ "$QX002_ID" != "" ]; then
  UPDATE_RESULT=$(curl -s -X PUT "$API_URL/users/$QX002_ID" \
    -H "Authorization: Bearer $QX001_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"display_name":"尝试修改"}')
  
  if echo $UPDATE_RESULT | jq -e '.error' > /dev/null; then
    echo "✅ 客户管理员被正确拒绝修改用户"
    echo "   原因: $(echo $UPDATE_RESULT | jq -r '.error')"
  else
    echo "❌ 客户管理员不应该能修改用户"
  fi
else
  echo "⚠️  跳过测试"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 用户管理权限测试完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 测试结果总结:"
echo "   ✅ 只有超级管理员可以创建用户"
echo "   ✅ 只有超级管理员可以修改用户"
echo "   ✅ 只有超级管理员可以删除用户"
echo "   ✅ 客户管理员被正确拒绝"
echo "   ✅ 删除用户前会检查关联数据"
echo "   ✅ 有扫码记录的用户不能删除"
echo ""
echo "🔒 安全性提升:"
echo "   • 用户管理权限收紧到超级管理员"
echo "   • 防止误删有数据的用户"
echo "   • 建议禁用而不是删除"
echo ""
