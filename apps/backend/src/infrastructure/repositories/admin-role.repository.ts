// /Users/workspace/paperly/apps/backend/src/infrastructure/repositories/admin-role.repository.ts

import { injectable } from 'tsyringe';
import { DatabaseConnection } from '../database/database.connection';
import { Logger } from '../logging/Logger';

/**
 * 관리자 역할 관리 리포지토리
 * 
 * 사용자의 역할과 권한을 관리하는 데이터 접근 계층입니다.
 * 기존 데이터베이스 스키마의 user_roles, user_role_assignments 테이블을 사용합니다.
 */

export interface UserRole {
  id: string;
  name: string;
  displayName: string;
  description: string;
  permissions: string[];
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface UserRoleAssignment {
  id: string;
  userId: string;
  roleId: string;
  role: UserRole;
  assignedBy: string;
  assignedAt: Date;
  expiresAt?: Date;
  isActive: boolean;
}

export interface UserWithRole {
  userId: string;
  email: string;
  name: string;
  role: string;
  permissions: string[];
  roleAssignedAt: Date;
  roleExpiresAt?: Date;
}

@injectable()
export class AdminRoleRepository {
  private readonly logger = new Logger('AdminRoleRepository');

  constructor(private readonly db: DatabaseConnection) {}

  /**
   * 사용자의 역할과 권한 조회
   * 
   * @param userId 사용자 ID
   * @returns 사용자의 역할 정보 또는 null
   */
  async getUserRole(userId: string): Promise<UserWithRole | null> {
    try {
      const query = `
        SELECT 
          u.id as user_id,
          u.email,
          u.name,
          r.name as role_name,
          r.permissions,
          ura.created_at as role_assigned_at,
          ura.expires_at as role_expires_at
        FROM paperly.users u
        LEFT JOIN paperly.user_role_assignments ura ON u.id = ura.user_id AND ura.is_active = true
        LEFT JOIN paperly.user_roles r ON ura.role_id = r.id AND r.is_active = true
        WHERE u.id = $1
          AND u.status = 'active'
          AND (ura.expires_at IS NULL OR ura.expires_at > CURRENT_TIMESTAMP)
        ORDER BY ura.created_at DESC
        LIMIT 1
      `;

      const result = await this.db.query(query, [userId]);
      
      if (result.rows.length === 0) {
        return null;
      }

      const row = result.rows[0];
      return {
        userId: row.user_id,
        email: row.email,
        name: row.name,
        role: row.role_name || 'user',
        permissions: row.permissions || [],
        roleAssignedAt: row.role_assigned_at,
        roleExpiresAt: row.role_expires_at
      };
    } catch (error) {
      this.logger.error('사용자 역할 조회 실패', { userId, error });
      throw error;
    }
  }

  /**
   * 모든 역할 목록 조회
   * 
   * @returns 활성화된 역할 목록
   */
  async getAllRoles(): Promise<UserRole[]> {
    try {
      const query = `
        SELECT 
          id,
          name,
          display_name,
          description,
          permissions,
          is_active,
          created_at,
          updated_at
        FROM paperly.user_roles
        WHERE is_active = true
        ORDER BY created_at ASC
      `;

      const result = await this.db.query(query);
      
      return result.rows.map(row => ({
        id: row.id,
        name: row.name,
        displayName: row.display_name,
        description: row.description,
        permissions: row.permissions || [],
        isActive: row.is_active,
        createdAt: row.created_at,
        updatedAt: row.updated_at
      }));
    } catch (error) {
      this.logger.error('역할 목록 조회 실패', { error });
      throw error;
    }
  }

  /**
   * 사용자에게 역할 할당
   * 
   * @param userId 사용자 ID
   * @param roleId 역할 ID
   * @param assignedBy 할당한 관리자 ID
   * @param expiresAt 만료일 (선택사항)
   */
  async assignRole(
    userId: string, 
    roleId: string, 
    assignedBy: string, 
    expiresAt?: Date
  ): Promise<void> {
    const client = await this.db.getClient();
    
    try {
      await client.query('BEGIN');

      // 기존 역할 할당 비활성화
      await client.query(
        `UPDATE paperly.user_role_assignments 
         SET is_active = false, updated_at = CURRENT_TIMESTAMP 
         WHERE user_id = $1 AND is_active = true`,
        [userId]
      );

      // 새 역할 할당
      await client.query(
        `INSERT INTO paperly.user_role_assignments 
         (id, user_id, role_id, assigned_by, expires_at, is_active, created_at, updated_at)
         VALUES (uuid_generate_v4(), $1, $2, $3, $4, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
        [userId, roleId, assignedBy, expiresAt]
      );

      await client.query('COMMIT');
      
      this.logger.info('사용자 역할 할당 완료', { 
        userId, 
        roleId, 
        assignedBy, 
        expiresAt 
      });
    } catch (error) {
      await client.query('ROLLBACK');
      this.logger.error('사용자 역할 할당 실패', { 
        userId, 
        roleId, 
        assignedBy, 
        error 
      });
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * 사용자의 역할 제거
   * 
   * @param userId 사용자 ID
   * @param removedBy 제거한 관리자 ID
   */
  async removeRole(userId: string, removedBy: string): Promise<void> {
    try {
      await this.db.query(
        `UPDATE paperly.user_role_assignments 
         SET is_active = false, updated_at = CURRENT_TIMESTAMP 
         WHERE user_id = $1 AND is_active = true`,
        [userId]
      );

      this.logger.info('사용자 역할 제거 완료', { userId, removedBy });
    } catch (error) {
      this.logger.error('사용자 역할 제거 실패', { userId, removedBy, error });
      throw error;
    }
  }

  /**
   * 관리자 권한을 가진 사용자 목록 조회
   * 
   * @returns 관리자 사용자 목록
   */
  async getAdminUsers(): Promise<UserWithRole[]> {
    try {
      const query = `
        SELECT 
          u.id as user_id,
          u.email,
          u.name,
          r.name as role_name,
          r.permissions,
          ura.created_at as role_assigned_at,
          ura.expires_at as role_expires_at
        FROM paperly.users u
        INNER JOIN paperly.user_role_assignments ura ON u.id = ura.user_id AND ura.is_active = true
        INNER JOIN paperly.user_roles r ON ura.role_id = r.id AND r.is_active = true
        WHERE u.status = 'active'
          AND r.name IN ('admin', 'super_admin')
          AND (ura.expires_at IS NULL OR ura.expires_at > CURRENT_TIMESTAMP)
        ORDER BY r.name DESC, u.name ASC
      `;

      const result = await this.db.query(query);
      
      return result.rows.map(row => ({
        userId: row.user_id,
        email: row.email,
        name: row.name,
        role: row.role_name,
        permissions: row.permissions || [],
        roleAssignedAt: row.role_assigned_at,
        roleExpiresAt: row.role_expires_at
      }));
    } catch (error) {
      this.logger.error('관리자 사용자 목록 조회 실패', { error });
      throw error;
    }
  }

  /**
   * 역할별 사용자 수 통계
   * 
   * @returns 역할별 사용자 수
   */
  async getRoleStatistics(): Promise<{ [roleName: string]: number }> {
    try {
      const query = `
        SELECT 
          COALESCE(r.name, 'user') as role_name,
          COUNT(DISTINCT u.id) as user_count
        FROM paperly.users u
        LEFT JOIN paperly.user_role_assignments ura ON u.id = ura.user_id AND ura.is_active = true
        LEFT JOIN paperly.user_roles r ON ura.role_id = r.id AND r.is_active = true
        WHERE u.status = 'active'
          AND (ura.expires_at IS NULL OR ura.expires_at > CURRENT_TIMESTAMP)
        GROUP BY COALESCE(r.name, 'user')
        ORDER BY user_count DESC
      `;

      const result = await this.db.query(query);
      
      const statistics: { [roleName: string]: number } = {};
      result.rows.forEach(row => {
        statistics[row.role_name] = parseInt(row.user_count);
      });

      return statistics;
    } catch (error) {
      this.logger.error('역할 통계 조회 실패', { error });
      throw error;
    }
  }

  /**
   * 특정 역할의 사용자 목록 조회
   * 
   * @param roleName 역할 이름
   * @param offset 페이지네이션 오프셋
   * @param limit 페이지 크기
   * @returns 해당 역할의 사용자 목록
   */
  async getUsersByRole(
    roleName: string, 
    offset = 0, 
    limit = 50
  ): Promise<{ users: UserWithRole[]; total: number }> {
    try {
      // 총 개수 조회
      const countQuery = `
        SELECT COUNT(DISTINCT u.id) as total
        FROM paperly.users u
        LEFT JOIN paperly.user_role_assignments ura ON u.id = ura.user_id AND ura.is_active = true
        LEFT JOIN paperly.user_roles r ON ura.role_id = r.id AND r.is_active = true
        WHERE u.status = 'active'
          AND COALESCE(r.name, 'user') = $1
          AND (ura.expires_at IS NULL OR ura.expires_at > CURRENT_TIMESTAMP)
      `;

      const countResult = await this.db.query(countQuery, [roleName]);
      const total = parseInt(countResult.rows[0].total);

      // 사용자 목록 조회
      const usersQuery = `
        SELECT 
          u.id as user_id,
          u.email,
          u.name,
          COALESCE(r.name, 'user') as role_name,
          COALESCE(r.permissions, '[]'::jsonb) as permissions,
          ura.created_at as role_assigned_at,
          ura.expires_at as role_expires_at
        FROM paperly.users u
        LEFT JOIN paperly.user_role_assignments ura ON u.id = ura.user_id AND ura.is_active = true
        LEFT JOIN paperly.user_roles r ON ura.role_id = r.id AND r.is_active = true
        WHERE u.status = 'active'
          AND COALESCE(r.name, 'user') = $1
          AND (ura.expires_at IS NULL OR ura.expires_at > CURRENT_TIMESTAMP)
        ORDER BY u.name ASC
        LIMIT $2 OFFSET $3
      `;

      const usersResult = await this.db.query(usersQuery, [roleName, limit, offset]);
      
      const users = usersResult.rows.map(row => ({
        userId: row.user_id,
        email: row.email,
        name: row.name,
        role: row.role_name,
        permissions: row.permissions || [],
        roleAssignedAt: row.role_assigned_at,
        roleExpiresAt: row.role_expires_at
      }));

      return { users, total };
    } catch (error) {
      this.logger.error('역할별 사용자 조회 실패', { roleName, offset, limit, error });
      throw error;
    }
  }
}