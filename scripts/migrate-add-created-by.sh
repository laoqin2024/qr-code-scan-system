#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 数据库迁移：为 users 表添加 created_by 字段"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

DB_PATH="/Volumes/MyDisk/App programs/scan-code/db.sqlite"

echo ""
echo "📝 步骤 1: 备份数据库"
cp "$DB_PATH" "${DB_PATH}.backup-before-created-by-$(date +%Y%m%d-%H%M%S)"
echo "✅ 数据库已备份"

echo ""
echo "📝 步骤 2: 添加 created_by 字段"
sqlite3 "$DB_PATH" "ALTER TABLE users ADD COLUMN created_by INTEGER REFERENCES users(id);"

if [ $? -eq 0 ]; then
  echo "✅ created_by 字段添加成功"
else
  echo "❌ 添加字段失败"
  exit 1
fi

echo ""
echo "📝 步骤 3: 验证字段已添加"
sqlite3 "$DB_PATH" "PRAGMA table_info(users);" | grep created_by

if [ $? -eq 0 ]; then
  echo "✅ 字段验证成功"
else
  echo "❌ 字段验证失败"
  exit 1
fi

echo ""
echo "📝 步骤 4: 设置现有用户的 created_by"
echo "将所有现有用户的 created_by 设置为 1 (admin)"
sqlite3 "$DB_PATH" "UPDATE users SET created_by = 1 WHERE created_by IS NULL AND id != 1;"
echo "✅ 现有用户的 created_by 已设置"

echo ""
echo "📝 步骤 5: 查看更新后的用户数据"
sqlite3 "$DB_PATH" "SELECT id, username, role, created_by FROM users ORDER BY id;"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 数据库迁移完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 说明:"
echo "   • 已为 users 表添加 created_by 字段"
echo "   • 现有用户的 created_by 已设置为 1 (admin)"
echo "   • 新创建的用户将自动记录创建者"
echo ""
echo "⚠️  注意:"
echo "   • 需要重启后端服务以使更改生效"
echo "   • 备份文件已保存，如有问题可以恢复"
echo ""
