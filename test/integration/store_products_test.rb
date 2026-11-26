require "test_helper"

class StoreProductsTest < ActionDispatch::IntegrationTest
  test "products page introduces the catalog and renders browsable product cards" do
    get "/store"

    assert_response :success
    assert_select "nav.site-nav a[aria-current='page']", "Products"
    assert_select "h1#products-title", "Products"
    assert_select "form.products-toolbar[action='/store']"
    assert_select "article.product-card", count: 2
    assert_select "article.product-card a.product-card__action", count: 2
  end

  test "products can be searched and sorted by price" do
    get "/store", params: { q: "out of stock", sort: "price_asc" }

    assert_response :success
    assert_select "article.product-card h2", text: "Out of Stock Item"
    assert_select "article.product-card", count: 1

    get "/store", params: { sort: "price_asc" }

    assert_response :success
    assert_select "article.product-card h2" do |headings|
      assert_equal [ "Out of Stock Item", "T-Shirt" ], headings.map(&:text)
    end
  end

  test "products page offers a next step when a search has no matches" do
    get "/store", params: { q: "not-in-this-catalog" }

    assert_response :success
    assert_select ".products-empty h2", "No products found"
    assert_select ".products-empty a[href='/store']", "Clear search"
    assert_select "article.product-card", false
  end
end
