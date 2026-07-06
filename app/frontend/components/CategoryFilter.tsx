import type { Category } from '../types/article'
import { parameterize } from '../utils/format'

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
  const activeClasses =
    'filter-btn active px-5 py-2.5 bg-gradient-to-r from-primary-600 to-primary-700 text-white rounded-xl font-medium transition-all duration-200 hover:from-primary-700 hover:to-primary-800 hover:scale-105 hover:shadow-lg hover:shadow-primary-500/25'
  const inactiveClasses =
    'filter-btn px-5 py-2.5 bg-dark-800 border border-dark-700 text-gray-300 rounded-xl font-medium transition-all duration-200 hover:bg-dark-700 hover:border-primary-500 hover:text-white hover:scale-105 hover:shadow-lg hover:shadow-primary-500/10'

  return (
    <div className="mb-8 animate-slide-up">
      <div className="glass-effect rounded-2xl p-6">
        <h3 className="text-lg font-semibold text-gray-200 mb-4 flex items-center">
          <svg className="w-5 h-5 mr-2 text-primary-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.707A1 1 0 013 7V4z" />
          </svg>
          Filter by Category
        </h3>
        <div className="flex flex-wrap gap-3">
          <button
            type="button"
            className={activeFilter === 'all' ? activeClasses : inactiveClasses}
            data-filter-type="all"
            data-filter-value="all"
            aria-pressed={activeFilter === 'all'}
            onClick={() => onFilterChange('all')}
          >
            <span className="flex items-center">
              <span className="w-2 h-2 bg-white rounded-full mr-2" />
              All Articles ({totalCount})
            </span>
          </button>
          {categories.map((category) => {
            const slug = parameterize(category.name)
            const count = categoryCounts[category.name] ?? 0
            return (
              <button
                key={category.name}
                type="button"
                className={activeFilter === slug ? activeClasses : inactiveClasses}
                data-filter-type="category"
                data-filter-value={slug}
                aria-pressed={activeFilter === slug}
                onClick={() => onFilterChange(slug)}
              >
                <span className="flex items-center">
                  <span className="text-lg mr-2">{category.icon}</span>
                  {category.name} ({count})
                </span>
              </button>
            )
          })}
        </div>
      </div>
    </div>
  )
}
