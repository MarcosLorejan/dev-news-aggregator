import { Link, useParams } from 'react-router-dom'
import { fetchDigest } from '../api/digests'
import PageShell from '../components/PageShell'
import PageHeading from '../components/ui/PageHeading'
import Card from '../components/ui/Card'
import { useAsyncResource } from '../hooks/useAsyncResource'
import { humanizeSourceType } from '../utils/format'

export default function DigestsShowPage() {
  const { id } = useParams()
  const digestId = Number(id)

  const { data, loading, error, reload } = useAsyncResource(
    (signal) => fetchDigest(digestId, signal),
    { errorMessage: 'Failed to load digest.' }
  )

  return (
    <PageShell
      testId="digest-show-page"
      loading={loading}
      error={error}
      showFatalError={!data}
      onRetry={() => reload()}
      loadingMessage="Loading digest..."
    >
      <PageHeading
        title={`${data?.period ?? ''} digest`}
        subtitle={
          data
            ? `${new Date(data.window_start).toLocaleString()} – ${new Date(data.window_end).toLocaleString()}`
            : undefined
        }
      />

      <p className="mb-6">
        <Link to="/digests" className="text-primary-300 hover:text-primary-200 text-caption">
          Back to digests
        </Link>
      </p>

      {data && (
        <div className="space-y-8">
          <section>
            <h2 className="text-h3 text-gray-100 mb-4">Themes</h2>
            <div className="space-y-3">
              {data.payload.themes.map((theme) => (
                <Card key={theme.title}>
                  <div className="p-4">
                    <p className="text-gray-100 font-medium">{theme.title}</p>
                    <p className="text-body text-gray-300 mt-1">{theme.summary}</p>
                  </div>
                </Card>
              ))}
            </div>
          </section>

          <section>
            <h2 className="text-h3 text-gray-100 mb-4">Articles</h2>
            <div className="space-y-3">
              {data.payload.articles.map((article) => (
                <Card key={article.id}>
                  <div className="p-4">
                    <a
                      href={article.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-gray-50 hover:text-primary-300 font-medium"
                    >
                      {article.title}
                    </a>
                    <p className="text-caption text-gray-400 mt-1">
                      {humanizeSourceType(article.source_type)} · {article.why}
                    </p>
                    <Link
                      to={`/articles/${article.id}`}
                      className="text-caption text-primary-300 hover:text-primary-200 mt-2 inline-block"
                    >
                      Open in app
                    </Link>
                  </div>
                </Card>
              ))}
            </div>
          </section>
        </div>
      )}
    </PageShell>
  )
}
