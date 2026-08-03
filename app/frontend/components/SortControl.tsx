import Button from './ui/Button'
import Card from './ui/Card'

export type SortValue = 'published_at' | 'for_you' | 'score' | 'comment_count'

interface SortControlProps {
  activeSort: SortValue
  onSortChange: (value: SortValue) => void
  embedded?: boolean
}

export const SORT_OPTIONS: { value: SortValue; label: string }[] = [
  { value: 'published_at', label: 'Newest' },
  { value: 'for_you', label: 'For you' },
  { value: 'score', label: 'Highest score' },
  { value: 'comment_count', label: 'Most comments' },
]

const SORT_VALUES: SortValue[] = SORT_OPTIONS.map((option) => option.value)

export default function SortControl({
  activeSort,
  onSortChange,
  embedded = false,
}: SortControlProps) {
  const body = (
    <>
      {!embedded && <h2 className="mb-4 text-h3 text-gray-100">Sort by</h2>}
      <div className="flex flex-wrap gap-2" role={embedded ? 'listbox' : undefined} aria-label={embedded ? 'Sort by' : undefined}>
        {SORT_OPTIONS.map((option) => (
          <Button
            key={option.value}
            variant="filter"
            active={activeSort === option.value}
            className={embedded ? '!px-3 !py-1.5 text-sm' : undefined}
            data-sort={option.value}
            aria-pressed={activeSort === option.value}
            onClick={() => onSortChange(option.value)}
          >
            {option.label}
          </Button>
        ))}
      </div>
    </>
  )

  if (embedded) return <div>{body}</div>

  return (
    <Card tone="subtle" className="mb-8">
      {body}
    </Card>
  )
}

export function parseSort(value: string | null): SortValue {
  if (value && SORT_VALUES.includes(value as SortValue)) {
    return value as SortValue
  }
  return 'published_at'
}
