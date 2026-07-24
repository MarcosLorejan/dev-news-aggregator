import React from 'react'
import ReactDOM from 'react-dom/client'
import App from '../components/App'
import { registerServiceWorker } from '../utils/registerServiceWorker'

registerServiceWorker()

const rootElement = document.getElementById('root')

if (rootElement) {
  ReactDOM.createRoot(rootElement).render(
    <React.StrictMode>
      <App />
    </React.StrictMode>
  )
}
