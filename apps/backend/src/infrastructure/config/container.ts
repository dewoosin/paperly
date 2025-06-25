// apps/backend/src/infrastructure/config/container.ts

import 'reflect-metadata';
import { container } from 'tsyringe';

// Use Cases
import { RegisterUseCase } from '../../application/use-cases/auth/register.use-case';
import { LoginUseCase } from '../../application/use-cases/auth/login.use-case';
import { RefreshTokenUseCase, LogoutUseCase } from '../../application/use-cases/auth/refresh-token.use-case';
import { VerifyEmailUseCase, ResendVerificationUseCase } from '../../application/use-cases/auth/verify-email.use-case';

// Controllers
import { AuthController } from '../web/controllers/auth.controller';

// Repositories
import { AuthRepository } from '../repositories/auth.repository';

// Services (임시 구현)
import { Logger } from '../logging/logger';

const logger = new Logger('Container');

/**
 * 임시 Mock 서비스들
 * 실제 구현이 완성될 때까지 사용
 */

// Mock User Repository
class MockUserRepository {
  private users = new Map();
  
  async findByEmail(email: any) {
    const emailStr = email.getValue ? email.getValue() : email;
    logger.info('Mock: 사용자 조회 시도', { email: emailStr });
    
    // 기본 테스트 계정들
    const testUsers = {
      'test@example.com': {
        id: { getValue: () => 'test-user-1' },
        email: { getValue: () => 'test@example.com' },
        name: 'Test User',
        emailVerified: true,
        password: {
          verify: async (password: string) => password === 'password123'
        }
      },
      'admin@paperly.com': {
        id: { getValue: () => 'admin-user-1' },
        email: { getValue: () => 'admin@paperly.com' },
        name: 'Admin User',
        emailVerified: true,
        password: {
          verify: async (password: string) => password === 'admin123'
        }
      }
    };
    
    const user = testUsers[emailStr] || this.users.get(emailStr);
    
    if (user) {
      logger.info('Mock: 사용자 찾음', { email: emailStr, name: user.name });
      return user;
    }
    
    logger.info('Mock: 사용자 없음', { email: emailStr });
    return null;
  }
  
  async save(user: any) {
    const emailStr = user.email?.getValue ? user.email.getValue() : user.email;
    const userId = `user-${Date.now()}`;
    
    const savedUser = {
      id: { getValue: () => userId },
      email: { getValue: () => emailStr },
      name: user.name,
      emailVerified: false,
      password: {
        verify: async (password: string) => password === user.password
      }
    };
    
    this.users.set(emailStr, savedUser);
    logger.info('사용자 저장됨 (Mock)', { userId, email: emailStr, name: user.name });
    return savedUser;
  }
  
  async findById(id: any) {
    const idStr = id.getValue ? id.getValue() : id;
    logger.info('Mock: ID로 사용자 조회', { id: idStr });
    
    // users Map에서 찾기
    for (const user of this.users.values()) {
      if (user.id.getValue() === idStr) {
        return user;
      }
    }
    
    return null;
  }
}

// Mock Email Service
class MockEmailService {
  async sendVerificationEmail(email: string, name: string, token: string) {
    logger.info('인증 이메일 발송됨 (Mock)', { email, name });
    return true;
  }

  async sendWelcomeEmail(email: string, name: string) {
    logger.info('환영 이메일 발송됨 (Mock)', { email, name });
    return true;
  }
}

// Mock Token Service - JwtService와 호환되도록 구현
class MockTokenService {
  static generateTokenPair(userId: string, email: string) {
    const timestamp = Date.now();
    logger.info('Mock: JWT 토큰 쌍 생성', { userId, email });
    
    return {
      accessToken: `mock_access_${userId}_${timestamp}`,
      refreshToken: `mock_refresh_${userId}_${timestamp}`
    };
  }
  
  static generateAccessToken(userId: string, email: string) {
    const timestamp = Date.now();
    return `mock_access_${userId}_${timestamp}`;
  }
  
  static generateRefreshToken(userId: string, email: string) {
    const timestamp = Date.now();
    return `mock_refresh_${userId}_${timestamp}`;
  }
  
  static verifyAccessToken(token: string) {
    logger.info('Mock: Access token 검증', { token });
    
    if (token.startsWith('mock_access_')) {
      return {
        userId: 'test-user-1',
        email: 'test@example.com',
        type: 'access'
      };
    }
    
    throw new Error('Invalid token');
  }
  
  static verifyRefreshToken(token: string) {
    logger.info('Mock: Refresh token 검증', { token });
    
    if (token.startsWith('mock_refresh_')) {
      return {
        userId: 'test-user-1',
        email: 'test@example.com',
        type: 'refresh'
      };
    }
    
    throw new Error('Invalid refresh token');
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

// Mock Auth Repository
class MockAuthRepository {
  private refreshTokens = new Map();
  private loginAttempts = [];
  private emailVerifications = new Map();

  async saveRefreshToken(userId: string, token: string, expiresAt: Date, deviceId?: string, userAgent?: string, ipAddress?: string) {
    const tokenData = {
      userId,
      token,
      expiresAt,
      deviceId,
      userAgent,
      ipAddress,
      createdAt: new Date()
    };
    
    this.refreshTokens.set(token, tokenData);
    logger.info('Mock: Refresh token 저장됨', { userId, deviceId });
  }

  async findRefreshToken(token: string) {
    const tokenData = this.refreshTokens.get(token);
    if (tokenData && tokenData.expiresAt > new Date()) {
      return { ...tokenData, user: { id: tokenData.userId } };
    }
    return null;
  }

  async deleteRefreshToken(token: string) {
    this.refreshTokens.delete(token);
    logger.info('Mock: Refresh token 삭제됨', { token });
  }

  async deleteAllUserRefreshTokens(userId: string) {
    for (const [token, data] of this.refreshTokens.entries()) {
      if (data.userId === userId) {
        this.refreshTokens.delete(token);
      }
    }
    logger.info('Mock: 사용자 모든 refresh token 삭제됨', { userId });
  }

  async recordLoginAttempt(email: string, success: boolean, ipAddress?: string, userAgent?: string) {
    const attempt = {
      email,
      success,
      ipAddress,
      userAgent,
      attemptedAt: new Date()
    };
    
    this.loginAttempts.push(attempt);
    logger.info('Mock: 로그인 시도 기록됨', attempt);
  }

  async getRecentLoginAttempts(email: string, minutes: number = 15) {
    const since = new Date(Date.now() - minutes * 60 * 1000);
    return this.loginAttempts.filter(attempt => 
      attempt.email === email && attempt.attemptedAt >= since
    );
  }

  async saveEmailVerificationToken(userId: string, token: string, expiresAt: Date) {
    this.emailVerifications.set(token, {
      userId,
      token,
      expiresAt,
      createdAt: new Date(),
      verifiedAt: null
    });
    logger.info('Mock: 이메일 인증 토큰 저장됨', { userId });
  }

  async findEmailVerificationToken(token: string) {
    const verification = this.emailVerifications.get(token);
    if (verification && verification.expiresAt > new Date() && !verification.verifiedAt) {
      return { ...verification, user: { id: verification.userId } };
    }
    return null;
  }

  async markEmailAsVerified(token: string) {
    const verification = this.emailVerifications.get(token);
    if (verification) {
      verification.verifiedAt = new Date();
      logger.info('Mock: 이메일 인증 완료됨', { token });
    }
  }
}

/**
 * DI Container 설정
 */
export function setupContainer() {
  logger.info('Setting up DI container...');

  // Repositories
  logger.info('Registering UserRepository...');
  container.registerSingleton('UserRepository', MockUserRepository);
  logger.info('Registering other repositories...');
  container.registerSingleton('RefreshTokenRepository', MockRefreshTokenRepository);
  container.registerSingleton('EmailVerificationRepository', MockEmailVerificationRepository);
  container.registerSingleton('LoginAttemptRepository', MockLoginAttemptRepository);
  container.registerSingleton(AuthRepository, MockAuthRepository);

  // Services
  logger.info('Registering services...');
  container.registerSingleton('EmailService', MockEmailService);
  container.registerSingleton('TokenService', MockTokenService);

  // Use Cases
  logger.info('Registering use cases...');
  container.registerSingleton(RegisterUseCase, RegisterUseCase);
  container.registerSingleton(LoginUseCase, LoginUseCase);
  container.registerSingleton(RefreshTokenUseCase, RefreshTokenUseCase);
  container.registerSingleton(VerifyEmailUseCase, VerifyEmailUseCase);
  container.registerSingleton(ResendVerificationUseCase, ResendVerificationUseCase);
  container.registerSingleton(LogoutUseCase, LogoutUseCase);

  // Controllers
  logger.info('Registering controllers...');
  container.registerSingleton(AuthController, AuthController);

  logger.info('DI container setup completed');
  
  // Test registration
  try {
    logger.info('Testing UserRepository resolution...');
    const userRepo = container.resolve('UserRepository');
    logger.info('UserRepository resolved successfully');
  } catch (error) {
    logger.error('Failed to resolve UserRepository:', error);
  }
}