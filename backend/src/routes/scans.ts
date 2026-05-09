import express from 'express';
import { getDb } from '../db';
import { ScanRecord, ScanRecordDetail } from '../types';
import { requireAuth, requireOperator, AuthRequest, canAccessCustomer } from '../middleware/auth';

const router = express.Router();

// 扫码录入
router.post('/', requireOperator, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const { customer_id, product_id, code_text, notes } = req.body;
    
    if (!customer_id || !product_id || !code_text) {
      return res.status(400).json({ error: '缺少必填字段' });
    }
    
    const db = getDb();
    
    // 检查客户
    const customer = db.prepare('SELECT expected_length FROM customers WHERE id = ?').get(customer_id) as any;
    if (!customer) {
      return res.status(400).json({ error: '客户不存在' });
    }
    
    // 检查产品
    const product = db.prepare('SELECT * FROM products WHERE id = ? AND customer_id = ?').get(product_id, customer_id) as any;
    if (!product) {
      return res.status(400).json({ error: '产品不存在或不属于该客户' });
    }
    
    // 权限检查（基于产品授权，不限制客户）
    if (user.role === 'super_admin') {
      // super_admin 可以扫所有产品
    } else if (user.role === 'customer_admin') {
      // customer_admin 可以扫有权限的产品
      // 1. 检查产品是否属于自己的默认客户
      if (user.customer_id && product.customer_id === user.customer_id) {
        // 允许扫描默认客户的产品
      }
      // 2. 检查产品的客户是否是自己创建的
      else {
        const productCustomer = db.prepare('SELECT created_by FROM customers WHERE id = ?').get(product.customer_id) as any;
        if (productCustomer && productCustomer.created_by === user.id) {
          // 允许扫描自己创建的客户的产品
        }
        // 3. 检查是否有明确的产品授权
        else {
          const permission = db.prepare(`
            SELECT * FROM user_product_permissions
            WHERE user_id = ? AND product_id = ? AND can_scan = 1
          `).get(user.id, product_id);
          
          if (!permission) {
            return res.status(403).json({ error: '无权扫描此产品，请联系管理员授权' });
          }
        }
      }
    } else if (user.role === 'operator') {
      // operator 需要检查是否有扫码权限（可以跨客户）
      const permission = db.prepare(`
        SELECT * FROM user_product_permissions
        WHERE user_id = ? AND product_id = ? AND can_scan = 1
      `).get(user.id, product_id);
      
      if (!permission) {
        return res.status(403).json({ error: '无权扫描此产品，请联系管理员授权' });
      }
    } else {
      return res.status(403).json({ error: '无扫码权限' });
    }
    
    // 验证条码长度
    const code_length = code_text.length;
    let is_valid = 1;
    let error_reason = '';
    
    if (code_length < customer.expected_length) {
      is_valid = 0;
      error_reason = '长度不足';
    } else if (code_length > customer.expected_length) {
      is_valid = 0;
      error_reason = '长度超出';
    }
    
    // 插入扫码记录
    const result = db.prepare(`
      INSERT INTO scans (customer_id, product_id, user_id, code_text, code_length, is_valid, error_reason, notes, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
    `).run(customer_id, product_id, user.id, code_text, code_length, is_valid, error_reason, notes || null);
    
    // 记录审计日志
    db.prepare(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES (?, 'scan', 'scan', ?, ?, datetime('now'))
    `).run(user.id, result.lastInsertRowid, JSON.stringify({ product_id, is_valid }));
    
    res.json({ 
      id: result.lastInsertRowid, 
      is_valid: !!is_valid, 
      error_reason 
    });
  } catch (error: any) {
    res.status(500).json({ error: '保存失败: ' + error.message });
  }
});

// 查询扫码记录（按权限过滤）
router.get('/', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const { customer_id, product_id, user_id, start_time, end_time, is_valid } = req.query;
    const db = getDb();
    
    let query = `
      SELECT s.*, 
             c.name as customer_name, 
             p.model as product_model,
             u.username,
             u.display_name,
             u.role as user_role
      FROM scans s
      JOIN customers c ON s.customer_id = c.id
      JOIN products p ON s.product_id = p.id
      LEFT JOIN users u ON s.user_id = u.id
      WHERE 1=1
    `;
    const params: any[] = [];
    
    // 根据角色过滤数据
    if (user.role === 'super_admin') {
      // super_admin 可以看所有记录
    } else if (user.role === 'customer_admin') {
      // customer_admin 可以看自己创建的客户的产品记录 + 有权限的产品记录
      query += ` AND (
        s.customer_id IN (SELECT id FROM customers WHERE created_by = ?)
        OR s.product_id IN (SELECT product_id FROM user_product_permissions WHERE user_id = ? AND can_view = 1)
      )`;
      params.push(user.id, user.id);
    } else if (user.role === 'operator') {
      // operator 只能看自己扫的记录
      query += ' AND s.user_id = ?';
      params.push(user.id);
    } else if (user.role === 'viewer') {
      // viewer 只能看授权产品的记录
      query += ` AND s.product_id IN (
        SELECT product_id FROM user_product_permissions
        WHERE user_id = ? AND can_view = 1
      )`;
      params.push(user.id);
    }
    
    // 额外的查询条件
    if (customer_id) {
      // 检查权限
      if (user.role !== 'super_admin') {
        if (user.role === 'customer_admin') {
          // 客户管理员：检查是否是自己创建的客户 或 有该客户的产品权限
          const customer = db.prepare('SELECT created_by FROM customers WHERE id = ?').get(customer_id) as any;
          const hasPermission = db.prepare(`
            SELECT COUNT(*) as count
            FROM user_product_permissions upp
            JOIN products p ON upp.product_id = p.id
            WHERE upp.user_id = ? AND p.customer_id = ? AND upp.can_view = 1
          `).get(user.id, customer_id) as any;
          
          if (customer && customer.created_by !== user.id && hasPermission.count === 0) {
            return res.status(403).json({ error: '无权查询此客户的记录' });
          }
        } else {
          // 其他角色：检查是否有该客户的产品权限
          const hasPermission = db.prepare(`
            SELECT COUNT(*) as count
            FROM user_product_permissions upp
            JOIN products p ON upp.product_id = p.id
            WHERE upp.user_id = ? AND p.customer_id = ? AND upp.can_view = 1
          `).get(user.id, customer_id) as any;
          
          if (hasPermission.count === 0) {
            return res.status(403).json({ error: '无权查询此客户的记录' });
          }
        }
      }
      query += ' AND s.customer_id = ?';
      params.push(customer_id);
    }
    
    if (product_id) {
      query += ' AND s.product_id = ?';
      params.push(product_id);
    }
    
    if (user_id) {
      query += ' AND s.user_id = ?';
      params.push(user_id);
    }
    
    if (is_valid !== undefined) {
      query += ' AND s.is_valid = ?';
      params.push(is_valid === 'true' || is_valid === '1' ? 1 : 0);
    }
    
    if (start_time) {
      query += ' AND s.created_at >= ?';
      params.push(start_time);
    }
    
    if (end_time) {
      query += ' AND s.created_at <= ?';
      params.push(end_time);
    }
    
    query += ' ORDER BY s.created_at DESC LIMIT 1000';
    
    const scans = db.prepare(query).all(...params) as ScanRecordDetail[];
    res.json(scans);
  } catch (error: any) {
    res.status(500).json({ error: '查询失败: ' + error.message });
  }
});

// 获取扫码统计
router.get('/stats', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const { customer_id, product_id, start_time, end_time } = req.query;
    const db = getDb();
    
    let query = `
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN is_valid = 1 THEN 1 ELSE 0 END) as valid_count,
        SUM(CASE WHEN is_valid = 0 THEN 1 ELSE 0 END) as invalid_count
      FROM scans
      WHERE 1=1
    `;
    const params: any[] = [];
    
    // 根据角色过滤数据
    if (user.role === 'super_admin') {
      // super_admin 可以看所有统计
    } else if (user.role === 'customer_admin') {
      query += ' AND customer_id = ?';
      params.push(user.customer_id);
    } else if (user.role === 'operator') {
      query += ' AND user_id = ?';
      params.push(user.id);
    } else if (user.role === 'viewer') {
      query += ` AND product_id IN (
        SELECT product_id FROM user_product_permissions
        WHERE user_id = ? AND can_view = 1
      )`;
      params.push(user.id);
    }
    
    if (customer_id) {
      query += ' AND customer_id = ?';
      params.push(customer_id);
    }
    
    if (product_id) {
      query += ' AND product_id = ?';
      params.push(product_id);
    }
    
    if (start_time) {
      query += ' AND created_at >= ?';
      params.push(start_time);
    }
    
    if (end_time) {
      query += ' AND created_at <= ?';
      params.push(end_time);
    }
    
    const stats = db.prepare(query).get(...params) as any;
    res.json(stats);
  } catch (error: any) {
    res.status(500).json({ error: '统计失败: ' + error.message });
  }
});

// 删除单条扫码记录（超级管理员）
router.delete('/:id', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const scanId = parseInt(req.params.id);
    
    if (user.role !== 'super_admin') {
      return res.status(403).json({ error: '只有超级管理员可以删除扫码记录' });
    }
    
    const db = getDb();
    
    // 检查记录是否存在
    const scan = db.prepare('SELECT * FROM scans WHERE id = ?').get(scanId);
    if (!scan) {
      return res.status(404).json({ error: '扫码记录不存在' });
    }
    
    // 删除记录
    db.prepare('DELETE FROM scans WHERE id = ?').run(scanId);
    
    // 记录审计日志
    db.prepare(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES (?, 'delete', 'scan', ?, ?, datetime('now'))
    `).run(user.id, scanId, JSON.stringify({ scan_id: scanId }));
    
    res.json({ message: '删除成功' });
  } catch (error: any) {
    res.status(500).json({ error: '删除失败: ' + error.message });
  }
});

// 批量删除错误扫码记录（超级管理员）
router.post('/batch-delete-invalid', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    
    if (user.role !== 'super_admin') {
      return res.status(403).json({ error: '只有超级管理员可以批量删除记录' });
    }
    
    const { customer_id, product_id, start_time, end_time } = req.body;
    
    const db = getDb();
    
    let query = 'DELETE FROM scans WHERE is_valid = 0';
    const params: any[] = [];
    
    if (customer_id) {
      query += ' AND customer_id = ?';
      params.push(customer_id);
    }
    
    if (product_id) {
      query += ' AND product_id = ?';
      params.push(product_id);
    }
    
    if (start_time) {
      query += ' AND created_at >= ?';
      params.push(start_time);
    }
    
    if (end_time) {
      query += ' AND created_at <= ?';
      params.push(end_time);
    }
    
    const result = db.prepare(query).run(...params);
    
    // 记录审计日志
    db.prepare(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES (?, 'batch_delete_invalid_scans', 'scan', NULL, ?, datetime('now'))
    `).run(user.id, JSON.stringify({ 
      deleted_count: result.changes,
      filters: { customer_id, product_id, start_time, end_time }
    }));
    
    res.json({ 
      message: `成功删除 ${result.changes} 条错误记录`,
      deleted_count: result.changes 
    });
  } catch (error: any) {
    res.status(500).json({ error: '批量删除失败: ' + error.message });
  }
});

// 清理测试数据（超级管理员）
router.post('/cleanup-test-data', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    
    if (user.role !== 'super_admin') {
      return res.status(403).json({ error: '只有超级管理员可以清理测试数据' });
    }
    
    const db = getDb();
    
    // 开启事务
    db.exec('BEGIN TRANSACTION');
    
    try {
      // 统计要删除的数据
      const testCustomers = db.prepare(`
        SELECT id FROM customers 
        WHERE name LIKE '%测试%' OR name LIKE '%test%' OR description LIKE '%测试%'
      `).all() as any[];
      
      const testProducts = db.prepare(`
        SELECT id FROM products 
        WHERE model LIKE '%测试%' OR model LIKE '%test%' OR description LIKE '%测试%'
      `).all() as any[];
      
      const testUsers = db.prepare(`
        SELECT id FROM users 
        WHERE (username LIKE '%test%' OR display_name LIKE '%测试%') AND id != 1
      `).all() as any[]; // 不删除 admin (id=1)
      
      let deletedScans = 0;
      let deletedProducts = 0;
      let deletedCustomers = 0;
      let deletedUsers = 0;
      let deletedPermissions = 0;
      let deletedAuditLogs = 0;
      
      // 1. 删除测试客户的所有扫码记录
      for (const customer of testCustomers) {
        const result = db.prepare('DELETE FROM scans WHERE customer_id = ?').run(customer.id);
        deletedScans += result.changes;
      }
      
      // 2. 删除测试产品的所有扫码记录
      for (const product of testProducts) {
        const result = db.prepare('DELETE FROM scans WHERE product_id = ?').run(product.id);
        deletedScans += result.changes;
      }
      
      // 3. 删除测试用户的所有扫码记录
      for (const testUser of testUsers) {
        const result = db.prepare('DELETE FROM scans WHERE user_id = ?').run(testUser.id);
        deletedScans += result.changes;
      }
      
      // 4. 删除测试产品的权限
      for (const product of testProducts) {
        const result = db.prepare('DELETE FROM user_product_permissions WHERE product_id = ?').run(product.id);
        deletedPermissions += result.changes;
      }
      
      // 5. 删除测试用户的权限
      for (const testUser of testUsers) {
        const result = db.prepare('DELETE FROM user_product_permissions WHERE user_id = ?').run(testUser.id);
        deletedPermissions += result.changes;
      }
      
      // 6. 删除测试客户的所有产品
      for (const customer of testCustomers) {
        const customerProducts = db.prepare('SELECT id FROM products WHERE customer_id = ?').all(customer.id) as any[];
        for (const product of customerProducts) {
          // 删除产品权限
          db.prepare('DELETE FROM user_product_permissions WHERE product_id = ?').run(product.id);
          // 删除产品
          db.prepare('DELETE FROM products WHERE id = ?').run(product.id);
          deletedProducts++;
        }
      }
      
      // 7. 删除测试产品
      for (const product of testProducts) {
        db.prepare('DELETE FROM products WHERE id = ?').run(product.id);
        deletedProducts++;
      }
      
      // 8. 删除测试客户
      for (const customer of testCustomers) {
        db.prepare('DELETE FROM customers WHERE id = ?').run(customer.id);
        deletedCustomers++;
      }
      
      // 9. 删除测试用户的审计日志
      for (const testUser of testUsers) {
        const result = db.prepare('DELETE FROM audit_logs WHERE user_id = ?').run(testUser.id);
        deletedAuditLogs += result.changes;
      }
      
      // 10. 将其他用户引用测试用户的 customer_id 设为 NULL
      for (const testUser of testUsers) {
        db.prepare('UPDATE users SET customer_id = NULL WHERE customer_id IN (SELECT id FROM customers WHERE created_by = ?)').run(testUser.id);
      }
      
      // 11. 删除测试用户
      for (const testUser of testUsers) {
        db.prepare('DELETE FROM users WHERE id = ?').run(testUser.id);
        deletedUsers++;
      }
      
      // 提交事务
      db.exec('COMMIT');
      
      // 记录审计日志
      db.prepare(`
        INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
        VALUES (?, 'cleanup_test_data', 'system', NULL, ?, datetime('now'))
      `).run(user.id, JSON.stringify({ 
        deleted_scans: deletedScans,
        deleted_products: deletedProducts,
        deleted_customers: deletedCustomers,
        deleted_users: deletedUsers,
        deleted_permissions: deletedPermissions,
        deleted_audit_logs: deletedAuditLogs
      }));
      
      res.json({ 
        message: '测试数据清理完成',
        deleted_scans: deletedScans,
        deleted_products: deletedProducts,
        deleted_customers: deletedCustomers,
        deleted_users: deletedUsers,
        deleted_permissions: deletedPermissions,
        deleted_audit_logs: deletedAuditLogs
      });
    } catch (error) {
      // 回滚事务
      db.exec('ROLLBACK');
      throw error;
    }
  } catch (error: any) {
    res.status(500).json({ error: '清理失败: ' + error.message });
  }
});

// 初始化系统（超级管理员）
router.post('/initialize-system', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    
    if (user.role !== 'super_admin') {
      return res.status(403).json({ error: '只有超级管理员可以初始化系统' });
    }
    
    const db = getDb();
    
    // 开启事务
    db.exec('BEGIN TRANSACTION');
    
    try {
      // 统计要删除的数据
      const allCustomers = db.prepare('SELECT COUNT(*) as count FROM customers').get() as any;
      const allProducts = db.prepare('SELECT COUNT(*) as count FROM products').get() as any;
      const allUsers = db.prepare('SELECT COUNT(*) as count FROM users WHERE id != 1').get() as any; // 不包括 admin
      const allScans = db.prepare('SELECT COUNT(*) as count FROM scans').get() as any;
      const allPermissions = db.prepare('SELECT COUNT(*) as count FROM user_product_permissions').get() as any;
      const allAuditLogs = db.prepare('SELECT COUNT(*) as count FROM audit_logs').get() as any;
      
      // 1. 删除所有扫码记录
      db.prepare('DELETE FROM scans').run();
      
      // 2. 删除所有权限记录
      db.prepare('DELETE FROM user_product_permissions').run();
      
      // 3. 将所有用户的 customer_id 设为 NULL（先解除对客户的引用）
      db.prepare('UPDATE users SET customer_id = NULL').run();
      
      // 4. 将所有产品的 created_by 设为 NULL
      db.prepare('UPDATE products SET created_by = NULL').run();
      
      // 5. 删除所有产品
      db.prepare('DELETE FROM products').run();
      
      // 6. 将所有客户的 created_by 设为 NULL
      db.prepare('UPDATE customers SET created_by = NULL').run();
      
      // 7. 删除所有客户
      db.prepare('DELETE FROM customers').run();
      
      // 8. 删除所有审计日志
      db.prepare('DELETE FROM audit_logs').run();
      
      // 9. 将所有用户的 created_by 设为 NULL
      db.prepare('UPDATE users SET created_by = NULL').run();
      
      // 10. 删除除 admin 外的所有用户
      db.prepare('DELETE FROM users WHERE id != 1').run();
      
      // 11. 重置 admin 的状态
      db.prepare(`
        UPDATE users 
        SET is_active = 1, 
            last_login = NULL,
            customer_id = NULL,
            created_by = NULL
        WHERE id = 1
      `).run();
      
      // 提交事务
      db.exec('COMMIT');
      
      // 记录审计日志
      db.prepare(`
        INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
        VALUES (?, 'initialize_system', 'system', NULL, ?, datetime('now'))
      `).run(user.id, JSON.stringify({ 
        deleted_scans: allScans.count,
        deleted_products: allProducts.count,
        deleted_customers: allCustomers.count,
        deleted_users: allUsers.count,
        deleted_permissions: allPermissions.count,
        deleted_audit_logs: allAuditLogs.count
      }));
      
      res.json({ 
        message: '系统初始化完成',
        deleted_scans: allScans.count,
        deleted_products: allProducts.count,
        deleted_customers: allCustomers.count,
        deleted_users: allUsers.count,
        deleted_permissions: allPermissions.count,
        deleted_audit_logs: allAuditLogs.count
      });
    } catch (error) {
      // 回滚事务
      db.exec('ROLLBACK');
      throw error;
    }
  } catch (error: any) {
    res.status(500).json({ error: '初始化失败: ' + error.message });
  }
});

export default router;
