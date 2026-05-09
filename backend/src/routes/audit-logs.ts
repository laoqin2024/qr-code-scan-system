import express from 'express';
import { getDb } from '../db';
import { requireAuth, requireSuperAdmin, AuthRequest } from '../middleware/auth';

const router = express.Router();

// 查询审计日志
router.get('/', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const { user_id, action, resource_type, start_time, end_time, page = 1, limit = 50, search } = req.query;
    
    const db = getDb();
    
    let query = `
      SELECT al.*, 
             u.username, 
             u.display_name
      FROM audit_logs al
      LEFT JOIN users u ON al.user_id = u.id
      WHERE 1=1
    `;
    const params: any[] = [];
    
    // 权限控制：超级管理员可以看所有日志，其他用户只能看自己的
    if (user.role !== 'super_admin') {
      query += ' AND al.user_id = ?';
      params.push(user.id);
    }
    
    // 筛选条件
    if (user_id) {
      query += ' AND al.user_id = ?';
      params.push(user_id);
    }
    
    if (action) {
      query += ' AND al.action = ?';
      params.push(action);
    }
    
    if (resource_type) {
      query += ' AND al.resource_type = ?';
      params.push(resource_type);
    }
    
    if (start_time) {
      query += ' AND al.created_at >= ?';
      params.push(start_time);
    }
    
    if (end_time) {
      query += ' AND al.created_at <= ?';
      params.push(end_time);
    }
    
    // 搜索功能
    if (search) {
      query += ' AND (al.action LIKE ? OR al.resource_type LIKE ? OR al.details LIKE ? OR u.username LIKE ? OR u.display_name LIKE ?)';
      const searchPattern = `%${search}%`;
      params.push(searchPattern, searchPattern, searchPattern, searchPattern, searchPattern);
    }
    
    // 计算总数
    const countQuery = query.replace(/SELECT al\.\*, u\.username, u\.display_name/, 'SELECT COUNT(*) as total');
    const countResult = db.prepare(countQuery).get(...params) as any;
    const total = countResult.total;
    
    // 分页
    const pageNum = parseInt(page as string);
    const limitNum = parseInt(limit as string);
    const offset = (pageNum - 1) * limitNum;
    
    query += ' ORDER BY al.created_at DESC LIMIT ? OFFSET ?';
    params.push(limitNum, offset);
    
    const logs = db.prepare(query).all(...params) as any[];
    
    res.json({
      logs,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        totalPages: Math.ceil(total / limitNum)
      }
    });
  } catch (error: any) {
    res.status(500).json({ error: '查询失败: ' + error.message });
  }
});

// 获取日志详情
router.get('/:id', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const logId = parseInt(req.params.id);
    
    const db = getDb();
    
    const log = db.prepare(`
      SELECT al.*, 
             u.username, 
             u.display_name
      FROM audit_logs al
      LEFT JOIN users u ON al.user_id = u.id
      WHERE al.id = ?
    `).get(logId) as any;
    
    if (!log) {
      return res.status(404).json({ error: '日志不存在' });
    }
    
    // 权限检查：超级管理员可以看所有日志，其他用户只能看自己的
    if (user.role !== 'super_admin' && log.user_id !== user.id) {
      return res.status(403).json({ error: '无权查看此日志' });
    }
    
    res.json(log);
  } catch (error: any) {
    res.status(500).json({ error: '查询失败: ' + error.message });
  }
});

// 获取统计数据
router.get('/stats/summary', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const { start_time, end_time } = req.query;
    
    const db = getDb();
    
    let whereClause = 'WHERE 1=1';
    const params: any[] = [];
    
    // 权限控制
    if (user.role !== 'super_admin') {
      whereClause += ' AND user_id = ?';
      params.push(user.id);
    }
    
    if (start_time) {
      whereClause += ' AND created_at >= ?';
      params.push(start_time);
    }
    
    if (end_time) {
      whereClause += ' AND created_at <= ?';
      params.push(end_time);
    }
    
    // 总操作数
    const totalResult = db.prepare(`SELECT COUNT(*) as total FROM audit_logs ${whereClause}`).get(...params) as any;
    
    // 今日操作数
    const todayResult = db.prepare(`
      SELECT COUNT(*) as total FROM audit_logs 
      ${whereClause} AND DATE(created_at) = DATE('now')
    `).get(...params) as any;
    
    // 本周操作数
    const weekResult = db.prepare(`
      SELECT COUNT(*) as total FROM audit_logs 
      ${whereClause} AND DATE(created_at) >= DATE('now', '-7 days')
    `).get(...params) as any;
    
    // 本月操作数
    const monthResult = db.prepare(`
      SELECT COUNT(*) as total FROM audit_logs 
      ${whereClause} AND DATE(created_at) >= DATE('now', 'start of month')
    `).get(...params) as any;
    
    // 按操作类型统计
    const actionStats = db.prepare(`
      SELECT action, COUNT(*) as count
      FROM audit_logs
      ${whereClause}
      GROUP BY action
      ORDER BY count DESC
      LIMIT 10
    `).all(...params) as any[];
    
    // 按资源类型统计
    const resourceStats = db.prepare(`
      SELECT resource_type, COUNT(*) as count
      FROM audit_logs
      ${whereClause}
      GROUP BY resource_type
      ORDER BY count DESC
      LIMIT 10
    `).all(...params) as any[];
    
    res.json({
      total: totalResult.total,
      today: todayResult.total,
      week: weekResult.total,
      month: monthResult.total,
      actionStats,
      resourceStats
    });
  } catch (error: any) {
    res.status(500).json({ error: '统计失败: ' + error.message });
  }
});

// 导出日志（CSV格式）
router.get('/export/csv', requireAuth, async (req: AuthRequest, res) => {
  try {
    const user = req.user!;
    const { user_id, action, resource_type, start_time, end_time } = req.query;
    
    const db = getDb();
    
    let query = `
      SELECT al.*, 
             u.username, 
             u.display_name
      FROM audit_logs al
      LEFT JOIN users u ON al.user_id = u.id
      WHERE 1=1
    `;
    const params: any[] = [];
    
    // 权限控制
    if (user.role !== 'super_admin') {
      query += ' AND al.user_id = ?';
      params.push(user.id);
    }
    
    // 筛选条件
    if (user_id) {
      query += ' AND al.user_id = ?';
      params.push(user_id);
    }
    
    if (action) {
      query += ' AND al.action = ?';
      params.push(action);
    }
    
    if (resource_type) {
      query += ' AND al.resource_type = ?';
      params.push(resource_type);
    }
    
    if (start_time) {
      query += ' AND al.created_at >= ?';
      params.push(start_time);
    }
    
    if (end_time) {
      query += ' AND al.created_at <= ?';
      params.push(end_time);
    }
    
    query += ' ORDER BY al.created_at DESC LIMIT 10000'; // 限制导出数量
    
    const logs = db.prepare(query).all(...params) as any[];
    
    // 生成CSV
    const csv = [
      ['ID', '时间', '用户', '操作', '资源类型', '资源ID', '详情', 'IP地址'].join(','),
      ...logs.map(log => [
        log.id,
        log.created_at,
        log.display_name || log.username,
        log.action,
        log.resource_type,
        log.resource_id || '',
        `"${(log.details || '').replace(/"/g, '""')}"`,
        log.ip_address || ''
      ].join(','))
    ].join('\n');
    
    // 设置响应头
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename=audit_logs_${new Date().toISOString().split('T')[0]}.csv`);
    
    // 添加BOM以支持Excel正确显示中文
    res.write('\ufeff');
    res.write(csv);
    res.end();
  } catch (error: any) {
    res.status(500).json({ error: '导出失败: ' + error.message });
  }
});

export default router;
