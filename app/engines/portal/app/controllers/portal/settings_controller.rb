module Portal
  class SettingsController < ApplicationController
    before_action :set_user

    def show
    end

    def edit
    end

    def update
      settings = settings_params

      if password_change?(settings) && !@user.authenticate(settings.delete(:current_password).to_s)
        @user.errors.add(:current_password, t("portal.settings.current_password_incorrect"))
        render :edit, status: :unprocessable_entity
      elsif @user.update(settings.except(:current_password))
        redirect_to "/portal/settings", notice: t("portal.settings.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private
      def set_user
        @user = Current.user
      end

      def password_change?(settings)
        settings[:password].present? || settings[:password_confirmation].present?
      end

      def settings_params
        params.expect(user: [ :email_address, :preferred_locale, :current_password, :password, :password_confirmation ])
      end
  end
end
