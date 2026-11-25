module Store
  class UnsubscribesController < ApplicationController
    allow_unauthenticated_access
    before_action :set_subscriber

    def show
      redirect_to root_path, alert: t("store.subscribers.invalid_unsubscribe_link") unless @subscriber
    end

    def destroy
      if @subscriber
        @subscriber.destroy!
        redirect_to root_path, notice: t("store.subscribers.unsubscribed")
      else
        redirect_to root_path, alert: t("store.subscribers.invalid_unsubscribe_link")
      end
    end

    private
      def set_subscriber
        @subscriber = Subscriber.find_by_token_for(:unsubscribe, params[:token])
      end
  end
end
