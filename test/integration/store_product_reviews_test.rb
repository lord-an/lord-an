require "test_helper"

class StoreProductReviewsTest < ActionDispatch::IntegrationTest
  test "a signed-in customer can submit a review and the product rating is cached" do
    sign_in_as users(:one)
    product = Store::Product.create!(name: "Desk Lamp", inventory_count: 4)

    get "/store/products/#{product.id}/reviews/new"
    assert_response :success
    assert_select "input[type=radio][name='review[rating]']", count: 5

    post "/store/products/#{product.id}/reviews", params: {
      review: {
        rating: 5,
        body: "A useful, well-made lamp.",
        user_id: users(:two).id
      }
    }

    review = product.reviews.sole
    assert_equal users(:one), review.user
    assert_redirected_to "/store/products/#{product.id}"
    assert_equal 1, product.reload.reviews_count
    assert_equal 5.0, product.rating.to_f
  end

  test "review creation requires authentication" do
    product = Store::Product.create!(name: "Desk Lamp", inventory_count: 4)

    post "/store/products/#{product.id}/reviews", params: {
      review: { rating: 4, body: "Looks good." }
    }

    assert_redirected_to "/authenticate/session/new"
    assert_empty product.reviews
  end

  test "review validation rejects ratings outside one to five and missing bodies" do
    sign_in_as users(:one)
    product = Store::Product.create!(name: "Desk Lamp", inventory_count: 4)

    post "/store/products/#{product.id}/reviews", params: {
      review: { rating: 6, body: "" }
    }

    assert_response :unprocessable_entity
    assert_select ".error"
    assert_empty product.reviews
  end

  test "product pages display average ratings and filter reviews by rating" do
    product = Store::Product.create!(name: "Desk Lamp", inventory_count: 4)
    product.reviews.create!(user: users(:one), rating: 5, body: "Excellent.")
    product.reviews.create!(user: users(:two), rating: 3, body: "It is fine.")

    assert_equal 2, product.reload.reviews_count
    assert_equal 4.0, product.rating.to_f
    assert_equal 50, product.rating_percentage(5)
    assert_equal 50, product.rating_percentage(3)

    get "/store/products/#{product.id}?rating=5"
    assert_response :success
    assert_select ".review", count: 1
    assert_select ".review", text: /Excellent/
    assert_select ".review", text: /It is fine/, count: 0
    assert_select "a", text: "Clear filter"

    get "/store/products/#{product.id}?rating=foo"
    assert_response :success
    assert_select ".review", count: 0
  end

  test "updating and deleting reviews recomputes the product average and count" do
    product = Store::Product.create!(name: "Desk Lamp", inventory_count: 4)
    review = product.reviews.create!(user: users(:one), rating: 5, body: "Excellent.")
    product.reviews.create!(user: users(:two), rating: 3, body: "It is fine.")
    assert_equal 4.0, product.reload.rating.to_f

    review.update!(rating: 1)
    assert_equal 2.0, product.reload.rating.to_f

    product.reviews.where(user: users(:two)).destroy_all
    assert_equal 1, product.reload.reviews_count
    assert_equal 1.0, product.rating.to_f

    review.destroy!
    assert_equal 0, product.reload.reviews_count
    assert_nil product.rating
  end
end
