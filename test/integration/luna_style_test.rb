require "test_helper"

class LunaStyleTest < ActionDispatch::IntegrationTest
  test "theme settings require authentication" do
    get "/luna-style/theme"
    assert_redirected_to "/authenticate/session/new"

    patch "/luna-style/theme",
          params: { theme_setting: { theme: "forest" } }
    assert_redirected_to "/authenticate/session/new"
  end

  test "customers cannot view or update the theme" do
    sign_in_as users(:one)

    get "/luna-style/theme"
    assert_redirected_to "/store"

    patch "/luna-style/theme",
          params: { theme_setting: { theme: "forest" } }
    assert_redirected_to "/store"
    assert_equal "classic", LunaStyle::ThemeSetting.current.reload.theme
  end

  test "administrators can update the theme without changing its key" do
    administrator = users(:one)
    administrator.update!(admin: true)
    sign_in_as administrator

    get "/luna-style/theme"
    assert_response :success
    assert_select "label[for='theme_setting_theme']", "Active theme"
    assert_select "select[name='theme_setting[theme]'] option", count: 3

    patch "/luna-style/theme",
          params: { theme_setting: { theme: "forest", key: "changed-by-request" } }

    assert_redirected_to "/luna-style/theme"
    setting = LunaStyle::ThemeSetting.current.reload
    assert_equal "forest", setting.theme
    assert_equal "storefront", setting.key
  end

  test "unsupported theme values are rejected" do
    administrator = users(:one)
    administrator.update!(admin: true)
    sign_in_as administrator

    patch "/luna-style/theme",
          params: { theme_setting: { theme: "ultraviolet" } }

    assert_response :unprocessable_entity
    assert_equal "classic", LunaStyle::ThemeSetting.current.reload.theme
  end

  test "storefront renders the active theme and engine stylesheet" do
    LunaStyle::ThemeSetting.current.update!(theme: "sunrise")

    get "/store"

    assert_response :success
    assert_select 'body[data-storefront-theme="sunrise"]'
    assert_select 'link[rel="stylesheet"][href*="luna_style/application"]'

    stylesheet = css_select(
      'link[rel="stylesheet"][href*="luna_style/application"]'
    ).first
    get stylesheet["href"]

    assert_response :success
    assert_includes response.body, 'body[data-luna-style-theme="sunrise"]'
    assert_includes response.body, "--store-color-accent"
    assert_includes response.body, "--store-color-accent: var(--luna-color-accent)"
  end

  test "host and mounted engine layouts share LunaStyle" do
    administrator = users(:one)
    administrator.update!(admin: true)
    sign_in_as administrator
    LunaStyle::ThemeSetting.current.update!(theme: "forest")

    [
      "/",
      "/authenticate/session/new",
      "/portal/settings",
      "/store",
      "/commerce/cart",
      "/internationalization/settings",
      "/luna-style/theme"
    ].each do |path|
      get path

      assert_response :success, path
      assert_select 'body[data-luna-style-theme="forest"]', 1, path
      assert_select 'link[rel="stylesheet"][href*="luna_style/application"]', 1, path
    end
  end
end
