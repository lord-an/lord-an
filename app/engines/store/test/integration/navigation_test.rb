require "test_helper"

class NavigationTest < ActionDispatch::IntegrationTest
  test "the store is mounted at /store" do
    get "/store"

    assert_response :success
    assert_select "h1", "Products"
  end

  test "the product index is available in Spanish" do
    cookies[:locale] = "es"
    get "/store"

    assert_response :success
    assert_select "h1", "Productos"
  end

  test "visitors can view product details and inventory" do
    product = Store::Product.find_by!(name: "Out of Stock Item")

    get "/store/products/#{product.id}"

    assert_response :success
    assert_select "h1", "Out of Stock Item"
    assert_select "p", "Out of stock"
    assert_select "form[action='/store/products/#{product.id}/subscribers']"
  end

  test "visitors can subscribe to an out-of-stock product" do
    product = Store::Product.find_by!(name: "Out of Stock Item")

    post "/store/products/#{product.id}/subscribers", params: {
      subscriber: { email: "shopper@example.org" }
    }

    assert_redirected_to "/store/products/#{product.id}"
    assert product.subscribers.exists?(email: "shopper@example.org")
  end

  test "visitors can unsubscribe with a valid token" do
    subscriber = Store::Subscriber.find_by!(email: "david@example.org")
    token = subscriber.generate_token_for(:unsubscribe)

    get "/store/unsubscribe", params: { token: token }

    assert_response :success
    assert_select "h1", "Unsubscribe from stock alerts"
    assert_select "form[action^='/store/unsubscribe?token='][method='post']"
    assert Store::Subscriber.exists?(subscriber.id)

    delete "/store/unsubscribe", params: { token: token }

    assert_redirected_to "/store/"
    assert_not Store::Subscriber.exists?(subscriber.id)
  end

  test "invalid unsubscribe tokens do not change subscription state" do
    subscriber = Store::Subscriber.find_by!(email: "david@example.org")

    get "/store/unsubscribe", params: { token: "invalid-token" }

    assert_redirected_to "/store/"
    assert Store::Subscriber.exists?(subscriber.id)
  end
end
