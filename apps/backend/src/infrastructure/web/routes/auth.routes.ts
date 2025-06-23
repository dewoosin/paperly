// apps/backend/src/infrastructure/web/routes/auth.routes.ts

import { Router } from 'express';
import { container } from 'tsyringe';
import { AuthController } from '../controllers/auth.controller';
import { authMiddleware } from '../middleware/auth.middleware';
import { rateLimiter } from '../middleware/rate-limiter.middleware';

export function createAuthRoutes(): Router {
  const router = Router();
  const authController = container.resolve(AuthController);

  // Rate limiting 설정
  const strictRateLimit = rateLimiter({
    windowMs: 15 * 60 * 1000, // 15분
    max: 5 // 최대 5회
  });

  const normalRateLimit = rateLimiter({
    windowMs: 15 * 60 * 1000, // 15분
    max: 20 // 최대 20회
  });

  // Public 라우트 (인증 불필요)
  router.post('/register', normalRateLimit, authController.router);
  router.post('/login', strictRateLimit, authController.router);
  router.get('/verify-email', normalRateLimit, authController.router);
  router.post('/refresh', normalRateLimit, authController.router);

  // Protected 라우트 (인증 필요)
  router.post('/logout', authMiddleware, authController.router);
  router.post('/resend-verification', authMiddleware, normalRateLimit, authController.router);

  return router;
}
