import { useCallback, useEffect, useState } from 'react'
import {
  createKeywordFilter,
  deleteKeywordFilter,
  fetchKeywordFilters,
  updateKeywordFilter,
  type KeywordFilter,
} from '../api/keywordFilters'
import { useConfirmDialog } from '../hooks/useConfirmDialog'
import Badge from '../components/ui/Badge'
import Button from '../components/ui/Button'
import Card from '../components/ui/Card'
import PageContainer from '../components/ui/PageContainer'
import PageHeading from '../components/ui/PageHeading'
import Breadcrumbs from '../components/Breadcrumbs'
import { interestsBreadcrumbs } from '../components/breadcrumbTrails'
import TermChipInput, { addTerm } from '../components/TermChipInput'
import SourcesIndexSkeleton from '../components/SourcesIndexSkeleton'

function sortInterests(items: KeywordFilter[]): KeywordFilter[] {
  return [...items].sort((a, b) => a.position - b.position || a.name.localeCompare(b.name))
}

export default function InterestsIndexPage() {
  const [interests, setInterests] = useState<KeywordFilter[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [nameInput, setNameInput] = useState('')
  const [createTerms, setCreateTerms] = useState<string[]>([])
  const [creating, setCreating] = useState(false)
  const [validationError, setValidationError] = useState<string | null>(null)
  const [editingId, setEditingId] = useState<number | null>(null)
  const [editTerms, setEditTerms] = useState<string[]>([])
  const [savingId, setSavingId] = useState<number | null>(null)
  const { confirm, dialog } = useConfirmDialog()

  const loadInterests = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const response = await fetchKeywordFilters()
      setInterests(sortInterests(response.keyword_filters))
    } catch {
      setError('Failed to load interests.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadInterests()
  }, [loadInterests])

  const handleCreate = async (event: React.FormEvent) => {
    event.preventDefault()
    const name = nameInput.trim()
    const terms = createTerms.reduce((acc, term) => addTerm(acc, term), [] as string[])
    if (!name || terms.length === 0) {
      setValidationError('Name and at least one keyword are required.')
      return
    }

    setCreating(true)
    setValidationError(null)
    try {
      const created = await createKeywordFilter({
        name,
        terms,
        position: interests.length,
      })
      setInterests((current) => sortInterests([...current, created]))
      setNameInput('')
      setCreateTerms([])
    } catch (err) {
      setValidationError(err instanceof Error ? err.message : 'Failed to create interest.')
    } finally {
      setCreating(false)
    }
  }

  const handleToggle = async (interest: KeywordFilter) => {
    setSavingId(interest.id)
    setError(null)
    try {
      const updated = await updateKeywordFilter(interest.id, { active: !interest.active })
      setInterests((current) => current.map((item) => (item.id === updated.id ? updated : item)))
    } catch {
      setError('Failed to update interest.')
    } finally {
      setSavingId(null)
    }
  }

  const startEditing = (interest: KeywordFilter) => {
    setEditingId(interest.id)
    setEditTerms([...interest.terms])
    setValidationError(null)
  }

  const handleSaveTerms = async (interest: KeywordFilter) => {
    const terms = editTerms.reduce((acc, term) => addTerm(acc, term), [] as string[])
    if (terms.length === 0) {
      setValidationError('At least one keyword is required.')
      return
    }

    setSavingId(interest.id)
    setValidationError(null)
    try {
      const updated = await updateKeywordFilter(interest.id, { terms })
      setInterests((current) => current.map((item) => (item.id === updated.id ? updated : item)))
      setEditingId(null)
    } catch (err) {
      setValidationError(err instanceof Error ? err.message : 'Failed to update terms.')
    } finally {
      setSavingId(null)
    }
  }

  const handleMove = async (interest: KeywordFilter, direction: -1 | 1) => {
    const index = interests.findIndex((item) => item.id === interest.id)
    const swapWith = interests[index + direction]
    if (!swapWith) return

    setSavingId(interest.id)
    setError(null)
    try {
      const [updated, swapped] = await Promise.all([
        updateKeywordFilter(interest.id, { position: swapWith.position }),
        updateKeywordFilter(swapWith.id, { position: interest.position }),
      ])
      setInterests((current) =>
        sortInterests(
          current.map((item) => {
            if (item.id === updated.id) return updated
            if (item.id === swapped.id) return swapped
            return item
          })
        )
      )
    } catch {
      setError('Failed to reorder interests.')
    } finally {
      setSavingId(null)
    }
  }

  const handleDelete = async (interest: KeywordFilter) => {
    const confirmed = await confirm({
      message: `Delete the “${interest.name}” interest?`,
      confirmLabel: 'Delete',
    })
    if (!confirmed) return

    try {
      await deleteKeywordFilter(interest.id)
      setInterests((current) => current.filter((item) => item.id !== interest.id))
      if (editingId === interest.id) setEditingId(null)
    } catch {
      setError('Failed to delete interest.')
    }
  }

  if (loading) {
    return (
      <PageContainer width="4xl" testId="interests-page" role="status" aria-live="polite" aria-busy>
        <SourcesIndexSkeleton />
      </PageContainer>
    )
  }

  return (
    <PageContainer width="4xl" testId="interests-page">
      <Breadcrumbs items={interestsBreadcrumbs} />
      <PageHeading
        title="Interests"
        subtitle="Saved keyword presets used to filter the feed by topic."
        titleClassName="text-gray-100"
      />

      {error && <div className="mb-4 text-sm text-red-400">{error}</div>}

      <Card as="section" className="mb-8">
        <h2 className="text-h3 text-gray-200 mb-4">Add interest</h2>
        <form onSubmit={handleCreate} className="space-y-4">
          <input
            type="text"
            value={nameInput}
            onChange={(event) => setNameInput(event.target.value)}
            placeholder="Name, e.g. Software architecture"
            className="w-full px-4 py-2 bg-dark-800 border border-dark-700 rounded-xl text-gray-200 placeholder-gray-500 focus-visible:outline-none focus-visible:border-primary-500 focus-visible:ring-2 focus-visible:ring-primary-500"
            data-testid="interest-name-input"
          />
          <TermChipInput terms={createTerms} onChange={setCreateTerms} />
          <Button
            type="submit"
            disabled={creating || !nameInput.trim() || createTerms.length === 0}
            data-testid="add-interest-button"
          >
            {creating ? 'Saving...' : 'Add interest'}
          </Button>
        </form>
        {validationError && editingId === null && (
          <p className="text-sm text-red-400 mt-4" data-testid="interest-validation-error">
            {validationError}
          </p>
        )}
      </Card>

      <Card as="section">
        <h2 className="text-h3 text-gray-200 mb-4">Saved interests</h2>
        <div className="space-y-4">
          {interests.map((interest, index) => {
            const editing = editingId === interest.id
            return (
              <div
                key={interest.id}
                className="py-3 border-b border-dark-700 last:border-0"
                data-testid={`interest-row-${interest.slug}`}
              >
                <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                  <div className="min-w-0 space-y-2">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="text-gray-100 font-medium">{interest.name}</span>
                      <Badge variant={interest.active ? 'green' : 'orange'} size="sm">
                        {interest.active ? 'Active' : 'Inactive'}
                      </Badge>
                      {interest.article_count !== null && (
                        <span className="text-caption text-gray-500">
                          {interest.article_count} matching
                        </span>
                      )}
                    </div>
                    {editing ? (
                      <TermChipInput
                        terms={editTerms}
                        onChange={setEditTerms}
                        disabled={savingId === interest.id}
                        data-testid={`edit-terms-${interest.slug}`}
                      />
                    ) : (
                      <div className="flex flex-wrap gap-2">
                        {interest.terms.map((term) => (
                          <Badge key={term} variant="primary" size="sm">
                            {term}
                          </Badge>
                        ))}
                      </div>
                    )}
                  </div>

                  <div className="flex flex-wrap items-center gap-3 shrink-0">
                    <button
                      type="button"
                      className="text-sm text-gray-400 hover:text-white disabled:opacity-40"
                      disabled={index === 0 || savingId === interest.id}
                      aria-label={`Move ${interest.name} up`}
                      onClick={() => handleMove(interest, -1)}
                    >
                      Up
                    </button>
                    <button
                      type="button"
                      className="text-sm text-gray-400 hover:text-white disabled:opacity-40"
                      disabled={index === interests.length - 1 || savingId === interest.id}
                      aria-label={`Move ${interest.name} down`}
                      onClick={() => handleMove(interest, 1)}
                    >
                      Down
                    </button>
                    <label className="flex items-center gap-2 text-sm text-gray-400 cursor-pointer">
                      <input
                        type="checkbox"
                        className="rounded border-dark-600 bg-dark-800 text-primary-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-500"
                        checked={interest.active}
                        disabled={savingId === interest.id}
                        onChange={() => handleToggle(interest)}
                        data-testid={`interest-toggle-${interest.slug}`}
                      />
                      {interest.active ? 'Enabled' : 'Disabled'}
                    </label>
                    {editing ? (
                      <>
                        <Button
                          size="sm"
                          disabled={savingId === interest.id || editTerms.length === 0}
                          data-testid={`save-terms-${interest.slug}`}
                          onClick={() => handleSaveTerms(interest)}
                        >
                          Save
                        </Button>
                        <button
                          type="button"
                          className="text-sm text-gray-400 hover:text-white"
                          onClick={() => setEditingId(null)}
                        >
                          Cancel
                        </button>
                      </>
                    ) : (
                      <button
                        type="button"
                        className="text-sm text-primary-300 hover:text-primary-200"
                        data-testid={`edit-interest-${interest.slug}`}
                        onClick={() => startEditing(interest)}
                      >
                        Edit terms
                      </button>
                    )}
                    <button
                      type="button"
                      className="text-sm text-red-400 hover:text-red-300"
                      data-testid={`delete-interest-${interest.slug}`}
                      onClick={() => handleDelete(interest)}
                    >
                      Delete
                    </button>
                  </div>
                </div>
              </div>
            )
          })}
          {interests.length === 0 && (
            <p className="text-gray-500 text-sm">No interests configured yet.</p>
          )}
        </div>
        {validationError && editingId !== null && (
          <p className="text-sm text-red-400 mt-4" data-testid="interest-validation-error">
            {validationError}
          </p>
        )}
      </Card>
      {dialog}
    </PageContainer>
  )
}
