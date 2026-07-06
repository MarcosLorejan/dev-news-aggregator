import { useCallback, useEffect, useState, type Dispatch, type SetStateAction } from 'react'

interface UseAsyncResourceOptions {
  errorMessage?: string
}

interface AsyncResourceState<T> {
  data: T | null
  loading: boolean
  error: string | null
  reload: () => Promise<void>
  setData: Dispatch<SetStateAction<T | null>>
  setError: Dispatch<SetStateAction<string | null>>
}

export function useAsyncResource<T>(
  loader: () => Promise<T>,
  options: UseAsyncResourceOptions = {}
): AsyncResourceState<T> {
  const { errorMessage = 'Failed to load. Please try again.' } = options
  const [data, setData] = useState<T | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const reload = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const result = await loader()
      setData(result)
    } catch {
      setError(errorMessage)
    } finally {
      setLoading(false)
    }
  }, [loader, errorMessage])

  useEffect(() => {
    reload()
  }, [reload])

  return { data, loading, error, reload, setData, setError }
}
