Rails.application.routes.draw do
  devise_for :users
  get 'user_sessions/new'
  get 'user_sessions/create'
  get 'user_sessions/destroy'
  resources :posts, only: %i[new create edit update show destroy]
  root 'posts#index'
  get 'tags/search', to: 'tags#search'
  get 'login', to: 'user_sessions#new', as: :login
  post 'login', to: 'user_sessions#create'
  delete 'logout', to:'user_sessions#destroy', as: :logout
end
