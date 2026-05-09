import express from 'express';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { getDb } from '../db';
import { User } from '../types';
import { requireAuth, AuthRequest } from '../middleware/auth';

const router = express.Router();

// 登录
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    if (!username || !password) {
      return res.status(400).json({ error: '用户名和密码不能为空' });
    }
    
    const db = getDb();
    const user = db.prepare('SELECT * FROM users WHERE username = ?').get(username) as User | undefined;
    
    if (!user) {
      return res.status(401).json({ error: '用户不存在' });
    }
    
    // 检查用户是否被禁用
    if (!user.is_active) {
      return res.status(401).json({ error: '账号已被禁用，请联系管理员' });
    }
    
    // 验证密码
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    if (!isPasswordValid) {
      return res.status(401).json({ error: '密码错误' });
    }
    
    // 更新最后登录时间
    db.prepare('UPDATE users SET last_login = datetime(\'now\') WHERE id = ?').run(user.id);
    
    // 记录审计日志
    const ipAddress = req.ip || req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    db.prepare(`
      INSERT INTO audit_logs (user_id, action, resource_type, details, ip_address, created_at)
      VALUES (?, 'login', 'auth', ?, ?, datetime('now'))
    `).run(user.id, JSON.stringify({ username }), ipAddress);
    
    // 生成 JWT token
    const token = jwt.sign(
      { 
        id: user.id, 
        username: user.username,
        display_name: user.display_name,
        role: user.role,
        customer_id: user.customer_id 
      }, 
      process.env.JWT_SECRET || 'secret', 
      { expiresIn: '8h' }
    );
    
    res.json({ 
      token, 
      user: {
        id: user.id,
        username: user.username,
        display_name: user.display_name,
        role: user.role,
        customer_id: user.customer_id
      }
    });
  } catch (error: any) {
    res.status(500).json({ error: '登录失败: ' + error.message });
  }
});

// 获取当前用户信息
router.get('/me', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const db = getDb();
    
    const userInfo = db.prepare(`
      SELECT u.id, u.username, u.display_name, u.role, u.customer_id, u.is_active, u.last_login, u.created_at,
             c.name as customer_name
      FROM users u
      LEFT JOIN customers c ON u.customer_id = c.id
      WHERE u.id = ?
    `).get(user.id);
    
    res.json(userInfo);
  } catch (error: any) {
    res.status(500).json({ error: '获取用户信息失败: ' + error.message });
  }
});

// 修改密码
router.post('/change-password', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const { old_password, new_password } = req.body;
    
    if (!old_password || !new_password) {
      return res.status(400).json({ error: '旧密码和新密码不能为空' });
    }
    
    if (new_password.length < 6) {
      return res.status(400).json({ error: '新密码长度至少6位' });
    }
    
    const db = getDb();
    const userRecord = db.prepare('SELECT * FROM users WHERE id = ?').get(user.id) as User;
    
    // 验证旧密码
    const isOldPasswordValid = await bcrypt.compare(old_password, userRecord.password_hash);
    if (!isOldPasswordValid) {
      return res.status(401).json({ error: '旧密码错误' });
    }
    
    // 更新密码
    const new_password_hash = await bcrypt.hash(new_password, 10);
    db.prepare('UPDATE users SET password_hash = ? WHERE id = ?').run(new_password_hash, user.id);
    
    // 记录审计日志
    db.prepare(`
      INSERT INTO audit_logs (user_id, action, resource_type, details, created_at)
      VALUES (?, 'change_password', 'auth', ?, datetime('now'))
    `).run(user.id, JSON.stringify({ username: user.username }));
    
    res.json({ message: '密码修改成功' });
  } catch (error: any) {
    res.status(500).json({ error: '修改密码失败: ' + error.message });
  }
});

// 登出（记录日志）
router.post('/logout', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const db = getDb();
    
    // 记录审计日志
    db.prepare(`
      INSERT INTO audit_logs (user_id, action, resource_type, details, created_at)
      VALUES (?, 'logout', 'auth', ?, datetime('now'))
    `).run(user.id, JSON.stringify({ username: user.username }));
    
    res.json({ message: '登出成功' });
  } catch (error: any) {
    res.status(500).json({ error: '登出失败: ' + error.message });
  }
});

export default router;
