import type { ReactNode } from 'react'
import { formatPublishedDate } from '../../utils/format'
import type { ArticleCardData, CardThemeStyles } from './cardThemes'

interface CardMetadataProps {
  article: ArticleCardData
  styles: CardThemeStyles
  extra?: ReactNode
}

export default function CardMetadata({ article, styles, extra }: CardMetadataProps) {
  return (
    <div className="flex items-center space-x-6 text-gray-300">
      <span className="flex items-center">
        <svg
          className={`w-4 h-4 mr-1.5 ${styles.dateAccent}`}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth="2"
            d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
          />
        </svg>
        {formatPublishedDate(article.published_at)}
      </span>
      <span className="flex items-center">
        <svg
          className="w-4 h-4 mr-1.5 text-green-400"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth="2"
            d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V5a2 2 0 00-2-2h-.095c-.5 0-.905.405-.905.905 0 .714-.211 1.412-.608 2.006L7 11v9m7-10h-2M7 20H5a2 2 0 01-2-2v-6a2 2 0 012-2h2.5"
          />
        </svg>
        {article.score}
      </span>
      <span className="flex items-center">
        <svg
          className="w-4 h-4 mr-1.5 text-blue-400"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth="2"
            d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
          />
        </svg>
        {article.comment_count}
      </span>
      {extra}
    </div>
  )
}
