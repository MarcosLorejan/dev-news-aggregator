import Button from './ui/Button'
import Card from './ui/Card'

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
  return (
    <Card tone="subtle" className="mb-8">
      <h2 className="text-h3 text-gray-100 mb-4">Filter by score</h2>
      <div className="flex flex-wrap gap-3">
        {OPTIONS.map((option) => (
          <Button
            key={option.value}
            variant="filter"
            active={activeScoreFilter === option.value}
            data-score-filter={option.value}
            aria-pressed={activeScoreFilter === option.value}
            onClick={() => onScoreFilterChange(option.value)}
          >
            {option.label}
          </Button>
        ))}
      </div>
    </Card>
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
