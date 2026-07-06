import { useCallback, useEffect, useState } from 'react'
import { useParams } from 'react-router-dom'
import {
  bookmarkArticle,
  fetchArticle,
  markArticleAsRead,
  unbookmarkArticle,
  unmarkArticleAsRead,
} from '../api/articles'
import type { Article } from '../types/article'
import {
  formatDetailDate,
  humanizeSourceType,
  safeExternalUrl,
} from '../utils/format'
import { useConfirmDialog } from '../hooks/useConfirmDialog'

export default function ArticleShowPage() {
  const { id } = useParams<{ id: string }>()
  const articleId = Number(id)

  const [article, setArticle] = useState<Article | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)
  const { confirm, dialog } = useConfirmDialog()

  const loadArticle = useCallback(async () => {
    if (!articleId || Number.isNaN(articleId)) {
      setError('Article not found.')
      setLoading(false)
      return
    }

    setLoading(true)
    setError(null)
    try {
      const response = await fetchArticle(articleId)
      setArticle(response)
    } catch {
      setArticle(null)
      setError('Article not found.')
    } finally {
      setLoading(false)
    }
  }, [articleId])

  useEffect(() => {
    loadArticle()
  }, [loadArticle])

  const handleReadToggle = async () => {
    if (!article) return
    setActionError(null)
    try {
      if (article.read) {
        await unmarkArticleAsRead(article.id)
        setArticle({ ...article, read: false })
      } else {
        await markArticleAsRead(article.id)
        setArticle({ ...article, read: true })
      }
    } catch {
      setActionError('Failed to update read status.')
    }
  }

  const handleBookmarkToggle = async () => {
    if (!article) return
    if (article.bookmarked) {
      const confirmed = await confirm({
        message: 'Remove this article from your reading list?',
        confirmLabel: 'Remove',
      })
      if (!confirmed) return
    }

    setActionError(null)
    try {
      if (article.bookmarked) {
        await unbookmarkArticle(article.id)
        setArticle({ ...article, bookmarked: false })
      } else {
        await bookmarkArticle(article.id)
        setArticle({ ...article, bookmarked: true })
      }
    } catch {
      setActionError('Failed to update bookmark.')
    }
  }

  if (loading) {
    return (
      <div className="container mx-auto px-4 py-8 max-w-4xl text-center text-gray-400" data-testid="article-show-page">
        Loading article...
      </div>
    )
  }

  if (error || !article) {
    return (
      <div className="container mx-auto px-4 py-8 max-w-4xl text-center" data-testid="article-show-page">
        <p className="text-red-400 mb-4">{error ?? 'Article not found.'}</p>
        <a
          href="/articles"
          className="inline-flex items-center px-4 py-2 bg-primary-600 text-white rounded-lg"
        >
          Back to Articles
        </a>
      </div>
    )
  }

  const sourceUrl = safeExternalUrl(article.url)

  return (
    <div className="container mx-auto px-4 py-8 max-w-4xl" data-testid="article-show-page">
      <div className="mb-8 animate-fade-in">
        <a
          href="/articles"
          className="group inline-flex items-center px-4 py-2 bg-gradient-to-r from-dark-700 to-dark-600 border border-dark-500 text-gray-300 rounded-xl font-medium transition-all duration-200 hover:from-primary-600 hover:to-primary-700 hover:border-primary-500 hover:text-white hover:scale-105 hover:shadow-lg hover:shadow-primary-500/25"
        >
          <svg className="w-4 h-4 mr-2 transition-transform group-hover:scale-110" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
          Back to Articles
        </a>
      </div>

      <article className="glass-effect rounded-2xl p-8 md:p-12 animate-slide-up">
        <div className="mb-8">
          <div className="flex flex-wrap items-center gap-4 mb-6">
            <span className="inline-block px-4 py-2 text-sm font-semibold bg-gradient-to-r from-primary-600/20 to-primary-700/20 text-primary-300 border border-primary-500/30 rounded-full">
              {humanizeSourceType(article.source_type)}
            </span>
            {article.bookmarked && (
              <span className="inline-flex items-center px-3 py-1 text-xs font-medium bg-primary-600/20 text-primary-400 border border-primary-500/30 rounded-full">
                <svg className="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" />
                </svg>
                Bookmarked
              </span>
            )}
            {article.read && (
              <span className="inline-flex items-center px-3 py-1 text-xs font-medium bg-green-600/20 text-green-400 border border-green-500/30 rounded-full">
                <svg className="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                Already Read
              </span>
            )}
          </div>

          <h1 className="text-3xl md:text-4xl font-bold text-gray-100 mb-6 leading-tight">{article.title}</h1>

          <div className="flex flex-wrap items-center gap-6 text-sm text-gray-400 mb-6">
            <span className="flex items-center">
              <svg className="w-4 h-4 mr-2 text-primary-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              {formatDetailDate(article.published_at)}
            </span>
            <span className="flex items-center">
              <svg className="w-4 h-4 mr-2 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V5a2 2 0 00-2-2h-.095c-.5 0-.905.405-.905.905 0 .714-.211 1.412-.608 2.006L7 11v9m7-10h-2M7 20H5a2 2 0 01-2-2v-6a2 2 0 012-2h2.5" />
              </svg>
              {article.score} points
            </span>
            <span className="flex items-center">
              <svg className="w-4 h-4 mr-2 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
              </svg>
              {article.comment_count} comments
            </span>
          </div>
        </div>

        {article.description && (
          <div className="mb-8">
            <div className="prose prose-lg max-w-none">
              <div className="text-gray-300 leading-relaxed text-lg whitespace-pre-wrap">{article.description}</div>
            </div>
          </div>
        )}

        <div className="border-t border-dark-700 pt-8">
          {actionError && <div className="mb-4 text-sm text-red-400">{actionError}</div>}

          <div className="flex flex-col lg:flex-row justify-between items-start lg:items-center gap-6">
            <div className="text-sm text-gray-500 space-y-1">
              <p className="flex items-center">
                <svg className="w-4 h-4 mr-2 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M7 20l4-16m2 16l4-16M6 9h14M4 15h14" />
                </svg>
                External ID: <span className="text-gray-400 ml-1 font-mono">{article.external_id}</span>
              </p>
              <p className="flex items-center">
                <svg className="w-4 h-4 mr-2 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                Last updated: {formatDetailDate(article.updated_at)}
              </p>
            </div>

            <div className="flex flex-wrap gap-4">
              <button
                type="button"
                className={
                  article.read
                    ? 'group inline-flex items-center px-6 py-3 bg-gradient-to-r from-green-600 to-green-700 text-white rounded-xl font-medium transition-all duration-200 hover:from-orange-600 hover:to-orange-700 hover:scale-105 hover:shadow-lg hover:shadow-orange-500/25'
                    : 'group inline-flex items-center px-6 py-3 bg-gradient-to-r from-green-600 to-green-700 text-white rounded-xl font-medium transition-all duration-200 hover:from-green-700 hover:to-green-800 hover:scale-105 hover:shadow-lg hover:shadow-green-500/25'
                }
                onClick={handleReadToggle}
              >
                <svg
                  className="w-5 h-5 mr-2 transition-transform group-hover:scale-110"
                  fill={article.read ? 'currentColor' : 'none'}
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                {article.read ? 'Mark as Unread' : 'Mark as Read'}
              </button>

              <button
                type="button"
                className={
                  article.bookmarked
                    ? 'group inline-flex items-center px-6 py-3 bg-gradient-to-r from-red-600 to-red-700 text-white rounded-xl font-medium transition-all duration-200 hover:from-red-700 hover:to-red-800 hover:scale-105 hover:shadow-lg hover:shadow-red-500/25'
                    : 'group inline-flex items-center px-6 py-3 bg-gradient-to-r from-primary-600 to-primary-700 text-white rounded-xl font-medium transition-all duration-200 hover:from-primary-700 hover:to-primary-800 hover:scale-105 hover:shadow-lg hover:shadow-primary-500/25'
                }
                onClick={handleBookmarkToggle}
              >
                <svg
                  className="w-5 h-5 mr-2 transition-transform group-hover:scale-110"
                  fill={article.bookmarked ? 'currentColor' : 'none'}
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  {article.bookmarked ? (
                    <path d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" />
                  ) : (
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" />
                  )}
                </svg>
                {article.bookmarked ? 'Remove from Reading List' : 'Add to Reading List'}
              </button>

              {sourceUrl && (
                <a
                  href={sourceUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="group inline-flex items-center px-6 py-3 bg-gradient-to-r from-dark-700 to-dark-600 border border-dark-500 text-gray-300 rounded-xl font-medium transition-all duration-200 hover:from-primary-600 hover:to-primary-700 hover:border-primary-500 hover:text-white hover:scale-105 hover:shadow-lg hover:shadow-primary-500/25"
                >
                  Visit Source
                  <svg className="w-5 h-5 ml-2 transition-transform group-hover:translate-x-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                  </svg>
                </a>
              )}
            </div>
          </div>
        </div>
      </article>
      {dialog}
    </div>
  )
}
