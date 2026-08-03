import { useCallback, useEffect, useState } from 'react'
import {
  addRedditSource,
  addYoutubeSource,
  fetchSources,
  removeSource,
  updateSource,
  type NewsSource,
  type SourceLastFetch,
} from '../api/sources'
import { useConfirmDialog } from '../hooks/useConfirmDialog'
import Badge from '../components/ui/Badge'
import Button from '../components/ui/Button'
import Card from '../components/ui/Card'
import PageContainer from '../components/ui/PageContainer'
import Breadcrumbs from '../components/Breadcrumbs'
import { sourcesBreadcrumbs } from '../components/breadcrumbTrails'
import SourcesIndexSkeleton from '../components/SourcesIndexSkeleton'
import PageHeading from '../components/ui/PageHeading'
import { formatTimeAgo } from '../utils/format'

type AddSourceType = 'reddit' | 'youtube'

function sourceLabel(source: NewsSource): string {
  if (source.source_type === 'reddit') {
    return `r/${source.subreddit ?? source.name}`
  }
  if (source.source_type === 'youtube') {
    return source.channel_name || source.name
  }
  return source.name
}

function SourceFetchStatus({ lastFetch }: { lastFetch: SourceLastFetch | null }) {
  if (!lastFetch) {
    return (
      <p className="text-caption text-gray-500 mt-1" data-testid="source-fetch-status">
        Never fetched
      </p>
    )
  }

  const ok = lastFetch.status === 'success'
  const empty = Boolean(lastFetch.empty)
  const duration =
    lastFetch.duration_seconds == null ? null : `${lastFetch.duration_seconds.toFixed(1)}s`
  const successRate =
    lastFetch.success_rate == null ? null : `${lastFetch.success_rate}% success`

  return (
    <div className="mt-1 space-y-1" data-testid="source-fetch-status">
      <div className="flex flex-wrap items-center gap-2">
        <Badge variant={ok ? (empty ? 'orange' : 'green') : 'red'} size="sm">
          {ok ? (empty ? 'Empty' : 'Ok') : 'Error'}
        </Badge>
        <span className="text-caption text-gray-500">
          Last fetch {formatTimeAgo(lastFetch.finished_at)}
        </span>
      </div>
      <p className="text-caption text-gray-500" data-testid="source-fetch-metrics">
        {[
          `${lastFetch.articles_count} articles`,
          duration,
          successRate,
          lastFetch.last_article_at
            ? `last article ${formatTimeAgo(lastFetch.last_article_at)}`
            : 'no articles yet',
        ]
          .filter(Boolean)
          .join(' · ')}
      </p>
      {!ok && lastFetch.error_message && (
        <p className="text-caption text-red-400" data-testid="source-fetch-error">
          {lastFetch.error_message}
        </p>
      )}
      {ok && empty && (
        <p className="text-caption text-orange-400" data-testid="source-fetch-empty">
          Fetch succeeded with zero articles
        </p>
      )}
    </div>
  )
}

export default function SourcesIndexPage() {
  const [sources, setSources] = useState<NewsSource[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [addType, setAddType] = useState<AddSourceType>('reddit')
  const [sourceInput, setSourceInput] = useState('')
  const [adding, setAdding] = useState(false)
  const [validationError, setValidationError] = useState<string | null>(null)
  const { confirm, dialog } = useConfirmDialog()

  const loadSources = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const response = await fetchSources()
      setSources(response.sources)
    } catch {
      setError('Failed to load news sources.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    loadSources()
  }, [loadSources])

  const handleToggle = async (source: NewsSource) => {
    try {
      const updated = await updateSource(source.id, !source.active)
      setSources((current) => current.map((item) => (item.id === updated.id ? updated : item)))
    } catch {
      setError('Failed to update source.')
    }
  }

  const handleAddSource = async (event: React.FormEvent) => {
    event.preventDefault()
    const value = sourceInput.trim()
    if (!value) return

    setAdding(true)
    setValidationError(null)
    try {
      const created =
        addType === 'reddit' ? await addRedditSource(value) : await addYoutubeSource(value)
      setSources((current) =>
        [...current, created].sort((a, b) => {
          const typeCmp = a.source_type.localeCompare(b.source_type)
          return typeCmp !== 0 ? typeCmp : a.name.localeCompare(b.name)
        })
      )
      setSourceInput('')
    } catch (err) {
      setValidationError(
        err instanceof Error
          ? err.message
          : addType === 'reddit'
            ? 'Failed to add subreddit.'
            : 'Failed to add YouTube channel.'
      )
    } finally {
      setAdding(false)
    }
  }

  const handleRemove = async (source: NewsSource) => {
    const label =
      source.source_type === 'youtube'
        ? source.channel_name || source.name
        : `r/${source.subreddit ?? source.name}`
    const confirmed = await confirm({
      message: `Remove ${label} from sources?`,
      confirmLabel: 'Remove',
    })
    if (!confirmed) return

    try {
      await removeSource(source.id)
      setSources((current) => current.filter((item) => item.id !== source.id))
    } catch {
      setError(
        source.source_type === 'youtube'
          ? 'Failed to remove YouTube channel.'
          : 'Failed to remove subreddit.'
      )
    }
  }

  const fixedSources = sources.filter(
    (source) => source.source_type !== 'reddit' && source.source_type !== 'youtube'
  )
  const redditSources = sources.filter((source) => source.source_type === 'reddit')
  const youtubeSources = sources.filter((source) => source.source_type === 'youtube')

  if (loading) {
    return (
      <PageContainer width="4xl" testId="sources-page" role="status" aria-live="polite" aria-busy>
        <SourcesIndexSkeleton />
      </PageContainer>
    )
  }

  return (
    <PageContainer width="4xl" testId="sources-page">
      <Breadcrumbs items={sourcesBreadcrumbs} />
      <PageHeading
        title="News Sources"
        subtitle="Enable or disable sources and manage Reddit subreddits and YouTube channels."
        titleClassName="text-gray-100"
      />

      {error && <div className="mb-4 text-sm text-red-400">{error}</div>}

      <Card as="section" className="mb-8">
        <h2 className="text-h3 text-gray-200 mb-4">Built-in sources</h2>
        <div className="space-y-3">
          {fixedSources.map((source) => (
            <div key={source.id} className="flex items-center justify-between gap-4 py-3 border-b border-dark-700 last:border-0">
              <div className="min-w-0">
                <span className="text-gray-200 font-medium">{sourceLabel(source)}</span>
                <SourceFetchStatus lastFetch={source.last_fetch} />
              </div>
              <label className="flex items-center gap-2 text-sm text-gray-400 cursor-pointer shrink-0">
                <input
                  type="checkbox"
                  className="rounded border-dark-600 bg-dark-800 text-primary-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-500"
                  checked={source.active}
                  onChange={() => handleToggle(source)}
                  data-testid={`source-toggle-${source.source_type}`}
                />
                {source.active ? 'Enabled' : 'Disabled'}
              </label>
            </div>
          ))}
        </div>
      </Card>

      <Card as="section" className="mb-8">
        <h2 className="text-h3 text-gray-200 mb-4">Add a source</h2>
        <div className="flex flex-wrap gap-3 mb-4" role="group" aria-label="Source type">
          <Button
            type="button"
            variant="filter"
            active={addType === 'reddit'}
            aria-pressed={addType === 'reddit'}
            data-testid="add-type-reddit"
            onClick={() => {
              setAddType('reddit')
              setValidationError(null)
            }}
          >
            Reddit
          </Button>
          <Button
            type="button"
            variant="filter"
            active={addType === 'youtube'}
            aria-pressed={addType === 'youtube'}
            data-testid="add-type-youtube"
            onClick={() => {
              setAddType('youtube')
              setValidationError(null)
            }}
          >
            YouTube
          </Button>
        </div>

        <form onSubmit={handleAddSource} className="flex flex-col sm:flex-row gap-3 mb-2">
          <input
            type="text"
            value={sourceInput}
            onChange={(event) => setSourceInput(event.target.value)}
            placeholder={
              addType === 'reddit'
                ? 'e.g. programming'
                : 'UC… ID, @handle, or youtube.com/@channel'
            }
            className="flex-1 px-4 py-2 bg-dark-800 border border-dark-700 rounded-xl text-gray-200 placeholder-gray-500 focus-visible:outline-none focus-visible:border-primary-500 focus-visible:ring-2 focus-visible:ring-primary-500"
            data-testid="source-input"
          />
          <Button
            type="submit"
            disabled={adding || !sourceInput.trim()}
            data-testid="add-source-button"
          >
            {adding
              ? 'Validating...'
              : addType === 'reddit'
                ? 'Add subreddit'
                : 'Add channel'}
          </Button>
        </form>

        {validationError && (
          <p className="text-sm text-red-400 mb-4" data-testid="source-validation-error">
            {validationError}
          </p>
        )}
      </Card>

      <Card as="section" className="mb-8">
        <h2 className="text-h3 text-gray-200 mb-4">Reddit subreddits</h2>
        <div className="space-y-3">
          {redditSources.map((source) => (
            <div key={source.id} className="flex items-center justify-between gap-4 py-3 border-b border-dark-700 last:border-0">
              <div className="min-w-0">
                <span className="text-gray-200">r/{source.subreddit ?? source.name}</span>
                <SourceFetchStatus lastFetch={source.last_fetch} />
              </div>
              <div className="flex items-center gap-4 shrink-0">
                <label className="flex items-center gap-2 text-sm text-gray-400 cursor-pointer">
                  <input
                    type="checkbox"
                    className="rounded border-dark-600 bg-dark-800 text-primary-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-500"
                    checked={source.active}
                    onChange={() => handleToggle(source)}
                  />
                  {source.active ? 'Enabled' : 'Disabled'}
                </label>
                <button
                  type="button"
                  className="text-sm text-red-400 hover:text-red-300"
                  onClick={() => handleRemove(source)}
                  data-testid={`remove-reddit-${source.id}`}
                >
                  Remove
                </button>
              </div>
            </div>
          ))}
          {redditSources.length === 0 && (
            <p className="text-gray-500 text-sm">No Reddit subreddits configured.</p>
          )}
        </div>
      </Card>

      <Card as="section">
        <h2 className="text-h3 text-gray-200 mb-4">YouTube channels</h2>
        <div className="space-y-3">
          {youtubeSources.map((source) => (
            <div key={source.id} className="flex items-center justify-between gap-4 py-3 border-b border-dark-700 last:border-0">
              <div className="min-w-0">
                <span className="text-gray-200 font-medium">{sourceLabel(source)}</span>
                {source.channel_id && (
                  <p className="text-caption text-gray-500 mt-1">{source.channel_id}</p>
                )}
                <SourceFetchStatus lastFetch={source.last_fetch} />
              </div>
              <div className="flex items-center gap-4 shrink-0">
                <label className="flex items-center gap-2 text-sm text-gray-400 cursor-pointer">
                  <input
                    type="checkbox"
                    className="rounded border-dark-600 bg-dark-800 text-primary-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-500"
                    checked={source.active}
                    onChange={() => handleToggle(source)}
                    data-testid={`source-toggle-youtube-${source.channel_id ?? source.id}`}
                  />
                  {source.active ? 'Enabled' : 'Disabled'}
                </label>
                <button
                  type="button"
                  className="text-sm text-red-400 hover:text-red-300"
                  onClick={() => handleRemove(source)}
                  data-testid={`remove-youtube-${source.id}`}
                >
                  Remove
                </button>
              </div>
            </div>
          ))}
          {youtubeSources.length === 0 && (
            <p className="text-gray-500 text-sm">No YouTube channels configured.</p>
          )}
        </div>
      </Card>
      {dialog}
    </PageContainer>
  )
}
