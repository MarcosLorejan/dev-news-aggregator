interface PaginationControlsProps {
  currentPage: number
  totalPages: number
  totalCount: number
  perPage: number
  onPageChange: (page: number) => void
}

export default function PaginationControls({
  currentPage,
  totalPages,
  totalCount,
  perPage,
  onPageChange,
}: PaginationControlsProps) {
  if (totalPages <= 1) return null

  const rangeStart = (currentPage - 1) * perPage + 1
  const rangeEnd = Math.min(currentPage * perPage, totalCount)

  const goToPage = (page: number) => {
    if (page < 1 || page > totalPages || page === currentPage) return
    onPageChange(page)
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  return (
    <nav
      className="surface-subtle rounded-xl p-4 mt-8 flex flex-col sm:flex-row items-center justify-between gap-4"
      aria-label="Articles pagination"
      data-testid="articles-pagination"
    >
      <p className="text-sm text-gray-400">
        Showing{' '}
        <span className="text-gray-200 font-medium">
          {rangeStart}–{rangeEnd}
        </span>{' '}
        of <span className="text-gray-200 font-medium">{totalCount}</span> articles
      </p>

      <div className="flex items-center gap-2">
        <button
          type="button"
          className="px-4 py-2 rounded-lg border border-dark-500 bg-dark-700 text-gray-300 font-medium transition-all duration-200 hover:bg-dark-600 hover:text-white disabled:opacity-40 disabled:hover:bg-dark-700 disabled:hover:text-gray-300"
          onClick={() => goToPage(currentPage - 1)}
          disabled={currentPage <= 1}
          aria-label="Previous page"
          data-testid="pagination-prev"
        >
          Previous
        </button>

        <span className="px-3 text-sm text-gray-400" data-testid="pagination-status">
          Page <span className="text-primary-400 font-semibold">{currentPage}</span> of{' '}
          <span className="text-gray-200">{totalPages}</span>
        </span>

        <button
          type="button"
          className="px-4 py-2 rounded-lg border border-dark-500 bg-dark-700 text-gray-300 font-medium transition-all duration-200 hover:bg-dark-600 hover:text-white disabled:opacity-40 disabled:hover:bg-dark-700 disabled:hover:text-gray-300"
          onClick={() => goToPage(currentPage + 1)}
          disabled={currentPage >= totalPages}
          aria-label="Next page"
          data-testid="pagination-next"
        >
          Next
        </button>
      </div>
    </nav>
  )
}
