import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
import Customers from './pages/Customers';
import Products from './pages/Products';
import Scan from './pages/Scan';
import Query from './pages/Query';
import Users from './pages/Users';
import SystemManagement from './pages/SystemManagement';
import PermissionManagement from './pages/PermissionManagement';
import AuditLogs from './pages/AuditLogs';
import ProtectedRoute from './components/ProtectedRoute';

const App: React.FC = () => {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/customers" element={<ProtectedRoute requiredRole={['super_admin', 'customer_admin']}><Customers /></ProtectedRoute>} />
      <Route path="/products" element={<ProtectedRoute requiredRole={['super_admin', 'customer_admin']}><Products /></ProtectedRoute>} />
      <Route path="/scan" element={<ProtectedRoute requiredRole={['super_admin', 'customer_admin', 'operator']}><Scan /></ProtectedRoute>} />
      <Route path="/query" element={<ProtectedRoute><Query /></ProtectedRoute>} />
      <Route path="/users" element={<ProtectedRoute requiredRole="super_admin"><Users /></ProtectedRoute>} />
      <Route path="/permissions" element={<ProtectedRoute requiredRole="super_admin"><PermissionManagement /></ProtectedRoute>} />
      <Route path="/system" element={<ProtectedRoute requiredRole="super_admin"><SystemManagement /></ProtectedRoute>} />
      <Route path="/audit-logs" element={<ProtectedRoute><AuditLogs /></ProtectedRoute>} />
      <Route path="*" element={<Navigate to="/query" />} />
    </Routes>
  );
};

export default App;
