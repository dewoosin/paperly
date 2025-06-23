/**
 * User.entity.ts
 * 
 * 사용자 도메인 엔티티
 * DDD 원칙에 따라 비즈니스 로직을 엔티티에 포함
 */

import bcrypt from 'bcrypt';
import { BusinessRuleError } from '../../shared/errors/BaseError';
import { Email } from '../value-objects/Email';
import { Password } from '../value-objects/Password';
import { UserId } from '../value-objects/UserId';

/**
 * 사용자 상태
 */
export enum UserStatus {
  PENDING = 'PENDING',      // 이메일 인증 대기
  ACTIVE = 'ACTIVE',        // 활성 사용자
  SUSPENDED = 'SUSPENDED',  // 정지된 사용자
  DELETED = 'DELETED',      // 삭제된 사용자
}

/**
 * 사용자 역할
 */
export enum UserRole {
  USER = 'USER',
  ADMIN = 'ADMIN',
  AUTHOR = 'AUTHOR',
}

/**
 * 사용자 생성 매개변수
 */
export interface CreateUserParams {
  email: string;
  password: string;
  username?: string;
  fullName?: string;
}

/**
 * 사용자 엔티티 속성
 */
export interface UserProps {
  id: UserId;
  email: Email;
  passwordHash: string;
  username?: string;
  fullName?: string;
  profileImageUrl?: string;
  bio?: string;
  status: UserStatus;
  role: UserRole;
  emailVerified: boolean;
  emailVerificationToken?: string;
  emailVerificationExpiresAt?: Date;
  lastLoginAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * 사용자 도메인 엔티티
 * 
 * @example
 * const user = await User.create({
 *   email: 'user@example.com',
 *   password: 'SecurePassword123!',
 *   username: 'johndoe',
 *   fullName: 'John Doe'
 * });
 */
export class User {
  private readonly props: UserProps;

  /**
   * private 생성자 - 팩토리 메서드를 통해서만 생성 가능
   */
  private constructor(props: UserProps) {
    this.props = props;
  }

  /**
   * 새 사용자 생성 (팩토리 메서드)
   */
  public static async create(params: CreateUserParams): Promise<User> {
    // 이메일 검증
    const email = Email.create(params.email);
    
    // 비밀번호 검증
    const password = Password.create(params.password);
    
    // 비밀번호 해싱
    const passwordHash = await password.hash();
    
    // 사용자명 검증
    if (params.username) {
      this.validateUsername(params.username);
    }
    
    // 엔티티 생성
    return new User({
      id: UserId.generate(),
      email,
      passwordHash,
      username: params.username,
      fullName: params.fullName,
      status: UserStatus.PENDING,
      role: UserRole.USER,
      emailVerified: false,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  }

  /**
   * 기존 데이터로부터 엔티티 재구성
   */
  public static fromPersistence(props: UserProps): User {
    return new User(props);
  }

  /**
   * 사용자명 유효성 검증
   */
  private static validateUsername(username: string): void {
    if (username.length < 3 || username.length > 20) {
      throw new BusinessRuleError('Username must be between 3 and 20 characters');
    }
    
    if (!/^[a-zA-Z0-9_]+$/.test(username)) {
      throw new BusinessRuleError('Username can only contain letters, numbers, and underscores');
    }
  }

  /**
   * 비밀번호 검증
   */
  public async verifyPassword(password: string): Promise<boolean> {
    return bcrypt.compare(password, this.props.passwordHash);
  }

  /**
   * 비밀번호 변경
   */
  public async changePassword(currentPassword: string, newPassword: string): Promise<void> {
    // 현재 비밀번호 확인
    const isValid = await this.verifyPassword(currentPassword);
    if (!isValid) {
      throw new BusinessRuleError('Current password is incorrect');
    }
    
    // 새 비밀번호 검증 및 해싱
    const password = Password.create(newPassword);
    this.props.passwordHash = await password.hash();
    this.updateTimestamp();
  }

  /**
   * 이메일 인증 토큰 생성
   */
  public generateEmailVerificationToken(): string {
    const token = this.generateSecureToken();
    this.props.emailVerificationToken = token;
    this.props.emailVerificationExpiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24시간
    this.updateTimestamp();
    return token;
  }

  /**
   * 이메일 인증
   */
  public verifyEmail(token: string): void {
    if (!this.props.emailVerificationToken || this.props.emailVerificationToken !== token) {
      throw new BusinessRuleError('Invalid verification token');
    }
    
    if (this.props.emailVerificationExpiresAt && this.props.emailVerificationExpiresAt < new Date()) {
      throw new BusinessRuleError('Verification token has expired');
    }
    
    this.props.emailVerified = true;
    this.props.status = UserStatus.ACTIVE;
    this.props.emailVerificationToken = undefined;
    this.props.emailVerificationExpiresAt = undefined;
    this.updateTimestamp();
  }

  /**
   * 프로필 업데이트
   */
  public updateProfile(updates: {
    username?: string;
    fullName?: string;
    bio?: string;
    profileImageUrl?: string;
  }): void {
    if (updates.username) {
      User.validateUsername(updates.username);
      this.props.username = updates.username;
    }
    
    if (updates.fullName !== undefined) {
      this.props.fullName = updates.fullName;
    }
    
    if (updates.bio !== undefined) {
      this.props.bio = updates.bio;
    }
    
    if (updates.profileImageUrl !== undefined) {
      this.props.profileImageUrl = updates.profileImageUrl;
    }
    
    this.updateTimestamp();
  }

  /**
   * 로그인 시간 업데이트
   */
  public recordLogin(): void {
    this.props.lastLoginAt = new Date();
    this.updateTimestamp();
  }

  /**
   * 사용자 정지
   */
  public suspend(): void {
    if (this.props.status === UserStatus.DELETED) {
      throw new BusinessRuleError('Cannot suspend deleted user');
    }
    
    this.props.status = UserStatus.SUSPENDED;
    this.updateTimestamp();
  }

  /**
   * 사용자 활성화
   */
  public activate(): void {
    if (this.props.status === UserStatus.DELETED) {
      throw new BusinessRuleError('Cannot activate deleted user');
    }
    
    if (!this.props.emailVerified) {
      throw new BusinessRuleError('Cannot activate user with unverified email');
    }
    
    this.props.status = UserStatus.ACTIVE;
    this.updateTimestamp();
  }

  /**
   * 사용자 삭제 (소프트 삭제)
   */
  public delete(): void {
    this.props.status = UserStatus.DELETED;
    this.updateTimestamp();
  }

  /**
   * 타임스탬프 업데이트
   */
  private updateTimestamp(): void {
    this.props.updatedAt = new Date();
  }

  /**
   * 보안 토큰 생성
   */
  private generateSecureToken(): string {
    return Array.from(crypto.getRandomValues(new Uint8Array(32)))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('');
  }

  // Getters
  get id(): UserId { return this.props.id; }
  get email(): Email { return this.props.email; }
  get username(): string | undefined { return this.props.username; }
  get fullName(): string | undefined { return this.props.fullName; }
  get profileImageUrl(): string | undefined { return this.props.profileImageUrl; }
  get bio(): string | undefined { return this.props.bio; }
  get status(): UserStatus { return this.props.status; }
  get role(): UserRole { return this.props.role; }
  get emailVerified(): boolean { return this.props.emailVerified; }
  get lastLoginAt(): Date | undefined { return this.props.lastLoginAt; }
  get createdAt(): Date { return this.props.createdAt; }
  get updatedAt(): Date { return this.props.updatedAt; }

  /**
   * 엔티티를 영속성 계층용 plain object로 변환
   */
  public toPersistence(): UserProps {
    return { ...this.props };
  }
}
