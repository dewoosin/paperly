// /Users/workspace/paperly/apps/backend/src/infrastructure/config/env.config.ts

import { z } from 'zod';
import { config as dotenvConfig } from 'dotenv';
import { getPlatformConfig } from './platform.config';

// .env 파일 로드
dotenvConfig();

// 플랫폼별 설정 가져오기
const platformConfig = getPlatformConfig();

// Logger는 나중에 import (순환 참조 방지)
let Logger: any;

/**
 * 환경변수 스키마 정의
 * 
 * 모든 환경변수의 타입과 기본값을 정의합니다.
 */
const envSchema = z.object({
  // 기본 설정
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.string().transform(Number).default('3000'),
  
  // API 설정
  API_PREFIX: z.string().default('/api/v1'),
  
  // 데이터베이스 설정
  DB_HOST: z.string().default(platformConfig.databaseHost),
  DB_PORT: z.string().transform(Number).default('5432'),
  DB_NAME: z.string().default('paperly_db'),
  DB_USER: z.string().default('paperly_user'),
  DB_PASSWORD: z.string().default('paperly_dev_password'),
  DB_SSL: z.string().transform(val => val === 'true').default('false'),
  
  // Redis 설정
  REDIS_HOST: z.string().default(platformConfig.redisHost),
  REDIS_PORT: z.string().transform(Number).default('6379'),
  REDIS_PASSWORD: z.string().optional(),
  
  // JWT 설정
  JWT_SECRET: z.string().min(32, 'JWT_SECRET는 최소 32자 이상이어야 합니다'),
  JWT_REFRESH_SECRET: z.string().optional(),
  JWT_ACCESS_TOKEN_EXPIRES_IN: z.string().default('15m'),
  JWT_REFRESH_TOKEN_EXPIRES_IN: z.string().default('7d'),
  
  // CORS 설정
  CORS_ORIGIN: z.string().transform(val => val.split(',')).default('http://localhost:3000'),
  
  // Rate Limiting 설정
  RATE_LIMIT_WINDOW_MS: z.string().transform(Number).default('900000'), // 15분
  RATE_LIMIT_MAX_REQUESTS: z.string().transform(Number).default('100'),
  
  // 이메일 설정
  SMTP_HOST: z.string().optional(),
  SMTP_PORT: z.string().transform(Number).optional(),
  SMTP_SECURE: z.string().transform(val => val === 'true').optional(),
  SMTP_USER: z.string().optional(),
  SMTP_PASS: z.string().optional(),
  EMAIL_FROM: z.string().default('noreply@paperly.com'),
  
  // 클라이언트 URL
  CLIENT_URL: z.string().url().default('http://localhost:3000'),
  
  // 파일 업로드 설정
  UPLOAD_MAX_FILE_SIZE: z.string().transform(Number).default('10485760'), // 10MB
  UPLOAD_ALLOWED_TYPES: z.string().default('image/jpeg,image/png,image/gif,application/pdf'),
  
  // 로깅 설정
  LOG_LEVEL: z.enum(['error', 'warn', 'info', 'http', 'verbose', 'debug', 'silly']).default('info'),
  LOG_DIR: z.string().default('logs'),
  
  // API 키 (외부 서비스용)
  API_KEY: z.string().optional(),
  
  // OpenAI 설정 (향후 사용)
  OPENAI_API_KEY: z.string().optional(),
  OPENAI_ORGANIZATION: z.string().optional(),
  
  // AWS 설정 (향후 사용)
  AWS_ACCESS_KEY_ID: z.string().optional(),
  AWS_SECRET_ACCESS_KEY: z.string().optional(),
  AWS_REGION: z.string().default('ap-northeast-2'),
  AWS_S3_BUCKET: z.string().optional(),
  
  // 기타 설정
  BCRYPT_SALT_ROUNDS: z.string().transform(Number).default('10'),
  SESSION_SECRET: z.string().optional(),
});

/**
 * 환경변수 타입
 */
export type EnvConfig = z.infer<typeof envSchema>;

/**
 * 환경변수 검증 및 파싱
 */
function validateEnv(): EnvConfig {
  try {
    const config = envSchema.parse(process.env);
    
    // JWT_REFRESH_SECRET 필수 검증 - 보안상 독립적인 시크릿 사용 권장
    if (!config.JWT_REFRESH_SECRET) {
      if (config.NODE_ENV === 'production') {
        throw new Error('JWT_REFRESH_SECRET는 프로덕션 환경에서 필수입니다. 보안을 위해 JWT_SECRET과 다른 독립적인 값을 사용하세요.');
      } else {
        // 개발 환경에서만 fallback 허용 (보안 경고 포함)
        config.JWT_REFRESH_SECRET = config.JWT_SECRET + '-refresh-dev-only';
        console.warn('⚠️  보안 경고: JWT_REFRESH_SECRET이 설정되지 않아 fallback을 사용합니다. 프로덕션에서는 독립적인 시크릿을 사용하세요.');
      }
    }
    
    // SESSION_SECRET 필수 검증 - 보안상 독립적인 시크릿 사용 권장  
    if (!config.SESSION_SECRET) {
      if (config.NODE_ENV === 'production') {
        throw new Error('SESSION_SECRET는 프로덕션 환경에서 필수입니다. 보안을 위해 JWT_SECRET과 다른 독립적인 값을 사용하세요.');
      } else {
        // 개발 환경에서만 fallback 허용 (보안 경고 포함)
        config.SESSION_SECRET = config.JWT_SECRET + '-session-dev-only';
        console.warn('⚠️  보안 경고: SESSION_SECRET이 설정되지 않아 fallback을 사용합니다. 프로덕션에서는 독립적인 시크릿을 사용하세요.');
      }
    }
    
    // Logger를 동적으로 import (순환 참조 방지)
    import('../logging/Logger').then(({ Logger: LoggerClass }) => {
      Logger = LoggerClass;
      const logger = new Logger('EnvConfig');
      logger.info('Environment variables validated successfully', {
        NODE_ENV: config.NODE_ENV,
        PORT: config.PORT
      });
    });
    
    return config;
  } catch (error) {
    if (error instanceof z.ZodError) {
      console.error('\n❌ 환경변수 설정 오류:\n');
      error.errors.forEach(err => {
        console.error(`  - ${err.path.join('.')}: ${err.message}`);
      });
      console.error('\n💡 .env.example 파일을 참고하여 .env 파일을 생성해주세요.\n');
    } else {
      console.error('환경변수 로드 실패:', error);
    }
    
    process.exit(1);
  }
}

/**
 * 검증된 환경변수 export
 */
export const config = validateEnv();

/**
 * 환경별 플래그
 */
export const isDevelopment = config.NODE_ENV === 'development';
export const isTest = config.NODE_ENV === 'test';
export const isProduction = config.NODE_ENV === 'production';

/**
 * 데이터베이스 연결 문자열 생성
 */
export function getDatabaseUrl(): string {
  const { DB_USER, DB_PASSWORD, DB_HOST, DB_PORT, DB_NAME, DB_SSL } = config;
  const sslParam = DB_SSL ? '?sslmode=require' : '';
  return `postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}${sslParam}`;
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

/**
 * 환경변수 정보 출력 (민감정보 제외)
 */
export function printEnvInfo(): void {
  console.log('\n📋 환경 설정 정보:');
  console.log(`  - 환경: ${config.NODE_ENV}`);
  console.log(`  - 포트: ${config.PORT}`);
  console.log(`  - API 경로: ${config.API_PREFIX}`);
  console.log(`  - 데이터베이스: ${config.DB_HOST}:${config.DB_PORT}/${config.DB_NAME}`);
  console.log(`  - Redis: ${config.REDIS_HOST}:${config.REDIS_PORT}`);
  console.log(`  - CORS 허용: ${config.CORS_ORIGIN}`);
  console.log(`  - 로그 레벨: ${config.LOG_LEVEL}`);
  console.log('\n');
}