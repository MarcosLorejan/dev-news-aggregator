import { useCallback, useEffect, useRef, useState, type Dispatch, type SetStateAction } from 'react'
import { isAbortError } from '../api/client'

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
  loader: (signal: AbortSignal) => Promise<T>,
  options: UseAsyncResourceOptions = {}
): AsyncResourceState<T> {
  const { errorMessage = 'Failed to load. Please try again.' } = options
  const [data, setData] = useState<T | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const abortRef = useRef<AbortController | null>(null)
  const loaderRef = useRef(loader)

  useEffect(() => {
    loaderRef.current = loader
  }, [loader])

  const load = useCallback(async () => {
    abortRef.current?.abort()
    const controller = new AbortController()
    abortRef.current = controller
    const { signal } = controller

    setLoading(true)
    setError(null)
    try {
      const result = await loaderRef.current(signal)
      if (signal.aborted) return
      setData(result)
    } catch (err) {
      if (isAbortError(err) || signal.aborted) return
      setError(errorMessage)
    } finally {
      if (!signal.aborted) setLoading(false)
    }
  }, [errorMessage])

  useEffect(() => {
    void load()
    return () => {
      abortRef.current?.abort()
    }
  }, [load])

  return { data, loading, error, reload: load, setData, setError }
}
