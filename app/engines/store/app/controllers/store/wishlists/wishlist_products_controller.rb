module Store
  class Wishlists::WishlistProductsController < ApplicationController
    before_action :set_wishlist
    before_action :set_wishlist_product

    def update
      new_wishlist = Current.user.wishlists.find(params[:new_wishlist_id])
      if @wishlist_product.update(wishlist: new_wishlist)
        redirect_to @wishlist, status: :see_other,
          notice: t("store.wishlists.product_moved", product: @wishlist_product.product.localized_name, wishlist: new_wishlist.name)
      else
        redirect_to @wishlist, status: :see_other,
          alert: t("store.wishlists.product_already_exists", product: @wishlist_product.product.localized_name, wishlist: new_wishlist.name)
      end
    end

    def destroy
      @wishlist_product.destroy!
      redirect_to @wishlist, notice: t("store.wishlists.product_removed", product: @wishlist_product.product.localized_name)
    end

    private
      def set_wishlist
        @wishlist = Current.user.wishlists.find(params[:wishlist_id])
      end

      def set_wishlist_product
        @wishlist_product = @wishlist.wishlist_products.find(params[:id])
      end
  end
end
