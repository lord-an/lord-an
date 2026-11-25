require "test_helper"

class StoreMountTest < ActionDispatch::IntegrationTest
  test "serves the store from /store" do
    get "/store"

    assert_response :success
    assert_select "h1", "Products"
  end

  test "mounts signup and login through separate engines" do
    get "/authenticate/registrations/new"
    assert_response :success
    assert_select "h1", "Sign up"

    get "/authenticate/session/new"
    assert_response :success
    assert_select "h1", "Log in"
  end

  test "a visitor can sign up, view settings, and update account settings" do
    post "/authenticate/registrations", params: {
      user: {
        email_address: "engine-user@example.org",
        password: "a private password",
        password_confirmation: "a private password"
      }
    }

    assert_redirected_to "/portal/settings"
    assert User.exists?(email_address: "engine-user@example.org")

    get "/portal/settings"
    assert_response :success
    assert_select "p", /engine-user@example\.org/

    patch "/portal/settings", params: {
      user: {
        email_address: "updated-user@example.org",
        current_password: "a private password",
        password: "a new private password",
        password_confirmation: "a new private password"
      }
    }

    assert_redirected_to "/portal/settings"
    user = User.find_by!(email_address: "updated-user@example.org")
    assert user.authenticate("a new private password")
  end

  test "portal settings requires authentication" do
    get "/portal/settings"

    assert_redirected_to "/authenticate/session/new"
  end

  test "Store management uses host authentication" do
    User.create!(
      email_address: "store-owner@example.org",
      password: "a private password",
      password_confirmation: "a private password"
    )

    post "/authenticate/session", params: {
      email_address: "store-owner@example.org",
      password: "a private password"
    }

    assert_redirected_to "/portal/settings"

    get "/store/products/new"
    assert_response :success
  end
end
