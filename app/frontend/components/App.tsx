import { BrowserRouter, Route, Routes } from 'react-router-dom'
import ArticlesIndexPage from '../pages/ArticlesIndexPage'
import ArticleShowPage from '../pages/ArticleShowPage'
import BookmarksIndexPage from '../pages/BookmarksIndexPage'
import DismissedArticlesIndexPage from '../pages/DismissedArticlesIndexPage'
import ReadArticlesIndexPage from '../pages/ReadArticlesIndexPage'
import RecentlyDismissedPage from '../pages/RecentlyDismissedPage'

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<ArticlesIndexPage />} />
        <Route path="/articles" element={<ArticlesIndexPage />} />
        <Route path="/articles/:id" element={<ArticleShowPage />} />
        <Route path="/bookmarks" element={<BookmarksIndexPage />} />
        <Route path="/read" element={<ReadArticlesIndexPage />} />
        <Route path="/dismissed" element={<DismissedArticlesIndexPage />} />
        <Route path="/recently_dismissed" element={<RecentlyDismissedPage />} />
      </Routes>
    </BrowserRouter>
  )
}
