/// Paperly Backend - 인증 관련 API 컨트롤러
/// 
/// 이 파일은 사용자 인증과 관련된 모든 HTTP API 엔드포인트를 처리합니다.
/// Clean Architecture의 Controller 레이어로, HTTP 요청을 도메인 Use Case로 매핑합니다.
/// 
/// 아키텍처 패턴:
/// - Presentation Layer: HTTP 요청/응답 처리
/// - Dependency Injection: TSyringe로 Use Case 주입
/// - Error Handling: Express 미들웨어로 에러 위임
/// - Logging: 구조화된 로깅으로 모니터링 지원
/// 
/// 지원 API 엔드포인트:
/// - POST /auth/register - 새로운 사용자 회원가입
/// - POST /auth/login - 이메일/비밀번호 로그인
/// - POST /auth/refresh - JWT 토큰 갱신
/// - POST /auth/logout - 로그아웃 및 토큰 무효화
/// - GET /auth/verify-email - 이메일 인증 링크 처리
/// - POST /auth/resend-verification - 인증 이메일 재전송
/// - POST /auth/skip-verification - 이메일 인증 스킵 (개발용)
/// 
/// 보안 고려사항:
/// - JWT 토큰 기반 인증
/// - Device ID 추적으로 다중 기기 로그인 지원
/// - Rate Limiting으로 브루트포스 공격 방지
/// - IP 및 User-Agent 로깅으로 보안 모니터링

import { Router, Request, Response, NextFunction } from 'express'; // Express 타입 정의
import { inject, injectable, container } from 'tsyringe';           // 의존성 주입
import { RegisterUseCase } from '../../../application/use-cases/auth/register.use-case';      // 회원가입 Use Case
import { LoginUseCase } from '../../../application/use-cases/auth/login.use-case';          // 로그인 Use Case
import { VerifyEmailUseCase, ResendVerificationUseCase } from '../../../application/use-cases/auth/verify-email.use-case'; // 이메일 인증 Use Cases
import { RefreshTokenUseCase, LogoutUseCase } from '../../../application/use-cases/auth/refresh-token.use-case'; // 토큰 관리 Use Cases
import { Logger } from '../../logging/Logger';                    // 구조화된 로깅
import { IUserRepository } from '../../repositories/user.repository'; // 사용자 레포지토리

/**
 * 인증 관련 REST API 컨트롤러
 * 
 * Clean Architecture의 Presentation Layer를 구현하는 HTTP 컨트롤러입니다.
 * Express Router를 사용하여 RESTful API를 제공하고, 
 * Use Case 계층에 비즈니스 로직을 위임합니다.
 * 
 * 책임:
 * 1. HTTP 요청 매개변수 추출 및 검증
 * 2. Use Case 실행 및 결과 처리
 * 3. HTTP 응답 형식 정규화
 * 4. 에러 처리 및 로깅
 * 5. 보안 정보 (디바이스 ID, IP 등) 추출
 * 
 * API 엔드포인트:
 * - POST /register - 새 사용자 회원가입
 * - POST /login - 사용자 로그인
 * - POST /refresh - JWT 토큰 갱신
 * - POST /logout - 로그아웃
 * - GET /verify-email - 이메일 인증
 * - POST /resend-verification - 인증 메일 재발송
 * - POST /skip-verification - 인증 스킵 (개발용)
 */
@injectable()
export class AuthController {
  // ============================================================================
  // 🌍 Express Router 및 서비스 인스턴스
  // ============================================================================
  
  public readonly router: Router;                     // Express 라우터 인스턴스
  private readonly logger = new Logger('AuthController'); // 인증 컨트롤러 전용 로거

  /**
   * 인증 컨트롤러 생성자
   * 
   * TSyringe 의존성 주입을 통해 모든 Use Case를 주입받고,
   * Express Router를 초기화하여 모든 라우트를 설정합니다.
   * 
   * @param registerUseCase 회원가입 비즈니스 로직
   * @param loginUseCase 로그인 비즈니스 로직
   * @param verifyEmailUseCase 이메일 인증 비즈니스 로직
   * @param resendVerificationUseCase 인증 메일 재전송 비즈니스 로직
   * @param refreshTokenUseCase 토큰 갱신 비즈니스 로직
   * @param logoutUseCase 로그아웃 비즈니스 로직
   */
  constructor(
    @inject(RegisterUseCase) private registerUseCase: RegisterUseCase,
    @inject(LoginUseCase) private loginUseCase: LoginUseCase,
    @inject(VerifyEmailUseCase) private verifyEmailUseCase: VerifyEmailUseCase,
    @inject(ResendVerificationUseCase) private resendVerificationUseCase: ResendVerificationUseCase,
    @inject(RefreshTokenUseCase) private refreshTokenUseCase: RefreshTokenUseCase,
    @inject(LogoutUseCase) private logoutUseCase: LogoutUseCase,
    @inject('UserRepository') private userRepository: IUserRepository
  ) {
    this.router = Router();
    this.setupRoutes();
  }

  /**
   * Express 라우트 설정
   * 
   * 모든 인증 관련 API 엔드포인트를 등록하고 적절한 핸들러에 바인딩합니다.
   * bind(this)를 사용하여 메서드의 this 컨텍스트를 보장합니다.
   * 
   * 개발 환경에서만 skip-verification 엔드포인트를 제공하여 보안을 강화합니다.
   */
  private setupRoutes() {
    // ============================================================================
    // 회원가입 및 로그인 엔드포인트
    // ============================================================================
    
    this.router.post('/register', this.register.bind(this));     // 새 사용자 회원가입
    this.router.post('/login', this.login.bind(this));           // 이메일/비밀번호 로그인
    this.router.get('/check-username/:username', this.checkUsername.bind(this)); // 사용자명 중복 확인
    
    // ============================================================================
    // 토큰 관리 엔드포인트
    // ============================================================================
    
    this.router.post('/refresh', this.refreshToken.bind(this));  // JWT 토큰 갱신
    this.router.post('/logout', this.logout.bind(this));         // 로그아웃 및 토큰 무효화
    
    // ============================================================================
    // 이메일 인증 엔드포인트
    // ============================================================================
    
    this.router.get('/verify-email', this.verifyEmail.bind(this));           // 이메일 인증 링크 처리
    this.router.post('/resend-verification', this.resendVerification.bind(this)); // 인증 메일 재전송
    
    // ============================================================================
    // 개발 전용 엔드포인트 (프로덕션에서 비활성화)
    // ============================================================================
    
    // 이메일 인증 스킵 기능은 개발 환경에서만 사용 가능
    // 프로덕션에서는 보안상 이유로 비활성화
    if (process.env.NODE_ENV !== 'production') {
      this.router.post('/skip-verification', this.skipVerification.bind(this));
    }
  }

  // ============================================================================
  // 📝 회원가입 API 핸들러
  // ============================================================================
  
  /**
   * 새로운 사용자 회원가입 처리
   * 
   * 사용자의 기본 정보를 받아 새로운 계정을 생성합니다.
   * 성공 시 JWT 토큰을 발급하고 이메일 인증 메일을 전송합니다.
   * 
   * HTTP Method: POST
   * Endpoint: /auth/register
   * 
   * Request Body:
   * @param email 사용자 이메일 주소 (로그인 ID)
   * @param password 비밀번호 (평문, 8자 이상 권장)
   * @param name 사용자 실명
   * @param birthDate 생년월일 (YYYY-MM-DD 형식)
   * @param gender 성별 (선택사항: 'male', 'female', 'other', 'prefer_not_to_say')
   * 
   * Response:
   * - 201: 회원가입 성공 + 사용자 정보 + JWT 토큰
   * - 400: 유효성 검사 실패 (중복 이메일, 잘못된 형식 등)
   * - 500: 서버 내부 오류
   */
  private async register(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await this.registerUseCase.execute(req.body);

      res.status(201).json({
        success: true,
        data: {
          user: result.user,
          tokens: result.tokens,
          emailVerificationSent: result.emailVerificationSent
        },
        message: result.emailVerificationSent 
          ? '회원가입이 완료되었습니다. 이메일을 확인해주세요.'
          : '회원가입이 완료되었습니다.'
      });
    } catch (error) {
      next(error);
    }
  }

  // ============================================================================
  // 🔑 로그인 API 핸들러
  // ============================================================================
  
  /**
   * 사용자 로그인 인증 처리
   * 
   * 이메일과 비밀번호로 사용자를 인증하고 JWT 토큰을 발급합니다.
   * 디바이스 정보를 추출하여 다중 기기 로그인을 지원하고 보안 모니터링을 수행합니다.
   * 
   * HTTP Method: POST
   * Endpoint: /auth/login
   * 
   * Request Body:
   * @param email 로그인 이메일 주소
   * @param password 비밀번호
   * 
   * Request Headers:
   * @param X-Device-Id 디바이스 고유 식별자 (선택사항, 분석용)
   * @param User-Agent 브라우저/앱 정보 (보안 모니터링용)
   * 
   * Response:
   * - 200: 로그인 성공 + 사용자 정보 + JWT 토큰
   * - 401: 인증 실패 (잘못된 이메일/비밀번호)
   * - 403: 계정 상태 이슈 (정지, 비활성화 등)
   * - 429: 로그인 시도 횟수 초과
   */

  /**
   * 사용자명 중복 확인 API
   * GET /auth/check-username/:username
   * 
   * 회원가입 시 사용자명(아이디)의 중복 여부를 확인합니다.
   * 
   * @param username URL 매개변수에서 추출한 확인할 사용자명
   * 
   * Response:
   * - 200: 사용 가능한 사용자명
   * - 409: 이미 사용 중인 사용자명
   * - 400: 유효하지 않은 사용자명 형식
   */
  private async checkUsername(req: Request, res: Response, next: NextFunction) {
    try {
      const { username } = req.params;

      // 사용자명 형식 검증
      if (!username || username.length < 3 || username.length > 20) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'INVALID_USERNAME',
            message: '사용자명은 3자 이상 20자 이하여야 합니다'
          }
        });
      }

      // 영문, 숫자, 언더스코어만 허용
      if (!/^[a-zA-Z0-9_]+$/.test(username)) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'INVALID_USERNAME_FORMAT',
            message: '사용자명은 영문, 숫자, 언더스코어(_)만 사용 가능합니다'
          }
        });
      }

      // 중복 확인
      const exists = await this.userRepository.existsByUsername(username);
      
      if (exists) {
        return res.status(409).json({
          success: false,
          error: {
            code: 'USERNAME_ALREADY_EXISTS',
            message: '이미 사용 중인 사용자명입니다'
          }
        });
      }

      // 사용 가능한 사용자명
      res.json({
        success: true,
        message: '사용 가능한 사용자명입니다',
        data: {
          username,
          available: true
        }
      });

      this.logger.info('사용자명 중복 확인 완료', { 
        username,
        available: true
      });
    } catch (error) {
      this.logger.error('사용자명 중복 확인 실패', { 
        username: req.params.username,
        error 
      });
      next(error);
    }
  }

  private async login(req: Request, res: Response, next: NextFunction) {
    try {
      // ========================================================================
      // 디바이스 및 보안 정보 추출
      // ========================================================================
      
      // 클라이언트에서 전송한 디바이스 고유 식별자 추출
      // 다중 기기 로그인 추적 및 보안 모니터링에 사용
      const deviceId = req.headers['x-device-id'] as string || 'unknown';
      
      // 디바이스 ID가 제공되지 않은 경우 경고 로깅
      // 보안 모니터링 및 이상 행위 탐지에 중요
      if (deviceId === 'unknown') {
        this.logger.warn('로그인 시 디바이스 ID가 제공되지 않음', { 
          userAgent: req.headers['user-agent'], // 브라우저/앱 정보
          ip: req.ip,                           // 클라이언트 IP 주소
          email: req.body.email                 // 로그인 시도 이메일
        });
      }
      
      // 보안 및 로깅용 디바이스 정보 구성
      const deviceInfo = {
        deviceId,                                      // 디바이스 고유 식별자
        userAgent: req.headers['user-agent'],          // User-Agent 헤더
        ipAddress: req.ip || req.connection.remoteAddress // 클라이언트 IP 주소
      };

      const result = await this.loginUseCase.execute({
        ...req.body,
        deviceInfo
      });

      res.json({
        success: true,
        data: {
          user: result.user,
          tokens: result.tokens
        },
        message: '로그인되었습니다.'
      });
    } catch (error) {
      next(error);
    }
  }

  // ============================================================================
  // 🔄 JWT 토큰 갱신 API 핸들러
  // ============================================================================
  
  /**
   * JWT Access Token 갱신 처리
   * 
   * 만료된 Access Token을 Refresh Token을 사용하여 갱신합니다.
   * 보안을 위해 디바이스 정보를 검증하고, 신규 토큰 쌍을 발급합니다.
   * 
   * HTTP Method: POST
   * Endpoint: /auth/refresh
   * 
   * Request Body:
   * @param refreshToken 유효한 Refresh Token 문자열
   * 
   * Request Headers:
   * @param X-Device-Id 디바이스 고유 식별자 (보안 검증용)
   * 
   * Response:
   * - 200: 토큰 갱신 성공 + 새로운 JWT 토큰 쌍
   * - 401: Refresh Token 만료 또는 무효
   * - 403: 디바이스 정보 불일치 또는 보안 이슈
   */
  private async refreshToken(req: Request, res: Response, next: NextFunction) {
    try {
      // 디바이스 정보 추출
      const deviceId = req.headers['x-device-id'] as string || 'unknown';
      
      if (deviceId === 'unknown') {
        this.logger.warn('토큰 갱신 시 디바이스 ID가 제공되지 않음', { 
          userAgent: req.headers['user-agent'],
          ip: req.ip 
        });
      }
      
      const deviceInfo = {
        deviceId,
        userAgent: req.headers['user-agent'],
        ipAddress: req.ip || req.connection.remoteAddress
      };

      const result = await this.refreshTokenUseCase.execute({
        refreshToken: req.body.refreshToken,
        deviceInfo
      });

      res.json({
        success: true,
        data: {
          user: result.user,
          tokens: result.tokens
        }
      });
    } catch (error) {
      next(error);
    }
  }

  // ============================================================================
  // 📟 로그아웃 API 핸들러
  // ============================================================================
  
  /**
   * 사용자 로그아웃 처리
   * 
   * 사용자의 로그인 세션을 종료하고 관련 토큰을 무효화합니다.
   * 특정 기기만 로그아웃하거나 모든 기기에서 로그아웃할 수 있습니다.
   * 
   * HTTP Method: POST
   * Endpoint: /auth/logout
   * 
   * Request Body:
   * @param refreshToken 무효화할 Refresh Token (선택사항)
   * @param allDevices 모든 기기에서 로그아웃 여부 (기본: false)
   * 
   * Request (Authenticated):
   * - Authorization 헤더에서 사용자 ID 추출 가능
   * 
   * Response:
   * - 200: 로그아웃 성공
   * - 401: 인증 정보 없음 또는 무효
   */
  private async logout(req: Request, res: Response, next: NextFunction) {
    try {
      // 인증된 사용자의 경우 req.user에서 userId 가져오기
      const userId = (req as any).user?.userId;

      const result = await this.logoutUseCase.execute({
        refreshToken: req.body.refreshToken,
        allDevices: req.body.allDevices,
        userId
      });

      res.json({
        success: result.success,
        message: result.message
      });
    } catch (error) {
      next(error);
    }
  }

  // ============================================================================
  // ✉️ 이메일 인증 API 핸들러
  // ============================================================================
  
  /**
   * 이메일 인증 링크 처리
   * 
   * 사용자가 이메일로 받은 인증 링크를 클릭했을 때 호출되는 API입니다.
   * 인증 토큰을 검증하고 사용자의 이메일 인증 상태를 업데이트합니다.
   * 
   * HTTP Method: GET
   * Endpoint: /auth/verify-email
   * 
   * Query Parameters:
   * @param token 이메일로 전송된 인증 토큰
   * 
   * Response:
   * - 200: 이메일 인증 성공 + 업데이트된 사용자 정보
   * - 400: 유효하지 않은 또는 누락된 토큰
   * - 404: 토큰에 해당하는 사용자 없음
   * - 410: 만료된 인증 토큰
   */
  private async verifyEmail(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await this.verifyEmailUseCase.execute({
        token: req.query.token as string
      });

      res.json({
        success: result.success,
        data: result.user,
        message: result.message
      });
    } catch (error) {
      next(error);
    }
  }

  // ============================================================================
  // 📧 인증 메일 재전송 API 핸들러
  // ============================================================================
  
  /**
   * 이메일 인증 메일 재전송 처리
   * 
   * 사용자가 인증 이메일을 받지 못했거나 만료된 경우 새로운 인증 메일을 전송합니다.
   * Rate Limiting을 적용하여 남용을 방지하고, 이미 인증된 사용자는 제외합니다.
   * 
   * HTTP Method: POST
   * Endpoint: /auth/resend-verification
   * 
   * Request Body:
   * @param userId 인증 메일을 재전송할 사용자 ID (선택사항)
   * 
   * Request (Authenticated):
   * - Authorization 헤더에서 사용자 ID 추출 가능
   * 
   * Response:
   * - 200: 인증 메일 재전송 성공
   * - 400: 이미 인증된 사용자 또는 잘못된 요청
   * - 404: 사용자를 찾을 수 없음
   * - 429: 재전송 요청 횟수 초과
   */
  private async resendVerification(req: Request, res: Response, next: NextFunction) {
    try {
      // 인증된 사용자의 경우 req.user에서 userId 가져오기
      const userId = (req as any).user?.userId || req.body.userId;

      const result = await this.resendVerificationUseCase.execute({
        userId
      });

      res.json({
        success: result.success,
        message: result.message
      });
    } catch (error) {
      next(error);
    }
  }

  // ============================================================================
  // 🛠️ 개발용 이메일 인증 스킵 API 핸들러
  // ============================================================================
  
  /**
   * 이메일 인증 스킵 처리 (개발 환경 전용)
   * 
   * 개발 환경에서 이메일 인증 프로세스를 스킵하는 편의 기능입니다.
   * 이메일 주소로 사용자를 찾아 즉시 인증된 상태로 변경합니다.
   * 
   * 보안 주의사항:
   * - 프로덕션 환경에서는 완전히 비활성화됨
   * - 개발 학습 및 테스트 목적으로만 사용
   * - 실제 이메일 전송 없이 인증 상태 변경
   * 
   * HTTP Method: POST
   * Endpoint: /auth/skip-verification
   * 
   * Request Body:
   * @param email 인증을 스킵할 사용자의 이메일 주소
   * 
   * Response:
   * - 200: 인증 스킵 성공 + 업데이트된 사용자 정보
   * - 400: 이메일 파라미터 누락
   * - 404: 해당 이메일의 사용자 없음
   * - 409: 이미 인증된 사용자
   */
  private async skipVerification(req: Request, res: Response, next: NextFunction) {
    try {
      // ========================================================================
      // 요청 데이터 검증
      // ========================================================================
      
      const { email } = req.body;
      
      // 이메일 파라미터 필수 검증
      if (!email) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'BAD_REQUEST',
            message: '이메일이 필요합니다.'
          }
        });
      }

      // ========================================================================
      // 사용자 조회 및 인증 상태 업데이트
      // ========================================================================
      
      // 동적 임포트로 Repository와 Value Object 로드
      // 순환 의존성을 방지하고 늨용 방지를 위해 지연 로드
      const { UserRepository } = await import('../../repositories/user.repository');
      const userRepository = container.resolve(UserRepository);
      const { Email } = await import('../../../domain/value-objects/email.vo');
      
      // 이메일 문자열을 Email Value Object로 변환
      const emailVO = Email.create(email);
      
      // 데이터베이스에서 이메일로 사용자 검색
      const user = await userRepository.findByEmail(emailVO);
      
      if (!user) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'USER_NOT_FOUND',
            message: '사용자를 찾을 수 없습니다.'
          }
        });
      }

      if (user.emailVerified) {
        return res.json({
          success: true,
          message: '이미 이메일이 인증되었습니다.'
        });
      }

      // ========================================================================
      // 이메일 인증 상태 업데이트
      // ========================================================================
      
      // User 엔티티의 비즈니스 로직을 통해 이메일 인증 처리
      // 인증 상태와 인증 시간이 자동으로 업데이트됨
      user.verifyEmail();
      
      // 변경된 사용자 정보를 데이터베이스에 영속화
      await userRepository.update(user);

      // 보안 감사 및 모니터링을 위한 로깅
      this.logger.info('이메일 인증 스킵 완료', { 
        userId: user.id.getValue(), 
        email,
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV 
      });

      // 성공 응답 반환 (인증 완료된 사용자 정보 포함)
      res.json({
        success: true,
        message: '이메일 인증이 완료되었습니다.',
        data: {
          user: {
            id: user.id,                        // 사용자 ID
            email: user.email,                  // 인증된 이메일
            emailVerified: user.emailVerified   // 인증 상태 (true)
          }
        }
      });
    } catch (error) {
      next(error);
    }
  }
}