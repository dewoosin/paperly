// /Users/workspace/paperly/apps/backend/src/application/use-cases/auth/verify-email.use-case.ts

import { inject, injectable } from 'tsyringe';
import { z } from 'zod';
import { IUserRepository } from '../../../infrastructure/repositories/user.repository';
import { AuthRepository } from '../../../infrastructure/repositories/auth.repository';
import { EmailService } from '../../../infrastructure/email/email.service';
import { UserId } from '../../../domain/value-objects/user-id.vo';
import { BadRequestError, NotFoundError } from '../../../shared/errors/index';
import { Logger } from '../../../infrastructure/logging/Logger';
import { MESSAGE_CODES } from '../../../shared/constants/message-codes';

/**
 * 이메일 인증 입력 스키마
 */
const VerifyEmailInputSchema = z.object({
  token: z.string().uuid('유효하지 않은 토큰 형식입니다')
});

export type VerifyEmailInput = z.infer<typeof VerifyEmailInputSchema>;

export interface VerifyEmailOutput {
  success: boolean;
  message: string;
  user?: {
    id: string;
    email: string;
    name: string;
  };
}

/**
 * 이메일 인증 유스케이스
 * 
 * 1. 토큰 검증
 * 2. 사용자 이메일 인증 처리
 * 3. 환영 이메일 발송
 */
@injectable()
export class VerifyEmailUseCase {
  private readonly logger = new Logger('VerifyEmailUseCase');

  constructor(
    @inject('UserRepository') private userRepository: IUserRepository,
    @inject('EmailService') private emailService: EmailService,
    @inject(AuthRepository) private authRepository: AuthRepository
  ) {}

  async execute(input: VerifyEmailInput): Promise<VerifyEmailOutput> {
    // 1. 입력 검증
    const validatedInput = VerifyEmailInputSchema.parse(input);
    
    this.logger.info('이메일 인증 시도', { token: validatedInput.token });

    try {
      // 2. 토큰 조회
      const verificationToken = await this.authRepository.findEmailVerificationToken(
        validatedInput.token
      );
      
      if (!verificationToken) {
        throw new BadRequestError('유효하지 않은 인증 토큰입니다', undefined, MESSAGE_CODES.AUTH.INVALID_VERIFICATION_CODE);
      }

      // 3. 사용자 조회
      const user = await this.userRepository.findById(
        UserId.from(verificationToken.userId)
      );
      
      if (!user) {
        throw new NotFoundError('사용자를 찾을 수 없습니다', undefined, MESSAGE_CODES.USER.NOT_FOUND);
      }

      // 4. 이미 인증된 경우
      if (user.emailVerified) {
        return {
          success: true,
          message: '이미 인증된 이메일입니다',
          user: {
            id: user.id.getValue(),
            email: user.email.getValue(),
            name: user.name
          }
        };
      }

      // 5. 이메일 인증 처리
      user.verifyEmail();
      await this.userRepository.save(user);

      // 6. 사용한 토큰 삭제
      await this.authRepository.markEmailAsVerified(validatedInput.token);

      // 7. 환영 이메일 발송
      try {
        await this.emailService.sendWelcomeEmail(
          user.email.getValue(),
          user.name
        );
      } catch (error) {
        this.logger.error('환영 이메일 발송 실패', error);
        // 이메일 발송 실패해도 인증은 성공 처리
      }

      this.logger.info('이메일 인증 완료', { userId: user.id.getValue() });

      return {
        success: true,
        message: '이메일 인증이 완료되었습니다',
        user: {
          id: user.id.getValue(),
          email: user.email.getValue(),
          name: user.name
        }
      };
    } catch (error) {
      this.logger.error('이메일 인증 실패', error);
      throw error;
    }
  }
}

/**
 * 이메일 인증 재전송 입력 스키마
 */
const ResendVerificationInputSchema = z.object({
  userId: z.string().uuid('유효하지 않은 사용자 ID입니다')
});

export type ResendVerificationInput = z.infer<typeof ResendVerificationInputSchema>;

export interface ResendVerificationOutput {
  success: boolean;
  message: string;
}

/**
 * 이메일 인증 재전송 유스케이스
 */
@injectable()
export class ResendVerificationUseCase {
  private readonly logger = new Logger('ResendVerificationUseCase');

  constructor(
    @inject('UserRepository') private userRepository: IUserRepository,
    @inject('EmailService') private emailService: EmailService,
    @inject(AuthRepository) private authRepository: AuthRepository
  ) {}

  async execute(input: ResendVerificationInput): Promise<ResendVerificationOutput> {
    // 1. 입력 검증
    const validatedInput = ResendVerificationInputSchema.parse(input);
    
    this.logger.info('이메일 인증 재전송 요청', { userId: validatedInput.userId });

    try {
      // 2. 사용자 조회
      const user = await this.userRepository.findById(
        UserId.from(validatedInput.userId)
      );
      
      if (!user) {
        throw new NotFoundError('사용자를 찾을 수 없습니다', undefined, MESSAGE_CODES.USER.NOT_FOUND);
      }

      // 3. 이미 인증된 경우
      if (user.emailVerified) {
        return {
          success: false,
          message: '이미 인증된 이메일입니다'
        };
      }

      // 4. 새로운 인증 토큰 생성
      const token = `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
      const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24시간
      await this.authRepository.saveEmailVerificationToken(
        user.id.getValue(),
        token,
        expiresAt
      );
      const verificationToken = { token };

      // 5. 인증 이메일 발송
      await this.emailService.sendVerificationEmail(
        user.email.getValue(),
        user.name,
        verificationToken.token
      );

      this.logger.info('이메일 인증 재전송 완료', { 
        userId: user.id.getValue() 
      });

      return {
        success: true,
        message: '인증 이메일이 재전송되었습니다'
      };
    } catch (error) {
      this.logger.error('이메일 인증 재전송 실패', error);
      throw error;
    }
  }
}