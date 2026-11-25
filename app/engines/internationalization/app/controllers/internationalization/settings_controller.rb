module Internationalization
  class SettingsController < ApplicationController
    def show
      @preferred_locale = load_locale_user&.preferred_locale.presence || cookies[:locale] || I18n.default_locale
    end
  end
end
