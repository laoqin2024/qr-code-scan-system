import { Router } from 'express';
import { AuthRequest, requireAuth, requireCustomerAdmin, canAccessCustomer } from '../middleware/auth';
import { getDb } from '../db';

const router = Router();

// ============================================
// 权限管理
// ============================================

// 获取用户的产品权限
router.get('/users/:id/permissions', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const userId = parseInt(req.params.id);
    const db = getDb();
    
    // 检查目标用户
    const targetUser = db.prepare('SELECT * FROM users WHERE id = ?').get(userId) as any;
    if (!targetUser) {
      return res.status(404).json({ error: '用户不存在' });
    }
    
    // 权限检查：超级管理员可以查看任何用户，客户管理员可以查看自己创建的用户
    if (user.role !== 'super_admin') {
      if (user.role === 'customer_admin') {
        if (targetUser.created_by !== user.id && userId !== user.id) {
          return res.status(403).json({ error: '无权查看此用户权限（只能查看自己创建的用户）' });
        }
      } else {
        if (userId !== user.id) {
          return res.status(403).json({ error: '无权查看此用户权限' });
        }
      }
    }
    
    const permissions = db.prepare(`
      SELECT p.id, p.user_id, p.product_id, p.can_scan, p.can_view, p.created_at,
             pr.model as product_model, pr.customer_id,
             c.name as customer_name
      FROM user_product_permissions p
      JOIN products pr ON p.product_id = pr.id
      JOIN customers c ON pr.customer_id = c.id
      WHERE p.user_id = ?
      ORDER BY p.created_at DESC
    `).all(userId);
    
    res.json(permissions);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// 授权产品给用户
router.post('/users/:id/permissions/products', requireCustomerAdmin, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const userId = parseInt(req.params.id);
    const { product_id, can_scan = true, can_view = true } = req.body;
    
    if (!product_id) {
      return res.status(400).json({ error: '缺少产品ID' });
    }
    
    const db = getDb();
    
    // 检查目标用户
    const targetUser = db.prepare('SELECT * FROM users WHERE id = ?').get(userId) as any;
    if (!targetUser) {
      return res.status(404).json({ error: '用户不存在' });
    }
    
    // 检查产品
    const product = db.prepare('SELECT * FROM products WHERE id = ?').get(product_id) as any;
    if (!product) {
      return res.status(404).json({ error: '产品不存在' });
    }
    
    // 权限检查：超级管理员可以授权任何用户，客户管理员只能授权自己创建的用户
    if (user.role === 'customer_admin') {
      if (targetUser.created_by !== user.id) {
        return res.status(403).json({ error: '无权为此用户授权（只能管理自己创建的用户）' });
      }
    }
    
    // 插入或更新权限
    db.prepare(`
      INSERT INTO user_product_permissions (user_id, product_id, can_scan, can_view, created_at)
      VALUES (?, ?, ?, ?, datetime('now'))
      ON CONFLICT(user_id, product_id) DO UPDATE SET
        can_scan = excluded.can_scan,
        can_view = excluded.can_view
    `).run(userId, product_id, can_scan ? 1 : 0, can_view ? 1 : 0);
    
    // 记录审计日志
    db.prepare(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES (?, 'grant_permission', 'permission', ?, ?, datetime('now'))
    `).run(user.id, userId, JSON.stringify({ product_id, can_scan, can_view }));
    
    res.json({ message: '授权成功' });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// 批量授权产品
router.post('/users/:id/permissions/products/batch', requireCustomerAdmin, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const userId = parseInt(req.params.id);
    const { product_ids, can_scan = true, can_view = true } = req.body;
    
    if (!Array.isArray(product_ids) || product_ids.length === 0) {
      return res.status(400).json({ error: '产品ID列表不能为空' });
    }
    
    const db = getDb();
    
    // 检查目标用户
    const targetUser = db.prepare('SELECT * FROM users WHERE id = ?').get(userId) as any;
    if (!targetUser) {
      return res.status(404).json({ error: '用户不存在' });
    }
    
    // 权限检查：超级管理员可以授权任何用户，客户管理员只能授权自己创建的用户
    if (user.role === 'customer_admin') {
      if (targetUser.created_by !== user.id) {
        return res.status(403).json({ error: '无权为此用户授权（只能管理自己创建的用户）' });
      }
    }
    
    // 批量插入
    const stmt = db.prepare(`
      INSERT INTO user_product_permissions (user_id, product_id, can_scan, can_view, created_at)
      VALUES (?, ?, ?, ?, datetime('now'))
      ON CONFLICT(user_id, product_id) DO UPDATE SET
        can_scan = excluded.can_scan,
        can_view = excluded.can_view
    `);
    
    let successCount = 0;
    for (const productId of product_ids) {
      // 检查产品是否存在
      const product = db.prepare('SELECT * FROM products WHERE id = ?').get(productId) as any;
      if (!product) continue;
      
      stmt.run(userId, productId, can_scan ? 1 : 0, can_view ? 1 : 0);
      successCount++;
    }
    
    // 记录审计日志
    db.prepare(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES (?, 'grant_permission_batch', 'permission', ?, ?, datetime('now'))
    `).run(user.id, userId, JSON.stringify({ product_ids, can_scan, can_view, successCount }));
    
    res.json({ message: `批量授权成功，共授权 ${successCount} 个产品` });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// 批量授权客户的所有产品（新增）
router.post('/users/:id/permissions/customers/:customerId/products', requireCustomerAdmin, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const userId = parseInt(req.params.id);
    const customerId = parseInt(req.params.customerId);
    const { can_scan = true, can_view = true } = req.body;
    
    const db = getDb();
    
    // 检查目标用户
    const targetUser = db.prepare('SELECT * FROM users WHERE id = ?').get(userId) as any;
    if (!targetUser) {
      return res.status(404).json({ error: '用户不存在' });
    }
    
    // 检查客户
    const customer = db.prepare('SELECT * FROM customers WHERE id = ?').get(customerId) as any;
    if (!customer) {
      return res.status(404).json({ error: '客户不存在' });
    }
    
    // 权限检查
    if (user.role === 'customer_admin' && user.customer_id && user.customer_id !== customerId) {
      // 检查是否有该客户的任意产品权限
      const hasPermission = db.prepare(`
        SELECT COUNT(*) as count
        FROM user_product_permissions upp
        JOIN products p ON upp.product_id = p.id
        WHERE upp.user_id = ? AND p.customer_id = ?
      `).get(user.id, customerId) as any;
      
      if (hasPermission.count === 0) {
        return res.status(403).json({ error: '无权授权此客户的产品' });
      }
    }
    
    // 获取该客户的所有产品
    const products = db.prepare('SELECT id FROM products WHERE customer_id = ?').all(customerId) as any[];
    
    if (products.length === 0) {
      return res.status(400).json({ error: '该客户没有产品' });
    }
    
    // 批量授权
    const stmt = db.prepare(`
      INSERT INTO user_product_permissions (user_id, product_id, can_scan, can_view, created_at)
      VALUES (?, ?, ?, ?, datetime('now'))
      ON CONFLICT(user_id, product_id) DO UPDATE SET
        can_scan = excluded.can_scan,
        can_view = excluded.can_view
    `);
    
    for (const product of products) {
      stmt.run(userId, product.id, can_scan ? 1 : 0, can_view ? 1 : 0);
    }
    
    // 记录审计日志
    db.prepare(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES (?, 'grant_customer_products', 'permission', ?, ?, datetime('now'))
    `).run(user.id, userId, JSON.stringify({ customer_id: customerId, product_count: products.length, can_scan, can_view }));
    
    res.json({ message: `成功授权 ${products.length} 个产品` });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// 撤销产品权限
router.delete('/users/:id/permissions/products/:productId', requireCustomerAdmin, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const userId = parseInt(req.params.id);
    const productId = parseInt(req.params.productId);
    
    const db = getDb();
    
    // 检查目标用户
    const targetUser = db.prepare('SELECT * FROM users WHERE id = ?').get(userId) as any;
    if (!targetUser) {
      return res.status(404).json({ error: '用户不存在' });
    }
    
    // 权限检查：超级管理员可以撤销任何权限，客户管理员只能撤销自己创建的用户的权限
    if (user.role === 'customer_admin') {
      if (targetUser.created_by !== user.id) {
        return res.status(403).json({ error: '无权撤销此用户权限（只能管理自己创建的用户）' });
      }
    }
    
    db.prepare('DELETE FROM user_product_permissions WHERE user_id = ? AND product_id = ?')
      .run(userId, productId);
    
    // 记录审计日志
    db.prepare(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES (?, 'revoke_permission', 'permission', ?, ?, datetime('now'))
    `).run(user.id, userId, JSON.stringify({ product_id: productId }));
    
    res.json({ message: '撤销成功' });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// 获取产品的授权用户列表
router.get('/products/:id/users', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const productId = parseInt(req.params.id);
    const db = getDb();
    
    // 检查产品
    const product = db.prepare('SELECT * FROM products WHERE id = ?').get(productId) as any;
    if (!product) {
      return res.status(404).json({ error: '产品不存在' });
    }
    
    // 权限检查
    if (!canAccessCustomer(user, product.customer_id)) {
      return res.status(403).json({ error: '无权查看此产品' });
    }
    
    const users = db.prepare(`
      SELECT u.id, u.username, u.role, p.can_scan, p.can_view, p.created_at
      FROM user_product_permissions p
      JOIN users u ON p.user_id = u.id
      WHERE p.product_id = ?
      ORDER BY p.created_at DESC
    `).all(productId);
    
    res.json(users);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// 获取用户可访问的客户列表（新增）
router.get('/users/:id/customers', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const userId = parseInt(req.params.id);
    const db = getDb();
    
    // 检查目标用户
    const targetUser = db.prepare('SELECT * FROM users WHERE id = ?').get(userId) as any;
    if (!targetUser) {
      return res.status(404).json({ error: '用户不存在' });
    }
    
    // 权限检查
    if (user.role !== 'super_admin' && user.id !== userId) {
      if (user.role === 'customer_admin' && targetUser.customer_id !== user.customer_id) {
        return res.status(403).json({ error: '无权查看此用户信息' });
      }
    }
    
    // 查询用户有权限的所有客户（通过产品授权反推）
    const customers = db.prepare(`
      SELECT DISTINCT c.id, c.name, c.expected_length, c.description,
             COUNT(DISTINCT upp.product_id) as product_count
      FROM customers c
      JOIN products p ON c.id = p.customer_id
      JOIN user_product_permissions upp ON p.id = upp.product_id
      WHERE upp.user_id = ?
      GROUP BY c.id
      ORDER BY c.name
    `).all(userId);
    
    res.json(customers);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// 审计日志
// ============================================

// 获取审计日志
router.get('/audit-logs', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const { limit = 100, offset = 0, resource_type, action } = req.query;
    const db = getDb();
    
    // 只有管理员可以查看审计日志
    if (!['super_admin', 'customer_admin'].includes(user.role)) {
      return res.status(403).json({ error: '需要管理员权限' });
    }
    
    let query = `
      SELECT a.*, u.username
      FROM audit_logs a
      JOIN users u ON a.user_id = u.id
    `;
    
    const conditions: string[] = [];
    const params: any[] = [];
    
    // customer_admin 只能看自己客户的日志
    if (user.role === 'customer_admin') {
      conditions.push(`u.customer_id = ?`);
      params.push(user.customer_id);
    }
    
    if (resource_type) {
      conditions.push('a.resource_type = ?');
      params.push(resource_type);
    }
    
    if (action) {
      conditions.push('a.action = ?');
      params.push(action);
    }
    
    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ');
    }
    
    query += ' ORDER BY a.created_at DESC LIMIT ? OFFSET ?';
    params.push(limit, offset);
    
    const logs = db.prepare(query).all(...params);
    res.json(logs);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// 获取我的操作记录
router.get('/audit-logs/my', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const { limit = 50, offset = 0 } = req.query;
    const db = getDb();
    
    const logs = db.prepare(`
      SELECT * FROM audit_logs
      WHERE user_id = ?
      ORDER BY created_at DESC
      LIMIT ? OFFSET ?
    `).all(user.id, limit, offset);
    
    res.json(logs);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

export default router;