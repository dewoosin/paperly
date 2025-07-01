// apps/backend/src/infrastructure/web/express/app.ts

import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import morgan from 'morgan';
import { config } from '../../config/env.config';
import { morganStream } from '../../logging/Logger';
import { errorMiddleware, notFoundMiddleware } from './middlewares/error.middleware';
import { rateLimiter } from './middlewares/rateLimit.middleware';
import { requestId } from './middlewares/requestId.middleware';
import { requestLogger } from './middlewares/request-logger.middleware';
import { apiRouter } from '../routes';
import { getCorsOptions } from './cors.config';

export function createApp(): Application {
  const app = express();

  // Secure CORS configuration
  app.use(cors(getCorsOptions()));

  // 보안 헤더 설정 (CORS 이후에)
  app.use(helmet({
    contentSecurityPolicy: false, // 개발 환경에서는 비활성화
    crossOriginEmbedderPolicy: false
  }));

  // 요청 본문 파싱
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));

  // 응답 압축
  app.use(compression());

  // 요청 ID 미들웨어
  app.use(requestId);

  // 상세 요청 로깅
  app.use(requestLogger);

  // HTTP 로깅
  app.use(morgan('combined', { stream: morganStream }));

  // Rate limiting (개발 환경에서는 관대하게)
  if (config.NODE_ENV === 'production') {
    app.use(rateLimiter);
  }

  // 헬스 체크 엔드포인트
  app.get('/health', (req, res) => {
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      environment: config.NODE_ENV,
    });
  });

  // API 라우트
  app.use(config.API_PREFIX, apiRouter);

  // 정적 파일 서빙
  if (config.NODE_ENV !== 'production') {
    app.use('/uploads', express.static('uploads'));
  }

  // 404 핸들러
  app.use(notFoundMiddleware);

  // 글로벌 에러 핸들러
  app.use(errorMiddleware);

  return app;
}