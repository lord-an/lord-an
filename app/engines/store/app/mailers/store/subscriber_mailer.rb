module Store
  class SubscriberMailer < ApplicationMailer
    def confirmation
      @subscriber = params[:subscriber]
      @product = @subscriber.product
      mail to: @subscriber.email, subject: I18n.t("store.subscribers.confirm_title")
    end
  end
end
