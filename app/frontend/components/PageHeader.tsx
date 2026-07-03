import { formatLastUpdated } from '../utils/format'

interface PageHeaderProps {
  totalCount: number
  lastUpdated: string | null
  showRead?: boolean
  onShowReadChange?: (showRead: boolean) => void
  onFetchNews?: () => void
  fetchingNews?: boolean
  fetchMessage?: string | null
}

export default function PageHeader({
  totalCount,
  lastUpdated,
  showRead = false,
  onShowReadChange,
  onFetchNews,
  fetchingNews = false,
  fetchMessage = null,
}: PageHeaderProps) {
  return (
    <div className="glass-effect rounded-2xl p-8 mb-8 animate-fade-in">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
        <div>
          <h1 className="text-4xl md:text-5xl font-bold bg-gradient-to-r from-primary-400 to-primary-600 bg-clip-text text-transparent mb-2">
            Developer News Aggregator
          </h1>
          <p className="text-gray-400 text-lg">Stay updated with the latest in tech and development</p>
          {fetchMessage && (
            <p className="text-sm text-primary-300 mt-2" data-testid="fetch-message">{fetchMessage}</p>
          )}
        </div>
        <div className="flex flex-wrap items-center gap-3">
          {onFetchNews && (
            <button
              type="button"
              className="group flex items-center px-4 py-2 bg-gradient-to-r from-blue-600 to-blue-700 text-white rounded-xl font-medium transition-all duration-200 hover:from-blue-700 hover:to-blue-800 hover:scale-105 disabled:opacity-60 disabled:hover:scale-100"
              onClick={onFetchNews}
              disabled={fetchingNews}
              data-testid="fetch-news-button"
            >
              <svg className={`w-4 h-4 mr-2 ${fetchingNews ? 'animate-spin' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
              </svg>
              {fetchingNews ? 'Fetching...' : 'Fetch News'}
            </button>
          )}
          <a
            href="/sources"
            className="group flex items-center px-4 py-2 bg-gradient-to-r from-purple-600 to-purple-700 text-white rounded-xl font-medium transition-all duration-200 hover:from-purple-700 hover:to-purple-800 hover:scale-105 hover:shadow-lg hover:shadow-purple-500/25"
          >
            Sources
          </a>
          <a
            href="/bookmarks"
            className="group flex items-center px-4 py-2 bg-gradient-to-r from-primary-600 to-primary-700 text-white rounded-xl font-medium transition-all duration-200 hover:from-primary-700 hover:to-primary-800 hover:scale-105 hover:shadow-lg hover:shadow-primary-500/25"
          >
            <svg className="w-4 h-4 mr-2 transition-transform group-hover:scale-110" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" />
            </svg>
            Reading List
          </a>
          <a
            href="/read"
            className="group flex items-center px-4 py-2 bg-gradient-to-r from-green-600 to-green-700 text-white rounded-xl font-medium transition-all duration-200 hover:from-green-700 hover:to-green-800 hover:scale-105 hover:shadow-lg hover:shadow-green-500/25"
          >
            <svg className="w-4 h-4 mr-2 transition-transform group-hover:scale-110" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            Already Read
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
          {onShowReadChange && (
            <label className="flex items-center gap-2 text-sm text-gray-400 cursor-pointer">
              <input
                type="checkbox"
                className="rounded border-dark-600 bg-dark-800 text-primary-500 focus:ring-primary-500"
                checked={showRead}
                onChange={(event) => onShowReadChange(event.target.checked)}
                data-testid="show-read-toggle"
              />
              Show read articles
            </label>
          )}
          <div className="text-sm text-gray-400">
            <div className="flex items-center space-x-2">
              <span className="w-2 h-2 bg-primary-500 rounded-full animate-pulse" />
              <span>
                Total: <span className="text-primary-400 font-semibold">{totalCount}</span> articles
              </span>
            </div>
            {lastUpdated && (
              <div className="text-xs text-gray-500 mt-1">
                Updated {formatLastUpdated(lastUpdated)}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
