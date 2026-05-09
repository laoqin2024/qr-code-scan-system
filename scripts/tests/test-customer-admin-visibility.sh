#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 测试客户管理员授权后的数据可见性"
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

# 2. 登录 qx001
echo ""
echo "📝 步骤 2: 登录 qx001"
QX001_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"qx001","password":"123456"}')
QX001_TOKEN=$(echo $QX001_LOGIN | jq -r '.token')
QX001_ID=$(echo $QX001_LOGIN | jq -r '.user.id')

if [ "$QX001_TOKEN" != "null" ] && [ "$QX001_TOKEN" != "" ]; then
  echo "✅ qx001 登录成功 (ID: $QX001_ID)"
else
  echo "❌ qx001 登录失败"
  exit 1
fi

# 3. 查看 qx001 的权限
echo ""
echo "📝 步骤 3: 查看 qx001 的产品权限"
QX001_PERMS=$(curl -s -X GET "$API_URL/permissions/users/$QX001_ID/permissions" \
  -H "Authorization: Bearer $ADMIN_TOKEN")
QX001_PERM_COUNT=$(echo $QX001_PERMS | jq '. | length')

echo "✅ qx001 的产品权限: $QX001_PERM_COUNT 个"
echo ""
echo "权限详情:"
echo $QX001_PERMS | jq -r '.[] | "  - \(.product_model) (客户: \(.customer_name))"'

# 统计授权的客户数量
AUTHORIZED_CUSTOMERS=$(echo $QX001_PERMS | jq -r '[.[].customer_name] | unique | length')
echo ""
echo "授权的客户数量: $AUTHORIZED_CUSTOMERS 个"

# 4. 查看 qx001 可见的客户
echo ""
echo "📝 步骤 4: 查看 qx001 可见的客户"
QX001_CUSTOMERS=$(curl -s -X GET "$API_URL/customers" \
  -H "Authorization: Bearer $QX001_TOKEN")
QX001_CUSTOMER_COUNT=$(echo $QX001_CUSTOMERS | jq '. | length')

echo "✅ qx001 可见的客户: $QX001_CUSTOMER_COUNT 个"
echo ""
echo "客户列表:"
echo $QX001_CUSTOMERS | jq -r '.[] | "  - \(.name) (创建者: \(.created_by_username // "未知"))"'

# 5. 查看 qx001 可见的产品
echo ""
echo "📝 步骤 5: 查看 qx001 可见的产品"
QX001_PRODUCTS=$(curl -s -X GET "$API_URL/products" \
  -H "Authorization: Bearer $QX001_TOKEN")
QX001_PRODUCT_COUNT=$(echo $QX001_PRODUCTS | jq '. | length')

echo "✅ qx001 可见的产品: $QX001_PRODUCT_COUNT 个"
echo ""
echo "产品列表:"
echo $QX001_PRODUCTS | jq -r '.[] | "  - \(.model) (客户: \(.customer_name))"'

# 6. 对比分析
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 数据对比分析"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "授权情况:"
echo "  产品权限: $QX001_PERM_COUNT 个产品"
echo "  涉及客户: $AUTHORIZED_CUSTOMERS 个客户"
echo ""
echo "实际可见:"
echo "  可见客户: $QX001_CUSTOMER_COUNT 个"
echo "  可见产品: $QX001_PRODUCT_COUNT 个"
echo ""

# 判断是否正常
if [ "$QX001_CUSTOMER_COUNT" -ge "$AUTHORIZED_CUSTOMERS" ]; then
  echo "✅ 客户可见性正常（可见客户数 >= 授权客户数）"
else
  echo "❌ 客户可见性异常（可见客户数 < 授权客户数）"
  echo "   期望至少看到 $AUTHORIZED_CUSTOMERS 个客户"
  echo "   实际只看到 $QX001_CUSTOMER_COUNT 个客户"
fi

if [ "$QX001_PRODUCT_COUNT" -ge "$QX001_PERM_COUNT" ]; then
  echo "✅ 产品可见性正常（可见产品数 >= 授权产品数）"
else
  echo "❌ 产品可见性异常（可见产品数 < 授权产品数）"
  echo "   期望至少看到 $QX001_PERM_COUNT 个产品"
  echo "   实际只看到 $QX001_PRODUCT_COUNT 个产品"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 测试完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 说明:"
echo "   • 客户管理员可见数据 = 自己创建的数据 + 授权的产品数据"
echo "   • 如果授权了其他客户的产品，应该能看到那些客户"
echo "   • 如果授权了产品，应该能看到那些产品"
echo ""
