import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import {
  bookmarkArticle,
  dismissArticle,
  fetchArticles,
  markArticleAsRead,
  undismissArticle,
  unbookmarkArticle,
  unmarkArticleAsRead,
  type Article,
} from '../api/articles'
import type { ArticlesIndexResponse } from '../types/article'
import { parameterize, truncate } from '../utils/format'
import ArticleList from '../components/ArticleList'
import CategoryFilter from '../components/CategoryFilter'
import DismissToast from '../components/DismissToast'
import PageHeader from '../components/PageHeader'

const DISMISS_TIMEOUT_SECONDS = 15

function buildArticleCategories(response: ArticlesIndexResponse): Record<number, string> {
  const map: Record<number, string> = {}
  Object.entries(response.articles_by_category).forEach(([category, ids]) => {
    const slug = parameterize(category)
    ids.forEach((id) => {
      map[id] = slug
    })
  })
  return map
}

export default function ArticlesIndexPage() {
  const [data, setData] = useState<ArticlesIndexResponse | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [activeFilter, setActiveFilter] = useState('all')
  const [dismissingIds, setDismissingIds] = useState<Set<number>>(new Set())
  const [removedIds, setRemovedIds] = useState<Set<number>>(new Set())
  const [toast, setToast] = useState<{ articleId: number; title: string; timeLeft: number } | null>(null)

  const countdownRef = useRef<number | null>(null)
  const pendingDismissRef = useRef<{ articleId: number; title: string } | null>(null)

  const loadArticles = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const response = await fetchArticles()
      setData(response)
      setRemovedIds(new Set())
    } catch {
      setError('Failed to load articles. Please try again.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    loadArticles()
  }, [loadArticles])

  const articleCategories = useMemo(
    () => (data ? buildArticleCategories(data) : {}),
    [data]
  )

  const categoryCounts = useMemo(() => {
    if (!data) return {}
    return Object.fromEntries(
      Object.entries(data.articles_by_category).map(([name, ids]) => [name, ids.length])
    )
  }, [data])

  const articles = useMemo(
    () => data?.articles.filter((article) => !removedIds.has(article.id)) ?? [],
    [data, removedIds]
  )

  const clearDismissTimer = () => {
    if (countdownRef.current) {
      window.clearInterval(countdownRef.current)
      countdownRef.current = null
    }
  }

  const finalizeDismiss = useCallback((articleId: number) => {
    clearDismissTimer()
    setToast(null)
    setDismissingIds((prev) => {
      const next = new Set(prev)
      next.delete(articleId)
      return next
    })
    setRemovedIds((prev) => new Set(prev).add(articleId))
    pendingDismissRef.current = null
  }, [])

  const handleUndoDismiss = useCallback(async (article?: Article) => {
    const articleId = article?.id ?? toast?.articleId
    if (!articleId) return

    clearDismissTimer()
    setToast(null)
    setDismissingIds((prev) => {
      const next = new Set(prev)
      next.delete(articleId)
      return next
    })
    pendingDismissRef.current = null

    try {
      await undismissArticle(articleId)
    } catch {
      setError('Failed to restore article.')
    }
  }, [toast])

  const handleDismiss = useCallback(async (article: Article) => {
    setDismissingIds((prev) => new Set(prev).add(article.id))
    pendingDismissRef.current = { articleId: article.id, title: truncate(article.title, 50) }

    try {
      await dismissArticle(article.id)
      setToast({
        articleId: article.id,
        title: truncate(article.title, 50),
        timeLeft: DISMISS_TIMEOUT_SECONDS,
      })

      clearDismissTimer()
      countdownRef.current = window.setInterval(() => {
        setToast((current) => {
          if (!current) return null
          if (current.timeLeft <= 1) {
            finalizeDismiss(current.articleId)
            return null
          }
          return { ...current, timeLeft: current.timeLeft - 1 }
        })
      }, 1000)
    } catch {
      setDismissingIds((prev) => {
        const next = new Set(prev)
        next.delete(article.id)
        return next
      })
      setError('Failed to dismiss article.')
    }
  }, [finalizeDismiss])

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.ctrlKey && event.key === 'z' && toast) {
        event.preventDefault()
        handleUndoDismiss()
      }
    }

    document.addEventListener('keydown', onKeyDown)
    return () => document.removeEventListener('keydown', onKeyDown)
  }, [toast, handleUndoDismiss])

  useEffect(() => () => clearDismissTimer(), [])

  const updateArticle = (articleId: number, changes: Partial<Article>) => {
    setData((current) => {
      if (!current) return current
      return {
        ...current,
        articles: current.articles.map((article) =>
          article.id === articleId ? { ...article, ...changes } : article
        ),
      }
    })
  }

  const handleBookmarkToggle = async (article: Article) => {
    try {
      if (article.bookmarked) {
        await unbookmarkArticle(article.id)
        updateArticle(article.id, { bookmarked: false })
      } else {
        await bookmarkArticle(article.id)
        updateArticle(article.id, { bookmarked: true })
      }
    } catch {
      setError('Failed to update bookmark.')
    }
  }

  const handleReadToggle = async (article: Article) => {
    try {
      if (article.read) {
        await unmarkArticleAsRead(article.id)
        updateArticle(article.id, { read: false })
      } else {
        await markArticleAsRead(article.id)
        updateArticle(article.id, { read: true })
      }
    } catch {
      setError('Failed to update read status.')
    }
  }

  if (loading) {
    return (
      <div className="container mx-auto px-4 py-8 max-w-7xl text-center text-gray-400" data-testid="articles-page">
        Loading articles...
      </div>
    )
  }

  if (error && !data) {
    return (
      <div className="container mx-auto px-4 py-8 max-w-7xl text-center" data-testid="articles-page">
        <p className="text-red-400 mb-4">{error}</p>
        <button
          type="button"
          className="px-4 py-2 bg-primary-600 text-white rounded-lg"
          onClick={loadArticles}
        >
          Retry
        </button>
      </div>
    )
  }

  if (!data || articles.length === 0) {
    return (
      <div className="container mx-auto px-4 py-8 max-w-7xl" data-testid="articles-page">
        <PageHeader totalCount={data?.pagination.total_count ?? 0} lastUpdated={data?.last_updated ?? null} />
        <div className="glass-effect rounded-2xl p-12 text-center animate-fade-in">
          <div className="w-20 h-20 mx-auto mb-6 bg-gradient-to-r from-primary-600/20 to-primary-700/20 rounded-full flex items-center justify-center">
            <svg className="w-10 h-10 text-primary-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9.5a2.5 2.5 0 00-2.5-2.5H15" />
            </svg>
          </div>
          <h2 className="text-2xl font-bold text-gray-200 mb-4">No articles found</h2>
          <p className="text-gray-400 mb-8 max-w-md mx-auto leading-relaxed">
            The news aggregator hasn&apos;t fetched any articles yet. Run the following command to populate your feed with the latest tech news:
          </p>
          <div className="bg-dark-800 border border-dark-700 rounded-xl px-6 py-4 inline-block mb-6">
            <code className="text-primary-300 font-mono text-sm">bin/rails news:fetch</code>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="container mx-auto px-4 py-8 max-w-7xl" data-testid="articles-page">
      <PageHeader totalCount={data.pagination.total_count} lastUpdated={data.last_updated} />

      {error && (
        <div className="mb-4 text-sm text-red-400">{error}</div>
      )}

      <CategoryFilter
        categories={data.categories}
        categoryCounts={categoryCounts}
        totalCount={articles.length}
        activeFilter={activeFilter}
        onFilterChange={setActiveFilter}
      />

      <ArticleList
        articles={articles}
        articleCategories={articleCategories}
        activeFilter={activeFilter}
        dismissingIds={dismissingIds}
        onDismiss={handleDismiss}
        onUndoDismiss={handleUndoDismiss}
        onBookmarkToggle={handleBookmarkToggle}
        onReadToggle={handleReadToggle}
      />

      {toast && (
        <DismissToast
          articleTitle={toast.title}
          timeLeft={toast.timeLeft}
          onUndo={ () => handleUndoDismiss() }
        />
      )}
    </div>
  )
}

// Expose for system tests that call initializeCategoryFilter after Turbo navigation
declare global {
  interface Window {
    initializeCategoryFilter?: () => void
  }
}

if (typeof window !== 'undefined') {
  window.initializeCategoryFilter = () => {
    // React manages filter state; no-op keeps legacy system tests from failing.
  }
}
