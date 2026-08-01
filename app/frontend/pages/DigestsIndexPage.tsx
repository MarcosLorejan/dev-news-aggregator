import { Link } from 'react-router-dom'
import { createDigest, fetchDigests } from '../api/digests'
import EmptyState from '../components/EmptyState'
import PageShell from '../components/PageShell'
import PageHeading from '../components/ui/PageHeading'
import Button from '../components/ui/Button'
import Card from '../components/ui/Card'
import { useAsyncResource } from '../hooks/useAsyncResource'
import { useState } from 'react'

export default function DigestsIndexPage() {
  const { data, loading, error, reload, setData, setError } = useAsyncResource(
    (signal) => fetchDigests(signal),
    { errorMessage: 'Failed to load digests. Please try again.' }
  )
  const [generating, setGenerating] = useState(false)

  const digests = data?.digests ?? []

  const handleGenerate = async (period: 'daily' | 'weekly') => {
    setGenerating(true)
    setError(null)
    try {
      const created = await createDigest(period)
      setData((current) => ({
        digests: [created, ...(current?.digests ?? [])],
      }))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to generate digest.')
    } finally {
      setGenerating(false)
    }
  }

  return (
    <PageShell
      testId="digests-page"
      loading={loading}
      error={error}
      showFatalError={digests.length === 0}
      onRetry={() => reload()}
      loadingMessage="Loading digests..."
    >
      <PageHeading
        title="Digests"
        subtitle="Unread highlights for a day or week — works without an LLM (title-only themes)"
      />

      <div className="mb-8 flex flex-wrap gap-3">
        <Button
          variant="primary"
          disabled={generating}
          onClick={() => void handleGenerate('daily')}
        >
          Generate daily digest
        </Button>
        <Button
          variant="filter"
          disabled={generating}
          onClick={() => void handleGenerate('weekly')}
        >
          Generate weekly digest
        </Button>
      </div>

      {digests.length === 0 ? (
        <EmptyState
          icon={
            <svg className="w-10 h-10 text-primary-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
              />
            </svg>
          }
          title="No digests yet"
          description="Generate a daily or weekly digest from your unread articles."
        />
      ) : (
        <div className="space-y-4">
          {digests.map((digest) => (
            <Card key={digest.id}>
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <p className="text-h3 text-gray-100 capitalize">{digest.period} digest</p>
                  <p className="text-caption text-gray-400">
                    {digest.payload.articles.length} articles · {digest.payload.themes.length} themes
                  </p>
                </div>
                <Link
                  to={`/digests/${digest.id}`}
                  className="text-primary-300 hover:text-primary-200 text-caption"
                >
                  View digest
                </Link>
              </div>
            </Card>
          ))}
        </div>
      )}
    </PageShell>
  )
}
