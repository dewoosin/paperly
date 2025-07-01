// apps/backend/src/infrastructure/web/express/cors.config.ts

import { CorsOptions } from 'cors';
import { Logger } from '../../logging/Logger';

const logger = new Logger('CORS');

/**
 * Get allowed origins from environment variables
 */
function getAllowedOrigins(): string[] {
  const defaultOrigins = [
    'http://localhost:3000',
    'http://localhost:3001',
    'http://localhost:8080',
    'http://localhost:4200',
    'http://localhost:5173', // Vite default
  ];

  // Production origins from environment
  const productionOrigins = process.env.ALLOWED_ORIGINS
    ? process.env.ALLOWED_ORIGINS.split(',').map(origin => origin.trim())
    : [];

  // Admin panel origins
  const adminOrigins = process.env.ADMIN_ORIGINS
    ? process.env.ADMIN_ORIGINS.split(',').map(origin => origin.trim())
    : [];

  // Mobile app deep links (if needed)
  const mobileOrigins = [
    'paperly://',
    'com.paperly.app://',
  ];

  const allOrigins = [
    ...defaultOrigins,
    ...productionOrigins,
    ...adminOrigins,
    ...mobileOrigins,
  ];

  // Remove duplicates
  return [...new Set(allOrigins)];
}

/**
 * CORS configuration
 */
export const corsOptions: CorsOptions = {
  origin: (origin, callback) => {
    const allowedOrigins = getAllowedOrigins();
    
    // Allow requests with no origin (mobile apps, Postman, etc.)
    if (!origin) {
      return callback(null, true);
    }

    // Check if origin is allowed
    if (allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      logger.warn(`CORS: Blocked request from origin: ${origin}`);
      callback(new Error(`CORS: Origin ${origin} not allowed`));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: [
    'Content-Type',
    'Authorization',
    'X-Request-ID',
    'x-device-id',
    'X-Device-Id',
    'X-CSRF-Token',
    'Cache-Control',
  ],
  exposedHeaders: [
    'X-Request-ID',
    'X-RateLimit-Limit',
    'X-RateLimit-Remaining',
    'X-RateLimit-Reset',
  ],
  maxAge: 86400, // 24 hours
  preflightContinue: false,
  optionsSuccessStatus: 204,
};

/**
 * Development CORS configuration (more permissive)
 */
export const devCorsOptions: CorsOptions = {
  origin: true, // Allow all origins in development
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: [
    'Content-Type',
    'Authorization',
    'X-Request-ID',
    'x-device-id',
    'X-Device-Id',
    'X-CSRF-Token',
    'Cache-Control',
  ],
  exposedHeaders: [
    'X-Request-ID',
    'X-RateLimit-Limit',
    'X-RateLimit-Remaining',
    'X-RateLimit-Reset',
  ],
  maxAge: 3600,
};

/**
 * Get CORS options based on environment
 */
export function getCorsOptions(): CorsOptions {
  const isDevelopment = process.env.NODE_ENV === 'development' || !process.env.NODE_ENV;
  
  if (isDevelopment) {
    logger.info('Using development CORS configuration (permissive)');
    return devCorsOptions;
  }
  
  logger.info('Using production CORS configuration (restrictive)');
  logger.info(`Allowed origins: ${getAllowedOrigins().join(', ')}`);
  return corsOptions;
}