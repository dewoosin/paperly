const { Client } = require('pg');

const config = {
  host: 'localhost',
  port: 5432,
  database: 'paperly_db',
  user: 'paperly_user',
  password: 'paperly_dev_password'
};

async function checkArticles() {
  const client = new Client(config);
  
  try {
    await client.connect();
    
    // articles 테이블 구조 확인
    console.log('\n📊 articles 테이블 구조:');
    const columns = await client.query(`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_schema = 'paperly' 
      AND table_name = 'articles'
      ORDER BY ordinal_position;
    `);
    columns.rows.forEach(col => 
      console.log(`- ${col.column_name}: ${col.data_type} (nullable: ${col.is_nullable})`));
    
    // 기존 기사 수 확인
    const count = await client.query('SELECT COUNT(*) FROM paperly.articles');
    console.log(`\n📝 기존 기사 수: ${count.rows[0].count}`);
    
  } catch (error) {
    console.error('❌ 에러:', error.message);
  } finally {
    await client.end();
  }
}

checkArticles();