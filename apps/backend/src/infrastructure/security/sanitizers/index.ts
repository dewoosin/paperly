/// Paperly Backend - 보안 새니타이저 통합 인덱스
/// 
/// 이 파일은 모든 보안 새니타이저를 한 곳에서 관리하고 내보내는 중앙 집중식 인덱스입니다.
/// 
/// 포함된 새니타이저들:
/// - HTMLSanitizer: HTML 코드 새니타이징 및 XSS 방지
/// - SQLSanitizer: SQL 코드 새니타이징 및 SQL Injection 방지

// 내부 사용을 위한 import
import { htmlSanitizer as _htmlSanitizer, SanitizationContext as _SanitizationContext } from './html-sanitizer';
import { sqlSanitizer as _sqlSanitizer, SQLSanitizationContext as _SQLSanitizationContext } from './sql-sanitizer';

// HTML 새니타이저
export {
  HTMLSanitizer,
  htmlSanitizer,
  HTMLSanitizationResult,
  HTMLSanitizationOptions,
  SanitizationContext
} from './html-sanitizer';

// SQL 새니타이저
export {
  SQLSanitizer,
  sqlSanitizer,
  SQLSanitizationResult,
  SQLSanitizationOptions,
  SQLSanitizationContext
} from './sql-sanitizer';

/**
 * 통합 보안 새니타이저 클래스
 * 
 * 모든 보안 새니타이저를 하나의 인터페이스로 통합하여 사용할 수 있게 해주는 클래스입니다.
 */
export class SecuritySanitizer {
  /**
   * HTML과 SQL 보안 새니타이징 통합 수행
   * 
   * 입력값에 대해 HTML XSS 방지와 SQL Injection 방지를 모두 적용합니다.
   * 
   * @param input 새니타이징할 입력 문자열
   * @param options 새니타이징 옵션
   * @returns 통합 새니타이징 결과
   */
  public static sanitizeAll(
    input: string,
    options?: {
      htmlContext?: SanitizationContext;
      sqlContext?: SQLSanitizationContext;
      fieldName?: string;
    }
  ): {
    originalValue: string;
    htmlSanitized: string;
    sqlSanitized: string;
    finalValue: string;
    htmlResult: HTMLSanitizationResult;
    sqlResult: SQLSanitizationResult;
    wasModified: boolean;
  } {
    const originalValue = input;

    // HTML 새니타이징 먼저 수행
    const htmlResult = _htmlSanitizer.sanitize(
      input,
      options?.htmlContext || _SanitizationContext.BASIC_HTML
    );

    // HTML 새니타이징 결과를 SQL 새니타이징에 적용
    const sqlResult = _sqlSanitizer.sanitize(
      htmlResult.sanitizedHTML,
      options?.sqlContext || _SQLSanitizationContext.STRING_LITERAL
    );

    const finalValue = sqlResult.sanitizedValue;
    const wasModified = originalValue !== finalValue;

    return {
      originalValue,
      htmlSanitized: htmlResult.sanitizedHTML,
      sqlSanitized: sqlResult.sanitizedValue,
      finalValue,
      htmlResult,
      sqlResult,
      wasModified
    };
  }

  /**
   * 빠른 기본 새니타이징
   * 
   * 가장 일반적인 XSS와 SQL Injection 방지를 빠르게 적용합니다.
   * 
   * @param input 새니타이징할 입력 문자열
   * @returns 새니타이징된 문자열
   */
  public static quickSanitize(input: string): string {
    // HTML 특수문자 인코딩
    const htmlSafe = _htmlSanitizer.quickEncode(input);
    
    // SQL 따옴표 이스케이프
    const sqlSafe = _sqlSanitizer.quickEscape(htmlSafe);
    
    return sqlSafe;
  }

  /**
   * 플레인 텍스트 추출
   * 
   * 모든 HTML 태그를 제거하고 순수 텍스트만 반환합니다.
   * 
   * @param input HTML이 포함될 수 있는 입력 문자열
   * @returns 순수 텍스트
   */
  public static extractPlainText(input: string): string {
    return _htmlSanitizer.stripAllHTML(input);
  }

  /**
   * 검색 쿼리 새니타이징
   * 
   * 검색 입력에 특화된 새니타이징을 수행합니다.
   * 
   * @param query 검색 쿼리
   * @returns 새니타이징된 검색 쿼리
   */
  public static sanitizeSearchQuery(query: string): string {
    // HTML 태그 완전 제거
    const plainText = _htmlSanitizer.stripAllHTML(query);
    
    // SQL 새니타이징 (와일드카드 허용)
    const sqlResult = _sqlSanitizer.sanitize(
      plainText,
      _SQLSanitizationContext.SEARCH_TERM
    );
    
    return sqlResult.sanitizedValue;
  }

  /**
   * 사용자 프로필 데이터 새니타이징
   * 
   * 사용자 프로필에 특화된 새니타이징을 수행합니다.
   * 
   * @param data 프로필 데이터
   * @returns 새니타이징된 프로필 데이터
   */
  public static sanitizeUserProfile(data: {
    name?: string;
    bio?: string;
    email?: string;
  }): {
    name?: string;
    bio?: string;
    email?: string;
  } {
    const sanitized: any = {};

    if (data.name) {
      // 이름: 기본 HTML 허용 + SQL 새니타이징
      const htmlResult = _htmlSanitizer.sanitize(data.name, _SanitizationContext.PLAIN_TEXT);
      const sqlResult = _sqlSanitizer.sanitize(htmlResult.sanitizedHTML, _SQLSanitizationContext.USERNAME);
      sanitized.name = sqlResult.sanitizedValue;
    }

    if (data.bio) {
      // 자기소개: 기본 HTML 허용 + SQL 새니타이징
      const htmlResult = _htmlSanitizer.sanitize(data.bio, _SanitizationContext.USER_BIO);
      const sqlResult = _sqlSanitizer.sanitize(htmlResult.sanitizedHTML, _SQLSanitizationContext.STRING_LITERAL);
      sanitized.bio = sqlResult.sanitizedValue;
    }

    if (data.email) {
      // 이메일: HTML 완전 제거 + 이메일 특화 SQL 새니타이징
      const plainEmail = _htmlSanitizer.stripAllHTML(data.email);
      const sqlResult = _sqlSanitizer.sanitize(plainEmail, _SQLSanitizationContext.EMAIL_ADDRESS);
      sanitized.email = sqlResult.sanitizedValue;
    }

    return sanitized;
  }
}

/**
 * 통합 보안 새니타이저 싱글톤 인스턴스
 */
export const securitySanitizer = new SecuritySanitizer();