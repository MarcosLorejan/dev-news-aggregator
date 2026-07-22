import { act, renderHook, waitFor } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { useAsyncResource } from './useAsyncResource'

function deferred<T>() {
  let resolve!: (value: T) => void
  let reject!: (reason?: unknown) => void
  const promise = new Promise<T>((res, rej) => {
    resolve = res
    reject = rej
  })
  return { promise, resolve, reject }
}

describe('useAsyncResource', () => {
  it('loads data successfully', async () => {
    const loader = vi.fn(async (_signal: AbortSignal) => 'ok')

    const { result } = renderHook(() => useAsyncResource(loader))

    await waitFor(() => expect(result.current.loading).toBe(false))
    expect(result.current.data).toBe('ok')
    expect(result.current.error).toBeNull()
    expect(loader).toHaveBeenCalledTimes(1)
    expect(loader.mock.calls[0][0]).toBeInstanceOf(AbortSignal)
  })

  it('sets error state when loader fails', async () => {
    const loader = vi.fn(async (_signal: AbortSignal) => {
      throw new Error('boom')
    })

    const { result } = renderHook(() =>
      useAsyncResource(loader, { errorMessage: 'Could not load.' })
    )

    await waitFor(() => expect(result.current.loading).toBe(false))
    expect(result.current.data).toBeNull()
    expect(result.current.error).toBe('Could not load.')
  })

  it('does not treat AbortError as a failure', async () => {
    const loader = vi.fn(async (signal: AbortSignal) => {
      await new Promise<void>((_resolve, reject) => {
        signal.addEventListener('abort', () => {
          reject(new DOMException('Aborted', 'AbortError'))
        })
      })
      return 'never'
    })

    const { result, unmount } = renderHook(() => useAsyncResource(loader))

    expect(result.current.loading).toBe(true)
    unmount()

    await act(async () => {
      await Promise.resolve()
    })

    expect(result.current.error).toBeNull()
    expect(result.current.data).toBeNull()
  })

  it('does not restart load when only the loader function identity changes', async () => {
    const pending = deferred<string>()
    const loader = vi.fn(async (_signal: AbortSignal) => pending.promise)

    const { result, rerender } = renderHook(
      ({ loader: current }: { loader: typeof loader }) => useAsyncResource(current),
      { initialProps: { loader } }
    )

    expect(loader).toHaveBeenCalledTimes(1)

    // Inline-style identity churn must not abort/restart the in-flight request.
    rerender({ loader: vi.fn(async (_signal: AbortSignal) => pending.promise) })
    rerender({ loader: vi.fn(async (_signal: AbortSignal) => pending.promise) })

    expect(loader).toHaveBeenCalledTimes(1)

    await act(async () => {
      pending.resolve('stable')
    })

    await waitFor(() => expect(result.current.data).toBe('stable'))
    expect(result.current.error).toBeNull()
    expect(loader).toHaveBeenCalledTimes(1)
  })

  it('aborts previous request on reload', async () => {
    const signals: AbortSignal[] = []
    const pending = deferred<string>()
    let resolveCount = 0

    const loader = vi.fn(async (signal: AbortSignal) => {
      signals.push(signal)
      if (signals.length === 1) {
        signal.addEventListener('abort', () => {
          pending.reject(new DOMException('Aborted', 'AbortError'))
        })
        return pending.promise
      }
      resolveCount += 1
      return `result-${resolveCount}`
    })

    const { result } = renderHook(() => useAsyncResource(loader))

    await waitFor(() => expect(loader).toHaveBeenCalledTimes(1))

    await act(async () => {
      await result.current.reload()
    })

    await waitFor(() => expect(result.current.data).toBe('result-1'))
    expect(signals[0].aborted).toBe(true)
    expect(result.current.error).toBeNull()
  })
})
