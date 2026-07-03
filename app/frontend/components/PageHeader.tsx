import { formatLastUpdated } from '../utils/format'

interface PageHeaderProps {
  totalCount: number
  lastUpdated: string | null
}

export default function PageHeader({ totalCount, lastUpdated }: PageHeaderProps) {
  return (
    <div className="glass-effect rounded-2xl p-8 mb-8 animate-fade-in">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
        <div>
          <h1 className="text-4xl md:text-5xl font-bold bg-gradient-to-r from-primary-400 to-primary-600 bg-clip-text text-transparent mb-2">
            Developer News Aggregator
          </h1>
          <p className="text-gray-400 text-lg">Stay updated with the latest in tech and development</p>
        </div>
        <div className="flex items-center space-x-4">
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
