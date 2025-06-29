/// Paperly Backend - SQL 새니타이저
/// 
/// 이 파일은 사용자 입력에서 위험한 SQL 구문을 안전하게 제거하거나 이스케이프하는
/// 새니타이징 로직을 구현합니다. SQL Injection 공격을 방지하면서도 정상적인 텍스트는 보존합니다.
/// 
/// 주요 기능:
/// 1. SQL 메타문자 이스케이프: ', ", ;, -- 등 특수문자 무력화
/// 2. SQL 키워드 필터링: SELECT, INSERT, DROP 등 위험한 키워드 제거
/// 3. 숫자 검증: 숫자 필드에 숫자가 아닌 값 필터링
/// 4. 컨텍스트 인식: 필드 타입에 따른 맞춤형 새니타이징
/// 5. 길이 제한: 비정상적으로 긴 입력 차단
/// 
/// 새니타이징 전략:
/// - 이스케이프 우선: 가능한 한 이스케이프로 처리
/// - 컨텍스트 인식: 필드 타입에 따른 다른 처리
/// - 보존적 접근: 정상 데이터는 최대한 보존
/// - 로깅 강화: 의심스러운 패턴은 상세 기록

import { Logger } from '../../logging/Logger';

/**
 * SQL 새니타이징 결과 인터페이스
 */
export interface SQLSanitizationResult {
  sanitizedValue: string;        // 새니타이징된 값
  originalValue: string;         // 원본 값
  wasModified: boolean;          // 수정 여부
  removedPatterns: string[];     // 제거된 SQL 패턴
  warnings: string[];            // 경고 메시지
  riskLevel: 'low' | 'medium' | 'high' | 'critical';  // 위험도
}

/**
 * SQL 새니타이징 옵션
 */
export interface SQLSanitizationOptions {
  escapeQuotes?: boolean;        // 따옴표 이스케이프 여부
  removeComments?: boolean;      // SQL 주석 제거 여부
  removeSemicolons?: boolean;    // 세미콜론 제거 여부
  maxLength?: number;            // 최대 길이 제한
  allowWildcards?: boolean;      // 와일드카드 허용 여부
  strictMode?: boolean;          // 엄격 모드 (더 많은 패턴 차단)
  preserveWhitespace?: boolean;  // 공백 보존 여부
}

/**
 * SQL 새니타이징 컨텍스트 열거형
 */
export enum SQLSanitizationContext {
  STRING_LITERAL = 'STRING_LITERAL',     // 문자열 리터럴
  NUMERIC_VALUE = 'NUMERIC_VALUE',       // 숫자 값
  COLUMN_NAME = 'COLUMN_NAME',           // 컬럼명
  TABLE_NAME = 'TABLE_NAME',             // 테이블명
  SEARCH_TERM = 'SEARCH_TERM',           // 검색어
  EMAIL_ADDRESS = 'EMAIL_ADDRESS',       // 이메일 주소
  USERNAME = 'USERNAME',                 // 사용자명
  PASSWORD = 'PASSWORD',                 // 비밀번호
  URL_PARAMETER = 'URL_PARAMETER',       // URL 매개변수
  JSON_VALUE = 'JSON_VALUE'              // JSON 값
}

/**
 * SQL 새니타이저 클래스
 * 
 * 사용자 입력을 안전하게 새니타이징하여 SQL Injection 공격을 방지하는 클래스입니다.
 */
export class SQLSanitizer {
  private readonly logger = new Logger('SQLSanitizer');

  // ============================================================================
  // 🔧 SQL 메타문자 및 패턴 정의
  // ============================================================================
  
  /**
   * SQL에서 특별한 의미를 가지는 메타문자들
   */
  private readonly SQL_METACHARACTERS = [
    "'",     // 문자열 구분자
    '"',     // 식별자 구분자
    ';',     // 명령 구분자
    '--',    // 주석
    '/*',    // 블록 주석 시작
    '*/',    // 블록 주석 끝
    '\\',    // 이스케이프 문자
    '%',     // LIKE 와일드카드
    '_',     // LIKE 와일드카드
    '(',     // 함수/서브쿼리 시작
    ')',     // 함수/서브쿼리 끝
    '=',     // 등호
    '<',     // 부등호
    '>',     // 부등호
    '|',     // OR 연산자 (일부 DB)
    '&',     // AND 연산자 (일부 DB)
    '^',     // XOR 연산자 (일부 DB)
    '+',     // 더하기
    '-',     // 빼기
    '*',     // 곱하기
    '/',     // 나누기
    '#'      // MySQL 주석
  ];

  /**
   * 이스케이프가 필요한 문자와 그 대체값
   */
  private readonly ESCAPE_MAP: Record<string, string> = {
    "'": "''",           // 작은따옴표 이스케이프
    '"': '""',           // 큰따옴표 이스케이프 (일부 DB)
    '\\': '\\\\',        // 백슬래시 이스케이프
    '\0': '\\0',         // NULL 문자
    '\n': '\\n',         // 줄바꿈
    '\r': '\\r',         // 캐리지 리턴
    '\x1a': '\\Z',       // Ctrl+Z
    '\t': '\\t',         // 탭
    '\b': '\\b',         // 백스페이스
    '\f': '\\f'          // 폼피드
  };

  /**
   * 위험한 SQL 키워드 (대소문자 무관)
   */
  private readonly DANGEROUS_SQL_KEYWORDS = [
    // DDL (Data Definition Language)
    'CREATE', 'DROP', 'ALTER', 'TRUNCATE',
    
    // DML (Data Manipulation Language)
    'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'MERGE', 'REPLACE',
    
    // DCL (Data Control Language)
    'GRANT', 'REVOKE',
    
    // TCL (Transaction Control Language)
    'COMMIT', 'ROLLBACK', 'SAVEPOINT',
    
    // 조건 및 연산자
    'UNION', 'INTERSECT', 'EXCEPT', 'MINUS',
    'WHERE', 'HAVING', 'ORDER', 'GROUP', 'LIMIT', 'OFFSET',
    'JOIN', 'INNER', 'OUTER', 'LEFT', 'RIGHT', 'FULL', 'CROSS',
    
    // 함수 및 기타
    'EXEC', 'EXECUTE', 'CALL', 'DECLARE', 'SET',
    'INTO', 'FROM', 'AS', 'ON', 'USING',
    'CASE', 'WHEN', 'THEN', 'ELSE', 'END',
    'IF', 'WHILE', 'FOR', 'LOOP', 'BREAK', 'CONTINUE',
    
    // 시스템 함수
    'VERSION', 'USER', 'DATABASE', 'SCHEMA',
    'CONCAT', 'SUBSTRING', 'SUBSTR', 'LENGTH', 'CHAR',
    'ASCII', 'HEX', 'UNHEX', 'BIN', 'OCT',
    'SLEEP', 'BENCHMARK', 'LOAD_FILE',
    
    // 특수 값
    'NULL', 'TRUE', 'FALSE',
    
    // 논리 연산자
    'AND', 'OR', 'NOT', 'XOR', 'LIKE', 'RLIKE', 'REGEXP',
    'IN', 'EXISTS', 'BETWEEN', 'IS'
  ];

  /**
   * 컨텍스트별 기본 새니타이징 옵션
   */
  private readonly CONTEXT_OPTIONS: Record<SQLSanitizationContext, SQLSanitizationOptions> = {
    [SQLSanitizationContext.STRING_LITERAL]: {
      escapeQuotes: true,
      removeComments: true,
      removeSemicolons: true,
      maxLength: 1000,
      allowWildcards: false,
      strictMode: true,
      preserveWhitespace: true
    },
    [SQLSanitizationContext.NUMERIC_VALUE]: {
      escapeQuotes: false,
      removeComments: true,
      removeSemicolons: true,
      maxLength: 50,
      allowWildcards: false,
      strictMode: true,
      preserveWhitespace: false
    },
    [SQLSanitizationContext.SEARCH_TERM]: {
      escapeQuotes: true,
      removeComments: true,
      removeSemicolons: true,
      maxLength: 500,
      allowWildcards: true,
      strictMode: false,
      preserveWhitespace: true
    },
    [SQLSanitizationContext.EMAIL_ADDRESS]: {
      escapeQuotes: true,
      removeComments: true,
      removeSemicolons: true,
      maxLength: 254,
      allowWildcards: false,
      strictMode: true,
      preserveWhitespace: false
    },
    [SQLSanitizationContext.USERNAME]: {
      escapeQuotes: true,
      removeComments: true,
      removeSemicolons: true,
      maxLength: 100,
      allowWildcards: false,
      strictMode: true,
      preserveWhitespace: false
    },
    [SQLSanitizationContext.PASSWORD]: {
      escapeQuotes: true,
      removeComments: true,
      removeSemicolons: true,
      maxLength: 128,
      allowWildcards: false,
      strictMode: true,
      preserveWhitespace: true
    },
    [SQLSanitizationContext.COLUMN_NAME]: {
      escapeQuotes: false,
      removeComments: true,
      removeSemicolons: true,
      maxLength: 64,
      allowWildcards: false,
      strictMode: true,
      preserveWhitespace: false
    },
    [SQLSanitizationContext.TABLE_NAME]: {
      escapeQuotes: false,
      removeComments: true,
      removeSemicolons: true,
      maxLength: 64,
      allowWildcards: false,
      strictMode: true,
      preserveWhitespace: false
    },
    [SQLSanitizationContext.URL_PARAMETER]: {
      escapeQuotes: true,
      removeComments: true,
      removeSemicolons: true,
      maxLength: 200,
      allowWildcards: false,
      strictMode: true,
      preserveWhitespace: false
    },
    [SQLSanitizationContext.JSON_VALUE]: {
      escapeQuotes: true,
      removeComments: true,
      removeSemicolons: true,
      maxLength: 2000,
      allowWildcards: false,
      strictMode: false,
      preserveWhitespace: true
    }
  };

  // ============================================================================
  // 📊 공개 메서드들
  // ============================================================================

  /**
   * SQL 새니타이징 수행
   * 
   * @param value 새니타이징할 값
   * @param context 새니타이징 컨텍스트
   * @param customOptions 사용자 정의 옵션
   * @returns 새니타이징 결과
   */
  public sanitize(
    value: string,
    context: SQLSanitizationContext = SQLSanitizationContext.STRING_LITERAL,
    customOptions?: Partial<SQLSanitizationOptions>
  ): SQLSanitizationResult {
    if (!value || typeof value !== 'string') {
      return {
        sanitizedValue: '',
        originalValue: value || '',
        wasModified: false,
        removedPatterns: [],
        warnings: [],
        riskLevel: 'low'
      };
    }

    const originalValue = value;
    const removedPatterns: string[] = [];
    const warnings: string[] = [];
    let riskLevel: 'low' | 'medium' | 'high' | 'critical' = 'low';

    // 옵션 구성
    const options = this.buildOptions(context, customOptions);

    let sanitizedValue = value;

    // 1. 길이 제한 확인
    if (options.maxLength && sanitizedValue.length > options.maxLength) {
      sanitizedValue = sanitizedValue.substring(0, options.maxLength);
      warnings.push(`Value truncated to ${options.maxLength} characters`);
      riskLevel = this.escalateRisk(riskLevel, 'medium');
    }

    // 2. 숫자 컨텍스트 특별 처리
    if (context === SQLSanitizationContext.NUMERIC_VALUE) {
      const numericResult = this.sanitizeNumericValue(sanitizedValue);
      sanitizedValue = numericResult.value;
      if (!numericResult.isValid) {
        removedPatterns.push('INVALID_NUMERIC');
        riskLevel = this.escalateRisk(riskLevel, 'high');
      }
    }

    // 3. SQL 키워드 검사 및 제거
    const keywordResult = this.removeOrEscapeSQLKeywords(sanitizedValue, options.strictMode!);
    sanitizedValue = keywordResult.value;
    removedPatterns.push(...keywordResult.removed);
    if (keywordResult.removed.length > 0) {
      riskLevel = this.escalateRisk(riskLevel, 'critical');
    }

    // 4. SQL 주석 제거
    if (options.removeComments) {
      const commentResult = this.removeSQLComments(sanitizedValue);
      sanitizedValue = commentResult.value;
      removedPatterns.push(...commentResult.removed);
      if (commentResult.removed.length > 0) {
        riskLevel = this.escalateRisk(riskLevel, 'high');
      }
    }

    // 5. 세미콜론 처리
    if (options.removeSemicolons) {
      if (sanitizedValue.includes(';')) {
        sanitizedValue = sanitizedValue.replace(/;/g, '');
        removedPatterns.push('SEMICOLON');
        riskLevel = this.escalateRisk(riskLevel, 'high');
      }
    }

    // 6. 따옴표 이스케이프
    if (options.escapeQuotes) {
      sanitizedValue = this.escapeQuotes(sanitizedValue);
    }

    // 7. 기타 메타문자 처리
    const metacharResult = this.handleMetacharacters(sanitizedValue, options);
    sanitizedValue = metacharResult.value;
    removedPatterns.push(...metacharResult.removed);
    if (metacharResult.removed.length > 0) {
      riskLevel = this.escalateRisk(riskLevel, 'medium');
    }

    // 8. 공백 정리
    if (!options.preserveWhitespace) {
      sanitizedValue = sanitizedValue.replace(/\s+/g, ' ').trim();
    }

    // 9. 최종 검증
    const finalResult = this.finalValidation(sanitizedValue, context);
    sanitizedValue = finalResult.value;
    warnings.push(...finalResult.warnings);
    if (finalResult.warnings.length > 0) {
      riskLevel = this.escalateRisk(riskLevel, 'medium');
    }

    const wasModified = originalValue !== sanitizedValue;

    // 위험한 패턴 감지 시 로깅
    if (wasModified || removedPatterns.length > 0) {
      this.logger.warn('SQL 새니타이징 수행', {
        context,
        originalLength: originalValue.length,
        sanitizedLength: sanitizedValue.length,
        removedPatterns,
        riskLevel,
        preview: originalValue.substring(0, 100)
      });
    }

    return {
      sanitizedValue,
      originalValue,
      wasModified,
      removedPatterns,
      warnings,
      riskLevel
    };
  }

  /**
   * 빠른 SQL 이스케이핑 (성능 중시)
   * 
   * @param value 이스케이프할 값
   * @returns 이스케이프된 값
   */
  public quickEscape(value: string): string {
    if (!value || typeof value !== 'string') {
      return '';
    }

    return this.escapeQuotes(value);
  }

  /**
   * 숫자 값 검증 및 새니타이징
   * 
   * @param value 검증할 값
   * @returns 검증 결과
   */
  public sanitizeNumber(value: string): { value: string; isValid: boolean } {
    return this.sanitizeNumericValue(value);
  }

  /**
   * LIKE 패턴 새니타이징 (검색용)
   * 
   * @param pattern LIKE 패턴
   * @param allowWildcards 와일드카드 허용 여부
   * @returns 새니타이징된 패턴
   */
  public sanitizeLikePattern(pattern: string, allowWildcards: boolean = true): string {
    if (!pattern || typeof pattern !== 'string') {
      return '';
    }

    let sanitized = this.escapeQuotes(pattern);

    if (!allowWildcards) {
      // 와일드카드 이스케이프
      sanitized = sanitized.replace(/%/g, '\\%').replace(/_/g, '\\_');
    }

    return sanitized;
  }

  // ============================================================================
  // 🔧 내부 처리 메서드들
  // ============================================================================

  /**
   * 새니타이징 옵션 구성
   */
  private buildOptions(
    context: SQLSanitizationContext,
    customOptions?: Partial<SQLSanitizationOptions>
  ): SQLSanitizationOptions {
    const defaultOptions = this.CONTEXT_OPTIONS[context];
    return { ...defaultOptions, ...customOptions };
  }

  /**
   * 숫자 값 새니타이징
   */
  private sanitizeNumericValue(value: string): { value: string; isValid: boolean } {
    // 숫자, 소수점, 부호, 공백만 허용
    const numericPattern = /^[+\-]?[0-9]*\.?[0-9]+([eE][+\-]?[0-9]+)?$/;
    const cleaned = value.trim();

    if (numericPattern.test(cleaned)) {
      return { value: cleaned, isValid: true };
    }

    // 숫자 부분만 추출
    const numbersOnly = cleaned.replace(/[^0-9+\-\.eE]/g, '');
    return { value: numbersOnly, isValid: false };
  }

  /**
   * SQL 키워드 제거 또는 이스케이프
   */
  private removeOrEscapeSQLKeywords(
    value: string,
    strictMode: boolean
  ): { value: string; removed: string[] } {
    const removed: string[] = [];
    let processed = value;

    for (const keyword of this.DANGEROUS_SQL_KEYWORDS) {
      // 단어 경계를 고려한 정확한 매칭
      const pattern = new RegExp(`\\b${keyword}\\b`, 'gi');
      
      if (pattern.test(processed)) {
        removed.push(keyword);
        
        if (strictMode) {
          // 엄격 모드: 키워드 완전 제거
          processed = processed.replace(pattern, '');
        } else {
          // 일반 모드: 키워드를 안전한 형태로 변경
          processed = processed.replace(pattern, `[${keyword}]`);
        }
      }
    }

    return { value: processed, removed };
  }

  /**
   * SQL 주석 제거
   */
  private removeSQLComments(value: string): { value: string; removed: string[] } {
    const removed: string[] = [];
    let processed = value;

    // 한줄 주석 제거 (--)
    if (/--/.test(processed)) {
      processed = processed.replace(/--.*$/gm, '');
      removed.push('LINE_COMMENT');
    }

    // 한줄 주석 제거 (#)
    if (/#/.test(processed)) {
      processed = processed.replace(/#.*$/gm, '');
      removed.push('HASH_COMMENT');
    }

    // 블록 주석 제거 (/* */)
    if (/\/\*[\s\S]*?\*\//.test(processed)) {
      processed = processed.replace(/\/\*[\s\S]*?\*\//g, '');
      removed.push('BLOCK_COMMENT');
    }

    return { value: processed, removed };
  }

  /**
   * 따옴표 이스케이프
   */
  private escapeQuotes(value: string): string {
    return value.replace(/'/g, "''");
  }

  /**
   * 메타문자 처리
   */
  private handleMetacharacters(
    value: string,
    options: SQLSanitizationOptions
  ): { value: string; removed: string[] } {
    const removed: string[] = [];
    let processed = value;

    // 특수 문자 이스케이프
    for (const [char, escaped] of Object.entries(this.ESCAPE_MAP)) {
      if (processed.includes(char)) {
        processed = processed.replace(new RegExp(char.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g'), escaped);
        if (char !== "'" || !options.escapeQuotes) { // 따옴표는 이미 처리됨
          removed.push(`ESCAPED_${char.charCodeAt(0)}`);
        }
      }
    }

    // 와일드카드 처리
    if (!options.allowWildcards) {
      if (processed.includes('%')) {
        processed = processed.replace(/%/g, '\\%');
        removed.push('WILDCARD_PERCENT');
      }
      if (processed.includes('_')) {
        processed = processed.replace(/_/g, '\\_');
        removed.push('WILDCARD_UNDERSCORE');
      }
    }

    return { value: processed, removed };
  }

  /**
   * 최종 검증
   */
  private finalValidation(
    value: string,
    context: SQLSanitizationContext
  ): { value: string; warnings: string[] } {
    const warnings: string[] = [];
    let validated = value;

    // 컨텍스트별 추가 검증
    switch (context) {
      case SQLSanitizationContext.EMAIL_ADDRESS:
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(validated)) {
          warnings.push('Invalid email format detected');
        }
        break;
      
      case SQLSanitizationContext.USERNAME:
        if (!/^[a-zA-Z0-9_\-\.]+$/.test(validated)) {
          // 사용자명에 허용되지 않는 문자 제거
          validated = validated.replace(/[^a-zA-Z0-9_\-\.]/g, '');
          warnings.push('Invalid username characters removed');
        }
        break;
      
      case SQLSanitizationContext.COLUMN_NAME:
      case SQLSanitizationContext.TABLE_NAME:
        if (!/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(validated)) {
          warnings.push('Invalid identifier format detected');
        }
        break;
    }

    // 길이 0인 경우 경고
    if (validated.length === 0 && value.length > 0) {
      warnings.push('Value was completely sanitized (empty result)');
    }

    return { value: validated, warnings };
  }

  /**
   * 위험도 에스컬레이션
   */
  private escalateRisk(
    current: 'low' | 'medium' | 'high' | 'critical',
    newRisk: 'low' | 'medium' | 'high' | 'critical'
  ): 'low' | 'medium' | 'high' | 'critical' {
    const riskLevels = { low: 1, medium: 2, high: 3, critical: 4 };
    return riskLevels[newRisk] > riskLevels[current] ? newRisk : current;
  }

  /**
   * 새니타이징 통계 조회
   */
  public getSanitizationStats(): {
    totalSanitizations: number;
    modificationsCount: number;
    riskDistribution: Record<string, number>;
    commonPatterns: Record<string, number>;
  } {
    return {
      totalSanitizations: 0,
      modificationsCount: 0,
      riskDistribution: {
        low: 0,
        medium: 0,
        high: 0,
        critical: 0
      },
      commonPatterns: {
        'sql_keywords': 0,
        'sql_comments': 0,
        'quotes': 0,
        'semicolons': 0,
        'metacharacters': 0
      }
    };
  }
}

/**
 * SQL 새니타이저 싱글톤 인스턴스
 */
export const sqlSanitizer = new SQLSanitizer();