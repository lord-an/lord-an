require "test_helper"

class StoreWishlistsTest < ActionDispatch::IntegrationTest
  test "an owner can create, add, move, and remove wishlist products" do
    sign_in_as users(:one)
    product = Store::Product.create!(name: "Desk Lamp", inventory_count: 4, price_cents: 2200, currency_code: "USD")

    post "/store/wishlists", params: { wishlist: { name: "Home Ideas" } }
    wishlist = users(:one).wishlists.find_by!(name: "Home Ideas")
    assert_redirected_to "/store/wishlists/#{wishlist.to_param}"

    post "/store/products/#{product.id}/wishlist", params: { wishlist_id: wishlist.id }
    assert_redirected_to "/store/wishlists/#{wishlist.to_param}"
    assert_equal 1, wishlist.reload.products_count
    assert_equal 1, product.reload.wishlists_count

    post "/store/products/#{product.id}/wishlist", params: { wishlist_id: wishlist.id }
    assert_equal 1, wishlist.reload.wishlist_products.count
    assert_equal 1, product.reload.wishlists_count

    destination = users(:one).wishlists.create!(name: "Gift Ideas")
    wishlist_product = wishlist.wishlist_products.sole
    patch "/store/wishlists/#{wishlist.id}/wishlist_products/#{wishlist_product.id}",
      params: { new_wishlist_id: destination.id }
    assert_equal 0, wishlist.reload.products_count
    assert_equal 1, destination.reload.products_count
    assert_equal 1, product.reload.wishlists_count

    delete "/store/wishlists/#{destination.id}/wishlist_products/#{wishlist_product.id}"
    assert_equal 0, destination.reload.products_count
    assert_equal 0, product.reload.wishlists_count
  end

  test "wishlists are publicly viewable but only their owner can manage them" do
    owner = users(:one)
    wishlist = owner.wishlists.create!(name: "Public List")

    get "/store/wishlists/#{wishlist.to_param}"
    assert_response :success
    assert_select "h1", "Public List"
    assert_select "button", "Copy to clipboard"
    assert_select "a", text: "Edit", count: 0

    sign_in_as users(:two)
    get "/store/wishlists/#{wishlist.to_param}/edit"
    assert_response :not_found

    delete "/store/wishlists/#{wishlist.to_param}"
    assert_response :not_found
    assert owner.wishlists.exists?(wishlist.id)
  end

  test "the product wishlist form is available to signed-in customers" do
    sign_in_as users(:one)
    product = Store::Product.create!(name: "Desk Lamp", inventory_count: 4, price_cents: 2200, currency_code: "USD")

    get "/store/products/#{product.id}"

    assert_response :success
    assert_select "input[type=submit][value='Add to wishlist']"
  end

  test "the product wishlist form directs visitors to sign up" do
    product = Store::Product.create!(name: "Desk Lamp", inventory_count: 4, price_cents: 2200, currency_code: "USD")

    get "/store/products/#{product.id}"

    assert_response :success
    assert_select "a[href='/authenticate/registrations/new']", text: "Add to wishlist"
  end

  test "wishlists can be filtered by owner and product" do
    wishlist = users(:one).wishlists.create!(name: "Filtered List")
    product = Store::Product.create!(name: "Desk Lamp", inventory_count: 4, price_cents: 2200, currency_code: "USD")
    wishlist.wishlist_products.create!(product: product)

    assert_equal [ wishlist ], Store::Wishlist.filter_by(
      user_id: users(:one).id,
      product_id: product.id
    )
  end
end
