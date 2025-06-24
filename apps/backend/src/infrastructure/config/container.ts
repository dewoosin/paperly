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
import { VerifyEmailUseCase, ResendVerificationUseCase } from '../../application/use-cases/auth/verify-email.use-case';
import { RefreshTokenUseCase, LogoutUseCase } from '../../application/use-cases/auth/refresh-token.use-case';

// Controllers
import { AuthController } from '../web/controllers/auth.controller';

/**
 * 의존성 주입 컨테이너 초기화
 */
export function setupContainer(): void {
  // Database
  container.registerInstance('Database', db);

  // Repositories - 인스턴스로 등록
  container.registerInstance('UserRepository', new UserRepository());
  container.registerInstance('IUserRepository', new UserRepository());
  // AuthRepository는 static 클래스이므로 클래스 자체를 등록
  container.registerInstance('IAuthRepository', AuthRepository);

  // Services - 인스턴스로 등록
  container.registerInstance('EmailService', new EmailService());
  container.registerInstance('IEmailService', new EmailService());
  container.registerInstance('TokenService', JwtService);

  // Use Cases
  container.register(RegisterUseCase, {
    useFactory: () => {
      return new RegisterUseCase(
        container.resolve('UserRepository'),
        container.resolve('EmailService'),
        JwtService  // 직접 클래스 사용
      );
    }
  });

  container.register(LoginUseCase, {
    useFactory: () => {
      return new LoginUseCase(
        container.resolve('UserRepository'),
        JwtService  // 직접 클래스 사용
      );
    }
  });

  container.register(VerifyEmailUseCase, {
    useFactory: () => {
      return new VerifyEmailUseCase(
        container.resolve('UserRepository'),
        container.resolve('EmailService')
      );
    }
  });

  container.register(ResendVerificationUseCase, {
    useFactory: () => {
      return new ResendVerificationUseCase(
        container.resolve('UserRepository'),
        container.resolve('EmailService')
      );
    }
  });

  container.register(RefreshTokenUseCase, {
    useFactory: () => {
      return new RefreshTokenUseCase(
        container.resolve('UserRepository'),
        JwtService  // 직접 클래스 사용
      );
    }
  });

  container.register(LogoutUseCase, {
    useClass: LogoutUseCase
  });

  // Controllers
  container.register(AuthController, {
    useClass: AuthController
  });

  console.log('✅ 의존성 주입 컨테이너 설정 완료');
}