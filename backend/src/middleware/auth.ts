import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { UserRole } from '../types';

export interface AuthRequest extends Request {
  user?: { 
    id: number; 
    username: string; 
    role: UserRole;
    customer_id?: number;
  };
}

// 基础认证：验证JWT token
export function requireAuth(req: AuthRequest, res: Response, next: NextFunction) {
  const auth = req.headers.authorization;
  if (!auth || !auth.startsWith('Bearer ')) {
    return res.status(401).json({ error: '未登录' });
  }
  try {
    const token = auth.slice(7);
    const user = jwt.verify(token, process.env.JWT_SECRET || 'secret') as any;
    req.user = user;
    next();
  } catch {
    res.status(401).json({ error: '无效token' });
  }
}

// 要求超级管理员权限
export function requireSuperAdmin(req: AuthRequest, res: Response, next: NextFunction) {
  requireAuth(req, res, () => {
    if (req.user?.role !== 'super_admin') {
      return res.status(403).json({ error: '需要超级管理员权限' });
    }
    next();
  });
}

// 要求管理员权限（super_admin 或 customer_admin）
export function requireAdmin(req: AuthRequest, res: Response, next: NextFunction) {
  requireAuth(req, res, () => {
    if (!req.user || !['super_admin', 'customer_admin'].includes(req.user.role)) {
      return res.status(403).json({ error: '需要管理员权限' });
    }
    next();
  });
}

// 要求客户管理员权限（管理指定客户）
export function requireCustomerAdmin(req: AuthRequest, res: Response, next: NextFunction) {
  requireAuth(req, res, () => {
    const user = req.user;
    if (!user) {
      return res.status(403).json({ error: '无权限' });
    }
    
    // super_admin 可以管理所有客户
    if (user.role === 'super_admin') {
      return next();
    }
    
    // customer_admin 可以管理客户（不再要求必须有 customer_id）
    if (user.role === 'customer_admin') {
      return next();
    }
    
    res.status(403).json({ error: '需要客户管理员权限' });
  });
}

// 要求操作员权限（可以扫码）
export function requireOperator(req: AuthRequest, res: Response, next: NextFunction) {
  requireAuth(req, res, () => {
    const user = req.user;
    if (!user) {
      return res.status(403).json({ error: '无权限' });
    }
    
    // super_admin, customer_admin, operator 都可以扫码
    if (['super_admin', 'customer_admin', 'operator'].includes(user.role)) {
      return next();
    }
    
    res.status(403).json({ error: '需要操作员权限' });
  });
}

// 角色检查辅助函数
export function hasRole(user: AuthRequest['user'], roles: UserRole[]): boolean {
  return !!user && roles.includes(user.role);
}

// 检查是否可以访问指定客户的数据
export function canAccessCustomer(user: AuthRequest['user'], customerId: number): boolean {
  if (!user) return false;
  
  // super_admin 可以访问所有客户
  if (user.role === 'super_admin') return true;
  
  // 其他角色只能访问自己的客户
  return user.customer_id === customerId;
}
