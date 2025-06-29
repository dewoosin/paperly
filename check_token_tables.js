const { Client } = require('pg');

const config = {
  host: 'localhost',
  port: 5432,
  database: 'paperly_db',
  user: 'paperly_user',
  password: 'paperly_dev_password'
};

async function checkTokenTables() {
  const client = new Client(config);
  
  try {
    await client.connect();
    console.log('✅ DB 연결 성공');
    
    // paperly 스키마 설정
    await client.query('SET search_path TO paperly, public');
    
    // refresh_tokens 테이블 확인
    console.log('\n🔍 refresh_tokens 테이블 확인:');
    try {
      const refreshTokenResult = await client.query(`
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns 
        WHERE table_schema = 'paperly' AND table_name = 'refresh_tokens'
        ORDER BY ordinal_position
      `);
      
      if (refreshTokenResult.rows.length > 0) {
        console.log('✅ refresh_tokens 테이블 존재:');
        refreshTokenResult.rows.forEach(row => {
          console.log(`  ${row.column_name.padEnd(25)} | ${row.data_type.padEnd(20)} | ${row.is_nullable.padEnd(8)} | ${row.column_default || 'null'}`);
        });
      } else {
        console.log('❌ refresh_tokens 테이블이 없습니다.');
      }
    } catch (error) {
      console.log('❌ refresh_tokens 테이블 확인 실패:', error.message);
    }
    
    // email_verification_tokens 테이블 확인
    console.log('\n🔍 email_verification_tokens 테이블 확인:');
    try {
      const emailVerificationResult = await client.query(`
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns 
        WHERE table_schema = 'paperly' AND table_name = 'email_verification_tokens'
        ORDER BY ordinal_position
      `);
      
      if (emailVerificationResult.rows.length > 0) {
        console.log('✅ email_verification_tokens 테이블 존재:');
        emailVerificationResult.rows.forEach(row => {
          console.log(`  ${row.column_name.padEnd(25)} | ${row.data_type.padEnd(20)} | ${row.is_nullable.padEnd(8)} | ${row.column_default || 'null'}`);
        });
      } else {
        console.log('❌ email_verification_tokens 테이블이 없습니다.');
      }
    } catch (error) {
      console.log('❌ email_verification_tokens 테이블 확인 실패:', error.message);
    }
    
  } catch (error) {
    console.error('❌ 에러:', error.message);
  } finally {
    await client.end();
  }
}

checkTokenTables();