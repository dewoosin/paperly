// /Users/workspace/paperly/apps/backend/src/application/services/admin-auth.service.ts

import { injectable, inject } from 'tsyringe';
import { Email } from '../../domain/value-objects/email.vo';
import { Password } from '../../domain/value-objects/password.vo';
import { IUserRepository } from '../../infrastructure/repositories/user.repository';
import { AdminRoleRepository } from '../../infrastructure/repositories/admin-role.repository';
import { JwtService } from '../../infrastructure/auth/jwt.service';
import { Logger } from '../../infrastructure/logging/Logger';
import { UnauthorizedError, ForbiddenError } from '../../shared/errors';
import { SecurityMonitor, SecurityEventType, SecuritySeverity, SecurityAction } from '../../infrastructure/security/monitoring/security-monitor';

/**
 * 관리자 인증 서비스
 * 
 * 관리자 로그인, 역할 확인, 권한 관리를 담당하는 애플리케이션 서비스입니다.
 * 일반 사용자 인증과 달리 역할 기반 접근 제어를 제공합니다.
 */

export interface AdminLoginRequest {
  email: string;
  password: string;
  deviceId?: string;
  userAgent?: string;
  ip?: string;
}

export interface AdminLoginResponse {
  user: {
    id: string;
    email: string;
    name: string;
    role: string;
    permissions: string[];
    roleAssignedAt: Date;
    roleExpiresAt?: Date;
  };
  tokens: {
    accessToken: string;
    refreshToken: string;
  };
}

export interface AdminUserInfo {
  id: string;
  email: string;
  name: string;
  role: string;
  permissions: string[];
  isActive: boolean;
  lastLoginAt?: Date;
  createdAt: Date;
}

@injectable()
export class AdminAuthService {
  private readonly logger = new Logger('AdminAuthService');

  constructor(
    @inject('UserRepository') private readonly userRepository: IUserRepository,
    private readonly roleRepository: AdminRoleRepository,
    private readonly securityMonitor: SecurityMonitor
  ) {}

  /**
   * 관리자 로그인
   * 
   * 이메일과 비밀번호로 로그인하고, 관리자 역할을 확인한 후 
   * 역할 정보가 포함된 JWT 토큰을 발급합니다.
   * 
   * @param request 로그인 요청 정보
   * @returns 로그인 응답 (사용자 정보 + 토큰)
   * @throws UnauthorizedError 인증 실패
   * @throws ForbiddenError 관리자 권한 없음
   */
  async login(request: AdminLoginRequest): Promise<AdminLoginResponse> {
    try {
      // 입력값 검증
      const email = Email.create(request.email);

      // 사용자 조회
      const user = await this.userRepository.findByEmail(email);
      if (!user) {
        this.logger.warn('관리자 로그인 실패 - 사용자 없음', { 
          email: request.email,
          ip: request.ip 
        });
        
        // 보안 이벤트 기록
        this.securityMonitor.recordSecurityEvent({
          type: SecurityEventType.MULTIPLE_FAILED_LOGINS,
          severity: SecuritySeverity.MEDIUM,
          source: {
            ip: request.ip || 'unknown',
            userAgent: request.userAgent,
            deviceId: request.deviceId
          },
          target: {
            endpoint: '/admin/auth/login',
            method: 'POST'
          },
          details: {
            description: '존재하지 않는 이메일로 관리자 로그인 시도',
            riskScore: 5,
            threats: ['ADMIN_BRUTE_FORCE']
          },
          response: {
            action: SecurityAction.LOGGED,
            blocked: false,
            timestamp: new Date()
          }
        });

        throw new UnauthorizedError('이메일 또는 비밀번호가 잘못되었습니다');
      }

      // 비밀번호 확인
      const isPasswordValid = await user.password.verify(request.password);
      if (!isPasswordValid) {
        this.logger.warn('관리자 로그인 실패 - 비밀번호 불일치', { 
          userId: user.id.getValue(),
          email: request.email,
          ip: request.ip 
        });

        // 보안 이벤트 기록
        this.securityMonitor.recordSecurityEvent({
          type: SecurityEventType.MULTIPLE_FAILED_LOGINS,
          severity: SecuritySeverity.MEDIUM,
          source: {
            ip: request.ip || 'unknown',
            userAgent: request.userAgent,
            userId: user.id.getValue(),
            deviceId: request.deviceId
          },
          target: {
            endpoint: '/admin/auth/login',
            method: 'POST'
          },
          details: {
            description: '잘못된 비밀번호로 관리자 로그인 시도',
            riskScore: 7,
            threats: ['ADMIN_BRUTE_FORCE']
          },
          response: {
            action: SecurityAction.LOGGED,
            blocked: false,
            timestamp: new Date()
          }
        });

        throw new UnauthorizedError('이메일 또는 비밀번호가 잘못되었습니다');
      }

      // 계정 상태 확인
      if (user.status !== 'active') {
        this.logger.warn('관리자 로그인 실패 - 비활성 계정', { 
          userId: user.id.getValue(),
          status: user.status,
          ip: request.ip 
        });
        throw new UnauthorizedError('비활성화된 계정입니다');
      }

      // 역할 정보 조회
      const userRole = await this.roleRepository.getUserRole(user.id.getValue());
      if (!userRole) {
        this.logger.warn('관리자 로그인 실패 - 역할 정보 없음', { 
          userId: user.id.getValue(),
          email: request.email,
          ip: request.ip 
        });
        throw new ForbiddenError('관리자 권한이 없습니다');
      }

      // 관리자 역할 확인
      const adminRoles = ['admin', 'super_admin', 'editor', 'reviewer'];
      if (!adminRoles.includes(userRole.role)) {
        this.logger.warn('관리자 로그인 실패 - 관리자 역할 아님', { 
          userId: user.id.getValue(),
          role: userRole.role,
          ip: request.ip 
        });

        // 보안 이벤트 기록
        this.securityMonitor.recordSecurityEvent({
          type: SecurityEventType.PRIVILEGE_ESCALATION,
          severity: SecuritySeverity.HIGH,
          source: {
            ip: request.ip || 'unknown',
            userAgent: request.userAgent,
            userId: user.id.getValue(),
            deviceId: request.deviceId
          },
          target: {
            endpoint: '/admin/auth/login',
            method: 'POST'
          },
          details: {
            description: '일반 사용자가 관리자 로그인 시도',
            riskScore: 8,
            threats: ['PRIVILEGE_ESCALATION'],
            context: { userRole: userRole.role }
          },
          response: {
            action: SecurityAction.LOGGED,
            blocked: false,
            timestamp: new Date()
          }
        });

        throw new ForbiddenError('관리자 권한이 없습니다');
      }

      // 역할 만료 확인
      if (userRole.roleExpiresAt && userRole.roleExpiresAt <= new Date()) {
        this.logger.warn('관리자 로그인 실패 - 역할 만료', { 
          userId: user.id.getValue(),
          expiresAt: userRole.roleExpiresAt,
          ip: request.ip 
        });
        throw new ForbiddenError('관리자 권한이 만료되었습니다');
      }

      // 마지막 로그인 시간 업데이트
      user.updateLastLogin();
      await this.userRepository.update(user);

      // JWT 토큰 생성 (역할 정보 포함)
      const tokens = JwtService.generateTokenPair(
        user.id.getValue(),
        user.email.getValue(),
        user.userType,
        user.userCode || 'AD0001',
        userRole.role,
        userRole.permissions
      );

      // 성공적인 로그인 기록
      this.logger.info('관리자 로그인 성공', {
        userId: user.id.getValue(),
        email: user.email.getValue(),
        role: userRole.role,
        permissions: userRole.permissions,
        ip: request.ip
      });

      return {
        user: {
          id: user.id.getValue(),
          email: user.email.getValue(),
          name: user.name,
          role: userRole.role,
          permissions: userRole.permissions,
          roleAssignedAt: userRole.roleAssignedAt,
          roleExpiresAt: userRole.roleExpiresAt
        },
        tokens
      };
    } catch (error) {
      if (error instanceof UnauthorizedError || error instanceof ForbiddenError) {
        throw error;
      }
      
      this.logger.error('관리자 로그인 중 오류 발생', { 
        email: request.email,
        ip: request.ip,
        error 
      });
      throw new Error('로그인 처리 중 오류가 발생했습니다');
    }
  }

  /**
   * 관리자 토큰 새로고침
   * 
   * Refresh 토큰을 사용하여 새로운 Access 토큰을 발급합니다.
   * 역할 정보도 함께 갱신하여 실시간 권한 변경을 반영합니다.
   * 
   * @param refreshToken Refresh JWT 토큰
   * @returns 새로운 토큰 쌍
   */
  async refreshToken(refreshToken: string): Promise<{ 
    accessToken: string; 
    refreshToken: string; 
  }> {
    try {
      // Refresh 토큰 검증
      const decoded = JwtService.verifyRefreshToken(refreshToken);
      
      // 사용자 및 역할 정보 재조회
      const userRole = await this.roleRepository.getUserRole(decoded.userId);
      if (!userRole) {
        throw new UnauthorizedError('사용자 역할 정보를 찾을 수 없습니다');
      }

      // 관리자 권한 재확인
      const adminRoles = ['admin', 'super_admin', 'editor', 'reviewer'];
      if (!adminRoles.includes(userRole.role)) {
        throw new ForbiddenError('관리자 권한이 없습니다');
      }

      // 새로운 토큰 쌍 생성
      const tokens = JwtService.generateTokenPair(
        userRole.userId,
        userRole.email,
        'admin', // userType
        'AD0001', // userCode
        userRole.role,
        userRole.permissions
      );

      this.logger.info('관리자 토큰 새로고침 완료', {
        userId: userRole.userId,
        role: userRole.role
      });

      return tokens;
    } catch (error) {
      this.logger.error('관리자 토큰 새로고침 실패', { error });
      throw error;
    }
  }

  /**
   * 관리자 사용자 정보 조회
   * 
   * @param userId 사용자 ID
   * @returns 관리자 사용자 정보
   */
  async getAdminUser(userId: string): Promise<AdminUserInfo | null> {
    try {
      const user = await this.userRepository.findById({ getValue: () => userId } as any);
      if (!user) {
        return null;
      }

      const userRole = await this.roleRepository.getUserRole(userId);
      if (!userRole) {
        return null;
      }

      return {
        id: user.id.getValue(),
        email: user.email.getValue(),
        name: user.name,
        role: userRole.role,
        permissions: userRole.permissions,
        isActive: user.status === 'active',
        lastLoginAt: user.lastLoginAt,
        createdAt: user.createdAt
      };
    } catch (error) {
      this.logger.error('관리자 사용자 조회 실패', { userId, error });
      throw error;
    }
  }

  /**
   * 사용자에게 관리자 역할 할당
   * 
   * @param targetUserId 대상 사용자 ID
   * @param roleId 할당할 역할 ID
   * @param assignedBy 할당하는 관리자 ID
   * @param expiresAt 만료일 (선택사항)
   */
  async assignAdminRole(
    targetUserId: string,
    roleId: string,
    assignedBy: string,
    expiresAt?: Date
  ): Promise<void> {
    try {
      await this.roleRepository.assignRole(targetUserId, roleId, assignedBy, expiresAt);
      
      this.logger.info('관리자 역할 할당 완료', {
        targetUserId,
        roleId,
        assignedBy,
        expiresAt
      });
    } catch (error) {
      this.logger.error('관리자 역할 할당 실패', {
        targetUserId,
        roleId,
        assignedBy,
        error
      });
      throw error;
    }
  }

  /**
   * 사용자의 관리자 역할 제거
   * 
   * @param targetUserId 대상 사용자 ID
   * @param removedBy 제거하는 관리자 ID
   */
  async removeAdminRole(targetUserId: string, removedBy: string): Promise<void> {
    try {
      await this.roleRepository.removeRole(targetUserId, removedBy);
      
      this.logger.info('관리자 역할 제거 완료', {
        targetUserId,
        removedBy
      });
    } catch (error) {
      this.logger.error('관리자 역할 제거 실패', {
        targetUserId,
        removedBy,
        error
      });
      throw error;
    }
  }

  /**
   * 모든 관리자 사용자 목록 조회
   * 
   * @returns 관리자 사용자 목록
   */
  async getAllAdminUsers(): Promise<AdminUserInfo[]> {
    try {
      const adminUsers = await this.roleRepository.getAdminUsers();
      
      return adminUsers.map(userRole => ({
        id: userRole.userId,
        email: userRole.email,
        name: userRole.name,
        role: userRole.role,
        permissions: userRole.permissions,
        isActive: true, // 활성 사용자만 조회됨
        lastLoginAt: undefined, // 필요시 별도 조회
        createdAt: userRole.roleAssignedAt // 역할 할당일을 생성일로 사용
      }));
    } catch (error) {
      this.logger.error('관리자 사용자 목록 조회 실패', { error });
      throw error;
    }
  }
}