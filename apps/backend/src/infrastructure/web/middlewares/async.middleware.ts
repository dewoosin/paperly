// apps/backend/src/infrastructure/web/middlewares/async.middleware.ts

import { Request, Response, NextFunction } from 'express';

type AsyncRequestHandler = (req: Request, res: Response, next: NextFunction) => Promise<any>;

/**
 * 비동기 라우트 핸들러를 위한 래퍼
 * 비동기 함수에서 발생하는 예외를 자동으로 catch하여 에러 미들웨어로 전달
 */
export const asyncHandler = (fn: AsyncRequestHandler) => {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};