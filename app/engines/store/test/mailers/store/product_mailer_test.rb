require "test_helper"

module Store
  class ProductMailerTest < ActionMailer::TestCase
    test "in_stock" do
      product = Product.find_by!(name: "T-Shirt")
      subscriber = Subscriber.find_by!(email: "david@example.org")
      mail = ProductMailer.with(product: product, subscriber: subscriber).in_stock

      assert_equal "In stock", mail.subject
      assert_equal [ "david@example.org" ], mail.to
      assert_equal [ "from@example.com" ], mail.from
      assert_match "Good news!", mail.body.encoded
      assert_match "/store/products/", mail.body.encoded
      assert_match "/store/unsubscribe?token=", mail.body.encoded
    end
  end
end
