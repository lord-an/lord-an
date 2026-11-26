module Commerce
  class ProcessAdyenWebhookJob < ApplicationJob
    retry_on AvaTaxGateway::Error, wait: :polynomially_longer, attempts: 10

    def perform(notification)
      return unless notification["eventCode"] == "AUTHORISATION"

      order = Order.find_by!(merchant_reference: notification.fetch("merchantReference"))
      return unless verify_amount!(order, notification)

      if notification.fetch("success") == "true"
        process_authorisation(order, notification)
      else
        order.cancel_and_release_inventory!
        AvaTaxGateway.new.void(order: order) if order.status == "cancelled"
      end
    end

    private
      def process_authorisation(order, notification)
        order.with_lock do
          return if %w[ paid payment_review ].include?(order.status)

          if order.status == "cancelled"
            order.update!(status: "payment_review", payment_psp_reference: notification.fetch("pspReference"))
            Rails.logger.error("Adyen authorised cancelled order #{order.id}; manual refund review required")
            return
          end

          order.update!(status: "processing_payment", payment_psp_reference: notification.fetch("pspReference"))
        end

        AvaTaxGateway.new.commit(order: order)

        order.with_lock do
          return unless order.status == "processing_payment"

          order.update!(status: "paid", tax_committed_at: Time.current)
          order.cart&.update!(checkout_order_id: nil)
        end
      end

      def verify_amount!(order, notification)
        amount = notification.fetch("amount")
        received_amount = Integer(amount.fetch("value"), exception: false)
        return true if amount.fetch("currency") == order.currency_code && received_amount == order.total_cents

        order.with_lock do
          needs_review = %w[ pending_payment processing_payment ].include?(order.status) ||
            (order.status == "cancelled" && notification["success"] == "true")
          if needs_review
            order.update!(status: "payment_review", payment_psp_reference: notification["pspReference"])
          end
        end
        Rails.logger.error("Adyen authorization amount mismatch for order #{order.id}; manual payment review required")
        false
      end
  end
end
