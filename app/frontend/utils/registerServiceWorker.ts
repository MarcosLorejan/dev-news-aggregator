const SERVICE_WORKER_PATH = '/service-worker'

function register(): void {
  navigator.serviceWorker.register(SERVICE_WORKER_PATH, { scope: '/' }).catch((error) => {
    console.error('Service worker registration failed', error)
  })
}

function unregisterAll(): void {
  navigator.serviceWorker.getRegistrations().then((registrations) => {
    registrations.forEach((registration) => {
      registration.unregister().catch(() => {})
    })
  })
}

export function registerServiceWorker(): void {
  if (!('serviceWorker' in navigator)) {
    return
  }

  // Skip (and clear) service workers in Vite/Rails development. A leftover SW
  // from a previous session can leave a blank page while HMR assets change.
  if (import.meta.env.DEV) {
    unregisterAll()
    return
  }

  // Registering on load keeps the service worker from competing with the
  // initial render for bandwidth. When the entrypoint itself runs after load
  // (a lazily imported chunk), that event never fires again, so register now.
  if (document.readyState === 'complete') {
    register()
  } else {
    window.addEventListener('load', register, { once: true })
  }
}
