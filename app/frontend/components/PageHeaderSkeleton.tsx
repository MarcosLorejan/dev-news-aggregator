import Card from './ui/Card'
import { Skeleton } from './ui/Skeleton'

export default function PageHeaderSkeleton() {
  return (
    <Card tone="elevated" padding="lg" className="mb-8" aria-hidden="true">
      <Skeleton className="h-10 w-2/3 max-w-xl mb-3" />
      <Skeleton className="h-5 w-1/2 max-w-md" />
    </Card>
  )
}
