'use client'

import { Sidebar } from './sidebar'
import { Header } from './header'

interface AdminLayoutProps {
  children: React.ReactNode
  title?: string
  subtitle?: string
}

export function AdminLayout({ children, title, subtitle }: AdminLayoutProps) {
  return (
    <div className="admin-container">
      <Sidebar />
      <div className="admin-main">
        <Header title={title} subtitle={subtitle} />
        <main className="admin-content">
          {children}
        </main>
      </div>
    </div>
  )
}