module Store
  class Products::WishlistsController < ApplicationController
    before_action :set_product

    def create
      if params[:wishlist_id].present?
        @wishlist = Current.user.wishlists.find(params[:wishlist_id])
      else
        @wishlist = Current.user.wishlists.find_or_create_by!(name: t("store.wishlists.default_name"))
      end

      @wishlist.wishlist_products.find_or_create_by!(product: @product)
      redirect_to @wishlist, notice: t("store.wishlists.product_added", product: @product.localized_name)
    end

    private
      def set_product
        @product = Product.find(params[:product_id])
      end
  end
end
