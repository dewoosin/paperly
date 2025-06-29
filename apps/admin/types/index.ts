// API 응답 타입
export interface ApiResponse<T = any> {
  success: boolean
  data?: T
  error?: {
    code: string
    message: string
  }
  message?: string
}

// 페이지네이션
export interface PaginatedResponse<T> {
  items: T[]
  total: number
  page: number
  limit: number
  totalPages: number
}

// 사용자 관련 타입
export interface User {
  id: string
  email: string
  name: string
  birthDate: string
  gender?: 'male' | 'female' | 'other' | 'prefer_not_to_say'
  emailVerified: boolean
  createdAt: string
  updatedAt: string
}

// 관리자 타입
export interface AdminUser {
  id: string
  email: string
  name: string
  role: AdminRole
  permissions: string[]
  lastLoginAt?: string
  isActive: boolean
  createdAt: string
  updatedAt: string
}

export interface AdminRole {
  id: string
  name: string
  displayName: string
  description: string
  permissions: string[]
  isActive: boolean
}

// 작가 관련 타입
export interface Writer {
  id: string
  userId: string
  user: User
  bio?: string
  expertise: string[]
  socialLinks?: Record<string, string>
  isApproved: boolean
  approvedAt?: string
  approvedBy?: string
  articleCount: number
  totalViews: number
  averageRating: number
  createdAt: string
  updatedAt: string
}

// 기사 관련 타입
export interface Article {
  id: string
  title: string
  subtitle?: string
  slug: string
  excerpt?: string
  content: string
  contentHtml?: string
  status: ArticleStatus
  visibility: 'public' | 'private' | 'unlisted'
  authorId: string
  author: User
  categoryId: string
  category: Category
  tags: Tag[]
  viewCount: number
  likeCount: number
  shareCount: number
  commentCount: number
  isFeatured: boolean
  isInternal: boolean
  publishedAt?: string
  scheduledAt?: string
  createdAt: string
  updatedAt: string
}

export type ArticleStatus = 'draft' | 'review' | 'published' | 'archived' | 'deleted'

// 카테고리 타입
export interface Category {
  id: string
  name: string
  slug: string
  description?: string
  colorCode?: string
  iconName?: string
  parentId?: string
  children?: Category[]
  displayOrder: number
  isFeatured: boolean
  isActive: boolean
  articleCount: number
  createdBy?: string
  createdAt: string
  updatedAt: string
}

// 태그 타입
export interface Tag {
  id: string
  name: string
  slug?: string
  description?: string
  colorHex?: string
  usageCount: number
  isFeatured: boolean
  createdBy?: string
  createdAt: string
  updatedAt: string
}

// 보안 관련 타입
export interface SecurityEvent {
  id: string
  type: SecurityEventType
  severity: SecuritySeverity
  status: SecurityEventStatus
  timestamp: string
  source: {
    ip: string
    userAgent?: string
    userId?: string
    sessionId?: string
    deviceId?: string
  }
  target: {
    endpoint: string
    method: string
    parameters?: Record<string, any>
    headers?: Record<string, string>
  }
  details: {
    description: string
    payload?: string
    threats: string[]
    riskScore: number
    validationResults?: any
    context?: Record<string, any>
  }
  response: {
    action: SecurityAction
    blocked: boolean
    message?: string
    timestamp: string
  }
}

export type SecurityEventType = 
  | 'XSS_ATTACK_DETECTED'
  | 'SQL_INJECTION_DETECTED'
  | 'PATH_TRAVERSAL_DETECTED'
  | 'COMMAND_INJECTION_DETECTED'
  | 'BRUTE_FORCE_ATTACK'
  | 'SUSPICIOUS_USER_AGENT'
  | 'MULTIPLE_FAILED_LOGINS'
  | 'UNUSUAL_REQUEST_PATTERN'
  | 'RATE_LIMIT_EXCEEDED'
  | 'MALICIOUS_FILE_UPLOAD'
  | 'DATA_EXFILTRATION_ATTEMPT'
  | 'PRIVILEGE_ESCALATION'

export type SecuritySeverity = 'low' | 'medium' | 'high' | 'critical'

export type SecurityEventStatus = 'detected' | 'investigating' | 'blocked' | 'resolved' | 'false_positive'

export type SecurityAction = 
  | 'none'
  | 'logged'
  | 'rate_limited'
  | 'temporarily_blocked'
  | 'permanently_blocked'
  | 'account_suspended'
  | 'alert_sent'
  | 'escalated'

// 통계 관련 타입
export interface DashboardStats {
  totalUsers: number
  totalArticles: number
  activeWriters: number
  securityEvents: number
  dailyViews: number
  monthlyGrowth: number
}

export interface SecurityStats {
  totalEvents: number
  eventsByType: Record<SecurityEventType, number>
  eventsBySeverity: Record<SecuritySeverity, number>
  topAttackers: Array<{
    ip: string
    eventCount: number
    riskScore: number
  }>
  topTargets: Array<{
    endpoint: string
    eventCount: number
  }>
  timeRange: {
    start: string
    end: string
  }
  trends: {
    hourlyEvents: number[]
    dailyEvents: number[]
    weeklyEvents: number[]
  }
}

// 공통코드 타입
export interface SystemCode {
  id: string
  category: string
  code: string
  name: string
  description?: string
  value: string
  displayOrder: number
  isActive: boolean
  createdBy: string
  createdAt: string
  updatedAt: string
}

// 메시지코드 타입
export interface MessageCode {
  id: string
  code: string
  language: string
  message: string
  description?: string
  category?: string
  isActive: boolean
  createdBy: string
  createdAt: string
  updatedAt: string
}

// 로그 타입
export interface SystemLog {
  id: string
  level: 'debug' | 'info' | 'warn' | 'error'
  message: string
  meta?: Record<string, any>
  source: string
  userId?: string
  sessionId?: string
  ip?: string
  userAgent?: string
  timestamp: string
}

// 시스템 설정 타입
export interface SystemSetting {
  id: string
  category: string
  key: string
  value: string
  dataType: 'string' | 'number' | 'boolean' | 'json'
  description?: string
  isPublic: boolean
  createdBy: string
  updatedBy: string
  createdAt: string
  updatedAt: string
}

// 폼 관련 타입
export interface FormError {
  field: string
  message: string
}

// 테이블 관련 타입
export interface TableColumn<T = any> {
  key: keyof T
  label: string
  sortable?: boolean
  width?: string
  render?: (value: any, row: T) => React.ReactNode
}

export interface TableSort {
  field: string
  direction: 'asc' | 'desc'
}

// 필터 관련 타입
export interface Filter {
  field: string
  operator: 'eq' | 'ne' | 'like' | 'in' | 'gte' | 'lte'
  value: any
}

// 검색 옵션
export interface SearchOptions {
  query?: string
  filters?: Filter[]
  sort?: TableSort
  page?: number
  limit?: number
}