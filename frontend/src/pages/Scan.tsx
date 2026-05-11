import React, { useEffect, useState, useRef } from 'react';
import Navbar from '../components/Navbar';
import ConfirmDialog from '../components/ConfirmDialog';
import api from '../api';
import { Customer, Product, ScanRecord } from '../types';
import '../styles/Scan.css';

interface TodayScanRecord extends ScanRecord {
  customer_name?: string;
  product_model?: string;
}

const Scan: React.FC = () => {
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [customerId, setCustomerId] = useState(0);
  const [productId, setProductId] = useState(0);
  const [codeText, setCodeText] = useState('');
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(false);
  const [statusMessage, setStatusMessage] = useState(''); // 状态信息（显示在长度区域）
  const [statusType, setStatusType] = useState<'success' | 'error' | ''>(''); // 状态类型
  const [todayScans, setTodayScans] = useState<TodayScanRecord[]>([]);
  const [showStats, setShowStats] = useState(false);
  const [continuousMode, setContinuousMode] = useState(true);
  const [autoSubmit, setAutoSubmit] = useState(true);
  const [lastInputTime, setLastInputTime] = useState<number>(0);
  const codeInputRef = useRef<HTMLTextAreaElement>(null);
  const autoSubmitTimerRef = useRef<NodeJS.Timeout | null>(null);
  
  // 确认对话框状态
  const [showDialog, setShowDialog] = useState(false);
  const [dialogType, setDialogType] = useState<'duplicate' | 'error'>('error');
  const [dialogTitle, setDialogTitle] = useState('');
  const [dialogMessage, setDialogMessage] = useState('');

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

  const fetchTodayScans = async () => {
    try {
      const today = new Date().toISOString().split('T')[0];
      const res = await api.get('/scans', {
        params: {
          start_time: `${today} 00:00:00`,
          end_time: `${today} 23:59:59`
        }
      });
      const scansWithNames = res.data.map((scan: ScanRecord) => ({
        ...scan,
        customer_name: customers.find(c => c.id === scan.customer_id)?.name || '-',
        product_model: products.find(p => p.id === scan.product_id)?.model || '-'
      }));
      setTodayScans(scansWithNames);
    } catch (err) {
      console.error('获取今日扫码记录失败');
    }
  };

  useEffect(() => {
    fetchCustomers();
    fetchProducts();
  }, []);

  useEffect(() => {
    if (customers.length > 0 && products.length > 0) {
      fetchTodayScans();
    }
  }, [customers, products]);

  // 当客户改变时，重置产品选择
  useEffect(() => {
    setProductId(0);
  }, [customerId]);

  // 根据选择的客户过滤产品
  const filteredProducts = customerId 
    ? products.filter(p => p.customer_id === customerId)
    : products;

  const getCustomer = (id: number) => customers.find(c => c.id === id);
  const currentCustomer = getCustomer(customerId);
  const codeLength = codeText.length;
  const expectedLength = currentCustomer?.expected_length || 0;
  const isValid = expectedLength === 0 || codeLength === expectedLength;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setStatusMessage('');
    setStatusType('');

    if (!customerId) {
      setStatusMessage('请选择客户');
      setStatusType('error');
      return;
    }
    if (!productId) {
      setStatusMessage('请选择产品');
      setStatusType('error');
      return;
    }
    if (!codeText.trim()) {
      setStatusMessage('请输入二维码内容');
      setStatusType('error');
      return;
    }

    const trimmedCode = codeText.trim();
    
    // 检查是否重复扫码（在今日记录中查找相同的二维码）
    const isDuplicate = todayScans.some(scan => 
      scan.code_text === trimmedCode && 
      scan.customer_id === customerId && 
      scan.product_id === productId
    );

    if (isDuplicate) {
      // 重复扫码：显示自定义对话框
      setDialogType('duplicate');
      setDialogTitle('重复扫码警告');
      setDialogMessage(
        `该二维码今日已扫描过！\n\n` +
        `二维码内容:\n${trimmedCode}\n\n` +
        `客户: ${currentCustomer?.name}\n` +
        `产品: ${products.find(p => p.id === productId)?.model}\n\n` +
        `此数据不会被保存，请继续扫描下一个二维码。`
      );
      setShowDialog(true);
      return; // 不保存，等待用户点击确定
    }

    // 检查长度是否匹配
    if (!isValid) {
      // 长度不匹配：显示自定义对话框，包含详细的错误数据
      const errorReason = codeLength < expectedLength ? '长度不足' : '长度超出';
      const diff = Math.abs(codeLength - expectedLength);
      
      // 构建详细的错误信息
      let errorDetails = `${errorReason}！相差 ${diff} 个字符\n\n`;
      errorDetails += `期望长度: ${expectedLength}\n`;
      errorDetails += `实际长度: ${codeLength}\n\n`;
      errorDetails += `错误数据内容:\n${trimmedCode}\n\n`;
      
      // 如果长度不足，显示缺少多少
      if (codeLength < expectedLength) {
        errorDetails += `缺少: ${diff} 个字符\n`;
        errorDetails += `当前: [${trimmedCode}]\n`;
        errorDetails += `应为: [${trimmedCode}${'?'.repeat(diff)}]\n\n`;
      } else {
        // 如果长度超出，显示多余的部分
        const extra = trimmedCode.substring(expectedLength);
        const normal = trimmedCode.substring(0, expectedLength);
        errorDetails += `正常部分: [${normal}]\n`;
        errorDetails += `多余部分: [${extra}] (${diff} 个字符)\n\n`;
      }
      
      errorDetails += `客户: ${currentCustomer?.name}\n`;
      errorDetails += `产品: ${products.find(p => p.id === productId)?.model}\n\n`;
      errorDetails += `此异常数据不会被保存，请检查后重新扫描。`;
      
      setDialogType('error');
      setDialogTitle('数据异常警告');
      setDialogMessage(errorDetails);
      setShowDialog(true);
      return; // 不保存，等待用户点击确定
    }

    setLoading(true);
    try {
      const res = await api.post('/scans', {
        customer_id: customerId,
        product_id: productId,
        code_text: trimmedCode,
        notes
      });
      
      // 刷新今日扫码列表
      await fetchTodayScans();
      
      // 根据结果显示状态
      if (res.data.is_valid) {
        // 正常：显示绿色成功信息
        setStatusMessage('✓ 扫码成功');
        setStatusType('success');
        
        // 清空输入框
        setCodeText('');
        setNotes('');
        
        // 聚焦输入框
        setTimeout(() => {
          codeInputRef.current?.focus();
        }, 100);
        
        // 2秒后清除状态信息
        setTimeout(() => {
          setStatusMessage('');
          setStatusType('');
        }, 2000);
      } else {
        // 错误：显示红色错误信息
        setStatusMessage(`✗ ${res.data.error_reason}`);
        setStatusType('error');
        
        // 清空输入框但保持错误提示
        setCodeText('');
        setNotes('');
        
        // 聚焦输入框
        setTimeout(() => {
          codeInputRef.current?.focus();
        }, 100);
      }
    } catch (err: any) {
      setStatusMessage(err.response?.data?.error || '保存失败');
      setStatusType('error');
    } finally {
      setLoading(false);
    }
  };

  // 处理对话框确认
  const handleDialogConfirm = () => {
    setShowDialog(false);
    // 清空输入框
    setCodeText('');
    setNotes('');
    // 聚焦输入框
    setTimeout(() => {
      codeInputRef.current?.focus();
    }, 100);
  };

  // 处理输入变化（用于扫码枪智能检测）
  const handleCodeChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    const value = e.target.value;
    setCodeText(value);
    setLastInputTime(Date.now());
    
    // 用户继续输入时，清除错误提示，显示实时长度信息
    if (statusType === 'error') {
      setStatusMessage('');
      setStatusType('');
    }

    // 如果开启自动提交且不是连续模式，设置定时器
    if (autoSubmit && !continuousMode && value.trim()) {
      // 清除之前的定时器
      if (autoSubmitTimerRef.current) {
        clearTimeout(autoSubmitTimerRef.current);
      }
      
      // 设置新的定时器：300ms内没有新输入则自动提交
      // 这个时间足够扫码枪完成输入，但不会影响手动输入
      autoSubmitTimerRef.current = setTimeout(() => {
        if (customerId && productId && value.trim()) {
          // 模拟表单提交
          const form = codeInputRef.current?.form;
          if (form) {
            form.requestSubmit();
          }
        }
      }, 300);
    }
  };

  // 处理键盘事件（检测回车键）
  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    // 检测到回车键
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      
      // 如果开启自动提交且有内容，直接提交
      if (autoSubmit && codeText.trim() && customerId && productId) {
        const form = codeInputRef.current?.form;
        if (form) {
          form.requestSubmit();
        }
      }
    }
  };

  // 清理定时器
  useEffect(() => {
    return () => {
      if (autoSubmitTimerRef.current) {
        clearTimeout(autoSubmitTimerRef.current);
      }
    };
  }, []);

  const handleFinishScanning = () => {
    setShowStats(true);
  };

  const handleContinueScanning = () => {
    setShowStats(false);
  };

  const getTodayStats = () => {
    const total = todayScans.length;
    const valid = todayScans.filter(s => s.is_valid).length;
    const invalid = total - valid;
    const validRate = total > 0 ? ((valid / total) * 100).toFixed(1) : '0';
    
    // 计算当前用户今日扫码数
    const userStr = localStorage.getItem('user');
    let myScans = 0;
    if (userStr) {
      const user = JSON.parse(userStr);
      myScans = todayScans.filter(s => s.user_id === user.id).length;
    }
    
    return { total, valid, invalid, validRate, myScans };
  };

  const stats = getTodayStats();

  return (
    <>
      <Navbar />
      <div className="page-container">
        <div className="scan-header">
          <h2>扫码录入</h2>
          <div className="header-right">
            <div className="scan-gun-toggle">
              <label className="toggle-label">
                <input
                  type="checkbox"
                  checked={autoSubmit}
                  onChange={(e) => setAutoSubmit(e.target.checked)}
                />
                <span className="toggle-slider"></span>
                <span className="toggle-text">扫码枪模式</span>
              </label>
            </div>
            <div className="continuous-mode-toggle">
              <label className="toggle-label">
                <input
                  type="checkbox"
                checked={continuousMode}
                onChange={(e) => setContinuousMode(e.target.checked)}
              />
              <span className="toggle-slider"></span>
              <span className="toggle-text">连续扫码</span>
            </label>
          </div>
        </div>
      </div>

      <div className="form-card">
        {autoSubmit && (
          <div className="scan-gun-tip">
            <span className="tip-icon">🔫</span>
            <div className="tip-content">
              <strong>扫码枪模式已开启</strong>
              <p>• 带回车码：扫描后自动提交</p>
              <p>• 无回车码：扫描完成300ms后自动提交</p>
            </div>
          </div>
        )}
        {continuousMode && !autoSubmit && (
          <div className="continuous-mode-tip">
            <span className="tip-icon">⚡</span>
            <span className="tip-text">连续扫码模式已开启：正常扫码后将自动清空输入框，等待下一次扫码</span>
          </div>
        )}
        <form onSubmit={handleSubmit}>
          <div className="form-grid">
            <div className="form-group">
              <label>选择客户</label>
              <select value={customerId} onChange={e => setCustomerId(parseInt(e.target.value))} required>
                <option value={0}>请选择客户</option>
                {customers.map(c => (
                  <option key={c.id} value={c.id}>
                    {c.name} (期望长度: {c.expected_length})
                  </option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label>选择产品</label>
              <select value={productId} onChange={e => setProductId(parseInt(e.target.value))} required disabled={!customerId}>
                <option value={0}>请选择产品</option>
                {filteredProducts.map(p => (
                  <option key={p.id} value={p.id}>{p.model}</option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label>备注</label>
              <input
                type="text"
                value={notes}
                onChange={e => setNotes(e.target.value)}
                placeholder="可选"
              />
            </div>

            <div className="form-group form-grid-full">
              <label>
                二维码内容 
                {autoSubmit && <span className="scan-gun-badge">扫码枪</span>}
                {continuousMode && !autoSubmit && <span className="quick-scan-badge">快速扫码</span>}
              </label>
              <div className="code-input-wrapper">
                <textarea
                  ref={codeInputRef}
                  value={codeText}
                  onChange={handleCodeChange}
                  onKeyDown={handleKeyDown}
                  placeholder={
                    autoSubmit 
                      ? "使用扫码枪扫描，自动提交..." 
                      : continuousMode 
                        ? "扫描或粘贴二维码，正常扫码后自动清空..." 
                        : "粘贴或输入二维码扫描内容"
                  }
                  maxLength={100}
                  required
                  autoFocus
                />
                <span className={`char-counter ${codeText.length > 80 ? 'warning' : ''}`}>
                  {codeText.length}/100
                </span>
              </div>
            </div>
          </div>

          {customerId && currentCustomer && (
            <div className={`length-info ${statusType === 'success' ? 'status-success' : statusType === 'error' ? 'status-error' : isValid ? 'valid' : 'invalid'}`}>
              {statusMessage ? (
                // 显示状态信息
                <span className="status-message">{statusMessage}</span>
              ) : (
                // 显示长度信息
                <>
                  <span>期望: {expectedLength}</span>
                  <span>实际: {codeLength}</span>
                  <span>{isValid ? '✓ 正确' : '✗ 异常'}</span>
                </>
              )}
            </div>
          )}

          <div className="button-group">
            <button type="submit" disabled={loading} className="btn-submit">
              {loading ? '保存中...' : '提交保存'}
            </button>
            <button 
              type="button" 
              onClick={handleFinishScanning}
              className="btn-finish"
              disabled={todayScans.length === 0}
            >
              完成扫码
            </button>
          </div>
        </form>
      </div>

      {/* 今日扫码列表 */}
      <div className="today-scans-card">
        <div className="list-header">
          <h3>今日扫码记录</h3>
          <div className="stats-badges">
            <span className="stats-badge badge-total">今日总数: {stats.total}</span>
            <span className="stats-badge badge-my">我的扫码: {stats.myScans}</span>
            <span className="stats-badge badge-valid">正常: {stats.valid}</span>
            <span className="stats-badge badge-invalid">异常: {stats.invalid}</span>
            <span className="stats-badge badge-rate">正常率: {stats.validRate}%</span>
          </div>
        </div>
        {todayScans.length === 0 ? (
          <div className="empty-state">
            <p>暂无今日扫码记录</p>
          </div>
        ) : (
          <div className="scans-table-wrapper">
            <table className="scans-table">
              <thead>
                <tr>
                  <th>序号</th>
                  <th>客户</th>
                  <th>产品</th>
                  <th>二维码</th>
                  <th>长度</th>
                  <th>状态</th>
                  <th>时间</th>
                </tr>
              </thead>
              <tbody>
                {todayScans.map((scan, index) => (
                  <tr key={scan.id} className={!scan.is_valid ? 'invalid-row' : ''}>
                    <td>{index + 1}</td>
                    <td>{scan.customer_name}</td>
                    <td>{scan.product_model}</td>
                    <td className="code-text">{scan.code_text}</td>
                    <td>{scan.code_length}</td>
                    <td>
                      <span className={scan.is_valid ? 'badge-success' : 'badge-danger'}>
                        {scan.is_valid ? '✓ 正常' : '✗ 异常'}
                      </span>
                    </td>
                    <td>{scan.created_at.split(' ')[1]}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* 统计弹窗 */}
      {showStats && (
        <div className="stats-modal-overlay" onClick={handleContinueScanning}>
          <div className="stats-modal" onClick={(e) => e.stopPropagation()}>
            <div className="stats-modal-header">
              <h2>📊 今日扫码统计</h2>
              <button className="close-btn" onClick={handleContinueScanning}>✕</button>
            </div>
            <div className="stats-modal-body">
              <div className="stats-grid">
                <div className="stat-card stat-total">
                  <div className="stat-icon">📦</div>
                  <div className="stat-value">{stats.total}</div>
                  <div className="stat-label">总扫码数</div>
                </div>
                <div className="stat-card stat-valid">
                  <div className="stat-icon">✓</div>
                  <div className="stat-value">{stats.valid}</div>
                  <div className="stat-label">正常数量</div>
                </div>
                <div className="stat-card stat-invalid">
                  <div className="stat-icon">✗</div>
                  <div className="stat-value">{stats.invalid}</div>
                  <div className="stat-label">异常数量</div>
                </div>
                <div className="stat-card stat-rate">
                  <div className="stat-icon">📈</div>
                  <div className="stat-value">{stats.validRate}%</div>
                  <div className="stat-label">正常率</div>
                </div>
              </div>
              
              {stats.invalid > 0 && (
                <div className="warning-box">
                  <div className="warning-icon">⚠️</div>
                  <div className="warning-text">
                    <strong>注意：</strong>今日有 {stats.invalid} 条异常记录，请及时处理！
                  </div>
                </div>
              )}

              <div className="stats-summary">
                <p>✅ 今日共扫码 <strong>{stats.total}</strong> 次</p>
                <p>✅ 正常率为 <strong>{stats.validRate}%</strong></p>
                {stats.validRate === '100.0' && (
                  <p className="perfect-score">🎉 完美！所有扫码均正常！</p>
                )}
              </div>
            </div>
            <div className="stats-modal-footer">
              <button className="btn-continue" onClick={handleContinueScanning}>
                继续扫码
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 确认对话框 */}
      <ConfirmDialog
        show={showDialog}
        type={dialogType}
        title={dialogTitle}
        message={dialogMessage}
        onConfirm={handleDialogConfirm}
      />
      </div>
    </>
  );
};

export default Scan;
