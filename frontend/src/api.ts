import axios from 'axios';
import type { User, Customer, Product, ScanRecord, UserProductPermission, AuditLog, LoginResponse } from './types';

const api = axios.create({
  baseURL: '/api',
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers = config.headers || {};
    config.headers['Authorization'] = `Bearer ${token}`;
  }
  return config;
});

// 认证相关
export const authAPI = {
  login: (username: string, password: string) => 
    api.post<LoginResponse>('/auth/login', { username, password }),
  
  getMe: () => 
    api.get<User>('/auth/me'),
  
  changePassword: (old_password: string, new_password: string) => 
    api.post('/auth/change-password', { old_password, new_password }),
  
  logout: () => 
    api.post('/auth/logout'),
};

// 用户管理
export const userAPI = {
  getUsers: () => 
    api.get<User[]>('/users'),
  
  getUser: (id: number) => 
    api.get<User>(`/users/${id}`),
  
  createUser: (data: { username: string; password: string; role: string; customer_id?: number }) => 
    api.post<User>('/users', data),
  
  updateUser: (id: number, data: { password?: string; is_active?: boolean; customer_id?: number }) => 
    api.put(`/users/${id}`, data),
  
  deleteUser: (id: number) => 
    api.delete(`/users/${id}`),
  
  changeMyPassword: (data: { old_password: string; new_password: string }) => 
    api.put('/users/me/password', data),
};

// 权限管理
export const permissionAPI = {
  getUserPermissions: (userId: number) => 
    api.get<UserProductPermission[]>(`/permissions/users/${userId}/permissions`),
  
  getUserCustomers: (userId: number) => 
    api.get(`/permissions/users/${userId}/customers`),
  
  grantPermission: (userId: number, productId: number, canScan: boolean = true, canView: boolean = true) => 
    api.post(`/permissions/users/${userId}/permissions/products`, {
      product_id: productId,
      can_scan: canScan,
      can_view: canView,
    }),
  
  grantPermissionBatch: (userId: number, productIds: number[], canScan: boolean = true, canView: boolean = true) => 
    api.post(`/permissions/users/${userId}/permissions/products/batch`, {
      product_ids: productIds,
      can_scan: canScan,
      can_view: canView,
    }),
  
  grantCustomerProducts: (userId: number, customerId: number, canScan: boolean = true, canView: boolean = true) => 
    api.post(`/permissions/users/${userId}/permissions/customers/${customerId}/products`, {
      can_scan: canScan,
      can_view: canView,
    }),
  
  revokePermission: (userId: number, productId: number) => 
    api.delete(`/permissions/users/${userId}/permissions/products/${productId}`),
  
  getProductUsers: (productId: number) => 
    api.get(`/permissions/products/${productId}/users`),
  
  getAuditLogs: (params?: { limit?: number; offset?: number; resource_type?: string; action?: string }) => 
    api.get<AuditLog[]>('/permissions/audit-logs', { params }),
  
  getMyAuditLogs: (params?: { limit?: number; offset?: number }) => 
    api.get<AuditLog[]>('/permissions/audit-logs/my', { params }),
};

// 客户管理
export const customerAPI = {
  getCustomers: () => 
    api.get<Customer[]>('/customers'),
  
  getCustomer: (id: number) => 
    api.get<Customer>(`/customers/${id}`),
  
  createCustomer: (data: { name: string; expected_length: number; description?: string }) => 
    api.post<{ id: number }>('/customers', data),
  
  updateCustomer: (id: number, data: { name?: string; expected_length?: number; description?: string }) => 
    api.put(`/customers/${id}`, data),
  
  deleteCustomer: (id: number) => 
    api.delete(`/customers/${id}`),
};

// 产品管理
export const productAPI = {
  getProducts: () => 
    api.get<Product[]>('/products'),
  
  getProduct: (id: number) => 
    api.get<Product>(`/products/${id}`),
  
  createProduct: (data: { model: string; customer_id: number; description?: string }) => 
    api.post<{ id: number }>('/products', data),
  
  updateProduct: (id: number, data: { model?: string; description?: string }) => 
    api.put(`/products/${id}`, data),
  
  deleteProduct: (id: number) => 
    api.delete(`/products/${id}`),
};

// 扫码管理
export const scanAPI = {
  createScan: (data: { customer_id: number; product_id: number; code_text: string; notes?: string }) => 
    api.post<{ id: number; is_valid: boolean; error_reason?: string }>('/scans', data),
  
  getScans: (params?: { 
    customer_id?: number; 
    product_id?: number;
    user_id?: number;
    start_time?: string; 
    end_time?: string; 
    is_valid?: number;
    code_text?: string;
    page?: number;
    limit?: number;
  }) => 
    api.get<{
      scans: ScanRecord[];
      pagination: { page: number; limit: number; total: number; totalPages: number };
      stats: { total: number; valid_count: number; invalid_count: number; today_count: number };
    }>('/scans', { params }),
  
  getStats: (params?: { 
    customer_id?: number; 
    product_id?: number; 
    start_time?: string; 
    end_time?: string 
  }) => 
    api.get<{ total: number; valid_count: number; invalid_count: number }>('/scans/stats', { params }),
  
  deleteScan: (id: number) => 
    api.delete(`/scans/${id}`),
  
  batchDeleteInvalid: (params?: {
    customer_id?: number;
    product_id?: number;
    start_time?: string;
    end_time?: string;
  }) => 
    api.post('/scans/batch-delete-invalid', params),
  
  cleanupTestData: () => 
    api.post('/scans/cleanup-test-data'),
  
  initializeSystem: () => 
    api.post('/scans/initialize-system'),
};

// 审计日志
export const auditLogAPI = {
  getLogs: (params?: {
    user_id?: number;
    action?: string;
    resource_type?: string;
    start_time?: string;
    end_time?: string;
    page?: number;
    limit?: number;
    search?: string;
  }) =>
    api.get('/audit-logs', { params }),
  
  getLog: (id: number) =>
    api.get(`/audit-logs/${id}`),
  
  getStats: (params?: {
    start_time?: string;
    end_time?: string;
  }) =>
    api.get('/audit-logs/stats/summary', { params }),
  
  exportCSV: (params?: {
    user_id?: number;
    action?: string;
    resource_type?: string;
    start_time?: string;
    end_time?: string;
  }) => {
    const queryString = new URLSearchParams(params as any).toString();
    window.open(`/api/audit-logs/export/csv?${queryString}`, '_blank');
  },
};

export default api;
