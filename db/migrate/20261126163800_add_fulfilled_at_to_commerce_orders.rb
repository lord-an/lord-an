class AddFulfilledAtToCommerceOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :commerce_orders, :fulfilled_at, :datetime
  end
end
