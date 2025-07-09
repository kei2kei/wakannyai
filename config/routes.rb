Rails.application.routes.draw do
  resources :posts, only: %i[new create edit update show destroy]
  root "posts#index"
end
