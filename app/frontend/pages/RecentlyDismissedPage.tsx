import { undismissArticle } from '../api/articles'
import { fetchRecentlyDismissed } from '../api/dismissedArticles'
import type { DismissedArticle } from '../types/dismissedArticle'
import { NavLink } from 'react-router-dom'
import DismissedArticlesList from '../components/DismissedArticlesList'
import PageShell from '../components/PageShell'
import { buttonClassName } from '../components/ui/Button'
import PageHeading from '../components/ui/PageHeading'
import EmptyState from '../components/EmptyState'
import { useAsyncResource } from '../hooks/useAsyncResource'

export default function RecentlyDismissedPage() {
  const { data, loading, error, reload, setData, setError } = useAsyncResource(fetchRecentlyDismissed, {
    errorMessage: 'Failed to load recently dismissed articles. Please try again.',
  })

  const articles = data?.articles ?? []

  const handleRestore = async (article: DismissedArticle) => {
    try {
      await undismissArticle(article.id)
      setData((current) =>
        current
          ? {
              ...current,
              articles: current.articles.filter((item) => item.id !== article.id),
            }
          : current
      )
    } catch {
      setError('Failed to restore article.')
    }
  }

  return (
    <PageShell
      testId="recently-dismissed-page"
      loading={loading}
      loadingMessage="Loading recently dismissed articles..."
      error={error}
      showFatalError={articles.length === 0}
      onRetry={reload}
    >
      <PageHeading
        title="Recently Dismissed"
        subtitle="Articles dismissed in the last 24 hours - easy to restore"
        actions={
          <NavLink
            to="/dismissed"
            className={({ isActive }) =>
              buttonClassName({
                color: 'red',
                className: isActive ? 'ring-2 ring-white/30' : undefined,
              })
            }
          >
            <svg className="w-4 h-4 mr-2 transition-transform group-hover:scale-110" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
            All Dismissed
          </NavLink>
        }
      />

      {error && <div className="mb-4 text-sm text-red-400">{error}</div>}

      {articles.length === 0 ? (
        <EmptyState
          icon={
            <svg className="w-10 h-10 text-orange-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          }
          iconWrapperClassName="bg-gradient-to-r from-orange-600/20 to-orange-700/20"
          title="No recently dismissed articles"
          description="You haven't dismissed any articles in the last 24 hours. Recently dismissed articles appear here for easy restoration."
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
            {
              href: '/dismissed',
              label: 'View All Dismissed',
              color: 'red' as const,
              icon: (
                <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
              ),
            },
          ]}
        />
      ) : (
        <>
          <div className="surface-subtle rounded-xl p-4 mb-6 border border-orange-500/20 bg-orange-600/5">
            <div className="flex items-center text-orange-300">
              <svg className="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <span className="text-sm font-medium">
                These articles were dismissed recently and can be quickly restored to your main feed.
              </span>
            </div>
          </div>
          <DismissedArticlesList articles={articles} variant="recent" onRestore={handleRestore} />
        </>
      )}
    </PageShell>
  )
}
