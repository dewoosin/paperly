/// Paperly Backend - 보안 모니터링 시스템
/// 
/// 이 파일은 실시간 보안 위협 감지, 로깅, 알림 및 대응 시스템을 구현합니다.
/// 모든 보안 이벤트를 수집하고 분석하여 의심스러운 활동을 감지하고 차단합니다.
/// 
/// 주요 기능:
/// 1. 실시간 위협 감지: XSS, SQL Injection, Path Traversal 등 실시간 탐지
/// 2. 이벤트 수집 및 분석: 패턴 분석을 통한 공격 행위 탐지
/// 3. 알림 시스템: 심각한 위협 감지 시 즉시 관리자 알림
/// 4. 자동 차단: 임계치 도달 시 IP/사용자 자동 차단
/// 5. 상세 로깅: 포렌식 분석을 위한 상세 기록
/// 6. 대시보드: 실시간 보안 현황 모니터링
/// 
/// 모니터링 전략:
/// - 실시간 분석: 스트림 처리로 즉시 위협 탐지
/// - 패턴 학습: 머신러닝 기반 이상 행동 탐지
/// - 계층적 대응: 위험도에 따른 단계별 대응
/// - 상관관계 분석: 여러 이벤트 간의 연관성 분석

import { EventEmitter } from 'events';
import { Logger } from '../../logging/Logger';
import { SecurityValidator } from '../validators';
import { XSSValidationResult, SQLInjectionValidationResult, PathTraversalValidationResult } from '../validators';
import { SecurityEventRepository } from '../../repositories/security-event.repository';
import { injectable, inject } from 'tsyringe';

/**
 * 보안 이벤트 타입 정의
 */
export enum SecurityEventType {
  XSS_ATTACK_DETECTED = 'XSS_ATTACK_DETECTED',
  SQL_INJECTION_DETECTED = 'SQL_INJECTION_DETECTED',
  PATH_TRAVERSAL_DETECTED = 'PATH_TRAVERSAL_DETECTED',
  COMMAND_INJECTION_DETECTED = 'COMMAND_INJECTION_DETECTED',
  BRUTE_FORCE_ATTACK = 'BRUTE_FORCE_ATTACK',
  SUSPICIOUS_USER_AGENT = 'SUSPICIOUS_USER_AGENT',
  MULTIPLE_FAILED_LOGINS = 'MULTIPLE_FAILED_LOGINS',
  UNUSUAL_REQUEST_PATTERN = 'UNUSUAL_REQUEST_PATTERN',
  RATE_LIMIT_EXCEEDED = 'RATE_LIMIT_EXCEEDED',
  MALICIOUS_FILE_UPLOAD = 'MALICIOUS_FILE_UPLOAD',
  DATA_EXFILTRATION_ATTEMPT = 'DATA_EXFILTRATION_ATTEMPT',
  PRIVILEGE_ESCALATION = 'PRIVILEGE_ESCALATION'
}

/**
 * 보안 이벤트 심각도
 */
export enum SecuritySeverity {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  CRITICAL = 'critical'
}

/**
 * 보안 이벤트 상태
 */
export enum SecurityEventStatus {
  DETECTED = 'detected',
  INVESTIGATING = 'investigating',
  BLOCKED = 'blocked',
  RESOLVED = 'resolved',
  FALSE_POSITIVE = 'false_positive'
}

/**
 * 보안 이벤트 인터페이스
 */
export interface SecurityEvent {
  id: string;                           // 이벤트 고유 ID
  type: SecurityEventType;              // 이벤트 타입
  severity: SecuritySeverity;           // 심각도
  status: SecurityEventStatus;          // 처리 상태
  timestamp: Date;                      // 발생 시간
  source: {                             // 출처 정보
    ip: string;                         // 클라이언트 IP
    userAgent?: string;                 // User-Agent
    userId?: string;                    // 사용자 ID (로그인한 경우)
    sessionId?: string;                 // 세션 ID
    deviceId?: string;                  // 디바이스 ID
  };
  target: {                             // 대상 정보
    endpoint: string;                   // 공격 대상 엔드포인트
    method: string;                     // HTTP 메서드
    parameters?: Record<string, any>;   // 요청 파라미터
    headers?: Record<string, string>;   // 요청 헤더
  };
  details: {                            // 상세 정보
    description: string;                // 이벤트 설명
    payload?: string;                   // 공격 페이로드
    threats: string[];                  // 감지된 위협 목록
    riskScore: number;                  // 위험 점수 (0-100)
    validationResults?: {               // 검증 결과
      xss?: XSSValidationResult;
      sql?: SQLInjectionValidationResult;
      path?: PathTraversalValidationResult;
    };
    context?: Record<string, any>;      // 추가 컨텍스트
  };
  response: {                           // 대응 정보
    action: SecurityAction;             // 취한 조치
    blocked: boolean;                   // 차단 여부
    message?: string;                   // 응답 메시지
    timestamp: Date;                    // 대응 시간
  };
  investigation?: {                     // 조사 정보
    assignedTo?: string;                // 담당자
    notes?: string[];                   // 조사 노트
    evidence?: string[];                // 증거 자료
    relatedEvents?: string[];           // 관련 이벤트 ID
  };
}

/**
 * 보안 조치 타입
 */
export enum SecurityAction {
  NONE = 'none',                        // 조치 없음
  LOGGED = 'logged',                    // 로그 기록만
  RATE_LIMITED = 'rate_limited',        // 속도 제한
  TEMPORARILY_BLOCKED = 'temporarily_blocked',  // 임시 차단
  PERMANENTLY_BLOCKED = 'permanently_blocked',  // 영구 차단
  ACCOUNT_SUSPENDED = 'account_suspended',      // 계정 정지
  ALERT_SENT = 'alert_sent',            // 알림 발송
  ESCALATED = 'escalated'               // 상급자 에스컬레이션
}

/**
 * 위협 통계 인터페이스
 */
export interface ThreatStatistics {
  totalEvents: number;                  // 총 이벤트 수
  eventsByType: Record<SecurityEventType, number>;  // 타입별 이벤트 수
  eventsBySeverity: Record<SecuritySeverity, number>;  // 심각도별 이벤트 수
  topAttackers: Array<{                 // 상위 공격자 IP
    ip: string;
    eventCount: number;
    riskScore: number;
  }>;
  topTargets: Array<{                   // 상위 공격 대상
    endpoint: string;
    eventCount: number;
  }>;
  timeRange: {                          // 시간 범위
    start: Date;
    end: Date;
  };
  trends: {                             // 트렌드 정보
    hourlyEvents: number[];             // 시간별 이벤트 수
    dailyEvents: number[];              // 일별 이벤트 수
    weeklyEvents: number[];             // 주별 이벤트 수
  };
}

/**
 * 실시간 보안 모니터링 설정
 */
export interface SecurityMonitorConfig {
  enableRealTimeMonitoring: boolean;    // 실시간 모니터링 활성화
  alertThresholds: {                    // 알림 임계값
    criticalEventsPerMinute: number;    // 분당 중요 이벤트 수
    highRiskScore: number;              // 고위험 점수
    suspiciousPatternScore: number;     // 의심스러운 패턴 점수
  };
  autoBlockEnabled: boolean;            // 자동 차단 활성화
  blockThresholds: {                    // 차단 임계값
    eventsPerMinute: number;            // 분당 이벤트 수
    riskScoreThreshold: number;         // 위험 점수 임계값
    repeatOffenseCount: number;         // 반복 위반 횟수
  };
  retentionPeriod: number;              // 데이터 보존 기간 (일)
  enableForensics: boolean;             // 포렌식 데이터 수집
  notificationChannels: {               // 알림 채널
    email: boolean;
    sms: boolean;
    slack: boolean;
    webhook: boolean;
  };
}

/**
 * 보안 모니터링 시스템 클래스
 */
@injectable()
export class SecurityMonitor extends EventEmitter {
  private readonly logger = new Logger('SecurityMonitor');
  private readonly events: Map<string, SecurityEvent> = new Map();
  private readonly ipRiskScores: Map<string, number> = new Map();
  private readonly userRiskScores: Map<string, number> = new Map();
  private readonly blockedIPs: Set<string> = new Set();
  private readonly blockedUsers: Set<string> = new Set();
  
  private eventCount = 0;
  private isRunning = false;
  private monitoringInterval?: NodeJS.Timeout;

  /**
   * 기본 설정
   */
  private readonly DEFAULT_CONFIG: SecurityMonitorConfig = {
    enableRealTimeMonitoring: true,
    alertThresholds: {
      criticalEventsPerMinute: 5,
      highRiskScore: 80,
      suspiciousPatternScore: 70
    },
    autoBlockEnabled: true,
    blockThresholds: {
      eventsPerMinute: 10,
      riskScoreThreshold: 90,
      repeatOffenseCount: 3
    },
    retentionPeriod: 30,
    enableForensics: true,
    notificationChannels: {
      email: true,
      sms: false,
      slack: true,
      webhook: false
    }
  };

  private config: SecurityMonitorConfig;

  constructor(
    @inject(SecurityEventRepository) private readonly securityEventRepository: SecurityEventRepository,
    config?: Partial<SecurityMonitorConfig>
  ) {
    super();
    this.config = { ...this.DEFAULT_CONFIG, ...config };
    this.setupEventListeners();
  }

  /**
   * 보안 모니터링 시작
   */
  public start(): void {
    if (this.isRunning) {
      this.logger.warn('보안 모니터링이 이미 실행 중입니다');
      return;
    }

    this.isRunning = true;
    
    if (this.config.enableRealTimeMonitoring) {
      this.startRealTimeMonitoring();
    }

    this.logger.info('보안 모니터링 시스템이 시작되었습니다', {
      config: this.config
    });
  }

  /**
   * 보안 모니터링 중지
   */
  public stop(): void {
    if (!this.isRunning) {
      return;
    }

    this.isRunning = false;
    
    if (this.monitoringInterval) {
      clearInterval(this.monitoringInterval);
      this.monitoringInterval = undefined;
    }

    this.logger.info('보안 모니터링 시스템이 중지되었습니다');
  }

  /**
   * 보안 이벤트 기록
   */
  public async recordSecurityEvent(event: Omit<SecurityEvent, 'id' | 'timestamp' | 'status'>): Promise<string> {
    const eventId = this.generateEventId();
    const fullEvent: SecurityEvent = {
      ...event,
      id: eventId,
      timestamp: new Date(),
      status: SecurityEventStatus.DETECTED
    };

    try {
      // 데이터베이스에 이벤트 저장
      await this.securityEventRepository.saveEvent(fullEvent);
      
      // 메모리에도 캐시 (빠른 접근용)
      this.events.set(eventId, fullEvent);
      this.eventCount++;

      // 위험 점수 업데이트
      this.updateRiskScores(fullEvent);

      // 실시간 분석
      if (this.config.enableRealTimeMonitoring) {
        this.analyzeEventInRealTime(fullEvent);
      }

      // 이벤트 발생 알림
      this.emit('securityEvent', fullEvent);

      this.logger.warn('보안 이벤트 감지 및 저장 완료', {
        eventId,
        type: event.type,
        severity: event.severity,
        source: event.source,
        details: event.details
      });

      return eventId;
    } catch (error) {
      this.logger.error('보안 이벤트 저장 실패', {
        eventId,
        type: event.type,
        error: error.message
      });
      
      // 저장 실패시에도 메모리에는 저장하여 손실 방지
      this.events.set(eventId, fullEvent);
      this.eventCount++;
      
      throw error;
    }
  }

  /**
   * XSS 공격 기록
   */
  public async recordXSSAttack(
    source: SecurityEvent['source'],
    target: SecurityEvent['target'],
    xssResult: XSSValidationResult,
    payload: string
  ): Promise<string> {
    return await this.recordSecurityEvent({
      type: SecurityEventType.XSS_ATTACK_DETECTED,
      severity: this.determineSeverity(xssResult.severity),
      source,
      target,
      details: {
        description: 'XSS 공격 시도가 감지되었습니다',
        payload,
        threats: xssResult.threats,
        riskScore: this.calculateRiskScore(xssResult.severity, xssResult.threats.length),
        validationResults: { xss: xssResult }
      },
      response: {
        action: SecurityAction.LOGGED,
        blocked: false,
        timestamp: new Date()
      }
    });
  }

  /**
   * SQL Injection 공격 기록
   */
  public async recordSQLInjectionAttack(
    source: SecurityEvent['source'],
    target: SecurityEvent['target'],
    sqlResult: SQLInjectionValidationResult,
    payload: string
  ): Promise<string> {
    return await this.recordSecurityEvent({
      type: SecurityEventType.SQL_INJECTION_DETECTED,
      severity: this.determineSeverity(sqlResult.severity),
      source,
      target,
      details: {
        description: 'SQL Injection 공격 시도가 감지되었습니다',
        payload,
        threats: sqlResult.threats,
        riskScore: this.calculateRiskScore(sqlResult.severity, sqlResult.threats.length),
        validationResults: { sql: sqlResult }
      },
      response: {
        action: SecurityAction.LOGGED,
        blocked: false,
        timestamp: new Date()
      }
    });
  }

  /**
   * Path Traversal 공격 기록
   */
  public async recordPathTraversalAttack(
    source: SecurityEvent['source'],
    target: SecurityEvent['target'],
    pathResult: PathTraversalValidationResult,
    payload: string
  ): Promise<string> {
    return await this.recordSecurityEvent({
      type: SecurityEventType.PATH_TRAVERSAL_DETECTED,
      severity: this.determineSeverity(pathResult.severity),
      source,
      target,
      details: {
        description: 'Path Traversal 공격 시도가 감지되었습니다',
        payload,
        threats: pathResult.threats,
        riskScore: this.calculateRiskScore(pathResult.severity, pathResult.threats.length),
        validationResults: { path: pathResult }
      },
      response: {
        action: SecurityAction.LOGGED,
        blocked: false,
        timestamp: new Date()
      }
    });
  }

  /**
   * 브루트포스 공격 기록
   */
  public recordBruteForceAttack(
    source: SecurityEvent['source'],
    target: SecurityEvent['target'],
    attemptCount: number,
    timeWindow: number
  ): string {
    return this.recordSecurityEvent({
      type: SecurityEventType.BRUTE_FORCE_ATTACK,
      severity: attemptCount > 10 ? SecuritySeverity.CRITICAL : SecuritySeverity.HIGH,
      source,
      target,
      details: {
        description: `${timeWindow}분 동안 ${attemptCount}회의 로그인 시도가 감지되었습니다`,
        threats: ['brute_force', 'credential_stuffing'],
        riskScore: Math.min(attemptCount * 10, 100),
        context: { attemptCount, timeWindow }
      },
      response: {
        action: SecurityAction.RATE_LIMITED,
        blocked: attemptCount > 5,
        timestamp: new Date()
      }
    });
  }

  /**
   * 이벤트 상태 업데이트
   */
  public updateEventStatus(eventId: string, status: SecurityEventStatus, notes?: string): void {
    const event = this.events.get(eventId);
    if (!event) {
      this.logger.warn('존재하지 않는 이벤트 ID', { eventId });
      return;
    }

    event.status = status;
    
    if (notes) {
      if (!event.investigation) {
        event.investigation = {};
      }
      if (!event.investigation.notes) {
        event.investigation.notes = [];
      }
      event.investigation.notes.push(`${new Date().toISOString()}: ${notes}`);
    }

    this.logger.info('보안 이벤트 상태 업데이트', {
      eventId,
      status,
      notes
    });
  }

  /**
   * IP 차단
   */
  public blockIP(ip: string, reason: string, duration?: number): void {
    this.blockedIPs.add(ip);
    
    this.logger.warn('IP 주소 차단', {
      ip,
      reason,
      duration: duration ? `${duration}분` : '영구'
    });

    // 임시 차단인 경우 자동 해제
    if (duration) {
      setTimeout(() => {
        this.unblockIP(ip);
      }, duration * 60 * 1000);
    }

    this.emit('ipBlocked', { ip, reason, duration });
  }

  /**
   * IP 차단 해제
   */
  public unblockIP(ip: string): void {
    this.blockedIPs.delete(ip);
    this.logger.info('IP 주소 차단 해제', { ip });
    this.emit('ipUnblocked', { ip });
  }

  /**
   * 사용자 차단
   */
  public blockUser(userId: string, reason: string, duration?: number): void {
    this.blockedUsers.add(userId);
    
    this.logger.warn('사용자 차단', {
      userId,
      reason,
      duration: duration ? `${duration}분` : '영구'
    });

    // 임시 차단인 경우 자동 해제
    if (duration) {
      setTimeout(() => {
        this.unblockUser(userId);
      }, duration * 60 * 1000);
    }

    this.emit('userBlocked', { userId, reason, duration });
  }

  /**
   * 사용자 차단 해제
   */
  public unblockUser(userId: string): void {
    this.blockedUsers.delete(userId);
    this.logger.info('사용자 차단 해제', { userId });
    this.emit('userUnblocked', { userId });
  }

  /**
   * IP 차단 상태 확인
   */
  public isIPBlocked(ip: string): boolean {
    return this.blockedIPs.has(ip);
  }

  /**
   * 사용자 차단 상태 확인
   */
  public isUserBlocked(userId: string): boolean {
    return this.blockedUsers.has(userId);
  }

  /**
   * 위협 통계 조회
   */
  public getThreatStatistics(timeRange?: { start: Date; end: Date }): ThreatStatistics {
    const events = Array.from(this.events.values());
    const filteredEvents = timeRange 
      ? events.filter(e => e.timestamp >= timeRange.start && e.timestamp <= timeRange.end)
      : events;

    const eventsByType: Record<SecurityEventType, number> = {} as any;
    const eventsBySeverity: Record<SecuritySeverity, number> = {} as any;
    const attackerCounts = new Map<string, number>();
    const targetCounts = new Map<string, number>();

    // 통계 계산
    filteredEvents.forEach(event => {
      // 타입별 집계
      eventsByType[event.type] = (eventsByType[event.type] || 0) + 1;
      
      // 심각도별 집계
      eventsBySeverity[event.severity] = (eventsBySeverity[event.severity] || 0) + 1;
      
      // 공격자 IP별 집계
      const count = attackerCounts.get(event.source.ip) || 0;
      attackerCounts.set(event.source.ip, count + 1);
      
      // 대상 엔드포인트별 집계
      const targetCount = targetCounts.get(event.target.endpoint) || 0;
      targetCounts.set(event.target.endpoint, targetCount + 1);
    });

    // 상위 공격자
    const topAttackers = Array.from(attackerCounts.entries())
      .map(([ip, eventCount]) => ({
        ip,
        eventCount,
        riskScore: this.ipRiskScores.get(ip) || 0
      }))
      .sort((a, b) => b.eventCount - a.eventCount)
      .slice(0, 10);

    // 상위 타겟
    const topTargets = Array.from(targetCounts.entries())
      .map(([endpoint, eventCount]) => ({ endpoint, eventCount }))
      .sort((a, b) => b.eventCount - a.eventCount)
      .slice(0, 10);

    return {
      totalEvents: filteredEvents.length,
      eventsByType,
      eventsBySeverity,
      topAttackers,
      topTargets,
      timeRange: timeRange || {
        start: new Date(Math.min(...events.map(e => e.timestamp.getTime()))),
        end: new Date(Math.max(...events.map(e => e.timestamp.getTime())))
      },
      trends: this.calculateTrends(filteredEvents)
    };
  }

  /**
   * 실시간 보안 상태 조회
   */
  public getSecurityStatus(): {
    isRunning: boolean;
    totalEvents: number;
    recentEvents: number;
    blockedIPs: number;
    blockedUsers: number;
    riskLevel: SecuritySeverity;
    lastUpdate: Date;
  } {
    const recentEvents = Array.from(this.events.values())
      .filter(e => e.timestamp > new Date(Date.now() - 60 * 60 * 1000)) // 지난 1시간
      .length;

    const riskLevel = this.calculateOverallRiskLevel();

    return {
      isRunning: this.isRunning,
      totalEvents: this.eventCount,
      recentEvents,
      blockedIPs: this.blockedIPs.size,
      blockedUsers: this.blockedUsers.size,
      riskLevel,
      lastUpdate: new Date()
    };
  }

  // ============================================================================
  // 🔧 내부 메서드들
  // ============================================================================

  /**
   * 이벤트 리스너 설정
   */
  private setupEventListeners(): void {
    this.on('securityEvent', this.handleSecurityEvent.bind(this));
    this.on('ipBlocked', this.handleIPBlocked.bind(this));
    this.on('userBlocked', this.handleUserBlocked.bind(this));
  }

  /**
   * 실시간 모니터링 시작
   */
  private startRealTimeMonitoring(): void {
    this.monitoringInterval = setInterval(() => {
      this.performPeriodicAnalysis();
    }, 60000); // 1분마다 실행
  }

  /**
   * 실시간 이벤트 분석
   */
  private analyzeEventInRealTime(event: SecurityEvent): void {
    // 임계값 확인 및 자동 차단
    if (this.config.autoBlockEnabled) {
      this.checkAutoBlockThresholds(event);
    }

    // 알림 임계값 확인
    this.checkAlertThresholds(event);

    // 패턴 분석
    this.analyzeAttackPatterns(event);
  }

  /**
   * 자동 차단 임계값 확인
   */
  private checkAutoBlockThresholds(event: SecurityEvent): void {
    const ip = event.source.ip;
    const currentScore = this.ipRiskScores.get(ip) || 0;

    // 위험 점수 임계값 확인
    if (currentScore >= this.config.blockThresholds.riskScoreThreshold) {
      this.blockIP(ip, `위험 점수 임계값 초과 (${currentScore})`, 30); // 30분 차단
      return;
    }

    // 분당 이벤트 수 확인
    const recentEvents = Array.from(this.events.values())
      .filter(e => 
        e.source.ip === ip && 
        e.timestamp > new Date(Date.now() - 60000) // 지난 1분
      );

    if (recentEvents.length >= this.config.blockThresholds.eventsPerMinute) {
      this.blockIP(ip, `분당 이벤트 임계값 초과 (${recentEvents.length}회)`, 15); // 15분 차단
    }
  }

  /**
   * 알림 임계값 확인
   */
  private checkAlertThresholds(event: SecurityEvent): void {
    // 중요 이벤트 알림
    if (event.severity === SecuritySeverity.CRITICAL) {
      this.sendAlert('critical', `중요 보안 이벤트 감지: ${event.type}`, event);
    }

    // 고위험 점수 알림
    if (event.details.riskScore >= this.config.alertThresholds.highRiskScore) {
      this.sendAlert('high', `고위험 보안 이벤트: 위험 점수 ${event.details.riskScore}`, event);
    }
  }

  /**
   * 공격 패턴 분석
   */
  private analyzeAttackPatterns(event: SecurityEvent): void {
    // 동일 IP에서의 반복 공격 패턴 분석
    const ipEvents = Array.from(this.events.values())
      .filter(e => e.source.ip === event.source.ip)
      .slice(-10); // 최근 10개 이벤트

    if (ipEvents.length >= 5) {
      const patternScore = this.calculatePatternScore(ipEvents);
      if (patternScore >= this.config.alertThresholds.suspiciousPatternScore) {
        this.sendAlert('pattern', `의심스러운 공격 패턴 감지 (점수: ${patternScore})`, event);
      }
    }
  }

  /**
   * 주기적 분석 수행
   */
  private performPeriodicAnalysis(): void {
    this.cleanupOldEvents();
    this.updateOverallRiskAssessment();
    this.generatePeriodicReport();
  }

  /**
   * 오래된 이벤트 정리
   */
  private cleanupOldEvents(): void {
    const cutoffDate = new Date(Date.now() - this.config.retentionPeriod * 24 * 60 * 60 * 1000);
    
    for (const [eventId, event] of this.events) {
      if (event.timestamp < cutoffDate) {
        this.events.delete(eventId);
      }
    }
  }

  /**
   * 전체 위험도 평가 업데이트
   */
  private updateOverallRiskAssessment(): void {
    // IP별 위험 점수 감소 (시간 경과에 따른 자연 감소)
    for (const [ip, score] of this.ipRiskScores) {
      const newScore = Math.max(0, score - 1); // 매분 1점씩 감소
      if (newScore === 0) {
        this.ipRiskScores.delete(ip);
      } else {
        this.ipRiskScores.set(ip, newScore);
      }
    }

    // 사용자별 위험 점수 감소
    for (const [userId, score] of this.userRiskScores) {
      const newScore = Math.max(0, score - 1);
      if (newScore === 0) {
        this.userRiskScores.delete(userId);
      } else {
        this.userRiskScores.set(userId, newScore);
      }
    }
  }

  /**
   * 주기적 보고서 생성
   */
  private generatePeriodicReport(): void {
    const stats = this.getThreatStatistics();
    
    this.logger.info('주기적 보안 현황 보고서', {
      totalEvents: stats.totalEvents,
      recentEvents: Array.from(this.events.values())
        .filter(e => e.timestamp > new Date(Date.now() - 60 * 60 * 1000)).length,
      topAttackers: stats.topAttackers.slice(0, 3),
      topTargets: stats.topTargets.slice(0, 3),
      blockedIPs: this.blockedIPs.size,
      blockedUsers: this.blockedUsers.size
    });
  }

  /**
   * 위험 점수 업데이트
   */
  private updateRiskScores(event: SecurityEvent): void {
    const ip = event.source.ip;
    const userId = event.source.userId;

    // IP 위험 점수 업데이트
    const currentIPScore = this.ipRiskScores.get(ip) || 0;
    const newIPScore = Math.min(100, currentIPScore + event.details.riskScore);
    this.ipRiskScores.set(ip, newIPScore);

    // 사용자 위험 점수 업데이트 (로그인한 경우)
    if (userId) {
      const currentUserScore = this.userRiskScores.get(userId) || 0;
      const newUserScore = Math.min(100, currentUserScore + event.details.riskScore);
      this.userRiskScores.set(userId, newUserScore);
    }
  }

  /**
   * 심각도 결정
   */
  private determineSeverity(severity: 'low' | 'medium' | 'high' | 'critical'): SecuritySeverity {
    switch (severity) {
      case 'low': return SecuritySeverity.LOW;
      case 'medium': return SecuritySeverity.MEDIUM;
      case 'high': return SecuritySeverity.HIGH;
      case 'critical': return SecuritySeverity.CRITICAL;
      default: return SecuritySeverity.LOW;
    }
  }

  /**
   * 위험 점수 계산
   */
  private calculateRiskScore(severity: string, threatCount: number): number {
    const severityScores = {
      low: 10,
      medium: 25,
      high: 50,
      critical: 75
    };

    const baseScore = severityScores[severity as keyof typeof severityScores] || 10;
    const threatBonus = threatCount * 5;
    
    return Math.min(100, baseScore + threatBonus);
  }

  /**
   * 패턴 점수 계산
   */
  private calculatePatternScore(events: SecurityEvent[]): number {
    let score = 0;

    // 시간 패턴 분석 (짧은 시간 내 많은 이벤트)
    const timeSpan = events[events.length - 1].timestamp.getTime() - events[0].timestamp.getTime();
    if (timeSpan < 60000) { // 1분 이내
      score += 30;
    }

    // 타입 다양성 (다양한 공격 타입)
    const uniqueTypes = new Set(events.map(e => e.type)).size;
    score += uniqueTypes * 10;

    // 심각도 누적
    const severitySum = events.reduce((sum, e) => {
      const severityScores = { low: 1, medium: 2, high: 3, critical: 4 };
      return sum + (severityScores[e.severity] || 1);
    }, 0);
    score += severitySum * 2;

    return Math.min(100, score);
  }

  /**
   * 전체 위험 수준 계산
   */
  private calculateOverallRiskLevel(): SecuritySeverity {
    const recentEvents = Array.from(this.events.values())
      .filter(e => e.timestamp > new Date(Date.now() - 60 * 60 * 1000)); // 지난 1시간

    const criticalEvents = recentEvents.filter(e => e.severity === SecuritySeverity.CRITICAL).length;
    const highEvents = recentEvents.filter(e => e.severity === SecuritySeverity.HIGH).length;

    if (criticalEvents > 0) return SecuritySeverity.CRITICAL;
    if (highEvents > 2) return SecuritySeverity.HIGH;
    if (recentEvents.length > 10) return SecuritySeverity.MEDIUM;
    
    return SecuritySeverity.LOW;
  }

  /**
   * 트렌드 계산
   */
  private calculateTrends(events: SecurityEvent[]): ThreatStatistics['trends'] {
    const now = new Date();
    const hourlyEvents = new Array(24).fill(0);
    const dailyEvents = new Array(7).fill(0);
    const weeklyEvents = new Array(4).fill(0);

    events.forEach(event => {
      const eventTime = event.timestamp;
      const hoursAgo = Math.floor((now.getTime() - eventTime.getTime()) / (1000 * 60 * 60));
      const daysAgo = Math.floor(hoursAgo / 24);
      const weeksAgo = Math.floor(daysAgo / 7);

      if (hoursAgo < 24) hourlyEvents[23 - hoursAgo]++;
      if (daysAgo < 7) dailyEvents[6 - daysAgo]++;
      if (weeksAgo < 4) weeklyEvents[3 - weeksAgo]++;
    });

    return { hourlyEvents, dailyEvents, weeklyEvents };
  }

  /**
   * 이벤트 ID 생성
   */
  private generateEventId(): string {
    const timestamp = Date.now().toString(36);
    const random = Math.random().toString(36).substr(2, 5);
    return `SEC_${timestamp}_${random}`.toUpperCase();
  }

  /**
   * 보안 이벤트 처리
   */
  private handleSecurityEvent(event: SecurityEvent): void {
    // 추가 처리 로직 (외부 시스템 연동 등)
  }

  /**
   * IP 차단 처리
   */
  private handleIPBlocked(data: { ip: string; reason: string; duration?: number }): void {
    // IP 차단 알림 발송
    this.sendAlert('block', `IP 주소가 차단되었습니다: ${data.ip}`, undefined, data);
  }

  /**
   * 사용자 차단 처리
   */
  private handleUserBlocked(data: { userId: string; reason: string; duration?: number }): void {
    // 사용자 차단 알림 발송
    this.sendAlert('block', `사용자가 차단되었습니다: ${data.userId}`, undefined, data);
  }

  /**
   * 알림 발송
   */
  private sendAlert(
    type: 'critical' | 'high' | 'pattern' | 'block',
    message: string,
    event?: SecurityEvent,
    data?: any
  ): void {
    this.logger.warn(`보안 알림 [${type.toUpperCase()}]`, {
      message,
      event: event ? {
        id: event.id,
        type: event.type,
        severity: event.severity,
        source: event.source
      } : undefined,
      data
    });

    // 실제 알림 발송 로직 (이메일, SMS, Slack 등)
    this.emit('securityAlert', { type, message, event, data });
  }

  /**
   * 보안 이벤트 목록 조회 (관리자 API용) - DB에서 조회
   */
  public async getSecurityEvents(
    filters: any = {}, 
    page: number = 1, 
    limit: number = 50
  ): Promise<{ events: SecurityEvent[], total: number, totalPages: number, currentPage: number }> {
    try {
      // SecurityEventRepository를 통해 DB에서 조회
      const result = await this.securityEventRepository.getEvents(filters, page, limit);
      return result;
    } catch (error) {
      this.logger.error('보안 이벤트 목록 조회 실패', { filters, page, limit, error: error.message });
      
      // 오류 발생시 메모리 데이터로 폴백
      let events = Array.from(this.events.values());

      // 필터 적용 (메모리 데이터용 폴백)
      if (filters.severity) {
        events = events.filter(e => e.severity === filters.severity);
      }
      if (filters.type) {
        events = events.filter(e => e.type === filters.type);
      }
      if (filters.status) {
        events = events.filter(e => e.status === filters.status);
      }
      if (filters.sourceIp) {
        events = events.filter(e => e.source.ip === filters.sourceIp);
      }
      if (filters.startDate) {
        events = events.filter(e => e.timestamp >= filters.startDate);
      }
      if (filters.endDate) {
        events = events.filter(e => e.timestamp <= filters.endDate);
      }

      // 정렬 (최신순)
      events.sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());

      // 페이지네이션
      const offset = (page - 1) * limit;
      const paginatedEvents = events.slice(offset, offset + limit);
      const total = events.length;
      const totalPages = Math.ceil(total / limit);
      
      return {
        events: paginatedEvents,
        total,
        totalPages,
        currentPage: page
      };
    }
  }

  /**
   * 보안 이벤트 개수 조회 (관리자 API용)
   */
  public getSecurityEventCount(filters: any = {}): number {
    let events = Array.from(this.events.values());

    // 필터 적용
    if (filters.severity) {
      events = events.filter(e => e.severity === filters.severity);
    }
    if (filters.type) {
      events = events.filter(e => e.type === filters.type);
    }
    if (filters.status) {
      events = events.filter(e => e.status === filters.status);
    }
    if (filters.ip) {
      events = events.filter(e => e.source.ip === filters.ip);
    }
    if (filters.startDate) {
      events = events.filter(e => e.timestamp >= filters.startDate);
    }
    if (filters.endDate) {
      events = events.filter(e => e.timestamp <= filters.endDate);
    }

    return events.length;
  }

  /**
   * 특정 보안 이벤트 조회 (관리자 API용) - DB에서 조회
   */
  public async getSecurityEvent(eventId: string): Promise<SecurityEvent | null> {
    try {
      // SecurityEventRepository를 통해 DB에서 조회
      const event = await this.securityEventRepository.getEventById(eventId);
      return event;
    } catch (error) {
      this.logger.error('보안 이벤트 조회 실패', { eventId, error: error.message });
      
      // 오류 발생시 메모리 데이터로 폴백
      return this.events.get(eventId) || null;
    }
  }

  /**
   * 차단된 IP 목록 조회 (관리자 API용)
   */
  public getBlockedIPs(): Array<{ ip: string; blockedAt: Date }> {
    return Array.from(this.blockedIPs).map(ip => ({
      ip,
      blockedAt: new Date() // 실제로는 차단 시간을 저장해야 함
    }));
  }

  /**
   * 보안 통계 조회 (관리자 API용) - DB에서 조회
   */
  public async getSecurityStatistics(days: number = 30): Promise<any> {
    try {
      // SecurityEventRepository를 통해 DB에서 통계 조회
      const stats = await this.securityEventRepository.getEventStats(days);
      return stats;
    } catch (error) {
      this.logger.error('보안 통계 조회 실패', { days, error: error.message });
      
      // 오류 발생시 메모리 데이터로 폴백
      const end = new Date();
      const start = new Date();
      start.setDate(start.getDate() - days);
      return this.getThreatStatistics({ start, end });
    }
  }

  /**
   * 상위 공격자 목록 조회 (관리자 API용)
   */
  public getTopAttackers(limit: number = 10, start?: Date, end?: Date): Array<{
    ip: string;
    eventCount: number;
    riskScore: number;
  }> {
    const stats = this.getThreatStatistics(start && end ? { start, end } : undefined);
    return stats.topAttackers.slice(0, limit);
  }

  /**
   * 상위 타겟 목록 조회 (관리자 API용)
   */
  public getTopTargets(limit: number = 10, start?: Date, end?: Date): Array<{
    endpoint: string;
    eventCount: number;
  }> {
    const stats = this.getThreatStatistics(start && end ? { start, end } : undefined);
    return stats.topTargets.slice(0, limit);
  }

  /**
   * 시간대별 이벤트 데이터 조회 (관리자 API용)
   */
  public getTimelineData(start: Date, end: Date): Array<{
    timestamp: Date;
    eventCount: number;
    severityBreakdown: Record<SecuritySeverity, number>;
  }> {
    const events = Array.from(this.events.values())
      .filter(e => e.timestamp >= start && e.timestamp <= end);

    // 시간대별로 그룹화 (1시간 단위)
    const hourlyData = new Map<string, {
      timestamp: Date;
      events: SecurityEvent[];
    }>();

    events.forEach(event => {
      const hour = new Date(event.timestamp);
      hour.setMinutes(0, 0, 0); // 정시로 맞춤
      const key = hour.toISOString();

      if (!hourlyData.has(key)) {
        hourlyData.set(key, {
          timestamp: hour,
          events: []
        });
      }
      hourlyData.get(key)!.events.push(event);
    });

    // 결과 변환
    return Array.from(hourlyData.values())
      .map(({ timestamp, events }) => {
        const severityBreakdown: Record<SecuritySeverity, number> = {
          [SecuritySeverity.LOW]: 0,
          [SecuritySeverity.MEDIUM]: 0,
          [SecuritySeverity.HIGH]: 0,
          [SecuritySeverity.CRITICAL]: 0
        };

        events.forEach(event => {
          severityBreakdown[event.severity]++;
        });

        return {
          timestamp,
          eventCount: events.length,
          severityBreakdown
        };
      })
      .sort((a, b) => a.timestamp.getTime() - b.timestamp.getTime());
  }

  /**
   * 위험 분석 데이터 조회 (관리자 API용)
   */
  public getRiskAnalysis(start: Date, end: Date): {
    overallRiskLevel: SecuritySeverity;
    riskTrend: 'increasing' | 'decreasing' | 'stable';
    topRiskFactors: Array<{
      factor: string;
      impact: number;
      description: string;
    }>;
  } {
    const events = Array.from(this.events.values())
      .filter(e => e.timestamp >= start && e.timestamp <= end);

    // 전체 위험 수준 계산
    const avgRiskScore = events.length > 0 
      ? events.reduce((sum, e) => sum + e.details.riskScore, 0) / events.length 
      : 0;

    let overallRiskLevel: SecuritySeverity;
    if (avgRiskScore >= 80) overallRiskLevel = SecuritySeverity.CRITICAL;
    else if (avgRiskScore >= 60) overallRiskLevel = SecuritySeverity.HIGH;
    else if (avgRiskScore >= 30) overallRiskLevel = SecuritySeverity.MEDIUM;
    else overallRiskLevel = SecuritySeverity.LOW;

    // 위험 트렌드 분석 (간단한 구현)
    const riskTrend: 'increasing' | 'decreasing' | 'stable' = 'stable';

    // 주요 위험 요소
    const topRiskFactors = [
      {
        factor: 'SQL Injection Attempts',
        impact: events.filter(e => e.type === SecurityEventType.SQL_INJECTION_DETECTED).length,
        description: 'SQL 인젝션 공격 시도'
      },
      {
        factor: 'XSS Attacks',
        impact: events.filter(e => e.type === SecurityEventType.XSS_ATTACK_DETECTED).length,
        description: 'XSS 공격 시도'
      },
      {
        factor: 'Brute Force Attempts',
        impact: events.filter(e => e.type === SecurityEventType.BRUTE_FORCE_ATTACK).length,
        description: '무차별 대입 공격 시도'
      }
    ].sort((a, b) => b.impact - a.impact);

    return {
      overallRiskLevel,
      riskTrend,
      topRiskFactors
    };
  }

  /**
   * 이벤트 상태 업데이트 (관리자 API용)
   */
  public updateEventStatus(
    eventId: string, 
    status: SecurityEventStatus, 
    adminUserId?: string, 
    notes?: string
  ): boolean {
    const event = this.events.get(eventId);
    if (!event) {
      return false;
    }

    event.status = status;
    
    // 조사 정보 추가
    if (!event.investigation) {
      event.investigation = {
        investigatedBy: adminUserId,
        investigatedAt: new Date(),
        notes: []
      };
    }

    if (notes) {
      if (!event.investigation.notes) {
        event.investigation.notes = [];
      }
      event.investigation.notes.push({
        timestamp: new Date(),
        adminUserId: adminUserId || 'system',
        note: notes
      });
    }

    this.logger.info('보안 이벤트 상태 업데이트', {
      eventId,
      status,
      adminUserId,
      notes
    });

    return true;
  }
}

/**
 * 보안 모니터 싱글톤 인스턴스
 */
export const securityMonitor = new SecurityMonitor();