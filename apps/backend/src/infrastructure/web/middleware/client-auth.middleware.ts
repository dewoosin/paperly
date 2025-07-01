import { Request, Response, NextFunction } from 'express';
import { Logger } from '../../logging/Logger';

const logger = new Logger('ClientAuthMiddleware');

export enum ClientType {
  MOBILE = 'mobile',
  WRITER = 'writer',
  ADMIN = 'admin'
}

export interface ClientAuthRequest extends Request {
  clientType?: ClientType;
}

export const clientAuthMiddleware = (allowedClientTypes: ClientType[]) => {
  return (req: ClientAuthRequest, res: Response, next: NextFunction) => {
    try {
      const requestPath = req.path;
      let detectedClientType: ClientType | null = null;

      if (requestPath.startsWith('/api/mobile/') || req.headers['x-client-type'] === 'mobile') {
        detectedClientType = ClientType.MOBILE;
      } else if (requestPath.startsWith('/api/writer/') || req.headers['x-client-type'] === 'writer') {
        detectedClientType = ClientType.WRITER;
      } else if (requestPath.startsWith('/api/admin/') || req.headers['x-client-type'] === 'admin') {
        detectedClientType = ClientType.ADMIN;
      }

      if (!detectedClientType) {
        logger.warn('Client type could not be determined', {
          path: requestPath,
          headers: req.headers,
          ip: req.ip
        });
        return res.status(400).json({
          success: false,
          error: {
            code: 'CLIENT_TYPE_REQUIRED',
            message: 'Client type must be specified'
          }
        });
      }

      if (!allowedClientTypes.includes(detectedClientType)) {
        logger.warn('Client type not allowed for this endpoint', {
          detectedClientType,
          allowedClientTypes,
          path: requestPath,
          ip: req.ip
        });
        return res.status(403).json({
          success: false,
          error: {
            code: 'CLIENT_TYPE_FORBIDDEN',
            message: `${detectedClientType} clients are not allowed to access this endpoint`
          }
        });
      }

      req.clientType = detectedClientType;
      logger.debug('Client type validated', {
        clientType: detectedClientType,
        path: requestPath
      });

      next();
    } catch (error) {
      logger.error('Client auth middleware error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'CLIENT_AUTH_ERROR',
          message: 'Client authentication failed'
        }
      });
    }
  };
};

export const requireMobileClient = clientAuthMiddleware([ClientType.MOBILE]);
export const requireWriterClient = clientAuthMiddleware([ClientType.WRITER]);
export const requireAdminClient = clientAuthMiddleware([ClientType.ADMIN]);
export const requireWriterOrAdmin = clientAuthMiddleware([ClientType.WRITER, ClientType.ADMIN]);
export const requireAnyClient = clientAuthMiddleware([ClientType.MOBILE, ClientType.WRITER, ClientType.ADMIN]);