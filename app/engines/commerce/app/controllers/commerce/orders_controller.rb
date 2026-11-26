module Commerce
  class OrdersController < ApplicationController
    before_action :require_admin!, only: :mark_fulfilled

    def index
      @orders = orders_scope.order(created_at: :desc)
    end

    def create
      @order = Checkout.new(current_cart, shipping_address: shipping_address_params).call
      redirect_to @order.adyen_checkout_url, allow_other_host: true
    rescue Checkout::EmptyCart
      redirect_to cart_path, alert: t("commerce.cart.empty")
    rescue Checkout::UnavailableItems
      redirect_to cart_path, alert: t("commerce.cart.stock_changed")
    rescue Checkout::MixedCurrencies
      redirect_to cart_path, alert: t("commerce.cart.mixed_currencies")
    rescue Checkout::UnsupportedCurrency
      redirect_to cart_path, alert: t("commerce.cart.usd_only")
    rescue Checkout::InvalidShippingAddress
      redirect_to cart_path, alert: t("commerce.cart.invalid_shipping_address")
    rescue Checkout::ProviderUnavailable
      redirect_to cart_path, alert: t("commerce.cart.checkout_unavailable")
    end

    def show
      @order = orders_scope.find(params[:id])
    end

    def payment_return
      @order = orders_scope.find(params[:id])
      redirect_to order_path(@order), notice: t("commerce.orders.returned_from_payment")
    end

    def mark_fulfilled
      @order = Order.find(params[:id])
      return head :conflict unless @order.fulfillable?

      @order.update!(fulfilled_at: Time.current)
      redirect_to order_path(@order), notice: t("commerce.orders.marked_fulfilled")
    end

    private
      def orders_scope
        Current.user.admin? ? Order.all : Order.where(user: Current.user)
      end

      def require_admin!
        head :forbidden unless Current.user.admin?
      end

      def shipping_address_params
        params.expect(shipping_address: [ :name, :line1, :line2, :city, :region, :postal_code, :country_code ])
      end
  end
end
