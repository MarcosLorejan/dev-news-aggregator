import type { DismissedArticle } from '../types/dismissedArticle'
import {
  formatBookmarkedDate,
  formatPublishedDate,
  formatTimeAgo,
  truncate,
} from '../utils/format'

interface DismissedArticleCardProps {
  article: DismissedArticle
  index: number
  variant: 'dismissed' | 'recent'
  onRestore: (article: DismissedArticle) => void
}

export default function DismissedArticleCard({
  article,
  index,
  variant,
  onRestore,
}: DismissedArticleCardProps) {
  const isRecent = variant === 'recent'
  const accentHover = isRecent ? 'group-hover:text-orange-300' : 'group-hover:text-red-300'
  const linkHover = isRecent ? 'hover:text-orange-400' : 'hover:text-red-400'
  const shadowHover = isRecent ? 'hover:shadow-orange-500/10' : 'hover:shadow-red-500/10'
  const borderClass = isRecent ? 'border-orange-500/20' : 'border-red-500/20'
  const badgeClasses = isRecent
    ? 'bg-gradient-to-r from-orange-600/20 to-orange-700/20 text-orange-300 border border-orange-500/30'
    : 'bg-gradient-to-r from-red-600/20 to-red-700/20 text-red-300 border border-red-500/30'
  const dateAccent = isRecent ? 'text-orange-400' : 'text-red-400'
  const restoreLabel = isRecent ? 'Quick Restore' : 'Restore'

  const handleRestore = () => {
    if (!isRecent && !window.confirm('Restore this article to your main feed?')) {
      return
    }
    onRestore(article)
  }

  const badgeText = isRecent
    ? article.dismissed_at
      ? formatTimeAgo(article.dismissed_at)
      : 'Recently'
    : article.dismissed_at
      ? `Dismissed ${formatBookmarkedDate(article.dismissed_at)}`
      : 'Dismissed'

  return (
    <article
      className={`article-card group glass-effect rounded-2xl p-6 transition-all duration-300 hover:scale-[1.02] hover:shadow-2xl ${shadowHover} animate-fade-in ${borderClass}`}
      style={{ animationDelay: `${index * 50}ms` }}
    >
      <div className="flex justify-between items-start mb-4">
        <div className="flex-1">
          <h2 className={`text-xl font-bold text-gray-100 mb-2 leading-tight ${accentHover} transition-colors duration-200`}>
            <a
              href={article.url}
              target="_blank"
              rel="noopener noreferrer"
              className={`${linkHover} transition-colors duration-200 flex items-start group/link`}
            >
              <span className="flex-1">{article.title}</span>
              <svg className="w-4 h-4 ml-2 mt-1 opacity-60 group-hover/link:opacity-100 transition-all duration-200 group-hover/link:translate-x-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
              </svg>
            </a>
          </h2>
        </div>
        <div className="ml-4 flex items-center space-x-2">
          <span className={`inline-block px-3 py-1.5 text-xs font-semibold rounded-full ${badgeClasses}`}>
            {badgeText}
          </span>
        </div>
      </div>

      {article.description && (
        <p className="text-gray-400 mb-6 line-clamp-3 leading-relaxed">
          {truncate(article.description, 280)}
        </p>
      )}

      <div className="flex justify-between items-center text-sm border-t border-dark-700 pt-4">
        <div className="flex items-center space-x-6 text-gray-500">
          <span className="flex items-center">
            <svg className={`w-4 h-4 mr-1.5 ${dateAccent}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
            {formatPublishedDate(article.published_at)}
          </span>
          <span className="flex items-center">
            <svg className="w-4 h-4 mr-1.5 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V5a2 2 0 00-2-2h-.095c-.5 0-.905.405-.905.905 0 .714-.211 1.412-.608 2.006L7 11v9m7-10h-2M7 20H5a2 2 0 01-2-2v-6a2 2 0 012-2h2.5" />
            </svg>
            {article.score}
          </span>
          <span className="flex items-center">
            <svg className="w-4 h-4 mr-1.5 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
            </svg>
            {article.comment_count}
          </span>
        </div>

        <div className="flex items-center space-x-3">
          <button
            type="button"
            className="group/restore px-4 py-2 bg-gradient-to-r from-green-600 to-green-700 text-white rounded-lg font-medium transition-all duration-200 hover:from-green-700 hover:to-green-800 hover:scale-105 hover:shadow-lg hover:shadow-green-500/25"
            title="Restore article"
            onClick={handleRestore}
          >
            <span className="flex items-center">
              <svg className="w-4 h-4 mr-2 transition-transform group-hover/restore:scale-110" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
              </svg>
              {restoreLabel}
            </span>
          </button>
        </div>
      </div>
    </article>
  )
}
