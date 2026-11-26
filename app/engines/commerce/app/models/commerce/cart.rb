module Commerce
  class Cart < ApplicationRecord
    belongs_to :user, class_name: "::User"
    has_many :items, class_name: "Commerce::CartItem", dependent: :destroy
    belongs_to :checkout_order, class_name: "Commerce::Order", optional: true

    def checkout_in_progress?
      checkout_order&.status.in?(%w[ pending_payment processing_payment ])
    end

    def total_cents
      items.sum { |item| item.quantity * item.product.price_cents }
    end
  end
end
