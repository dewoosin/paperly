# Paperly Database Migrations v2.0

Google/Facebook 수준의 고급 추천 시스템 및 사용자 행동 분석을 위한 데이터베이스 스키마입니다.

## 📋 개요

이 마이그레이션 시스템은 Paperly AI 맞춤형 학습 앱을 위한 완전한 데이터베이스 스키마를 제공합니다:

- **핵심 비즈니스 테이블**: 사용자, 카테고리, 태그, 게시글, 작가 관리
- **고급 추천 시스템**: 벡터 임베딩, AI 분석, 개인화 추천
- **사용자 행동 분석**: Google Analytics 수준의 상세 추적
- **보안 모니터링**: 실시간 위험 평가 및 이벤트 추적

## 🚀 빠른 시작

### 1. 환경 변수 설정

```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=paperly
export DB_USER=paperly_user
export DB_PASSWORD=your_password_here
```

### 2. 마이그레이션 실행

```bash
# 기본 실행
./run_migrations.sh

# 백업과 함께 실행
BACKUP_BEFORE_MIGRATION=true ./run_migrations.sh

# 오류 발생 시에도 계속 진행
CONTINUE_ON_ERROR=true ./run_migrations.sh
```

### 3. 구조 확인

```bash
# 데이터베이스 구조만 확인
./run_migrations.sh --verify-only
```

## 📁 마이그레이션 파일 구조

```
migrations/
├── 000_create_paperly_schema.sql     # 기본 스키마 생성
├── 001_paperly_master_schema.sql     # 핵심 비즈니스 테이블
├── 002_recommendation_system.sql     # 고급 추천 시스템
├── 003_user_behavior_analytics.sql   # 사용자 행동 분석
├── 004_security_system.sql           # 보안 모니터링
├── run_migrations.sh                 # 실행 스크립트
├── README.md                         # 이 문서
└── archive/                          # 구버전 파일들
    ├── 001_init_schema.sql
    ├── 004_paperly_complete_schema.sql
    └── ...
```

## 🗃️ 주요 테이블 그룹

### 1. 사용자 관리 (User Management)
- `users`: 사용자 기본 정보
- `user_roles`: 역할 및 권한 관리
- `user_onboarding_steps`: 온보딩 단계 추적
- `writer_profiles`: 작가 프로필 관리

### 2. 콘텐츠 관리 (Content Management)
- `categories`: 계층적 카테고리 시스템
- `tags`: 스마트 태그 및 관심사 추적
- `articles`: 게시글 및 메타데이터
- `article_series`: 시리즈 연재 관리

### 3. 추천 시스템 (Recommendation System)
- `user_interest_profiles`: 사용자 관심사 분석
- `content_embeddings`: 콘텐츠 벡터 임베딩
- `user_recommendations`: 개인화 추천 결과
- `recommendation_feedback`: 추천 성과 피드백

### 4. 행동 분석 (Behavior Analytics)
- `user_sessions`: 세션 추적
- `page_views`: 페이지 조회 분석
- `interaction_events`: 상호작용 이벤트
- `reading_behaviors`: 읽기 행동 상세 분석
- `daily_reading_patterns`: 일일 읽기 패턴

### 5. 보안 모니터링 (Security Monitoring)
- `security_events`: 보안 이벤트 로그
- `login_attempts`: 로그인 시도 기록
- `user_risk_profiles`: 사용자 위험 프로필
- `api_access_logs`: API 접근 로그

## 🔧 고급 기능

### 벡터 임베딩 지원
- OpenAI Ada-002 호환 임베딩 저장
- 콘텐츠 유사도 계산 지원
- 사용자 선호도 벡터화

### 실시간 분석 뷰
- `user_360_view`: 사용자 종합 프로필
- `content_performance_dashboard`: 콘텐츠 성과 분석
- `security_dashboard`: 실시간 보안 모니터링

### 자동화 트리거
- 통계 자동 업데이트
- 위험 점수 자동 계산
- 관심사 프로필 자동 갱신

## 📊 성능 최적화

### 인덱스 전략
- 복합 인덱스로 쿼리 최적화
- GIN 인덱스로 JSON 검색 가속
- 부분 인덱스로 저장공간 절약

### 파티셔닝
- 시간 기반 파티셔닝 준비
- 대용량 로그 테이블 분할 지원

## 🛡️ 보안 기능

### 자동 위험 평가
- 실시간 사용자 위험 점수 계산
- 의심스러운 패턴 자동 탐지
- 로그인 이상 행동 모니터링

### 감사 로그
- 모든 데이터 접근 기록
- API 호출 추적
- 관리자 활동 모니터링

## 🔄 마이그레이션 옵션

### 환경 변수
- `DB_HOST`: 데이터베이스 호스트 (기본값: localhost)
- `DB_PORT`: 데이터베이스 포트 (기본값: 5432)
- `DB_NAME`: 데이터베이스 이름 (기본값: paperly)
- `DB_USER`: 데이터베이스 사용자 (기본값: paperly_user)
- `DB_PASSWORD`: 데이터베이스 비밀번호 (필수)
- `BACKUP_BEFORE_MIGRATION`: 마이그레이션 전 백업 생성
- `CONTINUE_ON_ERROR`: 오류 발생 시 계속 진행

### 실행 옵션
```bash
# 도움말 보기
./run_migrations.sh --help

# 구조 검증만 실행
./run_migrations.sh --verify-only

# 백업만 생성
./run_migrations.sh --backup-only
```

## 📈 예상 테이블 수

마이그레이션 완료 후 생성되는 구조:
- **테이블**: 30+ 개
- **뷰**: 5+ 개  
- **함수**: 10+ 개
- **인덱스**: 50+ 개
- **트리거**: 15+ 개

## 🎯 사용 사례

### 추천 시스템
```sql
-- 사용자별 개인화 추천 조회
SELECT a.title, ur.recommendation_score, ur.explanation_text
FROM paperly.user_recommendations ur
JOIN paperly.articles a ON ur.article_id = a.id
WHERE ur.user_id = ? AND ur.expires_at > NOW()
ORDER BY ur.recommendation_score DESC;
```

### 행동 분석
```sql
-- 사용자 읽기 패턴 분석
SELECT 
    user_id,
    average_reading_speed_wpm,
    preferred_article_length,
    average_completion_rate
FROM paperly.user_reading_patterns
WHERE user_id = ?;
```

### 보안 모니터링
```sql
-- 고위험 사용자 조회
SELECT * FROM paperly.high_risk_users
WHERE current_risk_score > 70;
```

## 🤝 기여

이 스키마는 지속적으로 개선되고 있습니다. 새로운 기능 제안이나 최적화 아이디어가 있으시면 언제든 공유해주세요.

## 📄 라이선스

Paperly 프로젝트의 일부로 관리됩니다.

---

**참고**: 이 스키마는 Google과 Facebook의 추천 시스템 아키텍처를 참고하여 설계되었으며, 대규모 사용자 기반과 실시간 개인화를 지원할 수 있도록 최적화되었습니다.