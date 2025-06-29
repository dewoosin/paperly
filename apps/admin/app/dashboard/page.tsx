'use client'

import { AdminLayout } from '@/components/layout/admin-layout'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { 
  Users, 
  FileText, 
  Shield, 
  TrendingUp,
  AlertTriangle,
  Activity,
  UserCheck,
  Eye
} from 'lucide-react'

// 임시 통계 데이터
const stats = {
  totalUsers: 1234,
  totalArticles: 567,
  activeWriters: 89,
  securityEvents: 12,
  dailyViews: 45678,
  monthlyGrowth: 12.5,
}

const recentSecurityEvents = [
  {
    id: 1,
    type: 'XSS 공격 시도',
    severity: 'high',
    ip: '192.168.1.100',
    time: '2분 전',
  },
  {
    id: 2,
    type: 'SQL Injection 시도',
    severity: 'critical',
    ip: '10.0.0.50',
    time: '15분 전',
  },
  {
    id: 3,
    type: '브루트포스 공격',
    severity: 'medium',
    ip: '172.16.0.25',
    time: '1시간 전',
  },
]

const getSeverityColor = (severity: string) => {
  switch (severity) {
    case 'critical':
      return 'text-red-600 bg-red-100'
    case 'high':
      return 'text-orange-600 bg-orange-100'
    case 'medium':
      return 'text-yellow-600 bg-yellow-100'
    default:
      return 'text-green-600 bg-green-100'
  }
}

export default function DashboardPage() {
  return (
    <AdminLayout
      title="대시보드"
      subtitle="시스템 전체 현황을 확인하세요"
    >
      {/* 통계 카드들 */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">총 회원수</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalUsers.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">
              전월 대비 +{stats.monthlyGrowth}%
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">총 기사수</CardTitle>
            <FileText className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalArticles.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">
              이번 달 발행된 기사
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">활성 작가</CardTitle>
            <UserCheck className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.activeWriters}</div>
            <p className="text-xs text-muted-foreground">
              이번 달 활동한 작가
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">일일 조회수</CardTitle>
            <Eye className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.dailyViews.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">
              오늘 페이지 조회수
            </p>
          </CardContent>
        </Card>
      </div>

      <div className="mt-6 grid gap-6 md:grid-cols-2">
        {/* 보안 이벤트 */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <Shield className="h-5 w-5" />
              <span>최근 보안 이벤트</span>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {recentSecurityEvents.map((event) => (
                <div key={event.id} className="flex items-center justify-between">
                  <div className="flex items-center space-x-3">
                    <div className={`rounded-full px-2 py-1 text-xs ${getSeverityColor(event.severity)}`}>
                      {event.severity}
                    </div>
                    <div>
                      <p className="text-sm font-medium">{event.type}</p>
                      <p className="text-xs text-muted-foreground">IP: {event.ip}</p>
                    </div>
                  </div>
                  <span className="text-xs text-muted-foreground">{event.time}</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* 시스템 활동 */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <Activity className="h-5 w-5" />
              <span>시스템 활동</span>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <div className="rounded-full bg-green-100 p-2">
                    <TrendingUp className="h-3 w-3 text-green-600" />
                  </div>
                  <div>
                    <p className="text-sm font-medium">새 기사 발행</p>
                    <p className="text-xs text-muted-foreground">"React 최신 동향"</p>
                  </div>
                </div>
                <span className="text-xs text-muted-foreground">5분 전</span>
              </div>

              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <div className="rounded-full bg-blue-100 p-2">
                    <Users className="h-3 w-3 text-blue-600" />
                  </div>
                  <div>
                    <p className="text-sm font-medium">새 회원 가입</p>
                    <p className="text-xs text-muted-foreground">user@example.com</p>
                  </div>
                </div>
                <span className="text-xs text-muted-foreground">10분 전</span>
              </div>

              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <div className="rounded-full bg-yellow-100 p-2">
                    <AlertTriangle className="h-3 w-3 text-yellow-600" />
                  </div>
                  <div>
                    <p className="text-sm font-medium">시스템 알림</p>
                    <p className="text-xs text-muted-foreground">백업 완료</p>
                  </div>
                </div>
                <span className="text-xs text-muted-foreground">30분 전</span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* 차트 영역 (향후 구현) */}
      <div className="mt-6">
        <Card>
          <CardHeader>
            <CardTitle>트래픽 통계</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex h-64 items-center justify-center rounded-lg bg-muted">
              <p className="text-muted-foreground">차트가 여기에 표시됩니다</p>
            </div>
          </CardContent>
        </Card>
      </div>
    </AdminLayout>
  )
}