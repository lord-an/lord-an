module Store
  class SubscribersController < ApplicationController
    allow_unauthenticated_access
    before_action :set_product

    def create
      subscriber = @product.subscribers.find_or_initialize_by(subscriber_params)

      if subscriber.save
        redirect_to @product, notice: t("store.subscribers.subscribed")
      else
        redirect_to @product, alert: subscriber.errors.full_messages.to_sentence
      end
    end

    private
      def set_product
        @product = Product.find(params[:product_id])
      end

      def subscriber_params
        params.expect(subscriber: [ :email ])
      end
  end
end
