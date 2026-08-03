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
  embedded?: boolean
}

export default function TopicFilter({
  tags,
  activeTag,
  onTagChange,
  embedded = false,
}: TopicFilterProps) {
  if (tags.length === 0) return null

  const body = (
    <>
      <h2 className={embedded ? 'mb-3 text-sm font-medium text-gray-200' : 'mb-4 text-h3 text-gray-100'}>
        Filter by topic
      </h2>
      <div className="flex flex-wrap gap-2">
        <Button
          variant="filter"
          active={activeTag === 'all'}
          className={embedded ? '!px-3 !py-1.5 text-sm' : undefined}
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
            className={embedded ? '!px-3 !py-1.5 text-sm' : undefined}
            data-filter-type="tag"
            data-filter-value={tag.slug}
            aria-pressed={activeTag === tag.slug}
            onClick={() => onTagChange(tag.slug)}
          >
            {tag.name}
          </Button>
        ))}
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
