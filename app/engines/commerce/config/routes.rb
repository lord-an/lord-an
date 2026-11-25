Commerce::Engine.routes.draw do
  resource :cart, only: :show do
    post :checkout, to: "orders#create"
    resources :items, only: %i[ create update destroy ], controller: :cart_items
  end

  resources :orders, only: %i[ index show ]
end
