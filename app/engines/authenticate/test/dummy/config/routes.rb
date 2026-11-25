Rails.application.routes.draw do
  mount Authenticate::Engine => "/authenticate"
end
