const { Client } = require('pg');

const config = {
  host: 'localhost',
  port: 5432,
  database: 'paperly_db',
  user: 'paperly_user',
  password: 'paperly_dev_password'
};

async function checkTableStructure() {
  const client = new Client(config);
  
  try {
    await client.connect();
    console.log('✅ DB 연결 성공');
    
    // paperly 스키마 설정
    await client.query('SET search_path TO paperly, public');
    
    // users 테이블 구조 확인
    const result = await client.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_schema = 'paperly' AND table_name = 'users'
      ORDER BY ordinal_position
    `);
    
    console.log('📋 users 테이블 구조:');
    console.log('='.repeat(80));
    result.rows.forEach(row => {
      console.log(`${row.column_name.padEnd(25)} | ${row.data_type.padEnd(20)} | ${row.is_nullable.padEnd(8)} | ${row.column_default || 'null'}`);
    });
    
  } catch (error) {
    console.error('❌ 에러:', error.message);
  } finally {
    await client.end();
  }
}

checkTableStructure();