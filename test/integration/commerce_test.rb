require "test_helper"
require "base64"
require "openssl"
require "ostruct"

class CommerceTest < ActionDispatch::IntegrationTest
  SHIPPING_ADDRESS = {
    name: "Customer One",
    line1: "1 Main Street",
    city: "New York",
    region: "NY",
    postal_code: "10001",
    country_code: "US"
  }.freeze

  class FakeAvaTaxGateway
    def calculate(order:)
      600
    end

    def commit(order:); end
    def void(order:)
      order.update!(tax_voided_at: Time.current)
    end
  end

  class FakeAdyenGateway
    def create_session(order:, return_url:)
      {
        id: "test-session-#{order.id}",
        url: "https://checkoutshopper-test.adyen.com/checkout/session",
        expires_at: 1.hour.from_now
      }
    end
  end

  class FakeAdyenSdkClient
    attr_reader :payload, :headers

    def checkout
      self
    end

    def payments_api
      self
    end

    def sessions(payload, headers:)
      @payload = payload
      @headers = headers
      OpenStruct.new(response: {
        "id" => "session-123",
        "url" => "https://checkoutshopper-test.adyen.com/checkout/session",
        "expiresAt" => 1.hour.from_now.iso8601
      })
    end
  end

  test "customers can add products to a persistent cart and update quantities" do
    sign_in_as users(:one)
    product = Store::Product.find_by!(name: "T-Shirt")

    get "/store/products/#{product.id}"

    assert_response :success
    assert_select "form[action='/commerce/cart/items']"

    post "/commerce/cart/items", params: {
      cart_item: { product_id: product.id, quantity: "2" }
    }

    assert_redirected_to "/commerce/cart"
    item = Commerce::Cart.find_by!(user: users(:one)).items.find_by!(product: product)
    assert_equal 2, item.quantity

    get "/commerce/cart"

    assert_response :success
    assert_select "input[name='cart_item[quantity]'][value='2']"

    patch "/commerce/cart/items/#{item.id}", params: {
      cart_item: { quantity: "3" }
    }

    assert_redirected_to "/commerce/cart"
    assert_equal 3, item.reload.quantity
  end

  test "cart additions require a signed-in customer" do
    product = Store::Product.find_by!(name: "T-Shirt")

    post "/commerce/cart/items", params: {
      cart_item: { product_id: product.id, quantity: "1" }
    }

    assert_redirected_to "/authenticate/session/new"
    assert_not Commerce::Cart.exists?
  end

  test "cart quantity cannot exceed available inventory" do
    sign_in_as users(:one)
    product = Store::Product.find_by!(name: "T-Shirt")

    post "/commerce/cart/items", params: {
      cart_item: { product_id: product.id, quantity: (product.inventory_count + 1).to_s }
    }

    assert_redirected_to "/commerce/cart"
    assert_empty Commerce::Cart.find_by!(user: users(:one)).items
  end

  test "unpriced products are not shown as free or added to a cart" do
    product = Store::Product.create!(name: "Unpriced product", inventory_count: 2, price_cents: 100, currency_code: "USD")
    product.update_column(:price_cents, 0)
    sign_in_as users(:one)

    get "/store/products/#{product.id}"

    assert_response :success
    assert_select "p", text: "This product is not available for purchase yet."
    assert_select "form[action='/commerce/cart/items']", false

    post "/commerce/cart/items", params: {
      cart_item: { product_id: product.id, quantity: "1" }
    }

    assert_redirected_to "/commerce/cart"
    assert_not Commerce::Cart.exists?(user: users(:one))
  end

  test "checkout rejects products whose price has not been configured" do
    sign_in_as users(:one)
    product = Store::Product.create!(name: "Temporarily unpriced", inventory_count: 2, price_cents: 100, currency_code: "USD")
    cart = Commerce::Cart.create!(user: users(:one))
    cart.items.create!(product: product, quantity: 1)
    product.update_column(:price_cents, 0)

    post_checkout

    assert_redirected_to "/commerce/cart"
    assert_not Commerce::Order.exists?(user: users(:one))
    assert_equal 1, cart.items.count
  end

  test "checkout rejects a cart with multiple currencies" do
    sign_in_as users(:one)
    cart = Commerce::Cart.create!(user: users(:one))
    usd_product = Store::Product.find_by!(name: "T-Shirt")
    cad_product = Store::Product.create!(
      name: "Canadian product",
      inventory_count: 2,
      price_cents: 1200,
      currency_code: "CAD"
    )
    cart.items.create!(product: usd_product, quantity: 1)
    cart.items.create!(product: cad_product, quantity: 1)

    post_checkout

    assert_redirected_to "/commerce/cart"
    assert_not Commerce::Order.exists?(user: users(:one))
    assert_equal 2, cart.items.count

    get "/commerce/cart"

    assert_response :success
    assert_select "p", text: "Items in one order must use the same currency."
    assert_select "p", text: /Subtotal:/, count: 0
  end

  test "deleting a catalog product removes cart rows but preserves order snapshots" do
    sign_in_as users(:one)
    product = Store::Product.create!(
      name: "Order snapshot product",
      inventory_count: 2,
      price_cents: 900,
      currency_code: "USD"
    )
    cart = Commerce::Cart.create!(user: users(:one))
    cart.items.create!(product: product, quantity: 1)
    order = Commerce::Order.create!(
      user: users(:one),
      status: "pending_payment",
      currency_code: "USD",
      total_cents: 900
    )
    order.items.create!(
      product: product,
      product_name: product.name,
      quantity: 1,
      unit_price_cents: 900,
      total_cents: 900
    )

    product.destroy!

    assert_empty cart.items.reload
    assert_equal "Order snapshot product", order.items.reload.sole.product_name
    assert_nil order.items.reload.sole.product_id
  end

  test "checkout redirects to Adyen with tax, shipping, snapshots, and reserved inventory" do
    sign_in_as users(:one)
    product = Store::Product.find_by!(name: "T-Shirt")
    post "/commerce/cart/items", params: {
      cart_item: { product_id: product.id, quantity: "2" }
    }

    post_checkout

    order = Commerce::Order.find_by!(user: users(:one))
    assert_redirected_to "https://checkoutshopper-test.adyen.com/checkout/session"
    assert_equal "pending_payment", order.status
    assert_equal "USD", order.currency_code
    assert_equal 10_000, order.shipping_cents
    assert_equal 600, order.tax_cents
    assert_equal 15_600, order.total_cents
    assert_equal "T-Shirt", order.items.sole.product_name
    assert_equal 2500, order.items.sole.unit_price_cents
    assert_empty Commerce::Cart.find_by!(user: users(:one)).items
    assert_equal 13, product.reload.inventory_count

    get "/commerce/orders/#{order.id}"

    assert_response :success
    assert_select "p", text: /Awaiting payment confirmation/
    assert_select "p", text: /USD 100.00/

    get "/commerce/orders"

    assert_response :success
    assert_select "a[href='/commerce/orders/#{order.id}']"
  end

  test "an authorization webhook marks the order paid after AvaTax commits" do
    sign_in_as users(:one)
    product = Store::Product.find_by!(name: "T-Shirt")
    Commerce::Cart.create!(user: users(:one)).items.create!(product: product, quantity: 2)
    post_checkout
    order = Commerce::Order.find_by!(user: users(:one))
    notification = payment_notification(order, success: "true")

    with_fake_gateways do
      Commerce::ProcessAdyenWebhookJob.perform_now(notification)
    end

    assert_equal "paid", order.reload.status
    assert order.tax_committed_at
    assert_equal 13, product.reload.inventory_count
    assert_nil Commerce::Cart.find_by!(user: users(:one)).checkout_order_id
  end

  test "a declined payment releases stock and restores the cart" do
    sign_in_as users(:one)
    product = Store::Product.find_by!(name: "T-Shirt")
    Commerce::Cart.create!(user: users(:one)).items.create!(product: product, quantity: 2)
    post_checkout
    order = Commerce::Order.find_by!(user: users(:one))

    with_fake_gateways do
      Commerce::ProcessAdyenWebhookJob.perform_now(payment_notification(order, success: "false"))
    end

    assert_equal "cancelled", order.reload.status
    assert order.tax_voided_at
    assert_equal 15, product.reload.inventory_count
    assert_equal 2, Commerce::Cart.find_by!(user: users(:one)).items.sole.quantity
  end

  test "an expired payment session releases stock and restores the cart" do
    sign_in_as users(:one)
    product = Store::Product.find_by!(name: "T-Shirt")
    Commerce::Cart.create!(user: users(:one)).items.create!(product: product, quantity: 2)
    post_checkout
    order = Commerce::Order.find_by!(user: users(:one))

    with_fake_gateways do
      Commerce::ExpirePendingOrderJob.perform_now(order.id)
    end

    assert_equal "cancelled", order.reload.status
    assert order.tax_voided_at
    assert_equal 15, product.reload.inventory_count
    assert_equal 2, Commerce::Cart.find_by!(user: users(:one)).items.sole.quantity
  end

  test "Adyen gateway sends the final amount and idempotency key through the SDK" do
    order = OpenStruct.new(
      merchant_reference: "order-123",
      currency_code: "USD",
      total_cents: 15600,
      shipping_country_code: "US",
      user: OpenStruct.new(email_address: "customer@example.com")
    )
    client = FakeAdyenSdkClient.new

    result = nil
    with_environment("ADYEN_MERCHANT_ACCOUNT", "test-merchant") do
      result = Commerce::AdyenGateway.new(client: client).create_session(
        order: order,
        return_url: "https://shop.example.com/commerce/orders/123/payment_return"
      )
    end

    assert_equal "session-123", result.fetch(:id)
    assert_equal "https://checkoutshopper-test.adyen.com/checkout/session", result.fetch(:url)
    assert_equal({ currency: "USD", value: 15600 }, client.payload.fetch(:amount))
    assert_equal "order-123", client.headers.fetch("Idempotency-Key")
  end

  test "Adyen webhook enqueues only notifications with a valid HMAC" do
    order = Commerce::Order.create!(
      user: users(:one),
      status: "pending_payment",
      currency_code: "USD",
      total_cents: 1000,
      merchant_reference: SecureRandom.uuid
    )
    notification = signed_notification(order)

    with_environment("ADYEN_HMAC_KEY", HMAC_KEY) do
      with_environment("ADYEN_MERCHANT_ACCOUNT", "test-merchant") do
        assert_enqueued_jobs 1, only: Commerce::ProcessAdyenWebhookJob do
          post "/commerce/webhooks/adyen", params: { notificationItems: [ { NotificationRequestItem: notification } ] }, as: :json
        end
        assert_response :success
        assert_equal "[accepted]", response.body

        notification["amount"]["value"] += 1
        assert_enqueued_jobs 0, only: Commerce::ProcessAdyenWebhookJob do
          post "/commerce/webhooks/adyen", params: { notificationItems: [ { NotificationRequestItem: notification } ] }, as: :json
        end
        assert_response :unauthorized
      end
    end
  end

  test "an authorization amount mismatch is held for manual review" do
    order = Commerce::Order.create!(
      user: users(:one),
      status: "pending_payment",
      currency_code: "USD",
      total_cents: 1000,
      merchant_reference: SecureRandom.uuid
    )
    notification = payment_notification(order, success: "true")
    notification["amount"]["value"] += 1

    Commerce::ProcessAdyenWebhookJob.perform_now(notification)

    assert_equal "payment_review", order.reload.status
    assert_equal "psp-#{order.id}", order.payment_psp_reference
  end


  test "invalid shipping addresses do not reserve inventory" do
    sign_in_as users(:one)
    product = Store::Product.find_by!(name: "T-Shirt")
    Commerce::Cart.create!(user: users(:one)).items.create!(product: product, quantity: 1)

    post "/commerce/cart/checkout", params: { shipping_address: SHIPPING_ADDRESS.merge(country_code: "USA") }

    assert_redirected_to "/commerce/cart"
    assert_equal 15, product.reload.inventory_count
    assert_equal 1, Commerce::Cart.find_by!(user: users(:one)).items.sole.quantity
  end

  test "checkout does not allow access to another customer's order" do
    order = Commerce::Order.create!(
      user: users(:one),
      status: "pending_payment",
      currency_code: "USD",
      total_cents: 100
    )
    sign_in_as users(:two)

    get "/commerce/orders/#{order.id}"

    assert_response :not_found
  end

  test "administrators can inspect and mark paid orders fulfilled" do
    users(:one).update!(admin: true)
    order = Commerce::Order.create!(
      user: users(:two),
      status: "paid",
      currency_code: "USD",
      total_cents: 1600,
      shipping_name: "Customer Two",
      shipping_line1: "2 Main Street",
      shipping_city: "New York",
      shipping_region: "NY",
      shipping_postal_code: "10002",
      shipping_country_code: "US"
    )
    sign_in_as users(:one)

    get "/commerce/orders"
    assert_response :success
    assert_select "li", text: /two@example.com/

    get "/commerce/orders/#{order.id}"
    assert_response :success
    assert_select "p", text: "Customer Two"
    assert_select "form[action='/commerce/orders/#{order.id}/mark_fulfilled']"

    post "/commerce/orders/#{order.id}/mark_fulfilled"
    assert_redirected_to "/commerce/orders/#{order.id}"
    assert order.reload.fulfilled_at
  end

  test "customers cannot mark orders fulfilled and unpaid orders cannot be fulfilled" do
    order = Commerce::Order.create!(
      user: users(:one), status: "pending_payment", currency_code: "USD", total_cents: 100
    )
    sign_in_as users(:two)

    post "/commerce/orders/#{order.id}/mark_fulfilled"
    assert_response :forbidden
    assert_nil order.reload.fulfilled_at

    users(:two).update!(admin: true)
    sign_in_as users(:two)
    post "/commerce/orders/#{order.id}/mark_fulfilled"
    assert_response :conflict
    assert_nil order.reload.fulfilled_at
  end

  test "checkout rejects an empty cart" do
    sign_in_as users(:one)

    post_checkout

    assert_redirected_to "/commerce/cart"
    assert_equal "Your cart is empty.", flash[:alert]
    assert_not Commerce::Order.exists?(user: users(:one))
  end

  private
    HMAC_KEY = "0123456789abcdef" * 4

    def signed_notification(order)
      notification = {
        "pspReference" => "psp-#{order.id}",
        "originalReference" => "",
        "merchantAccountCode" => "test-merchant",
        "merchantReference" => order.merchant_reference,
        "amount" => { "value" => order.total_cents, "currency" => order.currency_code },
        "eventCode" => "AUTHORISATION",
        "success" => "true"
      }
      signature = Base64.strict_encode64(
        OpenSSL::HMAC.digest("SHA256", [ HMAC_KEY ].pack("H*"), webhook_signing_string(notification))
      )
      notification["additionalData"] = { "hmacSignature" => signature }
      notification
    end

    def webhook_signing_string(notification)
      amount = notification.fetch("amount")
      %w[ pspReference originalReference merchantAccountCode merchantReference ].map { |key| notification[key].to_s }.push(
        amount.fetch("value").to_s,
        amount.fetch("currency").to_s,
        notification.fetch("eventCode"),
        notification.fetch("success")
      ).join(":")
    end

    def with_environment(name, value)
      previous_value = ENV[name]
      ENV[name] = value
      yield
    ensure
      previous_value ? ENV[name] = previous_value : ENV.delete(name)
    end

    def payment_notification(order, success:)
      {
        "eventCode" => "AUTHORISATION",
        "success" => success,
        "merchantReference" => order.merchant_reference,
        "pspReference" => "psp-#{order.id}",
        "amount" => { "currency" => order.currency_code, "value" => order.total_cents }
      }
    end

    def post_checkout
      with_fake_gateways do
        post "/commerce/cart/checkout", params: { shipping_address: SHIPPING_ADDRESS }
      end
    end

    def with_fake_gateways
      adyen_new = Commerce::AdyenGateway.method(:new)
      tax_new = Commerce::AvaTaxGateway.method(:new)
      Commerce::AdyenGateway.define_singleton_method(:new) { FakeAdyenGateway.new }
      Commerce::AvaTaxGateway.define_singleton_method(:new) { FakeAvaTaxGateway.new }
      yield
    ensure
      Commerce::AdyenGateway.define_singleton_method(:new, adyen_new)
      Commerce::AvaTaxGateway.define_singleton_method(:new, tax_new)
    end
end
