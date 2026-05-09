import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import os from 'os';
import './db.js';
import authRoutes from './routes/auth';
import customerRoutes from './routes/customers';
import productRoutes from './routes/products';
import scanRoutes from './routes/scans';
import userRoutes from './routes/users';
import permissionRoutes from './routes/permissions';
import auditLogRoutes from './routes/audit-logs';

dotenv.config();

const app = express();

// 配置 CORS 允许局域网访问
app.use(cors({
  origin: '*', // 允许所有来源
  credentials: true
}));

app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/products', productRoutes);
app.use('/api/scans', scanRoutes);
app.use('/api/users', userRoutes);
app.use('/api/permissions', permissionRoutes);
app.use('/api/audit-logs', auditLogRoutes);

const PORT = process.env.PORT || 3001;
const HOST = '0.0.0.0'; // 监听所有网络接口

app.listen(PORT, HOST, () => {
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('🚀 后端服务已启动（权限管理系统 v2）');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`📍 本地访问: http://localhost:${PORT}`);
  
  // 获取本机局域网IP
  const networkInterfaces = os.networkInterfaces();
  const addresses: string[] = [];
  
  for (const name of Object.keys(networkInterfaces)) {
    const nets = networkInterfaces[name];
    if (nets) {
      for (const net of nets) {
        // 跳过内部和非IPv4地址
        if (net.family === 'IPv4' && !net.internal) {
          addresses.push(net.address);
        }
      }
    }
  }
  
  if (addresses.length > 0) {
    console.log(`🌐 局域网访问:`);
    addresses.forEach((addr) => {
      console.log(`   http://${addr}:${PORT}`);
    });
  }
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
});

export default app;
