module Authenticate
  class SessionsController < ApplicationController
    allow_unauthenticated_access only: %i[ new create ]
    before_action :redirect_authenticated_user, only: %i[ new create ]

    rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
      redirect_to "/authenticate/session/new", alert: I18n.t("authenticate.try_again_later")
    }

    def new
    end

    def create
      if user = ::User.authenticate_by(params.permit(:email_address, :password))
        redirect_url = after_authentication_url
        start_new_session_for(user)
        redirect_to redirect_url
      else
        redirect_to "/authenticate/session/new", alert: t("authenticate.invalid_credentials")
      end
    end

    def destroy
      terminate_session
      redirect_to "/authenticate/session/new", status: :see_other
    end
  end
end
