import React, { useEffect, useState } from 'react';
import Navbar from '../components/Navbar';
import api from '../api';
import { Product, Customer } from '../types';
import '../styles/Page.css';

const Products: React.FC = () => {
  const [products, setProducts] = useState<Product[]>([]);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(false);
  const [model, setModel] = useState('');
  const [customerId, setCustomerId] = useState(0);
  const [description, setDescription] = useState('');
  const [error, setError] = useState('');
  const [editingId, setEditingId] = useState<number | null>(null);
  const [showModal, setShowModal] = useState(false);

  const fetchProducts = async () => {
    setLoading(true);
    try {
      const res = await api.get('/products');
      setProducts(res.data);
    } catch (err: any) {
      setError(err.response?.data?.error || '获取产品列表失败');
    } finally {
      setLoading(false);
    }
  };

  const fetchCustomers = async () => {
    try {
      const res = await api.get('/customers');
      setCustomers(res.data);
    } catch (err: any) {
      console.error('获取客户列表失败');
    }
  };

  useEffect(() => {
    fetchProducts();
    fetchCustomers();
  }, []);

  const handleAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    if (!customerId) {
      setError('请选择客户');
      return;
    }
    try {
      if (editingId) {
        // 编辑
        await api.put(`/products/${editingId}`, { model, description });
        alert('修改成功');
      } else {
        // 新增
        await api.post('/products', { model, customer_id: customerId, description });
        alert('新增成功');
      }
      setModel('');
      setCustomerId(0);
      setDescription('');
      setEditingId(null);
      setShowModal(false);
      fetchProducts();
    } catch (err: any) {
      setError(err.response?.data?.error || '操作失败');
    }
  };

  const handleEdit = (product: Product) => {
    setEditingId(product.id);
    setModel(product.model);
    setCustomerId(product.customer_id);
    setDescription(product.description || '');
    setShowModal(true);
    setError('');
  };

  const handleCreate = () => {
    setEditingId(null);
    setModel('');
    setCustomerId(0);
    setDescription('');
    setShowModal(true);
    setError('');
  };

  const handleDelete = async (id: number) => {
    if (!window.confirm('确定删除该产品吗？')) return;
    try {
      await api.delete(`/products/${id}`);
      fetchProducts();
    } catch (err: any) {
      setError(err.response?.data?.error || '删除失败');
    }
  };

  const getCustomerName = (customerId: number) => {
    const c = customers.find(x => x.id === customerId);
    return c?.name || '-';
  };

  return (
    <>
      <Navbar />
      <div className="page-container">
        <div className="page-header">
          <h2>产品维护</h2>
          <button onClick={handleCreate} className="btn-primary">+ 新增产品</button>
        </div>
        {error && <div className="error-msg">{error}</div>}

      <div className="list-card">
        <h3>产品列表</h3>
        {loading ? (
          <p>加载中...</p>
        ) : products.length === 0 ? (
          <p>暂无产品</p>
        ) : (
          <table>
            <thead>
              <tr>
                <th>产品型号</th>
                <th>关联客户</th>
                <th>创建者</th>
                <th>描述</th>
                <th>创建时间</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              {products.map(p => (
                <tr key={p.id}>
                  <td>{p.model}</td>
                  <td>{p.customer_name || getCustomerName(p.customer_id)}</td>
                  <td>
                    <span className="creator-badge">
                      {p.created_by_display_name || p.created_by_username || '-'}
                    </span>
                  </td>
                  <td>{p.description || '-'}</td>
                  <td>{new Date(p.created_at).toLocaleString('zh-CN')}</td>
                  <td>
                    {p.can_edit ? (
                      <div className="action-buttons">
                        <button onClick={() => handleEdit(p)} className="btn-edit">编辑</button>
                        <button onClick={() => handleDelete(p.id)} className="btn-delete">删除</button>
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
            <h3>{editingId ? '编辑产品' : '新增产品'}</h3>
            {error && <div className="error-msg">{error}</div>}
            <form onSubmit={handleAdd}>
              <div className="form-group">
                <label>产品型号 *</label>
                <input
                  type="text"
                  value={model}
                  onChange={e => setModel(e.target.value)}
                  placeholder="请输入产品型号"
                  required
                />
              </div>
              <div className="form-group">
                <label>关联客户 *</label>
                <select 
                  value={customerId} 
                  onChange={e => setCustomerId(parseInt(e.target.value))} 
                  required
                  disabled={!!editingId}
                >
                  <option value={0}>请选择客户</option>
                  {customers.map(c => (
                    <option key={c.id} value={c.id}>{c.name}</option>
                  ))}
                </select>
                {editingId && <small style={{color: '#999'}}>编辑时不能修改关联客户</small>}
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

export default Products;
