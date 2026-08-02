import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import {
  apiRequest,
  clearMutatingAuthCredentials,
  isAbortError,
  setMutatingAuthCredentials,
} from './client'

describe('apiRequest', () => {
  beforeEach(() => {
    clearMutatingAuthCredentials()
  })

  afterEach(() => {
    clearMutatingAuthCredentials()
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

  it('sends Basic Authorization when mutating credentials are stored', async () => {
    setMutatingAuthCredentials('admin', 'secret')
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ bookmarked: true }),
    })
    vi.stubGlobal('fetch', fetchMock)

    await apiRequest('/articles/1/bookmark', { method: 'POST' })

    const headers = fetchMock.mock.calls[0][1].headers as Headers
    expect(headers.get('Authorization')).toBe(`Basic ${btoa('admin:secret')}`)
  })

  it('prompts and retries once on mutating 401', async () => {
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce({
        ok: false,
        status: 401,
        json: async () => ({ error: 'Unauthorized' }),
      })
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => ({ bookmarked: true }),
      })
    vi.stubGlobal('fetch', fetchMock)
    vi.stubGlobal(
      'prompt',
      vi
        .fn()
        .mockReturnValueOnce('admin')
        .mockReturnValueOnce('secret')
    )

    await expect(apiRequest('/articles/1/bookmark', { method: 'POST' })).resolves.toEqual({
      bookmarked: true,
    })
    expect(fetchMock).toHaveBeenCalledTimes(2)
    const retryHeaders = fetchMock.mock.calls[1][1].headers as Headers
    expect(retryHeaders.get('Authorization')).toBe(`Basic ${btoa('admin:secret')}`)
  })

  it('joins plural errors from unprocessable responses', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: false,
      status: 422,
      json: async () => ({ errors: ["Name can't be blank", 'Terms must include at least one keyword'] }),
    })
    vi.stubGlobal('fetch', fetchMock)

    await expect(apiRequest('/keyword_filters.json', { method: 'POST', body: '{}' })).rejects.toThrow(
      "Name can't be blank, Terms must include at least one keyword"
    )
  })

  it('isAbortError detects AbortError', () => {
    expect(isAbortError(new DOMException('Aborted', 'AbortError'))).toBe(true)
    expect(isAbortError(Object.assign(new Error('Aborted'), { name: 'AbortError' }))).toBe(true)
    expect(isAbortError(new Error('other'))).toBe(false)
  })
})
