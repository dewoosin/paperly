const { Client } = require('pg');

const config = {
  host: 'localhost',
  port: 5432,
  database: 'paperly_db',
  user: 'paperly_user',
  password: 'paperly_dev_password'
};

async function testDirectRegistration() {
  const client = new Client(config);
  
  try {
    await client.connect();
    console.log('✅ DB 연결 성공');
    
    // paperly 스키마 설정
    await client.query('SET search_path TO paperly, public');
    console.log('✅ 스키마 설정 완료');
    
    // 실제 등록 API가 시도하는 것과 같은 데이터 구조로 삽입
    const testUser = {
      id: 'd8cee035-9c00-4410-9f35-71b88c9e4d3b', // 이전 API 응답에서 받은 ID 사용
      email: 'test7@example.com',
      password_hash: '$2b$10$abcdefghijklmnopqrstuvwxyz',
      name: 'Test User 7',
      nickname: null,
      profile_image_url: null,
      email_verified: false,
      phone_number: null,
      phone_verified: false,
      status: 'active',
      birth_date: new Date('1990-01-01'),
      gender: 'male',
      last_login_at: null,
      created_at: new Date(),
      updated_at: new Date()
    };
    
    console.log('🚀 사용자 직접 삽입 시도...');
    
    const result = await client.query(
      `INSERT INTO users (
         id, email, password_hash, name, nickname, profile_image_url,
         email_verified, phone_number, phone_verified,
         status, birth_date, gender, last_login_at, created_at, updated_at
       )
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)`,
      [
        testUser.id,
        testUser.email,
        testUser.password_hash,
        testUser.name,
        testUser.nickname,
        testUser.profile_image_url,
        testUser.email_verified,
        testUser.phone_number,
        testUser.phone_verified,
        testUser.status,
        testUser.birth_date,
        testUser.gender,
        testUser.last_login_at,
        testUser.created_at,
        testUser.updated_at
      ]
    );
    
    console.log(`✅ 직접 삽입 성공! rowCount: ${result.rowCount}`);
    
    // 확인을 위한 조회
    const selectResult = await client.query('SELECT * FROM users WHERE id = $1', [testUser.id]);
    console.log('📊 삽입된 사용자 확인:', selectResult.rows[0]);
    
  } catch (error) {
    console.error('❌ 에러:', error.message);
    console.error('전체 에러:', error);
  } finally {
    await client.end();
  }
}

testDirectRegistration();