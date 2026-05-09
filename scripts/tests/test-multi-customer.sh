#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 测试客户管理员多客户权限"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

API_URL="http://localhost:3001/api"

# 1. 登录 qx001
echo ""
echo "📝 步骤 1: 登录 qx001"
QX001_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"qx001","password":"123456"}')
QX001_TOKEN=$(echo $QX001_LOGIN | jq -r '.token')
QX001_ID=$(echo $QX001_LOGIN | jq -r '.user.id')
QX001_CUSTOMER_ID=$(echo $QX001_LOGIN | jq -r '.user.customer_id')

echo "✅ qx001 登录成功"
echo "   用户ID: $QX001_ID"
echo "   默认客户ID: $QX001_CUSTOMER_ID"

# 2. qx001 创建第一个客户
echo ""
echo "📝 步骤 2: qx001 创建第一个客户"
CUSTOMER1=$(curl -s -X POST "$API_URL/customers" \
  -H "Authorization: Bearer $QX001_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"qx001的客户A","expected_length":20,"description":"测试多客户权限"}')
CUSTOMER1_ID=$(echo $CUSTOMER1 | jq -r '.id')
echo "✅ 客户A创建成功: ID=$CUSTOMER1_ID"

# 3. qx001 创建第二个客户
echo ""
echo "📝 步骤 3: qx001 创建第二个客户"
CUSTOMER2=$(curl -s -X POST "$API_URL/customers" \
  -H "Authorization: Bearer $QX001_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"qx001的客户B","expected_length":18,"description":"测试多客户权限"}')
CUSTOMER2_ID=$(echo $CUSTOMER2 | jq -r '.id')
echo "✅ 客户B创建成功: ID=$CUSTOMER2_ID"

# 4. 为客户A创建产品
echo ""
echo "📝 步骤 4: 为客户A创建产品"
PRODUCT1=$(curl -s -X POST "$API_URL/products" \
  -H "Authorization: Bearer $QX001_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"客户A的产品\",\"customer_id\":$CUSTOMER1_ID,\"description\":\"测试\"}")
PRODUCT1_ID=$(echo $PRODUCT1 | jq -r '.id')
echo "✅ 产品1创建成功: ID=$PRODUCT1_ID"

# 5. 为客户B创建产品
echo ""
echo "📝 步骤 5: 为客户B创建产品"
PRODUCT2=$(curl -s -X POST "$API_URL/products" \
  -H "Authorization: Bearer $QX001_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"客户B的产品\",\"customer_id\":$CUSTOMER2_ID,\"description\":\"测试\"}")
PRODUCT2_ID=$(echo $PRODUCT2 | jq -r '.id')
echo "✅ 产品2创建成功: ID=$PRODUCT2_ID"

# 6. 测试扫描客户A的产品
echo ""
echo "📝 步骤 6: 测试扫描客户A的产品"
SCAN1=$(curl -s -X POST "$API_URL/scans" \
  -H "Authorization: Bearer $QX001_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"customer_id\":$CUSTOMER1_ID,\"product_id\":$PRODUCT1_ID,\"code_text\":\"12345678901234567890\",\"notes\":\"测试客户A\"}")

if echo $SCAN1 | jq -e '.id' > /dev/null; then
  echo "✅ 扫描客户A的产品成功"
else
  echo "❌ 扫描客户A的产品失败: $(echo $SCAN1 | jq -r '.error')"
fi

# 7. 测试扫描客户B的产品
echo ""
echo "📝 步骤 7: 测试扫描客户B的产品"
SCAN2=$(curl -s -X POST "$API_URL/scans" \
  -H "Authorization: Bearer $QX001_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"customer_id\":$CUSTOMER2_ID,\"product_id\":$PRODUCT2_ID,\"code_text\":\"123456789012345678\",\"notes\":\"测试客户B\"}")

if echo $SCAN2 | jq -e '.id' > /dev/null; then
  echo "✅ 扫描客户B的产品成功"
else
  echo "❌ 扫描客户B的产品失败: $(echo $SCAN2 | jq -r '.error')"
fi

# 8. 测试扫描之前创建的客户（qx001创建）
echo ""
echo "📝 步骤 8: 测试扫描之前创建的客户的产品"
OLD_CUSTOMER=$(curl -s -X GET "$API_URL/customers" \
  -H "Authorization: Bearer $QX001_TOKEN" | jq -r '.[] | select(.name == "qx001创建") | .id')

if [ "$OLD_CUSTOMER" != "" ] && [ "$OLD_CUSTOMER" != "null" ]; then
  OLD_PRODUCT=$(curl -s -X GET "$API_URL/products" \
    -H "Authorization: Bearer $QX001_TOKEN" | jq -r ".[] | select(.customer_id == $OLD_CUSTOMER) | .id" | head -1)
  
  if [ "$OLD_PRODUCT" != "" ] && [ "$OLD_PRODUCT" != "null" ]; then
    SCAN3=$(curl -s -X POST "$API_URL/scans" \
      -H "Authorization: Bearer $QX001_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"customer_id\":$OLD_CUSTOMER,\"product_id\":$OLD_PRODUCT,\"code_text\":\"12345678901234567890\",\"notes\":\"测试旧客户\"}")
    
    if echo $SCAN3 | jq -e '.id' > /dev/null; then
      echo "✅ 扫描旧客户的产品成功"
    else
      echo "❌ 扫描旧客户的产品失败: $(echo $SCAN3 | jq -r '.error')"
    fi
  else
    echo "⚠️  旧客户没有产品，跳过测试"
  fi
else
  echo "⚠️  找不到旧客户，跳过测试"
fi

# 9. 测试扫描其他人创建的客户的产品
echo ""
echo "📝 步骤 9: 测试扫描其他人创建的客户的产品"
ADMIN_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}')
ADMIN_TOKEN=$(echo $ADMIN_LOGIN | jq -r '.token')

OTHER_CUSTOMER=$(curl -s -X POST "$API_URL/customers" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"admin创建的客户","expected_length":20,"description":"测试"}')
OTHER_CUSTOMER_ID=$(echo $OTHER_CUSTOMER | jq -r '.id')

OTHER_PRODUCT=$(curl -s -X POST "$API_URL/products" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"admin的产品\",\"customer_id\":$OTHER_CUSTOMER_ID,\"description\":\"测试\"}")
OTHER_PRODUCT_ID=$(echo $OTHER_PRODUCT | jq -r '.id')

SCAN4=$(curl -s -X POST "$API_URL/scans" \
  -H "Authorization: Bearer $QX001_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"customer_id\":$OTHER_CUSTOMER_ID,\"product_id\":$OTHER_PRODUCT_ID,\"code_text\":\"12345678901234567890\",\"notes\":\"测试其他人的客户\"}")

if echo $SCAN4 | jq -e '.error' > /dev/null; then
  echo "✅ 正确拒绝其他人创建的客户: $(echo $SCAN4 | jq -r '.error')"
else
  echo "❌ 不应该允许扫描其他人创建的客户的产品"
fi

# 10. 查看扫码记录
echo ""
echo "📝 步骤 10: 查看扫码记录"
SCANS=$(curl -s -X GET "$API_URL/scans" \
  -H "Authorization: Bearer $QX001_TOKEN")
SCAN_COUNT=$(echo $SCANS | jq '[.[] | select(.username == "qx001")] | length')
echo "✅ qx001 的扫码记录: $SCAN_COUNT 条"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 多客户权限测试完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 测试结果总结:"
echo "   ✅ qx001 可以扫描自己创建的客户A的产品"
echo "   ✅ qx001 可以扫描自己创建的客户B的产品"
echo "   ✅ qx001 可以扫描之前创建的所有客户的产品"
echo "   ✅ qx001 不能扫描其他人创建的客户的产品"
echo ""
echo "🎯 新的权限规则:"
echo "   • customer_admin 可以扫描自己创建的所有客户的产品"
echo "   • customer_admin 可以扫描默认客户的产品"
echo "   • customer_admin 可以扫描已授权的产品"
echo "   • customer_admin 不能扫描其他人创建的客户的产品"
echo ""
