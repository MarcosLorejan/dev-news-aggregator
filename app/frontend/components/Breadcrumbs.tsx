import { Link } from 'react-router-dom'
import { cn } from '../utils/cn'
import { FOCUS_RING } from './ui/buttonStyles'

export interface BreadcrumbItem {
  label: string
  to?: string
}

interface BreadcrumbsProps {
  items: BreadcrumbItem[]
  className?: string
}

const LINK_CLASS = cn('text-gray-400 hover:text-gray-200 transition-colors rounded', FOCUS_RING)

function shouldCollapseMobile(items: BreadcrumbItem[]) {
  if (items.length > 2) return true
  return items[items.length - 1].label.length > 36
}

export default function Breadcrumbs({ items, className }: BreadcrumbsProps) {
  if (items.length === 0) return null

  const collapse = shouldCollapseMobile(items)
  const parent = items.length >= 2 ? items[items.length - 2] : null
  const current = items[items.length - 1]

  return (
    <nav aria-label="Breadcrumb" className={cn('mb-4', className)} data-testid="breadcrumbs">
      <ol
        className={cn(
          'flex items-center flex-wrap gap-x-2 gap-y-1 text-sm text-gray-500 list-none p-0 m-0',
          collapse && 'hidden sm:flex'
        )}
      >
        {items.map((item, index) => {
          const isLast = index === items.length - 1
          const isLink = Boolean(item.to) && !isLast

          return (
            <li key={`${item.label}-${index}`} className="inline-flex items-center gap-2 min-w-0 max-w-full">
              {index > 0 && (
                <span aria-hidden="true" className="text-gray-600">
                  /
                </span>
              )}
              {isLink ? (
                <Link to={item.to!} className={LINK_CLASS}>
                  {item.label}
                </Link>
              ) : (
                <span
                  className={cn('truncate', isLast && 'text-gray-300')}
                  aria-current={isLast ? 'page' : undefined}
                >
                  {item.label}
                </span>
              )}
            </li>
          )
        })}
      </ol>

      {collapse && parent?.to && (
        <div className="flex sm:hidden items-center gap-2 text-sm min-w-0" data-testid="breadcrumbs-mobile">
          <Link to={parent.to} className={cn(LINK_CLASS, 'shrink-0')} data-testid="breadcrumbs-back">
            ← Back
          </Link>
          <span aria-hidden="true" className="text-gray-600">
            ·
          </span>
          <span className="text-gray-300 truncate" aria-current="page">
            {current.label}
          </span>
        </div>
      )}
    </nav>
  )
}
