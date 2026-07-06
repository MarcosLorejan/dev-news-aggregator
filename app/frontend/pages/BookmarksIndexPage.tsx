import { useMemo } from 'react'
import { Link } from 'react-router-dom'
import { fetchBookmarks } from '../api/bookmarks'
import {
  markArticleAsRead,
  unbookmarkArticle,
  unmarkArticleAsRead,
} from '../api/articles'
import type { BookmarkArticle } from '../types/bookmark'
import BookmarksList from '../components/BookmarksList'
import SourceFilter from '../components/SourceFilter'
import PageShell from '../components/PageShell'
import EmptyState from '../components/EmptyState'
import { useAsyncResource } from '../hooks/useAsyncResource'
import { useSearchParam } from '../hooks/useSearchParamState'

export default function BookmarksIndexPage() {
  const { data, loading, error, reload, setData, setError } = useAsyncResource(fetchBookmarks, {
    errorMessage: 'Failed to load reading list. Please try again.',
  })
  const [activeSource, setActiveSource] = useSearchParam('source', 'all')

  const articles = data?.articles ?? []
  const articlesBySource = data?.articles_by_source ?? {}
  const totalCount = data?.pagination.total_count ?? 0

  const sources = useMemo(() => Object.keys(articlesBySource).sort(), [articlesBySource])

  const sourceCounts = useMemo(
    () => Object.fromEntries(sources.map((source) => [source, articlesBySource[source]?.length ?? 0])),
    [articlesBySource, sources]
  )

  const handleRemoveBookmark = async (article: BookmarkArticle) => {
    try {
      await unbookmarkArticle(article.id)
      setData((current) => {
        if (!current) return current
        const nextArticles = current.articles.filter((item) => item.id !== article.id)
        const nextBySource: Record<string, number[]> = {}
        Object.entries(current.articles_by_source).forEach(([source, ids]) => {
          const filtered = ids.filter((id) => id !== article.id)
          if (filtered.length > 0) nextBySource[source] = filtered
        })
        return {
          ...current,
          articles: nextArticles,
          articles_by_source: nextBySource,
          pagination: {
            ...current.pagination,
            total_count: Math.max(0, current.pagination.total_count - 1),
          },
        }
      })
    } catch {
      setError('Failed to remove bookmark.')
    }
  }

  const handleReadToggle = async (article: BookmarkArticle) => {
    try {
      if (article.read) {
        await unmarkArticleAsRead(article.id)
        setData((current) =>
          current
            ? {
                ...current,
                articles: current.articles.map((item) =>
                  item.id === article.id ? { ...item, read: false } : item
                ),
              }
            : current
        )
      } else {
        await markArticleAsRead(article.id)
        setData((current) =>
          current
            ? {
                ...current,
                articles: current.articles.map((item) =>
                  item.id === article.id ? { ...item, read: true } : item
                ),
              }
            : current
        )
      }
    } catch {
      setError('Failed to update read status.')
    }
  }

  return (
    <PageShell
      testId="bookmarks-page"
      loading={loading}
      loadingMessage="Loading reading list..."
      error={error}
      showFatalError={articles.length === 0 && totalCount === 0}
      onRetry={reload}
    >
      <div className="glass-effect rounded-2xl p-8 mb-8 animate-fade-in">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
          <div>
            <h1 className="text-4xl md:text-5xl font-bold bg-gradient-to-r from-primary-400 to-primary-600 bg-clip-text text-transparent mb-2">
              Reading List
            </h1>
            <p className="text-gray-400 text-lg">Your curated collection of bookmarked articles</p>
          </div>
          <div className="flex items-center space-x-6">
            <Link
              to="/articles"
              className="group flex items-center px-4 py-3 bg-gradient-to-r from-dark-700 to-dark-600 border border-dark-500 text-gray-300 rounded-xl font-medium transition-all duration-200 hover:from-primary-600 hover:to-primary-700 hover:border-primary-500 hover:text-white hover:scale-105 hover:shadow-lg hover:shadow-primary-500/25"
            >
              <svg className="w-5 h-5 mr-2 transition-transform group-hover:scale-110" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9.5a2.5 2.5 0 00-2.5-2.5H15" />
              </svg>
              Back to All Articles
            </Link>
            <div className="text-sm text-gray-400">
              <div className="flex items-center space-x-2">
                <span className="w-2 h-2 bg-primary-500 rounded-full animate-pulse" />
                <span>
                  Bookmarked: <span className="text-primary-400 font-semibold">{articles.length}</span> articles
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {error && <div className="mb-4 text-sm text-red-400">{error}</div>}

      {totalCount === 0 ? (
        <EmptyState
          icon={
            <svg className="w-10 h-10 text-primary-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" />
            </svg>
          }
          title="No bookmarked articles yet"
          description="Articles you bookmark will appear here in your reading list."
          actions={[
            {
              href: '/articles',
              label: 'Browse Articles',
              className:
                'group inline-flex items-center px-6 py-3 bg-gradient-to-r from-primary-600 to-primary-700 text-white rounded-xl font-medium transition-all duration-200 hover:from-primary-700 hover:to-primary-800 hover:scale-105 hover:shadow-lg hover:shadow-primary-500/25',
              icon: (
                <svg className="w-5 h-5 mr-2 transition-transform group-hover:scale-110" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9.5a2.5 2.5 0 00-2.5-2.5H15" />
                </svg>
              ),
            },
          ]}
        />
      ) : (
        <>
          <SourceFilter
            sources={sources}
            sourceCounts={sourceCounts}
            totalCount={articles.length}
            activeSource={activeSource}
            onSourceChange={setActiveSource}
          />
          <BookmarksList
            articles={articles}
            activeSource={activeSource}
            onRemoveBookmark={handleRemoveBookmark}
            onReadToggle={handleReadToggle}
          />
        </>
      )}
    </PageShell>
  )
}
