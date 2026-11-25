module Commerce
  class CartItem < ApplicationRecord
    belongs_to :cart
    belongs_to :product, class_name: "Store::Product"

    validates :quantity, numericality: { only_integer: true, greater_than: 0 }
    validates :product_id, uniqueness: { scope: :cart_id }
    validate :product_is_purchasable

    private
      def product_is_purchasable
        return unless product

        errors.add(:product, I18n.t("commerce.cart.price_unavailable")) unless product.price_set?
        if quantity.present? && quantity > product.inventory_count
          errors.add(:quantity, I18n.t("commerce.cart.exceeds_inventory"))
        end
      end
  end
end
