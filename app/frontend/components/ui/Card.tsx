import type { ElementType, ReactNode } from 'react'
import { cn } from '../../utils/cn'

export type CardPadding = 'sm' | 'md' | 'lg' | 'empty'
export type CardTone = 'elevated' | 'card' | 'subtle' | 'panel'

export interface CardProps {
  children: ReactNode
  as?: ElementType
  padding?: CardPadding
  tone?: CardTone
  className?: string
  animate?: boolean
}

const PADDING_CLASSES: Record<CardPadding, string> = {
  sm: 'p-4',
  md: 'p-6',
  lg: 'p-6 md:p-8',
  empty: 'p-12 text-center',
}

const TONE_CLASSES: Record<CardTone, string> = {
  elevated: 'surface-elevated rounded-2xl',
  card: 'surface-card rounded-2xl',
  subtle: 'surface-subtle rounded-xl',
  panel: 'surface-panel rounded-2xl',
}

export default function Card({
  children,
  as: Component = 'div',
  padding = 'md',
  tone = 'card',
  className,
  animate = false,
}: CardProps) {
  return (
    <Component
      className={cn(
        TONE_CLASSES[tone],
        PADDING_CLASSES[padding],
        animate && 'motion-safe:animate-fade-in motion-sensitive',
        className
      )}
    >
      {children}
    </Component>
  )
}
