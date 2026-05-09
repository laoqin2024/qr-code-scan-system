import React, { useEffect, useState } from 'react';
import Navbar from '../components/Navbar';
import api from '../api';
import { Customer } from '../types';
import '../styles/Page.css';

const Customers: React.FC = () => {
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(false);
  const [name, setName] = useState('');
  const [expectedLength, setExpectedLength] = useState(0);
  const [description, setDescription] = useState('');
  const [error, setError] = useState('');
  const [editingId, setEditingId] = useState<number | null>(null);
  const [showModal, setShowModal] = useState(false);

  const fetchCustomers = async () => {
    setLoading(true);
    try {
      const res = await api.get('/customers');
      setCustomers(res.data);
    } catch (err: any) {
      setError(err.response?.data?.error || '获取客户列表失败');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCustomers();
  }, []);

  const handleAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    try {
      if (editingId) {
        // 编辑
        await api.put(`/customers/${editingId}`, { name, expected_length: expectedLength, description });
        alert('修改成功');
      } else {
        // 新增
        await api.post('/customers', { name, expected_length: expectedLength, description });
        alert('新增成功');
      }
      setName('');
      setExpectedLength(0);
      setDescription('');
      setEditingId(null);
      setShowModal(false);
      fetchCustomers();
    } catch (err: any) {
      setError(err.response?.data?.error || '操作失败');
    }
  };

  const handleEdit = (customer: Customer) => {
    setEditingId(customer.id);
    setName(customer.name);
    setExpectedLength(customer.expected_length);
    setDescription(customer.description || '');
    setShowModal(true);
    setError('');
  };

  const handleCreate = () => {
    setEditingId(null);
    setName('');
    setExpectedLength(0);
    setDescription('');
    setShowModal(true);
    setError('');
  };

  const handleDelete = async (id: number) => {
    if (!window.confirm('确定删除该客户吗？')) return;
    try {
      await api.delete(`/customers/${id}`);
      fetchCustomers();
    } catch (err: any) {
      setError(err.response?.data?.error || '删除失败');
    }
  };

  return (
    <>
      <Navbar />
      <div className="page-container">
        <div className="page-header">
          <h2>客户维护</h2>
          <button onClick={handleCreate} className="btn-primary">+ 新增客户</button>
        </div>
        {error && <div className="error-msg">{error}</div>}

      <div className="list-card">
        <h3>客户列表</h3>
        {loading ? (
          <p>加载中...</p>
        ) : customers.length === 0 ? (
          <p>暂无客户</p>
        ) : (
          <table>
            <thead>
              <tr>
                <th>客户名称</th>
                <th>期望长度</th>
                <th>创建者</th>
                <th>描述</th>
                <th>创建时间</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              {customers.map(c => (
                <tr key={c.id}>
                  <td>{c.name}</td>
                  <td>{c.expected_length}</td>
                  <td>
                    <span className="creator-badge">
                      {c.created_by_display_name || c.created_by_username || '-'}
                    </span>
                  </td>
                  <td>{c.description || '-'}</td>
                  <td>{new Date(c.created_at).toLocaleString('zh-CN')}</td>
                  <td>
                    {c.can_edit ? (
                      <div className="action-buttons">
                        <button onClick={() => handleEdit(c)} className="btn-edit">编辑</button>
                        <button onClick={() => handleDelete(c.id)} className="btn-delete">删除</button>
                      </div>
                    ) : (
                      <span className="readonly-badge">只读</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
      
      {/* 编辑/新增模态框 */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal-content" onClick={e => e.stopPropagation()}>
            <h3>{editingId ? '编辑客户' : '新增客户'}</h3>
            {error && <div className="error-msg">{error}</div>}
            <form onSubmit={handleAdd}>
              <div className="form-group">
                <label>客户名称 *</label>
                <input
                  type="text"
                  value={name}
                  onChange={e => setName(e.target.value)}
                  placeholder="请输入客户名称"
                  required
                />
              </div>
              <div className="form-group">
                <label>期望二维码长度 *</label>
                <input
                  type="number"
                  value={expectedLength}
                  onChange={e => setExpectedLength(parseInt(e.target.value))}
                  placeholder="请输入期望长度"
                  required
                />
              </div>
              <div className="form-group">
                <label>描述</label>
                <input
                  type="text"
                  value={description}
                  onChange={e => setDescription(e.target.value)}
                  placeholder="请输入描述"
                />
              </div>
              <div className="modal-actions">
                <button type="button" onClick={() => setShowModal(false)} className="btn-secondary">
                  取消
                </button>
                <button type="submit" className="btn-primary">
                  {editingId ? '保存' : '新增'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
      </div>
    </>
  );
};

export default Customers;
