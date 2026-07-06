import type { ReactNode } from 'react'
import { cn } from '../../utils/cn'

export type PageContainerWidth = '7xl' | '4xl'

export interface PageContainerProps {
  children: ReactNode
  width?: PageContainerWidth
  centered?: boolean
  className?: string
  testId?: string
  role?: string
  'aria-live'?: 'off' | 'polite' | 'assertive'
  'aria-busy'?: boolean
}

export default function PageContainer({
  children,
  width = '7xl',
  centered = false,
  className,
  testId,
  role,
  'aria-live': ariaLive,
  'aria-busy': ariaBusy,
}: PageContainerProps) {
  return (
    <div
      className={cn(
        'container mx-auto px-4 py-8',
        width === '7xl' ? 'max-w-7xl' : 'max-w-4xl',
        centered && 'text-center text-gray-400',
        className
      )}
      data-testid={testId}
      role={role}
      aria-live={ariaLive}
      aria-busy={ariaBusy}
    >
      {children}
    </div>
  )
}
