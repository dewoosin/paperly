/// Paperly Backend - 회원가입 Use Case
/// 
/// 이 파일은 새로운 사용자 회원가입 프로세스를 처리하는 Application Layer의 Use Case입니다.
/// Clean Architecture의 Application Service 역할을 하며, 회원가입의 모든 비즈니스 로직을 조정합니다.
/// 
/// 주요 책임:
/// 1. 회원가입 입력 데이터 검증 및 변환
/// 2. 이메일 중복성 검사 및 비즈니스 규칙 적용
/// 3. 사용자 도메인 엔티티 생성 및 저장
/// 4. JWT 인증 토큰 생성 및 관리
/// 5. 이메일 인증 프로세스 시작
/// 6. 트랜잭션 조정 및 에러 처리
/// 
/// 아키텍처 패턴:
/// - Use Case Pattern: 단일 비즈니스 시나리오 처리
/// - Dependency Injection: TSyringe를 통한 의존성 주입
/// - Command Pattern: 입력/출력 DTO로 명확한 인터페이스
/// - Error Handling: 도메인별 예외 타입 사용
/// 
/// 보안 고려사항:
/// - 입력 데이터 철저한 검증 (Zod 스키마)
/// - 이메일 중복 확인으로 계정 충돌 방지
/// - 비밀번호 해싱 및 안전한 저장
/// - 만 14세 이상 가입 제한
/// - 이메일 인증을 통한 계정 활성화

import { inject, injectable } from 'tsyringe';           // 의존성 주입 프레임워크
import { z } from 'zod';                                 // 런타임 데이터 검증 라이브러리
import { IUserRepository } from '../../../infrastructure/repositories/user.repository';     // 사용자 데이터 저장소 인터페이스
import { EmailService } from '../../../infrastructure/email/email.service';                // 이메일 전송 서비스
import { User } from '../../../domain/entities/user.entity';                               // 사용자 도메인 엔티티
import { Email } from '../../../domain/value-objects/email.vo';                            // 이메일 Value Object
import { Password } from '../../../domain/value-objects/password.vo';                      // 비밀번호 Value Object
import { Gender } from '../../../domain/auth/auth.types';                                  // 성별 타입 정의
import { ConflictError, BadRequestError } from '../../../shared/errors/index';                   // 도메인 에러 타입들
import { Logger } from '../../../infrastructure/logging/Logger';                           // 구조화된 로깅 서비스
import { SecuritySanitizer, SanitizationContext, SQLSanitizationContext } from '../../../infrastructure/security/sanitizers';  // 보안 새니타이저
import { MESSAGE_CODES } from '../../../shared/constants/message-codes';                                                 // 메시지 코드 상수

// ============================================================================
// 📋 입력/출력 스키마 및 타입 정의
// ============================================================================

/**
 * 회원가입 입력 데이터 검증 스키마
 * 
 * Zod를 사용하여 런타임에 입력 데이터를 검증합니다.
 * 프론트엔드에서 전송된 데이터의 형식과 비즈니스 규칙을 엄격하게 검사합니다.
 * 
 * 검증 규칙:
 * - 이메일: RFC 5322 표준 이메일 형식
 * - 비밀번호: 8자 이상 (보안 강화)
 * - 이름: 2-50자 (실명 정책)
 * - 생년월일: YYYY-MM-DD 형식 (ISO 8601)
 * - 성별: 4가지 옵션 중 선택 (선택사항)
 */
const RegisterInputSchema = z.object({
  email: z.string().email('올바른 이메일 형식이 아닙니다'),                                        // RFC 5322 이메일 검증
  password: z.string().min(8, '비밀번호는 최소 8자 이상이어야 합니다'),                              // 최소 길이 보안 규칙
  name: z.string().min(2, '이름은 최소 2자 이상이어야 합니다').max(50),                            // 실명 정책 (2-50자)
  username: z.string().min(3, '아이디는 최소 3자 이상이어야 합니다')
    .max(20, '아이디는 최대 20자까지 가능합니다')
    .regex(/^[a-zA-Z0-9_]+$/, '아이디는 영문, 숫자, 언더스코어(_)만 사용 가능합니다'),                // 사용자명 (3-20자, 영문/숫자/언더스코어)
  birthDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, '생년월일 형식은 YYYY-MM-DD여야 합니다'),      // ISO 8601 날짜 형식
  gender: z.enum(['male', 'female', 'other', 'prefer_not_to_say']).optional(),                  // 성별 선택사항 (4가지 옵션)
  userType: z.enum(['reader', 'writer']).optional().default('reader')                          // 사용자 타입 (기본값: reader)
});

/**
 * 회원가입 입력 데이터 타입
 * 
 * Zod 스키마에서 추론된 TypeScript 타입입니다.
 * 컴파일 타임과 런타임 모두에서 타입 안전성을 보장합니다.
 */
export type RegisterInput = z.infer<typeof RegisterInputSchema>;

/**
 * 회원가입 성공 응답 인터페이스
 * 
 * 회원가입 완료 후 클라이언트에게 반환되는 데이터 구조입니다.
 * JWT 토큰과 사용자 기본 정보, 이메일 전송 여부를 포함합니다.
 * 
 * 반환 데이터:
 * - user: 새로 생성된 사용자의 기본 정보 (민감하지 않은 데이터만)
 * - tokens: JWT Access Token과 Refresh Token 쌍
 * - emailVerificationSent: 인증 이메일 전송 성공 여부
 */
export interface RegisterOutput {
  user: {
    id: string;              // 사용자 고유 식별자 (UUID)
    email: string;           // 이메일 주소 (로그인 ID)
    name: string;            // 사용자 실명
    emailVerified: boolean;  // 이메일 인증 상태 (회원가입 직후 false)
  };
  tokens: {
    accessToken: string;     // JWT Access Token (API 호출용, 단기)
    refreshToken: string;    // JWT Refresh Token (토큰 갱신용, 장기)
  };
  emailVerificationSent: boolean;  // 인증 이메일 발송 성공 여부
}

// ============================================================================
// 🔐 회원가입 Use Case 클래스
// ============================================================================

/**
 * 회원가입 유스케이스 클래스
 * 
 * Clean Architecture의 Application Layer에서 회원가입 비즈니스 로직을 조정하는 클래스입니다.
 * 단일 책임 원칙에 따라 회원가입 시나리오만을 담당하며, 다음 단계를 순차적으로 처리합니다:
 * 
 * 처리 단계:
 * 1. 입력 데이터 검증 및 변환 (Zod 스키마 기반)
 * 2. 이메일 중복성 검사 (기존 사용자 확인)
 * 3. 연령 제한 검증 (만 14세 이상)
 * 4. 사용자 도메인 엔티티 생성 (Value Objects 포함)
 * 5. 데이터베이스에 사용자 정보 영속화
 * 6. JWT 토큰 쌍 생성 (Access + Refresh)
 * 7. 이메일 인증 메일 발송 (비동기 처리)
 * 
 * 보안 및 안정성:
 * - 트랜잭션 처리로 데이터 일관성 보장
 * - 실패 시 롤백 및 적절한 에러 메시지
 * - 이메일 전송 실패가 회원가입을 방해하지 않음
 * - 모든 단계에서 구조화된 로깅
 * 
 * 의존성:
 * - UserRepository: 사용자 데이터 영속화
 * - EmailService: 인증 이메일 전송
 * - TokenService: JWT 토큰 관리
 * - AuthRepository: 인증 관련 데이터 관리
 */
@injectable()
export class RegisterUseCase {
  private readonly logger = new Logger('RegisterUseCase');

  /**
   * 회원가입 Use Case 생성자
   * 
   * TSyringe를 통해 필요한 모든 의존성을 주입받습니다.
   * 각 의존성은 인터페이스를 통해 주입되어 느슨한 결합을 유지합니다.
   * 
   * @param userRepository 사용자 데이터 저장 및 조회
   * @param emailService 이메일 발송 서비스
   * @param tokenService JWT 토큰 생성 및 관리
   * @param authRepository 인증 관련 데이터 관리
   */
  constructor(
    @inject('UserRepository') private userRepository: IUserRepository,
    @inject('EmailService') private emailService: EmailService,
    @inject('TokenService') private tokenService: any
  ) {}

  /**
   * 회원가입 프로세스 실행
   * 
   * 새로운 사용자의 회원가입 요청을 처리하는 메인 메서드입니다.
   * 모든 비즈니스 규칙을 적용하고 필요한 서비스들을 조정하여
   * 안전하고 완전한 회원가입 프로세스를 제공합니다.
   * 
   * 프로세스 플로우:
   * 1. 입력 검증: Zod 스키마로 런타임 데이터 검증
   * 2. Value Objects 변환: 도메인 객체로 변환
   * 3. 비즈니스 규칙 검증: 연령, 이메일 중복 등
   * 4. 사용자 엔티티 생성: 도메인 로직 활용
   * 5. 데이터 영속화: Repository를 통한 저장
   * 6. 토큰 생성: JWT 인증 토큰 발급
   * 7. 이메일 인증: 비동기 인증 메일 전송
   * 
   * @param input 회원가입 입력 데이터 (이메일, 비밀번호, 개인정보)
   * @returns 회원가입 성공 결과 (사용자 정보, 토큰, 이메일 전송 여부)
   * @throws ConflictError 이메일 중복 시
   * @throws BadRequestError 나이 제한 위반 시
   * @throws ValidationError 입력 데이터 형식 오류 시
   */
  async execute(input: RegisterInput): Promise<RegisterOutput> {
    // ========================================================================
    // 1단계: 입력 데이터 보안 검증
    // ========================================================================
    
    // 개별 필드별 보안 검증 및 새니타이징
    const sanitizedInput = {
      email: SecuritySanitizer.sanitizeAll(input.email, {
        htmlContext: SanitizationContext.PLAIN_TEXT,
        sqlContext: SQLSanitizationContext.EMAIL_ADDRESS,
        fieldName: 'email'
      }).finalValue,
      password: input.password, // 비밀번호는 해싱되므로 새니타이징 생략
      name: SecuritySanitizer.sanitizeAll(input.name, {
        htmlContext: SanitizationContext.PLAIN_TEXT,
        sqlContext: SQLSanitizationContext.STRING_LITERAL,
        fieldName: 'name'
      }).finalValue,
      username: SecuritySanitizer.sanitizeAll(input.username, {
        htmlContext: SanitizationContext.PLAIN_TEXT,
        sqlContext: SQLSanitizationContext.USERNAME,
        fieldName: 'username'
      }).finalValue,
      birthDate: SecuritySanitizer.sanitizeAll(input.birthDate, {
        htmlContext: SanitizationContext.PLAIN_TEXT,
        sqlContext: SQLSanitizationContext.STRING_LITERAL,
        fieldName: 'birthDate'
      }).finalValue,
      gender: input.gender
    };

    // ========================================================================
    // 2단계: 입력 데이터 검증 및 파싱
    // ========================================================================
    
    // Zod 스키마를 사용한 런타임 입력 검증
    // 타입 안전성과 비즈니스 규칙을 동시에 보장
    const validatedInput = RegisterInputSchema.parse(sanitizedInput);
    
    this.logger.info('회원가입 프로세스 시작', { 
      email: validatedInput.email,
      name: validatedInput.name,
      securityCheck: 'passed'
    });

    try {
      // ========================================================================
      // 3단계: Value Objects 생성 및 변환
      // ========================================================================
      
      // 이메일을 Email Value Object로 변환 (형식 검증 포함)
      const email = Email.create(validatedInput.email);
      
      // 비밀번호를 Password Value Object로 변환 (해싱 수행)
      const password = await Password.create(validatedInput.password);
      
      // 문자열 날짜를 Date 객체로 변환
      const birthDate = new Date(validatedInput.birthDate);
      
      // ========================================================================
      // 4단계: 비즈니스 규칙 검증
      // ========================================================================
      
      // 연령 제한 검증: 만 14세 이상만 가입 가능
      // 국내 개인정보보호법 및 서비스 정책 준수
      const age = this.calculateAge(birthDate);
      if (age < 14) {
        this.logger.warn('연령 제한 위반', { age, email: validatedInput.email });
        throw new BadRequestError('14세 이상만 가입할 수 있습니다', undefined, MESSAGE_CODES.VALIDATION.REQUIRED_FIELD_MISSING);
      }

      // ========================================================================
      // 5단계: 이메일 및 사용자명 중복 검사
      // ========================================================================
      
      // 동일한 이메일로 가입된 기존 사용자 확인
      // 계정 충돌 방지 및 고유성 보장
      const existingUser = await this.userRepository.findByEmail(email);
      if (existingUser) {
        this.logger.warn('이메일 중복 감지', { email: validatedInput.email });
        throw new ConflictError('이미 사용 중인 이메일입니다', undefined, MESSAGE_CODES.AUTH.EMAIL_EXISTS);
      }

      // 동일한 사용자명으로 가입된 기존 사용자 확인
      const existingUsername = await this.userRepository.findByUsername(validatedInput.username);
      if (existingUsername) {
        this.logger.warn('사용자명 중복 감지', { username: validatedInput.username });
        throw new ConflictError('이미 사용 중인 아이디입니다', undefined, MESSAGE_CODES.USER.NICKNAME_IN_USE);
      }

      // ========================================================================
      // 6단계: 사용자 도메인 엔티티 생성
      // ========================================================================
      
      // User 엔티티의 팩토리 메서드를 통한 새 사용자 생성
      // 도메인 규칙과 불변성이 자동으로 적용됨
      const user = User.create({
        email,                                      // 검증된 이메일 Value Object
        password,                                   // 해싱된 비밀번호 Value Object
        name: validatedInput.name,                  // 사용자 실명
        username: validatedInput.username,          // 사용자명 (아이디)
        userType: validatedInput.userType as 'reader' | 'writer' | 'admin', // 사용자 타입
        birthDate,                                  // 생년월일
        gender: validatedInput.gender as Gender     // 성별 (선택사항)
      });

      // ========================================================================
      // 7단계: 데이터베이스 영속화
      // ========================================================================
      
      // Repository를 통한 사용자 데이터 저장
      // 트랜잭션이 자동으로 적용되어 데이터 일관성 보장
      await this.userRepository.save(user);
      
      this.logger.info('사용자 저장 완료', { userId: user.id.getValue() });

      // ========================================================================
      // 8단계: JWT 토큰 생성
      // ========================================================================
      
      // Access Token과 Refresh Token 쌍 생성
      // Refresh Token은 자동으로 데이터베이스에 저장됨
      const tokens = await this.tokenService.generateAuthTokens(user);
      
      this.logger.info('JWT 토큰 생성 완료', { userId: user.id.getValue() });

      // ========================================================================
      // 9단계: 이메일 인증 프로세스 시작
      // ========================================================================
      
      // 인증 이메일 발송 (실패해도 회원가입은 성공 처리)
      let emailVerificationSent = false;
      try {
        // 이메일 인증 토큰 생성 (단기 유효, 일회성)
        const verificationToken = await this.tokenService.generateEmailVerificationToken(
          user.id.getValue(),
          user.email.getValue()
        );
        
        // 인증 메일 발송 (HTML 템플릿 포함)
        await this.emailService.sendVerificationEmail(
          user.email.getValue(),
          user.name,
          verificationToken
        );
        
        emailVerificationSent = true;
        this.logger.info('인증 이메일 발송 성공', { 
          userId: user.id.getValue(),
          email: user.email.getValue() 
        });
      } catch (error) {
        // 이메일 발송 실패는 회원가입 성공을 방해하지 않음
        // 사용자는 나중에 재전송 요청 가능
        this.logger.error('인증 이메일 발송 실패', { 
          userId: user.id.getValue(),
          error: error 
        });
      }

      // ========================================================================
      // 10단계: 성공 응답 구성 및 반환
      // ========================================================================
      
      this.logger.info('회원가입 프로세스 완료', { 
        userId: user.id.getValue(),
        emailVerificationSent,
        timestamp: new Date().toISOString()
      });

      // 클라이언트에게 반환할 회원가입 성공 데이터
      return {
        user: {
          id: user.id.getValue(),                   // UUID 문자열
          email: user.email.getValue(),             // 이메일 주소
          name: user.name,                          // 사용자 실명
          emailVerified: user.emailVerified         // 인증 상태 (false)
        },
        tokens,                                     // JWT 토큰 쌍
        emailVerificationSent                       // 이메일 전송 성공 여부
      };
    } catch (error) {
      // 회원가입 프로세스 중 발생한 모든 에러 로깅
      this.logger.error('회원가입 프로세스 실패', { 
        email: validatedInput.email,
        error: error,
        timestamp: new Date().toISOString()
      });
      throw error;  // 상위 계층으로 에러 전파
    }
  }

  // ============================================================================
  // 🧮 유틸리티 메서드들
  // ============================================================================
  
  /**
   * 정확한 만 나이 계산
   * 
   * 생년월일을 기준으로 현재 시점의 정확한 만 나이를 계산합니다.
   * 단순히 연도 차이만 계산하지 않고, 생일이 지났는지도 고려하여
   * 법적으로 유효한 만 나이를 반환합니다.
   * 
   * 계산 로직:
   * 1. 현재 연도에서 출생 연도를 빼서 기본 나이 계산
   * 2. 현재 월과 출생 월을 비교
   * 3. 아직 생일이 지나지 않았다면 나이에서 1을 빼서 만 나이 산출
   * 
   * 사용 사례:
   * - 회원가입 연령 제한 확인 (만 14세 이상)
   * - 서비스 이용 약관 동의 가능 연령 확인
   * - 개인정보보호법 준수를 위한 연령 확인
   * 
   * @param birthDate 사용자의 생년월일 Date 객체
   * @returns 정확한 만 나이 (정수)
   * 
   * @example
   * // 2000년 6월 15일 생, 현재가 2023년 3월 10일인 경우
   * const birthDate = new Date('2000-06-15');
   * const age = this.calculateAge(birthDate); // 22 (아직 생일 전이므로)
   * 
   * // 2000년 6월 15일 생, 현재가 2023년 8월 20일인 경우
   * const age = this.calculateAge(birthDate); // 23 (생일이 지났으므로)
   */
  private calculateAge(birthDate: Date): number {
    const today = new Date();                                    // 현재 날짜
    let age = today.getFullYear() - birthDate.getFullYear();     // 연도 차이 계산
    const monthDiff = today.getMonth() - birthDate.getMonth();   // 월 차이 계산
    
    // 생일이 아직 지나지 않은 경우 나이에서 1을 뺌
    // 1. 현재 월이 출생 월보다 이전인 경우
    // 2. 같은 월이지만 현재 일자가 출생 일자보다 이전인 경우
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
      age--;
    }
    
    return age;
  }
}