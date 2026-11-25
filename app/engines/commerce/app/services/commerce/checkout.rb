module Commerce
  class Checkout
    class Error < StandardError; end
    class EmptyCart < Error; end
    class UnavailableItems < Error; end
    class MixedCurrencies < Error; end

    def initialize(cart)
      @cart = cart
    end

    def call
      Order.transaction do
        cart = Cart.lock.find(@cart.id)
        cart_items = cart.items.includes(:product).to_a
        raise EmptyCart if cart_items.empty?

        raise UnavailableItems if cart_items.any? do |item|
          !item.product.price_set? || item.quantity > item.product.inventory_count
        end

        currencies = cart_items.map { |item| item.product.currency_code }.uniq
        raise MixedCurrencies unless currencies.one?

        order = Order.create!(
          user: cart.user,
          status: "pending_payment",
          currency_code: currencies.first,
          total_cents: 0
        )

        cart_items.each do |item|
          product = item.product
          order.items.create!(
            product: product,
            product_name: product.localized_name,
            quantity: item.quantity,
            unit_price_cents: product.price_cents,
            total_cents: product.price_cents * item.quantity
          )
        end

        order.update!(total_cents: order.items.sum(:total_cents))
        cart.items.destroy_all
        order
      end
    end
  end
end
