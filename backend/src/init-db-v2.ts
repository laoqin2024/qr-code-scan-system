import Database from 'better-sqlite3';
import bcrypt from 'bcryptjs';
import * as path from 'path';
import * as fs from 'fs';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const DB_PATH = path.join(__dirname, '../../db.sqlite');

console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log('🎬 初始化权限管理系统数据库');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

// 读取 schema
const schemaPath = path.join(__dirname, 'schema-v2.sql');
const schema = fs.readFileSync(schemaPath, 'utf-8');

const db = new Database(DB_PATH);
db.pragma('foreign_keys = ON');

try {
  console.log('\n📝 创建数据库表结构...');
  db.exec(schema);
  console.log('✅ 表结构创建完成');
  
  // 检查是否已有数据
  const existingUsers = db.prepare('SELECT COUNT(*) as count FROM users').get() as { count: number };
  
  if (existingUsers.count > 0) {
    console.log('\n⚠️  数据库已包含数据，跳过初始化');
    console.log(`   当前用户数: ${existingUsers.count}`);
    console.log('\n💡 如需重新初始化，请先删除数据库文件: rm db.sqlite');
    process.exit(0);
  }
  
  console.log('\n👤 创建初始用户...');
  
  // 创建超级管理员
  const adminPassword = await bcrypt.hash('admin123', 10);
  db.prepare(`
    INSERT INTO users (username, password_hash, role, is_active, created_at, display_name)
    VALUES (?, ?, 'super_admin', 1, datetime('now'), ?)
  `).run('admin', adminPassword, '系统管理员');
  console.log('  ✓ 超级管理员: admin / admin123');
  
  // 创建测试客户管理员（不绑定客户）
  const testPassword = await bcrypt.hash('test123', 10);
  db.prepare(`
    INSERT INTO users (username, password_hash, role, is_active, created_at, display_name)
    VALUES (?, ?, 'customer_admin', 1, datetime('now'), ?)
  `).run('test', testPassword, '测试管理员');
  console.log('  ✓ 客户管理员: test / test123 (测试账号)');
  
  // 创建示例客户
  console.log('\n🏢 创建示例数据...');
  const customer1 = db.prepare(`
    INSERT INTO customers (name, expected_length, description, created_at)
    VALUES (?, ?, ?, datetime('now'))
  `).run('富士康', 20, '电子产品制造');
  console.log('  ✓ 客户: 富士康');
  
  const customer2 = db.prepare(`
    INSERT INTO customers (name, expected_length, description, created_at)
    VALUES (?, ?, ?, datetime('now'))
  `).run('比亚迪', 18, '新能源汽车');
  console.log('  ✓ 客户: 比亚迪');
  
  // 创建客户管理员
  const customerAdminPassword = await bcrypt.hash('manager123', 10);
  const customerAdmin1 = db.prepare(`
    INSERT INTO users (username, password_hash, role, customer_id, is_active, created_at)
    VALUES (?, ?, 'customer_admin', ?, 1, datetime('now'))
  `).run('foxconn_manager', customerAdminPassword, customer1.lastInsertRowid);
  console.log('  ✓ 客户管理员: foxconn_manager / manager123 (富士康)');
  
  const customerAdmin2 = db.prepare(`
    INSERT INTO users (username, password_hash, role, customer_id, is_active, created_at)
    VALUES (?, ?, 'customer_admin', ?, 1, datetime('now'))
  `).run('byd_manager', customerAdminPassword, customer2.lastInsertRowid);
  console.log('  ✓ 客户管理员: byd_manager / manager123 (比亚迪)');
  
  // 创建产品
  const product1 = db.prepare(`
    INSERT INTO products (model, customer_id, description, created_at)
    VALUES (?, ?, ?, datetime('now'))
  `).run('iPhone 15 Pro', customer1.lastInsertRowid, '苹果手机');
  console.log('  ✓ 产品: iPhone 15 Pro');
  
  const product2 = db.prepare(`
    INSERT INTO products (model, customer_id, description, created_at)
    VALUES (?, ?, ?, datetime('now'))
  `).run('iPad Air', customer1.lastInsertRowid, '苹果平板');
  console.log('  ✓ 产品: iPad Air');
  
  const product3 = db.prepare(`
    INSERT INTO products (model, customer_id, description, created_at)
    VALUES (?, ?, ?, datetime('now'))
  `).run('海豹电池模组', customer2.lastInsertRowid, '动力电池');
  console.log('  ✓ 产品: 海豹电池模组');
  
  // 创建操作员
  const operatorPassword = await bcrypt.hash('operator123', 10);
  const operator1 = db.prepare(`
    INSERT INTO users (username, password_hash, role, customer_id, is_active, created_at)
    VALUES (?, ?, 'operator', ?, 1, datetime('now'))
  `).run('operator_zhang', operatorPassword, customer1.lastInsertRowid);
  console.log('  ✓ 操作员: operator_zhang / operator123 (富士康)');
  
  const operator2 = db.prepare(`
    INSERT INTO users (username, password_hash, role, customer_id, is_active, created_at)
    VALUES (?, ?, 'operator', ?, 1, datetime('now'))
  `).run('operator_li', operatorPassword, customer2.lastInsertRowid);
  console.log('  ✓ 操作员: operator_li / operator123 (比亚迪)');
  
  // 授权操作员
  console.log('\n🔑 配置权限...');
  db.prepare(`
    INSERT INTO user_product_permissions (user_id, product_id, can_scan, can_view, created_at)
    VALUES (?, ?, 1, 1, datetime('now'))
  `).run(operator1.lastInsertRowid, product1.lastInsertRowid);
  console.log('  ✓ operator_zhang 可以扫描 iPhone 15 Pro');
  
  db.prepare(`
    INSERT INTO user_product_permissions (user_id, product_id, can_scan, can_view, created_at)
    VALUES (?, ?, 1, 1, datetime('now'))
  `).run(operator1.lastInsertRowid, product2.lastInsertRowid);
  console.log('  ✓ operator_zhang 可以扫描 iPad Air');
  
  db.prepare(`
    INSERT INTO user_product_permissions (user_id, product_id, can_scan, can_view, created_at)
    VALUES (?, ?, 1, 1, datetime('now'))
  `).run(operator2.lastInsertRowid, product3.lastInsertRowid);
  console.log('  ✓ operator_li 可以扫描 海豹电池模组');
  
  // 创建查看者
  const viewerPassword = await bcrypt.hash('viewer123', 10);
  const viewer1 = db.prepare(`
    INSERT INTO users (username, password_hash, role, customer_id, is_active, created_at)
    VALUES (?, ?, 'viewer', ?, 1, datetime('now'))
  `).run('viewer_wang', viewerPassword, customer1.lastInsertRowid);
  console.log('  ✓ 查看者: viewer_wang / viewer123 (富士康)');
  
  db.prepare(`
    INSERT INTO user_product_permissions (user_id, product_id, can_scan, can_view, created_at)
    VALUES (?, ?, 0, 1, datetime('now'))
  `).run(viewer1.lastInsertRowid, product1.lastInsertRowid);
  console.log('  ✓ viewer_wang 可以查看 iPhone 15 Pro 记录');
  
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('✅ 数据库初始化完成！');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('\n📋 测试账号:');
  console.log('\n  超级管理员:');
  console.log('    用户名: admin');
  console.log('    密码: admin123');
  console.log('    权限: 全局管理');
  console.log('\n  客户管理员 (测试账号):');
  console.log('    用户名: test');
  console.log('    密码: test123');
  console.log('    权限: 可创建客户、产品、用户');
  console.log('\n  客户管理员 (富士康):');
  console.log('    用户名: foxconn_manager');
  console.log('    密码: manager123');
  console.log('    权限: 管理富士康的产品和操作员');
  console.log('\n  客户管理员 (比亚迪):');
  console.log('    用户名: byd_manager');
  console.log('    密码: manager123');
  console.log('    权限: 管理比亚迪的产品和操作员');
  console.log('\n  操作员 (富士康):');
  console.log('    用户名: operator_zhang');
  console.log('    密码: operator123');
  console.log('    权限: 扫描 iPhone 15 Pro 和 iPad Air');
  console.log('\n  操作员 (比亚迪):');
  console.log('    用户名: operator_li');
  console.log('    密码: operator123');
  console.log('    权限: 扫描 海豹电池模组');
  console.log('\n  查看者 (富士康):');
  console.log('    用户名: viewer_wang');
  console.log('    密码: viewer123');
  console.log('    权限: 查看 iPhone 15 Pro 记录');
  console.log('\n💡 提示: 请在生产环境中修改默认密码！');
  console.log('\n');
  
} catch (error: any) {
  console.error('\n❌ 初始化失败:', error.message);
  console.error(error.stack);
  process.exit(1);
} finally {
  db.close();
}
