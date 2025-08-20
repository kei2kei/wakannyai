Rails.application.routes.draw do
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }
  resources :posts, only: %i[new create edit update show destroy] do
    resources :comments, only: %i[create edit destroy]
  end
  root 'posts#index'
  get 'tags/search', to: 'tags#search'
  devise_scope :user do
    get 'sign_in', :to => 'devise/sessions#new', :as => :new_user_session
    get 'sign_out', :to => 'devise/sessions#destroy', :as => :destroy_user_session
  end
end
