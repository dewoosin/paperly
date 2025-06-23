#!/bin/bash

# Value Objects 생성 스크립트

echo "Creating Value Objects..."

# Email Value Object
cat > src/domain/value-objects/Email.ts << 'EOF'
/**
 * Email.ts
 * 
 * 이메일 주소를 나타내는 Value Object
 * 불변성과 유효성 검증을 보장
 */

import { ValidationError } from '../../shared/errors/BaseError';

export class Email {
  private readonly value: string;

  private constructor(email: string) {
    this.value = email.toLowerCase();
  }

  /**
   * 이메일 생성 및 검증
   */
  public static create(email: string): Email {
    if (!email) {
      throw new ValidationError('Email is required');
    }

    const trimmedEmail = email.trim();
    
    if (!this.isValid(trimmedEmail)) {
      throw new ValidationError('Invalid email format');
    }

    return new Email(trimmedEmail);
  }

  /**
   * 이메일 형식 검증
   */
  private static isValid(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  /**
   * 문자열로 변환
   */
  public toString(): string {
    return this.value;
  }

  /**
   * 값 비교
   */
  public equals(other: Email): boolean {
    return this.value === other.value;
  }
}
EOF

# Password Value Object
cat > src/domain/value-objects/Password.ts << 'EOF'
/**
 * Password.ts
 * 
 * 비밀번호를 나타내는 Value Object
 * 비밀번호 강도 검증 및 해싱 담당
 */

import bcrypt from 'bcrypt';
import { ValidationError } from '../../shared/errors/BaseError';
import { config } from '../../infrastructure/config/env.config';

export class Password {
  private readonly value: string;

  private constructor(password: string) {
    this.value = password;
  }

  /**
   * 비밀번호 생성 및 검증
   */
  public static create(password: string): Password {
    if (!password) {
      throw new ValidationError('Password is required');
    }

    if (!this.isStrong(password)) {
      throw new ValidationError(
        'Password must be at least 8 characters long and contain uppercase, lowercase, number, and special character'
      );
    }

    return new Password(password);
  }

  /**
   * 비밀번호 강도 검증
   */
  private static isStrong(password: string): boolean {
    // 최소 8자, 대문자, 소문자, 숫자, 특수문자 포함
    const minLength = password.length >= 8;
    const hasUpperCase = /[A-Z]/.test(password);
    const hasLowerCase = /[a-z]/.test(password);
    const hasNumber = /\d/.test(password);
    const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(password);

    return minLength && hasUpperCase && hasLowerCase && hasNumber && hasSpecialChar;
  }

  /**
   * 비밀번호 해싱
   */
  public async hash(): Promise<string> {
    return bcrypt.hash(this.value, config.BCRYPT_SALT_ROUNDS);
  }

  /**
   * 해시와 비교
   */
  public async compare(hash: string): Promise<boolean> {
    return bcrypt.compare(this.value, hash);
  }
}
EOF

# UserId Value Object
cat > src/domain/value-objects/UserId.ts << 'EOF'
/**
 * UserId.ts
 * 
 * 사용자 ID를 나타내는 Value Object
 * 타입 안정성과 ID 생성 로직 캡슐화
 */

import { ValidationError } from '../../shared/errors/BaseError';

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
EOF

# ArticleId Value Object
cat > src/domain/value-objects/ArticleId.ts << 'EOF'
/**
 * ArticleId.ts
 * 
 * 기사 ID를 나타내는 Value Object
 */

import { ValidationError } from '../../shared/errors/BaseError';

export class ArticleId {
  private readonly value: number;

  private constructor(id: number) {
    this.value = id;
  }

  public static create(id: number): ArticleId {
    if (!id || id <= 0) {
      throw new ValidationError('Invalid article ID');
    }

    return new ArticleId(id);
  }

  public static generate(): ArticleId {
    return new ArticleId(0);
  }

  public toNumber(): number {
    return this.value;
  }

  public toString(): string {
    return this.value.toString();
  }

  public equals(other: ArticleId): boolean {
    return this.value === other.value;
  }

  public isNew(): boolean {
    return this.value === 0;
  }
}
EOF

# CategoryId Value Object
cat > src/domain/value-objects/CategoryId.ts << 'EOF'
/**
 * CategoryId.ts
 * 
 * 카테고리 ID를 나타내는 Value Object
 */

import { ValidationError } from '../../shared/errors/BaseError';

export class CategoryId {
  private readonly value: number;

  private constructor(id: number) {
    this.value = id;
  }

  public static create(id: number): CategoryId {
    if (!id || id <= 0) {
      throw new ValidationError('Invalid category ID');
    }

    return new CategoryId(id);
  }

  public toNumber(): number {
    return this.value;
  }

  public toString(): string {
    return this.value.toString();
  }

  public equals(other: CategoryId): boolean {
    return this.value === other.value;
  }
}
EOF

echo "✅ Value Objects created successfully!"
EOF
