// /Users/workspace/paperly/apps/backend/src/application/use-cases/auth/refresh-token.use-case.ts

import { inject, injectable } from 'tsyringe';
import { z } from 'zod';
import { IUserRepository } from '../../../infrastructure/repositories/user.repository';
import { JwtService } from '../../../infrastructure/auth/jwt.service';
import { AuthRepository } from '../../../infrastructure/repositories/auth.repository';
import { UserId } from '../../../domain/value-objects/user-id.vo';
import { UnauthorizedError } from '../../../shared/errors';
import { Logger } from '../../../infrastructure/logging/Logger';

/**
 * 토큰 갱신 입력 스키마
 */
const RefreshTokenInputSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token이 필요합니다'),
  deviceInfo: z.object({
    deviceId: z.string().optional(),
    userAgent: z.string().optional(),
    ipAddress: z.string().optional()
  }).optional()
});

export type RefreshTokenInput = z.infer<typeof RefreshTokenInputSchema>;

export interface RefreshTokenOutput {
  tokens: {
    accessToken: string;
    refreshToken: string;
  };
  user: {
    id: string;
    email: string;
    name: string;
    emailVerified: boolean;
  };
}

/**
 * 토큰 갱신 유스케이스
 * 
 * 1. Refresh Token 검증
 * 2. 새로운 토큰 쌍 발급
 * 3. 기존 토큰 무효화
 */
@injectable()
export class RefreshTokenUseCase {
  private readonly logger = new Logger('RefreshTokenUseCase');

  constructor(
    @inject('UserRepository') private userRepository: IUserRepository,
    @inject('TokenService') private tokenService: typeof JwtService
  ) {}

  async execute(input: RefreshTokenInput): Promise<RefreshTokenOutput> {
    // 1. 입력 검증
    const validatedInput = RefreshTokenInputSchema.parse(input);
    
    this.logger.info('토큰 갱신 시도');

    try {
      // 2. Refresh Token 검증
      let decodedToken;
      try {
        decodedToken = this.tokenService.verifyRefreshToken(validatedInput.refreshToken);
      } catch (error) {
        throw new UnauthorizedError('유효하지 않은 Refresh Token입니다');
      }

      // 3. DB에서 토큰 확인
      const savedToken = await AuthRepository.findRefreshToken(validatedInput.refreshToken);
      if (!savedToken) {
        throw new UnauthorizedError('존재하지 않는 토큰입니다');
      }

      // 4. 토큰의 사용자 ID 일치 확인
      if (savedToken.userId !== decodedToken.userId) {
        this.logger.warn('토큰 사용자 ID 불일치', {
          savedUserId: savedToken.userId,
          tokenUserId: decodedToken.userId
        });
        throw new UnauthorizedError('토큰 정보가 일치하지 않습니다');
      }

      // 5. 사용자 조회
      const user = await this.userRepository.findById(UserId.from(decodedToken.userId));
      if (!user) {
        throw new UnauthorizedError('사용자를 찾을 수 없습니다');
      }

      // 6. 새로운 토큰 쌍 생성
      const newTokens = this.tokenService.generateTokenPair(
        user.id.getValue(),
        user.email.getValue()
      );

      // 7. 기존 Refresh Token 삭제
      await AuthRepository.deleteRefreshToken(validatedInput.refreshToken);

      // 8. 새로운 Refresh Token 저장
      const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7일
      await AuthRepository.saveRefreshToken(
        user.id.getValue(),
        newTokens.refreshToken,
        expiresAt,
        validatedInput.deviceInfo?.deviceId || savedToken.deviceId,
        validatedInput.deviceInfo?.userAgent || savedToken.userAgent,
        validatedInput.deviceInfo?.ipAddress || savedToken.ipAddress
      );

      this.logger.info('토큰 갱신 성공', { userId: user.id.getValue() });

      return {
        tokens: newTokens,
        user: {
          id: user.id.getValue(),
          email: user.email.getValue(),
          name: user.name,
          emailVerified: user.emailVerified
        }
      };
    } catch (error) {
      this.logger.error('토큰 갱신 실패', error);
      throw error;
    }
  }
}

/**
 * 로그아웃 입력 스키마
 */
const LogoutInputSchema = z.object({
  refreshToken: z.string().optional(),
  allDevices: z.boolean().default(false),
  userId: z.string().uuid().optional()
});

export type LogoutInput = z.infer<typeof LogoutInputSchema>;

export interface LogoutOutput {
  success: boolean;
  message: string;
}

/**
 * 로그아웃 유스케이스
 */
@injectable()
export class LogoutUseCase {
  private readonly logger = new Logger('LogoutUseCase');

  constructor() {}

  async execute(input: LogoutInput): Promise<LogoutOutput> {
    // 1. 입력 검증
    const validatedInput = LogoutInputSchema.parse(input);
    
    this.logger.info('로그아웃 시도', { 
      allDevices: validatedInput.allDevices,
      userId: validatedInput.userId 
    });

    try {
      if (validatedInput.allDevices && validatedInput.userId) {
        // 모든 디바이스에서 로그아웃
        await AuthRepository.deleteAllUserRefreshTokens(validatedInput.userId);
        
        this.logger.info('모든 디바이스에서 로그아웃 완료', { 
          userId: validatedInput.userId 
        });

        return {
          success: true,
          message: '모든 디바이스에서 로그아웃되었습니다'
        };
      } else if (validatedInput.refreshToken) {
        // 현재 디바이스에서만 로그아웃
        await AuthRepository.deleteRefreshToken(validatedInput.refreshToken);
        
        this.logger.info('로그아웃 완료');

        return {
          success: true,
          message: '로그아웃되었습니다'
        };
      }

      return {
        success: true,
        message: '로그아웃되었습니다'
      };
    } catch (error) {