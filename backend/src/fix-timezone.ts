import Database from 'better-sqlite3';
import * as path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const DB_PATH = path.join(__dirname, '../../db.sqlite');

console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log('🕐 修复时区问题 - 将 UTC 时间转换为本地时间（UTC+8）');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

const db = new Database(DB_PATH);
db.pragma('foreign_keys = ON');

try {
  console.log('\n📊 统计需要修复的数据...');
  
  // 统计各表的记录数
  const scansCount = db.prepare('SELECT COUNT(*) as count FROM scans').get() as { count: number };
  const usersCount = db.prepare('SELECT COUNT(*) as count FROM users').get() as { count: number };
  const customersCount = db.prepare('SELECT COUNT(*) as count FROM customers').get() as { count: number };
  const productsCount = db.prepare('SELECT COUNT(*) as count FROM products').get() as { count: number };
  const permissionsCount = db.prepare('SELECT COUNT(*) as count FROM user_product_permissions').get() as { count: number };
  const auditLogsCount = db.prepare('SELECT COUNT(*) as count FROM audit_logs').get() as { count: number };
  
  console.log(`  扫码记录: ${scansCount.count} 条`);
  console.log(`  用户: ${usersCount.count} 个`);
  console.log(`  客户: ${customersCount.count} 个`);
  console.log(`  产品: ${productsCount.count} 个`);
  console.log(`  权限: ${permissionsCount.count} 条`);
  console.log(`  审计日志: ${auditLogsCount.count} 条`);
  
  console.log('\n⚠️  警告：此操作将修改所有时间戳，将 UTC 时间转换为 UTC+8');
  console.log('   如果数据已经是本地时间，请不要运行此脚本！');
  console.log('');
  
  // 开启事务
  db.exec('BEGIN TRANSACTION');
  
  try {
    console.log('\n🔄 开始修复时间戳...');
    
    // 1. 修复扫码记录时间
    console.log('\n  1. 修复扫码记录时间...');
    db.prepare(`
      UPDATE scans 
      SET created_at = datetime(created_at, '+8 hours')
      WHERE created_at IS NOT NULL
    `).run();
    console.log(`     ✓ 已修复 ${scansCount.count} 条扫码记录`);
    
    // 2. 修复用户时间
    console.log('\n  2. 修复用户时间...');
    db.prepare(`
      UPDATE users 
      SET created_at = datetime(created_at, '+8 hours')
      WHERE created_at IS NOT NULL
    `).run();
    db.prepare(`
      UPDATE users 
      SET last_login = datetime(last_login, '+8 hours')
      WHERE last_login IS NOT NULL
    `).run();
    console.log(`     ✓ 已修复 ${usersCount.count} 个用户的时间`);
    
    // 3. 修复客户时间
    console.log('\n  3. 修复客户时间...');
    db.prepare(`
      UPDATE customers 
      SET created_at = datetime(created_at, '+8 hours')
      WHERE created_at IS NOT NULL
    `).run();
    console.log(`     ✓ 已修复 ${customersCount.count} 个客户的时间`);
    
    // 4. 修复产品时间
    console.log('\n  4. 修复产品时间...');
    db.prepare(`
      UPDATE products 
      SET created_at = datetime(created_at, '+8 hours')
      WHERE created_at IS NOT NULL
    `).run();
    console.log(`     ✓ 已修复 ${productsCount.count} 个产品的时间`);
    
    // 5. 修复权限时间
    console.log('\n  5. 修复权限时间...');
    db.prepare(`
      UPDATE user_product_permissions 
      SET created_at = datetime(created_at, '+8 hours')
      WHERE created_at IS NOT NULL
    `).run();
    console.log(`     ✓ 已修复 ${permissionsCount.count} 条权限的时间`);
    
    // 6. 修复审计日志时间
    console.log('\n  6. 修复审计日志时间...');
    db.prepare(`
      UPDATE audit_logs 
      SET created_at = datetime(created_at, '+8 hours')
      WHERE created_at IS NOT NULL
    `).run();
    console.log(`     ✓ 已修复 ${auditLogsCount.count} 条审计日志的时间`);
    
    // 提交事务
    db.exec('COMMIT');
    
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('✅ 时区修复完成！');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // 显示示例数据
    console.log('\n📋 验证修复结果（最近 5 条扫码记录）:');
    const recentScans = db.prepare(`
      SELECT id, code_text, created_at 
      FROM scans 
      ORDER BY id DESC 
      LIMIT 5
    `).all();
    
    if (recentScans.length > 0) {
      console.log('\n  ID  | 二维码 | 时间');
      console.log('  ----+--------+---------------------');
      recentScans.forEach((scan: any) => {
        console.log(`  ${scan.id.toString().padEnd(4)}| ${scan.code_text.substring(0, 6).padEnd(7)}| ${scan.created_at}`);
      });
    } else {
      console.log('  暂无扫码记录');
    }
    
    console.log('\n💡 提示：');
    console.log('  - 所有时间戳已从 UTC 转换为 UTC+8（北京时间）');
    console.log('  - 新创建的数据会自动使用本地时间');
    console.log('  - 如果时间仍然不对，请检查服务器系统时区设置');
    console.log('');
    
  } catch (error) {
    // 回滚事务
    db.exec('ROLLBACK');
    throw error;
  }
  
} catch (error: any) {
  console.error('\n❌ 修复失败:', error.message);
  console.error(error.stack);
  process.exit(1);
} finally {
  db.close();
}
