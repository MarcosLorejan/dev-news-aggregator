import { useMemo } from 'react'
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
import PageHeading from '../components/ui/PageHeading'
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
      <PageHeading
        title="Reading List"
        subtitle="Your curated collection of bookmarked articles"
        meta={
          <div className="text-sm text-gray-400">
            <div className="flex items-center space-x-2">
              <span className="w-2 h-2 bg-primary-500 rounded-full animate-pulse" />
              <span>
                Bookmarked: <span className="text-primary-400 font-semibold">{articles.length}</span> articles
              </span>
            </div>
          </div>
        }
      />

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
              color: 'primary' as const,
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
