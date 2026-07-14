import { afterEach, describe, expect, it, vi } from 'vitest'
import { registerServiceWorker } from './registerServiceWorker'

function stubServiceWorkerContainer(register: ReturnType<typeof vi.fn>) {
  Object.defineProperty(navigator, 'serviceWorker', {
    value: { register },
    configurable: true,
  })
}

function stubReadyState(readyState: DocumentReadyState) {
  Object.defineProperty(document, 'readyState', {
    value: readyState,
    configurable: true,
  })
}

afterEach(() => {
  // jsdom exposes neither of these by default, so drop the stubs between tests.
  Reflect.deleteProperty(navigator, 'serviceWorker')
  Reflect.deleteProperty(document, 'readyState')
  vi.restoreAllMocks()
})

describe('registerServiceWorker', () => {
  it('registers the service worker at the app scope on an already loaded page', () => {
    const register = vi.fn().mockResolvedValue({})
    stubServiceWorkerContainer(register)
    stubReadyState('complete')

    registerServiceWorker()

    expect(register).toHaveBeenCalledWith('/service-worker', { scope: '/' })
  })

  it('waits for the load event when the page is still loading', () => {
    const register = vi.fn().mockResolvedValue({})
    stubServiceWorkerContainer(register)
    stubReadyState('loading')

    registerServiceWorker()
    expect(register).not.toHaveBeenCalled()

    window.dispatchEvent(new Event('load'))

    expect(register).toHaveBeenCalledWith('/service-worker', { scope: '/' })
  })

  it('does nothing when the browser has no service worker support', () => {
    stubReadyState('complete')

    expect(() => registerServiceWorker()).not.toThrow()
  })

  it('reports a failed registration instead of rejecting', async () => {
    const register = vi.fn().mockRejectedValue(new Error('boom'))
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => {})
    stubServiceWorkerContainer(register)
    stubReadyState('complete')

    registerServiceWorker()
    await vi.waitFor(() => expect(consoleError).toHaveBeenCalled())

    expect(consoleError.mock.calls[0][0]).toBe('Service worker registration failed')
  })
})
