import type { ReactNode } from 'react'
import { Link } from 'react-router-dom'
import type { ButtonColor } from './ui/buttonStyles'
import { buttonClassName } from './ui/Button'
import Card from './ui/Card'

interface EmptyStateAction {
  href: string
  label: string
  color?: ButtonColor
  icon?: ReactNode
}

interface EmptyStateProps {
  icon: ReactNode
  iconWrapperClassName?: string
  title: string
  description: string
  actions?: EmptyStateAction[]
}

export default function EmptyState({
  icon,
  iconWrapperClassName = 'bg-gradient-to-r from-primary-600/20 to-primary-700/20',
  title,
  description,
  actions = [],
}: EmptyStateProps) {
  return (
    <Card tone="panel" padding="empty" animate>
      <div
        className={`w-20 h-20 mx-auto mb-6 rounded-full flex items-center justify-center ${iconWrapperClassName}`}
      >
        {icon}
      </div>
      <h2 className="text-h2 text-gray-100 mb-4">{title}</h2>
      <p className="text-body text-gray-400 mb-8 max-w-prose mx-auto leading-relaxed">{description}</p>
      {actions.length > 0 && (
        <div
          className={
            actions.length > 1
              ? 'flex flex-col sm:flex-row gap-4 justify-center'
              : 'flex justify-center'
          }
        >
          {actions.map((action) => (
            <Link
              key={`${action.href}-${action.label}`}
              to={action.href}
              className={buttonClassName({ size: 'lg', color: action.color ?? 'primary' })}
            >
              {action.icon}
              {action.label}
            </Link>
          ))}
        </div>
      )}
    </Card>
  )
}
