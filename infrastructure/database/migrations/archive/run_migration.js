#!/usr/bin/env node

const { Client } = require('pg');
const fs = require('fs').promises;
const path = require('path');
const readline = require('readline');

// 색상 코드
const colors = {
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  reset: '\x1b[0m'
};

// 데이터베이스 설정
const config = {
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'paperly',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || ''
};

const log = {
  info: (msg) => console.log(`${colors.green}${msg}${colors.reset}`),
  warn: (msg) => console.log(`${colors.yellow}${msg}${colors.reset}`),
  error: (msg) => console.log(`${colors.red}${msg}${colors.reset}`)
};

async function question(prompt) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });
  
  return new Promise((resolve) => {
    rl.question(prompt, (answer) => {
      rl.close();
      resolve(answer);
    });
  });
}

async function runMigration() {
  log.info('=== Paperly 데이터베이스 마이그레이션 ===');
  console.log(`데이터베이스: ${config.database}`);
  console.log(`호스트: ${config.host}:${config.port}`);
  console.log(`사용자: ${config.user}\n`);

  // 비밀번호 입력 받기
  if (!config.password) {
    config.password = await question('데이터베이스 비밀번호를 입력하세요: ');
  }

  const client = new Client(config);

  try {
    await client.connect();
    log.info('✓ 데이터베이스 연결 성공\n');

    // 1. paperly 스키마 생성
    log.warn('1. paperly 스키마 생성 중...');
    const createSchemaSQL = await fs.readFile(
      path.join(__dirname, '000_create_paperly_schema.sql'), 
      'utf8'
    );
    await client.query(createSchemaSQL);
    log.info('✓ paperly 스키마 생성 완료\n');

    // 2. 기존 public 스키마 확인
    log.warn('2. 기존 public 스키마 테이블 확인');
    const publicTables = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
        AND table_type = 'BASE TABLE'
      ORDER BY table_name
    `);
    
    if (publicTables.rows.length > 0) {
      console.log('다음 테이블들이 public 스키마에 있습니다:');
      publicTables.rows.forEach(row => console.log(`  - ${row.table_name}`));
      console.log('');
      
      const answer = await question('계속 진행하시겠습니까? (Y/n): ');
      if (answer.toLowerCase() === 'n') {
        console.log('마이그레이션을 취소했습니다.');
        process.exit(0);
      }
    }

    // 3. paperly 스키마에 테이블 생성
    log.warn('\n3. paperly 스키마에 테이블 생성 중...');
    console.log('이 작업은 시간이 걸릴 수 있습니다...');
    
    const createTablesSQL = await fs.readFile(
      path.join(__dirname, '004_paperly_complete_schema.sql'), 
      'utf8'
    );
    
    // SQL을 세미콜론으로 분리하여 각각 실행
    const statements = createTablesSQL
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0);
    
    for (let i = 0; i < statements.length; i++) {
      try {
        await client.query(statements[i] + ';');
        process.stdout.write('.');
      } catch (err) {
        console.error(`\n오류 발생 (statement ${i + 1}):`, err.message);
        console.error('문제가 된 SQL:', statements[i].substring(0, 100) + '...');
      }
    }
    
    console.log('');
    log.info('✓ 테이블 생성 완료\n');

    // 4. 생성된 테이블 확인
    log.warn('4. 생성된 테이블 확인');
    const paperlyTables = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'paperly' 
        AND table_type = 'BASE TABLE'
      ORDER BY table_name
      LIMIT 20
    `);
    
    console.log('paperly 스키마에 생성된 테이블:');
    paperlyTables.rows.forEach(row => console.log(`  - ${row.table_name}`));
    console.log(`  ... 총 ${paperlyTables.rowCount}개 테이블\n`);

    log.info('=== 마이그레이션 완료! ===\n');
    
    console.log('다음 명령으로 paperly 스키마를 기본으로 설정할 수 있습니다:');
    log.warn(`ALTER DATABASE ${config.database} SET search_path TO paperly, public;\n`);
    
    console.log('애플리케이션에서 연결 시 다음과 같이 설정하세요:');
    log.warn('SET search_path TO paperly, public;');

  } catch (err) {
    log.error('✗ 오류 발생:');
    console.error(err);
    process.exit(1);
  } finally {
    await client.end();
  }
}

// 스크립트 실행
runMigration().catch(console.error);