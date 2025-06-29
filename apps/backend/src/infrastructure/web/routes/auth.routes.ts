// /Users/workspace/paperly/apps/backend/src/infrastructure/web/routes/auth.routes.ts

import { Router, Request, Response, NextFunction } from 'express';
import { container } from 'tsyringe';
import { AuthController } from '../controllers/auth.controller';
import { authMiddleware } from '../middleware/auth.middleware';
import { rateLimiter, strictRateLimiter, emailRateLimiter } from '../middleware/rate-limiter.middleware';
import { asyncHandler } from '../express/middlewares/error.middleware';

/**
 * 인증 관련 라우트 생성
 * 
 * @returns Express Router
 */
export function createAuthRoutes(): Router {
  const router = Router();
  
  // 컨트롤러 인스턴스 가져오기
  const authController = container.resolve(AuthController);

  /**
   * Public 라우트 (인증 불필요)
   */
  
  // POST /api/v1/auth/register - 회원가입
  router.post(
    '/register',
    rateLimiter({ windowMs: 15 * 60 * 1000, max: 5 }), // 15분에 5회
    asyncHandler((req: Request, res: Response, next: NextFunction) => authController.router(req, res, next))
  );

  // POST /api/v1/auth/login - 로그인
  router.post(
    '/login',
    strictRateLimiter, // 15분에 5회
    asyncHandler((req: Request, res: Response, next: NextFunction) => authController.router(req, res, next))
  );

  // GET /api/v1/auth/verify-email - 이메일 인증
  router.get(
    '/verify-email',
    rateLimiter({ windowMs: 60 * 1000, max: 10 }), // 1분에 10회
    asyncHandler((req: Request, res: Response, next: NextFunction) => authController.router(req, res, next))
  );

  // POST /api/v1/auth/refresh - 토큰 갱신
  router.post(
    '/refresh',
    rateLimiter({ windowMs: 60 * 1000, max: 10 }), // 1분에 10회
    asyncHandler((req: Request, res: Response, next: NextFunction) => authController.router(req, res, next))
  );

  /**
   * Protected 라우트 (인증 필요)
   */
  
  // POST /api/v1/auth/logout - 로그아웃
  router.post(
    '/logout',
    authMiddleware,
    asyncHandler((req: Request, res: Response, next: NextFunction) => authController.router(req, res, next))
  );

  // POST /api/v1/auth/resend-verification - 인증 메일 재발송
  router.post(
    '/resend-verification',
    authMiddleware,
    emailRateLimiter, // 1시간에 3회
    asyncHandler((req: Request, res: Response, next: NextFunction) => authController.router(req, res, next))
  );

  // POST /api/v1/auth/skip-verification - 이메일 인증 스킵 (개발용)
  if (process.env.NODE_ENV !== 'production') {
    router.post(
      '/skip-verification',
      asyncHandler((req: Request, res: Response, next: NextFunction) => authController.router(req, res, next))
    );
  }

  // 실제로는 authController의 라우트를 사용
  router.use('/', authController.router);

  return router;
}

/**
 * 인증 관련 라우트 정보
 * 
 * API 문서화를 위한 라우트 정보입니다.
 */
export const authRoutesInfo = {
  prefix: '/auth',
  routes: [
    {
      method: 'POST',
      path: '/register',
      description: '회원가입',
      auth: false,
      rateLimit: '15분에 5회',
      body: {
        email: 'string (required)',
        password: 'string (required, min 8)',
        name: 'string (required, min 2)',
        birthDate: 'string (required, YYYY-MM-DD)',
        gender: 'string (optional, male|female|other|prefer_not_to_say)'
      }
    },
    {
      method: 'POST',
      path: '/login',
      description: '로그인',
      auth: false,
      rateLimit: '15분에 5회',
      body: {
        email: 'string (required)',
        password: 'string (required)'
      }
    },
    {
      method: 'GET',
      path: '/verify-email',
      description: '이메일 인증',
      auth: false,
      rateLimit: '1분에 10회',
      query: {
        token: 'string (required, UUID)'
      }
    },
    {
      method: 'POST',
      path: '/refresh',
      description: '토큰 갱신',
      auth: false,
      rateLimit: '1분에 10회',
      body: {
        refreshToken: 'string (required)'
      }
    },
    {
      method: 'POST',
      path: '/logout',
      description: '로그아웃',
      auth: true,
      body: {
        refreshToken: 'string (optional)',
        allDevices: 'boolean (optional)'
      }
    },
    {
      method: 'POST',
      path: '/resend-verification',
      description: '인증 이메일 재발송',
      auth: true,
      rateLimit: '1시간에 3회'
    }
  ]
};