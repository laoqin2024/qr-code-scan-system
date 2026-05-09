-- 权限管理系统 - 数据库升级脚本 v2
PRAGMA foreign_keys = ON;

-- ============================================
-- 1. 用户表（扩展）
-- ============================================
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL CHECK(role IN ('super_admin','customer_admin','operator','viewer')),
  customer_id INTEGER,  -- 关联客户（customer_admin/operator/viewer 必填）
  is_active INTEGER DEFAULT 1,  -- 是否激活
  last_login TEXT,  -- 最后登录时间
  created_at TEXT NOT NULL,
  FOREIGN KEY(customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

-- ============================================
-- 2. 客户表
-- ============================================
CREATE TABLE IF NOT EXISTS customers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  expected_length INTEGER NOT NULL,
  description TEXT,
  created_at TEXT NOT NULL
);

-- ============================================
-- 3. 产品表
-- ============================================
CREATE TABLE IF NOT EXISTS products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  model TEXT NOT NULL,
  customer_id INTEGER NOT NULL,
  description TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY(customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

-- ============================================
-- 4. 用户-产品权限表（新增）
-- ============================================
CREATE TABLE IF NOT EXISTS user_product_permissions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  can_scan INTEGER DEFAULT 1,  -- 是否可以扫码
  can_view INTEGER DEFAULT 1,  -- 是否可以查看
  created_at TEXT NOT NULL,
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE,
  UNIQUE(user_id, product_id)
);

-- ============================================
-- 5. 扫码记录表（扩展）
-- ============================================
CREATE TABLE IF NOT EXISTS scans (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  customer_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  user_id INTEGER,  -- 扫码操作员（新增）
  code_text TEXT NOT NULL,
  code_length INTEGER NOT NULL,
  is_valid INTEGER NOT NULL,
  error_reason TEXT,
  notes TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY(customer_id) REFERENCES customers(id),
  FOREIGN KEY(product_id) REFERENCES products(id),
  FOREIGN KEY(user_id) REFERENCES users(id)
);

-- ============================================
-- 6. 审计日志表（新增）
-- ============================================
CREATE TABLE IF NOT EXISTS audit_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  action TEXT NOT NULL,  -- 操作类型：login, create, update, delete, scan
  resource_type TEXT NOT NULL,  -- 资源类型：user, customer, product, scan
  resource_id INTEGER,  -- 资源ID
  details TEXT,  -- JSON格式的详细信息
  ip_address TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY(user_id) REFERENCES users(id)
);

-- ============================================
-- 索引优化
-- ============================================
CREATE INDEX IF NOT EXISTS idx_users_customer ON users(customer_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_products_customer ON products(customer_id);
CREATE INDEX IF NOT EXISTS idx_scans_user ON scans(user_id);
CREATE INDEX IF NOT EXISTS idx_scans_product ON scans(product_id);
CREATE INDEX IF NOT EXISTS idx_scans_created ON scans(created_at);
CREATE INDEX IF NOT EXISTS idx_permissions_user ON user_product_permissions(user_id);
CREATE INDEX IF NOT EXISTS idx_permissions_product ON user_product_permissions(product_id);
CREATE INDEX IF NOT EXISTS idx_audit_user ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_created ON audit_logs(created_at);
