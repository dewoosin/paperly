// /Users/workspace/paperly/apps/backend/src/application/use-cases/auth/register.use-case.ts

import { inject, injectable } from 'tsyringe';
import { z } from 'zod';
import { IUserRepository } from '../../../infrastructure/repositories/user.repository';
import { EmailService } from '../../../infrastructure/email/email.service';
import { JwtService } from '../../../infrastructure/auth/jwt.service';
import { AuthRepository } from '../../../infrastructure/repositories/auth.repository';
import { User } from '../../../domain/entities/User.entity';
import { Email } from '../../../domain/value-objects/email.vo';
import { Password } from '../../../domain/value-objects/password.vo';
import { UserId } from '../../../domain/value-objects/user-id.vo';
import { Gender } from '../../../domain/auth/auth.types';
import { ConflictError, BadRequestError } from '../../../shared/errors';
import { Logger } from '../../../infrastructure/logging/Logger';

/**
 * 회원가입 입력 스키마
 */
const RegisterInputSchema = z.object({
  email: z.string().email('올바른 이메일 형식이 아닙니다'),
  password: z.string().min(8, '비밀번호는 최소 8자 이상이어야 합니다'),
  name: z.string().min(2, '이름은 최소 2자 이상이어야 합니다').max(50),
  birthDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, '생년월일 형식은 YYYY-MM-DD여야 합니다'),
  gender: z.enum(['male', 'female', 'other', 'prefer_not_to_say']).optional()
});

export type RegisterInput = z.infer<typeof RegisterInputSchema>;

export interface RegisterOutput {
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
  emailVerificationSent: boolean;
}

/**
 * 회원가입 유스케이스
 * 
 * 1. 입력 검증
 * 2. 이메일 중복 확인
 * 3. 사용자 생성
 * 4. 토큰 발급
 * 5. 인증 이메일 발송
 */
@injectable()
export class RegisterUseCase {
  private readonly logger = new Logger('RegisterUseCase');

  constructor(
    @inject('UserRepository') private userRepository: IUserRepository,
    @inject('EmailService') private emailService: EmailService,
    @inject('TokenService') private tokenService: any,
    @inject(AuthRepository) private authRepository: AuthRepository
  ) {}

  async execute(input: RegisterInput): Promise<RegisterOutput> {
    // 1. 입력 검증
    const validatedInput = RegisterInputSchema.parse(input);
    
    this.logger.info('회원가입 시도', { email: validatedInput.email });

    try {
      // 2. Value Objects 생성
      const email = Email.create(validatedInput.email);
      const password = await Password.create(validatedInput.password);
      const birthDate = new Date(validatedInput.birthDate);
      
      // 나이 검증 (14세 이상)
      const age = this.calculateAge(birthDate);
      if (age < 14) {
        throw new BadRequestError('14세 이상만 가입할 수 있습니다');
      }

      // 3. 이메일 중복 확인
      const existingUser = await this.userRepository.findByEmail(email);
      if (existingUser) {
        throw new ConflictError('이미 사용 중인 이메일입니다');
      }

      // 4. 사용자 생성
      const user = User.create({
        email,
        password,
        name: validatedInput.name,
        birthDate,
        gender: validatedInput.gender as Gender
      });

      // 5. DB에 저장
      await this.userRepository.save(user);

      // 6. JWT 토큰 생성
      const tokens = this.tokenService.generateTokenPair(
        user.id.getValue(),
        user.email.getValue()
      );

      // 7. Refresh Token 저장
      const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7일
      await this.authRepository.saveRefreshToken(
        user.id.getValue(),
        tokens.refreshToken,
        expiresAt
      );

      // 8. 이메일 인증 메일 발송
      let emailVerificationSent = false;
      try {
        const verificationToken = await this.authRepository.createEmailVerificationToken(
          user.id.getValue()
        );
        
        await this.emailService.sendVerificationEmail(
          user.email.getValue(),
          user.name,
          verificationToken.token
        );
        
        emailVerificationSent = true;
        this.logger.info('인증 이메일 발송 성공', { userId: user.id.getValue() });
      } catch (error) {
        this.logger.error('인증 이메일 발송 실패', error);
        // 이메일 발송 실패해도 회원가입은 성공 처리
      }

      this.logger.info('회원가입 완료', { 
        userId: user.id.getValue(),
        emailVerificationSent 
      });

      return {
        user: {
          id: user.id.getValue(),
          email: user.email.getValue(),
          name: user.name,
          emailVerified: user.emailVerified
        },
        tokens,
        emailVerificationSent
      };
    } catch (error) {
      this.logger.error('회원가입 실패', error);
      throw error;
    }
  }

  /**
   * 나이 계산
   */
  private calculateAge(birthDate: Date): number {
    const today = new Date();
    let age = today.getFullYear() - birthDate.getFullYear();
    const monthDiff = today.getMonth() - birthDate.getMonth();
    
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
      age--;
    }
    
    return age;
  }
}