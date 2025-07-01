import { Request, Response, NextFunction } from 'express';
import { Logger } from '../../logging/Logger';
import { ClientType } from './client-auth.middleware';

const logger = new Logger('ErrorHandler');

export interface ClientAuthRequest extends Request {
  clientType?: ClientType;
}

export interface ApiError extends Error {
  statusCode?: number;
  code?: string;
  details?: any;
  clientType?: ClientType;
}

export class ApiErrorBuilder {
  private error: ApiError;

  constructor(message: string) {
    this.error = new Error(message) as ApiError;
  }

  withStatusCode(statusCode: number): ApiErrorBuilder {
    this.error.statusCode = statusCode;
    return this;
  }

  withCode(code: string): ApiErrorBuilder {
    this.error.code = code;
    return this;
  }

  withDetails(details: any): ApiErrorBuilder {
    this.error.details = details;
    return this;
  }

  withClientType(clientType: ClientType): ApiErrorBuilder {
    this.error.clientType = clientType;
    return this;
  }

  build(): ApiError {
    return this.error;
  }
}

export const createApiError = (message: string): ApiErrorBuilder => {
  return new ApiErrorBuilder(message);
};

// Centralized error handling middleware
export const errorHandler = (
  error: ApiError,
  req: ClientAuthRequest,
  res: Response,
  next: NextFunction
) => {
  const clientType = req.clientType || 'unknown';
  const statusCode = error.statusCode || 500;
  const errorCode = error.code || 'INTERNAL_SERVER_ERROR';
  
  // Log error with client context
  logger.error('API Error occurred', {
    message: error.message,
    statusCode,
    errorCode,
    clientType,
    path: req.path,
    method: req.method,
    ip: req.ip,
    userAgent: req.get('User-Agent'),
    stack: error.stack,
    details: error.details
  });

  // Client-specific error response formatting
  const baseErrorResponse = {
    success: false,
    error: {
      code: errorCode,
      message: error.message,
      timestamp: new Date().toISOString(),
      path: req.path,
      method: req.method
    }
  };

  // Add client-specific context
  switch (clientType) {
    case ClientType.MOBILE:
      res.status(statusCode).json({
        ...baseErrorResponse,
        client: 'mobile',
        error: {
          ...baseErrorResponse.error,
          userFriendlyMessage: getUserFriendlyMessage(errorCode, 'mobile'),
          canRetry: isRetryableError(statusCode),
          suggestedAction: getSuggestedAction(errorCode, 'mobile')
        }
      });
      break;

    case ClientType.WRITER:
      res.status(statusCode).json({
        ...baseErrorResponse,
        client: 'writer',
        error: {
          ...baseErrorResponse.error,
          userFriendlyMessage: getUserFriendlyMessage(errorCode, 'writer'),
          canRetry: isRetryableError(statusCode),
          suggestedAction: getSuggestedAction(errorCode, 'writer'),
          details: process.env.NODE_ENV === 'development' ? error.details : undefined
        }
      });
      break;

    case ClientType.ADMIN:
      res.status(statusCode).json({
        ...baseErrorResponse,
        client: 'admin',
        error: {
          ...baseErrorResponse.error,
          details: error.details,
          stack: process.env.NODE_ENV === 'development' ? error.stack : undefined,
          canRetry: isRetryableError(statusCode),
          suggestedAction: getSuggestedAction(errorCode, 'admin')
        }
      });
      break;

    default:
      // Legacy/unknown client handling
      res.status(statusCode).json({
        ...baseErrorResponse,
        error: {
          ...baseErrorResponse.error,
          canRetry: isRetryableError(statusCode)
        }
      });
  }
};

// Helper functions for error context
function getUserFriendlyMessage(errorCode: string, clientType: string): string {
  const messages = {
    mobile: {
      'AUTHENTICATION_FAILED': 'Please log in again to continue.',
      'INSUFFICIENT_PERMISSIONS': 'You don\'t have permission to access this content.',
      'VALIDATION_ERROR': 'Please check your input and try again.',
      'NETWORK_ERROR': 'Connection problem. Please check your internet.',
      'SERVER_ERROR': 'Something went wrong. Please try again later.',
      'NOT_FOUND': 'The content you\'re looking for isn\'t available.',
      'RATE_LIMIT_EXCEEDED': 'Too many requests. Please wait a moment.',
      'CLIENT_TYPE_FORBIDDEN': 'This feature is not available in the mobile app.'
    },
    writer: {
      'AUTHENTICATION_FAILED': 'Your session has expired. Please log in again.',
      'INSUFFICIENT_PERMISSIONS': 'Writer permissions required for this action.',
      'VALIDATION_ERROR': 'Please review your submission and correct any errors.',
      'NETWORK_ERROR': 'Network connection issue. Your work is saved locally.',
      'SERVER_ERROR': 'Server error occurred. Your work has been auto-saved.',
      'NOT_FOUND': 'The article or resource could not be found.',
      'RATE_LIMIT_EXCEEDED': 'Publishing rate limit reached. Please wait before trying again.',
      'CLIENT_TYPE_FORBIDDEN': 'This action requires writer app access.'
    },
    admin: {
      'AUTHENTICATION_FAILED': 'Admin authentication required.',
      'INSUFFICIENT_PERMISSIONS': 'Insufficient admin privileges for this operation.',
      'VALIDATION_ERROR': 'Input validation failed.',
      'NETWORK_ERROR': 'Network connectivity issue.',
      'SERVER_ERROR': 'Internal server error occurred.',
      'NOT_FOUND': 'Resource not found.',
      'RATE_LIMIT_EXCEEDED': 'API rate limit exceeded.',
      'CLIENT_TYPE_FORBIDDEN': 'Admin access required for this endpoint.'
    }
  };

  return messages[clientType]?.[errorCode] || 'An unexpected error occurred.';
}

function getSuggestedAction(errorCode: string, clientType: string): string {
  const actions = {
    mobile: {
      'AUTHENTICATION_FAILED': 'Tap to log in again',
      'INSUFFICIENT_PERMISSIONS': 'Contact support if this seems wrong',
      'VALIDATION_ERROR': 'Review and correct your input',
      'NETWORK_ERROR': 'Check connection and retry',
      'SERVER_ERROR': 'Pull down to refresh',
      'NOT_FOUND': 'Go back or search for content',
      'RATE_LIMIT_EXCEEDED': 'Wait a moment and try again',
      'CLIENT_TYPE_FORBIDDEN': 'Use the web version for this feature'
    },
    writer: {
      'AUTHENTICATION_FAILED': 'Click to log in again',
      'INSUFFICIENT_PERMISSIONS': 'Apply for writer access in settings',
      'VALIDATION_ERROR': 'Check highlighted fields and resubmit',
      'NETWORK_ERROR': 'Check connection - work is saved',
      'SERVER_ERROR': 'Refresh the page and try again',
      'NOT_FOUND': 'Return to dashboard or create new content',
      'RATE_LIMIT_EXCEEDED': 'Wait before publishing again',
      'CLIENT_TYPE_FORBIDDEN': 'Access this feature from the writer dashboard'
    },
    admin: {
      'AUTHENTICATION_FAILED': 'Log in with admin credentials',
      'INSUFFICIENT_PERMISSIONS': 'Contact super admin for access',
      'VALIDATION_ERROR': 'Review request parameters',
      'NETWORK_ERROR': 'Check network connection',
      'SERVER_ERROR': 'Check system logs for details',
      'NOT_FOUND': 'Verify resource exists',
      'RATE_LIMIT_EXCEEDED': 'Reduce request frequency',
      'CLIENT_TYPE_FORBIDDEN': 'Use admin panel for this operation'
    }
  };

  return actions[clientType]?.[errorCode] || 'Try again or contact support';
}

function isRetryableError(statusCode: number): boolean {
  // Server errors and rate limits are typically retryable
  return statusCode >= 500 || statusCode === 429 || statusCode === 408;
}

// Not found handler for unmatched routes
export const notFoundHandler = (req: ClientAuthRequest, res: Response, next: NextFunction) => {
  const clientType = req.clientType || 'unknown';
  
  logger.warn('Route not found', {
    path: req.path,
    method: req.method,
    clientType,
    ip: req.ip,
    userAgent: req.get('User-Agent')
  });

  const error = createApiError('Route not found')
    .withStatusCode(404)
    .withCode('NOT_FOUND')
    .withClientType(clientType as ClientType)
    .withDetails({
      availableEndpoints: getAvailableEndpoints(clientType)
    })
    .build();

  next(error);
};

function getAvailableEndpoints(clientType: string): string[] {
  const endpoints = {
    mobile: ['/api/mobile/auth', '/api/mobile/articles', '/api/mobile/categories', '/api/mobile/recommendations'],
    writer: ['/api/writer/auth', '/api/writer/articles', '/api/writer/profile', '/api/writer/analytics'],
    admin: ['/api/admin/auth', '/api/admin/users', '/api/admin/articles', '/api/admin/security'],
    unknown: ['/api/mobile/', '/api/writer/', '/api/admin/']
  };

  return endpoints[clientType] || endpoints.unknown;
}