// apps/backend/src/domain/auth/auth.types.ts

import { z } from 'zod';

/**
 * 성별 열거형
 */
export enum Gender {
  MALE = 'male',
  FEMALE = 'female',
  OTHER = 'other',
  PREFER_NOT_TO_SAY = 'prefer_not_to_say',
}

/**
 * 회원가입 요청 스키마
 */
export const RegisterRequestSchema = z.object({
  email: z.string().email('올바른 이메일 형식이 아닙니다'),
  password: z.string().min(8, '비밀번호는 최소 8자 이상이어야 합니다'),
  name: z.string().min(1, '이름을 입력해주세요').max(50, '이름은 50자 이하여야 합니다'),
  birthDate: z.string().datetime({ message: '올바른 날짜 형식이 아닙니다' }),
  gender: z.nativeEnum(Gender).optional(),
});

export type RegisterRequest = z.infer<typeof RegisterRequestSchema>;

/**
 * 로그인 요청 스키마
 */
export const LoginRequestSchema = z.object({
  email: z.string().email('올바른 이메일 형식이 아닙니다'),
  password: z.string().min(1, '비밀번호를 입력해주세요'),
});

export type LoginRequest = z.infer<typeof LoginRequestSchema>;

/**
 * 토큰 갱신 요청 스키마
 */
export const RefreshTokenRequestSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token을 입력해주세요'),
});

export type RefreshTokenRequest = z.infer<typeof RefreshTokenRequestSchema>;

/**
 * 로그아웃 요청 스키마
 */
export const LogoutRequestSchema = z.object({
  refreshToken: z.string().optional(),
  allDevices: z.boolean().default(false),
});

export type LogoutRequest = z.infer<typeof LogoutRequestSchema>;

/**
 * 이메일 인증 토큰 검증 스키마
 */
export const VerifyEmailRequestSchema = z.object({
  token: z.string().min(1, '인증 토큰을 입력해주세요'),
});

export type VerifyEmailRequest = z.infer<typeof VerifyEmailRequestSchema>;

/**
 * 인증 토큰 응답
 */
export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

/**
 * 인증 응답
 */
export interface AuthResponse {
  user: {
    id: string;
    email: string;
    name: string;
    emailVerified: boolean;
    birthDate?: Date;
    gender?: Gender;
  };
  tokens: AuthTokens;
  emailVerificationSent?: boolean;
}

/**
 * Refresh Token 저장 모델
 */
export interface RefreshTokenModel {
  id: string;
  userId: string;
  token: string;
  deviceId?: string;
  userAgent?: string;
  ipAddress?: string;
  expiresAt: Date;
  createdAt: Date;
}

/**
 * 이메일 인증 토큰 모델
 */
export interface EmailVerificationToken {
  id: string;
  userId: string;
  token: string;
  expiresAt: Date;
  createdAt: Date;
}