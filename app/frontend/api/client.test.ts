import { afterEach, describe, expect, it, vi } from 'vitest'
import { apiRequest, isAbortError } from './client'

describe('apiRequest', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
    vi.restoreAllMocks()
  })

  it('passes AbortSignal through to fetch', async () => {
    const controller = new AbortController()
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ ok: true }),
    })
    vi.stubGlobal('fetch', fetchMock)

    await apiRequest('/articles.json', { signal: controller.signal })

    expect(fetchMock).toHaveBeenCalledTimes(1)
    expect(fetchMock.mock.calls[0][1].signal).toBe(controller.signal)
  })

  it('isAbortError detects AbortError', () => {
    expect(isAbortError(new DOMException('Aborted', 'AbortError'))).toBe(true)
    expect(isAbortError(Object.assign(new Error('Aborted'), { name: 'AbortError' }))).toBe(true)
    expect(isAbortError(new Error('other'))).toBe(false)
  })
})
