// apps/backend/src/infrastructure/di/container.ts

import 'reflect-metadata';
import { container } from 'tsyringe';

// Domain Repositories (인터페이스들)
import { IUserRepository } from '../../domain/repositories/user.repository';
import { IRefreshTokenRepository } from '../../domain/repositories/refresh-token.repository';
import { IEmailVerificationRepository } from '../../domain/repositories/email-verification.repository';
import { ILoginAttemptRepository } from '../../domain/repositories/login-attempt.repository';

// Infrastructure Repositories (구현체들)
import { UserRepository } from '../repositories/user.repository';

// Domain Services (인터페이스들)
import { ITokenService } from '../../domain/services/token.service';
import { IEmailService } from '../../domain/services/email.service';

// Infrastructure Services (구현체들)
import { TokenService } from '../services/token.service';
import { EmailService } from '../services/email.service';

// Application Use Cases
import { RegisterUseCase } from '../../application/use-cases/auth/register.use-case';
import { LoginUseCase } from '../../application/use-cases/auth/login.use-case';
import { VerifyEmailUseCase } from '../../application/use-cases/auth/verify-email.use-case';
import { RefreshTokenUseCase } from '../../application/use-cases/auth/refresh-token.use-case';

// Infrastructure Controllers
import { AuthController } from '../web/controllers/auth.controller';

// Configuration
import { config } from '../config/env.config';

/**
 * 의존성 주입 컨테이너 설정 (Mock을 사용한 실행 가능한 버전)
 * 
 * Mock 서비스들을 사용하여 실제 동작하는 Auth 시스템을 제공합니다.
 */
export function setupContainer(): void {
  // config 설정을 사용
  const { setupContainer: setupMockContainer } = require('../config/container');
  setupMockContainer();
  
  console.log('✅ DI Container가 성공적으로 설정되었습니다 (Mock 서비스 포함).');
}

/**
 * 컨테이너 상태 확인 (디버깅용)
 */
export function validateContainer(): void {
  try {
    // Auth Controller 해결 가능한지 확인
    const authController = container.resolve(AuthController);
    
    console.log('✅ 컨테이너 검증 완료: AuthController와 모든 의존성이 올바르게 등록되었습니다.');
  } catch (error) {
    console.error('❌ 컨테이너 검증 실패:', error);
    throw error;
  }
}