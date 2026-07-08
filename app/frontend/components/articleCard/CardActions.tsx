import type { MouseEvent } from 'react'
import { Link } from 'react-router-dom'
import Button from '../ui/Button'
import { cn } from '../../utils/cn'
import type { CardThemeStyles } from './cardThemes'

function stopPropagation(event: MouseEvent) {
  event.stopPropagation()
}

const ICON_BTN =
  'p-2 rounded-lg transition-all duration-200 hover:scale-110 hover:shadow-lg'

export function DismissButton({ onClick }: { onClick: () => void }) {
  return (
    <button
      type="button"
      className="group/dismiss p-1.5 text-gray-500 hover:text-red-400 hover:bg-red-400/10 rounded-lg transition-all duration-200 hover:scale-110"
      title="Dismiss article"
      aria-label="Dismiss article"
      onClick={(event) => {
        stopPropagation(event)
        onClick()
      }}
    >
      <svg
        className="w-4 h-4 transition-transform group-hover/dismiss:scale-110"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" />
      </svg>
    </button>
  )
}

interface BookmarkButtonProps {
  active: boolean
  mode: 'toggle' | 'remove'
  onClick: () => void
}

export function BookmarkButton({ active, mode, onClick }: BookmarkButtonProps) {
  const isRemove = mode === 'remove'
  const title = isRemove
    ? 'Remove from reading list'
    : active
      ? 'Remove from reading list'
      : 'Add to reading list'

  return (
    <button
      type="button"
      className={cn(
        ICON_BTN,
        'group/bookmark',
        isRemove || active
          ? isRemove
            ? 'bg-gradient-to-r from-red-600 to-red-700 text-white hover:from-red-700 hover:to-red-800 hover:shadow-red-500/25'
            : 'bg-gradient-to-r from-primary-600 to-primary-700 text-white hover:from-primary-700 hover:to-primary-800 hover:shadow-primary-500/25'
          : 'bg-dark-700 border border-dark-600 text-gray-400 hover:bg-primary-600 hover:border-primary-500 hover:text-white hover:shadow-primary-500/25'
      )}
      title={title}
      aria-label={title}
      onClick={(event) => {
        stopPropagation(event)
        onClick()
      }}
    >
      <svg
        className="w-4 h-4 transition-transform group-hover/bookmark:scale-110"
        fill={active || isRemove ? 'currentColor' : 'none'}
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth="2"
          d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z"
        />
      </svg>
    </button>
  )
}

interface ReadButtonProps {
  active: boolean
  mode: 'toggle' | 'unmark'
  onClick: () => void
}

export function ReadButton({ active, mode, onClick }: ReadButtonProps) {
  const isUnmark = mode === 'unmark'
  const title = isUnmark ? 'Mark as unread' : active ? 'Mark as unread' : 'Mark as read'

  return (
    <button
      type="button"
      className={cn(
        ICON_BTN,
        'group/read',
        isUnmark
          ? 'bg-gradient-to-r from-orange-600 to-orange-700 text-white hover:from-orange-700 hover:to-orange-800 hover:shadow-orange-500/25'
          : active
            ? 'bg-gradient-to-r from-green-600 to-green-700 text-white hover:from-orange-600 hover:to-orange-700 hover:shadow-orange-500/25'
            : 'bg-dark-700 border border-dark-600 text-gray-400 hover:bg-green-600 hover:border-green-500 hover:text-white hover:shadow-green-500/25'
      )}
      title={title}
      aria-label={title}
      onClick={(event) => {
        stopPropagation(event)
        onClick()
      }}
    >
      <svg
        className="w-4 h-4 transition-transform group-hover/read:scale-110"
        fill={active && !isUnmark ? 'currentColor' : 'none'}
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth="2"
          d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
        />
      </svg>
    </button>
  )
}

export function RestoreButton({ label, onClick }: { label: string; onClick: () => void }) {
  return (
    <Button color="green" size="sm" className="group/restore" title="Restore article" onClick={onClick}>
      <span className="flex items-center">
        <svg
          className="w-4 h-4 mr-2 transition-transform group-hover/restore:scale-110"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth="2"
            d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
          />
        </svg>
        {label}
      </span>
    </Button>
  )
}

export function DetailsLink({ href, styles }: { href: string; styles: CardThemeStyles }) {
  return (
    <Link
      to={href}
      className={`group/detail px-4 py-2 bg-gradient-to-r from-dark-700 to-dark-600 border border-dark-500 text-gray-300 rounded-lg font-medium transition-all duration-200 ${styles.detailsHover} hover:text-white hover:scale-105 hover:shadow-lg`}
      onClick={stopPropagation}
    >
      <span className="flex items-center">
        Details
        <svg
          className="w-4 h-4 ml-2 transition-transform group-hover/detail:translate-x-1"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 5l7 7-7 7" />
        </svg>
      </span>
    </Link>
  )
}
