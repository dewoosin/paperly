# Paperly 백엔드 개발자 가이드

이 가이드는 Paperly 백엔드 API 서버 개발에 참여하는 개발자들을 위한 포괄적인 문서를 제공합니다. 아키텍처, 설정, 개발 관행, 배포 절차를 다룹니다.

## 목차

1. [개요](#개요)
2. [Paperly 시스템에서의 역할](#paperly-시스템에서의-역할)
3. [핵심 기능](#핵심-기능)
4. [아키텍처](#아키텍처)
5. [기술 스택](#기술-스택)
6. [프로젝트 구조](#프로젝트-구조)
7. [개발 환경 설정](#개발-환경-설정)
8. [API 문서](#api-문서)
9. [데이터베이스 스키마](#데이터베이스-스키마)
10. [테스트](#테스트)
11. [배포](#배포)
12. [문제 해결](#문제-해결)

---

## 개요

Paperly 백엔드는 모든 클라이언트 애플리케이션(모바일, 작가, 관리자)을 지원하는 중앙 API 서버입니다. Node.js와 TypeScript로 구축되었으며, 확장성, 유지보수성, 테스트 가능성을 보장하기 위해 클린 아키텍처와 도메인 주도 설계 원칙을 따릅니다.

### 주요 책임
- **API 게이트웨이**: 모든 클라이언트 애플리케이션을 위한 통합 API
- **비즈니스 로직**: 핵심 도메인 로직과 유스케이스
- **데이터 지속성**: 데이터베이스 작업 및 캐싱
- **인증**: 리프레시 토큰을 포함한 JWT 기반 인증
- **AI 통합**: 콘텐츠 추천 및 생성
- **이메일 서비스**: 트랜잭션 이메일 및 알림
- **보안**: 속도 제한, 입력 검증, 모니터링

---

## Paperly 시스템에서의 역할

백엔드는 Paperly 플랫폼의 중추 신경계 역할을 합니다:

```
┌─────────────────────────────────────────────────────────┐
│                    클라이언트 애플리케이션                 │
├───────────────┬─────────────────┬───────────────────────┤
│  모바일 앱     │   작가 앱        │    관리자 패널         │
└───────┬───────┴────────┬────────┴───────┬───────────────┘
        │                │                │
        └────────────────┼────────────────┘
                         │
                   ┌─────▼─────┐
                   │  백엔드    │
                   │  API 서버  │
                   └─────┬─────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
   ┌────▼────┐    ┌─────▼─────┐   ┌─────▼─────┐
   │PostgreSQL│    │   Redis   │   │ AI 서비스  │
   │    DB    │    │   캐시     │   │  (OpenAI) │
   └─────────┘    └───────────┘   └───────────┘
```

### 다중 클라이언트 아키텍처
- **모바일 API** (`/api/v1/mobile/*`): 독자 중심 엔드포인트
- **작가 API** (`/api/v1/writer/*`): 콘텐츠 생성 엔드포인트
- **관리자 API** (`/api/v1/admin/*`): 플랫폼 관리 엔드포인트

---

## 핵심 기능

### 1. 사용자 관리
- **등록**: 인증을 포함한 이메일/비밀번호 등록
- **인증**: 장치 추적을 포함한 JWT 토큰
- **프로필 관리**: 사용자 선호도 및 설정
- **세션 관리**: 다중 장치 지원

### 2. 콘텐츠 관리
- **기사 CRUD**: 기사 생성, 읽기, 업데이트, 삭제
- **카테고리 및 태그**: 콘텐츠 구성
- **검색 및 필터**: 전문 검색 기능
- **버전 관리**: 기사 기록 및 초안

### 3. 개인화 및 AI
- **추천**: AI 기반 콘텐츠 제안
- **사용자 행동**: 읽기 패턴 분석
- **콘텐츠 생성**: AI 지원 글쓰기
- **선호도 학습**: 적응형 알고리즘

### 4. 소셜 기능
- **작가 팔로우**: 작가 구독
- **좋아요 및 북마크**: 콘텐츠 상호작용
- **댓글**: 독자 참여 (계획 중)
- **공유**: 소셜 미디어 통합

### 5. 분석 및 보고
- **읽기 분석**: 시간, 완료율, 참여도
- **작가 대시보드**: 성과 지표
- **관리자 분석**: 플랫폼 전체 통계
- **수익 추적**: 구독 분석

### 6. 시스템 서비스
- **이메일 서비스**: 트랜잭션 이메일
- **알림 시스템**: 푸시 알림
- **파일 저장소**: 이미지 및 문서 처리
- **백그라운드 작업**: 비동기 작업 처리

---

## 아키텍처

### 클린 아키텍처 레이어

```
┌─────────────────────────────────────────────────────┐
│                 프레젠테이션 레이어                   │
│         (컨트롤러, 라우트, 미들웨어)                  │
├─────────────────────────────────────────────────────┤
│                 애플리케이션 레이어                   │
│          (유스케이스, DTO, 서비스)                    │
├─────────────────────────────────────────────────────┤
│                   도메인 레이어                       │
│     (엔티티, 값 객체, 도메인 서비스)                  │
├─────────────────────────────────────────────────────┤
│                인프라스트럭처 레이어                  │
│  (데이터베이스, 외부 API, 이메일, 파일 시스템)       │
└─────────────────────────────────────────────────────┘
```

### 설계 원칙
1. **의존성 역전**: 핵심 도메인은 외부 의존성이 없음
2. **단일 책임**: 각 클래스는 변경의 이유가 하나
3. **인터페이스 분리**: 작고 집중된 인터페이스
4. **의존성 주입**: IoC 컨테이너로 TSyringe 사용
5. **도메인 주도 설계**: 풍부한 도메인 모델

---

## 기술 스택

### 핵심 기술
| 기술 | 버전 | 목적 |
|------------|---------|---------|
| Node.js | 20.x | 런타임 환경 |
| TypeScript | 5.x | 타입 안전성 |
| Express.js | 4.x | 웹 프레임워크 |
| PostgreSQL | 15 | 주 데이터베이스 |
| Redis | 7.x | 캐싱 및 세션 |
| TypeORM | 0.3.x | ORM |
| TSyringe | 4.x | 의존성 주입 |

### 보안 및 검증
| 기술 | 목적 |
|------------|---------|
| JWT | 인증 토큰 |
| bcrypt | 비밀번호 해싱 |
| Helmet | 보안 헤더 |
| express-rate-limit | 속도 제한 |
| Zod | 스키마 검증 |
| express-validator | 입력 검증 |

### 개발 및 테스트
| 기술 | 목적 |
|------------|---------|
| Jest | 단위 테스트 |
| Supertest | 통합 테스트 |
| Winston | 로깅 |
| ESLint | 코드 린팅 |
| tsx | TypeScript 실행 |

---

## 프로젝트 구조

```
apps/backend/
├── src/
│   ├── domain/                 # 핵심 비즈니스 로직
│   │   ├── entities/          # 비즈니스 엔티티
│   │   ├── value-objects/     # 값 객체 (Email, Password)
│   │   ├── repositories/      # 리포지토리 인터페이스
│   │   ├── services/          # 도메인 서비스
│   │   └── events/            # 도메인 이벤트
│   │
│   ├── application/           # 애플리케이션 비즈니스 로직
│   │   ├── use-cases/        # 비즈니스 작업
│   │   ├── dto/              # 데이터 전송 객체
│   │   ├── services/         # 애플리케이션 서비스
│   │   └── interfaces/       # 포트 인터페이스
│   │
│   ├── infrastructure/        # 외부 관심사
│   │   ├── web/              # HTTP 레이어
│   │   │   ├── controllers/  # 요청 핸들러
│   │   │   ├── routes/       # 라우트 정의
│   │   │   ├── middleware/   # Express 미들웨어
│   │   │   └── validators/   # 요청 검증
│   │   ├── database/         # 데이터베이스 구현
│   │   ├── repositories/     # 리포지토리 구현
│   │   ├── email/           # 이메일 서비스
│   │   ├── auth/            # 인증 구현
│   │   ├── logging/         # 로거 설정
│   │   └── config/          # 설정
│   │
│   ├── shared/               # 공유 유틸리티
│   │   ├── errors/          # 오류 정의
│   │   ├── constants/       # 상수
│   │   └── utils/           # 도우미 함수
│   │
│   └── main.ts              # 애플리케이션 진입점
│
├── scripts/                  # 유틸리티 스크립트
│   ├── check-db.ts          # 데이터베이스 연결 테스트
│   ├── test-email.ts        # 이메일 서비스 테스트
│   └── setup-gmail.ts       # Gmail 설정
│
├── tests/                    # 테스트 파일
│   ├── unit/                # 단위 테스트
│   ├── integration/         # 통합 테스트
│   └── e2e/                 # 엔드투엔드 테스트
│
├── database/                # 데이터베이스 파일
│   ├── migrations/          # 데이터베이스 마이그레이션
│   └── seeds/               # 시드 데이터
│
└── config/                  # 설정 파일
```

### 주요 디렉토리 설명

- **domain/**: 순수 비즈니스 로직, 프레임워크 의존성 없음
- **application/**: 도메인 로직 조율, 유스케이스 처리
- **infrastructure/**: 모든 외부 의존성 및 통합
- **shared/**: 레이어 전반에서 사용되는 공통 관심사

---

## 개발 환경 설정

### 필수 조건
- Node.js 20.x 이상
- Docker & Docker Compose
- PostgreSQL 클라이언트 (선택사항)

### 빠른 시작

1. **백엔드로 이동**
```bash
cd apps/backend
```

2. **의존성 설치**
```bash
npm install
```

3. **환경 설정**
```bash
# 환경 템플릿 복사
cp .env.example .env

# JWT 시크릿 생성
openssl rand -hex 32  # JWT_ACCESS_SECRET
openssl rand -hex 32  # JWT_REFRESH_SECRET
```

4. **서비스 시작**
```bash
# Docker 서비스 시작 (PostgreSQL, Redis)
npm run docker:up

# 데이터베이스 연결 확인
npm run db:check
```

5. **개발 서버 실행**
```bash
# 표준 개발
npm run dev

# WSL 개발 (호스트 IP 자동 감지)
npm run dev:wsl

# 디버그 로깅과 함께
npm run dev:debug
```

### 환경 변수

| 변수 | 설명 | 기본값 |
|----------|-------------|---------|
| `PORT` | 서버 포트 | 3000 |
| `NODE_ENV` | 환경 | development |
| `DATABASE_URL` | PostgreSQL 연결 | - |
| `REDIS_URL` | Redis 연결 | - |
| `JWT_ACCESS_SECRET` | 액세스 토큰 시크릿 | - |
| `JWT_REFRESH_SECRET` | 리프레시 토큰 시크릿 | - |
| `JWT_ACCESS_EXPIRY` | 액세스 토큰 TTL | 15m |
| `JWT_REFRESH_EXPIRY` | 리프레시 토큰 TTL | 7d |

---

## API 문서

### 기본 URL 구조
```
https://api.paperly.com/api/v1/{client}/{resource}
```

여기서 `{client}`는 다음 중 하나입니다:
- `mobile` - 모바일 앱 엔드포인트
- `writer` - 작가 대시보드 엔드포인트  
- `admin` - 관리자 패널 엔드포인트

### 인증 및 보안

#### JWT 토큰 구조
- **알고리즘**: HS256 (HMAC SHA-256)
- **발행자**: "paperly"
- **대상**: "paperly-app"
- **액세스 토큰 만료**: 15분
- **리프레시 토큰 만료**: 7일

#### 인증 헤더
모든 보호된 엔드포인트는 헤더에 JWT 토큰이 필요합니다:
```
Authorization: Bearer {access_token}
X-Client-Type: mobile|writer|admin
X-Device-ID: {device_uuid} (선택사항이지만 권장)
```

#### 클라이언트 검증
각 엔드포인트는 미들웨어를 사용하여 클라이언트 유형을 검증합니다:
- `requireMobileClient` - 모바일 엔드포인트용
- `requireWriterClient` - 작가 엔드포인트용
- `requireAdminClient` - 관리자 엔드포인트용

#### 속도 제한
- **인증**: 15분당 5회 요청 (엄격한 속도 제한)
- **API 호출**: 15분당 100회 요청 (표준 속도 제한)
- **관리자 로그인**: 15분당 5회 요청 (관리자 전용 제한)

#### 구현 상태

**모바일 API (`/api/v1/mobile/`)**
- ✅ **완전 구현**: 인증, 기사 탐색, 카테고리 (기본 + 고급), 포괄적인 추천 시스템, 전체 온보딩 플로우
- ⚠️ **플레이스홀더 구현**: 사용자 프로필 관리, 북마크, 읽기 기록 (엔드포인트는 존재하지만 모의 데이터 반환)

**작가 API (`/api/v1/writer/`)**
- ✅ **완전 구현**: 인증, 기사 CRUD 작업, 대시보드 지표
- ⚠️ **플레이스홀더 구현**: 프로필 관리, 분석, 초안 관리 (엔드포인트는 존재하지만 모의 데이터 반환)

**관리자 API (`/api/v1/admin/`)**
- ✅ **완전 구현**: 인증, 보안 모니터링, 기사 관리
- ⚠️ **플레이스홀더 구현**: 사용자 관리, 작가 관리, 카테고리 관리 (엔드포인트는 존재하지만 모의 데이터 반환)
- ❌ **구현되지 않음**: 시스템 관리 엔드포인트 (통계, 설정, 로그) - 501 Not Implemented 반환

**레거시 API (`/api/v1/`)**
- ✅ **완전 구현**: 인증, 기사, 카테고리, 추천, 온보딩을 위한 하위 호환성 엔드포인트

---

## 모바일 앱 API (`/api/v1/mobile/`)

### 인증 (`/auth`)

#### 사용자 등록
```http
POST /api/v1/mobile/auth/register
Content-Type: application/json
X-Client-Type: mobile

{
  "username": "string",
  "email": "string", 
  "password": "string",
  "name": "string",
  "deviceId": "generated-uuid"
}
```

**응답:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "username": "string",
      "email": "string",
      "name": "string",
      "isEmailVerified": false,
      "createdAt": "ISO-date"
    },
    "tokens": {
      "accessToken": "jwt-token",
      "refreshToken": "jwt-token"
    }
  }
}
```

#### 사용자 로그인
```http
POST /api/v1/mobile/auth/login
Content-Type: application/json
X-Client-Type: mobile

{
  "email": "string",
  "password": "string",
  "deviceId": "device-uuid"
}
```

**응답:** 등록과 동일

#### 토큰 갱신
```http
POST /api/v1/mobile/auth/refresh
Content-Type: application/json

{
  "refreshToken": "stored-refresh-token",
  "deviceId": "device-uuid"
}
```

#### 로그아웃
```http
POST /api/v1/mobile/auth/logout
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "deviceId": "device-uuid"
}
```

#### 이메일 인증
```http
GET /api/v1/mobile/auth/verify-email?token=verification-token
```

#### 인증 이메일 재전송
```http
POST /api/v1/mobile/auth/resend-verification
Content-Type: application/json

{
  "email": "user@example.com"
}
```

#### 사용자명 사용 가능 여부 확인
```http
POST /api/v1/mobile/auth/check-username
Content-Type: application/json

{
  "username": "desired_username"
}
```

#### 이메일 인증 건너뛰기 (개발 전용)
```http
POST /api/v1/mobile/auth/skip-verification
Authorization: Bearer <access_token>
```

### 기사 (`/articles`)

#### 게시된 기사 가져오기 (기본 피드)
```http
GET /api/v1/mobile/articles?page=1&limit=20&category=categoryId&sort=newest
X-Client-Type: mobile
```

**쿼리 매개변수:**
- `page` (선택사항): 페이지 번호 (기본값: 1)
- `limit` (선택사항): 페이지당 항목 수 (기본값: 20)
- `category` (선택사항): 카테고리 ID 필터
- `sort` (선택사항): 정렬 순서 (newest, oldest, popular)

**응답:**
```json
{
  "success": true,
  "data": {
    "articles": [
      {
        "id": "uuid",
        "title": "기사 제목",
        "excerpt": "기사 요약...",
        "author": {
          "id": "uuid",
          "username": "writer1",
          "avatar": "url"
        },
        "category": {
          "id": "uuid",
          "name": "기술"
        },
        "publishedAt": "ISO-date",
        "readingTimeMinutes": 5,
        "likesCount": 42,
        "isLiked": false,
        "featuredImage": "url"
      }
    ],
    "pagination": {
      "total": 150,
      "page": 1,
      "limit": 20,
      "totalPages": 8
    }
  }
}
```

#### 추천 기사 가져오기
```http
GET /api/v1/mobile/articles/featured
X-Client-Type: mobile
```

#### 트렌딩 기사 가져오기
```http
GET /api/v1/mobile/articles/trending
X-Client-Type: mobile
```

#### 기사 검색
```http
GET /api/v1/mobile/articles/search?q=keyword&page=1&limit=20
X-Client-Type: mobile
```

#### ID로 기사 가져오기
```http
GET /api/v1/mobile/articles/:id
X-Client-Type: mobile
```

#### 작가별 기사 가져오기
```http
GET /api/v1/mobile/articles/author/:authorId?page=1&limit=20
X-Client-Type: mobile
```

#### 카테고리별 기사 가져오기
```http
GET /api/v1/mobile/articles/category/:categoryId?page=1&limit=20
X-Client-Type: mobile
```

#### 기사 좋아요
```http
POST /api/v1/mobile/articles/:id/like
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### 기사 좋아요 취소
```http
DELETE /api/v1/mobile/articles/:id/like
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### 좋아요 상태 토글
```http
POST /api/v1/mobile/articles/:id/toggle-like
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### 좋아요 상태 가져오기
```http
GET /api/v1/mobile/articles/:id/like-status
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

### 카테고리 (`/categories`)

#### 모든 카테고리 가져오기
```http
GET /api/v1/mobile/categories
X-Client-Type: mobile
```

**응답:**
```json
{
  "success": true,
  "data": {
    "categories": [
      {
        "id": "uuid",
        "name": "기술",
        "slug": "technology",
        "description": "기술 기사",
        "articlesCount": 45,
        "featured": true
      }
    ]
  }
}
```

#### 카테고리 트리 가져오기
```http
GET /api/v1/mobile/categories/tree
X-Client-Type: mobile
```

#### 추천 카테고리 가져오기
```http
GET /api/v1/mobile/categories/featured
X-Client-Type: mobile
```

#### 카테고리 상세 정보 가져오기
```http
GET /api/v1/mobile/categories/:id
X-Client-Type: mobile
```

#### 카테고리 기사 가져오기
```http
GET /api/v1/mobile/categories/:id/articles?page=1&limit=20
X-Client-Type: mobile
```

#### 하위 카테고리 가져오기
```http
GET /api/v1/mobile/categories/:id/subcategories
X-Client-Type: mobile
```

#### 카테고리 구독
```http
POST /api/v1/mobile/categories/:id/subscribe
Authorization: Bearer <access_token>
X-Client-Type: mobile
Content-Type: application/json

{
  "notificationEnabled": true,
  "priorityLevel": 5
}
```

#### 카테고리 구독 해제
```http
DELETE /api/v1/mobile/categories/:id/subscribe
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### 내 카테고리 구독 가져오기
```http
GET /api/v1/mobile/categories/subscriptions/my
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

### 추천 (`/recommendations`)

#### 개인화된 추천 가져오기
```http
GET /api/v1/mobile/recommendations/personal
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### 홈페이지 추천 가져오기
```http
GET /api/v1/mobile/recommendations/homepage
X-Client-Type: mobile
```

#### 유사 기사 가져오기
```http
GET /api/v1/mobile/recommendations/similar/:articleId?limit=5
X-Client-Type: mobile
```

#### 트렌딩 추천 가져오기
```http
GET /api/v1/mobile/recommendations/trending?period=24h&limit=10&category=categoryId
X-Client-Type: mobile
```

#### 카테고리 추천 가져오기
```http
GET /api/v1/mobile/recommendations/category/:categoryId?limit=10
X-Client-Type: mobile
```

#### 추천 피드백 제출
```http
POST /api/v1/mobile/recommendations/feedback
Authorization: Bearer <access_token>
X-Client-Type: mobile
Content-Type: application/json

{
  "recommendationId": "rec-uuid",
  "feedbackType": "like|dislike|not_interested|inappropriate",
  "feedbackValue": true,
  "reason": "선택적 이유",
  "articleId": "article-uuid"
}
```

#### 추천 상호작용 추적
```http
POST /api/v1/mobile/recommendations/interaction
Authorization: Bearer <access_token>
X-Client-Type: mobile
Content-Type: application/json

{
  "recommendationId": "rec-uuid",
  "interactionType": "impression|click|like|bookmark|share",
  "articleId": "article-uuid",
  "timeToInteraction": 1500,
  "context": "homepage"
}
```

#### 추천 해제
```http
POST /api/v1/mobile/recommendations/dismiss/:recommendationId
Authorization: Bearer <access_token>
X-Client-Type: mobile
Content-Type: application/json

{
  "reason": "not_interested"
}
```

#### 추천 새로고침
```http
POST /api/v1/mobile/recommendations/refresh
Authorization: Bearer <access_token>
X-Client-Type: mobile
Content-Type: application/json

{
  "force": false
}
```

#### 추천 설정 가져오기
```http
GET /api/v1/mobile/recommendations/settings
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### 추천 설정 업데이트
```http
PUT /api/v1/mobile/recommendations/settings
Authorization: Bearer <access_token>
X-Client-Type: mobile
Content-Type: application/json

{
  "personalizedRecommendations": true,
  "includePopularContent": true,
  "diversityLevel": "medium",
  "noveltyPreference": 0.3,
  "difficultyRange": [2, 4],
  "contentTypes": ["article", "tutorial", "opinion"],
  "excludedCategories": [],
  "refreshFrequency": "daily",
  "notificationSettings": {
    "newRecommendations": true,
    "weeklyDigest": true,
    "trendingAlerts": false
  }
}
```

### 온보딩 (`/onboarding`)

#### 온보딩 상태 가져오기
```http
GET /api/v1/mobile/onboarding/status
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### 온보딩 단계 가져오기
```http
GET /api/v1/mobile/onboarding/steps
X-Client-Type: mobile
```

#### 사용자 관심사 설정
```http
POST /api/v1/mobile/onboarding/interests
Authorization: Bearer <access_token>
X-Client-Type: mobile
Content-Type: application/json

{
  "categoryIds": ["tech-id", "business-id", "lifestyle-id"],
  "tagNames": ["programming", "startup", "productivity"],
  "customInterests": ["machine learning", "blockchain"]
}
```

#### 읽기 선호도 설정
```http
POST /api/v1/mobile/onboarding/reading-preferences
Authorization: Bearer <access_token>
X-Client-Type: mobile
Content-Type: application/json

{
  "preferredLength": "medium",
  "difficulty": 3,
  "readingTimeSlots": ["morning", "evening"],
  "dailyReadingGoal": 15,
  "preferredTopics": ["tutorials", "opinion"]
}
```

#### AI 개인화 동의 설정
```http
POST /api/v1/mobile/onboarding/ai-consent
Authorization: Bearer <access_token>
X-Client-Type: mobile
Content-Type: application/json

{
  "aiPersonalizationConsent": true,
  "dataCollectionConsent": true
}
```

#### 온보딩 완료
```http
POST /api/v1/mobile/onboarding/complete
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### 온보딩 건너뛰기
```http
POST /api/v1/mobile/onboarding/skip
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### 온보딩 재시작
```http
POST /api/v1/mobile/onboarding/restart
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

### 사용자 프로필 (`/user`)
**참고:** 모든 사용자 엔드포인트는 모의 응답을 반환하는 플레이스홀더 구현입니다. 사용자 프로필, 북마크, 읽기 기록에 대한 데이터베이스 통합이 구현 대기 중입니다.

#### 사용자 프로필 가져오기
```http
GET /api/v1/mobile/user/profile
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### 프로필 업데이트
```http
PUT /api/v1/mobile/user/profile
Authorization: Bearer <access_token>
X-Client-Type: mobile
Content-Type: application/json

{
  "username": "new_username",
  "bio": "사용자 소개",
  "avatar": "base64_image_data"
}
```

#### 읽기 기록 가져오기
```http
GET /api/v1/mobile/user/reading-history
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### 북마크 가져오기
```http
GET /api/v1/mobile/user/bookmarks
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### 북마크 추가
```http
POST /api/v1/mobile/user/bookmarks/:articleId
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

#### 북마크 제거
```http
DELETE /api/v1/mobile/user/bookmarks/:articleId
Authorization: Bearer <access_token>
X-Client-Type: mobile
```

---

## 작가 앱 API (`/api/v1/writer/`)

### 인증 (`/auth`)
모바일 인증과 동일한 엔드포인트이지만 다른 클라이언트 검증을 사용합니다.

### 프로필 (`/profile`)

#### 작가 프로필 가져오기
```http
GET /api/v1/writer/profile
Authorization: Bearer <access_token>
X-Client-Type: writer
```

**참고:** 플레이스홀더 구현 - 모의 응답 반환.

#### 작가 프로필 업데이트
```http
PUT /api/v1/writer/profile  
Authorization: Bearer <access_token>
X-Client-Type: writer
Content-Type: application/json

{
  "fullName": "업데이트된 이름",
  "bio": "업데이트된 소개...",
  "socialLinks": {
    "twitter": "https://twitter.com/username",
    "linkedin": "https://linkedin.com/in/username"
  }
}
```

**참고:** 플레이스홀더 구현 - 모의 응답 반환.

### 기사 (`/articles`)

#### 기사 생성
```http
POST /api/v1/writer/articles
Authorization: Bearer <access_token>
X-Client-Type: writer
Content-Type: application/json

{
  "title": "기사 제목",
  "content": "전체 기사 내용...",
  "excerpt": "기사 요약...",
  "categoryId": "category-uuid",
  "tags": ["tag1", "tag2"],
  "featuredImage": "image-url",
  "targetAudience": ["beginner", "intermediate"],
  "isDraft": false
}
```

**응답:**
```json
{
  "success": true,
  "data": {
    "article": {
      "id": "article-uuid",
      "title": "기사 제목",
      "slug": "article-title",
      "content": "전체 내용...",
      "excerpt": "기사 요약...",
      "authorId": "writer-uuid",
      "categoryId": "category-uuid",
      "tags": ["tag1", "tag2"],
      "readingTimeMinutes": 5,
      "wordCount": 1200,
      "status": "draft",
      "createdAt": "ISO-date",
      "updatedAt": "ISO-date"
    }
  }
}
```

#### 작가의 기사 가져오기
```http
GET /api/v1/writer/articles?page=1&limit=20&status=all&sortBy=updatedAt
Authorization: Bearer <access_token>
X-Client-Type: writer
```

**쿼리 매개변수:**
- `page` (선택사항): 페이지 번호 (기본값: 1)
- `limit` (선택사항): 페이지당 항목 수 (기본값: 20) 
- `status` (선택사항): 상태별 필터 (draft, published, archived)
- `sortBy` (선택사항): 정렬 필드 (createdAt, updatedAt, title)

#### 작가 통계 가져오기
```http
GET /api/v1/writer/articles/stats
Authorization: Bearer <access_token>
X-Client-Type: writer
```

**응답:**
```json
{
  "success": true,
  "data": {
    "totalArticles": 25,
    "publishedArticles": 20,
    "draftArticles": 5,
    "totalViews": 15420,
    "totalLikes": 892,
    "averageReadingTime": 6.5
  }
}
```

#### ID로 기사 가져오기
```http
GET /api/v1/writer/articles/:id
Authorization: Bearer <access_token>
X-Client-Type: writer
```

#### 기사 업데이트
```http
PUT /api/v1/writer/articles/:id
Authorization: Bearer <access_token>
X-Client-Type: writer
Content-Type: application/json

{
  "title": "업데이트된 제목",
  "content": "업데이트된 내용...",
  "excerpt": "업데이트된 요약...",
  "tags": ["updated", "tags"]
}
```

#### 기사 삭제
```http
DELETE /api/v1/writer/articles/:id
Authorization: Bearer <access_token>
X-Client-Type: writer
```

#### 기사 게시
```http
POST /api/v1/writer/articles/:id/publish
Authorization: Bearer <access_token>
X-Client-Type: writer
Content-Type: application/json

{
  "publishAt": "ISO-date", // 선택적 예약 게시
  "notifySubscribers": true
}
```

#### 기사 게시 취소
```http
POST /api/v1/writer/articles/:id/unpublish
Authorization: Bearer <access_token>
X-Client-Type: writer
```

#### 기사 보관
```http
POST /api/v1/writer/articles/:id/archive
Authorization: Bearer <access_token>
X-Client-Type: writer
```

### 분석 (`/analytics`)
**참고:** 모든 분석 엔드포인트는 모의 응답을 반환하는 플레이스홀더 구현입니다.

#### 분석 개요 가져오기
```http
GET /api/v1/writer/analytics/overview
Authorization: Bearer <access_token>
X-Client-Type: writer
```

#### 기사 통계 가져오기
```http
GET /api/v1/writer/analytics/articles/:id/stats
Authorization: Bearer <access_token>
X-Client-Type: writer
```

#### 참여 지표 가져오기
```http
GET /api/v1/writer/analytics/engagement
Authorization: Bearer <access_token>
X-Client-Type: writer
```

#### 수익 분석 가져오기
```http
GET /api/v1/writer/analytics/revenue
Authorization: Bearer <access_token>
X-Client-Type: writer
```

### 대시보드 (`/dashboard`)

#### 대시보드 지표 가져오기
```http
GET /api/v1/writer/dashboard/metrics
Authorization: Bearer <access_token>
X-Client-Type: writer
```

**응답:**
```json
{
  "success": true,
  "data": {
    "totalViews": 15420,
    "totalLikes": 892,
    "subscribersCount": 234,
    "totalArticles": 25,
    "publishedArticles": 20,
    "draftArticles": 5,
    "averageEngagement": 8.5,
    "weeklyViews": 1250,
    "weeklyLikes": 85,
    "weeklySubscribers": 12
  }
}
```

#### 실시간 대시보드 데이터 가져오기
```http
GET /api/v1/writer/dashboard/realtime
Authorization: Bearer <access_token>
X-Client-Type: writer
```

#### 상세 대시보드 데이터 가져오기
```http
GET /api/v1/writer/dashboard/detailed
Authorization: Bearer <access_token>
X-Client-Type: writer
```

#### 기간별 대시보드 데이터 가져오기
```http
GET /api/v1/writer/dashboard/period?period=week&startDate=2024-01-01&endDate=2024-01-07
Authorization: Bearer <access_token>
X-Client-Type: writer
```

#### 대시보드 비교 데이터 가져오기
```http
GET /api/v1/writer/dashboard/comparison?period=month
Authorization: Bearer <access_token>
X-Client-Type: writer
```

### 카테고리 (`/categories`)

#### 모든 카테고리 가져오기 (읽기 전용)
```http
GET /api/v1/writer/categories
Authorization: Bearer <access_token>
X-Client-Type: writer
```

### 초안 (`/drafts`)
**참고:** 모든 초안 엔드포인트는 모의 응답을 반환하는 플레이스홀더 구현입니다.

#### 초안 가져오기
```http
GET /api/v1/writer/drafts
Authorization: Bearer <access_token>
X-Client-Type: writer
```

#### 초안 생성
```http
POST /api/v1/writer/drafts
Authorization: Bearer <access_token>
X-Client-Type: writer
Content-Type: application/json

{
  "title": "초안 제목",
  "content": "초안 내용..."
}
```

#### 초안 업데이트
```http
PUT /api/v1/writer/drafts/:id
Authorization: Bearer <access_token>
X-Client-Type: writer
Content-Type: application/json

{
  "title": "업데이트된 초안 제목",
  "content": "업데이트된 초안 내용..."
}
```

#### 초안 삭제
```http
DELETE /api/v1/writer/drafts/:id
Authorization: Bearer <access_token>
X-Client-Type: writer
```

#### 초안 자동 저장
```http
POST /api/v1/writer/drafts/:id/autosave
Authorization: Bearer <access_token>
X-Client-Type: writer
Content-Type: application/json

{
  "title": "초안 제목",
  "content": "현재 내용...",
  "lastModified": "ISO-date"
}
```

---

## 관리자 패널 API (`/api/v1/admin/`)

### 인증 (`/auth`)

#### 관리자 로그인
```http
POST /api/v1/admin/auth/login
Content-Type: application/json
X-Client-Type: admin

{
  "email": "admin@paperly.com",
  "password": "admin_password"
}
```

**보안:** 15분당 5회 요청으로 속도 제한

#### 관리자 토큰 갱신
```http
POST /api/v1/admin/auth/refresh
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### 관리자 로그아웃
```http
POST /api/v1/admin/auth/logout
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### 현재 관리자 사용자 가져오기
```http
GET /api/v1/admin/auth/me
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### 관리자 상태 확인
```http
GET /api/v1/admin/auth/verify
X-Client-Type: admin
```

### 사용자 관리 (`/users`)
**참고:** 대부분의 사용자 엔드포인트는 모의 응답을 반환하는 플레이스홀더 구현입니다.

#### 모든 사용자 목록
```http
GET /api/v1/admin/users?page=1&limit=50&search=keyword&role=all
Authorization: Bearer <access_token>
X-Client-Type: admin
```

**필요한 권한:** admin 역할

#### 관리자 사용자 가져오기
```http
GET /api/v1/admin/users/admins
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### 사용자 상세 정보 가져오기
```http
GET /api/v1/admin/users/:id
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### 사용자 업데이트
```http
PUT /api/v1/admin/users/:id
Authorization: Bearer <access_token>
X-Client-Type: admin
Content-Type: application/json

{
  "name": "업데이트된 이름",
  "email": "updated@example.com",
  "status": "active"
}
```

#### 사용자 삭제 (최고 관리자 전용)
```http
DELETE /api/v1/admin/users/:id
Authorization: Bearer <access_token>
X-Client-Type: admin
```

**필요한 권한:** super_admin 역할

#### 사용자에게 역할 할당 (최고 관리자 전용)
```http
POST /api/v1/admin/users/:userId/assign-role
Authorization: Bearer <access_token>
X-Client-Type: admin
Content-Type: application/json

{
  "roleId": "writer",
  "expiresAt": "ISO-date" // 선택사항
}
```

#### 사용자에서 역할 제거 (최고 관리자 전용)
```http
DELETE /api/v1/admin/users/:userId/remove-role
Authorization: Bearer <access_token>
X-Client-Type: admin
```

### 작가 관리 (`/writers`)
**참고:** 모든 작가 엔드포인트는 모의 응답을 반환하는 플레이스홀더 구현입니다.

#### 모든 작가 가져오기
```http
GET /api/v1/admin/writers
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### 대기 중인 작가 신청 가져오기
```http
GET /api/v1/admin/writers/pending
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### 작가 신청 승인
```http
PUT /api/v1/admin/writers/:id/approve
Authorization: Bearer <access_token>
X-Client-Type: admin
Content-Type: application/json

{
  "reason": "승인 이유",
  "permissions": ["article:create", "article:publish"]
}
```

#### 작가 신청 거부
```http
PUT /api/v1/admin/writers/:id/reject
Authorization: Bearer <access_token>
X-Client-Type: admin
Content-Type: application/json

{
  "reason": "거부 이유"
}
```

#### 작가 분석 가져오기
```http
GET /api/v1/admin/writers/:id/analytics
Authorization: Bearer <access_token>
X-Client-Type: admin
```

### 콘텐츠 관리 (`/articles`)

#### 모든 기사 목록
```http
GET /api/v1/admin/articles?page=1&limit=50&status=all&author=author-id
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### 기사 생성 (관리자)
```http
POST /api/v1/admin/articles
Authorization: Bearer <access_token>
X-Client-Type: admin
Content-Type: application/json

{
  "title": "관리자 기사",
  "content": "기사 내용...",
  "authorId": "writer-uuid",
  "categoryId": "category-uuid"
}
```

#### 기사 상세 정보 가져오기
```http
GET /api/v1/admin/articles/:id
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### 기사 업데이트
```http
PUT /api/v1/admin/articles/:id
Authorization: Bearer <access_token>
X-Client-Type: admin
Content-Type: application/json

{
  "title": "업데이트된 제목",
  "content": "업데이트된 내용..."
}
```

#### 기사 삭제
```http
DELETE /api/v1/admin/articles/:id
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### 기사 추천 설정
```http
PATCH /api/v1/admin/articles/:id/feature
Authorization: Bearer <access_token>
X-Client-Type: admin
Content-Type: application/json

{
  "featured": true,
  "featuredOrder": 1
}
```

#### 기사 추천 해제
```http
PATCH /api/v1/admin/articles/:id/unfeature
Authorization: Bearer <access_token>
X-Client-Type: admin
```

### 카테고리 관리 (`/categories`)

#### 카테고리 목록
```http
GET /api/v1/admin/categories
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### 카테고리 생성
```http
POST /api/v1/admin/categories
Authorization: Bearer <access_token>
X-Client-Type: admin
Content-Type: application/json

{
  "name": "새 카테고리",
  "description": "카테고리 설명",
  "slug": "new-category"
}
```

**참고:** 플레이스홀더 구현 - 모의 응답 반환.

#### 카테고리 업데이트
```http
PUT /api/v1/admin/categories/:id
Authorization: Bearer <access_token>
X-Client-Type: admin
Content-Type: application/json

{
  "name": "업데이트된 카테고리",
  "description": "업데이트된 설명"
}
```

**참고:** 플레이스홀더 구현 - 모의 응답 반환.

#### 카테고리 삭제
```http
DELETE /api/v1/admin/categories/:id
Authorization: Bearer <access_token>
X-Client-Type: admin
```

**참고:** 플레이스홀더 구현 - 모의 응답 반환.

### 보안 모니터링 (`/security`)

#### 보안 이벤트 로그 가져오기
```http
GET /api/v1/admin/security/events?page=1&limit=50&type=all&severity=high
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### 보안 이벤트 상세 정보 가져오기
```http
GET /api/v1/admin/security/events/:eventId
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### 보안 통계 가져오기
```http
GET /api/v1/admin/security/stats
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### IP 주소 차단
```http
POST /api/v1/admin/security/block-ip
Authorization: Bearer <access_token>
X-Client-Type: admin
Content-Type: application/json

{
  "ip": "192.168.1.100",
  "reason": "의심스러운 활동",
  "duration": 24 // 시간
}
```

#### IP 주소 차단 해제
```http
DELETE /api/v1/admin/security/unblock-ip/:ip
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### 차단된 IP 가져오기
```http
GET /api/v1/admin/security/blocked-ips
Authorization: Bearer <access_token>
X-Client-Type: admin
```

#### 이벤트 상태 업데이트
```http
PATCH /api/v1/admin/security/events/:eventId/status
Authorization: Bearer <access_token>
X-Client-Type: admin
Content-Type: application/json

{
  "status": "resolved", // detected | investigating | blocked | resolved | false_positive
  "notes": "이벤트 해결됨 - 오탐"
}
```

#### 실시간 이벤트 스트림 (Server-Sent Events)
```http
GET /api/v1/admin/security/events/stream
Authorization: Bearer <access_token>
X-Client-Type: admin
Accept: text/event-stream
```

### 시스템 관리 (`/system`)

#### 상태 확인
```http
GET /api/v1/admin/system/health
X-Client-Type: admin
```

**응답:**
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "timestamp": "ISO-date",
    "version": "1.0.0"
  },
  "message": "관리자 API 서버가 정상 작동 중입니다"
}
```

#### 시스템 통계 가져오기 (구현되지 않음)
```http
GET /api/v1/admin/system/stats
Authorization: Bearer <access_token>
X-Client-Type: admin
```

**응답:** 501 Not Implemented

#### 시스템 설정 가져오기 (최고 관리자 전용 - 구현되지 않음)
```http
GET /api/v1/admin/system/settings
Authorization: Bearer <access_token>
X-Client-Type: admin
```

**필요한 권한:** super_admin 역할  
**응답:** 501 Not Implemented

#### 시스템 설정 업데이트 (최고 관리자 전용 - 구현되지 않음)
```http
PUT /api/v1/admin/system/settings
Authorization: Bearer <access_token>
X-Client-Type: admin
Content-Type: application/json
```

**필요한 권한:** super_admin 역할  
**응답:** 501 Not Implemented

#### 시스템 로그 가져오기 (구현되지 않음)
```http
GET /api/v1/admin/system/logs?level=error&limit=100
Authorization: Bearer <access_token>
X-Client-Type: admin
```

**필요한 권한:** logs:read 권한  
**응답:** 501 Not Implemented

---

## 레거시 API 엔드포인트 (사용 중단)

**⚠️ 사용 중단 알림:** 이러한 엔드포인트는 하위 호환성을 위해 유지되지만 새로운 구현에서는 사용해서는 안 됩니다. 모든 클라이언트는 위의 클라이언트별 엔드포인트로 마이그레이션해야 합니다.

### 레거시 인증 (`/api/v1/auth`)
- `POST /api/v1/auth/register` - 모바일 등록과 동일
- `POST /api/v1/auth/login` - 모바일 로그인과 동일
- `POST /api/v1/auth/refresh` - 모바일 토큰 갱신과 동일
- `POST /api/v1/auth/logout` - 모바일 로그아웃과 동일
- `GET /api/v1/auth/verify-email` - 모바일 이메일 인증과 동일
- `POST /api/v1/auth/resend-verification` - 모바일 재전송 인증과 동일

### 레거시 기사 (`/api/v1/articles`)
- ArticleController (레거시 구현)의 모든 엔드포인트

### 레거시 카테고리 (`/api/v1/categories`)
- 모바일 카테고리와 동일한 엔드포인트

### 레거시 추천 (`/api/v1/recommendations`)
- 모바일 추천과 동일한 엔드포인트

### 레거시 온보딩 (`/api/v1/onboarding`)
- 모바일 온보딩과 동일한 엔드포인트

**마이그레이션 타임라인:**
- **현재:** 레거시 엔드포인트 기능함
- **2025년 2분기:** 사용 중단 경고 추가
- **2025년 4분기:** 레거시 엔드포인트 제거

---

## 응답 형식

### 성공 응답
```json
{
  "success": true,
  "message": "작업 성공",
  "data": {
    // 응답 페이로드
  },
  "meta": {
    "timestamp": "2025-01-20T10:00:00Z",
    "requestId": "uuid-v4",
    "version": "1.0.0"
  }
}
```

### 오류 응답
```json
{
  "success": false,
  "message": "오류 설명",
  "error": {
    "code": "ERROR_CODE",
    "message": "상세한 오류 메시지",
    "details": {}
  },
  "meta": {
    "timestamp": "2025-01-20T10:00:00Z",
    "requestId": "uuid-v4"
  }
}
```

### 일반적인 오류 코드

#### 인증 오류
- `TOKEN_EXPIRED`: 액세스 토큰이 만료됨
- `TOKEN_INVALID`: 잘못된 형식이거나 유효하지 않은 토큰
- `REFRESH_TOKEN_EXPIRED`: 리프레시 토큰 만료
- `DEVICE_MISMATCH`: 장치 ID가 일치하지 않음
- `INSUFFICIENT_PERMISSIONS`: 사용자에게 필요한 권한이 없음
- `ACCOUNT_LOCKED`: 계정이 일시적으로 잠김
- `TOO_MANY_ATTEMPTS`: 속도 제한 초과

#### 검증 오류
- `VALIDATION_ERROR`: 요청 검증 실패
- `INVALID_INPUT`: 잘못된 입력 데이터
- `REQUIRED_FIELD_MISSING`: 필수 필드 누락
- `INVALID_EMAIL_FORMAT`: 잘못된 이메일 형식
- `PASSWORD_TOO_WEAK`: 비밀번호가 요구사항을 충족하지 않음

#### 비즈니스 로직 오류
- `RESOURCE_NOT_FOUND`: 요청된 리소스를 찾을 수 없음
- `DUPLICATE_RESOURCE`: 리소스가 이미 존재함
- `OPERATION_NOT_ALLOWED`: 작업이 허용되지 않음
- `QUOTA_EXCEEDED`: 사용자 할당량 초과

#### 시스템 오류
- `INTERNAL_SERVER_ERROR`: 예상치 못한 서버 오류
- `SERVICE_UNAVAILABLE`: 서비스가 일시적으로 사용 불가
- `DATABASE_ERROR`: 데이터베이스 작업 실패

---

## 보안 기능

### JWT 토큰 관리
- **단기 액세스 토큰**: 15분 만료로 노출 감소
- **토큰 회전**: 리프레시 토큰은 일회성 사용
- **장치 추적**: 장치 식별을 통한 다중 장치 지원
- **자동 정리**: 만료된 토큰 자동 제거

### 요청 보안
- **속도 제한**: 무차별 대입 공격 방지
- **CORS 정책**: 클라이언트별 허용된 출처
- **보안 헤더**: Helmet.js 구현
- **입력 검증**: 포괄적인 검증 및 정리
- **SQL 인젝션 방지**: 매개변수화된 쿼리만 사용

### 모니터링 및 감사
- **실시간 위협 감지**: 의심스러운 활동에 대한 위험 평가
- **포괄적인 로깅**: 보안 이벤트에 대한 전체 감사 추적
- **IP 주소 추적**: 의심스러운 IP 모니터링 및 차단
- **세션 관리**: 사용자 세션 추적 및 관리

---

## 클라이언트별 기능

### 모바일 앱
- 기사 및 추천에 대한 읽기 전용 액세스
- 읽기 패턴 기반 개인화된 콘텐츠
- 북마크 및 읽기 기록 관리
- 업데이트용 푸시 알림 지원

### 작가 앱
- 자신의 기사에 대한 전체 CRUD 작업
- 자동 저장 기능을 포함한 초안 관리
- WebSocket 업데이트를 통한 실시간 분석 대시보드
- 수익 추적 및 지급 정보
- 승인 프로세스를 포함한 게시 워크플로우

### 관리자 패널
- 포괄적인 사용자 및 역할 관리
- 콘텐츠 조정 및 승인 워크플로우
- 이벤트 스트리밍을 통한 실시간 보안 모니터링
- 시스템 구성 및 설정 관리
- 플랫폼 전체 분석 및 보고

---

## 버전 관리 및 사용 중단

### API 버전 관리
- 현재 버전: `v1`
- URL 경로에 버전 지정: `/api/v1/`
- 마이너 버전에 대한 하위 호환성 유지

### 사용 중단 정책
- 클라이언트 접두사가 없는 **레거시 엔드포인트** (예: `/api/auth`)는 사용 중단됨
- **마이그레이션 기간**: 제거 전 6개월
- **사용 중단 헤더**: 마이그레이션 지침과 함께 `X-API-Deprecated: true`
- **모든 클라이언트**는 클라이언트별 엔드포인트로 마이그레이션해야 함

### 마이그레이션 경로
```
기존: /api/v1/auth/login (레거시)
새로운: /api/v1/mobile/auth/login (모바일용)
새로운: /api/v1/writer/auth/login (작가용)
새로운: /api/v1/admin/auth/login (관리자용)
```

---

## 데이터베이스 스키마

### 개요
도메인별로 구성된 33개 테이블을 가진 PostgreSQL 데이터베이스:

- **사용자 도메인**: users, profiles, settings, sessions
- **콘텐츠 도메인**: articles, categories, tags, authors
- **상호작용 도메인**: likes, bookmarks, comments, follows
- **분석 도메인**: reading_sessions, metrics, logs
- **시스템 도메인**: configs, migrations, jobs

### 주요 관계
```
users ─┬─< articles (author)
       ├─< reading_sessions
       ├─< bookmarks
       └─< user_follows

articles ─┬─< article_tags >── tags
          ├─< article_likes
          └─< reading_sessions

categories ──< articles
```

### 데이터베이스 링크
- [전체 스키마](../../docs/database/schema.sql)
- [ERD 다이어그램](../../docs/database/erd.png)
- [마이그레이션 가이드](../../docs/database/migrations.md)

---

## 테스트

### 테스트 구조
```
tests/
├── unit/           # 비즈니스 로직 테스트
├── integration/    # API 통합 테스트
└── e2e/           # 엔드투엔드 테스트
```

### 테스트 실행
```bash
# 모든 테스트
npm test

# 단위 테스트만
npm test -- unit

# 통합 테스트
npm test -- integration

# 커버리지와 함께
npm test -- --coverage
```

### 테스트 가이드라인
1. 테스트 우선 작성 (TDD 접근법)
2. 외부 의존성 모킹
3. 경계 사례 및 오류 테스트
4. 80% 이상 커버리지 유지
5. 설명적인 테스트 이름 사용

---

## 배포

### 개발 파이프라인
```
로컬 → GitHub → CI/CD → 스테이징 → 프로덕션
```

### 빌드 프로세스
```bash
# TypeScript 빌드
npm run build

# 프로덕션 실행
npm start
```

### Docker 배포
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
CMD ["npm", "start"]
```

### 상태 확인
- `GET /health` - 기본 상태 확인
- `GET /health/ready` - 준비 상태 프로브
- `GET /health/live` - 생존 상태 프로브

---

## 문제 해결

### 일반적인 문제

#### 데이터베이스 연결 실패
```bash
# PostgreSQL 확인
docker ps | grep postgres

# 연결 테스트
npm run db:check

# 자격 증명 확인
echo $DATABASE_URL
```

#### 포트가 이미 사용 중
```bash
# 프로세스 찾기
lsof -i :3000

# 프로세스 종료
kill -9 <PID>

# 다른 포트 사용
PORT=3001 npm run dev
```

#### TypeScript 오류
```bash
# 빌드 정리
rm -rf dist
npm run build

# tsconfig 확인
npx tsc --noEmit
```

### 디버그 모드
```bash
# 모든 디버그 로그 활성화
DEBUG=* npm run dev

# 특정 네임스페이스
DEBUG=paperly:* npm run dev
```

### 로그 위치
- 개발: 콘솔 출력
- 프로덕션: `logs/` 디렉토리
- 오류 로그: `logs/error.log`
- 통합 로그: `logs/combined.log`

---

## 모범 사례

### 코드 품질
1. TypeScript strict 모드 준수
2. 의존성 주입 사용
3. 순수 함수 작성
4. 명시적 오류 처리
5. 중요한 작업 로깅

### 보안
1. 모든 입력 검증
2. 매개변수화된 쿼리 사용
3. 속도 제한 구현
4. 의존성 정기 감사
5. 민감한 데이터 로깅 금지

### 성능
1. 데이터베이스 쿼리 최적화
2. 적절한 인덱싱 사용
3. 캐싱 전략 구현
4. 연결 풀링 사용
5. 정기적인 성능 모니터링

---

*최종 업데이트: 2025년 1월*  
*버전: 1.0.0*  
*관리자: 백엔드 팀*