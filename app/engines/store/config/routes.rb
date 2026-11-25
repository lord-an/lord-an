Store::Engine.routes.draw do
  root "products#index"

  resources :products do
    resource :wishlist, only: [ :create ], module: :products
    resources :reviews, only: [ :new, :create ], module: :products
    resources :subscribers, only: [ :create ]
  end

  resources :wishlists do
    resources :wishlist_products, only: [ :update, :destroy ], module: :wishlists
  end

  resource :unsubscribe, only: %i[ show destroy ]
end
