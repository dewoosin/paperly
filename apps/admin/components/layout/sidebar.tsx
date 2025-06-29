'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { cn } from '@/utils/cn'
import {
  LayoutDashboard,
  Shield,
  Users,
  PenTool,
  FileText,
  FolderTree,
  Settings,
  LogOut,
  Menu,
  X,
  Activity,
  Code,
  MessageSquare,
  Bug,
} from 'lucide-react'
import { useState } from 'react'
import { Button } from '@/components/ui/button'

interface SidebarProps {
  className?: string
}

const menuItems = [
  {
    title: '대시보드',
    href: '/dashboard',
    icon: LayoutDashboard,
  },
  {
    title: '보안 모니터링',
    href: '/security',
    icon: Shield,
  },
  {
    title: '회원 관리',
    href: '/users',
    icon: Users,
  },
  {
    title: '작가 관리',
    href: '/writers',
    icon: PenTool,
  },
  {
    title: '기사 관리',
    href: '/articles',
    icon: FileText,
  },
  {
    title: '카테고리 관리',
    href: '/categories',
    icon: FolderTree,
  },
  {
    title: '로그 관리',
    href: '/logs',
    icon: Activity,
  },
  {
    title: '공통코드',
    href: '/codes',
    icon: Code,
  },
  {
    title: '메시지코드',
    href: '/messages',
    icon: MessageSquare,
  },
  {
    title: '예외 관리',
    href: '/errors',
    icon: Bug,
  },
  {
    title: '시스템 설정',
    href: '/settings',
    icon: Settings,
  },
]

export function Sidebar({ className }: SidebarProps) {
  const pathname = usePathname()
  const [isCollapsed, setIsCollapsed] = useState(false)

  return (
    <>
      {/* 모바일 오버레이 */}
      {isCollapsed && (
        <div
          className="fixed inset-0 z-30 bg-black/50 lg:hidden"
          onClick={() => setIsCollapsed(false)}
        />
      )}

      {/* 사이드바 */}
      <aside
        className={cn(
          'admin-sidebar',
          isCollapsed && 'translate-x-0',
          className
        )}
      >
        {/* 헤더 */}
        <div className="flex h-16 items-center justify-between border-b px-6">
          <div className="flex items-center space-x-2">
            <div className="h-8 w-8 rounded bg-primary" />
            <span className="text-lg font-semibold">Paperly Admin</span>
          </div>
          <Button
            variant="ghost"
            size="icon"
            className="lg:hidden"
            onClick={() => setIsCollapsed(false)}
          >
            <X className="h-4 w-4" />
          </Button>
        </div>

        {/* 메뉴 */}
        <nav className="flex-1 space-y-1 p-4">
          {menuItems.map((item) => {
            const isActive = pathname === item.href
            const Icon = item.icon

            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  'flex items-center space-x-3 rounded-lg px-3 py-2 text-sm transition-colors',
                  isActive
                    ? 'bg-primary text-primary-foreground'
                    : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'
                )}
              >
                <Icon className="h-4 w-4" />
                <span>{item.title}</span>
              </Link>
            )
          })}
        </nav>

        {/* 푸터 */}
        <div className="border-t p-4">
          <Button
            variant="ghost"
            className="w-full justify-start space-x-3"
            onClick={() => {
              // 로그아웃 로직
              console.log('로그아웃')
            }}
          >
            <LogOut className="h-4 w-4" />
            <span>로그아웃</span>
          </Button>
        </div>
      </aside>

      {/* 모바일 메뉴 버튼 */}
      <Button
        variant="ghost"
        size="icon"
        className="fixed left-4 top-4 z-50 lg:hidden"
        onClick={() => setIsCollapsed(true)}
      >
        <Menu className="h-4 w-4" />
      </Button>
    </>
  )
}