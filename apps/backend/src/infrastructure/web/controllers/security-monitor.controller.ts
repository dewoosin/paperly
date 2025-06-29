// /Users/workspace/paperly/apps/backend/src/infrastructure/web/controllers/security-monitor.controller.ts

import { Request, Response } from 'express';
import { injectable, inject } from 'tsyringe';
import { SecurityMonitor } from '../../security/monitoring/security-monitor';
import { Logger } from '../../logging/Logger';
import { ValidationError } from '../../../shared/errors';

/**
 * 보안 모니터링 컨트롤러
 * 
 * 보안 이벤트 조회, 통계, 관리 기능을 제공하는 API 컨트롤러입니다.
 * 관리자 권한이 필요한 보안 관련 엔드포인트를 처리합니다.
 */

@injectable()
export class SecurityMonitorController {
  private readonly logger = new Logger('SecurityMonitorController');

  constructor(
    @inject(SecurityMonitor) private readonly securityMonitor: SecurityMonitor
  ) {}

  /**
   * 보안 이벤트 목록 조회
   * 
   * GET /admin/security/events
   * 
   * @param req Express Request
   * @param res Express Response
   */
  async getSecurityEvents(req: Request, res: Response): Promise<void> {
    try {
      const { 
        page = 1, 
        limit = 50, 
        severity, 
        type, 
        status,
        startDate,
        endDate,
        ip 
      } = req.query;

      // 페이지네이션 검증
      const pageNum = Math.max(1, parseInt(page as string) || 1);
      const limitNum = Math.min(100, Math.max(1, parseInt(limit as string) || 50));
      const offset = (pageNum - 1) * limitNum;

      // 필터 조건 구성
      const filters: any = {};
      
      if (severity) filters.severity = severity;
      if (type) filters.type = type;
      if (status) filters.status = status;
      if (ip) filters.ip = ip;

      // 날짜 범위 필터
      if (startDate) {
        filters.startDate = new Date(startDate as string);
      }
      if (endDate) {
        filters.endDate = new Date(endDate as string);
      }

      // 보안 이벤트 조회 (DB에서)
      const result = await this.securityMonitor.getSecurityEvents(filters, pageNum, limitNum);

      res.status(200).json({
        success: true,
        data: {
          events: result.events,
          pagination: {
            page: result.currentPage,
            limit: limitNum,
            total: result.total,
            totalPages: result.totalPages,
            hasNext: result.currentPage < result.totalPages,
            hasPrev: result.currentPage > 1
          }
        },
        message: '보안 이벤트 목록 조회가 완료되었습니다'
      });

      this.logger.info('보안 이벤트 목록 조회 완료', {
        adminUserId: req.user?.userId,
        filters,
        page: pageNum,
        limit: limitNum,
        totalEvents: result.total
      });
    } catch (error) {
      this.logger.error('보안 이벤트 목록 조회 오류', { error });
      
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_SERVER_ERROR',
          message: '서버 오류가 발생했습니다'
        }
      });
    }
  }

  /**
   * 보안 이벤트 상세 조회
   * 
   * GET /admin/security/events/:eventId
   * 
   * @param req Express Request
   * @param res Express Response
   */
  async getSecurityEvent(req: Request, res: Response): Promise<void> {
    try {
      const { eventId } = req.params;

      if (!eventId) {
        throw new ValidationError('이벤트 ID는 필수입니다');
      }

      const event = await this.securityMonitor.getSecurityEvent(eventId);

      if (!event) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'NOT_FOUND',
            message: '보안 이벤트를 찾을 수 없습니다'
          }
        });
      }

      res.status(200).json({
        success: true,
        data: event,
        message: '보안 이벤트 상세 조회가 완료되었습니다'
      });
    } catch (error) {
      this.logger.error('보안 이벤트 상세 조회 오류', { error });

      if (error instanceof ValidationError) {
        res.status(400).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: error.message
          }
        });
      } else {
        res.status(500).json({
          success: false,
          error: {
            code: 'INTERNAL_SERVER_ERROR',
            message: '서버 오류가 발생했습니다'
          }
        });
      }
    }
  }

  /**
   * 보안 통계 조회
   * 
   * GET /admin/security/stats
   * 
   * @param req Express Request
   * @param res Express Response
   */
  async getSecurityStats(req: Request, res: Response): Promise<void> {
    try {
      const { 
        period = '24h',
        startDate,
        endDate 
      } = req.query;

      // 기간 설정
      let start: Date, end: Date;
      
      if (startDate && endDate) {
        start = new Date(startDate as string);
        end = new Date(endDate as string);
      } else {
        end = new Date();
        switch (period) {
          case '1h':
            start = new Date(end.getTime() - 60 * 60 * 1000);
            break;
          case '24h':
            start = new Date(end.getTime() - 24 * 60 * 60 * 1000);
            break;
          case '7d':
            start = new Date(end.getTime() - 7 * 24 * 60 * 60 * 1000);
            break;
          case '30d':
            start = new Date(end.getTime() - 30 * 24 * 60 * 60 * 1000);
            break;
          default:
            start = new Date(end.getTime() - 24 * 60 * 60 * 1000);
        }
      }

      // 보안 통계 데이터 수집 (DB에서)
      let days = 1;
      switch (period) {
        case '1h':
          days = 1;
          break;
        case '24h':
          days = 1;
          break;
        case '7d':
          days = 7;
          break;
        case '30d':
          days = 30;
          break;
        default:
          days = 1;
      }
      const stats = await this.securityMonitor.getSecurityStatistics(days);

      res.status(200).json({
        success: true,
        data: {
          overview: stats,
          topAttackers: stats.topSourceIPs || [],
          topTargets: stats.topEndpoints || [],
          timeline: stats.trendData || [],
          riskAnalysis: {
            averageRiskScore: stats.riskScoreAverage,
            totalEvents: stats.totalEvents,
            recentEvents: stats.recentEvents,
            blockedEvents: stats.blockedEvents
          },
          period: {
            start: start.toISOString(),
            end: end.toISOString(),
            label: period
          }
        },
        message: '보안 통계 조회가 완료되었습니다'
      });

      this.logger.info('보안 통계 조회 완료', {
        adminUserId: req.user?.userId,
        period,
        start: start.toISOString(),
        end: end.toISOString()
      });
    } catch (error) {
      this.logger.error('보안 통계 조회 오류', { error });

      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_SERVER_ERROR',
          message: '서버 오류가 발생했습니다'
        }
      });
    }
  }

  /**
   * IP 차단 관리
   * 
   * POST /admin/security/block-ip
   * 
   * @param req Express Request
   * @param res Express Response
   */
  async blockIP(req: Request, res: Response): Promise<void> {
    try {
      const { ip, reason, duration } = req.body;
      const adminUserId = req.user?.userId;

      if (!ip || !reason) {
        throw new ValidationError('IP 주소와 차단 사유는 필수입니다');
      }

      // IP 주소 형식 검증
      const ipPattern = /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;
      if (!ipPattern.test(ip)) {
        throw new ValidationError('유효하지 않은 IP 주소 형식입니다');
      }

      // IP 차단 실행
      this.securityMonitor.blockIP(ip, reason, duration);

      // 관리 로그 기록
      this.logger.info('IP 차단 실행', {
        adminUserId,
        blockedIP: ip,
        reason,
        duration
      });

      res.status(200).json({
        success: true,
        message: `IP ${ip}가 성공적으로 차단되었습니다`
      });
    } catch (error) {
      this.logger.error('IP 차단 오류', { error });

      if (error instanceof ValidationError) {
        res.status(400).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: error.message
          }
        });
      } else {
        res.status(500).json({
          success: false,
          error: {
            code: 'INTERNAL_SERVER_ERROR',
            message: '서버 오류가 발생했습니다'
          }
        });
      }
    }
  }

  /**
   * IP 차단 해제
   * 
   * DELETE /admin/security/unblock-ip/:ip
   * 
   * @param req Express Request
   * @param res Express Response
   */
  async unblockIP(req: Request, res: Response): Promise<void> {
    try {
      const { ip } = req.params;
      const adminUserId = req.user?.userId;

      if (!ip) {
        throw new ValidationError('IP 주소는 필수입니다');
      }

      // IP 차단 해제
      this.securityMonitor.unblockIP(ip);

      // 관리 로그 기록
      this.logger.info('IP 차단 해제', {
        adminUserId,
        unblockedIP: ip
      });

      res.status(200).json({
        success: true,
        message: `IP ${ip}의 차단이 해제되었습니다`
      });
    } catch (error) {
      this.logger.error('IP 차단 해제 오류', { error });

      if (error instanceof ValidationError) {
        res.status(400).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: error.message
          }
        });
      } else {
        res.status(500).json({
          success: false,
          error: {
            code: 'INTERNAL_SERVER_ERROR',
            message: '서버 오류가 발생했습니다'
          }
        });
      }
    }
  }

  /**
   * 차단된 IP 목록 조회
   * 
   * GET /admin/security/blocked-ips
   * 
   * @param req Express Request
   * @param res Response
   */
  async getBlockedIPs(req: Request, res: Response): Promise<void> {
    try {
      const blockedIPs = this.securityMonitor.getBlockedIPs();

      res.status(200).json({
        success: true,
        data: blockedIPs,
        message: '차단된 IP 목록 조회가 완료되었습니다'
      });
    } catch (error) {
      this.logger.error('차단된 IP 목록 조회 오류', { error });

      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_SERVER_ERROR',
          message: '서버 오류가 발생했습니다'
        }
      });
    }
  }

  /**
   * 보안 이벤트 상태 업데이트
   * 
   * PATCH /admin/security/events/:eventId/status
   * 
   * @param req Express Request
   * @param res Express Response
   */
  async updateEventStatus(req: Request, res: Response): Promise<void> {
    try {
      const { eventId } = req.params;
      const { status, notes } = req.body;
      const adminUserId = req.user?.userId;

      if (!eventId || !status) {
        throw new ValidationError('이벤트 ID와 상태는 필수입니다');
      }

      // 유효한 상태 확인
      const validStatuses = ['detected', 'investigating', 'blocked', 'resolved', 'false_positive'];
      if (!validStatuses.includes(status)) {
        throw new ValidationError(`유효하지 않은 상태입니다. 가능한 상태: ${validStatuses.join(', ')}`);
      }

      // 이벤트 상태 업데이트
      const updated = this.securityMonitor.updateEventStatus(eventId, status, adminUserId, notes);

      if (!updated) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'NOT_FOUND',
            message: '보안 이벤트를 찾을 수 없습니다'
          }
        });
      }

      this.logger.info('보안 이벤트 상태 업데이트', {
        adminUserId,
        eventId,
        newStatus: status,
        notes
      });

      res.status(200).json({
        success: true,
        message: '보안 이벤트 상태가 업데이트되었습니다'
      });
    } catch (error) {
      this.logger.error('보안 이벤트 상태 업데이트 오류', { error });

      if (error instanceof ValidationError) {
        res.status(400).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: error.message
          }
        });
      } else {
        res.status(500).json({
          success: false,
          error: {
            code: 'INTERNAL_SERVER_ERROR',
            message: '서버 오류가 발생했습니다'
          }
        });
      }
    }
  }

  /**
   * 실시간 보안 이벤트 스트림
   * 
   * GET /admin/security/events/stream
   * 
   * @param req Express Request
   * @param res Express Response
   */
  async getEventStream(req: Request, res: Response): Promise<void> {
    try {
      // SSE 헤더 설정
      res.writeHead(200, {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Cache-Control'
      });

      // 이벤트 리스너 등록
      const eventListener = (event: any) => {
        res.write(`data: ${JSON.stringify(event)}\n\n`);
      };

      this.securityMonitor.on('securityEvent', eventListener);

      // 클라이언트 연결 종료 시 리스너 제거
      req.on('close', () => {
        this.securityMonitor.off('securityEvent', eventListener);
      });

      // Keep-alive 핑
      const keepAlive = setInterval(() => {
        res.write(': keep-alive\n\n');
      }, 30000);

      req.on('close', () => {
        clearInterval(keepAlive);
      });

      this.logger.info('보안 이벤트 실시간 스트림 시작', {
        adminUserId: req.user?.userId
      });
    } catch (error) {
      this.logger.error('보안 이벤트 스트림 오류', { error });
      
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_SERVER_ERROR',
          message: '스트림 연결에 실패했습니다'
        }
      });
    }
  }
}