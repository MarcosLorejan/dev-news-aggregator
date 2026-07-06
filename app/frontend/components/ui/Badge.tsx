import type { ReactNode } from 'react'
import { cn } from '../../utils/cn'

export type BadgeVariant = 'primary' | 'green' | 'red' | 'orange'
export type BadgeSize = 'sm' | 'md'

export interface BadgeProps {
  children: ReactNode
  variant?: BadgeVariant
  size?: BadgeSize
  className?: string
}

const VARIANT_CLASSES: Record<BadgeVariant, string> = {
  primary:
    'bg-gradient-to-r from-primary-600/20 to-primary-700/20 text-primary-300 border border-primary-500/30',
  green:
    'bg-gradient-to-r from-green-600/20 to-green-700/20 text-green-300 border border-green-500/30',
  red: 'bg-gradient-to-r from-red-600/20 to-red-700/20 text-red-300 border border-red-500/30',
  orange:
    'bg-gradient-to-r from-orange-600/20 to-orange-700/20 text-orange-300 border border-orange-500/30',
}

const SIZE_CLASSES: Record<BadgeSize, string> = {
  sm: 'px-3 py-1 text-xs',
  md: 'px-3 py-1.5 text-xs',
}

export function badgeClassName({
  variant = 'primary',
  size = 'md',
  className,
}: Pick<BadgeProps, 'variant' | 'size' | 'className'> = {}) {
  return cn(
    'inline-block font-semibold rounded-full',
    SIZE_CLASSES[size],
    VARIANT_CLASSES[variant],
    className
  )
}

export default function Badge({
  children,
  variant = 'primary',
  size = 'md',
  className,
}: BadgeProps) {
  return <span className={badgeClassName({ variant, size, className })}>{children}</span>
}
