import express from 'express';
import { getDb } from '../db';
import { Product, ProductDetail } from '../types';
import { requireAuth, requireCustomerAdmin, AuthRequest, canAccessCustomer } from '../middleware/auth';

const router = express.Router();

// 获取产品列表（按权限过滤）
router.get('/', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const db = getDb();
    
    let query = `
      SELECT p.*, c.name as customer_name,
             u.username as created_by_username,
             u.display_name as created_by_display_name,
             CASE WHEN p.created_by = ? OR ? = 'super_admin' THEN 1 ELSE 0 END as can_edit
      FROM products p
      JOIN customers c ON p.customer_id = c.id
      LEFT JOIN users u ON p.created_by = u.id
    `;
    const params: any[] = [user.id, user.role];
    
    // super_admin 可以看所有产品
    if (user.role === 'super_admin') {
      query += ' ORDER BY p.created_at DESC';
    }
    // customer_admin 可以看自己创建的客户的产品 + 授权的产品
    else if (user.role === 'customer_admin') {
      query = `
        SELECT DISTINCT p.*, c.name as customer_name,
               u.username as created_by_username,
               u.display_name as created_by_display_name,
               CASE WHEN p.created_by = ? THEN 1 ELSE 0 END as can_edit
        FROM products p
        JOIN customers c ON p.customer_id = c.id
        LEFT JOIN users u ON p.created_by = u.id
        LEFT JOIN user_product_permissions upp ON p.id = upp.product_id AND upp.user_id = ?
        WHERE p.customer_id IN (SELECT id FROM customers WHERE created_by = ?) OR upp.user_id = ?
        ORDER BY p.created_at DESC
      `;
      params.length = 0;
      params.push(user.id, user.id, user.id, user.id);
    }
    // operator/viewer 只能看授权的产品（可以跨客户）
    else if (user.role === 'operator' || user.role === 'viewer') {
      query = `
        SELECT p.*, c.name as customer_name,
               u.username as created_by_username,
               u.display_name as created_by_display_name,
               0 as can_edit
        FROM products p
        JOIN customers c ON p.customer_id = c.id
        LEFT JOIN users u ON p.created_by = u.id
        JOIN user_product_permissions upp ON p.id = upp.product_id
        WHERE upp.user_id = ?
        ORDER BY c.name, p.created_at DESC
      `;
      params.length = 0;
      params.push(user.id);
    } else {
      return res.json([]);
    }
    
    const products = db.prepare(query).all(...params) as ProductDetail[];
    res.json(products);
  } catch (error: any) {
    res.status(500).json({ error: '查询产品失败: ' + error.message });
  }
});

// 获取单个产品信息
router.get('/:id', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const productId = parseInt(req.params.id);
    const db = getDb();
    
    const product = db.prepare(`
      SELECT p.*, c.name as customer_name
      FROM products p
      JOIN customers c ON p.customer_id = c.id
      WHERE p.id = ?
    `).get(productId) as ProductDetail | undefined;
    
    if (!product) {
      return res.status(404).json({ error: '产品不存在' });
    }
    
    // 权限检查
    if (user.role === 'super_admin') {
      // super_admin 可以访问所有产品
    } else if (user.role === 'customer_admin') {
      if (product.customer_id !== user.customer_id) {
        return res.status(403).json({ error: '无权访问此产品' });
      }
    } else {
      // operator/viewer 需要检查是否有权限
      const permission = db.prepare(`
        SELECT * FROM user_product_permissions
        WHERE user_id = ? AND product_id = ?
      `).get(user.id, productId);
      
      if (!permission) {
        return res.status(403).json({ error: '无权访问此产品' });
      }
    }
    
    res.json(product);
  } catch (error: any) {
    res.status(500).json({ error: '查询产品失败: ' + error.message });
  }
});

// 创建产品（管理员）
router.post('/', requireCustomerAdmin, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const { model, customer_id, description } = req.body;
    
    if (!model || !customer_id) {
      return res.status(400).json({ error: '缺少必填字段' });
    }
    
    const db = getDb();
    
    // 检查客户是否存在
    const customer = db.prepare('SELECT * FROM customers WHERE id = ?').get(customer_id);
    if (!customer) {
      return res.status(400).json({ error: '客户不存在' });
    }
    
    const result = db.prepare(`
      INSERT INTO products (model, customer_id, description, created_by, created_at)
      VALUES (?, ?, ?, ?, datetime('now', 'localtime'))
    `).run(model, customer_id, description || null, user.id);
    
    // 记录审计日志
    db.prepare(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES (?, 'create', 'product', ?, ?, datetime('now', 'localtime'))
    `).run(user.id, result.lastInsertRowid, JSON.stringify({ model, customer_id }));
    
    res.json({ id: result.lastInsertRowid });
  } catch (error: any) {
    res.status(500).json({ error: '新增产品失败: ' + error.message });
  }
});

// 更新产品（管理员）
router.put('/:id', requireCustomerAdmin, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const productId = parseInt(req.params.id);
    const { model, description } = req.body;
    const db = getDb();
    
    // 检查产品
    const product = db.prepare('SELECT * FROM products WHERE id = ?').get(productId) as Product | undefined;
    if (!product) {
      return res.status(404).json({ error: '产品不存在' });
    }
    
    // 权限检查：只能编辑自己创建的产品
    if (user.role !== 'super_admin' && product.created_by !== user.id) {
      return res.status(403).json({ error: '只能编辑自己创建的产品' });
    }
    
    const updates: string[] = [];
    const params: any[] = [];
    
    if (model) {
      updates.push('model = ?');
      params.push(model);
    }
    
    if (description !== undefined) {
      updates.push('description = ?');
      params.push(description);
    }
    
    if (updates.length === 0) {
      return res.status(400).json({ error: '没有可更新的字段' });
    }
    
    params.push(productId);
    db.prepare(`UPDATE products SET ${updates.join(', ')} WHERE id = ?`).run(...params);
    
    // 记录审计日志
    db.prepare(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES (?, 'update', 'product', ?, ?, datetime('now', 'localtime'))
    `).run(user.id, productId, JSON.stringify(req.body));
    
    res.json({ success: true });
  } catch (error: any) {
    res.status(500).json({ error: '更新产品失败: ' + error.message });
  }
});

// 删除产品（管理员）
router.delete('/:id', requireCustomerAdmin, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const productId = parseInt(req.params.id);
    const db = getDb();
    
    // 检查产品
    const product = db.prepare('SELECT * FROM products WHERE id = ?').get(productId) as Product | undefined;
    if (!product) {
      return res.status(404).json({ error: '产品不存在' });
    }
    
    // 权限检查：只能删除自己创建的产品
    if (user.role !== 'super_admin' && product.created_by !== user.id) {
      return res.status(403).json({ error: '只能删除自己创建的产品' });
    }
    
    db.prepare('DELETE FROM products WHERE id = ?').run(productId);
    
    // 记录审计日志
    db.prepare(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES (?, 'delete', 'product', ?, ?, datetime('now', 'localtime'))
    `).run(user.id, productId, JSON.stringify({ id: productId, model: product.model }));
    
    res.json({ success: true });
  } catch (error: any) {
    res.status(500).json({ error: '删除产品失败: ' + error.message });
  }
});

export default router;
