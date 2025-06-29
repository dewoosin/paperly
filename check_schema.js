const { Client } = require('pg');

const config = {
  host: 'localhost',
  port: 5432,
  database: 'paperly_db',
  user: 'paperly_user',
  password: 'paperly_dev_password'
};

async function checkSchema() {
  const client = new Client(config);
  
  try {
    await client.connect();
    console.log('✅ DB 연결 성공');
    
    // 기존 테이블 확인
    const result = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'paperly'
      ORDER BY table_name;
    `);
    
    console.log('\n📋 기존 테이블들:');
    result.rows.forEach(row => console.log(`- ${row.table_name}`));
    
    // categories 테이블 존재 여부 확인
    const categoryCheck = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'paperly' 
        AND table_name = 'categories'
      );
    `);
    
    if (categoryCheck.rows[0].exists) {
      console.log('\n📊 categories 테이블 구조:');
      const columns = await client.query(`
        SELECT column_name, data_type, is_nullable 
        FROM information_schema.columns 
        WHERE table_schema = 'paperly' 
        AND table_name = 'categories'
        ORDER BY ordinal_position;
      `);
      columns.rows.forEach(col => 
        console.log(`- ${col.column_name}: ${col.data_type} (nullable: ${col.is_nullable})`));
    }
    
  } catch (error) {
    console.error('❌ 에러:', error.message);
  } finally {
    await client.end();
  }
}

checkSchema();