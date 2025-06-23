/**
 * env.config.ts
 * 
 * 환경 변수 검증 및 타입 안전한 설정 관리
 * Zod를 사용하여 환경 변수의 유효성을 검증하고 타입을 보장
 */

import { z } from 'zod';
import dotenv from 'dotenv';
import { Logger } from '../logging/Logger';

// 환경별 .env 파일 로드
dotenv.config({
  path: `.env.${process.env.NODE_ENV || 'development'}`,
});

// 기본 .env 파일도 로드 (공통 설정)
dotenv.config();

const logger = new Logger('EnvConfig');

/**
 * 환경 변수 스키마 정의
 */
const envSchema = z.object({
  // 노드 환경
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  
  // 서버 설정
  PORT: z.string().transform(Number).default('3000'),
  API_PREFIX: z.string().default('/api/v1'),
  
  // 데이터베이스 설정
  DB_HOST: z.string(),
  DB_PORT: z.string().transform(Number),
  DB_NAME: z.string(),
  DB_USER: z.string(),
  DB_PASSWORD: z.string(),
  DB_SSL_CA: z.string().optional(),
  
  // Redis 설정
  REDIS_HOST: z.string().default('localhost'),
  REDIS_PORT: z.string().transform(Number).default('6379'),
  REDIS_PASSWORD: z.string().optional(),
  
  // JWT 설정
  JWT_SECRET: z.string().min(32),
  JWT_ACCESS_TOKEN_EXPIRES_IN: z.string().default('15m'),
  JWT_REFRESH_TOKEN_EXPIRES_IN: z.string().default('7d'),
  
  // CORS 설정
  CORS_ORIGIN: z.string().transform((val) => {
    // 콤마로 구분된 여러 origin 지원
    return val.split(',').map(origin => origin.trim());
  }).default('http://localhost:3000'),
  
  // 로깅 설정
  LOG_LEVEL: z.enum(['error', 'warn', 'info', 'http', 'debug']).default('info'),
  
  // OpenAI 설정 (선택적)
  OPENAI_API_KEY: z.string().optional(),
  OPENAI_ORGANIZATION: z.string().optional(),
  
  // AWS S3 설정 (선택적)
  AWS_ACCESS_KEY_ID: z.string().optional(),
  AWS_SECRET_ACCESS_KEY: z.string().optional(),
  AWS_REGION: z.string().default('ap-northeast-2'),
  S3_BUCKET_NAME: z.string().optional(),
  
  // 이메일 설정 (선택적)
  SMTP_HOST: z.string().optional(),
  SMTP_PORT: z.string().transform(Number).optional(),
  SMTP_USER: z.string().optional(),
  SMTP_PASSWORD: z.string().optional(),
  EMAIL_FROM: z.string().email().optional(),
  
  // 앱 설정
  APP_NAME: z.string().default('Paperly'),
  APP_URL: z.string().url().default('http://localhost:3000'),
  
  // 보안 설정
  BCRYPT_SALT_ROUNDS: z.string().transform(Number).default('10'),
  RATE_LIMIT_WINDOW_MS: z.string().transform(Number).default('900000'), // 15분
  RATE_LIMIT_MAX_REQUESTS: z.string().transform(Number).default('100'),
});

/**
 * 환경 변수 타입
 */
export type EnvConfig = z.infer<typeof envSchema>;

/**
 * 환경 변수 검증 및 파싱
 */
function validateEnv(): EnvConfig {
  try {
    const env = envSchema.parse(process.env);
    logger.info('Environment variables validated successfully', {
      NODE_ENV: env.NODE_ENV,
      PORT: env.PORT,
    });
    return env;
  } catch (error) {
    if (error instanceof z.ZodError) {
      logger.error('Environment validation failed', error.errors);
      console.error('❌ Invalid environment variables:');
      error.errors.forEach((err) => {
        console.error(`  - ${err.path.join('.')}: ${err.message}`);
      });
    }
    process.exit(1);
  }
}

/**
 * 검증된 환경 변수 export
 */
export const config = validateEnv();

/**
 * 환경별 설정값
 */
export const isDevelopment = config.NODE_ENV === 'development';
export const isTest = config.NODE_ENV === 'test';
export const isProduction = config.NODE_ENV === 'production';

/**
 * 데이터베이스 연결 문자열 생성
 */
export function getDatabaseUrl(): string {
  const { DB_USER, DB_PASSWORD, DB_HOST, DB_PORT, DB_NAME } = config;
  return `postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}`;
}

/**
 * Redis 연결 문자열 생성
 */
export function getRedisUrl(): string {
  const { REDIS_HOST, REDIS_PORT, REDIS_PASSWORD } = config;
  if (REDIS_PASSWORD) {
    return `redis://:${REDIS_PASSWORD}@${REDIS_HOST}:${REDIS_PORT}`;
  }
  return `redis://${REDIS_HOST}:${REDIS_PORT}`;
}
