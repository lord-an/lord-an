module Authenticate
  class ApplicationController < ActionController::Base
    include Authentication
    include Internationalization::Locale

    private
      def after_signup_url
        "/settings#account"
      end
  end
end
