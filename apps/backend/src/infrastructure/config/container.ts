/**
 * container.ts
 * 
 * tsyringe 의존성 주입 컨테이너 설정
 * 모든 서비스, 레포지토리, 유스케이스를 등록합니다.
 */

import 'reflect-metadata';
import { container } from 'tsyringe';
import { db } from '../config/database.config';

// Repositories
import { UserRepository } from '../repositories/user.repository';
import { AuthRepository } from '../repositories/auth.repository';

// Services
import { JwtService } from '../auth/jwt.service';
import { PasswordService } from '../auth/password.service';
import { EmailService } from '../email/email.service';

// Use Cases
import { AuthUseCases } from '../../application/use-cases/auth.use-cases';
import { RegisterUseCase } from '../../application/use-cases/auth/register.use-case';
import { LoginUseCase } from '../../application/use-cases/auth/login.use-case';
import { VerifyEmailUseCase } from '../../application/use-cases/auth/verify-email.use-case';
import { RefreshTokenUseCase } from '../../application/use-cases/auth/refresh-token.use-case';

// Controllers
import { AuthController } from '../web/controllers/auth.controller';

/**
 * 의존성 주입 컨테이너 초기화
 */
export function setupContainer(): void {
  // Database
  container.registerInstance('Database', db);

  // Repositories
  container.register('IUserRepository', {
    useClass: UserRepository
  });
  
  container.register('IAuthRepository', {
    useClass: AuthRepository
  });

  // Services
  container.register('IJwtService', {
    useClass: JwtService
  });
  
  container.register('IPasswordService', {
    useClass: PasswordService
  });
  
  container.register('IEmailService', {
    useClass: EmailService
  });

  container.register('TokenService', {
    useFactory: () => JwtService
  });

  container.register('UserRepository', {
    useFactory: () => new UserRepository()
  });

  // Use Cases
  container.register('AuthUseCases', {
    useFactory: () => {
      const userRepository = container.resolve<UserRepository>('UserRepository');
      const emailService = container.resolve<EmailService>('IEmailService');
      return new AuthUseCases(userRepository, emailService);
    }
  });

  container.register(RegisterUseCase, {
    useFactory: () => {
      return new RegisterUseCase(
        container.resolve('UserRepository'),
        container.resolve('IEmailService'),
        container.resolve('TokenService')
      );
    }
  });

  container.register(LoginUseCase, {
    useFactory: () => {
      return new LoginUseCase(
        container.resolve('UserRepository'),
        container.resolve('TokenService')
      );
    }
  });

  container.register(VerifyEmailUseCase, {
    useFactory: () => {
      return new VerifyEmailUseCase(
        container.resolve('UserRepository'),
        container.resolve('IAuthRepository')
      );
    }
  });

  container.register(RefreshTokenUseCase, {
    useFactory: () => {
      return new RefreshTokenUseCase(
        container.resolve('UserRepository'),
        container.resolve('IAuthRepository'),
        container.resolve('TokenService')
      );
    }
  });

  // Controllers
  container.register(AuthController, {
    useClass: AuthController
  });

  console.log('✅ 의존성 주입 컨테이너 설정 완료');
}