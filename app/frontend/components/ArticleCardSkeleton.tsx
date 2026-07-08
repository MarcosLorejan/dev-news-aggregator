import { Skeleton } from './ui/Skeleton'

export default function ArticleCardSkeleton() {
  return (
    <div className="surface-card rounded-2xl p-6" data-testid="article-card-skeleton" aria-hidden="true">
      <div className="flex justify-between items-start mb-4 gap-4">
        <div className="flex-1 space-y-3">
          <Skeleton className="h-5 w-11/12" />
          <Skeleton className="h-5 w-8/12" />
        </div>
        <Skeleton className="h-6 w-20 rounded-full shrink-0" />
      </div>

      <div className="space-y-2 mb-6">
        <Skeleton className="h-4 w-full" />
        <Skeleton className="h-4 w-full" />
        <Skeleton className="h-4 w-4/5" />
      </div>

      <div className="flex justify-between items-center border-t border-dark-700/80 pt-4 gap-4">
        <div className="flex flex-wrap items-center gap-4">
          <Skeleton className="h-4 w-24" />
          <Skeleton className="h-4 w-10" />
          <Skeleton className="h-4 w-10" />
        </div>
        <div className="flex items-center gap-3 shrink-0">
          <Skeleton className="h-8 w-8 rounded-lg" />
          <Skeleton className="h-8 w-8 rounded-lg" />
          <Skeleton className="h-9 w-20 rounded-lg" />
        </div>
      </div>
    </div>
  )
}
