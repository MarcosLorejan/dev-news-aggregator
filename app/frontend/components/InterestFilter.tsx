import type { KeywordFilter } from '../types/keywordFilter'
import Button from './ui/Button'
import Card from './ui/Card'

interface InterestFilterProps {
  interests: KeywordFilter[]
  selectedSlugs: string[]
  onToggle: (slug: string) => void
  onClear: () => void
  embedded?: boolean
}

export default function InterestFilter({
  interests,
  selectedSlugs,
  onToggle,
  onClear,
  embedded = false,
}: InterestFilterProps) {
  if (interests.length === 0) return null

  const body = (
    <>
      <div className={`flex items-center justify-between gap-4 ${embedded ? 'mb-3' : 'mb-4'}`}>
        <h2 className={embedded ? 'text-sm font-medium text-gray-200' : 'text-h3 text-gray-100'}>
          Filter by interest
        </h2>
        {selectedSlugs.length > 0 && (
          <button
            type="button"
            className="text-sm text-gray-300 underline hover:text-white"
            data-testid="clear-interests"
            onClick={onClear}
          >
            Clear interests
          </button>
        )}
      </div>
      <div className="flex flex-wrap gap-2">
        {interests.map((interest) => {
          const selected = selectedSlugs.includes(interest.slug)
          return (
            <Button
              key={interest.slug}
              variant="filter"
              active={selected}
              className={embedded ? '!px-3 !py-1.5 text-sm' : undefined}
              data-filter-type="interest"
              data-filter-value={interest.slug}
              aria-pressed={selected}
              onClick={() => onToggle(interest.slug)}
            >
              {interest.article_count === null
                ? interest.name
                : `${interest.name} (${interest.article_count})`}
            </Button>
          )
        })}
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

export function parseInterests(value: string | null): string[] {
  if (!value) return []

  return [...new Set(value.split(',').map((slug) => slug.trim().toLowerCase()).filter(Boolean))]
}

export function toggleInterest(slugs: string[], slug: string): string[] {
  return slugs.includes(slug) ? slugs.filter((current) => current !== slug) : [...slugs, slug]
}
