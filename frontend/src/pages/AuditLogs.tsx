import React, { useEffect, useState } from 'react';
import Navbar from '../components/Navbar';
import { auditLogAPI, userAPI } from '../api';
import { UserRole } from '../types';
import '../styles/Page.css';

interface AuditLog {
  id: number;
  user_id: number;
  username: string;
  display_name?: string;
  action: string;
  resource_type: string;
  resource_id?: number;
  details?: string;
  ip_address?: string;
  created_at: string;
}

interface Stats {
  total: number;
  today: number;
  week: number;
  month: number;
  actionStats: { action: string; count: number }[];
  resourceStats: { resource_type: string; count: number }[];
}

const AuditLogs: React.FC = () => {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [stats, setStats] = useState<Stats | null>(null);
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [currentUserRole, setCurrentUserRole] = useState<UserRole | null>(null);
  
  // 筛选条件
  const [filterUserId, setFilterUserId] = useState(0);
  const [filterAction, setFilterAction] = useState('');
  const [filterResourceType, setFilterResourceType] = useState('');
  const [filterStartTime, setFilterStartTime] = useState('');
  const [filterEndTime, setFilterEndTime] = useState('');
  const [searchKeyword, setSearchKeyword] = useState('');
  
  // 分页
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [total, setTotal] = useState(0);
  const limit = 50;
  
  // 详情弹窗
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [selectedLog, setSelectedLog] = useState<AuditLog | null>(null);

  useEffect(() => {
    const userStr = localStorage.getItem('user');
    if (userStr) {
      const user = JSON.parse(userStr);
      setCurrentUserRole(user.role);
    }
    fetchUsers();
    fetchStats();
  }, []);

  useEffect(() => {
    fetchLogs();
  }, [page, filterUserId, filterAction, filterResourceType, filterStartTime, filterEndTime, searchKeyword]);

  const fetchUsers = async () => {
    try {
      const res = await userAPI.getUsers();
      setUsers(res.data);
    } catch (err) {
      console.error('获取用户列表失败');
    }
  };

  const fetchStats = async () => {
    try {
      const res = await auditLogAPI.getStats();
      setStats(res.data);
    } catch (err) {
      console.error('获取统计数据失败');
    }
  };

  const fetchLogs = async () => {
    setLoading(true);
    setError('');
    try {
      const params: any = { page, limit };
      if (filterUserId) params.user_id = filterUserId;
      if (filterAction) params.action = filterAction;
      if (filterResourceType) params.resource_type = filterResourceType;
      if (filterStartTime) params.start_time = filterStartTime;
      if (filterEndTime) params.end_time = filterEndTime;
      if (searchKeyword) params.search = searchKeyword;

      const res = await auditLogAPI.getLogs(params);
      setLogs(res.data.logs);
      setTotal(res.data.pagination.total);
      setTotalPages(res.data.pagination.totalPages);
    } catch (err: any) {
      setError(err.response?.data?.error || '查询失败');
    } finally {
      setLoading(false);
    }
  };

  const handleViewDetail = async (log: AuditLog) => {
    setSelectedLog(log);
    setShowDetailModal(true);
  };

  const handleExport = () => {
    const params: any = {};
    if (filterUserId) params.user_id = filterUserId;
    if (filterAction) params.action = filterAction;
    if (filterResourceType) params.resource_type = filterResourceType;
    if (filterStartTime) params.start_time = filterStartTime;
    if (filterEndTime) params.end_time = filterEndTime;
    auditLogAPI.exportCSV(params);
  };

  const getActionName = (action: string) => {
    const actionMap: { [key: string]: string } = {
      'login': '登录', 'logout': '登出', 'create': '创建', 'update': '更新', 'delete': '删除',
      'scan': '扫码', 'grant_permission': '授予权限', 'revoke_permission': '撤销权限',
      'batch_grant_permissions': '批量授权', 'batch_delete_invalid_scans': '批量删除错误记录',
      'cleanup_test_data': '清理测试数据', 'initialize_system': '初始化系统',
    };
    return actionMap[action] || action;
  };

  const getResourceTypeName = (type: string) => {
    const typeMap: { [key: string]: string } = {
      'user': '用户', 'customer': '客户', 'product': '产品',
      'scan': '扫码', 'permission': '权限', 'system': '系统',
    };
    return typeMap[type] || type;
  };

  return (
    <>
      <Navbar />
      <div className="page-container">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
          <h2>审计日志</h2>
          <button onClick={handleExport} className="btn-primary">📊 导出日志</button>
        </div>

        {error && <div className="error-msg">{error}</div>}

        {stats && (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '15px', marginBottom: '20px' }}>
            <div className="stat-card"><div className="stat-label">今日操作</div><div className="stat-value">{stats.today}</div></div>
            <div className="stat-card"><div className="stat-label">本周操作</div><div className="stat-value">{stats.week}</div></div>
            <div className="stat-card"><div className="stat-label">本月操作</div><div className="stat-value">{stats.month}</div></div>
            <div className="stat-card"><div className="stat-label">总操作数</div><div className="stat-value">{stats.total}</div></div>
          </div>
        )}

        <div className="filter-card">
          <h3>筛选条件</h3>
          <div className="filter-row">
            {currentUserRole === 'super_admin' && (
              <div className="filter-item">
                <label>用户</label>
                <select value={filterUserId} onChange={e => { setFilterUserId(parseInt(e.target.value)); setPage(1); }}>
                  <option value={0}>全部</option>
                  {users.map(u => (<option key={u.id} value={u.id}>{u.display_name || u.username}</option>))}
                </select>
              </div>
            )}
            <div className="filter-item">
              <label>操作类型</label>
              <select value={filterAction} onChange={e => { setFilterAction(e.target.value); setPage(1); }}>
                <option value="">全部</option>
                <option value="login">登录</option>
                <option value="create">创建</option>
                <option value="update">更新</option>
                <option value="delete">删除</option>
                <option value="scan">扫码</option>
                <option value="grant_permission">授予权限</option>
                <option value="revoke_permission">撤销权限</option>
              </select>
            </div>
            <div className="filter-item">
              <label>资源类型</label>
              <select value={filterResourceType} onChange={e => { setFilterResourceType(e.target.value); setPage(1); }}>
                <option value="">全部</option>
                <option value="user">用户</option>
                <option value="customer">客户</option>
                <option value="product">产品</option>
                <option value="scan">扫码</option>
                <option value="permission">权限</option>
                <option value="system">系统</option>
              </select>
            </div>
            <div className="filter-item">
              <label>搜索</label>
              <input type="text" value={searchKeyword} onChange={e => { setSearchKeyword(e.target.value); setPage(1); }} placeholder="搜索关键字..." />
            </div>
          </div>
          <div className="filter-row">
            <div className="filter-item">
              <label>起始时间</label>
              <input type="datetime-local" value={filterStartTime} onChange={e => { setFilterStartTime(e.target.value); setPage(1); }} />
            </div>
            <div className="filter-item">
              <label>结束时间</label>
              <input type="datetime-local" value={filterEndTime} onChange={e => { setFilterEndTime(e.target.value); setPage(1); }} />
            </div>
          </div>
        </div>

        <div className="list-card">
          <h3>日志记录 (共 {total} 条)</h3>
          {loading ? (<p>加载中...</p>) : logs.length === 0 ? (<p>暂无记录</p>) : (
            <>
              <table>
                <thead>
                  <tr><th>时间</th><th>用户</th><th>操作</th><th>资源类型</th><th>资源ID</th><th>IP地址</th><th>操作</th></tr>
                </thead>
                <tbody>
                  {logs.map(log => (
                    <tr key={log.id}>
                      <td>{new Date(log.created_at).toLocaleString('zh-CN')}</td>
                      <td>
                        <div className="user-info-cell">
                          <span className="user-name">{log.display_name || log.username}</span>
                          {log.display_name && log.username && (<span className="user-account">({log.username})</span>)}
                        </div>
                      </td>
                      <td>{getActionName(log.action)}</td>
                      <td>{getResourceTypeName(log.resource_type)}</td>
                      <td>{log.resource_id || '-'}</td>
                      <td>{log.ip_address || '-'}</td>
                      <td><button onClick={() => handleViewDetail(log)} className="btn-view-small">查看详情</button></td>
                    </tr>
                  ))}
                </tbody>
              </table>
              {totalPages > 1 && (
                <div className="pagination">
                  <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1} className="btn-secondary">上一页</button>
                  <span className="page-info">第 {page} / {totalPages} 页</span>
                  <button onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page === totalPages} className="btn-secondary">下一页</button>
                </div>
              )}
            </>
          )}
        </div>

        {showDetailModal && selectedLog && (
          <div className="modal-overlay" onClick={() => setShowDetailModal(false)}>
            <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: '600px' }}>
              <h3>日志详情</h3>
              <div style={{ marginTop: '20px' }}>
                <div className="detail-row"><strong>ID:</strong><span>{selectedLog.id}</span></div>
                <div className="detail-row"><strong>时间:</strong><span>{new Date(selectedLog.created_at).toLocaleString('zh-CN')}</span></div>
                <div className="detail-row"><strong>用户:</strong><span>{selectedLog.display_name || selectedLog.username} ({selectedLog.username})</span></div>
                <div className="detail-row"><strong>操作:</strong><span>{getActionName(selectedLog.action)}</span></div>
                <div className="detail-row"><strong>资源类型:</strong><span>{getResourceTypeName(selectedLog.resource_type)}</span></div>
                <div className="detail-row"><strong>资源ID:</strong><span>{selectedLog.resource_id || '-'}</span></div>
                <div className="detail-row"><strong>IP地址:</strong><span>{selectedLog.ip_address || '-'}</span></div>
                {selectedLog.details && (
                  <div className="detail-row" style={{ flexDirection: 'column', alignItems: 'flex-start' }}>
                    <strong>详细信息:</strong>
                    <pre style={{ marginTop: '8px', padding: '12px', background: '#f5f5f5', borderRadius: '4px', fontSize: '12px', overflow: 'auto', maxHeight: '300px', width: '100%' }}>
                      {JSON.stringify(JSON.parse(selectedLog.details), null, 2)}
                    </pre>
                  </div>
                )}
              </div>
              <div className="modal-actions">
                <button onClick={() => setShowDetailModal(false)} className="btn-secondary">关闭</button>
              </div>
            </div>
          </div>
        )}
      </div>
    </>
  );
};

export default AuditLogs;
