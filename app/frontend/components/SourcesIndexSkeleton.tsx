import Card from './ui/Card'
import { Skeleton } from './ui/Skeleton'

function SourceRowSkeleton() {
  return (
    <div className="flex items-center justify-between py-3 border-b border-dark-700 last:border-0" aria-hidden="true">
      <Skeleton className="h-5 w-40" />
      <Skeleton className="h-5 w-24" />
    </div>
  )
}

export default function SourcesIndexSkeleton() {
  return (
    <div data-testid="sources-list-skeleton" role="status" aria-live="polite" aria-busy="true">
      <span className="sr-only">Loading sources</span>
      <Card tone="elevated" padding="lg" className="mb-8" aria-hidden="true">
        <Skeleton className="h-9 w-48 max-w-full mb-2" />
        <Skeleton className="h-5 w-96 max-w-full" />
      </Card>

      <Card as="section" className="mb-8" aria-hidden="true">
        <Skeleton className="h-7 w-40 mb-4" />
        <div className="space-y-0">
          <SourceRowSkeleton />
          <SourceRowSkeleton />
          <SourceRowSkeleton />
        </div>
      </Card>

      <Card as="section" aria-hidden="true">
        <Skeleton className="h-7 w-44 mb-4" />
        <Skeleton className="h-10 w-full mb-4 rounded-lg" />
        <SourceRowSkeleton />
        <SourceRowSkeleton />
      </Card>
    </div>
  )
}
