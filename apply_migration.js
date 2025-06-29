const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const config = {
  host: 'localhost',
  port: 5432,
  database: 'paperly_db',
  user: 'paperly_user',
  password: 'paperly_dev_password'
};

async function applyMigration(migrationFile) {
  const client = new Client(config);
  
  try {
    await client.connect();
    console.log('✅ DB 연결 성공');
    
    const migrationPath = path.resolve(migrationFile);
    const sql = fs.readFileSync(migrationPath, 'utf8');
    
    console.log(`📄 마이그레이션 파일 실행: ${migrationFile}`);
    
    await client.query(sql);
    console.log('✅ 마이그레이션 완료');
    
  } catch (error) {
    console.error('❌ 마이그레이션 실패:', error.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

const migrationFile = process.argv[2];
if (!migrationFile) {
  console.error('사용법: node apply_migration.js <migration_file>');
  process.exit(1);
}

applyMigration(migrationFile);