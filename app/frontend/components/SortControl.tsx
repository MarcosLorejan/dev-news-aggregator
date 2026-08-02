import Button from './ui/Button'
import Card from './ui/Card'

export type SortValue = 'published_at' | 'for_you' | 'score' | 'comment_count'

interface SortControlProps {
  activeSort: SortValue
  onSortChange: (value: SortValue) => void
}

const OPTIONS: { value: SortValue; label: string }[] = [
  { value: 'published_at', label: 'Newest' },
  { value: 'for_you', label: 'For you' },
  { value: 'score', label: 'Highest score' },
  { value: 'comment_count', label: 'Most comments' },
]

const SORT_VALUES: SortValue[] = OPTIONS.map((option) => option.value)

export default function SortControl({ activeSort, onSortChange }: SortControlProps) {
  return (
    <Card tone="subtle" className="mb-8">
      <h2 className="text-h3 text-gray-100 mb-4">Sort by</h2>
      <div className="flex flex-wrap gap-3">
        {OPTIONS.map((option) => (
          <Button
            key={option.value}
            variant="filter"
            active={activeSort === option.value}
            data-sort={option.value}
            aria-pressed={activeSort === option.value}
            onClick={() => onSortChange(option.value)}
          >
            {option.label}
          </Button>
        ))}
      </div>
    </Card>
  )
}

export function parseSort(value: string | null): SortValue {
  if (value && SORT_VALUES.includes(value as SortValue)) {
    return value as SortValue
  }
  return 'published_at'
}
