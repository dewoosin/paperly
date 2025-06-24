// /Users/workspace/paperly/apps/backend/src/domain/entities/user.entity.ts

import { Email } from '../value-objects/email.vo';
import { Password } from '../value-objects/password.vo';
import { UserId } from '../value-objects/user-id.vo';
import { Gender } from '../auth/auth.types';

/**
 * User Entity
 * 
 * 사용자 도메인 엔티티
 * 비즈니스 로직과 불변성을 보장합니다.
 */
export class User {
  private readonly _id: UserId;
  private readonly _email: Email;
  private readonly _password: Password;
  private _name: string;
  private _emailVerified: boolean;
  private readonly _birthDate: Date;
  private readonly _gender?: Gender;
  private readonly _createdAt: Date;
  private _updatedAt: Date;

  /**
   * 생성자
   * 
   * @param id - 사용자 ID
   * @param email - 이메일
   * @param password - 비밀번호 (해시된 상태)
   * @param name - 이름
   * @param emailVerified - 이메일 인증 여부
   * @param birthDate - 생년월일
   * @param gender - 성별 (선택적)
   * @param createdAt - 생성일시
   * @param updatedAt - 수정일시
   */
  constructor(
    id: UserId,
    email: Email,
    password: Password,
    name: string,
    emailVerified: boolean,
    birthDate: Date,
    gender?: Gender,
    createdAt?: Date,
    updatedAt?: Date
  ) {
    this._id = id;
    this._email = email;
    this._password = password;
    this._name = name;
    this._emailVerified = emailVerified;
    this._birthDate = birthDate;
    this._gender = gender;
    this._createdAt = createdAt || new Date();
    this._updatedAt = updatedAt || new Date();
  }

  /**
   * 새로운 사용자 생성 (팩토리 메서드)
   */
  static create(params: {
    email: Email;
    password: Password;
    name: string;
    birthDate: Date;
    gender?: Gender;
  }): User {
    return new User(
      UserId.generate(),
      params.email,
      params.password,
      params.name,
      false, // 신규 사용자는 이메일 미인증 상태
      params.birthDate,
      params.gender
    );
  }

  /**
   * DB 데이터로부터 재구성 (팩토리 메서드)
   */
  static fromPersistence(params: {
    id: string;
    email: string;
    passwordHash: string;
    name: string;
    emailVerified: boolean;
    birthDate: Date;
    gender?: Gender;
    createdAt: Date;
    updatedAt: Date;
  }): User {
    return new User(
      UserId.from(params.id),
      Email.create(params.email),
      Password.fromHash(params.passwordHash),
      params.name,
      params.emailVerified,
      params.birthDate,
      params.gender,
      params.createdAt,
      params.updatedAt
    );
  }

  // Getters
  get id(): UserId {
    return this._id;
  }

  get email(): Email {
    return this._email;
  }

  get password(): Password {
    return this._password;
  }

  get name(): string {
    return this._name;
  }

  get emailVerified(): boolean {
    return this._emailVerified;
  }

  get birthDate(): Date {
    return this._birthDate;
  }

  get gender(): Gender | undefined {
    return this._gender;
  }

  get createdAt(): Date {
    return this._createdAt;
  }

  get updatedAt(): Date {
    return this._updatedAt;
  }

  /**
   * 나이 계산
   */
  getAge(): number {
    const today = new Date();
    const birthDate = new Date(this._birthDate);
    let age = today.getFullYear() - birthDate.getFullYear();
    const monthDiff = today.getMonth() - birthDate.getMonth();
    
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
      age--;
    }
    
    return age;
  }

  /**
   * 이메일 인증 처리
   */
  verifyEmail(): void {
    this._emailVerified = true;
    this._updatedAt = new Date();
  }

  /**
   * 이름 변경
   */
  changeName(newName: string): void {
    if (!newName || newName.trim().length < 2) {
      throw new Error('이름은 2자 이상이어야 합니다');
    }
    this._name = newName.trim();
    this._updatedAt = new Date();
  }

  /**
   * 영속성을 위한 일반 객체로 변환
   */
  toPersistence() {
    return {
      id: this._id.getValue(),
      email: this._email.getValue(),
      passwordHash: this._password.getHashedValue(),
      name: this._name,
      emailVerified: this._emailVerified,
      birthDate: this._birthDate,
      gender: this._gender,
      createdAt: this._createdAt,
      updatedAt: this._updatedAt,
    };
  }
}