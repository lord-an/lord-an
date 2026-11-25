require "test_helper"

module LunaStyle
  class ThemeSettingTest < ActiveSupport::TestCase
    test "current creates one classic setting and reuses it" do
      setting = ThemeSetting.current

      assert_equal "classic", setting.theme
      assert_equal setting, ThemeSetting.current
    end

    test "only supported themes are valid" do
      setting = ThemeSetting.current

      ThemeSetting::THEMES.each do |theme|
        setting.theme = theme
        assert_predicate setting, :valid?
      end

      setting.theme = "ultraviolet"
      assert_not_predicate setting, :valid?
    end

    test "the setting key has a unique database index" do
      assert ThemeSetting.connection.index_exists?(
        ThemeSetting.table_name,
        :key,
        unique: true
      )

      ThemeSetting.current
      assert_raises(ActiveRecord::RecordNotUnique) do
        ThemeSetting.insert!({ key: "storefront", theme: "classic" })
      end
    end
  end
end
