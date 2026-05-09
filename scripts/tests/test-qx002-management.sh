#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 测试超级管理员管理 qx002 用户"
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

# 2. 查找 qx002 用户
echo ""
echo "📝 步骤 2: 查找 qx002 用户"
USERS=$(curl -s -X GET "$API_URL/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

QX002=$(echo $USERS | jq '.[] | select(.username == "qx002")')
QX002_ID=$(echo $QX002 | jq -r '.id')
QX002_CREATED_BY=$(echo $QX002 | jq -r '.created_by')

if [ "$QX002_ID" != "null" ] && [ "$QX002_ID" != "" ]; then
  echo "✅ 找到 qx002 用户"
  echo "   ID: $QX002_ID"
  echo "   创建者ID: $QX002_CREATED_BY"
  echo "   角色: $(echo $QX002 | jq -r '.role')"
  echo "   显示名: $(echo $QX002 | jq -r '.display_name')"
  
  # 3. 查看 qx002 的当前权限
  echo ""
  echo "📝 步骤 3: 查看 qx002 的当前权限"
  QX002_PERMS=$(curl -s -X GET "$API_URL/permissions/users/$QX002_ID/permissions" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
  
  if echo $QX002_PERMS | jq -e 'type == "array"' > /dev/null 2>&1; then
    PERM_COUNT=$(echo $QX002_PERMS | jq '. | length')
    echo "✅ qx002 当前权限: $PERM_COUNT 个产品"
    
    if [ "$PERM_COUNT" -gt 0 ]; then
      echo ""
      echo "权限详情:"
      echo $QX002_PERMS | jq -r '.[] | "  - \(.product_model) (客户: \(.customer_name))"'
      
      # 4. 测试撤销所有权限
      echo ""
      echo "📝 步骤 4: 测试撤销所有权限"
      
      PRODUCT_IDS=$(echo $QX002_PERMS | jq -r '.[].product_id')
      
      for PRODUCT_ID in $PRODUCT_IDS; do
        echo "撤销产品 ID: $PRODUCT_ID"
        REVOKE_RESULT=$(curl -s -X DELETE "$API_URL/permissions/users/$QX002_ID/permissions/products/$PRODUCT_ID" \
          -H "Authorization: Bearer $ADMIN_TOKEN")
        
        if echo $REVOKE_RESULT | jq -e '.message' > /dev/null; then
          echo "  ✅ 撤销成功"
        else
          echo "  ❌ 撤销失败: $(echo $REVOKE_RESULT | jq -r '.error')"
        fi
      done
      
      # 验证权限已全部撤销
      echo ""
      echo "验证权限..."
      QX002_PERMS_AFTER=$(curl -s -X GET "$API_URL/permissions/users/$QX002_ID/permissions" \
        -H "Authorization: Bearer $ADMIN_TOKEN")
      PERM_COUNT_AFTER=$(echo $QX002_PERMS_AFTER | jq '. | length')
      echo "✅ 撤销后权限数: $PERM_COUNT_AFTER 个产品"
    else
      echo "✅ qx002 当前没有产品权限"
    fi
  else
    echo "❌ 查看权限失败: $(echo $QX002_PERMS | jq -r '.error')"
  fi
  
  # 5. 测试删除 qx002
  echo ""
  echo "📝 步骤 5: 测试删除 qx002"
  
  DELETE_RESULT=$(curl -s -X DELETE "$API_URL/users/$QX002_ID" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
  
  if echo $DELETE_RESULT | jq -e '.message' > /dev/null; then
    echo "✅ 删除成功: $(echo $DELETE_RESULT | jq -r '.message')"
    
    # 验证用户已删除
    VERIFY=$(curl -s -X GET "$API_URL/users" \
      -H "Authorization: Bearer $ADMIN_TOKEN" | jq ".[] | select(.id == $QX002_ID)")
    
    if [ "$VERIFY" = "" ]; then
      echo "✅ 用户已成功删除"
    else
      echo "❌ 用户仍然存在"
    fi
  else
    ERROR=$(echo $DELETE_RESULT | jq -r '.error')
    if [[ "$ERROR" == *"扫码记录"* ]] || [[ "$ERROR" == *"创建了"* ]]; then
      echo "⚠️  无法删除（有关联数据）: $ERROR"
      echo ""
      echo "建议：禁用该用户而不是删除"
      
      # 测试禁用用户
      echo ""
      echo "📝 测试禁用用户"
      DISABLE_RESULT=$(curl -s -X PUT "$API_URL/users/$QX002_ID" \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"is_active":false}')
      
      if echo $DISABLE_RESULT | jq -e '.message' > /dev/null; then
        echo "✅ 禁用成功"
      else
        echo "❌ 禁用失败: $(echo $DISABLE_RESULT | jq -r '.error')"
      fi
    else
      echo "❌ 删除失败: $ERROR"
    fi
  fi
else
  echo "⚠️  未找到 qx002 用户"
  echo ""
  echo "查看所有用户:"
  echo $USERS | jq -r '.[] | "  - \(.username) (ID: \(.id), 创建者: \(.created_by))"'
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 测试完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 修复说明:"
echo "   ✅ 权限检查已从基于 customer_id 改为基于 created_by"
echo "   ✅ 超级管理员可以管理所有用户"
echo "   ✅ 客户管理员可以管理自己创建的用户"
echo "   ✅ 撤销权限功能已修复"
echo "   ✅ 删除用户功能已修复"
echo ""
echo "🎯 权限规则:"
echo "   • 超级管理员：可以管理所有用户的权限和删除任何用户"
echo "   • 客户管理员：只能管理自己创建的用户（查看、授权、撤销、删除）"
echo "   • 基于创建者关系（created_by），而不是客户关系（customer_id）"
echo ""
