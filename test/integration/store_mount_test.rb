require "test_helper"

class StoreMountTest < ActionDispatch::IntegrationTest
  test "serves the store from /store" do
    get "/store"

    assert_response :success
    assert_select "h1", "Products"
  end

  test "the application root redirects to the store" do
    get "/"

    assert_redirected_to "/store"
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
        password_confirmation: "a private password",
        admin: true
      }
    }

    assert_redirected_to "/portal/settings"
    user = User.find_by!(email_address: "engine-user@example.org")
    assert_not user.admin?

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

    post "/store/products", params: {
      product: { name: "Admin-created product", inventory_count: 3 }
    }
    assert_response :redirect
    assert_match %r{/store/products/\d+\z}, response.location
    assert Store::Product.exists?(name: "Admin-created product")
  end
end
