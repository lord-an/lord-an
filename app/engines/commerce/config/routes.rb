Commerce::Engine.routes.draw do
  resource :cart, only: :show do
    post :checkout, to: "orders#create"
    resources :items, only: %i[ create update destroy ], controller: :cart_items
  end

  resources :orders, only: %i[ index show ] do
    get :payment_return, on: :member
    post :mark_fulfilled, on: :member
  end

  post "webhooks/adyen", to: "adyen_webhooks#create", as: :adyen_webhook
end
