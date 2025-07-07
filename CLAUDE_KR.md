# Paperly 개발자 문서

이 종합 가이드는 Paperly 플랫폼을 이해하고, 개발하고, 기여하는 데 필요한 모든 것을 제공합니다. Claude Code나 다른 IDE로 작업하는 개발자들을 위한 주요 참조 문서입니다.

## 목차

1. [프로젝트 개요](#프로젝트-개요)
2. [시스템 아키텍처](#시스템-아키텍처)
3. [기술 스택](#기술-스택)
4. [프로젝트 구조](#프로젝트-구조)
5. [개발 환경](#개발-환경)
6. [API 문서](#api-문서)
7. [데이터베이스 스키마](#데이터베이스-스키마)
8. [개발 가이드라인](#개발-가이드라인)
9. [보안 및 인증](#보안-및-인증)
10. [테스트 전략](#테스트-전략)
11. [배포 및 운영](#배포-및-운영)
12. [문제 해결](#문제-해결)

---

## 프로젝트 개요

### 비전
Paperly는 디지털 시대에 사람들이 지식을 소비하고 보유하는 방식을 변화시키는 AI 기반 개인화 학습 플랫폼입니다. AI 큐레이션과 미니멀리스트 디자인 원칙을 결합하여 깊은 사고와 지식 보존을 촉진하는 지속 가능한 학습 생태계를 만듭니다.

### 핵심 문제
플랫폼은 세 가지 주요 과제를 해결합니다:
1. **주의력 경제 위기**: 2000년 이후 평균 주의 지속 시간이 74% 감소
2. **지식 휘발성**: 디지털 콘텐츠 보유율이 3일 후 단 5%
3. **환경적 영향**: 디지털 탄소 발자국을 98.8% 감소

### 솔루션
Paperly는 다음을 통해 개인화된 일일 학습 콘텐츠를 제공합니다:
- 개인의 관심사에 맞춘 AI 큐레이션 기사
- 미니멀리스트, 집중력을 방해하지 않는 읽기 경험
- 더 나은 보유를 위한 오프라인 우선 아키텍처
- 다중 클라이언트 생태계 (모바일, 작가, 관리자)

### 주요 지표
- **목표**: 40일 스프린트 내 앱스토어 출시
- **사용자**: B2C 독자, 콘텐츠 창작자, 플랫폼 관리자
- **규모**: 10만명 이상의 동시 사용자를 위한 설계

---

## 시스템 아키텍처

### 상위 수준 아키텍처

```
┌─────────────────────────────────────────────────────────────────────┐
│                          클라이언트 애플리케이션                         │
├─────────────────┬─────────────────┬─────────────────────────────────┤
│   모바일 앱      │   작가 앱        │         관리자 패널              │
│   (Flutter)     │   (Next.js)     │         (Next.js)               │
└────────┬────────┴────────┬────────┴────────┬────────────────────────┘
         │                 │                 │
         └─────────────────┴─────────────────┘
                           │
                    ┌──────▼──────┐
                    │ API 게이트웨이 │
                    │  (Express.js)│
                    └──────┬──────┘
                           │
     ┌─────────────────────┼─────────────────────┐
     │                     │                     │
┌────▼─────┐      ┌────────▼────────┐   ┌───────▼────────┐
│  백엔드   │      │  AI 서비스       │   │   알림          │
│   API    │◄─────┤  (Python/       │   │   서비스        │
│(Node.js) │      │   OpenAI)       │   │   (Node.js)    │
└────┬─────┘      └─────────────────┘   └────────────────┘
     │
     ├──────────────┬──────────────┬────────────────┐
     │              │              │                │
┌────▼─────┐  ┌────▼────┐  ┌──────▼─────┐  ┌──────▼──────┐
│PostgreSQL│  │  Redis  │  │   이메일    │  │   저장소     │
│    15    │  │  캐시    │  │  서비스     │  │   (S3)      │
└──────────┘  └─────────┘  └────────────┘  └─────────────┘
```

### 아키텍처 원칙
- **클린 아키텍처**: 명확한 경계로 관심사 분리
- **도메인 주도 설계 (DDD)**: 핵심에 비즈니스 로직 배치
- **마이크로서비스 준비**: 향후 확장을 위한 모듈식 설계
- **이벤트 기반**: 적절한 곳에서 비동기 통신
- **API 우선**: 잘 정의된 API를 통해 모든 기능 노출

---

## 기술 스택

### 백엔드 서비스
| 구성 요소 | 기술 | 목적 |
|-----------|------------|---------|
| 런타임 | Node.js 20.x | 서버 런타임 |
| 언어 | TypeScript 5.x | 타입 안전성 |
| 프레임워크 | Express.js | HTTP 서버 |
| 데이터베이스 | PostgreSQL 15 | 주 데이터 저장소 |
| 캐시 | Redis 7.x | 세션 및 캐시 |
| ORM | TypeORM | 데이터베이스 추상화 |
| 검증 | Zod | 스키마 검증 |
| DI | TSyringe | 의존성 주입 |
| 테스팅 | Jest + Supertest | 단위 및 통합 테스트 |
| 로깅 | Winston | 구조화된 로깅 |
| 인증 | JWT + bcrypt | 보안 |

### 모바일 애플리케이션
| 구성 요소 | 기술 | 목적 |
|-----------|------------|---------|
| 프레임워크 | Flutter 3.32+ | 크로스 플랫폼 UI |
| 언어 | Dart | 모바일 개발 |
| 상태 관리 | Riverpod | 상태 관리 |
| HTTP | Dio | 네트워크 요청 |
| 저장소 | SharedPreferences | 로컬 저장소 |
| 인증 | flutter_secure_storage | 안전한 토큰 저장소 |

### 인프라
| 구성 요소 | 기술 | 목적 |
|-----------|------------|---------|
| 컨테이너 | Docker | 개발 환경 |
| 오케스트레이션 | Docker Compose | 서비스 관리 |
| 모니터링 | Winston + Sentry | 오류 추적 |
| CI/CD | GitHub Actions | 자동화 |

---

## 프로젝트 구조

### 저장소 구성
```
paperly/
├── apps/                      # 애플리케이션 작업 공간
│   ├── backend/              # Node.js API 서버
│   │   ├── src/
│   │   │   ├── domain/       # 비즈니스 로직 및 엔티티
│   │   │   │   ├── entities/        # 핵심 비즈니스 객체
│   │   │   │   ├── value-objects/   # 도메인 기본 요소
│   │   │   │   ├── repositories/    # 데이터 접근 인터페이스
│   │   │   │   └── services/        # 도메인 서비스
│   │   │   ├── application/  # 유스케이스 및 DTO
│   │   │   │   ├── auth/           # 인증 유스케이스
│   │   │   │   ├── content/        # 콘텐츠 관리
│   │   │   │   ├── user/           # 사용자 관리
│   │   │   │   └── recommendation/ # AI 추천
│   │   │   ├── infrastructure/ # 외부 의존성
│   │   │   │   ├── database/      # TypeORM 구현
│   │   │   │   ├── cache/         # Redis 구현
│   │   │   │   ├── email/         # 이메일 제공자
│   │   │   │   ├── ai/            # AI 서비스 통합
│   │   │   │   └── security/      # 보안 구현
│   │   │   ├── presentation/  # API 레이어
│   │   │   │   ├── controllers/   # 요청 핸들러
│   │   │   │   ├── routes/        # 라우트 정의
│   │   │   │   ├── middleware/    # Express 미들웨어
│   │   │   │   └── validators/    # 요청 검증
│   │   │   └── shared/        # 공통 관심사
│   │   │       ├── errors/        # 오류 정의
│   │   │       ├── utils/         # 유틸리티 함수
│   │   │       └── types/         # 공유 타입
│   │   ├── tests/            # 테스트 스위트
│   │   ├── scripts/          # 유틸리티 스크립트
│   │   └── config/           # 설정 파일
│   ├── mobile/               # Flutter 모바일 앱
│   │   ├── lib/
│   │   │   ├── core/             # 핵심 기능
│   │   │   ├── data/             # 데이터 레이어
│   │   │   ├── domain/           # 비즈니스 로직
│   │   │   ├── presentation/     # UI 레이어
│   │   │   └── main.dart         # 진입점
│   │   ├── assets/           # 이미지, 폰트 등
│   │   ├── test/             # Flutter 테스트
│   │   └── pubspec.yaml      # 의존성
│   ├── writer/               # 작가 대시보드 (Next.js)
│   └── admin/                # 관리자 패널 (Next.js)
├── packages/                 # 공유 패키지
│   └── shared-types/        # TypeScript 타입
├── infrastructure/          # Docker 및 배포
│   ├── docker/             # Dockerfile
│   └── docker-compose.yml  # 서비스 오케스트레이션
├── docs/                    # 추가 문서
│   ├── api/                # API 명세
│   ├── database/           # DB 스키마 및 마이그레이션
│   └── architecture/       # 아키텍처 결정
├── scripts/                # 전역 스크립트
└── logs/                   # 개발 로그
    └── work-history/       # 월별 진행 로그
```

### 주요 디자인 패턴
1. **리포지토리 패턴**: 인터페이스 뒤에 데이터 접근 추상화
2. **유스케이스 패턴**: 비즈니스 작업 캡슐화
3. **값 객체**: 타입 안전 도메인 기본 요소
4. **의존성 주입**: TSyringe를 통한 느슨한 결합
5. **DTO 패턴**: 도메인에서 API 계약 분리

---

## 개발 환경

### 필수 조건
- Node.js 20.x 이상
- npm 10.x 이상
- Docker & Docker Compose
- Flutter SDK 3.32+
- Git

### 빠른 시작

#### 1. 저장소 복제
```bash
git clone https://github.com/your-org/paperly.git
cd paperly
```

#### 2. 의존성 설치
```bash
npm install  # 모든 작업 공간 의존성 설치
```

#### 3. 환경 설정
```bash
# 환경 템플릿 복사
cp apps/backend/.env.example apps/backend/.env

# 보안 시크릿 생성
openssl rand -hex 32  # JWT_ACCESS_SECRET용
openssl rand -hex 32  # JWT_REFRESH_SECRET용
```

#### 4. 개발 환경 시작
```bash
# 모든 것 시작 (Docker + 백엔드)
npm run dev

# 또는 서비스를 개별적으로 실행
npm run dev:docker      # PostgreSQL + Redis
npm run dev:backend     # 백엔드 API만
npm run dev:mobile      # Flutter 앱
```

#### 5. 설정 확인
```bash
# 데이터베이스 연결 확인
npm run db:check

# 테스트 실행
npm run test

# API 상태 확인
curl http://localhost:3000/api/v1/health
```

### 개발 명령어

| 명령어 | 설명 |
|---------|-------------|
| `npm run dev` | 전체 개발 환경 시작 |
| `npm run dev:backend` | 백엔드 서버만 시작 |
| `npm run dev:mobile` | Flutter 모바일 앱 실행 |
| `npm run dev:wsl` | WSL 환경을 위한 특별 모드 |
| `npm run build` | 모든 애플리케이션 빌드 |
| `npm run test` | 모든 테스트 스위트 실행 |
| `npm run lint` | 모든 코드 린트 |
| `npm run docker:stop` | Docker 컨테이너 중지 |
| `npm run docker:reset` | 컨테이너 및 볼륨 재설정 |
| `npm run db:seed` | 개발 데이터 시드 |

### 경로 별칭 (TypeScript)
```typescript
// 백엔드에서 사용 가능한 경로 별칭
import { User } from '@domain/entities/user.entity';
import { LoginUseCase } from '@application/auth/login.usecase';
import { DatabaseConfig } from '@infrastructure/database/config';
import { AppError } from '@shared/errors/app-error';

// 별칭 매핑
@/*               → src/*
@domain/*         → src/domain/*
@application/*    → src/application/*
@infrastructure/* → src/infrastructure/*
@shared/*         → src/shared/*
```

---

## API 문서

### 기본 URL 구조
```
https://api.paperly.com/api/{version}/{client}/{resource}
```

- **Version**: API 버전 (예: `v1`)
- **Client**: 대상 클라이언트 (`mobile`, `writer`, `admin`)
- **Resource**: API 리소스 경로

## 전체 API 명세

**📖 전체 API 명세는 [apps/backend/CLAUDE.md](./apps/backend/CLAUDE.md)에서 확인할 수 있습니다**

백엔드 문서에는 세 가지 클라이언트 애플리케이션 모두에 대한 포괄적인 API 명세가 포함되어 있습니다:

### 클라이언트별 API 범위

#### 모바일 앱 API (`/api/v1/mobile/`)
- **인증**: 등록, 로그인, 토큰 갱신, 이메일 인증
- **기사**: 피드 탐색, 검색, 기사 상세, 읽기 추적
- **사용자 프로필**: 프로필 관리, 읽기 기록, 북마크
- **추천**: 개인화, 트렌딩, 최신 콘텐츠
- **카테고리**: 콘텐츠 구성 및 필터링
- **온보딩**: 주제 선택 및 선호도 설정

#### 작가 앱 API (`/api/v1/writer/`)
- **인증**: 향상된 프로필 데이터를 포함한 작가 전용 로그인
- **프로필 관리**: 약력, 아바타, 소셜 링크, 통계
- **기사 관리**: 전체 CRUD 작업, 게시 워크플로우
- **초안 시스템**: 자동 저장, 버전 관리, 초안에서 기사로 변환
- **분석**: 성과 지표, 참여 데이터, 수익 추적
- **대시보드**: 요약 보기, 활동 피드, 알림

#### 관리자 패널 API (`/api/v1/admin/`)
- **인증**: 향상된 보안을 갖춘 관리자 로그인
- **사용자 관리**: 사용자 관리, 역할 할당, 계정 관리
- **작가 관리**: 신청 승인, 작가 분석
- **콘텐츠 관리**: 기사 승인, 콘텐츠 관리
- **보안 모니터링**: 이벤트 추적, IP 관리, 위협 감지
- **시스템 관리**: 설정, 상태 확인, 시스템 로그

### 빠른 참조

#### 기본 URL 구조
```
https://api.paperly.com/api/v1/{client}/{resource}
```

#### 인증
```http
Authorization: Bearer {access_token}
X-Client-Type: mobile|writer|admin
X-Device-ID: {device_uuid}
```

#### 표준 응답 형식
```json
{
  "success": true,
  "data": { /* 응답 페이로드 */ },
  "meta": { "timestamp": "ISO-date", "requestId": "uuid" }
}
```

### 보안 및 속도 제한
- **JWT 토큰**: 15분 액세스 토큰, 7일 리프레시 토큰
- **속도 제한**: 15분당 인증 요청 5회, API 요청 100회
- **장치 추적**: 다중 장치 세션 관리
- **보안 모니터링**: 실시간 위협 감지 및 IP 차단

자세한 엔드포인트 명세, 요청/응답 예제, 오류 코드 및 구현 참고 사항은 [전체 API 문서](./apps/backend/CLAUDE.md)를 참조하세요.

---

## 데이터베이스 스키마

### 개요
데이터베이스는 논리적 도메인으로 구성된 33개의 테이블로 구성됩니다:

```
┌─────────────────────────────────────────────────────────┐
│                    데이터베이스 스키마                      │
├──────────────┬────────────────┬────────────────────────┤
│ 사용자 도메인  │ 콘텐츠 도메인   │ 분석 도메인             │
├──────────────┼────────────────┼────────────────────────┤
│ • users      │ • articles     │ • reading_sessions     │
│ • profiles   │ • categories   │ • user_activity_logs   │
│ • settings   │ • tags         │ • daily_stats          │
│ • interests  │ • authors      │ • recommendation_logs  │
├──────────────┼────────────────┼────────────────────────┤
│ 인증 도메인   │ 구독            │ 시스템 도메인           │
├──────────────┼────────────────┼────────────────────────┤
│ • tokens     │ • plans        │ • system_configs       │
│ • sessions   │ • subscriptions│ • common_codes         │
│ • devices    │ • payments     │ • error_logs           │
└──────────────┴────────────────┴────────────────────────┘
```

### 주요 엔티티

#### 사용자
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 기사
```sql
CREATE TABLE articles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    summary TEXT,
    author_id UUID REFERENCES authors(id),
    category_id UUID REFERENCES categories(id),
    reading_time INT NOT NULL,
    published_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 읽기 세션
```sql
CREATE TABLE reading_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    article_id UUID REFERENCES articles(id),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    duration INT,
    scroll_depth DECIMAL(3,2),
    completed BOOLEAN DEFAULT false
);
```

### 데이터베이스 문서 링크
- [전체 스키마](./docs/database/schema.sql)
- [엔티티 관계 다이어그램](./docs/database/erd.png)
- [마이그레이션 가이드](./docs/database/migrations.md)

---

## 개발 가이드라인

### 코드 스타일

#### TypeScript/JavaScript
- 제공된 ESLint 설정 사용
- 함수형 프로그래밍 패턴 선호
- 콜백 대신 async/await 사용
- 적절한 오류 처리 구현

```typescript
// ✅ 좋은 예
export class CreateUserUseCase {
  async execute(dto: CreateUserDto): Promise<Result<User>> {
    try {
      const email = Email.create(dto.email);
      if (email.isFailure) {
        return Result.fail(email.error);
      }
      // ... 구현
    } catch (error) {
      return Result.fail(new AppError.UnexpectedError(error));
    }
  }
}

// ❌ 나쁜 예
export class CreateUserUseCase {
  execute(dto) {
    // 타입 없음, 오류 처리 없음
    const user = new User(dto);
    return user.save();
  }
}
```

#### Flutter/Dart
- Flutter 스타일 가이드 준수
- 상태 관리를 위해 Riverpod 사용
- 적절한 오류 경계 구현

```dart
// ✅ 좋은 예
class ArticleRepository {
  final Dio _dio;
  
  ArticleRepository(this._dio);
  
  Future<Either<Failure, Article>> getArticle(String id) async {
    try {
      final response = await _dio.get('/articles/$id');
      return Right(Article.fromJson(response.data));
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Unknown error'));
    }
  }
}
```

### Git 워크플로우

#### 브랜치 명명
- `feature/description` - 새 기능
- `fix/description` - 버그 수정
- `refactor/description` - 코드 리팩토링
- `docs/description` - 문서 업데이트

#### 커밋 메시지
기존 커밋 규칙을 따르세요:
```
feat: 사용자 인증 추가
fix: 토큰 갱신 문제 해결
docs: API 문서 업데이트
refactor: 검증 로직 단순화
test: 인증 서비스 테스트 추가
```

### 테스트 요구사항

#### 백엔드 테스팅
```typescript
// 비즈니스 로직을 위한 단위 테스트
describe('CreateUserUseCase', () => {
  it('유효한 데이터로 사용자를 생성해야 함', async () => {
    // 준비
    const dto = { email: 'test@example.com', password: 'Test123!' };
    
    // 실행
    const result = await useCase.execute(dto);
    
    // 검증
    expect(result.isSuccess).toBe(true);
    expect(result.getValue().email.value).toBe(dto.email);
  });
});

// API를 위한 통합 테스트
describe('POST /auth/register', () => {
  it('새 사용자를 등록해야 함', async () => {
    const response = await request(app)
      .post('/api/v1/mobile/auth/register')
      .send({ email: 'test@example.com', password: 'Test123!' });
      
    expect(response.status).toBe(201);
    expect(response.body.success).toBe(true);
  });
});
```

#### 모바일 테스팅
```dart
// 위젯 테스트
testWidgets('로그인 버튼이 로딩 상태를 표시해야 함', (tester) async {
  await tester.pumpWidget(LoginScreen());
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();
  
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

---

## 보안 및 인증

### JWT 설정
- **액세스 토큰**: 15분 만료
- **리프레시 토큰**: 회전을 통한 7일
- **알고리즘**: 프로덕션용 RS256, 개발용 HS256

### 보안 헤더
```typescript
// Helmet.js 설정
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true,
  },
}));
```

### 보안 모범 사례
1. **입력 검증**: Zod로 모든 입력 검증
2. **SQL 인젝션**: 매개변수화된 쿼리 사용
3. **XSS 방지**: 모든 사용자 콘텐츠 삭제
4. **속도 제한**: 엔드포인트별 제한 구현
5. **CORS**: 엄격한 출처 검증
6. **시크릿**: 환경 변수 사용
7. **로깅**: 민감한 데이터는 절대 로그하지 않음

### 장치 추적
```typescript
interface DeviceInfo {
  deviceId: string;
  platform: 'ios' | 'android' | 'web';
  appVersion: string;
  osVersion: string;
  lastSeen: Date;
}
```

---

## 테스트 전략

### 테스트 피라미드
```
         ┌─────┐
        /  E2E  \       5%
       /─────────\
      / 통합 테스트 \    25%
     /──────────────\
    /   단위 테스트    \  70%
   └──────────────────┘
```

### 커버리지 요구사항
- 단위 테스트: 최소 80%
- 통합 테스트: 중요 경로
- E2E 테스트: 사용자 여정

### 테스트 실행
```bash
# 모든 테스트 실행
npm run test

# 커버리지와 함께 실행
npm run test:coverage

# 특정 스위트 실행
npm run test:unit
npm run test:integration
npm run test:e2e

# 모바일 테스트
cd apps/mobile && flutter test
```

---

## 배포 및 운영

### 환경 전략
```
┌──────────┐    ┌──────────┐    ┌────────────┐
│   로컬    │───▶│ 스테이징  │───▶│   프로덕션   │
└──────────┘    └──────────┘    └────────────┘
```

### 인프라 요구사항

#### 프로덕션
- **API 서버**: 최소 2 vCPU, 4GB RAM
- **데이터베이스**: PostgreSQL 15, 100GB SSD
- **Redis**: 2GB RAM
- **CDN**: 정적 자산용 CloudFlare

#### 모니터링
- **APM**: 오류 추적을 위한 Sentry
- **로그**: 일별 회전을 포함한 Winston
- **메트릭**: 사용자 정의 대시보드
- **경고**: PagerDuty 통합

### 배포 체크리스트
- [ ] 모든 테스트 통과
- [ ] 환경 변수 구성됨
- [ ] 데이터베이스 마이그레이션 적용됨
- [ ] Redis 캐시 지워짐
- [ ] 상태 확인 검증됨
- [ ] 롤백 계획 준비됨

---

## 문제 해결

### 일반적인 문제

#### 데이터베이스 연결 실패
```bash
# PostgreSQL 상태 확인
docker ps | grep postgres

# 연결 테스트
npm run db:check

# 데이터베이스 재설정
npm run docker:reset
```

#### Flutter 빌드 오류
```bash
# Flutter 캐시 정리
flutter clean
flutter pub cache repair
flutter pub get

# iOS 전용
cd ios && pod install
```

#### API가 응답하지 않음
```bash
# 로그 확인
npm run docker:logs

# 서비스 재시작
npm run docker:stop
npm run dev
```

### 디버그 도구
- **pgAdmin**: http://localhost:5050
- **Redis CLI**: `docker exec -it paperly_redis redis-cli`
- **API 로그**: `npm run dev:backend -- --verbose`

---

## 기여

### 풀 리퀘스트 프로세스
1. `main`에서 기능 브랜치 생성
2. 새 기능에 대한 테스트 작성
3. 모든 테스트가 통과하는지 확인
4. 문서 업데이트
5. 명확한 설명과 함께 PR 제출
6. 코드 리뷰 대기

### 코드 리뷰 체크리스트
- [ ] 테스트 포함 및 통과
- [ ] 문서 업데이트됨
- [ ] 보안 취약점 없음
- [ ] 성능 영향 고려됨
- [ ] 코딩 표준 준수

---

## 리소스

### 내부 문서
- [API 명세](./docs/api/)
- [데이터베이스 스키마](./docs/database/)
- [아키텍처 결정](./docs/architecture/)
- [작업 기록 로그](./logs/work-history/)

### 외부 리소스
- [Flutter 문서](https://flutter.dev/docs)
- [Node.js 모범 사례](https://github.com/goldbergyoni/nodebestpractices)
- [클린 아키텍처](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [도메인 주도 설계](https://martinfowler.com/tags/domain%20driven%20design.html)

---

## 지원

### 도움 받기
- **문서**: 이 파일 및 `/docs` 디렉토리
- **이슈**: 버그 보고를 위한 GitHub Issues
- **토론**: 질문을 위한 GitHub Discussions

### 연락처
- **기술 리드**: tech@paperly.com
- **프로젝트 매니저**: pm@paperly.com

---

*최종 업데이트: 2025년 1월*  
*버전: 2.0.0*  
*상태: 활발한 개발 중*