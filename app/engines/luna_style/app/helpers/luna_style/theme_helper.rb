module LunaStyle
  module ThemeHelper
    def storefront_theme
      ThemeSetting.current.theme
    end
  end
end
