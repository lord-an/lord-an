module Commerce
  class CartItemsController < ApplicationController
    before_action :redirect_if_checkout_in_progress

    def create
      attributes = cart_item_params
      product = Store::Product.find(attributes[:product_id])
      unless product.price_set? && product.shippable? && product.tax_configured? && product.currency_code == "USD"
        message = product.price_set? && product.currency_code != "USD" ? t("commerce.cart.usd_only") : t("commerce.cart.price_unavailable")
        redirect_to cart_path, alert: message
        return
      end

      quantity = Integer(attributes[:quantity], 10)
      item = current_cart.items.find_or_initialize_by(product: product)
      item.quantity = item.quantity.to_i + quantity

      if item.save
        redirect_to cart_path, notice: t("commerce.cart.item_added")
      else
        redirect_to cart_path, alert: item.errors.full_messages.to_sentence
      end
    rescue ArgumentError, TypeError
      redirect_to cart_path, alert: t("commerce.cart.invalid_quantity")
    end

    def update
      item = current_cart.items.find(params[:id])
      quantity = Integer(cart_item_params[:quantity], 10)

      if item.update(quantity: quantity)
        redirect_to cart_path, notice: t("commerce.cart.updated")
      else
        redirect_to cart_path, alert: item.errors.full_messages.to_sentence
      end
    rescue ArgumentError, TypeError
      redirect_to cart_path, alert: t("commerce.cart.invalid_quantity")
    end

    def destroy
      current_cart.items.find(params[:id]).destroy!
      redirect_to cart_path, status: :see_other, notice: t("commerce.cart.removed")
    end

    private
      def redirect_if_checkout_in_progress
        cart = Cart.find_by(user: Current.user)
        return unless cart&.checkout_in_progress?

        redirect_to cart_path, alert: t("commerce.cart.checkout_in_progress")
      end

      def cart_item_params
        params.expect(cart_item: [ :product_id, :quantity ])
      end
  end
end
