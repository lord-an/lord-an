require "test_helper"

class SettingsTest < ActionDispatch::IntegrationTest
  test "settings brings account, language, and appearance together" do
    get "/settings"

    assert_response :success
    assert_select "main.settings-page"
    assert_select "h1", "Settings"
    assert_select "nav.site-nav a[href='/settings']", "Settings"
    assert_select "nav.settings-nav a[href='#account']", "Account"
    assert_select "nav.settings-nav a[href='#language']", "Language"
    assert_select "nav.settings-nav a[href='#appearance']", "Appearance"
    assert_select "section#account"
    assert_select "section#language form[action='/internationalization/locale']"
    assert_select "section#appearance"
  end

  test "language preference can be changed from the unified settings page" do
    get "/settings"
    assert_response :success

    patch "/internationalization/locale", params: {
      locale: "fr",
      return_to: "/settings#language"
    }

    assert_redirected_to "/settings#language"
    assert_equal "fr", cookies[:locale]

    get "/settings"

    assert_response :success
    assert_select "h1", "Paramètres"
    assert_select "select[name=locale] option[selected][value=fr]"
  end

  test "signed-in account details are available inside unified settings" do
    sign_in_as users(:one)

    get "/settings"

    assert_response :success
    assert_select "p.settings-card__value", users(:one).email_address
    assert_select "a[href='/portal/settings/edit']", "Edit account details"
    assert_select "a[href='/commerce/cart']", "Cart"
    assert_select "nav.section-nav a[href='#language']", "Language"

    get "/store"

    assert_response :success
    assert_select "nav.section-nav a[href='/store/wishlists']", "Wishlists"
  end

  test "appearance management is available only to explicitly designated administrators" do
    get "/settings"

    assert_response :success
    assert_select "a[href='/luna-style/theme']", false
    assert_select "p.settings-card__note", /Only accounts designated as store administrators/

    sign_in_as users(:one)
    get "/settings"

    assert_response :success
    assert_select "a[href='/luna-style/theme']", false

    administrator = User.find(users(:two).id)
    administrator.update!(admin: true)
    sign_in_as administrator
    get "/settings"

    assert_response :success
    assert_select "a[href='/luna-style/theme']", "Manage storefront appearance"
    assert_select "p.settings-card__note", "This account has store administrator access."
  end

  test "account edits cannot change the language preference" do
    user = users(:one)
    original_locale = user.preferred_locale
    sign_in_as user

    patch "/portal/settings", params: {
      user: {
        email_address: user.email_address,
        preferred_locale: "fr"
      }
    }

    assert_redirected_to "/settings#account"
    assert_equal original_locale, user.reload.preferred_locale
  end

  test "legacy settings destinations redirect to their unified settings sections" do
    sign_in_as users(:one)

    get "/portal/settings"
    assert_redirected_to "/settings#account"

    get "/internationalization/settings"
    assert_redirected_to "/settings#language"
  end
end
