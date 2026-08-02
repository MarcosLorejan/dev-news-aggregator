import Button from './ui/Button'
import Card from './ui/Card'

export type ContentTypeFilterValue = 'all' | 'article' | 'video'
export type MaxDurationFilterValue = 'all' | '5' | '10' | '20'

interface ContentTypeFilterProps {
  activeContentType: ContentTypeFilterValue
  activeMaxDuration: MaxDurationFilterValue
  onContentTypeChange: (value: ContentTypeFilterValue) => void
  onMaxDurationChange: (value: MaxDurationFilterValue) => void
}

const TYPE_OPTIONS: { value: ContentTypeFilterValue; label: string }[] = [
  { value: 'all', label: 'All' },
  { value: 'article', label: 'Articles' },
  { value: 'video', label: 'Videos' },
]

const DURATION_OPTIONS: { value: MaxDurationFilterValue; label: string }[] = [
  { value: 'all', label: 'Any length' },
  { value: '5', label: '≤ 5 min' },
  { value: '10', label: '≤ 10 min' },
  { value: '20', label: '≤ 20 min' },
]

export default function ContentTypeFilter({
  activeContentType,
  activeMaxDuration,
  onContentTypeChange,
  onMaxDurationChange,
}: ContentTypeFilterProps) {
  return (
    <Card tone="subtle" className="mb-8">
      <h2 className="text-h3 text-gray-100 mb-4">Filter by content</h2>
      <div className="flex flex-wrap gap-3 mb-4">
        {TYPE_OPTIONS.map((option) => (
          <Button
            key={option.value}
            variant="filter"
            active={activeContentType === option.value}
            data-content-type-filter={option.value}
            aria-pressed={activeContentType === option.value}
            onClick={() => onContentTypeChange(option.value)}
          >
            {option.label}
          </Button>
        ))}
      </div>
      <h3 className="text-sm font-medium text-gray-300 mb-3">Max video length</h3>
      <div className="flex flex-wrap gap-3">
        {DURATION_OPTIONS.map((option) => (
          <Button
            key={option.value}
            variant="filter"
            active={activeMaxDuration === option.value}
            data-max-duration-filter={option.value}
            aria-pressed={activeMaxDuration === option.value}
            onClick={() => onMaxDurationChange(option.value)}
          >
            {option.label}
          </Button>
        ))}
      </div>
    </Card>
  )
}

export function contentTypeFilterParams(value: ContentTypeFilterValue): {
  content_type?: 'article' | 'video'
} {
  if (value === 'all') return {}
  return { content_type: value }
}

export function maxDurationFilterParams(value: MaxDurationFilterValue): {
  max_duration?: number
} {
  if (value === 'all') return {}
  return { max_duration: Number(value) }
}

const CONTENT_TYPE_VALUES: ContentTypeFilterValue[] = ['all', 'article', 'video']
const MAX_DURATION_VALUES: MaxDurationFilterValue[] = ['all', '5', '10', '20']

export function parseContentTypeFilter(value: string | null): ContentTypeFilterValue {
  if (value && CONTENT_TYPE_VALUES.includes(value as ContentTypeFilterValue)) {
    return value as ContentTypeFilterValue
  }
  return 'all'
}

export function parseMaxDurationFilter(value: string | null): MaxDurationFilterValue {
  if (value && MAX_DURATION_VALUES.includes(value as MaxDurationFilterValue)) {
    return value as MaxDurationFilterValue
  }
  return 'all'
}
