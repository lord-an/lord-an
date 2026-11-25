module Store
  class ApplicationController < ActionController::Base
    include Authenticate::Authentication
    include Internationalization::Locale
  end
end
