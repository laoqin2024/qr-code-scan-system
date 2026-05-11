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
  const [filterCodeText, setFilterCodeText] = useState('');
  
  const [users, setUsers] = useState<any[]>([]);
  
  // 分页状态
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(50);
  
  // 统计信息
  const [totalCount, setTotalCount] = useState(0);
  const [todayCount, setTodayCount] = useState(0);
  const [validCount, setValidCount] = useState(0);
  const [invalidCount, setInvalidCount] = useState(0);

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
      
      // 前端过滤：如果有二维码搜索条件，进行模糊匹配
      let filteredScans = res.data;
      if (filterCodeText.trim()) {
        const searchText = filterCodeText.trim().toLowerCase();
        filteredScans = res.data.filter((scan: ScanRecord) => 
          scan.code_text.toLowerCase().includes(searchText)
        );
      }
      
      // 计算统计信息
      setTotalCount(filteredScans.length);
      
      // 计算今日扫码数
      const today = new Date().toISOString().split('T')[0];
      const todayScans = filteredScans.filter((scan: ScanRecord) => 
        scan.created_at.startsWith(today)
      );
      setTodayCount(todayScans.length);
      
      // 计算正常和异常数量
      const valid = filteredScans.filter((scan: ScanRecord) => scan.is_valid).length;
      setValidCount(valid);
      setInvalidCount(filteredScans.length - valid);
      
      setScans(filteredScans);
      
      // 重置到第一页
      setCurrentPage(1);
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
  }, [filterCustomerId, filterProductId, filterUserId, filterStartTime, filterEndTime, filterValid, filterCodeText]);

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

  // 分页逻辑
  const totalPages = Math.ceil(scans.length / pageSize);
  const startIndex = (currentPage - 1) * pageSize;
  const endIndex = startIndex + pageSize;
  const currentScans = scans.slice(startIndex, endIndex);

  const handlePageChange = (page: number) => {
    setCurrentPage(page);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handlePageSizeChange = (size: number) => {
    setPageSize(size);
    setCurrentPage(1);
  };

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
          <div className="filter-item filter-item-wide">
            <label>二维码搜索</label>
            <input
              type="text"
              placeholder="输入二维码内容进行搜索（支持模糊匹配）"
              value={filterCodeText}
              onChange={e => setFilterCodeText(e.target.value)}
              className="code-search-input"
            />
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
        <div className="list-header">
          <h3>扫码记录</h3>
          <div className="stats-badges">
            <span className="stats-badge badge-total">总记录数: {totalCount}</span>
            <span className="stats-badge badge-today">今日扫码: {todayCount}</span>
            <span className="stats-badge badge-valid">正常: {validCount}</span>
            <span className="stats-badge badge-invalid">异常: {invalidCount}</span>
          </div>
        </div>
        
        {loading ? (
          <p>加载中...</p>
        ) : scans.length === 0 ? (
          <p>暂无记录</p>
        ) : (
          <>
            <div className="pagination-info">
              <span>共 {totalCount} 条记录，显示第 {startIndex + 1} - {Math.min(endIndex, totalCount)} 条</span>
              <div className="page-size-selector">
                <label>每页显示：</label>
                <select value={pageSize} onChange={e => handlePageSizeChange(parseInt(e.target.value))}>
                  <option value={20}>20</option>
                  <option value={50}>50</option>
                  <option value={100}>100</option>
                  <option value={200}>200</option>
                </select>
              </div>
            </div>
            
            <table>
              <thead>
                <tr>
                  <th>序号</th>
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
                {currentScans.map((s, index) => (
                  <tr key={s.id} className={s.is_valid ? '' : 'invalid-row'}>
                    <td>{startIndex + index + 1}</td>
                    <td>{s.customer_name || getCustomerName(s.customer_id)}</td>
                    <td>{s.product_model || getProductModel(s.product_id)}</td>
                    <td className="code-text" title={s.code_text}>
                      <div className="code-text-wrapper">{s.code_text}</div>
                    </td>
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
            
            {totalPages > 1 && (
              <div className="pagination">
                <button 
                  className="pagination-btn"
                  onClick={() => handlePageChange(1)}
                  disabled={currentPage === 1}
                >
                  首页
                </button>
                <button 
                  className="pagination-btn"
                  onClick={() => handlePageChange(currentPage - 1)}
                  disabled={currentPage === 1}
                >
                  上一页
                </button>
                
                <div className="pagination-pages">
                  {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
                    let pageNum;
                    if (totalPages <= 5) {
                      pageNum = i + 1;
                    } else if (currentPage <= 3) {
                      pageNum = i + 1;
                    } else if (currentPage >= totalPages - 2) {
                      pageNum = totalPages - 4 + i;
                    } else {
                      pageNum = currentPage - 2 + i;
                    }
                    
                    return (
                      <button
                        key={pageNum}
                        className={`pagination-btn ${currentPage === pageNum ? 'active' : ''}`}
                        onClick={() => handlePageChange(pageNum)}
                      >
                        {pageNum}
                      </button>
                    );
                  })}
                </div>
                
                <button 
                  className="pagination-btn"
                  onClick={() => handlePageChange(currentPage + 1)}
                  disabled={currentPage === totalPages}
                >
                  下一页
                </button>
                <button 
                  className="pagination-btn"
                  onClick={() => handlePageChange(totalPages)}
                  disabled={currentPage === totalPages}
                >
                  末页
                </button>
                
                <span className="pagination-info-text">
                  第 {currentPage} / {totalPages} 页
                </span>
              </div>
            )}
          </>
        )}
      </div>
      </div>
    </>
  );
};

export default Query;
