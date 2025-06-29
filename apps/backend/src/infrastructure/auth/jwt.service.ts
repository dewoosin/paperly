// /Users/workspace/paperly/apps/backend/src/infrastructure/auth/jwt.service.ts

import jwt from 'jsonwebtoken';
import { jwtConfig, JwtPayload, DecodedToken } from './jwt.config';
import { UnauthorizedError } from '../../shared/errors';
import { Logger } from '../logging/Logger';

/**
 * JWT 토큰 서비스
 * 
 * JWT 토큰의 생성, 검증, 갱신을 담당합니다.
 */
export class JwtService {
  private static readonly logger = new Logger('JwtService');

  /**
   * Access Token 생성
   * 
   * @param userId - 사용자 ID
   * @param email - 사용자 이메일
   * @param userType - 사용자 타입 (reader/writer/admin)
   * @param userCode - 사용자 코드 (RD0001, WR0001 등)
   * @param role - 사용자 역할 (선택사항)
   * @param permissions - 사용자 권한 목록 (선택사항)
   * @returns 생성된 access token
   */
  static generateAccessToken(
    userId: string, 
    email: string, 
    userType: string,
    userCode: string,
    role?: string, 
    permissions?: string[]
  ): string {
    const payload: JwtPayload = {
      userId,
      email,
      userType,
      userCode,
      type: 'access',
    };

    if (role) {
      payload.role = role;
    }

    if (permissions && permissions.length > 0) {
      payload.permissions = permissions;
    }

    return jwt.sign(payload, jwtConfig.accessTokenSecret, {
      expiresIn: jwtConfig.accessTokenExpiresIn,
      issuer: jwtConfig.issuer,
      audience: jwtConfig.audience,
    });
  }

  /**
   * Refresh Token 생성
   * 
   * @param userId - 사용자 ID
   * @param email - 사용자 이메일
   * @param userType - 사용자 타입 (reader/writer/admin)
   * @param userCode - 사용자 코드 (RD0001, WR0001 등)
   * @param role - 사용자 역할 (선택사항)
   * @param permissions - 사용자 권한 목록 (선택사항)
   * @returns 생성된 refresh token
   */
  static generateRefreshToken(
    userId: string, 
    email: string, 
    userType: string,
    userCode: string,
    role?: string, 
    permissions?: string[]
  ): string {
    const payload: JwtPayload = {
      userId,
      email,
      userType,
      userCode,
      type: 'refresh',
    };

    if (role) {
      payload.role = role;
    }

    if (permissions && permissions.length > 0) {
      payload.permissions = permissions;
    }

    return jwt.sign(payload, jwtConfig.refreshTokenSecret, {
      expiresIn: jwtConfig.refreshTokenExpiresIn,
      issuer: jwtConfig.issuer,
      audience: jwtConfig.audience,
    });
  }

  /**
   * Access Token과 Refresh Token 쌍 생성
   * 
   * @param userId - 사용자 ID
   * @param email - 사용자 이메일
   * @param userType - 사용자 타입 (reader/writer/admin)
   * @param userCode - 사용자 코드 (RD0001, WR0001 등)
   * @param role - 사용자 역할 (선택사항)
   * @param permissions - 사용자 권한 목록 (선택사항)
   * @returns 토큰 쌍
   */
  static generateTokenPair(
    userId: string, 
    email: string, 
    userType: string,
    userCode: string,
    role?: string, 
    permissions?: string[]
  ): {
    accessToken: string;
    refreshToken: string;
  } {
    return {
      accessToken: this.generateAccessToken(userId, email, userType, userCode, role, permissions),
      refreshToken: this.generateRefreshToken(userId, email, userType, userCode, role, permissions),
    };
  }

  /**
   * Access Token 검증
   * 
   * @param token - 검증할 토큰
   * @returns 디코딩된 토큰 정보
   * @throws UnauthorizedError - 토큰이 유효하지 않은 경우
   */
  static verifyAccessToken(token: string): DecodedToken {
    try {
      const decoded = jwt.verify(token, jwtConfig.accessTokenSecret, {
        issuer: jwtConfig.issuer,
        audience: jwtConfig.audience,
      }) as DecodedToken;

      if (decoded.type !== 'access') {
        throw new UnauthorizedError('Invalid token type');
      }

      return decoded;
    } catch (error) {
      if (error instanceof jwt.TokenExpiredError) {
        throw new UnauthorizedError('Token expired');
      }
      if (error instanceof jwt.JsonWebTokenError) {
        throw new UnauthorizedError('Invalid token');
      }
      throw error;
    }
  }

  /**
   * Refresh Token 검증
   * 
   * @param token - 검증할 토큰
   * @returns 디코딩된 토큰 정보
   * @throws UnauthorizedError - 토큰이 유효하지 않은 경우
   */
  static verifyRefreshToken(token: string): DecodedToken {
    try {
      const decoded = jwt.verify(token, jwtConfig.refreshTokenSecret, {
        issuer: jwtConfig.issuer,
        audience: jwtConfig.audience,
      }) as DecodedToken;

      if (decoded.type !== 'refresh') {
        throw new UnauthorizedError('Invalid token type');
      }

      return decoded;
    } catch (error) {
      if (error instanceof jwt.TokenExpiredError) {
        throw new UnauthorizedError('Refresh token expired');
      }
      if (error instanceof jwt.JsonWebTokenError) {
        throw new UnauthorizedError('Invalid refresh token');
      }
      throw error;
    }
  }

  /**
   * 토큰에서 페이로드 추출 (검증 없이)
   * 
   * @param token - 토큰
   * @returns 페이로드 또는 null
   */
  static decode(token: string): JwtPayload | null {
    try {
      return jwt.decode(token) as JwtPayload;
    } catch {
      return null;
    }
  }

  /**
   * 토큰 만료 시간 확인
   * 
   * @param token - 확인할 토큰
   * @returns 만료 시간 (Unix timestamp) 또는 null
   */
  static getExpirationTime(token: string): number | null {
    const decoded = this.decode(token);
    return decoded?.exp || null;
  }

  /**
   * 토큰이 만료되었는지 확인
   * 
   * @param token - 확인할 토큰
   * @returns 만료 여부
   */
  static isExpired(token: string): boolean {
    const exp = this.getExpirationTime(token);
    if (!exp) return true;
    
    return Date.now() >= exp * 1000;
  }

  /**
   * 토큰 남은 유효 시간 계산 (초)
   * 
   * @param token - 확인할 토큰
   * @returns 남은 시간 (초) 또는 0
   */
  static getTimeToExpiry(token: string): number {
    const exp = this.getExpirationTime(token);
    if (!exp) return 0;
    
    const remaining = (exp * 1000) - Date.now();
    return Math.max(0, Math.floor(remaining / 1000));
  }

  /**
   * 토큰 서명 검증 (페이로드 검증 없이)
   * 
   * @param token - 검증할 토큰
   * @param type - 토큰 타입
   * @returns 서명 유효 여부
   */
  static isValidSignature(token: string, type: 'access' | 'refresh'): boolean {
    try {
      const secret = type === 'access' 
        ? jwtConfig.accessTokenSecret 
        : jwtConfig.refreshTokenSecret;
      
      jwt.verify(token, secret, {
        ignoreExpiration: true,
        issuer: jwtConfig.issuer,
        audience: jwtConfig.audience,
      });
      
      return true;
    } catch {
      return false;
    }
  }
}