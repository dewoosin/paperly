/**
 * Logger.ts
 * 
 * Winston 기반의 엔터프라이즈급 로거
 * 환경별 로그 레벨, 포맷, 전송 방식을 다르게 설정
 */

import winston from 'winston';
import DailyRotateFile from 'winston-daily-rotate-file';
import { hostname } from 'os';

/**
 * 로그 레벨 정의
 */
const logLevels = {
  error: 0,
  warn: 1,
  info: 2,
  http: 3,
  debug: 4,
};

/**
 * 환경별 로그 레벨
 */
const getLogLevel = (): string => {
  const env = process.env.NODE_ENV || 'development';
  return env === 'development' ? 'debug' : 'info';
};

/**
 * 로그 포맷 정의
 */
const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
  winston.format.errors({ stack: true }),
  winston.format.json(),
);

/**
 * 개발 환경용 컬러 포맷
 */
const devFormat = winston.format.combine(
  winston.format.colorize(),
  winston.format.timestamp({ format: 'HH:mm:ss.SSS' }),
  winston.format.printf(({ timestamp, level, message, context, ...meta }) => {
    const contextStr = context ? `[${context}]` : '';
    const metaStr = Object.keys(meta).length ? JSON.stringify(meta, null, 2) : '';
    return `${timestamp} ${level} ${contextStr} ${message} ${metaStr}`;
  }),
);

/**
 * 파일 로테이션 설정
 */
const fileRotateTransport = new DailyRotateFile({
  filename: 'logs/paperly-%DATE%.log',
  datePattern: 'YYYY-MM-DD',
  zippedArchive: true,
  maxSize: '20m',
  maxFiles: '14d',
  format: logFormat,
});

/**
 * 에러 전용 파일 로테이션
 */
const errorFileTransport = new DailyRotateFile({
  filename: 'logs/paperly-error-%DATE%.log',
  datePattern: 'YYYY-MM-DD',
  zippedArchive: true,
  maxSize: '20m',
  maxFiles: '30d',
  level: 'error',
  format: logFormat,
});

/**
 * Winston 로거 인스턴스 생성
 */
const winstonLogger = winston.createLogger({
  levels: logLevels,
  level: getLogLevel(),
  format: logFormat,
  defaultMeta: {
    service: 'paperly-backend',
    hostname: hostname(),
    pid: process.pid,
  },
  transports: [
    // 프로덕션 환경에서는 파일로 저장
    ...(process.env.NODE_ENV === 'production' ? [
      fileRotateTransport,
      errorFileTransport,
    ] : []),
  ],
});

/**
 * 개발 환경에서는 콘솔 출력 추가
 */
if (process.env.NODE_ENV !== 'production') {
  winstonLogger.add(new winston.transports.Console({
    format: devFormat,
  }));
}

/**
 * 로거 클래스
 * 컨텍스트별로 로거 인스턴스를 생성하여 사용
 * 
 * @example
 * const logger = new Logger('UserService');
 * logger.info('User created', { userId: 123 });
 */
export class Logger {
  private context: string;
  private logger: winston.Logger;

  constructor(context: string) {
    this.context = context;
    this.logger = winstonLogger;
  }

  /**
   * 에러 로그
   */
  error(message: string, error?: any, meta?: any): void {
    this.logger.error(message, {
      context: this.context,
      error: this.serializeError(error),
      ...meta,
    });
  }

  /**
   * 경고 로그
   */
  warn(message: string, meta?: any): void {
    this.logger.warn(message, {
      context: this.context,
      ...meta,
    });
  }

  /**
   * 정보 로그
   */
  info(message: string, meta?: any): void {
    this.logger.info(message, {
      context: this.context,
      ...meta,
    });
  }

  /**
   * HTTP 요청 로그
   */
  http(message: string, meta?: any): void {
    this.logger.http(message, {
      context: this.context,
      ...meta,
    });
  }

  /**
   * 디버그 로그
   */
  debug(message: string, meta?: any): void {
    this.logger.debug(message, {
      context: this.context,
      ...meta,
    });
  }

  /**
   * 성능 측정 로그
   */
  performance(operation: string, duration: number, meta?: any): void {
    const level = duration > 1000 ? 'warn' : 'info';
    this.logger.log(level, `Performance: ${operation}`, {
      context: this.context,
      duration,
      durationPretty: `${duration}ms`,
      ...meta,
    });
  }

  /**
   * 에러 객체 직렬화
   */
  private serializeError(error: any): any {
    if (!error) return null;
    
    if (error instanceof Error) {
      return {
        name: error.name,
        message: error.message,
        stack: error.stack,
        ...error,
      };
    }
    
    return error;
  }

  /**
   * 자식 로거 생성
   */
  child(subContext: string): Logger {
    return new Logger(`${this.context}:${subContext}`);
  }
}

/**
 * Express 미들웨어용 HTTP 로거
 */
export const httpLogger = winston.createLogger({
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json(),
  ),
  transports: [
    new winston.transports.Console({
      format: process.env.NODE_ENV === 'production' ? logFormat : devFormat,
    }),
  ],
});

/**
 * Morgan 스트림 어댑터
 */
export const morganStream = {
  write: (message: string) => {
    httpLogger.info(message.trim());
  },
};
