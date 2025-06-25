// apps/backend/src/infrastructure/web/routes/index.ts

import { Router } from 'express';
import { container } from 'tsyringe';
import { Logger } from '../../logging/Logger';
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
 * 실제 Auth 라우트 설정
 */
function setupAuthRoutes(): Router {
  const authController = container.resolve(AuthController);
  return authController.router;
}

// 실제 Auth 라우트 등록
apiRouter.use('/auth', setupAuthRoutes());

logger.info('API routes initialized with real Auth endpoints');

// TODO: Day 4 - User routes  
// apiRouter.use('/users', userRouter);

// TODO: Day 4 - Article routes
// apiRouter.use('/articles', articleRouter);

// TODO: Day 5 - Category routes
// apiRouter.use('/categories', categoryRouter);