const { Client } = require('pg');

const config = {
  host: 'localhost',
  port: 5432,
  database: 'paperly_db',
  user: 'paperly_user',
  password: 'paperly_dev_password'
};

async function checkTokensInDB() {
  const client = new Client(config);
  
  try {
    await client.connect();
    console.log('✅ DB 연결 성공');
    
    // paperly 스키마 설정
    await client.query('SET search_path TO paperly, public');
    
    // refresh_tokens 확인
    console.log('\n🔍 Refresh Tokens:');
    const refreshResult = await client.query(`
      SELECT rt.id, rt.user_id, rt.device_id, rt.expires_at, rt.created_at, u.email
      FROM refresh_tokens rt
      JOIN users u ON rt.user_id = u.id
      ORDER BY rt.created_at DESC
      LIMIT 5
    `);
    
    if (refreshResult.rows.length > 0) {
      console.log(`📊 총 ${refreshResult.rowCount}개의 refresh token 발견:`);
      refreshResult.rows.forEach((token, index) => {
        console.log(`${index + 1}. 사용자: ${token.email}`);
        console.log(`   토큰 ID: ${token.id}`);
        console.log(`   디바이스 ID: ${token.device_id || 'N/A'}`);
        console.log(`   만료일: ${token.expires_at}`);
        console.log(`   생성일: ${token.created_at}`);
        console.log('-'.repeat(50));
      });
    } else {
      console.log('❌ refresh token이 없습니다.');
    }
    
    // email_verification_tokens 확인
    console.log('\n🔍 Email Verification Tokens:');
    const emailResult = await client.query(`
      SELECT evt.id, evt.user_id, evt.email, evt.expires_at, evt.verified_at, evt.created_at, u.name
      FROM email_verification_tokens evt
      JOIN users u ON evt.user_id = u.id
      ORDER BY evt.created_at DESC
      LIMIT 5
    `);
    
    if (emailResult.rows.length > 0) {
      console.log(`📊 총 ${emailResult.rowCount}개의 email verification token 발견:`);
      emailResult.rows.forEach((token, index) => {
        console.log(`${index + 1}. 사용자: ${token.name} (${token.email})`);
        console.log(`   토큰 ID: ${token.id}`);
        console.log(`   인증 완료: ${token.verified_at ? '✅' : '❌'}`);
        console.log(`   만료일: ${token.expires_at}`);
        console.log(`   생성일: ${token.created_at}`);
        console.log('-'.repeat(50));
      });
    } else {
      console.log('❌ email verification token이 없습니다.');
    }
    
  } catch (error) {
    console.error('❌ 에러:', error.message);
  } finally {
    await client.end();
  }
}

checkTokensInDB();