import { useCallback, useEffect, useState } from 'react'
import { undismissArticle } from '../api/articles'
import { fetchDismissedArticles } from '../api/dismissedArticles'
import type { DismissedArticle } from '../types/dismissedArticle'
import DismissedArticlesList from '../components/DismissedArticlesList'

export default function DismissedArticlesIndexPage() {
  const [articles, setArticles] = useState<DismissedArticle[]>([])
  const [totalCount, setTotalCount] = useState(0)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const loadDismissedArticles = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const response = await fetchDismissedArticles()
      setArticles(response.articles)
      setTotalCount(response.pagination.total_count)
    } catch {
      setError('Failed to load dismissed articles. Please try again.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    loadDismissedArticles()
  }, [loadDismissedArticles])

  const handleRestore = async (article: DismissedArticle) => {
    try {
      await undismissArticle(article.id)
      setArticles((current) => current.filter((item) => item.id !== article.id))
      setTotalCount((count) => Math.max(0, count - 1))
    } catch {
      setError('Failed to restore article.')
    }
  }

  if (loading) {
    return (
      <div className="container mx-auto px-4 py-8 max-w-7xl text-center text-gray-400" data-testid="dismissed-articles-page">
        Loading dismissed articles...
      </div>
    )
  }

  if (error && articles.length === 0 && totalCount === 0) {
    return (
      <div className="container mx-auto px-4 py-8 max-w-7xl text-center" data-testid="dismissed-articles-page">
        <p className="text-red-400 mb-4">{error}</p>
        <button
          type="button"
          className="px-4 py-2 bg-primary-600 text-white rounded-lg"
          onClick={loadDismissedArticles}
        >
          Retry
        </button>
      </div>
    )
  }

  return (
    <div className="container mx-auto px-4 py-8 max-w-7xl" data-testid="dismissed-articles-page">
      <div className="glass-effect rounded-2xl p-8 mb-8 animate-fade-in">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
          <div>
            <h1 className="text-4xl md:text-5xl font-bold bg-gradient-to-r from-red-400 to-red-600 bg-clip-text text-transparent mb-2">
              Dismissed Articles
            </h1>
            <p className="text-gray-400 text-lg">Articles you&apos;ve dismissed from your feed</p>
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
              href="/recently_dismissed"
              className="group flex items-center px-4 py-2 bg-gradient-to-r from-orange-600 to-orange-700 text-white rounded-xl font-medium transition-all duration-200 hover:from-orange-700 hover:to-orange-800 hover:scale-105 hover:shadow-lg hover:shadow-orange-500/25"
            >
              <svg className="w-4 h-4 mr-2 transition-transform group-hover:scale-110" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              Recently Dismissed
            </a>
          </div>
        </div>
      </div>

      {error && <div className="mb-4 text-sm text-red-400">{error}</div>}

      {totalCount === 0 ? (
        <div className="glass-effect rounded-2xl p-12 text-center animate-fade-in">
          <div className="w-20 h-20 mx-auto mb-6 bg-gradient-to-r from-red-600/20 to-red-700/20 rounded-full flex items-center justify-center">
            <svg className="w-10 h-10 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </div>
          <h2 className="text-2xl font-bold text-gray-200 mb-4">No dismissed articles</h2>
          <p className="text-gray-400 mb-8 max-w-md mx-auto leading-relaxed">
            You haven&apos;t dismissed any articles yet. Dismissed articles will appear here, and you can restore them to your main feed.
          </p>
          <a
            href="/articles"
            className="inline-flex items-center px-6 py-3 bg-gradient-to-r from-primary-600 to-primary-700 text-white rounded-xl font-medium transition-all duration-200 hover:from-primary-700 hover:to-primary-800 hover:scale-105"
          >
            <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
            </svg>
            Browse Articles
          </a>
        </div>
      ) : (
        <DismissedArticlesList articles={articles} variant="dismissed" onRestore={handleRestore} />
      )}
    </div>
  )
}
