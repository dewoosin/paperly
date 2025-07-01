// apps/backend/src/infrastructure/auth/jwt.config.ts

import { z } from 'zod';
import { config } from '../config/env.config';

/**
 * JWT 설정 스키마
 */
const JwtConfigSchema = z.object({
  accessTokenSecret: z.string().min(32),
  refreshTokenSecret: z.string().min(32),
  accessTokenExpiresIn: z.string().default('15m'),
  refreshTokenExpiresIn: z.string().default('7d'),
  issuer: z.string().default('paperly'),
  audience: z.string().default('paperly-app'),
});

/**
 * JWT 페이로드 타입
 */
export interface JwtPayload {
  userId: string;
  email: string;
  userType: string;
  userCode: string;
  role?: string;
  permissions?: string[];
  type: 'access' | 'refresh';
  iat?: number;
  exp?: number;
  iss?: string;
  aud?: string;
}

/**
 * 디코딩된 토큰 타입
 */
export interface DecodedToken extends JwtPayload {
  iat: number;
  exp: number;
  iss: string;
  aud: string;
}

/**
 * JWT 설정
 * 
 * 환경 변수에서 JWT 관련 설정을 로드합니다.
 * 보안상 중요한 secret들은 환경 변수가 필수이며, fallback을 제공하지 않습니다.
 */
function createJwtConfig() {
  // 프로덕션 환경에서는 JWT_SECRET이 필수
  if (config.NODE_ENV === 'production' && !config.JWT_SECRET) {
    throw new Error('JWT_SECRET 환경 변수는 프로덕션에서 필수입니다. 보안을 위해 안전한 임의의 값을 설정하세요.');
  }
  
  // 개발 환경에서도 JWT_SECRET 누락 시 경고
  if (!config.JWT_SECRET) {
    console.warn('⚠️  보안 경고: JWT_SECRET 환경 변수가 설정되지 않았습니다. 개발 환경에서도 안전한 값을 사용하는 것을 권장합니다.');
  }
  
  return JwtConfigSchema.parse({
    // JWT_SECRET이 없으면 애플리케이션이 실패하도록 함 (보안 강화)
    accessTokenSecret: config.JWT_SECRET || (() => {
      throw new Error('JWT_SECRET 환경 변수가 설정되지 않았습니다. .env 파일에 안전한 32자 이상의 시크릿을 설정하세요.');
    })(),
    
    // JWT_REFRESH_SECRET은 env.config.ts에서 이미 검증됨
    refreshTokenSecret: config.JWT_REFRESH_SECRET,
    
    accessTokenExpiresIn: config.JWT_ACCESS_EXPIRES_IN || '15m',
    refreshTokenExpiresIn: config.JWT_REFRESH_EXPIRES_IN || '7d',
    issuer: 'paperly',
    audience: 'paperly-app',
  });
}

export const jwtConfig = createJwtConfig();

/**
 * 토큰 만료 시간 계산 헬퍼
 */
export const tokenExpiryTimes = {
  // Access Token: 15분 (밀리초)
  accessToken: 15 * 60 * 1000,
  
  // Refresh Token: 7일 (밀리초)
  refreshToken: 7 * 24 * 60 * 60 * 1000,
  
  // Email Verification Token: 24시간 (밀리초)
  emailVerification: 24 * 60 * 60 * 1000,
  
  // Password Reset Token: 1시간 (밀리초)
  passwordReset: 60 * 60 * 1000,
};

/**
 * 토큰 타입별 시크릿 키 가져오기
 */
export function getTokenSecret(type: 'access' | 'refresh'): string {
  return type === 'access' 
    ? jwtConfig.accessTokenSecret 
    : jwtConfig.refreshTokenSecret;
}

/**
 * 토큰 타입별 만료 시간 가져오기
 */
export function getTokenExpiresIn(type: 'access' | 'refresh'): string {
  return type === 'access'
    ? jwtConfig.accessTokenExpiresIn
    : jwtConfig.refreshTokenExpiresIn;
}

/**
 * 환경별 쿠키 설정
 */
export const cookieConfig = {
  httpOnly: true,
  secure: config.NODE_ENV === 'production',
  sameSite: 'strict' as const,
  maxAge: tokenExpiryTimes.refreshToken,
  path: '/',
};

/**
 * CORS에서 허용할 헤더
 */
export const allowedHeaders = [
  'Authorization',
  'X-Refresh-Token',
  'X-Device-Id',
  'X-Client-Version',
];

/**
 * 토큰 블랙리스트 TTL (Redis)
 */
export const blacklistTTL = {
  // Access Token 블랙리스트: 토큰 만료 시간 + 1시간
  accessToken: tokenExpiryTimes.accessToken + (60 * 60 * 1000),
  
  // Refresh Token 블랙리스트: 토큰 만료 시간 + 1일
  refreshToken: tokenExpiryTimes.refreshToken + (24 * 60 * 60 * 1000),
};

/**
 * 알고리즘 설정
 */
export const algorithm = 'HS256' as const;