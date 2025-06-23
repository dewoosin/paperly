// apps/backend/src/infrastructure/auth/jwt.config.ts

import { z } from 'zod';
import { config } from '../config/environment';

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
 * JWT 설정
 * 
 * 환경 변수에서 JWT 관련 설정을 로드합니다.
 */
export const jwtConfig = JwtConfigSchema.parse({
  accessTokenSecret: config.JWT_SECRET,
  refreshTokenSecret: config.JWT_REFRESH_SECRET || config.JWT_SECRET + '_refresh',
  accessTokenExpiresIn: config.JWT_ACCESS_EXPIRES_IN || '15m',
  refreshTokenExpiresIn: config.JWT_REFRESH_EXPIRES_IN || '7d',
  issuer: 'paperly',
  audience: 'paperly-app',
});

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