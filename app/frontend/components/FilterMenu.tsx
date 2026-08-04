import { useEffect, useId, useRef, useState, type ReactNode } from 'react'
import { cn } from '../utils/cn'
import { FOCUS_RING } from './ui/buttonStyles'

interface FilterMenuProps {
  label: string
  summary?: string
  active?: boolean
  align?: 'left' | 'right'
  panelClassName?: string
  testId?: string
  children: ReactNode
}

export default function FilterMenu({
  label,
  summary,
  active = false,
  align = 'left',
  panelClassName,
  testId,
  children,
}: FilterMenuProps) {
  const [open, setOpen] = useState(false)
  const rootRef = useRef<HTMLDivElement>(null)
  const panelId = useId()

  useEffect(() => {
    if (!open) return

    const onPointerDown = (event: MouseEvent) => {
      if (!rootRef.current?.contains(event.target as Node)) {
        setOpen(false)
      }
    }

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') setOpen(false)
    }

    document.addEventListener('mousedown', onPointerDown)
    document.addEventListener('keydown', onKeyDown)
    return () => {
      document.removeEventListener('mousedown', onPointerDown)
      document.removeEventListener('keydown', onKeyDown)
    }
  }, [open])

  return (
    <div ref={rootRef} className="relative shrink-0">
      <button
        type="button"
        className={cn(
          'inline-flex items-center gap-1.5 rounded-lg border px-3 py-2 text-sm font-medium transition-colors',
          FOCUS_RING,
          active
            ? 'border-primary-500 bg-primary-600/20 text-primary-200'
            : 'border-dark-500 bg-dark-800 text-gray-200 hover:border-dark-400 hover:bg-dark-700 hover:text-white'
        )}
        aria-expanded={open}
        aria-haspopup="true"
        aria-controls={panelId}
        data-testid={testId}
        onClick={() => setOpen((current) => !current)}
      >
        <span className="max-w-[10rem] truncate sm:max-w-[14rem]">
          {summary ? (
            <>
              <span className="text-gray-400">{label}: </span>
              {summary}
            </>
          ) : (
            label
          )}
        </span>
        <svg
          className={cn('h-4 w-4 shrink-0 text-gray-400 transition-transform', open && 'rotate-180')}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
          aria-hidden="true"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {open && (
        <div
          id={panelId}
          role="region"
          aria-label={label}
          data-testid={testId ? `${testId}-panel` : undefined}
          className={cn(
            'absolute top-full z-30 mt-2 min-w-[16rem] rounded-xl border border-dark-600 bg-dark-900 p-4 shadow-xl',
            align === 'right' ? 'right-0' : 'left-0',
            panelClassName
          )}
        >
          {children}
        </div>
      )}
    </div>
  )
}
