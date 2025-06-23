// apps/backend/src/application/use-cases/auth/register.use-case.ts

import { inject, injectable } from 'tsyringe';
import { z } from 'zod';
import { UseCase } from '../../../shared/application/use-case';
import { IUserRepository } from '../../../domain/repositories/user.repository';
import { IEmailService } from '../../../domain/services/email.service';
import { ITokenService } from '../../../domain/services/token.service';
import { User } from '../../../domain/entities/user.entity';
import { Email, Password, BirthDate, Gender } from '../../../domain/value-objects/auth.value-objects';
import { UserId } from '../../../domain/value-objects/user-id.value-object';
import { AppError, ErrorCode } from '../../../shared/errors/app-error';
import { logger } from '../../../infrastructure/logging/logger';

// 회원가입 입력 스키마
const RegisterInputSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  name: z.string().min(1).max(50),
  birthDate: z.string().datetime(),
  gender: z.enum(['male', 'female', 'other', 'prefer_not_to_say']).optional()
});

export type RegisterInput = z.infer<typeof RegisterInputSchema>;

export interface RegisterOutput {
  user: {
    id: string;
    email: string;
    name: string;
  };
  tokens: {
    accessToken: string;
    refreshToken: string;
  };
  emailVerificationSent: boolean;
}

/**
 * 회원가입 유스케이스
 * 
 * 1. 입력 검증
 * 2. 이메일 중복 확인
 * 3. 사용자 생성
 * 4. 인증 이메일 발송
 * 5. 토큰 발급
 */
@injectable()
export class RegisterUseCase implements UseCase<RegisterInput, RegisterOutput> {
  constructor(
    @inject('UserRepository') private userRepository: IUserRepository,
    @inject('EmailService') private emailService: IEmailService,
    @inject('TokenService') private tokenService: ITokenService
  ) {}

  async execute(input: RegisterInput): Promise<RegisterOutput> {
    // 1. 입력 검증
    const validatedInput = RegisterInputSchema.parse(input);
    
    logger.info('회원가입 시도', { email: validatedInput.email });

    try {
      // 2. Value Objects 생성
      const email = Email.create(validatedInput.email);
      const password = Password.create(validatedInput.password);
      const birthDate = BirthDate.create(validatedInput.birthDate);
      const gender = Gender.createOptional(validatedInput.gender);

      // 3. 이메일 중복 확인
      const existingUser = await this.userRepository.findByEmail(email);
      if (existingUser) {
        throw new AppError(
          ErrorCode.CONFLICT,
          '이미 사용 중인 이메일입니다'
        );
      }

      // 4. 비밀번호 해싱
      const hashedPassword = await password.hash();

      // 5. 사용자 생성
      const user = User.create({
        email,
        password: Password.fromHash(hashedPassword),
        name: validatedInput.name,
        birthDate,
        gender
      });

      // 6. DB에 저장
      await this.userRepository.save(user);

      // 7. 이메일 인증 토큰 생성 및 발송
      let emailVerificationSent = false;
      try {
        const verificationToken = await this.tokenService.generateEmailVerificationToken(user.id);
        await this.emailService.sendVerificationEmail(email, verificationToken, user.name);
        emailVerificationSent = true;
        
        logger.info('인증 이메일 발송 완료', { userId: user.id.value });
      } catch (error) {
        // 이메일 발송 실패해도 회원가입은 성공으로 처리
        logger.error('인증 이메일 발송 실패', { userId: user.id.value, error });
      }

      // 8. Access & Refresh 토큰 생성
      const tokens = await this.tokenService.generateAuthTokens(user);

      logger.info('회원가입 완료', { userId: user.id.value });

      return {
        user: {
          id: user.id.value,
          email: user.email.value,
          name: user.name
        },
        tokens: {
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken
        },
        emailVerificationSent
      };

    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      
      logger.error('회원가입 실패', { error });
      throw new AppError(
        ErrorCode.INTERNAL_ERROR,
        '회원가입 처리 중 오류가 발생했습니다'
      );
    }
  }
}
