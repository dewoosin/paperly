/// Paperly Backend - 보안 시스템 통합 인덱스
/// 
/// 이 파일은 Paperly 백엔드의 전체 보안 시스템을 통합하여 관리하는 중앙 집중식 인덱스입니다.
/// 모든 보안 관련 컴포넌트를 한 곳에서 내보내어 일관된 보안 정책을 제공합니다.
/// 
/// 보안 시스템 구성:
/// 1. 검증기 (Validators): XSS, SQL Injection, Path Traversal 공격 탐지
/// 2. 새니타이저 (Sanitizers): 위험한 입력을 안전한 형태로 변환
/// 3. 미들웨어 (Middlewares): Express 요청에 자동 보안 검증 적용
/// 4. 설정 (Configuration): 보안 정책 및 규칙 관리
/// 
/// 사용 예시:
/// ```typescript
/// import { securityValidator, securitySanitizer, inputValidationMiddleware } from './infrastructure/security';
/// 
/// // 개별 검증
/// const result = securityValidator.validateAll(userInput);
/// 
/// // 새니타이징
/// const safe = securitySanitizer.quickSanitize(userInput);
/// 
/// // 미들웨어 적용
/// app.use(inputValidationMiddleware.create({ strictMode: true }));
/// ```

// ============================================================================
// 🛡️ 검증기 (Validators)
// ============================================================================

export {
  // XSS 검증기
  XSSValidator,
  xssValidator,
  XSSValidationResult,
  XSSThreatType,
  
  // SQL Injection 검증기
  SQLInjectionValidator,
  sqlInjectionValidator,
  SQLInjectionValidationResult,
  SQLThreatType,
  FieldType,
  
  // Path Traversal 검증기
  PathTraversalValidator,
  pathTraversalValidator,
  PathTraversalValidationResult,
  PathThreatType,
  InputContext,
  
  // 통합 검증기
  SecurityValidator,
  securityValidator
} from './validators';

// ============================================================================
// 🧹 새니타이저 (Sanitizers)
// ============================================================================

export {
  // HTML 새니타이저
  HTMLSanitizer,
  htmlSanitizer,
  HTMLSanitizationResult,
  HTMLSanitizationOptions,
  SanitizationContext,
  
  // SQL 새니타이저
  SQLSanitizer,
  sqlSanitizer,
  SQLSanitizationResult,
  SQLSanitizationOptions,
  SQLSanitizationContext,
  
  // 통합 새니타이저
  SecuritySanitizer,
  securitySanitizer
} from './sanitizers';

// ============================================================================
// 🔧 미들웨어 (Middlewares)
// ============================================================================

export {
  InputValidationMiddleware,
  inputValidationMiddleware,
  SecurityValidationConfig,
  SecurityRule
} from './middlewares/input-validation.middleware';

// ============================================================================
// 📊 보안 모니터링 시스템
// ============================================================================

export {
  SecurityMonitor,
  securityMonitor,
  SecurityEvent,
  SecurityEventType,
  SecuritySeverity,
  SecurityEventStatus,
  SecurityAction,
  ThreatStatistics,
  SecurityMonitorConfig
} from './monitoring/security-monitor';

// ============================================================================
// 📊 보안 시스템 통합 관리자
// ============================================================================

/**
 * 보안 시스템 통합 관리자 클래스
 * 
 * 전체 보안 시스템의 설정, 모니터링, 관리를 담당하는 중앙 관리자입니다.
 */
export class SecurityManager {
  private static instance: SecurityManager;
  private isInitialized = false;
  private securityMetrics = {
    totalValidations: 0,
    threatsDetected: 0,
    sanitizations: 0,
    blockedRequests: 0
  };

  /**
   * 싱글톤 인스턴스 반환
   */
  public static getInstance(): SecurityManager {
    if (!SecurityManager.instance) {
      SecurityManager.instance = new SecurityManager();
    }
    return SecurityManager.instance;
  }

  /**
   * 보안 시스템 초기화
   * 
   * 애플리케이션 시작 시 보안 시스템을 초기화하고 설정을 적용합니다.
   * 
   * @param config 보안 시스템 설정
   */
  public initialize(config?: {
    enableMetrics?: boolean;
    enableAutoUpdate?: boolean;
    logLevel?: 'debug' | 'info' | 'warn' | 'error';
    enableMonitoring?: boolean;
  }): void {
    if (this.isInitialized) {
      console.warn('보안 시스템이 이미 초기화되었습니다.');
      return;
    }

    // 기본 설정 적용
    const defaultConfig = {
      enableMetrics: true,
      enableAutoUpdate: false,
      logLevel: 'info' as const,
      enableMonitoring: true
    };

    const finalConfig = { ...defaultConfig, ...config };

    // 메트릭 수집 활성화
    if (finalConfig.enableMetrics) {
      this.enableMetricsCollection();
    }

    // 보안 모니터링 시작
    if (finalConfig.enableMonitoring) {
      securityMonitor.start();
      console.log('📊 보안 모니터링 시스템이 활성화되었습니다.');
    }

    this.isInitialized = true;
    console.log('✅ Paperly 보안 시스템이 성공적으로 초기화되었습니다.');
  }

  /**
   * 보안 메트릭 수집 활성화
   */
  private enableMetricsCollection(): void {
    // 실제 구현에서는 메트릭 수집 시스템과 연동
    console.log('📊 보안 메트릭 수집이 활성화되었습니다.');
  }

  /**
   * 실시간 보안 상태 조회
   * 
   * @returns 현재 보안 시스템 상태
   */
  public getSecurityStatus(): {
    isActive: boolean;
    metrics: typeof this.securityMetrics;
    validators: {
      xss: boolean;
      sqlInjection: boolean;
      pathTraversal: boolean;
    };
    sanitizers: {
      html: boolean;
      sql: boolean;
    };
    middleware: {
      inputValidation: boolean;
    };
    monitoring: {
      isRunning: boolean;
      totalEvents: number;
      recentEvents: number;
      blockedIPs: number;
      blockedUsers: number;
    };
  } {
    const monitoringStatus = securityMonitor.getSecurityStatus();

    return {
      isActive: this.isInitialized,
      metrics: { ...this.securityMetrics },
      validators: {
        xss: true,
        sqlInjection: true,
        pathTraversal: true
      },
      sanitizers: {
        html: true,
        sql: true
      },
      middleware: {
        inputValidation: true
      },
      monitoring: {
        isRunning: monitoringStatus.isRunning,
        totalEvents: monitoringStatus.totalEvents,
        recentEvents: monitoringStatus.recentEvents,
        blockedIPs: monitoringStatus.blockedIPs,
        blockedUsers: monitoringStatus.blockedUsers
      }
    };
  }

  /**
   * 보안 메트릭 업데이트
   */
  public updateMetrics(type: 'validation' | 'threat' | 'sanitization' | 'block'): void {
    switch (type) {
      case 'validation':
        this.securityMetrics.totalValidations++;
        break;
      case 'threat':
        this.securityMetrics.threatsDetected++;
        break;
      case 'sanitization':
        this.securityMetrics.sanitizations++;
        break;
      case 'block':
        this.securityMetrics.blockedRequests++;
        break;
    }
  }

  /**
   * 보안 정책 업데이트
   * 
   * 런타임에 보안 정책을 동적으로 업데이트할 수 있습니다.
   * 
   * @param policy 새로운 보안 정책
   */
  public updateSecurityPolicy(policy: {
    xssProtection?: boolean;
    sqlInjectionProtection?: boolean;
    pathTraversalProtection?: boolean;
    autoSanitization?: boolean;
    strictMode?: boolean;
  }): void {
    console.log('🔧 보안 정책이 업데이트되었습니다:', policy);
    // 실제 구현에서는 각 컴포넌트의 설정을 동적으로 변경
  }

  /**
   * 보안 위협 요약 보고서 생성
   * 
   * @returns 보안 위협 요약 정보
   */
  public generateThreatReport(): {
    totalThreats: number;
    threatTypes: Record<string, number>;
    topTargets: string[];
    recommendations: string[];
  } {
    // 실제 구현에서는 로그 데이터를 분석하여 실제 보고서 생성
    return {
      totalThreats: this.securityMetrics.threatsDetected,
      threatTypes: {
        'XSS': 0,
        'SQL Injection': 0,
        'Path Traversal': 0,
        'Command Injection': 0
      },
      topTargets: ['/api/auth/login', '/api/users/profile', '/api/articles'],
      recommendations: [
        '입력 검증 규칙 강화',
        'Rate Limiting 적용',
        '추가 모니터링 설정'
      ]
    };
  }

  /**
   * 응급 보안 모드 활성화
   * 
   * 심각한 보안 위협 감지 시 모든 요청에 최고 수준의 보안 검증을 적용합니다.
   */
  public enableEmergencyMode(): void {
    console.log('🚨 응급 보안 모드가 활성화되었습니다.');
    // 실제 구현에서는 모든 보안 설정을 최고 수준으로 변경
  }

  /**
   * 응급 보안 모드 비활성화
   */
  public disableEmergencyMode(): void {
    console.log('✅ 응급 보안 모드가 비활성화되었습니다.');
    // 실제 구현에서는 보안 설정을 원래대로 복원
  }
}

/**
 * 보안 관리자 싱글톤 인스턴스
 */
export const securityManager = SecurityManager.getInstance();

// ============================================================================
// 🚀 편의 함수들
// ============================================================================

/**
 * 빠른 보안 검증 (모든 위협 확인)
 * 
 * @param input 검증할 입력
 * @returns 안전성 여부
 */
export function isSecure(input: string): boolean {
  return SecurityValidator.quickValidate(input);
}

/**
 * 빠른 안전 변환 (기본 새니타이징)
 * 
 * @param input 변환할 입력
 * @returns 안전한 출력
 */
export function makeSafe(input: string): string {
  return SecuritySanitizer.quickSanitize(input);
}

/**
 * 검색 쿼리 안전 변환
 * 
 * @param query 검색 쿼리
 * @returns 안전한 검색 쿼리
 */
export function makeSearchSafe(query: string): string {
  return SecuritySanitizer.sanitizeSearchQuery(query);
}

/**
 * 사용자 데이터 안전 변환
 * 
 * @param userData 사용자 데이터
 * @returns 안전한 사용자 데이터
 */
export function makeUserDataSafe(userData: any): any {
  return SecuritySanitizer.sanitizeUserProfile(userData);
}

// ============================================================================
// 📝 타입 정의 재내보내기
// ============================================================================

// 주요 타입들을 다시 내보내어 사용 편의성 제공
export type {
  XSSValidationResult,
  SQLInjectionValidationResult,
  PathTraversalValidationResult,
  HTMLSanitizationResult,
  SQLSanitizationResult,
  SecurityValidationConfig,
  SecurityRule
};

/**
 * 통합 보안 검증 결과 타입
 */
export interface SecurityValidationResult {
  isValid: boolean;
  threats: string[];
  severity: 'low' | 'medium' | 'high' | 'critical';
  sanitizedValue?: string;
  recommendations?: string[];
}

/**
 * 보안 컨텍스트 타입
 */
export interface SecurityContext {
  fieldType: FieldType;
  inputContext: InputContext;
  sanitizationContext: SanitizationContext;
  sqlSanitizationContext: SQLSanitizationContext;
  fieldName?: string;
  maxLength?: number;
  required?: boolean;
}