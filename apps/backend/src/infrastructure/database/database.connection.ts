/**
 * database.connection.ts
 * 
 * PostgreSQL 데이터베이스 연결 클래스
 * 싱글톤 패턴으로 데이터베이스 연결을 관리합니다.
 */

import { Pool, PoolClient, PoolConfig } from 'pg';
import { Logger } from '../logging/Logger';

export class DatabaseConnection {
  private static instance: DatabaseConnection;
  private pool: Pool;
  private readonly logger = new Logger('DatabaseConnection');

  private constructor() {
    // 환경별 데이터베이스 설정
    const config: PoolConfig = {
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
      ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
    };

    this.pool = new Pool(config);
    
    // 연결 이벤트 리스너
    this.pool.on('connect', () => {
      this.logger.info('데이터베이스 연결 성공');
    });
    
    this.pool.on('error', (err) => {
      this.logger.error('데이터베이스 연결 오류', { error: err });
    });
  }

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
   * 데이터베이스 쿼리 실행
   */
  public async query(text: string, params?: any[]): Promise<any> {
    const client = await this.pool.connect();
    try {
      // paperly 스키마로 설정
      await client.query('SET search_path TO paperly, public');
      const result = await client.query(text, params);
      return result;
    } finally {
      client.release();
    }
  }

  /**
   * 클라이언트 연결 반환 (트랜잭션용)
   */
  public async getClient(): Promise<PoolClient> {
    const client = await this.pool.connect();
    // paperly 스키마로 설정
    await client.query('SET search_path TO paperly, public');
    return client;
  }

  /**
   * 연결 종료
   */
  public async close(): Promise<void> {
    await this.pool.end();
    this.logger.info('데이터베이스 연결 종료');
  }

  /**
   * 연결 상태 확인
   */
  public async isConnected(): Promise<boolean> {
    try {
      await this.query('SELECT 1');
      return true;
    } catch (error) {
      this.logger.error('데이터베이스 연결 상태 확인 실패', { error });
      return false;
    }
  }
}