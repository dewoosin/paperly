// /Users/workspace/paperly/apps/backend/src/application/use-cases/auth/login.use-case.ts

import { inject, injectable } from 'tsyringe';
import { z } from 'zod';
import { IUserRepository } from '../../../infrastructure/repositories/user.repository';
import { JwtService } from '../../../infrastructure/auth/jwt.service';
import { AuthRepository } from '../../../infrastructure/repositories/auth.repository';
import { Email } from '../../../domain/value-objects/email.vo';
import { UnauthorizedError, TooManyRequestsError } from '../../../shared/errors';
import { Logger } from '../../../infrastructure/logging/Logger';
import { DeviceInfo } from '../../../domain/auth/auth.types';

/**
 * 로그인 입력 스키마
 */
const LoginInputSchema = z.object({
  email: z.string().email('올바른 이메일 형식이 아닙니다'),
  password: z.string().min(1, '비밀번호를 입력해주세요'),
  deviceInfo: z.object({
    deviceId: z.string().default('unknown'),
    userAgent: z.string().optional(),
    ipAddress: z.string().optional()
  })
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
 * 3. 비밀번호 검증
 * 4. 토큰 발급
 * 5. 로그인 기록
 */
@injectable()
export class LoginUseCase {
  private readonly logger = new Logger('LoginUseCase');
  
  // 로그인 시도 제한 설정
  private readonly MAX_LOGIN_ATTEMPTS = 5;
  private readonly LOCKOUT_DURATION = 15 * 60 * 1000; // 15분
  private loginAttempts = new Map<string, { count: number; lastAttempt: Date }>();

  constructor(
    @inject('UserRepository') private userRepository: IUserRepository,
    @inject('TokenService') private tokenService: any,
    @inject(AuthRepository) private authRepository: AuthRepository
  ) {}

  async execute(input: LoginInput): Promise<LoginOutput> {
    // 1. 입력 검증
    const validatedInput = LoginInputSchema.parse(input);
    
    this.logger.info('로그인 시도', { email: validatedInput.email });

    // 2. 로그인 시도 제한 확인
    this.checkLoginAttempts(validatedInput.email);

    try {
      // 3. 사용자 조회
      const email = Email.create(validatedInput.email);
      const user = await this.userRepository.findByEmail(email);
      
      if (!user) {
        await this.recordFailedAttempt(validatedInput.email, validatedInput.deviceInfo);
        // 보안상 이메일 존재 여부를 노출하지 않음
        throw new UnauthorizedError('이메일 또는 비밀번호가 올바르지 않습니다. 입력하신 정보를 다시 확인해주세요.');
      }

      // 4. 비밀번호 검증
      const isPasswordValid = await user.password.verify(validatedInput.password);
      if (!isPasswordValid) {
        await this.recordFailedAttempt(validatedInput.email, validatedInput.deviceInfo);
        throw new UnauthorizedError('이메일 또는 비밀번호가 올바르지 않습니다. 입력하신 정보를 다시 확인해주세요.');
      }

      // 5. 이메일 인증 확인
      if (!user.emailVerified) {
        this.logger.warn('이메일 미인증 사용자 로그인 시도', { userId: user.id.getValue() });
        // 로그인은 허용하되, 클라이언트에서 인증 필요 메시지 표시
      }

      // 6. 로그인 성공 - 시도 기록 초기화
      this.clearLoginAttempts(validatedInput.email);

      // 7. JWT 토큰 생성
      const tokens = this.tokenService.generateTokenPair(
        user.id.getValue(),
        user.email.getValue()
      );

      // 8. Refresh Token 저장
      const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7일
      await this.authRepository.saveRefreshToken(
        user.id.getValue(),
        tokens.refreshToken,
        expiresAt,
        validatedInput.deviceInfo.deviceId,
        validatedInput.deviceInfo.userAgent,
        validatedInput.deviceInfo.ipAddress
      );

      // 9. 로그인 성공 기록
      await this.authRepository.recordLoginAttempt(
        validatedInput.email,
        true,
        validatedInput.deviceInfo?.ipAddress,
        validatedInput.deviceInfo?.userAgent
      );

      this.logger.info('로그인 성공', { 
        userId: user.id.getValue(),
        deviceId: validatedInput.deviceInfo.deviceId,
        emailVerified: user.emailVerified
      });

      return {
        user: {
          id: user.id.getValue(),
          email: user.email.getValue(),
          name: user.name,
          emailVerified: user.emailVerified
        },
        tokens
      };
    } catch (error) {
      this.logger.error('로그인 실패', error);
      throw error;
    }
  }

  /**
   * 로그인 시도 제한 확인
   */
  private checkLoginAttempts(email: string): void {
    const attempts = this.loginAttempts.get(email);
    
    if (!attempts) return;

    const timeSinceLastAttempt = Date.now() - attempts.lastAttempt.getTime();
    
    // 잠금 시간이 지났으면 초기화
    if (timeSinceLastAttempt > this.LOCKOUT_DURATION) {
      this.loginAttempts.delete(email);
      return;
    }

    // 최대 시도 횟수 초과
    if (attempts.count >= this.MAX_LOGIN_ATTEMPTS) {
      const remainingTime = Math.ceil((this.LOCKOUT_DURATION - timeSinceLastAttempt) / 1000 / 60);
      throw new TooManyRequestsError(
        `너무 많은 로그인 시도가 있었습니다. ${remainingTime}분 후에 다시 시도해주세요.`
      );
    }
  }

  /**
   * 실패한 로그인 시도 기록
   */
  private async recordFailedAttempt(email: string, deviceInfo?: DeviceInfo): Promise<void> {
    // DB에 실패 기록
    await this.authRepository.recordLoginAttempt(
      email,
      false,
      deviceInfo?.ipAddress,
      deviceInfo?.userAgent
    );
    
    // 메모리에도 기록 (빠른 체크를 위해)
    const attempts = this.loginAttempts.get(email) || { count: 0, lastAttempt: new Date() };
    attempts.count++;
    attempts.lastAttempt = new Date();
    this.loginAttempts.set(email, attempts);

    this.logger.warn('로그인 실패 시도', { 
      email, 
      attemptCount: attempts.count 
    });

    // 남은 시도 횟수를 에러 메시지에 포함
    if (attempts.count >= 3) {
      const remainingAttempts = this.MAX_LOGIN_ATTEMPTS - attempts.count;
      if (remainingAttempts > 0) {
        throw new UnauthorizedError(
          `로그인에 실패했습니다. ${remainingAttempts}번의 시도가 남았습니다. 5회 실패 시 15분간 로그인이 제한됩니다.`
        );
      }
    }
  }

  /**
   * 로그인 시도 기록 초기화
   */
  private clearLoginAttempts(email: string): void {
    this.loginAttempts.delete(email);
  }
}