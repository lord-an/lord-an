require "test_helper"

class CommerceTest < ActionDispatch::IntegrationTest
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

    post "/commerce/cart/checkout"

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

    post "/commerce/cart/checkout"

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

  test "checkout creates an unpaid order with immutable price snapshots" do
    sign_in_as users(:one)
    product = Store::Product.find_by!(name: "T-Shirt")
    post "/commerce/cart/items", params: {
      cart_item: { product_id: product.id, quantity: "2" }
    }

    post "/commerce/cart/checkout"

    order = Commerce::Order.find_by!(user: users(:one))
    assert_redirected_to "/commerce/orders/#{order.id}"
    assert_equal "pending_payment", order.status
    assert_equal "USD", order.currency_code
    assert_equal 5000, order.total_cents
    assert_equal "T-Shirt", order.items.sole.product_name
    assert_equal 2500, order.items.sole.unit_price_cents
    assert_empty Commerce::Cart.find_by!(user: users(:one)).items
    assert_equal 15, product.reload.inventory_count

    get "/commerce/orders/#{order.id}"

    assert_response :success
    assert_select "p", text: /Awaiting payment/
    assert_select "p", text: /No payment has been taken/

    get "/commerce/orders"

    assert_response :success
    assert_select "a[href='/commerce/orders/#{order.id}']"
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

  test "checkout rejects an empty cart" do
    sign_in_as users(:one)

    post "/commerce/cart/checkout"

    assert_redirected_to "/commerce/cart"
    assert_equal "Your cart is empty.", flash[:alert]
    assert_not Commerce::Order.exists?(user: users(:one))
  end
end
