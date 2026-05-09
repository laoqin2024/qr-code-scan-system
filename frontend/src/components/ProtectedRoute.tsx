import React from 'react';
import { Navigate } from 'react-router-dom';
import type { UserRole } from '../types';

const isAuthenticated = () => {
  return !!localStorage.getItem('token');
};

const getUserRole = (): UserRole | null => {
  const userStr = localStorage.getItem('user');
  if (userStr) {
    const user = JSON.parse(userStr);
    return user.role;
  }
  return null;
};

interface ProtectedRouteProps {
  children: React.ReactNode;
  requiredRole?: UserRole | UserRole[];
}

const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ children, requiredRole }) => {
  if (!isAuthenticated()) {
    return <Navigate to="/login" replace />;
  }
  
  // 如果指定了角色要求，检查用户角色
  if (requiredRole) {
    const userRole = getUserRole();
    const allowedRoles = Array.isArray(requiredRole) ? requiredRole : [requiredRole];
    
    if (!userRole || !allowedRoles.includes(userRole)) {
      // 无权限，返回首页
      return <Navigate to="/query" replace />;
    }
  }
  
  return <>{children}</>;
};

export default ProtectedRoute;
