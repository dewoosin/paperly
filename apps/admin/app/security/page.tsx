'use client'

import { useState, useEffect } from 'react'
import { AdminLayout } from '@/components/layout/admin-layout'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { 
  Shield, 
  AlertTriangle, 
  Activity, 
  Ban,
  Eye,
  MoreVertical,
  Filter,
  RefreshCw,
  TrendingUp,
  AlertCircle
} from 'lucide-react'

/**
 * 보안 모니터링 대시보드 페이지
 * 
 * 보안 이벤트, 통계, 차단된 IP 등의 정보를 실시간으로 모니터링합니다.
 */

interface SecurityEvent {
  id: string
  type: string
  severity: 'low' | 'medium' | 'high' | 'critical'
  status: 'detected' | 'investigating' | 'blocked' | 'resolved' | 'false_positive'
  timestamp: string
  source: {
    ip: string
    userAgent?: string
    userId?: string
  }
  target: {
    endpoint: string
    method: string
  }
  details: {
    description: string
    riskScore: number
    threats: string[]
  }
}

interface SecurityStats {
  totalEvents: number
  recentEvents: number
  blockedIPs: number
  riskLevel: 'low' | 'medium' | 'high' | 'critical'
  topAttackers: Array<{
    ip: string
    eventCount: number
    riskScore: number
  }>
  eventsBySeverity: Record<string, number>
}

const mockSecurityEvents: SecurityEvent[] = [
  {
    id: 'SEC_1',
    type: 'XSS_ATTACK_DETECTED',
    severity: 'high',
    status: 'detected',
    timestamp: new Date().toISOString(),
    source: {
      ip: '192.168.1.100',
      userAgent: 'Mozilla/5.0...'
    },
    target: {
      endpoint: '/api/articles',
      method: 'POST'
    },
    details: {
      description: 'XSS 공격 시도가 감지되었습니다',
      riskScore: 85,
      threats: ['XSS', 'SCRIPT_INJECTION']
    }
  },
  {
    id: 'SEC_2',
    type: 'SQL_INJECTION_DETECTED',
    severity: 'critical',
    status: 'investigating',
    timestamp: new Date(Date.now() - 300000).toISOString(),
    source: {
      ip: '10.0.0.50'
    },
    target: {
      endpoint: '/api/users',
      method: 'GET'
    },
    details: {
      description: 'SQL Injection 공격 시도',
      riskScore: 95,
      threats: ['SQL_INJECTION', 'DATA_BREACH']
    }
  }
]

const mockStats: SecurityStats = {
  totalEvents: 156,
  recentEvents: 23,
  blockedIPs: 8,
  riskLevel: 'medium',
  topAttackers: [
    { ip: '192.168.1.100', eventCount: 15, riskScore: 85 },
    { ip: '10.0.0.50', eventCount: 12, riskScore: 92 },
    { ip: '172.16.0.25', eventCount: 8, riskScore: 67 }
  ],
  eventsBySeverity: {
    critical: 5,
    high: 18,
    medium: 42,
    low: 91
  }
}

export default function SecurityPage() {
  const [events, setEvents] = useState<SecurityEvent[]>(mockSecurityEvents)
  const [stats, setStats] = useState<SecurityStats>(mockStats)
  const [isLoading, setIsLoading] = useState(false)
  const [selectedPeriod, setSelectedPeriod] = useState('24h')

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical':
        return 'text-red-600 bg-red-100 border-red-200'
      case 'high':
        return 'text-orange-600 bg-orange-100 border-orange-200'
      case 'medium':
        return 'text-yellow-600 bg-yellow-100 border-yellow-200'
      case 'low':
        return 'text-green-600 bg-green-100 border-green-200'
      default:
        return 'text-gray-600 bg-gray-100 border-gray-200'
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'blocked':
        return 'text-red-600'
      case 'investigating':
        return 'text-yellow-600'
      case 'resolved':
        return 'text-green-600'
      case 'false_positive':
        return 'text-gray-600'
      default:
        return 'text-blue-600'
    }
  }

  const getEventTypeLabel = (type: string) => {
    const labels: Record<string, string> = {
      'XSS_ATTACK_DETECTED': 'XSS 공격',
      'SQL_INJECTION_DETECTED': 'SQL 인젝션',
      'PATH_TRAVERSAL_DETECTED': 'Path Traversal',
      'BRUTE_FORCE_ATTACK': '무차별 대입 공격',
      'SUSPICIOUS_USER_AGENT': '의심스러운 User-Agent',
      'MULTIPLE_FAILED_LOGINS': '다중 로그인 실패'
    }
    return labels[type] || type
  }

  const refreshData = async () => {
    setIsLoading(true)
    // TODO: API 호출로 실제 데이터 가져오기
    setTimeout(() => {
      setIsLoading(false)
    }, 1000)
  }

  return (
    <AdminLayout
      title="보안 모니터링"
      subtitle="실시간 보안 이벤트와 위협을 모니터링합니다"
    >
      {/* 컨트롤 바 */}
      <div className="flex justify-between items-center mb-6">
        <div className="flex items-center space-x-4">
          <div className="flex items-center space-x-2">
            <Filter className="h-4 w-4 text-gray-500" />
            <select 
              value={selectedPeriod}
              onChange={(e) => setSelectedPeriod(e.target.value)}
              className="px-3 py-1 border border-gray-300 rounded-md text-sm"
            >
              <option value="1h">지난 1시간</option>
              <option value="24h">지난 24시간</option>
              <option value="7d">지난 7일</option>
              <option value="30d">지난 30일</option>
            </select>
          </div>
        </div>
        
        <Button
          onClick={refreshData}
          disabled={isLoading}
          className="flex items-center space-x-2"
        >
          <RefreshCw className={`h-4 w-4 ${isLoading ? 'animate-spin' : ''}`} />
          <span>새로고침</span>
        </Button>
      </div>

      {/* 통계 카드들 */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4 mb-6">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">총 보안 이벤트</CardTitle>
            <Shield className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalEvents}</div>
            <p className="text-xs text-muted-foreground">
              최근 24시간: {stats.recentEvents}건
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">차단된 IP</CardTitle>
            <Ban className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.blockedIPs}</div>
            <p className="text-xs text-muted-foreground">
              활성 차단
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">위험 수준</CardTitle>
            <AlertTriangle className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className={`text-2xl font-bold ${
              stats.riskLevel === 'critical' ? 'text-red-600' :
              stats.riskLevel === 'high' ? 'text-orange-600' :
              stats.riskLevel === 'medium' ? 'text-yellow-600' : 'text-green-600'
            }`}>
              {stats.riskLevel.toUpperCase()}
            </div>
            <p className="text-xs text-muted-foreground">
              현재 위험 수준
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">중요 이벤트</CardTitle>
            <AlertCircle className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-red-600">
              {stats.eventsBySeverity.critical + stats.eventsBySeverity.high}
            </div>
            <p className="text-xs text-muted-foreground">
              중요/심각 이벤트
            </p>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        {/* 최근 보안 이벤트 */}
        <div className="lg:col-span-2">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <Activity className="h-5 w-5" />
                <span>최근 보안 이벤트</span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {events.map((event) => (
                  <div key={event.id} className="border rounded-lg p-4">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center space-x-3 mb-2">
                          <span className={`px-2 py-1 text-xs rounded-full border ${getSeverityColor(event.severity)}`}>
                            {event.severity}
                          </span>
                          <span className="font-medium text-sm">
                            {getEventTypeLabel(event.type)}
                          </span>
                          <span className={`text-xs ${getStatusColor(event.status)}`}>
                            {event.status}
                          </span>
                        </div>
                        
                        <p className="text-sm text-gray-600 mb-2">
                          {event.details.description}
                        </p>
                        
                        <div className="flex items-center space-x-4 text-xs text-gray-500">
                          <span>IP: {event.source.ip}</span>
                          <span>{event.target.method} {event.target.endpoint}</span>
                          <span>위험도: {event.details.riskScore}</span>
                          <span>{new Date(event.timestamp).toLocaleString('ko-KR')}</span>
                        </div>
                      </div>
                      
                      <div className="flex items-center space-x-2">
                        <Button variant="ghost" size="sm">
                          <Eye className="h-4 w-4" />
                        </Button>
                        <Button variant="ghost" size="sm">
                          <MoreVertical className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* 상위 공격자 */}
        <div>
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <TrendingUp className="h-5 w-5" />
                <span>상위 공격자</span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {stats.topAttackers.map((attacker, index) => (
                  <div key={attacker.ip} className="flex items-center justify-between">
                    <div className="flex items-center space-x-3">
                      <div className="w-6 h-6 rounded-full bg-red-100 text-red-600 text-xs flex items-center justify-center">
                        {index + 1}
                      </div>
                      <div>
                        <p className="text-sm font-medium">{attacker.ip}</p>
                        <p className="text-xs text-gray-500">{attacker.eventCount}건의 이벤트</p>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-sm font-medium">{attacker.riskScore}</div>
                      <div className="text-xs text-gray-500">위험점수</div>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* 심각도별 분포 */}
          <Card className="mt-6">
            <CardHeader>
              <CardTitle>심각도별 이벤트</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {Object.entries(stats.eventsBySeverity).map(([severity, count]) => (
                  <div key={severity} className="flex items-center justify-between">
                    <div className="flex items-center space-x-2">
                      <div className={`w-3 h-3 rounded-full ${
                        severity === 'critical' ? 'bg-red-500' :
                        severity === 'high' ? 'bg-orange-500' :
                        severity === 'medium' ? 'bg-yellow-500' : 'bg-green-500'
                      }`} />
                      <span className="text-sm capitalize">{severity}</span>
                    </div>
                    <span className="text-sm font-medium">{count}</span>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </AdminLayout>
  )
}