// apps/backend/src/infrastructure/config/container.ts

import 'reflect-metadata';
import { container } from 'tsyringe';

// Use Cases
import { RegisterUseCase } from '../../application/use-cases/auth/register.use-case';
import { LoginUseCase } from '../../application/use-cases/auth/login.use-case';
import { RefreshTokenUseCase } from '../../application/use-cases/auth/refresh-token.use-case';
import { VerifyEmailUseCase } from '../../application/use-cases/auth/verify-email.use-case';

// Controllers
import { AuthController } from '../web/controllers/auth.controller';

// Services (임시 구현)
import { Logger } from '../logging/logger';

const logger = new Logger('Container');

/**
 * 임시 Mock 서비스들
 * 실제 구현이 완성될 때까지 사용
 */

// Mock User Repository
class MockUserRepository {
  async findByEmail(email: any) {
    return null; // 사용자 없음 - 회원가입 가능
  }
  
  async save(user: any) {
    logger.info('사용자 저장됨 (Mock)', { user });
    return user;
  }
  
  async findById(id: any) {
    return null;
  }
}

// Mock Email Service
class MockEmailService {
  async sendVerificationEmail(email: string, name: string, token: string) {
    logger.info('인증 이메일 발송됨 (Mock)', { email, name });
    return true;
  }
}

// Mock Token Service
class MockTokenService {
  async generateAuthTokens(user: any) {
    const userId = Date.now().toString();
    return {
      accessToken: `mock_access_${userId}`,
      refreshToken: `mock_refresh_${userId}`
    };
  }
  
  async refreshTokens(token: any) {
    const userId = Date.now().toString();
    return {
      accessToken: `mock_access_${userId}`,
      refreshToken: `mock_refresh_${userId}`
    };
  }
  
  async generateEmailVerificationToken(userId: any) {
    return `mock_verify_${userId}`;
  }
}

// Mock Refresh Token Repository
class MockRefreshTokenRepository {
  async findByToken(token: any) {
    return null;
  }
  
  async save(tokenData: any) {
    return tokenData;
  }
  
  async create(tokenData: any) {
    return tokenData;
  }
}

// Mock Email Verification Repository
class MockEmailVerificationRepository {
  async findByToken(token: any) {
    return null;
  }
  
  async save(verification: any) {
    return verification;
  }
}

// Mock Login Attempt Repository
class MockLoginAttemptRepository {
  async create(attempt: any) {
    logger.info('로그인 시도 기록됨 (Mock)', attempt);
    return attempt;
  }
}

/**
 * DI Container 설정
 */
export function setupContainer() {
  logger.info('Setting up DI container...');

  // Repositories
  container.registerSingleton('UserRepository', MockUserRepository);
  container.registerSingleton('RefreshTokenRepository', MockRefreshTokenRepository);
  container.registerSingleton('EmailVerificationRepository', MockEmailVerificationRepository);
  container.registerSingleton('LoginAttemptRepository', MockLoginAttemptRepository);

  // Services
  container.registerSingleton('EmailService', MockEmailService);
  container.registerSingleton('TokenService', MockTokenService);

  // Use Cases
  container.registerSingleton(RegisterUseCase, RegisterUseCase);
  container.registerSingleton(LoginUseCase, LoginUseCase);
  container.registerSingleton(RefreshTokenUseCase, RefreshTokenUseCase);
  container.registerSingleton(VerifyEmailUseCase, VerifyEmailUseCase);

  // Controllers
  container.registerSingleton(AuthController, AuthController);

  logger.info('DI container setup completed');
}