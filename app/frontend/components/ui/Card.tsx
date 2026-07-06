import type { ElementType, ReactNode } from 'react'
import { cn } from '../../utils/cn'

export type CardPadding = 'sm' | 'md' | 'lg' | 'empty'

export interface CardProps {
  children: ReactNode
  as?: ElementType
  padding?: CardPadding
  className?: string
  animate?: boolean
}

const PADDING_CLASSES: Record<CardPadding, string> = {
  sm: 'p-4',
  md: 'p-6',
  lg: 'p-6 md:p-8',
  empty: 'p-12 text-center',
}

export default function Card({
  children,
  as: Component = 'div',
  padding = 'md',
  className,
  animate = false,
}: CardProps) {
  return (
    <Component
      className={cn(
        'glass-effect rounded-2xl',
        PADDING_CLASSES[padding],
        animate && 'animate-fade-in',
        className
      )}
    >
      {children}
    </Component>
  )
}
