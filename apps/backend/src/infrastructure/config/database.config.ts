/**
 * database.config.ts
 * 
 * PostgreSQL 데이터베이스 연결 설정 및 연결 풀 관리
 * 환경별로 다른 설정을 적용하고, 연결 상태를 모니터링
 */

import { Pool, PoolConfig, PoolClient } from 'pg';
import { Logger } from '../logging/Logger';
import { BaseError, ErrorCode } from '../../shared/errors/BaseError';

/**
 * 데이터베이스 설정 인터페이스
 */
interface DatabaseConfig extends PoolConfig {
  // 추가 설정
  enableSSL?: boolean;
  poolSize?: {
    min: number;
    max: number;
  };
  idleTimeoutMillis?: number;
  connectionTimeoutMillis?: number;
}

/**
 * 환경별 데이터베이스 설정
 */
const configs: Record<string, DatabaseConfig> = {
  development: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    database: process.env.DB_NAME || 'paperly_db',
    user: process.env.DB_USER || 'paperly_user',
    password: process.env.DB_PASSWORD || 'paperly_dev_password',
    
    // 연결 풀 설정
    min: 2,
    max: 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
    
    // 개발 환경에서는 SSL 비활성화
    ssl: false,
  },
  
  test: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    database: process.env.DB_NAME || 'paperly_test',
    user: process.env.DB_USER || 'paperly_user',
    password: process.env.DB_PASSWORD || 'paperly_dev_password',
    
    // 테스트 환경은 작은 풀 사이즈
    min: 1,
    max: 5,
    idleTimeoutMillis: 10000,
    connectionTimeoutMillis: 1000,
    
    ssl: false,
  },
  
  production: {
    host: process.env.DB_HOST!,
    port: parseInt(process.env.DB_PORT!),
    database: process.env.DB_NAME!,
    user: process.env.DB_USER!,
    password: process.env.DB_PASSWORD!,
    
    // 프로덕션 환경은 큰 풀 사이즈
    min: 10,
    max: 50,
    idleTimeoutMillis: 60000,
    connectionTimeoutMillis: 5000,
    
    // 프로덕션에서는 SSL 필수
    ssl: {
      rejectUnauthorized: true,
      ca: process.env.DB_SSL_CA,
    },
  },
};

/**
 * 데이터베이스 연결 풀 관리 클래스
 * 싱글톤 패턴으로 구현하여 애플리케이션 전체에서 하나의 풀만 사용
 */
export class DatabaseConnection {
  private static instance: DatabaseConnection;
  private pool: Pool | null = null;
  private logger = new Logger('DatabaseConnection');
  private isShuttingDown = false;

  private constructor() {}

  /**
   * 싱글톤 인스턴스 반환
   */
  public static getInstance(): DatabaseConnection {
    if (!DatabaseConnection.instance) {
      DatabaseConnection.instance = new DatabaseConnection();
    }
    return DatabaseConnection.instance;
  }

  /**
   * 데이터베이스 연결 풀 초기화
   */
  public async initialize(): Promise<void> {
    if (this.pool) {
      this.logger.warn('Database pool already initialized');
      return;
    }

    const env = process.env.NODE_ENV || 'development';
    const config = configs[env];

    if (!config) {
      throw new BaseError(
        `No database configuration found for environment: ${env}`,
        ErrorCode.DATABASE_ERROR
      );
    }

    try {
      this.logger.info('Initializing database connection pool...', { env });
      
      this.pool = new Pool(config);
      
      // 연결 풀 이벤트 리스너
      this.setupPoolEventListeners();
      
      // 연결 테스트
      await this.testConnection();
      
      this.logger.info('Database connection pool initialized successfully');
    } catch (error) {
      this.logger.error('Failed to initialize database connection', error);
      throw new BaseError(
        'Database connection failed',
        ErrorCode.DATABASE_ERROR,
        { originalError: error }
      );
    }
  }

  /**
   * 연결 풀 이벤트 리스너 설정
   */
  private setupPoolEventListeners(): void {
    if (!this.pool) return;

    // 새 클라이언트 연결 시
    this.pool.on('connect', (client) => {
      this.logger.debug('New client connected to pool');
    });

    // 클라이언트 에러 발생 시
    this.pool.on('error', (err, client) => {
      this.logger.error('Unexpected error on idle client', err);
    });

    // 클라이언트 제거 시
    this.pool.on('remove', () => {
      this.logger.debug('Client removed from pool');
    });
  }

  /**
   * 데이터베이스 연결 테스트
   */
  private async testConnection(): Promise<void> {
    const client = await this.getClient();
    try {
      // paperly 스키마로 search_path 설정
      await client.query('SET search_path TO paperly, public');
      
      const result = await client.query('SELECT NOW()');
      this.logger.info('Database connection test successful', {
        serverTime: result.rows[0].now,
      });
    } finally {
      client.release();
    }
  }

  /**
   * 연결 풀에서 클라이언트 가져오기
   */
  public async getClient(): Promise<PoolClient> {
    if (!this.pool) {
      throw new BaseError(
        'Database pool not initialized',
        ErrorCode.DATABASE_ERROR
      );
    }

    if (this.isShuttingDown) {
      throw new BaseError(
        'Database is shutting down',
        ErrorCode.SERVICE_UNAVAILABLE
      );
    }

    try {
      const client = await this.pool.connect();
      
      // 각 클라이언트 연결마다 paperly 스키마를 기본으로 설정
      await client.query('SET search_path TO paperly, public');
      
      // 클라이언트에 추가 메타데이터 설정
      const originalQuery = client.query.bind(client);
      const startTime = Date.now();
      
      // 쿼리 로깅을 위한 래퍼
      client.query = async (...args: any[]) => {
        const queryStartTime = Date.now();
        try {
          const result = await originalQuery(...args);
          const duration = Date.now() - queryStartTime;
          
          // 느린 쿼리 로깅 (100ms 이상)
          if (duration > 100) {
            this.logger.warn('Slow query detected', {
              query: args[0],
              duration,
            });
          }
          
          return result;
        } catch (error) {
          this.logger.error('Query error', {
            query: args[0],
            error,
          });
          throw error;
        }
      };
      
      return client;
    } catch (error) {
      this.logger.error('Failed to get database client', error);
      throw new BaseError(
        'Failed to get database connection',
        ErrorCode.DATABASE_ERROR,
        { originalError: error }
      );
    }
  }

  /**
   * 트랜잭션 실행 헬퍼
   */
  public async transaction<T>(
    callback: (client: PoolClient) => Promise<T>
  ): Promise<T> {
    const client = await this.getClient();
    
    try {
      await client.query('BEGIN');
      const result = await callback(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * 연결 풀 상태 확인
   */
  public getPoolStats() {
    if (!this.pool) {
      return null;
    }

    return {
      totalCount: this.pool.totalCount,
      idleCount: this.pool.idleCount,
      waitingCount: this.pool.waitingCount,
    };
  }

  /**
   * 데이터베이스 연결 종료
   */
  public async close(): Promise<void> {
    if (!this.pool) {
      return;
    }

    this.isShuttingDown = true;
    this.logger.info('Closing database connection pool...');
    
    try {
      await this.pool.end();
      this.pool = null;
      this.logger.info('Database connection pool closed successfully');
    } catch (error) {
      this.logger.error('Error closing database connection pool', error);
      throw error;
    }
  }
}

/**
 * 데이터베이스 연결 인스턴스 export
 */
export const db = DatabaseConnection.getInstance();
