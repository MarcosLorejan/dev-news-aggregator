import { useState, type KeyboardEvent } from 'react'
import Badge from './ui/Badge'

interface TermChipInputProps {
  terms: string[]
  onChange: (terms: string[]) => void
  disabled?: boolean
  placeholder?: string
  'data-testid'?: string
}

function normalizeTerm(value: string): string {
  return value.trim().toLowerCase()
}

export function addTerm(terms: string[], raw: string): string[] {
  const term = normalizeTerm(raw)
  if (!term || terms.includes(term)) return terms
  return [...terms, term]
}

export default function TermChipInput({
  terms,
  onChange,
  disabled = false,
  placeholder = 'Add a keyword and press Enter',
  'data-testid': testId = 'term-chip-input',
}: TermChipInputProps) {
  const [draft, setDraft] = useState('')

  const commitDraft = () => {
    const next = addTerm(terms, draft)
    if (next !== terms) onChange(next)
    setDraft('')
  }

  const handleKeyDown = (event: KeyboardEvent<HTMLInputElement>) => {
    if (event.key === 'Enter' || event.key === ',') {
      event.preventDefault()
      commitDraft()
      return
    }

    if (event.key === 'Backspace' && draft === '' && terms.length > 0) {
      event.preventDefault()
      onChange(terms.slice(0, -1))
    }
  }

  return (
    <div
      className="flex flex-wrap items-center gap-2 px-3 py-2 bg-dark-800 border border-dark-700 rounded-xl focus-within:border-primary-500 focus-within:ring-2 focus-within:ring-primary-500"
      data-testid={testId}
    >
      {terms.map((term) => (
        <Badge key={term} variant="primary" size="sm" className="inline-flex items-center gap-1">
          <span>{term}</span>
          <button
            type="button"
            className="text-primary-100 hover:text-white"
            aria-label={`Remove ${term}`}
            disabled={disabled}
            onClick={() => onChange(terms.filter((current) => current !== term))}
          >
            ×
          </button>
        </Badge>
      ))}
      <input
        type="text"
        value={draft}
        disabled={disabled}
        placeholder={terms.length === 0 ? placeholder : undefined}
        className="flex-1 min-w-[10rem] bg-transparent text-gray-200 placeholder-gray-500 focus-visible:outline-none"
        data-testid={`${testId}-field`}
        onChange={(event) => setDraft(event.target.value)}
        onKeyDown={handleKeyDown}
        onBlur={commitDraft}
      />
    </div>
  )
}
