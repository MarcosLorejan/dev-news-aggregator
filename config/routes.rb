Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Articles routes
  resources :articles, only: [ :index, :show ] do
    member do
      post :bookmark
      delete :unbookmark
      post :mark_as_read
      delete :unmark_as_read
    end
  end

  # Bookmarks routes
  resources :bookmarks, only: [ :index ]

  # Read articles routes
  resources :read_articles, only: [ :index ], path: 'read'
  post 'articles/:article_id/mark_as_read', to: 'read_articles#create', as: 'mark_article_as_read'
  delete 'articles/:article_id/unmark_as_read', to: 'read_articles#destroy', as: 'unmark_article_as_read'

  root "articles#index"
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by uptime monitors and load balancers.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
