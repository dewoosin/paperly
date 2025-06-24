// apps/backend/src/domain/entities/refresh-token.entity.ts

import { Entity } from '../../shared/domain/entity';
import { Token } from '../value-objects/auth.value-objects';
import { UserId } from '../value-objects/user-id.value-object';

/**
 * Refresh Token 엔티티
 * 
 * JWT Refresh Token을 관리하는 도메인 엔티티
 * 디바이스별로 독립적인 토큰을 관리하여 다중 디바이스 로그인 지원
 */
export interface RefreshTokenProps {
  userId: UserId;
  token: Token;
  deviceId?: string;
  deviceName?: string;
  ipAddress?: string;
  lastUsedAt: Date;
  expiresAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

export class RefreshToken extends Entity<RefreshTokenProps> {
  /**
   * Refresh Token 생성
   */
  static create(props: {
    userId: UserId;
    token: Token;
    deviceId?: string;
    deviceName?: string;
    ipAddress?: string;
    expiresAt: Date;
  }): RefreshToken {
    const now = new Date();
    
    return new RefreshToken({
      ...props,
      lastUsedAt: now,
      createdAt: now,
      updatedAt: now
    });
  }

  /**
   * 기존 데이터로부터 복원
   */
  static fromPersistence(id: string, props: RefreshTokenProps): RefreshToken {
    const refreshToken = new RefreshToken(props);
    refreshToken._id = id;
    return refreshToken;
  }

  get userId(): UserId {
    return this.props.userId;
  }

  get token(): Token {
    return this.props.token;
  }

  get deviceId(): string | undefined {
    return this.props.deviceId;
  }

  get deviceName(): string | undefined {
    return this.props.deviceName;
  }

  get ipAddress(): string | undefined {
    return this.props.ipAddress;
  }

  get lastUsedAt(): Date {
    return this.props.lastUsedAt;
  }

  get expiresAt(): Date {
    return this.props.expiresAt;
  }

  get createdAt(): Date {
    return this.props.createdAt;
  }

  get updatedAt(): Date {
    return this.props.updatedAt;
  }

  /**
   * 토큰이 만료되었는지 확인
   */
  isExpired(): boolean {
    return new Date() > this.expiresAt;
  }

  /**
   * 마지막 사용 시간 업데이트
   */
  updateLastUsed(ipAddress?: string): void {
    this.props.lastUsedAt = new Date();
    this.props.updatedAt = new Date();
    
    if (ipAddress) {
      this.props.ipAddress = ipAddress;
    }
  }

  /**
   * 토큰 갱신
   * 
   * @param newToken - 새로운 토큰
   * @param expiresAt - 새로운 만료 시간
   */
  refresh(newToken: Token, expiresAt: Date): void {
    this.props.token = newToken;
    this.props.expiresAt = expiresAt;
    this.props.lastUsedAt = new Date();
    this.props.updatedAt = new Date();
  }

  /**
   * 디바이스 정보 업데이트
   */
  updateDeviceInfo(deviceId: string, deviceName: string): void {
    this.props.deviceId = deviceId;
    this.props.deviceName = deviceName;
    this.props.updatedAt = new Date();
  }
}