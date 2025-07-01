// /Users/workspace/paperly/apps/backend/src/infrastructure/logging/logger.ts

import winston from 'winston';
import { sanitizeLogData, createSanitizedLogMessage } from './log-sanitizer';

/**
 * Winston Logger 인스턴스
 * 
 * 구조화된 로깅을 제공합니다.
 * 환경에 따라 다른 로그 레벨과 포맷을 사용합니다.
 */

// 로그 레벨 정의
const logLevels = {
  error: 0,
  warn: 1,
  info: 2,
  http: 3,
  verbose: 4,
  debug: 5,
  silly: 6
};

// 환경별 로그 레벨 (env.config를 사용하지 않고 직접 process.env 사용)
const level = (() => {
  const env = process.env.NODE_ENV || 'development';
  const isDevelopment = env === 'development';
  return isDevelopment ? 'debug' : 'info';
})();

// 로그 색상 정의
const colors = {
  error: 'red',
  warn: 'yellow',
  info: 'green',
  http: 'magenta',
  verbose: 'cyan',
  debug: 'blue',
  silly: 'grey'
};

winston.addColors(colors);

// 로그 포맷 정의
const format = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
  winston.format.errors({ stack: true }),
  winston.format.splat(),
  winston.format.json()
);

// 개발 환경용 포맷
const devFormat = winston.format.combine(
  winston.format.timestamp({ format: 'HH:mm:ss.SSS' }),
  winston.format.colorize({ all: true }),
  winston.format.printf(
    (info) => {
      const { timestamp, level, message, context, ...extra } = info;
      const contextStr = context ? ` [${context}]` : '';
      const extraStr = Object.keys(extra).length ? ` ${JSON.stringify(extra, null, 2)}` : '';
      return `${timestamp} ${level}${contextStr} ${message}${extraStr}`;
    }
  )
);

// 트랜스포트 정의
const transports = [
  // 콘솔 출력
  new winston.transports.Console({
    format: process.env.NODE_ENV === 'development' ? devFormat : format,
  })
];

// 프로덕션 환경에서는 파일로도 저장
if (process.env.NODE_ENV === 'production') {
  transports.push(
    // 에러 로그 파일
    new winston.transports.File({
      filename: 'logs/error.log',
      level: 'error',
      maxsize: 10485760, // 10MB
      maxFiles: 5,
    }),
    // 전체 로그 파일
    new winston.transports.File({
      filename: 'logs/combined.log',
      maxsize: 10485760, // 10MB
      maxFiles: 5,
    })
  );
}

// Winston logger 인스턴스 생성
const winstonLogger = winston.createLogger({
  level,
  levels: logLevels,
  format,
  transports,
  exitOnError: false, // 로깅 에러 시 프로세스 종료 방지
});

/**
 * 커스텀 Logger 클래스
 * 
 * 컨텍스트 정보를 추가로 포함할 수 있는 래퍼
 */
export class Logger {
  private context?: string;
  private static hostname = require('os').hostname();

  constructor(context?: string) {
    this.context = context;
  }

  private log(level: string, message: string, meta?: any) {
    // Sanitize sensitive data before logging
    const sanitizedMessage = createSanitizedLogMessage(message, meta);
    
    const logData = {
      service: 'paperly-backend',
      hostname: Logger.hostname,
      pid: process.pid,
      context: this.context,
      ...(sanitizedMessage.data ? sanitizeLogData(sanitizedMessage.data) : {}),
      ...(meta ? sanitizeLogData(meta) : {})
    };

    winstonLogger.log(level, sanitizedMessage.message, logData);
  }

  error(message: string, error?: Error | any, meta?: any) {
    const errorMeta = error instanceof Error ? {
      error: {
        name: error.name,
        message: error.message,
        stack: error.stack
      }
    } : error;

    this.log('error', message, { ...errorMeta, ...meta });
  }

  warn(message: string, meta?: any) {
    this.log('warn', message, meta);
  }

  info(message: string, meta?: any) {
    this.log('info', message, meta);
  }

  http(message: string, meta?: any) {
    this.log('http', message, meta);
  }

  verbose(message: string, meta?: any) {
    this.log('verbose', message, meta);
  }

  debug(message: string, meta?: any) {
    this.log('debug', message, meta);
  }

  /**
   * 자식 로거 생성 (컨텍스트 상속)
   */
  child(context: string): Logger {
    const childContext = this.context ? `${this.context}:${context}` : context;
    return new Logger(childContext);
  }
}

// 기본 logger 인스턴스
export const logger = new Logger();

// Morgan HTTP 로깅용 스트림
export const morganStream = {
  write: (message: string) => {
    logger.http(message.trim());
  }
};