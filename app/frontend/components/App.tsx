import { BrowserRouter, Route, Routes } from 'react-router-dom'
import ArticlesIndexPage from '../pages/ArticlesIndexPage'

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<ArticlesIndexPage />} />
      </Routes>
    </BrowserRouter>
  )
}
