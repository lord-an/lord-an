class AddTaxVoidTimestampToCommerceOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :commerce_orders, :tax_voided_at, :datetime
  end
end
