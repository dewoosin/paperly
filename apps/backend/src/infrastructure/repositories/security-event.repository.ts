// /Users/workspace/paperly/apps/backend/src/infrastructure/repositories/security-event.repository.ts

import { injectable, inject } from 'tsyringe';
import { DatabaseConnection } from '../database/database.connection';
import { Logger } from '../logging/Logger';
import { SecurityEvent, SecurityEventType, SecuritySeverity, SecurityEventStatus } from '../security/monitoring/security-monitor';

/**
 * 보안 이벤트 데이터베이스 접근 리포지토리
 * 
 * SecurityEvent 데이터의 영속성 관리와 조회 기능을 제공합니다.
 * PostgreSQL의 paperly.security_events 테이블을 사용합니다.
 */

export interface SecurityEventFilter {
  type?: SecurityEventType[];
  severity?: SecuritySeverity[];
  status?: SecurityEventStatus[];
  sourceIp?: string;
  userId?: string;
  startDate?: Date;
  endDate?: Date;
  riskScoreMin?: number;
  riskScoreMax?: number;
  endpoint?: string;
}

export interface SecurityEventSearchResult {
  events: SecurityEvent[];
  total: number;
  totalPages: number;
  currentPage: number;
}

export interface SecurityEventStats {
  totalEvents: number;
  eventsByType: { [key: string]: number };
  eventsBySeverity: { [key: string]: number };
  eventsByStatus: { [key: string]: number };
  recentEvents: number; // 최근 24시간
  blockedEvents: number;
  topSourceIPs: Array<{ ip: string; count: number }>;
  topEndpoints: Array<{ endpoint: string; count: number }>;
  riskScoreAverage: number;
  trendData: Array<{ date: string; count: number }>; // 최근 7일 일별 통계
}

@injectable()
export class SecurityEventRepository {
  private readonly logger = new Logger('SecurityEventRepository');

  constructor(@inject(DatabaseConnection) private readonly db: DatabaseConnection) {}

  /**
   * 보안 이벤트 저장
   * 
   * @param event 저장할 보안 이벤트
   * @returns 저장된 이벤트 ID
   */
  async saveEvent(event: SecurityEvent): Promise<string> {
    try {
      const query = `
        INSERT INTO paperly.security_events (
          id, type, severity, status, timestamp, 
          source, source_ip, source_user_id,
          target, target_endpoint,
          details, risk_score, threats,
          response, blocked,
          metadata, created_at, updated_at
        ) VALUES (
          $1, $2, $3, $4, $5,
          $6, $7, $8,
          $9, $10,
          $11, $12, $13,
          $14, $15,
          $16, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        )
        RETURNING id
      `;

      const values = [
        event.id,
        event.type,
        event.severity,
        event.status,
        event.timestamp,
        JSON.stringify(event.source),
        event.source.ip || null,
        event.source.userId || null,
        JSON.stringify(event.target),
        event.target.endpoint || null,
        JSON.stringify(event.details),
        event.details.riskScore || null,
        event.details.threats || [],
        JSON.stringify(event.response),
        event.response?.blocked || false,
        JSON.stringify({}) // 기본 메타데이터
      ];

      const result = await this.db.query(query, values);
      
      this.logger.info('보안 이벤트 저장 완료', { 
        eventId: event.id, 
        type: event.type, 
        severity: event.severity 
      });

      return result.rows[0].id;
    } catch (error) {
      this.logger.error('보안 이벤트 저장 실패', { 
        eventId: event.id, 
        error: error.message 
      });
      throw error;
    }
  }

  /**
   * 보안 이벤트 ID로 조회
   * 
   * @param eventId 이벤트 ID
   * @returns 보안 이벤트 또는 null
   */
  async getEventById(eventId: string): Promise<SecurityEvent | null> {
    try {
      const query = `
        SELECT 
          id, type, severity, status, timestamp,
          source, target, details, response,
          created_at, updated_at
        FROM paperly.security_events 
        WHERE id = $1
      `;

      const result = await this.db.query(query, [eventId]);
      
      if (result.rows.length === 0) {
        return null;
      }

      return this.mapRowToSecurityEvent(result.rows[0]);
    } catch (error) {
      this.logger.error('보안 이벤트 조회 실패', { eventId, error: error.message });
      throw error;
    }
  }

  /**
   * 보안 이벤트 목록 조회 (필터링 및 페이징 지원)
   * 
   * @param filter 필터 조건
   * @param page 페이지 번호 (1부터 시작)
   * @param limit 페이지 크기
   * @returns 보안 이벤트 검색 결과
   */
  async getEvents(
    filter: SecurityEventFilter = {}, 
    page = 1, 
    limit = 50
  ): Promise<SecurityEventSearchResult> {
    try {
      const offset = (page - 1) * limit;
      const { whereClause, params } = this.buildWhereClause(filter);

      // 총 개수 조회
      const countQuery = `
        SELECT COUNT(*) as total
        FROM paperly.security_events 
        ${whereClause}
      `;

      const countResult = await this.db.query(countQuery, params);
      const total = parseInt(countResult.rows[0].total);
      const totalPages = Math.ceil(total / limit);

      // 이벤트 목록 조회
      const eventsQuery = `
        SELECT 
          id, type, severity, status, timestamp,
          source, target, details, response,
          created_at, updated_at
        FROM paperly.security_events 
        ${whereClause}
        ORDER BY timestamp DESC
        LIMIT $${params.length + 1} OFFSET $${params.length + 2}
      `;

      const eventsResult = await this.db.query(eventsQuery, [...params, limit, offset]);
      
      const events = eventsResult.rows.map(row => this.mapRowToSecurityEvent(row));

      return {
        events,
        total,
        totalPages,
        currentPage: page
      };
    } catch (error) {
      this.logger.error('보안 이벤트 목록 조회 실패', { filter, page, limit, error: error.message });
      throw error;
    }
  }

  /**
   * 보안 이벤트 통계 조회
   * 
   * @param days 통계 기간 (일)
   * @returns 보안 이벤트 통계
   */
  async getEventStats(days = 30): Promise<SecurityEventStats> {
    try {
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - days);

      // 기본 통계
      const basicStatsQuery = `
        SELECT 
          COUNT(*) as total_events,
          COUNT(CASE WHEN timestamp >= CURRENT_TIMESTAMP - INTERVAL '24 hours' THEN 1 END) as recent_events,
          COUNT(CASE WHEN blocked = true THEN 1 END) as blocked_events,
          COALESCE(AVG(risk_score), 0) as risk_score_average
        FROM paperly.security_events 
        WHERE timestamp >= $1
      `;

      // 타입별 통계
      const typeStatsQuery = `
        SELECT type, COUNT(*) as count
        FROM paperly.security_events 
        WHERE timestamp >= $1
        GROUP BY type
        ORDER BY count DESC
      `;

      // 심각도별 통계
      const severityStatsQuery = `
        SELECT severity, COUNT(*) as count
        FROM paperly.security_events 
        WHERE timestamp >= $1
        GROUP BY severity
        ORDER BY 
          CASE severity 
            WHEN 'critical' THEN 1 
            WHEN 'high' THEN 2 
            WHEN 'medium' THEN 3 
            WHEN 'low' THEN 4 
          END
      `;

      // 상태별 통계
      const statusStatsQuery = `
        SELECT status, COUNT(*) as count
        FROM paperly.security_events 
        WHERE timestamp >= $1
        GROUP BY status
        ORDER BY count DESC
      `;

      // 상위 IP 주소
      const topIPsQuery = `
        SELECT source_ip as ip, COUNT(*) as count
        FROM paperly.security_events 
        WHERE timestamp >= $1 AND source_ip IS NOT NULL
        GROUP BY source_ip
        ORDER BY count DESC
        LIMIT 10
      `;

      // 상위 엔드포인트
      const topEndpointsQuery = `
        SELECT target_endpoint as endpoint, COUNT(*) as count
        FROM paperly.security_events 
        WHERE timestamp >= $1 AND target_endpoint IS NOT NULL
        GROUP BY target_endpoint
        ORDER BY count DESC
        LIMIT 10
      `;

      // 최근 7일 일별 트렌드
      const trendQuery = `
        SELECT 
          DATE(timestamp) as date,
          COUNT(*) as count
        FROM paperly.security_events 
        WHERE timestamp >= CURRENT_TIMESTAMP - INTERVAL '7 days'
        GROUP BY DATE(timestamp)
        ORDER BY date DESC
      `;

      // 모든 쿼리 실행
      const [
        basicStats,
        typeStats,
        severityStats,
        statusStats,
        topIPs,
        topEndpoints,
        trendData
      ] = await Promise.all([
        this.db.query(basicStatsQuery, [startDate]),
        this.db.query(typeStatsQuery, [startDate]),
        this.db.query(severityStatsQuery, [startDate]),
        this.db.query(statusStatsQuery, [startDate]),
        this.db.query(topIPsQuery, [startDate]),
        this.db.query(topEndpointsQuery, [startDate]),
        this.db.query(trendQuery)
      ]);

      // 결과 구성
      const stats: SecurityEventStats = {
        totalEvents: parseInt(basicStats.rows[0].total_events),
        recentEvents: parseInt(basicStats.rows[0].recent_events),
        blockedEvents: parseInt(basicStats.rows[0].blocked_events),
        riskScoreAverage: parseFloat(basicStats.rows[0].risk_score_average),
        eventsByType: {},
        eventsBySeverity: {},
        eventsByStatus: {},
        topSourceIPs: topIPs.rows.map(row => ({
          ip: row.ip,
          count: parseInt(row.count)
        })),
        topEndpoints: topEndpoints.rows.map(row => ({
          endpoint: row.endpoint,
          count: parseInt(row.count)
        })),
        trendData: trendData.rows.map(row => ({
          date: row.date,
          count: parseInt(row.count)
        }))
      };

      // 각 통계 데이터 매핑
      typeStats.rows.forEach(row => {
        stats.eventsByType[row.type] = parseInt(row.count);
      });

      severityStats.rows.forEach(row => {
        stats.eventsBySeverity[row.severity] = parseInt(row.count);
      });

      statusStats.rows.forEach(row => {
        stats.eventsByStatus[row.status] = parseInt(row.count);
      });

      return stats;
    } catch (error) {
      this.logger.error('보안 이벤트 통계 조회 실패', { days, error: error.message });
      throw error;
    }
  }

  /**
   * 보안 이벤트 상태 업데이트
   * 
   * @param eventId 이벤트 ID
   * @param status 새로운 상태
   * @param updatedBy 업데이트한 사용자 ID
   */
  async updateEventStatus(
    eventId: string, 
    status: SecurityEventStatus, 
    updatedBy?: string
  ): Promise<void> {
    try {
      const query = `
        UPDATE paperly.security_events 
        SET 
          status = $1,
          metadata = metadata || $2,
          updated_at = CURRENT_TIMESTAMP
        WHERE id = $3
      `;

      const metadata = {
        lastUpdatedBy: updatedBy,
        statusUpdatedAt: new Date().toISOString()
      };

      await this.db.query(query, [status, JSON.stringify(metadata), eventId]);
      
      this.logger.info('보안 이벤트 상태 업데이트 완료', { 
        eventId, 
        status, 
        updatedBy 
      });
    } catch (error) {
      this.logger.error('보안 이벤트 상태 업데이트 실패', { 
        eventId, 
        status, 
        updatedBy, 
        error: error.message 
      });
      throw error;
    }
  }

  /**
   * 특정 IP의 최근 이벤트 수 조회
   * 
   * @param ip IP 주소
   * @param hours 시간 범위
   * @returns 이벤트 수
   */
  async getEventCountByIP(ip: string, hours = 24): Promise<number> {
    try {
      const query = `
        SELECT COUNT(*) as count
        FROM paperly.security_events 
        WHERE source_ip = $1 
          AND timestamp >= CURRENT_TIMESTAMP - INTERVAL '${hours} hours'
      `;

      const result = await this.db.query(query, [ip]);
      return parseInt(result.rows[0].count);
    } catch (error) {
      this.logger.error('IP별 이벤트 수 조회 실패', { ip, hours, error: error.message });
      throw error;
    }
  }

  /**
   * 데이터베이스 행을 SecurityEvent 객체로 변환
   */
  private mapRowToSecurityEvent(row: any): SecurityEvent {
    return {
      id: row.id,
      type: row.type,
      severity: row.severity,
      status: row.status,
      timestamp: new Date(row.timestamp),
      source: JSON.parse(row.source),
      target: JSON.parse(row.target),
      details: JSON.parse(row.details),
      response: JSON.parse(row.response)
    };
  }

  /**
   * 필터 조건에서 WHERE 절과 파라미터 생성
   */
  private buildWhereClause(filter: SecurityEventFilter): { whereClause: string; params: any[] } {
    const conditions: string[] = [];
    const params: any[] = [];
    let paramIndex = 1;

    if (filter.type && filter.type.length > 0) {
      conditions.push(`type = ANY($${paramIndex})`);
      params.push(filter.type);
      paramIndex++;
    }

    if (filter.severity && filter.severity.length > 0) {
      conditions.push(`severity = ANY($${paramIndex})`);
      params.push(filter.severity);
      paramIndex++;
    }

    if (filter.status && filter.status.length > 0) {
      conditions.push(`status = ANY($${paramIndex})`);
      params.push(filter.status);
      paramIndex++;
    }

    if (filter.sourceIp) {
      conditions.push(`source_ip = $${paramIndex}`);
      params.push(filter.sourceIp);
      paramIndex++;
    }

    if (filter.userId) {
      conditions.push(`source_user_id = $${paramIndex}`);
      params.push(filter.userId);
      paramIndex++;
    }

    if (filter.startDate) {
      conditions.push(`timestamp >= $${paramIndex}`);
      params.push(filter.startDate);
      paramIndex++;
    }

    if (filter.endDate) {
      conditions.push(`timestamp <= $${paramIndex}`);
      params.push(filter.endDate);
      paramIndex++;
    }

    if (filter.riskScoreMin !== undefined) {
      conditions.push(`risk_score >= $${paramIndex}`);
      params.push(filter.riskScoreMin);
      paramIndex++;
    }

    if (filter.riskScoreMax !== undefined) {
      conditions.push(`risk_score <= $${paramIndex}`);
      params.push(filter.riskScoreMax);
      paramIndex++;
    }

    if (filter.endpoint) {
      conditions.push(`target_endpoint ILIKE $${paramIndex}`);
      params.push(`%${filter.endpoint}%`);
      paramIndex++;
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    return { whereClause, params };
  }
}