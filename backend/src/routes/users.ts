import { Router } from 'express';
import { AuthRequest, requireAuth, requireSuperAdmin, requireCustomerAdmin, canAccessCustomer } from '../middleware/auth';
import { getDb } from '../db';
import { UserInfo } from '../types';
import bcrypt from 'bcryptjs';

const router = Router();

// ============================================
// 用户管理
// ============================================

// 修改自己的密码
router.put('/me/password', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const { old_password, new_password } = req.body;
    
    if (!old_password || !new_password) {
      return res.status(400).json({ error: '旧密码和新密码不能为空' });
    }
    
    if (new_password.length < 6) {
      return res.status(400).json({ error: '新密码长度不能少于6位' });
    }
    
    const db = getDb();
    
    // 获取当前用户信息
    const currentUser = db.prepare('SELECT * FROM users WHERE id = ?').get(user.id) as any;
    
    // 验证旧密码
    const isValidPassword = await bcrypt.compare(old_password, currentUser.password_hash);
    if (!isValidPassword) {
      return res.status(400).json({ error: '旧密码错误' });
    }
    
    // 加密新密码
    const new_password_hash = await bcrypt.hash(new_password, 10);
    
    // 更新密码
    db.prepare('UPDATE users SET password_hash = ? WHERE id = ?').run(new_password_hash, user.id);
    
    // 记录审计日志
    db.prepare(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES (?, 'change_password', 'user', ?, ?, datetime('now', 'localtime'))
    `).run(user.id, user.id, JSON.stringify({ username: user.username }));
    
    res.json({ message: '密码修改成功，请重新登录' });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// 获取用户列表（按权限过滤）
router.get('/', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const db = getDb();
    
    let query = `
      SELECT u.id, u.username, u.display_name, u.role, u.customer_id, u.is_active, u.last_login, u.created_at, u.created_by,
             c.name as customer_name
      FROM users u
      LEFT JOIN customers c ON u.customer_id = c.id
    `;
    
    const params: any[] = [];
    
    // super_admin 可以看所有用户
    if (user.role === 'super_admin') {
      query += ' ORDER BY u.created_at DESC';
    }
    // customer_admin 只能看自己客户下的用户
    else if (user.role === 'customer_admin') {
      query += ' WHERE u.customer_id = ? ORDER BY u.created_at DESC';
      params.push(user.customer_id);
    }
    // 其他角色只能看自己
    else {
      query += ' WHERE u.id = ?';
      params.push(user.id);
    }
    
    const users = db.prepare(query).all(...params) as UserInfo[];
    res.json(users);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// 获取单个用户信息
router.get('/:id', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const userId = parseInt(req.params.id);
    const db = getDb();
    
    const targetUser = db.prepare(`
      SELECT u.id, u.username, u.display_name, u.role, u.customer_id, u.is_active, u.last_login, u.created_at,
             c.name as customer_name
      FROM users u
      LEFT JOIN customers c ON u.customer_id = c.id
      WHERE u.id = ?
    `).get(userId) as UserInfo | undefined;
    
    if (!targetUser) {
      return res.status(404).json({ error: '用户不存在' });
    }
    
    // 权限检查
    if (user.role !== 'super_admin') {
      if (user.role === 'customer_admin' && targetUser.customer_id !== user.customer_id) {
        return res.status(403).json({ error: '无权访问此用户' });
      }
      if (user.role !== 'customer_admin' && targetUser.id !== user.id) {
        return res.status(403).json({ error: '无权访问此用户' });
      }
    }
    
    res.json(targetUser);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// 创建用户
router.post('/', requireSuperAdmin, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const { username, password, display_name, role, customer_id } = req.body;
    
    // 参数验证
    if (!username || !password || !role || !display_name) {
      return res.status(400).json({ error: '缺少必填字段' });
    }
    
    // 角色验证
    const validRoles = ['super_admin', 'customer_admin', 'operator', 'viewer'];
    if (!validRoles.includes(role)) {
      return res.status(400).json({ error: '无效的角色' });
    }
    
    // 权限检查：只有 super_admin 可以创建 super_admin
    if (role === 'super_admin' && user.role !== 'super_admin') {
      return res.status(403).json({ error: '无权创建超级管理员' });
    }
    
    // 非 super_admin 角色可以选择关联客户（可选）
    let finalCustomerId = customer_id;
    if (role !== 'super_admin') {
      if (user.role === 'customer_admin' && user.customer_id) {
        // customer_admin 创建用户时，默认使用自己的客户（但可以不指定）
        if (!customer_id) {
          finalCustomerId = user.customer_id;
        }
      }
      // customer_id 现在是可选的，通过产品授权来控制权限
    }
    
    // 密码加密
    const password_hash = await bcrypt.hash(password, 10);
    
    const db = getDb();
    const result = db.prepare(`
      INSERT INTO users (username, password_hash, display_name, role, customer_id, is_active, created_at, created_by)
      VALUES (?, ?, ?, ?, ?, 1, datetime('now', 'localtime'), ?)
    `).run(username, password_hash, display_name, role, finalCustomerId || null, user.id);
    
    const newUserId = result.lastInsertRowid as number;
    
    // 如果是 viewer 或 operator，自动授权产品
    if (role === 'viewer' || role === 'operator') {
      let products: any[] = [];
      
      if (user.role === 'super_admin') {
        // super_admin 创建的用户，授权所有产品
        products = db.prepare('SELECT id FROM products').all();
      } else if (user.role === 'customer_admin') {
        if (finalCustomerId) {
          // 授权指定客户的所有产品
          products = db.prepare('SELECT id FROM products WHERE customer_id = ?').all(finalCustomerId);
        } else if (user.customer_id) {
          // 授权创建者客户的所有产品
          products = db.prepare('SELECT id FROM products WHERE customer_id = ?').all(user.customer_id);
        } else {
          // 授权创建者有权限的所有产品
          products = db.prepare(`
            SELECT DISTINCT product_id as id FROM user_product_permissions
            WHERE user_id = ?
          `).all(user.id);
        }
      }
      
      // 批量授权
      if (products.length > 0) {
        const stmt = db.prepare(`
          INSERT INTO user_product_permissions (user_id, product_id, can_scan, can_view, created_at)
          VALUES (?, ?, ?, ?, datetime('now', 'localtime'))
        `);
        
        const canScan = role === 'operator' ? 1 : 0;
        for (const product of products) {
          stmt.run(newUserId, product.id, canScan, 1);
        }
        
        // 记录审计日志
        db.prepare(`
          INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
          VALUES (?, 'auto_grant_permissions', 'permission', ?, ?, datetime('now', 'localtime'))
        `).run(user.id, newUserId, JSON.stringify({ 
          product_count: products.length,
          role,
          auto_granted: true
        }));
      }
    }
    
    // 记录审计日志
    db.prepare(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES (?, 'create', 'user', ?, ?, datetime('now', 'localtime'))
    `).run(user.id, newUserId, JSON.stringify({ username, role }));
    
    res.json({ 
      id: newUserId, 
      username, 
      role, 
      customer_id: finalCustomerId 
    });
  } catch (error: any) {
    if (error.message.includes('UNIQUE constraint failed')) {
      res.status(400).json({ error: '用户名已存在' });
    } else {
      res.status(500).json({ error: error.message });
    }
  }
});

// 更新用户
router.put('/:id', requireSuperAdmin, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const userId = parseInt(req.params.id);
    const { password, display_name, is_active, customer_id, role } = req.body;
    
    const db = getDb();
    
    // 检查目标用户
    const targetUser = db.prepare('SELECT * FROM users WHERE id = ?').get(userId) as any;
    if (!targetUser) {
      return res.status(404).json({ error: '用户不存在' });
    }
    
    // 权限检查
    if (user.role === 'customer_admin' && targetUser.customer_id !== user.customer_id) {
      return res.status(403).json({ error: '无权修改此用户' });
    }
    
    // 更新字段
    const updates: string[] = [];
    const params: any[] = [];
    
    if (password) {
      const password_hash = await bcrypt.hash(password, 10);
      updates.push('password_hash = ?');
      params.push(password_hash);
    }
    
    if (display_name) {
      updates.push('display_name = ?');
      params.push(display_name);
    }
    
    if (typeof is_active === 'boolean') {
      updates.push('is_active = ?');
      params.push(is_active ? 1 : 0);
    }
    
    if (customer_id !== undefined && user.role === 'super_admin') {
      updates.push('customer_id = ?');
      params.push(customer_id || null);
    }
    
    if (role && user.role === 'super_admin') {
      // 只有超级管理员可以修改角色
      const validRoles = ['super_admin', 'customer_admin', 'operator', 'viewer'];
      if (validRoles.includes(role)) {
        updates.push('role = ?');
        params.push(role);
      }
    }
    
    if (updates.length === 0) {
      return res.status(400).json({ error: '没有可更新的字段' });
    }
    
    params.push(userId);
    db.prepare(`UPDATE users SET ${updates.join(', ')} WHERE id = ?`).run(...params);
    
    // 记录审计日志
    db.prepare(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES (?, 'update', 'user', ?, ?, datetime('now', 'localtime'))
    `).run(user.id, userId, JSON.stringify(req.body));
    
    res.json({ message: '更新成功' });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// 删除用户
router.delete('/:id', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const userId = parseInt(req.params.id);
    
    if (userId === user.id) {
      return res.status(400).json({ error: '不能删除自己' });
    }
    
    const db = getDb();
    
    // 检查目标用户
    const targetUser = db.prepare('SELECT * FROM users WHERE id = ?').get(userId) as any;
    if (!targetUser) {
      return res.status(404).json({ error: '用户不存在' });
    }
    
    // 权限检查：超级管理员可以删除任何用户，客户管理员只能删除自己创建的用户
    if (user.role === 'super_admin') {
      // 超级管理员可以删除任何用户
    } else if (user.role === 'customer_admin') {
      if (targetUser.created_by !== user.id) {
        return res.status(403).json({ error: '无权删除此用户（只能删除自己创建的用户）' });
      }
    } else {
      return res.status(403).json({ error: '需要管理员权限' });
    }
    
    // 检查是否有扫码记录
    const scanCount = db.prepare('SELECT COUNT(*) as count FROM scans WHERE user_id = ?').get(userId) as any;
    if (scanCount.count > 0) {
      return res.status(400).json({ 
        error: `该用户有 ${scanCount.count} 条扫码记录，无法删除。建议禁用该用户。` 
      });
    }
    
    // 检查是否创建了数据
    const customerCount = db.prepare('SELECT COUNT(*) as count FROM customers WHERE created_by = ?').get(userId) as any;
    const productCount = db.prepare('SELECT COUNT(*) as count FROM products WHERE created_by = ?').get(userId) as any;
    const createdUserCount = db.prepare('SELECT COUNT(*) as count FROM users WHERE created_by = ?').get(userId) as any;
    
    if (customerCount.count > 0 || productCount.count > 0 || createdUserCount.count > 0) {
      return res.status(400).json({ 
        error: `该用户创建了 ${customerCount.count} 个客户、${productCount.count} 个产品和 ${createdUserCount.count} 个用户，无法删除。建议禁用该用户。` 
      });
    }
    
    // 使用事务删除
    db.exec('BEGIN TRANSACTION');
    
    try {
      // 1. 删除用户的权限记录
      db.prepare('DELETE FROM user_product_permissions WHERE user_id = ?').run(userId);
      
      // 2. 删除用户的审计日志（或者设置为NULL，但这里选择删除）
      db.prepare('DELETE FROM audit_logs WHERE user_id = ?').run(userId);
      
      // 3. 将其他用户引用该用户的 customer_id 设为 NULL
      db.prepare('UPDATE users SET customer_id = NULL WHERE customer_id IN (SELECT id FROM customers WHERE created_by = ?)').run(userId);
      
      // 4. 删除用户
      db.prepare('DELETE FROM users WHERE id = ?').run(userId);
      
      db.exec('COMMIT');
    } catch (err) {
      db.exec('ROLLBACK');
      throw err;
    }
    
    // 记录审计日志
    db.prepare(`
      INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details, created_at)
      VALUES (?, 'delete', 'user', ?, ?, datetime('now', 'localtime'))
    `).run(user.id, userId, JSON.stringify({ username: targetUser.username }));
    
    res.json({ message: '删除成功' });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

export default router;