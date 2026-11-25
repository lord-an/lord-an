Portal::Engine.routes.draw do
  root "settings#show"

  resource :settings, only: %i[ show edit update ]
end
