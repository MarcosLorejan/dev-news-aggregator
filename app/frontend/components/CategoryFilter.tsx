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
}

export default function CategoryFilter({
  categories,
  categoryCounts,
  totalCount,
  activeFilter,
  onFilterChange,
}: CategoryFilterProps) {
  return (
    <div className="mb-8">
      <Card tone="subtle">
        <h2 className="text-h3 text-gray-100 mb-4 flex items-center">
          <svg className="w-5 h-5 mr-2 text-primary-400" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.707A1 1 0 013 7V4z" />
          </svg>
          Filter by Category
        </h2>
        <div className="flex flex-wrap gap-3">
          <Button
            variant="filter"
            active={activeFilter === 'all'}
            data-filter-type="all"
            data-filter-value="all"
            aria-pressed={activeFilter === 'all'}
            onClick={() => onFilterChange('all')}
          >
            <span className="flex items-center">
              <span className="w-2 h-2 bg-white rounded-full mr-2" />
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
                data-filter-type="category"
                data-filter-value={slug}
                aria-pressed={activeFilter === slug}
                onClick={() => onFilterChange(slug)}
              >
                <span className="flex items-center">
                  <span className="inline-flex items-center justify-center w-5 text-base leading-none mr-2" aria-hidden="true">
                    {category.icon}
                  </span>
                  {category.name} ({count})
                </span>
              </Button>
            )
          })}
        </div>
      </Card>
    </div>
  )
}
