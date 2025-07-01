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
import { ArticleController } from '../web/controllers/article.controller';
import { AdminAuthController } from '../web/controllers/admin-auth.controller';
import { AdminArticleController } from '../web/controllers/admin-article.controller';

// Repositories
import { AuthRepository } from '../repositories/auth.repository';

// Article imports
import { ArticleService } from '../../application/services/article.service';
import { PgArticleRepository } from '../repositories/pg-article.repository';

// Admin imports
import { AdminAuthService } from '../../application/services/admin-auth.service';
import { AdminRoleRepository } from '../repositories/admin-role.repository';
import { SecurityEventRepository } from '../repositories/security-event.repository';
import { SecurityMonitor } from '../security/monitoring/security-monitor';
import { SecurityMonitorController } from '../web/controllers/security-monitor.controller';
import { DatabaseConnection } from '../database/database.connection';

// Services (임시 구현)
import { Logger } from '../logging/Logger';
import { RealEmailService } from '../email/real-email.service';

const logger = new Logger('Container');

// Import production container setup
import { setupProductionContainer } from './container.prod';

/**
 * Development-only Mock Services
 * WARNING: These should NEVER be used in production!
 * Only for local development and testing
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
    const userId = user.id?.getValue() || `user-${Date.now()}`;
    
    // 실제 데이터베이스에 저장 (간단한 버전)
    const { Pool } = require('pg');
    const pool = new Pool({
      host: 'localhost',
      port: 5432,
      database: 'paperly_db',
      user: 'paperly_user',
      password: 'paperly_dev_password'
    });
    
    try {
      const client = await pool.connect();
      await client.query('SET search_path TO paperly');
      
      // 이미 존재하는지 확인
      const existingUser = await client.query(
        'SELECT id FROM users WHERE id = $1',
        [userId]
      );
      
      if (existingUser.rows.length === 0) {
        // 새 사용자 저장 (간단한 버전)
        await client.query(
          `INSERT INTO users (id, email, password_hash, name, birth_date, gender, status, created_at) 
           VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())`,
          [userId, emailStr, 'hashed_password', user.name, '1990-01-01', 'other', 'active']
        );
        logger.info('실제 DB에 사용자 저장됨', { userId, email: emailStr, name: user.name });
      }
      
      client.release();
      pool.end();
    } catch (error) {
      logger.error('사용자 저장 중 에러 (DB에 저장 시도)', { error });
    }
    
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

  async findByUsername(username: string) {
    logger.info('Mock: 사용자명으로 사용자 조회', { username });
    
    // 테스트용으로 몇 개의 사용자명을 사용 중으로 시뮬레이션
    const usedUsernames = ['admin', 'test', 'user', 'writer', 'author', 'paperly'];
    
    if (usedUsernames.includes(username.toLowerCase())) {
      return {
        id: { getValue: () => `mock-user-${username}` },
        email: { getValue: () => `${username}@example.com` },
        name: username,
        emailVerified: true
      };
    }
    
    return null;
  }

  async existsByUsername(username: string) {
    logger.info('Mock: 사용자명 존재 여부 확인', { username });
    
    // 테스트용으로 몇 개의 사용자명을 사용 중으로 시뮬레이션
    const usedUsernames = ['admin', 'test', 'user', 'writer', 'author', 'paperly'];
    
    return usedUsernames.includes(username.toLowerCase());
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
  generateTokenPair(userId: string, email: string) {
    const timestamp = Date.now();
    logger.info('Mock: JWT 토큰 쌍 생성', { userId, email });
    
    return {
      accessToken: `mock_access_${userId}_${timestamp}`,
      refreshToken: `mock_refresh_${userId}_${timestamp}`
    };
  }
  
  generateAccessToken(userId: string, email: string) {
    const timestamp = Date.now();
    return `mock_access_${userId}_${timestamp}`;
  }
  
  generateRefreshToken(userId: string, email: string) {
    const timestamp = Date.now();
    return `mock_refresh_${userId}_${timestamp}`;
  }
  
  verifyAccessToken(token: string) {
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

// Message Service
import { MessageService, createMessageService } from '../services/message.service';
import { ResponseUtil, createResponseUtil } from '../../shared/utils/response.util';

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
  
  async saveRefreshToken(
    userId: string, 
    token: string, 
    expiresAt: Date, 
    deviceId?: string, 
    userAgent?: string, 
    ipAddress?: string
  ): Promise<void> {
    // Mock implementation - just return success
    return Promise.resolve();
  }
  
  async updateLastUsed(token: string): Promise<void> {
    // Mock implementation - just return success
    return Promise.resolve();
  }
  
  async revokeAllByUserId(userId: any): Promise<void> {
    return Promise.resolve();
  }
  
  async revokeByToken(token: any): Promise<void> {
    return Promise.resolve();
  }
  
  async cleanupExpiredTokens(): Promise<void> {
    return Promise.resolve();
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

  async createEmailVerificationToken(userId: string) {
    const token = `verify_${userId}_${Date.now()}_${Math.random().toString(36)}`;
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24시간
    
    await this.saveEmailVerificationToken(userId, token, expiresAt);
    
    logger.info('Mock: 이메일 인증 토큰 생성됨', { userId, token });
    
    return {
      token,
      expiresAt
    };
  }
}

/**
 * DI Container 설정
 */
export function setupContainer() {
  const isProduction = process.env.NODE_ENV === 'production';
  const isDevelopment = process.env.NODE_ENV === 'development' || !process.env.NODE_ENV;
  
  logger.info(`Setting up DI container for ${process.env.NODE_ENV || 'development'} environment...`);
  
  // Use production container in production
  if (isProduction) {
    return setupProductionContainer();
  }
  
  // Development mode setup
  logger.warn('⚠️  Using MOCK services for development. These should NEVER be used in production!');
  
  // Import real implementations for mixed mode
  const { UserRepository } = require('../repositories/user.repository');
  const { RefreshTokenRepository } = require('../repositories/refresh-token.repository');
  const { EmailVerificationRepository } = require('../repositories/email-verification.repository');
  const { TokenService } = require('../services/token.service');
  
  // Repositories - Use mocks in development
  logger.info('Registering Mock UserRepository for development...');
  container.registerSingleton('UserRepository', MockUserRepository);
  logger.info('Registering other repositories...');
  container.registerSingleton('RefreshTokenRepository', MockRefreshTokenRepository);
  container.registerSingleton('EmailVerificationRepository', MockEmailVerificationRepository);
  container.registerSingleton('LoginAttemptRepository', MockLoginAttemptRepository);
  container.registerSingleton(AuthRepository, MockAuthRepository);

  // Services
  logger.info('Registering services...');
  container.register('EmailService', {
    useClass: RealEmailService
  });
  container.register('TokenService', {
    useClass: TokenService
  });

  // Use Cases
  logger.info('Registering use cases...');
  container.registerSingleton(RegisterUseCase, RegisterUseCase);
  container.registerSingleton(LoginUseCase, LoginUseCase);
  container.registerSingleton(RefreshTokenUseCase, RefreshTokenUseCase);
  container.registerSingleton(VerifyEmailUseCase, VerifyEmailUseCase);
  container.registerSingleton(ResendVerificationUseCase, ResendVerificationUseCase);
  container.registerSingleton(LogoutUseCase, LogoutUseCase);

  // Article related registrations
  logger.info('Registering article related services...');
  
  // Need to register DatabasePool first
  const { Pool } = require('pg');
  const pool = new Pool({
    host: 'localhost',
    port: 5432,
    database: 'paperly_db',
    user: 'paperly_user',
    password: 'paperly_dev_password'
  });
  
  container.registerInstance('DatabasePool', pool);
  container.register('ArticleRepository', { useClass: PgArticleRepository });
  container.registerSingleton('ArticleService', ArticleService);

  // Like service and repositories
  logger.info('Registering like service and repositories...');
  const { PostgresLikeRepository, PostgresArticleStatsRepository } = require('../repositories/like.repository');
  const { LikeService } = require('../../application/services/like.service');
  
  container.register('LikeRepository', { 
    useFactory: () => new PostgresLikeRepository(pool)
  });
  container.register('ArticleStatsRepository', { 
    useFactory: () => new PostgresArticleStatsRepository(pool)
  });
  container.registerSingleton('LikeService', LikeService);
  
  // Message Service 등록
  const messageService = createMessageService(pool);
  container.registerInstance('MessageService', messageService);
  container.registerInstance('ResponseUtil', createResponseUtil(messageService));
  
  // Import repository classes
  const { CategoryRepository } = require('../repositories/category.repository');
  const { TagRepository } = require('../repositories/tag.repository');
  
  // Register Category and Tag repositories
  container.register('CategoryRepository', { useClass: CategoryRepository });
  container.register('TagRepository', { useClass: TagRepository });

  // Controllers
  logger.info('Registering controllers...');
  container.registerSingleton(AuthController, AuthController);
  container.registerSingleton(ArticleController, ArticleController);
  container.registerSingleton(AdminArticleController, AdminArticleController);
  
  // Mobile controllers
  const { MobileArticleController } = require('../web/controllers/mobile-article.controller');
  container.registerSingleton(MobileArticleController, MobileArticleController);

  // Admin services registration
  logger.info('Registering admin services...');
  
  // Database connection for admin services
  container.registerSingleton(DatabaseConnection, DatabaseConnection);
  
  // Security event repository
  container.registerSingleton(SecurityEventRepository, SecurityEventRepository);
  
  // Security monitor with dependency injection
  container.registerSingleton(SecurityMonitor, SecurityMonitor);
  
  // Admin repositories and services
  container.registerSingleton(AdminRoleRepository, AdminRoleRepository);
  container.register('AdminAuthService', { useClass: AdminAuthService });
  container.registerSingleton(AdminAuthController, AdminAuthController);
  container.registerSingleton(SecurityMonitorController, SecurityMonitorController);

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