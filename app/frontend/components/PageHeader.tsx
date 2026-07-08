import { NavLink } from 'react-router-dom'
import { formatLastUpdated } from '../utils/format'
import { buttonClassName } from './ui/Button'
import Card from './ui/Card'
import Button from './ui/Button'

interface PageHeaderProps {
  totalCount: number
  lastUpdated: string | null
  showRead?: boolean
  onShowReadChange?: (showRead: boolean) => void
  onFetchNews?: () => void
  fetchingNews?: boolean
  fetchMessage?: string | null
}

function navLinkClassName(color: 'blue' | 'purple') {
  return ({ isActive }: { isActive: boolean }) =>
    buttonClassName({
      color,
      className: isActive ? 'ring-2 ring-white/30' : undefined,
    })
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
    <Card padding="lg" tone="elevated" className="mb-8" animate>
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
        <div>
          <h1 className="text-h1 md:text-display font-bold bg-gradient-to-r from-primary-400 to-primary-600 bg-clip-text text-transparent mb-2">
            Developer News Aggregator
          </h1>
          <p className="text-body-lg text-gray-400">Stay updated with the latest in tech and development</p>
          {fetchMessage && (
            <p className="text-sm text-primary-300 mt-2" data-testid="fetch-message">{fetchMessage}</p>
          )}
        </div>
        <div className="flex flex-wrap items-center gap-3">
          {onFetchNews && (
            <Button
              color="blue"
              className="group"
              onClick={onFetchNews}
              disabled={fetchingNews}
              data-testid="fetch-news-button"
            >
              <svg className={`w-4 h-4 mr-2 ${fetchingNews ? 'animate-spin' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
              </svg>
              {fetchingNews ? 'Fetching...' : 'Fetch News'}
            </Button>
          )}
          <NavLink to="/sources" className={navLinkClassName('purple')}>
            Sources
          </NavLink>
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
    </Card>
  )
}
