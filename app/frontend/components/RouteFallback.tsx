import PageContainer from './ui/PageContainer'

export default function RouteFallback() {
  return (
    <PageContainer testId="route-loading" centered role="status" aria-live="polite">
      Loading page...
    </PageContainer>
  )
}
