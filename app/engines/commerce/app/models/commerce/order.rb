module Commerce
  class Order < ApplicationRecord
    STATUSES = %w[ pending_payment processing_payment paid cancelled payment_review ].freeze

    belongs_to :user, class_name: "::User"
    has_many :items, class_name: "Commerce::OrderItem", dependent: :destroy
    has_one :cart, class_name: "Commerce::Cart", foreign_key: :checkout_order_id, dependent: :nullify

    validates :status, inclusion: { in: STATUSES }
    validates :currency_code, format: { with: /\A[A-Z]{3}\z/ }
    validates :total_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    def fulfillable?
      status == "paid" && fulfilled_at.nil?
    end

    def cancel_and_release_inventory!
      self.class.transaction do
        lock!
        return unless status == "pending_payment"

        items.includes(:product).each do |item|
          product = Store::Product.lock.find_by(id: item.product_id)
          product&.update!(inventory_count: product.inventory_count + item.quantity)
        end

        update!(status: "cancelled")
        restore_cart_items
      end
    end

    private
      def restore_cart_items
        cart = Commerce::Cart.find_by(checkout_order_id: id)
        return unless cart

        if cart.items.empty?
          items.each do |item|
            next unless item.product_id

            cart_item = cart.items.find_or_initialize_by(product_id: item.product_id)
            cart_item.quantity = cart_item.quantity.to_i + item.quantity
            cart_item.save!(validate: false)
          end
        end
        cart.update!(checkout_order_id: nil)
      end
  end
end
