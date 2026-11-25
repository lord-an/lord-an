require "test_helper"

class StoreMountTest < ActionDispatch::IntegrationTest
  test "serves the store from /store" do
    get "/store"

    assert_response :success
    assert_select "h1", "Products"
  end

  test "the application root introduces the store and customer features" do
    get "/"

    assert_response :success
    assert_select "h1", "Find your next favorite."
    assert_select "h2", "More than a catalog"
    assert_select "a[href='/store']", "Explore the store"
    assert_select "a[href='/authenticate/registrations/new']", "Create an account"
  end

  test "signed-in customers are not prompted to create another account" do
    sign_in_as users(:one)

    get "/"

    assert_response :success
    assert_select "a[href='/authenticate/registrations/new']", false
    assert_select "a[href='/authenticate/session/new']", false
    assert_select "a[href='/authenticate/session']", false
  end

  test "mounts signup and login through separate engines" do
    get "/authenticate/registrations/new"
    assert_response :success
    assert_select "h1", "Sign up"
    assert_select "input[name='user[password]'][minlength='12']"

    get "/authenticate/session/new"
    assert_response :success
    assert_select "h1", "Log in"
  end

  test "authenticated users cannot open or submit registration" do
    sign_in_as users(:one)
    user_count = User.count

    get "/authenticate/registrations/new"
    assert_redirected_to "/settings#account"

    post "/authenticate/registrations", params: {
      user: {
        email_address: "second-account@example.org",
        password: "a private password",
        password_confirmation: "a private password"
      }
    }

    assert_redirected_to "/settings#account"
    assert_equal user_count, User.count
  end

  test "signup rejects passwords shorter than twelve characters" do
    post "/authenticate/registrations", params: {
      user: {
        email_address: "short-password@example.org",
        password: "too-short",
        password_confirmation: "too-short"
      }
    }

    assert_response :unprocessable_entity
    assert_not User.exists?(email_address: "short-password@example.org")
  end

  test "a visitor can sign up, view settings, and update account settings" do
    post "/authenticate/registrations", params: {
      user: {
        email_address: "engine-user@example.org",
        password: "a private password",
        password_confirmation: "a private password",
        admin: true
      }
    }

    assert_redirected_to "/settings#account"
    user = User.find_by!(email_address: "engine-user@example.org")
    assert_not user.admin?

    get "/settings"
    assert_response :success
    assert_select "h2#account-title", "Account"
    assert_select "p.settings-card__value", "engine-user@example.org"

    get "/portal/settings/edit"
    assert_response :success
    assert_select "input[name='user[password]'][minlength='12']"

    patch "/portal/settings", params: {
      user: {
        email_address: "updated-user@example.org",
        current_password: "a private password",
        password: "a new private password",
        password_confirmation: "a new private password"
      }
    }

    assert_redirected_to "/settings#account"
    user = User.find_by!(email_address: "updated-user@example.org")
    assert user.authenticate("a new private password")

    patch "/portal/settings", params: {
      user: {
        email_address: "updated-user@example.org",
        current_password: "a new private password",
        password: "too-short",
        password_confirmation: "too-short"
      }
    }

    assert_response :unprocessable_entity
    assert user.reload.authenticate("a new private password")
  end

  test "portal settings requires authentication" do
    get "/portal/settings"

    assert_redirected_to "/authenticate/session/new"
  end

  test "changing a password revokes other sessions but keeps the current session" do
    user = users(:one)
    sign_in_as user
    current_session_id = Current.session.id
    other_session = user.sessions.create!

    patch "/portal/settings", params: {
      user: {
        email_address: user.email_address,
        current_password: "password",
        password: "a new private password",
        password_confirmation: "a new private password"
      }
    }

    assert_redirected_to "/settings#account"
    assert Session.exists?(current_session_id)
    assert_not Session.exists?(other_session.id)
    assert user.reload.authenticate("a new private password")
  end

  test "product management is restricted to administrators" do
    customer = User.create!(
      email_address: "store-customer@example.org",
      password: "a private password",
      password_confirmation: "a private password"
    )
    get "/store/products/new"
    assert_redirected_to "/authenticate/session/new"

    sign_in_as(customer)

    get "/store/products/new"
    assert_redirected_to "/store"

    post "/store/products", params: {
      product: { name: "Unauthorized product", inventory_count: 3 }
    }
    assert_redirected_to "/store"
    assert_not Store::Product.exists?(name: "Unauthorized product")

    product = Store::Product.find_by!(name: "T-Shirt")
    patch "/store/products/#{product.id}", params: {
      product: { name: "Customer changed product", inventory_count: 3 }
    }
    assert_redirected_to "/store"
    assert_equal "T-Shirt", product.reload.name

    delete "/store/products/#{product.id}"
    assert_redirected_to "/store"
    assert Store::Product.exists?(product.id)

    sign_out
    administrator = User.create!(
      email_address: "store-admin@example.org",
      password: "a private password",
      password_confirmation: "a private password",
      admin: true
    )
    sign_in_as(administrator)
    get "/store/products/new"
    assert_response :success
    assert_select "input[name='product[price_cents]'][required]"
    assert_select "input[name='product[currency_code]'][required]"

    post "/store/products", params: {
      product: { name: "Admin-created product", inventory_count: 3, price_cents: 1500, currency_code: "USD" }
    }
    assert_response :redirect
    assert_match %r{/store/products/\d+\z}, response.location
    assert Store::Product.exists?(name: "Admin-created product")
  end
end
