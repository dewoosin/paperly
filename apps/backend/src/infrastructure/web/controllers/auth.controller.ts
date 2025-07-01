/// Paperly Backend - 인증 관련 API 컨트롤러 (메시지 코드 버전)
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
/// - POST /auth/check-username - 사용자명 중복 확인
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
import { ResponseUtil } from '../../../shared/utils/response.util'; // 응답 유틸리티
import { MESSAGE_CODES } from '../../../shared/constants/message-codes'; // 메시지 코드

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
 * - POST /check-username - 사용자명 중복 확인
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
   * @param responseUtil 응답 유틸리티
   */
  constructor(
    @inject(RegisterUseCase) private registerUseCase: RegisterUseCase,
    @inject(LoginUseCase) private loginUseCase: LoginUseCase,
    @inject(VerifyEmailUseCase) private verifyEmailUseCase: VerifyEmailUseCase,
    @inject(ResendVerificationUseCase) private resendVerificationUseCase: ResendVerificationUseCase,
    @inject(RefreshTokenUseCase) private refreshTokenUseCase: RefreshTokenUseCase,
    @inject(LogoutUseCase) private logoutUseCase: LogoutUseCase,
    @inject('UserRepository') private userRepository: IUserRepository,
    @inject('ResponseUtil') private responseUtil: ResponseUtil
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
  private setupRoutes(): void {
    this.router.post('/register', this.register.bind(this));
    this.router.post('/login', this.login.bind(this));
    this.router.post('/refresh', this.refresh.bind(this));
    this.router.post('/logout', this.logout.bind(this));
    this.router.get('/verify-email', this.verifyEmail.bind(this));
    this.router.post('/resend-verification', this.resendVerification.bind(this));
    this.router.post('/check-username', this.checkUsername.bind(this));
    
    // 개발 환경 전용 엔드포인트
    if (process.env.NODE_ENV === 'development') {
      this.router.post('/skip-verification', this.skipVerification.bind(this));
    }
  }

  // ============================================================================
  // 🔐 회원가입 API 핸들러
  // ============================================================================

  /**
   * POST /auth/register - 새로운 사용자 회원가입
   * 
   * 새로운 사용자를 등록하고 이메일 인증 메일을 발송합니다.
   * 클라이언트로부터 디바이스 정보를 수집하여 다중 기기 로그인을 지원합니다.
   * 
   * Request Body:
   * - email: string (필수) - 사용자 이메일
   * - password: string (필수) - 비밀번호 (최소 8자)
   * - name: string (필수) - 사용자 실명
   * - deviceId?: string - 디바이스 고유 ID
   * 
   * Response:
   * - 201 Created: 회원가입 성공
   *   - user: { id, email, name, emailVerified, role }
   *   - tokens: { accessToken, refreshToken }
   *   - message: string
   * - 400 Bad Request: 유효성 검증 실패
   * - 409 Conflict: 이미 존재하는 이메일
   * - 500 Internal Server Error: 서버 오류
   * 
   * Security:
   * - 비밀번호는 bcrypt로 해시화
   * - 디바이스 ID로 로그인 세션 추적
   * - IP 주소 및 User-Agent 로깅
   */
  async register(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      this.logger.info('회원가입 요청', { 
        email: req.body.email,
        name: req.body.name,
        nameLength: req.body.name?.length,
        username: req.body.username,
        usernameLength: req.body.username?.length,
        birthDate: req.body.birthDate,
        userType: req.body.userType,
        deviceId: req.body.deviceId,
        ip: req.ip,
        userAgent: req.headers['user-agent']
      });

      const result = await this.registerUseCase.execute({
        email: req.body.email,
        password: req.body.password,
        name: req.body.name,
        username: req.body.username,
        birthDate: req.body.birthDate,
        userType: req.body.userType || 'reader',
        deviceId: req.body.deviceId || this.generateDeviceId(req),
        ipAddress: req.ip,
        userAgent: req.headers['user-agent'] as string
      });

      this.logger.info('회원가입 성공', { 
        userId: result.user.id,
        email: result.user.email,
        emailVerified: result.user.emailVerified
      });

      await this.responseUtil.success(res, MESSAGE_CODES.AUTH.REGISTER_SUCCESS, {
        user: result.user,
        tokens: result.tokens
      }, undefined, 201);
    } catch (error: any) {
      this.logger.error('회원가입 실패', { 
        error: error.message,
        email: req.body.email,
        stack: error.stack
      });
      
      // 에러 타입에 따라 적절한 메시지 코드 사용
      if (error.message.includes('이미 사용 중인 이메일')) {
        await this.responseUtil.error(res, MESSAGE_CODES.AUTH.EMAIL_EXISTS);
      } else if (error.message.includes('14세 이상')) {
        await this.responseUtil.error(res, MESSAGE_CODES.VALIDATION.REQUIRED_FIELD_MISSING, {
          age: '14세 이상만 가입할 수 있습니다'
        });
      } else {
        await this.responseUtil.serverError(res, error);
      }
    }
  }

  // ============================================================================
  // 🔑 로그인 API 핸들러
  // ============================================================================

  /**
   * POST /auth/login - 사용자 로그인
   * 
   * 이메일과 비밀번호로 사용자를 인증하고 JWT 토큰을 발급합니다.
   * 로그인 시도를 기록하여 보안 모니터링을 지원합니다.
   * 
   * Request Body:
   * - email: string (필수) - 사용자 이메일
   * - password: string (필수) - 비밀번호
   * - deviceId?: string - 디바이스 고유 ID
   * 
   * Response:
   * - 200 OK: 로그인 성공
   *   - user: { id, email, name, emailVerified, role }
   *   - tokens: { accessToken, refreshToken }
   *   - message: string
   * - 401 Unauthorized: 인증 실패
   * - 403 Forbidden: 이메일 미인증
   * - 429 Too Many Requests: 너무 많은 로그인 시도
   * - 500 Internal Server Error: 서버 오류
   * 
   * Security:
   * - 실패한 로그인 시도 추적
   * - Rate limiting으로 브루트포스 방지
   * - IP 주소 및 User-Agent 로깅
   */
  async login(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      this.logger.info('로그인 요청', { 
        email: req.body.email,
        deviceId: req.body.deviceId,
        ip: req.ip,
        userAgent: req.headers['user-agent']
      });

      const result = await this.loginUseCase.execute({
        email: req.body.email,
        password: req.body.password,
        deviceId: req.body.deviceId || this.generateDeviceId(req),
        ipAddress: req.ip,
        userAgent: req.headers['user-agent'] as string
      });

      this.logger.info('로그인 성공', { 
        userId: result.user.id,
        email: result.user.email,
        emailVerified: result.user.emailVerified
      });

      await this.responseUtil.success(res, MESSAGE_CODES.AUTH.LOGIN_SUCCESS, {
        user: result.user,
        tokens: result.tokens
      });
    } catch (error: any) {
      this.logger.error('로그인 실패', { 
        error: error.message,
        email: req.body.email,
        stack: error.stack
      });
      
      // 에러 타입에 따라 적절한 메시지 코드 사용
      if (error.message.includes('올바르지 않습니다')) {
        await this.responseUtil.error(res, MESSAGE_CODES.AUTH.INVALID_CREDENTIALS);
      } else if (error.message.includes('이메일 인증')) {
        await this.responseUtil.error(res, MESSAGE_CODES.AUTH.EMAIL_VERIFICATION_REQUIRED);
      } else {
        await this.responseUtil.serverError(res, error);
      }
    }
  }

  // ============================================================================
  // 🔄 토큰 갱신 API 핸들러
  // ============================================================================

  /**
   * POST /auth/refresh - JWT 토큰 갱신
   * 
   * Refresh Token을 사용하여 새로운 Access Token을 발급합니다.
   * 토큰 탈취 방지를 위해 Refresh Token도 함께 갱신합니다.
   * 
   * Request Body:
   * - refreshToken: string (필수) - 리프레시 토큰
   * - deviceId?: string - 디바이스 고유 ID
   * 
   * Response:
   * - 200 OK: 토큰 갱신 성공
   *   - tokens: { accessToken, refreshToken }
   *   - message: string
   * - 401 Unauthorized: 유효하지 않은 토큰
   * - 500 Internal Server Error: 서버 오류
   * 
   * Security:
   * - Refresh Token Rotation 적용
   * - 디바이스 ID 검증
   * - 토큰 재사용 방지
   */
  async refresh(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      this.logger.info('토큰 갱신 요청', { 
        deviceId: req.body.deviceId,
        ip: req.ip
      });

      const result = await this.refreshTokenUseCase.execute({
        refreshToken: req.body.refreshToken,
        deviceId: req.body.deviceId || this.generateDeviceId(req),
        ipAddress: req.ip,
        userAgent: req.headers['user-agent'] as string
      });

      this.logger.info('토큰 갱신 성공', { 
        userId: result.userId
      });

      await this.responseUtil.success(res, MESSAGE_CODES.AUTH.TOKEN_REFRESHED, {
        tokens: result.tokens
      });
    } catch (error: any) {
      this.logger.error('토큰 갱신 실패', { 
        error: error.message,
        stack: error.stack
      });
      
      await this.responseUtil.error(res, MESSAGE_CODES.AUTH.INVALID_REFRESH_TOKEN);
    }
  }

  // ============================================================================
  // 🚪 로그아웃 API 핸들러
  // ============================================================================

  /**
   * POST /auth/logout - 사용자 로그아웃
   * 
   * 현재 디바이스의 Refresh Token을 무효화하거나 
   * 모든 디바이스에서 로그아웃합니다.
   * 
   * Request Body:
   * - refreshToken: string (필수) - 리프레시 토큰
   * - allDevices?: boolean - 모든 디바이스에서 로그아웃 여부
   * 
   * Response:
   * - 200 OK: 로그아웃 성공
   *   - message: string
   * - 400 Bad Request: 토큰 누락
   * - 500 Internal Server Error: 서버 오류
   * 
   * Security:
   * - Refresh Token 무효화
   * - 디바이스별 또는 전체 로그아웃 지원
   */
  async logout(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      this.logger.info('로그아웃 요청', { 
        allDevices: req.body.allDevices,
        ip: req.ip
      });

      await this.logoutUseCase.execute({
        refreshToken: req.body.refreshToken,
        allDevices: req.body.allDevices || false
      });

      this.logger.info('로그아웃 성공');

      await this.responseUtil.success(res, MESSAGE_CODES.AUTH.LOGOUT_SUCCESS);
    } catch (error: any) {
      this.logger.error('로그아웃 실패', { 
        error: error.message,
        stack: error.stack
      });
      
      await this.responseUtil.serverError(res, error);
    }
  }

  // ============================================================================
  // ✅ 이메일 인증 API 핸들러
  // ============================================================================

  /**
   * GET /auth/verify-email - 이메일 인증 처리
   * 
   * 이메일로 전송된 인증 링크를 통해 이메일 주소를 인증합니다.
   * 토큰 유효성을 검증하고 사용자의 이메일 인증 상태를 업데이트합니다.
   * 
   * Query Parameters:
   * - token: string (필수) - 이메일 인증 토큰
   * 
   * Response:
   * - 200 OK: 인증 성공
   *   - message: string
   *   - user: { id, email, emailVerified }
   * - 400 Bad Request: 유효하지 않은 토큰
   * - 410 Gone: 만료된 토큰
   * - 500 Internal Server Error: 서버 오류
   * 
   * Security:
   * - 토큰 만료 시간 검증 (24시간)
   * - 일회용 토큰 (재사용 방지)
   * - 토큰 유출 시 영향 최소화
   */
  async verifyEmail(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const token = req.query.token as string;
      
      this.logger.info('이메일 인증 요청', { 
        token: token?.substring(0, 10) + '...',
        ip: req.ip
      });

      if (!token) {
        await this.responseUtil.error(res, MESSAGE_CODES.VALIDATION.REQUIRED_FIELD_MISSING, {
          token: '인증 토큰이 필요합니다'
        });
        return;
      }

      const result = await this.verifyEmailUseCase.execute({ token });

      this.logger.info('이메일 인증 성공', { 
        userId: result.user.id,
        email: result.user.email
      });

      await this.responseUtil.success(res, MESSAGE_CODES.AUTH.EMAIL_VERIFIED, {
        user: result.user
      });
    } catch (error: any) {
      this.logger.error('이메일 인증 실패', { 
        error: error.message,
        stack: error.stack
      });
      
      if (error.message.includes('이미 인증')) {
        await this.responseUtil.error(res, MESSAGE_CODES.AUTH.EMAIL_VERIFIED);
      } else if (error.message.includes('만료')) {
        await this.responseUtil.error(res, MESSAGE_CODES.AUTH.TOKEN_EXPIRED);
      } else {
        await this.responseUtil.error(res, MESSAGE_CODES.AUTH.INVALID_VERIFICATION_CODE);
      }
    }
  }

  // ============================================================================
  // 📧 인증 이메일 재전송 API 핸들러
  // ============================================================================

  /**
   * POST /auth/resend-verification - 인증 이메일 재전송
   * 
   * 이메일 인증을 완료하지 않은 사용자에게 인증 메일을 재전송합니다.
   * 스팸 방지를 위해 재전송 간격을 제한합니다.
   * 
   * Request Body:
   * - email: string (필수) - 사용자 이메일
   * 
   * Response:
   * - 200 OK: 재전송 성공
   *   - message: string
   * - 400 Bad Request: 이미 인증된 이메일
   * - 429 Too Many Requests: 너무 잦은 재전송 요청
   * - 500 Internal Server Error: 서버 오류
   * 
   * Security:
   * - Rate limiting (5분에 1회)
   * - 이메일 발송 로깅
   * - 악용 방지를 위한 모니터링
   */
  async resendVerification(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      this.logger.info('인증 이메일 재전송 요청', { 
        email: req.body.email,
        ip: req.ip
      });

      await this.resendVerificationUseCase.execute({
        email: req.body.email
      });

      this.logger.info('인증 이메일 재전송 성공', { 
        email: req.body.email
      });

      await this.responseUtil.success(res, MESSAGE_CODES.AUTH.VERIFICATION_EMAIL_SENT);
    } catch (error: any) {
      this.logger.error('인증 이메일 재전송 실패', { 
        error: error.message,
        email: req.body.email,
        stack: error.stack
      });
      
      if (error.message.includes('이미 인증')) {
        await this.responseUtil.error(res, MESSAGE_CODES.AUTH.EMAIL_VERIFIED);
      } else {
        await this.responseUtil.serverError(res, error);
      }
    }
  }

  // ============================================================================
  // 🔍 사용자명 중복 확인 API 핸들러
  // ============================================================================

  /**
   * POST /auth/check-username - 사용자명 중복 확인
   * 
   * 회원가입 시 사용자명(username) 중복 여부를 실시간으로 확인합니다.
   * 
   * Request Body:
   * - username: string (필수) - 확인할 사용자명
   * 
   * Response:
   * - 200 OK: 확인 완료
   *   - available: boolean - 사용 가능 여부
   *   - message: string
   * - 400 Bad Request: 유효하지 않은 사용자명
   * - 500 Internal Server Error: 서버 오류
   */
  async checkUsername(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { username } = req.body;

      if (!username) {
        await this.responseUtil.error(res, MESSAGE_CODES.VALIDATION.REQUIRED_FIELD_MISSING, {
          username: '사용자명을 입력해주세요'
        });
        return;
      }

      // 사용자명 유효성 검사
      if (username.length < 3 || username.length > 20) {
        await this.responseUtil.error(res, MESSAGE_CODES.VALIDATION.NICKNAME_LENGTH);
        return;
      }

      if (!/^[a-zA-Z0-9_]+$/.test(username)) {
        await this.responseUtil.validationError(res, {
          username: '사용자명은 영문, 숫자, 언더스코어(_)만 사용 가능합니다'
        });
        return;
      }

      const isUsernameExists = await this.userRepository.existsByUsername(username);
      
      if (isUsernameExists) {
        await this.responseUtil.success(res, MESSAGE_CODES.USER.NICKNAME_IN_USE, {
          available: false
        });
      } else {
        res.status(200).json({
          success: true,
          message: '사용 가능한 사용자명입니다',
          data: {
            available: true
          }
        });
      }
    } catch (error: any) {
      this.logger.error('사용자명 중복 확인 실패', { 
        error: error.message,
        username: req.body.username,
        stack: error.stack
      });
      
      await this.responseUtil.serverError(res, error);
    }
  }

  // ============================================================================
  // 🚀 개발 전용 API 핸들러
  // ============================================================================

  /**
   * POST /auth/skip-verification - 이메일 인증 스킵 (개발 전용)
   * 
   * 개발 환경에서 테스트를 위해 이메일 인증을 건너뜁니다.
   * 프로덕션 환경에서는 사용할 수 없습니다.
   * 
   * Request Body:
   * - email: string (필수) - 사용자 이메일
   * 
   * Response:
   * - 200 OK: 인증 스킵 성공
   *   - message: string
   *   - user: { id, email, emailVerified }
   * - 404 Not Found: 사용자를 찾을 수 없음
   * - 500 Internal Server Error: 서버 오류
   * 
   * Security:
   * - 개발 환경에서만 활성화
   * - 프로덕션 빌드에서 제외
   */
  async skipVerification(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      this.logger.warn('이메일 인증 스킵 요청 (개발 전용)', { 
        email: req.body.email,
        ip: req.ip
      });

      const user = await this.userRepository.findByEmail(req.body.email);
      
      if (!user) {
        await this.responseUtil.error(res, MESSAGE_CODES.USER.NOT_FOUND);
        return;
      }

      // 실제로는 use case를 통해 처리해야 하지만 개발용이므로 직접 처리
      user.emailVerified = true;
      await this.userRepository.save(user);

      this.logger.warn('이메일 인증 스킵 완료 (개발 전용)', { 
        userId: user.id,
        email: user.email
      });

      await this.responseUtil.success(res, MESSAGE_CODES.AUTH.EMAIL_VERIFIED, {
        user: {
          id: user.id,
          email: user.email,
          emailVerified: user.emailVerified
        }
      });
    } catch (error: any) {
      this.logger.error('이메일 인증 스킵 실패', { 
        error: error.message,
        email: req.body.email,
        stack: error.stack
      });
      
      await this.responseUtil.serverError(res, error);
    }
  }

  // ============================================================================
  // 🛠️ 유틸리티 메서드
  // ============================================================================

  /**
   * 디바이스 ID 생성
   * 
   * 클라이언트가 디바이스 ID를 제공하지 않은 경우
   * User-Agent와 IP 주소를 기반으로 임시 ID를 생성합니다.
   * 
   * @param req Express Request 객체
   * @returns 생성된 디바이스 ID
   */
  private generateDeviceId(req: Request): string {
    const userAgent = req.headers['user-agent'] || 'unknown';
    const ip = req.ip || 'unknown';
    return `web_${Buffer.from(`${userAgent}_${ip}`).toString('base64').substring(0, 16)}`;
  }
}