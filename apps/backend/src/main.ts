// apps/backend/src/main.ts

/**
 * main.ts
 * 
 * 애플리케이션 진입점
 * DI 컨테이너 초기화, 서버 시작 및 graceful shutdown 처리
 */

import 'reflect-metadata'; // TSyringe 의존성 주입을 위해 필요
import { setupContainer, validateContainer } from './infrastructure/di/container';
import { createApp } from './infrastructure/web/express/app';
import { config } from './infrastructure/config/env.config';
import { db } from './infrastructure/config/database.config';
import { Logger } from './infrastructure/logging/Logger';

const logger = new Logger('Main');

/**
 * 서버 시작
 */
async function bootstrap() {
  try {
    logger.info('🚀 Paperly backend server 시작 중...');

    // 1. DI 컨테이너 설정
    logger.info('⚙️  의존성 주입 컨테이너 설정 중...');
    setupContainer();
    validateContainer();
    logger.info('✅ DI 컨테이너 설정 완료');

    // 2. 데이터베이스 연결
    logger.info('🗄️  데이터베이스 연결 중...');
    await db.initialize();
    logger.info('✅ 데이터베이스 연결 완료');

    // 3. Express 앱 생성
    logger.info('🌐 Express 애플리케이션 생성 중...');
    const app = createApp();
    logger.info('✅ Express 애플리케이션 생성 완료');

    // 4. 서버 시작
    const server = app.listen(config.PORT, () => {
      logger.info(`🎉 서버가 포트 ${config.PORT}에서 실행 중입니다!`, {
        environment: config.NODE_ENV,
        apiPrefix: config.API_PREFIX,
        corsOrigin: config.CORS_ORIGIN,
        pid: process.pid,
      });
    });

    // 5. Graceful shutdown 처리
    setupGracefulShutdown(server);

  } catch (error) {
    logger.error('❌ 서버 시작 실패', error);
    
    // 컨테이너 관련 에러인 경우 추가 정보 제공
    if (error instanceof Error && error.message.includes('Cannot inject')) {
      logger.error('🔧 DI 컨테이너 설정을 확인해주세요. 누락된 의존성이 있을 수 있습니다.');
    }
    
    process.exit(1);
  }
}

/**
 * Graceful shutdown 설정
 */
function setupGracefulShutdown(server: any) {
  const shutdown = async (signal: string) => {
    logger.info(`📶 ${signal} 신호를 받았습니다. Graceful shutdown을 시작합니다...`);

    // 새로운 연결 거부
    server.close(() => {
      logger.info('🔒 HTTP 서버가 종료되었습니다');
    });

    try {
      // 데이터베이스 연결 종료
      logger.info('🗄️  데이터베이스 연결을 종료하는 중...');
      await db.close();
      logger.info('✅ 데이터베이스 연결이 종료되었습니다');

      // 기타 정리 작업
      // Redis 연결 종료, 파일 핸들 닫기 등
      // TODO: Redis 연결 종료 로직 추가

      logger.info('🎯 Graceful shutdown이 완료되었습니다');
      process.exit(0);
    } catch (error) {
      logger.error('❌ Graceful shutdown 중 오류 발생', error);
      process.exit(1);
    }
  };

  // 시그널 핸들러 등록
  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));

  // 예외 처리
  process.on('uncaughtException', (error) => {
    logger.error('💥 처리되지 않은 예외', error);
    shutdown('uncaughtException');
  });

  process.on('unhandledRejection', (reason, promise) => {
    logger.error('🚫 처리되지 않은 Promise 거부', { promise, reason });
    shutdown('unhandledRejection');
  });
}

// 서버 시작
bootstrap();