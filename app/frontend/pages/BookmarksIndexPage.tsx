import { useCallback, useEffect, useMemo, useState } from 'react'
import { fetchBookmarks } from '../api/bookmarks'
import {
  markArticleAsRead,
  unbookmarkArticle,
  unmarkArticleAsRead,
} from '../api/articles'
import type { BookmarkArticle } from '../types/bookmark'
import BookmarksList from '../components/BookmarksList'
import SourceFilter from '../components/SourceFilter'

export default function BookmarksIndexPage() {
  const [articles, setArticles] = useState<BookmarkArticle[]>([])
  const [articlesBySource, setArticlesBySource] = useState<Record<string, number[]>>({})
  const [totalCount, setTotalCount] = useState(0)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [activeSource, setActiveSource] = useState('all')

  const loadBookmarks = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const response = await fetchBookmarks()
      setArticles(response.articles)
      setArticlesBySource(response.articles_by_source)
      setTotalCount(response.pagination.total_count)
    } catch {
      setError('Failed to load reading list. Please try again.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    loadBookmarks()
  }, [loadBookmarks])

  const sources = useMemo(() => Object.keys(articlesBySource).sort(), [articlesBySource])

  const sourceCounts = useMemo(
    () => Object.fromEntries(sources.map((source) => [source, articlesBySource[source]?.length ?? 0])),
    [articlesBySource, sources]
  )

  const handleRemoveBookmark = async (article: BookmarkArticle) => {
    try {
      await unbookmarkArticle(article.id)
      setArticles((current) => current.filter((item) => item.id !== article.id))
      setTotalCount((count) => Math.max(0, count - 1))
      setArticlesBySource((current) => {
        const next: Record<string, number[]> = {}
        Object.entries(current).forEach(([source, ids]) => {
          const filtered = ids.filter((id) => id !== article.id)
          if (filtered.length > 0) next[source] = filtered
        })
        return next
      })
    } catch {
      setError('Failed to remove bookmark.')
    }
  }

  const handleReadToggle = async (article: BookmarkArticle) => {
    try {
      if (article.read) {
        await unmarkArticleAsRead(article.id)
        setArticles((current) =>
          current.map((item) => (item.id === article.id ? { ...item, read: false } : item))
        )
      } else {
        await markArticleAsRead(article.id)
        setArticles((current) =>
          current.map((item) => (item.id === article.id ? { ...item, read: true } : item))
        )
      }
    } catch {
      setError('Failed to update read status.')
    }
  }

  if (loading) {
    return (
      <div className="container mx-auto px-4 py-8 max-w-7xl text-center text-gray-400" data-testid="bookmarks-page">
        Loading reading list...
      </div>
    )
  }

  if (error && articles.length === 0 && totalCount === 0) {
    return (
      <div className="container mx-auto px-4 py-8 max-w-7xl text-center" data-testid="bookmarks-page">
        <p className="text-red-400 mb-4">{error}</p>
        <button
          type="button"
          className="px-4 py-2 bg-primary-600 text-white rounded-lg"
          onClick={loadBookmarks}
        >
          Retry
        </button>
      </div>
    )
  }

  return (
    <div className="container mx-auto px-4 py-8 max-w-7xl" data-testid="bookmarks-page">
      <div className="glass-effect rounded-2xl p-8 mb-8 animate-fade-in">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
          <div>
            <h1 className="text-4xl md:text-5xl font-bold bg-gradient-to-r from-primary-400 to-primary-600 bg-clip-text text-transparent mb-2">
              Reading List
            </h1>
            <p className="text-gray-400 text-lg">Your curated collection of bookmarked articles</p>
          </div>
          <div className="flex items-center space-x-6">
            <a
              href="/articles"
              className="group flex items-center px-4 py-3 bg-gradient-to-r from-dark-700 to-dark-600 border border-dark-500 text-gray-300 rounded-xl font-medium transition-all duration-200 hover:from-primary-600 hover:to-primary-700 hover:border-primary-500 hover:text-white hover:scale-105 hover:shadow-lg hover:shadow-primary-500/25"
            >
              <svg className="w-5 h-5 mr-2 transition-transform group-hover:scale-110" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9.5a2.5 2.5 0 00-2.5-2.5H15" />
              </svg>
              Back to All Articles
            </a>
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
        <div className="glass-effect rounded-2xl p-12 text-center animate-fade-in">
          <div className="w-20 h-20 mx-auto mb-6 bg-gradient-to-r from-primary-600/20 to-primary-700/20 rounded-full flex items-center justify-center">
            <svg className="w-10 h-10 text-primary-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" />
            </svg>
          </div>
          <h2 className="text-2xl font-bold text-gray-200 mb-4">No bookmarked articles yet</h2>
          <p className="text-gray-400 mb-8 max-w-md mx-auto leading-relaxed">
            Articles you bookmark will appear here in your reading list.
          </p>
          <a
            href="/articles"
            className="group inline-flex items-center px-6 py-3 bg-gradient-to-r from-primary-600 to-primary-700 text-white rounded-xl font-medium transition-all duration-200 hover:from-primary-700 hover:to-primary-800 hover:scale-105 hover:shadow-lg hover:shadow-primary-500/25"
          >
            <svg className="w-5 h-5 mr-2 transition-transform group-hover:scale-110" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9.5a2.5 2.5 0 00-2.5-2.5H15" />
            </svg>
            Browse Articles
          </a>
        </div>
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
    </div>
  )
}
