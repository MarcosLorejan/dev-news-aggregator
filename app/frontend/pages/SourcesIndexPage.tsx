import { useCallback, useEffect, useState } from 'react'
import {
  addRedditSource,
  fetchSources,
  removeSource,
  updateSource,
  type NewsSource,
} from '../api/sources'
import { useConfirmDialog } from '../hooks/useConfirmDialog'
import Button from '../components/ui/Button'
import Card from '../components/ui/Card'
import PageContainer from '../components/ui/PageContainer'
import SourcesIndexSkeleton from '../components/SourcesIndexSkeleton'
import PageHeading from '../components/ui/PageHeading'

function sourceLabel(source: NewsSource): string {
  if (source.source_type === 'reddit') {
    return `r/${source.subreddit ?? source.name}`
  }
  return source.name
}

export default function SourcesIndexPage() {
  const [sources, setSources] = useState<NewsSource[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [subredditInput, setSubredditInput] = useState('')
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

  const handleAddSubreddit = async (event: React.FormEvent) => {
    event.preventDefault()
    const subreddit = subredditInput.trim()
    if (!subreddit) return

    setAdding(true)
    setValidationError(null)
    try {
      const created = await addRedditSource(subreddit)
      setSources((current) => [...current, created].sort((a, b) => a.name.localeCompare(b.name)))
      setSubredditInput('')
    } catch (err) {
      setValidationError(err instanceof Error ? err.message : 'Failed to add subreddit.')
    } finally {
      setAdding(false)
    }
  }

  const handleRemove = async (source: NewsSource) => {
    const confirmed = await confirm({
      message: `Remove r/${source.subreddit ?? source.name} from sources?`,
      confirmLabel: 'Remove',
    })
    if (!confirmed) return

    try {
      await removeSource(source.id)
      setSources((current) => current.filter((item) => item.id !== source.id))
    } catch {
      setError('Failed to remove subreddit.')
    }
  }

  const fixedSources = sources.filter((source) => source.source_type !== 'reddit')
  const redditSources = sources.filter((source) => source.source_type === 'reddit')

  if (loading) {
    return (
      <PageContainer width="4xl" testId="sources-page" role="status" aria-live="polite" aria-busy>
        <SourcesIndexSkeleton />
      </PageContainer>
    )
  }

  return (
    <PageContainer width="4xl" testId="sources-page">
      <PageHeading
        title="News Sources"
        subtitle="Enable or disable sources and manage Reddit subreddits."
        titleClassName="text-gray-100"
      />

      {error && <div className="mb-4 text-sm text-red-400">{error}</div>}

      <Card as="section" className="mb-8">
        <h2 className="text-h3 text-gray-200 mb-4">Built-in sources</h2>
        <div className="space-y-3">
          {fixedSources.map((source) => (
            <div key={source.id} className="flex items-center justify-between py-3 border-b border-dark-700 last:border-0">
              <span className="text-gray-200 font-medium">{sourceLabel(source)}</span>
              <label className="flex items-center gap-2 text-sm text-gray-400 cursor-pointer">
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

      <Card as="section">
        <h2 className="text-h3 text-gray-200 mb-4">Reddit subreddits</h2>

        <form onSubmit={handleAddSubreddit} className="flex flex-col sm:flex-row gap-3 mb-6">
          <input
            type="text"
            value={subredditInput}
            onChange={(event) => setSubredditInput(event.target.value)}
            placeholder="e.g. programming"
            className="flex-1 px-4 py-2 bg-dark-800 border border-dark-700 rounded-xl text-gray-200 placeholder-gray-500 focus-visible:outline-none focus-visible:border-primary-500 focus-visible:ring-2 focus-visible:ring-primary-500"
            data-testid="subreddit-input"
          />
          <Button type="submit" disabled={adding || !subredditInput.trim()} data-testid="add-subreddit-button">
            {adding ? 'Validating...' : 'Add subreddit'}
          </Button>
        </form>

        {validationError && (
          <p className="text-sm text-red-400 mb-4" data-testid="subreddit-validation-error">{validationError}</p>
        )}

        <div className="space-y-3">
          {redditSources.map((source) => (
            <div key={source.id} className="flex items-center justify-between py-3 border-b border-dark-700 last:border-0">
              <span className="text-gray-200">r/{source.subreddit ?? source.name}</span>
              <div className="flex items-center gap-4">
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
      {dialog}
    </PageContainer>
  )
}
