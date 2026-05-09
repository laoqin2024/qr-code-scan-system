import Database from 'better-sqlite3';
import * as path from 'path';
import * as fs from 'fs';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const DB_PATH = path.join(__dirname, '../../db.sqlite');
const BACKUP_PATH = path.join(__dirname, '../../db.sqlite.backup-v3');

console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log('🔄 数据库升级到 v3 - 数据所有权 + 用户真实姓名');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

// 备份数据库
console.log('\n📦 备份现有数据库...');
if (fs.existsSync(DB_PATH)) {
  fs.copyFileSync(DB_PATH, BACKUP_PATH);
  console.log('✅ 数据库已备份到:', BACKUP_PATH);
}

const db = new Database(DB_PATH);
db.pragma('foreign_keys = ON');

try {
  console.log('\n🔍 检查数据库结构...');
  
  // 检查是否需要升级
  const usersColumns = db.prepare("PRAGMA table_info(users)").all() as any[];
  const hasDisplayName = usersColumns.some(col => col.name === 'display_name');
  const hasCreatedBy = usersColumns.some(col => col.name === 'created_by');
  
  const customersColumns = db.prepare("PRAGMA table_info(customers)").all() as any[];
  const customersHasCreatedBy = customersColumns.some(col => col.name === 'created_by');
  
  const productsColumns = db.prepare("PRAGMA table_info(products)").all() as any[];
  const productsHasCreatedBy = productsColumns.some(col => col.name === 'created_by');
  
  if (hasDisplayName && hasCreatedBy && customersHasCreatedBy && productsHasCreatedBy) {
    console.log('✅ 数据库已是最新版本，无需升级');
    process.exit(0);
  }
  
  console.log('📝 需要升级，开始执行...\n');
  
  db.exec('BEGIN TRANSACTION');
  
  // 1. 添加用户真实姓名字段
  if (!hasDisplayName) {
    console.log('🔧 添加用户真实姓名字段...');
    db.exec('ALTER TABLE users ADD COLUMN display_name TEXT');
    
    // 为现有用户设置默认姓名
    db.exec(`UPDATE users SET display_name = 
      CASE 
        WHEN username = 'admin' THEN '系统管理员'
        WHEN role = 'customer_admin' THEN username
        WHEN role = 'operator' THEN username
        WHEN role = 'viewer' THEN username
        ELSE username
      END
      WHERE display_name IS NULL`);
    
    console.log('  ✓ display_name 字段已添加');
    console.log('  ✓ 现有用户已设置默认姓名');
  }
  
  // 2. 添加数据所有权字段
  if (!customersHasCreatedBy) {
    console.log('\n🔧 添加客户创建者字段...');
    db.exec('ALTER TABLE customers ADD COLUMN created_by INTEGER REFERENCES users(id)');
    
    // 为现有客户设置创建者（设为第一个 super_admin）
    const firstAdmin = db.prepare("SELECT id FROM users WHERE role = 'super_admin' LIMIT 1").get() as any;
    if (firstAdmin) {
      db.exec(`UPDATE customers SET created_by = ${firstAdmin.id} WHERE created_by IS NULL`);
      console.log(`  ✓ 现有客户的创建者设为 admin (ID: ${firstAdmin.id})`);
    }
    
    db.exec('CREATE INDEX IF NOT EXISTS idx_customers_created_by ON customers(created_by)');
    console.log('  ✓ created_by 字段已添加');
  }
  
  if (!productsHasCreatedBy) {
    console.log('\n🔧 添加产品创建者字段...');
    db.exec('ALTER TABLE products ADD COLUMN created_by INTEGER REFERENCES users(id)');
    
    // 为现有产品设置创建者
    const firstAdmin = db.prepare("SELECT id FROM users WHERE role = 'super_admin' LIMIT 1").get() as any;
    if (firstAdmin) {
      db.exec(`UPDATE products SET created_by = ${firstAdmin.id} WHERE created_by IS NULL`);
      console.log(`  ✓ 现有产品的创建者设为 admin (ID: ${firstAdmin.id})`);
    }
    
    db.exec('CREATE INDEX IF NOT EXISTS idx_products_created_by ON products(created_by)');
    console.log('  ✓ created_by 字段已添加');
  }
  
  // 3. 创建索引
  console.log('\n🔧 创建索引...');
  db.exec('CREATE INDEX IF NOT EXISTS idx_users_display_name ON users(display_name)');
  console.log('  ✓ 所有索引已创建');
  
  db.exec('COMMIT');
  
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('✅ 数据库升级成功！');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('\n📋 升级摘要:');
  console.log('  • users 表添加 display_name 字段（用户真实姓名）');
  console.log('  • customers 表添加 created_by 字段（创建者）');
  console.log('  • products 表添加 created_by 字段（创建者）');
  console.log('  • 现有数据已设置默认值');
  console.log('  • 性能优化索引已创建');
  console.log('\n💡 提示:');
  console.log('  • 现有用户的姓名默认为用户名，可在用户管理中修改');
  console.log('  • 现有客户和产品的创建者为 admin');
  console.log('  • 新创建的数据会自动记录创建者');
  console.log('  • 备份文件位置:', BACKUP_PATH);
  console.log('\n');
  
} catch (error: any) {
  console.error('\n❌ 升级失败:', error.message);
  console.log('🔄 正在回滚...');
  db.exec('ROLLBACK');
  
  // 恢复备份
  if (fs.existsSync(BACKUP_PATH)) {
    fs.copyFileSync(BACKUP_PATH, DB_PATH);
    console.log('✅ 已从备份恢复数据库');
  }
  
  process.exit(1);
} finally {
  db.close();
}
