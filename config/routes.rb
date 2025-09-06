Rails.application.routes.draw do
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }
  devise_scope :user do
    get 'sign_in', to: 'devise/sessions#new', as: :new_user_session
    delete 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
  end
  resources :posts, only: %i[new create edit update show destroy] do
    member do
      patch :solve
      patch :sync_to_github
    end
    resources :comments, only: %i[create destroy]
  end

  resources :comments, only: [] do
    collection do
      get :new_reply
    end
    member do
      patch :set_best_comment
    end
  end

  root 'posts#index'
  get 'tags/search', to: 'tags#search'

  # API関連
  post '/api/upload-image', to: 'images#upload'
  delete "/api/images/:id", to: "images#destroy"
end
