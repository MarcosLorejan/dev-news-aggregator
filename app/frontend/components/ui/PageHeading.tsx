import type { ReactNode } from 'react'
import Card from './Card'

interface PageHeadingProps {
  title: string
  subtitle?: string
  titleClassName?: string
  actions?: ReactNode
  meta?: ReactNode
}

export default function PageHeading({
  title,
  subtitle,
  titleClassName = 'text-gray-100',
  actions,
  meta,
}: PageHeadingProps) {
  return (
    <Card padding="lg" tone="elevated" className="mb-8" animate>
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 md:gap-6">
        <div>
          <h1 className={`text-3xl md:text-4xl font-bold mb-2 ${titleClassName}`}>{title}</h1>
          {subtitle && <p className="text-gray-400 text-base md:text-lg">{subtitle}</p>}
        </div>
        {(actions || meta) && (
          <div className="flex flex-wrap items-center gap-3 md:gap-4">
            {actions}
            {meta}
          </div>
        )}
      </div>
    </Card>
  )
}
