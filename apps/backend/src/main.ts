/// Paperly Backend Server - 메인 진입점
/// 
/// 이 파일은 Paperly 백엔드 서버의 핵심 진입점입니다.
/// Domain-Driven Design(DDD)와 Clean Architecture 패턴을 따르며,
/// TSyringe를 사용한 의존성 주입 컨테이너로 관리됩니다.
/// 
/// 주요 책임:
/// 1. 애플리케이션 부트스트래핑 및 초기화
/// 2. 의존성 주입 컨테이너 설정 및 검증
/// 3. 데이터베이스 연결 관리
/// 4. Express 웹 서버 설정 및 시작
/// 5. Graceful shutdown 처리
/// 6. 전역 예외 및 에러 처리
/// 
/// 아키텍처 패턴:
/// - Clean Architecture: 계층 분리와 의존성 역전
/// - Domain-Driven Design: 도메인 중심 설계
/// - Dependency Injection: TSyringe 컨테이너 사용
/// - Infrastructure as Code: 설정 기반 인프라 관리
/// 
/// 서버 시작 순서:
/// reflect-metadata → DI 컨테이너 → 데이터베이스 → Express 앱 → 서버 리스닝

import 'reflect-metadata';  // TSyringe 데코레이터와 메타데이터 리플렉션을 위한 polyfill

// 인프라스트럭처 계층 임포트
import { setupContainer, validateContainer } from './infrastructure/di/container';  // 의존성 주입 컨테이너
import { createApp } from './infrastructure/web/express/app';                      // Express 애플리케이션 팩토리
import { config } from './infrastructure/config/env.config';                      // 환경 설정 관리
import { db } from './infrastructure/config/database.config';                     // 데이터베이스 연결 관리
import { Logger } from './infrastructure/logging/Logger';                         // 구조화된 로깅 서비스

// 메인 애플리케이션 로거 인스턴스
// 'Main' 컨텍스트로 모든 부트스트래핑 로그를 구분
const logger = new Logger('Main');

/**
 * 애플리케이션 부트스트래핑 함수
 * 
 * 서버 시작에 필요한 모든 초기화 작업을 순차적으로 수행합니다.
 * 각 단계는 독립적이며, 실패 시 전체 프로세스를 중단하고 적절한 에러를 반환합니다.
 * 
 * 초기화 단계:
 * 1. DI 컨테이너 설정 및 검증
 * 2. 데이터베이스 연결 및 헬스체크
 * 3. Express 애플리케이션 생성 및 미들웨어 설정
 * 4. HTTP 서버 시작 및 포트 바인딩
 * 5. Graceful shutdown 핸들러 등록
 * 
 * @throws {Error} DI 컨테이너, 데이터베이스, 또는 서버 시작 중 오류 발생 시
 */
async function bootstrap() {
  try {
    logger.info('🚀 Paperly backend server 시작 중...');

    // ========================================================================
    // 1단계: 의존성 주입 컨테이너 초기화
    // ========================================================================
    
    logger.info('⚙️  의존성 주입 컨테이너 설정 중...');
    
    // TSyringe 컨테이너에 모든 서비스, 리포지토리, 유스케이스 등록
    // 의존성 그래프를 빌드하고 순환 의존성 검사
    setupContainer();
    
    // 컨테이너 설정 검증: 모든 의존성이 해결 가능한지 확인
    // 누락된 바인딩이나 잘못된 설정을 사전에 감지
    validateContainer();
    
    logger.info('✅ DI 컨테이너 설정 완료');

    // ========================================================================
    // 2단계: 데이터베이스 연결 초기화
    // ========================================================================
    
    logger.info('🗄️  데이터베이스 연결 중...');
    
    // PostgreSQL 데이터베이스 연결 풀 초기화
    // 마이그레이션 상태 확인 및 스키마 검증
    await db.initialize();
    
    logger.info('✅ 데이터베이스 연결 완료');

    // ========================================================================
    // 3단계: Express 애플리케이션 생성
    // ========================================================================
    
    logger.info('🌐 Express 애플리케이션 생성 중...');
    
    // Express 인스턴스 생성 및 모든 미들웨어, 라우트, 에러 핸들러 설정
    // CORS, 보안 헤더, 로깅, 인증, Rate Limiting 등 포함
    const app = createApp();
    
    logger.info('✅ Express 애플리케이션 생성 완료');

    // ========================================================================
    // 4단계: HTTP 서버 시작
    // ========================================================================
    
    // 설정된 포트에서 HTTP 서버 시작
    // 성공 시 상세한 서버 정보 로깅
    const server = app.listen(config.PORT, () => {
      logger.info(`🎉 서버가 포트 ${config.PORT}에서 실행 중입니다!`, {
        environment: config.NODE_ENV,    // 개발/프로덕션 환경
        apiPrefix: config.API_PREFIX,    // API 경로 접두사 (예: /api/v1)
        corsOrigin: config.CORS_ORIGIN,  // 허용된 CORS 오리진
        pid: process.pid,                // 프로세스 ID (클러스터링/모니터링용)
      });
    });

    // ========================================================================
    // 5단계: Graceful Shutdown 핸들러 등록
    // ========================================================================
    
    // SIGTERM, SIGINT 등의 시그널과 예외 처리를 위한 핸들러 설정
    // 서버 종료 시 진행 중인 요청 완료 후 안전하게 종료
    setupGracefulShutdown(server);

  } catch (error) {
    // ========================================================================
    // 부트스트래핑 실패 처리
    // ========================================================================
    
    logger.error('❌ 서버 시작 실패', error);
    
    // 의존성 주입 관련 에러 특별 처리
    // TSyringe 컨테이너에서 의존성을 해결할 수 없는 경우 상세한 안내 제공
    if (error instanceof Error && error.message.includes('Cannot inject')) {
      logger.error('🔧 DI 컨테이너 설정을 확인해주세요. 누락된 의존성이 있을 수 있습니다.');
      logger.error('📋 확인 사항: @injectable 데코레이터, 컨테이너 바인딩, 순환 의존성');
    }
    
    // 데이터베이스 연결 실패 특별 처리
    if (error instanceof Error && error.message.includes('database')) {
      logger.error('🗄️  데이터베이스 연결을 확인해주세요. 환경변수와 네트워크를 점검하세요.');
    }
    
    // 프로세스 종료: exit code 1로 실패 상태 명시
    // Docker, PM2 등에서 재시작 정책 판단에 사용
    process.exit(1);
  }
}

/**
 * Graceful Shutdown 설정 함수
 * 
 * 애플리케이션이 안전하게 종료될 수 있도록 시그널 핸들러를 등록합니다.
 * 진행 중인 요청의 완료를 기다리고, 데이터베이스 연결을 정리하며,
 * 기타 리소스를 해제한 후 프로세스를 종료합니다.
 * 
 * 처리하는 시그널:
 * - SIGTERM: 정상 종료 요청 (Docker, Kubernetes에서 사용)
 * - SIGINT: 인터럽트 신호 (Ctrl+C)
 * - uncaughtException: 처리되지 않은 예외
 * - unhandledRejection: 처리되지 않은 Promise 거부
 * 
 * Graceful Shutdown 단계:
 * 1. 새로운 연결 거부
 * 2. 진행 중인 요청 완료 대기
 * 3. 데이터베이스 연결 정리
 * 4. 기타 리소스 해제 (Redis, 파일 핸들 등)
 * 5. 프로세스 종료
 * 
 * @param server Express HTTP 서버 인스턴스
 */
function setupGracefulShutdown(server: any) {
  /**
   * 실제 종료 로직을 수행하는 내부 함수
   * 
   * @param signal 수신된 종료 시그널 또는 에러 타입
   */
  const shutdown = async (signal: string) => {
    logger.info(`📶 ${signal} 신호를 받았습니다. Graceful shutdown을 시작합니다...`);

    // ========================================================================
    // 1단계: HTTP 서버 종료 (새로운 연결 거부)
    // ========================================================================
    
    // HTTP 서버가 새로운 연결을 받지 않도록 설정
    // 기존 연결은 완료될 때까지 유지
    server.close(() => {
      logger.info('🔒 HTTP 서버가 종료되었습니다');
    });

    try {
      // ========================================================================
      // 2단계: 데이터베이스 연결 정리
      // ========================================================================
      
      logger.info('🗄️  데이터베이스 연결을 종료하는 중...');
      
      // PostgreSQL 연결 풀 종료
      // 진행 중인 쿼리 완료 후 모든 연결 해제
      await db.close();
      
      logger.info('✅ 데이터베이스 연결이 종료되었습니다');

      // ========================================================================
      // 3단계: 기타 리소스 정리
      // ========================================================================
      
      // TODO: Redis 연결 종료
      // TODO: 열린 파일 핸들 정리
      // TODO: WebSocket 연결 정리
      // TODO: 백그라운드 작업 중단
      // TODO: 외부 API 연결 정리
      
      logger.info('🎯 Graceful shutdown이 완료되었습니다');
      
      // 정상 종료: exit code 0
      process.exit(0);
      
    } catch (error) {
      // ========================================================================
      // 종료 과정 중 에러 처리
      // ========================================================================
      
      logger.error('❌ Graceful shutdown 중 오류 발생', error);
      
      // 강제 종료: exit code 1 (에러 상태)
      // 리소스 정리에 실패했으므로 빠른 종료
      process.exit(1);
    }
  };

  // ========================================================================
  // 정상 종료 시그널 핸들러 등록
  // ========================================================================
  
  // SIGTERM: Docker, Kubernetes, PM2 등에서 전송하는 정상 종료 신호
  // 컨테이너 재시작, 배포, 스케일링 시 사용
  process.on('SIGTERM', () => shutdown('SIGTERM'));
  
  // SIGINT: 사용자가 Ctrl+C를 누르거나 키보드 인터럽트 시 발생
  // 개발 환경에서 서버 중단 시 주로 사용
  process.on('SIGINT', () => shutdown('SIGINT'));

  // ========================================================================
  // 예외적 상황 핸들러 등록
  // ========================================================================
  
  // 처리되지 않은 동기 예외 캐치
  // try-catch로 잡히지 않은 예외가 Node.js 이벤트 루프까지 도달한 경우
  process.on('uncaughtException', (error) => {
    logger.error('💥 처리되지 않은 예외', error);
    logger.error('🔍 스택 트레이스를 확인하여 예외 처리를 추가해주세요');
    shutdown('uncaughtException');
  });

  // 처리되지 않은 Promise 거부 캐치
  // .catch()나 try-catch로 처리되지 않은 rejected Promise
  process.on('unhandledRejection', (reason, promise) => {
    logger.error('🚫 처리되지 않은 Promise 거부', { promise, reason });
    logger.error('🔍 Promise에 .catch() 핸들러를 추가하거나 try-catch로 감싸주세요');
    shutdown('unhandledRejection');
  });
}

// ============================================================================
// 애플리케이션 시작점
// ============================================================================

// 부트스트래핑 함수 실행으로 전체 서버 초기화 프로세스 시작
// 이 시점에서 모든 의존성, 데이터베이스, 웹 서버가 순차적으로 초기화됨
bootstrap();