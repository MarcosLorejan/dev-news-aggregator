import Button from './ui/Button'
import Card from './ui/Card'

export interface TopicTagOption {
  slug: string
  name: string
}

interface TopicFilterProps {
  tags: TopicTagOption[]
  activeTag: string
  onTagChange: (slug: string) => void
}

export default function TopicFilter({ tags, activeTag, onTagChange }: TopicFilterProps) {
  if (tags.length === 0) return null

  return (
    <div className="mb-8">
      <Card tone="subtle">
        <h2 className="text-h3 text-gray-100 mb-4">Filter by topic</h2>
        <div className="flex flex-wrap gap-3">
          <Button
            variant="filter"
            active={activeTag === 'all'}
            data-filter-type="tag"
            data-filter-value="all"
            aria-pressed={activeTag === 'all'}
            onClick={() => onTagChange('all')}
          >
            All topics
          </Button>
          {tags.map((tag) => (
            <Button
              key={tag.slug}
              variant="filter"
              active={activeTag === tag.slug}
              data-filter-type="tag"
              data-filter-value={tag.slug}
              aria-pressed={activeTag === tag.slug}
              onClick={() => onTagChange(tag.slug)}
            >
              {tag.name}
            </Button>
          ))}
        </div>
      </Card>
    </div>
  )
}
