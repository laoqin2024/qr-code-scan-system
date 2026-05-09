import React, { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { authAPI, userAPI } from '../api';
import type { UserRole } from '../types';
import './Navbar.css';

const Navbar: React.FC = () => {
  const navigate = useNavigate();
  const [user, setUser] = useState<{ username: string; display_name?: string; role: UserRole } | null>(null);
  const [showPasswordModal, setShowPasswordModal] = useState(false);
  const [passwordForm, setPasswordForm] = useState({
    old_password: '',
    new_password: '',
    confirm_password: '',
  });
  const [passwordError, setPasswordError] = useState('');
  const [passwordLoading, setPasswordLoading] = useState(false);

  useEffect(() => {
    const userStr = localStorage.getItem('user');
    if (userStr) {
      setUser(JSON.parse(userStr));
    }
  }, []);

  const handleLogout = async () => {
    try {
      await authAPI.logout();
    } catch (error) {
      console.error('登出失败:', error);
    } finally {
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      navigate('/login');
    }
  };

  const handleChangePassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setPasswordError('');
    
    if (passwordForm.new_password !== passwordForm.confirm_password) {
      setPasswordError('两次输入的新密码不一致');
      return;
    }
    
    if (passwordForm.new_password.length < 6) {
      setPasswordError('新密码长度不能少于6位');
      return;
    }
    
    setPasswordLoading(true);
    try {
      await userAPI.changeMyPassword({
        old_password: passwordForm.old_password,
        new_password: passwordForm.new_password,
      });
      
      alert('密码修改成功，请重新登录');
      
      // 清除登录信息
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      navigate('/login');
    } catch (error: any) {
      setPasswordError(error.response?.data?.error || '修改密码失败');
    } finally {
      setPasswordLoading(false);
    }
  };

  const role = user?.role;
  const displayName = user?.display_name || user?.username || '未知用户';

  // 角色显示名称
  const getRoleName = (role?: UserRole) => {
    switch (role) {
      case 'super_admin': return '超级管理员';
      case 'customer_admin': return '客户管理员';
      case 'operator': return '操作员';
      case 'viewer': return '查看者';
      default: return '';
    }
  };

  return (
    <nav className="navbar">
      <div className="navbar-brand">
        <h1>二维码扫码防错系统</h1>
        {user && (
          <span className="user-info">
            {displayName} ({getRoleName(role)})
          </span>
        )}
      </div>
      <div className="navbar-menu">
        {/* 所有角色都能看到的菜单 */}
        {(role === 'super_admin' || role === 'customer_admin' || role === 'operator') && (
          <Link to="/scan" className="nav-link">扫码录入</Link>
        )}
        
        <Link to="/query" className="nav-link">查询记录</Link>
        
        {/* 管理员菜单 */}
        {(role === 'super_admin' || role === 'customer_admin') && (
          <>
            <Link to="/customers" className="nav-link">客户管理</Link>
            <Link to="/products" className="nav-link">产品管理</Link>
          </>
        )}
        
        {/* 超级管理员专属 */}
        {role === 'super_admin' && (
          <>
            <Link to="/users" className="nav-link">用户管理</Link>
            <Link to="/permissions" className="nav-link">权限管理</Link>
            <Link to="/system" className="nav-link">系统管理</Link>
            <Link to="/audit-logs" className="nav-link">审计日志</Link>
          </>
        )}
        
        <button onClick={() => setShowPasswordModal(true)} className="change-password-btn">修改密码</button>
        <button onClick={handleLogout} className="logout-btn">退出登录</button>
      </div>
      
      {/* 修改密码模态框 */}
      {showPasswordModal && (
        <div className="modal-overlay" onClick={() => setShowPasswordModal(false)}>
          <div className="modal-content" onClick={e => e.stopPropagation()}>
            <h3>修改密码</h3>
            {passwordError && <div className="error-msg">{passwordError}</div>}
            <form onSubmit={handleChangePassword}>
              <div className="form-group">
                <label>旧密码 *</label>
                <input
                  type="password"
                  value={passwordForm.old_password}
                  onChange={e => setPasswordForm({ ...passwordForm, old_password: e.target.value })}
                  placeholder="请输入旧密码"
                  required
                />
              </div>
              
              <div className="form-group">
                <label>新密码 *</label>
                <input
                  type="password"
                  value={passwordForm.new_password}
                  onChange={e => setPasswordForm({ ...passwordForm, new_password: e.target.value })}
                  placeholder="请输入新密码（至少6位）"
                  required
                  minLength={6}
                />
              </div>
              
              <div className="form-group">
                <label>确认新密码 *</label>
                <input
                  type="password"
                  value={passwordForm.confirm_password}
                  onChange={e => setPasswordForm({ ...passwordForm, confirm_password: e.target.value })}
                  placeholder="请再次输入新密码"
                  required
                  minLength={6}
                />
              </div>
              
              <div className="modal-actions">
                <button type="button" onClick={() => setShowPasswordModal(false)} className="btn-secondary">
                  取消
                </button>
                <button type="submit" className="btn-primary" disabled={passwordLoading}>
                  {passwordLoading ? '修改中...' : '确定'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </nav>
  );
};

export default Navbar;
