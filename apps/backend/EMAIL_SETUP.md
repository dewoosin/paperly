# 📧 이메일 설정 가이드

실제 이메일을 보내기 위해 SMTP 설정이 필요합니다.

## 🔐 Gmail SMTP 설정 (추천)

### 1단계: Google 계정 설정
1. [Google 계정](https://myaccount.google.com/)에 로그인
2. **보안** 탭으로 이동
3. **2단계 인증**을 활성화 (필수)

### 2단계: 앱 비밀번호 생성
1. 2단계 인증 활성화 후, **앱 비밀번호** 메뉴 찾기
2. **앱 선택** → "메일" 선택
3. **기기 선택** → "기타(맞춤 이름)" 선택 → "Paperly" 입력
4. **생성** 클릭
5. 16자리 앱 비밀번호를 복사 (공백 제거)

### 3단계: .env 파일 설정
```bash
# 현재 .env 파일 편집
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@gmail.com
SMTP_PASS=generated-app-password
EMAIL_FROM=your-email@gmail.com
EMAIL_FROM_NAME=Paperly
```

### 4단계: 테스트
```bash
npm run test:email
```

## 🌐 다른 이메일 서비스 옵션

### SendGrid (프로덕션 추천)
```bash
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=apikey
SMTP_PASS=your-sendgrid-api-key
```

### Outlook/Hotmail
```bash
SMTP_HOST=smtp-mail.outlook.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@outlook.com
SMTP_PASS=your-password
```

### AWS SES
```bash
SMTP_HOST=email-smtp.us-east-1.amazonaws.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-aws-access-key
SMTP_PASS=your-aws-secret-key
```

## 🛠️ 문제 해결

### "Invalid login" 오류
- 앱 비밀번호를 올바르게 입력했는지 확인
- 2단계 인증이 활성화되어 있는지 확인
- Gmail의 경우 "보안 수준이 낮은 앱 액세스"를 허용할 필요 없음 (앱 비밀번호 사용 시)

### "Connection timeout" 오류
- 네트워크 연결 확인
- 방화벽이 587 포트를 차단하지 않는지 확인
- WSL의 경우 Windows 방화벽 설정 확인

### 이메일이 스팸함에 들어가는 경우
- SPF, DKIM, DMARC 레코드 설정 (도메인 소유 시)
- Gmail의 경우 처음에는 스팸함에 들어갈 수 있음 (정상적인 현상)

## 📋 개발 vs 프로덕션

### 개발 환경
- Gmail SMTP 사용 (무료, 하루 500통 제한)
- 테스트 목적으로 충분

### 프로덕션 환경
- SendGrid, AWS SES, Mailgun 등 전문 서비스 사용
- 높은 전달률과 대량 발송 지원
- 상세한 분석과 모니터링 제공