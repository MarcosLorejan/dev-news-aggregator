import { Skeleton } from './ui/Skeleton'

export default function ArticleShowSkeleton() {
  return (
    <div
      className="container mx-auto px-4 py-8 max-w-4xl"
      data-testid="article-show-skeleton"
      role="status"
      aria-live="polite"
      aria-busy="true"
    >
      <span className="sr-only">Loading article</span>
      <article className="surface-panel rounded-2xl p-8 md:p-12">
        <div className="mb-8">
          <div className="flex flex-wrap items-center gap-4 mb-6">
            <Skeleton className="h-8 w-28 rounded-full" />
            <Skeleton className="h-7 w-24 rounded-full" />
          </div>

          <Skeleton className="h-9 w-11/12 max-w-3xl mb-6" />

          <div className="flex flex-wrap items-center gap-6 mb-6">
            <Skeleton className="h-4 w-32" />
            <Skeleton className="h-4 w-20" />
            <Skeleton className="h-4 w-24" />
          </div>
        </div>

        <div className="space-y-3 mb-8 max-w-prose">
          <Skeleton className="h-4 w-full" />
          <Skeleton className="h-4 w-full" />
          <Skeleton className="h-4 w-full" />
          <Skeleton className="h-4 w-5/6" />
          <Skeleton className="h-4 w-4/6" />
        </div>

        <div className="border-t border-dark-700 pt-8 flex flex-wrap gap-4">
          <Skeleton className="h-11 w-40 rounded-xl" />
          <Skeleton className="h-11 w-52 rounded-xl" />
          <Skeleton className="h-11 w-36 rounded-xl" />
        </div>
      </article>
    </div>
  )
}
