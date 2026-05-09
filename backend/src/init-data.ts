import bcrypt from 'bcryptjs';
import db from './db.js';

async function initData() {
  try {
    // 检查是否已有用户
    const existingUser = await db.prepare('SELECT * FROM users WHERE username = ?').get('admin') as any;
    
    if (!existingUser) {
      console.log('初始化默认用户...');
      const passwordHash = bcrypt.hashSync('admin', 10);
      const created_at = new Date().toISOString().slice(0, 19).replace('T', ' ');
      
      // 创建管理员账号
      await db.prepare('INSERT INTO users (username, password_hash, role, created_at) VALUES (?, ?, ?, ?)').run('admin', passwordHash, 'admin', created_at);
      console.log('✓ 管理员账号创建成功: admin / admin');
      
      // 创建操作员账号
      const operatorHash = bcrypt.hashSync('operator', 10);
      await db.prepare('INSERT INTO users (username, password_hash, role, created_at) VALUES (?, ?, ?, ?)').run('operator', operatorHash, 'operator', created_at);
      console.log('✓ 操作员账号创建成功: operator / operator');
    } else {
      console.log('用户已存在，跳过初始化');
    }
    
    // 检查是否已有客户数据
    const existingCustomers = await db.prepare('SELECT COUNT(*) as count FROM customers').get() as any;
    
    if (existingCustomers.count === 0) {
      console.log('\n初始化测试数据...');
      const created_at = new Date().toISOString().slice(0, 19).replace('T', ' ');
      
      // 创建测试客户
      const customer1 = await db.prepare('INSERT INTO customers (name, expected_length, description, created_at) VALUES (?, ?, ?, ?)').run('客户A', 20, '测试客户A，二维码长度20', created_at);
      const customer2 = await db.prepare('INSERT INTO customers (name, expected_length, description, created_at) VALUES (?, ?, ?, ?)').run('客户B', 15, '测试客户B，二维码长度15', created_at);
      console.log('✓ 测试客户创建成功');
      
      // 创建测试产品
      await db.prepare('INSERT INTO products (model, customer_id, description, created_at) VALUES (?, ?, ?, ?)').run('产品A1', customer1.lastInsertRowid, '客户A的产品型号1', created_at);
      await db.prepare('INSERT INTO products (model, customer_id, description, created_at) VALUES (?, ?, ?, ?)').run('产品A2', customer1.lastInsertRowid, '客户A的产品型号2', created_at);
      await db.prepare('INSERT INTO products (model, customer_id, description, created_at) VALUES (?, ?, ?, ?)').run('产品B1', customer2.lastInsertRowid, '客户B的产品型号1', created_at);
      console.log('✓ 测试产品创建成功');
    } else {
      console.log('客户数据已存在，跳过初始化');
    }
    
    console.log('\n数据库初始化完成！');
    console.log('==========================================');
    console.log('管理员账号: admin / admin');
    console.log('操作员账号: operator / operator');
    console.log('==========================================\n');
    
    process.exit(0);
  } catch (error) {
    console.error('初始化失败:', error);
    process.exit(1);
  }
}

initData();
