module Commerce
  class CartItemsController < ApplicationController
    def create
      attributes = cart_item_params
      product = Store::Product.find(attributes[:product_id])
      unless product.price_set?
        redirect_to cart_path, alert: t("commerce.cart.price_unavailable")
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
      def cart_item_params
        params.expect(cart_item: [ :product_id, :quantity ])
      end
  end
end
