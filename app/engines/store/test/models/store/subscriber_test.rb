require "test_helper"

module Store
  class SubscriberTest < ActiveSupport::TestCase
    test "requires a valid email address" do
      subscriber = Subscriber.new(product: Product.find_by!(name: "T-Shirt"), email: "not-an-email")

      assert_not subscriber.valid?
      assert_includes subscriber.errors[:email], "is invalid"
    end

    test "generates unsubscribe tokens" do
      subscriber = Subscriber.find_by!(email: "david@example.org")

      assert_equal subscriber, Subscriber.find_by_token_for(
        :unsubscribe,
        subscriber.generate_token_for(:unsubscribe)
      )
    end
  end
end
