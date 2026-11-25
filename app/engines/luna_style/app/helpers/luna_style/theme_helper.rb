module LunaStyle
  module ThemeHelper
    def luna_style_theme
      ThemeSetting.current.theme
    end

    def storefront_theme
      luna_style_theme
    end
  end
end
