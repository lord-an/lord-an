module Commerce
  class Cart < ApplicationRecord
    belongs_to :user, class_name: "::User"
    has_many :items, class_name: "Commerce::CartItem", dependent: :destroy

    def total_cents
      items.sum { |item| item.quantity * item.product.price_cents }
    end
  end
end
