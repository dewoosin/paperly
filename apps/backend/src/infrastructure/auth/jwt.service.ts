// apps/backend/src/infrastructure/auth/jwt.service.ts

import jwt from 'jsonwebtoken';
import { jwtConfig, JwtPayload, DecodedToken } from './jwt.config';
import { UnauthorizedError } from '../../shared/errors';
import { logger } from '../logging/logger';

/**
 * JWT 토큰 서비스
 * 
 * JWT 토큰의 생성, 검증, 갱신을 담당합니다.
 */
export class JwtService {
  /**
   * Access Token 생성
   * 
   * @param userId - 사용자 ID
   * @param email - 사용자 이메일
   * @returns 생성된 access token
   */
  static generateAccessToken(userId: string, email: string): string {
    const payload: JwtPayload = {
      userId,
      email,
      type: 'access',
    };

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
   * @returns 생성된 refresh token
   */
  static generateRefreshToken(userId: string, email: string): string {
    const payload: JwtPayload = {
      userId,
      email,
      type: 'refresh',
    };

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
   * @returns 토큰 쌍
   */
  static generateTokenPair(userId: string, email: string): {
    accessToken: string;
    refreshToken: string;
  } {
    return {
      accessToken: this.generateAccessToken(userId, email),
      refreshToken: this.generateRefreshToken(userId, email),
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
   * 토큰에서 Bearer 접두사 제거
   * 
   * @param authHeader - Authorization 헤더 값
   * @returns 토큰 문자열
   */
  static extractTokenFromHeader(authHeader?: string): string | null {
    if (!authHeader) return null;
    
    const parts = authHeader.split(' ');
    if (parts.length !== 2 || parts[0] !== 'Bearer') {
      return null;
    }
    
    return parts[1];
  }

  /**
   * 토큰 만료까지 남은 시간 계산 (초 단위)
   * 
   * @param token - 토큰
   * @returns 남은 시간 (초)
   */
  static getTokenRemainingTime(token: DecodedToken): number {
    const now = Math.floor(Date.now() / 1000);
    return Math.max(0, token.exp - now);
  }

  /**
   * 토큰 정보 로깅 (디버깅용)
   * 
   * @param token - 토큰
   * @param label - 로그 라벨
   */
  static logTokenInfo(token: DecodedToken, label: string = 'Token'): void {
    const remainingTime = this.getTokenRemainingTime(token);
    const remainingMinutes = Math.floor(remainingTime / 60);
    
    logger.debug(`${label} Info:`, {
      userId: token.userId,
      type: token.type,
      remainingTime: `${remainingMinutes}m ${remainingTime % 60}s`,
      expiresAt: new Date(token.exp * 1000).toISOString(),
    });
  }
}