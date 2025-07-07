# Paperly 모바일 앱 개발자 가이드

이 종합 가이드는 Paperly 모바일 애플리케이션을 이해하고, 개발하고, 기여하는 데 필요한 모든 것을 제공합니다. Flutter 기반 모바일 클라이언트를 작업하는 개발자들을 위한 주요 참조 문서입니다.

## 목차

1. [앱 개요](#앱-개요)
2. [Paperly 생태계에서의 역할](#paperly-생태계에서의-역할)
3. [주요 기능](#주요-기능)
4. [아키텍처 및 기술 스택](#아키텍처-및-기술-스택)
5. [프로젝트 구조](#프로젝트-구조)
6. [개발 환경 설정](#개발-환경-설정)
7. [API 통합](#api-통합)
8. [상태 관리](#상태-관리)
9. [UI/UX 가이드라인](#uiux-가이드라인)
10. [테스트 전략](#테스트-전략)
11. [빌드 및 배포](#빌드-및-배포)
12. [문제 해결](#문제-해결)

---

## 앱 개요

### 목적
Paperly 모바일 앱은 Paperly 생태계에서 독자들을 위한 주요 콘텐츠 소비 인터페이스입니다. 지식 보유에 최적화된 미니멀리스트, 집중력을 방해하지 않는 읽기 경험을 통해 AI가 큐레이션한 개인화된 일일 학습 콘텐츠를 제공합니다.

### 대상 사용자
- **주요**: 큐레이션된 콘텐츠를 찾는 지식 노동자, 학생, 평생 학습자
- **보조**: 자신의 분야에서 최신 정보를 유지하려는 전문가
- **인구 통계**: 25-45세, 교육 중심, 지속 가능성을 의식하는 사용자

### 핵심 가치 제안
1. **개인화된 학습**: 개인의 관심사와 읽기 패턴을 기반으로 한 AI 큐레이션 콘텐츠
2. **집중력을 방해하지 않는 읽기**: MUJI 미학에서 영감을 받은 미니멀리스트 디자인
3. **지식 보유**: 오프라인 우선 아키텍처와 사려 깊은 읽기 경험
4. **환경적 영향**: 효율적인 디자인을 통한 디지털 탄소 발자국 감소

---

## Paperly 생태계에서의 역할

모바일 앱은 Paperly 플랫폼의 세 가지 클라이언트 애플리케이션 중 하나입니다:

```
┌─────────────────────────────────────────────────────┐
│                 Paperly 생태계                       │
├──────────────┬────────────────┬────────────────────┤
│  모바일 앱    │  작가 앱        │   관리자 패널       │
│  (독자)      │  (창작자)       │   (관리자)         │
├──────────────┼────────────────┼────────────────────┤
│ • 콘텐츠     │ • 콘텐츠       │ • 플랫폼           │
│   소비       │   생성         │   관리             │
│ • 읽기       │ • 분석         │ • 사용자           │
│   경험       │ • 게시         │   중재             │
│ • 개인       │ • 수익         │ • 콘텐츠           │
│   라이브러리  │   추적         │   큐레이션         │
└──────────────┴────────────────┴────────────────────┘
                         │
                    백엔드 API
```

### 모바일 앱 책임
1. **콘텐츠 전달**: 매력적인 형식으로 AI 큐레이션 기사 제공
2. **사용자 경험**: 오프라인 지원과 함께 원활한 읽기 경험 제공
3. **개인화**: 더 나은 추천을 위한 읽기 패턴과 선호도 추적
4. **참여**: 북마크, 좋아요, 작가 팔로우와 같은 상호작용 활성화
5. **인증**: 안전한 사용자 인증 및 세션 관리

---

## 주요 기능

### 1. 콘텐츠 발견 및 읽기
- **일일 추천**: 사용자 선호도에 따른 AI 큐레이션 기사
- **카테고리 탐색**: 주제별(기술, 비즈니스, 과학 등) 콘텐츠 탐색
- **검색 기능**: 기사와 저자 전체 텍스트 검색
- **읽기 경험**: 조정 가능한 설정이 있는 깨끗하고 타이포그래피에 중점을 둔 레이아웃
- **오프라인 지원**: 오프라인 읽기를 위한 기사 다운로드

### 2. 개인화 및 AI
- **관심사 추적**: 추천 개선을 위한 읽기 패턴 모니터링
- **적응형 학습**: 참여도에 따라 AI가 콘텐츠 난이도와 주제 조정
- **읽기 목표**: 일일/주간 읽기 목표 설정 및 추적
- **사용자 정의 컬렉션**: 개인 읽기 목록 및 컬렉션 생성

### 3. 소셜 및 참여
- **작가 팔로우**: 좋아하는 작가를 구독하여 업데이트 받기
- **기사 상호작용**: 기사 좋아요, 북마크, 공유
- **읽기 진행**: 읽기 시간 및 완료율 추적
- **업적**: 일관된 읽기 습관을 위한 게임화 요소

### 4. 사용자 관리
- **안전한 인증**: 생체 인증 지원을 포함한 JWT 기반 인증
- **프로필 관리**: 읽기 선호도 및 관심사 사용자 정의
- **다중 장치 동기화**: 장치 간 원활한 경험
- **프라이버시 제어**: 데이터 수집 및 공유 선호도 관리

### 5. 기술적 기능
- **푸시 알림**: 일일 읽기 알림 및 작가 업데이트
- **성능 모니터링**: 앱 성능 및 사용자 경험 추적
- **오류 처리**: 오프라인 폴백을 통한 우아한 오류 복구
- **분석 통합**: 프라이버시 중심의 사용 분석

---

## 아키텍처 및 기술 스택

### 기술 스택

| 레이어 | 기술 | 목적 |
|-------|------------|---------|
| **프레임워크** | Flutter 3.32+ | 크로스 플랫폼 UI 프레임워크 |
| **언어** | Dart 3.0+ | 주요 개발 언어 |
| **상태 관리** | Provider 6.0+ | 단순하고 효율적인 상태 관리 |
| **네비게이션** | Navigator 2.0 | 선언적 네비게이션 |
| **HTTP 클라이언트** | Dio 5.4+ | 인터셉터를 포함한 고급 HTTP 클라이언트 |
| **로컬 저장소** | Flutter Secure Storage | 민감한 데이터를 위한 암호화된 저장소 |
| **데이터베이스** | SharedPreferences | 간단한 키-값 저장소 |
| **인증** | JWT + Biometric | 안전한 다단계 인증 |
| **UI 컴포넌트** | Material Design 3 | 현대적이고 적응형 UI 컴포넌트 |
| **코드 생성** | Freezed + JsonSerializable | 불변 모델 및 JSON 파싱 |
| **로깅** | Logger 2.0+ | 레벨별 구조화된 로깅 |
| **테스팅** | Flutter Test + Mockito | 단위 및 위젯 테스팅 |

### 아키텍처 패턴

앱은 명확한 관심사 분리를 통한 클린 아키텍처 원칙을 따릅니다:

```
┌─────────────────────────────────────────────────────┐
│                  프레젠테이션 레이어                   │
│  (화면, 위젯, 프로바이더, UI 로직)                    │
├─────────────────────────────────────────────────────┤
│                   도메인 레이어                       │
│  (비즈니스 로직, 엔티티, 유스케이스)                  │
├─────────────────────────────────────────────────────┤
│                    데이터 레이어                      │
│  (서비스, 리포지토리, 모델, API)                      │
└─────────────────────────────────────────────────────┘
```

### 디자인 패턴

1. **리포지토리 패턴**: 인터페이스 뒤에 데이터 소스 추상화
2. **프로바이더 패턴**: 변경 알림을 통한 반응형 상태 관리
3. **서비스 로케이터**: 서비스를 위한 의존성 주입
4. **팩토리 패턴**: JSON에서 모델 생성
5. **싱글톤 패턴**: 서비스 및 관리자를 위한 단일 인스턴스

---

## 프로젝트 구조

```
apps/mobile/
├── lib/                          # 주요 소스 코드 디렉토리
│   ├── config/                   # 앱 구성
│   │   └── api_config.dart      # API 엔드포인트 및 환경 구성
│   ├── models/                   # 데이터 모델
│   │   ├── article_models.dart  # 기사 관련 모델
│   │   ├── auth_models.dart     # 인증 모델
│   │   └── author_models.dart   # 저자/작가 모델
│   ├── providers/                # 상태 관리
│   │   ├── auth_provider.dart   # 인증 상태
│   │   └── follow_provider.dart # 팔로우/구독 상태
│   ├── screens/                  # UI 화면
│   │   ├── auth/                # 인증 화면
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── email_verification_screen.dart
│   │   ├── article_detail_screen.dart    # 기사 읽기 보기
│   │   ├── article_list_screen.dart      # 기사 탐색
│   │   ├── author_detail_screen.dart     # 저자 프로필
│   │   ├── home_screen.dart              # 메인 홈 화면
│   │   ├── search_screen.dart            # 검색 기능
│   │   └── obsidian_view_screen.dart     # 특별 읽기 모드
│   ├── services/                 # 비즈니스 로직 및 API 호출
│   │   ├── article_service.dart         # 기사 API 작업
│   │   ├── auth_service.dart            # 인증 로직
│   │   ├── device_info_service.dart     # 장치 정보
│   │   ├── error_translation_service.dart # 오류 메시지 현지화
│   │   ├── follow_service.dart          # 팔로우/언팔로우 작업
│   │   └── secure_storage_service.dart  # 암호화된 저장소
│   ├── theme/                    # UI 테마
│   │   └── muji_theme.dart      # MUJI 영감 디자인 시스템
│   ├── utils/                    # 유틸리티 함수
│   │   ├── error_handler.dart   # 중앙화된 오류 처리
│   │   └── logger.dart          # 로깅 유틸리티
│   ├── widgets/                  # 재사용 가능한 UI 컴포넌트
│   │   ├── muji_button.dart     # 사용자 정의 버튼 위젯
│   │   └── muji_text_field.dart # 사용자 정의 텍스트 입력
│   └── main.dart                # 앱 진입점
├── assets/                       # 정적 자산
│   ├── images/                  # 이미지 자산
│   ├── fonts/                   # 사용자 정의 폰트
│   └── icons/                   # 앱 아이콘
├── test/                        # 테스트 파일
│   ├── unit/                    # 단위 테스트
│   ├── widget/                  # 위젯 테스트
│   └── integration/             # 통합 테스트
├── android/                     # 안드로이드 플랫폼 코드
├── ios/                         # iOS 플랫폼 코드
├── web/                         # 웹 플랫폼 코드
├── pubspec.yaml                 # 의존성 및 메타데이터
└── README.md                    # 기본 프로젝트 정보
```

### 주요 디렉토리 설명

- **`config/`**: 환경별 구성 (개발, 스테이징, 프로덕션)
- **`models/`**: JSON 직렬화를 포함한 불변 데이터 모델
- **`providers/`**: ChangeNotifier를 확장하는 상태 관리 클래스
- **`screens/`**: 앱 화면을 나타내는 전체 페이지 UI 컴포넌트
- **`services/`**: 비즈니스 로직, API 호출 및 외부 통합
- **`theme/`**: 색상, 타이포그래피, 간격을 포함한 디자인 시스템 구현
- **`utils/`**: 앱 전체에서 사용되는 도우미 함수 및 유틸리티
- **`widgets/`**: MUJI 디자인 원칙을 따르는 재사용 가능한 UI 컴포넌트

---

## 개발 환경 설정

### 필수 조건
- Flutter SDK 3.32 이상
- Dart SDK 3.0 이상
- Android Studio / Xcode (플랫폼 도구용)
- Flutter 플러그인이 있는 VS Code 또는 IntelliJ IDEA

### 시작하기

1. **모바일 디렉토리로 이동**
```bash
cd apps/mobile
```

2. **의존성 설치**
```bash
flutter pub get
```

3. **코드 생성**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **환경 구성**
```dart
// lib/config/api_config.dart를 백엔드 URL로 업데이트
static const String baseUrl = 'http://192.168.1.100:3000'; // 로컬 IP
```

5. **앱 실행**
```bash
# iOS 시뮬레이터
flutter run -d ios

# 안드로이드 에뮬레이터
flutter run -d android

# 모든 장치
flutter run -d all
```

### 개발 명령어

| 명령어 | 설명 |
|---------|-------------|
| `flutter pub get` | 의존성 설치 |
| `flutter run` | 디버그 모드로 앱 실행 |
| `flutter build apk` | 안드로이드 APK 빌드 |
| `flutter build ios` | iOS 앱 빌드 |
| `flutter test` | 모든 테스트 실행 |
| `flutter analyze` | 코드 품질 분석 |
| `flutter clean` | 빌드 아티팩트 정리 |

### 환경 구성

앱은 빌드 플레이버를 통해 여러 환경을 지원합니다:

```bash
# 개발
flutter run --flavor dev

# 스테이징
flutter run --flavor staging

# 프로덕션
flutter run --flavor prod
```

---

## API 통합

### 기본 구성
```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://192.168.1.100:3000';
  static const String apiPrefix = '/api/v1/mobile';
  
  // 엔드포인트
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String articles = '/articles';
  static const String recommendations = '/recommendations/daily';
}
```

### API 서비스 패턴
```dart
// 예제: 기사 서비스
class ArticleService {
  final Dio _dio;
  
  Future<List<Article>> getArticles({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.apiPrefix}/articles',
        queryParameters: {'page': page, 'limit': limit},
      );
      return (response.data['data'] as List)
          .map((json) => Article.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
}
```

### 인증 플로우
1. **로그인**: 이메일/비밀번호 → JWT 토큰 (액세스 + 리프레시)
2. **토큰 저장**: Flutter Secure Storage를 사용한 암호화된 저장
3. **토큰 갱신**: 액세스 토큰 만료 시 자동 갱신
4. **로그아웃**: 토큰 삭제 및 로그인으로 리디렉션

### 오류 처리
```dart
// 중앙화된 오류 처리
mixin ErrorHandlerMixin {
  void handleError(dynamic error) {
    if (error is DioException) {
      // 네트워크 오류
    } else if (error is FormatException) {
      // 파싱 오류
    } else {
      // 알 수 없는 오류
    }
  }
}
```

---

## 상태 관리

### 프로바이더 아키텍처

앱은 다음 구조로 Provider를 사용하여 상태를 관리합니다:

```dart
// 메인 앱 프로바이더
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => FollowProvider()),
    // 필요에 따라 더 많은 프로바이더 추가
  ],
  child: MyApp(),
)
```

### 프로바이더 가이드라인

1. **단일 책임**: 각 프로바이더는 하나의 도메인 관리
2. **불변 상태**: 상태 업데이트를 위한 copyWith 패턴 사용
3. **비동기 작업**: 로딩/오류 상태를 적절히 처리
4. **메모리 관리**: dispose()에서 리소스 해제

### 예제 프로바이더
```dart
class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _user = await _authService.login(email, password);
    } catch (e) {
      // 오류 처리
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

---

## UI/UX 가이드라인

### 디자인 원칙

앱은 MUJI에서 영감을 받은 미니멀리스트 디자인을 따릅니다:

1. **단순성**: 필수 요소만 있는 깨끗한 인터페이스
2. **타이포그래피**: 사려 깊은 폰트 선택으로 가독성에 중점
3. **여백**: 시각적 여유를 위한 충분한 간격
4. **자연스러운 색상**: 차분한 대지색 (세이지, 클레이, 모스, 차콜)
5. **미묘한 애니메이션**: 부드럽고 목적이 있는 전환

### 색상 팔레트
```dart
class MujiTheme {
  // 기본 색상
  static const Color ink = Color(0xFF1C1C1E);      // 거의 검정
  static const Color paper = Color(0xFFFAFAF8);    // 오프 화이트
  
  // 액센트 색상
  static const Color sage = Color(0xFF7C9885);     // 차분한 녹색
  static const Color clay = Color(0xFFB08968);     // 따뜻한 갈색
  static const Color moss = Color(0xFF5F7161);     // 진한 녹색
  static const Color sand = Color(0xFFE5D4B7);     // 연한 베이지
}
```

### 타이포그래피
```dart
// 제목 스타일
static const TextStyle h1 = TextStyle(
  fontFamily: 'NotoSans',
  fontSize: 28,
  fontWeight: FontWeight.w600,
  height: 1.2,
);

// 본문 텍스트
static const TextStyle body = TextStyle(
  fontFamily: 'NotoSans',
  fontSize: 16,
  fontWeight: FontWeight.w400,
  height: 1.6,
);
```

### 컴포넌트 가이드라인

1. **버튼**: 누를 때 미묘한 그림자가 있는 플랫 디자인
2. **카드**: 가벼운 그림자가 있는 부드러운 모서리 (8px 반경)
3. **리스트**: 충분한 패딩이 있는 깨끗한 구분선
4. **폼**: 포커스 상태가 있는 최소한의 테두리
5. **로딩**: 스피너 대신 스켈레톤 화면

---

## 테스트 전략

### 테스트 구조
```
test/
├── unit/               # 비즈니스 로직 테스트
│   ├── services/      # 서비스 레이어 테스트
│   ├── providers/     # 상태 관리 테스트
│   └── utils/         # 유틸리티 함수 테스트
├── widget/            # UI 컴포넌트 테스트
│   ├── screens/       # 화면 위젯 테스트
│   └── widgets/       # 재사용 가능한 위젯 테스트
└── integration/       # 엔드투엔드 테스트
```

### 테스트 실행
```bash
# 모든 테스트
flutter test

# 특정 테스트 파일
flutter test test/unit/services/auth_service_test.dart

# 커버리지와 함께
flutter test --coverage
```

### 테스트 가이드라인

1. **단위 테스트**: 서비스, 프로바이더 및 유틸리티 테스트
2. **위젯 테스트**: 격리된 UI 컴포넌트 테스트
3. **통합 테스트**: 완전한 사용자 플로우 테스트
4. **모의 데이터**: 일관된 테스트를 위한 가짜 리포지토리 사용
5. **커버리지 목표**: 80% 이상의 코드 커버리지 유지

---

## 빌드 및 배포

### 안드로이드 빌드
```bash
# 디버그 APK
flutter build apk --debug

# 릴리스 APK
flutter build apk --release

# Play Store를 위한 앱 번들
flutter build appbundle --release
```

### iOS 빌드
```bash
# 디버그 빌드
flutter build ios --debug

# 릴리스 빌드
flutter build ios --release

# App Store를 위한 아카이브
flutter build ipa --release
```

### CI/CD 파이프라인

앱은 자동화된 빌드를 위해 GitHub Actions를 사용합니다:

1. **PR 검사**: 풀 리퀘스트에서 테스트 및 린팅 실행
2. **베타 빌드**: develop 브랜치에서 TestFlight/Play Console로 배포
3. **프로덕션**: 버전 태그에서 릴리스 빌드

### 버전 관리
```yaml
# pubspec.yaml
version: 1.0.0+1  # version+buildNumber
```

---

## 문제 해결

### 일반적인 문제

#### 1. 빌드 실패
```bash
# 정리 및 재빌드
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 2. iOS Pod 문제
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter run
```

#### 3. 안드로이드 Gradle 문제
```bash
cd android
./gradlew clean
cd ..
flutter run
```

#### 4. 상태가 업데이트되지 않음
- `notifyListeners()` 호출 확인
- 프로바이더가 위젯 트리에서 위에 있는지 확인
- `Consumer` 또는 `context.watch()` 사용

#### 5. API 연결 문제
- 백엔드가 실행 중인지 확인
- 네트워크 권한 확인
- localhost 대신 장치 IP 사용

### 디버그 도구

1. **Flutter Inspector**: 위젯 트리 분석
2. **Network Inspector**: API 호출 모니터링
3. **Performance Overlay**: 프레임 속도 확인
4. **Debug Console**: 로그 및 오류 보기

### 도움 받기

- **문서**: `/docs` 폴더 확인
- **팀 채팅**: Slack #mobile-dev 채널
- **이슈 트래커**: GitHub Issues
- **코드 리뷰**: 피드백을 위한 PR 제출

---

## API 문서

**📖 전체 API 명세는 [../backend/CLAUDE.md](../backend/CLAUDE.md)에서 확인할 수 있습니다**

모바일 앱은 다음을 포함하는 모바일 API 엔드포인트(`/api/v1/mobile/`)를 사용합니다:

### 모바일 앱 API 사용

#### 인증 API
- JWT 토큰을 사용한 등록 및 로그인
- 장치 추적을 통한 자동 토큰 갱신
- 이메일 인증 및 비밀번호 재설정

#### 콘텐츠 API
- 페이지네이션 및 필터링이 있는 기사 피드
- 기사 및 저자 전체 검색 기능
- 카테고리 기반 콘텐츠 탐색
- 개인화된 일일 추천

#### 사용자 프로필 API
- 프로필 관리 및 선호도
- 읽기 기록 추적
- 북마크 관리
- 저자 팔로우/언팔로우

#### 상호작용 API
- 기사 좋아요 및 참여 추적
- 읽기 세션 분석
- 온보딩 및 선호도 설정

### 주요 엔드포인트 참조

| 엔드포인트 | 메서드 | 설명 |
|----------|--------|-------------|
| `/api/v1/mobile/auth/login` | POST | 사용자 로그인 |
| `/api/v1/mobile/auth/register` | POST | 사용자 등록 |
| `/api/v1/mobile/auth/refresh` | POST | JWT 토큰 갱신 |
| `/api/v1/mobile/articles` | GET | 기사 목록 |
| `/api/v1/mobile/articles/:id` | GET | 기사 상세 정보 |
| `/api/v1/mobile/articles/:id/toggle-like` | POST | 기사 좋아요/좋아요 취소 |
| `/api/v1/mobile/recommendations` | GET | 개인화된 추천 |
| `/api/v1/mobile/user/bookmarks` | GET | 사용자 북마크 |

### 인증 헤더
```http
Authorization: Bearer {access_token}
X-Client-Type: mobile
X-Device-ID: {device_uuid}
```

완전한 엔드포인트 명세, 요청/응답 예제 및 오류 처리 세부 정보는 [백엔드 API 문서](../backend/CLAUDE.md)를 참조하세요.

---

## 모범 사례

### 코드 품질
1. Dart 스타일 가이드 및 린팅 규칙 준수
2. 의미 있는 변수 및 함수 이름 사용
3. 공개 API에 문서 주석 추가
4. 함수를 작고 집중적으로 유지
5. 오류를 우아하게 처리

### 성능
1. 가능한 곳에서 `const` 생성자 사용
2. 리스트에 대한 지연 로딩 구현
3. 이미지 최적화 (WebP 형식 선호)
4. 위젯 재빌드 최소화
5. 최적화 전에 프로파일링

### 보안
1. SharedPreferences에 민감한 데이터를 저장하지 않음
2. 토큰을 위해 Flutter Secure Storage 사용
3. 프로덕션을 위한 인증서 고정 구현
4. 모든 사용자 입력 검증
5. OWASP 모바일 가이드라인 준수

### 접근성
1. 모든 상호작용 요소에 의미 있는 레이블 추가
2. 충분한 색상 대비 보장 (WCAG AA)
3. 스크린 리더 지원
4. 접근성 도구로 테스트
5. 이미지에 대한 대체 텍스트 제공

---

*최종 업데이트: 2025년 1월*  
*버전: 1.0.0*  
*관리자: 모바일 팀*