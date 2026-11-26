require "test_helper"

class StoreSubscribersTest < ActionDispatch::IntegrationTest
  setup do
    @product = Store::Product.create!(name: "Desk Lamp", inventory_count: 0, price_cents: 2200, currency_code: "USD")
  end

  test "stock alert signups require email confirmation" do
    assert_enqueued_emails 1 do
      post "/store/products/#{@product.id}/subscribers", params: { subscriber: { email: "customer@example.com" } }
    end

    subscriber = @product.subscribers.sole
    assert_nil subscriber.confirmed_at
    assert_equal "customer@example.com", subscriber.email
    assert_redirected_to "/store/products/#{@product.id}"
  end

  test "confirmation emails link to the explicit confirmation page" do
    subscriber = @product.subscribers.create!(email: "customer@example.com")

    email = Store::SubscriberMailer.with(subscriber: subscriber).confirmation

    assert_equal [ "customer@example.com" ], email.to
    assert_includes email.parts.map(&:decoded).join, "/store/subscribers/confirm/"
  end

  test "a valid confirmation token confirms a subscriber" do
    subscriber = @product.subscribers.create!(email: "customer@example.com")

    get "/store/subscribers/confirm/#{subscriber.generate_token_for(:confirmation)}"

    assert_response :success
    assert_nil subscriber.reload.confirmed_at

    post "/store/subscribers/confirm/#{subscriber.generate_token_for(:confirmation)}"

    assert subscriber.reload.confirmed_at
    assert_redirected_to "/store/products/#{@product.id}"
  end

  test "an invalid confirmation token does not confirm a subscriber" do
    subscriber = @product.subscribers.create!(email: "customer@example.com")

    get "/store/subscribers/confirm/invalid-token"

    assert_nil subscriber.reload.confirmed_at
    assert_redirected_to "/store/"
  end

  test "duplicate signups are normalized and do not send repeated confirmation emails" do
    post "/store/products/#{@product.id}/subscribers", params: { subscriber: { email: "customer@example.com" } }

    assert_enqueued_emails 0 do
      post "/store/products/#{@product.id}/subscribers", params: { subscriber: { email: " CUSTOMER@EXAMPLE.COM " } }
    end

    assert_equal 1, @product.subscribers.count
    assert_equal "customer@example.com", @product.subscribers.sole.email
  end

  test "the database prevents duplicate subscriber emails for a product" do
    @product.subscribers.create!(email: "customer@example.com")

    assert_raises ActiveRecord::RecordNotUnique do
      Store::Subscriber.insert!({
        product_id: @product.id,
        email: "customer@example.com",
        created_at: Time.current,
        updated_at: Time.current
      })
    end
  end

  test "stock alert signups are rate limited by IP address" do
    5.times do |index|
      post "/store/products/#{@product.id}/subscribers",
        params: { subscriber: { email: "customer#{index}@example.com" } },
        headers: { "REMOTE_ADDR" => "198.51.100.99" }
      assert_redirected_to "/store/products/#{@product.id}"
    end

    post "/store/products/#{@product.id}/subscribers",
      params: { subscriber: { email: "blocked@example.com" } },
      headers: { "REMOTE_ADDR" => "198.51.100.99" }

    assert_response :too_many_requests
    assert_equal 5, @product.subscribers.count
  end

  test "only confirmed subscribers receive back in stock notifications" do
    confirmed = @product.subscribers.create!(email: "confirmed@example.com", confirmed_at: Time.current)
    @product.subscribers.create!(email: "pending@example.com")

    assert_enqueued_emails 1 do
      @product.update!(inventory_count: 2)
    end

    assert_equal "confirmed@example.com", confirmed.email
  end
end
