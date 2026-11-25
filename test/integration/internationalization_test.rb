require "test_helper"

class InternationalizationTest < ActionDispatch::IntegrationTest
  test "guests can select a locale that is retained in a cookie across engines" do
    get "/internationalization/settings"
    assert_response :success
    assert_select "select[name=locale] option", count: 3
    assert_select "form[action='/internationalization/locale']"

    patch "/internationalization/locale", params: {
      locale: "fr",
      return_to: "/authenticate/session/new"
    }

    assert_redirected_to "/authenticate/session/new"
    assert_equal "fr", cookies[:locale]

    get "/authenticate/session/new"

    assert_response :success
    assert_select "h1", "Se connecter"
  end

  test "signed-in locale preferences persist on the account and apply across engines" do
    sign_in_as users(:one)

    patch "/internationalization/locale", params: {
      locale: "es",
      return_to: "/store"
    }

    assert_redirected_to "/store"
    assert_equal "es", users(:one).reload.preferred_locale

    get "/store"

    assert_response :success
    assert_select "h1", "Productos"

    get "/portal/settings"
    assert_response :success
    assert_select "p", /Idioma/
    assert_select "p", /Español/
  end

  test "the signed-in account preference overrides and refreshes a stale guest cookie" do
    users(:one).update!(preferred_locale: "es")
    cookies[:locale] = "fr"
    sign_in_as users(:one)

    get "/store"

    assert_response :success
    assert_select "h1", "Productos"
    assert_equal "es", cookies[:locale]
  end

  test "unsupported locales are rejected without changing a preference" do
    sign_in_as users(:one)

    patch "/internationalization/locale", params: { locale: "pt", return_to: "/store" }

    assert_redirected_to "/store"
    assert_equal "en", users(:one).reload.preferred_locale
    assert_equal "Please choose a supported language.", flash[:alert]
  end

  test "signing up carries the guest language preference into account settings" do
    cookies[:locale] = "fr"

    post "/authenticate/registrations", params: {
      user: {
        email_address: "french-user@example.org",
        password: "a private password",
        password_confirmation: "a private password"
      }
    }

    user = User.find_by!(email_address: "french-user@example.org")
    assert_equal "fr", user.preferred_locale
    assert_redirected_to "/portal/settings"
  end

  test "translation dictionaries configure locale-specific pluralization and dates" do
    assert_equal "0 pomme", I18n.t("internationalization.pluralization.apples", count: 0, locale: :fr)
    assert_equal "1 manzana", I18n.t("internationalization.pluralization.apples", count: 1, locale: :es)
    assert_equal "25 de noviembre de 2026", I18n.l(Date.new(2026, 11, 25), format: :long, locale: :es)
  end

  test "product names and rich-text descriptions fall back and localize by locale" do
    product = Store::Product.create!(name: "Lamp", inventory_count: 2, price_cents: 1800, currency_code: "USD")
    product.update!(description: "A useful lamp.")
    translation = product.translations.create!(locale: "fr", name: "Lampe")
    translation.update!(description: "Une lampe de bureau.")

    assert_equal "Lamp", product.localized_name(:en)
    assert_equal "Lampe", product.localized_name(:fr)
    assert_equal "Lamp", product.localized_name(:es)
    assert_equal "Une lampe de bureau.", product.localized_description(:fr).to_plain_text
    assert_equal "A useful lamp.", product.localized_description(:es).to_plain_text
  end

  test "product editor exposes separate French and Spanish translation fields" do
    sign_in_as_admin users(:one)

    get "/store/products/new"

    assert_response :success
    assert_select "h3", "French"
    assert_select "h3", "Spanish"
    assert_select "input[name^='product[translations_attributes]'][name$='[name]']", count: 2
  end

  test "product creation saves translated names and descriptions" do
    sign_in_as_admin users(:one)
    patch "/internationalization/locale", params: { locale: "fr", return_to: "/store/products/new" }

    post "/store/products", params: {
      product: {
        name: "Lamp",
        description: "A useful lamp.",
        inventory_count: 2,
        price_cents: 1800,
        currency_code: "USD",
        translations_attributes: {
          "0" => { locale: "fr", name: "Lampe", description: "Une lampe de bureau." },
          "1" => { locale: "es", name: "Lámpara", description: "Una lámpara de escritorio." }
        }
      }
    }

    product = Store::Product.find_by!(name: "Lamp")
    assert_equal "Lampe", product.localized_name(:fr)
    assert_equal "Lámpara", product.localized_name(:es)
    assert_equal "Une lampe de bureau.", product.localized_description(:fr).to_plain_text
    assert_redirected_to "/store/products/#{product.id}"

    get "/store/products/#{product.id}"
    assert_response :success
    assert_select "h1", "Lampe"
    assert_select "trix-editor", false
    assert_includes response.body, "Une lampe de bureau."
  end

  private
    def sign_in_as_admin(user)
      user.update!(admin: true)
      sign_in_as(user)
    end
end
