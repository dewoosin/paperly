'use client'

import { Button } from '@/components/ui/button'
import { Moon, Sun, Bell, User } from 'lucide-react'
import { useTheme } from 'next-themes'

interface HeaderProps {
  title?: string
  subtitle?: string
}

export function Header({ title, subtitle }: HeaderProps) {
  const { theme, setTheme } = useTheme()

  return (
    <header className="admin-header">
      <div className="flex items-center justify-between">
        {/* 제목 */}
        <div>
          {title && <h1 className="text-2xl font-semibold">{title}</h1>}
          {subtitle && <p className="text-sm text-muted-foreground">{subtitle}</p>}
        </div>

        {/* 액션 버튼들 */}
        <div className="flex items-center space-x-2">
          {/* 알림 버튼 */}
          <Button variant="ghost" size="icon" className="relative">
            <Bell className="h-4 w-4" />
            {/* 알림 배지 */}
            <span className="absolute -right-1 -top-1 h-3 w-3 rounded-full bg-red-500 text-xs" />
          </Button>

          {/* 테마 토글 */}
          <Button
            variant="ghost"
            size="icon"
            onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
          >
            <Sun className="h-4 w-4 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
            <Moon className="absolute h-4 w-4 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
            <span className="sr-only">테마 토글</span>
          </Button>

          {/* 사용자 메뉴 */}
          <Button variant="ghost" size="icon">
            <User className="h-4 w-4" />
          </Button>
        </div>
      </div>
    </header>
  )
}