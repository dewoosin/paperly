/// Paperly Backend - 사용자 도메인 엔티티
/// 
/// 이 파일은 Domain-Driven Design(DDD)의 핵심인 User 엔티티를 구현합니다.
/// 사용자의 모든 비즈니스 로직과 불변성을 보장하며, 도메인 규칙을 캡슐화합니다.
/// 
/// DDD 패턴:
/// - Entity: 고유한 식별자를 가지는 도메인 객체
/// - Value Objects: 불변하는 값 객체들로 구성 (Email, Password, UserId)
/// - Business Logic: 도메인 규칙과 제약사항을 메서드로 캡슐화
/// - Factory Methods: 객체 생성의 복잡성을 숨기고 올바른 상태 보장
/// 
/// 주요 책임:
/// 1. 사용자 데이터의 일관성과 유효성 보장
/// 2. 사용자 관련 비즈니스 규칙 구현 (이름 변경, 이메일 인증 등)
/// 3. 데이터 캡슐화 및 무결성 유지
/// 4. 영속성 계층과의 변환 지원
/// 
/// 보안 고려사항:
/// - 비밀번호는 Value Object로 해시된 상태로만 저장
/// - 이메일 인증 상태 추적
/// - 사용자 상태 관리 (활성, 비활성, 정지, 삭제)

import { Email } from '../value-objects/email.vo';      // 이메일 Value Object
import { Password } from '../value-objects/password.vo'; // 비밀번호 Value Object  
import { UserId } from '../value-objects/user-id.vo';    // 사용자 ID Value Object
import { Gender } from '../auth/auth.types';             // 성별 열거형

/**
 * 사용자 도메인 엔티티
 * 
 * DDD의 Entity 패턴을 구현한 사용자 도메인 객체입니다.
 * 사용자의 생명주기 동안 변하지 않는 고유한 식별자(UserId)를 가지며,
 * 사용자와 관련된 모든 비즈니스 로직을 캡슐화합니다.
 * 
 * 특징:
 * - Immutable ID: 생성 후 변경되지 않는 고유 식별자
 * - Value Objects: 복잡한 값들을 타입 안전한 객체로 관리
 * - Business Rules: 도메인 규칙을 메서드로 구현
 * - Self-Validation: 객체 자체가 유효성을 검증
 * 
 * 상태 관리:
 * - active: 정상 활동 가능한 사용자
 * - inactive: 비활성화된 사용자 (일시적)
 * - suspended: 정지된 사용자 (관리자 조치)
 * - deleted: 삭제된 사용자 (소프트 삭제)
 */
export class User {
  // ============================================================================
  // 🔒 불변 속성들 (생성 후 변경 불가)
  // ============================================================================
  
  private readonly _id: UserId;           // 사용자 고유 식별자 (UUID)
  private readonly _email: Email;         // 이메일 주소 (로그인 ID)
  private readonly _password: Password;   // 해시된 비밀번호
  private readonly _birthDate: Date;      // 생년월일
  private readonly _gender?: Gender;      // 성별 (선택사항)
  private readonly _createdAt: Date;      // 계정 생성일시
  
  // ============================================================================
  // 📝 가변 속성들 (비즈니스 로직을 통해 변경 가능)
  // ============================================================================
  
  private _name: string;                  // 사용자 실명
  private _username?: string;             // 사용자명/아이디 (영문, 숫자, 언더스코어)
  private _nickname?: string;             // 별명/닉네임 (선택사항)
  private _profileImageUrl?: string;      // 프로필 이미지 URL (선택사항)
  
  // ============================================================================
  // ✅ 인증 관련 속성들
  // ============================================================================
  
  private _emailVerified: boolean;        // 이메일 인증 완료 여부
  private _emailVerifiedAt?: Date;        // 이메일 인증 완료 일시
  private _phoneNumber?: string;          // 전화번호 (선택사항)
  private _phoneVerified: boolean;        // 전화번호 인증 완료 여부
  
  // ============================================================================
  // 🎯 상태 및 메타데이터
  // ============================================================================
  
  private _status: 'active' | 'inactive' | 'suspended' | 'deleted'; // 사용자 상태
  private _userType: 'reader' | 'writer' | 'admin';  // 사용자 타입 (독자/작가/관리자)
  private _userCode?: string;             // 사용자 고유 코드 (RD0001, WR0001 형식)
  private _lastLoginAt?: Date;            // 마지막 로그인 일시
  private _updatedAt: Date;               // 마지막 수정일시

  /**
   * 사용자 엔티티 생성자
   * 
   * 직접 호출하기보다는 팩토리 메서드(create, fromPersistence)를 사용하는 것을 권장합니다.
   * 모든 필수 속성과 선택적 속성을 받아 사용자 객체를 초기화합니다.
   * 
   * @param params 사용자 초기화에 필요한 모든 속성들
   */
  constructor(params: {
    id: UserId;
    email: Email;
    password: Password;
    name: string;
    username?: string;
    nickname?: string;
    profileImageUrl?: string;
    emailVerified: boolean;
    emailVerifiedAt?: Date;
    phoneNumber?: string;
    phoneVerified: boolean;
    status: 'active' | 'inactive' | 'suspended' | 'deleted';
    userType: 'reader' | 'writer' | 'admin';
    userCode?: string;
    birthDate: Date;
    gender?: Gender;
    lastLoginAt?: Date;
    createdAt?: Date;
    updatedAt?: Date;
  }) {
    this._id = params.id;
    this._email = params.email;
    this._password = params.password;
    this._name = params.name;
    this._username = params.username;
    this._nickname = params.nickname;
    this._profileImageUrl = params.profileImageUrl;
    this._emailVerified = params.emailVerified;
    this._emailVerifiedAt = params.emailVerifiedAt;
    this._phoneNumber = params.phoneNumber;
    this._phoneVerified = params.phoneVerified;
    this._status = params.status;
    this._userType = params.userType;
    this._userCode = params.userCode;
    this._birthDate = params.birthDate;
    this._gender = params.gender;
    this._lastLoginAt = params.lastLoginAt;
    this._createdAt = params.createdAt || new Date();
    this._updatedAt = params.updatedAt || new Date();
  }

  /**
   * 새로운 사용자 생성 팩토리 메서드
   * 
   * 회원가입 시 사용되는 팩토리 메서드입니다.
   * 새로운 UserId를 생성하고 기본값들을 설정하여 사용자 객체를 생성합니다.
   * 
   * 기본 설정:
   * - ID: 새로운 UUID 생성
   * - 이메일 인증: false (인증 필요)
   * - 전화번호 인증: false
   * - 상태: 'active' (즉시 활성화)
   * - 생성/수정 시간: 현재 시간
   * 
   * @param params 회원가입에 필요한 기본 정보
   * @returns 새로 생성된 User 엔티티
   */
  static create(params: {
    email: Email;       // 로그인에 사용할 이메일 주소
    password: Password; // 해시된 비밀번호
    name: string;       // 사용자 실명
    username?: string;  // 사용자명 (아이디)
    userType: 'reader' | 'writer' | 'admin'; // 사용자 타입
    birthDate: Date;    // 생년월일
    gender?: Gender;    // 성별 (선택사항)
  }): User {
    return new User({
      id: UserId.generate(),
      email: params.email,
      password: params.password,
      name: params.name,
      username: params.username,
      emailVerified: false,
      phoneVerified: false,
      status: 'active',
      userType: params.userType,
      birthDate: params.birthDate,
      gender: params.gender
    });
  }

  /**
   * 데이터베이스 데이터로부터 사용자 엔티티 재구성 팩토리 메서드
   * 
   * 데이터베이스에서 조회한 raw 데이터를 도메인 객체로 변환합니다.
   * Value Object들을 적절히 복원하고 모든 속성을 올바르게 설정합니다.
   * 
   * 변환 과정:
   * - string id → UserId Value Object
   * - string email → Email Value Object  
   * - string passwordHash → Password Value Object
   * - 기타 원시 타입들을 적절한 속성으로 매핑
   * 
   * @param params 데이터베이스에서 조회한 사용자 데이터
   * @returns 완전히 복원된 User 엔티티
   */
  static fromPersistence(params: {
    id: string;
    email: string;
    passwordHash: string;
    name: string;
    username?: string;
    nickname?: string;
    profileImageUrl?: string;
    emailVerified: boolean;
    emailVerifiedAt?: Date;
    phoneNumber?: string;
    phoneVerified: boolean;
    status: 'active' | 'inactive' | 'suspended' | 'deleted';
    userType: 'reader' | 'writer' | 'admin';
    userCode?: string;
    birthDate: Date;
    gender?: Gender;
    lastLoginAt?: Date;
    createdAt: Date;
    updatedAt: Date;
  }): User {
    return new User({
      id: UserId.from(params.id),
      email: Email.create(params.email),
      password: Password.fromHash(params.passwordHash),
      name: params.name,
      username: params.username,
      nickname: params.nickname,
      profileImageUrl: params.profileImageUrl,
      emailVerified: params.emailVerified,
      emailVerifiedAt: params.emailVerifiedAt,
      phoneNumber: params.phoneNumber,
      phoneVerified: params.phoneVerified,
      status: params.status,
      userType: params.userType,
      userCode: params.userCode,
      birthDate: params.birthDate,
      gender: params.gender,
      lastLoginAt: params.lastLoginAt,
      createdAt: params.createdAt,
      updatedAt: params.updatedAt
    });
  }

  // ============================================================================
  // 📖 Getter 메서드들 (읽기 전용 접근)
  // ============================================================================
  
  /**
   * 사용자 고유 식별자 반환
   * 
   * @returns UserId Value Object
   */
  get id(): UserId {
    return this._id;
  }

  /**
   * 사용자 이메일 주소 반환
   * 
   * @returns Email Value Object
   */
  get email(): Email {
    return this._email;
  }

  /**
   * 사용자 비밀번호 객체 반환 (해시된 상태)
   * 
   * @returns Password Value Object
   */
  get password(): Password {
    return this._password;
  }

  /**
   * 사용자 실명 반환
   * 
   * @returns 사용자 이름 문자열
   */
  get name(): string {
    return this._name;
  }

  /**
   * 이메일 인증 완료 여부 반환
   * 
   * @returns true: 인증완료, false: 미인증
   */
  get emailVerified(): boolean {
    return this._emailVerified;
  }

  /**
   * 사용자 생년월일 반환
   * 
   * @returns 생년월일 Date 객체
   */
  get birthDate(): Date {
    return this._birthDate;
  }

  /**
   * 사용자 성별 반환
   * 
   * @returns 성별 또는 undefined (선택사항)
   */
  get gender(): Gender | undefined {
    return this._gender;
  }

  /**
   * 계정 생성일시 반환
   * 
   * @returns 생성일시 Date 객체
   */
  get createdAt(): Date {
    return this._createdAt;
  }

  /**
   * 마지막 수정일시 반환
   * 
   * @returns 수정일시 Date 객체
   */
  get updatedAt(): Date {
    return this._updatedAt;
  }

  get username(): string | undefined {
    return this._username;
  }

  get nickname(): string | undefined {
    return this._nickname;
  }

  get profileImageUrl(): string | undefined {
    return this._profileImageUrl;
  }

  get emailVerifiedAt(): Date | undefined {
    return this._emailVerifiedAt;
  }

  get phoneNumber(): string | undefined {
    return this._phoneNumber;
  }

  get phoneVerified(): boolean {
    return this._phoneVerified;
  }

  get status(): 'active' | 'inactive' | 'suspended' | 'deleted' {
    return this._status;
  }

  get lastLoginAt(): Date | undefined {
    return this._lastLoginAt;
  }

  get userType(): 'reader' | 'writer' | 'admin' {
    return this._userType;
  }

  get userCode(): string | undefined {
    return this._userCode;
  }

  // ============================================================================
  // 🧮 계산 메서드들 (비즈니스 로직)
  // ============================================================================
  
  /**
   * 현재 나이 계산
   * 
   * 생년월일을 기준으로 만 나이를 계산합니다.
   * 생일이 지나지 않았다면 한 살을 빼서 정확한 만 나이를 반환합니다.
   * 
   * 계산 방식:
   * 1. 현재 연도에서 출생 연도를 뺌
   * 2. 생일이 아직 지나지 않았다면 1을 빼서 만 나이 계산
   * 
   * @returns 만 나이 (정수)
   */
  getAge(): number {
    const today = new Date();
    const birthDate = new Date(this._birthDate);
    let age = today.getFullYear() - birthDate.getFullYear();
    
    // 생일이 아직 지나지 않은 경우 나이에서 1을 뺌
    const monthDiff = today.getMonth() - birthDate.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
      age--;
    }
    
    return age;
  }

  // ============================================================================
  // 🔐 인증 관련 메서드들
  // ============================================================================
  
  /**
   * 이메일 인증 완료 처리
   * 
   * 사용자가 이메일 인증 링크를 클릭했을 때 호출됩니다.
   * 인증 상태를 true로 변경하고 인증 완료 시간을 기록합니다.
   * 
   * 비즈니스 규칙:
   * - 이미 인증된 이메일이라도 재인증 허용
   * - 인증 시간 갱신으로 최신 인증 시점 추적
   * - 수정 시간 자동 업데이트
   */
  verifyEmail(): void {
    this._emailVerified = true;
    this._emailVerifiedAt = new Date();
    this._updatedAt = new Date();
  }

  /**
   * 마지막 로그인 시간 업데이트
   * 
   * 사용자가 성공적으로 로그인했을 때 호출됩니다.
   * 로그인 패턴 분석, 보안 모니터링, 사용자 활동 추적에 사용됩니다.
   * 
   * 사용 사례:
   * - 장기간 미접속 사용자 식별
   * - 로그인 패턴 분석
   * - 보안 이벤트 탐지
   * - 사용자 활성도 측정
   */
  updateLastLogin(): void {
    this._lastLoginAt = new Date();
    this._updatedAt = new Date();
  }

  // ============================================================================
  // 👤 프로필 관리 메서드들
  // ============================================================================
  
  /**
   * 프로필 이미지 URL 변경
   * 
   * 사용자의 프로필 이미지를 변경합니다.
   * null 또는 빈 문자열을 전달하면 프로필 이미지를 제거합니다.
   * 
   * 보안 고려사항:
   * - URL 유효성은 상위 계층에서 검증해야 함
   * - 이미지 파일 존재 여부는 별도 검증 필요
   * - CDN URL 또는 안전한 스토리지 URL만 허용 권장
   * 
   * @param imageUrl 새로운 프로필 이미지 URL (null이면 제거)
   */
  updateProfileImage(imageUrl: string | null): void {
    this._profileImageUrl = imageUrl || undefined;
    this._updatedAt = new Date();
  }

  /**
   * 닉네임 변경
   * 
   * 사용자의 별명/닉네임을 변경합니다.
   * null 또는 빈 문자열을 전달하면 닉네임을 제거합니다.
   * 
   * 비즈니스 규칙:
   * - 닉네임은 2자 이상이어야 함
   * - 앞뒤 공백은 자동으로 제거
   * - null/빈값은 닉네임 제거로 처리
   * 
   * @param nickname 새로운 닉네임 (null이면 제거)
   * @throws Error 닉네임이 2자 미만인 경우
   */
  updateNickname(nickname: string | null): void {
    // 닉네임이 제공되었지만 너무 짧은 경우 에러
    if (nickname && nickname.trim().length < 2) {
      throw new Error('닉네임은 2자 이상이어야 합니다');
    }
    
    // 공백 제거 후 설정, 빈값이면 undefined로 처리
    this._nickname = nickname?.trim() || undefined;
    this._updatedAt = new Date();
  }

  // ============================================================================
  // 🎯 계정 상태 관리 메서드들
  // ============================================================================
  
  /**
   * 사용자 계정 상태 변경
   * 
   * 관리자 권한 또는 시스템 정책에 의해 사용자 상태를 변경합니다.
   * 
   * 상태별 의미:
   * - active: 정상 활동 가능한 상태
   * - inactive: 일시적으로 비활성화된 상태 (사용자 요청)
   * - suspended: 관리자에 의해 정지된 상태 (위반 행위 등)
   * - deleted: 삭제된 상태 (소프트 삭제, 복구 가능)
   * 
   * 주의사항:
   * - 상태 변경 시 적절한 권한 검증이 선행되어야 함
   * - 상태 변경 이력을 별도로 기록하는 것을 권장
   * 
   * @param status 새로운 계정 상태
   */
  updateStatus(status: 'active' | 'inactive' | 'suspended' | 'deleted'): void {
    this._status = status;
    this._updatedAt = new Date();
  }

  /**
   * 사용자 실명 변경
   * 
   * 사용자의 실명을 변경합니다. 실명은 필수 항목이므로 null이나 빈값을 허용하지 않습니다.
   * 
   * 비즈니스 규칙:
   * - 이름은 필수 항목 (null, undefined, 빈 문자열 불허)
   * - 최소 2자 이상이어야 함
   * - 앞뒤 공백은 자동으로 제거
   * 
   * 보안 고려사항:
   * - 실명 변경은 신중해야 하므로 별도 인증 절차 권장
   * - 변경 이력을 기록하여 추적 가능하도록 구현 권장
   * 
   * @param newName 새로운 실명 (2자 이상)
   * @throws Error 이름이 비어있거나 2자 미만인 경우
   */
  changeName(newName: string): void {
    // 이름이 비어있거나 공백만 있는 경우
    if (!newName || newName.trim().length < 2) {
      throw new Error('이름은 2자 이상이어야 합니다');
    }
    
    this._name = newName.trim();
    this._updatedAt = new Date();
  }

  // ============================================================================
  // 💾 영속성 지원 메서드들
  // ============================================================================
  
  /**
   * 데이터베이스 저장을 위한 일반 객체로 변환
   * 
   * 도메인 엔티티를 데이터베이스 테이블 구조에 맞는 일반 객체로 변환합니다.
   * Value Object들은 원시 값으로 추출하고, 필드명은 데이터베이스 컨벤션(snake_case)에 맞춥니다.
   * 
   * 변환 과정:
   * - UserId → string (UUID)
   * - Email → string (이메일 주소)
   * - Password → string (해시된 비밀번호)
   * - camelCase → snake_case 필드명 변환
   * 
   * 주의사항:
   * - 이 메서드는 Repository 계층에서만 사용해야 함
   * - 반환된 객체는 도메인 객체가 아닌 순수 데이터
   * - 비밀번호는 이미 해시된 상태로 반환
   * 
   * @returns 데이터베이스 저장용 일반 객체
   */
  toPersistence() {
    return {
      id: this._id.getValue(),                    // UUID 문자열
      email: this._email.getValue(),              // 이메일 주소 문자열
      password_hash: this._password.getHashedValue(), // 해시된 비밀번호
      name: this._name,                           // 사용자 실명
      username: this._username,                   // 사용자명 (아이디)
      nickname: this._nickname,                   // 닉네임 (선택사항)
      profile_image_url: this._profileImageUrl,   // 프로필 이미지 URL (선택사항)
      email_verified: this._emailVerified,        // 이메일 인증 여부
      phone_number: this._phoneNumber,            // 전화번호 (선택사항)
      phone_verified: this._phoneVerified,        // 전화번호 인증 여부
      status: this._status,                       // 계정 상태
      user_type: this._userType,                  // 사용자 타입
      user_code: this._userCode,                  // 사용자 코드
      birth_date: this._birthDate,                // 생년월일
      gender: this._gender,                       // 성별 (선택사항)
      last_login_at: this._lastLoginAt,           // 마지막 로그인 시간 (선택사항)
      created_at: this._createdAt,                // 생성일시
      updated_at: this._updatedAt,                // 수정일시
    };
  }
}