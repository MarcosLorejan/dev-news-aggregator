import type { Category } from '../types/article'
import { parameterize } from '../utils/format'
import Button from './ui/Button'
import Card from './ui/Card'

interface CategoryFilterProps {
  categories: Category[]
  categoryCounts: Record<string, number>
  totalCount: number
  activeFilter: string
  onFilterChange: (filter: string) => void
  embedded?: boolean
}

export default function CategoryFilter({
  categories,
  categoryCounts,
  totalCount,
  activeFilter,
  onFilterChange,
  embedded = false,
}: CategoryFilterProps) {
  const body = (
    <>
      <h2
        className={
          embedded
            ? 'mb-3 flex items-center text-sm font-medium text-gray-200'
            : 'mb-4 flex items-center text-h3 text-gray-100'
        }
      >
        <svg
          className="mr-2 h-4 w-4 text-primary-400"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
          aria-hidden="true"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth="2"
            d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.707A1 1 0 013 7V4z"
          />
        </svg>
        Filter by source
      </h2>
      {embedded && (
        <p className="mb-3 text-xs text-gray-400">Where it came from (HN, Reddit, Dev.to, …)</p>
      )}
      <div className="flex flex-wrap gap-2">
        <Button
          variant="filter"
          active={activeFilter === 'all'}
          className={embedded ? '!px-3 !py-1.5 text-sm' : undefined}
          data-filter-type="all"
          data-filter-value="all"
          aria-pressed={activeFilter === 'all'}
          onClick={() => onFilterChange('all')}
        >
          <span className="flex items-center">
            <span className="mr-2 h-2 w-2 rounded-full bg-white" />
            All Articles ({totalCount})
          </span>
        </Button>
        {categories.map((category) => {
          const slug = parameterize(category.name)
          const count = categoryCounts[category.name] ?? 0
          return (
            <Button
              key={category.name}
              variant="filter"
              active={activeFilter === slug}
              className={embedded ? '!px-3 !py-1.5 text-sm' : undefined}
              data-filter-type="category"
              data-filter-value={slug}
              aria-pressed={activeFilter === slug}
              onClick={() => onFilterChange(slug)}
            >
              <span className="flex items-center">
                <span
                  className="mr-2 inline-flex w-5 items-center justify-center text-base leading-none"
                  aria-hidden="true"
                >
                  {category.icon}
                </span>
                {category.name} ({count})
              </span>
            </Button>
          )
        })}
      </div>
    </>
  )

  if (embedded) return <div>{body}</div>

  return (
    <div className="mb-8">
      <Card tone="subtle">{body}</Card>
    </div>
  )
}
