import { ValueObject } from '../../shared/domain/value-object';

/**
 * UserId Value Object
 * - DB는 SERIAL (INTEGER) 사용
 */
export class UserId extends ValueObject<number> {
  private constructor(value: number) {
    super(value);
  }

  static create(id: number): UserId {
    if (!Number.isInteger(id) || id <= 0) {
      throw new Error('유효하지 않은 사용자 ID입니다');
    }
    return new UserId(id);
  }

  static generate(): UserId {
    // 새 ID는 데이터베이스에서 SERIAL로 자동 생성되므로
    // 이 메서드는 사용하지 않거나 에러를 던집니다
    throw new Error('UserId는 데이터베이스에서 자동 생성됩니다');
  }

  toString(): string {
    return this.value.toString();
  }
}
