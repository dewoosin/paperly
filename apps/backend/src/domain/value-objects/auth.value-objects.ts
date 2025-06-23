// apps/backend/src/domain/value-objects/auth.value-objects.ts

import { z } from 'zod';
import { createHash, randomBytes } from 'crypto';
import { ValueObject } from '../../shared/domain/value-object';

/**
 * 이메일 Value Object
 * - 형식 검증
 * - 정규화 (소문자 변환)
 */
export class Email extends ValueObject<string> {
  private static readonly schema = z.string().email();

  private constructor(value: string) {
    super(value);
  }

  static create(email: string): Email {
    // 이메일 정규화 (소문자 변환, 공백 제거)
    const normalized = email.trim().toLowerCase();
    
    // 검증
    const result = this.schema.safeParse(normalized);
    if (!result.success) {
      throw new Error('유효하지 않은 이메일 형식입니다');
    }

    return new Email(normalized);
  }

  get domain(): string {
    return this.value.split('@')[1];
  }

  toString(): string {
    return this.value;
  }
}

/**
 * 비밀번호 Value Object
 * - 복잡도 검증 (최소 8자, 영문+숫자)
 * - 해싱 처리
 */
export class Password extends ValueObject<string> {
  private static readonly MIN_LENGTH = 8;
  private static readonly SALT_ROUNDS = 10;

  private constructor(value: string) {
    super(value);
  }

  /**
   * 평문 비밀번호로부터 Password 객체 생성
   */
  static create(plainPassword: string): Password {
    this.validate(plainPassword);
    return new Password(plainPassword);
  }

  /**
   * 해시된 비밀번호로부터 Password 객체 생성 (DB에서 읽을 때)
   */
  static fromHash(hashedPassword: string): Password {
    return new Password(hashedPassword);
  }

  /**
   * 비밀번호 검증
   */
  private static validate(password: string): void {
    if (password.length < this.MIN_LENGTH) {
      throw new Error(`비밀번호는 최소 ${this.MIN_LENGTH}자 이상이어야 합니다`);
    }

    if (!/[a-zA-Z]/.test(password)) {
      throw new Error('비밀번호는 영문자를 포함해야 합니다');
    }

    if (!/[0-9]/.test(password)) {
      throw new Error('비밀번호는 숫자를 포함해야 합니다');
    }
  }

  /**
   * bcrypt를 사용한 비밀번호 해싱
   */
  async hash(): Promise<string> {
    const bcrypt = await import('bcrypt');
    return bcrypt.hash(this.value, Password.SALT_ROUNDS);
  }

  /**
   * 비밀번호 일치 여부 확인
   */
  async compare(plainPassword: string): Promise<boolean> {
    const bcrypt = await import('bcrypt');
    return bcrypt.compare(plainPassword, this.value);
  }
}

/**
 * JWT 토큰 Value Object
 */
export class Token extends ValueObject<string> {
  private constructor(value: string) {
    super(value);
  }

  static create(value: string): Token {
    if (!value || value.trim().length === 0) {
      throw new Error('토큰이 비어있습니다');
    }
    return new Token(value.trim());
  }

  /**
   * 랜덤 토큰 생성 (이메일 인증, 비밀번호 재설정 등)
   */
  static generateRandom(bytes: number = 32): Token {
    const token = randomBytes(bytes).toString('hex');
    return new Token(token);
  }

  /**
   * 토큰 해시 (DB 저장용)
   */
  hash(): string {
    return createHash('sha256').update(this.value).digest('hex');
  }

  toString(): string {
    return this.value;
  }
}

/**
 * 생년월일 Value Object
 */
export class BirthDate extends ValueObject<Date> {
  private constructor(value: Date) {
    super(value);
  }

  static create(date: Date | string): BirthDate {
    const birthDate = typeof date === 'string' ? new Date(date) : date;
    
    // 유효한 날짜인지 확인
    if (isNaN(birthDate.getTime())) {
      throw new Error('유효하지 않은 날짜입니다');
    }

    // 미래 날짜 체크
    if (birthDate > new Date()) {
      throw new Error('생년월일은 미래일 수 없습니다');
    }

    // 너무 오래된 날짜 체크 (120년)
    const minDate = new Date();
    minDate.setFullYear(minDate.getFullYear() - 120);
    if (birthDate < minDate) {
      throw new Error('유효하지 않은 생년월일입니다');
    }

    return new BirthDate(birthDate);
  }

  get age(): number {
    const today = new Date();
    let age = today.getFullYear() - this.value.getFullYear();
    const monthDiff = today.getMonth() - this.value.getMonth();
    
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < this.value.getDate())) {
      age--;
    }
    
    return age;
  }

  get ageGroup(): string {
    const age = this.age;
    if (age < 20) return '10대';
    if (age < 30) return '20대';
    if (age < 40) return '30대';
    if (age < 50) return '40대';
    if (age < 60) return '50대';
    return '60대 이상';
  }

  toISOString(): string {
    return this.value.toISOString().split('T')[0];
  }
}

/**
 * 성별 Value Object
 */
export enum GenderType {
  MALE = 'male',
  FEMALE = 'female',
  OTHER = 'other',
  PREFER_NOT_TO_SAY = 'prefer_not_to_say'
}

export class Gender extends ValueObject<GenderType> {
  private constructor(value: GenderType) {
    super(value);
  }

  static create(gender: string): Gender {
    const normalizedGender = gender.toLowerCase();
    
    if (!Object.values(GenderType).includes(normalizedGender as GenderType)) {
      throw new Error('유효하지 않은 성별입니다');
    }

    return new Gender(normalizedGender as GenderType);
  }

  static createOptional(gender?: string | null): Gender | null {
    if (!gender) return null;
    return this.create(gender);
  }

  toKorean(): string {
    switch (this.value) {
      case GenderType.MALE:
        return '남성';
      case GenderType.FEMALE:
        return '여성';
      case GenderType.OTHER:
        return '기타';
      case GenderType.PREFER_NOT_TO_SAY:
        return '밝히지 않음';
    }
  }
}

/**
 * 디바이스 정보 Value Object
 */
export class DeviceInfo extends ValueObject<{ id: string; name: string }> {
  private constructor(value: { id: string; name: string }) {
    super(value);
  }

  static create(deviceId: string, userAgent: string): DeviceInfo {
    if (!deviceId || deviceId.trim().length === 0) {
      throw new Error('디바이스 ID가 필요합니다');
    }

    // User-Agent에서 디바이스 이름 추출
    const deviceName = this.parseDeviceName(userAgent);

    return new DeviceInfo({
      id: deviceId.trim(),
      name: deviceName
    });
  }

  private static parseDeviceName(userAgent: string): string {
    // 간단한 User-Agent 파싱
    if (userAgent.includes('iPhone')) return 'iPhone';
    if (userAgent.includes('iPad')) return 'iPad';
    if (userAgent.includes('Android')) return 'Android Device';
    if (userAgent.includes('Windows')) return 'Windows PC';
    if (userAgent.includes('Mac')) return 'Mac';
    if (userAgent.includes('Linux')) return 'Linux PC';
    return 'Unknown Device';
  }

  get id(): string {
    return this.value.id;
  }

  get name(): string {
    return this.value.name;
  }
}
