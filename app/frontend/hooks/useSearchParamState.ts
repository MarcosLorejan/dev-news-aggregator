import { useCallback } from 'react'
import { useSearchParams } from 'react-router-dom'

type SetSearchParamsOptions = { replace?: boolean }

export function useSearchParam(
  key: string,
  defaultValue = ''
): [string, (value: string) => void] {
  const [searchParams, setSearchParams] = useSearchParams()
  const value = searchParams.get(key) ?? defaultValue

  const setValue = useCallback(
    (next: string) => {
      setSearchParams(
        (prev) => {
          const params = new URLSearchParams(prev)
          if (!next || next === defaultValue) {
            params.delete(key)
          } else {
            params.set(key, next)
          }
          return params
        },
        { replace: true }
      )
    },
    [key, defaultValue, setSearchParams]
  )

  return [value, setValue]
}

export function useSearchParamInt(
  key: string,
  defaultValue = 1,
  min = 1
): [number, (value: number) => void] {
  const [searchParams, setSearchParams] = useSearchParams()
  const raw = parseInt(searchParams.get(key) ?? String(defaultValue), 10)
  const value = Number.isFinite(raw) && raw >= min ? raw : defaultValue

  const setValue = useCallback(
    (next: number) => {
      setSearchParams(
        (prev) => {
          const params = new URLSearchParams(prev)
          if (next <= defaultValue) {
            params.delete(key)
          } else {
            params.set(key, String(next))
          }
          return params
        },
        { replace: true }
      )
    },
    [key, defaultValue, setSearchParams]
  )

  return [value, setValue]
}

export function usePatchSearchParams() {
  const [, setSearchParams] = useSearchParams()

  return useCallback(
    (patch: (params: URLSearchParams) => void, options?: SetSearchParamsOptions) => {
      setSearchParams(
        (prev) => {
          const params = new URLSearchParams(prev)
          patch(params)
          return params
        },
        { replace: options?.replace ?? true }
      )
    },
    [setSearchParams]
  )
}
