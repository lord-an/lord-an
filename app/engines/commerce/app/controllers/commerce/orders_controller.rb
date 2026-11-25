module Commerce
  class OrdersController < ApplicationController
    def index
      @orders = Order.where(user: Current.user).order(created_at: :desc)
    end

    def create
      @order = Checkout.new(current_cart).call
      redirect_to order_path(@order), notice: t("commerce.orders.pending_payment")
    rescue Checkout::EmptyCart
      redirect_to cart_path, alert: t("commerce.cart.empty")
    rescue Checkout::UnavailableItems
      redirect_to cart_path, alert: t("commerce.cart.stock_changed")
    rescue Checkout::MixedCurrencies
      redirect_to cart_path, alert: t("commerce.cart.mixed_currencies")
    end

    def show
      @order = Order.where(user: Current.user).find(params[:id])
    end
  end
end
