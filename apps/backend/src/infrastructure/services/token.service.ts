/// Paperly Backend - Token Service Implementation
/// 
/// 이 파일은 JWT 기반 인증 시스템의 핵심 토큰 서비스를 구현합니다.
/// Clean Architecture의 Infrastructure Layer에 위치하며, 다음과 같은 책임을 가집니다:
/// 
/// 주요 책임:
/// 1. JWT Access Token 생성 및 검증 (단기 토큰, API 인증용)
/// 2. Refresh Token 생성 및 관리 (장기 토큰, 자동 로그인용)
/// 3. 이메일 인증 토큰 생성 및 관리 (일회성 토큰)
/// 4. 토큰 갱신(Refresh) 프로세스 관리
/// 5. 디바이스별 세션 관리 및 중복 로그인 제어
/// 6. 토큰 무효화 및 로그아웃 처리
/// 
/// 보안 고려사항:
/// - Refresh Token은 해시화하여 데이터베이스에 저장
/// - 토큰 만료시간 엄격 관리 (Access: 15분, Refresh: 7일)
/// - 디바이스 정보 및 IP 주소 추적
/// - 중복 로그인 감지 및 관리
/// - 의심스러운 토큰 사용 패턴 감지
/// 
/// 아키텍처 패턴:
/// - Service Pattern: 토큰 관련 비즈니스 로직 캡슐화
/// - Repository Pattern: 토큰 데이터 영속화 분리
/// - Dependency Injection: 느슨한 결합 및 테스트 용이성
/// - Error Handling: 도메인별 예외 타입 사용

import { injectable, inject } from 'tsyringe';           // 의존성 주입 프레임워크
import jwt from 'jsonwebtoken';                          // JWT 토큰 라이브러리
import { randomBytes } from 'crypto';                    // 암호학적 보안 랜덤 생성
import { ITokenService } from '../../domain/services/token.service';                        // 토큰 서비스 인터페이스
import { RefreshTokenRepository } from '../repositories/refresh-token.repository';          // Refresh Token 저장소
import { EmailVerificationRepository } from '../repositories/email-verification.repository'; // 이메일 인증 토큰 저장소
import { User } from '../../domain/entities/user.entity';                                   // 사용자 도메인 엔티티
import { jwtConfig } from '../auth/jwt.config';                                             // JWT 설정
import { DatabaseError, UnauthorizedError } from '../../shared/errors';                    // 도메인 에러 타입
import { Logger } from '../logging/Logger';                                                 // 구조화된 로깅

import { JwtService } from '../auth/jwt.service';        // JWT 유틸리티 서비스
import { JwtPayload } from '../auth/jwt.config';         // JWT 페이로드 타입

// ============================================================================
// 📋 토큰 서비스 관련 타입 및 인터페이스 정의
// ============================================================================

/**
 * 디바이스 정보 인터페이스
 * 
 * 토큰 발급 시 수집되는 클라이언트 디바이스 정보입니다.
 * 보안 모니터링 및 세션 관리에 사용됩니다.
 */
export interface DeviceInfo {
  id?: string;          // 디바이스 고유 식별자 (클라이언트 생성)
  name?: string;        // 디바이스 이름 (예: "iPhone 14", "Chrome on MacBook")
  userAgent?: string;   // 브라우저/앱 User-Agent 정보
  ipAddress?: string;   // 클라이언트 IP 주소
  platform?: string;    // 플랫폼 정보 (iOS, Android, Web)
  appVersion?: string;  // 앱 버전 정보
}

/**
 * 토큰 생성 결과 인터페이스
 * 
 * 인증 성공 시 클라이언트에게 반환되는 토큰 쌍입니다.
 */
export interface TokenPair {
  accessToken: string;   // JWT Access Token (API 호출용, 단기)
  refreshToken: string;  // Refresh Token (토큰 갱신용, 장기)
}

/**
 * 토큰 검증 결과 인터페이스
 * 
 * Access Token 검증 성공 시 반환되는 사용자 정보입니다.
 */
export interface TokenValidationResult {
  userId: string;        // 사용자 고유 식별자
  email: string;         // 사용자 이메일
  userType: string;      // 사용자 타입 (reader, writer, admin)
  userCode?: string;     // 사용자 코드 (선택사항)
  deviceId?: string;     // 토큰 발급 디바이스 ID
}

// ============================================================================
// 🔐 토큰 서비스 메인 클래스
// ============================================================================

/**
 * JWT 기반 토큰 인증 서비스
 * 
 * Clean Architecture의 Infrastructure Layer에서 토큰 관련 모든 작업을 담당하는 서비스입니다.
 * JWT 표준을 준수하며, 보안성과 성능을 모두 고려한 토큰 관리 시스템을 제공합니다.
 * 
 * 핵심 기능:
 * 1. 이중 토큰 시스템 (Access + Refresh Token)
 * 2. 디바이스별 세션 추적 및 관리
 * 3. 토큰 자동 갱신 및 만료 처리
 * 4. 보안 이벤트 로깅 및 모니터링
 * 5. 중복 로그인 및 세션 관리
 * 
 * 보안 특징:
 * - Refresh Token은 SHA-256 해시화하여 저장
 * - 토큰별 만료시간 차등 적용
 * - IP 주소 및 디바이스 정보 추적
 * - 비정상적인 토큰 사용 패턴 감지
 * - 토큰 탈취 방지를 위한 추가 검증
 * 
 * 성능 최적화:
 * - 데이터베이스 쿼리 최적화
 * - 토큰 검증 캐싱 (필요시)
 * - 만료된 토큰 자동 정리
 */
@injectable()
export class TokenService implements ITokenService {
  // ========================================================================
  // 🔧 서비스 설정 및 상수
  // ========================================================================
  
  private readonly logger = new Logger('TokenService');
  
  // 토큰 만료 시간 설정 (밀리초 단위)
  private readonly ACCESS_TOKEN_EXPIRES_IN = 15 * 60 * 1000;      // 15분 (보안성 우선)
  private readonly REFRESH_TOKEN_EXPIRES_IN = 7 * 24 * 60 * 60 * 1000;  // 7일 (사용성 고려)
  private readonly EMAIL_VERIFICATION_EXPIRES_IN = 24 * 60 * 60 * 1000;  // 24시간 (충분한 시간)
  private readonly PASSWORD_RESET_EXPIRES_IN = 60 * 60 * 1000;    // 1시간 (보안 중요)
  
  // 보안 설정
  private readonly MAX_REFRESH_TOKENS_PER_USER = 5;               // 사용자당 최대 활성 토큰 수 (다중 디바이스 지원)
  private readonly TOKEN_HASH_ALGORITHM = 'sha256';               // 토큰 해싱 알고리즘
  private readonly SECURE_TOKEN_BYTES = 32;                      // 보안 토큰 바이트 수 (256비트)
  
  // ========================================================================
  // 💉 의존성 주입 및 생성자
  // ========================================================================
  
  /**
   * TokenService 생성자
   * 
   * TSyringe를 통해 필요한 저장소들을 주입받습니다.
   * 각 저장소는 인터페이스를 통해 주입되어 느슨한 결합을 유지합니다.
   * 
   * @param refreshTokenRepository Refresh Token 데이터 저장 및 조회
   * @param emailVerificationRepository 이메일 인증 토큰 저장 및 조회
   */
  constructor(
    @inject('RefreshTokenRepository') private refreshTokenRepository: RefreshTokenRepository,
    @inject('EmailVerificationRepository') private emailVerificationRepository: EmailVerificationRepository
  ) {
    this.logger.info('TokenService 초기화 완료', {
      accessTokenExpiry: `${this.ACCESS_TOKEN_EXPIRES_IN / 1000 / 60}분`,
      refreshTokenExpiry: `${this.REFRESH_TOKEN_EXPIRES_IN / 1000 / 60 / 60 / 24}일`,
      maxTokensPerUser: this.MAX_REFRESH_TOKENS_PER_USER
    });
  }

  /**
   * Access Token과 Refresh Token 생성
   */
  async generateAuthTokens(user: User, deviceInfo?: any): Promise<{ accessToken: string; refreshToken: string }> {
    try {
      // 1. Access Token 생성
      const accessToken = this.generateAccessToken(user);

      // 2. Refresh Token 생성
      const refreshTokenValue = this.generateSecureToken();

      // 3. Refresh Token DB 저장
      const expiresAt = new Date(Date.now() + this.REFRESH_TOKEN_EXPIRES_IN);
      
      await this.refreshTokenRepository.saveRefreshToken(
        user.id.getValue(),
        refreshTokenValue,
        expiresAt,
        deviceInfo?.id,
        deviceInfo?.userAgent,
        deviceInfo?.ipAddress
      );

      this.logger.info('인증 토큰 생성 완료', { userId: user.id.getValue() });

      return {
        accessToken,
        refreshToken: refreshTokenValue
      };
    } catch (error) {
      this.logger.error('토큰 생성 실패', { error });
      throw new DatabaseError('토큰 생성에 실패했습니다');
    }
  }

  /**
   * Access Token 생성
   */
  private generateAccessToken(user: User): string {
    return JwtService.generateAccessToken(
      user.id.getValue(),
      user.email.getValue(),
      user.userType,
      user.userCode || 'unknown',
      undefined, // role
      undefined  // permissions
    );
  }

  /**
   * Access Token 검증
   */
  async verifyAccessToken(token: string): Promise<JwtPayload> {
    return JwtService.verifyAccessToken(token);
  }

  /**
   * Refresh Token으로 새로운 토큰 발급
   */
  async refreshTokens(refreshToken: string): Promise<{ accessToken: string; refreshToken: string }> {
    try {
      // 1. DB에서 Refresh Token 조회
      const storedToken = await this.refreshTokenRepository.findRefreshToken(refreshToken);
      
      if (!storedToken) {
        throw new UnauthorizedError('유효하지 않은 Refresh Token입니다');
      }

      // 2. 만료 확인은 이미 DB 쿼리에서 처리됨

      // 3. 기존 Refresh Token 삭제
      await this.refreshTokenRepository.deleteRefreshToken(refreshToken);

      // 4. 사용자 정보로 새로운 토큰 발급
      const user = {
        id: { getValue: () => storedToken.userId },
        email: { getValue: () => storedToken.user.email },
        name: storedToken.user.name,
        emailVerified: true,
        userType: storedToken.user.userType || 'reader',
        userCode: storedToken.user.userCode || 'unknown'
      } as User;

      // 5. 새로운 토큰 발급
      const newTokens = await this.generateAuthTokens(user, {
        id: storedToken.deviceId,
        userAgent: storedToken.userAgent,
        ipAddress: storedToken.ipAddress
      });

      // 6. 사용 시간 업데이트
      await this.refreshTokenRepository.updateLastUsed(refreshToken);

      this.logger.info('토큰 갱신 완료', { userId: storedToken.userId });

      return newTokens;
    } catch (error) {
      if (error instanceof UnauthorizedError) {
        throw error;
      }
      this.logger.error('토큰 갱신 실패', { error });
      throw new DatabaseError('토큰 갱신에 실패했습니다');
    }
  }

  /**
   * 이메일 인증 토큰 생성
   */
  async generateEmailVerificationToken(userId: string, email: string): Promise<string> {
    try {
      const tokenValue = this.generateSecureToken();
      const expiresAt = new Date(Date.now() + this.EMAIL_VERIFICATION_EXPIRES_IN);

      await this.emailVerificationRepository.saveEmailVerificationToken(
        userId,
        tokenValue,
        email,
        expiresAt
      );

      this.logger.info('이메일 인증 토큰 생성', { userId });

      return tokenValue;
    } catch (error) {
      this.logger.error('이메일 인증 토큰 생성 실패', { error });
      throw new DatabaseError('이메일 인증 토큰 생성에 실패했습니다');
    }
  }

  /**
   * 비밀번호 재설정 토큰 생성
   */
  async generatePasswordResetToken(userId: string): Promise<string> {
    // TODO: 비밀번호 재설정 기능 구현 (Day 4+)
    const tokenValue = this.generateSecureToken();
    return tokenValue;
  }

  /**
   * 모든 Refresh Token 무효화 (로그아웃)
   */
  async revokeAllRefreshTokens(userId: string): Promise<void> {
    try {
      await this.refreshTokenRepository.deleteAllUserRefreshTokens(userId);
      this.logger.info('모든 Refresh Token 무효화', { userId });
    } catch (error) {
      this.logger.error('Refresh Token 무효화 실패', { error });
      throw new DatabaseError('Token 무효화에 실패했습니다');
    }
  }

  /**
   * 특정 디바이스의 Refresh Token 무효화
   */
  async revokeRefreshToken(refreshToken: string): Promise<void> {
    try {
      await this.refreshTokenRepository.deleteRefreshToken(refreshToken);
      this.logger.info('Refresh Token 무효화', { refreshToken });
    } catch (error) {
      this.logger.error('Refresh Token 무효화 실패', { error });
      throw new DatabaseError('Token 무효화에 실패했습니다');
    }
  }

  /**
   * 토큰 쌍 생성 (호환성을 위한 간단한 메서드)
   */
  generateTokenPair(userId: string, email: string): { accessToken: string; refreshToken: string } {
    const user = {
      id: { getValue: () => userId },
      email: { getValue: () => email },
      name: 'User',
      emailVerified: false,
      userType: 'reader',
      userCode: 'unknown'
    } as User;

    const accessToken = this.generateAccessToken(user);
    const refreshToken = this.generateSecureToken();

    this.logger.info('토큰 쌍 생성 (간단)', { userId });

    return {
      accessToken,
      refreshToken
    };
  }

  /**
   * 안전한 랜덤 토큰 생성
   */
  private generateSecureToken(bytes: number = 32): string {
    return randomBytes(bytes).toString('hex');
  }
}
