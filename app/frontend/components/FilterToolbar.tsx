import type { Category } from '../types/article'
import type { KeywordFilter } from '../types/keywordFilter'
import { parameterize } from '../utils/format'
import CategoryFilter from './CategoryFilter'
import ContentTypeFilter, {
  type ContentTypeFilterValue,
  type MaxDurationFilterValue,
} from './ContentTypeFilter'
import FilterMenu from './FilterMenu'
import InterestFilter from './InterestFilter'
import ScoreFilter, { SCORE_FILTER_OPTIONS, type ScoreFilterValue } from './ScoreFilter'
import SortControl, { SORT_OPTIONS, type SortValue } from './SortControl'
import TopicFilter, { type TopicTagOption } from './TopicFilter'
import { FOCUS_RING } from './ui/buttonStyles'
import Card from './ui/Card'

interface ActiveChip {
  key: string
  label: string
  onClear: () => void
}

interface FilterToolbarProps {
  searchValue: string
  onSearchChange: (value: string) => void
  interests: KeywordFilter[]
  selectedInterestSlugs: string[]
  onInterestToggle: (slug: string) => void
  onInterestsClear: () => void
  activeScoreFilter: ScoreFilterValue
  onScoreFilterChange: (value: ScoreFilterValue) => void
  activeContentType: ContentTypeFilterValue
  activeMaxDuration: MaxDurationFilterValue
  onContentTypeChange: (value: ContentTypeFilterValue) => void
  onMaxDurationChange: (value: MaxDurationFilterValue) => void
  activeSort: SortValue
  onSortChange: (value: SortValue) => void
  categories: Category[]
  categoryCounts: Record<string, number>
  totalCount: number
  activeCategory: string
  onCategoryChange: (filter: string) => void
  topicTags: TopicTagOption[]
  activeTag: string
  onTagChange: (slug: string) => void
  onClearAllFilters: () => void
}

function contentTypeLabel(value: ContentTypeFilterValue): string {
  switch (value) {
    case 'article':
      return 'Articles'
    case 'video':
      return 'Videos'
    default:
      return 'All'
  }
}

function durationLabel(value: MaxDurationFilterValue): string {
  switch (value) {
    case '5':
      return '≤ 5 min'
    case '10':
      return '≤ 10 min'
    case '20':
      return '≤ 20 min'
    default:
      return 'Any length'
  }
}

export default function FilterToolbar({
  searchValue,
  onSearchChange,
  interests,
  selectedInterestSlugs,
  onInterestToggle,
  onInterestsClear,
  activeScoreFilter,
  onScoreFilterChange,
  activeContentType,
  activeMaxDuration,
  onContentTypeChange,
  onMaxDurationChange,
  activeSort,
  onSortChange,
  categories,
  categoryCounts,
  totalCount,
  activeCategory,
  onCategoryChange,
  topicTags,
  activeTag,
  onTagChange,
  onClearAllFilters,
}: FilterToolbarProps) {
  const sortLabel = SORT_OPTIONS.find((option) => option.value === activeSort)?.label ?? 'Newest'
  const scoreLabel =
    SCORE_FILTER_OPTIONS.find((option) => option.value === activeScoreFilter)?.label ?? 'All scores'

  const activeCategoryName =
    activeCategory === 'all'
      ? null
      : categories.find((category) => parameterize(category.name) === activeCategory)?.name ??
        activeCategory

  const activeTagName =
    activeTag === 'all' ? null : topicTags.find((tag) => tag.slug === activeTag)?.name ?? activeTag

  const interestNames = selectedInterestSlugs.map(
    (slug) => interests.find((interest) => interest.slug === slug)?.name ?? slug
  )

  const filterCount = [
    selectedInterestSlugs.length > 0,
    activeScoreFilter !== 'all',
    activeContentType !== 'all',
    activeMaxDuration !== 'all',
    activeCategory !== 'all',
    activeTag !== 'all',
  ].filter(Boolean).length

  const filtersActive = filterCount > 0

  const filtersSummary =
    filterCount === 0 ? undefined : filterCount === 1 ? '1 active' : `${filterCount} active`

  const activeChips: ActiveChip[] = [
    ...interestNames.map((name, index) => ({
      key: `interest-${selectedInterestSlugs[index]}`,
      label: name,
      onClear: () => onInterestToggle(selectedInterestSlugs[index]),
    })),
    ...(activeScoreFilter !== 'all'
      ? [
          {
            key: 'score',
            label: scoreLabel,
            onClear: () => onScoreFilterChange('all'),
          },
        ]
      : []),
    ...(activeContentType !== 'all'
      ? [
          {
            key: 'content-type',
            label: contentTypeLabel(activeContentType),
            onClear: () => onContentTypeChange('all'),
          },
        ]
      : []),
    ...(activeMaxDuration !== 'all'
      ? [
          {
            key: 'max-duration',
            label: durationLabel(activeMaxDuration),
            onClear: () => onMaxDurationChange('all'),
          },
        ]
      : []),
    ...(activeCategoryName
      ? [
          {
            key: 'category',
            label: activeCategoryName,
            onClear: () => onCategoryChange('all'),
          },
        ]
      : []),
    ...(activeTagName
      ? [
          {
            key: 'tag',
            label: activeTagName,
            onClear: () => onTagChange('all'),
          },
        ]
      : []),
  ]

  return (
    <div className="mb-6" data-testid="filter-toolbar">
      <Card tone="subtle" padding="sm">
        <div className="flex flex-col gap-3 lg:flex-row lg:items-center">
          <div className="relative min-w-0 flex-1">
            <label htmlFor="article-search" className="sr-only">
              Search articles
            </label>
            <svg
              className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-500"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
              aria-hidden="true"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
              />
            </svg>
            <input
              id="article-search"
              type="search"
              value={searchValue}
              onChange={(event) => onSearchChange(event.target.value)}
              placeholder="Search by title or description"
              className={`w-full rounded-lg border border-dark-700 bg-dark-800 py-2 pl-9 pr-3 text-sm text-gray-200 placeholder-gray-500 ${FOCUS_RING} focus-visible:border-primary-500`}
              data-testid="article-search-input"
              autoComplete="off"
            />
          </div>

          <div className="flex flex-wrap items-center gap-2">
            <FilterMenu
              label="Sort"
              summary={sortLabel}
              active={activeSort !== 'published_at'}
              testId="sort-menu"
            >
              <SortControl embedded activeSort={activeSort} onSortChange={onSortChange} />
            </FilterMenu>

            <FilterMenu
              label="Filters"
              summary={filtersSummary}
              active={filtersActive}
              align="right"
              panelClassName="w-[min(36rem,calc(100vw-2rem))] max-h-[70vh] overflow-y-auto"
              testId="filters-menu"
            >
              <div className="space-y-5">
                <InterestFilter
                  embedded
                  interests={interests}
                  selectedSlugs={selectedInterestSlugs}
                  onToggle={onInterestToggle}
                  onClear={onInterestsClear}
                />
                <ScoreFilter
                  embedded
                  activeScoreFilter={activeScoreFilter}
                  onScoreFilterChange={onScoreFilterChange}
                />
                <ContentTypeFilter
                  embedded
                  activeContentType={activeContentType}
                  activeMaxDuration={activeMaxDuration}
                  onContentTypeChange={onContentTypeChange}
                  onMaxDurationChange={onMaxDurationChange}
                />
                <CategoryFilter
                  embedded
                  categories={categories}
                  categoryCounts={categoryCounts}
                  totalCount={totalCount}
                  activeFilter={activeCategory}
                  onFilterChange={onCategoryChange}
                />
                <TopicFilter
                  embedded
                  tags={topicTags}
                  activeTag={activeTag}
                  onTagChange={onTagChange}
                />
              </div>
            </FilterMenu>
          </div>
        </div>

        {activeChips.length > 0 && (
          <div
            className="mt-3 flex flex-wrap items-center gap-2 border-t border-dark-700 pt-3"
            data-testid="active-filter-chips"
          >
            {activeChips.map((chip) => (
              <button
                key={chip.key}
                type="button"
                className={`inline-flex items-center gap-1.5 rounded-full border border-primary-500/40 bg-primary-600/15 px-2.5 py-1 text-xs text-primary-100 hover:bg-primary-600/25 ${FOCUS_RING}`}
                onClick={chip.onClear}
                aria-label={`Clear filter ${chip.label}`}
              >
                {chip.label}
                <span aria-hidden="true">×</span>
              </button>
            ))}
            <button
              type="button"
              className={`rounded text-xs text-gray-400 underline hover:text-white ${FOCUS_RING}`}
              data-testid="clear-all-filters"
              onClick={onClearAllFilters}
            >
              Clear all
            </button>
          </div>
        )}
      </Card>
    </div>
  )
}
