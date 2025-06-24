// /Users/workspace/paperly/apps/backend/src/infrastructure/auth/password.service.ts

import bcrypt from 'bcrypt';

/**
 * 비밀번호 관련 서비스
 * 
 * 비밀번호 해싱, 검증, 강도 체크 등의 기능을 제공합니다.
 */
export class PasswordService {
  /**
   * 비밀번호 해싱 설정
   */
  private static readonly SALT_ROUNDS = 10;

  /**
   * 비밀번호 정책
   */
  private static readonly MIN_LENGTH = 8;
  private static readonly MAX_LENGTH = 100;

  /**
   * 비밀번호 해싱
   * 
   * @param plainPassword - 평문 비밀번호
   * @returns 해시된 비밀번호
   */
  static async hash(plainPassword: string): Promise<string> {
    return bcrypt.hash(plainPassword, this.SALT_ROUNDS);
  }

  /**
   * 비밀번호 검증
   * 
   * @param plainPassword - 평문 비밀번호
   * @param hashedPassword - 해시된 비밀번호
   * @returns 일치 여부
   */
  static async verify(plainPassword: string, hashedPassword: string): Promise<boolean> {
    return bcrypt.compare(plainPassword, hashedPassword);
  }

  /**
   * 비밀번호 강도 검증
   * 
   * @param password - 검증할 비밀번호
   * @returns 검증 결과
   */
  static validateStrength(password: string): {
    isValid: boolean;
    score: number;
    errors: string[];
  } {
    const errors: string[] = [];
    let score = 0;

    // 길이 검증
    if (!password || password.length < this.MIN_LENGTH) {
      errors.push(`비밀번호는 최소 ${this.MIN_LENGTH}자 이상이어야 합니다`);
    } else if (password.length > this.MAX_LENGTH) {
      errors.push(`비밀번호는 ${this.MAX_LENGTH}자를 초과할 수 없습니다`);
    } else {
      score += 1;
    }

    // 대문자 포함 여부
    if (/[A-Z]/.test(password)) {
      score += 1;
    } else {
      errors.push('대문자를 포함해야 합니다');
    }

    // 소문자 포함 여부
    if (/[a-z]/.test(password)) {
      score += 1;
    } else {
      errors.push('소문자를 포함해야 합니다');
    }

    // 숫자 포함 여부
    if (/[0-9]/.test(password)) {
      score += 1;
    } else {
      errors.push('숫자를 포함해야 합니다');
    }

    // 특수문자 포함 여부
    if (/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password)) {
      score += 1;
    } else {
      errors.push('특수문자를 포함해야 합니다');
    }

    // 연속된 문자 체크
    if (this.hasRepeatingCharacters(password)) {
      errors.push('같은 문자를 3번 이상 연속해서 사용할 수 없습니다');
      score -= 1;
    }

    // 일반적인 패턴 체크
    if (this.hasCommonPatterns(password)) {
      errors.push('쉽게 추측 가능한 패턴은 사용할 수 없습니다');
      score -= 1;
    }

    return {
      isValid: errors.length === 0 && score >= 3,
      score: Math.max(0, Math.min(5, score)),
      errors
    };
  }

  /**
   * 연속된 문자 체크
   * 
   * @param password - 검사할 비밀번호
   * @returns 연속된 문자가 있는지 여부
   */
  private static hasRepeatingCharacters(password: string): boolean {
    return /(.)\1{2,}/.test(password);
  }

  /**
   * 일반적인 패턴 체크
   * 
   * @param password - 검사할 비밀번호
   * @returns 일반적인 패턴이 있는지 여부
   */
  private static hasCommonPatterns(password: string): boolean {
    const commonPatterns = [
      '123456',
      'password',
      'qwerty',
      'abc123',
      '111111',
      '12345678',
      'password123',
      '1234567890',
      'qwertyuiop',
      'asdfghjkl',
      'zxcvbnm'
    ];

    const lowerPassword = password.toLowerCase();
    return commonPatterns.some(pattern => lowerPassword.includes(pattern));
  }

  /**
   * 랜덤 비밀번호 생성
   * 
   * @param length - 비밀번호 길이 (기본값: 16)
   * @returns 생성된 비밀번호
   */
  static generateRandom(length: number = 16): string {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const symbols = '!@#$%^&*()_+-=[]{}|;:,.<>?';
    
    const allChars = uppercase + lowercase + numbers + symbols;
    let password = '';

    // 각 문자 유형에서 최소 하나씩 포함
    password += uppercase[Math.floor(Math.random() * uppercase.length)];
    password += lowercase[Math.floor(Math.random() * lowercase.length)];
    password += numbers[Math.floor(Math.random() * numbers.length)];
    password += symbols[Math.floor(Math.random() * symbols.length)];

    // 나머지 문자 채우기
    for (let i = password.length; i < length; i++) {
      password += allChars[Math.floor(Math.random() * allChars.length)];
    }

    // 문자 순서 섞기
    return password.split('').sort(() => Math.random() - 0.5).join('');
  }
}