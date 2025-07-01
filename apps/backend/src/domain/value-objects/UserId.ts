/**
 * UserId.ts
 * 
 * 사용자 ID를 나타내는 Value Object
 * 타입 안정성과 ID 생성 로직 캡슐화
 */

import { ValidationError } from '../../shared/errors/index';

export class UserId {
  private readonly value: number;

  private constructor(id: number) {
    this.value = id;
  }

  /**
   * 기존 ID로부터 생성
   */
  public static create(id: number): UserId {
    if (!id || id <= 0) {
      throw new ValidationError('Invalid user ID');
    }

    return new UserId(id);
  }

  /**
   * 새 ID 생성 (자동 증가는 DB에서 처리)
   * 임시 ID 생성용
   */
  public static generate(): UserId {
    // 실제로는 DB에서 자동 생성되므로 임시값
    return new UserId(0);
  }

  /**
   * 숫자값 반환
   */
  public toNumber(): number {
    return this.value;
  }

  /**
   * 문자열로 변환
   */
  public toString(): string {
    return this.value.toString();
  }

  /**
   * 값 비교
   */
  public equals(other: UserId): boolean {
    return this.value === other.value;
  }

  /**
   * 신규 생성 여부 확인
   */
  public isNew(): boolean {
    return this.value === 0;
  }
}
