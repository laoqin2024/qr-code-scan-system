import React, { useState, useEffect } from 'react';
import Navbar from '../components/Navbar';
import { userAPI, customerAPI } from '../api';
import type { User, Customer, UserRole } from '../types';
import '../styles/Page.css';

const Users: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(false);
  const [showModal, setShowModal] = useState(false);
  const [editingUser, setEditingUser] = useState<User | null>(null);
  const [formData, setFormData] = useState({
    username: '',
    password: '',
    display_name: '',
    role: 'operator' as UserRole,
    customer_id: '',
  });

  const currentUser = JSON.parse(localStorage.getItem('user') || '{}');

  useEffect(() => {
    loadUsers();
    loadCustomers();
  }, []);

  const loadUsers = async () => {
    setLoading(true);
    try {
      const res = await userAPI.getUsers();
      setUsers(res.data);
    } catch (error: any) {
      alert('加载用户失败: ' + (error.response?.data?.error || error.message));
    } finally {
      setLoading(false);
    }
  };

  const loadCustomers = async () => {
    try {
      const res = await customerAPI.getCustomers();
      setCustomers(res.data);
    } catch (error) {
      console.error('加载客户失败:', error);
    }
  };

  const handleCreate = () => {
    setEditingUser(null);
    setFormData({
      username: '',
      password: '',
      display_name: '',
      role: 'operator',
      customer_id: currentUser.role === 'customer_admin' ? currentUser.customer_id : '',
    });
    setShowModal(true);
  };

  const handleEdit = (user: User) => {
    setEditingUser(user);
    setFormData({
      username: user.username,
      password: '',
      display_name: user.display_name || '',
      role: user.role,
      customer_id: user.customer_id?.toString() || '',
    });
    setShowModal(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      if (editingUser) {
        // 更新用户
        const updateData: any = {};
        if (formData.password) {
          updateData.password = formData.password;
        }
        if (formData.display_name) {
          updateData.display_name = formData.display_name;
        }
        if (formData.role && formData.role !== editingUser.role) {
          updateData.role = formData.role;
        }
        if (formData.customer_id !== editingUser.customer_id?.toString()) {
          updateData.customer_id = formData.customer_id ? parseInt(formData.customer_id) : null;
        }
        await userAPI.updateUser(editingUser.id, updateData);
        alert('更新成功');
      } else {
        // 创建用户
        await userAPI.createUser({
          username: formData.username,
          password: formData.password,
          display_name: formData.display_name,
          role: formData.role,
          customer_id: formData.customer_id ? parseInt(formData.customer_id) : undefined,
        });
        alert('创建成功！\n\n提示：请到"权限管理"页面为该用户授权产品');
      }
      
      setShowModal(false);
      loadUsers();
    } catch (error: any) {
      alert('操作失败: ' + (error.response?.data?.error || error.message));
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm('确定要删除此用户吗？')) return;
    setLoading(true);
    try {
      await userAPI.deleteUser(id);
      alert('删除成功');
      loadUsers();
    } catch (error: any) {
      alert('删除失败: ' + (error.response?.data?.error || error.message));
    } finally {
      setLoading(false);
    }
  };

  const handleToggleActive = async (user: User) => {
    if (!confirm(`确定要${user.is_active ? '禁用' : '启用'}此用户吗？`)) return;
    setLoading(true);
    try {
      await userAPI.updateUser(user.id, { is_active: !user.is_active });
      alert('操作成功');
      loadUsers();
    } catch (error: any) {
      alert('操作失败: ' + (error.response?.data?.error || error.message));
    } finally {
      setLoading(false);
    }
  };

  const getRoleName = (role: UserRole) => {
    const roleMap = {
      super_admin: '超级管理员',
      customer_admin: '客户管理员',
      operator: '操作员',
      viewer: '查看者',
    };
    return roleMap[role] || role;
  };

  return (
    <div>
      <Navbar />
      <div className="page-container">
        <div className="page-header">
          <h2>用户管理</h2>
          <button onClick={handleCreate} className="btn-primary">
            + 新增用户
          </button>
        </div>

        {loading && <div className="loading">加载中...</div>}

        <div className="table-container">
          <table className="data-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>用户名</th>
                <th>姓名</th>
                <th>角色</th>
                <th>所属客户</th>
                <th>状态</th>
                <th>最后登录</th>
                <th>创建时间</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              {users.map(user => (
                <tr key={user.id}>
                  <td>{user.id}</td>
                  <td>{user.username}</td>
                  <td><strong>{user.display_name || '-'}</strong></td>
                  <td>
                    <span className={`role-badge role-${user.role}`}>
                      {getRoleName(user.role)}
                    </span>
                  </td>
                  <td>{user.customer_name || '-'}</td>
                  <td>
                    <span className={`status-badge ${user.is_active ? 'active' : 'inactive'}`}>
                      {user.is_active ? '正常' : '禁用'}
                    </span>
                  </td>
                  <td>{user.last_login ? new Date(user.last_login).toLocaleString() : '-'}</td>
                  <td>{new Date(user.created_at).toLocaleString()}</td>
                  <td>
                    <div className="action-buttons">
                      <button onClick={() => handleEdit(user)} className="btn-edit">
                        编辑
                      </button>
                      <button 
                        onClick={() => handleToggleActive(user)} 
                        className={user.is_active ? 'btn-warning' : 'btn-success'}
                      >
                        {user.is_active ? '禁用' : '启用'}
                      </button>
                      {(user.role === 'operator' || user.role === 'viewer' || user.role === 'customer_admin') && (
                        <button 
                          onClick={() => window.location.href = `/permissions?userId=${user.id}`}
                          className="btn-primary"
                          style={{fontSize: '12px', padding: '6px 12px'}}
                        >
                          权限管理
                        </button>
                      )}
                      {user.id !== currentUser.id && (
                        <button onClick={() => handleDelete(user.id)} className="btn-delete">
                          删除
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {showModal && (
          <div className="modal-overlay" onClick={() => setShowModal(false)}>
            <div className="modal-content" onClick={e => e.stopPropagation()}>
              <h3>{editingUser ? '编辑用户' : '新增用户'}</h3>
              <form onSubmit={handleSubmit}>
                <div className="form-group">
                  <label>登录账号 *</label>
                  <input
                    type="text"
                    value={formData.username}
                    onChange={e => setFormData({ ...formData, username: e.target.value })}
                    placeholder="用于登录的账号"
                    required
                    disabled={!!editingUser}
                  />
                </div>

                <div className="form-group">
                  <label>姓名 *</label>
                  <input
                    type="text"
                    value={formData.display_name}
                    onChange={e => setFormData({ ...formData, display_name: e.target.value })}
                    placeholder="真实姓名或显示名称"
                    required={!editingUser}
                  />
                </div>

                <div className="form-group">
                  <label>{editingUser ? '新密码（留空不修改）' : '密码 *'}</label>
                  <input
                    type="password"
                    value={formData.password}
                    onChange={e => setFormData({ ...formData, password: e.target.value })}
                    placeholder="登录密码"
                    required={!editingUser}
                    minLength={6}
                  />
                </div>

                <div className="form-group">
                  <label>角色</label>
                  <select
                    value={formData.role}
                    onChange={e => setFormData({ ...formData, role: e.target.value as UserRole })}
                    required
                    disabled={editingUser && currentUser.role !== 'super_admin'}
                  >
                    {currentUser.role === 'super_admin' && (
                      <>
                        <option value="super_admin">超级管理员</option>
                        <option value="customer_admin">客户管理员</option>
                      </>
                    )}
                    <option value="operator">操作员</option>
                    <option value="viewer">查看者</option>
                  </select>
                  {editingUser && currentUser.role !== 'super_admin' && (
                    <small style={{color: '#999', fontSize: '12px', display: 'block', marginTop: '4px'}}>
                      只有超级管理员可以修改角色
                    </small>
                  )}
                </div>

                {formData.role !== 'super_admin' && currentUser.role === 'super_admin' && (
                  <div className="form-group">
                    <label>所属客户</label>
                    <select
                      value={formData.customer_id}
                      onChange={e => setFormData({ ...formData, customer_id: e.target.value })}
                    >
                      <option value="">无</option>
                      {customers.map(c => (
                        <option key={c.id} value={c.id}>{c.name}</option>
                      ))}
                    </select>
                    <small style={{color: '#999', fontSize: '12px', display: 'block', marginTop: '4px'}}>
                      客户管理员建议选择所属客户
                    </small>
                  </div>
                )}

                <div style={{
                  padding: '12px',
                  background: '#e3f2fd',
                  borderRadius: '8px',
                  marginTop: '15px',
                  fontSize: '13px',
                  color: '#1565c0'
                }}>
                  💡 提示：创建用户后，请到"权限管理"页面为操作员和查看者授权产品
                </div>

                <div className="modal-actions">
                  <button type="button" onClick={() => setShowModal(false)} className="btn-secondary">
                    取消
                  </button>
                  <button type="submit" className="btn-primary" disabled={loading}>
                    {loading ? '提交中...' : '确定'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Users;