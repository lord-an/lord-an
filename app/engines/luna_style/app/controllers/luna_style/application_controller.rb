module LunaStyle
  class ApplicationController < ActionController::Base
    include Authenticate::Authentication
  end
end
