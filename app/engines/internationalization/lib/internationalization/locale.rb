module Internationalization
  SUPPORTED_LOCALES = %w[en fr es].freeze
  LOCALE_NAMES = { "en" => "English", "fr" => "Français", "es" => "Español" }.freeze

  def self.normalize_locale(locale)
    locale = locale.to_s
    locale if SUPPORTED_LOCALES.include?(locale)
  end

  def self.locale_or_default(locale)
    normalize_locale(locale) || I18n.default_locale.to_s
  end

  module PluralizationRules
    def pluralizer(locale)
      case locale.to_s
      when "fr"
        ->(count) { count <= 1 ? :one : :other }
      when "en", "es"
        ->(count) { count == 1 ? :one : :other }
      else
        super
      end
    end
  end

  module Locale
    extend ActiveSupport::Concern

    included do
      around_action :switch_locale
      helper_method :locale_options
    end

    private
      def switch_locale(&action)
        locale_user = load_locale_user
        locale = locale_user&.preferred_locale.presence || cookies[:locale]
        remember_locale(locale) if locale_user && Internationalization.normalize_locale(locale)
        I18n.with_locale(Internationalization.locale_or_default(locale), &action)
      end

      def remember_locale(locale)
        return if cookies[:locale] == locale

        cookies.permanent[:locale] = { value: locale, httponly: true, same_site: :lax }
      end

      def load_locale_user
        return unless defined?(::Current) && defined?(::Session)

        ::Current.session ||= ::Current.session_from(cookies) if ::Current.respond_to?(:session)

        ::Current.user if ::Current.respond_to?(:user)
      end

      def locale_options
        Internationalization::LOCALE_NAMES.map do |locale, name|
          [ I18n.t("internationalization.languages.#{locale}", default: name), locale ]
        end
      end
  end
end
