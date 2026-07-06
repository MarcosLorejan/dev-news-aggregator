export type ScoreFilterValue = 'all' | '50' | '100' | '500' | 'top10'

interface ScoreFilterProps {
  activeScoreFilter: ScoreFilterValue
  onScoreFilterChange: (value: ScoreFilterValue) => void
}

const OPTIONS: { value: ScoreFilterValue; label: string }[] = [
  { value: 'all', label: 'All scores' },
  { value: 'top10', label: 'Top 10%' },
  { value: '50', label: 'Score > 50' },
  { value: '100', label: 'Score > 100' },
  { value: '500', label: 'Score > 500' },
]

export default function ScoreFilter({ activeScoreFilter, onScoreFilterChange }: ScoreFilterProps) {
  const activeClasses =
    'px-4 py-2 rounded-xl text-sm font-medium bg-gradient-to-r from-primary-600 to-primary-700 text-white shadow-lg shadow-primary-500/20'
  const inactiveClasses =
    'px-4 py-2 rounded-xl text-sm font-medium bg-dark-800 border border-dark-700 text-gray-400 hover:text-gray-200 hover:border-dark-600 transition-colors'

  return (
    <div className="glass-effect rounded-2xl p-6 mb-8 animate-fade-in">
      <h2 className="text-lg font-semibold text-gray-200 mb-4">Filter by score</h2>
      <div className="flex flex-wrap gap-3">
        {OPTIONS.map((option) => (
          <button
            key={option.value}
            type="button"
            className={activeScoreFilter === option.value ? activeClasses : inactiveClasses}
            data-score-filter={option.value}
            onClick={() => onScoreFilterChange(option.value)}
          >
            {option.label}
          </button>
        ))}
      </div>
    </div>
  )
}

export function scoreFilterParams(value: ScoreFilterValue): { min_score?: number; top_percent?: number } {
  switch (value) {
    case '50':
      return { min_score: 50 }
    case '100':
      return { min_score: 100 }
    case '500':
      return { min_score: 500 }
    case 'top10':
      return { top_percent: 10 }
    default:
      return {}
  }
}

const SCORE_FILTER_VALUES: ScoreFilterValue[] = ['all', '50', '100', '500', 'top10']

export function parseScoreFilter(value: string | null): ScoreFilterValue {
  if (value && SCORE_FILTER_VALUES.includes(value as ScoreFilterValue)) {
    return value as ScoreFilterValue
  }
  return 'all'
}
