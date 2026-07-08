import React from 'react'
import ReactDOM from 'react-dom/client'
import '@fontsource/inter/latin.css'
import './application.css'
import App from '../components/App'

const rootElement = document.getElementById('root')

if (rootElement) {
  ReactDOM.createRoot(rootElement).render(
    <React.StrictMode>
      <App />
    </React.StrictMode>
  )
}
