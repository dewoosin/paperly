// apps/backend/src/infrastructure/web/routes/index.ts

import { Router } from 'express';
import { container } from 'tsyringe';
import { Logger } from '../../logging/Logger';

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
 * 임시 Auth 라우트 (테스트용)
 */
function setupTempAuthRoutes(): Router {
  const authRouter = Router();

  // 임시 회원가입 엔드포인트
  authRouter.post('/register', (req, res) => {
    logger.info('임시 회원가입 요청 받음', { body: req.body });
    
    // 임시 응답
    res.status(201).json({
      success: true,
      data: {
        user: {
          id: 'temp-user-id',
          email: req.body.email,
          name: req.body.name
        },
        tokens: {
          accessToken: 'temp-access-token',
          refreshToken: 'temp-refresh-token'
        },
        emailVerificationSent: false,
        message: '임시 회원가입이 완료되었습니다.'
      }
    });
  });

  // 임시 로그인 엔드포인트
  authRouter.post('/login', (req, res) => {
    logger.info('임시 로그인 요청 받음', { body: req.body });
    
    res.json({
      success: true,
      data: {
        user: {
          id: 'temp-user-id',
          email: req.body.email,
          name: 'Test User',
          emailVerified: true
        },
        tokens: {
          accessToken: 'temp-access-token',
          refreshToken: 'temp-refresh-token'
        }
      }
    });
  });

  // 기타 임시 엔드포인트들
  authRouter.post('/refresh', (req, res) => {
    res.json({
      success: true,
      data: {
        tokens: {
          accessToken: 'new-temp-access-token',
          refreshToken: 'new-temp-refresh-token'
        }
      }
    });
  });

  authRouter.post('/logout', (req, res) => {
    res.json({
      success: true,
      message: '로그아웃 되었습니다.'
    });
  });

  authRouter.get('/verify-email', (req, res) => {
    res.json({
      success: true,
      message: '이메일 인증이 완료되었습니다.'
    });
  });

  authRouter.post('/resend-verification', (req, res) => {
    res.json({
      success: true,
      message: '인증 메일이 재발송되었습니다.'
    });
  });

  return authRouter;
}

// 임시 Auth 라우트 등록
apiRouter.use('/auth', setupTempAuthRoutes());

logger.info('API routes initialized with temporary Auth endpoints');

// TODO: Day 4 - User routes  
// apiRouter.use('/users', userRouter);

// TODO: Day 4 - Article routes
// apiRouter.use('/articles', articleRouter);

// TODO: Day 5 - Category routes
// apiRouter.use('/categories', categoryRouter);