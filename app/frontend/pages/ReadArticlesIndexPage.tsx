import { useMemo } from 'react'
import { unmarkArticleAsRead } from '../api/articles'
import { fetchReadArticles } from '../api/readArticles'
import type { ReadArticle } from '../types/readArticle'
import ReadArticlesList from '../components/ReadArticlesList'
import SourceFilter from '../components/SourceFilter'
import PageShell from '../components/PageShell'
import PageHeading from '../components/PageHeading'
import EmptyState from '../components/EmptyState'
import { useAsyncResource } from '../hooks/useAsyncResource'
import { useSearchParam } from '../hooks/useSearchParamState'

export default function ReadArticlesIndexPage() {
  const { data, loading, error, reload, setData, setError } = useAsyncResource(fetchReadArticles, {
    errorMessage: 'Failed to load read articles. Please try again.',
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

  const handleUnmarkRead = async (article: ReadArticle) => {
    try {
      await unmarkArticleAsRead(article.id)
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
      setError('Failed to mark article as unread.')
    }
  }

  return (
    <PageShell
      testId="read-articles-page"
      loading={loading}
      loadingMessage="Loading read articles..."
      error={error}
      showFatalError={articles.length === 0 && totalCount === 0}
      onRetry={reload}
    >
      <PageHeading
        title="Already Read"
        subtitle="Articles you've finished reading"
        titleClassName="bg-gradient-to-r from-green-400 to-green-600 bg-clip-text text-transparent"
        meta={
          <div className="text-sm text-gray-400">
            <div className="flex items-center space-x-2">
              <span className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
              <span>
                Read: <span className="text-green-400 font-semibold">{articles.length}</span> articles
              </span>
            </div>
          </div>
        }
      />

      {error && <div className="mb-4 text-sm text-red-400">{error}</div>}

      {totalCount === 0 ? (
        <EmptyState
          icon={
            <svg className="w-10 h-10 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          }
          iconWrapperClassName="bg-gradient-to-r from-green-600/20 to-green-700/20"
          title="No read articles yet"
          description="Articles you mark as read will appear here. Start reading and mark articles as finished to build your reading history."
          actions={[
            {
              href: '/articles',
              label: 'Browse Articles',
              className:
                'group inline-flex items-center px-6 py-3 bg-gradient-to-r from-green-600 to-green-700 text-white rounded-xl font-medium transition-all duration-200 hover:from-green-700 hover:to-green-800 hover:scale-105 hover:shadow-lg hover:shadow-green-500/25',
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
          <ReadArticlesList
            articles={articles}
            activeSource={activeSource}
            onUnmarkRead={handleUnmarkRead}
          />
        </>
      )}
    </PageShell>
  )
}
