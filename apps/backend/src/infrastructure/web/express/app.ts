/**
 * app.ts
 * 
 * Express 애플리케이션 설정
 * 미들웨어, 라우트, 에러 핸들링 등을 구성
 */

import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import morgan from 'morgan';
import { config } from '../../config/env.config';
import { morganStream } from '../../logging/Logger';
import { errorHandler } from './middlewares/error.middleware';
import { notFoundHandler } from './middlewares/notFound.middleware';
import { rateLimiter } from './middlewares/rateLimit.middleware';
import { requestId } from './middlewares/requestId.middleware';
import { apiRouter } from '../routes';

/**
 * Express 앱 생성 및 설정
 */
export function createApp(): Application {
  const app = express();

  /**
   * 기본 미들웨어 설정
   */
  
  // 보안 헤더 설정
  app.use(helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'"],
        imgSrc: ["'self'", "data:", "https:"],
      },
    },
  }));

  // CORS 설정
  app.use(cors({
    origin: config.CORS_ORIGIN,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-ID'],
  }));

  // 요청 본문 파싱
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));

  // 응답 압축
  app.use(compression());

  // 요청 ID 미들웨어
  app.use(requestId);

  // HTTP 로깅
  app.use(morgan('combined', { stream: morganStream }));

  // Rate limiting
  app.use(rateLimiter);

  /**
   * 헬스 체크 엔드포인트
   */
  app.get('/health', (req, res) => {
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      environment: config.NODE_ENV,
    });
  });

  /**
   * API 라우트
   */
  app.use(config.API_PREFIX, apiRouter);

  /**
   * 정적 파일 서빙 (프로덕션에서는 Nginx 권장)
   */
  if (config.NODE_ENV !== 'production') {
    app.use('/uploads', express.static('uploads'));
  }

  /**
   * 404 핸들러
   */
  app.use(notFoundHandler);

  /**
   * 글로벌 에러 핸들러
   */
  app.use(errorHandler);

  return app;
}
