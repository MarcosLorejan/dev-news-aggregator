function csrfToken(): string {
  return document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? ''
}

const MUTATING_AUTH_STORAGE_KEY = 'mutatingAuthBasic'

export function isAbortError(error: unknown): boolean {
  return (
    (typeof DOMException !== 'undefined' && error instanceof DOMException && error.name === 'AbortError') ||
    (error instanceof Error && error.name === 'AbortError')
  )
}

/** True for common transient browser network failures (offline, connection reset, CORS-ish TypeErrors). */
export function isTransientNetworkError(error: unknown): boolean {
  if (!(error instanceof Error) || isAbortError(error)) return false
  const message = error.message.toLowerCase()
  return (
    error.name === 'TypeError' ||
    message.includes('failed to fetch') ||
    message.includes('networkerror') ||
    message.includes('network request failed') ||
    message.includes('load failed')
  )
}

export function setMutatingAuthCredentials(username: string, password: string): void {
  sessionStorage.setItem(MUTATING_AUTH_STORAGE_KEY, btoa(`${username}:${password}`))
}

export function clearMutatingAuthCredentials(): void {
  sessionStorage.removeItem(MUTATING_AUTH_STORAGE_KEY)
}

function mutatingAuthHeader(): string | null {
  try {
    return sessionStorage.getItem(MUTATING_AUTH_STORAGE_KEY)
  } catch {
    return null
  }
}

function isMutatingMethod(method?: string): boolean {
  const normalized = (method ?? 'GET').toUpperCase()
  return normalized === 'POST' || normalized === 'PATCH' || normalized === 'PUT' || normalized === 'DELETE'
}

function promptMutatingAuth(): boolean {
  if (typeof window === 'undefined' || typeof window.prompt !== 'function') return false

  const username = window.prompt('Username required for this action:')
  if (!username) return false
  const password = window.prompt('Password:')
  if (password === null) return false

  setMutatingAuthCredentials(username, password)
  return true
}

export async function apiRequest<T>(
  path: string,
  options: RequestInit = {},
  retryOnUnauthorized = true
): Promise<T> {
  const headers = new Headers(options.headers)
  headers.set('Accept', 'application/json')
  headers.set('X-CSRF-Token', csrfToken())

  if (options.body && !headers.has('Content-Type')) {
    headers.set('Content-Type', 'application/json')
  }

  const basic = mutatingAuthHeader()
  if (basic) {
    headers.set('Authorization', `Basic ${basic}`)
  }

  const response = await fetch(path, { ...options, headers })

  if (
    response.status === 401 &&
    retryOnUnauthorized &&
    isMutatingMethod(options.method) &&
    promptMutatingAuth()
  ) {
    return apiRequest(path, options, false)
  }

  if (!response.ok) {
    let message = `Request failed: ${response.status}`
    try {
      const body = await response.json()
      if (typeof body?.error === 'string' && body.error) {
        message = body.error
      } else if (Array.isArray(body?.errors) && body.errors.length > 0) {
        message = body.errors.join(', ')
      }
    } catch {
      // ignore JSON parse errors
    }
    throw new Error(message)
  }

  if (response.status === 204) {
    return undefined as T
  }

  return response.json() as Promise<T>
}
