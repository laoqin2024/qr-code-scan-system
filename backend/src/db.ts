import Database from 'better-sqlite3';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const dbFile = path.resolve(__dirname, '../../db.sqlite');
const schemaFile = path.resolve(__dirname, './schema.sql');

let db: Database.Database | null = null;

export function getDb(): Database.Database {
  if (!db) {
    db = new Database(dbFile);
    db.pragma('foreign_keys = ON');
    
    // 初始化表结构（如果需要）
    if (fs.existsSync(schemaFile)) {
      const schema = fs.readFileSync(schemaFile, 'utf-8');
      db.exec(schema);
    }
  }
  return db;
}

// 默认导出（保持向后兼容）
export default getDb();
