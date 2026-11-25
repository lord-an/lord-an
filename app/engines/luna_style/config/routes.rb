LunaStyle::Engine.routes.draw do
  resource :theme, only: %i[show update], controller: :themes
end
