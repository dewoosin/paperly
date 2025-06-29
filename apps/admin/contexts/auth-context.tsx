'use client'

import React, { createContext, useContext, useState, useEffect } from 'react'
import { useRouter, usePathname } from 'next/navigation'

/**
 * 관리자 인증 컨텍스트
 * 
 * 관리자 인증 상태를 전역으로 관리하고, 
 * 로그인/로그아웃 기능과 권한 확인을 제공합니다.
 */

interface AdminUser {
  id: string
  email: string
  name: string
  role: string
  permissions: string[]
  roleAssignedAt: string
  roleExpiresAt?: string
}

interface AuthContextType {
  user: AdminUser | null
  isLoading: boolean
  isAuthenticated: boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => void
  refreshToken: () => Promise<boolean>
  hasPermission: (permission: string) => boolean
  hasRole: (role: string) => boolean
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

interface AuthProviderProps {
  children: React.ReactNode
}

export function AuthProvider({ children }: AuthProviderProps) {
  const [user, setUser] = useState<AdminUser | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const router = useRouter()
  const pathname = usePathname()

  const isAuthenticated = !!user

  /**
   * 로그인 함수
   */
  const login = async (email: string, password: string): Promise<void> => {
    try {
      const response = await fetch('/api/admin/auth/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password }),
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error?.message || '로그인에 실패했습니다.')
      }

      if (data.success && data.data.accessToken) {
        // 토큰과 사용자 정보 저장
        localStorage.setItem('admin_access_token', data.data.accessToken)
        localStorage.setItem('admin_user', JSON.stringify(data.data.user))
        
        setUser(data.data.user)
      } else {
        throw new Error('서버 응답이 올바르지 않습니다.')
      }
    } catch (error) {
      console.error('로그인 오류:', error)
      throw error
    }
  }

  /**
   * 로그아웃 함수
   */
  const logout = () => {
    // 로컬 스토리지에서 토큰과 사용자 정보 제거
    localStorage.removeItem('admin_access_token')
    localStorage.removeItem('admin_user')
    
    setUser(null)
    
    // 로그인 페이지로 리디렉션
    router.push('/login')
  }

  /**
   * 토큰 새로고침
   */
  const refreshToken = async (): Promise<boolean> => {
    try {
      const response = await fetch('/api/admin/auth/refresh', {
        method: 'POST',
        credentials: 'include', // 쿠키 포함
      })

      if (!response.ok) {
        return false
      }

      const data = await response.json()
      
      if (data.success && data.data.accessToken) {
        localStorage.setItem('admin_access_token', data.data.accessToken)
        return true
      }

      return false
    } catch (error) {
      console.error('토큰 새로고침 오류:', error)
      return false
    }
  }

  /**
   * 권한 확인
   */
  const hasPermission = (permission: string): boolean => {
    if (!user) return false
    
    // 최고 관리자는 모든 권한을 가짐
    if (user.role === 'super_admin') return true
    
    return user.permissions.includes(permission)
  }

  /**
   * 역할 확인
   */
  const hasRole = (role: string): boolean => {
    if (!user) return false
    return user.role === role
  }

  /**
   * 초기 인증 상태 확인
   */
  useEffect(() => {
    const checkAuthStatus = async () => {
      try {
        const token = localStorage.getItem('admin_access_token')
        const savedUser = localStorage.getItem('admin_user')

        if (!token || !savedUser) {
          setIsLoading(false)
          return
        }

        // 저장된 사용자 정보 복원
        const userData = JSON.parse(savedUser)
        
        // 토큰 유효성 검증
        const response = await fetch('/api/admin/auth/verify', {
          headers: {
            'Authorization': `Bearer ${token}`
          }
        })

        if (response.ok) {
          const data = await response.json()
          if (data.success) {
            setUser(userData)
          } else {
            // 토큰이 유효하지 않으면 로그아웃
            logout()
          }
        } else if (response.status === 401) {
          // 토큰 만료 시 새로고침 시도
          const refreshed = await refreshToken()
          if (refreshed) {
            setUser(userData)
          } else {
            logout()
          }
        } else {
          logout()
        }
      } catch (error) {
        console.error('인증 상태 확인 오류:', error)
        logout()
      } finally {
        setIsLoading(false)
      }
    }

    checkAuthStatus()
  }, [])

  /**
   * 라우트 보호
   */
  useEffect(() => {
    if (!isLoading && !isAuthenticated && pathname !== '/login') {
      router.push('/login')
    }
  }, [isLoading, isAuthenticated, pathname, router])

  /**
   * 자동 토큰 새로고침 (30분마다)
   */
  useEffect(() => {
    if (!isAuthenticated) return

    const interval = setInterval(async () => {
      const success = await refreshToken()
      if (!success) {
        logout()
      }
    }, 30 * 60 * 1000) // 30분

    return () => clearInterval(interval)
  }, [isAuthenticated])

  const value: AuthContextType = {
    user,
    isLoading,
    isAuthenticated,
    login,
    logout,
    refreshToken,
    hasPermission,
    hasRole
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  )
}

/**
 * Auth Context Hook
 */
export function useAuth() {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth는 AuthProvider 내에서 사용되어야 합니다')
  }
  return context
}

/**
 * 인증 보호 컴포넌트
 */
interface ProtectedRouteProps {
  children: React.ReactNode
  requiredRole?: string
  requiredPermission?: string
  fallback?: React.ReactNode
}

export function ProtectedRoute({ 
  children, 
  requiredRole, 
  requiredPermission, 
  fallback 
}: ProtectedRouteProps) {
  const { isLoading, isAuthenticated, hasRole, hasPermission } = useAuth()

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-gray-900"></div>
      </div>
    )
  }

  if (!isAuthenticated) {
    return fallback || <div>접근 권한이 없습니다.</div>
  }

  if (requiredRole && !hasRole(requiredRole)) {
    return fallback || <div>필요한 역할이 없습니다.</div>
  }

  if (requiredPermission && !hasPermission(requiredPermission)) {
    return fallback || <div>필요한 권한이 없습니다.</div>
  }

  return <>{children}</>
}