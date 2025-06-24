// /Users/workspace/paperly/apps/backend/src/domain/value-objects/password.vo.ts

import bcrypt from 'bcrypt';
import { BadRequestError } from '../../shared/errors';
import { PasswordService } from '../../infrastructure/auth/password.service';

/**
 * Password Value Object
 * 
 * 비밀번호를 나타내는 불변 객체
 * 평문 비밀번호는 저장하지 않고, 해시된 값만 저장합니다.
 */
export class Password {
  private readonly hashedValue: string;

  /**
   * 비밀번호 정책
   */
  private static readonly MIN_LENGTH = 8;
  private static readonly MAX_LENGTH = 100;
  private static readonly SALT_ROUNDS = 10;

  /**
   * private 생성자 - 팩토리 메서드를 통해서만 생성
   */
  private constructor(hashedValue: string) {
    this.hashedValue = hashedValue;
  }

  /**
   * 평문 비밀번호로부터 Password 인스턴스 생성
   * 
   * @param plainPassword - 평문 비밀번호
   * @returns Password 인스턴스
   * @throws BadRequestError - 비밀번호 정책 위반 시
   */
  static async create(plainPassword: string): Promise<Password> {
    // 기본 검증
    if (!plainPassword || plainPassword.length < this.MIN_LENGTH) {
      throw new BadRequestError(
        `비밀번호는 최소 ${this.MIN_LENGTH}자 이상이어야 합니다`
      );
    }

    if (plainPassword.length > this.MAX_LENGTH) {
      throw new BadRequestError(
        `비밀번호는 ${this.MAX_LENGTH}자를 초과할 수 없습니다`
      );
    }

    // 강도 검증
    const strengthCheck = PasswordService.validateStrength(plainPassword);
    if (!strengthCheck.isValid) {
      throw new BadRequestError(strengthCheck.errors.join(', '));
    }

    // 해싱
    const hashedValue = await bcrypt.hash(plainPassword, this.SALT_ROUNDS);
    return new Password(hashedValue);
  }

  /**
   * 이미 해시된 값으로부터 Password 인스턴스 생성
   * (DB에서 조회한 경우)
   * 
   * @param hashedValue - 해시된 비밀번호
   * @returns Password 인스턴스
   */
  static fromHash(hashedValue: string): Password {
    if (!hashedValue) {
      throw new BadRequestError('해시된 비밀번호가 필요합니다');
    }
    return new Password(hashedValue);
  }

  /**
   * 평문 비밀번호와 비교
   * 
   * @param plainPassword - 비교할 평문 비밀번호
   * @returns 일치 여부
   */
  async verify(plainPassword: string): Promise<boolean> {
    if (!plainPassword) {
      return false;
    }
    return bcrypt.compare(plainPassword, this.hashedValue);
  }

  /**
   * 해시값 getter
   */
  getHashedValue(): string {
    return this.hashedValue;
  }

  /**
   * 동일성 비교 (해시값 비교)
   */
  equals(other: Password): boolean {
    return this.hashedValue === other.hashedValue;
  }
}