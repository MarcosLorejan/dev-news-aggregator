import { lazy, Suspense } from 'react'
import { BrowserRouter, Route, Routes } from 'react-router-dom'
import AppLayout from './AppLayout'
import RouteFallback from './RouteFallback'

const ArticlesIndexPage = lazy(() => import('../pages/ArticlesIndexPage'))
const ArticleShowPage = lazy(() => import('../pages/ArticleShowPage'))
const BookmarksIndexPage = lazy(() => import('../pages/BookmarksIndexPage'))
const DismissedArticlesIndexPage = lazy(() => import('../pages/DismissedArticlesIndexPage'))
const ReadArticlesIndexPage = lazy(() => import('../pages/ReadArticlesIndexPage'))
const RecentlyDismissedPage = lazy(() => import('../pages/RecentlyDismissedPage'))
const SourcesIndexPage = lazy(() => import('../pages/SourcesIndexPage'))
const DigestsIndexPage = lazy(() => import('../pages/DigestsIndexPage'))
const DigestsShowPage = lazy(() => import('../pages/DigestsShowPage'))

export default function App() {
  return (
    <BrowserRouter>
      <Suspense fallback={<RouteFallback />}>
        <Routes>
          <Route element={<AppLayout />}>
            <Route path="/" element={<ArticlesIndexPage />} />
            <Route path="/articles" element={<ArticlesIndexPage />} />
            <Route path="/articles/:id" element={<ArticleShowPage />} />
            <Route path="/bookmarks" element={<BookmarksIndexPage />} />
            <Route path="/read" element={<ReadArticlesIndexPage />} />
            <Route path="/dismissed" element={<DismissedArticlesIndexPage />} />
            <Route path="/recently_dismissed" element={<RecentlyDismissedPage />} />
            <Route path="/sources" element={<SourcesIndexPage />} />
            <Route path="/digests" element={<DigestsIndexPage />} />
            <Route path="/digests/:id" element={<DigestsShowPage />} />
          </Route>
        </Routes>
      </Suspense>
    </BrowserRouter>
  )
}
