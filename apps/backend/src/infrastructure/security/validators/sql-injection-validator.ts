/// Paperly Backend - SQL Injection 공격 방지 검증기
/// 
/// 이 파일은 SQL Injection 공격을 방지하기 위한 입력 검증 로직을 구현합니다.
/// 사용자 입력에서 악성 SQL 코드를 감지하고 차단하여 데이터베이스 보안을 강화합니다.
/// 
/// 주요 방어 기능:
/// 1. SQL 키워드 검증: SELECT, INSERT, DROP, UNION 등 위험한 SQL 명령어 차단
/// 2. SQL 메타문자 검증: ', ", ;, --, /* 등 SQL 구문 조작 문자 차단
/// 3. SQL 함수 검증: EXEC, EXECUTE, CONCAT 등 위험한 함수 차단
/// 4. 숫자 검증: 숫자 필드에 SQL 코드 삽입 방지
/// 5. UNION 공격 검증: UNION 기반 데이터 추출 공격 차단
/// 6. Boolean 공격 검증: 1=1, 1=0 등 조건문 우회 공격 차단
/// 
/// 보안 접근 방식:
/// - 다중 계층 방어: 여러 단계의 검증으로 우회 방지
/// - 패턴 매칭: 정교한 정규식으로 변형된 공격도 탐지
/// - 컨텍스트 인식: 필드 타입에 따른 맞춤형 검증
/// - 상세한 분석: 공격 벡터별 세부 분류 및 기록

import { Logger } from '../../logging/Logger';

/**
 * SQL Injection 검증 결과 인터페이스
 * 
 * 검증 과정에서 발견된 SQL 위협의 상세 정보를 담습니다.
 */
export interface SQLInjectionValidationResult {
  isValid: boolean;              // 입력값의 안전성 여부
  threats: string[];             // 감지된 위협 유형 목록
  sanitizedValue?: string;       // 새니타이징된 안전한 값
  severity: 'low' | 'medium' | 'high' | 'critical';  // 위협 심각도
  detectedPatterns: string[];    // 감지된 구체적인 공격 패턴
}

/**
 * SQL Injection 위협 유형 열거형
 * 
 * 다양한 SQL Injection 공격 벡터를 분류하여 관리합니다.
 */
export enum SQLThreatType {
  SQL_KEYWORD = 'SQL_KEYWORD',                    // 위험한 SQL 키워드
  SQL_METACHAR = 'SQL_METACHAR',                  // SQL 메타문자
  SQL_FUNCTION = 'SQL_FUNCTION',                  // 위험한 SQL 함수
  UNION_ATTACK = 'UNION_ATTACK',                  // UNION 기반 공격
  BOOLEAN_ATTACK = 'BOOLEAN_ATTACK',              // Boolean 기반 공격
  COMMENT_ATTACK = 'COMMENT_ATTACK',              // 주석을 통한 공격
  TIME_ATTACK = 'TIME_ATTACK',                    // Time-based blind 공격
  ERROR_ATTACK = 'ERROR_ATTACK',                  // Error-based 공격
  STACKED_QUERY = 'STACKED_QUERY',                // Stacked query 공격
  NUMERIC_INJECTION = 'NUMERIC_INJECTION'         // 숫자 필드 인젝션
}

/**
 * 입력 필드 타입 열거형
 * 
 * 필드 타입에 따라 다른 검증 규칙을 적용하기 위한 분류입니다.
 */
export enum FieldType {
  TEXT = 'TEXT',           // 텍스트 필드 (이름, 제목 등)
  EMAIL = 'EMAIL',         // 이메일 필드
  NUMBER = 'NUMBER',       // 숫자 필드
  DATE = 'DATE',           // 날짜 필드
  URL = 'URL',             // URL 필드
  SEARCH = 'SEARCH',       // 검색 필드
  PASSWORD = 'PASSWORD',   // 비밀번호 필드
  CONTENT = 'CONTENT'      // 컨텐츠 필드 (긴 텍스트)
}

/**
 * SQL Injection 공격 방지 검증기 클래스
 * 
 * 다양한 SQL Injection 공격 패턴을 감지하고 차단하는 종합적인 보안 검증 시스템입니다.
 * 실시간으로 사용자 입력을 분석하여 악성 SQL 코드를 식별하고 적절한 대응을 수행합니다.
 */
export class SQLInjectionValidator {
  private readonly logger = new Logger('SQLInjectionValidator');

  // ============================================================================
  // 🗄️ 위험한 SQL 키워드 패턴들
  // ============================================================================
  
  /**
   * 데이터 조작 SQL 키워드 목록 (높은 위험도)
   * 
   * 데이터베이스의 데이터를 직접 조작할 수 있는 위험한 명령어들입니다.
   */
  private readonly CRITICAL_SQL_KEYWORDS = [
    'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'DROP', 'CREATE', 'ALTER', 'TRUNCATE',
    'EXEC', 'EXECUTE', 'CALL', 'MERGE', 'REPLACE', 'LOAD', 'OUTFILE', 'DUMPFILE',
    'INTO', 'BULK', 'OPENROWSET', 'OPENDATASOURCE'
  ];

  /**
   * 데이터 제어 SQL 키워드 목록 (중간 위험도)
   * 
   * 권한이나 트랜잭션을 제어할 수 있는 명령어들입니다.
   */
  private readonly MODERATE_SQL_KEYWORDS = [
    'GRANT', 'REVOKE', 'COMMIT', 'ROLLBACK', 'SAVEPOINT', 'SET', 'DECLARE',
    'BEGIN', 'END', 'IF', 'ELSE', 'WHILE', 'FOR', 'LOOP', 'BREAK', 'CONTINUE',
    'RETURN', 'GOTO', 'TRY', 'CATCH', 'THROW', 'RAISERROR'
  ];

  /**
   * UNION 관련 키워드 목록
   * 
   * UNION 공격에 사용되는 키워드들입니다.
   */
  private readonly UNION_KEYWORDS = [
    'UNION', 'ALL', 'DISTINCT', 'ORDER', 'GROUP', 'HAVING', 'LIMIT', 'OFFSET'
  ];

  /**
   * 위험한 SQL 함수 목록
   * 
   * 시스템 정보 노출이나 파일 조작이 가능한 함수들입니다.
   */
  private readonly DANGEROUS_SQL_FUNCTIONS = [
    'SUBSTRING', 'SUBSTR', 'MID', 'CONCAT', 'CHAR', 'ASCII', 'ORD', 'HEX',
    'UNHEX', 'BIN', 'CONV', 'CAST', 'CONVERT', 'EXTRACT', 'SLEEP', 'BENCHMARK',
    'VERSION', 'USER', 'DATABASE', 'SCHEMA', 'CONNECTION_ID', 'CURRENT_USER',
    'SESSION_USER', 'SYSTEM_USER', 'LOAD_FILE', 'INTO_OUTFILE', 'INTO_DUMPFILE',
    'EXEC', 'EXECUTE', 'SP_EXECUTESQL', 'XP_CMDSHELL', 'XP_REGREAD', 'XP_REGWRITE'
  ];

  // ============================================================================
  // 🔧 SQL 메타문자 및 연산자 패턴들
  // ============================================================================
  
  /**
   * SQL 메타문자 목록
   * 
   * SQL 구문의 의미를 변경할 수 있는 특수 문자들입니다.
   */
  private readonly SQL_METACHARACTERS = [
    "'", '"',           // 문자열 구분자
    ';',                // 명령 구분자
    '--', '#',          // 주석 시작
    '/*', '*/',         // 블록 주석
    '=', '<', '>',      // 비교 연산자
    '(', ')',           // 괄호
    '+', '-', '*', '/', // 산술 연산자
    '||', '&&',         // 논리 연산자
    '|', '&', '^',      // 비트 연산자
    '%', '_'            // 와일드카드
  ];

  /**
   * SQL 주석 패턴 정규식
   * 
   * 다양한 형태의 SQL 주석을 감지합니다.
   */
  private readonly SQL_COMMENT_PATTERNS = [
    /--[^\r\n]*/gi,           // -- 단일 라인 주석
    /#[^\r\n]*/gi,            // # 단일 라인 주석 (MySQL)
    /\/\*[\s\S]*?\*\//gi      // /* */ 블록 주석
  ];

  /**
   * Boolean 기반 공격 패턴
   * 
   * 조건문을 조작하여 인증을 우회하는 공격을 감지합니다.
   */
  private readonly BOOLEAN_ATTACK_PATTERNS = [
    /(\s|^)(1\s*=\s*1)(\s|$)/gi,           // 1=1 (항상 참)
    /(\s|^)(1\s*=\s*0)(\s|$)/gi,           // 1=0 (항상 거짓)
    /(\s|^)(''\s*=\s*'')(\s|$)/gi,         // ''='' (항상 참)
    /(\s|^)(""\s*=\s*"")(\s|$)/gi,         // ""="" (항상 참)
    /(\s|^)(0\s*=\s*0)(\s|$)/gi,           // 0=0 (항상 참)
    /(\s|^)(\w+\s*=\s*\w+)(\s|$)/gi,       // 기본 등식 패턴
    /(\s|^)(OR\s+1\s*=\s*1)(\s|$)/gi,      // OR 1=1
    /(\s|^)(AND\s+1\s*=\s*1)(\s|$)/gi,     // AND 1=1
    /(\s|^)(OR\s+1)(\s|$)/gi,              // OR 1
    /(\s|^)(AND\s+1)(\s|$)/gi              // AND 1
  ];

  /**
   * UNION 공격 패턴
   * 
   * UNION을 이용한 데이터 추출 공격을 감지합니다.
   */
  private readonly UNION_ATTACK_PATTERNS = [
    /UNION\s+(ALL\s+)?SELECT/gi,           // UNION SELECT
    /UNION\s+(ALL\s+)?.*SELECT/gi,         // UNION ... SELECT
    /'\s*UNION\s+/gi,                      // ' UNION
    /\d+\s*UNION\s+/gi,                    // 숫자 UNION
    /NULL.*UNION/gi,                       // NULL UNION
    /UNION.*NULL/gi                        // UNION NULL
  ];

  /**
   * Time-based Blind 공격 패턴
   * 
   * 시간 지연을 이용한 블라인드 SQL 인젝션을 감지합니다.
   */
  private readonly TIME_BASED_PATTERNS = [
    /SLEEP\s*\(\s*\d+\s*\)/gi,             // SLEEP(숫자)
    /BENCHMARK\s*\(/gi,                    // BENCHMARK(
    /WAITFOR\s+DELAY/gi,                   // WAITFOR DELAY (SQL Server)
    /pg_sleep\s*\(/gi,                     // pg_sleep( (PostgreSQL)
    /DBMS_LOCK\.SLEEP/gi                   // DBMS_LOCK.SLEEP (Oracle)
  ];

  /**
   * Error-based 공격 패턴
   * 
   * 에러 메시지를 통한 정보 수집 공격을 감지합니다.
   */
  private readonly ERROR_BASED_PATTERNS = [
    /CONVERT\s*\(/gi,                      // CONVERT 함수
    /CAST\s*\(/gi,                         // CAST 함수
    /EXTRACTVALUE\s*\(/gi,                 // EXTRACTVALUE 함수
    /UPDATEXML\s*\(/gi,                    // UPDATEXML 함수
    /EXP\s*\(\s*~\s*\(/gi,                 // EXP(~( 패턴
    /FLOOR\s*\(\s*RAND\s*\(/gi             // FLOOR(RAND( 패턴
  ];

  // ============================================================================
  // 📊 공개 메서드들
  // ============================================================================

  /**
   * 종합적인 SQL Injection 검증 수행
   * 
   * 입력값에 대해 모든 SQL Injection 공격 패턴을 검사하고 상세한 결과를 반환합니다.
   * 필드 타입에 따라 다른 검증 규칙을 적용합니다.
   * 
   * @param input 검증할 입력 문자열
   * @param fieldType 필드 타입 (선택사항)
   * @param fieldName 필드명 (로깅용, 선택사항)
   * @returns SQL Injection 검증 결과 객체
   */
  public validate(
    input: string, 
    fieldType: FieldType = FieldType.TEXT, 
    fieldName?: string
  ): SQLInjectionValidationResult {
    if (!input || typeof input !== 'string') {
      return {
        isValid: true,
        threats: [],
        severity: 'low',
        detectedPatterns: []
      };
    }

    const threats: string[] = [];
    const detectedPatterns: string[] = [];
    let severity: 'low' | 'medium' | 'high' | 'critical' = 'low';

    // 필드 타입별 특화 검증
    this.validateByFieldType(input, fieldType, threats, detectedPatterns);

    // 1. SQL 키워드 검증
    const keywordResult = this.checkSQLKeywords(input);
    if (keywordResult.found) {
      threats.push(SQLThreatType.SQL_KEYWORD);
      detectedPatterns.push(...keywordResult.patterns);
      severity = this.escalateSeverity(severity, keywordResult.severity);
    }

    // 2. SQL 메타문자 검증
    if (this.hasSQLMetacharacters(input)) {
      threats.push(SQLThreatType.SQL_METACHAR);
      severity = this.escalateSeverity(severity, 'medium');
    }

    // 3. SQL 함수 검증
    if (this.hasDangerousSQLFunctions(input)) {
      threats.push(SQLThreatType.SQL_FUNCTION);
      detectedPatterns.push('DANGEROUS_SQL_FUNCTION');
      severity = this.escalateSeverity(severity, 'high');
    }

    // 4. UNION 공격 검증
    const unionResult = this.checkUnionAttack(input);
    if (unionResult.found) {
      threats.push(SQLThreatType.UNION_ATTACK);
      detectedPatterns.push(...unionResult.patterns);
      severity = this.escalateSeverity(severity, 'critical');
    }

    // 5. Boolean 공격 검증
    const booleanResult = this.checkBooleanAttack(input);
    if (booleanResult.found) {
      threats.push(SQLThreatType.BOOLEAN_ATTACK);
      detectedPatterns.push(...booleanResult.patterns);
      severity = this.escalateSeverity(severity, 'high');
    }

    // 6. 주석 공격 검증
    if (this.hasCommentAttack(input)) {
      threats.push(SQLThreatType.COMMENT_ATTACK);
      detectedPatterns.push('SQL_COMMENT');
      severity = this.escalateSeverity(severity, 'medium');
    }

    // 7. Time-based 공격 검증
    const timeResult = this.checkTimeBasedAttack(input);
    if (timeResult.found) {
      threats.push(SQLThreatType.TIME_ATTACK);
      detectedPatterns.push(...timeResult.patterns);
      severity = this.escalateSeverity(severity, 'high');
    }

    // 8. Error-based 공격 검증
    const errorResult = this.checkErrorBasedAttack(input);
    if (errorResult.found) {
      threats.push(SQLThreatType.ERROR_ATTACK);
      detectedPatterns.push(...errorResult.patterns);
      severity = this.escalateSeverity(severity, 'high');
    }

    // 9. Stacked Query 공격 검증
    if (this.hasStackedQuery(input)) {
      threats.push(SQLThreatType.STACKED_QUERY);
      detectedPatterns.push('STACKED_QUERY');
      severity = this.escalateSeverity(severity, 'critical');
    }

    const isValid = threats.length === 0;

    // 위협 감지 시 로깅
    if (!isValid) {
      this.logger.warn('SQL Injection 위협 감지', {
        fieldName,
        fieldType,
        threats,
        detectedPatterns,
        severity,
        inputLength: input.length,
        inputPreview: input.substring(0, 100) // 처음 100자만 로깅
      });
    }

    return {
      isValid,
      threats,
      severity,
      detectedPatterns
    };
  }

  /**
   * 빠른 SQL Injection 검증 (기본적인 패턴만 확인)
   * 
   * 성능이 중요한 상황에서 사용할 수 있는 경량화된 검증입니다.
   * 
   * @param input 검증할 입력 문자열
   * @returns 안전성 여부 (boolean)
   */
  public quickValidate(input: string): boolean {
    if (!input || typeof input !== 'string') {
      return true;
    }

    // 가장 일반적이고 위험한 패턴들만 빠르게 확인
    const quickPatterns = [
      /(\s|^)(SELECT|INSERT|UPDATE|DELETE|DROP|UNION)\s+/gi,
      /('|\"|;|--|\/\*)/g,
      /(1\s*=\s*1|1\s*=\s*0)/gi
    ];

    return !quickPatterns.some(pattern => pattern.test(input));
  }

  /**
   * 숫자 필드 전용 검증
   * 
   * 숫자만 허용되는 필드에서 SQL 인젝션을 차단합니다.
   * 
   * @param input 검증할 입력 문자열
   * @returns 안전성 여부 (boolean)
   */
  public validateNumericField(input: string): boolean {
    if (!input || typeof input !== 'string') {
      return true;
    }

    // 숫자, 공백, 기본 연산자만 허용
    const numericPattern = /^[0-9\s+\-*/.()]+$/;
    
    // 기본 숫자 패턴 확인
    if (!numericPattern.test(input)) {
      return false;
    }

    // SQL 키워드나 메타문자가 있는지 확인
    return this.quickValidate(input);
  }

  // ============================================================================
  // 🔍 내부 검증 메서드들
  // ============================================================================

  /**
   * 필드 타입별 특화 검증
   */
  private validateByFieldType(
    input: string,
    fieldType: FieldType,
    threats: string[],
    patterns: string[]
  ): void {
    switch (fieldType) {
      case FieldType.NUMBER:
        if (!this.validateNumericField(input)) {
          threats.push(SQLThreatType.NUMERIC_INJECTION);
          patterns.push('INVALID_NUMERIC_INPUT');
        }
        break;
      
      case FieldType.EMAIL:
        // 이메일 필드에서는 특정 문자만 허용
        if (this.hasInvalidEmailCharacters(input)) {
          threats.push(SQLThreatType.SQL_METACHAR);
          patterns.push('INVALID_EMAIL_CHARACTERS');
        }
        break;
      
      case FieldType.DATE:
        // 날짜 필드에서는 날짜 형식만 허용
        if (this.hasInvalidDateFormat(input)) {
          threats.push(SQLThreatType.SQL_METACHAR);
          patterns.push('INVALID_DATE_FORMAT');
        }
        break;
    }
  }

  /**
   * SQL 키워드 검증
   */
  private checkSQLKeywords(input: string): {
    found: boolean;
    patterns: string[];
    severity: 'low' | 'medium' | 'high' | 'critical';
  } {
    const patterns: string[] = [];
    let maxSeverity: 'low' | 'medium' | 'high' | 'critical' = 'low';

    // Critical 키워드 검사
    for (const keyword of this.CRITICAL_SQL_KEYWORDS) {
      const pattern = new RegExp(`\\b${keyword}\\b`, 'gi');
      if (pattern.test(input)) {
        patterns.push(keyword);
        maxSeverity = 'critical';
      }
    }

    // Moderate 키워드 검사 (Critical이 없는 경우에만)
    if (patterns.length === 0) {
      for (const keyword of this.MODERATE_SQL_KEYWORDS) {
        const pattern = new RegExp(`\\b${keyword}\\b`, 'gi');
        if (pattern.test(input)) {
          patterns.push(keyword);
          maxSeverity = 'high';
        }
      }
    }

    return {
      found: patterns.length > 0,
      patterns,
      severity: maxSeverity
    };
  }

  /**
   * SQL 메타문자 검증
   */
  private hasSQLMetacharacters(input: string): boolean {
    return this.SQL_METACHARACTERS.some(char => input.includes(char));
  }

  /**
   * 위험한 SQL 함수 검증
   */
  private hasDangerousSQLFunctions(input: string): boolean {
    return this.DANGEROUS_SQL_FUNCTIONS.some(func => {
      const pattern = new RegExp(`\\b${func}\\s*\\(`, 'gi');
      return pattern.test(input);
    });
  }

  /**
   * UNION 공격 검증
   */
  private checkUnionAttack(input: string): {
    found: boolean;
    patterns: string[];
  } {
    const patterns: string[] = [];

    for (const pattern of this.UNION_ATTACK_PATTERNS) {
      if (pattern.test(input)) {
        patterns.push('UNION_ATTACK');
        break;
      }
    }

    return {
      found: patterns.length > 0,
      patterns
    };
  }

  /**
   * Boolean 공격 검증
   */
  private checkBooleanAttack(input: string): {
    found: boolean;
    patterns: string[];
  } {
    const patterns: string[] = [];

    for (const pattern of this.BOOLEAN_ATTACK_PATTERNS) {
      if (pattern.test(input)) {
        patterns.push('BOOLEAN_ATTACK');
        break;
      }
    }

    return {
      found: patterns.length > 0,
      patterns
    };
  }

  /**
   * 주석 공격 검증
   */
  private hasCommentAttack(input: string): boolean {
    return this.SQL_COMMENT_PATTERNS.some(pattern => pattern.test(input));
  }

  /**
   * Time-based 공격 검증
   */
  private checkTimeBasedAttack(input: string): {
    found: boolean;
    patterns: string[];
  } {
    const patterns: string[] = [];

    for (const pattern of this.TIME_BASED_PATTERNS) {
      if (pattern.test(input)) {
        patterns.push('TIME_BASED_ATTACK');
        break;
      }
    }

    return {
      found: patterns.length > 0,
      patterns
    };
  }

  /**
   * Error-based 공격 검증
   */
  private checkErrorBasedAttack(input: string): {
    found: boolean;
    patterns: string[];
  } {
    const patterns: string[] = [];

    for (const pattern of this.ERROR_BASED_PATTERNS) {
      if (pattern.test(input)) {
        patterns.push('ERROR_BASED_ATTACK');
        break;
      }
    }

    return {
      found: patterns.length > 0,
      patterns
    };
  }

  /**
   * Stacked Query 공격 검증
   */
  private hasStackedQuery(input: string): boolean {
    // 세미콜론으로 구분된 다중 쿼리 감지
    const stackedPattern = /;\s*(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER)/gi;
    return stackedPattern.test(input);
  }

  /**
   * 이메일 필드 유효성 검증
   */
  private hasInvalidEmailCharacters(input: string): boolean {
    // 이메일에 허용되지 않는 SQL 메타문자 확인
    const invalidEmailChars = /['";\/\*\(\)<>=]|--/;
    return invalidEmailChars.test(input);
  }

  /**
   * 날짜 필드 유효성 검증
   */
  private hasInvalidDateFormat(input: string): boolean {
    // 날짜 형식이 아닌 문자가 포함되어 있는지 확인
    const validDatePattern = /^[0-9\-\/\s:.T]+$/;
    return !validDatePattern.test(input);
  }

  /**
   * 위협 심각도 에스컬레이션
   */
  private escalateSeverity(
    current: 'low' | 'medium' | 'high' | 'critical',
    threat: 'low' | 'medium' | 'high' | 'critical'
  ): 'low' | 'medium' | 'high' | 'critical' {
    const severityLevels = { low: 1, medium: 2, high: 3, critical: 4 };
    
    return severityLevels[threat] > severityLevels[current] ? threat : current;
  }

  /**
   * SQL Injection 검증 통계 조회
   */
  public getValidationStats(): {
    totalValidations: number;
    threatsDetected: number;
    threatTypes: Record<string, number>;
    severityDistribution: Record<string, number>;
  } {
    // 실제 구현에서는 메트릭 수집 시스템과 연동
    return {
      totalValidations: 0,
      threatsDetected: 0,
      threatTypes: Object.values(SQLThreatType).reduce((acc, type) => {
        acc[type] = 0;
        return acc;
      }, {} as Record<string, number>),
      severityDistribution: {
        low: 0,
        medium: 0,
        high: 0,
        critical: 0
      }
    };
  }
}

/**
 * SQL Injection 검증기 싱글톤 인스턴스
 * 
 * 애플리케이션 전체에서 사용할 수 있는 공유 인스턴스입니다.
 */
export const sqlInjectionValidator = new SQLInjectionValidator();