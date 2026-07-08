import { cn } from '../../utils/cn'

export const FOCUS_RING =
  'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-500 focus-visible:ring-offset-2 focus-visible:ring-offset-dark-950'

export type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger' | 'filter'
export type ButtonSize = 'sm' | 'md' | 'lg'
export type ButtonColor = 'primary' | 'blue' | 'purple' | 'green' | 'red' | 'orange'

export interface ButtonStyleOptions {
  variant?: ButtonVariant
  size?: ButtonSize
  color?: ButtonColor
  active?: boolean
  className?: string
}

const GRADIENT_COLORS: Record<
  ButtonColor,
  { from: string; to: string; hoverFrom: string; hoverTo: string; shadow: string }
> = {
  primary: {
    from: 'from-primary-600',
    to: 'to-primary-700',
    hoverFrom: 'hover:from-primary-700',
    hoverTo: 'hover:to-primary-800',
    shadow: 'hover:shadow-primary-500/25',
  },
  blue: {
    from: 'from-blue-600',
    to: 'to-blue-700',
    hoverFrom: 'hover:from-blue-700',
    hoverTo: 'hover:to-blue-800',
    shadow: 'hover:shadow-blue-500/25',
  },
  purple: {
    from: 'from-purple-600',
    to: 'to-purple-700',
    hoverFrom: 'hover:from-purple-700',
    hoverTo: 'hover:to-purple-800',
    shadow: 'hover:shadow-purple-500/25',
  },
  green: {
    from: 'from-green-600',
    to: 'to-green-700',
    hoverFrom: 'hover:from-green-700',
    hoverTo: 'hover:to-green-800',
    shadow: 'hover:shadow-green-500/25',
  },
  red: {
    from: 'from-red-600',
    to: 'to-red-700',
    hoverFrom: 'hover:from-red-700',
    hoverTo: 'hover:to-red-800',
    shadow: 'hover:shadow-red-500/25',
  },
  orange: {
    from: 'from-orange-600',
    to: 'to-orange-700',
    hoverFrom: 'hover:from-orange-700',
    hoverTo: 'hover:to-orange-800',
    shadow: 'hover:shadow-orange-500/25',
  },
}

const SIZE_CLASSES: Record<ButtonSize, string> = {
  sm: 'px-4 py-2 text-sm rounded-lg',
  md: 'px-4 py-2 rounded-xl',
  lg: 'px-6 py-3 rounded-xl',
}

export function buttonClassName({
  variant = 'primary',
  size = 'md',
  color = 'primary',
  active = false,
  className,
}: ButtonStyleOptions = {}) {
  const base = cn(
    'inline-flex items-center justify-center font-medium transition-all duration-200',
    FOCUS_RING
  )

  if (variant === 'ghost') {
    return cn(
      base,
      'p-1.5 text-gray-500 hover:text-red-400 hover:bg-red-400/10 rounded-lg',
      className
    )
  }

  if (variant === 'secondary') {
    return cn(
      base,
      SIZE_CLASSES[size],
      'border border-dark-500 bg-dark-700 text-gray-300 hover:bg-dark-600 hover:text-white',
      className
    )
  }

  if (variant === 'filter') {
    const filterSize = 'px-5 py-2.5 rounded-xl'
    if (active) {
      const gradient = GRADIENT_COLORS.primary
      return cn(
        base,
        filterSize,
        'filter-btn active bg-gradient-to-r text-white',
        gradient.from,
        gradient.to,
        gradient.hoverFrom,
        gradient.hoverTo,
        gradient.shadow,
        className
      )
    }
    return cn(
      base,
      filterSize,
      'filter-btn border border-dark-700 bg-transparent text-gray-400 hover:text-gray-200 hover:border-dark-500 hover:bg-dark-800/50',
      className
    )
  }

  const gradient = GRADIENT_COLORS[variant === 'danger' ? 'red' : color]
  return cn(
    base,
    SIZE_CLASSES[size],
    'bg-gradient-to-r text-white',
    gradient.from,
    gradient.to,
    gradient.hoverFrom,
    gradient.hoverTo,
    'hover:scale-105',
    size !== 'sm' && 'hover:shadow-lg',
    size !== 'sm' && gradient.shadow,
    'disabled:opacity-60 disabled:hover:scale-100',
    className
  )
}
