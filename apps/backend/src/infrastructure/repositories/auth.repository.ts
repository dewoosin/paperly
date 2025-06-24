// /Users/workspace/paperly/apps/backend/src/infrastructure/auth/jwt.config.ts

import { config } from '../config/env.config';

/**
 * JWT 설정
 * 
 * JWT 토큰 생성 및 검증에 필요한 설정값들을 정의합니다.
 */

/**
 * JWT 페이로드 타입
 */
export interface JwtPayload {
  userId: string;
  email: string;
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
 * JWT 설정값
 */
export const jwtConfig = {
  // Access Token 설정
  accessTokenSecret: config.JWT_SECRET || 'your-super-secret-jwt-key-change-this',
  accessTokenExpiresIn: '15m', // 15분
  
  // Refresh Token 설정
  refreshTokenSecret: config.JWT_REFRESH_SECRET || config.JWT_SECRET + '-refresh',
  refreshTokenExpiresIn: '7d', // 7일
  
  // 공통 설정
  issuer: 'paperly-api',
  audience: 'paperly-client',
  
  // 알고리즘
  algorithm: 'HS256' as const,
};

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