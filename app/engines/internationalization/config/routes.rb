Internationalization::Engine.routes.draw do
  root "settings#show"
  resource :locale, only: [ :update ]
  resource :settings, only: [ :show ]
end
