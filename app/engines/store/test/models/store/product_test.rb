require "test_helper"

module Store
  class ProductTest < ActiveSupport::TestCase
    include ActionMailer::TestHelper

    test "requires a name" do
      product = Product.new(name: nil)

      assert_not product.valid?
      assert_includes product.errors[:name], "can't be blank"
    end

    test "sends notifications when stock returns" do
      product = Product.find_by!(name: "T-Shirt")
      product.update!(inventory_count: 0)

      assert_emails 2 do
        product.update!(inventory_count: 99)
      end
    end
  end
end
