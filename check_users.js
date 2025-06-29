const { Client } = require('pg');

const config = {
  host: 'localhost',
  port: 5432,
  database: 'paperly_db',
  user: 'paperly_user',
  password: 'paperly_dev_password'
};

async function checkUsers() {
  const client = new Client(config);
  
  try {
    await client.connect();
    console.log('✅ DB 연결 성공');
    
    // paperly 스키마 설정
    await client.query('SET search_path TO paperly, public');
    
    // 사용자 목록 조회
    const result = await client.query(`
      SELECT id, email, name, email_verified, phone_verified, status, created_at 
      FROM users 
      ORDER BY created_at DESC 
      LIMIT 5
    `);
    
    console.log(`\n📊 총 ${result.rowCount}개의 사용자 발견:`);
    console.log('='.repeat(80));
    
    result.rows.forEach((user, index) => {
      console.log(`${index + 1}. ID: ${user.id}`);
      console.log(`   이메일: ${user.email}`);
      console.log(`   이름: ${user.name}`);
      console.log(`   이메일 인증: ${user.email_verified ? '✅' : '❌'}`);
      console.log(`   전화 인증: ${user.phone_verified ? '✅' : '❌'}`);
      console.log(`   상태: ${user.status}`);
      console.log(`   생성일: ${user.created_at}`);
      console.log('-'.repeat(40));
    });
    
  } catch (error) {
    console.error('❌ 에러:', error.message);
  } finally {
    await client.end();
  }
}

checkUsers();