import ArticleListSkeleton from './ArticleListSkeleton'
import PageContainer from './ui/PageContainer'

export default function RouteFallback() {
  return (
    <PageContainer testId="route-loading" role="status" aria-live="polite" aria-busy>
      <ArticleListSkeleton count={4} label="Loading page" />
    </PageContainer>
  )
}
