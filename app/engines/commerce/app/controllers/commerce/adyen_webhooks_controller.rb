module Commerce
  class AdyenWebhooksController < ActionController::Base
    skip_forgery_protection

    def create
      notifications = params[:notificationItems]
      return head :bad_request unless notifications.is_a?(Array)

      notifications.each do |notification|
        item = notification["NotificationRequestItem"]
        return head :unauthorized unless item.is_a?(ActionController::Parameters) || item.is_a?(Hash)

        item = item.respond_to?(:to_unsafe_h) ? item.to_unsafe_h : item
        return head :unauthorized unless AdyenWebhookValidator.new.valid?(item)
        return head :unauthorized unless item["merchantAccountCode"] == ENV.fetch("ADYEN_MERCHANT_ACCOUNT")

        ProcessAdyenWebhookJob.perform_later(item)
      end

      render plain: "[accepted]", content_type: "text/plain"
    rescue KeyError, ActiveJob::EnqueueError
      head :service_unavailable
    end
  end
end
