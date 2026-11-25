module Store
  class Products::ReviewsController < ApplicationController
    before_action :set_product

    def new
      @review = @product.reviews.new
    end

    def create
      @review = @product.reviews.new(review_params.merge(user: Current.user))
      if @review.save
        redirect_to @product, notice: t("store.reviews.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    private
      def set_product
        @product = Product.find(params[:product_id])
      end

      def review_params
        params.expect(review: [ :rating, :body, images: [] ])
      end
  end
end
