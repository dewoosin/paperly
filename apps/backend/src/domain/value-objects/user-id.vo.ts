// /Users/workspace/paperly/apps/backend/src/domain/value-objects/user-id.vo.ts

import { v4 as uuidv4 } from 'uuid';
import { BadRequestError } from '../../shared/errors';

/**
 * UserId Value Object
 * 
 * 사용자 ID를 나타내는 불변 객체
 * UUID v4 형식을 사용합니다.
 */
export class UserId {
  private readonly value: string;

  /**
   * UUID v4 정규식 패턴
   */
  private static readonly UUID_PATTERN = 
    /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

  /**
   * private 생성자
   */
  private constructor(id: string) {
    this.value = id.toLowerCase();
  }

  /**
   * 새로운 UserId 생성
   * 
   * @returns 새로운 UserId 인스턴스
   */
  static generate(): UserId {
    return new UserId(uuidv4());
  }

  /**
   * 기존 ID 문자열로부터 UserId 생성
   * 
   * @param id - UUID 문자열
   * @returns UserId 인스턴스
   * @throws BadRequestError - 유효하지 않은 UUID인 경우
   */
  static from(id: string): UserId {
    if (!id) {
      throw new BadRequestError('사용자 ID가 필요합니다');
    }

    if (!this.isValidUUID(id)) {
      throw new BadRequestError('유효하지 않은 사용자 ID 형식입니다');
    }

    return new UserId(id);
  }

  /**
   * UUID 유효성 검사
   */
  private static isValidUUID(id: string): boolean {
    return this.UUID_PATTERN.test(id);
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
   * 값 getter (호환성을 위한 별칭)
   */
  get value(): string {
    return this.value;
  }

  /**
   * 동일성 비교
   */
  equals(other: UserId): boolean {
    return this.value === other.value;
  }

  /**
   * JSON 직렬화 지원
   */
  toJSON(): string {
    return this.value;
  }
}