Authenticate::Engine.routes.draw do
  root "registrations#new"

  resources :registrations, only: %i[ new create ]
  resource :session
  resources :passwords, param: :token
end
