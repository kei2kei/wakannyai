Rails.application.routes.draw do
  resources :posts, only: %i[edit update show destroy]
  root "posts#index"
end
