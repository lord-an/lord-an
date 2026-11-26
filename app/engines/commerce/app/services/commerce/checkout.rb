module Commerce
  class Checkout
    class Error < StandardError; end
    class EmptyCart < Error; end
    class UnavailableItems < Error; end
    class MixedCurrencies < Error; end
    class UnsupportedCurrency < Error; end
    class InvalidShippingAddress < Error; end
    class ProviderUnavailable < Error; end

    SHIPPING_CENTS_PER_GRAM = 10
    SHIPPING_ADDRESS_FIELDS = %i[ name line1 line2 city region postal_code country_code ].freeze

    def initialize(cart, shipping_address:, adyen_gateway: AdyenGateway.new, tax_gateway: AvaTaxGateway.new)
      @cart = cart
      @shipping_address = shipping_address.to_h.symbolize_keys.slice(*SHIPPING_ADDRESS_FIELDS)
      @adyen_gateway = adyen_gateway
      @tax_gateway = tax_gateway
    end

    def call
      order = existing_order || reserve_inventory_and_create_order
      return order if order.status == "processing_payment"
      return finalize_existing_session(order) if order.adyen_checkout_url.present?

      order.update!(tax_cents: @tax_gateway.calculate(order: order))
      order.update!(total_cents: order.items.sum(:total_cents) + order.shipping_cents + order.tax_cents)

      session = @adyen_gateway.create_session(order: order, return_url: payment_return_url(order))
      order.update!(
        adyen_session_id: session.fetch(:id),
        adyen_checkout_url: session.fetch(:url),
        expires_at: session.fetch(:expires_at) + 15.minutes
      )

      finalize_existing_session(order)
    rescue AdyenGateway::Error, AvaTaxGateway::Error, ActiveJob::EnqueueError => error
      cancel_failed_checkout(order)
      raise ProviderUnavailable, "Checkout providers are temporarily unavailable"
    end

    private
      def reserve_inventory_and_create_order
        Order.transaction do
          cart = Cart.lock.find(@cart.id)
          raise UnavailableItems if cart.checkout_in_progress?
          raise EmptyCart if cart.items.empty?

          cart_items = cart.items.to_a
          products = Store::Product.where(id: cart_items.map(&:product_id)).order(:id).lock.index_by(&:id)
          raise UnavailableItems if cart_items.any? { |item| !products.key?(item.product_id) }

          currencies = cart_items.map { |item| products.fetch(item.product_id).currency_code }.uniq
          raise MixedCurrencies unless currencies.one?
          raise UnsupportedCurrency unless currencies.first == "USD"
          validate_shipping_address!

          cart_items.each do |item|
            product = products.fetch(item.product_id)
            raise UnavailableItems unless product.price_set? && product.shippable? && product.tax_configured? &&
              item.quantity <= product.inventory_count
          end

          order = Order.create!(
            user: cart.user,
            status: "pending_payment",
            currency_code: currencies.first,
            merchant_reference: SecureRandom.uuid,
            tax_transaction_code: "lord-an-#{SecureRandom.uuid}",
            shipping_cents: cart_items.sum do |item|
              item.quantity * products.fetch(item.product_id).shipping_weight_grams * SHIPPING_CENTS_PER_GRAM
            end,
            total_cents: 0,
            shipping_name: @shipping_address[:name],
            shipping_line1: @shipping_address[:line1],
            shipping_line2: @shipping_address[:line2],
            shipping_city: @shipping_address[:city],
            shipping_region: @shipping_address[:region],
            shipping_postal_code: @shipping_address[:postal_code],
            shipping_country_code: @shipping_address[:country_code],
            expires_at: 75.minutes.from_now
          )

          cart_items.each do |item|
            product = products.fetch(item.product_id)
            order.items.create!(
              product: product,
              product_name: product.localized_name,
              quantity: item.quantity,
              unit_price_cents: product.price_cents,
              total_cents: product.price_cents * item.quantity,
              shipping_weight_grams: product.shipping_weight_grams,
              avatax_tax_code: product.avatax_tax_code
            )
            product.update!(inventory_count: product.inventory_count - item.quantity)
          end

          order.update!(total_cents: order.items.sum(:total_cents) + order.shipping_cents)
          cart.update!(checkout_order: order)
          order
        end
      end

      def validate_shipping_address!
        required_fields = %i[ name line1 city country_code ]
        invalid = required_fields.any? { |field| @shipping_address[field].blank? } ||
          !@shipping_address[:country_code].to_s.match?(/\A[A-Z]{2}\z/)
        invalid ||= %w[US CA].include?(@shipping_address[:country_code]) &&
          (@shipping_address[:postal_code].blank? || @shipping_address[:region].blank?)
        raise InvalidShippingAddress if invalid

        SHIPPING_ADDRESS_FIELDS.each do |field|
          @shipping_address[field] = @shipping_address[field].to_s.strip.presence
        end
      end

      def payment_return_url(order)
        Commerce::Engine.routes.url_helpers.payment_return_order_url(
          order,
          host: ENV.fetch("APP_HOST", Rails.application.routes.default_url_options[:host] || "example.com"),
          protocol: "https"
        )
      end

      def finalize_existing_session(order)
        Cart.transaction do
          cart = Cart.lock.find_by!(checkout_order_id: order.id)
          cart.items.destroy_all
          order.update!(expires_at: order.expires_at || 75.minutes.from_now)
        end
        ExpirePendingOrderJob.set(wait_until: order.expires_at).perform_later(order.id)
        order
      end

      def cancel_failed_checkout(order)
        return unless order&.persisted?

        order.cancel_and_release_inventory! if order.status == "pending_payment"
        @tax_gateway.void(order: order) if order.status == "cancelled"
      rescue AvaTaxGateway::Error
        Rails.logger.error("AvaTax quote void failed for order #{order.id}")
      end

      def existing_order
        order = Cart.find(@cart.id).checkout_order
        order if order&.status.in?(%w[ pending_payment processing_payment ])
      end
  end
end
