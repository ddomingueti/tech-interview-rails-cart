require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'
  resources :products
  get "up" => "rails/health#show", as: :rails_health_check

  root "rails/health#show"

  resource :product, only: %i[show create update destroy]

  resource :cart, only: %i[show create] do
    post :add_item, on: :member
    delete ':product_id', to: 'carts#remove_item', as: :remove_item
  end
end
