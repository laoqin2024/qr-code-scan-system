import React, { useState } from 'react';
import Navbar from '../components/Navbar';
import { scanAPI } from '../api';
import '../styles/Page.css';

const SystemManagement: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  const handleCleanupTestData = async () => {
    if (!window.confirm('确定要清理所有测试数据吗？\n\n这将删除：\n- 名称包含"测试"或"test"的客户\n- 名称包含"测试"或"test"的产品\n- 用户名包含"test"或姓名包含"测试"的用户\n- 以及相关的所有扫码记录、权限记录和审计日志\n\n⚠️ 此操作不可恢复！')) {
      return;
    }

    setLoading(true);
    setError('');
    setMessage('');

    try {
      const result = await scanAPI.cleanupTestData();
      setMessage(`清理完成！\n删除了：\n- ${result.data.deleted_customers} 个客户\n- ${result.data.deleted_products} 个产品\n- ${result.data.deleted_users} 个用户\n- ${result.data.deleted_scans} 条扫码记录\n- ${result.data.deleted_permissions} 条权限记录\n- ${result.data.deleted_audit_logs} 条审计日志`);
    } catch (err: any) {
      setError(err.response?.data?.error || '清理失败');
    } finally {
      setLoading(false);
    }
  };

  const handleInitializeSystem = async () => {
    if (!window.confirm('⚠️ 警告：确定要初始化系统吗？\n\n这将删除所有数据：\n- 所有客户\n- 所有产品\n- 所有用户（除了超级管理员）\n- 所有扫码记录\n- 所有权限记录\n- 所有审计日志\n\n只保留超级管理员账号！\n\n此操作不可恢复！')) {
      return;
    }

    // 二次确认
    if (!window.confirm('⚠️⚠️⚠️ 最后确认 ⚠️⚠️⚠️\n\n您真的要初始化系统吗？\n\n所有数据将被永久删除！\n\n请输入"确认"后点击确定')) {
      return;
    }

    setLoading(true);
    setError('');
    setMessage('');

    try {
      const result = await scanAPI.initializeSystem();
      setMessage(`系统初始化完成！\n删除了：\n- ${result.data.deleted_customers} 个客户\n- ${result.data.deleted_products} 个产品\n- ${result.data.deleted_users} 个用户\n- ${result.data.deleted_scans} 条扫码记录\n- ${result.data.deleted_permissions} 条权限记录\n- ${result.data.deleted_audit_logs} 条审计日志\n\n超级管理员账号已保留`);
    } catch (err: any) {
      setError(err.response?.data?.error || '初始化失败');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteInvalidScans = async () => {
    if (!window.confirm('确定要删除所有错误的扫码记录吗？\n\n此操作不可恢复！')) {
      return;
    }

    setLoading(true);
    setError('');
    setMessage('');

    try {
      const result = await scanAPI.batchDeleteInvalid();
      setMessage(`成功删除 ${result.data.deleted_count} 条错误记录`);
    } catch (err: any) {
      setError(err.response?.data?.error || '删除失败');
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <Navbar />
      <div className="page-container">
        <h2>系统管理</h2>
        
        {message && (
          <div className="success-msg" style={{
            padding: '12px 16px',
            background: 'linear-gradient(135deg, #e8f5e9 0%, #c8e6c9 100%)',
            border: '2px solid #4caf50',
            borderRadius: '10px',
            color: '#2e7d32',
            marginBottom: '15px',
            whiteSpace: 'pre-line'
          }}>
            {message}
          </div>
        )}
        
        {error && <div className="error-msg">{error}</div>}

        <div className="management-grid" style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
          gap: '20px',
          marginTop: '20px'
        }}>
          {/* 清理测试数据 */}
          <div className="management-card" style={{
            background: 'white',
            padding: '24px',
            borderRadius: '12px',
            boxShadow: '0 4px 20px rgba(0, 0, 0, 0.06)',
            border: '1px solid rgba(0, 0, 0, 0.05)'
          }}>
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              marginBottom: '16px'
            }}>
              <span style={{ fontSize: '32px' }}>🧹</span>
              <h3 style={{ margin: 0, color: '#444' }}>清理测试数据</h3>
            </div>
            
            <p style={{ color: '#666', marginBottom: '16px', lineHeight: '1.6' }}>
              删除所有测试相关的数据，包括：
            </p>
            <ul style={{ color: '#666', marginBottom: '20px', paddingLeft: '20px' }}>
              <li>名称包含"测试"或"test"的客户</li>
              <li>名称包含"测试"或"test"的产品</li>
              <li>用户名包含"test"的用户</li>
              <li>相关的所有扫码记录</li>
              <li>相关的所有权限记录</li>
              <li>相关的所有审计日志</li>
            </ul>
            
            <button
              onClick={handleCleanupTestData}
              disabled={loading}
              style={{
                width: '100%',
                padding: '12px',
                background: 'linear-gradient(135deg, #ff9800 0%, #f57c00 100%)',
                color: 'white',
                border: 'none',
                borderRadius: '8px',
                fontSize: '14px',
                fontWeight: '600',
                cursor: loading ? 'not-allowed' : 'pointer',
                opacity: loading ? 0.6 : 1
              }}
            >
              {loading ? '清理中...' : '清理测试数据'}
            </button>
          </div>

          {/* 删除错误记录 */}
          <div className="management-card" style={{
            background: 'white',
            padding: '24px',
            borderRadius: '12px',
            boxShadow: '0 4px 20px rgba(0, 0, 0, 0.06)',
            border: '1px solid rgba(0, 0, 0, 0.05)'
          }}>
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              marginBottom: '16px'
            }}>
              <span style={{ fontSize: '32px' }}>🗑️</span>
              <h3 style={{ margin: 0, color: '#444' }}>删除错误记录</h3>
            </div>
            
            <p style={{ color: '#666', marginBottom: '16px', lineHeight: '1.6' }}>
              删除所有无效的扫码记录，释放数据库空间。
            </p>
            <ul style={{ color: '#666', marginBottom: '20px', paddingLeft: '20px' }}>
              <li>长度不足的记录</li>
              <li>长度超出的记录</li>
              <li>其他验证失败的记录</li>
            </ul>
            
            <button
              onClick={handleDeleteInvalidScans}
              disabled={loading}
              style={{
                width: '100%',
                padding: '12px',
                background: 'linear-gradient(135deg, #f44336 0%, #d32f2f 100%)',
                color: 'white',
                border: 'none',
                borderRadius: '8px',
                fontSize: '14px',
                fontWeight: '600',
                cursor: loading ? 'not-allowed' : 'pointer',
                opacity: loading ? 0.6 : 1
              }}
            >
              {loading ? '删除中...' : '删除错误记录'}
            </button>
          </div>

          {/* 初始化系统 */}
          <div className="management-card" style={{
            background: 'white',
            padding: '24px',
            borderRadius: '12px',
            boxShadow: '0 4px 20px rgba(0, 0, 0, 0.06)',
            border: '2px solid #f44336'
          }}>
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              marginBottom: '16px'
            }}>
              <span style={{ fontSize: '32px' }}>⚠️</span>
              <h3 style={{ margin: 0, color: '#d32f2f' }}>初始化系统</h3>
            </div>
            
            <p style={{ color: '#666', marginBottom: '16px', lineHeight: '1.6' }}>
              <strong style={{ color: '#d32f2f' }}>危险操作！</strong>删除所有数据，恢复系统到初始状态。
            </p>
            <ul style={{ color: '#666', marginBottom: '20px', paddingLeft: '20px' }}>
              <li>删除所有客户</li>
              <li>删除所有产品</li>
              <li>删除所有用户（除超级管理员）</li>
              <li>删除所有扫码记录</li>
              <li>删除所有权限和审计日志</li>
              <li style={{ color: '#4caf50', fontWeight: '600' }}>✓ 保留超级管理员账号</li>
            </ul>
            
            <button
              onClick={handleInitializeSystem}
              disabled={loading}
              style={{
                width: '100%',
                padding: '12px',
                background: 'linear-gradient(135deg, #d32f2f 0%, #b71c1c 100%)',
                color: 'white',
                border: 'none',
                borderRadius: '8px',
                fontSize: '14px',
                fontWeight: '600',
                cursor: loading ? 'not-allowed' : 'pointer',
                opacity: loading ? 0.6 : 1,
                boxShadow: '0 4px 15px rgba(211, 47, 47, 0.3)'
              }}
            >
              {loading ? '初始化中...' : '⚠️ 初始化系统'}
            </button>
          </div>
        </div>

        {/* 警告提示 */}
        <div style={{
          marginTop: '30px',
          padding: '16px',
          background: 'linear-gradient(135deg, #ffebee 0%, #ffcdd2 100%)',
          border: '2px solid #f44336',
          borderRadius: '10px',
          color: '#c62828'
        }}>
          <strong>⚠️⚠️⚠️ 严重警告：</strong> 以上操作不可恢复，请谨慎使用！
          <br/>
          <strong>特别提醒：</strong> "初始化系统"会删除所有数据，建议在执行前先备份数据库！
        </div>
      </div>
    </>
  );
};

export default SystemManagement;
