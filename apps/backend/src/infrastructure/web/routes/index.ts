/**
 * routes/index.ts
 * 
 * API 라우트 집합
 * 모든 라우트를 하나로 모아서 export
 */

import { Router } from 'express';
import { Logger } from '../../logging/logger';

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

// TODO: Day 3 - Auth routes
// apiRouter.use('/auth', authRouter);

// TODO: Day 4 - User routes  
// apiRouter.use('/users', userRouter);

// TODO: Day 4 - Article routes
// apiRouter.use('/articles', articleRouter);

// TODO: Day 5 - Category routes
// apiRouter.use('/categories', categoryRouter);

logger.info('API routes initialized');
