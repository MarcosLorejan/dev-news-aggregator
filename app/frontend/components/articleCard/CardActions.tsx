import type { MouseEvent } from 'react'
import { Link } from 'react-router-dom'
import Button from '../ui/Button'
import { FOCUS_RING } from '../ui/buttonStyles'
import { cn } from '../../utils/cn'
import type { CardThemeStyles } from './cardThemes'

function stopPropagation(event: MouseEvent) {
  event.stopPropagation()
}

const ICON_BTN = cn(
  'p-2 rounded-lg border border-transparent transition-colors duration-200 motion-sensitive',
  FOCUS_RING
)

export function DismissButton({ onClick }: { onClick: () => void }) {
  return (
    <button
      type="button"
      className={cn(
        'group/dismiss p-1.5 text-gray-500 hover:text-red-400 hover:bg-red-400/10 rounded-lg transition-colors duration-200 motion-sensitive',
        FOCUS_RING
      )}
      title="Dismiss article"
      aria-label="Dismiss article"
      onClick={(event) => {
        stopPropagation(event)
        onClick()
      }}
    >
      <svg
        className="w-4 h-4"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
        aria-hidden="true"
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
            ? 'bg-red-600/15 border-red-500/40 text-red-300 hover:bg-red-600/25 hover:border-red-500/60'
            : 'bg-primary-600/15 border-primary-500/40 text-primary-300 hover:bg-primary-600/25 hover:border-primary-500/60'
          : 'bg-dark-800/80 border-dark-600 text-gray-400 hover:bg-primary-600/10 hover:border-primary-500/40 hover:text-primary-200'
      )}
      title={title}
      aria-label={title}
      onClick={(event) => {
        stopPropagation(event)
        onClick()
      }}
    >
      <svg
        className="w-4 h-4"
        fill={active || isRemove ? 'currentColor' : 'none'}
        stroke="currentColor"
        viewBox="0 0 24 24"
        aria-hidden="true"
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
          ? 'bg-orange-600/15 border-orange-500/40 text-orange-300 hover:bg-orange-600/25 hover:border-orange-500/60'
          : active
            ? 'bg-green-600/15 border-green-500/40 text-green-300 hover:bg-orange-600/15 hover:border-orange-500/40 hover:text-orange-200'
            : 'bg-dark-800/80 border-dark-600 text-gray-400 hover:bg-green-600/10 hover:border-green-500/40 hover:text-green-200'
      )}
      title={title}
      aria-label={title}
      onClick={(event) => {
        stopPropagation(event)
        onClick()
      }}
    >
      <svg
        className="w-4 h-4"
        fill={active && !isUnmark ? 'currentColor' : 'none'}
        stroke="currentColor"
        viewBox="0 0 24 24"
        aria-hidden="true"
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
          className="w-4 h-4 mr-2"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
          aria-hidden="true"
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
      className={cn(
        'group/detail px-4 py-2 bg-dark-800/80 border border-dark-600 text-gray-300 rounded-lg font-medium transition-colors duration-200 motion-sensitive',
        FOCUS_RING,
        styles.detailsHover,
        'hover:text-white hover:border-dark-500'
      )}
      onClick={stopPropagation}
    >
      <span className="flex items-center">
        Details
        <svg
          className="w-4 h-4 ml-2 transition-transform motion-safe:group-hover/detail:translate-x-0.5"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
          aria-hidden="true"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 5l7 7-7 7" />
        </svg>
      </span>
    </Link>
  )
}
