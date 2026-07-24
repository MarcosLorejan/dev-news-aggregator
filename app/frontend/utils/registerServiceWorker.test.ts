import { afterEach, describe, expect, it, vi } from 'vitest'
import { registerServiceWorker } from './registerServiceWorker'

function stubServiceWorkerContainer(register: ReturnType<typeof vi.fn>, getRegistrations?: ReturnType<typeof vi.fn>) {
  Object.defineProperty(navigator, 'serviceWorker', {
    value: {
      register,
      getRegistrations: getRegistrations ?? vi.fn().mockResolvedValue([]),
    },
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
  vi.stubEnv('DEV', false)
  vi.unstubAllEnvs()
  vi.restoreAllMocks()
})

describe('registerServiceWorker', () => {
  it('registers the service worker at the app scope on an already loaded page', () => {
    vi.stubEnv('DEV', false)
    const register = vi.fn().mockResolvedValue({})
    stubServiceWorkerContainer(register)
    stubReadyState('complete')

    registerServiceWorker()

    expect(register).toHaveBeenCalledWith('/service-worker', { scope: '/' })
  })

  it('waits for the load event when the page is still loading', () => {
    vi.stubEnv('DEV', false)
    const register = vi.fn().mockResolvedValue({})
    stubServiceWorkerContainer(register)
    stubReadyState('loading')

    registerServiceWorker()
    expect(register).not.toHaveBeenCalled()

    window.dispatchEvent(new Event('load'))

    expect(register).toHaveBeenCalledWith('/service-worker', { scope: '/' })
  })

  it('does nothing when the browser has no service worker support', () => {
    vi.stubEnv('DEV', false)
    stubReadyState('complete')

    expect(() => registerServiceWorker()).not.toThrow()
  })

  it('reports a failed registration instead of rejecting', async () => {
    vi.stubEnv('DEV', false)
    const register = vi.fn().mockRejectedValue(new Error('boom'))
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => {})
    stubServiceWorkerContainer(register)
    stubReadyState('complete')

    registerServiceWorker()
    await vi.waitFor(() => expect(consoleError).toHaveBeenCalled())

    expect(consoleError.mock.calls[0][0]).toBe('Service worker registration failed')
  })

  it('skips registration and unregisters leftovers in development', async () => {
    vi.stubEnv('DEV', true)
    const register = vi.fn().mockResolvedValue({})
    const unregister = vi.fn().mockResolvedValue(true)
    const getRegistrations = vi.fn().mockResolvedValue([{ unregister }])
    stubServiceWorkerContainer(register, getRegistrations)
    stubReadyState('complete')

    registerServiceWorker()

    expect(register).not.toHaveBeenCalled()
    await vi.waitFor(() => expect(unregister).toHaveBeenCalled())
  })
})
