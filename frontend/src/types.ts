// 用户角色类型
export type UserRole = 'super_admin' | 'customer_admin' | 'operator' | 'viewer';

export interface User {
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
  created_by?: number;
  created_by_username?: string;
  created_by_display_name?: string;
  can_edit?: boolean;
  created_at: string;
}

export interface Product {
  id: number;
  model: string;
  customer_id: number;
  customer_name?: string;
  description?: string;
  created_by?: number;
  created_by_username?: string;
  created_by_display_name?: string;
  can_edit?: boolean;
  created_at: string;
}

export interface ScanRecord {
  id: number;
  customer_id: number;
  product_id: number;
  user_id?: number;
  customer_name?: string;
  product_model?: string;
  username?: string;
  display_name?: string;  // 录入人员姓名
  user_role?: UserRole;
  code_text: string;
  code_length: number;
  is_valid: boolean;
  error_reason?: string;
  notes?: string;
  created_at: string;
}

export interface UserProductPermission {
  id: number;
  user_id: number;
  product_id: number;
  product_model?: string;
  customer_name?: string;
  can_scan: boolean;
  can_view: boolean;
  created_at: string;
}

export interface AuditLog {
  id: number;
  user_id: number;
  username?: string;
  display_name?: string;
  action: string;
  resource_type: string;
  resource_id?: number;
  details?: string;
  ip_address?: string;
  created_at: string;
}

export interface LoginResponse {
  token: string;
  user: {
    id: number;
    username: string;
    display_name: string;
    role: UserRole;
    customer_id?: number;
  };
}
