import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import {
  bookmarkArticle,
  dismissArticle,
  fetchArticles,
  fetchNews,
  markArticleAsRead,
  undismissArticle,
  unbookmarkArticle,
  unmarkArticleAsRead,
  type Article,
} from '../api/articles'
import { isAbortError } from '../api/client'
import type { ArticlesIndexResponse } from '../types/article'
import { parameterize, truncate } from '../utils/format'
import ArticleList from '../components/ArticleList'
import ArticleListSkeleton from '../components/ArticleListSkeleton'
import CategoryFilter from '../components/CategoryFilter'
import DismissToast from '../components/DismissToast'
import PageHeader from '../components/PageHeader'
import PageHeaderSkeleton from '../components/PageHeaderSkeleton'
import PageContainer from '../components/ui/PageContainer'
import Card from '../components/ui/Card'
import PaginationControls from '../components/PaginationControls'
import ScoreFilter, { parseScoreFilter, scoreFilterParams, type ScoreFilterValue } from '../components/ScoreFilter'
import { usePatchSearchParams } from '../hooks/useSearchParamState'

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
  const [searchParams] = useSearchParams()
  const patchSearchParams = usePatchSearchParams()

  const currentPage = (() => {
    const raw = parseInt(searchParams.get('page') ?? '1', 10)
    return Number.isFinite(raw) && raw >= 1 ? raw : 1
  })()
  const activeFilter = searchParams.get('category') ?? 'all'
  const activeScoreFilter = parseScoreFilter(searchParams.get('score'))
  const showRead = searchParams.get('show_read') === 'true'

  const [data, setData] = useState<ArticlesIndexResponse | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [fetchingNews, setFetchingNews] = useState(false)
  const [fetchMessage, setFetchMessage] = useState<string | null>(null)
  const [dismissingIds, setDismissingIds] = useState<Set<number>>(new Set())
  const [removedIds, setRemovedIds] = useState<Set<number>>(new Set())
  const [toast, setToast] = useState<{ articleId: number; title: string; timeLeft: number } | null>(null)

  const countdownRef = useRef<number | null>(null)
  const pendingDismissRef = useRef<{ articleId: number; title: string } | null>(null)
  const abortRef = useRef<AbortController | null>(null)

  const loadArticles = useCallback(async (options?: { page?: number }) => {
    abortRef.current?.abort()
    const controller = new AbortController()
    abortRef.current = controller
    const { signal } = controller

    const page = options?.page ?? currentPage
    setLoading(true)
    setError(null)
    try {
      const response = await fetchArticles({
        page,
        show_read: showRead,
        category: activeFilter !== 'all' ? activeFilter : undefined,
        ...scoreFilterParams(activeScoreFilter),
        signal,
      })
      if (signal.aborted) return
      setData(response)
      setRemovedIds(new Set())
      if (options?.page !== undefined && options.page !== currentPage) {
        patchSearchParams((params) => {
          if (options.page! <= 1) params.delete('page')
          else params.set('page', String(options.page))
        })
      }
    } catch (err) {
      if (isAbortError(err) || signal.aborted) return
      setError('Failed to load articles. Please try again.')
    } finally {
      if (!signal.aborted) setLoading(false)
    }
  }, [showRead, activeScoreFilter, activeFilter, currentPage, patchSearchParams])

  useEffect(() => {
    void loadArticles()
    return () => {
      abortRef.current?.abort()
    }
  }, [loadArticles])

  const articleCategories = useMemo(
    () => (data ? buildArticleCategories(data) : {}),
    [data]
  )

  const categoryCounts = useMemo(() => data?.category_counts ?? {}, [data])

  const allArticlesCount = useMemo(
    () => Object.values(categoryCounts).reduce((sum, count) => sum + count, 0),
    [categoryCounts]
  )

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

    try {
      await undismissArticle(articleId)
      clearDismissTimer()
      setToast(null)
      setDismissingIds((prev) => {
        const next = new Set(prev)
        next.delete(articleId)
        return next
      })
      pendingDismissRef.current = null
    } catch {
      setError('Failed to restore article.')
    }
  }, [toast])

  const handleDismiss = useCallback(async (article: Article) => {
    if (toast) {
      finalizeDismiss(toast.articleId)
    }

    setDismissingIds(new Set([article.id]))
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
  }, [finalizeDismiss, toast])

  const handleShowReadChange = (value: boolean) => {
    patchSearchParams((params) => {
      if (value) params.set('show_read', 'true')
      else params.delete('show_read')
      params.delete('page')
    })
  }

  const handleScoreFilterChange = (value: ScoreFilterValue) => {
    patchSearchParams((params) => {
      if (value === 'all') params.delete('score')
      else params.set('score', value)
      params.delete('page')
    })
  }

  const handleFilterChange = (filter: string) => {
    patchSearchParams((params) => {
      if (filter === 'all') params.delete('category')
      else params.set('category', filter)
      params.delete('page')
    })
  }

  const handlePageChange = (page: number) => {
    patchSearchParams((params) => {
      if (page <= 1) params.delete('page')
      else params.set('page', String(page))
    })
  }

  const handleFetchNews = async () => {
    setFetchingNews(true)
    setFetchMessage(null)
    setError(null)
    try {
      await fetchNews()
      setFetchMessage('News fetch queued. New articles will appear shortly.')
      patchSearchParams((params) => {
        params.delete('page')
      })
      await loadArticles({ page: 1 })
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch news.')
    } finally {
      setFetchingNews(false)
    }
  }

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
        if (!showRead) {
          setRemovedIds((prev) => new Set(prev).add(article.id))
        } else {
          updateArticle(article.id, { read: true })
        }
      }
    } catch {
      setError('Failed to update read status.')
    }
  }

  if (loading) {
    return (
      <PageContainer testId="articles-page" role="status" aria-live="polite" aria-busy>
        <PageHeaderSkeleton />
        <ArticleListSkeleton count={6} label="Loading articles" />
      </PageContainer>
    )
  }

  if (error && !data) {
    return (
      <div className="container mx-auto px-4 py-8 max-w-7xl text-center" data-testid="articles-page">
        <p className="text-red-400 mb-4">{error}</p>
        <button
          type="button"
          className="px-4 py-2 bg-primary-600 text-white rounded-lg"
          onClick={() => loadArticles()}
        >
          Retry
        </button>
      </div>
    )
  }

  const showEmptyFeed = !data || (allArticlesCount === 0 && articles.length === 0)

  if (showEmptyFeed) {
    return (
      <div className="container mx-auto px-4 py-8 max-w-7xl" data-testid="articles-page">
        <PageHeader
          totalCount={data?.pagination.total_count ?? 0}
          lastUpdated={data?.last_updated ?? null}
          showRead={showRead}
          onShowReadChange={handleShowReadChange}
          onFetchNews={handleFetchNews}
          fetchingNews={fetchingNews}
          fetchMessage={fetchMessage}
        />
        <Card tone="panel" padding="empty" animate>
          <div className="w-20 h-20 mx-auto mb-6 bg-gradient-to-r from-primary-600/20 to-primary-700/20 rounded-full flex items-center justify-center">
            <svg className="w-10 h-10 text-primary-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9.5a2.5 2.5 0 00-2.5-2.5H15" />
            </svg>
          </div>
          <h2 className="text-h2 text-gray-100 mb-4">No articles found</h2>
          <p className="text-gray-300 mb-8 max-w-md mx-auto leading-relaxed">
            Your feed is empty. Click Fetch News to pull the latest articles from your configured sources.
          </p>
          <button
            type="button"
            className="px-6 py-3 bg-primary-600 text-white rounded-xl font-medium hover:bg-primary-700 disabled:opacity-60"
            onClick={handleFetchNews}
            disabled={fetchingNews}
            data-testid="fetch-news-button"
          >
            {fetchingNews ? 'Fetching...' : 'Fetch News'}
          </button>
        </Card>
      </div>
    )
  }

  return (
    <div className="container mx-auto px-4 py-8 max-w-7xl" data-testid="articles-page">
      <PageHeader
        totalCount={data.pagination.total_count}
        lastUpdated={data.last_updated}
        showRead={showRead}
        onShowReadChange={handleShowReadChange}
        onFetchNews={handleFetchNews}
        fetchingNews={fetchingNews}
        fetchMessage={fetchMessage}
      />

      {error && (
        <div className="mb-4 text-sm text-red-400">{error}</div>
      )}

      <ScoreFilter
        activeScoreFilter={activeScoreFilter}
        onScoreFilterChange={handleScoreFilterChange}
      />

      <CategoryFilter
        categories={data.categories}
        categoryCounts={categoryCounts}
        totalCount={allArticlesCount}
        activeFilter={activeFilter}
        onFilterChange={handleFilterChange}
      />

      <ArticleList
        articles={articles}
        articleCategories={articleCategories}
        dismissingIds={dismissingIds}
        onDismiss={handleDismiss}
        onUndoDismiss={handleUndoDismiss}
        onBookmarkToggle={handleBookmarkToggle}
        onReadToggle={handleReadToggle}
      />

      <PaginationControls
        currentPage={data.pagination.current_page}
        totalPages={data.pagination.total_pages}
        totalCount={data.pagination.total_count}
        perPage={data.pagination.per_page}
        onPageChange={handlePageChange}
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
