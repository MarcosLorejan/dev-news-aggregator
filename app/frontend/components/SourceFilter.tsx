import { humanizeSourceType } from '../utils/format'
import Button from './ui/Button'
import Card from './ui/Card'

interface SourceFilterProps {
  sources: string[]
  sourceCounts: Record<string, number>
  totalCount: number
  activeSource: string
  onSourceChange: (source: string) => void
}

export default function SourceFilter({
  sources,
  sourceCounts,
  totalCount,
  activeSource,
  onSourceChange,
}: SourceFilterProps) {
  return (
    <div className="mb-8">
      <Card tone="subtle">
        <h3 className="text-lg font-semibold text-gray-200 mb-4 flex items-center">
          <svg className="w-5 h-5 mr-2 text-primary-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.707A1 1 0 013 7V4z" />
          </svg>
          Filter by Source
        </h3>
        <div className="flex flex-wrap gap-3">
          <Button
            variant="filter"
            active={activeSource === 'all'}
            data-source="all"
            aria-pressed={activeSource === 'all'}
            onClick={() => onSourceChange('all')}
          >
            <span className="flex items-center">
              <span className="w-2 h-2 bg-white rounded-full mr-2" />
              All Sources ({totalCount})
            </span>
          </Button>
          {sources.map((source) => (
            <Button
              key={source}
              variant="filter"
              active={activeSource === source}
              data-source={source}
              aria-pressed={activeSource === source}
              onClick={() => onSourceChange(source)}
            >
              {humanizeSourceType(source)} ({sourceCounts[source] ?? 0})
            </Button>
          ))}
        </div>
      </Card>
    </div>
  )
}
