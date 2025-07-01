// /Users/workspace/paperly/apps/backend/src/application/use-cases/auth/refresh-token.use-case.ts

import { inject, injectable } from 'tsyringe';
import { z } from 'zod';
import { IUserRepository } from '../../../infrastructure/repositories/user.repository';
import { AuthRepository } from '../../../infrastructure/repositories/auth.repository';
import { UserId } from '../../../domain/value-objects/user-id.vo';
import { UnauthorizedError } from '../../../shared/errors';
import { Logger } from '../../../infrastructure/logging/Logger';
import { SecurityValidator, FieldType, InputContext } from '../../../infrastructure/security/validators';
import { SecuritySanitizer, SanitizationContext, SQLSanitizationContext } from '../../../infrastructure/security/sanitizers';
import { MESSAGE_CODES } from '../../../shared/constants/message-codes';

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
    @inject('TokenService') private tokenService: any,
    @inject(AuthRepository) private authRepository: AuthRepository
  ) {}

  async execute(input: RefreshTokenInput): Promise<RefreshTokenOutput> {
    // 1. 입력 데이터 보안 검증
    const securityValidation = SecurityValidator.validateAll(JSON.stringify(input), {
      fieldType: FieldType.TEXT,
      inputContext: InputContext.USER_INPUT,
      fieldName: 'refreshTokenInput'
    });

    if (!securityValidation.isValid) {
      this.logger.warn('토큰 갱신 입력 보안 위협 감지', {
        threats: securityValidation.xssResult.threats.concat(
          securityValidation.sqlResult.threats,
          securityValidation.pathResult.threats
        ),
        severity: securityValidation.overallSeverity
      });
      throw new UnauthorizedError('입력 데이터에 보안 위협이 감지되었습니다', undefined, MESSAGE_CODES.SECURITY.SUSPICIOUS_ACTIVITY);
    }

    // 개별 필드별 보안 검증 및 새니타이징
    const sanitizedInput = {
      refreshToken: SecuritySanitizer.sanitizeAll(input.refreshToken, {
        htmlContext: SanitizationContext.PLAIN_TEXT,
        sqlContext: SQLSanitizationContext.STRING_LITERAL,
        fieldName: 'refreshToken'
      }).finalValue,
      deviceInfo: input.deviceInfo ? {
        deviceId: input.deviceInfo.deviceId ? SecuritySanitizer.sanitizeAll(input.deviceInfo.deviceId, {
          htmlContext: SanitizationContext.PLAIN_TEXT,
          sqlContext: SQLSanitizationContext.STRING_LITERAL,
          fieldName: 'deviceId'
        }).finalValue : undefined,
        userAgent: input.deviceInfo.userAgent ? SecuritySanitizer.sanitizeAll(input.deviceInfo.userAgent, {
          htmlContext: SanitizationContext.PLAIN_TEXT,
          sqlContext: SQLSanitizationContext.STRING_LITERAL,
          fieldName: 'userAgent'
        }).finalValue : undefined,
        ipAddress: input.deviceInfo.ipAddress ? SecuritySanitizer.sanitizeAll(input.deviceInfo.ipAddress, {
          htmlContext: SanitizationContext.PLAIN_TEXT,
          sqlContext: SQLSanitizationContext.STRING_LITERAL,
          fieldName: 'ipAddress'
        }).finalValue : undefined
      } : undefined
    };

    // 2. 입력 검증
    const validatedInput = RefreshTokenInputSchema.parse(sanitizedInput);
    
    this.logger.info('토큰 갱신 시도', { securityCheck: 'passed' });

    try {
      // 3. Refresh Token 검증
      let decodedToken;
      try {
        decodedToken = this.tokenService.verifyRefreshToken(validatedInput.refreshToken);
      } catch (tokenError) {
        throw new UnauthorizedError('유효하지 않은 Refresh Token입니다', undefined, MESSAGE_CODES.AUTH.INVALID_REFRESH_TOKEN);
      }

      // 4. DB에서 토큰 확인
      const savedToken = await this.authRepository.findRefreshToken(validatedInput.refreshToken);
      if (!savedToken) {
        throw new UnauthorizedError('존재하지 않는 토큰입니다', undefined, MESSAGE_CODES.AUTH.INVALID_REFRESH_TOKEN);
      }

      // 5. 토큰의 사용자 ID 일치 확인
      if (savedToken.userId !== decodedToken.userId) {
        this.logger.warn('토큰 사용자 ID 불일치', {
          savedUserId: savedToken.userId,
          tokenUserId: decodedToken.userId
        });
        throw new UnauthorizedError('토큰 정보가 일치하지 않습니다', undefined, MESSAGE_CODES.AUTH.INVALID_TOKEN);
      }

      // 6. 사용자 조회
      const user = await this.userRepository.findById(UserId.from(decodedToken.userId));
      if (!user) {
        throw new UnauthorizedError('사용자를 찾을 수 없습니다', undefined, MESSAGE_CODES.USER.NOT_FOUND);
      }

      // 7. 새로운 토큰 쌍 생성
      const newTokens = this.tokenService.generateTokenPair(
        user.id.getValue(),
        user.email.getValue()
      );

      // 8. 기존 Refresh Token 삭제
      await this.authRepository.deleteRefreshToken(validatedInput.refreshToken);

      // 9. 새로운 Refresh Token 저장
      const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7일
      await this.authRepository.saveRefreshToken(
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

  constructor(
    @inject(AuthRepository) private authRepository: AuthRepository
  ) {}

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
        await this.authRepository.deleteAllUserRefreshTokens(validatedInput.userId);
        
        this.logger.info('모든 디바이스에서 로그아웃 완료', { 
          userId: validatedInput.userId 
        });

        return {
          success: true,
          message: '모든 디바이스에서 로그아웃되었습니다'
        };
      } else if (validatedInput.refreshToken) {
        // 현재 디바이스에서만 로그아웃
        await this.authRepository.deleteRefreshToken(validatedInput.refreshToken);
        
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
      this.logger.error('로그아웃 실패', error);
      // 로그아웃은 실패해도 성공으로 처리
      return {
        success: true,
        message: '로그아웃되었습니다'
      };
    }
  }
}