// 用户角色类型
export type UserRole = 'super_admin' | 'customer_admin' | 'operator' | 'viewer';

export interface User {
  id: number;
  username: string;
  password_hash: string;
  display_name: string;  // 真实姓名
  role: UserRole;
  customer_id?: number;
  is_active: boolean;
  last_login?: string;
  created_at: string;
}

// 用户信息（不含密码）
export interface UserInfo {
  id: number;
  username: string;
  display_name: string;  // 真实姓名
  role: UserRole;
  customer_id?: number;
  customer_name?: string;
  is_active: boolean;
  last_login?: string;
  created_at: string;
}

export interface Customer {
  id: number;
  name: string;
  expected_length: number;
  description?: string;
  created_by?: number;  // 创建者
  created_by_username?: string;  // 创建者用户名
  created_by_display_name?: string;  // 创建者姓名
  can_edit?: boolean;  // 当前用户是否可以编辑
  created_at: string;
}

export interface Product {
  id: number;
  model: string;
  customer_id: number;
  description?: string;
  created_by?: number;  // 创建者
  created_by_username?: string;  // 创建者用户名
  created_by_display_name?: string;  // 创建者姓名
  can_edit?: boolean;  // 当前用户是否可以编辑
  created_at: string;
}

// 产品详情（含客户信息）
export interface ProductDetail extends Product {
  customer_name: string;
}

export interface ScanRecord {
  id: number;
  customer_id: number;
  product_id: number;
  user_id?: number;
  code_text: string;
  code_length: number;
  is_valid: boolean;
  error_reason?: string;
  notes?: string;
  created_at: string;
}

// 扫码记录详情（含关联信息）
export interface ScanRecordDetail extends ScanRecord {
  customer_name: string;
  product_model: string;
  username?: string;
  display_name?: string;  // 录入人员姓名
  user_role?: UserRole;
}

// 用户-产品权限
export interface UserProductPermission {
  id: number;
  user_id: number;
  product_id: number;
  can_scan: boolean;
  can_view: boolean;
  created_at: string;
}

// 审计日志
export interface AuditLog {
  id: number;
  user_id: number;
  action: string;  // login, create, update, delete, scan
  resource_type: string;  // user, customer, product, scan
  resource_id?: number;
  details?: string;  // JSON
  ip_address?: string;
  created_at: string;
}

// 审计日志详情
export interface AuditLogDetail extends AuditLog {
  username: string;
}
