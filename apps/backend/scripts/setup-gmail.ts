/**
 * Gmail SMTP setup helper
 * 
 * Interactive script to help set up Gmail SMTP
 */

import * as readline from 'readline';
import * as fs from 'fs';
import * as path from 'path';

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function askQuestion(question: string): Promise<string> {
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      resolve(answer.trim());
    });
  });
}

async function setupGmail() {
  console.log('\n📧 Gmail SMTP 설정 도우미\n');

  console.log('📋 준비사항:');
  console.log('1. Gmail 계정의 2단계 인증 활성화');
  console.log('2. Gmail 앱 비밀번호 생성');
  console.log('   - Google 계정 → 보안 → 앱 비밀번호');
  console.log('   - 앱: 메일, 기기: 기타(Paperly)');
  console.log('\n');

  const proceed = await askQuestion('준비가 완료되었나요? (y/n): ');
  if (proceed.toLowerCase() !== 'y') {
    console.log('\n📖 자세한 설정 방법은 EMAIL_SETUP.md 파일을 참고하세요.');
    rl.close();
    return;
  }

  const email = await askQuestion('Gmail 주소를 입력하세요: ');
  const appPassword = await askQuestion('앱 비밀번호를 입력하세요 (16자리): ');
  
  // 공백 제거
  const cleanPassword = appPassword.replace(/\s/g, '');
  
  if (cleanPassword.length !== 16) {
    console.log('\n❌ 앱 비밀번호는 16자리여야 합니다.');
    rl.close();
    return;
  }

  // .env 파일 업데이트
  const envPath = path.join(__dirname, '../.env');
  let envContent = '';
  
  try {
    envContent = fs.readFileSync(envPath, 'utf8');
  } catch (error) {
    console.log('❌ .env 파일을 찾을 수 없습니다.');
    rl.close();
    return;
  }

  // SMTP 설정 업데이트
  envContent = envContent.replace(/SMTP_HOST=.*/, 'SMTP_HOST=smtp.gmail.com');
  envContent = envContent.replace(/SMTP_PORT=.*/, 'SMTP_PORT=587');
  envContent = envContent.replace(/SMTP_SECURE=.*/, 'SMTP_SECURE=false');
  envContent = envContent.replace(/SMTP_USER=.*/, `SMTP_USER=${email}`);
  envContent = envContent.replace(/SMTP_PASS=.*/, `SMTP_PASS=${cleanPassword}`);
  envContent = envContent.replace(/EMAIL_FROM=.*/, `EMAIL_FROM=${email}`);

  // 없는 설정은 추가
  if (!envContent.includes('SMTP_HOST=')) {
    envContent += `\n# Gmail SMTP Configuration\n`;
    envContent += `SMTP_HOST=smtp.gmail.com\n`;
    envContent += `SMTP_PORT=587\n`;
    envContent += `SMTP_SECURE=false\n`;
    envContent += `SMTP_USER=${email}\n`;
    envContent += `SMTP_PASS=${cleanPassword}\n`;
    envContent += `EMAIL_FROM=${email}\n`;
  }

  try {
    fs.writeFileSync(envPath, envContent);
    console.log('\n✅ .env 파일이 업데이트되었습니다!');
    console.log('\n🧪 이제 이메일 테스트를 실행해보세요:');
    console.log('npm run test:email');
    console.log('\n또는 실제 회원가입을 테스트해보세요.');
  } catch (error) {
    console.log('\n❌ .env 파일 업데이트에 실패했습니다:', error);
  }

  rl.close();
}

setupGmail().catch(console.error);