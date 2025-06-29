/// Paperly Backend - 입력 검증 보안 미들웨어
/// 
/// 이 파일은 모든 HTTP 요청에 대해 자동으로 보안 검증을 수행하는 Express 미들웨어를 구현합니다.
/// XSS, SQL Injection, Path Traversal 등 다양한 공격을 실시간으로 탐지하고 차단합니다.
/// 
/// 주요 기능:
/// 1. 요청 바디 검증: JSON, form-data 등 모든 형태의 입력 검증
/// 2. 쿼리 파라미터 검증: URL 쿼리 스트링 보안 검증
/// 3. 헤더 검증: 사용자 정의 헤더의 보안 위협 검증
/// 4. 파일 업로드 검증: 업로드 파일명 및 경로 검증
/// 5. 자동 새니타이징: 위험 요소 제거 또는 무력화
/// 6. 위협 로깅: 공격 시도 상세 기록 및 모니터링
/// 
/// 미들웨어 전략:
/// - 조기 차단: 위험한 요청은 애플리케이션 로직에 도달하기 전에 차단
/// - 유연한 설정: 경로별, 메서드별 다른 보안 정책 적용
/// - 성능 최적화: 빠른 검증으로 응답 속도 보장
/// - 상세 로깅: 공격 패턴 분석 및 보안 개선에 활용

import { Request, Response, NextFunction } from 'express';
import { Logger } from '../../logging/Logger';
import { SecurityValidator, FieldType, InputContext } from '../validators';
import { SecuritySanitizer, SanitizationContext, SQLSanitizationContext } from '../sanitizers';
import { securityMonitor, SecurityEventType } from '../monitoring/security-monitor';

/**
 * 보안 검증 설정 인터페이스
 */
export interface SecurityValidationConfig {
  enableXSSProtection?: boolean;           // XSS 보호 활성화
  enableSQLInjectionProtection?: boolean; // SQL Injection 보호 활성화
  enablePathTraversalProtection?: boolean;// Path Traversal 보호 활성화
  enableAutoSanitization?: boolean;       // 자동 새니타이징 활성화
  strictMode?: boolean;                   // 엄격 모드 (더 강한 보안)
  allowedFileExtensions?: string[];       // 허용할 파일 확장자
  maxRequestSize?: number;                // 최대 요청 크기 (바이트)
  logThreats?: boolean;                   // 위협 로깅 활성화
  blockOnThreat?: boolean;                // 위협 감지 시 요청 차단
  whitelistedPaths?: string[];            // 검증 예외 경로
  customRules?: SecurityRule[];           // 사용자 정의 보안 규칙
}

/**
 * 사용자 정의 보안 규칙 인터페이스
 */
export interface SecurityRule {
  name: string;                          // 규칙 이름
  pattern: RegExp;                       // 탐지 패턴
  severity: 'low' | 'medium' | 'high' | 'critical'; // 심각도
  action: 'log' | 'sanitize' | 'block'; // 대응 방식
  paths?: string[];                      // 적용할 경로 (선택사항)
  methods?: string[];                    // 적용할 HTTP 메서드 (선택사항)
}

/**
 * 필드별 검증 설정 매핑
 */
interface FieldValidationMapping {
  fieldName: string;
  fieldType: FieldType;
  inputContext: InputContext;
  sanitizationContext: SanitizationContext;
  sqlSanitizationContext: SQLSanitizationContext;
  maxLength?: number;
  required?: boolean;
}

/**
 * 입력 검증 보안 미들웨어 클래스
 */
export class InputValidationMiddleware {
  private readonly logger = new Logger('InputValidationMiddleware');
  
  /**
   * 기본 보안 설정
   */
  private readonly DEFAULT_CONFIG: SecurityValidationConfig = {
    enableXSSProtection: true,
    enableSQLInjectionProtection: true,
    enablePathTraversalProtection: true,
    enableAutoSanitization: true,
    strictMode: false,
    allowedFileExtensions: ['.jpg', '.jpeg', '.png', '.gif', '.pdf', '.doc', '.docx'],
    maxRequestSize: 10 * 1024 * 1024, // 10MB
    logThreats: true,
    blockOnThreat: true,
    whitelistedPaths: ['/health', '/metrics', '/favicon.ico'],
    customRules: []
  };

  /**
   * 필드별 검증 매핑 정의
   */
  private readonly FIELD_MAPPINGS: FieldValidationMapping[] = [
    // 사용자 인증 관련
    {
      fieldName: 'email',
      fieldType: FieldType.EMAIL,
      inputContext: InputContext.USER_INPUT,
      sanitizationContext: SanitizationContext.PLAIN_TEXT,
      sqlSanitizationContext: SQLSanitizationContext.EMAIL_ADDRESS,
      maxLength: 254,
      required: true
    },
    {
      fieldName: 'password',
      fieldType: FieldType.PASSWORD,
      inputContext: InputContext.USER_INPUT,
      sanitizationContext: SanitizationContext.PLAIN_TEXT,
      sqlSanitizationContext: SQLSanitizationContext.PASSWORD,
      maxLength: 128,
      required: true
    },
    {
      fieldName: 'name',
      fieldType: FieldType.TEXT,
      inputContext: InputContext.USER_INPUT,
      sanitizationContext: SanitizationContext.PLAIN_TEXT,
      sqlSanitizationContext: SQLSanitizationContext.USERNAME,
      maxLength: 100,
      required: true
    },
    // 콘텐츠 관련
    {
      fieldName: 'title',
      fieldType: FieldType.TEXT,
      inputContext: InputContext.USER_INPUT,
      sanitizationContext: SanitizationContext.BASIC_HTML,
      sqlSanitizationContext: SQLSanitizationContext.STRING_LITERAL,
      maxLength: 200,
      required: true
    },
    {
      fieldName: 'content',
      fieldType: FieldType.CONTENT,
      inputContext: InputContext.USER_INPUT,
      sanitizationContext: SanitizationContext.ARTICLE_CONTENT,
      sqlSanitizationContext: SQLSanitizationContext.STRING_LITERAL,
      maxLength: 50000
    },
    {
      fieldName: 'bio',
      fieldType: FieldType.TEXT,
      inputContext: InputContext.USER_INPUT,
      sanitizationContext: SanitizationContext.USER_BIO,
      sqlSanitizationContext: SQLSanitizationContext.STRING_LITERAL,
      maxLength: 500
    },
    // 검색 관련
    {
      fieldName: 'search',
      fieldType: FieldType.SEARCH,
      inputContext: InputContext.SEARCH_QUERY,
      sanitizationContext: SanitizationContext.PLAIN_TEXT,
      sqlSanitizationContext: SQLSanitizationContext.SEARCH_TERM,
      maxLength: 500
    },
    {
      fieldName: 'query',
      fieldType: FieldType.SEARCH,
      inputContext: InputContext.SEARCH_QUERY,
      sanitizationContext: SanitizationContext.PLAIN_TEXT,
      sqlSanitizationContext: SQLSanitizationContext.SEARCH_TERM,
      maxLength: 500
    },
    // 파일 관련
    {
      fieldName: 'filename',
      fieldType: FieldType.TEXT,
      inputContext: InputContext.FILE_NAME,
      sanitizationContext: SanitizationContext.PLAIN_TEXT,
      sqlSanitizationContext: SQLSanitizationContext.STRING_LITERAL,
      maxLength: 255
    },
    {
      fieldName: 'filepath',
      fieldType: FieldType.TEXT,
      inputContext: InputContext.FILE_PATH,
      sanitizationContext: SanitizationContext.PLAIN_TEXT,
      sqlSanitizationContext: SQLSanitizationContext.STRING_LITERAL,
      maxLength: 1000
    }
  ];

  /**
   * 미들웨어 팩토리 함수
   * 
   * 보안 설정에 따라 커스터마이징된 미들웨어 함수를 생성합니다.
   * 
   * @param config 보안 검증 설정
   * @returns Express 미들웨어 함수
   */
  public create(config?: Partial<SecurityValidationConfig>) {
    const finalConfig: SecurityValidationConfig = {
      ...this.DEFAULT_CONFIG,
      ...config
    };

    return async (req: Request, res: Response, next: NextFunction) => {
      try {
        // 화이트리스트 경로 확인
        if (this.isWhitelistedPath(req.path, finalConfig.whitelistedPaths!)) {
          return next();
        }

        // 요청 크기 제한 확인
        if (this.isRequestTooLarge(req, finalConfig.maxRequestSize!)) {
          return this.blockRequest(res, 'Request too large', 413);
        }

        // 보안 검증 수행
        const validationResult = await this.validateRequest(req, finalConfig);

        // 위협 감지 시 처리
        if (!validationResult.isValid) {
          if (finalConfig.logThreats) {
            this.logThreat(req, validationResult);
          }

          if (finalConfig.blockOnThreat) {
            return this.blockRequest(res, 'Security threat detected', 400);
          }
        }

        // 자동 새니타이징 적용
        if (finalConfig.enableAutoSanitization && validationResult.shouldSanitize) {
          this.applySanitization(req, finalConfig);
        }

        next();
      } catch (error) {
        this.logger.error('보안 검증 미들웨어 오류', error);
        next(error);
      }
    };
  }

  /**
   * 요청 보안 검증 수행
   */
  private async validateRequest(
    req: Request,
    config: SecurityValidationConfig
  ): Promise<{
    isValid: boolean;
    threats: string[];
    shouldSanitize: boolean;
    details: any;
  }> {
    const threats: string[] = [];
    const details: any = {};
    let shouldSanitize = false;

    // 1. 요청 바디 검증
    if (req.body && typeof req.body === 'object') {
      const bodyResult = await this.validateObject(req.body, 'body', config);
      if (!bodyResult.isValid) {
        threats.push(...bodyResult.threats);
        details.body = bodyResult.details;
        shouldSanitize = true;

        // 보안 모니터에 이벤트 기록
        this.recordSecurityEvents(req, bodyResult, 'body');
      }
    }

    // 2. 쿼리 파라미터 검증
    if (req.query && typeof req.query === 'object') {
      const queryResult = await this.validateObject(req.query, 'query', config);
      if (!queryResult.isValid) {
        threats.push(...queryResult.threats);
        details.query = queryResult.details;
        shouldSanitize = true;

        // 보안 모니터에 이벤트 기록
        this.recordSecurityEvents(req, queryResult, 'query');
      }
    }

    // 3. 파라미터 검증
    if (req.params && typeof req.params === 'object') {
      const paramsResult = await this.validateObject(req.params, 'params', config);
      if (!paramsResult.isValid) {
        threats.push(...paramsResult.threats);
        details.params = paramsResult.details;
        shouldSanitize = true;
      }
    }

    // 4. 헤더 검증 (사용자 정의 헤더만)
    const headerResult = await this.validateHeaders(req.headers, config);
    if (!headerResult.isValid) {
      threats.push(...headerResult.threats);
      details.headers = headerResult.details;
    }

    // 5. 파일 업로드 검증
    if (req.files || (req as any).file) {
      const fileResult = await this.validateFiles(req, config);
      if (!fileResult.isValid) {
        threats.push(...fileResult.threats);
        details.files = fileResult.details;
      }
    }

    // 6. 사용자 정의 규칙 검증
    if (config.customRules && config.customRules.length > 0) {
      const customResult = await this.validateCustomRules(req, config.customRules);
      if (!customResult.isValid) {
        threats.push(...customResult.threats);
        details.custom = customResult.details;
      }
    }

    return {
      isValid: threats.length === 0,
      threats,
      shouldSanitize,
      details
    };
  }

  /**
   * 객체 내 모든 필드 검증
   */
  private async validateObject(
    obj: any,
    context: string,
    config: SecurityValidationConfig
  ): Promise<{
    isValid: boolean;
    threats: string[];
    details: any;
  }> {
    const threats: string[] = [];
    const details: any = {};

    for (const [key, value] of Object.entries(obj)) {
      if (typeof value === 'string') {
        const fieldMapping = this.getFieldMapping(key);
        const result = SecurityValidator.validateAll(value, {
          fieldType: fieldMapping?.fieldType || FieldType.TEXT,
          inputContext: fieldMapping?.inputContext || InputContext.USER_INPUT,
          fieldName: key
        });

        if (!result.isValid) {
          threats.push(`${context}.${key}`);
          details[key] = {
            originalValue: value,
            xssThreats: result.xssResult.threats,
            sqlThreats: result.sqlResult.threats,
            pathThreats: result.pathResult.threats,
            severity: result.overallSeverity
          };
        }
      } else if (typeof value === 'object' && value !== null) {
        // 중첩 객체 재귀 검증
        const nestedResult = await this.validateObject(value, `${context}.${key}`, config);
        if (!nestedResult.isValid) {
          threats.push(...nestedResult.threats);
          details[key] = nestedResult.details;
        }
      }
    }

    return {
      isValid: threats.length === 0,
      threats,
      details
    };
  }

  /**
   * 헤더 검증
   */
  private async validateHeaders(
    headers: any,
    config: SecurityValidationConfig
  ): Promise<{
    isValid: boolean;
    threats: string[];
    details: any;
  }> {
    const threats: string[] = [];
    const details: any = {};

    // 사용자 정의 헤더만 검증 (x- 접두사)
    const customHeaders = Object.keys(headers).filter(key => 
      key.toLowerCase().startsWith('x-') || 
      key.toLowerCase().includes('custom')
    );

    for (const headerName of customHeaders) {
      const headerValue = headers[headerName];
      if (typeof headerValue === 'string') {
        const result = SecurityValidator.validateAll(headerValue, {
          fieldType: FieldType.TEXT,
          inputContext: InputContext.USER_INPUT,
          fieldName: headerName
        });

        if (!result.isValid) {
          threats.push(`header.${headerName}`);
          details[headerName] = result;
        }
      }
    }

    return {
      isValid: threats.length === 0,
      threats,
      details
    };
  }

  /**
   * 파일 업로드 검증
   */
  private async validateFiles(
    req: Request,
    config: SecurityValidationConfig
  ): Promise<{
    isValid: boolean;
    threats: string[];
    details: any;
  }> {
    const threats: string[] = [];
    const details: any = {};

    // Multer 파일 처리
    const files = req.files || (req as any).file ? [(req as any).file] : [];
    
    for (const file of files) {
      if (file && file.originalname) {
        // 파일명 검증
        const filenameResult = SecurityValidator.validateAll(file.originalname, {
          fieldType: FieldType.TEXT,
          inputContext: InputContext.FILE_NAME,
          fieldName: 'filename'
        });

        if (!filenameResult.isValid) {
          threats.push('file.originalname');
          details.filename = filenameResult;
        }

        // 파일 확장자 검증
        const ext = this.getFileExtension(file.originalname);
        if (config.allowedFileExtensions && !config.allowedFileExtensions.includes(ext)) {
          threats.push('file.extension');
          details.extension = { forbidden: ext, allowed: config.allowedFileExtensions };
        }
      }
    }

    return {
      isValid: threats.length === 0,
      threats,
      details
    };
  }

  /**
   * 사용자 정의 규칙 검증
   */
  private async validateCustomRules(
    req: Request,
    rules: SecurityRule[]
  ): Promise<{
    isValid: boolean;
    threats: string[];
    details: any;
  }> {
    const threats: string[] = [];
    const details: any = {};

    for (const rule of rules) {
      // 경로 및 메서드 필터링
      if (rule.paths && !rule.paths.some(path => req.path.includes(path))) {
        continue;
      }
      if (rule.methods && !rule.methods.includes(req.method)) {
        continue;
      }

      // 요청 전체 내용을 문자열로 변환하여 검사
      const requestContent = JSON.stringify({
        body: req.body,
        query: req.query,
        params: req.params
      });

      if (rule.pattern.test(requestContent)) {
        threats.push(rule.name);
        details[rule.name] = {
          severity: rule.severity,
          action: rule.action,
          pattern: rule.pattern.source
        };
      }
    }

    return {
      isValid: threats.length === 0,
      threats,
      details
    };
  }

  /**
   * 자동 새니타이징 적용
   */
  private applySanitization(req: Request, config: SecurityValidationConfig): void {
    try {
      // 요청 바디 새니타이징
      if (req.body && typeof req.body === 'object') {
        req.body = this.sanitizeObject(req.body, 'body');
      }

      // 쿼리 파라미터 새니타이징
      if (req.query && typeof req.query === 'object') {
        req.query = this.sanitizeObject(req.query, 'query');
      }

      this.logger.info('자동 새니타이징 적용 완료', {
        path: req.path,
        method: req.method
      });
    } catch (error) {
      this.logger.error('자동 새니타이징 실패', error);
    }
  }

  /**
   * 객체 새니타이징
   */
  private sanitizeObject(obj: any, context: string): any {
    const sanitized: any = {};

    for (const [key, value] of Object.entries(obj)) {
      if (typeof value === 'string') {
        const fieldMapping = this.getFieldMapping(key);
        
        if (fieldMapping) {
          const result = SecuritySanitizer.sanitizeAll(value, {
            htmlContext: fieldMapping.sanitizationContext,
            sqlContext: fieldMapping.sqlSanitizationContext,
            fieldName: key
          });
          sanitized[key] = result.finalValue;
        } else {
          // 기본 새니타이징
          sanitized[key] = SecuritySanitizer.quickSanitize(value);
        }
      } else if (typeof value === 'object' && value !== null) {
        // 중첩 객체 재귀 새니타이징
        sanitized[key] = this.sanitizeObject(value, `${context}.${key}`);
      } else {
        sanitized[key] = value;
      }
    }

    return sanitized;
  }

  /**
   * 필드 매핑 조회
   */
  private getFieldMapping(fieldName: string): FieldValidationMapping | undefined {
    return this.FIELD_MAPPINGS.find(mapping => 
      mapping.fieldName === fieldName ||
      fieldName.toLowerCase().includes(mapping.fieldName.toLowerCase())
    );
  }

  /**
   * 화이트리스트 경로 확인
   */
  private isWhitelistedPath(path: string, whitelistedPaths: string[]): boolean {
    return whitelistedPaths.some(whitelistedPath => 
      path.startsWith(whitelistedPath)
    );
  }

  /**
   * 요청 크기 확인
   */
  private isRequestTooLarge(req: Request, maxSize: number): boolean {
    const contentLength = req.get('content-length');
    return contentLength ? parseInt(contentLength) > maxSize : false;
  }

  /**
   * 파일 확장자 추출
   */
  private getFileExtension(filename: string): string {
    return filename.toLowerCase().substring(filename.lastIndexOf('.'));
  }

  /**
   * 위협 로깅
   */
  private logThreat(req: Request, validationResult: any): void {
    this.logger.warn('보안 위협 감지', {
      ip: req.ip,
      userAgent: req.get('user-agent'),
      path: req.path,
      method: req.method,
      threats: validationResult.threats,
      details: validationResult.details,
      timestamp: new Date().toISOString()
    });
  }

  /**
   * 요청 차단
   */
  private blockRequest(res: Response, message: string, statusCode: number): void {
    res.status(statusCode).json({
      success: false,
      error: {
        code: 'SECURITY_VIOLATION',
        message
      }
    });
  }

  /**
   * 보안 이벤트 기록
   */
  private recordSecurityEvents(
    req: Request,
    validationResult: {
      isValid: boolean;
      threats: string[];
      details: any;
    },
    context: string
  ): void {
    const source = {
      ip: req.ip || req.connection.remoteAddress || 'unknown',
      userAgent: req.get('user-agent'),
      userId: (req as any).user?.id,
      sessionId: (req as any).sessionID,
      deviceId: req.get('x-device-id')
    };

    const target = {
      endpoint: req.path,
      method: req.method,
      parameters: context === 'body' ? req.body : context === 'query' ? req.query : req.params,
      headers: req.headers
    };

    // 각 세부 검증 결과에 따라 개별 이벤트 기록
    Object.entries(validationResult.details).forEach(([fieldName, fieldDetails]: [string, any]) => {
      if (fieldDetails.xssThreats && fieldDetails.xssThreats.length > 0) {
        securityMonitor.recordXSSAttack(
          source,
          { ...target, endpoint: `${target.endpoint}#${fieldName}` },
          {
            isValid: false,
            threats: fieldDetails.xssThreats,
            severity: fieldDetails.severity || 'medium',
            detectedPatterns: fieldDetails.xssThreats,
            riskScore: fieldDetails.riskScore || 50
          },
          fieldDetails.originalValue || ''
        );
      }

      if (fieldDetails.sqlThreats && fieldDetails.sqlThreats.length > 0) {
        securityMonitor.recordSQLInjectionAttack(
          source,
          { ...target, endpoint: `${target.endpoint}#${fieldName}` },
          {
            isValid: false,
            threats: fieldDetails.sqlThreats,
            severity: fieldDetails.severity || 'medium',
            detectedKeywords: fieldDetails.sqlThreats,
            riskScore: fieldDetails.riskScore || 50
          },
          fieldDetails.originalValue || ''
        );
      }

      if (fieldDetails.pathThreats && fieldDetails.pathThreats.length > 0) {
        securityMonitor.recordPathTraversalAttack(
          source,
          { ...target, endpoint: `${target.endpoint}#${fieldName}` },
          {
            isValid: false,
            threats: fieldDetails.pathThreats,
            severity: fieldDetails.severity || 'medium',
            detectedPatterns: fieldDetails.pathThreats,
            riskScore: fieldDetails.riskScore || 50
          },
          fieldDetails.originalValue || ''
        );
      }
    });
  }
}

/**
 * 입력 검증 미들웨어 싱글톤 인스턴스
 */
export const inputValidationMiddleware = new InputValidationMiddleware();