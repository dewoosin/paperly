// /Users/workspace/paperly/apps/backend/src/infrastructure/web/middleware/validation.middleware.ts

import { Request, Response, NextFunction } from 'express';
import { ValidationError } from '../../../shared/errors';
import { Logger } from '../../logging/Logger';

/**
 * 입력값 검증 미들웨어
 * 
 * API 요청의 입력값을 검증하여 잘못된 데이터가 컨트롤러에 도달하는 것을 방지합니다.
 */

interface ValidationRule {
  required?: boolean;
  type?: 'string' | 'number' | 'boolean' | 'email' | 'date' | 'array' | 'object';
  minLength?: number;
  maxLength?: number;
  min?: number;
  max?: number;
  pattern?: RegExp;
  enum?: any[];
  custom?: (value: any) => boolean | string;
}

interface ValidationSchema {
  [key: string]: ValidationRule;
}

const logger = new Logger('ValidationMiddleware');

/**
 * 입력값 검증 미들웨어 팩토리
 * 
 * @param schema 검증 스키마
 * @param source 검증할 데이터 소스 ('body' | 'params' | 'query')
 * @returns Express 미들웨어 함수
 */
export function validateInput(
  schema: ValidationSchema, 
  source: 'body' | 'params' | 'query' = 'body'
) {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      const data = req[source];
      const errors: { field: string; message: string }[] = [];

      // 각 필드별 검증 수행
      for (const [fieldName, rule] of Object.entries(schema)) {
        const value = data[fieldName];
        const fieldErrors = validateField(fieldName, value, rule);
        errors.push(...fieldErrors);
      }

      // 검증 오류가 있으면 에러 응답
      if (errors.length > 0) {
        logger.warn('입력값 검증 실패', {
          endpoint: req.originalUrl,
          method: req.method,
          source,
          errors
        });

        const errorMessage = errors.map(e => `${e.field}: ${e.message}`).join(', ');
        throw new ValidationError(errorMessage);
      }

      next();
    } catch (error) {
      next(error);
    }
  };
}

/**
 * 개별 필드 검증
 * 
 * @param fieldName 필드명
 * @param value 검증할 값
 * @param rule 검증 규칙
 * @returns 검증 오류 목록
 */
function validateField(
  fieldName: string, 
  value: any, 
  rule: ValidationRule
): { field: string; message: string }[] {
  const errors: { field: string; message: string }[] = [];

  // 필수 필드 검증
  if (rule.required && (value === undefined || value === null || value === '')) {
    errors.push({
      field: fieldName,
      message: '필수 항목입니다'
    });
    return errors; // 필수 필드가 없으면 다른 검증은 무의미
  }

  // 값이 없으면 추가 검증 건너뛰기
  if (value === undefined || value === null || value === '') {
    return errors;
  }

  // 타입 검증
  if (rule.type) {
    const typeError = validateType(fieldName, value, rule.type);
    if (typeError) {
      errors.push(typeError);
      return errors; // 타입이 잘못되면 다른 검증은 무의미
    }
  }

  // 길이 검증 (문자열, 배열)
  if (typeof value === 'string' || Array.isArray(value)) {
    if (rule.minLength !== undefined && value.length < rule.minLength) {
      errors.push({
        field: fieldName,
        message: `최소 ${rule.minLength}자 이상이어야 합니다`
      });
    }

    if (rule.maxLength !== undefined && value.length > rule.maxLength) {
      errors.push({
        field: fieldName,
        message: `최대 ${rule.maxLength}자 이하여야 합니다`
      });
    }
  }

  // 숫자 범위 검증
  if (typeof value === 'number') {
    if (rule.min !== undefined && value < rule.min) {
      errors.push({
        field: fieldName,
        message: `${rule.min} 이상이어야 합니다`
      });
    }

    if (rule.max !== undefined && value > rule.max) {
      errors.push({
        field: fieldName,
        message: `${rule.max} 이하여야 합니다`
      });
    }
  }

  // 정규식 패턴 검증
  if (rule.pattern && typeof value === 'string') {
    if (!rule.pattern.test(value)) {
      errors.push({
        field: fieldName,
        message: '형식이 올바르지 않습니다'
      });
    }
  }

  // Enum 검증
  if (rule.enum && !rule.enum.includes(value)) {
    errors.push({
      field: fieldName,
      message: `허용된 값이 아닙니다. 가능한 값: ${rule.enum.join(', ')}`
    });
  }

  // 커스텀 검증
  if (rule.custom) {
    const result = rule.custom(value);
    if (result !== true) {
      errors.push({
        field: fieldName,
        message: typeof result === 'string' ? result : '커스텀 검증 실패'
      });
    }
  }

  return errors;
}

/**
 * 타입 검증
 * 
 * @param fieldName 필드명
 * @param value 검증할 값
 * @param expectedType 예상 타입
 * @returns 타입 오류 또는 null
 */
function validateType(
  fieldName: string, 
  value: any, 
  expectedType: string
): { field: string; message: string } | null {
  switch (expectedType) {
    case 'string':
      if (typeof value !== 'string') {
        return { field: fieldName, message: '문자열이어야 합니다' };
      }
      break;

    case 'number':
      if (typeof value !== 'number' || isNaN(value)) {
        return { field: fieldName, message: '숫자여야 합니다' };
      }
      break;

    case 'boolean':
      if (typeof value !== 'boolean') {
        return { field: fieldName, message: '불린값이어야 합니다' };
      }
      break;

    case 'array':
      if (!Array.isArray(value)) {
        return { field: fieldName, message: '배열이어야 합니다' };
      }
      break;

    case 'object':
      if (typeof value !== 'object' || Array.isArray(value) || value === null) {
        return { field: fieldName, message: '객체여야 합니다' };
      }
      break;

    case 'email':
      if (typeof value !== 'string' || !isValidEmail(value)) {
        return { field: fieldName, message: '유효한 이메일 주소여야 합니다' };
      }
      break;

    case 'date':
      if (typeof value === 'string') {
        const date = new Date(value);
        if (isNaN(date.getTime())) {
          return { field: fieldName, message: '유효한 날짜 형식이어야 합니다' };
        }
      } else if (!(value instanceof Date) || isNaN(value.getTime())) {
        return { field: fieldName, message: '유효한 날짜여야 합니다' };
      }
      break;

    default:
      logger.warn('알 수 없는 검증 타입', { fieldName, expectedType });
  }

  return null;
}

/**
 * 이메일 주소 유효성 검증
 * 
 * @param email 검증할 이메일 주소
 * @returns 유효성 여부
 */
function isValidEmail(email: string): boolean {
  const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailPattern.test(email);
}

/**
 * 쿼리 파라미터 검증 미들웨어
 * 
 * @param schema 검증 스키마
 * @returns Express 미들웨어 함수
 */
export function validateQuery(schema: ValidationSchema) {
  return validateInput(schema, 'query');
}

/**
 * URL 파라미터 검증 미들웨어
 * 
 * @param schema 검증 스키마
 * @returns Express 미들웨어 함수
 */
export function validateParams(schema: ValidationSchema) {
  return validateInput(schema, 'params');
}

/**
 * 페이지네이션 파라미터 검증 미들웨어
 * 
 * @returns Express 미들웨어 함수
 */
export function validatePagination() {
  return validateQuery({
    page: {
      required: false,
      type: 'number',
      min: 1
    },
    limit: {
      required: false,
      type: 'number',
      min: 1,
      max: 100
    },
    sort: {
      required: false,
      type: 'string'
    },
    order: {
      required: false,
      type: 'string',
      enum: ['asc', 'desc']
    }
  });
}