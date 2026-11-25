module Internationalization
  class Engine < ::Rails::Engine
    isolate_namespace Internationalization

    initializer "internationalization.locales" do |app|
      locale_files = root.join("config/locales/*.yml")
      app.config.i18n.load_path += Dir[locale_files]
      app.config.i18n.default_locale = :en
      app.config.i18n.available_locales = Internationalization::SUPPORTED_LOCALES.map(&:to_sym)
      app.config.i18n.enforce_available_locales = true
    end

    initializer "internationalization.pluralization" do
      I18n::Backend::Simple.include(I18n::Backend::Pluralization)
      I18n::Backend::Simple.include(Internationalization::PluralizationRules)
    end
  end
end
