module Authenticate
  class PasswordsController < ApplicationController
    allow_unauthenticated_access
    before_action :set_user_by_token, only: %i[ edit update ]

    rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
      redirect_to "/authenticate/passwords/new", alert: I18n.t("authenticate.try_again_later")
    }

    def new
    end

    def create
      if user = ::User.find_by(email_address: params[:email_address])
        PasswordsMailer.reset(user).deliver_later
      end

      redirect_to "/authenticate/session/new", notice: t("authenticate.password_reset_sent")
    end

    def edit
    end

    def update
      if @user.update(params.permit(:password, :password_confirmation))
        @user.sessions.destroy_all
        redirect_to "/authenticate/session/new", notice: t("authenticate.password_reset")
      else
        redirect_to "/authenticate/passwords/#{params[:token]}/edit", alert: @user.errors.full_messages.to_sentence
      end
    end

    private
      def set_user_by_token
        @user = ::User.find_by_token_for!(:password_reset, params[:token])
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        redirect_to "/authenticate/passwords/new", alert: t("authenticate.invalid_reset_link")
      end
  end
end
