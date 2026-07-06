interface ErrorRetryProps {
  message: string
  onRetry: () => void
}

export default function ErrorRetry({ message, onRetry }: ErrorRetryProps) {
  return (
    <>
      <p className="text-red-400 mb-4">{message}</p>
      <button
        type="button"
        className="px-4 py-2 bg-primary-600 text-white rounded-lg"
        onClick={onRetry}
      >
        Retry
      </button>
    </>
  )
}
