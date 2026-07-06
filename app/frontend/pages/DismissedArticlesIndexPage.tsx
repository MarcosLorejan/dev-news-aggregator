import { undismissArticle } from '../api/articles'
import { fetchDismissedArticles } from '../api/dismissedArticles'
import type { DismissedArticle } from '../types/dismissedArticle'
import { NavLink } from 'react-router-dom'
import DismissedArticlesList from '../components/DismissedArticlesList'
import PageShell from '../components/PageShell'
import { buttonClassName } from '../components/ui/Button'
import PageHeading from '../components/ui/PageHeading'
import EmptyState from '../components/EmptyState'
import { useAsyncResource } from '../hooks/useAsyncResource'

export default function DismissedArticlesIndexPage() {
  const { data, loading, error, reload, setData, setError } = useAsyncResource(fetchDismissedArticles, {
    errorMessage: 'Failed to load dismissed articles. Please try again.',
  })

  const articles = data?.articles ?? []
  const totalCount = data?.pagination.total_count ?? 0

  const handleRestore = async (article: DismissedArticle) => {
    try {
      await undismissArticle(article.id)
      setData((current) =>
        current
          ? {
              ...current,
              articles: current.articles.filter((item) => item.id !== article.id),
              pagination: {
                ...current.pagination,
                total_count: Math.max(0, current.pagination.total_count - 1),
              },
            }
          : current
      )
    } catch {
      setError('Failed to restore article.')
    }
  }

  return (
    <PageShell
      testId="dismissed-articles-page"
      loading={loading}
      loadingMessage="Loading dismissed articles..."
      error={error}
      showFatalError={articles.length === 0 && totalCount === 0}
      onRetry={reload}
    >
      <PageHeading
        title="Dismissed Articles"
        subtitle="Articles you've dismissed from your feed"
        titleClassName="bg-gradient-to-r from-red-400 to-red-600 bg-clip-text text-transparent"
        actions={
          <NavLink
            to="/recently_dismissed"
            className={({ isActive }) =>
              buttonClassName({
                color: 'orange',
                className: isActive ? 'ring-2 ring-white/30' : undefined,
              })
            }
          >
            <svg className="w-4 h-4 mr-2 transition-transform group-hover:scale-110" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            Recently Dismissed
          </NavLink>
        }
      />

      {error && <div className="mb-4 text-sm text-red-400">{error}</div>}

      {totalCount === 0 ? (
        <EmptyState
          icon={
            <svg className="w-10 h-10 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          }
          iconWrapperClassName="bg-gradient-to-r from-red-600/20 to-red-700/20"
          title="No dismissed articles"
          description="You haven't dismissed any articles yet. Dismissed articles will appear here, and you can restore them to your main feed."
          actions={[
            {
              href: '/articles',
              label: 'Browse Articles',
              color: 'primary' as const,
              icon: (
                <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
                </svg>
              ),
            },
          ]}
        />
      ) : (
        <DismissedArticlesList articles={articles} variant="dismissed" onRestore={handleRestore} />
      )}
    </PageShell>
  )
}
