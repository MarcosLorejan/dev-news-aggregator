interface DismissToastProps {
  articleTitle: string
  timeLeft: number
  onUndo: () => void
}

export default function DismissToast({ articleTitle, timeLeft, onUndo }: DismissToastProps) {
  return (
    <div
      className="dismiss-toast fixed top-4 right-4 surface-panel rounded-xl p-4 shadow-2xl z-50 max-w-sm motion-safe:animate-slide-in motion-sensitive border border-dark-700"
      role="status"
      aria-live="polite"
      aria-atomic="true"
    >
      <div className="flex items-center justify-between">
        <div className="flex-1 mr-4">
          <div className="text-primary-300 font-medium text-sm mb-1">Article dismissed</div>
          <div className="text-gray-400 text-xs">{articleTitle}</div>
        </div>
        <div className="flex items-center space-x-2">
          <button
            type="button"
            className="undo-btn px-4 py-2 bg-primary-600 hover:bg-primary-700 text-white text-sm font-medium rounded-lg transition-colors duration-200"
            aria-label="Undo dismiss"
            onClick={onUndo}
          >
            UNDO
          </button>
        </div>
      </div>
      <div className="mt-3 text-xs text-gray-500 flex items-center justify-between">
        <span>Ctrl+Z to undo</span>
        <span className="countdown" aria-hidden="true">
          {timeLeft}s remaining
        </span>
      </div>
      <div className="mt-2 bg-dark-700 rounded-full h-1 overflow-hidden" aria-hidden="true">
        <div
          className="countdown-bar bg-primary-500 h-full transition-all duration-1000"
          style={{ width: `${(timeLeft / 15) * 100}%` }}
        />
      </div>
    </div>
  )
}
