module Internationalization
  class LocalesController < ApplicationController
    def update
      locale = Internationalization.normalize_locale(params.expect(:locale))
      unless locale
        redirect_to return_path, alert: t("internationalization.invalid_locale")
        return
      end

      if (user = load_locale_user)
        if user.update(preferred_locale: locale)
          cookies.permanent[:locale] = { value: locale, httponly: true, same_site: :lax }
          redirect_to return_path, notice: t("internationalization.preference_saved")
        else
          redirect_to return_path, alert: user.errors.full_messages.to_sentence
        end
      else
        cookies.permanent[:locale] = { value: locale, httponly: true, same_site: :lax }
        redirect_to return_path, notice: t("internationalization.preference_saved")
      end
    end

    private
      def return_path
        requested_path = params[:return_to].to_s
        return requested_path if requested_path.start_with?("/") && !requested_path.start_with?("//") && !requested_path.include?("\\")

        "/store"
      end
  end
end
