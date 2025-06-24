// apps/backend/src/main.ts

import 'reflect-metadata'; // tsyringe 사용을 위해 필요
import { createApp } from './infrastructure/web/express/app';
import { config } from './infrastructure/config/env.config';
import { setupContainer } from './infrastructure/config/container';
import { Logger } from './infrastructure/logging/Logger';

const logger = new Logger('Main');

/**
 * 서버 시작
 */
async function bootstrap() {
  try {
    logger.info('Starting Paperly backend server...');

    // 1. DI Container 설정 (데이터베이스 연결 전에)
    setupContainer();
    logger.info('DI Container initialized');

    // 2. 데이터베이스 연결 (일단 스킵 - Mock 사용)
    // await db.initialize();
    logger.info('Database connection skipped (using Mock services)');

    // 3. Express 앱 생성
    const app = createApp();

    // 4. 서버 시작
    const server = app.listen(config.PORT, () => {
      logger.info(`🚀 Server is running on port ${config.PORT}`, {
        environment: config.NODE_ENV,
        apiPrefix: config.API_PREFIX,
        corsOrigin: config.CORS_ORIGIN,
      });
      
      logger.info('📋 Available endpoints:');
      logger.info('  GET  /health');
      logger.info('  GET  /api/v1/');
      logger.info('  POST /api/v1/auth/register');
      logger.info('  POST /api/v1/auth/login');
      logger.info('  POST /api/v1/auth/refresh');
      logger.info('  POST /api/v1/auth/logout');
      logger.info('  GET  /api/v1/auth/verify-email');
      logger.info('  POST /api/v1/auth/resend-verification');
    });

    // 5. Graceful shutdown 처리
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
      // 데이터베이스 연결 종료 (나중에 구현)
      // await db.close();
      logger.info('Database connection closed');

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