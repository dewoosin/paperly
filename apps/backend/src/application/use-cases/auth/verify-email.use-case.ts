// apps/backend/src/application/use-cases/auth/verify-email.use-case.ts

import { inject, injectable } from 'tsyringe';
import { z } from 'zod';
import { UseCase } from '../../../shared/application/use-case';
import { IUserRepository } from '../../../domain/repositories/user.repository';
import { IEmailVerificationRepository } from '../../../domain/repositories/email-verification.repository';
import { Token } from '../../../domain/value-objects/auth.value-objects';
import { AppError, ErrorCode } from '../../../shared/errors/app-error';
import { logger } from '../../../infrastructure/logging/logger';

const VerifyEmailInputSchema = z.object({
  token: z.string()
});

export type VerifyEmailInput = z.infer<typeof VerifyEmailInputSchema>;

export interface VerifyEmailOutput {
  success: boolean;
  message: string;
}

/**
 * 이메일 인증 유스케이스
 */
@injectable()
export class VerifyEmailUseCase implements UseCase<VerifyEmailInput, VerifyEmailOutput> {
  constructor(
    @inject('UserRepository') private userRepository: IUserRepository,
    @inject('EmailVerificationRepository') private emailVerificationRepository: IEmailVerificationRepository
  ) {}

  async execute(input: VerifyEmailInput): Promise<VerifyEmailOutput> {
    const validatedInput = VerifyEmailInputSchema.parse(input);
    
    logger.info('이메일 인증 시도');

    try {
      const token = Token.create(validatedInput.token);
      
      // 1. 토큰으로 인증 정보 조회
      const verification = await this.emailVerificationRepository.findByToken(token);
      
      if (!verification) {
        throw new AppError(
          ErrorCode.NOT_FOUND,
          '유효하지 않은 인증 토큰입니다'
        );
      }

      // 2. 토큰 만료 확인
      if (verification.isExpired()) {
        throw new AppError(
          ErrorCode.BAD_REQUEST,
          '인증 토큰이 만료되었습니다. 새로운 인증 메일을 요청해주세요'
        );
      }

      // 3. 이미 인증된 경우
      if (verification.isVerified()) {
        throw new AppError(
          ErrorCode.BAD_REQUEST,
          '이미 인증이 완료되었습니다'
        );
      }

      // 4. 사용자 조회
      const user = await this.userRepository.findById(verification.userId);
      if (!user) {
        throw new AppError(
          ErrorCode.NOT_FOUND,
          '사용자를 찾을 수 없습니다'
        );
      }

      // 5. 이메일 인증 처리
      user.verifyEmail();
      await this.userRepository.save(user);

      // 6. 인증 정보 업데이트
      verification.markAsVerified();
      await this.emailVerificationRepository.save(verification);

      logger.info('이메일 인증 완료', { userId: user.id.value });

      return {
        success: true,
        message: '이메일 인증이 완료되었습니다'
      };

    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      
      logger.error('이메일 인증 실패', { error });
      throw new AppError(
        ErrorCode.INTERNAL_ERROR,
        '이메일 인증 처리 중 오류가 발생했습니다'
      );
    }
  }
}
