// /Users/workspace/paperly/apps/backend/src/domain/auth/auth.types.ts

/**
 * 인증 관련 타입 정의
 */

/**
 * 성별 enum
 */
export enum Gender {
  MALE = 'male',
  FEMALE = 'female',
  OTHER = 'other',
  PREFER_NOT_TO_SAY = 'prefer_not_to_say'
}

/**
 * 회원가입 요청 DTO
 */
export interface RegisterRequest {
  email: string;
  password: string;
  name: string;
  birthDate: string; // ISO 8601 형식
  gender?: Gender;
}

/**
 * 로그인 요청 DTO
 */
export interface LoginRequest {
  email: string;
  password: string;
  deviceInfo?: DeviceInfo;
}

/**
 * 토큰 갱신 요청 DTO
 */
export interface RefreshTokenRequest {
  refreshToken: string;
}

/**
 * 디바이스 정보
 */
export interface DeviceInfo {
  deviceId?: string;
  userAgent?: string;
  ipAddress?: string;
}

/**
 * 인증 응답 DTO
 */
export interface AuthResponse {
  user: UserInfo;
  tokens: TokenPair;
  emailVerificationSent?: boolean;
}

/**
 * 사용자 정보 DTO
 */
export interface UserInfo {
  id: string;
  email: string;
  name: string;
  emailVerified: boolean;
  birthDate: Date;
  gender?: Gender;
}

/**
 * 토큰 쌍
 */
export interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

/**
 * JWT 페이로드
 */
export interface JwtPayload {
  userId: string;
  email: string;
  type: 'access' | 'refresh';
  iat?: number;
  exp?: number;
}

/**
 * 리프레시 토큰 DB 저장 모델
 */
export interface RefreshTokenModel {
  id: string;
  userId: string;
  token: string;
  expiresAt: Date;
  createdAt: Date;
  deviceId?: string;
  userAgent?: string;
  ipAddress?: string;
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

/**
 * 비밀번호 재설정 토큰 모델
 */
export interface PasswordResetToken {
  id: string;
  userId: string;
  token: string;
  expiresAt: Date;
  createdAt: Date;
  usedAt?: Date;
}

/**
 * 로그인 시도 기록
 */
export interface LoginAttempt {
  id: string;
  email: string;
  success: boolean;
  ipAddress?: string;
  userAgent?: string;
  attemptedAt: Date;
}

/**
 * 사용자 세션
 */
export interface UserSession {
  id: string;
  userId: string;
  refreshToken: string;
  deviceInfo?: DeviceInfo;
  lastActiveAt: Date;
  createdAt: Date;
}

/**
 * 인증 컨텍스트
 */
export interface AuthContext {
  userId: string;
  email: string;
  emailVerified: boolean;
  roles?: string[];
  permissions?: string[];
}

/**
 * 인증 요청 헤더
 */
export interface AuthHeaders {
  authorization?: string;
  'x-refresh-token'?: string;
  'x-device-id'?: string;
  'x-client-version'?: string;
}