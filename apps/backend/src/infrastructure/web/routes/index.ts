// apps/backend/src/infrastructure/web/routes/index.ts

import { Router } from 'express';
import { container } from 'tsyringe';
import { Logger } from '../../logging/logger';
import { AuthController } from '../controllers/auth.controller';

const logger = new Logger('Routes');

export const apiRouter = Router();

/**
 * API 버전 및 상태 정보
 */
apiRouter.get('/', (req, res) => {
  res.json({
    name: 'Paperly API',
    version: '1.0.0',
    status: 'running',
    timestamp: new Date().toISOString(),
  });
});

/**
 * Auth 라우트 설정
 */
function setupAuthRoutes(): Router {
  const authController = container.resolve(AuthController);
  const authRouter = Router();

  // 회원가입
  authRouter.post('/register', (req, res, next) => {
    authController.router.handle(req, res, next);
  });

  // 로그인
  authRouter.post('/login', (req, res, next) => {
    authController.router.handle(req, res, next);
  });

  // 토큰 갱신
  authRouter.post('/refresh', (req, res, next) => {
    authController.router.handle(req, res, next);
  });

  // 로그아웃
  authRouter.post('/logout', (req, res, next) => {
    authController.router.handle(req, res, next);
  });

  // 이메일 인증
  authRouter.get('/verify-email', (req, res, next) => {
    authController.router.handle(req, res, next);
  });

  // 인증 메일 재발송
  authRouter.post('/resend-verification', (req, res, next) => {
    authController.router.handle(req, res, next);
  });

  return authRouter;
}

// Auth 라우트 등록
apiRouter.use('/auth', setupAuthRoutes());

logger.info('API routes initialized with Auth endpoints');

// TODO: Day 4 - User routes  
// apiRouter.use('/users', userRouter);

// TODO: Day 4 - Article routes
// apiRouter.use('/articles', articleRouter);

// TODO: Day 5 - Category routes
// apiRouter.use('/categories', categoryRouter);