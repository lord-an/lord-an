module Commerce
  class CartsController < ApplicationController
    def show
      @cart = current_cart
      @items = @cart.items.includes(:product)
      @currencies = @items.map { |item| item.product.currency_code }.uniq
    end
  end
end
