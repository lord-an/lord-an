module LunaStyle
  class ThemesController < ApplicationController
    before_action :require_admin

    def show
      @theme_setting = ThemeSetting.current
    end

    def update
      @theme_setting = ThemeSetting.current

      if @theme_setting.update(theme_setting_params)
        redirect_to theme_path, notice: "Storefront theme updated."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private
      def require_admin
        return if Current.user&.admin?

        redirect_to "/store", alert: "Administrator access is required."
      end

      def theme_setting_params
        params.expect(theme_setting: [ :theme ])
      end
  end
end
