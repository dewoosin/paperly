// /Users/workspace/paperly/apps/backend/src/domain/value-objects/email.vo.ts

import { z } from 'zod';
import { BadRequestError } from '../../shared/errors/index';
import { MESSAGE_CODES } from '../../shared/constants/message-codes';

/**
 * Email Value Object
 * 
 * 이메일 주소를 나타내는 불변 객체
 * 유효성 검증 로직을 포함합니다.
 */
export class Email {
  private readonly value: string;

  /**
   * 이메일 검증 스키마
   */
  private static readonly schema = z
    .string()
    .email('Invalid email format')
    .toLowerCase()
    .max(255, 'Email cannot exceed 255 characters');

  /**
   * private 생성자 - create 메서드를 통해서만 생성 가능
   */
  private constructor(email: string) {
    this.value = email.toLowerCase().trim();
  }

  /**
   * 이메일 인스턴스 생성
   * 
   * @param email - 이메일 문자열
   * @returns Email 인스턴스
   * @throws BadRequestError - 유효하지 않은 이메일인 경우
   */
  static create(email: string): Email {
    try {
      const validatedEmail = this.schema.parse(email.trim());
      return new Email(validatedEmail);
    } catch (error) {
      if (error instanceof z.ZodError) {
        const isEmailFormat = error.errors.some(e => e.code === 'invalid_string' && e.validation === 'email');
        const messageCode = isEmailFormat ? MESSAGE_CODES.VALIDATION.INVALID_EMAIL_FORMAT : MESSAGE_CODES.VALIDATION.REQUIRED_FIELD_MISSING;
        throw new BadRequestError(error.errors[0].message, undefined, messageCode);
      }
      throw error;
    }
  }

  /**
   * 문자열로 변환
   */
  toString(): string {
    return this.value;
  }

  /**
   * 값 getter
   */
  getValue(): string {
    return this.value;
  }

  /**
   * 동일성 비교
   */
  equals(other: Email): boolean {
    return this.value === other.value;
  }

  /**
   * 도메인 추출
   */
  getDomain(): string {
    return this.value.split('@')[1];
  }

  /**
   * 로컬 파트 추출
   */
  getLocalPart(): string {
    return this.value.split('@')[0];
  }
}