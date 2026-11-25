class SettingsController < ApplicationController
  def show
    @user = Current.user
    @preferred_locale = @user&.preferred_locale.presence || cookies[:locale] || I18n.default_locale
  end
end
