// apps/backend/src/application/use-cases/auth/login.use-case.ts

import { inject, injectable } from 'tsyringe';
import { z } from 'zod';
import { UseCase } from '../../../shared/application/use-case';
import { IUserRepository } from '../../../domain/repositories/user.repository';
import { ITokenService } from '../../../domain/services/token.service';
import { ILoginAttemptRepository } from '../../../domain/repositories/login-attempt.repository';
import { Email, Password, DeviceInfo } from '../../../domain/value-objects/auth.value-objects';
import { AppError, ErrorCode } from '../../../shared/errors/app-error';
import { logger } from '../../../infrastructure/logging/logger';

const LoginInputSchema = z.object({
  email: z.string().email(),
  password: z.string(),
  deviceId: z.string(),
  userAgent: z.string(),
  ipAddress: z.string().optional()
});

export type LoginInput = z.infer<typeof LoginInputSchema>;

export interface LoginOutput {
  user: {
    id: string;
    email: string;
    name: string;
    emailVerified: boolean;
  };
  tokens: {
    accessToken: string;
    refreshToken: string;
  };
}

/**
 * 로그인 유스케이스
 * 
 * 1. 입력 검증
 * 2. 사용자 조회
 * 3. 비밀번호 확인
 * 4. 계정 잠금 확인
 * 5. 토큰 발급
 * 6. 로그인 기록
 */
@injectable()
export class LoginUseCase implements UseCase<LoginInput, LoginOutput> {
  private static readonly MAX_LOGIN_ATTEMPTS = 5;
  private static readonly LOCK_DURATION_MINUTES = 30;

  constructor(
    @inject('UserRepository') private userRepository: IUserRepository,
    @inject('TokenService') private tokenService: ITokenService,
    @inject('LoginAttemptRepository') private loginAttemptRepository: ILoginAttemptRepository
  ) {}

  async execute(input: LoginInput): Promise<LoginOutput> {
    const validatedInput = LoginInputSchema.parse(input);
    
    logger.info('로그인 시도', { email: validatedInput.email });

    try {
      const email = Email.create(validatedInput.email);
      const deviceInfo = DeviceInfo.create(validatedInput.deviceId, validatedInput.userAgent);

      // 1. 사용자 조회
      const user = await this.userRepository.findByEmail(email);
      
      // 로그인 시도 기록 (성공/실패 여부와 관계없이)
      const loginAttempt = {
        email: email.value,
        ipAddress: validatedInput.ipAddress,
        userAgent: validatedInput.userAgent,
        success: false,
        failureReason: null as string | null
      };

      if (!user) {
        // 보안을 위해 구체적인 에러 메시지는 숨김
        loginAttempt.failureReason = 'user_not_found';
        await this.loginAttemptRepository.create(loginAttempt);
        
        throw new AppError(
          ErrorCode.UNAUTHORIZED,
          '이메일 또는 비밀번호가 올바르지 않습니다'
        );
      }

      // 2. 계정 잠금 확인
      if (user.isLocked()) {
        loginAttempt.failureReason = 'account_locked';
        await this.loginAttemptRepository.create(loginAttempt);
        
        const remainingMinutes = user.getRemainingLockMinutes();
        throw new AppError(
          ErrorCode.FORBIDDEN,
          `계정이 잠겨있습니다. ${remainingMinutes}분 후에 다시 시도해주세요`
        );
      }

      // 3. 비밀번호 확인
      const isPasswordValid = await user.password.compare(validatedInput.password);
      
      if (!isPasswordValid) {
        // 실패 횟수 증가
        user.recordFailedLoginAttempt();
        
        // 계정 잠금 확인
        if (user.failedLoginAttempts >= LoginUseCase.MAX_LOGIN_ATTEMPTS) {
          user.lockAccount(LoginUseCase.LOCK_DURATION_MINUTES);
          await this.userRepository.save(user);
          
          loginAttempt.failureReason = 'invalid_password_locked';
          await this.loginAttemptRepository.create(loginAttempt);
          
          throw new AppError(
            ErrorCode.FORBIDDEN,
            `로그인 시도 횟수를 초과했습니다. ${LoginUseCase.LOCK_DURATION_MINUTES}분 후에 다시 시도해주세요`
          );
        }
        
        await this.userRepository.save(user);
        
        loginAttempt.failureReason = 'invalid_password';
        await this.loginAttemptRepository.create(loginAttempt);
        
        const remainingAttempts = LoginUseCase.MAX_LOGIN_ATTEMPTS - user.failedLoginAttempts;
        throw new AppError(
          ErrorCode.UNAUTHORIZED,
          `이메일 또는 비밀번호가 올바르지 않습니다. (남은 시도: ${remainingAttempts}회)`
        );
      }

      // 4. 로그인 성공 - 실패 횟수 초기화
      user.recordSuccessfulLogin();
      await this.userRepository.save(user);

      // 5. 토큰 생성
      const tokens = await this.tokenService.generateAuthTokens(user, deviceInfo);

      // 6. 로그인 성공 기록
      loginAttempt.success = true;
      loginAttempt.failureReason = null;
      await this.loginAttemptRepository.create(loginAttempt);

      logger.info('로그인 성공', { userId: user.id.value });

      return {
        user: {
          id: user.id.value,
          email: user.email.value,
          name: user.name,
          emailVerified: user.emailVerified
        },
        tokens: {
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken
        }
      };

    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      
      logger.error('로그인 실패', { error });
      throw new AppError(
        ErrorCode.INTERNAL_ERROR,
        '로그인 처리 중 오류가 발생했습니다'
      );
    }
  }
}
