module Commerce
  class ExpirePendingOrderJob < ApplicationJob
    retry_on AvaTaxGateway::Error, wait: :polynomially_longer, attempts: 10

    def perform(order_id)
      order = Order.find_by(id: order_id)
      return unless order

      order.cancel_and_release_inventory!
      AvaTaxGateway.new.void(order: order) if order.status == "cancelled"
    end
  end
end
