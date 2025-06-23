/**
 * notFound.middleware.ts
 * 404 처리 미들웨어
 */

import { Request, Response } from 'express';

export function notFoundHandler(req: Request, res: Response): void {
  res.status(404).json({
    error: {
      code: 'NOT_FOUND',
      message: `Route ${req.method} ${req.path} not found`,
      timestamp: new Date(),
      requestId: req.id,
    },
  });
}
