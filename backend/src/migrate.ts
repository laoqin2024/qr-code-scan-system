import Database from 'better-sqlite3';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const DB_PATH = path.join(__dirname, '../../db.sqlite');
const BACKUP_PATH = path.join(__dirname, '../../db.sqlite.backup');

console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log('🔄 开始数据库迁移到权限管理系统 v2');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

// 1. 备份现有数据库
console.log('📦 备份现有数据库...');
if (fs.existsSync(DB_PATH)) {
  fs.copyFileSync(DB_PATH, BACKUP_PATH);
  console.log('✅ 数据库已备份到:', BACKUP_PATH);
} else {
  console.log('⚠️  数据库文件不存在，将创建新数据库');
}

const db = new Database(DB_PATH);
db.pragma('foreign_keys = ON');

try {
  // 2. 检查是否需要迁移
  console.log('\n🔍 检查数据库结构...');
  
  const tables = db.prepare("SELECT name FROM sqlite_master WHERE type='table'").all() as any[];
  const tableNames = tables.map(t => t.name);
  
  const needsMigration = !tableNames.includes('user_product_permissions') || 
                         !tableNames.includes('audit_logs');
  
  if (!needsMigration) {
    console.log('✅ 数据库已是最新版本，无需迁移');
    process.exit(0);
  }
  
  console.log('📝 需要迁移，开始执行...\n');
  
  // 3. 开始事务
  db.exec('BEGIN TRANSACTION');
  
  // 4. 添加新字段到 users 表
  console.log('🔧 升级 users 表...');
  try {
    db.exec('ALTER TABLE users ADD COLUMN customer_id INTEGER REFERENCES customers(id)');
    console.log('  ✓ 添加 customer_id 字段');
  } catch (e: any) {
    if (!e.message.includes('duplicate column')) throw e;
    console.log('  - customer_id 字段已存在');
  }
  
  try {
    db.exec('ALTER TABLE users ADD COLUMN is_active INTEGER DEFAULT 1');
    console.log('  ✓ 添加 is_active 字段');
  } catch (e: any) {
    if (!e.message.includes('duplicate column')) throw e;
    console.log('  - is_active 字段已存在');
  }
  
  try {
    db.exec('ALTER TABLE users ADD COLUMN last_login TEXT');
    console.log('  ✓ 添加 last_login 字段');
  } catch (e: any) {
    if (!e.message.includes('duplicate column')) throw e;
    console.log('  - last_login 字段已存在');
  }
  
  // 5. 更新 users 表的角色约束（需要重建表）
  console.log('\n🔧 更新用户角色系统...');
  const users = db.prepare('SELECT * FROM users').all();
  
  db.exec(`
    CREATE TABLE users_new (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL CHECK(role IN ('super_admin','customer_admin','operator','viewer')),
      customer_id INTEGER,
      is_active INTEGER DEFAULT 1,
      last_login TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY(customer_id) REFERENCES customers(id) ON DELETE CASCADE
    )
  `);
  
  // 迁移用户数据，将旧角色映射到新角色
  for (const user of users as any[]) {
    let newRole = user.role;
    if (user.role === 'admin') {
      newRole = 'super_admin';
    } else if (user.role === 'operator') {
      newRole = 'operator';
    }
    
    db.prepare(`
      INSERT INTO users_new (id, username, password_hash, role, customer_id, is_active, last_login, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      user.id,
      user.username,
      user.password_hash,
      newRole,
      user.customer_id || null,
      user.is_active !== undefined ? user.is_active : 1,
      user.last_login || null,
      user.created_at
    );
  }
  
  db.exec('DROP TABLE users');
  db.exec('ALTER TABLE users_new RENAME TO users');
  console.log('  ✓ 用户角色系统已更新');
  
  // 6. 添加 user_id 到 scans 表
  console.log('\n🔧 升级 scans 表...');
  try {
    db.exec('ALTER TABLE scans ADD COLUMN user_id INTEGER REFERENCES users(id)');
    console.log('  ✓ 添加 user_id 字段');
  } catch (e: any) {
    if (!e.message.includes('duplicate column')) throw e;
    console.log('  - user_id 字段已存在');
  }
  
  // 7. 创建 user_product_permissions 表
  console.log('\n🔧 创建权限管理表...');
  db.exec(`
    CREATE TABLE IF NOT EXISTS user_product_permissions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      can_scan INTEGER DEFAULT 1,
      can_view INTEGER DEFAULT 1,
      created_at TEXT NOT NULL,
      FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE,
      UNIQUE(user_id, product_id)
    )
  `);
  console.log('  ✓ user_product_permissions 表已创建');
  
  // 8. 创建 audit_logs 表
  console.log('\n🔧 创建审计日志表...');
  db.exec(`
    CREATE TABLE IF NOT EXISTS audit_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      action TEXT NOT NULL,
      resource_type TEXT NOT NULL,
      resource_id INTEGER,
      details TEXT,
      ip_address TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY(user_id) REFERENCES users(id)
    )
  `);
  console.log('  ✓ audit_logs 表已创建');
  
  // 9. 创建索引
  console.log('\n🔧 创建索引优化查询性能...');
  const indexes = [
    'CREATE INDEX IF NOT EXISTS idx_users_customer ON users(customer_id)',
    'CREATE INDEX IF NOT EXISTS idx_users_role ON users(role)',
    'CREATE INDEX IF NOT EXISTS idx_products_customer ON products(customer_id)',
    'CREATE INDEX IF NOT EXISTS idx_scans_user ON scans(user_id)',
    'CREATE INDEX IF NOT EXISTS idx_scans_product ON scans(product_id)',
    'CREATE INDEX IF NOT EXISTS idx_scans_created ON scans(created_at)',
    'CREATE INDEX IF NOT EXISTS idx_permissions_user ON user_product_permissions(user_id)',
    'CREATE INDEX IF NOT EXISTS idx_permissions_product ON user_product_permissions(product_id)',
    'CREATE INDEX IF NOT EXISTS idx_audit_user ON audit_logs(user_id)',
    'CREATE INDEX IF NOT EXISTS idx_audit_created ON audit_logs(created_at)'
  ];
  
  for (const indexSql of indexes) {
    db.exec(indexSql);
  }
  console.log('  ✓ 所有索引已创建');
  
  // 10. 提交事务
  db.exec('COMMIT');
  
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('✅ 数据库迁移成功完成！');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('\n📋 迁移摘要:');
  console.log('  • users 表已升级（新增角色和字段）');
  console.log('  • scans 表已升级（新增 user_id）');
  console.log('  • user_product_permissions 表已创建');
  console.log('  • audit_logs 表已创建');
  console.log('  • 性能优化索引已创建');
  console.log('\n💡 提示:');
  console.log('  • 旧的 admin 角色已自动转换为 super_admin');
  console.log('  • 所有用户默认为激活状态');
  console.log('  • 备份文件位置:', BACKUP_PATH);
  console.log('\n');
  
} catch (error: any) {
  console.error('\n❌ 迁移失败:', error.message);
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
