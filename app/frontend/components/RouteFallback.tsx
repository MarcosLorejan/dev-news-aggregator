export default function RouteFallback() {
  return (
    <div
      className="container mx-auto px-4 py-8 max-w-7xl text-center text-gray-400"
      data-testid="route-loading"
      role="status"
      aria-live="polite"
    >
      Loading page...
    </div>
  )
}
