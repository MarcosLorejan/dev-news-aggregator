import { BrowserRouter, Route, Routes } from 'react-router-dom'
import ArticlesIndexPage from '../pages/ArticlesIndexPage'
import BookmarksIndexPage from '../pages/BookmarksIndexPage'

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<ArticlesIndexPage />} />
        <Route path="/articles" element={<ArticlesIndexPage />} />
        <Route path="/bookmarks" element={<BookmarksIndexPage />} />
      </Routes>
    </BrowserRouter>
  )
}
