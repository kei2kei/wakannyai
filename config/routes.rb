Rails.application.routes.draw do
  devise_for :users
  resources :posts, only: %i[new create edit update show destroy]
  root 'posts#index'
  get 'tags/search', to: 'tags#search'
  get 'login', to: 'user_sessions#new', as: :login
  post 'login', to: 'user_sessions#create'
  delete 'logout', to:'user_sessions#destroy', as: :logout
end
