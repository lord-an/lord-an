module LunaStyle
  class Engine < ::Rails::Engine
    isolate_namespace LunaStyle

    initializer "luna_style.action_controller_helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper LunaStyle::ThemeHelper
      end
    end
  end
end
