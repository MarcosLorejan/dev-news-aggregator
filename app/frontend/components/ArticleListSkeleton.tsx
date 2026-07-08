import ArticleCardSkeleton from './ArticleCardSkeleton'

interface ArticleListSkeletonProps {
  count?: number
  label?: string
}

export default function ArticleListSkeleton({ count = 6, label = 'Loading articles' }: ArticleListSkeletonProps) {
  return (
    <div data-testid="article-list-skeleton" role="status" aria-live="polite" aria-busy="true">
      <span className="sr-only">{label}</span>
      <div className="grid gap-5 md:gap-6">
        {Array.from({ length: count }, (_, index) => (
          <ArticleCardSkeleton key={index} />
        ))}
      </div>
    </div>
  )
}
