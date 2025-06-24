/**
 * main.ts
 * 
 * 애플리케이션 진입점
 * 서버 시작 및 graceful shutdown 처리
 */

import 'reflect-metadata'; // tsyringe를 위해 필요
import { createApp } from './infrastructure/web/express/app';
import { config } from './infrastructure/config/env.config';
import { db } from './infrastructure/config/database.config';
import { Logger } from './infrastructure/logging/Logger';
import { setupContainer } from './infrastructure/config/container';

const logger = new Logger('Main');

/**
 * 서버 시작
 */
async function bootstrap() {
  try {
    logger.info('Starting Paperly backend server...');

    // 의존성 주입 컨테이너 설정
    setupContainer();
    logger.info('Dependency injection container initialized');

    // 데이터베이스 연결
    await db.initialize();
    logger.info('Database connected successfully');

    // Express 앱 생성
    const app = createApp();

    // 서버 시작
    const server = app.listen(config.PORT, () => {
      logger.info(`Server is running on port ${config.PORT}`, {
        environment: config.NODE_ENV,
        apiPrefix: config.API_PREFIX,
        corsOrigin: config.CORS_ORIGIN,
      });
    });

    // Graceful shutdown 처리
    setupGracefulShutdown(server);

  } catch (error) {
    logger.error('Failed to start server', error);
    process.exit(1);
  }
}

/**
 * Graceful shutdown 설정
 */
function setupGracefulShutdown(server: any) {
  const shutdown = async (signal: string) => {
    logger.info(`Received ${signal} signal, starting graceful shutdown...`);

    // 새로운 연결 거부
    server.close(() => {
      logger.info('HTTP server closed');
    });

    try {
      // 데이터베이스 연결 종료
      await db.close();
      logger.info('Database connection closed');

      // 기타 정리 작업
      // Redis 연결 종료, 파일 핸들 닫기 등

      logger.info('Graceful shutdown completed');
      process.exit(0);
    } catch (error) {
      logger.error('Error during graceful shutdown', error);
      process.exit(1);
    }
  };

  // 시그널 핸들러 등록
  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));

  // 예외 처리
  process.on('uncaughtException', (error) => {
    logger.error('Uncaught Exception', error);
    shutdown('uncaughtException');
  });

  process.on('unhandledRejection', (reason, promise) => {
    logger.error('Unhandled Rejection at:', { promise, reason });
    shutdown('unhandledRejection');
  });
}

// 서버 시작
bootstrap();