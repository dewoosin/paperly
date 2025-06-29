// apps/backend/src/application/use-cases/auth.use-cases.ts

import { IUserRepository } from '../../infrastructure/repositories/user.repository';
import { AuthRepository } from '../../infrastructure/repositories/auth.repository';
import { JwtService } from '../../infrastructure/auth/jwt.service';
import { PasswordService } from '../../infrastructure/auth/password.service';
import { EmailService } from '../../infrastructure/email/email.service';
import { User } from '../../domain/entities/User.entity';
import { Email } from '../../domain/value-objects/email.vo';
import { Password } from '../../domain/value-objects/password.vo';
import { UserId } from '../../domain/value-objects/user-id.vo';
import {
  RegisterRequest,
  LoginRequest,
  AuthResponse,
  RefreshTokenRequest,
  Gender,
} from '../../domain/auth/auth.types';
import {
  BadRequestError,
  UnauthorizedError,
  ConflictError,
  NotFoundError,
} from '../../shared/errors';
import { Logger } from '../../infrastructure/logging/Logger';
import { MESSAGE_CODES } from '../../shared/constants/message-codes';

/**
 * 인증 관련 유스케이스
 * 
 * 회원가입, 로그인, 토큰 갱신 등의 비즈니스 로직을 담당합니다.
 */
export class AuthUseCases {
  private readonly logger = new Logger('AuthUseCases');

  constructor(
    private readonly userRepository: IUserRepository,
    private readonly emailService?: EmailService
  ) {}

  /**
   * 회원가입
   * 
   * @param request - 회원가입 요청 정보
   * @param deviceInfo - 디바이스 정보
   * @returns 인증 응답 (사용자 정보 + 토큰)
   */
  async register(
    request: RegisterRequest,
    deviceInfo?: { deviceId?: string; userAgent?: string; ipAddress?: string }
  ): Promise<AuthResponse> {
    this.logger.info('회원가입 시작', { email: request.email });

    // 1. 이메일 중복 확인
    const email = new Email(request.email);
    const existingUser = await this.userRepository.findByEmail(email);
    if (existingUser) {
      const error = new ConflictError('이미 사용 중인 이메일입니다');
      error.messageCode = MESSAGE_CODES.AUTH.EMAIL_EXISTS;
      throw error;
    }

    // 2. 비밀번호 강도 검증
    const passwordValidation = PasswordService.validateStrength(request.password);
    if (!passwordValidation.isValid) {
      throw new BadRequestError(passwordValidation.errors.join(', '));
    }

    // 3. 비밀번호 해싱
    const hashedPassword = await PasswordService.hash(request.password);
    const password = Password.fromHash(hashedPassword);

    // 4. 사용자 생성
    const user = new User(
      UserId.generate(),
      email,
      password,
      request.name,
      false, // 이메일 미인증 상태
      new Date(request.birthDate),
      request.gender as Gender | undefined
    );

    // 5. 사용자 저장
    await this.userRepository.save(user);

    // 6. JWT 토큰 생성
    const tokens = JwtService.generateTokenPair(user.id.value, user.email.value);

    // 7. Refresh Token 저장
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7일
    await AuthRepository.saveRefreshToken(
      user.id.value,
      tokens.refreshToken,
      expiresAt,
      deviceInfo?.deviceId,
      deviceInfo?.userAgent,
      deviceInfo?.ipAddress
    );

    // 8. 이메일 인증 메일 발송
    let emailVerificationSent = false;
    try {
      const verificationToken = await AuthRepository.createEmailVerificationToken(user.id.value);
      if (this.emailService) {
        await this.emailService.sendVerificationEmail(
          user.email.value,
          user.name,
          verificationToken.token
        );
        emailVerificationSent = true;
      }
    } catch (error) {
      logger.error('이메일 발송 실패', error);
      // 이메일 발송 실패해도 회원가입은 성공 처리
    }

    logger.info('회원가입 완료', { userId: user.id.value });

    return {
      user: {
        id: user.id.value,
        email: user.email.value,
        name: user.name,
        emailVerified: user.emailVerified,
        birthDate: user.birthDate,
        gender: user.gender,
      },
      tokens,
      emailVerificationSent,
    };
  }

  /**
   * 로그인
   * 
   * @param request - 로그인 요청 정보
   * @param deviceInfo - 디바이스 정보
   * @returns 인증 응답
   */
  async login(
    request: LoginRequest,
    deviceInfo?: { deviceId?: string; userAgent?: string; ipAddress?: string }
  ): Promise<AuthResponse> {
    logger.info('로그인 시도', { email: request.email });

    // 1. 사용자 조회
    const email = new Email(request.email);
    const user = await this.userRepository.findByEmail(email);
    if (!user) {
      const error = new UnauthorizedError('이메일 또는 비밀번호가 올바르지 않습니다');
      error.messageCode = MESSAGE_CODES.AUTH.INVALID_CREDENTIALS;
      throw error;
    }

    // 2. 비밀번호 검증
    const isPasswordValid = await user.password.verify(request.password);
    if (!isPasswordValid) {
      const error = new UnauthorizedError('이메일 또는 비밀번호가 올바르지 않습니다');
      error.messageCode = MESSAGE_CODES.AUTH.INVALID_CREDENTIALS;
      throw error;
    }

    // 3. JWT 토큰 생성
    const tokens = JwtService.generateTokenPair(user.id.value, user.email.value);

    // 4. Refresh Token 저장
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7일
    await AuthRepository.saveRefreshToken(
      user.id.value,
      tokens.refreshToken,
      expiresAt,
      deviceInfo?.deviceId,
      deviceInfo?.userAgent,
      deviceInfo?.ipAddress
    );

    logger.info('로그인 성공', { userId: user.id.value });

    return {
      user: {
        id: user.id.value,
        email: user.email.value,
        name: user.name,
        emailVerified: user.emailVerified,
        birthDate: user.birthDate,
        gender: user.gender,
      },
      tokens,
    };
  }

  /**
   * 토큰 갱신
   * 
   * @param request - 토큰 갱신 요청
   * @returns 새로운 토큰 쌍
   */
  async refreshTokens(request: RefreshTokenRequest): Promise<AuthResponse> {
    logger.info('토큰 갱신 시도');

    // 1. Refresh Token 검증
    const decodedToken = JwtService.verifyRefreshToken(request.refreshToken);

    // 2. DB에서 토큰 확인
    const savedToken = await AuthRepository.findRefreshToken(request.refreshToken);
    if (!savedToken) {
      const error = new UnauthorizedError('유효하지 않은 토큰입니다');
      error.messageCode = MESSAGE_CODES.AUTH.INVALID_REFRESH_TOKEN;
      throw error;
    }

    // 3. 사용자 조회
    const user = await this.userRepository.findById(new UserId(decodedToken.userId));
    if (!user) {
      const error = new UnauthorizedError('사용자를 찾을 수 없습니다');
      error.messageCode = MESSAGE_CODES.USER.NOT_FOUND;
      throw error;
    }

    // 4. 기존 토큰 삭제
    await AuthRepository.deleteRefreshToken(request.refreshToken);

    // 5. 새로운 토큰 생성
    const tokens = JwtService.generateTokenPair(user.id.value, user.email.value);

    // 6. 새로운 Refresh Token 저장
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7일
    await AuthRepository.saveRefreshToken(
      user.id.value,
      tokens.refreshToken,
      expiresAt,
      savedToken.deviceId,
      savedToken.userAgent,
      savedToken.ipAddress
    );

    logger.info('토큰 갱신 성공', { userId: user.id.value });

    return {
      user: {
        id: user.id.value,
        email: user.email.value,
        name: user.name,
        emailVerified: user.emailVerified,
        birthDate: user.birthDate,
        gender: user.gender,
      },
      tokens,
    };
  }

  /**
   * 로그아웃
   * 
   * @param refreshToken - 로그아웃할 Refresh Token
   * @param allDevices - 모든 디바이스에서 로그아웃 여부
   * @param userId - 사용자 ID (allDevices가 true일 때 필요)
   */
  async logout(
    refreshToken?: string,
    allDevices: boolean = false,
    userId?: string
  ): Promise<void> {
    logger.info('로그아웃 시도', { allDevices });

    if (allDevices && userId) {
      // 모든 디바이스에서 로그아웃
      await AuthRepository.deleteAllUserRefreshTokens(userId);
      logger.info('모든 디바이스에서 로그아웃 완료', { userId });
    } else if (refreshToken) {
      // 현재 디바이스에서만 로그아웃
      await AuthRepository.deleteRefreshToken(refreshToken);
      logger.info('로그아웃 완료');
    }
  }

  /**
   * 이메일 인증
   * 
   * @param token - 이메일 인증 토큰
   */
  async verifyEmail(token: string): Promise<void> {
    logger.info('이메일 인증 시도');

    // 1. 토큰 조회
    const verificationToken = await AuthRepository.findEmailVerificationToken(token);
    if (!verificationToken) {
      const error = new BadRequestError('유효하지 않은 인증 토큰입니다');
      error.messageCode = MESSAGE_CODES.AUTH.INVALID_VERIFICATION_CODE;
      throw error;
    }

    // 2. 사용자 이메일 인증 상태 업데이트
    await this.userRepository.updateEmailVerified(
      new UserId(verificationToken.userId),
      true
    );

    // 3. 사용한 토큰 삭제
    await AuthRepository.deleteEmailVerificationToken(token);

    logger.info('이메일 인증 완료', { userId: verificationToken.userId });
  }

  /**
   * 이메일 인증 메일 재발송
   * 
   * @param userId - 사용자 ID
   */
  async resendVerificationEmail(userId: string): Promise<void> {
    logger.info('이메일 인증 메일 재발송', { userId });

    // 1. 사용자 조회
    const user = await this.userRepository.findById(new UserId(userId));
    if (!user) {
      const error = new NotFoundError('사용자를 찾을 수 없습니다');
      error.messageCode = MESSAGE_CODES.USER.NOT_FOUND;
      throw error;
    }

    // 2. 이미 인증된 경우
    if (user.emailVerified) {
      const error = new BadRequestError('이미 이메일 인증이 완료되었습니다');
      error.messageCode = MESSAGE_CODES.AUTH.EMAIL_VERIFIED;
      throw error;
    }

    // 3. 새로운 인증 토큰 생성
    const verificationToken = await AuthRepository.createEmailVerificationToken(userId);

    // 4. 이메일 발송
    if (this.emailService) {
      await this.emailService.sendVerificationEmail(
        user.email.value,
        user.name,
        verificationToken.token
      );
    } else {
      throw new Error('이메일 서비스를 사용할 수 없습니다');
    }

    logger.info('이메일 인증 메일 재발송 완료', { userId });
  }

  /**
   * 만료된 토큰 정리 (배치 작업용)
   */
  async cleanupExpiredTokens(): Promise<number> {
    return await AuthRepository.cleanupExpiredTokens();
  }
}