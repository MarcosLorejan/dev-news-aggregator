import { useCallback, useEffect, useState } from 'react'
import { undismissArticle } from '../api/articles'
import { fetchRecentlyDismissed } from '../api/dismissedArticles'
import type { DismissedArticle } from '../types/dismissedArticle'
import DismissedArticlesList from '../components/DismissedArticlesList'

export default function RecentlyDismissedPage() {
  const [articles, setArticles] = useState<DismissedArticle[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const loadRecentlyDismissed = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const response = await fetchRecentlyDismissed()
      setArticles(response.articles)
    } catch {
      setError('Failed to load recently dismissed articles. Please try again.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    loadRecentlyDismissed()
  }, [loadRecentlyDismissed])

  const handleRestore = async (article: DismissedArticle) => {
    try {
      await undismissArticle(article.id)
      setArticles((current) => current.filter((item) => item.id !== article.id))
    } catch {
      setError('Failed to restore article.')
    }
  }

  if (loading) {
    return (
      <div className="container mx-auto px-4 py-8 max-w-7xl text-center text-gray-400" data-testid="recently-dismissed-page">
        Loading recently dismissed articles...
      </div>
    )
  }

  if (error && articles.length === 0) {
    return (
      <div className="container mx-auto px-4 py-8 max-w-7xl text-center" data-testid="recently-dismissed-page">
        <p className="text-red-400 mb-4">{error}</p>
        <button
          type="button"
          className="px-4 py-2 bg-primary-600 text-white rounded-lg"
          onClick={loadRecentlyDismissed}
        >
          Retry
        </button>
      </div>
    )
  }

  return (
    <div className="container mx-auto px-4 py-8 max-w-7xl" data-testid="recently-dismissed-page">
      <div className="glass-effect rounded-2xl p-8 mb-8 animate-fade-in">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
          <div>
            <h1 className="text-4xl md:text-5xl font-bold bg-gradient-to-r from-orange-400 to-orange-600 bg-clip-text text-transparent mb-2">
              Recently Dismissed
            </h1>
            <p className="text-gray-400 text-lg">Articles dismissed in the last 24 hours - easy to restore</p>
          </div>
          <div className="flex items-center space-x-4">
            <a
              href="/articles"
              className="group flex items-center px-4 py-2 bg-gradient-to-r from-primary-600 to-primary-700 text-white rounded-xl font-medium transition-all duration-200 hover:from-primary-700 hover:to-primary-800 hover:scale-105 hover:shadow-lg hover:shadow-primary-500/25"
            >
              <svg className="w-4 h-4 mr-2 transition-transform group-hover:scale-110" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
              Back to All Articles
            </a>
            <a
              href="/dismissed"
              className="group flex items-center px-4 py-2 bg-gradient-to-r from-red-600 to-red-700 text-white rounded-xl font-medium transition-all duration-200 hover:from-red-700 hover:to-red-800 hover:scale-105 hover:shadow-lg hover:shadow-red-500/25"
            >
              <svg className="w-4 h-4 mr-2 transition-transform group-hover:scale-110" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
              All Dismissed
            </a>
          </div>
        </div>
      </div>

      {error && <div className="mb-4 text-sm text-red-400">{error}</div>}

      {articles.length === 0 ? (
        <div className="glass-effect rounded-2xl p-12 text-center animate-fade-in">
          <div className="w-20 h-20 mx-auto mb-6 bg-gradient-to-r from-orange-600/20 to-orange-700/20 rounded-full flex items-center justify-center">
            <svg className="w-10 h-10 text-orange-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <h2 className="text-2xl font-bold text-gray-200 mb-4">No recently dismissed articles</h2>
          <p className="text-gray-400 mb-8 max-w-md mx-auto leading-relaxed">
            You haven&apos;t dismissed any articles in the last 24 hours. Recently dismissed articles appear here for easy restoration.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <a
              href="/articles"
              className="inline-flex items-center px-6 py-3 bg-gradient-to-r from-primary-600 to-primary-700 text-white rounded-xl font-medium transition-all duration-200 hover:from-primary-700 hover:to-primary-800 hover:scale-105"
            >
              <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
              Browse Articles
            </a>
            <a
              href="/dismissed"
              className="inline-flex items-center px-6 py-3 bg-gradient-to-r from-red-600 to-red-700 text-white rounded-xl font-medium transition-all duration-200 hover:from-red-700 hover:to-red-800 hover:scale-105"
            >
              <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
              View All Dismissed
            </a>
          </div>
        </div>
      ) : (
        <>
          <div className="glass-effect rounded-xl p-4 mb-6 bg-gradient-to-r from-orange-600/10 to-orange-700/10 border border-orange-500/30">
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
    </div>
  )
}
