import Card from './ui/Card'

interface ArticleSearchProps {
  value: string
  onChange: (value: string) => void
}

export default function ArticleSearch({ value, onChange }: ArticleSearchProps) {
  return (
    <Card tone="subtle" className="mb-8">
      <label htmlFor="article-search" className="text-h3 text-gray-100 mb-4 block">
        Search articles
      </label>
      <input
        id="article-search"
        type="search"
        value={value}
        onChange={(event) => onChange(event.target.value)}
        placeholder="Search by title or description"
        className="w-full px-4 py-2 bg-dark-800 border border-dark-700 rounded-xl text-gray-200 placeholder-gray-500 focus-visible:outline-none focus-visible:border-primary-500 focus-visible:ring-2 focus-visible:ring-primary-500"
        data-testid="article-search-input"
        autoComplete="off"
      />
    </Card>
  )
}
