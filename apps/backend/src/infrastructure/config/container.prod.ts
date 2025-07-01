// apps/backend/src/infrastructure/config/container.prod.ts

import 'reflect-metadata';
import { container } from 'tsyringe';
import { Pool } from 'pg';

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
import { UserRepository } from '../repositories/user.repository';
import { RefreshTokenRepository } from '../repositories/refresh-token.repository';
import { EmailVerificationRepository } from '../repositories/email-verification.repository';
import { LoginAttemptRepository } from '../repositories/login-attempt.repository';
import { CategoryRepository } from '../repositories/category.repository';
import { TagRepository } from '../repositories/tag.repository';

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

// Services
import { Logger } from '../logging/Logger';
import { RealEmailService } from '../email/real-email.service';
import { TokenService } from '../services/token.service';
import { createMessageService } from '../services/message.service';
import { createResponseUtil } from '../../shared/utils/response.util';

const logger = new Logger('Container');

/**
 * Production DI Container Configuration
 */
export function setupProductionContainer() {
  logger.info('Setting up production DI container...');

  // Database configuration from environment
  const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    database: process.env.DB_NAME || 'paperly_db',
    user: process.env.DB_USER || 'paperly_user',
    password: process.env.DB_PASSWORD || '',
    max: parseInt(process.env.DB_POOL_SIZE || '20'),
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
  };

  // Validate required environment variables
  if (!process.env.DB_PASSWORD) {
    throw new Error('DB_PASSWORD environment variable is required in production');
  }
  if (!process.env.JWT_SECRET) {
    throw new Error('JWT_SECRET environment variable is required in production');
  }

  // Create database pool
  const pool = new Pool(dbConfig);
  
  // Test database connection
  pool.query('SELECT NOW()', (err) => {
    if (err) {
      logger.error('Failed to connect to database', err);
      throw new Error('Database connection failed');
    }
    logger.info('Database connection established');
  });

  // Register database pool
  container.registerInstance('DatabasePool', pool);
  
  // Register repositories
  logger.info('Registering repositories...');
  container.registerSingleton('UserRepository', UserRepository);
  container.registerSingleton('RefreshTokenRepository', RefreshTokenRepository);
  container.registerSingleton('EmailVerificationRepository', EmailVerificationRepository);
  container.registerSingleton('LoginAttemptRepository', LoginAttemptRepository);
  container.registerSingleton(AuthRepository, AuthRepository);
  container.register('ArticleRepository', { useClass: PgArticleRepository });
  container.register('CategoryRepository', { useClass: CategoryRepository });
  container.register('TagRepository', { useClass: TagRepository });
  container.registerSingleton(AdminRoleRepository, AdminRoleRepository);
  container.registerSingleton(SecurityEventRepository, SecurityEventRepository);

  // Register services
  logger.info('Registering services...');
  container.register('EmailService', { useClass: RealEmailService });
  container.register('TokenService', { useClass: TokenService });
  container.registerSingleton('ArticleService', ArticleService);
  container.register('AdminAuthService', { useClass: AdminAuthService });
  
  // Register message service and response util
  const messageService = createMessageService(pool);
  container.registerInstance('MessageService', messageService);
  container.registerInstance('ResponseUtil', createResponseUtil(messageService));

  // Register use cases
  logger.info('Registering use cases...');
  container.registerSingleton(RegisterUseCase, RegisterUseCase);
  container.registerSingleton(LoginUseCase, LoginUseCase);
  container.registerSingleton(RefreshTokenUseCase, RefreshTokenUseCase);
  container.registerSingleton(VerifyEmailUseCase, VerifyEmailUseCase);
  container.registerSingleton(ResendVerificationUseCase, ResendVerificationUseCase);
  container.registerSingleton(LogoutUseCase, LogoutUseCase);

  // Register controllers
  logger.info('Registering controllers...');
  container.registerSingleton(AuthController, AuthController);
  container.registerSingleton(ArticleController, ArticleController);
  container.registerSingleton(AdminArticleController, AdminArticleController);
  container.registerSingleton(AdminAuthController, AdminAuthController);
  container.registerSingleton(SecurityMonitorController, SecurityMonitorController);
  
  // Register security services
  container.registerSingleton(DatabaseConnection, DatabaseConnection);
  container.registerSingleton(SecurityMonitor, SecurityMonitor);

  logger.info('Production DI container setup completed');
  
  // Register graceful shutdown
  process.on('SIGTERM', async () => {
    logger.info('SIGTERM received, closing database pool...');
    await pool.end();
    process.exit(0);
  });
}