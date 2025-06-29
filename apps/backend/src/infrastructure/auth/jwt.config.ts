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
 */
export const jwtConfig = JwtConfigSchema.parse({
  accessTokenSecret: config.JWT_SECRET || 'your-super-secret-jwt-key-change-this',
  refreshTokenSecret: config.JWT_REFRESH_SECRET || config.JWT_SECRET + '-refresh',
  accessTokenExpiresIn: config.JWT_ACCESS_EXPIRES_IN || '15m',
  refreshTokenExpiresIn: config.JWT_REFRESH_EXPIRES_IN || '7d',
  issuer: 'paperly',
  audience: 'paperly-app',
});

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