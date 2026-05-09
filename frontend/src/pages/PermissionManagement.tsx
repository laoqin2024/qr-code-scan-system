import React, { useState, useEffect } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
import Navbar from '../components/Navbar';
import { userAPI, customerAPI, productAPI, permissionAPI } from '../api';
import type { User, Customer, Product } from '../types';
import '../styles/Page.css';

const PermissionManagement: React.FC = () => {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const [users, setUsers] = useState<User[]>([]);
  const [selectedUserId, setSelectedUserId] = useState<number>(0);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [userPermissions, setUserPermissions] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [selectedCustomers, setSelectedCustomers] = useState<number[]>([]);
  const [selectedProducts, setSelectedProducts] = useState<number[]>([]);

  useEffect(() => {
    loadUsers();
    loadCustomers();
    loadProducts();
    
    // 从URL参数获取用户ID
    const userIdParam = searchParams.get('userId');
    if (userIdParam) {
      setSelectedUserId(parseInt(userIdParam));
    }
  }, [searchParams]);

  useEffect(() => {
    if (selectedUserId > 0) {
      loadUserPermissions();
    }
  }, [selectedUserId]);

  const loadUsers = async () => {
    try {
      const res = await userAPI.getUsers();
      // 显示操作员、查看者和客户管理员
      setUsers(res.data.filter((u: User) => 
        u.role === 'operator' || u.role === 'viewer' || u.role === 'customer_admin'
      ));
    } catch (error) {
      console.error('加载用户失败:', error);
    }
  };

  const loadCustomers = async () => {
    try {
      const res = await customerAPI.getCustomers();
      setCustomers(res.data);
    } catch (error) {
      console.error('加载客户失败:', error);
    }
  };

  const loadProducts = async () => {
    try {
      const res = await productAPI.getProducts();
      setProducts(res.data);
    } catch (error) {
      console.error('加载产品失败:', error);
    }
  };

  const loadUserPermissions = async () => {
    if (selectedUserId === 0) return;
    
    setLoading(true);
    try {
      const res = await permissionAPI.getUserPermissions(selectedUserId);
      setUserPermissions(res.data);
      
      // 设置已选择的产品
      const productIds = res.data.map((p: any) => p.product_id);
      setSelectedProducts(productIds);
      
      // 根据产品找出客户
      const customerIds = [...new Set(
        products
          .filter(p => productIds.includes(p.id))
          .map(p => p.customer_id)
      )];
      setSelectedCustomers(customerIds);
    } catch (error) {
      console.error('加载权限失败:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCustomerToggle = (customerId: number) => {
    const customerProducts = products.filter(p => p.customer_id === customerId);
    const customerProductIds = customerProducts.map(p => p.id);
    
    if (isCustomerFullySelected(customerId)) {
      // 取消选择客户的所有产品
      setSelectedProducts(selectedProducts.filter(id => !customerProductIds.includes(id)));
    } else {
      // 选择客户的所有产品
      setSelectedProducts([...new Set([...selectedProducts, ...customerProductIds])]);
    }
  };

  const handleProductToggle = (productId: number) => {
    if (selectedProducts.includes(productId)) {
      setSelectedProducts(selectedProducts.filter(id => id !== productId));
    } else {
      setSelectedProducts([...selectedProducts, productId]);
    }
  };

  const getCustomerProducts = (customerId: number) => {
    return products.filter(p => p.customer_id === customerId);
  };

  const isCustomerFullySelected = (customerId: number) => {
    const customerProducts = getCustomerProducts(customerId);
    return customerProducts.length > 0 && customerProducts.every(p => selectedProducts.includes(p.id));
  };

  const isCustomerPartiallySelected = (customerId: number) => {
    const customerProducts = getCustomerProducts(customerId);
    return customerProducts.some(p => selectedProducts.includes(p.id)) && !isCustomerFullySelected(customerId);
  };

  const handleSave = async () => {
    if (selectedUserId === 0) {
      alert('请选择用户');
      return;
    }

    setLoading(true);
    try {
      // 获取当前权限
      const currentPermissions = userPermissions.map((p: any) => p.product_id);
      
      // 找出要添加的权限
      const toAdd = selectedProducts.filter(id => !currentPermissions.includes(id));
      
      // 找出要删除的权限
      const toRemove = currentPermissions.filter((id: number) => !selectedProducts.includes(id));
      
      // 批量添加
      if (toAdd.length > 0) {
        await permissionAPI.grantPermissionBatch(selectedUserId, toAdd, true, true);
      }
      
      // 批量删除
      for (const productId of toRemove) {
        await permissionAPI.revokePermission(selectedUserId, productId);
      }
      
      alert(`权限更新成功！\n\n添加: ${toAdd.length} 个产品\n删除: ${toRemove.length} 个产品`);
      loadUserPermissions();
    } catch (error: any) {
      alert('保存失败: ' + (error.response?.data?.error || error.message));
    } finally {
      setLoading(false);
    }
  };

  const selectedUser = users.find(u => u.id === selectedUserId);

  return (
    <div>
      <Navbar />
      <div className="page-container">
        <div className="page-header">
          <h2>权限管理</h2>
          <button onClick={() => navigate('/users')} className="btn-secondary">
            返回用户列表
          </button>
        </div>

        <div className="form-card">
          <h3>选择用户</h3>
          <div className="form-group">
            <label>用户</label>
            <select
              value={selectedUserId}
              onChange={e => setSelectedUserId(parseInt(e.target.value))}
              style={{fontSize: '14px', padding: '10px'}}
            >
              <option value={0}>请选择用户</option>
              {users.map(u => (
                <option key={u.id} value={u.id}>
                  {u.display_name || u.username} ({
                    u.role === 'operator' ? '操作员' : 
                    u.role === 'viewer' ? '查看者' : 
                    '客户管理员'
                  })
                </option>
              ))}
            </select>
          </div>

          {selectedUser && (
            <div style={{
              padding: '12px',
              background: '#e3f2fd',
              borderRadius: '8px',
              marginTop: '10px',
              fontSize: '13px'
            }}>
              <strong>当前用户：</strong> {selectedUser.display_name || selectedUser.username}<br/>
              <strong>角色：</strong> {
                selectedUser.role === 'operator' ? '操作员' : 
                selectedUser.role === 'viewer' ? '查看者' : 
                '客户管理员'
              }<br/>
              <strong>当前权限：</strong> {userPermissions.length} 个产品
            </div>
          )}
        </div>

        {selectedUserId > 0 && (
          <div className="form-card">
            <h3>产品授权（可多选）</h3>
            <div style={{
              maxHeight: '400px',
              overflowY: 'auto',
              border: '2px solid #e8e8e8',
              borderRadius: '8px',
              padding: '15px',
              background: '#fafafa'
            }}>
              {customers.map(customer => {
                const customerProducts = getCustomerProducts(customer.id);
                if (customerProducts.length === 0) return null;
                
                const isFullySelected = isCustomerFullySelected(customer.id);
                const isPartiallySelected = isCustomerPartiallySelected(customer.id);
                
                return (
                  <div key={customer.id} style={{marginBottom: '20px'}}>
                    <div style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '10px',
                      padding: '10px',
                      background: isFullySelected ? '#e3f2fd' : isPartiallySelected ? '#fff3cd' : 'white',
                      borderRadius: '8px',
                      marginBottom: '10px',
                      cursor: 'pointer',
                      border: '2px solid #ddd',
                      transition: 'all 0.2s'
                    }} onClick={() => handleCustomerToggle(customer.id)}>
                      <input
                        type="checkbox"
                        checked={isFullySelected}
                        onChange={() => {}}
                        style={{cursor: 'pointer', width: '18px', height: '18px'}}
                      />
                      <strong style={{color: '#1976d2', fontSize: '15px'}}>{customer.name}</strong>
                      <span style={{fontSize: '13px', color: '#666'}}>
                        ({customerProducts.filter(p => selectedProducts.includes(p.id)).length}/{customerProducts.length} 个产品)
                      </span>
                    </div>
                    <div style={{paddingLeft: '40px'}}>
                      {customerProducts.map(product => (
                        <div key={product.id} style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: '10px',
                          padding: '8px',
                          marginBottom: '6px',
                          cursor: 'pointer',
                          background: selectedProducts.includes(product.id) ? '#e8f5e9' : 'white',
                          borderRadius: '6px',
                          border: '1px solid #e0e0e0',
                          transition: 'all 0.2s'
                        }} onClick={() => handleProductToggle(product.id)}>
                          <input
                            type="checkbox"
                            checked={selectedProducts.includes(product.id)}
                            onChange={() => {}}
                            style={{cursor: 'pointer', width: '16px', height: '16px'}}
                          />
                          <span style={{fontSize: '14px'}}>{product.model}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                );
              })}
              {customers.every(c => getCustomerProducts(c.id).length === 0) && (
                <div style={{textAlign: 'center', color: '#999', padding: '40px'}}>
                  暂无可授权的产品
                </div>
              )}
            </div>
            <div style={{
              marginTop: '15px',
              padding: '12px',
              background: '#f5f5f5',
              borderRadius: '8px',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center'
            }}>
              <span style={{fontSize: '14px', color: '#666'}}>
                已选择 <strong style={{color: '#1976d2', fontSize: '16px'}}>{selectedProducts.length}</strong> 个产品
              </span>
              <button 
                onClick={handleSave} 
                className="btn-primary"
                disabled={loading}
                style={{minWidth: '120px'}}
              >
                {loading ? '保存中...' : '保存权限'}
              </button>
            </div>
          </div>
        )}

        <div style={{
          marginTop: '20px',
          padding: '15px',
          background: 'linear-gradient(135deg, #e8f5e9 0%, #c8e6c9 100%)',
          border: '2px solid #4caf50',
          borderRadius: '10px',
          color: '#2e7d32',
          fontSize: '13px'
        }}>
          <strong>💡 使用说明：</strong><br/>
          • 可以为客户管理员、操作员和查看者授权产品<br/>
          • 点击客户名称可快速选择/取消该客户的所有产品<br/>
          • 点击产品名称可单独选择/取消该产品<br/>
          • 蓝色背景表示客户的所有产品已选择<br/>
          • 黄色背景表示客户的部分产品已选择<br/>
          • 绿色背景表示产品已选择
        </div>
      </div>
    </div>
  );
};

export default PermissionManagement;
