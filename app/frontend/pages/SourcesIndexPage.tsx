import { useCallback, useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  addRedditSource,
  fetchSources,
  removeSource,
  updateSource,
  type NewsSource,
} from '../api/sources'
import { useConfirmDialog } from '../hooks/useConfirmDialog'

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
      <div className="container mx-auto px-4 py-8 max-w-4xl text-center text-gray-400" data-testid="sources-page">
        Loading sources...
      </div>
    )
  }

  return (
    <div className="container mx-auto px-4 py-8 max-w-4xl" data-testid="sources-page">
      <div className="glass-effect rounded-2xl p-8 mb-8">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div>
            <h1 className="text-3xl font-bold text-gray-100 mb-2">News Sources</h1>
            <p className="text-gray-400">Enable or disable sources and manage Reddit subreddits.</p>
          </div>
          <Link to="/articles" className="px-4 py-2 bg-dark-700 border border-dark-600 text-gray-300 rounded-xl hover:bg-dark-600">
            Back to Articles
          </Link>
        </div>
      </div>

      {error && <div className="mb-4 text-sm text-red-400">{error}</div>}

      <section className="glass-effect rounded-2xl p-6 mb-8">
        <h2 className="text-lg font-semibold text-gray-200 mb-4">Built-in sources</h2>
        <div className="space-y-3">
          {fixedSources.map((source) => (
            <div key={source.id} className="flex items-center justify-between py-3 border-b border-dark-700 last:border-0">
              <span className="text-gray-200 font-medium">{sourceLabel(source)}</span>
              <label className="flex items-center gap-2 text-sm text-gray-400 cursor-pointer">
                <input
                  type="checkbox"
                  className="rounded border-dark-600 bg-dark-800 text-primary-500 focus:ring-primary-500"
                  checked={source.active}
                  onChange={() => handleToggle(source)}
                  data-testid={`source-toggle-${source.source_type}`}
                />
                {source.active ? 'Enabled' : 'Disabled'}
              </label>
            </div>
          ))}
        </div>
      </section>

      <section className="glass-effect rounded-2xl p-6">
        <h2 className="text-lg font-semibold text-gray-200 mb-4">Reddit subreddits</h2>

        <form onSubmit={handleAddSubreddit} className="flex flex-col sm:flex-row gap-3 mb-6">
          <input
            type="text"
            value={subredditInput}
            onChange={(event) => setSubredditInput(event.target.value)}
            placeholder="e.g. programming"
            className="flex-1 px-4 py-2 bg-dark-800 border border-dark-700 rounded-xl text-gray-200 placeholder-gray-500 focus:outline-none focus:border-primary-500"
            data-testid="subreddit-input"
          />
          <button
            type="submit"
            disabled={adding || !subredditInput.trim()}
            className="px-4 py-2 bg-primary-600 text-white rounded-xl font-medium hover:bg-primary-700 disabled:opacity-60"
            data-testid="add-subreddit-button"
          >
            {adding ? 'Validating...' : 'Add subreddit'}
          </button>
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
                    className="rounded border-dark-600 bg-dark-800 text-primary-500 focus:ring-primary-500"
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
      </section>
      {dialog}
    </div>
  )
}
