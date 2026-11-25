module Commerce
  class ApplicationController < ActionController::Base
    layout "commerce/application"

    include Authenticate::Authentication
    include Internationalization::Locale

    private
      def current_cart
        Cart.find_or_create_by!(user: Current.user)
      end
  end
end
