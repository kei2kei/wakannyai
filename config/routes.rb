Rails.application.routes.draw do
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }
  resources :posts, only: %i[new create edit update show destroy] do
    member do
      patch :solve # PATCH /posts/:id/solve
    end
    resources :comments, only: %i[create edit destroy]
  end
  resources :comments, only: [:create] do
    collection do
      get :new_reply
    end
  end
  resources :comments, only: [] do
    member do
      patch :set_best_comment
    end
  end
  root 'posts#index'
  get 'tags/search', to: 'tags#search'
  post '/api/upload-image', to: 'images#upload'
  delete "/api/images/:id", to: "images#destroy"
  devise_scope :user do
    get 'sign_in', :to => 'devise/sessions#new', :as => :new_user_session
    get 'sign_out', :to => 'devise/sessions#destroy', :as => :destroy_user_session
  end
end
