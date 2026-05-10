import React from 'react';
import '../styles/ConfirmDialog.css';

interface ConfirmDialogProps {
  show: boolean;
  type: 'duplicate' | 'error';
  title: string;
  message: string;
  onConfirm: () => void;
}

const ConfirmDialog: React.FC<ConfirmDialogProps> = ({ show, type, title, message, onConfirm }) => {
  if (!show) return null;

  const getIcon = () => {
    if (type === 'duplicate') {
      return '🔄'; // 重复图标
    } else {
      return '⚠️'; // 错误图标
    }
  };

  const getIconColor = () => {
    if (type === 'duplicate') {
      return '#ff9800'; // 橙色
    } else {
      return '#f44336'; // 红色
    }
  };

  return (
    <div className="confirm-dialog-overlay" onClick={onConfirm}>
      <div className="confirm-dialog" onClick={(e) => e.stopPropagation()}>
        <div className="confirm-dialog-icon" style={{ color: getIconColor() }}>
          {getIcon()}
        </div>
        <div className="confirm-dialog-title">{title}</div>
        <div className="confirm-dialog-message">{message}</div>
        <div className="confirm-dialog-actions">
          <button className="confirm-dialog-button" onClick={onConfirm}>
            确定
          </button>
        </div>
      </div>
    </div>
  );
};

export default ConfirmDialog;
