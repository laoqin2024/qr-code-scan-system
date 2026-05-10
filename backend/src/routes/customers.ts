import express from 'express';
import { getDb } from '../db';
import { Customer } from '../types';
import { requireAuth, requireCustomerAdmin, requireSuperAdmin, AuthRequest, canAccessCustomer } from '../middleware/auth';

const router = express.Router();

// 获取客户列表（按权限过滤）
router.get('/', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const db = getDb();
    
    let query = `
      SELECT c.*, 
             u.username as created_by_username,
             u.display_name as created_by_display_name,
             CASE WHEN c.created_by = ? OR ? = 'super_admin' THEN 1 ELSE 0 END as can_edit
      FROM customers c
      LEFT JOIN users u ON c.created_by = u.id
    `;
    const params: any[] = [user.id, user.role];
    
    // super_admin 可以看所有客户
    if (user.role === 'super_admin') {
      query += ' ORDER BY c.created_at DESC';
    }
    // customer_admin 可以看自己创建的客户 + 授权产品的客户
    else if (user.role === 'customer_admin') {
      query = `
        SELECT DISTINCT c.*,
               u.username as created_by_username,
               u.display_name as created_by_display_name,
               CASE WHEN c.created_by = ? THEN 1 ELSE 0 END as can_edit
        FROM customers c
        LEFT JOIN users u ON c.created_by = u.id
        LEFT JOIN products p ON c.id = p.customer_id
        LEFT JOIN user_product_permissions upp ON p.id = upp.product_id AND upp.user_id = ?
        WHERE c.created_by = ? OR upp.user_id = ?
        ORDER BY c.created_at DESC
      `;
      params.length = 0;
      params.push(user.id, user.id, user.id, user.id);
    }
    // operator/viewer 可以看到有权限产品的客户（用于筛选）
    else if (user.role === 'operator' || user.role === 'viewer') {
      query = `
        SELECT DISTINCT c.*,
               u.username as created_by_username,
               u.display_name as created_by_display_name,
               0 as can_edit
        FROM customers c
        LEFT JOIN users u ON c.created_by = u.id
        JOIN products p ON c.id = p.customer_id
        JOIN user_product_permissions upp ON p.id = upp.product_id
        WHERE upp.user_id = ?
        ORDER BY c.name
      `;
      params.length = 0;
      params.push(user.id);
    } else {
      return res.json([]);
    }
    
    const customers = db.prepare(query).all(...params) as Customer[];
    res.json(customers);
  } catch (error: any) {
    res.status(500).json({ error: '查询客户失败: ' + error.message });
  }
});

// 获取单个客户信息
router.get('/:id', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const customerId = parseInt(req.params.id);
    const db = getDb();
    
    // 权限检查
    if (!canAccessCustomer(user, customerId)) {
      return res.status(403).json({ error: '无权访问此客户' });
    }
    
    const customer = db.prepare('SELECT * FROM customers WHERE id = ?').get(customerId) as Customer | undefined;
    
    if (!customer) {
      return res.status(404).json({ error: '客户不存在' });
    }
    
    res.json(customer);
  } catch (error: any) {
    res.status(500).json({ error: '查询客户失败: ' + error.message });
  }
});

// 创建客户（管理员）
router.post('/', requireCustomerAdmin, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const { name, expected_length, description } = req.body;
    
    if (!name || !expected_length) {
      return res.status(400).json({ error: '缺少必填字段' });
    }
    
    const db = getDb();
    const result = db.prepare(`
      INSERT INTO customers (name, expected_length, description, created_by, created_at)
      VALUES (?, ?, ?, ?, datetime('now', 'localtime'))
    `).run(name, expected_length, description || null, user.id);
    
    // 记录审计日志
    db.prepare(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES (?, 'create', 'customer', ?, ?, datetime('now', 'localtime'))
    `).run(user.id, result.lastInsertRowid, JSON.stringify({ name, expected_length }));
    
    res.json({ id: result.lastInsertRowid });
  } catch (error: any) {
    res.status(500).json({ error: '新增客户失败: ' + error.message });
  }
});

// 更新客户（管理员）
router.put('/:id', requireCustomerAdmin, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const customerId = parseInt(req.params.id);
    const { name, expected_length, description } = req.body;
    const db = getDb();
    
    // 检查客户
    const customer = db.prepare('SELECT * FROM customers WHERE id = ?').get(customerId) as Customer | undefined;
    if (!customer) {
      return res.status(404).json({ error: '客户不存在' });
    }
    
    // 权限检查：只能编辑自己创建的客户
    if (user.role !== 'super_admin' && customer.created_by !== user.id) {
      return res.status(403).json({ error: '只能编辑自己创建的客户' });
    }
    
    const updates: string[] = [];
    const params: any[] = [];
    
    if (name) {
      updates.push('name = ?');
      params.push(name);
    }
    
    if (expected_length) {
      updates.push('expected_length = ?');
      params.push(expected_length);
    }
    
    if (description !== undefined) {
      updates.push('description = ?');
      params.push(description);
    }
    
    if (updates.length === 0) {
      return res.status(400).json({ error: '没有可更新的字段' });
    }
    
    params.push(customerId);
    db.prepare(`UPDATE customers SET ${updates.join(', ')} WHERE id = ?`).run(...params);
    
    // 记录审计日志
    db.prepare(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES (?, 'update', 'customer', ?, ?, datetime('now', 'localtime'))
    `).run(user.id, customerId, JSON.stringify(req.body));
    
    res.json({ success: true });
  } catch (error: any) {
    res.status(500).json({ error: '更新客户失败: ' + error.message });
  }
});

// 删除客户（管理员）
router.delete('/:id', requireCustomerAdmin, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const customerId = parseInt(req.params.id);
    const db = getDb();
    
    // 检查客户
    const customer = db.prepare('SELECT * FROM customers WHERE id = ?').get(customerId) as Customer | undefined;
    if (!customer) {
      return res.status(404).json({ error: '客户不存在' });
    }
    
    // 权限检查：只能删除自己创建的客户
    if (user.role !== 'super_admin' && customer.created_by !== user.id) {
      return res.status(403).json({ error: '只能删除自己创建的客户' });
    }
    
    // 检查是否有关联的用户
    const userCount = db.prepare('SELECT COUNT(*) as count FROM users WHERE customer_id = ?').get(customerId) as any;
    if (userCount.count > 0) {
      return res.status(400).json({ error: '该客户下还有用户，无法删除' });
    }
    
    db.prepare('DELETE FROM customers WHERE id = ?').run(customerId);
    
    // 记录审计日志
    db.prepare(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES (?, 'delete', 'customer', ?, ?, datetime('now', 'localtime'))
    `).run(user.id, customerId, JSON.stringify({ id: customerId }));
    
    res.json({ success: true });
  } catch (error: any) {
    res.status(500).json({ error: '删除客户失败: ' + error.message });
  }
});

export default router;
