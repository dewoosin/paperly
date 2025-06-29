'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Eye, EyeOff, Shield, AlertCircle } from 'lucide-react'

/**
 * 관리자 로그인 페이지
 * 
 * 관리자 인증을 위한 로그인 폼을 제공합니다.
 * JWT 기반 인증을 사용하여 관리자 권한을 확인합니다.
 */

interface LoginFormData {
  email: string
  password: string
}

interface LoginError {
  message: string
  code?: string
}

export default function AdminLoginPage() {
  const router = useRouter()
  const [formData, setFormData] = useState<LoginFormData>({
    email: '',
    password: ''
  })
  const [showPassword, setShowPassword] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<LoginError | null>(null)

  /**
   * 입력값 변경 처리
   */
  const handleInputChange = (field: keyof LoginFormData, value: string) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }))
    // 입력 시 에러 메시지 제거
    if (error) setError(null)
  }

  /**
   * 로그인 폼 제출 처리
   */
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)
    setError(null)

    try {
      // 기본 검증
      if (!formData.email || !formData.password) {
        throw new Error('이메일과 비밀번호를 입력해주세요.')
      }

      // API 요청
      const response = await fetch('/api/admin/auth/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: formData.email,
          password: formData.password
        }),
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error?.message || '로그인에 실패했습니다.')
      }

      // 로그인 성공
      if (data.success && data.data.accessToken) {
        // 액세스 토큰을 로컬 스토리지에 저장
        localStorage.setItem('admin_access_token', data.data.accessToken)
        
        // 사용자 정보도 저장
        localStorage.setItem('admin_user', JSON.stringify(data.data.user))

        // 대시보드로 리디렉션
        router.push('/dashboard')
      } else {
        throw new Error('서버 응답이 올바르지 않습니다.')
      }
    } catch (err) {
      console.error('로그인 오류:', err)
      setError({
        message: err instanceof Error ? err.message : '알 수 없는 오류가 발생했습니다.',
        code: 'LOGIN_ERROR'
      })
    } finally {
      setIsLoading(false)
    }
  }

  /**
   * Enter 키 처리
   */
  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !isLoading) {
      handleSubmit(e as any)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 p-4">
      <div className="w-full max-w-md">
        {/* 로고 및 제목 */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-blue-600 rounded-full mb-4">
            <Shield className="w-8 h-8 text-white" />
          </div>
          <h1 className="text-3xl font-bold text-white mb-2">Paperly Admin</h1>
          <p className="text-slate-400">관리자 로그인</p>
        </div>

        {/* 로그인 폼 */}
        <Card className="bg-slate-800 border-slate-700">
          <CardHeader>
            <CardTitle className="text-center text-white">
              관리자 인증이 필요합니다
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-6">
            {/* 에러 메시지 */}
            {error && (
              <div className="bg-red-500/10 border border-red-500/20 rounded-lg p-4">
                <div className="flex items-center space-x-2">
                  <AlertCircle className="w-4 h-4 text-red-400" />
                  <span className="text-red-400 text-sm">{error.message}</span>
                </div>
              </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-4">
              {/* 이메일 입력 */}
              <div>
                <label htmlFor="email" className="block text-sm font-medium text-slate-300 mb-2">
                  이메일
                </label>
                <input
                  id="email"
                  type="email"
                  value={formData.email}
                  onChange={(e) => handleInputChange('email', e.target.value)}
                  onKeyPress={handleKeyPress}
                  placeholder="admin@paperly.com"
                  className="w-full px-3 py-2 bg-slate-700 border border-slate-600 rounded-lg text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  disabled={isLoading}
                  required
                />
              </div>

              {/* 비밀번호 입력 */}
              <div>
                <label htmlFor="password" className="block text-sm font-medium text-slate-300 mb-2">
                  비밀번호
                </label>
                <div className="relative">
                  <input
                    id="password"
                    type={showPassword ? 'text' : 'password'}
                    value={formData.password}
                    onChange={(e) => handleInputChange('password', e.target.value)}
                    onKeyPress={handleKeyPress}
                    placeholder="관리자 비밀번호"
                    className="w-full px-3 py-2 pr-10 bg-slate-700 border border-slate-600 rounded-lg text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    disabled={isLoading}
                    required
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute inset-y-0 right-0 pr-3 flex items-center text-slate-400 hover:text-slate-300"
                    disabled={isLoading}
                  >
                    {showPassword ? (
                      <EyeOff className="w-4 h-4" />
                    ) : (
                      <Eye className="w-4 h-4" />
                    )}
                  </button>
                </div>
              </div>

              {/* 로그인 버튼 */}
              <Button
                type="submit"
                className="w-full bg-blue-600 hover:bg-blue-700 text-white py-2 px-4 rounded-lg font-medium transition-colors"
                disabled={isLoading || !formData.email || !formData.password}
              >
                {isLoading ? (
                  <div className="flex items-center justify-center space-x-2">
                    <div className="w-4 h-4 border-2 border-white/20 border-t-white rounded-full animate-spin" />
                    <span>로그인 중...</span>
                  </div>
                ) : (
                  '로그인'
                )}
              </Button>
            </form>

            {/* 보안 안내 */}
            <div className="text-center">
              <p className="text-xs text-slate-400">
                관리자 권한이 필요한 페이지입니다.<br />
                승인된 관리자만 접근할 수 있습니다.
              </p>
            </div>
          </CardContent>
        </Card>

        {/* 추가 정보 */}
        <div className="mt-8 text-center">
          <p className="text-slate-500 text-sm">
            문제가 있나요? 시스템 관리자에게 문의하세요.
          </p>
        </div>
      </div>
    </div>
  )
}