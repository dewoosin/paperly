/// Paperly Backend - 보안 검증기 통합 인덱스
/// 
/// 이 파일은 모든 보안 검증기를 한 곳에서 관리하고 내보내는 중앙 집중식 인덱스입니다.
/// 
/// 포함된 검증기들:
/// - XSSValidator: Cross-Site Scripting 공격 방지
/// - SQLInjectionValidator: SQL Injection 공격 방지
/// - PathTraversalValidator: Path Traversal 및 Command Injection 공격 방지

// XSS 검증기
import { XSSValidator as XSSValidatorClass } from './xss-validator';
export { XSSValidatorClass as XSSValidator };
export { XSSValidationResult, XSSThreatType } from './xss-validator';

// XSS 검증기 인스턴스 생성
export const xssValidator = new XSSValidatorClass();

// SQL Injection 검증기
import { SQLInjectionValidator as SQLInjectionValidatorClass } from './sql-injection-validator';
export { SQLInjectionValidatorClass as SQLInjectionValidator };
export { SQLInjectionValidationResult, SQLThreatType, FieldType } from './sql-injection-validator';

// SQL Injection 검증기 인스턴스 생성
export const sqlInjectionValidator = new SQLInjectionValidatorClass();

// Path Traversal 검증기
import { PathTraversalValidator as PathTraversalValidatorClass } from './path-traversal-validator';
export { PathTraversalValidatorClass as PathTraversalValidator };
export { PathTraversalValidationResult, PathThreatType, InputContext } from './path-traversal-validator';

// Path Traversal 검증기 인스턴스 생성
export const pathTraversalValidator = new PathTraversalValidatorClass();

/**
 * 통합 보안 검증기 클래스
 * 
 * 모든 보안 검증기를 하나의 인터페이스로 통합하여 사용할 수 있게 해주는 클래스입니다.
 */
export class SecurityValidator {
  /**
   * 포괄적인 보안 검증 수행
   * 
   * 입력값에 대해 XSS, SQL Injection, Path Traversal 등 모든 위협을 검사합니다.
   * 
   * @param input 검증할 입력 문자열
   * @param context 입력 컨텍스트 (선택사항)
   * @returns 통합 검증 결과
   */
  public static validateAll(
    input: string,
    context?: { 
      fieldType?: FieldType;
      inputContext?: InputContext;
      fieldName?: string;
    }
  ): {
    isValid: boolean;
    xssResult: XSSValidationResult;
    sqlResult: SQLInjectionValidationResult;
    pathResult: PathTraversalValidationResult;
    overallSeverity: 'low' | 'medium' | 'high' | 'critical';
  } {
    // 각 검증기 실행
    const xssResult = xssValidator.validate(input, context?.fieldName);
    const sqlResult = sqlInjectionValidator.validate(
      input, 
      context?.fieldType || FieldType.TEXT,
      context?.fieldName
    );
    const pathResult = pathTraversalValidator.validate(
      input,
      context?.inputContext || InputContext.USER_INPUT,
      context?.fieldName
    );

    // 전체 유효성 판단
    const isValid = xssResult.isValid && sqlResult.isValid && pathResult.isValid;

    // 최고 심각도 계산
    const severities = [xssResult.severity, sqlResult.severity, pathResult.severity];
    const severityLevels = { low: 1, medium: 2, high: 3, critical: 4 };
    const maxSeverity = severities.reduce((max, current) => 
      severityLevels[current] > severityLevels[max] ? current : max
    );

    return {
      isValid,
      xssResult,
      sqlResult,
      pathResult,
      overallSeverity: maxSeverity
    };
  }

  /**
   * 빠른 보안 검증 (성능 우선)
   * 
   * 기본적인 위협만 빠르게 검사하는 경량화된 검증입니다.
   * 
   * @param input 검증할 입력 문자열
   * @returns 전체 안전성 여부
   */
  public static quickValidate(input: string): boolean {
    return xssValidator.quickValidate(input) &&
           sqlInjectionValidator.quickValidate(input) &&
           pathTraversalValidator.quickValidate(input);
  }
}

/**
 * 통합 보안 검증기 싱글톤 인스턴스
 */
export const securityValidator = new SecurityValidator();