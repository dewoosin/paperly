// apps/backend/src/infrastructure/auth/password.service.ts

import bcrypt from 'bcrypt';
import { logger } from '../logging/logger';

/**
 * 비밀번호 서비스
 * 
 * 비밀번호의 해싱과 검증을 담당합니다.
 */
export class PasswordService {
  /**
   * Salt rounds for bcrypt
   * 높을수록 보안성은 좋지만 처리 시간이 길어집니다.
   */
  private static readonly SALT_ROUNDS = 10;

  /**
   * 비밀번호 해싱
   * 
   * @param password - 평문 비밀번호
   * @returns 해싱된 비밀번호
   */
  static async hash(password: string): Promise<string> {
    try {
      const hashedPassword = await bcrypt.hash(password, this.SALT_ROUNDS);
      logger.debug('Password hashed successfully');
      return hashedPassword;
    } catch (error) {
      logger.error('Password hashing failed:', error);
      throw new Error('Failed to hash password');
    }
  }

  /**
   * 비밀번호 검증
   * 
   * @param password - 평문 비밀번호
   * @param hashedPassword - 해싱된 비밀번호
   * @returns 일치 여부
   */
  static async verify(password: string, hashedPassword: string): Promise<boolean> {
    try {
      const isValid = await bcrypt.compare(password, hashedPassword);
      logger.debug('Password verification:', { isValid });
      return isValid;
    } catch (error) {
      logger.error('Password verification failed:', error);
      return false;
    }
  }

  /**
   * 비밀번호 강도 검증
   * 
   * @param password - 검증할 비밀번호
   * @returns 검증 결과
   */
  static validateStrength(password: string): {
    isValid: boolean;
    errors: string[];
  } {
    const errors: string[] = [];

    // 최소 길이 체크
    if (password.length < 8) {
      errors.push('비밀번호는 최소 8자 이상이어야 합니다');
    }

    // 영문 포함 체크
    if (!/[a-zA-Z]/.test(password)) {
      errors.push('비밀번호는 영문을 포함해야 합니다');
    }

    // 숫자 포함 체크
    if (!/\d/.test(password)) {
      errors.push('비밀번호는 숫자를 포함해야 합니다');
    }

    // 특수문자 포함 체크 (선택사항)
    // if (!/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
    //   errors.push('비밀번호는 특수문자를 포함해야 합니다');
    // }

    return {
      isValid: errors.length === 0,
      errors,
    };
  }

  /**
   * 임시 비밀번호 생성
   * 
   * @param length - 비밀번호 길이 (기본값: 12)
   * @returns 생성된 임시 비밀번호
   */
  static generateTemporary(length: number = 12): string {
    const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*';
    let password = '';

    // 각 유형별로 최소 1개씩 포함
    password += 'abcdefghijklmnopqrstuvwxyz'[Math.floor(Math.random() * 26)];
    password += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'[Math.floor(Math.random() * 26)];
    password += '0123456789'[Math.floor(Math.random() * 10)];
    password += '!@#$%^&*'[Math.floor(Math.random() * 8)];

    // 나머지 길이만큼 랜덤 생성
    for (let i = password.length; i < length; i++) {
      password += charset[Math.floor(Math.random() * charset.length)];
    }

    // 문자 순서 섞기
    return password
      .split('')
      .sort(() => Math.random() - 0.5)
      .join('');
  }
}