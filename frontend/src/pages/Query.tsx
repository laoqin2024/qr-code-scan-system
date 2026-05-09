import React, { useEffect, useState } from 'react';
import Navbar from '../components/Navbar';
import api, { scanAPI } from '../api';
import { ScanRecord, Customer, Product, UserRole } from '../types';
import '../styles/Page.css';

const Query: React.FC = () => {
  const [scans, setScans] = useState<ScanRecord[]>([]);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [currentUserRole, setCurrentUserRole] = useState<UserRole | null>(null);
  
  const [filterCustomerId, setFilterCustomerId] = useState(0);
  const [filterProductId, setFilterProductId] = useState(0);
  const [filterUserId, setFilterUserId] = useState(0);
  const [filterStartTime, setFilterStartTime] = useState('');
  const [filterEndTime, setFilterEndTime] = useState('');
  const [filterValid, setFilterValid] = useState<any>('');
  
  const [users, setUsers] = useState<any[]>([]);

  useEffect(() => {
    // 获取当前用户角色
    const userStr = localStorage.getItem('user');
    if (userStr) {
      const user = JSON.parse(userStr);
      setCurrentUserRole(user.role);
    }
  }, []);

  const fetchCustomers = async () => {
    try {
      const res = await api.get('/customers');
      setCustomers(res.data);
    } catch (err) {
      console.error('获取客户列表失败');
    }
  };

  const fetchProducts = async () => {
    try {
      const res = await api.get('/products');
      setProducts(res.data);
    } catch (err) {
      console.error('获取产品列表失败');
    }
  };

  const fetchUsers = async () => {
    try {
      const res = await api.get('/users');
      setUsers(res.data);
    } catch (err) {
      console.error('获取用户列表失败');
    }
  };

  const fetchScans = async () => {
    setLoading(true);
    setError('');
    try {
      const params: any = {};
      if (filterCustomerId) params.customer_id = filterCustomerId;
      if (filterProductId) params.product_id = filterProductId;
      if (filterUserId) params.user_id = filterUserId;
      if (filterStartTime) params.start_time = filterStartTime;
      if (filterEndTime) params.end_time = filterEndTime;
      if (filterValid !== '') params.is_valid = filterValid === 'true' ? 1 : 0;

      const res = await api.get('/scans', { params });
      setScans(res.data);
    } catch (err: any) {
      setError(err.response?.data?.error || '查询失败');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCustomers();
    fetchProducts();
    fetchUsers();
  }, []);

  useEffect(() => {
    fetchScans();
  }, [filterCustomerId, filterProductId, filterUserId, filterStartTime, filterEndTime, filterValid]);

  // 当客户改变时，重置产品选择
  useEffect(() => {
    setFilterProductId(0);
  }, [filterCustomerId]);

  // 根据选择的客户过滤产品
  const filteredProducts = filterCustomerId 
    ? products.filter(p => p.customer_id === filterCustomerId)
    : products;

  const getCustomerName = (id: number) => customers.find(c => c.id === id)?.name || '-';
  const getProductModel = (id: number) => products.find(p => p.id === id)?.model || '-';

  const handleDelete = async (id: number) => {
    if (!window.confirm('确定要删除这条扫码记录吗？')) return;
    
    try {
      await scanAPI.deleteScan(id);
      alert('删除成功');
      fetchScans();
    } catch (err: any) {
      alert(err.response?.data?.error || '删除失败');
    }
  };

  return (
    <>
      <Navbar />
      <div className="page-container">
        <h2>扫码查询</h2>
        {error && <div className="error-msg">{error}</div>}

        <div className="filter-card">
          <h3>筛选条件</h3>
          <div className="filter-row">
            <div className="filter-item">
            <label>客户</label>
            <select value={filterCustomerId} onChange={e => setFilterCustomerId(parseInt(e.target.value))}>
              <option value={0}>全部</option>
              {customers.map(c => (
                <option key={c.id} value={c.id}>{c.name}</option>
              ))}
            </select>
          </div>
          <div className="filter-item">
            <label>产品</label>
            <select value={filterProductId} onChange={e => setFilterProductId(parseInt(e.target.value))}>
              <option value={0}>全部</option>
              {filteredProducts.map(p => (
                <option key={p.id} value={p.id}>{p.model}</option>
              ))}
            </select>
          </div>
          <div className="filter-item">
            <label>录入人员</label>
            <select value={filterUserId} onChange={e => setFilterUserId(parseInt(e.target.value))}>
              <option value={0}>全部</option>
              {users.map(u => (
                <option key={u.id} value={u.id}>{u.display_name || u.username}</option>
              ))}
            </select>
          </div>
          <div className="filter-item">
            <label>状态</label>
            <select value={filterValid} onChange={e => setFilterValid(e.target.value)}>
              <option value="">全部</option>
              <option value="true">正常</option>
              <option value="false">异常</option>
            </select>
          </div>
        </div>
        <div className="filter-row">
          <div className="filter-item">
            <label>起始时间</label>
            <input
              type="datetime-local"
              value={filterStartTime}
              onChange={e => setFilterStartTime(e.target.value)}
            />
          </div>
          <div className="filter-item">
            <label>结束时间</label>
            <input
              type="datetime-local"
              value={filterEndTime}
              onChange={e => setFilterEndTime(e.target.value)}
            />
          </div>
        </div>
      </div>

      <div className="list-card">
        <h3>扫码记录</h3>
        {loading ? (
          <p>加载中...</p>
        ) : scans.length === 0 ? (
          <p>暂无记录</p>
        ) : (
          <table>
            <thead>
              <tr>
                <th>客户</th>
                <th>产品</th>
                <th>二维码</th>
                <th>长度</th>
                <th>录入人员</th>
                <th>状态</th>
                <th>异常原因</th>
                <th>备注</th>
                <th>时间</th>
                {currentUserRole === 'super_admin' && <th>操作</th>}
              </tr>
            </thead>
            <tbody>
              {scans.map(s => (
                <tr key={s.id} className={s.is_valid ? '' : 'invalid-row'}>
                  <td>{s.customer_name || getCustomerName(s.customer_id)}</td>
                  <td>{s.product_model || getProductModel(s.product_id)}</td>
                  <td className="code-text">{s.code_text}</td>
                  <td>{s.code_length}</td>
                  <td>
                    <div className="user-info-cell">
                      <span className="user-name">{s.display_name || s.username || '-'}</span>
                      {s.display_name && s.username && (
                        <span className="user-account">({s.username})</span>
                      )}
                    </div>
                  </td>
                  <td>
                    <span className={s.is_valid ? 'badge-success' : 'badge-danger'}>
                      {s.is_valid ? '✓ 正常' : '✗ 异常'}
                    </span>
                  </td>
                  <td>{s.error_reason || '-'}</td>
                  <td>{s.notes || '-'}</td>
                  <td>{new Date(s.created_at).toLocaleString('zh-CN')}</td>
                  {currentUserRole === 'super_admin' && (
                    <td>
                      <button onClick={() => handleDelete(s.id)} className="btn-delete-small">删除</button>
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
      </div>
    </>
  );
};

export default Query;
