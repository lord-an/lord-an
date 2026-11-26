module Store
  class SubscribersController < ApplicationController
    allow_unauthenticated_access
    before_action :set_product, only: :create
    rate_limit to: 5, within: 15.minutes, only: :create

    def create
      subscriber = @product.subscribers.find_or_initialize_by(email: subscriber_params[:email])

      if subscriber.new_record? && !subscriber.save
        return redirect_to @product, alert: subscriber.errors.full_messages.to_sentence
      end

      if !subscriber.confirmed? && subscriber.confirmation_email_due?
        subscriber.update!(confirmation_sent_at: Time.current)
        SubscriberMailer.with(subscriber: subscriber).confirmation.deliver_later
      end

      redirect_to @product, notice: t("store.subscribers.confirmation_sent")
    end

    def confirm
      @subscriber = Subscriber.find_by_token_for(:confirmation, params[:token])
      redirect_to root_path, alert: t("store.subscribers.invalid_confirmation_link") unless @subscriber
    end

    def activate
      subscriber = Subscriber.find_by_token_for(:confirmation, params[:token])
      unless subscriber
        return redirect_to root_path, alert: t("store.subscribers.invalid_confirmation_link")
      end

      subscriber.update!(confirmed_at: Time.current) unless subscriber.confirmed?
      redirect_to subscriber.product, notice: t("store.subscribers.confirmed")
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
