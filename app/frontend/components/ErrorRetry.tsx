import Button from './ui/Button'

interface ErrorRetryProps {
  message: string
  onRetry: () => void
}

export default function ErrorRetry({ message, onRetry }: ErrorRetryProps) {
  return (
    <>
      <p className="text-red-400 mb-4">{message}</p>
      <Button size="sm" onClick={onRetry}>
        Retry
      </Button>
    </>
  )
}
