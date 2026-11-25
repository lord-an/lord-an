require "test_helper"

class LunaStyle::ThemeSettingTest < ActiveSupport::TestCase
  test "current creates one classic setting and reuses it" do
    setting = LunaStyle::ThemeSetting.current

    assert_equal "classic", setting.theme
    assert_equal setting, LunaStyle::ThemeSetting.current
  end

  test "only supported themes are valid" do
    setting = LunaStyle::ThemeSetting.current

    LunaStyle::ThemeSetting::THEMES.each do |theme|
      setting.theme = theme
      assert_predicate setting, :valid?
    end

    setting.theme = "ultraviolet"
    assert_not_predicate setting, :valid?
  end

  test "the storefront key has a unique database index" do
    assert LunaStyle::ThemeSetting.connection.index_exists?(
      LunaStyle::ThemeSetting.table_name,
      :key,
      unique: true
    )

    LunaStyle::ThemeSetting.current
    assert_raises(ActiveRecord::RecordNotUnique) do
      LunaStyle::ThemeSetting.insert!({ key: "storefront", theme: "classic" })
    end
  end
end
